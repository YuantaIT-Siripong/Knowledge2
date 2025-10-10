#!/usr/bin/env python3
"""
FCN Taxonomy Validator (Phase 1)

Validates taxonomy tuple completeness and consistency across manifest, specs, and test vectors.
Part of the FCN v1.0 governance framework.

Usage:
    python taxonomy_validator.py <fcn_base_directory>
"""

import sys
import yaml
import re
from pathlib import Path
from typing import Dict, List, Set, Tuple


class TaxonomyValidator:
    """Validates taxonomy tuple conformance and consistency."""
    
    TAXONOMY_DIMENSIONS = {
        'barrier_type': ['down-in', 'down-and-in', 'down-and-out', 'up-and-in', 'none'],
        'settlement': ['physical-settlement', 'cash-settlement'],
        'coupon_memory': ['memory', 'no-memory'],
        'step_feature': ['step-down', 'no-step'],
        'recovery_mode': ['par-recovery', 'proportional-loss']
    }
    
    REQUIRED_DIMENSIONS = ['barrier_type', 'settlement', 'coupon_memory', 'step_feature', 'recovery_mode']
    
    def __init__(self):
        self.errors = []
        self.warnings = []
        self.branches_from_manifest = {}
        self.test_vectors_taxonomy = {}
    
    def load_manifest(self, manifest_path: Path) -> bool:
        """Load and parse manifest.yaml."""
        try:
            with open(manifest_path, 'r', encoding='utf-8') as f:
                manifest = yaml.safe_load(f)
            
            branches = manifest.get('branches', [])
            for branch in branches:
                branch_id = branch.get('branch_id')
                taxonomy = branch.get('taxonomy', {})
                self.branches_from_manifest[branch_id] = taxonomy
            
            return True
        except Exception as e:
            self.errors.append(f"Failed to load manifest: {e}")
            return False
    
    def validate_taxonomy_tuple(self, taxonomy: Dict, context: str) -> bool:
        """Validate a single taxonomy tuple."""
        valid = True
        
        # Check completeness
        for dimension in self.REQUIRED_DIMENSIONS:
            if dimension not in taxonomy or not taxonomy[dimension]:
                self.errors.append(f"{context}: Missing required dimension '{dimension}'")
                valid = False
                continue
            
            # Check valid code
            value = taxonomy[dimension]
            valid_codes = self.TAXONOMY_DIMENSIONS.get(dimension, [])
            if value not in valid_codes:
                self.errors.append(
                    f"{context}: Invalid code '{value}' for dimension '{dimension}'. "
                    f"Must be one of: {', '.join(valid_codes)}"
                )
                valid = False
        
        return valid
    
    def validate_manifest_branches(self) -> bool:
        """Validate taxonomy in manifest branches."""
        all_valid = True
        
        for branch_id, taxonomy in self.branches_from_manifest.items():
            context = f"Manifest branch '{branch_id}'"
            is_valid = self.validate_taxonomy_tuple(taxonomy, context)
            all_valid = all_valid and is_valid
        
        return all_valid
    
    def extract_test_vector_taxonomy(self, file_path: Path) -> Dict:
        """Extract taxonomy from test vector markdown file."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Extract YAML front matter
            pattern = r'^---\s*\n(.*?)\n---\s*\n'
            match = re.match(pattern, content, re.DOTALL)
            
            if not match:
                return None
            
            front_matter = yaml.safe_load(match.group(1))
            return front_matter.get('taxonomy')
        except Exception as e:
            self.warnings.append(f"Failed to parse {file_path.name}: {e}")
            return None
    
    def validate_test_vectors(self, test_vectors_dir: Path) -> bool:
        """Validate taxonomy in test vectors."""
        all_valid = True
        
        for vector_file in test_vectors_dir.glob('*.md'):
            taxonomy = self.extract_test_vector_taxonomy(vector_file)
            
            if taxonomy is None:
                self.warnings.append(f"Test vector {vector_file.name}: No taxonomy found")
                continue
            
            context = f"Test vector '{vector_file.name}'"
            is_valid = self.validate_taxonomy_tuple(taxonomy, context)
            all_valid = all_valid and is_valid
            
            # Store for cross-reference validation
            self.test_vectors_taxonomy[vector_file.name] = taxonomy
        
        return all_valid
    
    def validate_branch_consistency(self) -> bool:
        """Validate that test vectors reference valid branches."""
        all_valid = True
        
        # Extract branch taxonomy tuples from manifest
        manifest_tuples = set()
        for branch_id, taxonomy in self.branches_from_manifest.items():
            tuple_str = self._taxonomy_to_tuple(taxonomy)
            manifest_tuples.add(tuple_str)
        
        # Check test vector taxonomies
        for vector_name, taxonomy in self.test_vectors_taxonomy.items():
            tuple_str = self._taxonomy_to_tuple(taxonomy)
            
            if tuple_str not in manifest_tuples:
                self.warnings.append(
                    f"Test vector '{vector_name}' taxonomy does not match any branch in manifest: {tuple_str}"
                )
                all_valid = False
        
        return all_valid
    
    def _taxonomy_to_tuple(self, taxonomy: Dict) -> str:
        """Convert taxonomy dict to string tuple for comparison."""
        return f"({taxonomy.get('barrier_type')}, {taxonomy.get('settlement')}, " \
               f"{taxonomy.get('coupon_memory')}, {taxonomy.get('step_feature')}, " \
               f"{taxonomy.get('recovery_mode')})"
    
    def validate(self, fcn_base_dir: Path) -> bool:
        """Run all taxonomy validations."""
        self.errors = []
        self.warnings = []
        
        manifest_path = fcn_base_dir / 'manifest.yaml'
        test_vectors_dir = fcn_base_dir / 'test-vectors'
        
        # Load manifest
        if not manifest_path.exists():
            self.errors.append(f"Manifest not found: {manifest_path}")
            return False
        
        if not self.load_manifest(manifest_path):
            return False
        
        # Validate manifest branches
        manifest_valid = self.validate_manifest_branches()
        
        # Validate test vectors
        vectors_valid = True
        if test_vectors_dir.exists():
            vectors_valid = self.validate_test_vectors(test_vectors_dir)
        else:
            self.warnings.append(f"Test vectors directory not found: {test_vectors_dir}")
        
        # Cross-reference validation
        consistency_valid = self.validate_branch_consistency()
        
        return manifest_valid and vectors_valid and consistency_valid
    
    def print_results(self):
        """Print validation results."""
        print(f"\n{'='*70}")
        print(f"Taxonomy Validation Results")
        print(f"{'='*70}")
        
        if not self.errors and not self.warnings:
            print("✅ All taxonomy validations passed")
        else:
            if self.errors:
                print(f"\n❌ {len(self.errors)} error(s) found:")
                for error in self.errors:
                    print(f"   - {error}")
            
            if self.warnings:
                print(f"\n⚠️  {len(self.warnings)} warning(s):")
                for warning in self.warnings:
                    print(f"   - {warning}")
        
        print(f"{'='*70}\n")


def main():
    if len(sys.argv) < 2:
        print("Usage: python taxonomy_validator.py <fcn_base_directory>")
        sys.exit(1)
    
    fcn_base_dir = Path(sys.argv[1])
    
    if not fcn_base_dir.is_dir():
        print(f"Error: {fcn_base_dir} is not a valid directory")
        sys.exit(1)
    
    validator = TaxonomyValidator()
    is_valid = validator.validate(fcn_base_dir)
    validator.print_results()
    
    sys.exit(0 if is_valid else 1)


if __name__ == '__main__':
    main()
