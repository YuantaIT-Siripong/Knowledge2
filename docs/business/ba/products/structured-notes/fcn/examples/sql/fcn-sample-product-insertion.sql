/* 
FCN Sample Product Insertion Script
Purpose:
  Demonstrates shelf (template) creation and trade instantiation for the Yuanta sample FCN:
    Underlyings: AMZN.US, ORCL.US, PLTR.US
    Annual headline coupon: 13% p.a. (monthly per-period rate ≈ 0.010833)
    KO Barrier: 110%
    KI Barrier: 60%
    Put Strike: 80%
    Tenor: 6 months (monthly observations)
    Settlement: Physical worst-of (capital-at-risk)
    Currency: USD
    Issuer: VONTOBEL-CH-001 (must exist in issuer_whitelist if enforced)
Safety:
  - Idempotent where feasible (IF NOT EXISTS on template_code & dependent inserts).
  - Deterministic codes (FCN-SAMPLE-2025M10) to avoid duplication.
Prerequisites:
  - Migrations m0009..m0012 applied.
  - usp_FCN_ValidateTemplate available.
Execution:
  Run in SQL Server 2019+ environment.
*/
SET NOCOUNT ON; SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @TemplateCode NVARCHAR(100) = 'FCN-SAMPLE-2025M10';
DECLARE @TemplateName NVARCHAR(200) = 'Sample FCN Oct 2025 – 13% p.a. Monthly';
DECLARE @SpecVersion NVARCHAR(20) = '1.1.0';
DECLARE @Currency NVARCHAR(3) = 'USD';
DECLARE @TenorMonths INT = 6;
DECLARE @KI DECIMAL(9,6) = 0.60; DECLARE @PutStrike DECIMAL(9,6) = 0.80; DECLARE @KO DECIMAL(9,6) = 1.10;
DECLARE @CouponAnnualPct DECIMAL(12,8) = 0.13; DECLARE @CouponFreq NVARCHAR(16) = 'MONTHLY'; DECLARE @PeriodsPerYear INT = 12;
DECLARE @CouponPerPeriod DECIMAL(12,8) = ROUND(@CouponAnnualPct / @PeriodsPerYear, 6); -- 0.010833
DECLARE @CouponCondThresh DECIMAL(9,6) = 0.85; DECLARE @SettlementLagDays INT = 2;
DECLARE @IssueDate DATE = '2025-10-17'; DECLARE @MaturityDate DATE = '2026-03-17'; DECLARE @FinalValuationDate DATE = @MaturityDate;
DECLARE @Obs TABLE (idx INT PRIMARY KEY, obs_date DATE);
INSERT INTO @Obs(idx, obs_date) VALUES (0,'2025-10-17'),(1,'2025-11-17'),(2,'2025-12-17'),(3,'2026-01-17'),(4,'2026-02-17'),(5,@MaturityDate);
IF NOT EXISTS (SELECT 1 FROM fcn_template WHERE template_code=@TemplateCode)
BEGIN
 INSERT INTO fcn_template (
  template_code, template_name, template_description, product_family, spec_version, status,
  effective_date, expiry_date, currency, tenor_months, knock_in_barrier_pct, put_strike_pct,
  coupon_rate_pct, coupon_condition_threshold_pct, coupon_rate_type, coupon_memory,
  knock_out_barrier_pct, auto_call_observation_logic, settlement_type, settlement_lag_days,
  recovery_mode, share_delivery_enabled, share_delivery_rounding, fractional_share_cash_settlement,
  barrier_monitoring_type, issuer, step_down_enabled, created_by)
 VALUES (
  @TemplateCode, @TemplateName,
  'Yuanta sample FCN: 13% p.a. headline converted to monthly, physical worst-of settlement on capital-at-risk loss branch.',
  'FCN', @SpecVersion, 'Draft', @IssueDate, @MaturityDate, @Currency, @TenorMonths, @KI, @PutStrike,
  @CouponPerPeriod, @CouponCondThresh, 'per-period', 0, @KO, 'all-underlyings', 'physical-settlement', @SettlementLagDays,
  'capital-at-risk', 1, 'floor', 1, 'discrete','VONTOBEL-CH-001', 0, SYSTEM_USER);
 PRINT 'Template created.';
END ELSE PRINT 'Template exists.';
DECLARE @TemplateId UNIQUEIDENTIFIER; SELECT @TemplateId=template_id FROM fcn_template WHERE template_code=@TemplateCode;
IF @TemplateId IS NULL BEGIN RAISERROR('Template not found after creation attempt.',16,1); ROLLBACK TRANSACTION; RETURN; END;
IF NOT EXISTS (SELECT 1 FROM fcn_template_underlying WHERE template_id=@TemplateId)
BEGIN
 INSERT INTO fcn_template_underlying (template_id, underlying_code, underlying_name, weight, sequence_no, asset_class, exchange, currency)
 VALUES (@TemplateId,'AMZN.US','Amazon.com Inc',1.0/3,1,'Equity','NASDAQ','USD'),(@TemplateId,'ORCL.US','Oracle Corp',1.0/3,2,'Equity','NYSE','USD'),(@TemplateId,'PLTR.US','Palantir Tech',1.0/3,3,'Equity','NYSE','USD');
 PRINT 'Underlyings inserted.';
END ELSE PRINT 'Underlyings exist.';
IF NOT EXISTS (SELECT 1 FROM fcn_template_observation_schedule WHERE template_id=@TemplateId)
BEGIN
 DECLARE @i INT,@d DATE; DECLARE c CURSOR FOR SELECT idx,obs_date FROM @Obs ORDER BY idx; OPEN c; FETCH NEXT FROM c INTO @i,@d;
 WHILE @@FETCH_STATUS=0 BEGIN
  INSERT INTO fcn_template_observation_schedule (template_id, observation_type, observation_offset_months, observation_label, step_down_ko_barrier_pct, is_maturity)
  VALUES (@TemplateId, CASE WHEN @i<@TenorMonths-1 THEN 'autocall' ELSE 'maturity' END, @i, CONCAT('M',@i+1), CASE WHEN @i<@TenorMonths-1 THEN @KO ELSE NULL END, CASE WHEN @i=@TenorMonths-1 THEN 1 ELSE 0 END);
  FETCH NEXT FROM c INTO @i,@d; END; CLOSE c; DEALLOCATE c; PRINT 'Observation schedule inserted.';
END ELSE PRINT 'Observation schedule exists.';
BEGIN TRY
 EXEC usp_FCN_ValidateTemplate @template_id=@TemplateId;
 UPDATE fcn_template SET status='Active', updated_at=GETDATE(), updated_by=SYSTEM_USER WHERE template_id=@TemplateId AND status='Draft';
 PRINT 'Template activated.';
END TRY BEGIN CATCH PRINT 'Template validation failed: '+ERROR_MESSAGE(); ROLLBACK TRANSACTION; RETURN; END CATCH;
DECLARE @TradeId UNIQUEIDENTIFIER; IF NOT EXISTS (SELECT 1 FROM fcn_trade WHERE template_id=@TemplateId AND documentation_version=@SpecVersion)
BEGIN
 SET @TradeId=NEWID();
 INSERT INTO fcn_trade (trade_id, product_code, spec_version, documentation_version, trade_date, issue_date, maturity_date, notional, currency, issuer, knock_in_barrier_pct, put_strike_pct, knock_out_barrier_pct, coupon_rate_pct, coupon_condition_threshold_pct, is_memory_coupon, recovery_mode, settlement_type, barrier_monitoring_type, auto_call_observation_logic, day_count_convention, template_id)
 VALUES (@TradeId,'FCN',@SpecVersion,@SpecVersion,DATEADD(DAY,-30,@IssueDate),@IssueDate,@MaturityDate,1000000,@Currency,'VONTOBEL-CH-001',@KI,@PutStrike,@KO,@CouponPerPeriod,@CouponCondThresh,0,'capital-at-risk','physical-settlement','discrete','all-underlyings','ACT/365',@TemplateId);
 PRINT 'Trade instantiated.';
END ELSE SELECT TOP 1 @TradeId=trade_id FROM fcn_trade WHERE template_id=@TemplateId ORDER BY created_at;
IF @TradeId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM fcn_underlying WHERE trade_id=@TradeId)
BEGIN
 INSERT INTO fcn_underlying (trade_id, underlying_index, symbol, initial_level, weight)
 SELECT @TradeId, sequence_no-1, underlying_code,
  CASE underlying_code WHEN 'AMZN.US' THEN 180.00 WHEN 'ORCL.US' THEN 125.00 WHEN 'PLTR.US' THEN 35.00 END, weight
 FROM fcn_template_underlying WHERE template_id=@TemplateId ORDER BY sequence_no;
 PRINT 'Trade underlyings fixed.';
END ELSE PRINT 'Trade underlyings already fixed or trade missing.';
PRINT 'Observation prices will be ingested later (future data).';
PRINT '--- Summary ---';
SELECT template_code,status,settlement_type,recovery_mode,coupon_rate_pct,knock_in_barrier_pct,put_strike_pct,knock_out_barrier_pct FROM fcn_template WHERE template_id=@TemplateId;
SELECT trade_id,template_id,settlement_type,recovery_mode,coupon_rate_pct FROM fcn_trade WHERE template_id=@TemplateId;
SELECT trade_id,underlying_index,symbol,initial_level FROM fcn_underlying WHERE trade_id=@TradeId ORDER BY underlying_index;
COMMIT TRANSACTION; GO
