#!/usr/bin/env python3
"""
FCN v1.0 Phase 1 Taxonomy & Branch Consistency Validator

Validates branch taxonomy vs spec & manifest.

Checks:
- Each branch_code in manifest has all required dimension keys.
- No duplicate dimension tuples.
- Test vector branch_ids subset of manifest branch codes.
- All normative branches flagged is_normative=true.

Output: taxonomy-validation.json
{
  "status":"pass|fail",
  "branches_evaluated": n,
  "duplicate_tuples": [],
  "missing_dimensions": [],
  "unknown_branch_ids_in_vectors": []
}
"""

import json
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Tuple

import yaml


# Required taxonomy dimensions based on common/payoff_types.md
REQUIRED_DIMENSIONS = [
    'barrier_type',
    'settlement',
    'coupon_memory',
    'step_feature',
    'recovery_mode'
]


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


def parse_spec_branch_table(spec_path: Path) -> Tuple[List[Dict[str, Any]], str]:
    """
    Parse the branch inventory table from Section 6 of the spec.
    
    Args:
        spec_path: Path to fcn-v1.0.md file
        
    Returns:
        Tuple of (list of branch dictionaries, error_message)
    """
    try:
        content = spec_path.read_text(encoding='utf-8')
    except Exception as e:
        return [], f"Failed to read spec file: {e}"
    
    # Find Section 6 - Taxonomy & Branch Inventory
    section_match = re.search(
        r'## 6\. Taxonomy & Branch Inventory.*?Normative branches \(v1\.0\):\s*\n\|([^\n]+)\|\s*\n\|([^\n]+)\|\s*\n((?:\|[^\n]+\|\s*\n)+)',
        content,
        re.DOTALL
    )
    
    if not section_match:
        return [], "Could not find normative branches table in Section 6"
    
    header_line = section_match.group(1)
    table_rows = section_match.group(3)
    
    # Parse header
    headers = [h.strip() for h in header_line.split('|') if h.strip()]
    
    # Parse rows
    branches = []
    for line in table_rows.strip().split('\n'):
        if not line.strip() or line.strip().startswith('<!--'):
            continue
        
        cells = [c.strip() for c in line.split('|') if c.strip()]
        if len(cells) == len(headers):
            branch = dict(zip(headers, cells))
            branches.append(branch)
    
    return branches, ""


def get_test_vectors(test_vectors_dir: Path) -> List[Path]:
    """
    Get all test vector markdown files from the test-vectors directory.
    
    Args:
        test_vectors_dir: Path to test-vectors directory
        
    Returns:
        List of paths to test vector files
    """
    if not test_vectors_dir.exists():
        return []
    
    return [f for f in test_vectors_dir.glob('*.md') if f.is_file() and f.name != '.gitkeep']


def parse_test_vector(vector_path: Path) -> Tuple[Dict[str, Any], str]:
    """
    Parse a test vector file to extract branch_id, normative flag, and taxonomy.
    
    Args:
        vector_path: Path to test vector file
        
    Returns:
        Tuple of (vector_info dict, error_message)
    """
    front_matter, error = parse_front_matter(vector_path)
    if error:
        return {}, error
    
    vector_info = {
        'filename': vector_path.name,
        'branch_id': front_matter.get('branch_id'),
        'normative': front_matter.get('normative', False),
        'taxonomy': front_matter.get('taxonomy', {})
    }
    
    return vector_info, ""


def validate_branch_dimensions(branches: List[Dict[str, Any]]) -> List[str]:
    """
    Check that each branch has all required taxonomy dimensions.
    
    Args:
        branches: List of branch dictionaries from spec
        
    Returns:
        List of error messages for missing dimensions
    """
    missing_dimensions = []
    
    for branch in branches:
        branch_id = branch.get('branch_id', 'unknown')
        
        for dimension in REQUIRED_DIMENSIONS:
            if dimension not in branch or not branch[dimension]:
                missing_dimensions.append(
                    f"Branch '{branch_id}' missing dimension '{dimension}'"
                )
    
    return missing_dimensions


def check_duplicate_tuples(branches: List[Dict[str, Any]]) -> List[str]:
    """
    Check for duplicate taxonomy tuples across branches.
    
    Args:
        branches: List of branch dictionaries from spec
        
    Returns:
        List of duplicate descriptions
    """
    duplicates = []
    seen_tuples = {}
    
    for branch in branches:
        branch_id = branch.get('branch_id', 'unknown')
        
        # Create tuple of dimension values
        tuple_values = tuple(
            branch.get(dim, '') for dim in REQUIRED_DIMENSIONS
        )
        
        if tuple_values in seen_tuples:
            duplicates.append(
                f"Duplicate taxonomy tuple for branches '{seen_tuples[tuple_values]}' and '{branch_id}': {dict(zip(REQUIRED_DIMENSIONS, tuple_values))}"
            )
        else:
            seen_tuples[tuple_values] = branch_id
    
    return duplicates


def validate_test_vector_branches(
    branches: List[Dict[str, Any]], 
    test_vectors: List[Dict[str, Any]]
) -> List[str]:
    """
    Check that test vector branch_ids are subset of manifest branch codes.
    
    Args:
        branches: List of branch dictionaries from spec
        test_vectors: List of test vector info dictionaries
        
    Returns:
        List of unknown branch_ids found in test vectors
    """
    spec_branch_ids = {branch.get('branch_id') for branch in branches}
    unknown_branches = []
    
    for vector in test_vectors:
        branch_id = vector.get('branch_id')
        if branch_id and branch_id not in spec_branch_ids:
            unknown_branches.append(
                f"Test vector '{vector['filename']}' references unknown branch_id '{branch_id}'"
            )
    
    return unknown_branches


def validate_normative_flags(test_vectors: List[Dict[str, Any]]) -> List[str]:
    """
    Check that test vectors claiming to be normative have normative=true flag.
    
    Args:
        test_vectors: List of test vector info dictionaries
        
    Returns:
        List of warnings for normative flag issues
    """
    issues = []
    
    for vector in test_vectors:
        # Check if filename suggests it's normative (contains 'N' followed by number)
        filename = vector.get('filename', '')
        is_normative_file = bool(re.search(r'[Nn]\d+', filename))
        normative_flag = vector.get('normative', False)
        
        if is_normative_file and not normative_flag:
            issues.append(
                f"Test vector '{filename}' appears to be normative but has normative={normative_flag}"
            )
    
    return issues


def validate_fcn_taxonomy(spec_path: Path, test_vectors_dir: Path) -> Dict[str, Any]:
    """
    Main validation function for FCN v1.0 taxonomy and branch consistency.
    
    Args:
        spec_path: Path to fcn-v1.0.md file
        test_vectors_dir: Path to test-vectors directory
        
    Returns:
        Validation result dictionary
    """
    result = {
        "status": "pass",
        "branches_evaluated": 0,
        "duplicate_tuples": [],
        "missing_dimensions": [],
        "unknown_branch_ids_in_vectors": [],
        "normative_flag_warnings": [],
        "spec_path": str(spec_path),
        "test_vectors_path": str(test_vectors_dir),
        "parse_errors": []
    }
    
    # Parse spec branch table
    branches, parse_error = parse_spec_branch_table(spec_path)
    if parse_error:
        result["status"] = "fail"
        result["parse_errors"].append(f"Spec parsing error: {parse_error}")
        return result
    
    if not branches:
        result["status"] = "fail"
        result["parse_errors"].append("No branches found in spec")
        return result
    
    result["branches_evaluated"] = len(branches)
    
    # Validate branch dimensions
    missing_dims = validate_branch_dimensions(branches)
    if missing_dims:
        result["status"] = "fail"
        result["missing_dimensions"] = missing_dims
    
    # Check for duplicate tuples
    duplicates = check_duplicate_tuples(branches)
    if duplicates:
        result["status"] = "fail"
        result["duplicate_tuples"] = duplicates
    
    # Parse test vectors
    test_vector_files = get_test_vectors(test_vectors_dir)
    test_vectors = []
    
    for vector_path in test_vector_files:
        vector_info, error = parse_test_vector(vector_path)
        if error:
            result["parse_errors"].append(f"Error parsing {vector_path.name}: {error}")
        else:
            test_vectors.append(vector_info)
    
    # Validate test vector branch_ids
    unknown_branches = validate_test_vector_branches(branches, test_vectors)
    if unknown_branches:
        result["status"] = "fail"
        result["unknown_branch_ids_in_vectors"] = unknown_branches
    
    # Validate normative flags
    normative_warnings = validate_normative_flags(test_vectors)
    if normative_warnings:
        result["status"] = "fail"
        result["normative_flag_warnings"] = normative_warnings
    
    return result


def main():
    """Main entry point."""
    # Determine paths
    script_dir = Path(__file__).parent.resolve()
    repo_root = script_dir.parent.parent
    spec_path = repo_root / "docs/business/ba/products/structured-notes/fcn/specs/fcn-v1.0.md"
    test_vectors_dir = repo_root / "docs/business/ba/products/structured-notes/fcn/test-vectors"
    output_path = repo_root / "taxonomy-validation.json"
    
    # Check if spec file exists
    if not spec_path.exists():
        result = {
            "status": "fail",
            "branches_evaluated": 0,
            "duplicate_tuples": [],
            "missing_dimensions": [],
            "unknown_branch_ids_in_vectors": [],
            "parse_errors": [f"Specification file not found: {spec_path}"]
        }
        print(json.dumps(result, indent=2))
        output_path.write_text(json.dumps(result, indent=2) + "\n", encoding='utf-8')
        sys.exit(1)
    
    # Run validation
    print(f"Validating FCN v1.0 taxonomy from: {spec_path}")
    print(f"Test vectors directory: {test_vectors_dir}")
    result = validate_fcn_taxonomy(spec_path, test_vectors_dir)
    
    # Output results
    print("\n" + "=" * 60)
    print("TAXONOMY VALIDATION RESULTS")
    print("=" * 60)
    print(f"Status: {result['status'].upper()}")
    print(f"Branches Evaluated: {result['branches_evaluated']}")
    
    if result.get('parse_errors'):
        print(f"\nParse Errors ({len(result['parse_errors'])}):")
        for error in result['parse_errors']:
            print(f"  - {error}")
    
    if result['missing_dimensions']:
        print(f"\nMissing Dimensions ({len(result['missing_dimensions'])}):")
        for issue in result['missing_dimensions']:
            print(f"  - {issue}")
    
    if result['duplicate_tuples']:
        print(f"\nDuplicate Tuples ({len(result['duplicate_tuples'])}):")
        for dup in result['duplicate_tuples']:
            print(f"  - {dup}")
    
    if result['unknown_branch_ids_in_vectors']:
        print(f"\nUnknown Branch IDs in Test Vectors ({len(result['unknown_branch_ids_in_vectors'])}):")
        for issue in result['unknown_branch_ids_in_vectors']:
            print(f"  - {issue}")
    
    if result.get('normative_flag_warnings'):
        print(f"\nNormative Flag Warnings ({len(result['normative_flag_warnings'])}):")
        for warning in result['normative_flag_warnings']:
            print(f"  - {warning}")
    
    # Write JSON output
    output_path.write_text(json.dumps(result, indent=2) + "\n", encoding='utf-8')
    print(f"\nValidation results written to: {output_path}")
    
    # Exit with appropriate code
    sys.exit(0 if result['status'] == 'pass' else 1)


if __name__ == '__main__':
    main()
