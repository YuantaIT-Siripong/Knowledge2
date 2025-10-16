-- Migration: m0009-fcn-template-schema
-- Description: FCN product shelf template schema (SQL Server) - two-layer data model separating template from trade instance
-- Author: siripong.s@yuanta.co.th
-- Created: 2025-10-16
-- Depends on: (fcn_trade table assumed to exist)
-- Version: FCN v1.1+

-- ============================================================================
-- OVERVIEW
-- ============================================================================
-- This migration introduces a "product shelf" layer for FCN templates.
-- Templates define reusable product structures with parameters aligned to
-- Yuanta spec (step-down KO support, settlement lag, share delivery settings,
-- coupon annual vs per period). Trade instances reference templates via
-- template_id foreign key.
--
-- SCOPE:
-- - fcn_template: Core template metadata and product parameters
-- - fcn_template_underlying: Underlying basket composition per template
-- - fcn_template_observation_schedule: Observation dates (autocall/coupon)
--
-- ALIGNMENT:
-- - Step-down knock-out barriers (multiple KO levels)
-- - Settlement lag configuration
-- - Share delivery settings
-- - Coupon rate (annual vs per-period)
-- ============================================================================

-- ============================================================================
-- 1. FCN_TEMPLATE TABLE
-- ============================================================================
-- Core template metadata and product parameters

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'fcn_template' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE fcn_template (
        template_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        template_code NVARCHAR(100) NOT NULL UNIQUE,
        template_name NVARCHAR(200) NOT NULL,
        template_description NVARCHAR(MAX),
        
        -- Product classification
        product_family NVARCHAR(100) NOT NULL DEFAULT 'FCN',
        spec_version NVARCHAR(20) NOT NULL,
        branch_code NVARCHAR(100),
        
        -- Lifecycle metadata
        status NVARCHAR(20) NOT NULL CHECK (status IN ('Draft', 'Active', 'Deprecated', 'Removed')) DEFAULT 'Draft',
        effective_date DATE,
        expiry_date DATE,
        
        -- Core FCN parameters (common across all trades from this template)
        currency NVARCHAR(3) NOT NULL,
        tenor_months INT NOT NULL CHECK (tenor_months > 0),
        knock_in_barrier_pct DECIMAL(9, 6) NOT NULL CHECK (knock_in_barrier_pct > 0 AND knock_in_barrier_pct <= 1.0),
        put_strike_pct DECIMAL(9, 6) CHECK (put_strike_pct > 0 AND put_strike_pct <= 1.0),
        coupon_rate_pct DECIMAL(9, 6) NOT NULL CHECK (coupon_rate_pct >= 0),
        coupon_condition_threshold_pct DECIMAL(9, 6) NOT NULL CHECK (coupon_condition_threshold_pct > 0 AND coupon_condition_threshold_pct <= 1.5),
        
        -- Coupon settings
        coupon_memory BIT NOT NULL DEFAULT 0,
        coupon_rate_type NVARCHAR(20) NOT NULL CHECK (coupon_rate_type IN ('per-period', 'annual')) DEFAULT 'per-period',
        
        -- Autocall / Knock-out configuration
        knock_out_barrier_pct DECIMAL(9, 6) CHECK (knock_out_barrier_pct IS NULL OR (knock_out_barrier_pct > 0 AND knock_out_barrier_pct <= 1.30)),
        auto_call_observation_logic NVARCHAR(32) CHECK (auto_call_observation_logic IS NULL OR auto_call_observation_logic = 'all-underlyings'),
        
        -- Settlement configuration
        settlement_type NVARCHAR(50) NOT NULL CHECK (settlement_type IN ('cash', 'physical-worst-of')) DEFAULT 'cash',
        settlement_lag_days INT NOT NULL DEFAULT 2 CHECK (settlement_lag_days >= 0),
        recovery_mode NVARCHAR(50) NOT NULL CHECK (recovery_mode IN ('par-recovery', 'proportional-loss', 'capital-at-risk')) DEFAULT 'par-recovery',
        
        -- Share delivery settings (physical settlement)
        share_delivery_enabled BIT NOT NULL DEFAULT 0,
        share_delivery_rounding NVARCHAR(20) CHECK (share_delivery_rounding IS NULL OR share_delivery_rounding IN ('floor', 'round', 'ceiling')) DEFAULT 'floor',
        fractional_share_cash_settlement BIT DEFAULT 1,
        
        -- Monitoring
        barrier_monitoring_type NVARCHAR(20) NOT NULL CHECK (barrier_monitoring_type IN ('discrete', 'continuous')) DEFAULT 'discrete',
        
        -- Issuer
        issuer NVARCHAR(64),
        
        -- Step-down knock-out support
        step_down_enabled BIT NOT NULL DEFAULT 0,
        
        -- Audit fields
        created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
        updated_at DATETIME2 NOT NULL DEFAULT GETDATE(),
        created_by NVARCHAR(100),
        updated_by NVARCHAR(100),
        
        -- Business constraints
        CONSTRAINT chk_put_strike_ordering CHECK (
            put_strike_pct IS NULL OR knock_in_barrier_pct < put_strike_pct
        ),
        CONSTRAINT chk_autocall_logic_required CHECK (
            (knock_out_barrier_pct IS NULL AND auto_call_observation_logic IS NULL)
            OR (knock_out_barrier_pct IS NOT NULL AND auto_call_observation_logic IS NOT NULL)
        ),
        CONSTRAINT chk_share_delivery_physical_only CHECK (
            (share_delivery_enabled = 0)
            OR (share_delivery_enabled = 1 AND settlement_type = 'physical-worst-of')
        )
    );
    
    -- Indexes
    CREATE INDEX idx_fcn_template_code ON fcn_template(template_code);
    CREATE INDEX idx_fcn_template_status ON fcn_template(status);
    CREATE INDEX idx_fcn_template_family_version ON fcn_template(product_family, spec_version);
END
GO

-- Table comments
EXEC sys.sp_addextendedproperty 
    @name = N'MS_Description',
    @value = N'FCN product shelf template defining reusable product structures',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fcn_template';
GO

-- ============================================================================
-- 2. FCN_TEMPLATE_UNDERLYING TABLE
-- ============================================================================
-- Underlying basket composition per template

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'fcn_template_underlying' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE fcn_template_underlying (
        template_underlying_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        template_id UNIQUEIDENTIFIER NOT NULL,
        underlying_code NVARCHAR(50) NOT NULL,
        underlying_name NVARCHAR(200),
        weight DECIMAL(9, 6) NOT NULL CHECK (weight > 0 AND weight <= 1.0),
        sequence_no INT NOT NULL CHECK (sequence_no > 0),
        
        -- Reference data hints
        asset_class NVARCHAR(50),
        exchange NVARCHAR(50),
        currency NVARCHAR(3),
        
        -- Audit fields
        created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
        
        CONSTRAINT fk_template_underlying_template 
            FOREIGN KEY (template_id) REFERENCES fcn_template(template_id) ON DELETE CASCADE,
        CONSTRAINT uq_template_underlying_code 
            UNIQUE (template_id, underlying_code),
        CONSTRAINT uq_template_underlying_sequence 
            UNIQUE (template_id, sequence_no)
    );
    
    -- Indexes
    CREATE INDEX idx_fcn_template_underlying_template ON fcn_template_underlying(template_id);
END
GO

-- Table comments
EXEC sys.sp_addextendedproperty 
    @name = N'MS_Description',
    @value = N'Underlying basket composition for FCN templates',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fcn_template_underlying';
GO

-- ============================================================================
-- 3. FCN_TEMPLATE_OBSERVATION_SCHEDULE TABLE
-- ============================================================================
-- Observation dates for autocall and coupon evaluation

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'fcn_template_observation_schedule' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE fcn_template_observation_schedule (
        observation_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        template_id UNIQUEIDENTIFIER NOT NULL,
        observation_type NVARCHAR(20) NOT NULL CHECK (observation_type IN ('autocall', 'coupon', 'maturity')),
        observation_offset_months INT NOT NULL CHECK (observation_offset_months >= 0),
        observation_label NVARCHAR(50),
        
        -- Step-down knock-out barrier (only for autocall observations)
        step_down_ko_barrier_pct DECIMAL(9, 6) CHECK (
            step_down_ko_barrier_pct IS NULL 
            OR (observation_type = 'autocall' AND step_down_ko_barrier_pct > 0 AND step_down_ko_barrier_pct <= 1.30)
        ),
        
        -- Maturity flag (only one observation can be maturity)
        is_maturity BIT NOT NULL DEFAULT 0,
        
        -- Audit fields
        created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
        
        CONSTRAINT fk_template_observation_template 
            FOREIGN KEY (template_id) REFERENCES fcn_template(template_id) ON DELETE CASCADE,
        CONSTRAINT uq_template_observation_offset 
            UNIQUE (template_id, observation_offset_months)
    );
    
    -- Indexes
    CREATE INDEX idx_fcn_template_observation_template ON fcn_template_observation_schedule(template_id);
    CREATE INDEX idx_fcn_template_observation_type ON fcn_template_observation_schedule(template_id, observation_type);
END
GO

-- Table comments
EXEC sys.sp_addextendedproperty 
    @name = N'MS_Description',
    @value = N'Observation schedule for FCN templates (autocall, coupon, maturity)',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fcn_template_observation_schedule';
GO

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- After applying this migration, verify that:
-- 1. All three tables created successfully
-- 2. Foreign key constraints are in place
-- 3. Check constraints validate parameter ranges
-- 4. Indexes support common query patterns
-- 5. Template can be linked to trades via template_id (see m0011)

-- ============================================================================
-- NOTES
-- ============================================================================
-- - This migration is idempotent (safe to run multiple times)
-- - Step-down KO barriers are stored per observation in the schedule table
-- - Coupon rate type distinguishes annual vs per-period rates
-- - Settlement lag and share delivery settings align with physical settlement
-- - Template status lifecycle: Draft → Active → Deprecated → Removed
-- - Templates do not replace trades; they provide a lineage/reference layer

--
-- IMPORTANT: Schema Harmonization (v1.0.1)
-- - After applying this migration, run m0012-fcn-template-harmonization.sql
--   to align settlement_type values with FCN v1.1 canonical schema
-- - m0012 updates: 'cash' → 'cash-settlement', 'physical-worst-of' → 'physical-settlement'
-- - m0012 also changes default recovery_mode to 'capital-at-risk'
-- ============================================================================
