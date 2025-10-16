# FCN Schema Consolidation - Verification Checklist

## Consolidated Migration File

**File**: `fcn_schema_consolidated_v1_1.sql`
**Location**: `docs/business/ba/products/structured-notes/fcn/migrations/`
**Lines**: 893
**Status**: ✅ Created

### Schema Objects Created

#### Tables (10 total)

1. ✅ `issuer_whitelist` - Approved issuer whitelist for counterparty risk (BR-022)
2. ✅ `fcn_template` - Template layer core metadata and product parameters
3. ✅ `fcn_template_underlying` - Underlying basket composition per template
4. ✅ `fcn_template_observation_schedule` - Observation dates for autocall/coupon
5. ✅ `fcn_trade` - Trade instances with full product parameters
6. ✅ `fcn_underlying` - Underlying assets linked to trades with initial fixings
7. ✅ `fcn_observation` - Observation data (spot levels, performance ratios)
8. ✅ `fcn_coupon_cashflow` - Coupon cashflow schedule and status tracking
9. ✅ `fcn_event` - Event tracking (knock-in, autocall, maturity)
10. ✅ `fcn_settlement` - Settlement tracking (cash or physical delivery)

#### Stored Procedures (1 total)

1. ✅ `usp_FCN_ValidateTemplate` - Comprehensive validation procedure with 6 rules

#### Triggers (1 total)

1. ✅ `trg_FCN_ValidateTemplate` - Automatic validation for Active templates

### Harmonized Naming

✅ `settlement_type` values:
- 'cash-settlement' (not 'cash')
- 'physical-settlement' (not 'physical-worst-of')
- Default: 'cash-settlement'

✅ `recovery_mode` values:
- 'par-recovery'
- 'proportional-loss'
- 'capital-at-risk' (DEFAULT - harmonized)

### Validation Rules Implemented

1. ✅ **Step-down monotonicity**: Knock-out barriers must be non-increasing
2. ✅ **Single maturity**: Only one observation can be marked as maturity
3. ✅ **Observation schedule**: Must have at least one observation
4. ✅ **Weight sum**: Underlying weights must sum to ~1.0 (tolerance 0.001)
5. ✅ **Capital-at-risk constraint**: recovery_mode='capital-at-risk' requires put_strike_pct NOT NULL
6. ✅ **Share delivery constraint**: share_delivery_enabled=1 requires:
   - settlement_type='physical-settlement'
   - recovery_mode='capital-at-risk'
   - put_strike_pct NOT NULL

### Constraints and Integrity

✅ Foreign keys:
- fcn_template_underlying → fcn_template (CASCADE)
- fcn_template_observation_schedule → fcn_template (CASCADE)
- fcn_trade → fcn_template (SET NULL)
- fcn_underlying → fcn_trade (CASCADE)
- fcn_observation → fcn_trade (CASCADE)
- fcn_coupon_cashflow → fcn_trade (CASCADE)
- fcn_event → fcn_trade (CASCADE)
- fcn_settlement → fcn_trade (CASCADE)
- fcn_settlement → fcn_event (SET NULL)

✅ CHECK constraints:
- chk_put_strike_ordering (template & trade)
- chk_autocall_logic_required (template & trade)
- chk_share_delivery_physical_settlement
- chk_capital_at_risk_requires_put_strike (template & trade)
- chk_trade_dates (date ordering)

✅ Indexes created for:
- Primary keys (all tables)
- Foreign keys (all relationships)
- Status columns (template, event, settlement)
- Date columns (observation, payment, settlement)
- Code/symbol columns (issuer, template, underlying)

### Idempotency

✅ IF NOT EXISTS guards for tables
✅ IF OBJECT_ID guards for procedures/triggers
✅ WARNING messages for existing objects
✅ Safe to run multiple times

### Syntax Verification

✅ BEGIN/END statements balanced (45/45)
✅ All CREATE statements complete
✅ GO batch separators properly placed
✅ Extended properties for documentation
✅ PRINT statements for execution tracking

## Legacy Migrations Archived

### Archive Directory

**Location**: `docs/business/ba/products/structured-notes/fcn/migrations/archive/`
**Status**: ✅ Created

### Archived Files (4 total)

1. ✅ `m0001-fcn-baseline.sql` - With OBSOLETE header
2. ✅ `m0002-fcn-v1_1-autocall-extension.sql` - With OBSOLETE header
3. ✅ `m0003-fcn-v1_1-put-strike-extension.sql` - With OBSOLETE header
4. ✅ `m0004-fcn-v1_1-capital-at-risk-recovery-mode.sql` - With OBSOLETE header

### OBSOLETE Header Format

Each archived file contains:
```sql
-- ============================================================================
-- OBSOLETE MIGRATION - DO NOT USE FOR NEW ENVIRONMENTS
-- ============================================================================
-- This migration has been SUPERSEDED by fcn_schema_consolidated_v1_1.sql
--
-- This file is retained for historical audit and reference purposes only.
-- DO NOT apply this migration to new database environments.
--
-- For new installations, use:
--   docs/business/ba/products/structured-notes/fcn/migrations/fcn_schema_consolidated_v1_1.sql
--
-- This legacy migration was part of the incremental migration series (m0001–m0004)
-- that has been consolidated into a single authoritative schema file.
--
-- Consolidation Date: 2025-10-16
-- Superseded By: fcn_schema_consolidated_v1_1.sql
-- ============================================================================
```

### Original Files Removed

✅ Removed from migrations root directory:
- m0001-fcn-baseline.sql
- m0002-fcn-v1_1-autocall-extension.sql
- m0003-fcn-v1_1-put-strike-extension.sql
- m0004-fcn-v1_1-capital-at-risk-recovery-mode.sql

## Documentation

### README.md

**Location**: `docs/business/ba/products/structured-notes/fcn/migrations/README.md`
**Status**: ✅ Created

**Contents**:
- Migration strategy for new vs existing environments
- Consolidation rationale
- Harmonized naming conventions
- Testing guidance
- Support information

## Template Layer Migrations (Unchanged)

**Location**: `docs/business/ba/products/structured-notes/fcn/migrations/sqlserver/`
**Status**: ✅ Not modified (as required)

Existing files preserved:
- m0009-fcn-template-schema.sql
- m0010-fcn-template-validation.sql
- m0011-fcn-trade-link-template.sql
- m0012-fcn-template-harmonization.sql
- m0012-fcn-template-harmonization-test.sql
- HARMONIZATION_SUMMARY.md

## Testing Recommendations

### Post-Merge Testing (Manual)

1. ⏳ **Clean database test**: Run consolidated script on empty SQL Server sandbox
   ```sql
   -- Verify tables exist
   SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES 
   WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME LIKE 'fcn%' OR TABLE_NAME = 'issuer_whitelist'
   ORDER BY TABLE_NAME;
   ```

2. ⏳ **Sample insertion test**: Run `fcn-sample-product-insertion.sql`
   ```sql
   -- Expected: Template created and activated
   -- Expected: Trade instantiated with underlyings
   ```

3. ⏳ **Canonical values test**: Query settlement_type
   ```sql
   SELECT DISTINCT settlement_type FROM fcn_template;
   -- Expected: 'cash-settlement', 'physical-settlement'
   ```

4. ⏳ **Default verification**: Check recovery_mode default
   ```sql
   SELECT name, definition 
   FROM sys.default_constraints 
   WHERE parent_object_id = OBJECT_ID('dbo.fcn_template')
     AND parent_column_id = (SELECT column_id FROM sys.columns 
                             WHERE object_id = OBJECT_ID('dbo.fcn_template') 
                             AND name = 'recovery_mode');
   -- Expected: 'capital-at-risk'
   ```

5. ⏳ **Validation test**: Attempt invalid template
   ```sql
   -- Test: physical-settlement with share_delivery_enabled=1 but missing put_strike_pct
   -- Expected: Validation failure with error message
   ```

## Acceptance Criteria Status

✅ New file fcn_schema_consolidated_v1_1.sql present with full consolidated schema (10 tables, 1 procedure, 1 trigger)
✅ Folder archive/ created containing four legacy migration files
✅ OBSOLETE headers added to archived files with original content preserved
✅ Original m0001–m0004 removed from root migrations folder
✅ Settlement_type constraint with canonical values present
✅ Recovery_mode default set to 'capital-at-risk'
✅ Template validation procedure enforces all required rules:
  - Step-down monotonicity
  - Single maturity
  - Weights sum ~1.0 tolerance
  - Capital-at-risk requires put_strike_pct
  - Share delivery logic
✅ Trigger only invokes validation for Active templates
✅ Script is idempotent with IF guards and warning messages
✅ README.md added summarizing consolidation

## Out of Scope (Confirmed)

✅ No modifications to business-rules.md
✅ No modifications to example scripts
✅ No modifications to m0012 harmonization migration
✅ No exposure limit enforcement added
✅ No autocall settlement procedure added

## Summary

**Status**: ✅ COMPLETE

All acceptance criteria met. The consolidated migration provides a single authoritative schema for FCN v1.1 with:
- Full data model (issuer whitelist, template layer, trade layer)
- Harmonized naming conventions
- Comprehensive validation logic
- Idempotent execution
- Clear documentation

Legacy migrations properly archived with OBSOLETE headers, original files removed from root directory.

**Ready for**: Post-merge manual testing on SQL Server sandbox environment.
