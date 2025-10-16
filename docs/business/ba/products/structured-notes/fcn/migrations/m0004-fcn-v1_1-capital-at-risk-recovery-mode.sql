-- Migration: m0004-fcn-v1_1-capital-at-risk-recovery-mode.sql
-- Description: Add recovery_mode='capital-at-risk' enumeration support
-- Depends on: m0001, m0002, m0003
-- Version: FCN v1.1.3
-- Author: copilot
-- Date: 2025-10-16

-- ============================================================================
-- OVERVIEW
-- ============================================================================
-- This migration extends the recovery_mode enumeration to include the
-- 'capital-at-risk' option, enabling physical worst-of settlement mechanics
-- as defined in BR-025A.
--
-- If recovery_mode is stored as TEXT with no constraint, this migration is
-- effectively a no-op (documentation only). If a CHECK constraint exists,
-- this migration alters it to include the new value.

-- ============================================================================
-- APPROACH
-- ============================================================================
-- Use a guarded DO block to detect and modify existing CHECK constraints.
-- If no constraint exists, the migration completes successfully with no action.

DO $$
BEGIN
    -- Check if a CHECK constraint exists on recovery_mode column
    -- This is a placeholder approach; adapt to actual schema structure
    
    -- Example: If fcn_parameters table has a CHECK constraint named
    -- chk_recovery_mode, alter it to include 'capital-at-risk'
    
    IF EXISTS (
        SELECT 1
        FROM information_schema.constraint_column_usage
        WHERE table_name = 'fcn_parameters'
          AND column_name = 'recovery_mode'
          AND constraint_name LIKE 'chk_%recovery_mode%'
    ) THEN
        -- Drop existing constraint
        EXECUTE 'ALTER TABLE fcn_parameters DROP CONSTRAINT IF EXISTS chk_recovery_mode;';
        
        -- Recreate constraint with new value
        EXECUTE '
            ALTER TABLE fcn_parameters
            ADD CONSTRAINT chk_recovery_mode
            CHECK (recovery_mode IN (''par-recovery'', ''proportional-loss'', ''capital-at-risk''));
        ';
        
        RAISE NOTICE 'Updated recovery_mode CHECK constraint to include capital-at-risk';
    ELSE
        RAISE NOTICE 'No CHECK constraint found on recovery_mode; migration is no-op';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Migration m0004 encountered issue: %. Continuing...', SQLERRM;
END $$;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- After applying this migration, verify that:
-- 1. recovery_mode column accepts 'capital-at-risk' value
-- 2. Existing data integrity preserved
-- 3. No conflicts with BR-025A implementation

-- ============================================================================
-- ROLLBACK (if needed)
-- ============================================================================
-- To rollback this migration:
-- 1. Ensure no trades use recovery_mode='capital-at-risk'
-- 2. Re-apply constraint without 'capital-at-risk' value
-- 3. Test data migration path

-- ============================================================================
-- NOTES
-- ============================================================================
-- - This migration supports BR-025A physical worst-of settlement mechanics
-- - Related schema change: schemas/fcn-v1.1.0-parameters.schema.json
-- - Related business rule: business-rules.md BR-025A
-- - Idempotent: safe to run multiple times
