-- ============================================================================
-- Migration: fcn_patch_trade_settlement_consistency_view.sql
-- Description: Add diagnostic view and procedure for FCN trade-settlement consistency
-- Author: copilot
-- Created: 2025-10-17
-- Version: Patch 1.1.2
-- Applies To: Databases with fcn_schema_consolidated_v1_1.sql and fcn_patch_settlement_type_alignment.sql applied
-- ============================================================================
--
-- BACKGROUND:
-- After PR #55 (settlement type alignment), we need monitoring capabilities to detect:
-- - Mismatches between trade and settlement settlement_type values
-- - Missing settlements after maturity
-- - Inconsistencies with lifecycle expectations based on recovery_mode
--
-- OBJECTIVES:
-- 1. Create view v_fcn_trade_settlement_consistency surfacing:
--    - Trade and settlement basic info
--    - Settlement presence flag
--    - Settlement type comparison and mismatch detection
--    - Recovery mode analysis
--    - Physical settlement expectation flags
--    - KI trigger expectation vs actual
--    - Maturity date tracking
--    - Missing settlement detection
-- 2. Create stored procedure usp_FCN_ListSettlementInconsistencies to list problem rows
-- 3. Fully idempotent (drops and recreates)
--
-- IDEMPOTENCY:
-- - Drops view and procedure if they exist before creating
-- - Safe to run multiple times
--
-- USAGE:
-- Run after fcn_patch_settlement_type_alignment.sql
-- Query view: SELECT * FROM v_fcn_trade_settlement_consistency;
-- List issues: EXEC usp_FCN_ListSettlementInconsistencies;
-- ============================================================================

SET NOCOUNT ON;
PRINT '=== FCN Patch: Trade-Settlement Consistency Diagnostic ===';
PRINT 'Starting at: ' + CONVERT(NVARCHAR(30), GETDATE(), 120);
GO

-- ============================================================================
-- STEP 1: Pre-Migration Validation
-- ============================================================================

PRINT '';
PRINT 'Step 1: Pre-Migration Validation';

-- Verify required tables exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'fcn_trade' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    PRINT 'ERROR: fcn_trade table does not exist. Please apply fcn_schema_consolidated_v1_1.sql first.';
    RAISERROR('fcn_trade table not found', 16, 1);
    RETURN;
END

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'fcn_settlement' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    PRINT 'ERROR: fcn_settlement table does not exist. Please apply fcn_schema_consolidated_v1_1.sql first.';
    RAISERROR('fcn_settlement table not found', 16, 1);
    RETURN;
END

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'fcn_event' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    PRINT 'WARNING: fcn_event table does not exist. View will be created but ki_triggered_actual may not be accurate.';
END

PRINT 'All required tables validated successfully.';
GO

-- ============================================================================
-- STEP 2: Drop Existing Objects (Idempotency)
-- ============================================================================

PRINT '';
PRINT 'Step 2: Dropping existing objects if present';

-- Drop procedure first (depends on view)
IF OBJECT_ID('dbo.usp_FCN_ListSettlementInconsistencies', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_FCN_ListSettlementInconsistencies;
    PRINT 'Dropped existing procedure: usp_FCN_ListSettlementInconsistencies';
END

-- Drop view
IF OBJECT_ID('dbo.v_fcn_trade_settlement_consistency', 'V') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_fcn_trade_settlement_consistency;
    PRINT 'Dropped existing view: v_fcn_trade_settlement_consistency';
END

PRINT 'Cleanup complete.';
GO

-- ============================================================================
-- STEP 3: Create Diagnostic View
-- ============================================================================

PRINT '';
PRINT 'Step 3: Creating view v_fcn_trade_settlement_consistency';
GO

CREATE VIEW dbo.v_fcn_trade_settlement_consistency
AS
WITH trade_settlement_data AS (
    SELECT
        t.trade_id,
        t.maturity_date,
        t.settlement_type AS trade_settlement_type,
        t.recovery_mode AS trade_recovery_mode,
        t.put_strike_pct,
        s.settlement_id,
        s.settlement_type AS settlement_settlement_type,
        s.settlement_date,
        s.settlement_status,
        -- Physical settlement indicators
        s.delivery_shares,
        s.delivery_underlying_symbol,
        -- Check if KI event exists for this trade
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM fcn_event e 
                WHERE e.trade_id = t.trade_id 
                  AND e.event_type = 'knock-in'
            ) THEN 1
            ELSE 0
        END AS ki_event_exists
    FROM fcn_trade t
    LEFT JOIN fcn_settlement s ON t.trade_id = s.trade_id
)
SELECT
    trade_id,
    
    -- Settlement presence
    CASE WHEN settlement_id IS NOT NULL THEN 1 ELSE 0 END AS settlement_present_flag,
    
    -- Settlement type comparison
    trade_settlement_type,
    settlement_settlement_type,
    CASE 
        WHEN settlement_id IS NOT NULL 
             AND trade_settlement_type != settlement_settlement_type 
        THEN 1 
        ELSE 0 
    END AS mismatch_settlement_type_flag,
    
    -- Recovery mode
    trade_recovery_mode,
    
    -- Physical settlement expectation
    -- Physical settlement expected when:
    -- - settlement_type = 'physical-settlement' AND
    -- - recovery_mode = 'capital-at-risk' (requires put_strike_pct)
    CASE 
        WHEN settlement_id IS NOT NULL
             AND trade_settlement_type = 'physical-settlement'
             AND trade_recovery_mode = 'capital-at-risk'
             AND put_strike_pct IS NOT NULL
        THEN 1 
        ELSE 0 
    END AS settlement_physical_expected_flag,
    
    -- KI triggered expectation
    -- KI trigger expected when recovery_mode = 'capital-at-risk' and put_strike_pct is set
    -- (capital-at-risk requires put_strike_pct per BR-024)
    CASE 
        WHEN trade_recovery_mode = 'capital-at-risk' 
             AND put_strike_pct IS NOT NULL 
        THEN 1 
        ELSE 0 
    END AS ki_triggered_expected_flag,
    
    -- KI triggered actual (from events or could be inferred from settlement)
    ki_event_exists AS ki_triggered_actual,
    
    -- Maturity tracking
    CASE 
        WHEN CAST(GETDATE() AS DATE) >= maturity_date THEN 1 
        ELSE 0 
    END AS maturity_passed_flag,
    
    -- Settlement missing after maturity
    CASE 
        WHEN CAST(GETDATE() AS DATE) >= maturity_date 
             AND settlement_id IS NULL 
        THEN 1 
        ELSE 0 
    END AS settlement_missing_after_maturity_flag,
    
    -- Additional context fields
    maturity_date,
    settlement_date,
    settlement_status,
    put_strike_pct,
    delivery_shares,
    delivery_underlying_symbol

FROM trade_settlement_data;
GO

EXEC sys.sp_addextendedproperty 
    @name = N'MS_Description',
    @value = N'Diagnostic view for FCN trade-settlement consistency checking. Surfaces mismatches between trade and settlement layers, missing settlements, and lifecycle expectation violations.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'VIEW', @level1name = N'v_fcn_trade_settlement_consistency';

PRINT 'Created view: v_fcn_trade_settlement_consistency';
GO

-- ============================================================================
-- STEP 4: Create Diagnostic Stored Procedure
-- ============================================================================

PRINT '';
PRINT 'Step 4: Creating stored procedure usp_FCN_ListSettlementInconsistencies';
GO

CREATE PROCEDURE dbo.usp_FCN_ListSettlementInconsistencies
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Select all rows from the view where any flag indicates an issue
    SELECT 
        trade_id,
        settlement_present_flag,
        trade_settlement_type,
        settlement_settlement_type,
        mismatch_settlement_type_flag,
        trade_recovery_mode,
        settlement_physical_expected_flag,
        ki_triggered_expected_flag,
        ki_triggered_actual,
        maturity_passed_flag,
        settlement_missing_after_maturity_flag,
        maturity_date,
        settlement_date,
        settlement_status,
        put_strike_pct
    FROM dbo.v_fcn_trade_settlement_consistency
    WHERE mismatch_settlement_type_flag = 1
       OR settlement_missing_after_maturity_flag = 1
       OR (settlement_physical_expected_flag = 1 AND delivery_shares IS NULL)
    ORDER BY 
        settlement_missing_after_maturity_flag DESC,
        mismatch_settlement_type_flag DESC,
        maturity_date ASC;
END;
GO

EXEC sys.sp_addextendedproperty 
    @name = N'MS_Description',
    @value = N'Lists FCN trades with settlement inconsistencies or missing settlements. Returns rows where mismatch flags or missing settlement indicators are true.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'PROCEDURE', @level1name = N'usp_FCN_ListSettlementInconsistencies';

PRINT 'Created stored procedure: usp_FCN_ListSettlementInconsistencies';
GO

-- ============================================================================
-- STEP 5: Post-Creation Verification
-- ============================================================================

PRINT '';
PRINT 'Step 5: Post-Creation Verification';

-- Verify view exists
IF OBJECT_ID('dbo.v_fcn_trade_settlement_consistency', 'V') IS NOT NULL
BEGIN
    PRINT '✓ View v_fcn_trade_settlement_consistency created successfully';
    
    -- Show column list
    PRINT '';
    PRINT 'View columns:';
    SELECT 
        COLUMN_NAME,
        DATA_TYPE,
        CHARACTER_MAXIMUM_LENGTH
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'v_fcn_trade_settlement_consistency'
      AND TABLE_SCHEMA = 'dbo'
    ORDER BY ORDINAL_POSITION;
END
ELSE
BEGIN
    PRINT '✗ ERROR: View creation failed';
END

-- Verify procedure exists
IF OBJECT_ID('dbo.usp_FCN_ListSettlementInconsistencies', 'P') IS NOT NULL
BEGIN
    PRINT '';
    PRINT '✓ Procedure usp_FCN_ListSettlementInconsistencies created successfully';
END
ELSE
BEGIN
    PRINT '';
    PRINT '✗ ERROR: Procedure creation failed';
END

-- Show sample data (limit to 5 rows)
PRINT '';
PRINT 'Sample data from view (first 5 rows):';
SELECT TOP 5 
    trade_id,
    settlement_present_flag,
    mismatch_settlement_type_flag,
    settlement_missing_after_maturity_flag,
    maturity_date
FROM dbo.v_fcn_trade_settlement_consistency
ORDER BY maturity_date DESC;

-- ============================================================================
-- COMPLETION
-- ============================================================================

PRINT '';
PRINT '=== FCN Patch: Trade-Settlement Consistency Diagnostic Complete ===';
PRINT 'Completed at: ' + CONVERT(NVARCHAR(30), GETDATE(), 120);
PRINT '';
PRINT 'Summary:';
PRINT '- View created: v_fcn_trade_settlement_consistency';
PRINT '- Procedure created: usp_FCN_ListSettlementInconsistencies';
PRINT '';
PRINT 'Usage Examples:';
PRINT '  -- View all consistency data:';
PRINT '  SELECT TOP 20 * FROM v_fcn_trade_settlement_consistency ORDER BY settlement_missing_after_maturity_flag DESC;';
PRINT '';
PRINT '  -- List only inconsistencies:';
PRINT '  EXEC usp_FCN_ListSettlementInconsistencies;';
PRINT '';
PRINT '  -- Find trades with settlement type mismatches:';
PRINT '  SELECT * FROM v_fcn_trade_settlement_consistency WHERE mismatch_settlement_type_flag = 1;';
PRINT '';
PRINT '  -- Find trades missing settlements after maturity:';
PRINT '  SELECT * FROM v_fcn_trade_settlement_consistency WHERE settlement_missing_after_maturity_flag = 1;';
GO
