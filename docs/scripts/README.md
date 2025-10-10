# FCN v1.0 Validators

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

| Phase | Script (current)                    | Purpose |
|-------|-------------------------------------|---------|
| 0     | validate-fcn-metadata.py            | Validate YAML/document metadata & structure |
| 1     | validate-fcn-taxonomy.py            | Taxonomy table ↔ manifest ↔ test vector consistency |
| 2*    | (planned) validate-fcn-parameters.py| Parameter schema / value constraints |
| 3*    | (planned) validate-fcn-coverage.py  | Normative test vector coverage per branch |
| 4*    | (planned) validate-fcn-memory.py    | Memory coupon logic edge cases |
| *     | aggregator.py (future)              | Consolidated readiness report |

(* phases 2+ to be finalized; names may change when standardizing naming convention.)

## validate-fcn-metadata.py (Phase 0)

Validates:
- Required front matter keys
- doc_type alignment
- Version / status basic structure

Exit codes:
- 0: pass
- 1: failures

Output: `metadata-validation.json`

## validate-fcn-taxonomy.py (Phase 1)

Checks:
1. Branch dimension completeness (barrier_type, settlement, coupon_memory, step_feature, recovery_mode)
2. No duplicate taxonomy tuples
3. All test vector branch_ids exist in manifest / spec taxonomy
4. Normative naming pattern (N1–N5…) align with `normative: true` flag

Output example (`taxonomy-validation.json`):
```json
{
  "status": "pass",
  "branches_evaluated": 2,
  "duplicate_tuples": [],
  "missing_dimensions": [],
  "unknown_branch_ids_in_vectors": [],
  "normative_flag_warnings": [],
  "spec_path": "docs/business/ba/products/structured-notes/fcn/specs/fcn-v1.0.md",
  "test_vectors_path": "docs/business/ba/products/structured-notes/fcn/test-vectors",
  "parse_errors": []
}
```

## Running Validators

From repository root:
```bash
python3 docs/scripts/validate-fcn-metadata.py
python3 docs/scripts/validate-fcn-taxonomy.py
```

(Phase 2+ scripts will be added; CI workflow will call each sequentially.)

## Integration (CI)

The GitHub Actions workflow (`fcn-validators.yml`) will:
1. Ingest vectors
2. Run Phase 0
3. Run Phase 1
4. (Future) Run later phases
5. Upload JSON reports as artifacts
6. Fail on any non-pass status for enforced phases

## Contributing

1. Add or adjust a validator script.
2. Ensure output JSON consistently includes: `status`, counts, lists of issues.
3. Keep README updated with new phase scripts.

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

## Future Roadmap

- Standardize naming (e.g., `validate_metadata.py` vs `validate-fcn-metadata.py`).
- Add aggregator combined report.
- Introduce coverage thresholds gating promotion.
- Expand normative vector set for additional branches.
