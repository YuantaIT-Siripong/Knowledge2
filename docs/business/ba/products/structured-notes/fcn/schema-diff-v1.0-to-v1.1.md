---
title: FCN Schema Diff - v1.0 to v1.1
doc_type: technical-diff
status: Draft
version: 1.0.1
owner: siripong.s@yuanta.co.th
created: 2025-10-16
last_reviewed: 2025-10-16
classification: Internal
tags: [fcn, schema-diff, migration, v1.1, capital-at-risk]
related:
  - specs/fcn-v1.0.md
  - specs/fcn-v1.1.0.md
  - business-rules.md
  - manifest.yaml
  - migrations/m0002-fcn-v1_1-autocall-extension.sql
  - migrations/m0003-fcn-v1_1-put-strike-extension.sql
---

# FCN Schema Diff: v1.0 to v1.1

## Executive Summary

FCN v1.1.0 extends v1.0 with **capital-at-risk settlement**, **autocall (knock-out) early redemption** capability, and **issuer governance** support while maintaining full backward compatibility. All changes are **additive only** — no v1.0 parameters are removed, renamed, or have breaking constraint changes.

### Key Additions
- **Capital-at-risk settlement**: put_strike_pct parameter and conditional loss logic (BR-024, BR-025); deprecates unconditional par recovery (BR-011)
- **Barrier monitoring type**: barrier_monitoring_type parameter for discrete vs continuous monitoring governance (BR-026)
- **Issuer parameter**: Required for v1.1.0 trades; supports counterparty risk management
- **Knock-out barrier**: Optional upward barrier triggering early redemption
- **Autocall logic**: Configuration for autocall trigger conditions
- **Observation frequency helper**: Informational field for schedule documentation

## Supersession Statement

As of 2025-10-17, FCN v1.1.0 is the normative specification for all NEW trades. FCN v1.0 is classified as Superseded and retained for historical audit only. Booking or template creation against v1.0 after this date requires explicit governance approval.

## 1. Parameter Changes

### 1.1 New Parameters (v1.1.0)

| Parameter Name | Type | Required | Default | Constraints | Purpose |
|----------------|------|----------|---------|-------------|---------|
| put_strike_pct | decimal | **yes** | - | 0 < x ≤ 1.0; must be > knock_in_barrier_pct | Put strike threshold for capital-at-risk settlement (BR-024, BR-025) |
| barrier_monitoring_type | string | no | 'discrete' | enum: "discrete", "continuous" | Barrier monitoring mechanism; only 'discrete' normative for v1.1 (BR-026) |
| issuer | string | **yes** | - | 1-64 chars; must exist in approved whitelist | Issuer identifier for governance (BR-022) |
| knock_out_barrier_pct | decimal | no | null | 0 < x ≤ 1.30 | Upward barrier for early redemption trigger (BR-020) |
| auto_call_observation_logic | string | conditional | null | enum: "all-underlyings"; required if knock_out_barrier_pct present | Autocall condition logic (BR-021) |
| observation_frequency_months | integer | no | null | ≥ 1 | Informational: interval between observations |

### 1.2 Modified Parameters

**None**. All v1.0 parameters remain unchanged in name, type, and constraints.

### 1.3 Deprecated Parameters

| Parameter Name | Status | Reason | Notes |
|----------------|--------|--------|-------|
| redemption_barrier_pct | Reserved / Legacy | Superseded by put_strike_pct in capital-at-risk mode | No payoff effect in v1.1 capital-at-risk settlement; kept for backward compatibility with v1.0 schema |

### 1.4 Parameter Interaction Changes

| Interaction | v1.0 Behavior | v1.1.0 Behavior | Business Rule |
|-------------|---------------|-----------------|---------------|
| Barrier ordering | knock_in_barrier_pct < redemption_barrier_pct | knock_in_barrier_pct < **put_strike_pct** ≤ 1.0 | BR-003 (updated), BR-024 |
| Settlement logic | Unconditional par recovery (100% notional at maturity regardless of KI) | Capital-at-risk: if KI triggered AND worst_of_final_ratio < put_strike_pct, loss = notional × (put_strike_pct - worst_of_final_ratio) / put_strike_pct; else 100% notional | BR-025 (replaces deprecated BR-011) |
| Coupon condition vs KO barrier | N/A (no KO barrier) | coupon_condition_threshold_pct is **independent** of knock_out_barrier_pct; can be ≤ KO barrier | BR-023 |
| Autocall dependency | N/A | If knock_out_barrier_pct present, auto_call_observation_logic **required** | JSON schema dependency |
| Issuer requirement | Not present | **Required** for v1.1.0 trades; optional/null for legacy v1.0 trades | BR-022 |
| Barrier monitoring | Implicit discrete only | Explicit barrier_monitoring_type; defaults to 'discrete'; 'continuous' reserved for future | BR-026 |

## 2. Business Rules Changes

### 2.1 New Business Rules

| Rule ID | Category | Description | Impact |
|---------|----------|-------------|--------|
| BR-020 | Validation | `0 < knock_out_barrier_pct <= 1.30` when present | Validates autocall barrier range |
| BR-021 | Business Logic | On observation date, if ALL underlyings close ≥ initial × knock_out_barrier_pct, redeem early (principal + due coupon) | Defines autocall trigger and payoff |
| BR-022 | Governance | Issuer must exist in approved issuer whitelist; mismatch blocks booking | Enforces counterparty risk control |
| BR-023 | Business Logic | coupon_condition_threshold_pct independent of knock_out_barrier_pct; KO evaluated prior to coupon condition | Clarifies precedence order |
| BR-024 | Validation | `0 < put_strike_pct ≤ 1.0` and `knock_in_barrier_pct < put_strike_pct` | Validates capital-at-risk threshold and ordering |
| BR-025 | Settlement (Capital-at-Risk) | At maturity: if KI triggered AND worst_of_final_ratio < put_strike_pct, loss = notional × (put_strike_pct - worst_of_final_ratio) / put_strike_pct; else 100% notional | Defines conditional principal loss at maturity |
| BR-026 | Validation | `barrier_monitoring_type` in ['discrete', 'continuous']; only 'discrete' normative for v1.1 | Validates barrier monitoring mechanism |

### 2.2 Modified Business Rules

| Rule ID | Change | Reason |
|---------|--------|--------|
| BR-003 | Updated ordering: now `knock_in_barrier_pct < put_strike_pct` (v1.1+); legacy: `knock_in_barrier_pct < redemption_barrier_pct` | Capital-at-risk settlement replaces redemption_barrier_pct with put_strike_pct |
| BR-011 | **DEPRECATED**: Marked as v1.0 legacy; excluded from normative coverage | Unconditional par recovery superseded by capital-at-risk settlement (BR-025) |

## 3. Data Model Changes

### 3.1 Table: `trade`

**New Columns** (all nullable except issuer and put_strike_pct requirements apply to v1.1.0+ trades only):

```sql
-- Capital-at-risk parameters (m0003)
put_strike_pct NUMERIC(7,6)
  -- Required for v1.1.0 trades; NULL allowed for legacy v1.0 trades
  -- BR-024: Range 0 < x <= 1.0; must be > knock_in_barrier_pct
  -- BR-025: Threshold for capital-at-risk loss calculation

barrier_monitoring_type VARCHAR(16)
  -- Default 'discrete' if NULL
  -- BR-026: Enum ['discrete', 'continuous']; only 'discrete' normative in v1.1

-- Issuer identifier (m0002)
issuer VARCHAR(64)
  -- Required for v1.1.0 trades; NULL allowed for legacy v1.0 trades
  -- BR-022: Must exist in approved whitelist

-- Autocall barrier (m0002)
knock_out_barrier_pct NUMERIC(7,6)
  -- Optional; range: 0 < x <= 1.30 (BR-020)
  -- Triggers early redemption when ALL underlyings exceed initial × this level

-- Autocall logic (m0002)
auto_call_observation_logic VARCHAR(32)
  -- Conditional: required if knock_out_barrier_pct present
  -- Current enum: 'all-underlyings'
  -- BR-021: Defines trigger condition

-- Observation frequency helper (m0002)
observation_frequency_months INTEGER
  -- Optional informational field
  -- Range: >= 1 if specified
```

**New Constraints**:

```sql
-- Capital-at-risk constraints (m0003)

-- Range validation for put_strike_pct (BR-024)
CONSTRAINT chk_put_strike_range 
  CHECK (put_strike_pct IS NULL 
         OR (put_strike_pct > 0 AND put_strike_pct <= 1.0))

-- Ordering: KI barrier < put strike (BR-024)
CONSTRAINT chk_ki_put_strike_relation 
  CHECK (put_strike_pct IS NULL 
         OR knock_in_barrier_pct IS NULL 
         OR knock_in_barrier_pct < put_strike_pct)

-- Enum validation for barrier_monitoring_type (BR-026)
CONSTRAINT chk_barrier_monitoring_type 
  CHECK (barrier_monitoring_type IS NULL 
         OR barrier_monitoring_type IN ('discrete', 'continuous'))

-- Autocall constraints (m0002)

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
- `put_strike_pct` (required for v1.1.0 trades)

**v1.0 required fields** (unchanged):
- product_code, spec_version, trade_date, issue_date, maturity_date
- notional, currency, underlying_assets, observation_dates
- knock_in_barrier_pct, coupon_rate_pct, is_memory_coupon
- recovery_mode, settlement_type

### 5.3 New Properties

```json
{
  "put_strike_pct": {
    "type": "number",
    "exclusiveMinimum": 0,
    "maximum": 1.0,
    "description": "Put strike threshold for capital-at-risk settlement; must be > knock_in_barrier_pct (BR-024, BR-025)"
  },
  "barrier_monitoring_type": {
    "type": "string",
    "enum": ["discrete", "continuous"],
    "default": "discrete",
    "description": "Barrier monitoring mechanism; only 'discrete' normative for v1.1 (BR-026)"
  },
  "issuer": {
    "type": "string",
    "minLength": 1,
    "maxLength": 64,
    "description": "Issuer identifier; must exist in approved whitelist (BR-022)"
  },
  "knock_out_barrier_pct": {
    "type": ["number", "null"],
    "minimum": 0,
    "maximum": 1.30,
    "exclusiveMinimum": true,
    "description": "Knock-out (autocall) barrier for early redemption (BR-020, BR-021)"
  },
  "auto_call_observation_logic": {
    "type": ["string", "null"],
    "enum": ["all-underlyings", null],
    "description": "Autocall trigger condition logic (BR-021)"
  },
  "observation_frequency_months": {
    "type": ["integer", "null"],
    "minimum": 1,
    "description": "Informational: monthly interval between observations"
  },
  "redemption_barrier_pct": {
    "type": "number",
    "description": "LEGACY: Reserved for v1.0 compatibility; no payoff effect in v1.1 capital-at-risk mode"
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

**Scripts**: 
- `migrations/m0002-fcn-v1_1-autocall-extension.sql` (autocall & issuer)
- `migrations/m0003-fcn-v1_1-put-strike-extension.sql` (capital-at-risk)

**m0002 Operations**:
1. Add 4 new columns to `trade` table (issuer, knock_out_barrier_pct, auto_call_observation_logic, observation_frequency_months)
2. Add 4 CHECK constraints for validation
3. Create 2 optional indexes for performance
4. Insert v1.1.0 version metadata
5. Insert new branch definition (fcn-base-nomem-autocall)
6. Insert parameter definitions

**m0003 Operations**:
1. Add 2 new columns to `trade` table (put_strike_pct, barrier_monitoring_type)
2. Add 3 CHECK constraints for validation (range, ordering, enum)
3. Backfill existing rows with put_strike_pct = 1.0 and barrier_monitoring_type = 'discrete' (optional, no behavioral change)
4. Insert new branch definitions (fcn-caprisk-nomem, fcn-caprisk-mem, fcn-caprisk-nomem-autocall)
5. Insert parameter definitions

**Idempotency**: All operations use `IF NOT EXISTS` / `ON CONFLICT DO NOTHING` / DO $$ blocks with guards

**Rollback**: Not required (additive only); to remove v1.1.0, set product_version.status = 'Deprecated'

### 6.2 Data Migration Guidance

**For v1.0 Trades**:
- **issuer**: Can remain NULL (grandfathered) OR backfill with `'LEGACY_ISSUER_PLACEHOLDER'` if needed
- **autocall fields**: Remain NULL (no autocall feature)
- **put_strike_pct**: Can remain NULL (legacy par recovery applies per BR-011) OR backfill with `1.0` (no behavioral change if set to 1.0)
- **barrier_monitoring_type**: Can remain NULL (defaults to 'discrete')

**For v1.1.0 Trades**:
- **issuer**: REQUIRED at booking time; must pass BR-022 whitelist validation
- **autocall fields**: Optional; if knock_out_barrier_pct specified, auto_call_observation_logic REQUIRED
- **put_strike_pct**: REQUIRED at booking time; must satisfy BR-024 (0 < x ≤ 1.0, > knock_in_barrier_pct)
- **barrier_monitoring_type**: Optional; defaults to 'discrete' if not specified; 'continuous' reserved for future

### 6.3 Application Migration

**Validation Layer**:
- Update JSON schema reference to v1.1.0 for new trades
- Add BR-020 through BR-026 validation checks
- Implement issuer whitelist lookup (BR-022)
- Validate put_strike_pct ordering relative to knock_in_barrier_pct (BR-024)
- Validate barrier_monitoring_type enum (BR-026)

**Business Logic Layer**:
- Update payoff engine to evaluate autocall condition (BR-021)
- Implement early redemption flow
- **Implement capital-at-risk settlement logic (BR-025)**: At maturity, calculate worst_of_final_ratio and apply conditional loss formula
- Ensure coupon condition evaluation respects independence from KO barrier (BR-023)
- Deprecate BR-011 unconditional par recovery for v1.1+ trades

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

**v1.1.0 Normative Set - Capital-at-Risk**:
- `fcn-v1.1-caprisk-nomem-baseline`: No KI, no loss (baseline scenario)
- `fcn-v1.1-caprisk-nomem-ki-no-loss`: KI triggered but worst_of_final ≥ put_strike_pct (no loss)
- `fcn-v1.1-caprisk-nomem-ki-loss`: KI triggered and worst_of_final < put_strike_pct (loss incurred)
- `fcn-v1.1-caprisk-nomem-autocall-preempt`: Autocall preempts capital-at-risk evaluation
- `fcn-v1.1-caprisk-mem-baseline`: Memory variant baseline
- `fcn-v1.1-caprisk-mem-accrual-release`: Memory accumulation and release
- `fcn-v1.1-caprisk-mem-ki-loss`: Memory variant with capital-at-risk loss

**v1.1.0 Normative Set - Autocall** (from initial v1.1 draft):
- `fcn-v1.1-autocall-trigger`: Standard autocall trigger scenario
- `fcn-v1.1-autocall-near-miss`: Near-miss scenario (proceeds to maturity)
- `fcn-v1.1-autocall-late-trigger`: Late-stage autocall trigger

### 8.2 v1.0 Test Vectors

**Status**: All v1.0 normative test vectors (N1-N5) remain valid and must pass under v1.1.0 system (with autocall and capital-at-risk fields NULL or backfilled with put_strike_pct=1.0).

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
| 1.0.1 | 2025-10-16 | copilot | Enhanced with capital-at-risk parameters (put_strike_pct, barrier_monitoring_type); added BR-024–026; updated settlement logic; deprecated BR-011 and redemption_barrier_pct; added m0003 migration; extended test vector list |
| 1.0.2 | 2025-10-17 | copilot | Formal supersession recorded (v1.0 -> Superseded; v1.1.0 normative). Added Supersession Statement section. |

## 11. References

- [FCN v1.0 Specification](specs/fcn-v1.0.md)
- [FCN v1.1.0 Specification](specs/fcn-v1.1.0.md)
- [Business Rules](business-rules.md)
- [Manifest](manifest.yaml)
- [Migration Script m0002](migrations/m0002-fcn-v1_1-autocall-extension.sql)
- [Migration Script m0003](migrations/m0003-fcn-v1_1-put-strike-extension.sql)
- [JSON Schema v1.0](schemas/fcn-v1.0-parameters.schema.json)
- [JSON Schema v1.1](schemas/fcn-v1.1.0-parameters.schema.json)
