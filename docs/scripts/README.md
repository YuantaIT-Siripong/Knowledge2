# FCN v1.0 Validators

This directory contains validation scripts for the FCN v1.0 specification and parameters.

## Overview

### Phase 0: Metadata Validator (`validate-fcn-metadata.py`)

The `validate-fcn-metadata.py` script validates the front matter (YAML metadata) of the FCN v1.0 specification file against the requirements specified in the Phase 0 activation checklist.

### Phase 2: Parameter Schema Conformance Validator (`validate-fcn-params.py`)

The `validate-fcn-params.py` script validates FCN v1.0 parameter payloads against the JSON Schema and enforces cross-field business rules.

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

# FCN v1.0 Parameter Schema Conformance Validator (Phase 2)

## Overview

The `validate-fcn-params.py` script validates sample FCN v1.0 parameter payloads against:
1. **JSON Schema**: Structural validation of data types, formats, and constraints
2. **Cross-Field Rules**: Business logic validation between related fields

## Requirements

This validator checks:

### JSON Schema Validation
- All required fields are present
- Data types match specifications (strings, numbers, arrays, booleans)
- Date formats are valid (ISO-8601)
- Numeric constraints (positive values, ranges)
- Enum constraints (valid values for settlement_type, recovery_mode, etc.)
- Array constraints (minimum lengths, item types)

### Cross-Field Business Rules

1. **Array Length Matching**: `length(underlying_symbols) == length(initial_levels)`
2. **Date Ordering**: `observation_dates` must be strictly increasing and all < `maturity_date`
3. **Array Length Matching**: `length(coupon_payment_dates) == length(observation_dates)`
4. **Date Constraint**: All `coupon_payment_dates[i] >= issue_date`
5. **Conditional Null**: If `is_memory_coupon=false` then `memory_carry_cap_count` must be null

## Usage

### Basic Usage

Run from the repository root:

```bash
python3 docs/scripts/validate-fcn-params.py
```

This will:
- Load the JSON Schema from `docs/business/ba/products/structured-notes/fcn/schemas/fcn-v1.0-schema.json`
- Validate all JSON payloads in `docs/business/ba/products/structured-notes/fcn/test-vectors/sample-payloads/`
- Output results to console
- Write JSON results to `param-validation.json` in the repository root

### Exit Codes

- `0`: Validation passed (all payloads conform to schema and rules)
- `1`: Validation failed (one or more violations detected)

## Output Format

The script generates a JSON file (`param-validation.json`) with the following structure:

```json
{
  "status": "pass|fail",
  "payloads_tested": n,
  "violations": [
    {
      "payload": "filename.json",
      "path": "$.field_name",
      "rule": "rule_type",
      "message": "Description of violation"
    }
  ],
  "summary": {
    "errors": n,
    "warnings": m
  }
}
```

### Fields

- **status**: Overall validation status (`pass` or `fail`)
- **payloads_tested**: Number of payload files validated
- **violations**: Array of violation objects with:
  - **payload**: Name of the payload file containing the violation
  - **path**: JSONPath to the field with the violation
  - **rule**: Type of rule violated (e.g., `schema`, `array_length_match`, `strictly_increasing`)
  - **message**: Detailed description of the violation
- **summary**: Summary counts:
  - **errors**: Total number of errors across all payloads
  - **warnings**: Total number of warnings (currently all violations are errors)

## Examples

### Successful Validation

```
Validating FCN v1.0 parameters from: .../sample-payloads
Using schema: .../fcn-v1.0-schema.json

============================================================
VALIDATION RESULTS
============================================================
Status: PASS
Payloads Tested: 2
Total Errors: 0
Total Warnings: 0

Validation results written to: .../param-validation.json
```

### Failed Validation

```
Validating FCN v1.0 parameters from: .../sample-payloads
Using schema: .../fcn-v1.0-schema.json

============================================================
VALIDATION RESULTS
============================================================
Status: FAIL
Payloads Tested: 3
Total Errors: 4
Total Warnings: 0

Violations (4)
------------------------------------------------------------

Payload: fcn-v1.0-invalid-payload.json
  Path: $.initial_levels
  Rule: array_length_match
  Message: Length of initial_levels (1) must equal length of underlying_symbols (2)

Payload: fcn-v1.0-invalid-payload.json
  Path: $.observation_dates[3]
  Rule: strictly_increasing
  Message: observation_dates must be strictly increasing: 2026-06-30 >= 2026-06-30

Payload: fcn-v1.0-invalid-payload.json
  Path: $.coupon_payment_dates
  Rule: array_length_match
  Message: Length of coupon_payment_dates (4) must equal length of observation_dates (5)

Payload: fcn-v1.0-invalid-payload.json
  Path: $.memory_carry_cap_count
  Rule: conditional_null
  Message: memory_carry_cap_count must be null when is_memory_coupon is false

Validation results written to: .../param-validation.json
```

## Sample Payloads

Sample payloads for testing are located in:
`docs/business/ba/products/structured-notes/fcn/test-vectors/sample-payloads/`

### Valid Payloads
- `fcn-v1.0-n1-payload.json` - Based on test vector N1 (memory coupon, all coupons pay)
- `fcn-v1.0-n4-payload.json` - Based on test vector N4 (non-memory coupon)

### Invalid Payloads (for testing)
- `fcn-v1.0-invalid-payload.json` - Contains multiple violations for testing validator

## JSON Schema

The JSON Schema is located at:
`docs/business/ba/products/structured-notes/fcn/schemas/fcn-v1.0-schema.json`

This schema is derived from the parameter table in Section 3 of the FCN v1.0 specification.

## Dependencies

- Python 3.7+
- jsonschema 4.0+

All dependencies are included in standard Python distributions or are commonly available.

## Integration

This validator can be integrated into:

- CI/CD pipelines (use exit code to fail builds on validation errors)
- Pre-commit hooks
- Parameter validation workflows
- Test vector validation automation
- Quality assurance checks

## Related Documents

- FCN v1.0 Specification: `docs/business/ba/products/structured-notes/fcn/specs/fcn-v1.0.md`
- Test Vectors: `docs/business/ba/products/structured-notes/fcn/test-vectors/`
- Activation Checklist Issue: https://github.com/YuantaIT-Siripong/Knowledge2/issues/3

---

## Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-10 | System | Initial implementation of Phase 0 metadata validator |
| 1.1.0 | 2025-10-10 | System | Added Phase 2 parameter schema conformance validator |
