#!/usr/bin/env python3
"""
FCN Validator Aggregator

Runs all validators and generates consolidated report.
Part of the FCN v1.0 governance framework.

Usage:
    python aggregator.py <fcn_base_directory> [--output <report_file>]
"""

import sys
import subprocess
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple


class ValidatorAggregator:
    """Aggregates results from all validator phases."""
    
    def __init__(self, fcn_base_dir: Path):
        self.fcn_base_dir = fcn_base_dir
        self.validators_dir = fcn_base_dir / 'validators'
        self.results = {}
        self.start_time = datetime.now()
    
    def run_validator(self, script_name: str, args: List[str]) -> Tuple[int, str]:
        """Run a single validator script."""
        script_path = self.validators_dir / script_name
        
        if not script_path.exists():
            return -1, f"Validator script not found: {script_path}"
        
        try:
            cmd = [sys.executable, str(script_path)] + args
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=60
            )
            
            return result.returncode, result.stdout + result.stderr
        except subprocess.TimeoutExpired:
            return -1, "Validator timed out (60s limit)"
        except Exception as e:
            return -1, f"Failed to run validator: {e}"
    
    def run_phase_0(self) -> Dict:
        """Run Phase 0: Metadata & Document Structure."""
        print("\n" + "="*70)
        print("Phase 0: Metadata & Document Structure")
        print("="*70)
        
        specs_dir = self.fcn_base_dir / 'specs'
        returncode, output = self.run_validator('metadata_validator.py', [str(specs_dir)])
        
        print(output)
        
        return {
            'phase': 0,
            'name': 'Metadata & Document Structure',
            'passed': returncode == 0,
            'output': output
        }
    
    def run_phase_1(self) -> Dict:
        """Run Phase 1: Taxonomy & Branch Conformance."""
        print("\n" + "="*70)
        print("Phase 1: Taxonomy & Branch Conformance")
        print("="*70)
        
        returncode, output = self.run_validator('taxonomy_validator.py', [str(self.fcn_base_dir)])
        
        print(output)
        
        return {
            'phase': 1,
            'name': 'Taxonomy & Branch Conformance',
            'passed': returncode == 0,
            'output': output
        }
    
    def run_phase_2(self) -> Dict:
        """Run Phase 2: Parameter Schema Conformance."""
        print("\n" + "="*70)
        print("Phase 2: Parameter Schema Conformance")
        print("="*70)
        
        schema_path = self.fcn_base_dir / 'schemas' / 'fcn-v1.0-parameters.schema.json'
        test_vectors_dir = self.fcn_base_dir / 'test-vectors'
        
        returncode, output = self.run_validator(
            'parameter_validator.py',
            [str(schema_path), str(test_vectors_dir)]
        )
        
        print(output)
        
        return {
            'phase': 2,
            'name': 'Parameter Schema Conformance',
            'passed': returncode == 0,
            'output': output
        }
    
    def run_phase_3(self) -> Dict:
        """Run Phase 3: Test Vector Coverage."""
        print("\n" + "="*70)
        print("Phase 3: Test Vector Coverage")
        print("="*70)
        
        returncode, output = self.run_validator('coverage_validator.py', [str(self.fcn_base_dir)])
        
        print(output)
        
        return {
            'phase': 3,
            'name': 'Test Vector Coverage',
            'passed': returncode == 0,
            'output': output
        }
    
    def run_phase_4(self) -> Dict:
        """Run Phase 4: Payoff & Lifecycle Logic."""
        print("\n" + "="*70)
        print("Phase 4: Payoff & Lifecycle Logic")
        print("="*70)
        
        test_vectors_dir = self.fcn_base_dir / 'test-vectors'
        
        returncode, output = self.run_validator(
            'memory_logic_validator.py',
            [str(test_vectors_dir)]
        )
        
        print(output)
        
        return {
            'phase': 4,
            'name': 'Payoff & Lifecycle Logic',
            'passed': returncode == 0,
            'output': output
        }
    
    def run_all(self) -> List[Dict]:
        """Run all validator phases."""
        phases = [
            self.run_phase_0(),
            self.run_phase_1(),
            self.run_phase_2(),
            self.run_phase_3(),
            self.run_phase_4()
        ]
        
        self.results = {p['phase']: p for p in phases}
        return phases
    
    def generate_summary(self) -> str:
        """Generate summary report."""
        elapsed = (datetime.now() - self.start_time).total_seconds()
        
        lines = ["\n" + "="*70]
        lines.append("FCN v1.0 Validator Aggregation Report")
        lines.append("="*70)
        lines.append(f"Execution time: {elapsed:.2f}s")
        lines.append(f"Timestamp: {datetime.now().isoformat()}")
        lines.append("")
        
        total_phases = len(self.results)
        passed_phases = sum(1 for r in self.results.values() if r['passed'])
        
        lines.append(f"Overall Status: {passed_phases}/{total_phases} phases passed")
        lines.append("")
        
        for phase_num in sorted(self.results.keys()):
            result = self.results[phase_num]
            status = "✅ PASS" if result['passed'] else "❌ FAIL"
            lines.append(f"Phase {phase_num}: {result['name']} - {status}")
        
        lines.append("="*70)
        
        # Promotion readiness
        lines.append("\nPromotion Readiness Assessment:")
        lines.append("-" * 70)
        
        p0_ready = all(self.results.get(i, {}).get('passed', False) for i in [0, 1, 2])
        lines.append(f"Ready for Proposed → Active: {'✅ YES' if p0_ready else '❌ NO (Phase 0-2 required)'}")
        
        p1_ready = p0_ready and self.results.get(3, {}).get('passed', False)
        lines.append(f"Ready for Production: {'✅ YES' if p1_ready else '⚠️  NO (Phase 3 required)'}")
        
        lines.append("="*70 + "\n")
        
        return "\n".join(lines)
    
    def save_report(self, output_file: Path):
        """Save report to file."""
        try:
            summary = self.generate_summary()
            
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(summary)
                f.write("\n\nDetailed Results:\n")
                f.write("="*70 + "\n\n")
                
                for phase_num in sorted(self.results.keys()):
                    result = self.results[phase_num]
                    f.write(f"\n{'='*70}\n")
                    f.write(f"Phase {phase_num}: {result['name']}\n")
                    f.write(f"{'='*70}\n")
                    f.write(result['output'])
                    f.write("\n")
            
            print(f"\n📊 Report saved to: {output_file}")
        except Exception as e:
            print(f"❌ Failed to save report: {e}")


def main():
    if len(sys.argv) < 2:
        print("Usage: python aggregator.py <fcn_base_directory> [--output <report_file>]")
        sys.exit(1)
    
    fcn_base_dir = Path(sys.argv[1])
    
    if not fcn_base_dir.is_dir():
        print(f"Error: {fcn_base_dir} is not a valid directory")
        sys.exit(1)
    
    # Parse output option
    output_file = None
    if len(sys.argv) > 2 and sys.argv[2] == '--output' and len(sys.argv) > 3:
        output_file = Path(sys.argv[3])
    else:
        output_file = fcn_base_dir / 'validation-report.txt'
    
    aggregator = ValidatorAggregator(fcn_base_dir)
    
    print(f"\n🔍 Running FCN v1.0 Validators...")
    print(f"Base directory: {fcn_base_dir}")
    
    aggregator.run_all()
    
    summary = aggregator.generate_summary()
    print(summary)
    
    aggregator.save_report(output_file)
    
    # Exit with error if any critical phases failed
    p0_passed = all(aggregator.results.get(i, {}).get('passed', False) for i in [0, 1, 2])
    sys.exit(0 if p0_passed else 1)


if __name__ == '__main__':
    main()
