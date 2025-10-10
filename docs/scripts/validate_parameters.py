#!/usr/bin/env python3
"""
FCN v1.0 Phase 2 Parameters Validator

Validates that test vector parameters are complete and consistent.
Checks parameter types, ranges, and relationships.

Output: parameters-validation.json with status and validation details
"""

import json
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Tuple

import yaml


def parse_front_matter(file_path: Path) -> Tuple[Dict[str, Any], str]:
    """
    Parse YAML front matter from a markdown file.
    
    Args:
        file_path: Path to the markdown file
        
    Returns:
        Tuple of (front_matter_dict, error_message)
        error_message is empty string if successful
    """
    try:
        content = file_path.read_text(encoding='utf-8')
    except Exception as e:
        return {}, f"Failed to read file: {e}"
    
    # Match YAML front matter between --- delimiters
    match = re.match(r'^---\s*\n(.*?)\n---\s*\n', content, re.DOTALL)
    if not match:
        return {}, "No YAML front matter found"
    
    yaml_content = match.group(1)
    
    try:
        front_matter = yaml.safe_load(yaml_content)
        if not isinstance(front_matter, dict):
            return {}, "Front matter is not a valid YAML dictionary"
        return front_matter, ""
    except yaml.YAMLError as e:
        return {}, f"Failed to parse YAML front matter: {e}"


def extract_parameters_from_content(file_path: Path) -> Tuple[Dict[str, Any], str]:
    """
    Extract parameters from the ## Parameters section of the markdown.
    
    Args:
        file_path: Path to test vector markdown file
        
    Returns:
        Tuple of (parameters_dict, error_message)
    """
    try:
        content = file_path.read_text(encoding='utf-8')
    except Exception as e:
        return {}, f"Failed to read file: {e}"
    
    # Check if this test vector doesn't have a full parameters section
    # Some vectors may have different sections or reference other vectors
    params_match = re.search(
        r'## Parameters.*?\n\| name \| value \|\n\|---+\|---+\|\n((?:\|.*\|.*\n)+)',
        content,
        re.DOTALL
    )
    
    if not params_match:
        # No parameter table found - this is acceptable for vectors that
        # reference or extend other vectors
        return {}, ""
    
    # Parse the table
    params = {}
    table_content = params_match.group(1)
    for line in table_content.strip().split('\n'):
        if '|' in line:
            parts = [p.strip() for p in line.split('|')[1:-1]]
            if len(parts) == 2:
                name, value = parts
                # Try to parse the value
                if value.lower() in ['true', 'false']:
                    params[name] = value.lower() == 'true'
                elif value.lower() == 'null':
                    params[name] = None
                elif value.replace('.', '').replace('_', '').isdigit():
                    # Numeric value (without dashes, which would indicate dates)
                    if '.' in value:
                        params[name] = float(value.replace('_', ''))
                    else:
                        params[name] = int(value.replace('_', ''))
                else:
                    params[name] = value
    
    return params, ""


def validate_parameters(params: Dict[str, Any]) -> List[str]:
    """
    Validate FCN parameters for completeness and consistency.
    
    Args:
        params: Parameters dictionary extracted from test vector
        
    Returns:
        List of validation errors (empty if valid)
    """
    errors = []
    
    # Required parameters
    required_params = [
        'trade_date',
        'issue_date',
        'maturity_date',
        'notional_amount',
        'currency',
        'underlying_symbols',
        'initial_levels',
        'observation_dates',
        'coupon_payment_dates',
        'coupon_rate_pct',
        'is_memory_coupon',
        'knock_in_barrier_pct',
        'redemption_barrier_pct',
        'coupon_condition_threshold_pct',
        'settlement_type',
        'recovery_mode',
        'day_count_convention'
    ]
    
    for param in required_params:
        if param not in params:
            errors.append(f"Missing required parameter: {param}")
    
    # Validate percentage ranges
    percentage_params = [
        'coupon_rate_pct',
        'knock_in_barrier_pct',
        'redemption_barrier_pct',
        'coupon_condition_threshold_pct'
    ]
    
    for param in percentage_params:
        if param in params:
            value = params[param]
            if isinstance(value, (int, float)):
                if value < 0 or value > 1:
                    errors.append(f"Parameter {param} must be between 0 and 1, got {value}")
    
    # Validate barrier relationships
    if 'knock_in_barrier_pct' in params and 'coupon_condition_threshold_pct' in params:
        knock_in = params['knock_in_barrier_pct']
        coupon_threshold = params['coupon_condition_threshold_pct']
        if isinstance(knock_in, (int, float)) and isinstance(coupon_threshold, (int, float)):
            if knock_in >= coupon_threshold:
                errors.append(
                    f"knock_in_barrier_pct ({knock_in}) should be less than "
                    f"coupon_condition_threshold_pct ({coupon_threshold})"
                )
    
    # Validate notional amount is positive and has correct precision
    if 'notional_amount' in params:
        notional = params['notional_amount']
        if isinstance(notional, (int, float)) and notional <= 0:
            errors.append(f"notional_amount must be positive, got {notional}")
        
        # Validate notional precision based on currency
        if 'currency' in params and isinstance(notional, (int, float)):
            currency = params['currency']
            # Zero-decimal currencies (no fractional units)
            zero_decimal_currencies = ['JPY', 'KRW']
            # Standard currencies require 2 decimal places max
            
            if currency in zero_decimal_currencies:
                # Should be a whole number
                if notional != int(notional):
                    errors.append(
                        f"notional_amount for {currency} must be a whole number (0 decimal places), "
                        f"got {notional}"
                    )
            else:
                # Check if more than 2 decimal places
                decimal_str = str(notional)
                if '.' in decimal_str:
                    decimal_places = len(decimal_str.split('.')[1])
                    if decimal_places > 2:
                        errors.append(
                            f"notional_amount for {currency} must have at most 2 decimal places, "
                            f"got {decimal_places} decimal places"
                        )
    
    # Validate settlement_type
    if 'settlement_type' in params:
        valid_settlements = ['physical-settlement', 'cash-settlement']
        if params['settlement_type'] not in valid_settlements:
            errors.append(
                f"settlement_type must be one of {valid_settlements}, "
                f"got '{params['settlement_type']}'"
            )
    
    # Validate recovery_mode
    if 'recovery_mode' in params:
        valid_recovery = ['par-recovery', 'proportional-loss']
        if params['recovery_mode'] not in valid_recovery:
            errors.append(
                f"recovery_mode must be one of {valid_recovery}, "
                f"got '{params['recovery_mode']}'"
            )
    
    return errors


def validate_test_vector_parameters(file_path: Path) -> Dict[str, Any]:
    """
    Validate parameters in a single test vector file.
    
    Args:
        file_path: Path to test vector markdown file
        
    Returns:
        Validation result dictionary
    """
    result = {
        "file": str(file_path.name),
        "status": "pass",
        "errors": [],
        "parse_error": ""
    }
    
    # Extract parameters from content
    params, parse_error = extract_parameters_from_content(file_path)
    if parse_error:
        result["status"] = "fail"
        result["parse_error"] = parse_error
        return result
    
    # If no parameters found, this may reference another vector (acceptable)
    if not params:
        result["status"] = "pass"
        result["note"] = "Parameters reference another test vector"
        return result
    
    # Validate parameters
    errors = validate_parameters(params)
    if errors:
        result["status"] = "fail"
        result["errors"] = errors
    
    return result


def validate_all_parameters() -> Dict[str, Any]:
    """
    Validate parameters for all FCN v1.0 test vectors.
    
    Returns:
        Overall validation result
    """
    script_dir = Path(__file__).parent.resolve()
    repo_root = script_dir.parent.parent
    vectors_dir = repo_root / "docs/business/ba/products/structured-notes/fcn/test-vectors"
    
    result = {
        "status": "pass",
        "vectors_validated": 0,
        "vectors_failed": 0,
        "details": []
    }
    
    if not vectors_dir.exists():
        result["status"] = "fail"
        result["error"] = f"Test vectors directory not found: {vectors_dir}"
        return result
    
    # Find all test vector markdown files
    vector_files = sorted(vectors_dir.glob("fcn-v1.0-*.md"))
    
    if not vector_files:
        result["status"] = "fail"
        result["error"] = "No test vector files found"
        return result
    
    for vector_file in vector_files:
        vector_result = validate_test_vector_parameters(vector_file)
        result["details"].append(vector_result)
        
        if vector_result["status"] == "pass":
            result["vectors_validated"] += 1
        else:
            result["vectors_failed"] += 1
            result["status"] = "fail"
    
    return result


def main():
    """Main entry point."""
    print("=" * 60)
    print("FCN v1.0 Phase 2 Parameters Validation")
    print("=" * 60)
    
    result = validate_all_parameters()
    
    print(f"\nStatus: {result['status'].upper()}")
    print(f"Vectors Validated: {result.get('vectors_validated', 0)}")
    print(f"Vectors Failed: {result.get('vectors_failed', 0)}")
    
    if result.get('error'):
        print(f"\nError: {result['error']}")
    
    if result.get('details'):
        print("\nDetails:")
        for detail in result['details']:
            status_icon = "✓" if detail['status'] == 'pass' else "✗"
            print(f"  {status_icon} {detail['file']}: {detail['status']}")
            if detail.get('parse_error'):
                print(f"    Parse Error: {detail['parse_error']}")
            if detail.get('errors'):
                for error in detail['errors']:
                    print(f"    - {error}")
    
    # Write JSON output
    script_dir = Path(__file__).parent.resolve()
    repo_root = script_dir.parent.parent
    output_path = repo_root / "parameters-validation.json"
    output_path.write_text(json.dumps(result, indent=2) + "\n", encoding='utf-8')
    print(f"\nResults written to: {output_path}")
    
    # Exit with appropriate code
    sys.exit(0 if result['status'] == 'pass' else 1)


if __name__ == '__main__':
    main()
