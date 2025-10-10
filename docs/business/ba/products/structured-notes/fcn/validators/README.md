# FCN v1.0 Validators

This directory contains automated validators for FCN v1.0 governance framework, implementing the validation phases defined in `validator-roadmap.md`.

## Overview

The validators ensure compliance with:
- Metadata and document structure (Phase 0)
- Taxonomy tuple conformance (Phase 1)
- Parameter schema conformance (Phase 2)
- Test vector coverage (Phase 3)
- Payoff and lifecycle logic (Phase 4)

## Prerequisites

```bash
# Python 3.7+
python3 --version

# Install required packages
pip install pyyaml jsonschema
```

## Quick Start

### Run All Validators

```bash
# From the fcn/ directory
python validators/aggregator.py . --output validation-report.txt

# This will run all phases and generate a consolidated report
```

### Run Individual Validators

#### Phase 0: Metadata Validation

```bash
# Validate a single spec file
python validators/metadata_validator.py specs/fcn-v1.0.md

# Validate all specs in directory
python validators/metadata_validator.py specs/
```

#### Phase 1: Taxonomy Validation

```bash
# Validate taxonomy across manifest, specs, and test vectors
python validators/taxonomy_validator.py .
```

#### Phase 2: Parameter Validation

```bash
# Validate test vector parameters against schema
python validators/parameter_validator.py schemas/fcn-v1.0-parameters.schema.json test-vectors/
```

#### Phase 3: Coverage Validation

```bash
# Validate test vector coverage
python validators/coverage_validator.py .
```

#### Phase 4: Memory Logic Validation

```bash
# Validate memory coupon logic in test vectors
python validators/memory_logic_validator.py test-vectors/
```

### Utility Scripts

#### Ingest Test Vectors

```bash
# Extract test vectors to JSON (dry-run)
python validators/ingest_vectors.py test-vectors/

# Ingest to database (when available)
python validators/ingest_vectors.py test-vectors/ "postgresql://user:pass@host:5432/dbname"
```

## Validator Details

### metadata_validator.py (Phase 0)

**Purpose:** Validates YAML front matter completeness and document structure.

**Checks:**
- Required fields present (doc_type, status, version, owner, etc.)
- Valid status values (Draft, Proposed, Active, etc.)
- Valid classification (Public, Internal, Confidential, Restricted)
- Semantic versioning format (MAJOR.MINOR.PATCH)
- Product code validation for test vectors

**Exit Codes:**
- `0`: All validations passed
- `1`: One or more validations failed

**Example Output:**
```
======================================================================
Metadata Validation Results
======================================================================
Total files: 2
Passed: 2
Failed: 0
======================================================================

✅ 2 files passed without warnings
```

---

### taxonomy_validator.py (Phase 1)

**Purpose:** Validates taxonomy tuple completeness and consistency.

**Checks:**
- All 5 dimensions present (barrier_type, settlement, coupon_memory, step_feature, recovery_mode)
- Valid taxonomy codes per `payoff_types.md`
- Consistency across manifest.yaml, specs, and test vectors
- No undefined taxonomy codes

**Exit Codes:**
- `0`: All validations passed
- `1`: Taxonomy errors detected

**Example Output:**
```
======================================================================
Taxonomy Validation Results
======================================================================
✅ All taxonomy validations passed
======================================================================
```

---

### parameter_validator.py (Phase 2)

**Purpose:** Validates parameters against JSON Schema.

**Requirements:**
- `jsonschema` library: `pip install jsonschema`

**Checks:**
- JSON Schema validation
- Required fields
- Data type conformance
- Constraint validation (min/max, enum, pattern)
- Naming conventions (snake_case, _pct suffix, is_ prefix)

**Exit Codes:**
- `0`: All validations passed
- `1`: Schema violations detected

**Example Output:**
```
======================================================================
Parameter Validation Results
======================================================================
Total test vectors: 5
Passed: 3
Failed: 2
======================================================================

❌ test-vector-invalid.md
   ERROR: Schema validation failed: 'notional' is a required property
```

---

### coverage_validator.py (Phase 3)

**Purpose:** Validates test vector coverage requirements.

**Checks:**
- Minimum normative vector count per branch (≥1)
- Required tags present (baseline, edge)
- Normative vectors match manifest expectations
- Coverage gaps per branch

**Exit Codes:**
- `0`: Coverage requirements met
- `1`: Insufficient coverage

**Example Output:**
```
======================================================================
Test Vector Coverage Matrix
======================================================================

Branch: fcn-base-mem
Description: Memory coupon, par-recovery, physical settlement
Expected normative vectors: fcn-v1.0-base-mem-baseline, ...
Found 4 test vector(s):
  ✅ NORMATIVE fcn-v1.0-base-mem-baseline [baseline, memory]
  ✅ NORMATIVE fcn-v1.0-base-mem-edge-barrier-touch [edge, memory]
  ...
======================================================================
```

---

### memory_logic_validator.py (Phase 4)

**Purpose:** Validates memory coupon accumulation logic.

**Checks:**
- Missed coupon accumulation
- Payout of accumulated coupons
- `missed_coupons_accumulated` field accuracy
- Barrier breach logic
- Tolerance-based floating-point comparison (±0.0001)

**Exit Codes:**
- `0`: All memory logic correct
- `1`: Logic errors detected

**Example Output:**
```
======================================================================
Memory Logic Validation Results
======================================================================
Total memory vectors: 4
Passed: 4
Failed: 0
======================================================================
```

---

### aggregator.py

**Purpose:** Runs all validators and generates consolidated report.

**Usage:**
```bash
python validators/aggregator.py . [--output report_file.txt]
```

**Features:**
- Runs all phases sequentially
- Captures outputs and exit codes
- Generates summary report
- Promotion readiness assessment
- Detailed error aggregation

**Exit Codes:**
- `0`: Phase 0-2 (critical) passed
- `1`: Phase 0-2 failed

**Example Output:**
```
======================================================================
FCN v1.0 Validator Aggregation Report
======================================================================
Execution time: 12.34s
Timestamp: 2025-10-10T02:30:00.000000

Overall Status: 4/5 phases passed

Phase 0: Metadata & Document Structure - ✅ PASS
Phase 1: Taxonomy & Branch Conformance - ✅ PASS
Phase 2: Parameter Schema Conformance - ✅ PASS
Phase 3: Test Vector Coverage - ⚠️  WARN
Phase 4: Payoff & Lifecycle Logic - ✅ PASS
======================================================================

Promotion Readiness Assessment:
----------------------------------------------------------------------
Ready for Proposed → Active: ✅ YES
Ready for Production: ⚠️  NO (Phase 3 required)
======================================================================
```

---

### ingest_vectors.py

**Purpose:** Ingests test vectors into database.

**Usage:**
```bash
# Extract only (dry-run)
python validators/ingest_vectors.py test-vectors/

# Ingest to database
python validators/ingest_vectors.py test-vectors/ "postgresql://..."
```

**Features:**
- Parses markdown test vectors
- Extracts YAML metadata and JSON blocks
- Exports to JSON file
- Database ingestion (when connection provided)

**Output:**
- `test-vectors-export.json`: Extracted vectors in JSON format
- Database records in `test_vector` table

---

## CI Integration

### GitHub Actions Workflow

Create `.github/workflows/fcn-validators.yml`:

```yaml
name: FCN Validators

on:
  pull_request:
    paths:
      - 'docs/business/ba/products/structured-notes/fcn/**'
  push:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'
      
      - name: Install dependencies
        run: |
          pip install pyyaml jsonschema
      
      - name: Run Phase 0-2 Validators
        run: |
          cd docs/business/ba/products/structured-notes/fcn
          python validators/metadata_validator.py specs/
          python validators/taxonomy_validator.py .
          python validators/parameter_validator.py schemas/fcn-v1.0-parameters.schema.json test-vectors/
      
      - name: Run Aggregator
        run: |
          cd docs/business/ba/products/structured-notes/fcn
          python validators/aggregator.py . --output validation-report.txt
      
      - name: Upload Report
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: validation-report
          path: docs/business/ba/products/structured-notes/fcn/validation-report.txt
```

### Pre-commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Run Phase 0-2 validators before commit

cd docs/business/ba/products/structured-notes/fcn

echo "Running FCN validators..."

python validators/metadata_validator.py specs/ || exit 1
python validators/taxonomy_validator.py . || exit 1

echo "✅ Validators passed"
```

## Troubleshooting

### Import Errors

```bash
# Install missing dependencies
pip install pyyaml jsonschema
```

### Permission Denied

```bash
# Make scripts executable
chmod +x validators/*.py
```

### Script Not Found

```bash
# Run from fcn/ directory, not validators/
cd docs/business/ba/products/structured-notes/fcn
python validators/metadata_validator.py specs/
```

### Timeout Issues

```bash
# Increase timeout in aggregator.py (default: 60s)
# Edit aggregator.py and change timeout parameter in subprocess.run()
```

## Development

### Adding New Validators

1. Create validator script in `validators/` directory
2. Follow naming convention: `{purpose}_validator.py`
3. Implement `main()` function with proper argument parsing
4. Exit with code 0 on success, 1 on failure
5. Print clear error messages with context
6. Update `aggregator.py` to include new validator
7. Update `validator-roadmap.md` with validator details
8. Add entry to `validator-issues-draft.md`
9. Update this README

### Testing Validators

```bash
# Test with valid inputs
python validators/metadata_validator.py specs/fcn-v1.0.md
echo $?  # Should be 0

# Test with invalid inputs (create test file with missing fields)
python validators/metadata_validator.py test-invalid.md
echo $?  # Should be 1
```

## Related Documentation

- `../validator-roadmap.md`: Phased implementation roadmap
- `../validator-issues-draft.md`: GitHub issue templates
- `../manifest.yaml`: Product configuration
- `../../common/governance.md`: Governance framework
- `../../../sa/design-decisions/adr-003-fcn-version-activation.md`: Activation requirements

## Support

For issues or questions:
1. Check validator-roadmap.md for phase details
2. Review validator-issues-draft.md for known issues
3. Check exit codes and error messages
4. Consult FCN specification (specs/fcn-v1.0.md)

## Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-10 | siripong.s@yuanta.co.th | Initial validator suite for FCN v1.0 |
