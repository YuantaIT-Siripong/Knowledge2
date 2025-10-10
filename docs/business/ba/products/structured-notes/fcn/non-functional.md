---
title: FCN v1.0 Non-Functional Requirements
doc_type: product-definition
status: Draft
version: 1.0.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-10
last_reviewed: 2025-10-10
next_review: 2026-04-10
classification: Internal
tags: [structured-notes, fcn, non-functional, requirements, performance, security]
related:
  - specs/fcn-v1.0.md
  - er-fcn-v1.0.md
  - manifest.yaml
  - ../../sa/handoff/domain-handoff-fcn-v1.0.md
---

# FCN v1.0 Non-Functional Requirements

## 1. Purpose

This document specifies the non-functional requirements (NFRs) for the Fixed Coupon Note (FCN) v1.0 product implementation. These requirements define quality attributes, constraints, and system-level characteristics that must be satisfied for production deployment.

## 2. Scope

These non-functional requirements apply to all system components supporting FCN v1.0 functionality including:
- Trade booking and validation services
- Observation processing and barrier monitoring
- Coupon decision logic and calculation
- Settlement instruction generation
- Data persistence and retrieval
- Integration touchpoints with external systems

## 3. Performance Requirements

### 3.1 Latency Targets

| Operation | Target Latency | Measurement | Priority |
|-----------|---------------|-------------|----------|
| Trade Booking | < 500ms p95 | API response time | P0 |
| Trade Booking | < 200ms p50 | API response time | P1 |
| Coupon Decision Calculation | < 1s per trade | Processing time | P0 |
| Position Query | < 200ms p95 | API response time | P1 |
| Position Query | < 100ms p50 | API response time | P2 |
| Settlement Instruction Generation | < 2s per trade | Processing time | P1 |

### 3.2 Throughput Targets

| Operation | Target Throughput | Measurement | Priority |
|-----------|------------------|-------------|----------|
| Trade Bookings | 100 trades/hour sustained | Peak load | P1 |
| Observation Processing | 10,000 trades/day | Daily batch | P0 |
| Observation Processing | 500 trades/4-hour window | Peak observation date | P0 |
| Concurrent API Requests | 50 concurrent users | API gateway | P1 |

### 3.3 Batch Processing Windows

| Process | Window | Constraint | Priority |
|---------|--------|------------|----------|
| Daily Observation Processing | 4 hours | Must complete before market open next day | P0 |
| End-of-Day Position Reporting | 2 hours | Must complete by 22:00 GMT+7 | P1 |
| Coupon Payment Generation | 6 hours | T-2 before settlement date | P1 |

**Rationale:** Observation processing must complete within 4 hours to support same-day coupon decisions and next-day settlement instructions.

---

## 4. Availability & Reliability

### 4.1 System Availability

| Component | Target Availability | Measurement Window | Priority |
|-----------|--------------------|--------------------|----------|
| Trade Booking API | 99.5% | Trading hours (06:00-20:00 GMT+7) | P0 |
| Query API | 99.0% | Business hours (08:00-18:00 GMT+7) | P1 |
| Observation Processing | 99.9% | Scheduled batch execution | P0 |
| Database Services | 99.9% | 24/7 | P0 |

**Trading Hours Definition:** Monday-Friday, 06:00-20:00 GMT+7, excluding Thai public holidays.

### 4.2 Data Durability

| Data Category | Durability Target | Backup Frequency | Priority |
|---------------|-------------------|------------------|----------|
| Trade Records | 99.999% (no loss acceptable) | Real-time replication + hourly backup | P0 |
| Observation Data | 99.999% | Real-time replication + hourly backup | P0 |
| Coupon Decisions | 99.999% | Real-time replication + hourly backup | P0 |
| Settlement Instructions | 99.999% | Real-time replication + hourly backup | P0 |
| Audit Logs | 99.99% | Daily backup | P0 |

### 4.3 Disaster Recovery

| Metric | Target | Validation | Priority |
|--------|--------|------------|----------|
| Recovery Time Objective (RTO) | < 4 hours | Quarterly DR drill | P0 |
| Recovery Point Objective (RPO) | < 15 minutes | Real-time replication lag monitoring | P0 |
| Backup Retention | See Section 5.4 | Compliance validation | P0 |
| Failover Capability | Active-passive with automatic promotion | Monthly failover test | P1 |

### 4.4 Idempotency

All API operations must support idempotent retries to ensure safe recovery from transient failures:
- Trade booking: Same trade_id + parameters within 24 hours → no duplicate creation
- Observation processing: Same trade_id + observation_date → no duplicate processing
- Coupon decision: Same observation_id → no duplicate payment generation
- Settlement instruction: Same trade_id + maturity_date → no duplicate instruction

**Implementation:** Use idempotency keys and request deduplication with 24-hour retention window.

---

## 5. Scalability

### 5.1 Initial Capacity

| Resource | Initial Capacity | Target | Priority |
|----------|-----------------|--------|----------|
| Active FCN Trades | 1,000 trades | Live positions | P0 |
| Daily Observations | 200 trades/day | Average load | P1 |
| Historical Trades (Archive) | 5,000 trades | 5 years of data | P1 |
| Concurrent Users | 20 users | API access | P1 |

### 5.2 Growth Projection

| Year | Active Trades | Daily Observations | Notes |
|------|--------------|-------------------|-------|
| Y1 (2025) | 1,000 | 200/day | Initial launch |
| Y2 (2026) | 1,500 | 300/day | 50% YoY growth |
| Y3 (2027) | 2,250 | 450/day | 50% YoY growth |
| Y4 (2028) | 3,400 | 680/day | 50% YoY growth |

**Capacity Planning:** System architecture must support 3x growth beyond Y4 projection without major refactoring.

### 5.3 Peak Load Scenarios

| Scenario | Load Characteristics | Design Target | Priority |
|----------|---------------------|---------------|----------|
| Mass Observation Date | 500 trades observed on same date | Process within 4-hour window | P0 |
| Trade Booking Spike | 50 trades booked within 1 hour | < 500ms p95 latency maintained | P1 |
| Quarter-End Reporting | 100 concurrent position queries | < 200ms p95 latency maintained | P1 |
| Maturity Wave | 200 trades maturing same week | Generate all settlement instructions within T-2 | P1 |

### 5.4 Data Retention Policy

| Data Category | Retention Period | Rationale | Archive Strategy | Reference |
|---------------|------------------|-----------|------------------|-----------|
| **Active Trades** | Until maturity + 30 days | Operational lifecycle | Move to historical table | - |
| **Historical Trades** | 7 years minimum | Regulatory requirement (NFRQ-01) | Compressed cold storage after year 2 | MiFID II, Thai SEC |
| **Observation Data** | 7 years minimum | Regulatory requirement | Compressed cold storage after year 2 | MiFID II, Thai SEC |
| **Coupon Decisions** | 7 years minimum | Regulatory requirement | Compressed cold storage after year 2 | MiFID II, Thai SEC |
| **Settlement Instructions** | 7 years minimum | Regulatory requirement | Compressed cold storage after year 2 | MiFID II, Thai SEC |
| **Audit Logs** | 7 years minimum | Regulatory requirement | Write-once-read-many (WORM) storage | MiFID II, Thai SEC |
| **Validation Reports** | 30 days | Development artifacts | GitHub Actions artifacts | CI/CD policy |
| **Market Data Snapshots** | 1 year | Dispute resolution | Compressed storage | Operational |

**Resolution of NFRQ-01:** The retention period for all regulatory-significant data (trades, observations, coupon decisions, settlement instructions, audit logs) is **7 years minimum** to comply with MiFID II transaction reporting requirements and Thai SEC recordkeeping regulations. Data must be readily accessible for first 2 years (hot storage) and may be archived to compressed cold storage thereafter, provided retrieval within 48 hours is possible.

**Storage Tiers:**
- Hot Storage (Years 0-2): High-performance database, < 100ms query latency
- Warm Storage (Years 2-5): Compressed database, < 5s query latency
- Cold Storage (Years 5-7+): Object storage (S3 Glacier equivalent), < 48h retrieval

---

## 6. Security & Compliance

### 6.1 Authentication & Authorization

| Requirement | Implementation | Standard | Priority |
|-------------|----------------|----------|----------|
| API Authentication | OAuth 2.0 / JWT tokens | RFC 6749, RFC 7519 | P0 |
| Token Expiry | 1 hour for access tokens, 30 days for refresh tokens | Industry best practice | P0 |
| Authorization Model | Role-Based Access Control (RBAC) | NIST RBAC | P0 |
| Multi-Factor Authentication | Required for production access | NIST SP 800-63B | P1 |

### 6.2 Data Protection

| Protection Type | Requirement | Standard | Priority |
|-----------------|-------------|----------|----------|
| Data at Rest | AES-256 encryption | NIST FIPS 197 | P0 |
| Data in Transit | TLS 1.3 minimum | RFC 8446 | P0 |
| Key Management | Hardware Security Module (HSM) or cloud KMS | NIST FIPS 140-2 Level 2+ | P0 |
| Key Rotation | Quarterly for data encryption keys | Industry best practice | P1 |
| Database Encryption | Transparent Data Encryption (TDE) | Database vendor standard | P0 |

### 6.3 Audit & Compliance

| Requirement | Implementation | Priority |
|-------------|----------------|----------|
| Audit Trail Coverage | All lifecycle events (create, read, update, delete) | P0 |
| Audit Log Contents | Timestamp, user ID, action, resource ID, IP address, result | P0 |
| Audit Log Integrity | Cryptographic hash chain or WORM storage | P0 |
| Audit Log Retention | 7 years (see Section 5.4) | P0 |
| Regulatory Reporting | MiFID II transaction reporting support | P0 |
| PII Protection | No Personally Identifiable Information in FCN domain (institutional only) | P0 |

### 6.4 Access Control

| Role | Permissions | Justification | Priority |
|------|-------------|---------------|----------|
| Trader | Book trades, query positions | Operational need | P0 |
| Middle Office | Query trades, approve settlements | Settlement workflow | P0 |
| Risk Manager | Query all positions, read-only | Risk monitoring | P1 |
| System Admin | Configuration management, no data access | Separation of duties | P0 |
| Auditor | Read-only access to audit logs and historical data | Compliance | P1 |
| API Service Account | System-to-system integration, scoped by function | Integration | P0 |

---

## 7. Data Quality & Consistency

### 7.1 Validation Requirements

| Validation Type | Enforcement Point | Error Handling | Priority |
|----------------|-------------------|----------------|----------|
| JSON Schema Validation | API gateway (pre-persistence) | HTTP 400 with detailed error messages | P0 |
| Business Rule Validation | Application service layer | HTTP 422 with rule violation details | P0 |
| Referential Integrity | Database foreign key constraints | Transaction rollback, alert | P0 |
| Parameter Constraint Validation | API gateway + database check constraints | Reject invalid requests | P0 |

### 7.2 Consistency Requirements

| Consistency Type | Requirement | Implementation | Priority |
|------------------|-------------|----------------|----------|
| Trade Parameters | Immutable post-booking (no amendments in v1.0) | Database immutability constraint | P0 |
| Observation Idempotency | Same observation processed exactly once | Unique constraint on (trade_id, observation_date) | P0 |
| Coupon Payment Consistency | Total paid = sum of coupon decisions | Cross-table validation query | P1 |
| Settlement Amount Consistency | Settlement = notional ± coupons ± recovery | Reconciliation report | P1 |

### 7.3 Test Coverage Requirements

| Coverage Type | Target | Validation | Priority |
|---------------|--------|------------|----------|
| Normative Test Vectors | 100% pass rate | Required for Active status (ADR-003) | P0 |
| Business Rule Coverage | All BR-001 through BR-018 validated | Unit + integration tests | P0 |
| Branch Coverage | Minimum 1 normative test vector per branch | Test vector inventory | P0 |
| Regression Test Suite | 100% pass rate | Pre-merge CI check | P0 |

### 7.4 Data Lineage

| Requirement | Implementation | Priority |
|-------------|----------------|----------|
| Documentation Version Tracking | documentation_version field per trade | P0 |
| Market Data Provenance | Source + timestamp per underlying_level | P0 |
| Coupon Decision Audit Trail | Link to observation_id and decision logic version | P1 |
| Settlement Instruction Lineage | Link to trade, final observation, coupon decisions | P1 |

---

## 8. Observability

### 8.1 Logging Requirements

| Log Type | Format | Retention | Priority |
|----------|--------|-----------|----------|
| Application Logs | Structured JSON with correlation IDs | 30 days hot, 90 days archive | P0 |
| Audit Logs | Structured JSON, immutable | 7 years (see Section 5.4) | P0 |
| Access Logs | Common Log Format or JSON | 90 days | P1 |
| Error Logs | Structured JSON with stack traces | 90 days | P0 |

**Mandatory Log Fields:**
- `timestamp` (ISO 8601 UTC)
- `correlation_id` (request/session tracking)
- `service_name`
- `log_level` (DEBUG, INFO, WARN, ERROR, FATAL)
- `user_id` (if authenticated)
- `action` (operation performed)
- `resource_id` (trade_id, observation_id, etc.)
- `result` (success/failure)
- `duration_ms` (for operations)

### 8.2 Metrics & Monitoring

| Metric Category | Key Metrics | Alert Threshold | Priority |
|-----------------|-------------|-----------------|----------|
| **Latency** | Trade booking p50/p95/p99, Query p50/p95/p99 | p95 > 500ms (booking), p95 > 200ms (query) | P0 |
| **Throughput** | Trades booked/hour, Observations processed/hour | < 50% of capacity | P1 |
| **Error Rate** | API errors/minute, Validation failures/minute | > 5% error rate | P0 |
| **Availability** | Service uptime %, API success rate % | < 99.5% (trading hours) | P0 |
| **Data Quality** | Schema validation failures, BR violations | > 1% of requests | P1 |
| **Resource Utilization** | CPU %, Memory %, Disk I/O, Connection pool | > 80% sustained | P1 |
| **Batch Processing** | Observation batch duration, Settlement batch duration | > 4 hours (observation), > 6 hours (settlement) | P0 |

### 8.3 Alerting Strategy

| Alert Severity | Response Time | Escalation | Examples |
|----------------|---------------|------------|----------|
| P0 (Critical) | 15 minutes | Immediate on-call | Data loss, system down, p95 latency SLA breach |
| P1 (High) | 1 hour | Business hours on-call | Elevated error rate, batch processing delay |
| P2 (Medium) | 4 hours | Next business day | Resource utilization warning, non-critical failures |
| P3 (Low) | Best effort | Email notification | Informational, capacity planning triggers |

### 8.4 Distributed Tracing

| Requirement | Implementation | Priority |
|-------------|----------------|----------|
| End-to-End Request Tracing | OpenTelemetry or equivalent | P1 |
| Trace Context Propagation | W3C Trace Context standard | P1 |
| Trace Sampling | 100% for errors, 10% for success (configurable) | P1 |
| Trace Retention | 7 days | P2 |

### 8.5 Health Checks

| Health Check Type | Endpoint | Frequency | Priority |
|-------------------|----------|-----------|----------|
| Liveness Probe | `/health/live` | 10 seconds | P0 |
| Readiness Probe | `/health/ready` (checks DB, cache, dependencies) | 10 seconds | P0 |
| Deep Health Check | `/health/deep` (checks external integrations) | 60 seconds | P1 |

---

## 9. Operational Requirements

### 9.1 Deployment

| Requirement | Target | Priority |
|-------------|--------|----------|
| Deployment Frequency | Weekly (off-hours) | P1 |
| Deployment Window | Saturday 02:00-06:00 GMT+7 | P1 |
| Zero-Downtime Deployment | Blue-green or canary deployment strategy | P1 |
| Rollback Time | < 30 minutes | P0 |
| Database Migration | Backward-compatible, automated with rollback | P0 |

### 9.2 Maintenance Windows

| Maintenance Type | Frequency | Window | Impact |
|------------------|-----------|--------|--------|
| Planned Maintenance | Monthly | Sunday 02:00-06:00 GMT+7 | API unavailable, batch processing suspended |
| Database Maintenance | Quarterly | Sunday 02:00-06:00 GMT+7 | Read-only mode |
| Security Patching | As needed (within 48h for critical) | Off-hours | Rolling restart, minimal downtime |

### 9.3 Support & Documentation

| Requirement | Deliverable | Priority |
|-------------|-------------|----------|
| Runbook | Operational procedures for common scenarios | P0 |
| API Documentation | OpenAPI spec + usage examples | P0 |
| Troubleshooting Guide | Common errors and resolution steps | P1 |
| Architecture Diagrams | System context, deployment, data flow | P1 |

---

## 10. Integration Requirements

### 10.1 External System SLAs

| External System | Expected Uptime | Data Freshness | Timeout | Priority |
|-----------------|----------------|----------------|---------|----------|
| Trade Capture System | 99.5% | Real-time | 5s | P0 |
| Market Data Provider | 99.9% | By 18:00 GMT+7 on observation dates | 10s | P0 |
| Settlement System | 99.5% | T-2 before settlement | 30s | P0 |
| Reference Data | 99.0% | Daily | 5s | P1 |
| Audit Trail System | 99.5% | Real-time (async acceptable) | 1s (fire-and-forget) | P1 |

### 10.2 Integration Patterns

| Pattern | Use Case | Retry Strategy | Priority |
|---------|----------|----------------|----------|
| Synchronous API | Trade booking, position queries | 3 retries with exponential backoff | P0 |
| Asynchronous Messaging | Observation processing results, coupon decisions | Dead letter queue after 5 retries | P0 |
| Batch File Transfer | Settlement instructions (fallback) | Manual retry with alert | P1 |
| Event Streaming | Audit log publishing | At-least-once delivery guarantee | P1 |

---

## 11. Assumptions & Dependencies

### 11.1 Assumptions

| ID | Assumption | Risk if Invalid | Mitigation | Status |
|----|------------|-----------------|------------|--------|
| AS-NFR-001 | Market data available by 18:00 GMT+7 on observation dates | Delayed coupon decisions, SLA breach | Implement fallback data sources, alert at 17:00 | Active |
| AS-NFR-002 | No intraday amendments to booked trades (parameters immutable) | Simplified state management, no audit complexity | Define amendment workflow in v1.1+ | Active |
| AS-NFR-003 | Maximum 10 underlyings per basket | Performance bottleneck if exceeded | Enforce in parameter schema, monitor usage | Active |
| AS-NFR-004 | Single currency per trade (no multi-currency notional) | Scope constrained | Confirm with product owner, plan for v1.1+ | Active |
| AS-NFR-005 | Daily batch processing sufficient (no real-time intraday monitoring) | Operational risk if client expectations differ | Document SLA, confirm with stakeholders | Active |

### 11.2 Dependencies

| Dependency | Provider | SLA | Impact if Unavailable | Contingency |
|------------|----------|-----|------------------------|-------------|
| Cloud Infrastructure | Cloud Provider | 99.95% | System unavailable | Multi-region failover |
| Database Service | Cloud Provider / On-Prem | 99.9% | Cannot persist/query data | Standby replica promotion |
| Market Data Feed | Data Vendor | 99.9% | Cannot process observations | Fallback vendor, manual data entry |
| OAuth/IAM Service | Corporate IAM | 99.5% | Authentication failures | Cached tokens, emergency bypass |

---

## 12. Acceptance Criteria

The following criteria must be met before FCN v1.0 can be promoted to **Active** status:

### 12.1 Performance Testing

- [ ] Load test: 100 trades/hour sustained for 1 hour with < 500ms p95 latency
- [ ] Stress test: 500 observations processed in 4-hour window
- [ ] Endurance test: 48-hour continuous operation at 50% capacity
- [ ] Latency test: p95 < 500ms for trade booking, p95 < 200ms for queries

### 12.2 Availability & Reliability Testing

- [ ] Disaster recovery drill: RTO < 4 hours, RPO < 15 minutes validated
- [ ] Failover test: Automatic failover within 5 minutes
- [ ] Backup/restore test: Full database restore completed < 2 hours
- [ ] Idempotency test: Duplicate requests handled correctly

### 12.3 Security & Compliance Testing

- [ ] Penetration testing: No high/critical vulnerabilities
- [ ] Authentication bypass attempt: Blocked
- [ ] Encryption validation: TLS 1.3 enforced, AES-256 at rest
- [ ] Audit log completeness: 100% of lifecycle events captured

### 12.4 Data Quality & Consistency Testing

- [ ] Schema validation: 100% of normative test vectors pass
- [ ] Business rule validation: All BR-001 through BR-018 enforced
- [ ] Referential integrity: Foreign key violations prevented
- [ ] Regression test suite: 100% pass rate

### 12.5 Observability Testing

- [ ] Log aggregation: All services logging to centralized system
- [ ] Metrics collection: All key metrics (Section 8.2) reporting
- [ ] Alerting: All P0/P1 alerts configured and tested
- [ ] Distributed tracing: End-to-end traces visible for sample requests

### 12.6 Documentation Completeness

- [ ] Runbook: Complete with incident response procedures
- [ ] API documentation: OpenAPI spec published
- [ ] Architecture diagrams: System context, deployment, data flow
- [ ] Non-functional requirements: This document approved

---

## 13. Revision & Escalation

### 13.1 NFR Revision Process

Non-functional requirements may be revised through the following process:
1. Identify NFR gap or constraint (via incident, capacity planning, or stakeholder request)
2. Document proposed change with justification and impact analysis
3. Review with SA, BA, Product Owner, and Risk Manager
4. Update this document and increment minor version
5. Re-validate affected acceptance criteria (Section 12)
6. Communicate changes to all stakeholders

### 13.2 Escalation Path

If an NFR cannot be met:
1. **L1 (Team)**: Engineering lead attempts resolution within sprint
2. **L2 (Manager)**: Engineering manager negotiates scope/timeline adjustment
3. **L3 (Director)**: Product Director + Engineering Director + Risk Director decide on risk acceptance, scope reduction, or timeline extension
4. **L4 (Executive)**: CTO/CFO approval for significant risk acceptance or budget increase

---

## 14. Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-10 | siripong.s@yuanta.co.th | Initial non-functional requirements specification with resolved NFRQ-01 (7-year retention period) |

---

## 15. References

- [FCN v1.0 Specification](specs/fcn-v1.0.md)
- [FCN v1.0 Domain Handoff Package](../../sa/handoff/domain-handoff-fcn-v1.0.md)
- [ADR-003: FCN Version Activation & Promotion Workflow](../../sa/design-decisions/adr-003-fcn-version-activation.md)
- [Document Control Policy](../../../../_policies/document-control-policy.md)
- MiFID II Directive 2014/65/EU (Transaction Reporting)
- Thai SEC Notification on Recordkeeping Requirements
- NIST SP 800-53 (Security and Privacy Controls)
- NIST SP 800-63B (Digital Identity Guidelines)
