---
title: FCN Schema Diff - v1.0 to v1.1
doc_type: technical-diff
status: Draft
version: 1.0.0
owner: siripong.s@yuanta.co.th
created: 2025-10-16
last_reviewed: 2025-10-16
classification: Internal
tags: [fcn, schema-diff, migration, v1.1]
related:
  - specs/fcn-v1.0.md
  - specs/fcn-v1.1.0.md
  - business-rules.md
  - manifest.yaml
  - migrations/m0002-fcn-v1_1-autocall-extension.sql
---

# FCN Schema Diff: v1.0 to v1.1

## Executive Summary

FCN v1.1.0 extends v1.0 with **autocall (knock-out) early redemption** capability and **issuer governance** support while maintaining full backward compatibility. All changes are **additive only** — no v1.0 parameters are removed, renamed, or have breaking constraint changes.

### Key Additions
- **Issuer parameter**: Required for v1.1.0 trades; supports counterparty risk management
- **Knock-out barrier**: Optional upward barrier triggering early redemption
- **Autocall logic**: Configuration for autocall trigger conditions
- **Observation frequency helper**: Informational field for schedule documentation

## 1. Parameter Changes

### 1.1 New Parameters (v1.1.0)

| Parameter Name | Type | Required | Default | Constraints | Purpose |
|----------------|------|----------|---------|-------------|---------|
| issuer | string | **yes** | - | 1-64 chars; must exist in approved whitelist | Issuer identifier for governance (BR-022) |
| knock_out_barrier_pct | decimal | no | null | 0 < x ≤ 1.30 | Upward barrier for early redemption trigger (BR-020) |
| auto_call_observation_logic | string | conditional | null | enum: "all-underlyings"; required if knock_out_barrier_pct present | Autocall condition logic (BR-021) |
| observation_frequency_months | integer | no | null | ≥ 1 | Informational: interval between observations |

### 1.2 Modified Parameters

**None**. All v1.0 parameters remain unchanged in name, type, and constraints.

### 1.3 Deprecated Parameters

**None**. All v1.0 parameters remain valid in v1.1.0.

### 1.4 Parameter Interaction Changes

| Interaction | v1.0 Behavior | v1.1.0 Behavior | Business Rule |
|-------------|---------------|-----------------|---------------|
| Coupon condition vs KO barrier | N/A (no KO barrier) | coupon_condition_threshold_pct is **independent** of knock_out_barrier_pct; can be ≤ KO barrier | BR-023 |
| Autocall dependency | N/A | If knock_out_barrier_pct present, auto_call_observation_logic **required** | JSON schema dependency |
| Issuer requirement | Not present | **Required** for v1.1.0 trades; optional/null for legacy v1.0 trades | BR-022 |

## 2. Business Rules Changes

### 2.1 New Business Rules

| Rule ID | Category | Description | Impact |
|---------|----------|-------------|--------|
| BR-020 | Validation | `0 < knock_out_barrier_pct <= 1.30` when present | Validates autocall barrier range |
| BR-021 | Business Logic | On observation date, if ALL underlyings close ≥ initial × knock_out_barrier_pct, redeem early (principal + due coupon) | Defines autocall trigger and payoff |
| BR-022 | Governance | Issuer must exist in approved issuer whitelist; mismatch blocks booking | Enforces counterparty risk control |
| BR-023 | Business Logic | coupon_condition_threshold_pct independent of knock_out_barrier_pct; KO evaluated prior to coupon condition | Clarifies precedence order |

### 2.2 Modified Business Rules

**None**. All existing BR-001 through BR-019 remain unchanged.

## 3. Data Model Changes

### 3.1 Table: `trade`

**New Columns** (all nullable except issuer requirements apply to v1.1.0+ trades only):

```sql
-- Issuer identifier
issuer VARCHAR(64)
  -- Required for v1.1.0 trades; NULL allowed for legacy v1.0 trades
  -- BR-022: Must exist in approved whitelist

-- Autocall barrier
knock_out_barrier_pct NUMERIC(7,6)
  -- Optional; range: 0 < x <= 1.30 (BR-020)
  -- Triggers early redemption when ALL underlyings exceed initial × this level

-- Autocall logic
auto_call_observation_logic VARCHAR(32)
  -- Conditional: required if knock_out_barrier_pct present
  -- Current enum: 'all-underlyings'
  -- BR-021: Defines trigger condition

-- Observation frequency helper
observation_frequency_months INTEGER
  -- Optional informational field
  -- Range: >= 1 if specified
```

**New Constraints**:

```sql
-- Range validation for knock_out_barrier_pct (BR-020)
CONSTRAINT chk_knock_out_barrier_range 
  CHECK (knock_out_barrier_pct IS NULL 
         OR (knock_out_barrier_pct > 0 AND knock_out_barrier_pct <= 1.30))

-- Enum validation for auto_call_observation_logic
CONSTRAINT chk_auto_call_logic_enum 
  CHECK (auto_call_observation_logic IS NULL 
         OR auto_call_observation_logic IN ('all-underlyings'))

-- Dependency: logic required when barrier present
CONSTRAINT chk_autocall_logic_dependency 
  CHECK ((knock_out_barrier_pct IS NULL AND auto_call_observation_logic IS NULL)
         OR (knock_out_barrier_pct IS NOT NULL AND auto_call_observation_logic IS NOT NULL))

-- Positive observation frequency
CONSTRAINT chk_observation_frequency_positive 
  CHECK (observation_frequency_months IS NULL 
         OR observation_frequency_months >= 1)
```

**New Indexes**:

```sql
-- Index for issuer whitelist validation and counterparty queries
CREATE INDEX idx_trade_issuer ON trade(issuer) 
  WHERE issuer IS NOT NULL;

-- Index for autocall product queries
CREATE INDEX idx_trade_autocall_feature 
  ON trade(knock_out_barrier_pct, auto_call_observation_logic) 
  WHERE knock_out_barrier_pct IS NOT NULL;
```

### 3.2 Table: `product_version`

**New Row**:
```sql
INSERT INTO product_version (version, status, spec_file_path, parameter_schema_path)
VALUES ('1.1.0', 'Proposed', 'specs/fcn-v1.1.0.md', 'schemas/fcn-v1.1.0-parameters.schema.json');
```

### 3.3 Table: `branch`

**New Branch**:
```sql
INSERT INTO branch (branch_code, description, step_feature)
VALUES ('fcn-base-nomem-autocall', 
        'No-memory coupon, autocall enabled, par-recovery, physical settlement',
        'autocall');
-- Taxonomy: down-in / physical-settlement / no-memory / autocall / par-recovery
```

### 3.4 Table: `parameter_definition`

**New Parameter Definitions** (4 rows):
- issuer (string, required)
- knock_out_barrier_pct (number, optional)
- auto_call_observation_logic (string, conditional)
- observation_frequency_months (integer, optional)

## 4. Payoff Logic Changes

### 4.1 Evaluation Sequence

**v1.0 Sequence** (each observation date):
1. Check coupon condition
2. Monitor knock-in breach
3. At maturity: apply par-recovery or proportional-loss

**v1.1.0 Sequence** (each observation date):
1. **Check autocall (KO) condition** ← NEW (highest precedence)
   - If triggered: redeem early (principal + due coupon), **cease further observations**
2. Check coupon condition (independent of KO barrier)
3. Monitor knock-in breach (continuous)
4. At maturity (if not auto-called): apply par-recovery or proportional-loss

### 4.2 Precedence Order (BR-023)

| Condition | v1.0 | v1.1.0 |
|-----------|------|--------|
| Autocall (KO) | N/A | **Priority 1** (evaluated first) |
| Coupon Eligibility | Priority 1 | **Priority 2** (evaluated after KO check) |
| Knock-In Monitoring | Priority 2 | Priority 3 (continuous monitoring) |
| Final Settlement | Priority 3 | Priority 4 (if not auto-called) |

### 4.3 Key Precedence Note

**BR-023 Clarification**: `coupon_condition_threshold_pct` is **independent** of `knock_out_barrier_pct`.

Example valid configuration:
- knock_out_barrier_pct = 1.10 (110%)
- coupon_condition_threshold_pct = 1.00 (100%)

This means:
- Autocall triggers if ALL underlyings ≥ 110% of initial
- Coupon pays if ALL underlyings ≥ 100% of initial
- If price is 105%: autocall does NOT trigger, but coupon DOES pay

## 5. JSON Schema Changes

### 5.1 Schema Identifier

- **v1.0**: `https://yuanta.co.th/schemas/structured-notes/fcn/v1.0/parameters`
- **v1.1**: `https://yuanta.co.th/schemas/structured-notes/fcn/v1.1/parameters`

### 5.2 Required Fields

**Added to required array**:
- `issuer` (required for v1.1.0 trades)

**v1.0 required fields** (unchanged):
- product_code, spec_version, trade_date, issue_date, maturity_date
- notional, currency, underlying_assets, observation_dates
- knock_in_barrier_pct, coupon_rate_pct, is_memory_coupon
- recovery_mode, settlement_type

### 5.3 New Properties

```json
{
  "issuer": {
    "type": "string",
    "minLength": 1,
    "maxLength": 64
  },
  "knock_out_barrier_pct": {
    "type": ["number", "null"],
    "minimum": 0,
    "maximum": 1.30,
    "exclusiveMinimum": true
  },
  "auto_call_observation_logic": {
    "type": ["string", "null"],
    "enum": ["all-underlyings", null]
  },
  "observation_frequency_months": {
    "type": ["integer", "null"],
    "minimum": 1
  }
}
```

### 5.4 New Dependency Constraint

```json
{
  "allOf": [
    {
      "if": {
        "properties": { "knock_out_barrier_pct": { "type": "number" } },
        "required": ["knock_out_barrier_pct"]
      },
      "then": {
        "properties": { "auto_call_observation_logic": { "type": "string" } },
        "required": ["auto_call_observation_logic"]
      }
    }
  ]
}
```

## 6. Migration Strategy

### 6.1 Database Migration

**Script**: `migrations/m0002-fcn-v1_1-autocall-extension.sql`

**Operations**:
1. Add 4 new columns to `trade` table (all nullable initially)
2. Add 4 CHECK constraints for validation
3. Create 2 optional indexes for performance
4. Insert v1.1.0 version metadata
5. Insert new branch definition
6. Insert parameter definitions

**Idempotency**: All operations use `IF NOT EXISTS` / `ON CONFLICT DO NOTHING`

**Rollback**: Not required (additive only); to remove v1.1.0, set product_version.status = 'Deprecated'

### 6.2 Data Migration Guidance

**For v1.0 Trades**:
- **issuer**: Can remain NULL (grandfathered) OR backfill with `'LEGACY_ISSUER_PLACEHOLDER'` if needed
- **autocall fields**: Remain NULL (no autocall feature)

**For v1.1.0 Trades**:
- **issuer**: REQUIRED at booking time; must pass BR-022 whitelist validation
- **autocall fields**: Optional; if knock_out_barrier_pct specified, auto_call_observation_logic REQUIRED

### 6.3 Application Migration

**Validation Layer**:
- Update JSON schema reference to v1.1.0 for new trades
- Add BR-020, BR-021, BR-022, BR-023 validation checks
- Implement issuer whitelist lookup (BR-022)

**Business Logic Layer**:
- Update payoff engine to evaluate autocall condition (BR-021)
- Implement early redemption flow
- Ensure coupon condition evaluation respects independence from KO barrier (BR-023)

**API/Interface Layer**:
- Expose issuer field in trade booking API (required)
- Expose autocall fields in trade booking API (optional)
- Update API documentation with precedence order

## 7. Backward Compatibility

### 7.1 Compatibility Matrix

| v1.0 Trade | v1.1.0 System | Compatible? | Notes |
|------------|---------------|-------------|-------|
| Existing v1.0 trade (no issuer) | v1.1.0 schema | ✅ Yes | issuer NULL allowed for legacy trades |
| Existing v1.0 trade (no autocall) | v1.1.0 payoff engine | ✅ Yes | Autocall fields NULL = no autocall feature |
| New v1.0 trade (v1.0 schema) | v1.1.0 system | ✅ Yes | v1.0 schema still valid; issuer may be required by policy |
| v1.1.0 trade (with issuer) | v1.0 system | ❌ No | v1.0 system does not recognize issuer field |
| v1.1.0 trade (with autocall) | v1.0 system | ❌ No | v1.0 payoff engine does not support autocall |

### 7.2 No Breaking Changes

**Guaranteed**:
- No v1.0 parameters removed
- No v1.0 parameters renamed
- No v1.0 constraints made stricter
- No v1.0 data types changed
- No v1.0 semantic behavior altered (when autocall fields are NULL)

### 7.3 Forward Migration Path

v1.0 trades can be "upgraded" to v1.1.0 semantic by:
1. Backfilling issuer field (if required by policy)
2. Keeping autocall fields NULL (preserves v1.0 payoff behavior)
3. Updating documentation_version to "1.1.0" (optional)

## 8. Test Vector Changes

### 8.1 New Test Vectors

**v1.1.0 Normative Set**:
- `fcn-v1.1.0-nomem-autocall-baseline`: Standard autocall trigger scenario
- `fcn-v1.1.0-nomem-autocall-trigger`: Early autocall with memory coupons
- `fcn-v1.1.0-nomem-autocall-no-trigger-edge`: Near-miss scenario (proceeds to maturity)

### 8.2 v1.0 Test Vectors

**Status**: All v1.0 normative test vectors (N1-N5) remain valid and must pass under v1.1.0 system (with autocall fields NULL).

## 9. Open Questions & Future Enhancements

| ID | Question | Status | Resolution Target |
|----|----------|--------|-------------------|
| OQ-BR-005 | Should autocall trigger on equality (close == barrier) or only strictly greater? | Open | Before v1.1.0 activation |
| OQ-v1.1-001 | Should issuer be required for v1.0 trades during migration? | Open | Migration planning phase |
| OQ-v1.1-002 | Future autocall logic options: "any-underlying", "worst-of", custom basket? | Future | v1.2+ consideration |
| OQ-v1.1-003 | Autocall with memory coupon: pay all accrued or only current period? | Open | Test vector definition |

## 10. Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-10-16 | siripong.s | Initial schema diff document for v1.0 to v1.1 migration |

## 11. References

- [FCN v1.0 Specification](specs/fcn-v1.0.md)
- [FCN v1.1.0 Specification](specs/fcn-v1.1.0.md)
- [Business Rules](business-rules.md)
- [Manifest](manifest.yaml)
- [Migration Script m0002](migrations/m0002-fcn-v1_1-autocall-extension.sql)
- [JSON Schema v1.0](schemas/fcn-v1.0-parameters.schema.json)
- [JSON Schema v1.1](schemas/fcn-v1.1.0-parameters.schema.json)
