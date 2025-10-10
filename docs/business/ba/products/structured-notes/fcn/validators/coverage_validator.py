#!/usr/bin/env python3
"""
FCN Coverage Validator (Phase 3)

Validates test vector coverage against required scenarios per branch.
Part of the FCN v1.0 governance framework.

Usage:
    python coverage_validator.py <fcn_base_directory>
"""

import sys
import yaml
import re
from pathlib import Path
from typing import Dict, List, Set


class CoverageValidator:
    """Validates test vector coverage against normative requirements."""
    
    REQUIRED_TAGS_PER_BRANCH = ['baseline', 'edge']
    NORMATIVE_MIN_COUNT = 1
    
    def __init__(self):
        self.errors = []
        self.warnings = []
        self.branches = {}
        self.test_vectors = {}
    
    def load_manifest(self, manifest_path: Path) -> bool:
        """Load branches from manifest."""
        try:
            with open(manifest_path, 'r', encoding='utf-8') as f:
                manifest = yaml.safe_load(f)
            
            branches = manifest.get('branches', [])
            for branch in branches:
                branch_id = branch.get('branch_id')
                normative_vectors = branch.get('normative_vectors', [])
                self.branches[branch_id] = {
                    'description': branch.get('description'),
                    'normative_vectors': normative_vectors,
                    'found_vectors': []
                }
            
            return True
        except Exception as e:
            self.errors.append(f"Failed to load manifest: {e}")
            return False
    
    def extract_vector_metadata(self, file_path: Path) -> Dict:
        """Extract metadata from test vector file."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Extract YAML front matter
            pattern = r'^---\s*\n(.*?)\n---\s*\n'
            match = re.match(pattern, content, re.DOTALL)
            
            if not match:
                return None
            
            data = yaml.safe_load(match.group(1))
            return {
                'vector_id': data.get('vector_id', file_path.stem),
                'normative': data.get('normative', False),
                'tags': data.get('tags', []),
                'taxonomy': data.get('taxonomy', {})
            }
        except Exception as e:
            self.warnings.append(f"Failed to parse {file_path.name}: {e}")
            return None
    
    def map_vector_to_branch(self, taxonomy: Dict) -> str:
        """Map taxonomy to branch ID."""
        # Simple heuristic mapping based on taxonomy
        barrier_type = taxonomy.get('barrier_type', '')
        settlement = taxonomy.get('settlement', '')
        coupon_memory = taxonomy.get('coupon_memory', '')
        recovery_mode = taxonomy.get('recovery_mode', '')
        
        if coupon_memory == 'memory' and recovery_mode == 'par-recovery':
            return 'fcn-base-mem'
        elif coupon_memory == 'no-memory' and recovery_mode == 'par-recovery':
            return 'fcn-base-nomem'
        elif coupon_memory == 'memory' and recovery_mode == 'proportional-loss':
            return 'fcn-base-mem-proploss'
        
        return 'unknown'
    
    def scan_test_vectors(self, test_vectors_dir: Path) -> bool:
        """Scan test vectors and map to branches."""
        if not test_vectors_dir.exists():
            self.warnings.append(f"Test vectors directory not found: {test_vectors_dir}")
            return False
        
        for vector_file in test_vectors_dir.glob('*.md'):
            metadata = self.extract_vector_metadata(vector_file)
            
            if metadata is None:
                continue
            
            vector_id = metadata['vector_id']
            branch_id = self.map_vector_to_branch(metadata['taxonomy'])
            
            self.test_vectors[vector_id] = {
                'file': vector_file.name,
                'branch': branch_id,
                'normative': metadata['normative'],
                'tags': metadata['tags']
            }
            
            # Add to branch tracking
            if branch_id in self.branches:
                self.branches[branch_id]['found_vectors'].append(vector_id)
        
        return True
    
    def validate_coverage(self) -> bool:
        """Validate coverage requirements."""
        all_valid = True
        
        for branch_id, branch_data in self.branches.items():
            context = f"Branch '{branch_id}'"
            expected_normative = branch_data['normative_vectors']
            found_vectors = branch_data['found_vectors']
            
            # Check minimum normative count
            normative_count = sum(
                1 for v_id in found_vectors
                if v_id in self.test_vectors and self.test_vectors[v_id]['normative']
            )
            
            if normative_count < self.NORMATIVE_MIN_COUNT:
                self.errors.append(
                    f"{context}: Insufficient normative vectors. Expected at least {self.NORMATIVE_MIN_COUNT}, found {normative_count}"
                )
                all_valid = False
            
            # Check for expected normative vectors from manifest
            for expected_vector in expected_normative:
                if expected_vector not in found_vectors:
                    self.warnings.append(
                        f"{context}: Expected normative vector '{expected_vector}' not found in test-vectors/"
                    )
            
            # Check tag coverage
            found_tags = set()
            for v_id in found_vectors:
                if v_id in self.test_vectors:
                    found_tags.update(self.test_vectors[v_id]['tags'])
            
            missing_tags = set(self.REQUIRED_TAGS_PER_BRANCH) - found_tags
            if missing_tags:
                self.warnings.append(
                    f"{context}: Missing required tags: {', '.join(missing_tags)}"
                )
        
        return all_valid
    
    def generate_coverage_matrix(self) -> str:
        """Generate coverage matrix report."""
        lines = ["\n" + "="*70]
        lines.append("Test Vector Coverage Matrix")
        lines.append("="*70)
        
        for branch_id, branch_data in self.branches.items():
            lines.append(f"\nBranch: {branch_id}")
            lines.append(f"Description: {branch_data['description']}")
            lines.append(f"Expected normative vectors: {', '.join(branch_data['normative_vectors']) or 'None'}")
            
            found_vectors = branch_data['found_vectors']
            if not found_vectors:
                lines.append("❌ No test vectors found")
            else:
                lines.append(f"Found {len(found_vectors)} test vector(s):")
                for v_id in found_vectors:
                    if v_id in self.test_vectors:
                        vector = self.test_vectors[v_id]
                        normative_flag = "✅ NORMATIVE" if vector['normative'] else "   "
                        tags = ', '.join(vector['tags']) or 'no tags'
                        lines.append(f"  {normative_flag} {v_id} [{tags}]")
        
        lines.append("="*70 + "\n")
        return "\n".join(lines)
    
    def validate(self, fcn_base_dir: Path) -> bool:
        """Run coverage validation."""
        self.errors = []
        self.warnings = []
        
        manifest_path = fcn_base_dir / 'manifest.yaml'
        test_vectors_dir = fcn_base_dir / 'test-vectors'
        
        if not manifest_path.exists():
            self.errors.append(f"Manifest not found: {manifest_path}")
            return False
        
        if not self.load_manifest(manifest_path):
            return False
        
        self.scan_test_vectors(test_vectors_dir)
        is_valid = self.validate_coverage()
        
        return is_valid
    
    def print_results(self):
        """Print validation results."""
        print(self.generate_coverage_matrix())
        
        if self.errors:
            print(f"\n❌ {len(self.errors)} error(s) found:")
            for error in self.errors:
                print(f"   - {error}")
        
        if self.warnings:
            print(f"\n⚠️  {len(self.warnings)} warning(s):")
            for warning in self.warnings:
                print(f"   - {warning}")
        
        if not self.errors and not self.warnings:
            print("\n✅ All coverage requirements met")


def main():
    if len(sys.argv) < 2:
        print("Usage: python coverage_validator.py <fcn_base_directory>")
        sys.exit(1)
    
    fcn_base_dir = Path(sys.argv[1])
    
    if not fcn_base_dir.is_dir():
        print(f"Error: {fcn_base_dir} is not a valid directory")
        sys.exit(1)
    
    validator = CoverageValidator()
    is_valid = validator.validate(fcn_base_dir)
    validator.print_results()
    
    sys.exit(0 if is_valid else 1)


if __name__ == '__main__':
    main()
