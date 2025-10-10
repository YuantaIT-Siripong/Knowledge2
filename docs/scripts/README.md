# FCN v1.0 Validation Scripts

This directory contains validation scripts for FCN v1.0 specification quality assurance.

## Scripts

- **validate-fcn-metadata.py**: Phase 0 - Metadata and front matter validator
- **validate-fcn-taxonomy.py**: Phase 1 - Taxonomy and branch consistency validator

---

## Phase 0: Metadata Validator (`validate-fcn-metadata.py`)

### Overview

The `validate-fcn-metadata.py` script validates the front matter (YAML metadata) of the FCN v1.0 specification file against the requirements specified in the Phase 0 activation checklist.

### Requirements

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

### Usage

#### Basic Usage

Run from the repository root:

```bash
python3 docs/scripts/validate-fcn-metadata.py
```

This will:
- Parse the front matter from `docs/business/ba/products/structured-notes/fcn/specs/fcn-v1.0.md`
- Validate all requirements
- Output results to console
- Write JSON results to `metadata-validation.json` in the repository root

#### Exit Codes

- `0`: Validation passed (all checks successful)
- `1`: Validation failed (one or more checks failed)

### Output Format

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

### Examples

#### Successful Validation

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

#### Failed Validation (Missing Fields)

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

#### Failed Validation (Version Mismatch)

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

---

## Phase 1: Taxonomy Validator (`validate-fcn-taxonomy.py`)

### Overview

The `validate-fcn-taxonomy.py` script validates branch taxonomy consistency between the FCN v1.0 specification and test vectors, ensuring alignment with the taxonomy framework defined in `common/payoff_types.md`.

### Requirements

This validator checks:

1. **Branch Dimension Completeness**: Each branch in the specification's taxonomy table (Section 6) has all required taxonomy dimensions:
   - `barrier_type`
   - `settlement`
   - `coupon_memory`
   - `step_feature`
   - `recovery_mode`

2. **No Duplicate Tuples**: No two branches have identical taxonomy dimension values (which would make them indistinguishable)

3. **Test Vector Branch Consistency**: All `branch_id` values referenced in test vectors exist in the specification's branch inventory

4. **Normative Flag Validation**: Test vectors that appear to be normative (based on filename patterns like N1-N5) have the `normative: true` flag set

### Usage

#### Basic Usage

Run from the repository root:

```bash
python3 docs/scripts/validate-fcn-taxonomy.py
```

This will:
- Parse the branch taxonomy table from Section 6 of `docs/business/ba/products/structured-notes/fcn/specs/fcn-v1.0.md`
- Parse all test vector files from `docs/business/ba/products/structured-notes/fcn/test-vectors/`
- Validate taxonomy consistency
- Output results to console
- Write JSON results to `taxonomy-validation.json` in the repository root

#### Exit Codes

- `0`: Validation passed (all checks successful)
- `1`: Validation failed (one or more checks failed)

### Output Format

The script generates a JSON file (`taxonomy-validation.json`) with the following structure:

```json
{
  "status": "pass|fail",
  "branches_evaluated": 2,
  "duplicate_tuples": [],
  "missing_dimensions": [],
  "unknown_branch_ids_in_vectors": [],
  "normative_flag_warnings": [],
  "spec_path": "...",
  "test_vectors_path": "...",
  "parse_errors": []
}
```

#### Fields

- **status**: Overall validation status (`pass` or `fail`)
- **branches_evaluated**: Number of branches found in the specification
- **duplicate_tuples**: Array of duplicate taxonomy tuple descriptions
- **missing_dimensions**: Array of missing dimension issues per branch
- **unknown_branch_ids_in_vectors**: Array of test vectors referencing non-existent branch_ids
- **normative_flag_warnings**: Array of warnings about normative flag mismatches
- **spec_path**: Path to the specification file validated
- **test_vectors_path**: Path to the test vectors directory
- **parse_errors**: Array of parsing errors encountered

### Examples

#### Successful Validation

```
Validating FCN v1.0 taxonomy from: .../fcn-v1.0.md
Test vectors directory: .../test-vectors

============================================================
TAXONOMY VALIDATION RESULTS
============================================================
Status: PASS
Branches Evaluated: 2

Validation results written to: .../taxonomy-validation.json
```

#### Failed Validation (Missing Dimensions)

```
Validating FCN v1.0 taxonomy from: .../fcn-v1.0.md
Test vectors directory: .../test-vectors

============================================================
TAXONOMY VALIDATION RESULTS
============================================================
Status: FAIL
Branches Evaluated: 2

Missing Dimensions (3):
  - Branch 'base_mem' missing dimension 'recovery_mode'
  - Branch 'base_nomem' missing dimension 'settlement'
  - Branch 'base_nomem' missing dimension 'step_feature'

Validation results written to: .../taxonomy-validation.json
```

#### Failed Validation (Unknown Branch IDs)

```
Validating FCN v1.0 taxonomy from: .../fcn-v1.0.md
Test vectors directory: .../test-vectors

============================================================
TAXONOMY VALIDATION RESULTS
============================================================
Status: FAIL
Branches Evaluated: 2

Unknown Branch IDs in Test Vectors (1):
  - Test vector 'fcn-v1.0-invalid-branch.md' references unknown branch_id 'invalid_branch'

Validation results written to: .../taxonomy-validation.json
```

---

## Dependencies

Both validators require:

- Python 3.7+
- PyYAML
- requests (for metadata validator only)

All dependencies are included in standard Python distributions or are commonly available.

## Integration

These validators can be integrated into:

- CI/CD pipelines (use exit codes to fail builds on validation errors)
- Pre-commit hooks
- Manual validation workflows before spec promotion
- Automated documentation quality checks
- Activation checklist verification for Draft → Proposed promotion

## Related Documents

- FCN v1.0 Specification: `docs/business/ba/products/structured-notes/fcn/specs/fcn-v1.0.md`
- Taxonomy Framework: `docs/business/ba/products/structured-notes/common/payoff_types.md`
- Activation Checklist Issue: https://github.com/YuantaIT-Siripong/Knowledge2/issues/3
- ADR-003: FCN Version Activation & Promotion Workflow

## Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-10 | System | Initial implementation of Phase 0 metadata validator |
| 1.1.0 | 2025-10-10 | System | Added Phase 1 taxonomy and branch consistency validator |
