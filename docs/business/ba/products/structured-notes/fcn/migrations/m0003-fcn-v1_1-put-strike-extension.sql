-- Migration: m0003-fcn-v1_1-put-strike-extension
-- Description: Extends FCN v1.1 with capital-at-risk settlement parameters: put_strike_pct and barrier_monitoring_type
-- Author: copilot
-- Created: 2025-10-16
-- Depends on: m0001-fcn-baseline.sql, m0002-fcn-v1_1-autocall-extension.sql

-- ============================================================================
-- MIGRATION OVERVIEW
-- ============================================================================
-- This migration extends the FCN product schema to support capital-at-risk
-- settlement for version 1.1.0:
-- 1. Put strike percentage for conditional principal loss threshold (required)
-- 2. Barrier monitoring type for discrete vs continuous monitoring (optional)
-- 
-- BACKWARD COMPATIBILITY: All changes are additive only. Existing v1.0 trades
-- remain fully valid with legacy par recovery (BR-011). No columns are removed,
-- renamed, or have constraints modified in a breaking way.
--
-- SETTLEMENT LOGIC: At maturity, if KI triggered AND worst_of_final_ratio < 
-- put_strike_pct, loss = notional × (put_strike_pct - worst_of_final_ratio) / 
-- put_strike_pct; else redeem 100% notional (BR-025).
-- ============================================================================

-- ============================================================================
-- 1. EXTEND TRADE TABLE WITH CAPITAL-AT-RISK COLUMNS
-- ============================================================================

-- Add put_strike_pct column (required for new v1.1.0 trades)
ALTER TABLE trade 
ADD COLUMN IF NOT EXISTS put_strike_pct NUMERIC(7, 6);

COMMENT ON COLUMN trade.put_strike_pct IS 'Put strike threshold as decimal ratio for capital-at-risk settlement (BR-024, BR-025); required for v1.1.0+; range: 0 < x <= 1.0; must be > knock_in_barrier_pct';

-- Add barrier_monitoring_type column (defaults to discrete)
ALTER TABLE trade 
ADD COLUMN IF NOT EXISTS barrier_monitoring_type VARCHAR(16) DEFAULT 'discrete';

COMMENT ON COLUMN trade.barrier_monitoring_type IS 'Barrier monitoring mechanism (BR-026); enum: ["discrete", "continuous"]; only "discrete" normative for v1.1; defaults to "discrete"';

-- ============================================================================
-- 2. ADD CONSTRAINTS FOR NEW COLUMNS
-- ============================================================================

-- Constraint: put_strike_pct range validation (BR-024)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'chk_put_strike_range'
    ) THEN
        ALTER TABLE trade 
        ADD CONSTRAINT chk_put_strike_range 
        CHECK (
            put_strike_pct IS NULL 
            OR (put_strike_pct > 0 AND put_strike_pct <= 1.0)
        );
    END IF;
END $$;

COMMENT ON CONSTRAINT chk_put_strike_range ON trade IS 'BR-024: Validates put_strike_pct is in range (0, 1.0] when present';

-- Constraint: knock_in_barrier_pct < put_strike_pct ordering (BR-024)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'chk_ki_put_strike_relation'
    ) THEN
        ALTER TABLE trade 
        ADD CONSTRAINT chk_ki_put_strike_relation 
        CHECK (
            put_strike_pct IS NULL 
            OR knock_in_barrier_pct IS NULL 
            OR knock_in_barrier_pct < put_strike_pct
        );
    END IF;
END $$;

COMMENT ON CONSTRAINT chk_ki_put_strike_relation ON trade IS 'BR-024: Ensures knock_in_barrier_pct < put_strike_pct ordering for capital-at-risk settlement';

-- Constraint: barrier_monitoring_type enum validation (BR-026)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'chk_barrier_monitoring_type'
    ) THEN
        ALTER TABLE trade 
        ADD CONSTRAINT chk_barrier_monitoring_type 
        CHECK (
            barrier_monitoring_type IS NULL 
            OR barrier_monitoring_type IN ('discrete', 'continuous')
        );
    END IF;
END $$;

COMMENT ON CONSTRAINT chk_barrier_monitoring_type ON trade IS 'BR-026: Validates barrier_monitoring_type is a recognized enum value ["discrete", "continuous"]';

-- ============================================================================
-- 3. BACKFILL EXISTING ROWS (OPTIONAL - NO BEHAVIORAL CHANGE)
-- ============================================================================

-- Backfill existing v1.0 trades with put_strike_pct = 1.0 (equivalent to unconditional par recovery)
-- This is optional and maintains backward compatibility without changing payoff behavior
-- Uncomment if you want to normalize the schema for all trades

-- UPDATE trade
-- SET put_strike_pct = 1.0
-- WHERE put_strike_pct IS NULL;

-- Note: barrier_monitoring_type defaults to 'discrete' already via column DEFAULT

-- ============================================================================
-- 4. INSERT V1.1.0 CAPITAL-AT-RISK BRANCHES
-- ============================================================================

-- Insert capital-at-risk no-memory branch
INSERT INTO branch (
    product_id,
    version_id,
    branch_code,
    description,
    barrier_type,
    settlement,
    coupon_memory,
    step_feature,
    recovery_mode
)
SELECT
    p.product_id,
    pv.version_id,
    'fcn-caprisk-nomem',
    'No-memory coupon, capital-at-risk settlement, physical settlement',
    'down-in',
    'physical-settlement',
    'no-memory',
    'no-step',
    'capital-at-risk'
FROM product p
JOIN product_version pv ON p.product_id = pv.product_id
WHERE p.product_code = 'FCN' AND pv.version = '1.1.0'
ON CONFLICT (product_id, version_id, branch_code) DO NOTHING;

-- Insert capital-at-risk memory branch
INSERT INTO branch (
    product_id,
    version_id,
    branch_code,
    description,
    barrier_type,
    settlement,
    coupon_memory,
    step_feature,
    recovery_mode
)
SELECT
    p.product_id,
    pv.version_id,
    'fcn-caprisk-mem',
    'Memory coupon, capital-at-risk settlement, physical settlement',
    'down-in',
    'physical-settlement',
    'memory',
    'no-step',
    'capital-at-risk'
FROM product p
JOIN product_version pv ON p.product_id = pv.product_id
WHERE p.product_code = 'FCN' AND pv.version = '1.1.0'
ON CONFLICT (product_id, version_id, branch_code) DO NOTHING;

-- Insert capital-at-risk no-memory autocall branch
INSERT INTO branch (
    product_id,
    version_id,
    branch_code,
    description,
    barrier_type,
    settlement,
    coupon_memory,
    step_feature,
    recovery_mode
)
SELECT
    p.product_id,
    pv.version_id,
    'fcn-caprisk-nomem-autocall',
    'No-memory coupon, capital-at-risk settlement, autocall enabled, physical settlement',
    'down-in',
    'physical-settlement',
    'no-memory',
    'autocall',
    'capital-at-risk'
FROM product p
JOIN product_version pv ON p.product_id = pv.product_id
WHERE p.product_code = 'FCN' AND pv.version = '1.1.0'
ON CONFLICT (product_id, version_id, branch_code) DO NOTHING;

COMMENT ON TABLE branch IS 'Taxonomy-specific payoff branches within product version; fcn-caprisk-* branches added in v1.1.0 for capital-at-risk settlement';

-- ============================================================================
-- 5. INSERT V1.1.0 PARAMETER DEFINITIONS
-- ============================================================================

-- Insert put_strike_pct parameter definition
INSERT INTO parameter_definition (
    version_id,
    parameter_name,
    parameter_type,
    required,
    default_value,
    constraints,
    description
)
SELECT
    pv.version_id,
    'put_strike_pct',
    'number',
    TRUE,
    NULL,
    '{"exclusiveMinimum": 0, "maximum": 1.0}'::jsonb,
    'Put strike threshold for capital-at-risk settlement; must be > knock_in_barrier_pct (BR-024, BR-025)'
FROM product p
JOIN product_version pv ON p.product_id = pv.product_id
WHERE p.product_code = 'FCN' AND pv.version = '1.1.0'
ON CONFLICT (version_id, parameter_name) DO NOTHING;

-- Insert barrier_monitoring_type parameter definition
INSERT INTO parameter_definition (
    version_id,
    parameter_name,
    parameter_type,
    required,
    default_value,
    constraints,
    description
)
SELECT
    pv.version_id,
    'barrier_monitoring_type',
    'string',
    FALSE,
    'discrete',
    '{"enum": ["discrete", "continuous"]}'::jsonb,
    'Barrier monitoring mechanism; only "discrete" normative for v1.1 (BR-026)'
FROM product p
JOIN product_version pv ON p.product_id = pv.product_id
WHERE p.product_code = 'FCN' AND pv.version = '1.1.0'
ON CONFLICT (version_id, parameter_name) DO NOTHING;

-- ============================================================================
-- 6. MIGRATION TRACKING
-- ============================================================================

INSERT INTO schema_migrations (migration_id, description)
VALUES ('m0003_fcn_v1_1_put_strike', 'FCN v1.1.0: Added capital-at-risk settlement with put_strike_pct and barrier_monitoring_type')
ON CONFLICT (migration_id) DO NOTHING;

-- ============================================================================
-- 7. DATA MIGRATION GUIDANCE (COMMENTS)
-- ============================================================================

-- For existing v1.0 trades:
-- Option 1 (recommended): Leave put_strike_pct = NULL, legacy par recovery (BR-011) continues to apply
-- Option 2: Backfill put_strike_pct = 1.0 to normalize schema (no behavioral change, equivalent to par recovery)
--
-- For new v1.1 trades:
-- - put_strike_pct is REQUIRED (must be > knock_in_barrier_pct and <= 1.0)
-- - barrier_monitoring_type defaults to 'discrete' if not specified
-- - Settlement follows capital-at-risk logic (BR-025), NOT unconditional par recovery (BR-011 deprecated)

COMMENT ON SCHEMA public IS 'FCN schema - m0003 (v1.1.0): Extended with capital-at-risk settlement (put_strike_pct, barrier_monitoring_type)';

-- End of m0003-fcn-v1_1-put-strike-extension.sql
