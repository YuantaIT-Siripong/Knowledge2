---
title: FCN v1.0 API Integration Resources (BA Perspective)
doc_type: integration
role_primary: BA
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
status: Draft
version: 0.1.0
created: 2025-10-10
last_reviewed: 2025-10-10
next_review: 2026-04-10
classification: Internal
tags: [fcn, integration, api, business-analysis]
related:
  - specs/fcn-v1.0.md
  - ../../../sa/handoff/domain-handoff-fcn-v1.0.md
  - manifest.yaml
---

# FCN v1.0 API Integration Resources (BA Perspective)

## 1. Purpose

This document defines the conceptual API resources needed for Fixed Coupon Note (FCN) v1.0 operations from a Business Analysis perspective. It serves as input for Solution Architecture to design concrete API contracts, endpoints, and data schemas.

## 2. Scope

**In Scope:**
- Conceptual API resource identification
- Business purpose for each resource
- Minimal required fields based on FCN v1.0 specification
- Resource relationships and dependencies
- CRUD operations from business perspective

**Out of Scope:**
- Implementation-specific endpoint URLs (SA responsibility)
- Authentication/authorization mechanisms
- Technical API specifications (OpenAPI/Swagger)
- Performance/caching strategies
- API versioning strategy (covered in ADR-003)

## 3. API Resource Candidates

### 3.1 Contracts Resource

**Resource Name:** `/contracts`

**Business Purpose:**  
Represents FCN trade/contract lifecycle from booking through settlement. Central resource for managing FCN product instances.

**Business Operations:**
- **Create Contract:** Book new FCN trade with validated parameters
- **Retrieve Contract:** Get contract details and current state
- **Query Contracts:** Search/filter contracts by status, maturity, underlying, etc.
- **Update Contract State:** Record lifecycle transitions (not parameter amendments in v1.0)

**Minimal Required Fields:**

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| contract_id | string | Output | System-generated unique identifier | System |
| trade_date | date | Input | Date of trade agreement | Spec §3 |
| issue_date | date | Input | Settlement/inception date | Spec §3 |
| maturity_date | date | Input | Contract final maturity | Spec §3 |
| underlying_symbols | string[] | Input | Underlying instrument identifiers | Spec §3 |
| initial_levels | decimal[] | Input | Recorded initial spot/close per underlying | Spec §3 |
| notional_amount | decimal | Input | Face amount in currency units | Spec §3 |
| currency | string | Input | Settlement currency (ISO-4217) | Spec §3 |
| observation_dates | date[] | Input | Coupon & barrier observation schedule | Spec §3 |
| coupon_payment_dates | date[] | Input | Coupon payment dates | Spec §3 |
| coupon_rate_pct | decimal | Input | Period coupon rate (ratio form) | Spec §3 |
| is_memory_coupon | boolean | Input | Memory feature enabled flag | Spec §3 |
| memory_carry_cap_count | integer | Conditional | Memory accumulation cap (if is_memory_coupon=true) | Spec §3 |
| knock_in_barrier_pct | decimal | Input | KI barrier level as fraction of initial | Spec §3 |
| knock_in_condition | string | Input | KI condition logic (e.g., "any-underlying-breach") | Spec §3 |
| redemption_barrier_pct | decimal | Input | Final redemption barrier | Spec §3 |
| settlement_type | string | Input | Settlement method (physical-settlement, cash-settlement) | Spec §3 |
| coupon_condition_threshold_pct | decimal | Input | Coupon condition threshold | Spec §3 |
| recovery_mode | string | Input | Recovery branch (par-recovery, proportional-loss) | Spec §3 |
| documentation_version | string | Input | Traceability anchor (must match spec_version) | Spec §3 |
| contract_status | string | Output | Current lifecycle state (Active, Matured, Settled, Cancelled) | System |
| ki_triggered | boolean | Output | Whether KI event has occurred | Derived §4 |
| created_at | datetime | Output | Record creation timestamp | System |
| updated_at | datetime | Output | Last update timestamp | System |

**Business Rules:**
- BR-001: trade_date ≤ issue_date < maturity_date
- BR-002: All initial_levels > 0
- BR-003: 0 < knock_in_barrier_pct < redemption_barrier_pct ≤ 1.0
- BR-004: documentation_version must match active product version
- BR-014: observation_dates must be strictly increasing and < maturity_date
- BR-015: underlying_symbols array length = initial_levels array length

**Related Resources:**
- `/contracts/{id}/observations`
- `/contracts/{id}/coupons`
- `/contracts/{id}/settlement`
- `/contracts/{id}/cash-flows`

---

### 3.2 Observations Resource

**Resource Name:** `/contracts/{contract_id}/observations`

**Business Purpose:**  
Records and processes barrier and coupon condition observations at scheduled dates. Drives knock-in detection and coupon decision logic.

**Business Operations:**
- **Create Observation:** Record observation data for a specific date
- **Retrieve Observation:** Get observation details and evaluation results
- **List Observations:** Get all observations for a contract (with chronological ordering)

**Minimal Required Fields:**

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| observation_id | string | Output | System-generated unique identifier | System |
| contract_id | string | Input | Parent contract reference | FK |
| observation_date | date | Input | Scheduled observation date | Spec §3 |
| observation_index | integer | Output | Sequential observation number (0-based or 1-based) | Derived |
| underlying_levels | object[] | Input | Market levels per underlying at observation | Market Data |
| underlying_levels[].symbol | string | Input | Underlying identifier | Spec §3 |
| underlying_levels[].level | decimal | Input | Observed market level/close price | Market Data |
| underlying_levels[].performance_pct | decimal | Output | Level / initial_level ratio | Derived |
| ki_event_triggered | boolean | Output | Whether this observation triggered KI | Derived |
| coupon_condition_satisfied | boolean | Output | Whether coupon condition met | Derived |
| is_processed | boolean | Output | Processing completion flag | System |
| processed_at | datetime | Output | Processing timestamp | System |
| created_at | datetime | Output | Record creation timestamp | System |

**Business Rules:**
- BR-005: KI triggered if ANY underlying closes ≤ initial × knock_in_barrier_pct
- BR-006: Coupon condition satisfied if ALL underlyings close ≥ initial × coupon_condition_threshold_pct
- BR-007: Each observation date processed exactly once (idempotent)

**Related Resources:**
- `/contracts/{id}`
- `/contracts/{id}/coupons`
- `/market-data/underlyings`

---

### 3.3 Coupons Resource

**Resource Name:** `/contracts/{contract_id}/coupons`

**Business Purpose:**  
Manages coupon payment decisions based on observation results. Handles memory logic and accumulated unpaid coupons.

**Business Operations:**
- **Create Coupon Decision:** Record coupon decision after observation processing
- **Retrieve Coupon Decision:** Get specific coupon decision details
- **List Coupon Decisions:** Get all coupon decisions for a contract (chronological)
- **Query Payment Status:** Filter by paid/unpaid status

**Minimal Required Fields:**

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| decision_id | string | Output | System-generated unique identifier | System |
| contract_id | string | Input | Parent contract reference | FK |
| observation_id | string | Input | Associated observation reference | FK |
| observation_date | date | Output | Date of observation triggering decision | Derived |
| observation_index | integer | Output | Observation sequence number | Derived |
| condition_satisfied | boolean | Output | Whether coupon condition was met | Derived |
| accumulated_unpaid | integer | Output | Count of unpaid coupons carried forward (memory) | Derived |
| coupons_paid_count | integer | Output | Number of coupons paid in this decision | Derived |
| coupon_amount | decimal | Output | Total coupon payment amount | Derived |
| payment_date | date | Output | Scheduled payment date | Spec §3 |
| payment_status | string | Output | Payment state (Scheduled, Paid, Skipped) | System |
| created_at | datetime | Output | Decision creation timestamp | System |

**Business Rules:**
- BR-006: Coupon condition satisfied if all underlyings close ≥ initial × coupon_condition_threshold_pct
- BR-008: Memory accumulation capped at memory_carry_cap_count (if set)
- BR-009: coupon_amount = notional × coupon_rate_pct × coupons_paid_count
- BR-010: Payment date from coupon_payment_dates array, indexed by observation

**Related Resources:**
- `/contracts/{id}`
- `/contracts/{id}/observations`
- `/contracts/{id}/cash-flows`

---

### 3.4 Settlement Resource

**Resource Name:** `/contracts/{contract_id}/settlement`

**Business Purpose:**  
Provides maturity settlement instructions based on KI status, final redemption conditions, and recovery mode.

**Business Operations:**
- **Calculate Settlement:** Determine settlement instruction at/near maturity
- **Retrieve Settlement:** Get settlement details and status
- **Update Settlement Status:** Mark settlement executed

**Minimal Required Fields:**

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| settlement_id | string | Output | System-generated unique identifier | System |
| contract_id | string | Input | Parent contract reference | FK |
| maturity_date | date | Output | Contract maturity date | Spec §3 |
| ki_triggered | boolean | Output | Whether KI event occurred during lifecycle | Derived |
| final_redemption_condition_met | boolean | Output | Whether final underlyings above redemption_barrier | Derived |
| recovery_mode | string | Output | Applied recovery mode | Spec §3 |
| settlement_type | string | Output | Settlement method (physical/cash) | Spec §3 |
| settlement_instruction | string | Output | Instruction type (Return-Par, Deliver-Physical, Cash-Equivalent) | Derived |
| cash_amount | decimal | Conditional | Cash settlement amount (if applicable) | Derived |
| physical_delivery | object[] | Conditional | Physical delivery details (if applicable) | Derived |
| physical_delivery[].symbol | string | Output | Underlying to deliver | Spec §3 |
| physical_delivery[].units | decimal | Output | Number of units to deliver | Derived |
| settlement_status | string | Output | Settlement state (Pending, Instructed, Settled) | System |
| settled_at | datetime | Output | Settlement execution timestamp | System |
| created_at | datetime | Output | Record creation timestamp | System |

**Business Rules:**
- BR-011: Par recovery returns 100% notional at maturity (KI irrelevant)
- BR-012: Physical settlement delivers pro-rata underlying units if KI & proportional-loss
- BR-013: Final coupon evaluated separately from redemption logic

**Related Resources:**
- `/contracts/{id}`
- `/contracts/{id}/observations`
- `/contracts/{id}/cash-flows`

---

### 3.5 Parameters Validation Resource

**Resource Name:** `/parameters/validation`

**Business Purpose:**  
Validates FCN parameter sets against schema, constraints, and business rules before trade booking. Pre-booking validation service.

**Business Operations:**
- **Validate Parameters:** Check parameter completeness, types, ranges, and relationships
- **Retrieve Validation Rules:** Get current validation rule set for FCN v1.0

**Minimal Required Fields:**

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| validation_id | string | Output | System-generated request identifier | System |
| parameters | object | Input | Complete FCN parameter set to validate | Client |
| validation_status | string | Output | Overall status (Valid, Invalid, Warning) | Derived |
| errors | object[] | Output | Validation errors (blocking) | Derived |
| errors[].field | string | Output | Parameter name with error | Derived |
| errors[].error_code | string | Output | Error classification code | Derived |
| errors[].message | string | Output | Human-readable error description | Derived |
| warnings | object[] | Output | Validation warnings (non-blocking) | Derived |
| warnings[].field | string | Output | Parameter name with warning | Derived |
| warnings[].warning_code | string | Output | Warning classification code | Derived |
| warnings[].message | string | Output | Human-readable warning description | Derived |
| validated_at | datetime | Output | Validation timestamp | System |

**Validation Categories:**
- **Required Parameters:** Presence check (BR-014, BR-015)
- **Type Validation:** Data type conformance
- **Range Validation:** Percentage bounds (0 < knock_in_barrier_pct < redemption_barrier_pct ≤ 1.0) (BR-003)
- **Relationship Validation:** Date ordering (trade_date ≤ issue_date < maturity_date) (BR-001)
- **Constraint Validation:** Array length matching, positive values (BR-002)
- **Enum Validation:** settlement_type, recovery_mode, knock_in_condition
- **Conditional Validation:** memory_carry_cap_count required if is_memory_coupon=true

**Business Rules:**
- BR-001: trade_date ≤ issue_date < maturity_date
- BR-002: All initial_levels > 0
- BR-003: 0 < knock_in_barrier_pct < redemption_barrier_pct ≤ 1.0
- BR-014: observation_dates must be strictly increasing and < maturity_date
- BR-015: underlying_symbols array length = initial_levels array length
- BR-016: Basket weights sum to 1.0 (if explicit)

**Related Resources:**
- `/contracts` (POST contract after validation)
- `/parameters/schema` (get parameter schema)

---

### 3.6 Cash Flows Resource

**Resource Name:** `/contracts/{contract_id}/cash-flows`

**Business Purpose:**  
Tracks all cash movements related to a contract (coupons, redemption, fees). Supports reconciliation and accounting integration.

**Business Operations:**
- **Create Cash Flow:** Record new cash flow event
- **Retrieve Cash Flow:** Get specific cash flow details
- **List Cash Flows:** Get all cash flows for a contract (chronological)
- **Query by Type:** Filter by flow_type (Coupon, Redemption, Fee, etc.)

**Minimal Required Fields:**

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| cash_flow_id | string | Output | System-generated unique identifier | System |
| contract_id | string | Input | Parent contract reference | FK |
| flow_type | string | Input | Cash flow classification (Coupon, Redemption, Fee, Adjustment) | Business Logic |
| flow_date | date | Input | Scheduled/actual cash flow date | Derived |
| amount | decimal | Input | Cash flow amount (positive = inflow, negative = outflow) | Derived |
| currency | string | Input | Cash flow currency (ISO-4217) | Spec §3 |
| related_decision_id | string | Optional | Associated coupon decision (if flow_type=Coupon) | FK |
| related_settlement_id | string | Optional | Associated settlement (if flow_type=Redemption) | FK |
| payment_status | string | Output | Payment state (Scheduled, Paid, Cancelled) | System |
| paid_at | datetime | Output | Actual payment timestamp | System |
| created_at | datetime | Output | Record creation timestamp | System |

**Business Rules:**
- BR-009: Coupon amount = notional × coupon_rate_pct × coupons_paid_count
- BR-010: Payment date from coupon_payment_dates schedule

**Related Resources:**
- `/contracts/{id}`
- `/contracts/{id}/coupons`
- `/contracts/{id}/settlement`

---

### 3.7 Market Data Resource

**Resource Name:** `/market-data/underlyings`

**Business Purpose:**  
Provides underlying instrument market data (levels/prices) for observation processing. May be external integration point.

**Business Operations:**
- **Retrieve Current Levels:** Get latest market levels for specified underlyings
- **Retrieve Historical Level:** Get level at specific date/time
- **Bulk Retrieve:** Get levels for multiple underlyings simultaneously

**Minimal Required Fields:**

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| symbol | string | Input | Underlying identifier | Client |
| observation_date | date | Input | Date for level retrieval | Client |
| level | decimal | Output | Market level/close price | Market Data Provider |
| currency | string | Output | Price currency | Market Data Provider |
| data_source | string | Output | Market data provider identifier | System |
| recorded_at | datetime | Output | Data timestamp | Market Data Provider |

**Business Rules:**
- Data must be available by observation processing time (typically 18:00 GMT+7)
- Fallback sources required for data availability SLA

**Related Resources:**
- `/contracts/{id}/observations`

---

### 3.8 Parameter Schema Resource

**Resource Name:** `/parameters/schema`

**Business Purpose:**  
Provides JSON schema definition for FCN parameters. Supports client-side validation and API documentation.

**Business Operations:**
- **Retrieve Schema:** Get parameter schema for specified product/version
- **List Schemas:** Get available schemas (by product, version)

**Minimal Required Fields:**

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| schema_id | string | Output | Schema identifier | System |
| product_type | string | Output | Product code (e.g., "fcn") | System |
| spec_version | string | Output | Product specification version (e.g., "1.0.0") | Spec |
| schema | object | Output | JSON Schema definition | Spec §3 |
| created_at | datetime | Output | Schema creation timestamp | System |
| updated_at | datetime | Output | Last schema update timestamp | System |

**Related Resources:**
- `/parameters/validation`
- `/contracts` (POST contract with schema validation)

---

## 4. Resource Relationships

```
┌─────────────┐
│  Contracts  │ (Central Resource)
└──────┬──────┘
       │
       ├─────────────┐
       │             │
       ▼             ▼
┌────────────┐  ┌────────────┐
│Observations│  │  Coupons   │
└──────┬─────┘  └──────┬─────┘
       │               │
       └───────┬───────┘
               │
               ▼
         ┌──────────┐
         │Cash Flows│
         └──────────┘

┌─────────────┐
│ Settlement  │ (Maturity Event)
└──────┬──────┘
       │
       └──────────────┐
                      │
                      ▼
                ┌──────────┐
                │Cash Flows│
                └──────────┘

┌──────────────┐       ┌──────────────┐
│ Parameters   │       │   Market     │
│ Validation   │       │     Data     │
└──────┬───────┘       └──────┬───────┘
       │                      │
       └──────────┬───────────┘
                  │
                  ▼
            ┌──────────┐
            │Contracts │ (Creation)
            └──────────┘
```

**Key Relationships:**
- **Contract → Observations:** 1-to-Many (one contract has multiple observations)
- **Observation → Coupon Decision:** 1-to-1 (each observation generates one coupon decision)
- **Contract → Coupons:** 1-to-Many (via observations)
- **Contract → Settlement:** 1-to-1 (one settlement at maturity)
- **Contract → Cash Flows:** 1-to-Many (multiple cash flows: coupons, redemption)
- **Coupon Decision → Cash Flow:** 1-to-0..1 (decision may or may not generate cash flow)
- **Settlement → Cash Flow:** 1-to-1 (settlement generates redemption cash flow)
- **Market Data → Observations:** Many-to-Many (market data feeds observation processing)
- **Parameters Validation → Contract:** Supporting service for pre-booking validation

---

## 5. Integration Touchpoints

### 5.1 External Systems

| System | Integration Type | Direction | Resources Involved | Frequency |
|--------|------------------|-----------|-------------------|-----------|
| Trade Capture System | REST API / Message Queue | Inbound | `/contracts`, `/parameters/validation` | Real-time (trade booking) |
| Market Data Provider | REST API / FIX | Inbound | `/market-data/underlyings` | Daily (observation dates) |
| Settlement System | Message Queue / File | Outbound | `/contracts/{id}/settlement`, `/contracts/{id}/cash-flows` | T+2 after decisions |
| Reporting System | Database Replication / ETL | Outbound | All resources | Daily EOD |
| Reference Data | REST API | Inbound | `/market-data/underlyings` (metadata) | On-demand |
| Audit Trail System | Message Queue | Outbound | All resources (lifecycle events) | Real-time |

### 5.2 Internal Workflows

**Trade Booking Flow:**
1. Client → `/parameters/validation` (validate parameters)
2. If valid → Client → `POST /contracts` (create contract)
3. System → Contract created, observation schedule generated
4. System → Event published (trade booked)

**Observation Processing Flow:**
1. System → Scheduler triggers observation date
2. System → `/market-data/underlyings` (fetch levels)
3. System → `POST /contracts/{id}/observations` (record observation)
4. System → Evaluate KI and coupon conditions
5. System → `POST /contracts/{id}/coupons` (create coupon decision)
6. If coupon paid → System → `POST /contracts/{id}/cash-flows` (record cash flow)

**Maturity Settlement Flow:**
1. System → Scheduler triggers maturity date
2. System → `GET /contracts/{id}` (retrieve contract state)
3. System → `GET /contracts/{id}/observations` (retrieve final observations)
4. System → `POST /contracts/{id}/settlement` (calculate settlement)
5. System → `POST /contracts/{id}/cash-flows` (record redemption cash flow)
6. System → Event published (settlement instruction)

---

## 6. Non-Functional Requirements (API Level)

### 6.1 Performance
- **Contract Creation:** < 500ms p95
- **Observation Processing:** < 1s per contract
- **Query Operations:** < 200ms p95
- **Batch Processing:** 10,000 trades/day throughput

### 6.2 Data Quality
- **Parameter Validation:** JSON Schema + business rule validation at API gateway
- **Idempotency:** Observation processing must be idempotent (BR-007)
- **Referential Integrity:** Foreign key validation (contract_id, observation_id)
- **Audit Trail:** All mutations logged with correlation IDs

### 6.3 Availability
- **API Uptime:** 99.9% during market hours
- **Data Availability:** Market data by 18:00 GMT+7 on observation dates
- **Fallback:** Graceful degradation for market data unavailability

---

## 7. Open Questions

| ID | Question | Impact | Owner | Target Date |
|----|----------|--------|-------|-------------|
| OQ-API-001 | Should contract amendments be supported in v1.0 (PUT /contracts/{id})? | API scope, data model | BA/SA | 2025-10-17 |
| OQ-API-002 | Is bulk contract creation needed (POST /contracts with array)? | API design, performance | BA | 2025-10-17 |
| OQ-API-003 | Should historical observation replay be supported for backdated trades? | API complexity, data processing | SA | 2025-10-22 |
| OQ-API-004 | What level of granularity for cash flow filtering (by date range, type, status)? | API design, query performance | BA | 2025-10-17 |
| OQ-API-005 | Should market data resource be internal service or external integration? | Architecture, data sovereignty | SA | 2025-10-22 |

---

## 8. Next Steps

1. **SA Review:** Solution Architecture to review resource candidates and provide technical feasibility assessment
2. **API Design:** SA to create concrete API specifications (OpenAPI/Swagger) based on these resources
3. **Data Modeling:** SA to design database schema aligned with resources
4. **Prototype:** Build prototype endpoints for `/contracts` and `/parameters/validation`
5. **Integration Planning:** Define integration contracts with external systems (market data, settlement)
6. **Testing Strategy:** Define API test scenarios aligned with normative test vectors

---

## 9. References

- **FCN v1.0 Specification:** `specs/fcn-v1.0.md`
- **Domain Handoff Package:** `../../../sa/handoff/domain-handoff-fcn-v1.0.md`
- **Business Rules:** Domain Handoff §6
- **Logical Data Model:** Domain Handoff §7
- **Core Processes:** Domain Handoff §5
- **ADR-003:** FCN Version Activation & Promotion Workflow
- **Parameter Schema:** `schemas/fcn-v1.0-parameters.schema.json`

---

## 10. Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1.0 | 2025-10-10 | siripong.s@yuanta.co.th | Initial draft: API resource candidate list for FCN v1.0 operations |
