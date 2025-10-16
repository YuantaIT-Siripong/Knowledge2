-- Migration: m0010-fcn-template-validation
-- Description: Validation procedure and trigger for FCN templates (SQL Server)
-- Author: siripong.s@yuanta.co.th
-- Created: 2025-10-16
-- Depends on: m0009-fcn-template-schema.sql
-- Version: FCN v1.1+

-- ============================================================================
-- OVERVIEW
-- ============================================================================
-- This migration adds validation logic for FCN templates:
-- 1. Stored procedure usp_FCN_ValidateTemplate enforcing business rules
-- 2. Trigger on fcn_template to call validation on INSERT/UPDATE
--
-- VALIDATION RULES:
-- - Step-down knock-out barriers must be non-increasing (monotonic)
-- - Only one observation can be marked as maturity
-- - Observation schedule must have at least one maturity observation
-- - Underlying weights must sum to 1.0 (100%)
-- - Step-down enabled flag must match presence of step-down barriers
-- ============================================================================

-- ============================================================================
-- 1. VALIDATION STORED PROCEDURE
-- ============================================================================

IF OBJECT_ID('dbo.usp_FCN_ValidateTemplate', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_FCN_ValidateTemplate;
GO

CREATE PROCEDURE dbo.usp_FCN_ValidateTemplate
    @template_id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @step_down_enabled BIT;
    DECLARE @maturity_count INT;
    DECLARE @underlying_weight_sum DECIMAL(12, 6);
    DECLARE @observation_count INT;
    
    -- Get template settings
    SELECT @step_down_enabled = step_down_enabled
    FROM fcn_template
    WHERE template_id = @template_id;
    
    IF @step_down_enabled IS NULL
    BEGIN
        RAISERROR('Template not found: %s', 16, 1, @template_id);
        RETURN;
    END
    
    -- ========================================================================
    -- RULE 1: Step-down knock-out barriers must be non-increasing
    -- ========================================================================
    IF @step_down_enabled = 1
    BEGIN
        -- Check if any step-down barriers exist
        IF EXISTS (
            SELECT 1 
            FROM fcn_template_observation_schedule 
            WHERE template_id = @template_id 
              AND observation_type = 'autocall'
              AND step_down_ko_barrier_pct IS NOT NULL
        )
        BEGIN
            -- Verify non-increasing order (descending or equal)
            IF EXISTS (
                SELECT 1
                FROM (
                    SELECT 
                        observation_offset_months,
                        step_down_ko_barrier_pct,
                        LAG(step_down_ko_barrier_pct) OVER (ORDER BY observation_offset_months) AS prev_barrier
                    FROM fcn_template_observation_schedule
                    WHERE template_id = @template_id
                      AND observation_type = 'autocall'
                      AND step_down_ko_barrier_pct IS NOT NULL
                ) AS barriers
                WHERE step_down_ko_barrier_pct > prev_barrier
            )
            BEGIN
                SET @ErrorMessage = 'Step-down knock-out barriers must be non-increasing (descending over time). Violation detected for template: ' + CAST(@template_id AS NVARCHAR(36));
                RAISERROR(@ErrorMessage, 16, 1);
                RETURN;
            END
        END
        ELSE
        BEGIN
            -- Step-down enabled but no barriers defined
            SET @ErrorMessage = 'Step-down enabled but no step_down_ko_barrier_pct values found in observation schedule for template: ' + CAST(@template_id AS NVARCHAR(36));
            RAISERROR(@ErrorMessage, 16, 1);
            RETURN;
        END
    END
    ELSE
    BEGIN
        -- Step-down disabled, ensure no step-down barriers are set
        IF EXISTS (
            SELECT 1
            FROM fcn_template_observation_schedule
            WHERE template_id = @template_id
              AND step_down_ko_barrier_pct IS NOT NULL
        )
        BEGIN
            SET @ErrorMessage = 'Step-down disabled but step_down_ko_barrier_pct values found in observation schedule for template: ' + CAST(@template_id AS NVARCHAR(36));
            RAISERROR(@ErrorMessage, 16, 1);
            RETURN;
        END
    END
    
    -- ========================================================================
    -- RULE 2: Only one observation can be marked as maturity
    -- ========================================================================
    SELECT @maturity_count = COUNT(*)
    FROM fcn_template_observation_schedule
    WHERE template_id = @template_id
      AND is_maturity = 1;
    
    IF @maturity_count = 0
    BEGIN
        SET @ErrorMessage = 'No maturity observation found in schedule for template: ' + CAST(@template_id AS NVARCHAR(36));
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END
    
    IF @maturity_count > 1
    BEGIN
        SET @ErrorMessage = 'Multiple maturity observations found in schedule. Only one allowed for template: ' + CAST(@template_id AS NVARCHAR(36));
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END
    
    -- ========================================================================
    -- RULE 3: Observation schedule must have at least one observation
    -- ========================================================================
    SELECT @observation_count = COUNT(*)
    FROM fcn_template_observation_schedule
    WHERE template_id = @template_id;
    
    IF @observation_count = 0
    BEGIN
        SET @ErrorMessage = 'No observations defined in schedule for template: ' + CAST(@template_id AS NVARCHAR(36));
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END
    
    -- ========================================================================
    -- RULE 4: Underlying weights must sum to 1.0 (with tolerance)
    -- ========================================================================
    SELECT @underlying_weight_sum = SUM(weight)
    FROM fcn_template_underlying
    WHERE template_id = @template_id;
    
    IF @underlying_weight_sum IS NOT NULL
    BEGIN
        -- Allow small tolerance for floating point arithmetic (0.001 = 0.1%)
        IF ABS(@underlying_weight_sum - 1.0) > 0.001
        BEGIN
            SET @ErrorMessage = 'Underlying weights must sum to 1.0. Current sum: ' 
                + CAST(@underlying_weight_sum AS NVARCHAR(20)) 
                + ' for template: ' + CAST(@template_id AS NVARCHAR(36));
            RAISERROR(@ErrorMessage, 16, 1);
            RETURN;
        END
    END
    
    -- ========================================================================
    -- VALIDATION PASSED
    -- ========================================================================
    PRINT 'Template validation passed for: ' + CAST(@template_id AS NVARCHAR(36));
    
END
GO

-- ============================================================================
-- 2. VALIDATION TRIGGER
-- ============================================================================
-- Trigger to automatically validate template on INSERT/UPDATE

IF OBJECT_ID('dbo.trg_FCN_ValidateTemplate', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_FCN_ValidateTemplate;
GO

CREATE TRIGGER dbo.trg_FCN_ValidateTemplate
ON dbo.fcn_template
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @template_id UNIQUEIDENTIFIER;
    
    -- Get template_id from inserted rows
    DECLARE template_cursor CURSOR FOR
        SELECT template_id FROM inserted;
    
    OPEN template_cursor;
    FETCH NEXT FROM template_cursor INTO @template_id;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Call validation procedure
        -- Note: Validation only runs if observation schedule and underlyings exist
        -- For new templates, validation will fail until these are populated
        -- Consider deferring validation or making it optional for Draft status
        
        DECLARE @status NVARCHAR(20);
        SELECT @status = status FROM fcn_template WHERE template_id = @template_id;
        
        -- Only validate templates in Active status
        -- Draft templates can be incomplete
        IF @status = 'Active'
        BEGIN
            BEGIN TRY
                EXEC dbo.usp_FCN_ValidateTemplate @template_id = @template_id;
            END TRY
            BEGIN CATCH
                -- Re-raise the error from validation procedure
                DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
                DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
                DECLARE @ErrorState INT = ERROR_STATE();
                
                RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
                
                -- Rollback the transaction
                IF @@TRANCOUNT > 0
                    ROLLBACK TRANSACTION;
            END CATCH
        END
        
        FETCH NEXT FROM template_cursor INTO @template_id;
    END
    
    CLOSE template_cursor;
    DEALLOCATE template_cursor;
END
GO

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- After applying this migration, verify that:
-- 1. usp_FCN_ValidateTemplate procedure exists and can be called manually
-- 2. Trigger fires on INSERT/UPDATE to fcn_template (Active status only)
-- 3. Templates with invalid step-down barriers are rejected
-- 4. Templates with multiple maturity flags are rejected
-- 5. Templates with invalid underlying weights are rejected

-- ============================================================================
-- TESTING EXAMPLES
-- ============================================================================
-- Test Case 1: Invalid step-down barriers (increasing instead of decreasing)
-- Expected: Validation fails
--
-- Test Case 2: Multiple maturity observations
-- Expected: Validation fails
--
-- Test Case 3: Underlying weights sum to 0.95 (not 1.0)
-- Expected: Validation fails
--
-- Test Case 4: Valid template with step-down enabled and proper barriers
-- Expected: Validation passes

-- ============================================================================
-- NOTES
-- ============================================================================
-- - Validation only enforced for Active templates (Draft can be incomplete)
-- - Step-down barriers must decrease (or stay equal) over observation time
-- - Underlying weight tolerance set to 0.1% to handle floating point precision
-- - Trigger uses cursor to handle multiple rows in batch operations
-- - Consider adding a manual validation function for pre-activation checks
-- - Migration is idempotent (DROP/CREATE pattern used)
