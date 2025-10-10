-- Migration: m0001-fcn-baseline
-- Description: Core product, branches, taxonomy, parameters, trades for FCN v1.0
-- Author: siripong.s@yuanta.co.th
-- Created: 2025-10-10
-- Depends on: (none - initial migration)

-- ============================================================================
-- 1. CORE PRODUCT TABLES
-- ============================================================================

CREATE TABLE IF NOT EXISTS product (
    product_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_code VARCHAR(50) NOT NULL UNIQUE,
    product_name VARCHAR(200) NOT NULL,
    product_family VARCHAR(100) NOT NULL,
    spec_version VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('Proposed', 'Active', 'Deprecated', 'Removed')),
    owner VARCHAR(200) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_product_code ON product(product_code);
CREATE INDEX idx_product_status ON product(status);

COMMENT ON TABLE product IS 'Product definition and versioning metadata';
COMMENT ON COLUMN product.product_code IS 'Product type identifier (e.g., FCN)';
COMMENT ON COLUMN product.spec_version IS 'Current semantic version';
COMMENT ON COLUMN product.status IS 'Lifecycle status: Proposed, Active, Deprecated, Removed';

-- ============================================================================
-- 2. PRODUCT VERSION MANAGEMENT
-- ============================================================================

CREATE TABLE IF NOT EXISTS product_version (
    version_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES product(product_id) ON DELETE CASCADE,
    version VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('Proposed', 'Active', 'Deprecated', 'Removed')),
    spec_file_path TEXT NOT NULL,
    parameter_schema_path TEXT NOT NULL,
    activation_checklist_ref TEXT,
    release_date DATE,
    deprecated_date DATE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_product_version UNIQUE (product_id, version)
);

CREATE INDEX idx_product_version_product ON product_version(product_id, version);
CREATE INDEX idx_product_version_status ON product_version(status);

COMMENT ON TABLE product_version IS 'Version-specific metadata and promotion state';
COMMENT ON COLUMN product_version.activation_checklist_ref IS 'Reference to activation checklist issue/document';

-- ============================================================================
-- 3. TAXONOMY & BRANCH DEFINITIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS branch (
    branch_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES product(product_id) ON DELETE CASCADE,
    version_id UUID NOT NULL REFERENCES product_version(version_id) ON DELETE CASCADE,
    branch_code VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    barrier_type VARCHAR(50) NOT NULL,
    settlement VARCHAR(50) NOT NULL,
    coupon_memory VARCHAR(50) NOT NULL,
    step_feature VARCHAR(50) NOT NULL,
    recovery_mode VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_branch_code UNIQUE (product_id, version_id, branch_code)
);

CREATE INDEX idx_branch_product_version ON branch(product_id, version_id);
CREATE INDEX idx_branch_taxonomy ON branch(barrier_type, settlement, coupon_memory, step_feature, recovery_mode);

COMMENT ON TABLE branch IS 'Taxonomy-specific payoff branches within product version';
COMMENT ON COLUMN branch.branch_code IS 'Short identifier (e.g., fcn-base-mem)';

-- ============================================================================
-- 4. PARAMETER DEFINITIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS parameter_definition (
    parameter_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID NOT NULL REFERENCES product_version(version_id) ON DELETE CASCADE,
    parameter_name VARCHAR(100) NOT NULL,
    parameter_type VARCHAR(50) NOT NULL CHECK (parameter_type IN ('string', 'number', 'boolean', 'date', 'array', 'object')),
    required BOOLEAN NOT NULL DEFAULT FALSE,
    default_value TEXT,
    constraints JSONB,
    description TEXT NOT NULL,
    deprecated BOOLEAN NOT NULL DEFAULT FALSE,
    alias_of UUID REFERENCES parameter_definition(parameter_id) ON DELETE SET NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_parameter_version UNIQUE (version_id, parameter_name)
);

CREATE INDEX idx_parameter_version ON parameter_definition(version_id);
CREATE INDEX idx_parameter_name ON parameter_definition(parameter_name);
CREATE INDEX idx_parameter_deprecated ON parameter_definition(deprecated);

COMMENT ON TABLE parameter_definition IS 'Parameter metadata for product version';
COMMENT ON COLUMN parameter_definition.alias_of IS 'Foreign key to superseded parameter if aliased';

-- ============================================================================
-- 5. TRADE INSTANCES
-- ============================================================================

CREATE TABLE IF NOT EXISTS trade (
    trade_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES product(product_id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL REFERENCES branch(branch_id) ON DELETE RESTRICT,
    trade_date DATE NOT NULL,
    issue_date DATE NOT NULL,
    maturity_date DATE NOT NULL,
    notional NUMERIC(20, 4) NOT NULL CHECK (notional > 0),
    currency CHAR(3) NOT NULL,
    observation_style VARCHAR(20) NOT NULL CHECK (observation_style IN ('american', 'european')),
    knock_in_barrier_pct NUMERIC(5, 4) NOT NULL CHECK (knock_in_barrier_pct > 0 AND knock_in_barrier_pct <= 1),
    coupon_rate_pct NUMERIC(5, 4) NOT NULL CHECK (coupon_rate_pct >= 0),
    coupon_barrier_pct NUMERIC(5, 4) CHECK (coupon_barrier_pct >= 0 AND coupon_barrier_pct <= 1),
    is_memory_coupon BOOLEAN NOT NULL,
    recovery_mode VARCHAR(50) NOT NULL CHECK (recovery_mode IN ('par-recovery', 'proportional-loss')),
    settlement_type VARCHAR(50) NOT NULL CHECK (settlement_type IN ('physical-settlement', 'cash-settlement')),
    fx_reference VARCHAR(100),
    documentation_version VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_trade_dates CHECK (trade_date <= issue_date AND issue_date < maturity_date)
);

CREATE INDEX idx_trade_product_branch ON trade(product_id, branch_id);
CREATE INDEX idx_trade_date ON trade(trade_date);
CREATE INDEX idx_trade_maturity ON trade(maturity_date);

COMMENT ON TABLE trade IS 'Individual FCN trade instances';
COMMENT ON COLUMN trade.observation_style IS 'Barrier monitoring: american (continuous) or european (discrete)';

-- ============================================================================
-- 6. UNDERLYING ASSETS
-- ============================================================================

CREATE TABLE IF NOT EXISTS underlying_asset (
    asset_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trade_id UUID NOT NULL REFERENCES trade(trade_id) ON DELETE CASCADE,
    symbol VARCHAR(50) NOT NULL,
    initial_level NUMERIC(20, 8) NOT NULL CHECK (initial_level > 0),
    weight NUMERIC(5, 4) CHECK (weight >= 0 AND weight <= 1),
    asset_type VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_underlying_trade ON underlying_asset(trade_id);
CREATE INDEX idx_underlying_symbol ON underlying_asset(symbol);

COMMENT ON TABLE underlying_asset IS 'Links trades to underlying assets with initial levels and weights';

-- ============================================================================
-- 7. TEST VECTORS (Linkage only - detailed vectors stored in files)
-- ============================================================================

CREATE TABLE IF NOT EXISTS test_vector (
    vector_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES product(product_id) ON DELETE CASCADE,
    version_id UUID NOT NULL REFERENCES product_version(version_id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branch(branch_id) ON DELETE SET NULL,
    vector_code VARCHAR(200) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    normative BOOLEAN NOT NULL DEFAULT FALSE,
    parameters_json JSONB NOT NULL,
    market_scenario_json JSONB,
    expected_outputs_json JSONB NOT NULL,
    tags TEXT[],
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_test_vector_product_version ON test_vector(product_id, version_id);
CREATE INDEX idx_test_vector_normative ON test_vector(normative);
CREATE INDEX idx_test_vector_code ON test_vector(vector_code);

COMMENT ON TABLE test_vector IS 'Test cases for validation and regression';
COMMENT ON COLUMN test_vector.normative IS 'Whether test is part of normative set for promotion';

-- ============================================================================
-- 8. SEED DATA - FCN v1.0 BASELINE
-- ============================================================================

-- Insert FCN Product
INSERT INTO product (product_code, product_name, product_family, spec_version, status, owner)
VALUES ('FCN', 'Fixed Coupon Note', 'structured-notes', '1.0.0', 'Proposed', 'siripong.s@yuanta.co.th')
ON CONFLICT (product_code) DO NOTHING;

-- Insert FCN v1.0 Version
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
    '1.0.0',
    'Proposed',
    'specs/fcn-v1.0.md',
    'schemas/fcn-v1.0-parameters.schema.json',
    'specs/_activation-checklist-template.md'
FROM product p
WHERE p.product_code = 'FCN'
ON CONFLICT (product_id, version) DO NOTHING;

-- Insert FCN v1.0 Branches
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
    'fcn-base-mem',
    'Memory coupon, par-recovery, physical settlement',
    'down-in',
    'physical-settlement',
    'memory',
    'no-step',
    'par-recovery'
FROM product p
JOIN product_version pv ON p.product_id = pv.product_id
WHERE p.product_code = 'FCN' AND pv.version = '1.0.0'
ON CONFLICT (product_id, version_id, branch_code) DO NOTHING;

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
    'fcn-base-nomem',
    'No-memory coupon, par-recovery, physical settlement',
    'down-in',
    'physical-settlement',
    'no-memory',
    'no-step',
    'par-recovery'
FROM product p
JOIN product_version pv ON p.product_id = pv.product_id
WHERE p.product_code = 'FCN' AND pv.version = '1.0.0'
ON CONFLICT (product_id, version_id, branch_code) DO NOTHING;

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
    'fcn-base-mem-proploss',
    'Memory coupon, proportional-loss, physical settlement',
    'down-in',
    'physical-settlement',
    'memory',
    'no-step',
    'proportional-loss'
FROM product p
JOIN product_version pv ON p.product_id = pv.product_id
WHERE p.product_code = 'FCN' AND pv.version = '1.0.0'
ON CONFLICT (product_id, version_id, branch_code) DO NOTHING;

-- Insert FCN v1.0 Parameter Definitions (subset - core parameters)
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
    'product_code',
    'string',
    TRUE,
    NULL,
    '{"pattern": "^FCN$"}'::jsonb,
    'Product identifier; must be FCN'
FROM product p
JOIN product_version pv ON p.product_id = pv.product_id
WHERE p.product_code = 'FCN' AND pv.version = '1.0.0'
ON CONFLICT (version_id, parameter_name) DO NOTHING;

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
    'spec_version',
    'string',
    TRUE,
    NULL,
    '{"pattern": "^1\\.0\\.\\d+$"}'::jsonb,
    'Specification version; must match v1.0.x'
FROM product p
JOIN product_version pv ON p.product_id = pv.product_id
WHERE p.product_code = 'FCN' AND pv.version = '1.0.0'
ON CONFLICT (version_id, parameter_name) DO NOTHING;

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
    'notional',
    'number',
    TRUE,
    NULL,
    '{"minimum": 0, "exclusiveMinimum": true}'::jsonb,
    'Notional amount; must be positive'
FROM product p
JOIN product_version pv ON p.product_id = pv.product_id
WHERE p.product_code = 'FCN' AND pv.version = '1.0.0'
ON CONFLICT (version_id, parameter_name) DO NOTHING;

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
    'is_memory_coupon',
    'boolean',
    TRUE,
    NULL,
    NULL,
    'True if unpaid coupons accumulate and pay later; false otherwise'
FROM product p
JOIN product_version pv ON p.product_id = pv.product_id
WHERE p.product_code = 'FCN' AND pv.version = '1.0.0'
ON CONFLICT (version_id, parameter_name) DO NOTHING;

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
    'recovery_mode',
    'string',
    TRUE,
    NULL,
    '{"enum": ["par-recovery", "proportional-loss"]}'::jsonb,
    'Post knock-in payoff mode: par-recovery (100% notional) or proportional-loss (worst performance)'
FROM product p
JOIN product_version pv ON p.product_id = pv.product_id
WHERE p.product_code = 'FCN' AND pv.version = '1.0.0'
ON CONFLICT (version_id, parameter_name) DO NOTHING;

-- ============================================================================
-- 9. COMMENTS & METADATA
-- ============================================================================

COMMENT ON SCHEMA public IS 'FCN v1.0 baseline schema - m0001';

-- ============================================================================
-- 10. MIGRATION TRACKING
-- ============================================================================

CREATE TABLE IF NOT EXISTS schema_migrations (
    migration_id VARCHAR(50) PRIMARY KEY,
    description TEXT NOT NULL,
    applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO schema_migrations (migration_id, description)
VALUES ('m0001', 'Core product, branches, taxonomy, parameters, trades for FCN v1.0')
ON CONFLICT (migration_id) DO NOTHING;

-- End of m0001-fcn-baseline.sql
