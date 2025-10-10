#!/usr/bin/env python3
"""
FCN v1.0 Phase 1 Taxonomy Validator

Validates that test vector taxonomy entries conform to the canonical taxonomy
defined in common/payoff_types.md.

Output: taxonomy-validation.json with status and validation details
"""

import json
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Set, Tuple

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


def load_canonical_taxonomy() -> Dict[str, Set[str]]:
    """
    Load canonical taxonomy codes from payoff_types.md.
    
    Returns:
        Dictionary mapping dimension names to valid code sets
    """
    # Define canonical taxonomy based on the specification
    canonical = {
        "barrier_type": {"down-in", "down-and-in", "down-and-out", "up-and-in"},
        "settlement": {"physical-settlement", "cash-settlement"},
        "coupon_memory": {"memory", "no-memory"},
        "step_feature": {"step-down", "no-step"},
        "recovery_mode": {"par-recovery", "proportional-loss"}
    }
    return canonical


def validate_taxonomy_entry(taxonomy: Dict[str, Any], canonical: Dict[str, Set[str]]) -> List[str]:
    """
    Validate a taxonomy entry against canonical taxonomy.
    
    Args:
        taxonomy: Taxonomy dictionary from test vector
        canonical: Canonical taxonomy definitions
        
    Returns:
        List of validation errors (empty if valid)
    """
    errors = []
    
    # Check for missing dimensions
    for dimension in canonical.keys():
        if dimension not in taxonomy:
            errors.append(f"Missing taxonomy dimension: {dimension}")
            continue
        
        # Check if value is valid
        value = taxonomy[dimension]
        if value not in canonical[dimension]:
            valid_values = ", ".join(sorted(canonical[dimension]))
            errors.append(
                f"Invalid value '{value}' for dimension '{dimension}'. "
                f"Valid values: {valid_values}"
            )
    
    # Check for extra dimensions not in canonical
    for dimension in taxonomy.keys():
        if dimension not in canonical:
            errors.append(f"Unknown taxonomy dimension: {dimension}")
    
    return errors


def validate_test_vector_taxonomy(file_path: Path, canonical: Dict[str, Set[str]]) -> Dict[str, Any]:
    """
    Validate taxonomy in a single test vector file.
    
    Args:
        file_path: Path to test vector markdown file
        canonical: Canonical taxonomy definitions
        
    Returns:
        Validation result dictionary
    """
    result = {
        "file": str(file_path.name),
        "status": "pass",
        "errors": [],
        "parse_error": ""
    }
    
    # Parse front matter
    front_matter, parse_error = parse_front_matter(file_path)
    if parse_error:
        result["status"] = "fail"
        result["parse_error"] = parse_error
        return result
    
    # Check if taxonomy field exists
    if 'taxonomy' not in front_matter:
        result["status"] = "fail"
        result["errors"] = ["Missing taxonomy field in front matter"]
        return result
    
    taxonomy = front_matter['taxonomy']
    if not isinstance(taxonomy, dict):
        result["status"] = "fail"
        result["errors"] = ["Taxonomy must be a dictionary"]
        return result
    
    # Validate taxonomy
    errors = validate_taxonomy_entry(taxonomy, canonical)
    if errors:
        result["status"] = "fail"
        result["errors"] = errors
    
    return result


def validate_all_taxonomies() -> Dict[str, Any]:
    """
    Validate taxonomy for all FCN v1.0 test vectors.
    
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
    
    # Load canonical taxonomy
    canonical = load_canonical_taxonomy()
    
    # Find all test vector markdown files
    vector_files = sorted(vectors_dir.glob("fcn-v1.0-*.md"))
    
    if not vector_files:
        result["status"] = "fail"
        result["error"] = "No test vector files found"
        return result
    
    for vector_file in vector_files:
        vector_result = validate_test_vector_taxonomy(vector_file, canonical)
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
    print("FCN v1.0 Phase 1 Taxonomy Validation")
    print("=" * 60)
    
    result = validate_all_taxonomies()
    
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
    output_path = repo_root / "taxonomy-validation.json"
    output_path.write_text(json.dumps(result, indent=2) + "\n", encoding='utf-8')
    print(f"\nResults written to: {output_path}")
    
    # Exit with appropriate code
    sys.exit(0 if result['status'] == 'pass' else 1)


if __name__ == '__main__':
    main()
