# FCN Template Harmonization - Implementation Summary

## Overview

This document summarizes the harmonization updates implemented to align FCN template-level parameter naming and defaults with the trade-level canonical FCN v1.1 schema.

## Problem Statement

**Divergence Identified:**
- Template schema (m0009) used settlement_type values `'cash'` and `'physical-worst-of'`
- Trade/business rules used canonical values `'cash-settlement'` and `'physical-settlement'` (BR-025/BR-025A)
- Template default recovery_mode was `'par-recovery'` instead of v1.1 normative `'capital-at-risk'`
- Missing validation rules for capital-at-risk recovery mode requirements

## Solution Implemented

### 1. Migration Script (m0012-fcn-template-harmonization.sql)

**Purpose**: Idempotent migration to harmonize template schema with canonical FCN v1.1

**Key Changes**:
- **Data Migration**: Automated update of existing settlement_type values
  - `'cash'` → `'cash-settlement'`
  - `'physical-worst-of'` → `'physical-settlement'`
  
- **Constraint Updates**:
  - Dropped old CHECK constraint on settlement_type
  - Created new CHECK constraint accepting only canonical values
  - Updated DEFAULT for settlement_type to `'cash-settlement'`
  
- **Recovery Mode Default**: Changed from `'par-recovery'` to `'capital-at-risk'`

- **Enhanced Constraints**:
  - `share_delivery_enabled=1` now requires `settlement_type='physical-settlement'` AND `recovery_mode='capital-at-risk'`
  
- **Computed Column**: Added `settlement_physical_flag` for query optimization
  - Returns `1` for physical-settlement, `0` otherwise

**Statistics**:
- 418 lines of SQL code
- 12 batch separators (GO statements)
- Fully idempotent (safe to run multiple times)
- Includes verification queries

### 2. Test Suite (m0012-fcn-template-harmonization-test.sql)

**Purpose**: Comprehensive validation of migration changes

**Test Coverage**:
1. ✓ Canonical settlement_type values acceptance
2. ✓ Old settlement_type values rejection
3. ✓ Default recovery_mode verification
4. ✓ Invalid share_delivery combinations rejection
5. ✓ Valid share_delivery configurations acceptance
6. ✓ Computed column functionality
7. ✓ Post-migration data integrity

**Statistics**:
- 248 lines of SQL code
- 7 test cases with 21 assertions
- Auto-cleanup of test data

### 3. Validation Procedure Updates (m0010-fcn-template-validation.sql)

**New Validation Rules**:

**RULE 5**: recovery_mode='capital-at-risk' validation
```sql
IF @recovery_mode = 'capital-at-risk' AND @put_strike_pct IS NULL
BEGIN
    RAISERROR('recovery_mode=''capital-at-risk'' requires put_strike_pct to be NOT NULL', 16, 1);
END
```

**RULE 6**: share_delivery_enabled validation
```sql
IF @share_delivery_enabled = 1
BEGIN
    IF @settlement_type != 'physical-settlement' THEN RAISERROR(...)
    IF @put_strike_pct IS NULL THEN RAISERROR(...)
END
```

### 4. Documentation Updates

**README.md** (examples/sql/README.md):
- Version bumped: 1.0.0 → 1.0.1
- Added Version History table
- Added Harmonization Note section
- Updated all settlement_type references
- Added m0012 to migration execution workflow

**m0009-fcn-template-schema.sql**:
- Added note directing users to apply m0012 after m0009
- Documents harmonization path

## Execution Instructions

### Prerequisites
- SQL Server 2019+ (recommended)
- Migrations m0009, m0010, m0011 already applied
- Appropriate database permissions (CREATE TABLE, ALTER TABLE, etc.)

### Recommended Execution Sequence

```sql
-- 1. Apply base schema (if not already applied)
:r migrations/sqlserver/m0009-fcn-template-schema.sql
GO

-- 2. Apply validation procedures (if not already applied)
:r migrations/sqlserver/m0010-fcn-template-validation.sql
GO

-- 3. Apply template-trade link (if not already applied)
:r migrations/sqlserver/m0011-fcn-trade-link-template.sql
GO

-- 4. Apply harmonization migration (NEW)
:r migrations/sqlserver/m0012-fcn-template-harmonization.sql
GO

-- 5. Optional: Run test suite in DEV/SANDBOX
:r migrations/sqlserver/m0012-fcn-template-harmonization-test.sql
GO
```

### Verification Queries

After applying m0012, verify the changes:

```sql
-- Should return only 'cash-settlement' and 'physical-settlement'
SELECT DISTINCT settlement_type FROM fcn_template ORDER BY settlement_type;

-- Check default recovery_mode
SELECT dc.definition 
FROM sys.default_constraints dc
INNER JOIN sys.columns c ON dc.parent_object_id = c.object_id 
WHERE c.name = 'recovery_mode' 
  AND c.object_id = OBJECT_ID('fcn_template');
-- Expected: ('capital-at-risk')

-- Verify computed column
SELECT 
    template_code, 
    settlement_type, 
    settlement_physical_flag 
FROM fcn_template;
```

## Impact Analysis

### What Changed
✅ Template schema settlement_type values (data and constraints)  
✅ Default recovery_mode value  
✅ Validation procedure (2 new rules)  
✅ Documentation and examples  
✅ Schema constraints (share_delivery requirements)

### What Did NOT Change
❌ fcn_trade table (already uses canonical values)  
❌ Business rules documentation (already canonical)  
❌ Existing trade records  
❌ Template-trade relationships  
❌ Observation schedules  
❌ Underlying basket definitions

### Breaking Changes
**None** - This is a non-breaking migration:
- Old settlement_type values automatically migrated
- Existing templates remain functional
- Foreign key relationships preserved
- No data loss

### Backward Compatibility
- Templates created before migration: Data automatically updated
- Templates created after migration: Must use canonical values
- Applications using old values: Will receive constraint violation errors (expected behavior)

## Acceptance Criteria Status

| Criterion | Status | Notes |
|-----------|--------|-------|
| Migration file added (m0012) | ✅ Complete | 418 lines, idempotent |
| Validation procedure updated | ✅ Complete | RULE 5 & 6 added |
| README version bumped to 1.0.1 | ✅ Complete | With harmonization note |
| No trade record alterations | ✅ Verified | Only template schema affected |
| Only canonical settlement_type values | ✅ Enforced | Via CHECK constraint |
| Default recovery_mode='capital-at-risk' | ✅ Implemented | Via DEFAULT constraint |
| Share delivery invalid combos prevented | ✅ Enforced | Via CHECK constraint |

## Files Modified

| File | Type | Lines | Description |
|------|------|-------|-------------|
| m0012-fcn-template-harmonization.sql | Created | 418 | Migration script |
| m0012-fcn-template-harmonization-test.sql | Created | 248 | Test suite |
| m0010-fcn-template-validation.sql | Updated | +48 | Added RULE 5 & 6 |
| examples/sql/README.md | Updated | ~30 | Version 1.0.1 docs |
| m0009-fcn-template-schema.sql | Updated | +8 | Harmonization note |

## Rollback Strategy

**Not Recommended**: Rollback would reintroduce naming divergence.

If absolutely required:
1. Reverse data updates (manually update settlement_type values back)
2. Drop new constraints and recreate old ones
3. Revert recovery_mode default
4. Remove RULE 5 and RULE 6 from validation procedure

**Better Approach**: Fix any validation issues while keeping harmonized values.

## References

### Business Rules
- BR-025: Cash settlement (capital-at-risk recovery mode)
- BR-025A: Physical worst-of settlement mechanics
- BR-025B: Worst-of tie-break policy

### Schema Documents
- fcn-v1.1.0-parameters.schema.json: Canonical FCN v1.1 schema
- fcn-v1.1.0.md: FCN v1.1 specification
- settlement-physical-worst-of.md: Physical settlement guideline

### Related Migrations
- m0009: FCN template schema (base)
- m0010: Template validation procedures
- m0011: Template-trade linkage
- m0012: Template harmonization (this migration)

## Support

For questions or issues:
- **Owner**: siripong.s@yuanta.co.th
- **Repository**: YuantaIT-Siripong/Knowledge2
- **Issue Tag**: `fcn-template-harmonization`

---

**Implementation Date**: 2025-10-16  
**Version**: 1.0.1  
**Status**: Complete
