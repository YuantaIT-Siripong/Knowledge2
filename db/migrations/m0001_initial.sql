-- m0001_initial.sql
-- Purpose: Core schema objects for FCN v1.0 foundation (product, branches, parameters, trades).
-- Note: Event & validation related tables will be added in subsequent migrations.

BEGIN;

CREATE TABLE product_versions (
  id BIGSERIAL PRIMARY KEY,
  product_code TEXT NOT NULL,
  spec_version TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'Draft',
  activation_issue_url TEXT,
  manifest_path TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_product_version UNIQUE (product_code, spec_version)
);

CREATE TABLE product_branches (
  id BIGSERIAL PRIMARY KEY,
  product_version_id BIGINT NOT NULL REFERENCES product_versions(id) ON DELETE CASCADE,
  branch_code TEXT NOT NULL,
  taxonomy_tuple JSONB NOT NULL,
  is_normative BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_branch_code_per_version UNIQUE (product_version_id, branch_code)
);

CREATE TABLE taxonomy_dimensions (
  id BIGSERIAL PRIMARY KEY,
  product_version_id BIGINT NOT NULL REFERENCES product_versions(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  allowed_values TEXT[] NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_taxonomy_dimension UNIQUE (product_version_id, name)
);

CREATE TABLE taxonomy_assignments (
  id BIGSERIAL PRIMARY KEY,
  product_branch_id BIGINT NOT NULL REFERENCES product_branches(id) ON DELETE CASCADE,
  dimension_name TEXT NOT NULL,
  value TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_taxonomy_assignment UNIQUE (product_branch_id, dimension_name)
);

CREATE TABLE parameter_definitions (
  id BIGSERIAL PRIMARY KEY,
  product_version_id BIGINT NOT NULL REFERENCES product_versions(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  data_type TEXT NOT NULL,
  required_flag BOOLEAN NOT NULL DEFAULT FALSE,
  default_value TEXT,
  enum_domain TEXT[],
  min_value NUMERIC,
  max_value NUMERIC,
  pattern TEXT,
  deprecated_flag BOOLEAN NOT NULL DEFAULT FALSE,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_param_name_per_version UNIQUE (product_version_id, name)
);

CREATE TABLE trades (
  id BIGSERIAL PRIMARY KEY,
  product_version_id BIGINT NOT NULL REFERENCES product_versions(id) ON DELETE RESTRICT,
  product_branch_id BIGINT NOT NULL REFERENCES product_branches(id) ON DELETE RESTRICT,
  trade_ref TEXT NOT NULL,
  trade_date DATE NOT NULL,
  issue_date DATE NOT NULL,
  maturity_date DATE NOT NULL,
  notional_amount NUMERIC(20,4) NOT NULL,
  currency CHAR(3) NOT NULL,
  settlement_type TEXT NOT NULL,
  recovery_mode TEXT NOT NULL,
  parameter_payload JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_trade_ref UNIQUE (trade_ref),
  CONSTRAINT ck_dates_order CHECK (issue_date >= trade_date AND maturity_date > issue_date)
);

CREATE TABLE trade_underlyings (
  id BIGSERIAL PRIMARY KEY,
  trade_id BIGINT NOT NULL REFERENCES trades(id) ON DELETE CASCADE,
  idx INT NOT NULL,
  symbol TEXT NOT NULL,
  initial_level NUMERIC(20,8) NOT NULL,
  weight NUMERIC(12,6),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_underlying_idx UNIQUE (trade_id, idx),
  CONSTRAINT uq_underlying_symbol UNIQUE (trade_id, symbol),
  CONSTRAINT ck_initial_level_positive CHECK (initial_level > 0),
  CONSTRAINT ck_weight_nonnegative CHECK (weight IS NULL OR weight >= 0)
);

-- Index recommendations
CREATE INDEX idx_product_branches_version ON product_branches(product_version_id);
CREATE INDEX idx_parameter_defs_version ON parameter_definitions(product_version_id);
CREATE INDEX idx_trades_version ON trades(product_version_id);
CREATE INDEX idx_trades_branch ON trades(product_branch_id);

COMMIT;