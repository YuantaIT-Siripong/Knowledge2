# FCN Validator Scripts

This directory contains scripts implementing phased validation for the FCN v1.0 specification and its normative test vectors.

## Phases Implemented

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

## Future Roadmap

- Standardize naming (e.g., `validate_metadata.py` vs `validate-fcn-metadata.py`).
- Add aggregator combined report.
- Introduce coverage thresholds gating promotion.
- Expand normative vector set for additional branches.