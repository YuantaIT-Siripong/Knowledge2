# Validator Roadmap – Structured Notes (FCN v1.0 Baseline)

Status: Draft  
Scope: Establish staged validation framework to support promotion of FCN v1.0 (and future product versions) from Draft → Proposed → Active.

---

## Guiding Principles
1. Deterministic: All validators produce reproducible JSON outputs.
2. Incremental: Each phase adds a new validation surface without rewriting earlier logic.
3. Extensible: Same framework can incorporate future features (step-down barriers, proportional-loss, alias lifecycles).
4. Evidence-Centric: Each run emits artifacts linkable from activation / governance issues.

---

## Phase Matrix

| Phase | Name                                | Input Artifacts | Core Checks | Output Artifacts | Promotion Gate |
|-------|-------------------------------------|-----------------|-------------|------------------|----------------|
| 0     | Metadata / Front Matter Validator   | spec markdown, parameter schema, manifest | Required keys present; status transitions legal; spec_version consistency; activation issue URL validity | metadata-validation.json | Required for Proposed |
| 1     | Taxonomy & Branch Consistency       | spec taxonomy section, manifest, branch list | All declared dimensions enumerated; branch_ids unique; branch attribute combinations valid; test vectors reference existing branch_ids | taxonomy-validation.json | Required for Proposed |
| 2     | Parameter Schema Conformance        | parameter schema JSON, sample parameter payloads (test vectors) | All parameters validate; required sets satisfied; constraints obeyed; cross-field rules (arrays length equality) | param-validation.json | Required for Proposed |
| 3     | Memory Coupon Logic Recompute       | test vector JSON (normalized), payoff pseudocode | Recompute coupons, memory accrual, KI trigger; diffs vs expected | memory-logic-validation.json | Required for Active |
| 4     | Test Vector Coverage Auditor        | test vector index, gap table in spec | Confirms targeted dimension pairs covered; identifies uncovered categories | coverage-report.json | Required for Active |
| 5     | Alias Lifecycle Linter (future)     | alias table (future versions) | Stage ordering correctness; presence/absence vs version timeline | alias-lifecycle.json | Future |
| 6     | Promotion Gate Aggregator           | Prior phase outputs | Aggregates pass/fail; suggests readiness status | promotion-gate-summary.json | Drives status toggle |
| 7     | Extended Economic Scenario Validator| Non-normative vectors (EX*) | Ensures experimental branches not leaking into normative set | experimental-scan.json | Informational |

... (truncated for brevity in this instruction) 
