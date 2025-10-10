# FCN v1.0 Validators

## Overview

This directory contains validation scripts for FCN v1.0 specification and test vectors. These validators implement the multi-phase governance and promotion gating workflow for FCN v1.0.

### Validator Scripts

1. **`ingest_vectors.py`** - Test Vector Ingestion
2. **`validate-fcn-metadata.py`** - Phase 0: Metadata Validation
3. **`validate_taxonomy.py`** - Phase 1: Taxonomy Validation
4. **`validate_parameters.py`** - Phase 2: Parameters Validation

---

## Test Vector Ingestion

The `ingest_vectors.py` script ingests and validates all FCN v1.0 test vector files.

### What It Checks

- Presence of all required front matter fields in test vectors
- Valid YAML front matter structure
- Required fields: title, doc_type, status, version, normative, branch_id, spec_version, owner, classification, tags, taxonomy

### Usage

```bash
python3 docs/scripts/ingest_vectors.py
```

### Output

Generates `test-vectors-ingestion.json` with:
- Overall status (pass/fail)
- Number of vectors ingested/failed
- Details for each test vector file

---

## Phase 0: Metadata Validator

The `validate-fcn-metadata.py` script validates the front matter (YAML metadata) of the FCN v1.0 specification file against the requirements specified in the Phase 0 activation checklist.

## Requirements

This validator checks:

1. **Required Fields**: Ensures all required metadata fields are present:
   - `title`
   - `doc_type`
   - `status`
   - `spec_version`
   - `version`
   - `owner`
   - `classification`
   - `tags` (must not be empty)
   - `activation_checklist_issue`
   - `normative_test_vector_set` (must not be empty)

2. **Version Consistency**: Verifies that `version` == `spec_version`

3. **Activation Issue Reachability**: Confirms that the `activation_checklist_issue` URL:
   - Matches the expected GitHub issue pattern
   - Returns HTTP 200 (is accessible)

## Usage

### Basic Usage

Run from the repository root:

```bash
python3 docs/scripts/validate-fcn-metadata.py
```

This will:
- Parse the front matter from `docs/business/ba/products/structured-notes/fcn/specs/fcn-v1.0.md`
- Validate all requirements
- Output results to console
- Write JSON results to `metadata-validation.json` in the repository root

### Exit Codes

- `0`: Validation passed (all checks successful)
- `1`: Validation failed (one or more checks failed)

## Output Format

The script generates a JSON file (`metadata-validation.json`) with the following structure:

```json
{
  "status": "pass|fail",
  "missing_fields": [],
  "inconsistencies": [],
  "activation_issue_reachable": true|false,
  "activation_issue_check_message": "...",
  "file_path": "...",
  "parse_error": ""
}
```

### Fields

- **status**: Overall validation status (`pass` or `fail`)
- **missing_fields**: Array of field names that are missing or empty
- **inconsistencies**: Array of inconsistency descriptions (e.g., version mismatches, unreachable URLs)
- **activation_issue_reachable**: Boolean indicating if the activation checklist issue URL is accessible
- **activation_issue_check_message**: Detailed message about the activation issue check
- **file_path**: Absolute path to the validated specification file
- **parse_error**: Error message if YAML parsing failed (empty string if successful)

## Examples

### Successful Validation

```
Validating FCN v1.0 metadata from: .../fcn-v1.0.md

============================================================
VALIDATION RESULTS
============================================================
Status: PASS

Activation Issue Reachable: True
Check Message: HTTP 200 - Issue is reachable

Validation results written to: .../metadata-validation.json
```

### Failed Validation (Missing Fields)

```
Validating FCN v1.0 metadata from: .../fcn-v1.0.md

============================================================
VALIDATION RESULTS
============================================================
Status: FAIL

Missing Fields (3):
  - version
  - owner
  - classification

Activation Issue Reachable: False
Check Message: No activation_checklist_issue URL provided

Validation results written to: .../metadata-validation.json
```

### Failed Validation (Version Mismatch)

```
Validating FCN v1.0 metadata from: .../fcn-v1.0.md

============================================================
VALIDATION RESULTS
============================================================
Status: FAIL

Inconsistencies (1):
  - version (2.0.0) does not match spec_version (1.0.0)

Activation Issue Reachable: True
Check Message: HTTP 200 - Issue is reachable

Validation results written to: .../metadata-validation.json
```

## Dependencies

- Python 3.7+
- PyYAML
- requests

All dependencies are included in standard Python distributions or are commonly available.

## Integration

This validator can be integrated into:

- CI/CD pipelines (use exit code to fail builds on validation errors)
- Pre-commit hooks
- Manual validation workflows
- Automated documentation quality checks

## Related Documents

- FCN v1.0 Specification: `docs/business/ba/products/structured-notes/fcn/specs/fcn-v1.0.md`
- Activation Checklist Issue: https://github.com/YuantaIT-Siripong/Knowledge2/issues/3
- ADR-003: FCN Version Activation & Promotion Workflow

---

## Phase 1: Taxonomy Validator

The `validate_taxonomy.py` script validates that test vector taxonomy entries conform to the canonical taxonomy defined in `common/payoff_types.md`.

### What It Checks

- All taxonomy dimensions are present: `barrier_type`, `settlement`, `coupon_memory`, `step_feature`, `recovery_mode`
- Values conform to canonical taxonomy codes
- No unknown/deprecated taxonomy dimensions

### Canonical Taxonomy

| Dimension | Valid Values |
|-----------|-------------|
| barrier_type | `down-in`, `down-and-in`, `down-and-out`, `up-and-in` |
| settlement | `physical-settlement`, `cash-settlement` |
| coupon_memory | `memory`, `no-memory` |
| step_feature | `step-down`, `no-step` |
| recovery_mode | `par-recovery`, `proportional-loss` |

### Usage

```bash
python3 docs/scripts/validate_taxonomy.py
```

### Output

Generates `taxonomy-validation.json` with:
- Overall status (pass/fail)
- Number of vectors validated/failed
- Specific taxonomy errors for each failing vector

---

## Phase 2: Parameters Validator

The `validate_parameters.py` script validates that test vector parameters are complete and consistent.

### What It Checks

- Presence of required parameters (trade_date, issue_date, maturity_date, etc.)
- Parameter value ranges (percentages between 0 and 1)
- Logical relationships (knock_in_barrier < coupon_threshold)
- Valid enumeration values (settlement_type, recovery_mode)
- Positive notional amounts

### Usage

```bash
python3 docs/scripts/validate_parameters.py
```

### Output

Generates `parameters-validation.json` with:
- Overall status (pass/fail)
- Number of vectors validated/failed
- Specific parameter errors for each failing vector

---

## GitHub Actions Integration

All validators are integrated into the CI/CD pipeline via `.github/workflows/fcn-validators.yml`.

### Workflow Triggers

The workflow runs automatically on:
- Push to `fcn/specs/**`, `common/**`, `test-vectors/**`, or `docs/scripts/**`
- Pull requests touching the same paths

### Workflow Steps

1. Set up Python 3.12 environment
2. Install dependencies (jsonschema, pyyaml, requests)
3. Run test vector ingestion
4. Run Phase 0 metadata validation
5. Run Phase 1 taxonomy validation
6. Run Phase 2 parameters validation
7. Upload validation reports as artifacts
8. Fail build if any phase returns non-pass status

### Artifacts

Validation reports are uploaded as GitHub Actions artifacts with:
- Name: `fcn-validation-reports`
- Retention: 30 days
- Contents: All JSON validation reports

---

## Running All Validators

To run all validators locally:

```bash
# From repository root
python3 docs/scripts/ingest_vectors.py
python3 docs/scripts/validate-fcn-metadata.py
python3 docs/scripts/validate_taxonomy.py
python3 docs/scripts/validate_parameters.py
```

Check exit codes to determine pass/fail status (0 = pass, 1 = fail).

## Dependencies

- Python 3.7+
- PyYAML
- requests
- jsonschema

Install dependencies:

```bash
pip install pyyaml requests jsonschema
```

## Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 2.0.0 | 2025-10-10 | System | Add Phase 1-2 validators and test vector ingestion |
| 1.0.0 | 2025-10-10 | System | Initial implementation of Phase 0 metadata validator |
