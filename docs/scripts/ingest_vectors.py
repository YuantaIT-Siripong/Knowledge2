#!/usr/bin/env python3
"""
FCN v1.0 Test Vector Ingestion Script

Ingests and validates test vector files for FCN v1.0.
Parses front matter and ensures all required fields are present.

Output: test-vectors-ingestion.json with status and vector details
"""

import json
import re
import sys
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
        return {}, "No YAML front matter found (expected content between --- delimiters)"
    
    yaml_content = match.group(1)
    
    try:
        front_matter = yaml.safe_load(yaml_content)
        if not isinstance(front_matter, dict):
            return {}, "Front matter is not a valid YAML dictionary"
        return front_matter, ""
    except yaml.YAMLError as e:
        return {}, f"Failed to parse YAML front matter: {e}"


def validate_test_vector(file_path: Path) -> Dict[str, Any]:
    """
    Validate a single test vector file.
    
    Args:
        file_path: Path to test vector markdown file
        
    Returns:
        Validation result dictionary
    """
    result = {
        "file": str(file_path.name),
        "status": "pass",
        "missing_fields": [],
        "parse_error": ""
    }
    
    # Parse front matter
    front_matter, parse_error = parse_front_matter(file_path)
    if parse_error:
        result["status"] = "fail"
        result["parse_error"] = parse_error
        return result
    
    # Required fields for test vectors
    required_fields = [
        'title',
        'doc_type',
        'status',
        'version',
        'normative',
        'branch_id',
        'spec_version',
        'owner',
        'classification',
        'tags',
        'taxonomy'
    ]
    
    missing = []
    for field in required_fields:
        if field not in front_matter or front_matter[field] is None:
            missing.append(field)
        elif field in ['tags'] and not front_matter[field]:
            missing.append(f"{field} (empty)")
        elif field == 'taxonomy' and not isinstance(front_matter[field], dict):
            missing.append(f"{field} (must be a dictionary)")
    
    if missing:
        result["status"] = "fail"
        result["missing_fields"] = missing
    
    return result


def ingest_test_vectors() -> Dict[str, Any]:
    """
    Ingest all FCN v1.0 test vectors.
    
    Returns:
        Overall ingestion result
    """
    script_dir = Path(__file__).parent.resolve()
    repo_root = script_dir.parent.parent
    vectors_dir = repo_root / "docs/business/ba/products/structured-notes/fcn/test-vectors"
    
    result = {
        "status": "pass",
        "vectors_ingested": 0,
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
        vector_result = validate_test_vector(vector_file)
        result["details"].append(vector_result)
        
        if vector_result["status"] == "pass":
            result["vectors_ingested"] += 1
        else:
            result["vectors_failed"] += 1
            result["status"] = "fail"
    
    return result


def main():
    """Main entry point."""
    print("=" * 60)
    print("FCN v1.0 Test Vector Ingestion")
    print("=" * 60)
    
    result = ingest_test_vectors()
    
    print(f"\nStatus: {result['status'].upper()}")
    print(f"Vectors Ingested: {result.get('vectors_ingested', 0)}")
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
            if detail.get('missing_fields'):
                print(f"    Missing Fields: {', '.join(detail['missing_fields'])}")
    
    # Write JSON output
    script_dir = Path(__file__).parent.resolve()
    repo_root = script_dir.parent.parent
    output_path = repo_root / "test-vectors-ingestion.json"
    output_path.write_text(json.dumps(result, indent=2) + "\n", encoding='utf-8')
    print(f"\nResults written to: {output_path}")
    
    # Exit with appropriate code
    sys.exit(0 if result['status'] == 'pass' else 1)


if __name__ == '__main__':
    main()
