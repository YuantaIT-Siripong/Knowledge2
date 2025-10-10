---
title: FCN v1.0 Validator Roadmap
doc_type: product-definition
status: Draft
version: 1.0.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-10
last_reviewed: 2025-10-10
next_review: 2026-04-10
classification: Internal
tags: [structured-notes, fcn, validation, governance]
related:
  - specs/fcn-v1.0.md
  - manifest.yaml
  - validator-issues-draft.md
  - ../../common/governance.md
  - ../../../sa/design-decisions/adr-003-fcn-version-activation.md
---

# FCN v1.0 Validator Roadmap

## 1. Purpose

Defines the phased implementation roadmap for automated validators supporting FCN v1.0 governance, from metadata conformance (Phase 0) through full lifecycle validation (Phase 5). Ensures machine-readable enforcement of promotion requirements per ADR-003.

## 2. Validation Phases

### Phase 0: Metadata & Document Structure (Required for Proposed)
**Gate:** Documentation artifacts meet structural and metadata requirements.

**Validators:**
- **metadata_validator.py**: Validates YAML front matter completeness, doc_type alignment, version format, required fields.
- **spec_structure_validator.py**: Ensures spec files contain required sections (Parameter Table, Taxonomy, Payoff Pseudocode, Alias Table, Change Log).

**Success Criteria:**
- All spec files pass metadata schema validation.
- Front matter `status`, `version`, `owner`, `approver` fields present and valid.
- No missing required sections in spec markdown.

**Priority:** P0 (Blocker for promotion to Active)

---

### Phase 1: Taxonomy & Branch Conformance (Required for Proposed)
**Gate:** Taxonomy tuples are complete, unique, and consistent across spec, manifest, and test vectors.

**Validators:**
- **taxonomy_validator.py**: Validates taxonomy tuple completeness (barrier_type, settlement, coupon_memory, step_feature, recovery_mode).
- **branch_consistency_validator.py**: Cross-checks branch definitions in manifest.yaml against spec inventory and test vectors.

**Success Criteria:**
- All branches in manifest reference valid taxonomy tuples.
- Test vectors' `taxonomy` blocks match declared branches.
- No undefined taxonomy codes in specs or test vectors.

**Priority:** P0 (Blocker for promotion to Active)

---

### Phase 2: Parameter Schema Conformance (Required for Proposed)
**Gate:** Parameters conform to JSON schema and naming conventions.

**Validators:**
- **parameter_validator.py**: Validates trade parameters against `fcn-v1.0-parameters.schema.json`.
- **naming_convention_validator.py**: Enforces snake_case, `_pct` suffix, `_date` suffix, boolean `is_` prefix per conventions.md.
- **constraint_validator.py**: Validates parameter constraints (min/max, enum values, pattern matching).

**Success Criteria:**
- All test vector parameters validate against JSON schema.
- Parameter names in spec table match schema and conventions.
- Constraint violations flagged (e.g., `knock_in_barrier_pct > 1`).

**Priority:** P0 (Blocker for promotion to Active)

---

### Phase 3: Test Vector Coverage & Normative Set (Required for Active)
**Gate:** Minimum normative test vector set is complete and passing.

**Validators:**
- **coverage_validator.py**: Ensures each branch has minimum normative coverage (baseline, edge, KI event, recovery mode).
- **normative_flag_validator.py**: Validates `normative: true` vectors exist and are correctly tagged.
- **test_vector_schema_validator.py**: Validates test vector JSON structure against `test-vector.schema.json`.

**Success Criteria:**
- At least one normative vector per branch.
- Edge cases (barrier touch, KI event, memory logic) covered.
- All normative vectors pass expected output validation.

**Priority:** P1 (Required for Active promotion)

---

### Phase 4: Payoff & Lifecycle Logic (Required for Active)
**Gate:** Payoff calculations match expected outputs in normative vectors.

**Validators:**
- **memory_logic_validator.py**: Validates memory coupon accumulation and payout logic.
- **knock_in_validator.py**: Validates knock-in trigger detection and recovery mode application.
- **coupon_decision_validator.py**: Validates per-observation coupon payment decisions.
- **redemption_validator.py**: Validates final redemption amount calculation (par-recovery vs proportional-loss).

**Success Criteria:**
- Memory logic correctly accumulates missed coupons.
- Knock-in events correctly trigger recovery mode switch.
- Coupon decisions match expected outputs for all normative vectors.
- Redemption amounts within tolerance (±0.0001) of expected.

**Priority:** P1 (Required for Active promotion)

---

### Phase 5: Lifecycle & Data Model Integrity (Optional Enhancement)
**Gate:** Database model integrity and lifecycle event consistency.

**Validators:**
- **er_model_validator.py**: Validates migration scripts against ER model (er-fcn-v1.0.md).
- **observation_sequencing_validator.py**: Ensures observation dates are sequential and complete.
- **cash_flow_integrity_validator.py**: Validates cash flow records match coupon decisions and redemption.
- **alias_lifecycle_validator.py**: Ensures deprecated parameters follow ADR-004 alias policy.

**Success Criteria:**
- Migration schema matches ER model entity definitions.
- Observation records exist for all scheduled dates.
- Cash flow totals reconcile with expected coupon and redemption amounts.
- No orphaned alias references.

**Priority:** P2 (Enhancement for data quality)

---

## 3. Implementation Sequence

### Milestone 1: Foundation (Phase 0–2)
**Objective:** Establish minimum validation for Proposed → Active promotion.

**Deliverables:**
1. `metadata_validator.py` + `spec_structure_validator.py`
2. `taxonomy_validator.py` + `branch_consistency_validator.py`
3. `parameter_validator.py` + `naming_convention_validator.py` + `constraint_validator.py`
4. CI integration for pre-merge checks

**Timeline:** 2 weeks (initial prototype)

---

### Milestone 2: Normative Coverage (Phase 3)
**Objective:** Ensure normative test vector set completeness.

**Deliverables:**
1. `coverage_validator.py` + `normative_flag_validator.py` + `test_vector_schema_validator.py`
2. Aggregator script to generate coverage report
3. Update manifest.yaml with normative vector linkage

**Timeline:** 1 week

---

### Milestone 3: Payoff Logic (Phase 4)
**Objective:** Validate economic correctness via test vector execution.

**Deliverables:**
1. `memory_logic_validator.py` + `knock_in_validator.py`
2. `coupon_decision_validator.py` + `redemption_validator.py`
3. Tolerance configuration for floating-point comparison

**Timeline:** 2 weeks

---

### Milestone 4: Data Integrity (Phase 5)
**Objective:** Extend validation to database schema and lifecycle consistency.

**Deliverables:**
1. `er_model_validator.py` + `observation_sequencing_validator.py`
2. `cash_flow_integrity_validator.py` + `alias_lifecycle_validator.py`
3. Migration testing framework

**Timeline:** 1 week (deferred to post-Active)

---

## 4. Validator Scripts Overview

### Core Validators (Priority P0)

#### metadata_validator.py
- **Input:** Markdown files with YAML front matter
- **Checks:** Required fields, doc_type values, version format, status values
- **Output:** Pass/fail per file + error details

#### taxonomy_validator.py
- **Input:** manifest.yaml, test vectors, spec files
- **Checks:** Taxonomy tuple completeness, valid codes, cross-reference consistency
- **Output:** Pass/fail + list of undefined codes

#### parameter_validator.py
- **Input:** Test vector parameters JSON, parameter schema
- **Checks:** JSON schema validation, constraint enforcement
- **Output:** Pass/fail + constraint violations

### Coverage Validators (Priority P1)

#### coverage_validator.py
- **Input:** manifest.yaml branches, test-vectors/ directory
- **Checks:** Minimum normative vector count per branch, edge case tags
- **Output:** Coverage matrix + missing scenarios

#### memory_logic_validator.py
- **Input:** Test vectors with `is_memory_coupon = true`
- **Checks:** Missed coupon accumulation, payout logic on subsequent observations
- **Output:** Pass/fail + expected vs actual coupon decisions

### Supporting Scripts

#### ingest_vectors.py
- **Purpose:** Ingest test vector markdown files into database `test_vector` table
- **Functionality:** Parse markdown, extract YAML metadata, populate JSONB columns

#### aggregator.py
- **Purpose:** Generate consolidated validation report across all phases
- **Output:** HTML/Markdown summary with pass/fail counts, missing coverage, errors

---

## 5. CI Integration Plan

### Pre-Merge Checks (GitHub Actions)
1. Run Phase 0 validators (metadata, structure)
2. Run Phase 1 validators (taxonomy)
3. Run Phase 2 validators (parameters)
4. Fail merge if any P0 validator fails

### Nightly Builds
1. Run full Phase 0–4 validator suite
2. Generate coverage report
3. Notify on normative vector failures

### Release Gate
1. Require all Phase 0–3 validators passing
2. Require ≥ 80% normative vector coverage per branch
3. Require activation checklist linked in spec front matter

---

## 6. Validation Tooling Architecture

### Directory Structure
```
validators/
  metadata_validator.py
  taxonomy_validator.py
  parameter_validator.py
  coverage_validator.py
  memory_logic_validator.py
  knock_in_validator.py
  coupon_decision_validator.py
  redemption_validator.py
  er_model_validator.py
  ingest_vectors.py
  aggregator.py
  utils/
    schema_loader.py
    markdown_parser.py
    tolerance_config.py
  tests/
    test_metadata_validator.py
    test_taxonomy_validator.py
    ...
```

### Configuration File (validators/config.yaml)
```yaml
schemas:
  parameters: schemas/fcn-v1.0-parameters.schema.json
  test_vector: schemas/test-vector.schema.json

tolerance:
  float_comparison: 0.0001

normative_requirements:
  min_vectors_per_branch: 1
  required_tags: [baseline, edge, ki-event]

ci:
  fail_on_missing_metadata: true
  fail_on_taxonomy_error: true
  fail_on_parameter_violation: true
```

---

## 7. Metrics & Reporting

### Key Metrics:
- **Validation Pass Rate:** % of validators passing per phase
- **Normative Coverage:** % of branches with complete normative set
- **Constraint Violations:** Count of parameter violations per test run
- **Taxonomy Drift:** Count of undefined taxonomy codes detected
- **CI Build Time:** Validator execution time per phase

### Reporting Outputs:
1. **validation-summary.md:** Aggregated pass/fail per phase
2. **coverage-matrix.html:** Visual coverage heatmap (branches × tags)
3. **violations-report.json:** Detailed error log with file/line references
4. **drift-log.md:** Taxonomy and alias drift incidents

---

## 8. Extension Points for v1.1+

- Add step-down schedule validator (Phase 2 extension)
- Add autocall trigger validator (Phase 4 extension)
- Add multi-currency FX rate validator (Phase 2 extension)
- Add alias lifecycle transition validator (Phase 5 extension)

---

## 9. Success Criteria (Overall)

**For Proposed → Active Promotion:**
- ✅ All Phase 0–2 validators passing
- ✅ Minimum 1 normative vector per branch
- ✅ No P0 violations in CI

**For Production Readiness:**
- ✅ All Phase 0–4 validators passing
- ✅ ≥ 80% normative coverage
- ✅ All normative vectors passing expected output validation
- ✅ Activation checklist completed and linked

---

## 10. Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-10 | siripong.s@yuanta.co.th | Initial validator roadmap for FCN v1.0 governance |
