---
title: FCN API Service Architecture
doc_type: decision-record
adr: 006
status: Proposed
version: 0.1.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-22
last_reviewed: 2025-10-22
next_review: 2026-04-22
classification: Internal
tags: [architecture, decision, api, fcn, runtime]
related:
  - adr-003-fcn-version-activation.md
  - adr-004-parameter-alias-policy.md
  - adr-005-fcn-supersession-governance.md
  - ../../ba/products/structured-notes/fcn/specs/fcn-v1.1.0.md
  - ../interfaces/openapi/fcn-openapi-starter.yaml
---

# FCN API Service Architecture

## Context

The FCN (Fixed Coupon Note) product knowledge base has matured with formal specifications (v1.0, v1.1.0), governance processes (ADR-003, ADR-004, ADR-005), validation scripts, and OpenAPI documentation. We now need to transition from documentation and governance scripts to an actual runtime API service that implements:

- **Template Management**: Create, validate, update, and deprecate FCN product templates
- **Trade Lifecycle**: Create, update, and terminate FCN trades
- **Observations**: Record and process market observations for barrier monitoring
- **Lifecycle Events**: Process autocall triggers, knock-out events, coupon payments, and settlement

The service must enforce the business rules (BR-001 to BR-026), version governance policies, parameter validation, issuer whitelist constraints, and idempotency guarantees while providing observability, security, and operational reliability.

### Current State
- Documentation-driven governance with manual validation
- Python validation scripts (validate-fcn-metadata.py, validate-fcn-params.py, validate_taxonomy.py)
- OpenAPI specification (fcn-openapi-starter.yaml) defining API contract
- No runtime service implementation
- No persistent storage for templates or trades
- No real-time observation processing
- No lifecycle event automation

### Drivers
1. **Business Growth**: Trading desk requires programmatic template creation and trade booking
2. **Risk Management**: Real-time observation processing and automated lifecycle event handling
3. **Compliance**: Audit trail for all template/trade operations with version governance enforcement
4. **Integration**: Enable external systems (CRM, risk engine, pricing) to interact via API
5. **Operational Efficiency**: Reduce manual intervention in trade lifecycle management
6. **Governance Automation**: Enforce supersession policies (ADR-005) and parameter validation at runtime

## Decision

**Adopt a Modular Monolith architecture with FastAPI as the baseline framework**, structured around FCN domain boundaries (templates, trades, observations, lifecycle) with clear separation of concerns.

### Architecture Style
- **Modular Monolith**: Single deployable unit with logical domain modules for agility and team autonomy
- **Baseline Framework**: FastAPI (Python) for rapid development and strong typing support
- **Alternative Under Consideration**: NestJS (TypeScript) for enterprise patterns and decorator-based validation (see Open Questions)

### Core Architectural Principles
1. **Domain-Driven Boundaries**: Organize by FCN concepts (templates, trades, observations, lifecycle) not technical layers
2. **Explicit Business Rules**: Centralized rule registry (BR-001 to BR-026) with version-aware evaluation
3. **Version Governance First**: Integrate ADR-003/005 supersession policies into template/trade creation flows
4. **Fail-Fast Validation**: Early parameter validation with detailed error envelopes (fcn-validation-errors.md)
5. **Idempotency by Design**: Request-level idempotency keys for all mutating operations
6. **Observable by Default**: Structured logging, metrics, and distributed tracing (optional initially)

## Alternatives Considered

### 1. Microservices Architecture
**Rejected**: Premature optimization given current scale and team size.

**Considerations**:
- ✅ Independent scaling of template vs trade services
- ✅ Technology diversity (different languages per service)
- ❌ Operational complexity (distributed transactions, service mesh, multiple deployments)
- ❌ Network overhead for inter-service calls (template validation during trade creation)
- ❌ Data consistency challenges (templates and trades are tightly coupled)

**Future Path**: Modular monolith design enables extraction to microservices if scaling needs arise (e.g., observation processing becomes high-throughput bottleneck).

### 2. Serverless / Function-as-a-Service
**Rejected**: Cold start latency and stateful lifecycle processing not suitable.

**Considerations**:
- ✅ Zero operational overhead (no server management)
- ✅ Auto-scaling per endpoint
- ❌ Cold start delays (300-1000ms) unacceptable for real-time observation processing
- ❌ Lifecycle event orchestration complexity (step functions vs in-process state machines)
- ❌ Limited persistent connection for database transactions

### 3. Django REST Framework
**Rejected**: FastAPI preferred for async support, automatic OpenAPI generation, and modern type hints.

**Considerations**:
- ✅ Mature ecosystem with built-in ORM (Django Models)
- ✅ Strong admin interface for manual data inspection
- ❌ Synchronous by default (async views less mature)
- ❌ Heavier framework footprint
- ❌ OpenAPI generation requires additional tooling (drf-spectacular)

### 4. Spring Boot (Java)
**Rejected**: Team expertise in Python/TypeScript; JVM overhead not justified.

**Considerations**:
- ✅ Enterprise-grade patterns (dependency injection, aspect-oriented programming)
- ✅ Strong typing and compile-time safety
- ❌ Slower iteration cycle (compile-deploy-test)
- ❌ Team learning curve (Python/TypeScript → Java)
- ❌ Heavier resource footprint (JVM heap)

## Components

### 1. Domain Services

#### TemplateService
**Responsibilities**:
- Validate template parameters against FCN spec version (v1.0, v1.1.0)
- Enforce business rules (BR-001 to BR-026) via rule registry
- Check issuer whitelist constraints (BR-022)
- Enforce version governance (reject superseded spec_version per ADR-005)
- Generate unique template_id
- Persist validated templates to repository

**Key Methods**:
```python
create_template(request: CreateTemplateRequest) -> TemplateResponse
validate_template(template: Template, spec_version: str) -> ValidationResult
deprecate_template(template_id: str, reason: str) -> TemplateResponse
get_template(template_id: str) -> Template
list_templates(filter: TemplateFilter) -> List[Template]
```

#### TradeService
**Responsibilities**:
- Resolve template_id to template parameters
- Validate trade-specific overrides (notional, spot_ref, inception_date)
- Generate unique trade_id
- Initialize trade state machine (active, knocked-out, autocalled, settled)
- Create audit trail entry
- Persist trade to repository

**Key Methods**:
```python
create_trade(request: CreateTradeRequest) -> TradeResponse
update_trade(trade_id: str, update: TradeUpdate) -> TradeResponse
terminate_trade(trade_id: str, reason: str) -> TradeResponse
get_trade(trade_id: str) -> Trade
list_trades(filter: TradeFilter) -> List[Trade]
```

#### ObservationService
**Responsibilities**:
- Record market observations (spot price, coupon barrier check, autocall barrier check)
- Trigger lifecycle events when barriers breached
- Handle memory coupon accumulation logic
- Validate observation timestamps against trading calendars
- Emit observation events to lifecycle service

**Key Methods**:
```python
record_observation(request: RecordObservationRequest) -> ObservationResponse
get_observations(trade_id: str, date_range: DateRange) -> List[Observation]
check_barriers(trade_id: str, observation: Observation) -> BarrierCheckResult
```

#### LifecycleService
**Responsibilities**:
- Process lifecycle events (autocall, knock-out, coupon payment, maturity)
- Execute settlement logic (cash vs physical, capital-at-risk per BR-025)
- Calculate payoffs based on barrier breach history
- Update trade state machine (active → knocked-out/autocalled/settled)
- Generate lifecycle audit trail

**Key Methods**:
```python
process_autocall_event(trade_id: str, event: AutocallEvent) -> LifecycleResult
process_knockout_event(trade_id: str, event: KnockoutEvent) -> LifecycleResult
process_coupon_payment(trade_id: str, event: CouponEvent) -> LifecycleResult
process_maturity_settlement(trade_id: str) -> SettlementResult
```

### 2. Repositories

#### TemplateRepository
**Technology**: PostgreSQL (primary), Redis (cache)

**Schema**:
```sql
CREATE TABLE fcn_templates (
  template_id UUID PRIMARY KEY,
  spec_version VARCHAR(10) NOT NULL,  -- e.g., '1.1.0'
  status VARCHAR(20) NOT NULL,  -- active, deprecated
  parameters JSONB NOT NULL,  -- all FCN parameters
  issuer VARCHAR(50) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  created_by VARCHAR(100) NOT NULL,
  deprecated_at TIMESTAMP,
  deprecated_reason TEXT
);

CREATE INDEX idx_templates_spec_version ON fcn_templates(spec_version);
CREATE INDEX idx_templates_status ON fcn_templates(status);
CREATE INDEX idx_templates_issuer ON fcn_templates(issuer);
```

#### TradeRepository
**Technology**: PostgreSQL (primary)

**Schema**:
```sql
CREATE TABLE fcn_trades (
  trade_id UUID PRIMARY KEY,
  template_id UUID NOT NULL REFERENCES fcn_templates(template_id),
  trade_ref VARCHAR(50) UNIQUE NOT NULL,  -- external system reference
  spec_version VARCHAR(10) NOT NULL,
  status VARCHAR(20) NOT NULL,  -- active, knocked_out, autocalled, settled, terminated
  notional DECIMAL(18,2) NOT NULL,
  inception_date DATE NOT NULL,
  maturity_date DATE NOT NULL,
  parameters JSONB NOT NULL,  -- resolved template + overrides
  state JSONB NOT NULL,  -- trade state machine (barrier history, coupon payments)
  created_at TIMESTAMP NOT NULL,
  created_by VARCHAR(100) NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_trades_template_id ON fcn_trades(template_id);
CREATE INDEX idx_trades_status ON fcn_trades(status);
CREATE INDEX idx_trades_inception_date ON fcn_trades(inception_date);
CREATE INDEX idx_trades_maturity_date ON fcn_trades(maturity_date);
```

#### ObservationRepository
**Technology**: PostgreSQL (primary), TimescaleDB (optional for time-series optimization)

**Schema**:
```sql
CREATE TABLE fcn_observations (
  observation_id UUID PRIMARY KEY,
  trade_id UUID NOT NULL REFERENCES fcn_trades(trade_id),
  observation_date DATE NOT NULL,
  observation_timestamp TIMESTAMP NOT NULL,
  spot_price DECIMAL(18,6) NOT NULL,
  barrier_type VARCHAR(20) NOT NULL,  -- coupon, autocall, knockout
  barrier_breached BOOLEAN NOT NULL,
  barrier_level DECIMAL(18,6),
  created_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_observations_trade_id ON fcn_observations(trade_id);
CREATE INDEX idx_observations_date ON fcn_observations(observation_date);
CREATE INDEX idx_observations_timestamp ON fcn_observations(observation_timestamp);
```

#### LifecycleEventRepository
**Technology**: PostgreSQL (primary)

**Schema**:
```sql
CREATE TABLE fcn_lifecycle_events (
  event_id UUID PRIMARY KEY,
  trade_id UUID NOT NULL REFERENCES fcn_trades(trade_id),
  event_type VARCHAR(20) NOT NULL,  -- autocall, knockout, coupon, maturity
  event_date DATE NOT NULL,
  event_timestamp TIMESTAMP NOT NULL,
  event_data JSONB NOT NULL,  -- event-specific payload
  settlement_amount DECIMAL(18,2),
  settlement_type VARCHAR(20),  -- cash, physical
  created_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_lifecycle_trade_id ON fcn_lifecycle_events(trade_id);
CREATE INDEX idx_lifecycle_event_type ON fcn_lifecycle_events(event_type);
CREATE INDEX idx_lifecycle_event_date ON fcn_lifecycle_events(event_date);
```

### 3. Business Rule Registry

**Purpose**: Centralized, version-aware evaluation of FCN business rules (BR-001 to BR-026).

**Design**:
```python
class RuleRegistry:
    """Version-aware business rule registry"""
    
    def __init__(self):
        self._rules: Dict[str, Dict[str, Rule]] = {}  # {rule_id: {version: Rule}}
    
    def register_rule(self, rule_id: str, version: str, rule: Rule):
        """Register business rule for specific spec version"""
        if rule_id not in self._rules:
            self._rules[rule_id] = {}
        self._rules[rule_id][version] = rule
    
    def evaluate(self, rule_id: str, spec_version: str, context: Dict) -> RuleResult:
        """Evaluate rule for given spec version and context"""
        if rule_id not in self._rules:
            raise RuleNotFoundError(rule_id)
        
        # Version fallback logic (e.g., v1.1.0 → v1.1 → v1 → default)
        rule = self._resolve_rule(rule_id, spec_version)
        return rule.evaluate(context)
    
    def evaluate_all(self, spec_version: str, context: Dict) -> List[RuleResult]:
        """Evaluate all applicable rules for spec version"""
        results = []
        for rule_id in self._rules:
            results.append(self.evaluate(rule_id, spec_version, context))
        return results
```

**Example Rules**:
- **BR-001**: Spot reference validation (positive, non-zero)
- **BR-010**: Coupon barrier ordering (coupon_barrier_pct ≤ 100%)
- **BR-020**: Autocall barrier range validation (autocall_barrier_pct ≥ 100%)
- **BR-022**: Issuer whitelist enforcement
- **BR-024**: Put strike validation (put_strike_pct ≤ strike_pct for capital-at-risk)
- **BR-025**: Capital-at-risk settlement logic

### 4. Error Envelope

**Standard Format** (aligned with fcn-validation-errors.md):
```json
{
  "error": {
    "code": "FCN_VALIDATION_001",
    "message": "Invalid coupon barrier percentage",
    "details": {
      "rule": "BR-010",
      "field": "coupon_barrier_pct",
      "value": 120.5,
      "constraint": "Must be <= 100%",
      "spec_version": "1.1.0"
    },
    "timestamp": "2025-10-22T10:30:00Z",
    "request_id": "req_abc123",
    "path": "/api/v1/templates"
  }
}
```

**Error Categories**:
- **FCN_VALIDATION_xxx**: Parameter validation failures (BR-xxx rules)
- **FCN_GOVERNANCE_xxx**: Version governance violations (superseded spec, deprecated template)
- **FCN_BUSINESS_xxx**: Business logic errors (issuer not whitelisted, trade already terminated)
- **FCN_SYSTEM_xxx**: Technical errors (database unavailable, external service timeout)

### 5. Metrics

**Template Metrics**:
- `fcn.templates.created.total` (counter, labels: spec_version, issuer)
- `fcn.templates.deprecated.total` (counter)
- `fcn.templates.validation_errors.total` (counter, labels: error_code, rule_id)

**Trade Metrics**:
- `fcn.trades.created.total` (counter, labels: spec_version, template_id)
- `fcn.trades.active.gauge` (gauge)
- `fcn.trades.lifecycle_transitions.total` (counter, labels: from_state, to_state)

**Observation Metrics**:
- `fcn.observations.recorded.total` (counter, labels: trade_id, barrier_type)
- `fcn.observations.barriers_breached.total` (counter, labels: barrier_type)
- `fcn.observations.processing_latency.histogram` (histogram)

**Lifecycle Metrics**:
- `fcn.lifecycle_events.processed.total` (counter, labels: event_type)
- `fcn.lifecycle_events.settlement_amount.histogram` (histogram, labels: settlement_type)

## Version Governance Integration

### Supersession Enforcement (ADR-005)

**At Template Creation**:
1. Extract `spec_version` from request payload
2. Query SUPERSEDED_INDEX (in-memory cache from superseded specs JSON)
3. If `spec_version` is Superseded:
   - Check for governance override flag (`allow_superseded=true`, requires admin role)
   - If no override: reject with `FCN_GOVERNANCE_001` error
   - If override: log governance bypass event, proceed with warning
4. If `spec_version` is Active or Proposed: proceed

**At Trade Creation**:
1. Resolve `template_id` to template record
2. Check template `spec_version` and `status`
3. If template is deprecated: reject with `FCN_GOVERNANCE_002` error
4. If template `spec_version` is Superseded (without override): reject with `FCN_GOVERNANCE_001` error
5. If Active: proceed

**Supersession Index Cache**:
```python
class SupersessionCache:
    """In-memory cache of superseded spec versions"""
    
    def __init__(self, index_path: str):
        self._index = self._load_index(index_path)
        self._last_reload = datetime.now()
    
    def is_superseded(self, spec_version: str) -> bool:
        """Check if spec version is superseded"""
        return spec_version in self._index['superseded']
    
    def get_active_version(self) -> str:
        """Get current active normative version"""
        return self._index['active_version']
    
    def reload_if_stale(self, max_age_seconds: int = 300):
        """Reload index if cache is stale"""
        if (datetime.now() - self._last_reload).seconds > max_age_seconds:
            self._index = self._load_index(self._index_path)
            self._last_reload = datetime.now()
```

### Parameter Alias Management (ADR-004)

**Alias Resolution**:
1. Accept both legacy and canonical parameter names in API requests
2. Log warning if legacy name used
3. Transform legacy → canonical before validation
4. Store only canonical names in database

**Example**:
```python
class AliasResolver:
    """Resolve parameter aliases per ADR-004"""
    
    def __init__(self):
        self._aliases = {
            'min_upside_guarantee_pct': 'min_abs_move_guarantee_pct',  # Stage 2: Deprecation Notice
        }
    
    def resolve(self, parameters: Dict, spec_version: str) -> Dict:
        """Transform legacy parameter names to canonical"""
        resolved = parameters.copy()
        for legacy, canonical in self._aliases.items():
            if legacy in resolved:
                logger.warning(f"Legacy parameter '{legacy}' used; migrate to '{canonical}'")
                resolved[canonical] = resolved.pop(legacy)
        return resolved
```

## Idempotency Flow

### Request-Level Idempotency

**Mechanism**: Client-provided idempotency key in `Idempotency-Key` header (UUID format).

**Storage**: Redis cache (TTL: 24 hours) or PostgreSQL table.

**Schema** (PostgreSQL):
```sql
CREATE TABLE idempotency_records (
  idempotency_key UUID PRIMARY KEY,
  endpoint VARCHAR(100) NOT NULL,
  request_hash VARCHAR(64) NOT NULL,  -- SHA256 of request body
  response_status INTEGER NOT NULL,
  response_body JSONB NOT NULL,
  created_at TIMESTAMP NOT NULL,
  expires_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_idempotency_expires ON idempotency_records(expires_at);
```

**Flow**:
1. Client sends mutating request (POST /templates, POST /trades) with `Idempotency-Key: <uuid>` header
2. Service checks idempotency_records for matching key:
   - **Not found**: Process request, store response, return 201 Created
   - **Found + same request_hash**: Return cached response with 200 OK (idempotent replay)
   - **Found + different request_hash**: Return 409 Conflict (key reuse error)
3. Background job purges expired records (expires_at < now())

**Open Question**: Redis vs PostgreSQL for idempotency storage (see OQ-ADR006-02).

## Security Model

### Authentication
- **Mechanism**: OAuth 2.0 Bearer tokens (JWT)
- **Issuer**: Corporate identity provider (Azure AD, Okta, or similar)
- **Token Validation**: Public key verification, expiry check, audience claim

### Authorization
- **Roles**:
  - `fcn:template:read` - View templates
  - `fcn:template:write` - Create/update templates
  - `fcn:template:admin` - Deprecate templates, governance overrides
  - `fcn:trade:read` - View trades
  - `fcn:trade:write` - Create/update trades
  - `fcn:trade:admin` - Terminate trades
  - `fcn:observation:write` - Record observations
  - `fcn:lifecycle:admin` - Process lifecycle events manually

- **Enforcement**: Role claims in JWT validated by FastAPI dependency injection

### API Key (Alternative/Supplement)
- **Use Case**: Service-to-service integration (risk engine, pricing service)
- **Mechanism**: API key in `X-API-Key` header
- **Storage**: PostgreSQL table (hashed keys, rate limits, expiry)

### Rate Limiting
- **Global**: 1000 requests/minute per API key or user
- **Endpoint-Specific**: 
  - POST /templates: 10/minute
  - POST /trades: 100/minute
  - POST /observations: 1000/minute

### Input Validation
- **Request Size Limit**: 1 MB per request
- **Parameter Sanitization**: Strip HTML, validate JSON structure
- **SQL Injection Prevention**: Parameterized queries only (SQLAlchemy ORM)

## Logging & Tracing

### Structured Logging

**Format**: JSON logs with standard fields:
```json
{
  "timestamp": "2025-10-22T10:30:00.123Z",
  "level": "INFO",
  "service": "fcn-api",
  "version": "0.1.0",
  "request_id": "req_abc123",
  "user_id": "user_xyz789",
  "endpoint": "POST /api/v1/templates",
  "duration_ms": 45,
  "status_code": 201,
  "message": "Template created successfully",
  "context": {
    "template_id": "tmpl_def456",
    "spec_version": "1.1.0",
    "issuer": "BANK_A"
  }
}
```

**Log Levels**:
- **DEBUG**: Parameter validation details, rule evaluation steps
- **INFO**: Request/response summaries, successful operations
- **WARN**: Deprecated parameter usage, governance overrides, validation warnings
- **ERROR**: Business logic errors, external service failures
- **FATAL**: Database unavailable, configuration errors

### Distributed Tracing (Optional)

**Framework**: OpenTelemetry (open question OQ-ADR006-03)

**Instrumentation**:
- HTTP request spans (endpoint, method, status, duration)
- Database query spans (query type, table, duration)
- Business rule evaluation spans (rule_id, spec_version, result)
- External service call spans (service name, endpoint, status)

**Exporter**: Jaeger or Zipkin (deployment-specific)

### Audit Trail

**Events**:
- Template created/deprecated
- Trade created/updated/terminated
- Observation recorded
- Lifecycle event processed
- Governance override applied

**Storage**: PostgreSQL table (fcn_audit_log) with retention policy (7 years for compliance).

## Migration Strategy

### Phase 1: Foundation (Months 1-2)
**Objective**: Deploy minimal viable service with template management only.

**Deliverables**:
- [ ] FastAPI service scaffold (project structure, dependency injection)
- [ ] PostgreSQL schema (fcn_templates table)
- [ ] TemplateService + TemplateRepository
- [ ] Business rule registry (BR-001 to BR-026 core rules)
- [ ] Supersession cache (ADR-005 integration)
- [ ] Error envelope implementation
- [ ] Authentication/authorization middleware
- [ ] Structured logging
- [ ] Deployment pipeline (CI/CD)

**Endpoints**:
- `POST /api/v1/templates` - Create template
- `GET /api/v1/templates/{template_id}` - Get template
- `GET /api/v1/templates` - List templates (with filters)
- `DELETE /api/v1/templates/{template_id}` - Deprecate template

### Phase 2: Trade Management (Months 3-4)
**Objective**: Add trade lifecycle (create, update, terminate).

**Deliverables**:
- [ ] TradeService + TradeRepository
- [ ] fcn_trades table schema
- [ ] Template resolution in trade creation flow
- [ ] Trade state machine (active → knocked_out/autocalled/settled)
- [ ] Idempotency implementation (Redis or PostgreSQL)
- [ ] Trade validation with template parameters

**Endpoints**:
- `POST /api/v1/trades` - Create trade
- `GET /api/v1/trades/{trade_id}` - Get trade
- `GET /api/v1/trades` - List trades (with filters)
- `PUT /api/v1/trades/{trade_id}` - Update trade
- `DELETE /api/v1/trades/{trade_id}` - Terminate trade

### Phase 3: Observations (Months 5-6)
**Objective**: Add real-time observation recording and barrier monitoring.

**Deliverables**:
- [ ] ObservationService + ObservationRepository
- [ ] fcn_observations table schema (consider TimescaleDB)
- [ ] Barrier check logic (coupon, autocall, knockout per BR-020, BR-021)
- [ ] Memory coupon accumulation
- [ ] Event emission to LifecycleService

**Endpoints**:
- `POST /api/v1/observations` - Record observation
- `GET /api/v1/observations?trade_id={id}` - Get observations for trade

### Phase 4: Lifecycle Automation (Months 7-8)
**Objective**: Automate lifecycle event processing (autocall, knockout, settlement).

**Deliverables**:
- [ ] LifecycleService
- [ ] fcn_lifecycle_events table schema
- [ ] Autocall event processing (BR-021, BR-023)
- [ ] Knockout event processing
- [ ] Coupon payment calculation
- [ ] Settlement logic (cash vs physical, capital-at-risk per BR-025)
- [ ] Trade state machine updates

**Endpoints**:
- `POST /api/v1/lifecycle/autocall` - Process autocall event (admin)
- `POST /api/v1/lifecycle/knockout` - Process knockout event (admin)
- `POST /api/v1/lifecycle/coupon` - Process coupon payment (admin)
- `POST /api/v1/lifecycle/settlement` - Process maturity settlement (admin)

### Phase 5: Observability & Optimization (Months 9-10)
**Objective**: Add metrics, tracing, performance optimization.

**Deliverables**:
- [ ] Prometheus metrics endpoints
- [ ] Distributed tracing (if adopted, see OQ-ADR006-03)
- [ ] Database query optimization (indexes, query plans)
- [ ] Caching strategy (Redis for templates, observations)
- [ ] Load testing and capacity planning
- [ ] Alerting rules (error rates, latency, database health)

### Data Migration
**Existing Data**: None (greenfield implementation)

**Future Considerations**:
- If legacy trade data exists in other systems, define ETL pipeline to backfill fcn_trades table
- Ensure historical trades reference correct spec_version (v1.0 vs v1.1.0)

## Testing Strategy

### Unit Tests
**Scope**: Individual service methods, business rule evaluation, parameter validation.

**Framework**: pytest (Python) or Jest (TypeScript if NestJS)

**Coverage Target**: ≥ 80% line coverage for domain services and rule registry

**Examples**:
- `test_template_service.py::test_create_template_valid_v1_1_0`
- `test_template_service.py::test_create_template_rejects_superseded_version`
- `test_rule_registry.py::test_br_010_coupon_barrier_ordering`
- `test_rule_registry.py::test_br_022_issuer_whitelist_enforcement`

### Integration Tests
**Scope**: API endpoints, database interactions, idempotency flow.

**Framework**: pytest + TestClient (FastAPI) or Supertest (NestJS)

**Database**: PostgreSQL test container (Testcontainers)

**Examples**:
- `test_templates_api.py::test_create_template_returns_201`
- `test_templates_api.py::test_create_template_idempotency`
- `test_trades_api.py::test_create_trade_resolves_template`
- `test_trades_api.py::test_create_trade_rejects_deprecated_template`

### Contract Tests
**Scope**: Validate API implementation matches OpenAPI specification.

**Framework**: Schemathesis or Dredd

**Reference**: fcn-openapi-starter.yaml

**Examples**:
- Schema validation: response bodies match OpenAPI definitions
- Status code validation: 201 for successful POST, 400 for validation errors
- Required field validation: all required fields present in responses

### End-to-End Tests
**Scope**: Complete workflows (template → trade → observation → lifecycle event).

**Framework**: pytest + requests library

**Environment**: Staging environment with test database

**Examples**:
- `test_e2e.py::test_full_autocall_workflow`
  1. Create template (v1.1.0, autocall enabled)
  2. Create trade from template
  3. Record observation breaching autocall barrier
  4. Verify lifecycle event triggered
  5. Verify trade state = 'autocalled'
  6. Verify settlement calculated

### Load Tests
**Scope**: Performance under expected load (1000 req/min sustained, 5000 req/min peak).

**Framework**: Locust or k6

**Scenarios**:
- Template creation: 10 req/min sustained
- Trade creation: 100 req/min sustained
- Observation recording: 500 req/min sustained

**Metrics**:
- P50 latency < 100ms
- P95 latency < 500ms
- P99 latency < 1000ms
- Error rate < 0.1%

## Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **Performance bottleneck in observation processing** | High (real-time barrier monitoring critical) | Medium | Phase 3: Consider TimescaleDB for time-series optimization; implement Redis caching for barrier levels; horizontal scaling with read replicas |
| **Database schema evolution complexity** | Medium (adds migration effort) | High | Use Alembic (Python) or TypeORM (TypeScript) for versioned migrations; maintain schema compatibility across versions; test migrations in staging |
| **Business rule drift from documentation** | High (incorrect payoff calculations) | Medium | Maintain rule registry in sync with BR-xxx documentation; add CI checks to validate rule coverage; require sign-off from BA on rule changes |
| **Idempotency key exhaustion** | Low (UUID space large) | Low | Use UUIDv4 (2^122 unique values); implement key rotation policy (24-hour TTL); monitor key collision rate |
| **Version governance bypass** | High (trades created with superseded specs) | Low | Require admin role for governance overrides; log all bypass events; weekly audit report of override usage; disable override in production (config flag) |
| **Framework choice regret (FastAPI vs NestJS)** | Medium (rewrite effort) | Medium | Defer final decision to OQ-ADR006-01; prototype both options in Phase 1; evaluate based on team velocity, type safety, and ecosystem maturity |
| **External dependency failures (identity provider, pricing service)** | Medium (API unavailable) | Low | Implement circuit breaker pattern (resilience4j or pybreaker); cache authentication tokens; provide degraded mode (manual override) |

## Acceptance Criteria

### Functional
- ✅ Service accepts template creation requests with v1.1.0 parameters
- ✅ Service rejects template creation with superseded spec_version (v1.0) without governance override
- ✅ Service enforces issuer whitelist (BR-022)
- ✅ Service validates coupon barrier ordering (BR-010)
- ✅ Service validates autocall barrier range (BR-020)
- ✅ Service resolves template parameters in trade creation
- ✅ Service supports idempotent request replay (same response for duplicate idempotency key)
- ✅ Service returns error envelope with detailed validation errors

### Non-Functional
- ✅ API latency P95 < 500ms for template/trade creation
- ✅ API latency P95 < 100ms for observation recording
- ✅ Database schema supports 1M+ trades (indexing strategy)
- ✅ Service handles 1000 req/min sustained load
- ✅ Service emits structured JSON logs
- ✅ Service exposes Prometheus metrics endpoint
- ✅ Authentication/authorization enforced on all endpoints
- ✅ OpenAPI documentation auto-generated from code

### Operational
- ✅ Service deploys via CI/CD pipeline (Docker container)
- ✅ Database migrations automated (Alembic or TypeORM)
- ✅ Health check endpoints (liveness, readiness)
- ✅ Graceful shutdown on SIGTERM (drain connections, finish in-flight requests)
- ✅ Monitoring dashboard (Grafana with key metrics)
- ✅ Alerting rules configured (error rate, latency, database health)

## Open Questions

### OQ-ADR006-01: Runtime Language Selection
**Question**: Finalize FastAPI (Python) vs NestJS (TypeScript) as implementation framework?

**Considerations**:
- **FastAPI Pros**: Team Python expertise, rapid prototyping, strong async support, Pydantic validation
- **FastAPI Cons**: Type safety weaker than TypeScript, less enterprise patterns (DI, decorators)
- **NestJS Pros**: Strong TypeScript typing, mature DI container, decorator-based validation, enterprise patterns
- **NestJS Cons**: Team learning curve, heavier framework, slower iteration

**Decision Timeline**: Resolve by end of Phase 1 (Month 2) based on prototype experience.

**Owners**: Architecture team + Development team lead

### OQ-ADR006-02: Idempotency Storage Strategy
**Question**: Use Redis or PostgreSQL for idempotency record storage?

**Considerations**:
- **Redis Pros**: Low latency (< 5ms), built-in TTL, high throughput
- **Redis Cons**: Additional infrastructure, eventual consistency risk if Redis fails
- **PostgreSQL Pros**: Single data store, ACID guarantees, audit trail persistence
- **PostgreSQL Cons**: Higher latency (10-50ms), requires background cleanup job

**Decision Timeline**: Resolve by end of Phase 2 (Month 4) based on load testing results.

**Owners**: Architecture team + DevOps team

### OQ-ADR006-03: Distributed Tracing Adoption
**Question**: Implement distributed tracing (OpenTelemetry) in initial release or defer?

**Considerations**:
- **Adopt Early Pros**: Better debugging, performance insights, service dependency mapping
- **Adopt Early Cons**: Additional complexity, external infrastructure (Jaeger/Zipkin), learning curve
- **Defer Pros**: Faster initial delivery, simpler operational model
- **Defer Cons**: Harder to debug production issues, limited performance visibility

**Decision Timeline**: Resolve by end of Phase 3 (Month 6) based on production debugging needs.

**Owners**: Architecture team + SRE team

## Follow-up Tasks

- [ ] Create FastAPI project scaffold (service structure, dependency injection setup)
- [ ] Define PostgreSQL schema for fcn_templates table (Alembic migration)
- [ ] Implement RuleRegistry with BR-001 to BR-026 rules
- [ ] Implement SupersessionCache with ADR-005 integration
- [ ] Create authentication middleware (JWT validation)
- [ ] Set up CI/CD pipeline (GitHub Actions, Docker build, test automation)
- [ ] Create unit test suite for TemplateService (>80% coverage)
- [ ] Create integration test suite for /api/v1/templates endpoints
- [ ] Document deployment guide (infrastructure requirements, configuration)
- [ ] Prototype NestJS alternative for comparison (OQ-ADR006-01)
- [ ] Load test idempotency storage options (OQ-ADR006-02)

## Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1.0 | 2025-10-22 | siripong.s@yuanta.co.th | Initial draft; documented modular monolith architecture with FastAPI baseline; defined domain services (Template, Trade, Observation, Lifecycle), repositories, rule registry, error envelope, metrics; integrated version governance (ADR-003, ADR-005), parameter aliases (ADR-004); defined idempotency flow, security model, logging/tracing, migration strategy (5 phases), testing strategy (unit, integration, contract, e2e, load), risks & mitigations, acceptance criteria; identified open questions (language choice, idempotency storage, tracing adoption) |

