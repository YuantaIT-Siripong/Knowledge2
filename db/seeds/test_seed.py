#!/usr/bin/env python3
"""
Test script to verify seed_fcn_v1_parameters.py works correctly.

Validates:
1. All required parameters from FCN v1.0 spec are present
2. Type mappings are correct
3. Enum domains are properly formatted
4. Constraints are captured
"""

import sqlite3
import sys
from pathlib import Path


def test_seed():
    """Run validation tests on seeded database."""
    repo_root = Path(__file__).parent.parent.parent
    db_path = repo_root / 'db/fcn_parameters.db'
    
    if not db_path.exists():
        print("Error: Database not found. Run seed_fcn_v1_parameters.py first.")
        sys.exit(1)
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Test 1: Count parameters
    cursor.execute(
        "SELECT COUNT(*) FROM parameter_definitions WHERE product_type='fcn' AND spec_version='1.0.0'"
    )
    count = cursor.fetchone()[0]
    assert count == 24, f"Expected 24 parameters, found {count}"
    print(f"✓ Test 1: Found all 24 parameters")
    
    # Test 2: Check required parameters
    required_params = [
        'trade_date', 'issue_date', 'maturity_date', 'underlying_symbols',
        'initial_levels', 'notional_amount', 'currency', 'observation_dates',
        'coupon_payment_dates', 'coupon_rate_pct', 'knock_in_barrier_pct',
        'barrier_monitoring', 'knock_in_condition', 'redemption_barrier_pct',
        'settlement_type', 'recovery_mode', 'documentation_version'
    ]
    
    cursor.execute(
        "SELECT name FROM parameter_definitions WHERE required_flag=1 AND product_type='fcn'"
    )
    found_required = {row[0] for row in cursor.fetchall()}
    
    for param in required_params:
        assert param in found_required, f"Required parameter '{param}' not marked as required"
    print(f"✓ Test 2: All {len(required_params)} required parameters are marked correctly")
    
    # Test 3: Check date types
    cursor.execute(
        "SELECT name FROM parameter_definitions WHERE data_type='date' AND product_type='fcn'"
    )
    date_params = {row[0] for row in cursor.fetchall()}
    expected_dates = {'trade_date', 'issue_date', 'maturity_date'}
    assert date_params == expected_dates, f"Date parameters mismatch: {date_params} vs {expected_dates}"
    print(f"✓ Test 3: Date type mapping correct ({len(date_params)} date fields)")
    
    # Test 4: Check enum parameters
    cursor.execute(
        "SELECT name, enum_domain FROM parameter_definitions WHERE enum_domain IS NOT NULL AND product_type='fcn'"
    )
    enum_params = dict(cursor.fetchall())
    
    expected_enums = {
        'barrier_monitoring': 'discrete',
        'knock_in_condition': 'any-underlying-breach',
        'settlement_type': 'physical-settlement',
        'recovery_mode': 'par-recovery',
        'day_count_convention': 'ACT/365|ACT/360'
    }
    
    for name, expected_domain in expected_enums.items():
        assert name in enum_params, f"Enum parameter '{name}' not found"
        assert enum_params[name] == expected_domain, \
            f"Enum domain mismatch for {name}: '{enum_params[name]}' vs '{expected_domain}'"
    
    print(f"✓ Test 4: All {len(expected_enums)} enum parameters correctly defined")
    
    # Test 5: Check numeric constraints
    cursor.execute(
        "SELECT name, min_value, max_value FROM parameter_definitions "
        "WHERE name='knock_in_barrier_pct' AND product_type='fcn'"
    )
    row = cursor.fetchone()
    assert row, "knock_in_barrier_pct not found"
    name, min_val, max_val = row
    assert min_val == 0, f"knock_in_barrier_pct min_value should be 0, got {min_val}"
    assert max_val == 1, f"knock_in_barrier_pct max_value should be 1, got {max_val}"
    print(f"✓ Test 5: Numeric constraints correctly extracted")
    
    # Test 6: Check default values
    cursor.execute(
        "SELECT name, default_value FROM parameter_definitions "
        "WHERE default_value IS NOT NULL AND product_type='fcn' "
        "ORDER BY name"
    )
    defaults = dict(cursor.fetchall())
    
    expected_defaults = {
        'barrier_monitoring': '"discrete"',
        'business_day_calendar': '"TARGET"',
        'coupon_condition_threshold_pct': '1.0',
        'coupon_observation_offset_days': '0',
        'day_count_convention': '"ACT/365"',
        'fx_reference': 'null',
        'is_memory_coupon': 'false',
        'memory_carry_cap_count': 'null',
        'recovery_mode': '"par-recovery"'
    }
    
    for name, expected in expected_defaults.items():
        if name in defaults:
            assert defaults[name] == expected, \
                f"Default value mismatch for {name}: '{defaults[name]}' vs '{expected}'"
    
    print(f"✓ Test 6: Default values correctly encoded ({len(defaults)} parameters with defaults)")
    
    # Test 7: Check descriptions exist
    cursor.execute(
        "SELECT COUNT(*) FROM parameter_definitions "
        "WHERE (description IS NULL OR description = '') AND product_type='fcn'"
    )
    missing_desc = cursor.fetchone()[0]
    assert missing_desc == 0, f"{missing_desc} parameters missing descriptions"
    print(f"✓ Test 7: All parameters have descriptions")
    
    conn.close()
    
    print("\n" + "="*60)
    print("ALL TESTS PASSED!")
    print("="*60)


if __name__ == '__main__':
    try:
        test_seed()
    except AssertionError as e:
        print(f"\n✗ Test failed: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"\n✗ Unexpected error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
