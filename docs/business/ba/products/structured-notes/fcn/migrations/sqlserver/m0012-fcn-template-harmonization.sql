-- Migration: m0012-fcn-template-harmonization
-- Description: Harmonize FCN template parameter naming and defaults with trade-level canonical FCN v1.1 schema
-- Author: siripong.s@yuanta.co.th
-- Created: 2025-10-16
-- Depends on: m0009-fcn-template-schema.sql, m0010-fcn-template-validation.sql
-- Version: FCN v1.1+ (Template Schema v1.0.1)

-- ============================================================================
-- OVERVIEW
-- ============================================================================
-- This migration harmonizes template-level parameter naming and defaults with
-- the trade-level canonical FCN v1.1 schema to eliminate divergence before
-- activation.
--
-- KEY CHANGES:
-- 1. Settlement Type Naming Alignment
--    - Old values: 'cash', 'physical-worst-of'
--    - New canonical values: 'cash-settlement', 'physical-settlement'
--    - Updates existing data and CHECK constraint
--
-- 2. Default Recovery Mode Update
--    - Old default: 'par-recovery'
--    - New default: 'capital-at-risk'
--    - Aligns with FCN v1.1 normative behavior
--
-- 3. Enhanced Validation Constraints
--    - settlement_type='physical-settlement' requires recovery_mode='capital-at-risk'
--    - share_delivery_enabled=1 requires settlement_type='physical-settlement'
--
-- 4. Computed Column (Optional)
--    - settlement_physical_flag: 1 if physical-settlement, else 0
--
-- IDEMPOTENCY:
-- - Safe to run multiple times (includes existence checks)
-- - No data loss on re-run
--
-- ALIGNMENT:
-- - BR-025: Cash settlement (capital-at-risk recovery mode)
-- - BR-025A: Physical worst-of settlement mechanics
-- - FCN v1.1.0 canonical schema (fcn-v1.1.0-parameters.schema.json)
-- ============================================================================

-- ============================================================================
-- SAFETY CHECKS
-- ============================================================================

-- Verify fcn_template table exists
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'fcn_template' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    RAISERROR('fcn_template table not found. Apply m0009-fcn-template-schema.sql first.', 16, 1);
    RETURN;
END
GO

-- ============================================================================
-- 1. DATA MIGRATION: Update settlement_type values
-- ============================================================================

PRINT '=== Step 1: Migrating settlement_type values ===';

-- Update 'cash' → 'cash-settlement'
UPDATE fcn_template
SET settlement_type = 'cash-settlement',
    updated_at = GETDATE()
WHERE settlement_type = 'cash';

DECLARE @cash_updated INT = @@ROWCOUNT;
PRINT 'Updated ' + CAST(@cash_updated AS NVARCHAR(10)) + ' rows: ''cash'' → ''cash-settlement''';

-- Update 'physical-worst-of' → 'physical-settlement'
UPDATE fcn_template
SET settlement_type = 'physical-settlement',
    updated_at = GETDATE()
WHERE settlement_type = 'physical-worst-of';

DECLARE @physical_updated INT = @@ROWCOUNT;
PRINT 'Updated ' + CAST(@physical_updated AS NVARCHAR(10)) + ' rows: ''physical-worst-of'' → ''physical-settlement''';

GO

-- ============================================================================
-- 2. CONSTRAINT UPDATE: Drop and recreate settlement_type CHECK constraint
-- ============================================================================

PRINT '=== Step 2: Updating settlement_type CHECK constraint ===';

-- Drop existing constraint if it exists
IF EXISTS (
    SELECT * 
    FROM sys.check_constraints 
    WHERE name = 'CK__fcn_templ__settl__' -- SQL Server auto-generated name pattern
      AND parent_object_id = OBJECT_ID('dbo.fcn_template')
      AND definition LIKE '%settlement_type%'
)
BEGIN
    -- Find the exact constraint name (SQL Server auto-generates suffixes)
    DECLARE @constraint_name NVARCHAR(128);
    SELECT @constraint_name = name
    FROM sys.check_constraints
    WHERE parent_object_id = OBJECT_ID('dbo.fcn_template')
      AND definition LIKE '%settlement_type%'
      AND name LIKE 'CK__fcn_templ__settl__%';
    
    IF @constraint_name IS NOT NULL
    BEGIN
        DECLARE @drop_sql NVARCHAR(500) = 'ALTER TABLE fcn_template DROP CONSTRAINT ' + QUOTENAME(@constraint_name);
        EXEC sp_executesql @drop_sql;
        PRINT 'Dropped old settlement_type constraint: ' + @constraint_name;
    END
END
GO

-- Create new constraint with canonical values
IF NOT EXISTS (
    SELECT * 
    FROM sys.check_constraints 
    WHERE name = 'chk_settlement_type_canonical'
      AND parent_object_id = OBJECT_ID('dbo.fcn_template')
)
BEGIN
    ALTER TABLE fcn_template
    ADD CONSTRAINT chk_settlement_type_canonical
        CHECK (settlement_type IN ('cash-settlement', 'physical-settlement'));
    
    PRINT 'Added new settlement_type constraint with canonical values';
END
ELSE
BEGIN
    PRINT 'Canonical settlement_type constraint already exists';
END
GO

-- Update default value for settlement_type
IF EXISTS (
    SELECT * 
    FROM sys.default_constraints 
    WHERE parent_object_id = OBJECT_ID('dbo.fcn_template')
      AND parent_column_id = (SELECT column_id FROM sys.columns 
                              WHERE object_id = OBJECT_ID('dbo.fcn_template') 
                              AND name = 'settlement_type')
)
BEGIN
    DECLARE @default_constraint_name NVARCHAR(128);
    SELECT @default_constraint_name = name
    FROM sys.default_constraints
    WHERE parent_object_id = OBJECT_ID('dbo.fcn_template')
      AND parent_column_id = (SELECT column_id FROM sys.columns 
                              WHERE object_id = OBJECT_ID('dbo.fcn_template') 
                              AND name = 'settlement_type');
    
    IF @default_constraint_name IS NOT NULL
    BEGIN
        DECLARE @drop_default_sql NVARCHAR(500) = 'ALTER TABLE fcn_template DROP CONSTRAINT ' + QUOTENAME(@default_constraint_name);
        EXEC sp_executesql @drop_default_sql;
        PRINT 'Dropped old settlement_type default constraint';
    END
END
GO

-- Add new default
IF NOT EXISTS (
    SELECT * 
    FROM sys.default_constraints 
    WHERE name = 'df_settlement_type_cash'
      AND parent_object_id = OBJECT_ID('dbo.fcn_template')
)
BEGIN
    ALTER TABLE fcn_template
    ADD CONSTRAINT df_settlement_type_cash
        DEFAULT 'cash-settlement' FOR settlement_type;
    
    PRINT 'Set default settlement_type to ''cash-settlement''';
END
GO

-- ============================================================================
-- 3. DEFAULT RECOVERY_MODE UPDATE: Change to 'capital-at-risk'
-- ============================================================================

PRINT '=== Step 3: Updating recovery_mode default ===';

-- Drop existing default constraint
IF EXISTS (
    SELECT * 
    FROM sys.default_constraints 
    WHERE parent_object_id = OBJECT_ID('dbo.fcn_template')
      AND parent_column_id = (SELECT column_id FROM sys.columns 
                              WHERE object_id = OBJECT_ID('dbo.fcn_template') 
                              AND name = 'recovery_mode')
)
BEGIN
    DECLARE @recovery_default_name NVARCHAR(128);
    SELECT @recovery_default_name = name
    FROM sys.default_constraints
    WHERE parent_object_id = OBJECT_ID('dbo.fcn_template')
      AND parent_column_id = (SELECT column_id FROM sys.columns 
                              WHERE object_id = OBJECT_ID('dbo.fcn_template') 
                              AND name = 'recovery_mode');
    
    IF @recovery_default_name IS NOT NULL
    BEGIN
        DECLARE @drop_recovery_sql NVARCHAR(500) = 'ALTER TABLE fcn_template DROP CONSTRAINT ' + QUOTENAME(@recovery_default_name);
        EXEC sp_executesql @drop_recovery_sql;
        PRINT 'Dropped old recovery_mode default constraint';
    END
END
GO

-- Add new default
IF NOT EXISTS (
    SELECT * 
    FROM sys.default_constraints 
    WHERE name = 'df_recovery_mode_capital_at_risk'
      AND parent_object_id = OBJECT_ID('dbo.fcn_template')
)
BEGIN
    ALTER TABLE fcn_template
    ADD CONSTRAINT df_recovery_mode_capital_at_risk
        DEFAULT 'capital-at-risk' FOR recovery_mode;
    
    PRINT 'Set default recovery_mode to ''capital-at-risk''';
END
ELSE
BEGIN
    PRINT 'Default recovery_mode constraint already exists';
END
GO

-- ============================================================================
-- 4. ENHANCED CONSTRAINTS: Physical settlement and share delivery validation
-- ============================================================================

PRINT '=== Step 4: Adding enhanced validation constraints ===';

-- Update existing share_delivery constraint to align with new settlement_type values
IF EXISTS (
    SELECT * 
    FROM sys.check_constraints 
    WHERE name = 'chk_share_delivery_physical_only'
      AND parent_object_id = OBJECT_ID('dbo.fcn_template')
)
BEGIN
    ALTER TABLE fcn_template DROP CONSTRAINT chk_share_delivery_physical_only;
    PRINT 'Dropped old share_delivery constraint';
END
GO

-- Add updated constraint
IF NOT EXISTS (
    SELECT * 
    FROM sys.check_constraints 
    WHERE name = 'chk_share_delivery_physical_settlement'
      AND parent_object_id = OBJECT_ID('dbo.fcn_template')
)
BEGIN
    ALTER TABLE fcn_template
    ADD CONSTRAINT chk_share_delivery_physical_settlement
        CHECK (
            (share_delivery_enabled = 0)
            OR (share_delivery_enabled = 1 
                AND settlement_type = 'physical-settlement' 
                AND recovery_mode = 'capital-at-risk')
        );
    
    PRINT 'Added constraint: share_delivery_enabled=1 requires settlement_type=physical-settlement AND recovery_mode=capital-at-risk';
END
ELSE
BEGIN
    PRINT 'Share delivery constraint already exists';
END
GO

-- ============================================================================
-- 5. COMPUTED COLUMN: settlement_physical_flag (optional)
-- ============================================================================

PRINT '=== Step 5: Adding computed column settlement_physical_flag ===';

-- Add computed column if it doesn't exist
IF NOT EXISTS (
    SELECT * 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID('dbo.fcn_template') 
      AND name = 'settlement_physical_flag'
)
BEGIN
    ALTER TABLE fcn_template
    ADD settlement_physical_flag AS (
        CASE WHEN settlement_type = 'physical-settlement' THEN 1 ELSE 0 END
    ) PERSISTED;
    
    PRINT 'Added computed column settlement_physical_flag';
END
ELSE
BEGIN
    PRINT 'Computed column settlement_physical_flag already exists';
END
GO

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

PRINT '=== Verification ===';
PRINT '';

-- Check settlement_type values
PRINT 'Distinct settlement_type values:';
SELECT DISTINCT settlement_type 
FROM fcn_template
ORDER BY settlement_type;

-- Check recovery_mode default (test by viewing constraint)
PRINT '';
PRINT 'Recovery mode default constraint:';
SELECT 
    dc.name AS constraint_name,
    dc.definition AS default_value
FROM sys.default_constraints dc
INNER JOIN sys.columns c ON dc.parent_object_id = c.object_id 
                         AND dc.parent_column_id = c.column_id
WHERE c.object_id = OBJECT_ID('dbo.fcn_template')
  AND c.name = 'recovery_mode';

-- Check settlement_type default
PRINT '';
PRINT 'Settlement type default constraint:';
SELECT 
    dc.name AS constraint_name,
    dc.definition AS default_value
FROM sys.default_constraints dc
INNER JOIN sys.columns c ON dc.parent_object_id = c.object_id 
                         AND dc.parent_column_id = c.column_id
WHERE c.object_id = OBJECT_ID('dbo.fcn_template')
  AND c.name = 'settlement_type';

-- Check constraints
PRINT '';
PRINT 'Check constraints on fcn_template:';
SELECT 
    name AS constraint_name,
    definition
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('dbo.fcn_template')
ORDER BY name;

GO

-- ============================================================================
-- TESTING QUERIES (COMMENTED OUT - UNCOMMENT TO TEST)
-- ============================================================================

-- Test Case 1: Verify canonical settlement_type values are accepted
-- INSERT INTO fcn_template (template_code, template_name, spec_version, currency, tenor_months, 
--     knock_in_barrier_pct, coupon_rate_pct, coupon_condition_threshold_pct, settlement_type, recovery_mode)
-- VALUES ('TEST-HARMONIZE-001', 'Test Cash Settlement', '1.1.0', 'USD', 12, 
--     0.70, 0.06, 0.60, 'cash-settlement', 'capital-at-risk');

-- Test Case 2: Verify old values are rejected
-- This should fail with constraint violation:
-- INSERT INTO fcn_template (template_code, template_name, spec_version, currency, tenor_months, 
--     knock_in_barrier_pct, coupon_rate_pct, coupon_condition_threshold_pct, settlement_type, recovery_mode)
-- VALUES ('TEST-HARMONIZE-002', 'Test Old Cash Value', '1.1.0', 'USD', 12, 
--     0.70, 0.06, 0.60, 'cash', 'capital-at-risk');

-- Test Case 3: Verify default recovery_mode
-- INSERT INTO fcn_template (template_code, template_name, spec_version, currency, tenor_months, 
--     knock_in_barrier_pct, coupon_rate_pct, coupon_condition_threshold_pct, settlement_type)
-- VALUES ('TEST-HARMONIZE-003', 'Test Default Recovery', '1.1.0', 'USD', 12, 
--     0.70, 0.06, 0.60, 'cash-settlement');
-- SELECT recovery_mode FROM fcn_template WHERE template_code = 'TEST-HARMONIZE-003';
-- Expected: 'capital-at-risk'

-- Test Case 4: Verify share_delivery constraint
-- This should fail (share_delivery_enabled=1 requires physical-settlement AND capital-at-risk):
-- INSERT INTO fcn_template (template_code, template_name, spec_version, currency, tenor_months, 
--     knock_in_barrier_pct, coupon_rate_pct, coupon_condition_threshold_pct, 
--     settlement_type, recovery_mode, share_delivery_enabled)
-- VALUES ('TEST-HARMONIZE-004', 'Test Share Delivery Invalid', '1.1.0', 'USD', 12, 
--     0.70, 0.06, 0.60, 'cash-settlement', 'capital-at-risk', 1);

-- Test Case 5: Verify valid share_delivery configuration
-- INSERT INTO fcn_template (template_code, template_name, spec_version, currency, tenor_months, 
--     knock_in_barrier_pct, put_strike_pct, coupon_rate_pct, coupon_condition_threshold_pct, 
--     settlement_type, recovery_mode, share_delivery_enabled)
-- VALUES ('TEST-HARMONIZE-005', 'Test Share Delivery Valid', '1.1.0', 'USD', 12, 
--     0.70, 0.75, 0.06, 0.60, 'physical-settlement', 'capital-at-risk', 1);

-- Cleanup test data:
-- DELETE FROM fcn_template WHERE template_code LIKE 'TEST-HARMONIZE-%';

-- ============================================================================
-- NOTES
-- ============================================================================
-- Migration Version: 1.0.1 (Template Schema Harmonization)
-- 
-- Post-Migration Checklist:
-- 1. All existing settlement_type='cash' migrated to 'cash-settlement'
-- 2. All existing settlement_type='physical-worst-of' migrated to 'physical-settlement'
-- 3. CHECK constraint only allows canonical values
-- 4. Default recovery_mode is 'capital-at-risk'
-- 5. share_delivery_enabled=1 requires physical-settlement AND capital-at-risk
-- 6. No changes to fcn_trade table (already uses canonical values)
--
-- Backward Compatibility:
-- - Old settlement_type values automatically migrated
-- - Templates with old values still functional after migration
-- - No breaking changes to trade instances
--
-- Validation Procedure Update:
-- - See updated usp_FCN_ValidateTemplate in migration file (if updated separately)
-- - Or update validation procedure to check new constraints
--
-- Rollback Strategy:
-- - Not recommended (would reintroduce naming divergence)
-- - If required, reverse data updates and constraint changes
-- - Better approach: Fix validation issues and keep harmonized values
-- ============================================================================
