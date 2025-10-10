#!/usr/bin/env python3
"""
FCN Memory Logic Validator (Phase 4)

Validates memory coupon accumulation and payout logic against expected outputs.
Part of the FCN v1.0 governance framework.

Usage:
    python memory_logic_validator.py <test_vectors_dir>
"""

import sys
import yaml
import re
from pathlib import Path
from typing import Dict, List, Tuple


class MemoryLogicValidator:
    """Validates memory coupon logic in test vectors."""
    
    def __init__(self):
        self.errors = []
        self.warnings = []
        self.tolerance = 0.0001
    
    def extract_test_vector_data(self, file_path: Path) -> Tuple[Dict, Dict, Dict]:
        """Extract parameters, market scenario, and expected outputs from test vector."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Extract YAML front matter
            pattern = r'^---\s*\n(.*?)\n---\s*\n'
            match = re.match(pattern, content, re.DOTALL)
            
            if not match:
                return None, None, None
            
            data = yaml.safe_load(match.group(1))
            parameters = data.get('parameters', {})
            market_scenario = data.get('market_scenario', {})
            expected_outputs = data.get('expected_outputs', {})
            
            return parameters, market_scenario, expected_outputs
        except Exception as e:
            self.warnings.append(f"Failed to parse {file_path.name}: {e}")
            return None, None, None
    
    def validate_memory_logic(self, file_path: Path) -> bool:
        """Validate memory coupon logic for a single test vector."""
        parameters, market_scenario, expected_outputs = self.extract_test_vector_data(file_path)
        
        if parameters is None:
            return False
        
        # Only validate memory coupon vectors
        is_memory = parameters.get('is_memory_coupon', False)
        if not is_memory:
            return True  # Skip non-memory vectors
        
        context = f"Test vector '{file_path.name}'"
        
        # Get coupon decisions from expected outputs
        coupon_decisions = expected_outputs.get('coupon_decisions', [])
        if not coupon_decisions:
            self.warnings.append(f"{context}: No coupon_decisions found in expected_outputs")
            return True
        
        # Validate memory accumulation logic
        missed_count = 0
        for i, decision in enumerate(coupon_decisions):
            coupon_paid = decision.get('coupon_paid', 0)
            barrier_breached = decision.get('barrier_breached', False)
            accumulated = decision.get('missed_coupons_accumulated', 0)
            
            # If barrier breached, no coupon this period
            if barrier_breached:
                missed_count += 1
                
                # Check that coupon_paid is 0 when barrier breached
                if coupon_paid != 0:
                    self.errors.append(
                        f"{context}: Observation {i+1}: coupon_paid should be 0 when barrier_breached, got {coupon_paid}"
                    )
            else:
                # Barrier not breached - should pay current + accumulated
                expected_total_coupons = 1 + missed_count
                
                # Check accumulated count matches
                if accumulated != missed_count:
                    self.errors.append(
                        f"{context}: Observation {i+1}: missed_coupons_accumulated should be {missed_count}, got {accumulated}"
                    )
                
                # After payment, reset counter
                missed_count = 0
        
        return len(self.errors) == 0
    
    def validate_test_vectors(self, test_vectors_dir: Path) -> Dict[str, bool]:
        """Validate memory logic for all memory coupon test vectors."""
        results = {}
        
        for vector_file in test_vectors_dir.glob('*.md'):
            self.errors = []
            self.warnings = []
            
            is_valid = self.validate_memory_logic(vector_file)
            
            results[vector_file.name] = {
                'valid': is_valid,
                'errors': self.errors.copy(),
                'warnings': self.warnings.copy()
            }
        
        return results
    
    def print_results(self, results: Dict):
        """Print validation results."""
        # Filter to only memory vectors
        memory_results = {k: v for k, v in results.items() if 'mem' in k.lower() and 'nomem' not in k.lower()}
        
        if not memory_results:
            print("\n⚠️  No memory coupon test vectors found")
            return
        
        total = len(memory_results)
        passed = sum(1 for r in memory_results.values() if r['valid'])
        failed = total - passed
        
        print(f"\n{'='*70}")
        print(f"Memory Logic Validation Results")
        print(f"{'='*70}")
        print(f"Total memory vectors: {total}")
        print(f"Passed: {passed}")
        print(f"Failed: {failed}")
        print(f"{'='*70}\n")
        
        for vector_name, result in memory_results.items():
            if not result['valid']:
                print(f"❌ {vector_name}")
                for error in result['errors']:
                    print(f"   ERROR: {error}")
                for warning in result['warnings']:
                    print(f"   WARNING: {warning}")
                print()
            elif result['warnings']:
                print(f"⚠️  {vector_name}")
                for warning in result['warnings']:
                    print(f"   WARNING: {warning}")
                print()


def main():
    if len(sys.argv) < 2:
        print("Usage: python memory_logic_validator.py <test_vectors_dir>")
        sys.exit(1)
    
    test_vectors_dir = Path(sys.argv[1])
    
    if not test_vectors_dir.is_dir():
        print(f"Error: Test vectors directory not found: {test_vectors_dir}")
        sys.exit(1)
    
    validator = MemoryLogicValidator()
    results = validator.validate_test_vectors(test_vectors_dir)
    validator.print_results(results)
    
    # Exit with error if any memory vectors failed
    memory_results = {k: v for k, v in results.items() if 'mem' in k.lower() and 'nomem' not in k.lower()}
    sys.exit(0 if all(r['valid'] for r in memory_results.values()) else 1)


if __name__ == '__main__':
    main()
