#!/usr/bin/env python3
"""
FCN v1.0 Phase 0 Metadata / Front Matter Validator

Validates FCN v1.0 specification front matter and manifest linkage.

Requirements:
- Parse front matter of fcn-v1.0.md
- Verify required keys present: title, doc_type, status, spec_version, version, 
  owner, classification, tags, activation_checklist_issue, normative_test_vector_set
- Ensure version == spec_version
- Confirm activation_checklist_issue HTTP 200 (or existing issue number pattern)
- Output JSON: metadata-validation.json with fields:
  - status: pass|fail
  - missing_fields[]
  - inconsistencies[]
  - activation_issue_reachable: bool
"""

import json
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Tuple

import requests
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
        return {}, "No YAML front matter found (expected content between --- delimiters)"
    
    yaml_content = match.group(1)
    
    try:
        front_matter = yaml.safe_load(yaml_content)
        if not isinstance(front_matter, dict):
            return {}, "Front matter is not a valid YAML dictionary"
        return front_matter, ""
    except yaml.YAMLError as e:
        return {}, f"Failed to parse YAML front matter: {e}"


def validate_required_fields(front_matter: Dict[str, Any]) -> List[str]:
    """
    Validate that all required fields are present in front matter.
    
    Args:
        front_matter: Parsed front matter dictionary
        
    Returns:
        List of missing field names (empty if all present)
    """
    required_fields = [
        'title',
        'doc_type',
        'status',
        'spec_version',
        'version',
        'owner',
        'classification',
        'tags',
        'activation_checklist_issue',
        'normative_test_vector_set'
    ]
    
    missing = []
    for field in required_fields:
        if field not in front_matter or front_matter[field] is None:
            missing.append(field)
        # Check for empty lists/strings
        elif field in ['tags', 'normative_test_vector_set']:
            if not front_matter[field]:
                missing.append(f"{field} (empty)")
        elif field in ['title', 'owner', 'classification', 'activation_checklist_issue']:
            if isinstance(front_matter[field], str) and not front_matter[field].strip():
                missing.append(f"{field} (empty)")
    
    return missing


def check_version_consistency(front_matter: Dict[str, Any]) -> List[str]:
    """
    Check that version == spec_version.
    
    Args:
        front_matter: Parsed front matter dictionary
        
    Returns:
        List of inconsistency descriptions (empty if consistent)
    """
    inconsistencies = []
    
    version = front_matter.get('version')
    spec_version = front_matter.get('spec_version')
    
    if version is None or spec_version is None:
        # Already caught by missing fields check
        return inconsistencies
    
    # Convert to strings for comparison
    version_str = str(version)
    spec_version_str = str(spec_version)
    
    if version_str != spec_version_str:
        inconsistencies.append(
            f"version ({version_str}) does not match spec_version ({spec_version_str})"
        )
    
    return inconsistencies


def check_activation_issue_reachable(activation_url: str) -> Tuple[bool, str]:
    """
    Check if the activation_checklist_issue URL is reachable (HTTP 200).
    
    Args:
        activation_url: URL to check
        
    Returns:
        Tuple of (is_reachable, status_message)
    """
    if not activation_url:
        return False, "No activation_checklist_issue URL provided"
    
    # Check if it matches GitHub issue pattern
    github_issue_pattern = r'https://github\.com/[^/]+/[^/]+/issues/\d+'
    if not re.match(github_issue_pattern, activation_url):
        return False, f"URL does not match expected GitHub issue pattern: {activation_url}"
    
    try:
        response = requests.head(activation_url, timeout=10, allow_redirects=True)
        
        if response.status_code == 200:
            return True, f"HTTP {response.status_code} - Issue is reachable"
        elif response.status_code == 404:
            return False, f"HTTP {response.status_code} - Issue not found"
        else:
            # Try GET if HEAD fails
            response = requests.get(activation_url, timeout=10, allow_redirects=True)
            if response.status_code == 200:
                return True, f"HTTP {response.status_code} - Issue is reachable"
            else:
                return False, f"HTTP {response.status_code} - Issue not accessible"
                
    except requests.exceptions.Timeout:
        return False, "Request timeout - unable to verify issue reachability"
    except requests.exceptions.ConnectionError:
        return False, "Connection error - unable to reach GitHub"
    except Exception as e:
        return False, f"Error checking URL: {e}"


def validate_fcn_metadata(spec_path: Path) -> Dict[str, Any]:
    """
    Main validation function for FCN v1.0 metadata.
    
    Args:
        spec_path: Path to fcn-v1.0.md file
        
    Returns:
        Validation result dictionary
    """
    result = {
        "status": "pass",
        "missing_fields": [],
        "inconsistencies": [],
        "activation_issue_reachable": False,
        "activation_issue_check_message": "",
        "file_path": str(spec_path),
        "parse_error": ""
    }
    
    # Parse front matter
    front_matter, parse_error = parse_front_matter(spec_path)
    if parse_error:
        result["status"] = "fail"
        result["parse_error"] = parse_error
        return result
    
    # Check required fields
    missing_fields = validate_required_fields(front_matter)
    if missing_fields:
        result["status"] = "fail"
        result["missing_fields"] = missing_fields
    
    # Check version consistency
    inconsistencies = check_version_consistency(front_matter)
    if inconsistencies:
        result["status"] = "fail"
        result["inconsistencies"].extend(inconsistencies)
    
    # Check activation issue reachability
    activation_url = front_matter.get('activation_checklist_issue', '')
    is_reachable, message = check_activation_issue_reachable(activation_url)
    result["activation_issue_reachable"] = is_reachable
    result["activation_issue_check_message"] = message
    
    if not is_reachable:
        result["status"] = "fail"
        result["inconsistencies"].append(
            f"activation_checklist_issue not reachable: {message}"
        )
    
    return result


def main():
    """Main entry point."""
    # Determine paths
    script_dir = Path(__file__).parent.resolve()
    repo_root = script_dir.parent.parent
    spec_path = repo_root / "docs/business/ba/products/structured-notes/fcn/specs/fcn-v1.0.md"
    output_path = repo_root / "metadata-validation.json"
    
    # Check if spec file exists
    if not spec_path.exists():
        result = {
            "status": "fail",
            "missing_fields": [],
            "inconsistencies": [],
            "activation_issue_reachable": False,
            "parse_error": f"Specification file not found: {spec_path}"
        }
        print(json.dumps(result, indent=2))
        output_path.write_text(json.dumps(result, indent=2) + "\n", encoding='utf-8')
        sys.exit(1)
    
    # Run validation
    print(f"Validating FCN v1.0 metadata from: {spec_path}")
    result = validate_fcn_metadata(spec_path)
    
    # Output results
    print("\n" + "=" * 60)
    print("VALIDATION RESULTS")
    print("=" * 60)
    print(f"Status: {result['status'].upper()}")
    
    if result.get('parse_error'):
        print(f"\nParse Error: {result['parse_error']}")
    
    if result['missing_fields']:
        print(f"\nMissing Fields ({len(result['missing_fields'])}):")
        for field in result['missing_fields']:
            print(f"  - {field}")
    
    if result['inconsistencies']:
        print(f"\nInconsistencies ({len(result['inconsistencies'])}):")
        for inconsistency in result['inconsistencies']:
            print(f"  - {inconsistency}")
    
    print(f"\nActivation Issue Reachable: {result['activation_issue_reachable']}")
    print(f"Check Message: {result['activation_issue_check_message']}")
    
    # Write JSON output
    output_path.write_text(json.dumps(result, indent=2) + "\n", encoding='utf-8')
    print(f"\nValidation results written to: {output_path}")
    
    # Exit with appropriate code
    sys.exit(0 if result['status'] == 'pass' else 1)


if __name__ == '__main__':
    main()
