---
title: FCN v1.0 Validator Issues Draft
doc_type: product-definition
status: Draft
version: 1.0.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-10
last_reviewed: 2025-10-10
next_review: 2026-04-10
classification: Internal
tags: [structured-notes, fcn, validation, governance, issues]
related:
  - validator-roadmap.md
  - manifest.yaml
  - ../../common/governance.md
---

# FCN v1.0 Validator Issues Draft

## Purpose

Provides draft issue descriptions for implementing FCN v1.0 validators. These can be used to create GitHub issues to track validator implementation work.

---

## Issue Template

```
Title: [Validator] <Validator Name> - Phase <N>

Labels: validator, fcn, phase-<N>, <priority>

Description:
<Issue description from below>

Acceptance Criteria:
<Criteria from below>

Related:
- validator-roadmap.md
- <related spec/schema files>
```

---

## Phase 0 Issues

### Issue 1: Implement Metadata Validator

**Title:** [Validator] Metadata Validator - Phase 0

**Priority:** P0 (Blocker)

**Description:**
Implement metadata validator to ensure YAML front matter completeness and document structure conformance for FCN specs and test vectors.

**Requirements:**
- Validate required fields based on doc_type (product-spec, test-vector, etc.)
- Check status values against allowed list (Draft, Proposed, Active, etc.)
- Validate classification levels (Public, Internal, Confidential, Restricted)
- Validate version format (semantic versioning: MAJOR.MINOR.PATCH)
- Validate product_code for test vectors (must be 'FCN')
- Support directory and single-file validation
- Generate detailed error reports with file/line references

**Acceptance Criteria:**
- [ ] Script `metadata_validator.py` created and executable
- [ ] Validates all required fields per doc_type
- [ ] Detects missing or invalid YAML front matter
- [ ] Returns exit code 0 on success, 1 on failure
- [ ] Outputs clear error messages with field names
- [ ] Tested against existing FCN spec and test vector files

**Related Files:**
- `validators/metadata_validator.py`
- `specs/fcn-v1.0.md`
- `test-vectors/*.md`

---

### Issue 2: Implement Spec Structure Validator

**Title:** [Validator] Spec Structure Validator - Phase 0

**Priority:** P0 (Blocker)

**Description:**
Implement validator to ensure spec files contain required sections per conventions.

**Requirements:**
- Check for required sections: Parameter Table, Taxonomy & Branch Inventory, Payoff Pseudocode, Alias Table, Change Log
- Validate section heading hierarchy (H2, H3, etc.)
- Flag missing sections
- Support flexible heading formats (e.g., "3. Parameter Table" or "## Parameter Table")

**Acceptance Criteria:**
- [ ] Script `spec_structure_validator.py` created
- [ ] Validates presence of required sections
- [ ] Handles different markdown heading formats
- [ ] Clear error messages indicating missing sections
- [ ] Tested against fcn-v1.0.md

**Related Files:**
- `validators/spec_structure_validator.py`
- `specs/fcn-v1.0.md`
- `../common/conventions.md`

---

## Phase 1 Issues

### Issue 3: Implement Taxonomy Validator

**Title:** [Validator] Taxonomy Validator - Phase 1

**Priority:** P0 (Blocker)

**Description:**
Implement taxonomy validator to ensure taxonomy tuples are complete, unique, and use valid codes.

**Requirements:**
- Validate tuple completeness (all 5 dimensions: barrier_type, settlement, coupon_memory, step_feature, recovery_mode)
- Check codes against allowed values from payoff_types.md
- Validate consistency across manifest.yaml, spec files, and test vectors
- Flag undefined taxonomy codes
- Support taxonomy extension validation for future versions

**Acceptance Criteria:**
- [ ] Script `taxonomy_validator.py` created
- [ ] Validates completeness of taxonomy tuples
- [ ] Detects invalid taxonomy codes
- [ ] Cross-references manifest, specs, and test vectors
- [ ] Clear error messages with code suggestions
- [ ] Tested against FCN v1.0 branches

**Related Files:**
- `validators/taxonomy_validator.py`
- `manifest.yaml`
- `../common/payoff_types.md`
- `test-vectors/*.md`

---

### Issue 4: Implement Branch Consistency Validator

**Title:** [Validator] Branch Consistency Validator - Phase 1

**Priority:** P0 (Blocker)

**Description:**
Implement validator to cross-check branch definitions in manifest against spec inventory and test vectors.

**Requirements:**
- Validate branches in manifest.yaml match spec taxonomy inventory
- Ensure test vectors reference valid branches
- Flag orphaned test vectors (no matching branch)
- Flag branches with no test vectors
- Generate branch-to-vector mapping report

**Acceptance Criteria:**
- [ ] Script `branch_consistency_validator.py` created
- [ ] Cross-validates manifest, spec, and test vectors
- [ ] Detects orphaned vectors and uncovered branches
- [ ] Generates mapping report
- [ ] Tested with FCN v1.0 branches

**Related Files:**
- `validators/branch_consistency_validator.py`
- `manifest.yaml`
- `specs/fcn-v1.0.md`
- `test-vectors/*.md`

---

## Phase 2 Issues

### Issue 5: Implement Parameter Schema Validator

**Title:** [Validator] Parameter Schema Validator - Phase 2

**Priority:** P0 (Blocker)

**Description:**
Implement parameter validator using JSON Schema to validate test vector parameters.

**Requirements:**
- Load and parse fcn-v1.0-parameters.schema.json
- Validate test vector parameters against schema
- Check required fields, data types, constraints (min/max, enum, pattern)
- Report specific constraint violations with paths
- Support both YAML front matter and embedded parameter blocks

**Acceptance Criteria:**
- [ ] Script `parameter_validator.py` created
- [ ] Uses jsonschema library for validation
- [ ] Validates all test vectors in test-vectors/
- [ ] Clear error messages with JSON paths
- [ ] Identifies which constraint was violated
- [ ] Tested with valid and invalid parameter sets

**Related Files:**
- `validators/parameter_validator.py`
- `schemas/fcn-v1.0-parameters.schema.json`
- `test-vectors/*.md`

**Dependencies:**
- Requires `pip install jsonschema`

---

### Issue 6: Implement Naming Convention Validator

**Title:** [Validator] Naming Convention Validator - Phase 2

**Priority:** P1 (Required for Active)

**Description:**
Implement validator to enforce parameter naming conventions per conventions.md.

**Requirements:**
- Check snake_case format for parameter names
- Validate `_pct` suffix for percentage fields
- Validate `_date` suffix for date fields
- Validate `is_` prefix for boolean fields
- Flag convention violations with suggestions
- Support auto-fix mode (optional enhancement)

**Acceptance Criteria:**
- [ ] Script `naming_convention_validator.py` created or integrated into parameter_validator.py
- [ ] Validates all naming conventions
- [ ] Clear warnings with suggested corrections
- [ ] Tested against FCN parameter table
- [ ] Integrated with parameter_validator.py

**Related Files:**
- `validators/naming_convention_validator.py`
- `../common/conventions.md`
- `specs/fcn-v1.0.md` (Parameter Table section)

---

## Phase 3 Issues

### Issue 7: Implement Coverage Validator

**Title:** [Validator] Coverage Validator - Phase 3

**Priority:** P1 (Required for Active)

**Description:**
Implement coverage validator to ensure minimum normative test vector coverage per branch.

**Requirements:**
- Validate minimum normative vector count per branch (≥1)
- Check for required tags (baseline, edge, ki-event, recovery)
- Validate normative flag consistency with manifest
- Generate coverage matrix (branches × tags)
- Flag branches with insufficient coverage
- Support HTML and markdown report output

**Acceptance Criteria:**
- [ ] Script `coverage_validator.py` created
- [ ] Validates minimum normative count
- [ ] Checks required tag coverage
- [ ] Generates coverage matrix report
- [ ] Identifies coverage gaps
- [ ] Tested with FCN v1.0 branches

**Related Files:**
- `validators/coverage_validator.py`
- `manifest.yaml`
- `test-vectors/*.md`
- `validator-roadmap.md`

---

### Issue 8: Implement Test Vector Schema Validator

**Title:** [Validator] Test Vector Schema Validator - Phase 3

**Priority:** P1 (Required for Active)

**Description:**
Implement validator for test vector JSON structure against test-vector.schema.json.

**Requirements:**
- Validate test vector structure (vector_id, taxonomy, parameters, expected_outputs)
- Check required sections completeness
- Validate taxonomy structure
- Validate expected_outputs structure (knock_in_triggered, total_coupon_paid, coupon_decisions)
- Flag missing or malformed sections

**Acceptance Criteria:**
- [ ] Script `test_vector_schema_validator.py` created
- [ ] Validates against test-vector.schema.json
- [ ] Checks all required sections
- [ ] Clear error messages for malformed vectors
- [ ] Tested with existing test vectors

**Related Files:**
- `validators/test_vector_schema_validator.py`
- `schemas/test-vector.schema.json`
- `test-vectors/*.md`

---

## Phase 4 Issues

### Issue 9: Implement Memory Logic Validator

**Title:** [Validator] Memory Logic Validator - Phase 4

**Priority:** P1 (Required for Active)

**Description:**
Implement validator for memory coupon accumulation and payout logic.

**Requirements:**
- Validate missed coupon accumulation logic
- Check payout of accumulated coupons when barrier not breached
- Validate `missed_coupons_accumulated` field accuracy
- Compare against expected_outputs.coupon_decisions
- Support tolerance-based floating-point comparison
- Flag logic errors with observation-level detail

**Acceptance Criteria:**
- [ ] Script `memory_logic_validator.py` created
- [ ] Validates memory accumulation logic
- [ ] Checks accumulated coupon payouts
- [ ] Tolerance-based comparison (±0.0001)
- [ ] Clear error messages with observation indices
- [ ] Tested with memory and no-memory vectors

**Related Files:**
- `validators/memory_logic_validator.py`
- `test-vectors/fcn-v1.0-base-mem-*.md`
- `specs/fcn-v1.0.md` (Payoff Pseudocode section)

---

### Issue 10: Implement Knock-In Validator

**Title:** [Validator] Knock-In Validator - Phase 4

**Priority:** P1 (Required for Active)

**Description:**
Implement validator for knock-in trigger detection and recovery mode application.

**Requirements:**
- Validate knock-in trigger detection (barrier breach)
- Check knock_in_date accuracy
- Validate recovery mode switch (par-recovery vs proportional-loss)
- Validate redemption amount calculation post knock-in
- Support american and european observation styles
- Flag incorrect trigger detection or recovery application

**Acceptance Criteria:**
- [ ] Script `knock_in_validator.py` created
- [ ] Validates knock-in trigger detection
- [ ] Checks recovery mode application
- [ ] Validates redemption amounts
- [ ] Handles both observation styles
- [ ] Tested with KI and no-KI scenarios

**Related Files:**
- `validators/knock_in_validator.py`
- `test-vectors/fcn-v1.0-base-mem-ki-event.md`
- `specs/fcn-v1.0.md` (Payoff Pseudocode section)

---

### Issue 11: Implement Coupon Decision Validator

**Title:** [Validator] Coupon Decision Validator - Phase 4

**Priority:** P1 (Required for Active)

**Description:**
Implement validator for per-observation coupon payment decisions.

**Requirements:**
- Validate barrier evaluation at each observation
- Check coupon payment logic (paid vs not paid)
- Validate coupon_paid amounts against coupon_rate_pct
- Cross-check with expected_outputs.coupon_decisions
- Support memory and no-memory variants
- Flag decision logic errors

**Acceptance Criteria:**
- [ ] Script `coupon_decision_validator.py` created
- [ ] Validates barrier evaluation logic
- [ ] Checks coupon payment amounts
- [ ] Handles memory and no-memory logic
- [ ] Clear error messages with observation details
- [ ] Tested with multiple test vectors

**Related Files:**
- `validators/coupon_decision_validator.py`
- `test-vectors/*.md`
- `specs/fcn-v1.0.md`

---

### Issue 12: Implement Redemption Validator

**Title:** [Validator] Redemption Validator - Phase 4

**Priority:** P1 (Required for Active)

**Description:**
Implement validator for final redemption amount calculation.

**Requirements:**
- Validate redemption amount calculation
- Check par-recovery mode (100% notional if KI, else 100%)
- Check proportional-loss mode (worst performance if KI)
- Validate settlement_details structure
- Support tolerance-based comparison
- Flag redemption calculation errors

**Acceptance Criteria:**
- [ ] Script `redemption_validator.py` created
- [ ] Validates par-recovery calculation
- [ ] Validates proportional-loss calculation
- [ ] Checks settlement details
- [ ] Tolerance-based comparison
- [ ] Tested with both recovery modes

**Related Files:**
- `validators/redemption_validator.py`
- `test-vectors/*.md`
- `specs/fcn-v1.0.md`

---

## Supporting Scripts Issues

### Issue 13: Implement Test Vector Ingestion Script

**Title:** [Utility] Test Vector Ingestion Script

**Priority:** P2 (Enhancement)

**Description:**
Implement script to ingest test vector markdown files into database test_vector table.

**Requirements:**
- Parse test vector markdown files
- Extract YAML metadata and JSON blocks
- Populate test_vector table (vector_code, parameters_json, expected_outputs_json, etc.)
- Support batch ingestion
- Handle database connection errors gracefully
- Support dry-run mode (extract only, no DB insert)

**Acceptance Criteria:**
- [ ] Script `ingest_vectors.py` created
- [ ] Parses markdown and YAML correctly
- [ ] Populates database table
- [ ] Handles errors gracefully
- [ ] Supports dry-run mode
- [ ] Tested with FCN test vectors

**Related Files:**
- `validators/ingest_vectors.py`
- `test-vectors/*.md`
- `migrations/m0001-fcn-baseline.sql`

---

### Issue 14: Implement Validator Aggregator

**Title:** [Utility] Validator Aggregator Script

**Priority:** P1 (Required for CI)

**Description:**
Implement aggregator script to run all validators and generate consolidated report.

**Requirements:**
- Run all Phase 0-4 validators sequentially
- Capture exit codes and outputs
- Generate summary report (pass/fail counts, promotion readiness)
- Support markdown and HTML report formats
- Calculate execution time
- Provide promotion readiness assessment
- Exit with error if critical phases fail

**Acceptance Criteria:**
- [ ] Script `aggregator.py` created
- [ ] Runs all validators
- [ ] Generates consolidated report
- [ ] Assesses promotion readiness
- [ ] Supports output formats
- [ ] Tested end-to-end

**Related Files:**
- `validators/aggregator.py`
- `validator-roadmap.md`
- All validator scripts

---

## CI Integration Issue

### Issue 15: Integrate Validators into CI Pipeline

**Title:** [CI] Integrate FCN Validators into GitHub Actions

**Priority:** P0 (Blocker for automation)

**Description:**
Integrate FCN validators into GitHub Actions CI pipeline for automated validation on PR and merge.

**Requirements:**
- Create GitHub Actions workflow (e.g., `.github/workflows/fcn-validators.yml`)
- Run Phase 0-2 validators on every PR to fcn/ directory
- Run Phase 3-4 validators on nightly schedule
- Fail PR merge if Phase 0-2 validators fail
- Generate and upload validation report as artifact
- Add status badge to README.md
- Support manual workflow dispatch

**Acceptance Criteria:**
- [ ] GitHub Actions workflow created
- [ ] Validators run on PR and merge
- [ ] PR blocked on Phase 0-2 failures
- [ ] Nightly full validation runs
- [ ] Reports uploaded as artifacts
- [ ] Status badge added
- [ ] Tested with sample PR

**Related Files:**
- `.github/workflows/fcn-validators.yml`
- `validators/aggregator.py`
- `README.md`

---

## Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-10 | siripong.s@yuanta.co.th | Initial validator issues draft for FCN v1.0 governance |
