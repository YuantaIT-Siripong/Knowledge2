-- Test Script for m0012 FCN Template Harmonization
-- Description: Validates migration m0012 functionality
-- Author: siripong.s@yuanta.co.th
-- Created: 2025-10-16
-- Purpose: Test harmonization changes without affecting production data

-- ============================================================================
-- TEST SETUP
-- ============================================================================

PRINT '=== FCN Template Harmonization Test Suite ===';
PRINT '';

-- Clean up any existing test data
DELETE FROM fcn_template WHERE template_code LIKE 'TEST-HARM-%';
PRINT 'Cleaned up existing test data';
PRINT '';

-- ============================================================================
-- TEST 1: Verify canonical settlement_type values are accepted
-- ============================================================================

PRINT 'TEST 1: Verify canonical settlement_type values are accepted';
BEGIN TRY
    INSERT INTO fcn_template (
        template_code, template_name, spec_version, currency, tenor_months, 
        knock_in_barrier_pct, put_strike_pct, coupon_rate_pct, coupon_condition_threshold_pct, 
        settlement_type, recovery_mode, status
    )
    VALUES (
        'TEST-HARM-001', 'Test Cash Settlement', '1.1.0', 'USD', 12, 
        0.70, 0.75, 0.06, 0.60, 'cash-settlement', 'capital-at-risk', 'Draft'
    );
    PRINT '✓ PASS: cash-settlement value accepted';
END TRY
BEGIN CATCH
    PRINT '✗ FAIL: cash-settlement rejected - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

BEGIN TRY
    INSERT INTO fcn_template (
        template_code, template_name, spec_version, currency, tenor_months, 
        knock_in_barrier_pct, put_strike_pct, coupon_rate_pct, coupon_condition_threshold_pct, 
        settlement_type, recovery_mode, status
    )
    VALUES (
        'TEST-HARM-002', 'Test Physical Settlement', '1.1.0', 'USD', 12, 
        0.70, 0.75, 0.06, 0.60, 'physical-settlement', 'capital-at-risk', 'Draft'
    );
    PRINT '✓ PASS: physical-settlement value accepted';
END TRY
BEGIN CATCH
    PRINT '✗ FAIL: physical-settlement rejected - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

-- ============================================================================
-- TEST 2: Verify old values are rejected
-- ============================================================================

PRINT 'TEST 2: Verify old settlement_type values are rejected';
BEGIN TRY
    INSERT INTO fcn_template (
        template_code, template_name, spec_version, currency, tenor_months, 
        knock_in_barrier_pct, coupon_rate_pct, coupon_condition_threshold_pct, 
        settlement_type, recovery_mode, status
    )
    VALUES (
        'TEST-HARM-003', 'Test Old Cash Value', '1.1.0', 'USD', 12, 
        0.70, 0.06, 0.60, 'cash', 'capital-at-risk', 'Draft'
    );
    PRINT '✗ FAIL: Old value ''cash'' should be rejected but was accepted';
END TRY
BEGIN CATCH
    PRINT '✓ PASS: Old value ''cash'' correctly rejected - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

BEGIN TRY
    INSERT INTO fcn_template (
        template_code, template_name, spec_version, currency, tenor_months, 
        knock_in_barrier_pct, coupon_rate_pct, coupon_condition_threshold_pct, 
        settlement_type, recovery_mode, status
    )
    VALUES (
        'TEST-HARM-004', 'Test Old Physical Value', '1.1.0', 'USD', 12, 
        0.70, 0.06, 0.60, 'physical-worst-of', 'capital-at-risk', 'Draft'
    );
    PRINT '✗ FAIL: Old value ''physical-worst-of'' should be rejected but was accepted';
END TRY
BEGIN CATCH
    PRINT '✓ PASS: Old value ''physical-worst-of'' correctly rejected - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

-- ============================================================================
-- TEST 3: Verify default recovery_mode is 'capital-at-risk'
-- ============================================================================

PRINT 'TEST 3: Verify default recovery_mode is capital-at-risk';
BEGIN TRY
    INSERT INTO fcn_template (
        template_code, template_name, spec_version, currency, tenor_months, 
        knock_in_barrier_pct, put_strike_pct, coupon_rate_pct, coupon_condition_threshold_pct, 
        settlement_type, status
    )
    VALUES (
        'TEST-HARM-005', 'Test Default Recovery', '1.1.0', 'USD', 12, 
        0.70, 0.75, 0.06, 0.60, 'cash-settlement', 'Draft'
    );
    
    DECLARE @default_recovery NVARCHAR(50);
    SELECT @default_recovery = recovery_mode 
    FROM fcn_template 
    WHERE template_code = 'TEST-HARM-005';
    
    IF @default_recovery = 'capital-at-risk'
        PRINT '✓ PASS: Default recovery_mode is capital-at-risk';
    ELSE
        PRINT '✗ FAIL: Default recovery_mode is ' + @default_recovery + ', expected capital-at-risk';
END TRY
BEGIN CATCH
    PRINT '✗ FAIL: Error testing default recovery_mode - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

-- ============================================================================
-- TEST 4: Verify share_delivery constraint (invalid combination)
-- ============================================================================

PRINT 'TEST 4: Verify share_delivery constraint rejects invalid combinations';
BEGIN TRY
    INSERT INTO fcn_template (
        template_code, template_name, spec_version, currency, tenor_months, 
        knock_in_barrier_pct, put_strike_pct, coupon_rate_pct, coupon_condition_threshold_pct, 
        settlement_type, recovery_mode, share_delivery_enabled, status
    )
    VALUES (
        'TEST-HARM-006', 'Test Share Delivery Invalid', '1.1.0', 'USD', 12, 
        0.70, 0.75, 0.06, 0.60, 'cash-settlement', 'capital-at-risk', 1, 'Draft'
    );
    PRINT '✗ FAIL: share_delivery_enabled=1 with cash-settlement should be rejected but was accepted';
END TRY
BEGIN CATCH
    PRINT '✓ PASS: Invalid share_delivery combination correctly rejected - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

-- ============================================================================
-- TEST 5: Verify valid share_delivery configuration
-- ============================================================================

PRINT 'TEST 5: Verify valid share_delivery configuration is accepted';
BEGIN TRY
    INSERT INTO fcn_template (
        template_code, template_name, spec_version, currency, tenor_months, 
        knock_in_barrier_pct, put_strike_pct, coupon_rate_pct, coupon_condition_threshold_pct, 
        settlement_type, recovery_mode, share_delivery_enabled, status
    )
    VALUES (
        'TEST-HARM-007', 'Test Share Delivery Valid', '1.1.0', 'USD', 12, 
        0.70, 0.75, 0.06, 0.60, 'physical-settlement', 'capital-at-risk', 1, 'Draft'
    );
    PRINT '✓ PASS: Valid share_delivery configuration accepted';
END TRY
BEGIN CATCH
    PRINT '✗ FAIL: Valid share_delivery configuration rejected - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

-- ============================================================================
-- TEST 6: Verify computed column settlement_physical_flag
-- ============================================================================

PRINT 'TEST 6: Verify computed column settlement_physical_flag';
DECLARE @physical_flag_cash INT;
DECLARE @physical_flag_physical INT;

SELECT @physical_flag_cash = settlement_physical_flag 
FROM fcn_template 
WHERE template_code = 'TEST-HARM-001';

SELECT @physical_flag_physical = settlement_physical_flag 
FROM fcn_template 
WHERE template_code = 'TEST-HARM-002';

IF @physical_flag_cash = 0
    PRINT '✓ PASS: settlement_physical_flag = 0 for cash-settlement';
ELSE
    PRINT '✗ FAIL: settlement_physical_flag should be 0 for cash-settlement, got ' + CAST(@physical_flag_cash AS NVARCHAR(1));

IF @physical_flag_physical = 1
    PRINT '✓ PASS: settlement_physical_flag = 1 for physical-settlement';
ELSE
    PRINT '✗ FAIL: settlement_physical_flag should be 1 for physical-settlement, got ' + CAST(@physical_flag_physical AS NVARCHAR(1));
PRINT '';

-- ============================================================================
-- TEST 7: Verify distinct settlement_type values
-- ============================================================================

PRINT 'TEST 7: Verify only canonical settlement_type values exist in table';
DECLARE @canonical_only BIT = 1;

IF EXISTS (
    SELECT 1 FROM fcn_template 
    WHERE settlement_type NOT IN ('cash-settlement', 'physical-settlement')
)
BEGIN
    SET @canonical_only = 0;
    PRINT '✗ FAIL: Non-canonical settlement_type values found:';
    SELECT DISTINCT settlement_type 
    FROM fcn_template 
    WHERE settlement_type NOT IN ('cash-settlement', 'physical-settlement');
END
ELSE
BEGIN
    PRINT '✓ PASS: Only canonical settlement_type values present';
    PRINT 'Current distinct values:';
    SELECT DISTINCT settlement_type FROM fcn_template ORDER BY settlement_type;
END
PRINT '';

-- ============================================================================
-- TEST CLEANUP
-- ============================================================================

PRINT 'Cleaning up test data...';
DELETE FROM fcn_template WHERE template_code LIKE 'TEST-HARM-%';
PRINT 'Test cleanup complete';
PRINT '';

-- ============================================================================
-- TEST SUMMARY
-- ============================================================================

PRINT '=== Test Suite Complete ===';
PRINT 'Review results above for any FAIL messages';
PRINT '';
PRINT 'Expected Results:';
PRINT '- TEST 1: Both canonical values accepted';
PRINT '- TEST 2: Both old values rejected';
PRINT '- TEST 3: Default recovery_mode is capital-at-risk';
PRINT '- TEST 4: Invalid share_delivery rejected';
PRINT '- TEST 5: Valid share_delivery accepted';
PRINT '- TEST 6: Computed column works correctly';
PRINT '- TEST 7: Only canonical values in table';
