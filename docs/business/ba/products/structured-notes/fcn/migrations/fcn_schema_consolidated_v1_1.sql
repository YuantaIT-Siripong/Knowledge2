-- ============================================================================
-- Migration: fcn_schema_consolidated_v1_1.sql
-- Description: Consolidated FCN v1.1 Data Model for SQL Server
-- Author: copilot (consolidation)
-- Created: 2025-10-16
-- Version: FCN v1.1 (Consolidated Schema)
-- Supersedes: m0001-fcn-baseline.sql, m0002-fcn-v1_1-autocall-extension.sql,
--             m0003-fcn-v1_1-put-strike-extension.sql, m0004-fcn-v1_1-capital-at-risk-recovery-mode.sql
-- ============================================================================
--
-- OVERVIEW
-- ============================================================================
-- This migration provides a single authoritative schema for FCN v1.1 on SQL Server.
-- It consolidates all incremental migrations (m0001–m0004) and aligns with the
-- template layer (m0009-m0012) for production use.
--
-- SCOPE:
-- 1. Issuer whitelist for counterparty risk management
-- 2. Template layer: fcn_template, fcn_template_underlying, fcn_template_observation_schedule
-- 3. Trade layer: fcn_trade, fcn_underlying, fcn_observation, fcn_coupon_cashflow, fcn_event, fcn_settlement
-- 4. Validation: usp_FCN_ValidateTemplate procedure + trg_FCN_ValidateTemplate trigger
--
-- HARMONIZED NAMING:
-- - settlement_type values: 'cash-settlement', 'physical-settlement' (not 'cash' or 'physical-worst-of')
-- - recovery_mode default: 'capital-at-risk' (not 'par-recovery')
-- - Share delivery constraint: requires physical-settlement + capital-at-risk + put_strike_pct
--
-- IDEMPOTENCY:
-- - Uses IF NOT EXISTS / IF OBJECT_ID guards
-- - Safe to run multiple times
-- - Prints warnings if objects already exist
--
-- USAGE:
-- - Run on a clean SQL Server database for new environments
-- - For existing databases, ensure no conflicts with legacy migrations
-- ============================================================================

SET NOCOUNT ON;
PRINT '=== FCN v1.1 Consolidated Schema Migration ===';
PRINT 'Starting at: ' + CONVERT(NVARCHAR(30), GETDATE(), 120);
GO

-- ============================================================================
-- SECTION 1: ISSUER WHITELIST
-- ============================================================================

PRINT '';
PRINT '=== Section 1: Creating Issuer Whitelist ===';

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'issuer_whitelist' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE issuer_whitelist (
        issuer_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        issuer_code NVARCHAR(64) NOT NULL UNIQUE,
        issuer_name NVARCHAR(200) NOT NULL,
        country_code NCHAR(2),
        rating NVARCHAR(20),
        status NVARCHAR(20) NOT NULL CHECK (status IN ('Active', 'Suspended', 'Inactive')) DEFAULT 'Active',
        approval_date DATE,
        expiry_date DATE,
        notes NVARCHAR(MAX),
        created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
        updated_at DATETIME2 NOT NULL DEFAULT GETDATE(),
        created_by NVARCHAR(100),
        updated_by NVARCHAR(100)
    );
    
    CREATE INDEX idx_issuer_whitelist_code ON issuer_whitelist(issuer_code);
    CREATE INDEX idx_issuer_whitelist_status ON issuer_whitelist(status);
    
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description',
        @value = N'Approved issuer whitelist for FCN products (BR-022)',
        @level0type = N'SCHEMA', @level0name = N'dbo',
        @level1type = N'TABLE', @level1name = N'issuer_whitelist';
    
    PRINT 'Created issuer_whitelist table';
END
ELSE
BEGIN
    PRINT 'WARNING: issuer_whitelist table already exists, skipping creation';
END
GO

-- ============================================================================
-- SECTION 2: TEMPLATE LAYER
-- ============================================================================

PRINT '';
PRINT '=== Section 2: Creating Template Layer ===';

-- ----------------------------------------------------------------------------
-- 2.1 FCN_TEMPLATE
-- ----------------------------------------------------------------------------

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
        
        -- Core FCN parameters
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
        
        -- Settlement configuration (harmonized naming)
        settlement_type NVARCHAR(50) NOT NULL CHECK (settlement_type IN ('cash-settlement', 'physical-settlement')) DEFAULT 'cash-settlement',
        settlement_lag_days INT NOT NULL DEFAULT 2 CHECK (settlement_lag_days >= 0),
        recovery_mode NVARCHAR(50) NOT NULL CHECK (recovery_mode IN ('par-recovery', 'proportional-loss', 'capital-at-risk')) DEFAULT 'capital-at-risk',
        
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
        CONSTRAINT chk_share_delivery_physical_settlement CHECK (
            (share_delivery_enabled = 0)
            OR (share_delivery_enabled = 1 
                AND settlement_type = 'physical-settlement' 
                AND recovery_mode = 'capital-at-risk'
                AND put_strike_pct IS NOT NULL)
        ),
        CONSTRAINT chk_capital_at_risk_requires_put_strike CHECK (
            (recovery_mode != 'capital-at-risk')
            OR (recovery_mode = 'capital-at-risk' AND put_strike_pct IS NOT NULL)
        )
    );
    
    CREATE INDEX idx_fcn_template_code ON fcn_template(template_code);
    CREATE INDEX idx_fcn_template_status ON fcn_template(status);
    CREATE INDEX idx_fcn_template_family_version ON fcn_template(product_family, spec_version);
    
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description',
        @value = N'FCN product shelf template defining reusable product structures',
        @level0type = N'SCHEMA', @level0name = N'dbo',
        @level1type = N'TABLE', @level1name = N'fcn_template';
    
    PRINT 'Created fcn_template table';
END
ELSE
BEGIN
    PRINT 'WARNING: fcn_template table already exists, skipping creation';
END
GO

-- ----------------------------------------------------------------------------
-- 2.2 FCN_TEMPLATE_UNDERLYING
-- ----------------------------------------------------------------------------

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
    
    CREATE INDEX idx_fcn_template_underlying_template ON fcn_template_underlying(template_id);
    
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description',
        @value = N'Underlying basket composition for FCN templates',
        @level0type = N'SCHEMA', @level0name = N'dbo',
        @level1type = N'TABLE', @level1name = N'fcn_template_underlying';
    
    PRINT 'Created fcn_template_underlying table';
END
ELSE
BEGIN
    PRINT 'WARNING: fcn_template_underlying table already exists, skipping creation';
END
GO

-- ----------------------------------------------------------------------------
-- 2.3 FCN_TEMPLATE_OBSERVATION_SCHEDULE
-- ----------------------------------------------------------------------------

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
    
    CREATE INDEX idx_fcn_template_observation_template ON fcn_template_observation_schedule(template_id);
    CREATE INDEX idx_fcn_template_observation_type ON fcn_template_observation_schedule(template_id, observation_type);
    
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description',
        @value = N'Observation schedule for FCN templates (autocall, coupon, maturity)',
        @level0type = N'SCHEMA', @level0name = N'dbo',
        @level1type = N'TABLE', @level1name = N'fcn_template_observation_schedule';
    
    PRINT 'Created fcn_template_observation_schedule table';
END
ELSE
BEGIN
    PRINT 'WARNING: fcn_template_observation_schedule table already exists, skipping creation';
END
GO

-- ============================================================================
-- SECTION 3: TRADE LAYER
-- ============================================================================

PRINT '';
PRINT '=== Section 3: Creating Trade Layer ===';

-- ----------------------------------------------------------------------------
-- 3.1 FCN_TRADE
-- ----------------------------------------------------------------------------

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'fcn_trade' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE fcn_trade (
        trade_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        template_id UNIQUEIDENTIFIER NULL,
        
        -- Product identification
        product_code NVARCHAR(50) NOT NULL DEFAULT 'FCN',
        spec_version NVARCHAR(20) NOT NULL,
        documentation_version NVARCHAR(20) NOT NULL,
        
        -- Trade dates
        trade_date DATE NOT NULL,
        issue_date DATE NOT NULL,
        maturity_date DATE NOT NULL,
        
        -- Notional and currency
        notional DECIMAL(20, 4) NOT NULL CHECK (notional > 0),
        currency NCHAR(3) NOT NULL,
        
        -- Issuer
        issuer NVARCHAR(64),
        
        -- Barrier levels
        knock_in_barrier_pct DECIMAL(9, 6) NOT NULL CHECK (knock_in_barrier_pct > 0 AND knock_in_barrier_pct <= 1.0),
        put_strike_pct DECIMAL(9, 6) CHECK (put_strike_pct > 0 AND put_strike_pct <= 1.0),
        knock_out_barrier_pct DECIMAL(9, 6) CHECK (knock_out_barrier_pct IS NULL OR (knock_out_barrier_pct > 0 AND knock_out_barrier_pct <= 1.30)),
        
        -- Coupon parameters
        coupon_rate_pct DECIMAL(9, 6) NOT NULL CHECK (coupon_rate_pct >= 0),
        coupon_condition_threshold_pct DECIMAL(9, 6) NOT NULL CHECK (coupon_condition_threshold_pct > 0 AND coupon_condition_threshold_pct <= 1.5),
        is_memory_coupon BIT NOT NULL DEFAULT 0,
        
        -- Recovery and settlement (harmonized)
        recovery_mode NVARCHAR(50) NOT NULL CHECK (recovery_mode IN ('par-recovery', 'proportional-loss', 'capital-at-risk')) DEFAULT 'capital-at-risk',
        settlement_type NVARCHAR(50) NOT NULL CHECK (settlement_type IN ('cash-settlement', 'physical-settlement')) DEFAULT 'cash-settlement',
        
        -- Monitoring and observation
        barrier_monitoring_type NVARCHAR(20) NOT NULL CHECK (barrier_monitoring_type IN ('discrete', 'continuous')) DEFAULT 'discrete',
        auto_call_observation_logic NVARCHAR(32) CHECK (auto_call_observation_logic IS NULL OR auto_call_observation_logic = 'all-underlyings'),
        
        -- Day count and FX reference
        day_count_convention NVARCHAR(20),
        fx_reference NVARCHAR(100),
        
        -- Audit fields
        created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
        updated_at DATETIME2 NOT NULL DEFAULT GETDATE(),
        created_by NVARCHAR(100),
        updated_by NVARCHAR(100),
        
        -- Business constraints
        CONSTRAINT chk_trade_dates CHECK (trade_date <= issue_date AND issue_date < maturity_date),
        CONSTRAINT chk_trade_put_strike_ordering CHECK (
            put_strike_pct IS NULL OR knock_in_barrier_pct < put_strike_pct
        ),
        CONSTRAINT chk_trade_autocall_logic_required CHECK (
            (knock_out_barrier_pct IS NULL AND auto_call_observation_logic IS NULL)
            OR (knock_out_barrier_pct IS NOT NULL AND auto_call_observation_logic IS NOT NULL)
        ),
        CONSTRAINT chk_trade_capital_at_risk_requires_put_strike CHECK (
            (recovery_mode != 'capital-at-risk')
            OR (recovery_mode = 'capital-at-risk' AND put_strike_pct IS NOT NULL)
        ),
        CONSTRAINT fk_fcn_trade_template FOREIGN KEY (template_id) REFERENCES fcn_template(template_id) ON DELETE SET NULL
    );
    
    CREATE INDEX idx_fcn_trade_template ON fcn_trade(template_id) WHERE template_id IS NOT NULL;
    CREATE INDEX idx_fcn_trade_product ON fcn_trade(product_code, spec_version);
    CREATE INDEX idx_fcn_trade_dates ON fcn_trade(trade_date, maturity_date);
    CREATE INDEX idx_fcn_trade_issuer ON fcn_trade(issuer) WHERE issuer IS NOT NULL;
    
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description',
        @value = N'FCN trade instances with full product parameters',
        @level0type = N'SCHEMA', @level0name = N'dbo',
        @level1type = N'TABLE', @level1name = N'fcn_trade';
    
    PRINT 'Created fcn_trade table';
END
ELSE
BEGIN
    PRINT 'WARNING: fcn_trade table already exists, skipping creation';
END
GO

-- ----------------------------------------------------------------------------
-- 3.2 FCN_UNDERLYING
-- ----------------------------------------------------------------------------

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'fcn_underlying' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE fcn_underlying (
        underlying_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        trade_id UNIQUEIDENTIFIER NOT NULL,
        underlying_index INT NOT NULL CHECK (underlying_index >= 0),
        symbol NVARCHAR(50) NOT NULL,
        initial_level DECIMAL(20, 8) NOT NULL CHECK (initial_level > 0),
        weight DECIMAL(9, 6) NOT NULL CHECK (weight > 0 AND weight <= 1.0),
        
        -- Reference data
        asset_type NVARCHAR(50),
        exchange NVARCHAR(50),
        currency NVARCHAR(3),
        
        -- Audit fields
        created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
        
        CONSTRAINT fk_fcn_underlying_trade FOREIGN KEY (trade_id) REFERENCES fcn_trade(trade_id) ON DELETE CASCADE,
        CONSTRAINT uq_fcn_underlying_trade_index UNIQUE (trade_id, underlying_index),
        CONSTRAINT uq_fcn_underlying_trade_symbol UNIQUE (trade_id, symbol)
    );
    
    CREATE INDEX idx_fcn_underlying_trade ON fcn_underlying(trade_id);
    CREATE INDEX idx_fcn_underlying_symbol ON fcn_underlying(symbol);
    
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description',
        @value = N'Underlying assets linked to FCN trades with initial fixings',
        @level0type = N'SCHEMA', @level0name = N'dbo',
        @level1type = N'TABLE', @level1name = N'fcn_underlying';
    
    PRINT 'Created fcn_underlying table';
END
ELSE
BEGIN
    PRINT 'WARNING: fcn_underlying table already exists, skipping creation';
END
GO

-- ----------------------------------------------------------------------------
-- 3.3 FCN_OBSERVATION
-- ----------------------------------------------------------------------------

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'fcn_observation' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE fcn_observation (
        observation_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        trade_id UNIQUEIDENTIFIER NOT NULL,
        observation_date DATE NOT NULL,
        observation_type NVARCHAR(20) NOT NULL CHECK (observation_type IN ('autocall', 'coupon', 'maturity', 'barrier-monitoring')),
        underlying_index INT NOT NULL CHECK (underlying_index >= 0),
        spot_level DECIMAL(20, 8) NOT NULL CHECK (spot_level > 0),
        performance_ratio DECIMAL(12, 8),
        
        -- Audit fields
        created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
        data_source NVARCHAR(100),
        
        CONSTRAINT fk_fcn_observation_trade FOREIGN KEY (trade_id) REFERENCES fcn_trade(trade_id) ON DELETE CASCADE,
        CONSTRAINT uq_fcn_observation_trade_date_underlying UNIQUE (trade_id, observation_date, underlying_index)
    );
    
    CREATE INDEX idx_fcn_observation_trade ON fcn_observation(trade_id);
    CREATE INDEX idx_fcn_observation_date ON fcn_observation(observation_date);
    CREATE INDEX idx_fcn_observation_type ON fcn_observation(trade_id, observation_type);
    
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description',
        @value = N'Observation data for FCN trades (spot levels, performance ratios)',
        @level0type = N'SCHEMA', @level0name = N'dbo',
        @level1type = N'TABLE', @level1name = N'fcn_observation';
    
    PRINT 'Created fcn_observation table';
END
ELSE
BEGIN
    PRINT 'WARNING: fcn_observation table already exists, skipping creation';
END
GO

-- ----------------------------------------------------------------------------
-- 3.4 FCN_COUPON_CASHFLOW
-- ----------------------------------------------------------------------------

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'fcn_coupon_cashflow' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE fcn_coupon_cashflow (
        cashflow_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        trade_id UNIQUEIDENTIFIER NOT NULL,
        period_index INT NOT NULL CHECK (period_index >= 0),
        observation_date DATE NOT NULL,
        payment_date DATE NOT NULL,
        coupon_amount DECIMAL(20, 4) NOT NULL,
        coupon_status NVARCHAR(20) NOT NULL CHECK (coupon_status IN ('pending', 'paid', 'forfeited', 'deferred')) DEFAULT 'pending',
        worst_performance DECIMAL(12, 8),
        memory_accumulated_amount DECIMAL(20, 4) DEFAULT 0,
        
        -- Audit fields
        created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
        updated_at DATETIME2 NOT NULL DEFAULT GETDATE(),
        
        CONSTRAINT fk_fcn_coupon_trade FOREIGN KEY (trade_id) REFERENCES fcn_trade(trade_id) ON DELETE CASCADE,
        CONSTRAINT uq_fcn_coupon_trade_period UNIQUE (trade_id, period_index)
    );
    
    CREATE INDEX idx_fcn_coupon_trade ON fcn_coupon_cashflow(trade_id);
    CREATE INDEX idx_fcn_coupon_payment_date ON fcn_coupon_cashflow(payment_date);
    CREATE INDEX idx_fcn_coupon_status ON fcn_coupon_cashflow(coupon_status);
    
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description',
        @value = N'Coupon cashflow schedule and status tracking for FCN trades',
        @level0type = N'SCHEMA', @level0name = N'dbo',
        @level1type = N'TABLE', @level1name = N'fcn_coupon_cashflow';
    
    PRINT 'Created fcn_coupon_cashflow table';
END
ELSE
BEGIN
    PRINT 'WARNING: fcn_coupon_cashflow table already exists, skipping creation';
END
GO

-- ----------------------------------------------------------------------------
-- 3.5 FCN_EVENT
-- ----------------------------------------------------------------------------

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'fcn_event' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE fcn_event (
        event_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        trade_id UNIQUEIDENTIFIER NOT NULL,
        event_type NVARCHAR(50) NOT NULL CHECK (event_type IN ('knock-in', 'autocall', 'maturity', 'early-termination')),
        event_date DATE NOT NULL,
        event_status NVARCHAR(20) NOT NULL CHECK (event_status IN ('detected', 'confirmed', 'settled')) DEFAULT 'detected',
        trigger_level DECIMAL(12, 8),
        worst_performance DECIMAL(12, 8),
        notes NVARCHAR(MAX),
        
        -- Audit fields
        created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
        updated_at DATETIME2 NOT NULL DEFAULT GETDATE(),
        
        CONSTRAINT fk_fcn_event_trade FOREIGN KEY (trade_id) REFERENCES fcn_trade(trade_id) ON DELETE CASCADE
    );
    
    CREATE INDEX idx_fcn_event_trade ON fcn_event(trade_id);
    CREATE INDEX idx_fcn_event_type ON fcn_event(event_type);
    CREATE INDEX idx_fcn_event_date ON fcn_event(event_date);
    
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description',
        @value = N'Event tracking for FCN trades (knock-in, autocall, maturity)',
        @level0type = N'SCHEMA', @level0name = N'dbo',
        @level1type = N'TABLE', @level1name = N'fcn_event';
    
    PRINT 'Created fcn_event table';
END
ELSE
BEGIN
    PRINT 'WARNING: fcn_event table already exists, skipping creation';
END
GO

-- ----------------------------------------------------------------------------
-- 3.6 FCN_SETTLEMENT
-- ----------------------------------------------------------------------------

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'fcn_settlement' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE fcn_settlement (
        settlement_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        trade_id UNIQUEIDENTIFIER NOT NULL,
        settlement_type NVARCHAR(50) NOT NULL CHECK (settlement_type IN ('cash', 'physical', 'mixed')),
        settlement_date DATE NOT NULL,
        settlement_status NVARCHAR(20) NOT NULL CHECK (settlement_status IN ('pending', 'confirmed', 'completed')) DEFAULT 'pending',
        
        -- Cash settlement
        cash_amount DECIMAL(20, 4),
        
        -- Physical settlement
        delivery_underlying_symbol NVARCHAR(50),
        delivery_shares DECIMAL(20, 8),
        fractional_cash_amount DECIMAL(20, 4),
        
        -- References
        event_id UNIQUEIDENTIFIER,
        
        -- Audit fields
        created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
        updated_at DATETIME2 NOT NULL DEFAULT GETDATE(),
        
        CONSTRAINT fk_fcn_settlement_trade FOREIGN KEY (trade_id) REFERENCES fcn_trade(trade_id) ON DELETE CASCADE,
        CONSTRAINT fk_fcn_settlement_event FOREIGN KEY (event_id) REFERENCES fcn_event(event_id) ON DELETE SET NULL
    );
    
    CREATE INDEX idx_fcn_settlement_trade ON fcn_settlement(trade_id);
    CREATE INDEX idx_fcn_settlement_date ON fcn_settlement(settlement_date);
    CREATE INDEX idx_fcn_settlement_status ON fcn_settlement(settlement_status);
    
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description',
        @value = N'Settlement tracking for FCN trades (cash or physical delivery)',
        @level0type = N'SCHEMA', @level0name = N'dbo',
        @level1type = N'TABLE', @level1name = N'fcn_settlement';
    
    PRINT 'Created fcn_settlement table';
END
ELSE
BEGIN
    PRINT 'WARNING: fcn_settlement table already exists, skipping creation';
END
GO

-- ============================================================================
-- SECTION 4: VALIDATION PROCEDURE
-- ============================================================================

PRINT '';
PRINT '=== Section 4: Creating Validation Procedure ===';

IF OBJECT_ID('dbo.usp_FCN_ValidateTemplate', 'P') IS NOT NULL
BEGIN
    PRINT 'WARNING: usp_FCN_ValidateTemplate already exists, dropping and recreating';
    DROP PROCEDURE dbo.usp_FCN_ValidateTemplate;
END
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
    DECLARE @recovery_mode NVARCHAR(50);
    DECLARE @put_strike_pct DECIMAL(9, 6);
    DECLARE @share_delivery_enabled BIT;
    DECLARE @settlement_type NVARCHAR(50);
    
    -- Get template settings
    SELECT 
        @step_down_enabled = step_down_enabled,
        @recovery_mode = recovery_mode,
        @put_strike_pct = put_strike_pct,
        @share_delivery_enabled = share_delivery_enabled,
        @settlement_type = settlement_type
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
    -- RULE 4: Underlying weights must sum to 1.0 (with tolerance ~0.001)
    -- ========================================================================
    SELECT @underlying_weight_sum = SUM(weight)
    FROM fcn_template_underlying
    WHERE template_id = @template_id;
    
    IF @underlying_weight_sum IS NOT NULL
    BEGIN
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
    -- RULE 5: capital-at-risk requires put_strike_pct IS NOT NULL
    -- ========================================================================
    IF @recovery_mode = 'capital-at-risk' AND @put_strike_pct IS NULL
    BEGIN
        SET @ErrorMessage = 'recovery_mode=''capital-at-risk'' requires put_strike_pct to be NOT NULL for template: ' + CAST(@template_id AS NVARCHAR(36));
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END
    
    -- ========================================================================
    -- RULE 6: share_delivery_enabled=1 requires physical-settlement + put_strike_pct
    -- ========================================================================
    IF @share_delivery_enabled = 1
    BEGIN
        IF @settlement_type != 'physical-settlement'
        BEGIN
            SET @ErrorMessage = 'share_delivery_enabled=1 requires settlement_type=''physical-settlement'' for template: ' + CAST(@template_id AS NVARCHAR(36));
            RAISERROR(@ErrorMessage, 16, 1);
            RETURN;
        END
        
        IF @recovery_mode != 'capital-at-risk'
        BEGIN
            SET @ErrorMessage = 'share_delivery_enabled=1 requires recovery_mode=''capital-at-risk'' for template: ' + CAST(@template_id AS NVARCHAR(36));
            RAISERROR(@ErrorMessage, 16, 1);
            RETURN;
        END
        
        IF @put_strike_pct IS NULL
        BEGIN
            SET @ErrorMessage = 'share_delivery_enabled=1 requires put_strike_pct to be NOT NULL for template: ' + CAST(@template_id AS NVARCHAR(36));
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

PRINT 'Created usp_FCN_ValidateTemplate procedure';
GO

-- ============================================================================
-- SECTION 5: VALIDATION TRIGGER
-- ============================================================================

PRINT '';
PRINT '=== Section 5: Creating Validation Trigger ===';

IF OBJECT_ID('dbo.trg_FCN_ValidateTemplate', 'TR') IS NOT NULL
BEGIN
    PRINT 'WARNING: trg_FCN_ValidateTemplate already exists, dropping and recreating';
    DROP TRIGGER dbo.trg_FCN_ValidateTemplate;
END
GO

CREATE TRIGGER dbo.trg_FCN_ValidateTemplate
ON dbo.fcn_template
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @template_id UNIQUEIDENTIFIER;
    DECLARE @status NVARCHAR(20);
    
    -- Get template_id and status from inserted rows
    DECLARE template_cursor CURSOR FOR
        SELECT template_id, status FROM inserted;
    
    OPEN template_cursor;
    FETCH NEXT FROM template_cursor INTO @template_id, @status;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Only validate templates with Active status
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
        
        FETCH NEXT FROM template_cursor INTO @template_id, @status;
    END
    
    CLOSE template_cursor;
    DEALLOCATE template_cursor;
END
GO

PRINT 'Created trg_FCN_ValidateTemplate trigger';
GO

-- ============================================================================
-- COMPLETION
-- ============================================================================

PRINT '';
PRINT '=== FCN v1.1 Consolidated Schema Migration Complete ===';
PRINT 'Completed at: ' + CONVERT(NVARCHAR(30), GETDATE(), 120);
PRINT '';
PRINT 'Summary:';
PRINT '- Issuer whitelist: issuer_whitelist';
PRINT '- Template layer: fcn_template, fcn_template_underlying, fcn_template_observation_schedule';
PRINT '- Trade layer: fcn_trade, fcn_underlying, fcn_observation, fcn_coupon_cashflow, fcn_event, fcn_settlement';
PRINT '- Validation: usp_FCN_ValidateTemplate, trg_FCN_ValidateTemplate';
PRINT '';
PRINT 'Next Steps:';
PRINT '1. Verify all tables created successfully';
PRINT '2. Test validation procedure with sample templates';
PRINT '3. Run fcn-sample-product-insertion.sql to test full workflow';
PRINT '4. Query DISTINCT settlement_type from fcn_template to confirm canonical values';
GO
