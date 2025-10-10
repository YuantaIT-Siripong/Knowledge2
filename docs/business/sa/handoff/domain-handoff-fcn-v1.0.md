---
title: FCN v1.0 Domain Handoff Package
doc_type: architecture
role_primary: SA
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
status: Draft
version: 1.0.2
created: 2025-10-10
last_reviewed: 2025-10-10
next_review: 2026-04-10
classification: Internal
tags: [fcn, handoff, domain-model, architecture, structured-notes]
related:
  - ../../ba/products/structured-notes/fcn/specs/fcn-v1.0.md
  - ../../ba/products/structured-notes/fcn/non-functional.md
  - ../../ba/products/structured-notes/fcn/er-fcn-v1.0.md
  - ../../ba/products/structured-notes/fcn/manifest.yaml
  - ../design-decisions/adr-002-product-doc-structure.md
  - ../design-decisions/adr-003-fcn-version-activation.md
  - ../design-decisions/adr-004-parameter-alias-policy.md
  - ../design-decisions/dec-011-notional-precision.md
---

# FCN v1.0 Domain Handoff Package

## 1. Overview and Scope

### 1.1 Purpose
This document serves as the domain handoff package from Business Analysis to Solution Architecture for the Fixed Coupon Note (FCN) v1.0 product. It consolidates business domain knowledge to enable engineering implementation with clear traceability to rules, specification, and governance artifacts.

### 1.2 Scope
**In Scope:**
- FCN v1.0 baseline specification (single/basket underlying, memory/no-memory coupons)
- Down-in (knock-in) barrier monitoring on discrete observation dates
- Physical settlement with par-recovery mode (normative)
- Parameter definitions and constraints
- Core business processes (trade capture, observation, coupon decision, settlement)
- Initial business rules and validation requirements
- Logical data model for persistence
- Integration touchpoints (market data, trade booking, settlement)

**Out of Scope:**
- Step-down/step-up barrier schedules (deferred to v1.1+)
- Advanced autocall or averaging features
- Continuous barrier monitoring
- Parameter alias lifecycle (introduced in v1.1+)
- Implementation-specific pricing algorithms
- UI/UX specifications

### 1.3 Target Audience
- Solution Architects (API & database design)
- Backend Engineers (implementation)
- Data Engineers (ETL & persistence)
- QA Engineers (test strategy)
- Product Owners (feature validation)

---

## 2. Stakeholders and Actors

| Role | Responsibilities | Contact | Interest Level |
|------|------------------|---------|----------------|
| Product Owner | Defines economic behavior, approves specification | siripong.s@yuanta.co.th | High |
| Business Analyst | Documents requirements, validates test vectors | siripong.s@yuanta.co.th | High |
| Solution Architect | Designs API & data model, defines integration | siripong.s@yuanta.co.th | High |
| Backend Engineer | Implements pricing engine & lifecycle processing | engineering@yuanta.co.th | High |
| Data Engineer | Implements persistence & reporting pipelines | data-engineering@yuanta.co.th | Medium |
| Risk Manager | Reviews calibration scenarios & stress tests | risk@yuanta.co.th | Medium |
| Compliance Officer | Validates regulatory alignment & audit trails | compliance@yuanta.co.th | Medium |
| QA Engineer | Validates test coverage & regression suite | qa@yuanta.co.th | High |
| Front Office Trader | Books trades, monitors positions | trading@yuanta.co.th | Medium |
| Middle Office Operations | Validates settlements & lifecycle events | operations@yuanta.co.th | Medium |

### System Actors
- **Trade Capture System**: Sources trade bookings
- **Market Data Provider**: Delivers underlying levels for observations
- **Pricing Engine**: Computes valuations and payoff scenarios
- **Settlement System**: Processes cash flows and physical deliveries
- **Reporting System**: Generates client statements and risk reports
- **Audit Trail System**: Records all lifecycle events for compliance

---

## 3. Glossary (FCN-Specific Terms)

| Term | Definition | Source | Notes |
|------|------------|--------|-------|
| FCN | Fixed Coupon Note - A structured note paying periodic fixed coupons contingent on barrier conditions | Product Spec | Core product acronym |
| Knock-In (KI) | Event triggered when underlying breaches barrier level, switching to recovery mode | Product Economics | Also called "barrier breach" |
| Memory Coupon | Feature allowing unpaid coupons to accrue and pay later when conditions are met | Product Spec | Accumulator mechanism |
| Par Recovery | Recovery mode returning 100% of notional_amount at maturity despite KI event | Product Spec | Normative for v1.0 baseline |
| Proportional Loss | Recovery mode delivering underlying assets proportionally to breach level | Product Spec | Non-normative in v1.0 |
| Physical Settlement | Delivery of underlying assets rather than cash equivalent | Product Spec | Normative for v1.0 |
| Barrier Monitoring | Process of checking underlying levels against KI barrier on observation dates | Product Spec | Discrete only in v1.0 |
| Discrete Monitoring | Barrier evaluated only on scheduled observation dates (v1.0 in-scope) | Product Spec | Normative monitoring type |
| Continuous Monitoring | Barrier monitored continuously throughout life (deferred to v1.1+) | Product Spec | Future enhancement |
| Observation Date | Scheduled date for evaluating coupon conditions and barrier breaches | Product Spec | Excludes maturity unless explicit |
| Coupon Condition | Threshold requirement (all underlyings >= coupon_condition_threshold_pct * initial) for coupon payment | Product Spec | ALL underlying logic |
| Redemption Barrier | Final barrier level determining par redemption eligibility at maturity | Product Spec | Distinct from KI barrier |
| Branch | Taxonomy-specific payoff variant (e.g., base-mem, base-nomem) | Governance | Used for variant classification |
| Normative Test Vector | Required test case for version promotion from Proposed to Active | ADR-003 | Quality gate artifact |
| Parameter Schema | JSON Schema defining trade parameters, types, and constraints | Technical | Validation contract |
| Documentation Version | Traceability anchor linking trade to specification version | Product Spec | Audit requirement |

---

## 4. Conceptual Domain Model

### 4.1 Domain Entities (Mermaid Diagram)

```mermaid
erDiagram
    PRODUCT ||--o{ PRODUCT_VERSION : has
    PRODUCT_VERSION ||--o{ BRANCH : defines
    PRODUCT_VERSION ||--o{ PARAMETER_DEFINITION : specifies
    BRANCH ||--o{ TRADE : instantiates
    TRADE ||--o{ UNDERLYING_ASSET : references
    TRADE ||--o{ OBSERVATION : schedules
    OBSERVATION ||--o{ UNDERLYING_LEVEL : captures
    OBSERVATION ||--o{ COUPON_DECISION : triggers
    COUPON_DECISION ||--o{ CASH_FLOW : generates
    TRADE ||--o{ CASH_FLOW : produces
    TRADE ||--o{ TEST_VECTOR : validates
    
    PRODUCT {
        string product_id PK
        string product_code
        string product_name
        string product_family
        string status
        string owner
        datetime created_at
    }
    
    PRODUCT_VERSION {
        string version_id PK
        string product_id FK
        string version
        string status
        string spec_file_path
        string parameter_schema_path
        string activation_checklist_ref
        date release_date
    }
    
    BRANCH {
        string branch_id PK
        string product_id FK
        string version_id FK
        string branch_code
        string barrier_type
        string settlement
        string coupon_memory
        string recovery_mode
    }
    
    PARAMETER_DEFINITION {
        string parameter_id PK
        string version_id FK
        string parameter_name
        string parameter_type
        boolean required
        json constraints
        string description
    }
    
    TRADE {
        string trade_id PK
        string product_id FK
        string branch_id FK
        date trade_date
        date issue_date
        date maturity_date
        decimal notional_amount  // canonical parameter
        string currency
        decimal knock_in_barrier_pct
        decimal coupon_rate_pct
        boolean is_memory_coupon
        string recovery_mode
        string documentation_version
    }
    
    UNDERLYING_ASSET {
        string asset_id PK
        string trade_id FK
        string symbol
        decimal initial_level
        decimal weight
        string asset_type
    }
```

(Other entities unchanged.)

### 4.2 Key Domain Concepts

**Product Lifecycle:**
- Product → Product_Version → Branch → Trade
- Status progression: Proposed → Active → Deprecated → Removed
- Version promotion requires activation checklist completion

**Trade Lifecycle:**
- Trade Booking → Observation Processing → Coupon Decision → Cash Flow Generation → Settlement
- Barrier monitoring occurs on each observation date
- KI event triggers recovery mode switch

**Coupon Logic:**
- Memory: Unpaid coupons accumulate, paid when conditions satisfied
- No-Memory: Each period independent, missed coupons lost
- Condition: All underlyings must stay above coupon_condition_threshold_pct

**Settlement Modes:**
- Physical: Deliver underlying assets (normative for v1.0)
- Cash: Pay cash equivalent (non-normative)

### 4.3 Enumeration Definitions (v1.0 Scope)
(Enumeration subsections identical to previous version; unchanged.)

---

## 5. Core Processes

### 5.1 Trade Capture Process
(unchanged)

### 5.2 Observation Processing
(unchanged except parameter naming already aligned)

### 5.3 Coupon Decision Process (updated formula)

**Business Rules:**
- BR-008: Memory coupon accumulates up to memory_carry_cap_count (if set)
- BR-009: coupon_amount = (accrued_unpaid + 1) * notional_amount * coupon_rate_pct
- BR-010: Payment date from coupon_payment_dates schedule

### 5.4 Maturity Settlement Process
(unchanged; conceptual references to principal can use "notional" generically.)

---

## 6. Initial Business Rules Table

| Rule ID | Category | Description | Source | Owner | Priority | Status |
|---------|----------|-------------|--------|-------|----------|--------|
| BR-001 | Validation | trade_date ≤ issue_date < maturity_date | Spec §3 | BA | P0 | Draft |
| BR-002 | Validation | All initial_levels > 0 | Spec §3 | BA | P0 | Draft |
| BR-003 | Validation | 0 < knock_in_barrier_pct < redemption_barrier_pct ≤ 1.0 | Spec §3 | BA | P0 | Draft |
| BR-004 | Validation | documentation_version must match active product version | Governance | BA | P1 | Draft |
| BR-005 | KI Logic | KI triggered if ANY underlying closes ≤ initial × knock_in_barrier_pct | Spec §5 | BA | P0 | Draft |
| BR-006 | Coupon Logic | Coupon condition satisfied if ALL underlyings close ≥ initial × coupon_condition_threshold_pct | Spec §5 | BA | P0 | Draft |
| BR-007 | Observation | Each observation date processed exactly once (idempotent) | Technical | SA | P0 | Draft |
| BR-008 | Coupon Logic | Memory accumulation capped at memory_carry_cap_count (if set) | Spec §5 | BA | P1 | Draft |
| BR-009 | Coupon Calc | coupon_amount = (accrued_unpaid + 1) * notional_amount * coupon_rate_pct | Spec §5 | BA | P0 | Draft |
| BR-010 | Coupon Timing | Payment date from coupon_payment_dates array, indexed by observation | Spec §3 | BA | P0 | Draft |
| BR-011 | Settlement | Par recovery returns 100% of notional_amount at maturity (KI irrelevant) | Spec §2 | BA | P0 | Draft |
| BR-012 | Settlement | Physical settlement delivers pro-rata underlying units if KI & proportional-loss | Spec §2 | BA | P1 | Draft |
| BR-013 | Settlement | Final coupon evaluated separately from redemption logic | Spec §5 | BA | P1 | Draft |
| BR-014 | Validation | Observation dates must be strictly increasing and < maturity_date | Spec §3 | BA | P0 | Draft |
| BR-015 | Validation | underlying_symbols array length = initial_levels array length | Spec §3 | BA | P0 | Draft |
| BR-016 | Data Integrity | Basket weights sum to 1.0 (if explicit; default equal-weight) | Technical | SA | P2 | Draft |
| BR-017 | Test Coverage | Normative test vectors required for Proposed → Active promotion | ADR-003 | SA | P0 | Draft |
| BR-018 | Versioning | Parameter schema changes require new product version | ADR-004 | SA | P1 | Draft |
| BR-019 | Validation | notional_amount precision per DEC-011: 2 decimals (standard), 0 (zero-decimal currencies) & > 0 | Spec §3 / DEC-011 | BA | P1 | Draft |

### Naming Consistency Note
Canonical parameter keys: `notional_amount`, `coupon_condition_threshold_pct`. Internally persisted monetary column may appear as Trade.notional; rule and validation contexts MUST use the canonical parameter names.

---

## 12. Next Steps After Merge

### 12.1 Immediate Follow-Up (Week 1-2)
- [x] **Populate Rule Sources & Owners**: Assigned in business-rules v1.0.3
- [x] **Resolve RQ-001**: Decimal precision for notional_amount parameter (DEC-011)
- [ ] **Resolve OQ-001**: Decimal precision for percentage parameters (coordinate with database team)
- [ ] **Resolve OQ-005**: Clarify memory_carry_cap_count = 0 semantics (consult product owner)
- [x] **Create Schema-to-Rule Mapping Table**: Implemented in business-rules mapping section

(Other subsections unchanged.)

## 13. Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-10 | siripong.s@yuanta.co.th | Initial handoff package creation with all required sections |
| 1.0.1 | 2025-10-10 | copilot | Added DEC-011 for notional precision, BR-019 validation rule, resolved RQ-001 open question |
| 1.0.2 | 2025-10-10 | copilot | Hygiene: canonical notional_amount & coupon_condition_threshold_pct naming; BR-009 formula alignment; checklist updates; added DEC-011 to related |

## 14. Appendices

### 14.1 References
- [FCN v1.0 Specification](../../ba/products/structured-notes/fcn/specs/fcn-v1.0.md)
- [FCN v1.0 Logical ER Model](../../ba/products/structured-notes/fcn/er-fcn-v1.0.md)
- [FCN v1.0 Manifest](../../ba/products/structured-notes/fcn/manifest.yaml)
- [FCN v1.0 Parameter Schema](../../ba/products/structured-notes/fcn/schemas/fcn-v1.0-parameters.schema.json)
- [Validator Roadmap](../../ba/products/structured-notes/fcn/validator-roadmap.md)

### 14.2 Acronyms
- **FCN**: Fixed Coupon Note
- **KI**: Knock-In
- **BA**: Business Analyst
- **SA**: Solution Architect
- **ADR**: Architecture Decision Record
- **ER**: Entity-Relationship
- **API**: Application Programming Interface
- **SLA**: Service Level Agreement
- **RTO**: Recovery Time Objective
- **RPO**: Recovery Point Objective
- **RBAC**: Role-Based Access Control
- **PII**: Personally Identifiable Information

### 14.3 Document Conventions
- **Must / Shall**: Mandatory requirement
- **Should**: Recommended, but not mandatory
- **May / Can**: Optional or permitted
- **TBD**: To Be Determined (awaiting input)
- **P0**: Critical priority (blocker)
- **P1**: High priority (important)
- **P2**: Medium priority (desirable)