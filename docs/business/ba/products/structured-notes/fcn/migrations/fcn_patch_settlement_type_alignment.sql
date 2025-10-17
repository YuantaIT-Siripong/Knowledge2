-- ============================================================================
-- Migration: fcn_patch_settlement_type_alignment.sql
-- Description: Patch migration to align fcn_settlement.settlement_type with canonical values
-- Author: copilot
-- Created: 2025-10-17
-- Version: Patch 1.1.1
-- Applies To: Databases with fcn_schema_consolidated_v1_1.sql applied
-- ============================================================================
--
-- BACKGROUND:
-- After PR #54 consolidation, fcn_settlement.settlement_type constraint allowed
-- ('cash', 'physical', 'mixed'), which conflicts with canonical values used in
-- fcn_template and fcn_trade: ('cash-settlement', 'physical-settlement').
--
-- This divergence breaks:
-- - Joins between settlement and trade/template layers
-- - Analytics queries expecting consistent naming
-- - Validation assumptions
--
-- OBJECTIVES:
-- 1. Migrate existing data to canonical values:
--    - 'cash' -> 'cash-settlement'
--    - 'physical' -> 'physical-settlement'
--    - 'mixed' -> deterministic mapping based on share delivery fields
-- 2. Drop old CHECK constraint
-- 3. Recreate constraint with canonical values: ('cash-settlement', 'physical-settlement')
-- 4. Add index on settlement_type if not present
-- 5. Update extended property documentation
--
-- MIGRATION POLICY FOR 'mixed':
-- - If delivery_shares IS NOT NULL -> 'physical-settlement'
-- - Else -> 'cash-settlement'
--
-- IDEMPOTENCY:
-- - Safe to run multiple times
-- - Checks for existing canonical values before migration
-- - Skips if constraint already using canonical values
--
-- USAGE:
-- Run after fcn_schema_consolidated_v1_1.sql on databases with legacy data
-- ============================================================================

SET NOCOUNT ON;
PRINT '=== FCN Patch: Settlement Type Alignment ===';
PRINT 'Starting at: ' + CONVERT(NVARCHAR(30), GETDATE(), 120);
GO

-- ============================================================================
-- STEP 1: Pre-Migration Validation
-- ============================================================================

PRINT '';
PRINT 'Step 1: Pre-Migration Validation';

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'fcn_settlement' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    PRINT 'ERROR: fcn_settlement table does not exist. Please apply fcn_schema_consolidated_v1_1.sql first.';
    RAISERROR('fcn_settlement table not found', 16, 1);
    RETURN;
END

-- Check if patch already applied by looking for canonical constraint
DECLARE @constraint_exists BIT = 0;

IF EXISTS (
    SELECT 1 
    FROM sys.check_constraints cc
    INNER JOIN sys.tables t ON cc.parent_object_id = t.object_id
    WHERE t.name = 'fcn_settlement'
      AND cc.definition LIKE '%cash-settlement%'
      AND cc.definition LIKE '%physical-settlement%'
)
BEGIN
    SET @constraint_exists = 1;
END

IF @constraint_exists = 1
BEGIN
    PRINT 'INFO: Canonical settlement_type constraint already exists. Patch may have been applied previously.';
    PRINT 'Checking data for any non-canonical values...';
    
    IF EXISTS (
        SELECT 1 FROM fcn_settlement 
        WHERE settlement_type NOT IN ('cash-settlement', 'physical-settlement')
    )
    BEGIN
        PRINT 'WARNING: Found non-canonical settlement_type values despite canonical constraint.';
        PRINT 'Proceeding with data migration...';
    END
    ELSE
    BEGIN
        PRINT 'SUCCESS: All settlement_type values are already canonical. No action needed.';
        PRINT 'Patch execution complete (no changes required).';
        RETURN;
    END
END
ELSE
BEGIN
    PRINT 'INFO: Old constraint detected. Proceeding with migration...';
END
GO

-- ============================================================================
-- STEP 2: Data Migration
-- ============================================================================

PRINT '';
PRINT 'Step 2: Migrating settlement_type values to canonical format';

-- Check for existing non-canonical values
DECLARE @legacy_count INT;
DECLARE @cash_count INT;
DECLARE @physical_count INT;
DECLARE @mixed_count INT;

SELECT @legacy_count = COUNT(*) 
FROM fcn_settlement 
WHERE settlement_type NOT IN ('cash-settlement', 'physical-settlement');

SELECT @cash_count = COUNT(*) FROM fcn_settlement WHERE settlement_type = 'cash';
SELECT @physical_count = COUNT(*) FROM fcn_settlement WHERE settlement_type = 'physical';
SELECT @mixed_count = COUNT(*) FROM fcn_settlement WHERE settlement_type = 'mixed';

PRINT 'Found legacy values:';
PRINT '  - cash: ' + CAST(ISNULL(@cash_count, 0) AS NVARCHAR(10));
PRINT '  - physical: ' + CAST(ISNULL(@physical_count, 0) AS NVARCHAR(10));
PRINT '  - mixed: ' + CAST(ISNULL(@mixed_count, 0) AS NVARCHAR(10));
PRINT '  - Total non-canonical: ' + CAST(ISNULL(@legacy_count, 0) AS NVARCHAR(10));

IF @legacy_count > 0
BEGIN
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Migrate 'cash' -> 'cash-settlement'
        UPDATE fcn_settlement
        SET settlement_type = 'cash-settlement',
            updated_at = GETDATE()
        WHERE settlement_type = 'cash';
        
        PRINT 'Migrated ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' rows: ''cash'' -> ''cash-settlement''';
        
        -- Migrate 'physical' -> 'physical-settlement'
        UPDATE fcn_settlement
        SET settlement_type = 'physical-settlement',
            updated_at = GETDATE()
        WHERE settlement_type = 'physical';
        
        PRINT 'Migrated ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' rows: ''physical'' -> ''physical-settlement''';
        
        -- Migrate 'mixed' -> deterministic mapping
        -- If share delivery present -> 'physical-settlement', else -> 'cash-settlement'
        UPDATE fcn_settlement
        SET settlement_type = CASE 
                WHEN delivery_shares IS NOT NULL THEN 'physical-settlement'
                ELSE 'cash-settlement'
            END,
            updated_at = GETDATE()
        WHERE settlement_type = 'mixed';
        
        DECLARE @mixed_migrated INT = @@ROWCOUNT;
        PRINT 'Migrated ' + CAST(@mixed_migrated AS NVARCHAR(10)) + ' rows: ''mixed'' -> deterministic mapping';
        
        IF @mixed_migrated > 0
        BEGIN
            DECLARE @mixed_to_physical INT;
            DECLARE @mixed_to_cash INT;
            
            -- Count how many 'mixed' went to each type (query before the update)
            SELECT @mixed_to_physical = COUNT(*)
            FROM fcn_settlement
            WHERE settlement_type = 'physical-settlement'
              AND delivery_shares IS NOT NULL;
            
            SELECT @mixed_to_cash = COUNT(*)
            FROM fcn_settlement
            WHERE settlement_type = 'cash-settlement'
              AND delivery_shares IS NULL;
            
            PRINT '  - ''mixed'' -> ''physical-settlement'': determined by delivery_shares NOT NULL';
            PRINT '  - ''mixed'' -> ''cash-settlement'': determined by delivery_shares IS NULL';
        END
        
        COMMIT TRANSACTION;
        PRINT 'Data migration completed successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'ERROR: Data migration failed.';
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        RETURN;
    END CATCH
END
ELSE
BEGIN
    PRINT 'No legacy values found. Skipping data migration.';
END
GO

-- ============================================================================
-- STEP 3: Constraint Migration
-- ============================================================================

PRINT '';
PRINT 'Step 3: Updating settlement_type CHECK constraint';

-- Find and drop the old constraint
DECLARE @constraint_name NVARCHAR(200);
DECLARE @drop_sql NVARCHAR(500);

SELECT @constraint_name = cc.name
FROM sys.check_constraints cc
INNER JOIN sys.tables t ON cc.parent_object_id = t.object_id
WHERE t.name = 'fcn_settlement'
  AND t.schema_id = SCHEMA_ID('dbo')
  AND cc.parent_column_id = (
      SELECT column_id 
      FROM sys.columns 
      WHERE object_id = OBJECT_ID('dbo.fcn_settlement') 
        AND name = 'settlement_type'
  );

IF @constraint_name IS NOT NULL
BEGIN
    -- Drop old constraint
    SET @drop_sql = 'ALTER TABLE dbo.fcn_settlement DROP CONSTRAINT ' + QUOTENAME(@constraint_name);
    EXEC sp_executesql @drop_sql;
    PRINT 'Dropped old constraint: ' + @constraint_name;
END
ELSE
BEGIN
    PRINT 'INFO: No existing settlement_type constraint found (table may be empty or constraint already removed).';
END

-- Create new canonical constraint
IF NOT EXISTS (
    SELECT 1 
    FROM sys.check_constraints cc
    INNER JOIN sys.tables t ON cc.parent_object_id = t.object_id
    WHERE t.name = 'fcn_settlement'
      AND cc.name = 'chk_fcn_settlement_type_canonical'
)
BEGIN
    ALTER TABLE dbo.fcn_settlement 
    ADD CONSTRAINT chk_fcn_settlement_type_canonical 
    CHECK (settlement_type IN ('cash-settlement', 'physical-settlement'));
    
    PRINT 'Created new constraint: chk_fcn_settlement_type_canonical';
    PRINT '  Allowed values: ''cash-settlement'', ''physical-settlement''';
END
ELSE
BEGIN
    PRINT 'INFO: Constraint chk_fcn_settlement_type_canonical already exists.';
END
GO

-- ============================================================================
-- STEP 4: Index Creation
-- ============================================================================

PRINT '';
PRINT 'Step 4: Adding index on settlement_type';

IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE object_id = OBJECT_ID('dbo.fcn_settlement') 
      AND name = 'idx_fcn_settlement_type'
)
BEGIN
    CREATE INDEX idx_fcn_settlement_type ON dbo.fcn_settlement(settlement_type);
    PRINT 'Created index: idx_fcn_settlement_type';
END
ELSE
BEGIN
    PRINT 'INFO: Index idx_fcn_settlement_type already exists.';
END
GO

-- ============================================================================
-- STEP 5: Update Extended Property
-- ============================================================================

PRINT '';
PRINT 'Step 5: Updating extended property documentation';

-- Update or add extended property
IF EXISTS (
    SELECT 1 
    FROM sys.extended_properties 
    WHERE major_id = OBJECT_ID('dbo.fcn_settlement') 
      AND minor_id = 0 
      AND name = 'MS_Description'
)
BEGIN
    EXEC sys.sp_updateextendedproperty 
        @name = N'MS_Description',
        @value = N'Settlement tracking for FCN trades (cash-settlement or physical-settlement)',
        @level0type = N'SCHEMA', @level0name = N'dbo',
        @level1type = N'TABLE', @level1name = N'fcn_settlement';
    
    PRINT 'Updated extended property for fcn_settlement table';
END
ELSE
BEGIN
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description',
        @value = N'Settlement tracking for FCN trades (cash-settlement or physical-settlement)',
        @level0type = N'SCHEMA', @level0name = N'dbo',
        @level1type = N'TABLE', @level1name = N'fcn_settlement';
    
    PRINT 'Added extended property for fcn_settlement table';
END
GO

-- ============================================================================
-- STEP 6: Post-Migration Verification
-- ============================================================================

PRINT '';
PRINT 'Step 6: Post-Migration Verification';

-- Verify distinct values
PRINT 'Current distinct settlement_type values:';
SELECT DISTINCT settlement_type 
FROM fcn_settlement 
ORDER BY settlement_type;

-- Verify constraint
PRINT '';
PRINT 'Settlement_type constraint definition:';
SELECT 
    cc.name AS constraint_name,
    cc.definition AS constraint_definition
FROM sys.check_constraints cc
INNER JOIN sys.tables t ON cc.parent_object_id = t.object_id
WHERE t.name = 'fcn_settlement'
  AND cc.name = 'chk_fcn_settlement_type_canonical';

-- Count records by settlement_type
DECLARE @canonical_cash_count INT;
DECLARE @canonical_physical_count INT;

SELECT @canonical_cash_count = COUNT(*) 
FROM fcn_settlement 
WHERE settlement_type = 'cash-settlement';

SELECT @canonical_physical_count = COUNT(*) 
FROM fcn_settlement 
WHERE settlement_type = 'physical-settlement';

PRINT '';
PRINT 'Record counts by canonical settlement_type:';
PRINT '  - cash-settlement: ' + CAST(ISNULL(@canonical_cash_count, 0) AS NVARCHAR(10));
PRINT '  - physical-settlement: ' + CAST(ISNULL(@canonical_physical_count, 0) AS NVARCHAR(10));

-- Verify no non-canonical values remain
DECLARE @non_canonical_count INT;

SELECT @non_canonical_count = COUNT(*) 
FROM fcn_settlement 
WHERE settlement_type NOT IN ('cash-settlement', 'physical-settlement');

IF @non_canonical_count > 0
BEGIN
    PRINT '';
    PRINT 'ERROR: Found ' + CAST(@non_canonical_count AS NVARCHAR(10)) + ' non-canonical settlement_type values!';
    RAISERROR('Post-migration verification failed: non-canonical values still exist', 16, 1);
    RETURN;
END
ELSE
BEGIN
    PRINT '';
    PRINT 'SUCCESS: All settlement_type values are canonical.';
END

-- ============================================================================
-- COMPLETION
-- ============================================================================

PRINT '';
PRINT '=== FCN Patch: Settlement Type Alignment Complete ===';
PRINT 'Completed at: ' + CONVERT(NVARCHAR(30), GETDATE(), 120);
PRINT '';
PRINT 'Summary:';
PRINT '- Data migrated to canonical values';
PRINT '- Constraint updated: chk_fcn_settlement_type_canonical';
PRINT '- Index added: idx_fcn_settlement_type';
PRINT '- Extended property updated';
PRINT '- Verification passed';
PRINT '';
PRINT 'Next Steps:';
PRINT '1. Verify distinct settlement_type values: SELECT DISTINCT settlement_type FROM fcn_settlement;';
PRINT '2. Test joins with fcn_trade and fcn_template using settlement_type';
PRINT '3. Update any application code expecting legacy values';
GO
