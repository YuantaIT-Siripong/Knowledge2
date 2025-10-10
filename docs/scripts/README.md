# FCN v1.0 Validators

This directory contains validation scripts for the FCN v1.0 specification and related artifacts.

## Overview

### Phase 0: Metadata Validator (`validate-fcn-metadata.py`)

The `validate-fcn-metadata.py` script validates the front matter (YAML metadata) of the FCN v1.0 specification file against the requirements specified in the Phase 0 activation checklist.

### Phase 1: Taxonomy & Branch Consistency Validator (`validate-fcn-taxonomy.py`)

The `validate-fcn-taxonomy.py` script validates branch taxonomy consistency across the specification, manifest, and test vectors.

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

# Phase 1: Taxonomy & Branch Consistency Validator

## Overview

The `validate-fcn-taxonomy.py` script validates branch taxonomy consistency across:
- FCN specification (Section 6: Taxonomy & Branch Inventory)
- Common taxonomy definitions (`payoff_types.md`)
- Test vector files

## Requirements

This validator checks:

1. **Complete Dimension Keys**: Each branch in the manifest has all required taxonomy dimension keys
2. **No Duplicate Tuples**: No two branches have identical taxonomy dimension values
3. **Branch ID Consistency**: All test vector `branch_id` values are defined in the spec manifest
4. **Normative Flags**: All normative test vectors have `normative: true` in their front matter

## Usage

### Basic Usage

Run from the repository root:

```bash
python3 docs/scripts/validate-fcn-taxonomy.py
```

This will:
- Parse taxonomy dimensions from `docs/business/ba/products/structured-notes/common/payoff_types.md`
- Parse branch inventory from `docs/business/ba/products/structured-notes/fcn/specs/fcn-v1.0.md` (Section 6)
- Parse all test vector files in `docs/business/ba/products/structured-notes/fcn/test-vectors/`
- Validate consistency across all sources
- Output results to console
- Write JSON results to `taxonomy-validation.json` in the repository root

### Exit Codes

- `0`: Validation passed (all checks successful)
- `1`: Validation failed (one or more checks failed)

## Output Format

The script generates a JSON file (`taxonomy-validation.json`) with the following structure:

```json
{
  "status": "pass|fail",
  "branches_evaluated": 2,
  "duplicate_tuples": [],
  "missing_dimensions": [],
  "unknown_branch_ids_in_vectors": []
}
```

### Fields

- **status**: Overall validation status (`pass` or `fail`)
- **branches_evaluated**: Number of branches found in the specification manifest
- **duplicate_tuples**: Array of duplicate taxonomy tuples (each with `tuple` and `branch_ids`)
- **missing_dimensions**: Array of branches missing required dimensions (each with `branch_id` and `missing_keys`)
- **unknown_branch_ids_in_vectors**: Array of test vectors referencing undefined branches (each with `filename` and `branch_id`)

### Optional Fields

- **error**: Fatal error message if validation could not be completed
- **test_vector_parse_warnings**: Non-fatal warnings from parsing test vectors
- **normative_flag_warnings**: Informational warnings about normative flags (not blocking)

## Examples

### Successful Validation

```
Validating FCN v1.0 taxonomy and branch consistency...
  Spec: .../fcn-v1.0.md
  Taxonomy: .../payoff_types.md
  Test Vectors: .../test-vectors

============================================================
VALIDATION RESULTS
============================================================
Status: PASS
Branches Evaluated: 2

Validation results written to: .../taxonomy-validation.json
```

### Failed Validation (Unknown Branch ID)

```
Validating FCN v1.0 taxonomy and branch consistency...
  Spec: .../fcn-v1.0.md
  Taxonomy: .../payoff_types.md
  Test Vectors: .../test-vectors

============================================================
VALIDATION RESULTS
============================================================
Status: FAIL
Branches Evaluated: 2

Unknown Branch IDs in Vectors (1):
  - test-vector-x.md: branch_id 'unknown_branch' not in manifest

Validation results written to: .../taxonomy-validation.json
```

### Failed Validation (Missing Dimensions)

```
Validating FCN v1.0 taxonomy and branch consistency...
  Spec: .../fcn-v1.0.md
  Taxonomy: .../payoff_types.md
  Test Vectors: .../test-vectors

============================================================
VALIDATION RESULTS
============================================================
Status: FAIL
Branches Evaluated: 2

Missing Dimensions (1):
  - Branch 'base_mem': missing ['settlement', 'recovery_mode']

Validation results written to: .../taxonomy-validation.json
```

### Failed Validation (Duplicate Tuples)

```
Validating FCN v1.0 taxonomy and branch consistency...
  Spec: .../fcn-v1.0.md
  Taxonomy: .../payoff_types.md
  Test Vectors: .../test-vectors

============================================================
VALIDATION RESULTS
============================================================
Status: FAIL
Branches Evaluated: 3

Duplicate Tuples (1):
  - Tuple {'barrier_type': 'down-in', 'settlement': 'physical-settlement', ...}: found in branches ['base_mem', 'base_mem_v2']

Validation results written to: .../taxonomy-validation.json
```

## Dependencies

- Python 3.7+
- PyYAML

All dependencies are included in standard Python distributions or are commonly available.

## Integration

This validator can be integrated into:

- CI/CD pipelines (use exit code to fail builds on validation errors)
- Pre-commit hooks
- Documentation promotion workflows (Draft → Proposed gate)
- Automated documentation quality checks

## Related Documents

- FCN v1.0 Specification: `docs/business/ba/products/structured-notes/fcn/specs/fcn-v1.0.md`
- Payoff Types & Taxonomy: `docs/business/ba/products/structured-notes/common/payoff_types.md`
- Activation Checklist Issue: https://github.com/YuantaIT-Siripong/Knowledge2/issues/3
- ADR-003: FCN Version Activation & Promotion Workflow

---

## Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-10 | System | Initial implementation of Phase 0 metadata validator |
| 1.1.0 | 2025-10-10 | System | Added Phase 1 taxonomy & branch consistency validator |
