---
title: FCN v1.0 Context Architecture View
doc_type: architecture
role_primary: SA
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
status: Draft
version: 0.1.0
created: 2025-10-10
last_reviewed: 2025-10-10
next_review: 2026-04-10
classification: Internal
tags: [architecture, context, fcn, structured-notes]
related:
  - ../../handoff/domain-handoff-fcn-v1.0.md
  - ../../../ba/products/structured-notes/fcn/specs/fcn-v1.0.md
  - ../../design-decisions/adr-002-product-doc-structure.md
---

# FCN v1.0 Context Architecture View

## 1. Context

### 1.1 Purpose
This document presents the context architecture view for the Fixed Coupon Note (FCN) v1.0 product implementation. It defines the system boundary, external actors, integration points, and high-level responsibilities within the broader enterprise ecosystem.

### 1.2 Scope
The FCN v1.0 system encompasses:
- Trade lifecycle management (booking, observation, settlement)
- Pricing and valuation engine
- Coupon decision logic
- Barrier monitoring
- Data persistence and audit trails
- Integration interfaces with upstream/downstream systems

**Out of Scope:**
- Implementation of external market data providers
- Client-facing portfolio management UI (separate system)
- Settlement system implementation (integration only)

### 1.3 Architectural Drivers
- **Accuracy**: Payoff calculations must match specification test vectors exactly
- **Auditability**: All lifecycle events must be traceable for compliance
- **Extensibility**: Support future FCN variants (v1.1+) without breaking changes
- **Integration**: Clean interfaces with existing trade capture and market data systems
- **Performance**: Process daily observations for portfolio of 1000+ FCN trades within SLA

## 2. Quality Attributes

| Attribute | Priority | Rationale | Target Metric |
|-----------|----------|-----------|---------------|
| Correctness | P0 | Financial accuracy is non-negotiable | 100% test vector match |
| Auditability | P0 | Regulatory requirement | All events logged |
| Availability | P1 | Business continuity for daily processing | 99.5% during business hours |
| Performance | P1 | Daily batch processing window | < 30 min for 1000 trades |
| Maintainability | P1 | Enable rapid variant development | < 2 weeks for minor enhancements |
| Scalability | P2 | Growth accommodation | Support 5000 trades within 2 years |

## 3. Views

### 3.1 Context View

```mermaid
C4Context
    title FCN v1.0 System Context

    Person(trader, "Front Office Trader", "Books FCN trades")
    Person(ops, "Middle Office Ops", "Validates settlements")
    Person(risk, "Risk Manager", "Monitors exposure")
    
    System(fcn_system, "FCN Management System", "Manages FCN trade lifecycle, pricing, and settlements")
    
    System_Ext(trade_capture, "Trade Capture System", "Sources new trade bookings")
    System_Ext(market_data, "Market Data Provider", "Delivers underlying prices")
    System_Ext(pricing_lib, "Pricing Library", "Generic valuation functions")
    System_Ext(settlement, "Settlement System", "Processes cash/physical deliveries")
    System_Ext(reporting, "Reporting System", "Client statements and risk reports")
    System_Ext(audit_trail, "Audit Trail System", "Compliance event logging")
    SystemDb_Ext(master_data, "Master Data Service", "Security reference data")
    
    Rel(trader, fcn_system, "Monitors positions", "Web UI")
    Rel(ops, fcn_system, "Reviews lifecycle events", "Web UI")
    Rel(risk, fcn_system, "Analyzes scenarios", "API")
    
    Rel(trade_capture, fcn_system, "Sends trade bookings", "JSON/REST")
    Rel(fcn_system, market_data, "Requests underlying levels", "Market Data API")
    Rel(fcn_system, master_data, "Fetches security reference", "REST")
    Rel(fcn_system, pricing_lib, "Calculates valuations", "Library Call")
    Rel(fcn_system, settlement, "Initiates settlements", "Message Queue")
    Rel(fcn_system, reporting, "Publishes positions", "Event Stream")
    Rel(fcn_system, audit_trail, "Logs lifecycle events", "Event Stream")
```

### 3.2 Container View

```mermaid
C4Container
    title FCN v1.0 Container Diagram

    Person(trader, "Trader", "Front office user")
    
    Container(web_ui, "Web Application", "React", "User interface for monitoring")
    Container(api_gateway, "API Gateway", "Node.js/Express", "REST API facade")
    Container(trade_service, "Trade Service", "Python/FastAPI", "Trade lifecycle orchestration")
    Container(pricing_engine, "Pricing Engine", "Python", "FCN-specific payoff logic")
    Container(observation_processor, "Observation Processor", "Python", "Batch barrier monitoring")
    Container(coupon_engine, "Coupon Engine", "Python", "Coupon decision logic")
    ContainerDb(fcn_db, "FCN Database", "PostgreSQL", "Trade and lifecycle data")
    ContainerDb(timeseries_db, "Timeseries Store", "TimescaleDB", "Market data cache")
    Container(event_bus, "Event Bus", "RabbitMQ", "Async event distribution")
    
    System_Ext(trade_capture, "Trade Capture System", "External")
    System_Ext(market_data, "Market Data Provider", "External")
    System_Ext(settlement, "Settlement System", "External")
    
    Rel(trader, web_ui, "Uses", "HTTPS")
    Rel(web_ui, api_gateway, "Calls", "REST/JSON")
    Rel(api_gateway, trade_service, "Routes to", "HTTP")
    
    Rel(trade_capture, trade_service, "Publishes trades", "REST")
    Rel(trade_service, fcn_db, "Persists", "SQL")
    Rel(trade_service, event_bus, "Publishes events", "AMQP")
    
    Rel(observation_processor, market_data, "Fetches prices", "API")
    Rel(observation_processor, timeseries_db, "Caches", "SQL")
    Rel(observation_processor, coupon_engine, "Triggers", "Function Call")
    
    Rel(coupon_engine, fcn_db, "Updates", "SQL")
    Rel(coupon_engine, pricing_engine, "Calculates payoffs", "Function Call")
    
    Rel(trade_service, settlement, "Sends instructions", "Message Queue")
    Rel(event_bus, settlement, "Forwards events", "AMQP")
```

## 4. Data Considerations

### 4.1 Data Ownership
- **FCN System Owns**: Trade records, observation results, coupon decisions, calculated cash flows
- **External Systems Own**: Market prices, settlement confirmations, client account data

### 4.2 Data Volumes (Initial Estimates)
- Trades: ~100-200 new trades/month, ~1000 active trades
- Observations: ~20 observation dates/trade × 1000 trades = 20,000 events/year
- Market data: ~5 underlyings/trade × daily snapshots = ~250,000 price points/year

### 4.3 Data Retention
- Trade records: Retain for 7 years post-maturity (regulatory)
- Observation history: Retain for trade lifetime + 7 years
- Market data cache: Retain for 3 months (operational)
- Audit logs: Retain for 10 years

## 5. Risks & Technical Debt

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Market data provider downtime | High | Medium | Cache last-known prices; manual override capability |
| Schema evolution breaking clients | Medium | Medium | API versioning; backward compatibility contracts |
| Test vector drift from spec | High | Low | CI/CD validation gate; normative test suite |
| Performance degradation at scale | Medium | Medium | Batch optimization; database indexing strategy |
| Security vulnerability in API | High | Low | OWASP compliance; regular penetration testing |

### Technical Debt
- Initial implementation uses synchronous REST for observation processing (batch async preferred)
- No circuit breaker pattern for external service calls (add in phase 2)
- Logging framework not yet centralized (ELK stack integration planned)

## 6. Decisions

Reference ADRs:
- [ADR-001: Documentation Governance](../../design-decisions/adr-001-documentation-governance.md)
- [ADR-002: Product Documentation Structure](../../design-decisions/adr-002-product-doc-structure.md)
- [ADR-003: FCN Version Activation Workflow](../../design-decisions/adr-003-fcn-version-activation.md)
- [ADR-004: Parameter Alias Policy](../../design-decisions/adr-004-parameter-alias-policy.md)

Key architectural decisions:
- **Event-driven architecture** for lifecycle state changes (enables audit trail and downstream integration)
- **Python** for pricing/calculation components (data science ecosystem, numerical precision)
- **PostgreSQL** for transactional data (ACID guarantees, JSON support for flexible parameters)
- **TimescaleDB extension** for time-series market data (optimized for time-based queries)

## 7. Open Issues

| ID | Description | Owner | Target Date |
|----|-------------|-------|-------------|
| OI-001 | Define API versioning strategy | SA | 2025-10-20 |
| OI-002 | Finalize market data caching policy | SA | 2025-10-25 |
| OI-003 | Determine observation processing schedule | BA/Ops | 2025-10-30 |
| OI-004 | Select monitoring/alerting platform | Ops | 2025-11-15 |
| OI-005 | Define disaster recovery procedures | SA/Ops | 2025-11-30 |

## 8. Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1.0 | 2025-10-10 | siripong.s@yuanta.co.th | Initial context view for FCN v1.0 |
