---
title: SA Work Tracker - FCN v1.0
doc_type: playbook
role_primary: SA
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
status: Draft
version: 1.0.0
created: 2025-10-10
last_reviewed: 2025-10-10
next_review: 2025-10-24
classification: Internal
tags: [sa, tracker, fcn, project-management]
related:
  - sa-work-readiness-assessment.md
  - sa-onboarding-checklist.md
  - handoff/domain-handoff-fcn-v1.0.md
---

# SA Work Tracker - FCN v1.0

## Overview
This document tracks Solution Architecture work progress for FCN v1.0 implementation. It provides visibility into deliverables, decisions, blockers, and timeline.

**Current Phase:** Phase 1 - Immediate Start (Weeks 1-2)
**Overall Status:** 🟢 On Track
**Last Updated:** 2025-10-10

---

## Quick Status Dashboard

| Category | Status | Progress | Notes |
|----------|--------|----------|-------|
| **Policy Review** | ✅ Complete | 100% | All policies reviewed and understood |
| **Onboarding** | ✅ Complete | 100% | SA onboarding checklist created |
| **API Design** | 📋 Not Started | 0% | Ready to begin |
| **Data Model** | 📋 Not Started | 0% | Ready to begin |
| **Integration Architecture** | 📋 Not Started | 0% | Ready to begin |
| **Security Architecture** | 📋 Not Started | 0% | Ready to begin |
| **Decision Making** | ⏳ Pending | 0% | Awaiting Phase 1 completion |
| **Peer Review** | ⏳ Pending | 0% | Future phase |

**Legend:** ✅ Complete | 🟢 In Progress | 📋 Not Started | ⏳ Pending | ⚠️ Blocked | 🔴 At Risk

---

## Phase 1: Immediate Start (Weeks 1-2)

**Objective:** Create foundational architectural artifacts that enable development to begin.

**Target Completion:** Week 2 end
**Dependencies:** None - all inputs available from BA handoff

### 1.1 API Design

**Deliverable:** OpenAPI 3.0 specification for FCN v1.0 API

**Status:** 📋 Not Started
**Owner:** siripong.s@yuanta.co.th
**Target File:** `docs/business/sa/interfaces/fcn-api-v1.0-openapi.yaml`

**Tasks:**
- [ ] Create OpenAPI 3.0 base structure
- [ ] Define `/contracts` resource
  - [ ] POST /contracts (create trade)
  - [ ] GET /contracts/{id} (retrieve trade)
  - [ ] GET /contracts (list trades with pagination)
- [ ] Define `/parameters/validation` resource
  - [ ] POST /parameters/validation (validate parameters)
- [ ] Define `/observations` resource
  - [ ] POST /observations (record observation)
  - [ ] GET /observations (list observations)
  - [ ] GET /contracts/{id}/observations (contract observations)
- [ ] Define `/coupons` resource
  - [ ] GET /coupons (list coupon decisions)
  - [ ] GET /contracts/{id}/coupons (contract coupons)
- [ ] Define `/cash-flows` resource
  - [ ] GET /cash-flows (list cash flows)
  - [ ] GET /contracts/{id}/cash-flows (contract cash flows)
- [ ] Design common schemas (error responses, pagination)
- [ ] Document authentication/authorization requirements
- [ ] Define HTTP status codes and error handling
- [ ] Add API versioning strategy
- [ ] Document rate limiting and throttling

**Acceptance Criteria:**
- OpenAPI 3.0 compliant YAML file
- All endpoints documented with request/response schemas
- Error responses defined
- Examples provided for key operations
- Passes OpenAPI validator

**Blockers:** None

---

### 1.2 Data Model Design

**Deliverable:** Physical database schema design with DDL scripts

**Status:** 📋 Not Started
**Owner:** siripong.s@yuanta.co.th
**Target File:** `docs/business/sa/architecture/logical/fcn-database-schema.md`
**Target DDL:** `docs/business/sa/architecture/logical/fcn-schema-v1.0.sql`

**Tasks:**
- [ ] Create schema design document
- [ ] Design core tables:
  - [ ] `fcn_contracts` - Trade/contract master
  - [ ] `fcn_underlying_assets` - Underlying asset definitions
  - [ ] `fcn_contract_underlyings` - Contract-underlying linkage (for baskets)
  - [ ] `fcn_observations` - Observation events
  - [ ] `fcn_coupon_decisions` - Coupon decision results
  - [ ] `fcn_cash_flows` - Cash flow projections and actuals
  - [ ] `fcn_knock_in_events` - Barrier breach records
- [ ] Define column types and constraints
  - [ ] Primary keys (UUIDs vs integers)
  - [ ] Foreign keys with cascade rules
  - [ ] Check constraints for business rules
  - [ ] Not null constraints
- [ ] Design indexes
  - [ ] Query performance optimization
  - [ ] Unique constraints for idempotency
- [ ] Design audit tables
  - [ ] `fcn_audit_log` - All lifecycle events
  - [ ] Trigger-based or application-based auditing
- [ ] Document data retention policy
- [ ] Create ER diagram (logical to physical mapping)
- [ ] Write DDL scripts with comments
- [ ] Document migration strategy (versioning approach)

**Acceptance Criteria:**
- Complete DDL scripts that can create schema
- Documentation explains design decisions
- Traceability to business rules (BR-001 to BR-019)
- ER diagram shows relationships
- Indexing strategy documented
- Audit approach documented

**Blockers:** None

**Decision Point:** Database technology choice (PostgreSQL recommended)

---

### 1.3 Integration Architecture

**Deliverable:** Integration architecture document with sequence diagrams

**Status:** 📋 Not Started
**Owner:** siripong.s@yuanta.co.th
**Target File:** `docs/business/sa/architecture/integration/fcn-integration-architecture.md`

**Tasks:**
- [ ] Create integration architecture document
- [ ] Design trade booking integration
  - [ ] Integration pattern (REST API, message queue, batch file)
  - [ ] Contract creation message format
  - [ ] Error handling and retry logic
  - [ ] Sequence diagram: Trade capture → FCN system
- [ ] Design market data integration
  - [ ] Data sourcing approach (real-time vs batch)
  - [ ] Observation recording workflow
  - [ ] Data quality validation
  - [ ] Sequence diagram: Market data → Observation recording
- [ ] Design settlement system integration
  - [ ] Cash flow notification
  - [ ] Physical delivery instruction
  - [ ] Settlement confirmation
  - [ ] Sequence diagram: Coupon payment → Settlement
- [ ] Design reporting system integration
  - [ ] Position reporting
  - [ ] Risk reporting
  - [ ] Client statements
  - [ ] Data export formats
- [ ] Document integration patterns
  - [ ] Synchronous vs asynchronous
  - [ ] Message durability requirements
  - [ ] Idempotency handling
- [ ] Define SLAs and retry policies
- [ ] Create integration landscape diagram

**Acceptance Criteria:**
- Comprehensive integration document
- Sequence diagrams for key workflows
- Message formats specified
- Error handling documented
- Integration landscape diagram

**Blockers:** None

**Decision Point:** Market data source architecture (internal vs external) - OQ-API-005

---

### 1.4 Security Architecture

**Deliverable:** Security architecture document and ADR

**Status:** 📋 Not Started
**Owner:** siripong.s@yuanta.co.th
**Target Files:** 
- `docs/business/sa/architecture/security/fcn-security-architecture.md`
- `docs/business/sa/design-decisions/adr-007-fcn-security-model.md`

**Tasks:**
- [ ] Create security architecture document
- [ ] Design authentication model
  - [ ] User authentication (OAuth2, JWT, SAML)
  - [ ] Service-to-service authentication (mTLS, API keys)
  - [ ] Token management and refresh
- [ ] Design authorization model
  - [ ] Role-Based Access Control (RBAC)
  - [ ] Permission matrix by role
  - [ ] Resource-level authorization
- [ ] Define API security
  - [ ] API gateway configuration
  - [ ] Rate limiting and throttling
  - [ ] Input validation and sanitization
  - [ ] OWASP Top 10 mitigations
- [ ] Design data security
  - [ ] Data at rest encryption
  - [ ] Data in transit encryption (TLS 1.3)
  - [ ] PII data handling
  - [ ] Key management
- [ ] Document audit and logging
  - [ ] Security event logging
  - [ ] Access audit trail
  - [ ] Log retention policy
- [ ] Define network security
  - [ ] Network segmentation
  - [ ] Firewall rules
  - [ ] DMZ architecture (if applicable)
- [ ] Create security threat model
- [ ] Document compliance requirements (if any)
- [ ] Create **ADR-007: FCN Security Model**

**Acceptance Criteria:**
- Comprehensive security architecture document
- Authentication and authorization fully specified
- Security controls mapped to risks
- ADR-007 created and approved
- Compliance requirements addressed

**Blockers:** None

**Dependency:** Organizational security standards (if available)

---

## Phase 2: Decision Making (Weeks 2-3)

**Objective:** Resolve open architectural questions and document decisions in ADRs.

**Status:** ⏳ Pending Phase 1 completion
**Dependencies:** Phase 1 artifacts provide context for decisions

### 2.1 Idempotency Implementation (OQ-BR-002)

**Decision Required:** Database vs application enforcement for observation idempotency (BR-007)

**Status:** ⏳ Pending
**Owner:** siripong.s@yuanta.co.th
**Target File:** `docs/business/sa/design-decisions/adr-005-idempotency-implementation.md`

**Analysis Tasks:**
- [ ] Document Option A: Database unique constraint
  - [ ] Pros: Simple, guaranteed by DB, no application logic
  - [ ] Cons: Relies on DB-specific features, error handling complexity
- [ ] Document Option B: Application-level locking
  - [ ] Pros: Portable, flexible error handling, better error messages
  - [ ] Cons: More complex, potential race conditions, distributed system challenges
- [ ] Benchmark performance (if possible)
- [ ] Consider distributed system implications
- [ ] Make architectural decision
- [ ] Create **ADR-005: Idempotency Implementation Strategy**

**Priority:** P0 (Blocker for implementation)
**Recommendation Timeframe:** Week 3

---

### 2.2 Market Data Architecture (OQ-API-005)

**Decision Required:** Should market data resource be internal service or external integration?

**Status:** ⏳ Pending
**Owner:** siripong.s@yuanta.co.th
**Target File:** `docs/business/sa/design-decisions/adr-006-market-data-integration.md`

**Analysis Tasks:**
- [ ] Document Option A: Internal service (cache/proxy)
  - [ ] Pros: Data sovereignty, latency control, transformation flexibility
  - [ ] Cons: Infrastructure cost, maintenance overhead, data freshness responsibility
- [ ] Document Option B: External integration (direct)
  - [ ] Pros: Simpler, vendor responsibility, lower infrastructure cost
  - [ ] Cons: Latency, reliability dependency, vendor lock-in
- [ ] Analyze requirements:
  - [ ] Data freshness requirements
  - [ ] Latency requirements
  - [ ] Cost considerations
  - [ ] Reliability requirements
- [ ] Consider regulatory/compliance implications (data residency)
- [ ] Make architectural decision
- [ ] Create **ADR-006: Market Data Integration Architecture**

**Priority:** P0 (Blocker for integration architecture finalization)
**Recommendation Timeframe:** Week 3

---

### 2.3 Historical Observation Replay (OQ-API-003)

**Decision Required:** Should historical observation replay be supported for backdated trades?

**Status:** ⏳ Pending
**Owner:** siripong.s@yuanta.co.th (technical assessment), BA/PO (scope decision)
**Target File:** `docs/business/sa/assessments/historical-replay-assessment.md`

**Assessment Tasks:**
- [ ] Document use case for historical replay
- [ ] Assess technical feasibility
  - [ ] API endpoint design (replay vs historical ingest)
  - [ ] Data consistency requirements
  - [ ] Performance implications
- [ ] Document complexity
  - [ ] Implementation effort estimate
  - [ ] Testing effort estimate
- [ ] Document risks
  - [ ] Data integrity risks
  - [ ] Business logic complexity
- [ ] Provide recommendation (include vs defer to v1.1+)
- [ ] Present to BA/Product Owner for scope decision

**Priority:** P1 (Affects API design, but can work around)
**Recommendation Timeframe:** Week 3
**Final Decision By:** BA/Product Owner

---

### 2.4 Contract Amendment Support (OQ-API-001)

**Decision Required:** Should contract amendments be supported in v1.0 (PUT /contracts/{id})?

**Status:** ⏳ Pending
**Owner:** siripong.s@yuanta.co.th (technical assessment), BA/PO (scope decision)
**Type:** Collaborative decision

**Assessment Tasks:**
- [ ] Document technical assessment
  - [ ] Implementation complexity (data model, API, business logic)
  - [ ] Effort estimate
  - [ ] Testing requirements
  - [ ] Audit trail requirements
- [ ] Document risks
  - [ ] Data consistency risks
  - [ ] Regulatory/compliance implications
- [ ] Identify business questions for BA:
  - [ ] Amendment rules and constraints
  - [ ] Audit requirements
  - [ ] Approval workflows
- [ ] Provide recommendation (include vs defer to v1.1+)
- [ ] Collaborate with BA on business justification
- [ ] Support Product Owner decision
- [ ] Document decision outcome (in ADR or meeting notes)

**Priority:** P1 (Affects API design, but can work around)
**Recommendation Timeframe:** Week 3
**Final Decision By:** Product Owner (with BA/SA input)

---

## Phase 3: Refinement (Weeks 3-4)

**Objective:** Finalize all architectural artifacts based on Phase 2 decisions.

**Status:** ⏳ Pending Phase 2 completion

**Tasks:**
- [ ] Incorporate Phase 2 decisions into Phase 1 artifacts
- [ ] Finalize OpenAPI specification (v1.0)
- [ ] Finalize database schema DDL (v1.0)
- [ ] Complete integration sequence diagrams
- [ ] Create infrastructure architecture diagram
- [ ] Document deployment architecture
- [ ] Update all metadata (version, status, dates)
- [ ] Cross-check traceability to business rules
- [ ] Prepare for peer review

---

## Phase 4: Peer Review (Weeks 4-5)

**Objective:** Complete peer architecture review and cross-functional review.

**Status:** ⏳ Pending Phase 3 completion

**Tasks:**
- [ ] Submit all artifacts for Peer Architecture Review
- [ ] Address peer review comments
- [ ] Submit for Cross-Functional Review (Dev Lead, Ops, Security)
- [ ] Address cross-functional review comments
- [ ] Update all documents to "Approved" status
- [ ] Create implementation readiness checklist
- [ ] Hand off to implementation teams

---

## Open Issues and Blockers

### Current Blockers
None - SA work can proceed immediately.

### Risks
| Risk | Impact | Probability | Mitigation | Owner |
|------|--------|-------------|------------|-------|
| Database technology not chosen | Medium | Low | Recommend PostgreSQL; document alternatives | SA |
| Organizational security standards unclear | Low | Medium | Use industry best practices; align retroactively | SA |
| External system APIs not documented | Medium | Medium | Design generic integration; finalize when available | SA |

### Open Questions
| ID | Question | Status | Priority | Target Resolution |
|----|----------|--------|----------|-------------------|
| OQ-BR-002 | DB vs application enforcement for idempotency | ⏳ Pending | P0 | Week 3 |
| OQ-API-005 | Market data internal vs external | ⏳ Pending | P0 | Week 3 |
| OQ-API-003 | Historical observation replay support | ⏳ Pending | P1 | Week 3 |
| OQ-API-001 | Contract amendment support in v1.0 | ⏳ Pending | P1 | Week 3 |

---

## Deliverables Summary

### Phase 1 Deliverables (Weeks 1-2)
| Deliverable | File Path | Status | Target Date |
|-------------|-----------|--------|-------------|
| OpenAPI Specification | `interfaces/fcn-api-v1.0-openapi.yaml` | 📋 Not Started | Week 2 |
| Database Schema Design | `architecture/logical/fcn-database-schema.md` | 📋 Not Started | Week 2 |
| Database DDL Scripts | `architecture/logical/fcn-schema-v1.0.sql` | 📋 Not Started | Week 2 |
| Integration Architecture | `architecture/integration/fcn-integration-architecture.md` | 📋 Not Started | Week 2 |
| Security Architecture | `architecture/security/fcn-security-architecture.md` | 📋 Not Started | Week 2 |
| Security ADR | `design-decisions/adr-007-fcn-security-model.md` | 📋 Not Started | Week 2 |

### Phase 2 Deliverables (Weeks 2-3)
| Deliverable | File Path | Status | Target Date |
|-------------|-----------|--------|-------------|
| ADR-005: Idempotency | `design-decisions/adr-005-idempotency-implementation.md` | ⏳ Pending | Week 3 |
| ADR-006: Market Data | `design-decisions/adr-006-market-data-integration.md` | ⏳ Pending | Week 3 |
| Historical Replay Assessment | `assessments/historical-replay-assessment.md` | ⏳ Pending | Week 3 |

### Phase 3 Deliverables (Weeks 3-4)
All Phase 1 deliverables updated to v1.0 with Phase 2 decisions incorporated.

### Phase 4 Deliverables (Weeks 4-5)
All artifacts reviewed, approved, and ready for implementation.

---

## Timeline

```
Week 1:
├─ Policy Review ✅
├─ Onboarding ✅
├─ API Design Start
└─ Data Model Start

Week 2:
├─ API Design Complete
├─ Data Model Complete
├─ Integration Architecture
└─ Security Architecture

Week 3:
├─ Decision Making (ADR-005, ADR-006)
├─ Historical Replay Assessment
├─ Contract Amendment Assessment
└─ Refinement Start

Week 4:
├─ Refinement Complete
├─ Peer Review Submit
└─ Address Review Comments

Week 5:
├─ Cross-Functional Review
├─ Final Approval
└─ Implementation Handoff
```

---

## Success Metrics

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| Phase 1 deliverables on time | 100% | 0% (not started) | 🟢 On Track |
| ADRs documented | 3 (ADR-005, 006, 007) | 0 | 🟢 On Track |
| Decisions resolved | 4 (OQ-BR-002, OQ-API-005, OQ-API-003, OQ-API-001) | 0 | 🟢 On Track |
| Peer review pass rate | >90% | N/A | ⏳ Pending |
| Implementation blockers | 0 | 0 | ✅ Good |

---

## Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-10 | copilot | Initial work tracker created |
