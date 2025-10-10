---
title: FCN v1.0 Logical Entity-Relationship Model
doc_type: product-definition
status: Draft
version: 1.0.1
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-10
last_reviewed: 2025-10-10
next_review: 2026-04-10
classification: Internal
tags: [structured-notes, fcn, data-model, er-model]
related:
  - specs/fcn-v1.0.md
  - manifest.yaml
  - migrations/m0001-fcn-baseline.sql
  - ../../sa/design-decisions/dec-011-notional-precision.md
---

# FCN v1.0 Logical Entity-Relationship Model

## 1. Purpose

Defines the logical data model for Fixed Coupon Note (FCN) v1.0, establishing entities, relationships, and key attributes for persistence, validation, and reporting.

## 2. Entity Definitions

### 2.1 Product

Represents the product definition and versioning metadata.

**Attributes:**
- `product_id` (PK): Unique product identifier
- `product_code`: Product type code (e.g., "FCN")
- `product_name`: Human-readable name
- `product_family`: Classification (e.g., "structured-notes")
- `spec_version`: Semantic version (e.g., "1.0.0")
- `status`: Lifecycle status (enum: Draft, Proposed, Active, Deprecated, Removed)
- `owner`: Responsible party
- `created_at`: Creation timestamp
- `updated_at`: Last update timestamp

**Status Enumeration:**
- `Draft`: Initial specification development
- `Proposed`: Ready for activation review
- `Active`: Production-ready and approved for trading
- `Deprecated`: No longer recommended; existing trades continue
- `Removed`: Fully retired; no new trades allowed

### 2.2 Product_Version

Captures version-specific metadata and promotion state.

**Attributes:**
- `version_id` (PK): Unique version identifier
- `product_id` (FK → Product): Parent product
- `version`: Semantic version string
- `status`: Version-specific status (enum: Draft, Proposed, Active, Deprecated, Removed)
- `spec_file_path`: Relative path to specification document
- `parameter_schema_path`: Path to JSON schema
- `activation_checklist_ref`: Reference to checklist issue/document
- `release_date`: Date activated (if status = Active)
- `deprecated_date`: Date deprecated (if applicable)

**Status Enumeration:**
Same as Product status (Draft, Proposed, Active, Deprecated, Removed).
Status transition workflow: Draft → Proposed → Active → Deprecated → Removed

### 2.3 Branch

Defines taxonomy-specific payoff branches within a product version.

**Attributes:**
- `branch_id` (PK): Unique branch identifier
- `product_id` (FK → Product): Parent product
- `version_id` (FK → Product_Version): Applicable version
- `branch_code`: Short identifier (e.g., "fcn-base-mem")
- `description`: Human-readable branch description
- `barrier_type`: Taxonomy dimension (e.g., "down-in")
- `settlement`: Settlement mode (e.g., "physical-settlement")
- `coupon_memory`: Memory style (e.g., "memory")
- `step_feature`: Step behavior (e.g., "no-step")
- `recovery_mode`: Post-KI mode (e.g., "par-recovery")

### 2.4 Parameter_Definition

Defines parameter metadata for a product version.

**Attributes:**
- `parameter_id` (PK): Unique parameter identifier
- `version_id` (FK → Product_Version): Applicable version
- `parameter_name`: Parameter identifier (snake_case)
- `parameter_type`: Data type (string, number, boolean, date, array, object)
- `required`: Whether parameter is mandatory
- `default_value`: Default value (if applicable)
- `constraints`: JSON constraint specification
- `description`: Human-readable description
- `deprecated`: Whether parameter is deprecated
- `alias_of`: FK to superseded parameter (if aliased)

### 2.5 Trade

Represents an individual FCN trade instance.

**Attributes (updated):**
- `trade_id` (PK): Unique trade identifier
- `product_id` (FK → Product): Product definition
- `branch_id` (FK → Branch): Applicable branch
- `trade_date`: Execution date
- `issue_date`: Issuance date
- `maturity_date`: Final maturity date
- `notional` (source parameter: `notional_amount`; precision per DEC-011): Principal amount
- `currency`: Settlement currency (ISO-4217)
- `barrier_monitoring`: Monitoring style (enum: discrete) [replaces legacy `observation_style`]
- `knock_in_barrier_pct`: KI barrier level
- `coupon_rate_pct`: Coupon rate per period
- `coupon_condition_threshold_pct`: Coupon condition threshold (replaces legacy `coupon_barrier_pct`)
- `is_memory_coupon`: Memory flag
- `recovery_mode`: Recovery mode
- `settlement_type`: Settlement type
- `fx_reference`: FX source (if cross-currency)
- `documentation_version`: Traceability version
- `created_at`: Record creation timestamp
- `updated_at`: Record update timestamp

### 2.5.1 Attribute Naming Note
Legacy attribute names (`observation_style`, `coupon_barrier_pct`) have been aligned to specification terms (`barrier_monitoring`, `coupon_condition_threshold_pct`) in documentation version 1.0.1. No aliases are active (see ADR-004). Database schema SHOULD adopt updated column names before promotion to Proposed.

### 2.6 Underlying_Asset

Links trades to underlying assets with initial levels and weights.

**Attributes:**
- `asset_id` (PK): Unique asset link identifier
- `trade_id` (FK → Trade): Parent trade
- `symbol`: Asset identifier (ticker, ISIN)
- `initial_level`: Reference level at trade inception
- `weight`: Basket weight (for multi-asset; defaults to equal)
- `asset_type`: Classification (equity, index, commodity, etc.)

### 2.7 Observation

Records scheduled observation dates and events.

**Attributes:**
- `observation_id` (PK): Unique observation identifier
- `trade_id` (FK → Trade): Parent trade
- `observation_date`: Scheduled date
- `observation_index`: Sequential index (1, 2, 3, ...)
- `is_processed`: Whether observation has been evaluated
- `processed_at`: Evaluation timestamp

### 2.8 Underlying_Level

Captures observed underlying asset levels.

**Attributes:**
- `level_id` (PK): Unique level record identifier
- `observation_id` (FK → Observation): Parent observation
- `asset_id` (FK → Underlying_Asset): Asset reference
- `level`: Observed market level
- `performance_pct`: Performance vs. initial_level
- `recorded_at`: Data capture timestamp

### 2.9 Coupon_Decision

Records coupon payment decisions per observation.

**Attributes:**
- `decision_id` (PK): Unique decision identifier
- `observation_id` (FK → Observation): Parent observation
- `barrier_breached`: Whether coupon barrier was breached
- `coupon_paid`: Coupon amount paid
- `missed_coupons_accumulated`: Count of prior missed coupons paid (if memory)
- `notes`: Additional decision context

### 2.10 Knock_In_Trigger

Records knock-in event occurrence.

**Attributes:**
- `trigger_id` (PK): Unique trigger identifier
- `trade_id` (FK → Trade): Parent trade
- `observation_id` (FK → Observation): Triggering observation (null if continuous)
- `trigger_date`: Date of knock-in event
- `worst_performance_pct`: Worst underlying performance at trigger
- `trigger_mechanism`: Trigger type (discrete, continuous)

### 2.11 Cash_Flow

Captures all cash flows (coupons, redemption).

**Attributes:**
- `cash_flow_id` (PK): Unique cash flow identifier
- `trade_id` (FK → Trade): Parent trade
- `flow_type`: Type (coupon, redemption, fee)
- `flow_date`: Payment date
- `amount`: Cash amount
- `currency`: Payment currency
- `decision_id` (FK → Coupon_Decision): Source decision (if coupon)
- `notes`: Additional context

### 2.12 Test_Vector

Defines test cases for validation and regression.

**Attributes:**
- `vector_id` (PK): Unique test vector identifier
- `product_id` (FK → Product): Target product
- `version_id` (FK → Product_Version): Target version
- `branch_id` (FK → Branch): Target branch
- `vector_code`: Unique code (e.g., "fcn-v1.0-base-mem-baseline")
- `description`: Test scenario description
- `normative`: Whether test is part of normative set
- `parameters_json`: JSON parameters blob
- `market_scenario_json`: JSON market scenario blob
- `expected_outputs_json`: JSON expected outputs blob
- `tags`: Classification tags (array)
- `created_at`: Creation timestamp

## 3. Relationships

### 3.1 Core Product Hierarchy
```
Product (1) ──< (M) Product_Version (1) ──< (M) Branch
   │
   └──< (M) Trade ──> (1) Branch
```

### 3.2 Trade Lifecycle
```
Trade (1) ──< (M) Underlying_Asset
  │
  ├──< (M) Observation (1) ──< (M) Underlying_Level ──> (1) Underlying_Asset
  │             │
  │             ├──< (M) Coupon_Decision
  │             └──< (1) Knock_In_Trigger (optional)
  │
  └──< (M) Cash_Flow ──> (0..1) Coupon_Decision
```

### 3.3 Parameter Governance
```
Product_Version (1) ──< (M) Parameter_Definition
     │
     └──> (0..1) Parameter_Definition (alias_of)
```

### 3.4 Test Vector Coverage
```
Product_Version (1) ──< (M) Test_Vector ──> (1) Branch
```

## 4. Enumeration Definitions

This section defines all enumeration values used in the FCN v1.0 data model, marking which values are in-scope for v1.0 and which are deferred to future versions.

### 4.1 Product / Product_Version Status

**Enum Values:**

| Value | Description | Lifecycle Stage | v1.0 Status |
|-------|-------------|-----------------|-------------|
| Draft | Specification under development | Pre-production | **In-scope** |
| Proposed | Ready for activation review; awaiting approval | Pre-production | **In-scope** |
| Active | Production-ready; approved for trading | Production | **In-scope** |
| Deprecated | No longer recommended; existing trades continue | Phase-out | **In-scope** |
| Removed | Fully retired; no new trades allowed | Archived | **In-scope** |

**Status Transition Workflow:**
```
Draft → Proposed → Active → Deprecated → Removed
```

**Transition Rules:**
- Draft → Proposed: Requires activation checklist completion (see ADR-003)
- Proposed → Active: Requires governance approval and normative test vector validation
- Active → Deprecated: Manual deprecation notice with deprecation_date
- Deprecated → Removed: After grace period, all existing trades matured/settled

### 4.2 Trade Status (Lifecycle)

**Enum Values:**

| Value | Description | v1.0 Status | Notes |
|-------|-------------|-------------|-------|
| booked | Trade booked but not yet issued | **In-scope** | Initial state after trade capture |
| active | Trade issued and active | **In-scope** | Post-issue, pre-maturity |
| matured | Trade reached maturity date | **In-scope** | Awaiting final settlement |
| terminated | Trade terminated early (if supported) | Deferred to v1.1+ | Early termination feature |
| redeemed | Final settlement completed | **In-scope** | Terminal state |

**v1.0 Scope:**
- Supported: `booked`, `active`, `matured`, `redeemed`
- Deferred: `terminated` (early termination not supported in v1.0 baseline)

### 4.3 Barrier Monitoring Type

**Enum Values:**

| Value | Description | v1.0 Status | Notes |
|-------|-------------|-------------|-------|
| discrete | Barrier evaluated only on scheduled observation dates | **In-scope (normative)** | Only monitoring type supported in v1.0 |
| continuous | Barrier monitored continuously throughout life | Deferred to v1.1+ | Requires intraday market data infrastructure |

**v1.0 Constraint:** Only `discrete` monitoring supported. Continuous monitoring deferred to v1.1+.

### 4.4 Settlement Type

**Enum Values:**

| Value | Description | v1.0 Status | Notes |
|-------|-------------|-------------|-------|
| physical-settlement | Deliver underlying assets at maturity | **In-scope (normative)** | Baseline normative settlement mode |
| cash-settlement | Deliver cash equivalent at maturity | In-scope (non-normative) | Illustrative examples only |

**v1.0 Constraint:** `physical-settlement` is normative; `cash-settlement` non-normative (examples only).

### 4.5 Recovery Mode

**Enum Values:**

| Value | Description | v1.0 Status | Notes |
|-------|-------------|-------------|-------|
| par-recovery | Return 100% notional at maturity regardless of KI | **In-scope (normative)** | Baseline normative recovery mode |
| proportional-loss | Deliver underlying proportional to worst performance | In-scope (non-normative) | Illustrative examples only |

**v1.0 Constraint:** `par-recovery` is normative; `proportional-loss` non-normative (examples only).

### 4.6 Knock-In Condition

**Enum Values:**

| Value | Description | v1.0 Status | Notes |
|-------|-------------|-------------|-------|
| any-underlying-breach | KI triggered if any underlying breaches barrier | **In-scope** | Only condition supported in v1.0 |
| all-underlying-breach | KI triggered only if all underlyings breach | Deferred to v1.1+ | Future enhancement |
| worst-of | KI based on worst performing underlying | Deferred to v1.1+ | Future enhancement |

**v1.0 Constraint:** Only `any-underlying-breach` supported. Alternative conditions deferred.

### 4.7 Day Count Convention

**Enum Values:**

| Value | Description | v1.0 Status | Notes |
|-------|-------------|-------------|-------|
| ACT/365 | Actual days / 365 | **In-scope** | Default convention |
| ACT/360 | Actual days / 360 | **In-scope** | Alternative convention |
| 30/360 | 30 days per month / 360 days per year | Deferred to v1.1+ | Future enhancement |

**v1.0 Constraint:** `ACT/365` and `ACT/360` supported; default is `ACT/365`.

### 4.8 Cash Flow Type

**Enum Values:**

| Value | Description | v1.0 Status | Notes |
|-------|-------------|-------------|-------|
| coupon | Periodic coupon payment | **In-scope** | Standard coupon flow |
| redemption | Final principal redemption | **In-scope** | Maturity payment |
| fee | Administrative or structuring fee | Deferred to v1.1+ | Future enhancement |
| early-redemption | Early termination payment | Deferred to v1.1+ | Requires early termination feature |

**v1.0 Constraint:** Only `coupon` and `redemption` flow types supported.

## 5. Key Constraints

1. **Unique Product Version:** `(product_id, version)` must be unique.
2. **Unique Branch per Version:** `(product_id, version_id, branch_code)` must be unique.
3. **Observation Sequencing:** `(trade_id, observation_index)` must be unique and sequential.
4. **Cash Flow Referential Integrity:** `flow_type = 'coupon'` requires valid `decision_id`.
5. **Knock-In Singularity:** At most one `Knock_In_Trigger` per `trade_id`.
6. **Parameter Alias Chain:** `alias_of` must not form cycles.
7. **Test Vector Taxonomy Alignment:** `Test_Vector.branch_id` taxonomy must match parameters.

## 6. Indexing Strategy

### High-Priority Indexes:
- `Product.product_code`
- `Product_Version.(product_id, version)`
- `Trade.(product_id, branch_id, trade_date)`
- `Trade.maturity_date` (for lifecycle queries)
- `Observation.(trade_id, observation_date)`
- `Underlying_Level.(observation_id, asset_id)`
- `Cash_Flow.(trade_id, flow_date)`
- `Test_Vector.(product_id, version_id, normative)`

## 7. Data Integrity Rules

1. **Date Ordering:** `trade_date ≤ issue_date ≤ observation_dates[0] < maturity_date`
2. **Observation Completeness:** All `observation_dates` must have corresponding `Observation` records.
3. **Performance Calculation:** `performance_pct = (level / initial_level) - 1`
4. **Coupon Memory Logic:** If `is_memory_coupon = true`, `missed_coupons_accumulated` must be tracked.
5. **Knock-In Permanence:** Once `Knock_In_Trigger` exists, cannot be deleted (immutable event).

## 8. Migration Path

Initial migration (`m0001-fcn-baseline.sql`) creates:
- Core entities: Product, Product_Version, Branch, Parameter_Definition
- Taxonomy reference data
- Baseline FCN v1.0 branches
- Placeholder test vector linkage

Future migrations (`m0002`, `m0003`, ...) will:
- Extend entities for observations, underlying levels, cash flows
- Add computed views for performance analytics
- Introduce audit trail tables

## 9. Extensibility

### For Future Versions (v1.1+):
- Add `step_schedule` JSONB column to `Trade` for step-down features.
- Extend `Parameter_Definition` with `deprecated_in_version`, `removed_in_version` fields.
- Introduce `Autocall_Trigger` entity for autocall variants.

### For Multi-Product Support:
- Reuse `Product`, `Product_Version`, `Branch` schema.
- Introduce product-specific child tables inheriting from base trade structure.

## 10. Validation Hooks (Planned)

- **Phase 0 (Metadata):** Validate `Product_Version` status transitions, spec file existence.
- **Phase 1 (Taxonomy):** Ensure `Branch` taxonomy tuples are complete and unique.
- **Phase 2 (Parameters):** Validate `Trade` parameters against `Parameter_Definition` constraints.
- **Phase 3 (Test Vectors):** Ensure all `normative = true` vectors exist and pass.

## 11. Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-10 | siripong.s@yuanta.co.th | Initial ER model for FCN v1.0 baseline |
| 1.0.1 | 2025-10-10 | copilot | Hygiene: add DEC-011 link; rename observation_style→barrier_monitoring; coupon_barrier_pct→coupon_condition_threshold_pct; clarify notional source |
