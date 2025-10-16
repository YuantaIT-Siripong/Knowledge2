#!/usr/bin/env python3
"""
FCN Parameter Validator (Phase 2)

Validates parameters against JSON schema and naming conventions.
Part of the FCN v1.0 governance framework.

Usage:
    python parameter_validator.py <schema_path> <test_vectors_dir>
"""

import sys
import json
import yaml
import re
from pathlib import Path
from typing import Dict, List


try:
    import jsonschema
    from jsonschema import validate, ValidationError
except ImportError:
    print("Error: jsonschema library required. Install with: pip install jsonschema")
    sys.exit(1)


class ParameterValidator:
    """Validates parameter conformance to JSON schema."""
    
    def __init__(self, schema_path: Path):
        self.schema = self._load_schema(schema_path)
        self.errors = []
        self.warnings = []
    
    def _load_schema(self, schema_path: Path) -> Dict:
        """Load JSON schema."""
        try:
            with open(schema_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading schema: {e}")
            sys.exit(1)
    
    def extract_parameters_from_vector(self, file_path: Path) -> Dict:
        """Extract parameters from test vector file."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Try YAML front matter first
            pattern = r'^---\s*\n(.*?)\n---\s*\n'
            match = re.match(pattern, content, re.DOTALL)
            
            if match:
                front_matter = yaml.safe_load(match.group(1))
                return front_matter.get('parameters', {})
            
            # Try finding parameters section in markdown
            params_pattern = r'##\s+Parameters\s*\n```(?:yaml|json)\s*\n(.*?)\n```'
            match = re.search(params_pattern, content, re.DOTALL | re.IGNORECASE)
            
            if match:
                return yaml.safe_load(match.group(1))
            
            return {}
        except Exception as e:
            self.warnings.append(f"Failed to extract parameters from {file_path.name}: {e}")
            return {}
    
    def validate_parameters(self, parameters: Dict, context: str) -> bool:
        """Validate parameters against schema."""
        try:
            validate(instance=parameters, schema=self.schema)
            return True
        except ValidationError as e:
            self.errors.append(f"{context}: Schema validation failed: {e.message}")
            if e.path:
                self.errors.append(f"  Path: {' -> '.join(str(p) for p in e.path)}")
            return False
    
    def validate_naming_conventions(self, parameters: Dict, context: str) -> bool:
        """Validate parameter naming conventions."""
        all_valid = True
        
        # Check for deprecated alias 'notional_amount'
        if 'notional_amount' in parameters:
            self.warnings.append(
                f"{context}: Parameter 'notional_amount' is a deprecated alias (Stage 1 - Introduce). "
                f"Use canonical parameter 'notional' instead. See alias-register.md for migration guidance."
            )
        
        # Check for potential annual rate supplied instead of per-period rate
        if 'coupon_rate_pct' in parameters:
            coupon_rate_pct = parameters['coupon_rate_pct']
            if isinstance(coupon_rate_pct, (int, float)) and coupon_rate_pct > 0.20:
                self.warnings.append(
                    f"{context}: coupon_rate_pct value ({coupon_rate_pct}) > 0.20 suggests potential annual rate. "
                    f"Ensure per-period conversion per coupon-rate-conversion.md. "
                    f"For monthly payments, divide annual rate by 12; for quarterly, divide by 4."
                )
        
        for param_name in parameters.keys():
            # Check snake_case
            if not re.match(r'^[a-z][a-z0-9_]*$', param_name):
                self.warnings.append(
                    f"{context}: Parameter '{param_name}' does not follow snake_case convention"
                )
                all_valid = False
            
            # Check percentage suffix
            if 'pct' in param_name.lower() and not param_name.endswith('_pct'):
                self.warnings.append(
                    f"{context}: Percentage parameter '{param_name}' should have '_pct' suffix"
                )
            
            # Check date suffix
            if 'date' in param_name.lower() and not param_name.endswith('_date') and param_name != 'observation_dates':
                self.warnings.append(
                    f"{context}: Date parameter '{param_name}' should have '_date' suffix"
                )
            
            # Check boolean prefix
            param_value = parameters[param_name]
            if isinstance(param_value, bool) and not param_name.startswith('is_'):
                self.warnings.append(
                    f"{context}: Boolean parameter '{param_name}' should have 'is_' prefix"
                )
        
        return all_valid
    
    def validate_test_vectors(self, test_vectors_dir: Path) -> Dict[str, bool]:
        """Validate all test vectors in directory."""
        results = {}
        
        for vector_file in test_vectors_dir.glob('*.md'):
            self.errors = []
            self.warnings = []
            
            parameters = self.extract_parameters_from_vector(vector_file)
            
            if not parameters:
                self.warnings.append(f"No parameters found in {vector_file.name}")
                results[vector_file.name] = {
                    'valid': False,
                    'errors': self.errors.copy(),
                    'warnings': self.warnings.copy()
                }
                continue
            
            context = f"Test vector '{vector_file.name}'"
            schema_valid = self.validate_parameters(parameters, context)
            naming_valid = self.validate_naming_conventions(parameters, context)
            
            results[vector_file.name] = {
                'valid': schema_valid and naming_valid,
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
        print(f"Parameter Validation Results")
        print(f"{'='*70}")
        print(f"Total test vectors: {total}")
        print(f"Passed: {passed}")
        print(f"Failed: {failed}")
        print(f"{'='*70}\n")
        
        for vector_name, result in results.items():
            if not result['valid'] or result['errors']:
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
    if len(sys.argv) < 3:
        print("Usage: python parameter_validator.py <schema_path> <test_vectors_dir>")
        sys.exit(1)
    
    schema_path = Path(sys.argv[1])
    test_vectors_dir = Path(sys.argv[2])
    
    if not schema_path.exists():
        print(f"Error: Schema file not found: {schema_path}")
        sys.exit(1)
    
    if not test_vectors_dir.is_dir():
        print(f"Error: Test vectors directory not found: {test_vectors_dir}")
        sys.exit(1)
    
    validator = ParameterValidator(schema_path)
    results = validator.validate_test_vectors(test_vectors_dir)
    validator.print_results(results)
    
    sys.exit(0 if all(r['valid'] for r in results.values()) else 1)


if __name__ == '__main__':
    main()
