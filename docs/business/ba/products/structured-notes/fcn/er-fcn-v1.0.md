---
title: FCN v1.0 Logical Entity-Relationship Model
doc_type: product-definition
status: Draft
version: 1.0.0
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
- `status`: Lifecycle status (Proposed, Active, Deprecated, Removed)
- `owner`: Responsible party
- `created_at`: Creation timestamp
- `updated_at`: Last update timestamp

### 2.2 Product_Version

Captures version-specific metadata and promotion state.

**Attributes:**
- `version_id` (PK): Unique version identifier
- `product_id` (FK → Product): Parent product
- `version`: Semantic version string
- `status`: Version-specific status
- `spec_file_path`: Relative path to specification document
- `parameter_schema_path`: Path to JSON schema
- `activation_checklist_ref`: Reference to checklist issue/document
- `release_date`: Date activated (if status = Active)
- `deprecated_date`: Date deprecated (if applicable)

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

**Attributes:**
- `trade_id` (PK): Unique trade identifier
- `product_id` (FK → Product): Product definition
- `branch_id` (FK → Branch): Applicable branch
- `trade_date`: Execution date
- `issue_date`: Issuance date
- `maturity_date`: Final maturity date
- `notional`: Notional amount (precision: 2 decimal places for standard currencies, 0 for zero-decimal currencies)
- `currency`: Settlement currency (ISO-4217)
- `observation_style`: Barrier style (american, european)
- `knock_in_barrier_pct`: KI barrier level
- `coupon_rate_pct`: Coupon rate per period
- `coupon_barrier_pct`: Coupon barrier threshold
- `is_memory_coupon`: Memory flag
- `recovery_mode`: Recovery mode
- `settlement_type`: Settlement type
- `fx_reference`: FX source (if cross-currency)
- `documentation_version`: Traceability version
- `created_at`: Record creation timestamp
- `updated_at`: Record update timestamp

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

## 4. Key Constraints

1. **Unique Product Version:** `(product_id, version)` must be unique.
2. **Unique Branch per Version:** `(product_id, version_id, branch_code)` must be unique.
3. **Observation Sequencing:** `(trade_id, observation_index)` must be unique and sequential.
4. **Cash Flow Referential Integrity:** `flow_type = 'coupon'` requires valid `decision_id`.
5. **Knock-In Singularity:** At most one `Knock_In_Trigger` per `trade_id`.
6. **Parameter Alias Chain:** `alias_of` must not form cycles.
7. **Test Vector Taxonomy Alignment:** `Test_Vector.branch_id` taxonomy must match parameters.

## 5. Indexing Strategy

### High-Priority Indexes:
- `Product.product_code`
- `Product_Version.(product_id, version)`
- `Trade.(product_id, branch_id, trade_date)`
- `Trade.maturity_date` (for lifecycle queries)
- `Observation.(trade_id, observation_date)`
- `Underlying_Level.(observation_id, asset_id)`
- `Cash_Flow.(trade_id, flow_date)`
- `Test_Vector.(product_id, version_id, normative)`

## 6. Data Integrity Rules

1. **Date Ordering:** `trade_date ≤ issue_date ≤ observation_dates[0] < maturity_date`
2. **Observation Completeness:** All `observation_dates` must have corresponding `Observation` records.
3. **Performance Calculation:** `performance_pct = (level / initial_level) - 1`
4. **Coupon Memory Logic:** If `is_memory_coupon = true`, `missed_coupons_accumulated` must be tracked.
5. **Knock-In Permanence:** Once `Knock_In_Trigger` exists, cannot be deleted (immutable event).

## 7. Migration Path

Initial migration (`m0001-fcn-baseline.sql`) creates:
- Core entities: Product, Product_Version, Branch, Parameter_Definition
- Taxonomy reference data
- Baseline FCN v1.0 branches
- Placeholder test vector linkage

Future migrations (`m0002`, `m0003`, ...) will:
- Extend entities for observations, underlying levels, cash flows
- Add computed views for performance analytics
- Introduce audit trail tables

## 8. Extensibility

### For Future Versions (v1.1+):
- Add `step_schedule` JSONB column to `Trade` for step-down features.
- Extend `Parameter_Definition` with `deprecated_in_version`, `removed_in_version` fields.
- Introduce `Autocall_Trigger` entity for autocall variants.

### For Multi-Product Support:
- Reuse `Product`, `Product_Version`, `Branch` schema.
- Introduce product-specific child tables inheriting from base trade structure.

## 9. Validation Hooks (Planned)

- **Phase 0 (Metadata):** Validate `Product_Version` status transitions, spec file existence.
- **Phase 1 (Taxonomy):** Ensure `Branch` taxonomy tuples are complete and unique.
- **Phase 2 (Parameters):** Validate `Trade` parameters against `Parameter_Definition` constraints.
- **Phase 3 (Test Vectors):** Ensure all `normative = true` vectors exist and pass.

## 10. Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-10 | siripong.s@yuanta.co.th | Initial ER model for FCN v1.0 baseline |
