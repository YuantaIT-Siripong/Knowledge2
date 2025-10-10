# FCN v1.0 Metadata Validator

## Overview

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

## Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-10 | System | Initial implementation of Phase 0 metadata validator |
