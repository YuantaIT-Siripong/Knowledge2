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
from typing import Any, Dict, List, Tuple, Set

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


def parse_taxonomy_dimensions(payoff_types_path: Path) -> Tuple[List[str], str]:
    """
    Parse the payoff_types.md file to extract required taxonomy dimension keys.
    
    Args:
        payoff_types_path: Path to payoff_types.md
        
    Returns:
        Tuple of (dimension_keys_list, error_message)
    """
    try:
        content = payoff_types_path.read_text(encoding='utf-8')
    except Exception as e:
        return [], f"Failed to read payoff_types.md: {e}"
    
    # Look for the "Branch Coding" section which describes the tuple format
    # Expected: (barrier_type, settlement, coupon_memory, step_feature, recovery_mode)
    branch_coding_match = re.search(
        r'Each payoff branch path.*?tuple:\s*\(([^)]+)\)',
        content,
        re.DOTALL
    )
    
    if not branch_coding_match:
        return [], "Could not find branch coding tuple definition in payoff_types.md"
    
    # Extract dimension names from the tuple
    tuple_content = branch_coding_match.group(1)
    # Match dimension names like "barrier_type", "settlement", etc.
    dimensions = re.findall(r'(\w+)(?:\s*=|,|\))', tuple_content)
    
    # Clean up and validate
    dimensions = [d.strip() for d in dimensions if d.strip()]
    
    if not dimensions:
        return [], "Could not extract dimension keys from payoff_types.md"
    
    return dimensions, ""


def parse_spec_branches(spec_path: Path) -> Tuple[Dict[str, Dict[str, str]], str]:
    """
    Parse the FCN spec to extract branch inventory from Section 6.
    
    Args:
        spec_path: Path to fcn-v1.0.md
        
    Returns:
        Tuple of (branches_dict, error_message)
        branches_dict maps branch_id to its taxonomy dimensions
    """
    try:
        content = spec_path.read_text(encoding='utf-8')
    except Exception as e:
        return {}, f"Failed to read spec file: {e}"
    
    # Find Section 6 - Taxonomy & Branch Inventory
    section_match = re.search(
        r'## 6\. Taxonomy & Branch Inventory\s*\n(.*?)(?=\n## \d+\.|\Z)',
        content,
        re.DOTALL
    )
    
    if not section_match:
        return {}, "Could not find Section 6 (Taxonomy & Branch Inventory) in spec"
    
    section_content = section_match.group(1)
    
    # Find the normative branches table
    table_match = re.search(
        r'Normative branches.*?\n\|.*?\n\|[-|\s]+\n((?:\|.*?\n)+)',
        section_content,
        re.DOTALL | re.IGNORECASE
    )
    
    if not table_match:
        return {}, "Could not find normative branches table in Section 6"
    
    table_rows = table_match.group(1).strip().split('\n')
    
    branches = {}
    for row in table_rows:
        # Parse table row: | branch_id | barrier_type | settlement | coupon_memory | step_feature | recovery_mode | description |
        parts = [p.strip() for p in row.split('|') if p.strip()]
        
        if len(parts) >= 6:
            branch_id = parts[0]
            branches[branch_id] = {
                'barrier_type': parts[1],
                'settlement': parts[2],
                'coupon_memory': parts[3],
                'step_feature': parts[4],
                'recovery_mode': parts[5]
            }
    
    return branches, ""


def parse_test_vectors(test_vectors_dir: Path) -> Tuple[List[Dict[str, Any]], str]:
    """
    Parse all test vector files to extract branch_id, normative flag, and taxonomy.
    
    Args:
        test_vectors_dir: Path to test-vectors directory
        
    Returns:
        Tuple of (test_vectors_list, error_message)
    """
    test_vectors = []
    errors = []
    
    if not test_vectors_dir.exists():
        return [], f"Test vectors directory not found: {test_vectors_dir}"
    
    # Find all .md files except .gitkeep
    md_files = [f for f in test_vectors_dir.glob("*.md") if f.name != '.gitkeep']
    
    for md_file in md_files:
        front_matter, error = parse_front_matter(md_file)
        
        if error:
            errors.append(f"{md_file.name}: {error}")
            continue
        
        vector_info = {
            'filename': md_file.name,
            'branch_id': front_matter.get('branch_id', ''),
            'normative': front_matter.get('normative', False),
            'taxonomy': front_matter.get('taxonomy', {})
        }
        
        test_vectors.append(vector_info)
    
    error_msg = "; ".join(errors) if errors else ""
    return test_vectors, error_msg


def validate_branch_dimensions(
    branches: Dict[str, Dict[str, str]],
    required_dimensions: List[str]
) -> List[Dict[str, Any]]:
    """
    Validate that each branch has all required dimension keys.
    
    Returns:
        List of missing dimension errors
    """
    missing_dimensions = []
    
    for branch_id, dimensions in branches.items():
        missing = []
        for req_dim in required_dimensions:
            if req_dim not in dimensions or not dimensions[req_dim]:
                missing.append(req_dim)
        
        if missing:
            missing_dimensions.append({
                'branch_id': branch_id,
                'missing_keys': missing
            })
    
    return missing_dimensions


def check_duplicate_tuples(
    branches: Dict[str, Dict[str, str]]
) -> List[Dict[str, Any]]:
    """
    Check for duplicate dimension tuples across branches.
    
    Returns:
        List of duplicate tuple errors
    """
    tuple_to_branches = {}
    
    for branch_id, dimensions in branches.items():
        # Create a sorted tuple of dimension values for comparison
        tuple_key = tuple(sorted(dimensions.items()))
        
        if tuple_key not in tuple_to_branches:
            tuple_to_branches[tuple_key] = []
        tuple_to_branches[tuple_key].append(branch_id)
    
    duplicates = []
    for tuple_key, branch_ids in tuple_to_branches.items():
        if len(branch_ids) > 1:
            duplicates.append({
                'tuple': dict(tuple_key),
                'branch_ids': branch_ids
            })
    
    return duplicates


def validate_test_vector_branches(
    test_vectors: List[Dict[str, Any]],
    manifest_branches: Dict[str, Dict[str, str]]
) -> List[str]:
    """
    Validate that all test vector branch_ids are in manifest.
    
    Returns:
        List of unknown branch_ids
    """
    unknown_branches = []
    
    for vector in test_vectors:
        branch_id = vector['branch_id']
        if branch_id and branch_id not in manifest_branches:
            unknown_branches.append({
                'filename': vector['filename'],
                'branch_id': branch_id
            })
    
    return unknown_branches


def validate_normative_flags(
    test_vectors: List[Dict[str, Any]]
) -> List[str]:
    """
    Validate that all normative test vectors have is_normative=true.
    
    Returns:
        List of filenames with incorrect normative flags
    """
    incorrect_flags = []
    
    for vector in test_vectors:
        # Check if marked as normative in filename or should be normative
        # For now, we assume all vectors in the normative set should be marked true
        if vector['normative'] is not True:
            incorrect_flags.append({
                'filename': vector['filename'],
                'normative': vector['normative']
            })
    
    return incorrect_flags


def validate_fcn_taxonomy(
    spec_path: Path,
    payoff_types_path: Path,
    test_vectors_dir: Path
) -> Dict[str, Any]:
    """
    Main validation function for FCN v1.0 taxonomy and branch consistency.
    
    Returns:
        Validation result dictionary
    """
    result = {
        "status": "pass",
        "branches_evaluated": 0,
        "duplicate_tuples": [],
        "missing_dimensions": [],
        "unknown_branch_ids_in_vectors": []
    }
    
    # Parse required taxonomy dimensions from payoff_types.md
    required_dimensions, error = parse_taxonomy_dimensions(payoff_types_path)
    if error:
        result["status"] = "fail"
        result["error"] = error
        return result
    
    # Parse branch inventory from spec
    manifest_branches, error = parse_spec_branches(spec_path)
    if error:
        result["status"] = "fail"
        result["error"] = error
        return result
    
    result["branches_evaluated"] = len(manifest_branches)
    
    # Validate each branch has all required dimensions
    missing_dims = validate_branch_dimensions(manifest_branches, required_dimensions)
    if missing_dims:
        result["status"] = "fail"
        result["missing_dimensions"] = missing_dims
    
    # Check for duplicate tuples
    duplicates = check_duplicate_tuples(manifest_branches)
    if duplicates:
        result["status"] = "fail"
        result["duplicate_tuples"] = duplicates
    
    # Parse test vectors
    test_vectors, error = parse_test_vectors(test_vectors_dir)
    if error:
        # Non-fatal warning, continue
        result["test_vector_parse_warnings"] = error
    
    # Validate test vector branch_ids are subset of manifest
    unknown_branches = validate_test_vector_branches(test_vectors, manifest_branches)
    if unknown_branches:
        result["status"] = "fail"
        result["unknown_branch_ids_in_vectors"] = unknown_branches
    
    # Validate normative flags (informational, not blocking)
    incorrect_flags = validate_normative_flags(test_vectors)
    if incorrect_flags:
        result["normative_flag_warnings"] = incorrect_flags
    
    return result


def main():
    """Main entry point."""
    # Determine paths
    script_dir = Path(__file__).parent.resolve()
    repo_root = script_dir.parent.parent
    spec_path = repo_root / "docs/business/ba/products/structured-notes/fcn/specs/fcn-v1.0.md"
    payoff_types_path = repo_root / "docs/business/ba/products/structured-notes/common/payoff_types.md"
    test_vectors_dir = repo_root / "docs/business/ba/products/structured-notes/fcn/test-vectors"
    output_path = repo_root / "taxonomy-validation.json"
    
    # Check if required files exist
    if not spec_path.exists():
        result = {
            "status": "fail",
            "error": f"Specification file not found: {spec_path}",
            "branches_evaluated": 0,
            "duplicate_tuples": [],
            "missing_dimensions": [],
            "unknown_branch_ids_in_vectors": []
        }
        print(json.dumps(result, indent=2))
        output_path.write_text(json.dumps(result, indent=2) + "\n", encoding='utf-8')
        sys.exit(1)
    
    if not payoff_types_path.exists():
        result = {
            "status": "fail",
            "error": f"Payoff types file not found: {payoff_types_path}",
            "branches_evaluated": 0,
            "duplicate_tuples": [],
            "missing_dimensions": [],
            "unknown_branch_ids_in_vectors": []
        }
        print(json.dumps(result, indent=2))
        output_path.write_text(json.dumps(result, indent=2) + "\n", encoding='utf-8')
        sys.exit(1)
    
    # Run validation
    print(f"Validating FCN v1.0 taxonomy and branch consistency...")
    print(f"  Spec: {spec_path}")
    print(f"  Taxonomy: {payoff_types_path}")
    print(f"  Test Vectors: {test_vectors_dir}")
    
    result = validate_fcn_taxonomy(spec_path, payoff_types_path, test_vectors_dir)
    
    # Output results
    print("\n" + "=" * 60)
    print("VALIDATION RESULTS")
    print("=" * 60)
    print(f"Status: {result['status'].upper()}")
    print(f"Branches Evaluated: {result['branches_evaluated']}")
    
    if result.get('error'):
        print(f"\nError: {result['error']}")
    
    if result['missing_dimensions']:
        print(f"\nMissing Dimensions ({len(result['missing_dimensions'])}):")
        for item in result['missing_dimensions']:
            print(f"  - Branch '{item['branch_id']}': missing {item['missing_keys']}")
    
    if result['duplicate_tuples']:
        print(f"\nDuplicate Tuples ({len(result['duplicate_tuples'])}):")
        for item in result['duplicate_tuples']:
            print(f"  - Tuple {item['tuple']}: found in branches {item['branch_ids']}")
    
    if result['unknown_branch_ids_in_vectors']:
        print(f"\nUnknown Branch IDs in Vectors ({len(result['unknown_branch_ids_in_vectors'])}):")
        for item in result['unknown_branch_ids_in_vectors']:
            print(f"  - {item['filename']}: branch_id '{item['branch_id']}' not in manifest")
    
    if result.get('test_vector_parse_warnings'):
        print(f"\nTest Vector Parse Warnings: {result['test_vector_parse_warnings']}")
    
    if result.get('normative_flag_warnings'):
        print(f"\nNormative Flag Warnings ({len(result['normative_flag_warnings'])}):")
        for item in result['normative_flag_warnings']:
            print(f"  - {item['filename']}: normative={item['normative']} (expected True)")
    
    # Write JSON output
    output_path.write_text(json.dumps(result, indent=2) + "\n", encoding='utf-8')
    print(f"\nValidation results written to: {output_path}")
    
    # Exit with appropriate code
    sys.exit(0 if result['status'] == 'pass' else 1)


if __name__ == '__main__':
    main()
