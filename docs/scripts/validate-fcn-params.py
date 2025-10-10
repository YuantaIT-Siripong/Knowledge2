#!/usr/bin/env python3
"""
FCN v1.0 Phase 2 Parameter Schema Conformance Validator

Validates sample payloads against JSON Schema and cross-field rules.

Requirements:
- Validate payloads against fcn-v1.0-schema.json
- Cross-field validation rules:
  - Length(underlying_symbols) == length(initial_levels)
  - observation_dates strictly increasing and < maturity_date
  - coupon_payment_dates length matches observation_dates
  - coupon_payment_dates[i] >= issue_date
  - If is_memory_coupon=false then memory_carry_cap_count must be null
- Output: param-validation.json with status, violations, and summary
"""

import json
import sys
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Tuple

import jsonschema
from jsonschema import Draft7Validator


def load_json_file(file_path: Path) -> Tuple[Dict[str, Any], str]:
    """
    Load and parse a JSON file.
    
    Args:
        file_path: Path to JSON file
        
    Returns:
        Tuple of (parsed_json, error_message)
    """
    try:
        content = file_path.read_text(encoding='utf-8')
        data = json.loads(content)
        return data, ""
    except FileNotFoundError:
        return {}, f"File not found: {file_path}"
    except json.JSONDecodeError as e:
        return {}, f"Invalid JSON in {file_path.name}: {e}"
    except Exception as e:
        return {}, f"Error reading {file_path.name}: {e}"


def validate_json_schema(payload: Dict[str, Any], schema: Dict[str, Any]) -> List[Dict[str, str]]:
    """
    Validate payload against JSON Schema.
    
    Args:
        payload: Payload data to validate
        schema: JSON Schema definition
        
    Returns:
        List of violation dictionaries
    """
    violations = []
    validator = Draft7Validator(schema)
    
    for error in validator.iter_errors(payload):
        path = "$.{}".format(".".join(str(p) for p in error.path)) if error.path else "$"
        violations.append({
            "path": path,
            "rule": "schema",
            "message": error.message
        })
    
    return violations


def validate_cross_field_rules(payload: Dict[str, Any]) -> List[Dict[str, str]]:
    """
    Validate cross-field business rules.
    
    Args:
        payload: Payload data to validate
        
    Returns:
        List of violation dictionaries
    """
    violations = []
    
    # Rule 1: Length(underlying_symbols) == length(initial_levels)
    underlying_symbols = payload.get("underlying_symbols", [])
    initial_levels = payload.get("initial_levels", [])
    
    if len(underlying_symbols) != len(initial_levels):
        violations.append({
            "path": "$.initial_levels",
            "rule": "array_length_match",
            "message": f"Length of initial_levels ({len(initial_levels)}) must equal length of underlying_symbols ({len(underlying_symbols)})"
        })
    
    # Rule 2: observation_dates strictly increasing and < maturity_date
    observation_dates = payload.get("observation_dates", [])
    maturity_date_str = payload.get("maturity_date")
    
    if observation_dates and maturity_date_str:
        try:
            maturity_date = datetime.fromisoformat(maturity_date_str)
            
            # Check strictly increasing
            for i in range(len(observation_dates) - 1):
                date1 = datetime.fromisoformat(observation_dates[i])
                date2 = datetime.fromisoformat(observation_dates[i + 1])
                
                if date1 >= date2:
                    violations.append({
                        "path": f"$.observation_dates[{i + 1}]",
                        "rule": "strictly_increasing",
                        "message": f"observation_dates must be strictly increasing: {observation_dates[i]} >= {observation_dates[i + 1]}"
                    })
            
            # Check all < maturity_date
            for i, obs_date_str in enumerate(observation_dates):
                obs_date = datetime.fromisoformat(obs_date_str)
                if obs_date >= maturity_date:
                    violations.append({
                        "path": f"$.observation_dates[{i}]",
                        "rule": "before_maturity",
                        "message": f"observation_dates[{i}] ({obs_date_str}) must be before maturity_date ({maturity_date_str})"
                    })
        except (ValueError, TypeError) as e:
            violations.append({
                "path": "$.observation_dates",
                "rule": "date_format",
                "message": f"Error parsing dates: {e}"
            })
    
    # Rule 3: coupon_payment_dates length matches observation_dates
    coupon_payment_dates = payload.get("coupon_payment_dates", [])
    
    if len(coupon_payment_dates) != len(observation_dates):
        violations.append({
            "path": "$.coupon_payment_dates",
            "rule": "array_length_match",
            "message": f"Length of coupon_payment_dates ({len(coupon_payment_dates)}) must equal length of observation_dates ({len(observation_dates)})"
        })
    
    # Rule 4: coupon_payment_dates[i] >= issue_date
    issue_date_str = payload.get("issue_date")
    
    if issue_date_str and coupon_payment_dates:
        try:
            issue_date = datetime.fromisoformat(issue_date_str)
            
            for i, payment_date_str in enumerate(coupon_payment_dates):
                payment_date = datetime.fromisoformat(payment_date_str)
                if payment_date < issue_date:
                    violations.append({
                        "path": f"$.coupon_payment_dates[{i}]",
                        "rule": "after_issue",
                        "message": f"coupon_payment_dates[{i}] ({payment_date_str}) must be on or after issue_date ({issue_date_str})"
                    })
        except (ValueError, TypeError) as e:
            violations.append({
                "path": "$.coupon_payment_dates",
                "rule": "date_format",
                "message": f"Error parsing dates: {e}"
            })
    
    # Rule 5: If is_memory_coupon=false then memory_carry_cap_count must be null
    is_memory_coupon = payload.get("is_memory_coupon")
    memory_carry_cap_count = payload.get("memory_carry_cap_count")
    
    if is_memory_coupon is False and memory_carry_cap_count is not None:
        violations.append({
            "path": "$.memory_carry_cap_count",
            "rule": "conditional_null",
            "message": "memory_carry_cap_count must be null when is_memory_coupon is false"
        })
    
    return violations


def validate_payload(payload: Dict[str, Any], schema: Dict[str, Any], 
                     payload_name: str) -> Tuple[List[Dict[str, str]], int, int]:
    """
    Validate a single payload against schema and cross-field rules.
    
    Args:
        payload: Payload data
        schema: JSON Schema
        payload_name: Name/identifier for the payload
        
    Returns:
        Tuple of (violations, error_count, warning_count)
    """
    violations = []
    
    # Schema validation
    schema_violations = validate_json_schema(payload, schema)
    violations.extend(schema_violations)
    
    # Cross-field validation
    cross_field_violations = validate_cross_field_rules(payload)
    violations.extend(cross_field_violations)
    
    # For now, treat all violations as errors
    # Could be enhanced to distinguish warnings from errors
    error_count = len(violations)
    warning_count = 0
    
    return violations, error_count, warning_count


def validate_fcn_parameters(payload_dir: Path, schema_path: Path) -> Dict[str, Any]:
    """
    Main validation function for FCN v1.0 parameter conformance.
    
    Args:
        payload_dir: Directory containing payload JSON files
        schema_path: Path to JSON Schema file
        
    Returns:
        Validation result dictionary
    """
    result = {
        "status": "pass",
        "payloads_tested": 0,
        "violations": [],
        "summary": {
            "errors": 0,
            "warnings": 0
        }
    }
    
    # Load schema
    schema, error = load_json_file(schema_path)
    if error:
        result["status"] = "fail"
        result["violations"].append({
            "path": "$",
            "rule": "schema_load",
            "message": f"Failed to load schema: {error}"
        })
        result["summary"]["errors"] = 1
        return result
    
    # Find and validate all JSON payload files
    payload_files = sorted(payload_dir.glob("*.json"))
    
    if not payload_files:
        result["status"] = "fail"
        result["violations"].append({
            "path": "$",
            "rule": "no_payloads",
            "message": f"No JSON payload files found in {payload_dir}"
        })
        result["summary"]["errors"] = 1
        return result
    
    total_errors = 0
    total_warnings = 0
    
    for payload_file in payload_files:
        # Load payload
        payload, error = load_json_file(payload_file)
        if error:
            result["violations"].append({
                "path": f"${payload_file.name}",
                "rule": "payload_load",
                "message": error
            })
            total_errors += 1
            continue
        
        # Validate payload
        violations, error_count, warning_count = validate_payload(
            payload, schema, payload_file.name
        )
        
        # Add payload identifier to violations
        for violation in violations:
            violation["payload"] = payload_file.name
            result["violations"].append(violation)
        
        total_errors += error_count
        total_warnings += warning_count
        result["payloads_tested"] += 1
    
    # Update summary
    result["summary"]["errors"] = total_errors
    result["summary"]["warnings"] = total_warnings
    
    if total_errors > 0:
        result["status"] = "fail"
    
    return result


def main():
    """Main entry point."""
    # Determine paths
    script_dir = Path(__file__).parent.resolve()
    repo_root = script_dir.parent.parent
    
    schema_path = repo_root / "docs/business/ba/products/structured-notes/fcn/schemas/fcn-v1.0-schema.json"
    payload_dir = repo_root / "docs/business/ba/products/structured-notes/fcn/test-vectors/sample-payloads"
    output_path = repo_root / "param-validation.json"
    
    # Check if schema exists
    if not schema_path.exists():
        result = {
            "status": "fail",
            "payloads_tested": 0,
            "violations": [{
                "path": "$",
                "rule": "schema_not_found",
                "message": f"Schema file not found: {schema_path}"
            }],
            "summary": {
                "errors": 1,
                "warnings": 0
            }
        }
        print(json.dumps(result, indent=2))
        output_path.write_text(json.dumps(result, indent=2) + "\n", encoding='utf-8')
        sys.exit(1)
    
    # Check if payload directory exists
    if not payload_dir.exists():
        result = {
            "status": "fail",
            "payloads_tested": 0,
            "violations": [{
                "path": "$",
                "rule": "payload_dir_not_found",
                "message": f"Payload directory not found: {payload_dir}"
            }],
            "summary": {
                "errors": 1,
                "warnings": 0
            }
        }
        print(json.dumps(result, indent=2))
        output_path.write_text(json.dumps(result, indent=2) + "\n", encoding='utf-8')
        sys.exit(1)
    
    # Run validation
    print(f"Validating FCN v1.0 parameters from: {payload_dir}")
    print(f"Using schema: {schema_path}")
    result = validate_fcn_parameters(payload_dir, schema_path)
    
    # Output results
    print("\n" + "=" * 60)
    print("VALIDATION RESULTS")
    print("=" * 60)
    print(f"Status: {result['status'].upper()}")
    print(f"Payloads Tested: {result['payloads_tested']}")
    print(f"Total Errors: {result['summary']['errors']}")
    print(f"Total Warnings: {result['summary']['warnings']}")
    
    if result['violations']:
        print(f"\nViolations ({len(result['violations'])})")
        print("-" * 60)
        for violation in result['violations']:
            payload_name = violation.get('payload', 'N/A')
            print(f"\nPayload: {payload_name}")
            print(f"  Path: {violation['path']}")
            print(f"  Rule: {violation['rule']}")
            print(f"  Message: {violation['message']}")
    
    # Write JSON output
    output_path.write_text(json.dumps(result, indent=2) + "\n", encoding='utf-8')
    print(f"\nValidation results written to: {output_path}")
    
    # Exit with appropriate code
    sys.exit(0 if result['status'] == 'pass' else 1)


if __name__ == '__main__':
    main()
