-- Migration: m0011-fcn-trade-link-template
-- Description: Add template_id foreign key to fcn_trade for lineage tracking (SQL Server)
-- Author: siripong.s@yuanta.co.th
-- Created: 2025-10-16
-- Depends on: m0009-fcn-template-schema.sql
-- Version: FCN v1.1+

-- ============================================================================
-- OVERVIEW
-- ============================================================================
-- This migration links the fcn_trade table to the fcn_template table via
-- a template_id foreign key column. This establishes a lineage relationship
-- between trade instances and their source product shelf templates.
--
-- BENEFITS:
-- - Audit trail: trace which template generated each trade
-- - Parameter validation: compare trade parameters against template defaults
-- - Reporting: aggregate trades by template
-- - Product lifecycle: identify affected trades when template is deprecated
--
-- BACKWARD COMPATIBILITY:
-- - template_id is NULLABLE to support existing trades without templates
-- - No breaking changes to existing fcn_trade structure
-- - Foreign key with ON DELETE SET NULL ensures template deletion doesn't cascade
-- ============================================================================

-- ============================================================================
-- 1. ADD TEMPLATE_ID COLUMN TO FCN_TRADE
-- ============================================================================

-- Check if fcn_trade table exists (assumed to exist from baseline migrations)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'fcn_trade' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    RAISERROR('fcn_trade table not found. Ensure baseline FCN migrations are applied first.', 16, 1);
    RETURN;
END
GO

-- Add template_id column if it doesn't exist
IF NOT EXISTS (
    SELECT * 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID('dbo.fcn_trade') 
      AND name = 'template_id'
)
BEGIN
    ALTER TABLE fcn_trade
    ADD template_id UNIQUEIDENTIFIER NULL;
    
    PRINT 'Added template_id column to fcn_trade table';
END
ELSE
BEGIN
    PRINT 'template_id column already exists in fcn_trade table';
END
GO

-- ============================================================================
-- 2. ADD FOREIGN KEY CONSTRAINT
-- ============================================================================

-- Check if foreign key already exists
IF NOT EXISTS (
    SELECT * 
    FROM sys.foreign_keys 
    WHERE name = 'fk_fcn_trade_template' 
      AND parent_object_id = OBJECT_ID('dbo.fcn_trade')
)
BEGIN
    -- Add foreign key constraint to fcn_template
    ALTER TABLE fcn_trade
    ADD CONSTRAINT fk_fcn_trade_template
        FOREIGN KEY (template_id) 
        REFERENCES fcn_template(template_id)
        ON DELETE SET NULL;  -- Preserve trade history even if template is deleted
    
    PRINT 'Added foreign key constraint fk_fcn_trade_template';
END
ELSE
BEGIN
    PRINT 'Foreign key constraint fk_fcn_trade_template already exists';
END
GO

-- ============================================================================
-- 3. ADD INDEX FOR TEMPLATE_ID
-- ============================================================================

-- Create index to optimize queries filtering/joining by template_id
IF NOT EXISTS (
    SELECT * 
    FROM sys.indexes 
    WHERE name = 'idx_fcn_trade_template' 
      AND object_id = OBJECT_ID('dbo.fcn_trade')
)
BEGIN
    CREATE INDEX idx_fcn_trade_template 
    ON fcn_trade(template_id)
    WHERE template_id IS NOT NULL;  -- Filtered index for non-null values only
    
    PRINT 'Added index idx_fcn_trade_template';
END
ELSE
BEGIN
    PRINT 'Index idx_fcn_trade_template already exists';
END
GO

-- ============================================================================
-- 4. ADD COLUMN DESCRIPTION
-- ============================================================================

-- Add extended property for documentation
IF NOT EXISTS (
    SELECT * 
    FROM sys.extended_properties 
    WHERE major_id = OBJECT_ID('dbo.fcn_trade')
      AND minor_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('dbo.fcn_trade') AND name = 'template_id')
      AND name = 'MS_Description'
)
BEGIN
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description',
        @value = N'Optional reference to FCN template used to generate this trade. Provides lineage and parameter validation linkage.',
        @level0type = N'SCHEMA', @level0name = N'dbo',
        @level1type = N'TABLE', @level1name = N'fcn_trade',
        @level2type = N'COLUMN', @level2name = N'template_id';
    
    PRINT 'Added column description for template_id';
END
ELSE
BEGIN
    PRINT 'Column description for template_id already exists';
END
GO

-- ============================================================================
-- 5. OPTIONAL: VALIDATION PROCEDURE FOR TEMPLATE-TRADE CONSISTENCY
-- ============================================================================
-- This procedure can be called to verify that a trade's parameters
-- match its linked template (if template_id is set)

IF OBJECT_ID('dbo.usp_FCN_ValidateTradeAgainstTemplate', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_FCN_ValidateTradeAgainstTemplate;
GO

CREATE PROCEDURE dbo.usp_FCN_ValidateTradeAgainstTemplate
    @trade_id UNIQUEIDENTIFIER,
    @strict_mode BIT = 0  -- If 1, fail on any mismatch; if 0, only warn
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @template_id UNIQUEIDENTIFIER;
    DECLARE @warnings TABLE (warning_message NVARCHAR(500));
    
    -- Get template_id for this trade
    SELECT @template_id = template_id
    FROM fcn_trade
    WHERE trade_id = @trade_id;
    
    IF @template_id IS NULL
    BEGIN
        PRINT 'Trade has no linked template. Validation skipped.';
        RETURN;
    END
    
    -- Compare key parameters between trade and template
    -- This is a sample validation - extend as needed
    
    -- Example: Check currency match
    IF EXISTS (
        SELECT 1
        FROM fcn_trade t
        INNER JOIN fcn_template tpl ON t.template_id = tpl.template_id
        WHERE t.trade_id = @trade_id
          AND t.currency != tpl.currency
    )
    BEGIN
        INSERT INTO @warnings VALUES ('Currency mismatch between trade and template');
    END
    
    -- Example: Check knock_in_barrier_pct match
    IF EXISTS (
        SELECT 1
        FROM fcn_trade t
        INNER JOIN fcn_template tpl ON t.template_id = tpl.template_id
        WHERE t.trade_id = @trade_id
          AND ABS(t.knock_in_barrier_pct - tpl.knock_in_barrier_pct) > 0.000001
    )
    BEGIN
        INSERT INTO @warnings VALUES ('knock_in_barrier_pct mismatch between trade and template');
    END
    
    -- Report warnings
    IF EXISTS (SELECT 1 FROM @warnings)
    BEGIN
        SELECT warning_message FROM @warnings;
        
        IF @strict_mode = 1
        BEGIN
            RAISERROR('Trade parameter validation failed against template', 16, 1);
            RETURN;
        END
    END
    ELSE
    BEGIN
        PRINT 'Trade parameters match template';
    END
END
GO

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- After applying this migration, verify that:
-- 1. template_id column exists in fcn_trade table
-- 2. Foreign key constraint links to fcn_template
-- 3. Index on template_id improves query performance
-- 4. Existing trades have template_id = NULL (backward compatible)
-- 5. New trades can optionally set template_id
-- 6. Deleting a template sets template_id to NULL in related trades

-- ============================================================================
-- USAGE EXAMPLES
-- ============================================================================

-- Example 1: Create a trade from a template
-- UPDATE fcn_trade
-- SET template_id = (SELECT template_id FROM fcn_template WHERE template_code = 'FCN-STEPDOWN-Q-2025')
-- WHERE trade_code = 'TRD-001';

-- Example 2: Find all trades using a specific template
-- SELECT t.*
-- FROM fcn_trade t
-- INNER JOIN fcn_template tpl ON t.template_id = tpl.template_id
-- WHERE tpl.template_code = 'FCN-STEPDOWN-Q-2025';

-- Example 3: Find trades without a template linkage
-- SELECT * FROM fcn_trade WHERE template_id IS NULL;

-- Example 4: Validate a trade against its template
-- EXEC usp_FCN_ValidateTradeAgainstTemplate @trade_id = 'YOUR-TRADE-ID-GUID', @strict_mode = 0;

-- ============================================================================
-- NOTES
-- ============================================================================
-- - Migration is idempotent (safe to run multiple times)
-- - template_id is optional to maintain backward compatibility
-- - ON DELETE SET NULL ensures trade history preserved if template deleted
-- - Validation procedure is provided for audit purposes but not enforced
-- - Consider adding triggers or application-level validation for strict enforcement
-- - Template linkage enables product lifecycle management and governance
