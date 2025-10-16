-- Migration: m0002-fcn-v1_1-autocall-extension
-- Description: Extends FCN v1.0 with autocall (knock-out) barrier and issuer support for v1.1.0
-- Author: siripong.s@yuanta.co.th
-- Created: 2025-10-16
-- Depends on: m0001-fcn-baseline.sql

-- ============================================================================
-- MIGRATION OVERVIEW
-- ============================================================================
-- This migration extends the FCN product schema to support version 1.1.0 features:
-- 1. Issuer identifier for counterparty risk management (required)
-- 2. Knock-out (autocall) barrier for early redemption feature (optional)
-- 3. Auto-call observation logic configuration (conditional)
-- 
-- BACKWARD COMPATIBILITY: All changes are additive only. Existing v1.0 trades
-- remain fully valid. No columns are removed, renamed, or have constraints
-- modified in a breaking way.
-- ============================================================================

-- ============================================================================
-- 1. EXTEND TRADE TABLE WITH V1.1.0 COLUMNS
-- ============================================================================

-- Add issuer column (required for new v1.1.0 trades)
ALTER TABLE trade 
ADD COLUMN IF NOT EXISTS issuer VARCHAR(64);

COMMENT ON COLUMN trade.issuer IS 'Issuer identifier; must exist in approved issuer whitelist (BR-022); required for v1.1.0+';

-- Add knock_out_barrier_pct column (optional autocall barrier)
ALTER TABLE trade 
ADD COLUMN IF NOT EXISTS knock_out_barrier_pct NUMERIC(7, 6);

COMMENT ON COLUMN trade.knock_out_barrier_pct IS 'Knock-out (autocall) barrier as decimal ratio; triggers early redemption when ALL underlyings exceed initial × this level (BR-020, BR-021); range: 0 < x <= 1.30';

-- Add auto_call_observation_logic column (conditional - required if knock_out_barrier_pct present)
ALTER TABLE trade 
ADD COLUMN IF NOT EXISTS auto_call_observation_logic VARCHAR(32);

COMMENT ON COLUMN trade.auto_call_observation_logic IS 'Logic for autocall trigger evaluation; currently supports "all-underlyings" (BR-021); required if knock_out_barrier_pct is present';

-- Add observation_frequency_months column (optional helper)
ALTER TABLE trade 
ADD COLUMN IF NOT EXISTS observation_frequency_months INTEGER;

COMMENT ON COLUMN trade.observation_frequency_months IS 'Optional informational field: monthly interval between observations (e.g., 3 for quarterly, 1 for monthly)';

-- ============================================================================
-- 2. ADD CONSTRAINTS FOR NEW COLUMNS
-- ============================================================================

-- Constraint: knock_out_barrier_pct range validation (BR-020)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'chk_knock_out_barrier_range'
    ) THEN
        ALTER TABLE trade 
        ADD CONSTRAINT chk_knock_out_barrier_range 
        CHECK (
            knock_out_barrier_pct IS NULL 
            OR (knock_out_barrier_pct > 0 AND knock_out_barrier_pct <= 1.30)
        );
    END IF;
END $$;

COMMENT ON CONSTRAINT chk_knock_out_barrier_range ON trade IS 'BR-020: Validates knock_out_barrier_pct is in range (0, 1.30] when present';

-- Constraint: auto_call_observation_logic enum validation
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'chk_auto_call_logic_enum'
    ) THEN
        ALTER TABLE trade 
        ADD CONSTRAINT chk_auto_call_logic_enum 
        CHECK (
            auto_call_observation_logic IS NULL 
            OR auto_call_observation_logic IN ('all-underlyings')
        );
    END IF;
END $$;

COMMENT ON CONSTRAINT chk_auto_call_logic_enum ON trade IS 'Validates auto_call_observation_logic is a recognized enum value';

-- Constraint: auto_call_observation_logic required when knock_out_barrier_pct present
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'chk_autocall_logic_dependency'
    ) THEN
        ALTER TABLE trade 
        ADD CONSTRAINT chk_autocall_logic_dependency 
        CHECK (
            (knock_out_barrier_pct IS NULL AND auto_call_observation_logic IS NULL)
            OR (knock_out_barrier_pct IS NOT NULL AND auto_call_observation_logic IS NOT NULL)
        );
    END IF;
END $$;

COMMENT ON CONSTRAINT chk_autocall_logic_dependency ON trade IS 'BR-021: Ensures auto_call_observation_logic is specified when knock_out_barrier_pct is present';

-- Constraint: observation_frequency_months must be positive if specified
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'chk_observation_frequency_positive'
    ) THEN
        ALTER TABLE trade 
        ADD CONSTRAINT chk_observation_frequency_positive 
        CHECK (
            observation_frequency_months IS NULL 
            OR observation_frequency_months >= 1
        );
    END IF;
END $$;

COMMENT ON CONSTRAINT chk_observation_frequency_positive ON trade IS 'Validates observation_frequency_months is at least 1 when specified';

-- ============================================================================
-- 3. CREATE OPTIONAL INDEXES FOR QUERY PERFORMANCE
-- ============================================================================

-- Index on issuer for whitelist validation and reporting queries
CREATE INDEX IF NOT EXISTS idx_trade_issuer 
ON trade(issuer) 
WHERE issuer IS NOT NULL;

COMMENT ON INDEX idx_trade_issuer IS 'Supports issuer whitelist validation and counterparty risk queries';

-- Index on knock_out_barrier_pct for autocall product queries
CREATE INDEX IF NOT EXISTS idx_trade_autocall_feature 
ON trade(knock_out_barrier_pct, auto_call_observation_logic) 
WHERE knock_out_barrier_pct IS NOT NULL;

COMMENT ON INDEX idx_trade_autocall_feature IS 'Supports queries filtering trades with autocall feature';

-- ============================================================================
-- 4. INSERT V1.1.0 VERSION METADATA
-- ============================================================================

-- Insert FCN v1.1.0 Version
INSERT INTO product_version (
    product_id,
    version,
    status,
    spec_file_path,
    parameter_schema_path,
    activation_checklist_ref
)
SELECT
    p.product_id,
    '1.1.0',
    'Proposed',
    'specs/fcn-v1.1.0.md',
    'schemas/fcn-v1.1.0-parameters.schema.json',
    'TBD'
FROM product p
WHERE p.product_code = 'FCN'
ON CONFLICT (product_id, version) DO NOTHING;

COMMENT ON TABLE product_version IS 'Version-specific metadata and promotion state; v1.1.0 adds autocall and issuer support';

-- ============================================================================
-- 5. INSERT V1.1.0 BRANCH: fcn-base-nomem-autocall
-- ============================================================================

-- Insert new branch for no-memory + autocall variant
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
    'fcn-base-nomem-autocall',
    'No-memory coupon, autocall enabled, par-recovery, physical settlement',
    'down-in',
    'physical-settlement',
    'no-memory',
    'autocall',
    'par-recovery'
FROM product p
JOIN product_version pv ON p.product_id = pv.product_id
WHERE p.product_code = 'FCN' AND pv.version = '1.1.0'
ON CONFLICT (product_id, version_id, branch_code) DO NOTHING;

COMMENT ON TABLE branch IS 'Taxonomy-specific payoff branches within product version; fcn-base-nomem-autocall added in v1.1.0';

-- ============================================================================
-- 6. INSERT V1.1.0 PARAMETER DEFINITIONS
-- ============================================================================

-- Insert issuer parameter definition
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
    'issuer',
    'string',
    TRUE,
    NULL,
    '{"minLength": 1, "maxLength": 64}'::jsonb,
    'Issuer identifier; must exist in approved issuer whitelist (BR-022)'
FROM product p
JOIN product_version pv ON p.product_id = pv.product_id
WHERE p.product_code = 'FCN' AND pv.version = '1.1.0'
ON CONFLICT (version_id, parameter_name) DO NOTHING;

-- Insert knock_out_barrier_pct parameter definition
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
    'knock_out_barrier_pct',
    'number',
    FALSE,
    NULL,
    '{"minimum": 0, "maximum": 1.30, "exclusiveMinimum": true}'::jsonb,
    'Knock-out (autocall) barrier as decimal ratio; triggers early redemption (BR-020, BR-021)'
FROM product p
JOIN product_version pv ON p.product_id = pv.product_id
WHERE p.product_code = 'FCN' AND pv.version = '1.1.0'
ON CONFLICT (version_id, parameter_name) DO NOTHING;

-- Insert auto_call_observation_logic parameter definition
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
    'auto_call_observation_logic',
    'string',
    FALSE,
    NULL,
    '{"enum": ["all-underlyings"]}'::jsonb,
    'Logic for autocall trigger; required if knock_out_barrier_pct present (BR-021)'
FROM product p
JOIN product_version pv ON p.product_id = pv.product_id
WHERE p.product_code = 'FCN' AND pv.version = '1.1.0'
ON CONFLICT (version_id, parameter_name) DO NOTHING;

-- Insert observation_frequency_months parameter definition
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
    'observation_frequency_months',
    'integer',
    FALSE,
    NULL,
    '{"minimum": 1}'::jsonb,
    'Optional helper: monthly interval between observations (informational)'
FROM product p
JOIN product_version pv ON p.product_id = pv.product_id
WHERE p.product_code = 'FCN' AND pv.version = '1.1.0'
ON CONFLICT (version_id, parameter_name) DO NOTHING;

-- ============================================================================
-- 7. MIGRATION TRACKING
-- ============================================================================

INSERT INTO schema_migrations (migration_id, description)
VALUES ('m0002_fcn_v1_1', 'FCN v1.1.0: Added autocall (knock-out) barrier, issuer parameter, and supporting constraints')
ON CONFLICT (migration_id) DO NOTHING;

-- ============================================================================
-- 8. DATA MIGRATION GUIDANCE (OPTIONAL)
-- ============================================================================

-- For existing v1.0 trades that need to be compatible with v1.1.0 queries:
-- 
-- UPDATE trade
-- SET issuer = 'LEGACY_ISSUER_PLACEHOLDER'
-- WHERE issuer IS NULL AND documentation_version = '1.0.0';
--
-- Note: This is optional and should only be done if required by business rules.
-- By default, v1.0 trades can have NULL issuer (grandfathered).

COMMENT ON SCHEMA public IS 'FCN schema - m0002 (v1.1.0): Extended with autocall and issuer support';

-- End of m0002-fcn-v1_1-autocall-extension.sql
