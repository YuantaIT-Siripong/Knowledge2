-- ============================================================================
-- Verification Script: Settlement Type Alignment
-- Purpose: Quick verification that settlement_type fix has been applied
-- Usage: Run on any SQL Server database with FCN schema
-- ============================================================================

SET NOCOUNT ON;
PRINT '=== FCN Settlement Type Verification ===';
PRINT 'Checking at: ' + CONVERT(NVARCHAR(30), GETDATE(), 120);
PRINT '';

-- ============================================================================
-- CHECK 1: Verify fcn_settlement table exists
-- ============================================================================

PRINT 'Check 1: Table Existence';
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'fcn_settlement' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    PRINT '✓ fcn_settlement table exists';
END
ELSE
BEGIN
    PRINT '✗ fcn_settlement table NOT found';
    PRINT 'Please apply fcn_schema_consolidated_v1_1.sql first.';
    RETURN;
END
PRINT '';

-- ============================================================================
-- CHECK 2: Verify canonical constraint exists
-- ============================================================================

PRINT 'Check 2: Canonical Constraint';
IF EXISTS (
    SELECT 1 
    FROM sys.check_constraints cc
    INNER JOIN sys.tables t ON cc.parent_object_id = t.object_id
    WHERE t.name = 'fcn_settlement'
      AND cc.name = 'chk_fcn_settlement_type_canonical'
)
BEGIN
    PRINT '✓ Canonical constraint exists: chk_fcn_settlement_type_canonical';
    
    -- Show constraint definition
    SELECT 
        '  Definition: ' + cc.definition AS info
    FROM sys.check_constraints cc
    INNER JOIN sys.tables t ON cc.parent_object_id = t.object_id
    WHERE t.name = 'fcn_settlement'
      AND cc.name = 'chk_fcn_settlement_type_canonical';
END
ELSE
BEGIN
    PRINT '✗ Canonical constraint NOT found';
    PRINT 'Please apply fcn_patch_settlement_type_alignment.sql';
END
PRINT '';

-- ============================================================================
-- CHECK 3: Verify index exists
-- ============================================================================

PRINT 'Check 3: Settlement Type Index';
IF EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE object_id = OBJECT_ID('dbo.fcn_settlement') 
      AND name = 'idx_fcn_settlement_type'
)
BEGIN
    PRINT '✓ Index exists: idx_fcn_settlement_type';
END
ELSE
BEGIN
    PRINT '⚠ Index NOT found: idx_fcn_settlement_type';
    PRINT 'Consider applying fcn_patch_settlement_type_alignment.sql for better performance';
END
PRINT '';

-- ============================================================================
-- CHECK 4: Verify settlement_type values
-- ============================================================================

PRINT 'Check 4: Settlement Type Values';
DECLARE @row_count INT;
SELECT @row_count = COUNT(*) FROM fcn_settlement;

IF @row_count = 0
BEGIN
    PRINT 'ℹ No data in fcn_settlement table (empty table)';
    PRINT '  This is OK for new deployments';
END
ELSE
BEGIN
    PRINT 'Found ' + CAST(@row_count AS NVARCHAR(10)) + ' rows in fcn_settlement';
    PRINT '';
    PRINT 'Distinct settlement_type values:';
    
    -- Show distinct values with counts
    SELECT 
        settlement_type,
        COUNT(*) AS row_count,
        CASE 
            WHEN settlement_type IN ('cash-settlement', 'physical-settlement') THEN '✓ CANONICAL'
            ELSE '✗ NON-CANONICAL'
        END AS status
    FROM fcn_settlement
    GROUP BY settlement_type
    ORDER BY settlement_type;
    
    -- Check for non-canonical values
    DECLARE @non_canonical_count INT;
    SELECT @non_canonical_count = COUNT(*) 
    FROM fcn_settlement 
    WHERE settlement_type NOT IN ('cash-settlement', 'physical-settlement');
    
    PRINT '';
    IF @non_canonical_count > 0
    BEGIN
        PRINT '✗ Found ' + CAST(@non_canonical_count AS NVARCHAR(10)) + ' non-canonical values!';
        PRINT 'Action Required: Apply fcn_patch_settlement_type_alignment.sql';
    END
    ELSE
    BEGIN
        PRINT '✓ All values are canonical';
    END
END
PRINT '';

-- ============================================================================
-- CHECK 5: Cross-table consistency
-- ============================================================================

PRINT 'Check 5: Cross-Table Consistency';

-- Check if fcn_trade and fcn_template exist
DECLARE @trade_exists BIT = 0;
DECLARE @template_exists BIT = 0;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'fcn_trade' AND schema_id = SCHEMA_ID('dbo'))
    SET @trade_exists = 1;
    
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'fcn_template' AND schema_id = SCHEMA_ID('dbo'))
    SET @template_exists = 1;

IF @template_exists = 1
BEGIN
    PRINT 'fcn_template settlement_type constraint:';
    SELECT 
        '  ' + cc.definition AS constraint_def
    FROM sys.check_constraints cc
    INNER JOIN sys.tables t ON cc.parent_object_id = t.object_id
    WHERE t.name = 'fcn_template'
      AND cc.parent_column_id = (
          SELECT column_id 
          FROM sys.columns 
          WHERE object_id = OBJECT_ID('dbo.fcn_template') 
            AND name = 'settlement_type'
      );
END

IF @trade_exists = 1
BEGIN
    PRINT 'fcn_trade settlement_type constraint:';
    SELECT 
        '  ' + cc.definition AS constraint_def
    FROM sys.check_constraints cc
    INNER JOIN sys.tables t ON cc.parent_object_id = t.object_id
    WHERE t.name = 'fcn_trade'
      AND cc.parent_column_id = (
          SELECT column_id 
          FROM sys.columns 
          WHERE object_id = OBJECT_ID('dbo.fcn_trade') 
            AND name = 'settlement_type'
      );
END

PRINT 'fcn_settlement settlement_type constraint:';
SELECT 
    '  ' + cc.definition AS constraint_def
FROM sys.check_constraints cc
INNER JOIN sys.tables t ON cc.parent_object_id = t.object_id
WHERE t.name = 'fcn_settlement'
  AND cc.parent_column_id = (
      SELECT column_id 
      FROM sys.columns 
      WHERE object_id = OBJECT_ID('dbo.fcn_settlement') 
        AND name = 'settlement_type'
  );

PRINT '';
PRINT '✓ All constraints should use identical canonical values';
PRINT '';

-- ============================================================================
-- SUMMARY
-- ============================================================================

PRINT '=== Verification Summary ===';
PRINT '';

DECLARE @all_checks_passed BIT = 1;

-- Recheck all conditions
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'fcn_settlement')
    SET @all_checks_passed = 0;

IF NOT EXISTS (
    SELECT 1 
    FROM sys.check_constraints cc
    INNER JOIN sys.tables t ON cc.parent_object_id = t.object_id
    WHERE t.name = 'fcn_settlement'
      AND cc.name = 'chk_fcn_settlement_type_canonical'
)
    SET @all_checks_passed = 0;

SELECT @non_canonical_count = COUNT(*) 
FROM fcn_settlement 
WHERE settlement_type NOT IN ('cash-settlement', 'physical-settlement');

IF @non_canonical_count > 0
    SET @all_checks_passed = 0;

IF @all_checks_passed = 1
BEGIN
    PRINT '✅ ALL CHECKS PASSED';
    PRINT '   Settlement type alignment is complete and correct.';
END
ELSE
BEGIN
    PRINT '⚠ SOME CHECKS FAILED';
    PRINT '   Review the output above for details.';
    PRINT '   Consider applying fcn_patch_settlement_type_alignment.sql if needed.';
END

PRINT '';
PRINT 'Verification completed at: ' + CONVERT(NVARCHAR(30), GETDATE(), 120);
GO
