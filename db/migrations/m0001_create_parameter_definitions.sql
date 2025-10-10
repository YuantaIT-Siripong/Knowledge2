-- Migration: m0001_create_parameter_definitions
-- Description: Create parameter_definitions table for FCN parameter metadata
-- Author: System
-- Created: 2025-10-10

CREATE TABLE IF NOT EXISTS parameter_definitions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    data_type TEXT NOT NULL,
    required_flag BOOLEAN NOT NULL DEFAULT 0,
    default_value TEXT,
    enum_domain TEXT,
    min_value NUMERIC,
    max_value NUMERIC,
    pattern TEXT,
    description TEXT,
    constraints TEXT,
    product_type TEXT DEFAULT 'fcn',
    spec_version TEXT DEFAULT '1.0.0',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on name for faster lookups
CREATE INDEX IF NOT EXISTS idx_parameter_definitions_name ON parameter_definitions(name);

-- Create index on product_type and spec_version for filtering
CREATE INDEX IF NOT EXISTS idx_parameter_definitions_product_spec 
    ON parameter_definitions(product_type, spec_version);
