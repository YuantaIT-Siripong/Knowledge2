#!/usr/bin/env python3
"""
FCN Metadata Validator (Phase 0)

Validates YAML front matter completeness and document structure for FCN specs and test vectors.
Part of the FCN v1.0 governance framework.

Usage:
    python metadata_validator.py <file_or_directory>
"""

import sys
import yaml
import re
from pathlib import Path
from typing import Dict, List, Tuple


class MetadataValidator:
    """Validates document metadata (YAML front matter) conformance."""
    
    REQUIRED_FIELDS = {
        'product-spec': ['title', 'doc_type', 'status', 'spec_version', 'version', 'owner', 'approver', 'created', 'last_reviewed', 'classification', 'tags'],
        'product-definition': ['title', 'doc_type', 'status', 'version', 'owner', 'approver', 'created', 'last_reviewed', 'classification', 'tags'],
        'test-vector': ['vector_id', 'product_code', 'spec_version', 'description', 'taxonomy'],
        'decision-record': ['title', 'doc_type', 'adr', 'status', 'version', 'owner', 'approver', 'created', 'last_reviewed', 'classification', 'tags']
    }
    
    VALID_STATUSES = ['Draft', 'In Review', 'Approved', 'Published', 'Superseded', 'Archived', 'Proposed', 'Active', 'Deprecated', 'Removed']
    VALID_CLASSIFICATIONS = ['Public', 'Internal', 'Confidential', 'Restricted']
    
    def __init__(self):
        self.errors = []
        self.warnings = []
    
    def extract_front_matter(self, content: str) -> Tuple[Dict, str]:
        """Extract YAML front matter from markdown content."""
        pattern = r'^---\s*\n(.*?)\n---\s*\n'
        match = re.match(pattern, content, re.DOTALL)
        
        if not match:
            return None, content
        
        front_matter_str = match.group(1)
        body = content[match.end():]
        
        try:
            front_matter = yaml.safe_load(front_matter_str)
            return front_matter, body
        except yaml.YAMLError as e:
            self.errors.append(f"Invalid YAML in front matter: {e}")
            return None, body
    
    def validate_metadata(self, file_path: Path) -> bool:
        """Validate metadata for a single file."""
        self.errors = []
        self.warnings = []
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            self.errors.append(f"Failed to read file: {e}")
            return False
        
        front_matter, body = self.extract_front_matter(content)
        
        if front_matter is None:
            self.errors.append("No YAML front matter found")
            return False
        
        # Determine doc_type
        doc_type = front_matter.get('doc_type')
        if not doc_type:
            self.errors.append("Missing 'doc_type' field in front matter")
            return False
        
        # Check required fields
        required_fields = self.REQUIRED_FIELDS.get(doc_type, [])
        for field in required_fields:
            if field not in front_matter or front_matter[field] is None or front_matter[field] == '':
                self.errors.append(f"Missing or empty required field: '{field}'")
        
        # Validate status
        status = front_matter.get('status')
        if status and status not in self.VALID_STATUSES:
            self.errors.append(f"Invalid status '{status}'. Must be one of: {', '.join(self.VALID_STATUSES)}")
        
        # Validate classification
        classification = front_matter.get('classification')
        if classification and classification not in self.VALID_CLASSIFICATIONS:
            self.errors.append(f"Invalid classification '{classification}'. Must be one of: {', '.join(self.VALID_CLASSIFICATIONS)}")
        
        # Validate version format (semantic versioning)
        version = front_matter.get('version') or front_matter.get('spec_version')
        if version and not re.match(r'^\d+\.\d+\.\d+(-[a-z0-9-]+)?$', str(version)):
            self.warnings.append(f"Version '{version}' does not follow semantic versioning (MAJOR.MINOR.PATCH)")
        
        # Validate product_code for test vectors
        if doc_type == 'test-vector':
            product_code = front_matter.get('product_code')
            if product_code and product_code != 'FCN':
                self.errors.append(f"Invalid product_code '{product_code}'. Must be 'FCN' for FCN test vectors")
        
        return len(self.errors) == 0
    
    def validate_directory(self, dir_path: Path) -> Dict[str, bool]:
        """Validate all markdown files in directory."""
        results = {}
        
        for md_file in dir_path.rglob('*.md'):
            # Skip templates and archives
            if '_templates' in str(md_file) or 'archive' in str(md_file):
                continue
            
            is_valid = self.validate_metadata(md_file)
            results[str(md_file)] = {
                'valid': is_valid,
                'errors': self.errors.copy(),
                'warnings': self.warnings.copy()
            }
        
        return results
    
    def print_results(self, results: Dict):
        """Print validation results."""
        total = len(results)
        passed = sum(1 for r in results.values() if r['valid'])
        failed = total - passed
        
        print(f"\n{'='*70}")
        print(f"Metadata Validation Results")
        print(f"{'='*70}")
        print(f"Total files: {total}")
        print(f"Passed: {passed}")
        print(f"Failed: {failed}")
        print(f"{'='*70}\n")
        
        for file_path, result in results.items():
            if not result['valid']:
                print(f"❌ {file_path}")
                for error in result['errors']:
                    print(f"   ERROR: {error}")
                for warning in result['warnings']:
                    print(f"   WARNING: {warning}")
                print()
            else:
                if result['warnings']:
                    print(f"⚠️  {file_path}")
                    for warning in result['warnings']:
                        print(f"   WARNING: {warning}")
                    print()
        
        # Print passed files (optional)
        passed_files = [f for f, r in results.items() if r['valid'] and not r['warnings']]
        if passed_files:
            print(f"\n✅ {len(passed_files)} files passed without warnings")


def main():
    if len(sys.argv) < 2:
        print("Usage: python metadata_validator.py <file_or_directory>")
        sys.exit(1)
    
    path = Path(sys.argv[1])
    validator = MetadataValidator()
    
    if path.is_file():
        is_valid = validator.validate_metadata(path)
        results = {str(path): {
            'valid': is_valid,
            'errors': validator.errors,
            'warnings': validator.warnings
        }}
    elif path.is_dir():
        results = validator.validate_directory(path)
    else:
        print(f"Error: {path} is not a valid file or directory")
        sys.exit(1)
    
    validator.print_results(results)
    
    # Exit with error code if any validations failed
    if any(not r['valid'] for r in results.values()):
        sys.exit(1)
    else:
        sys.exit(0)


if __name__ == '__main__':
    main()
