---
title: FCN Version Activation & Promotion Workflow
doc_type: decision-record
adr: 003
status: Draft
version: 0.1.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-09
last_reviewed: 2025-10-09
next_review: 2026-04-09
classification: Internal
tags: [decision, products, governance, versioning]
related:
  - adr-002-product-doc-structure.md
  - ../../../../_policies/document-control-policy.md
---

# FCN Version Activation & Promotion Workflow

## Context
FCN specifications evolve (v1.0 baseline, v1.1 step-down extension). We require a governed path from Proposed → Active → Deprecated to ensure economic, risk, and implementation alignment.

## Decision
Establish a promotion pipeline:
Concept → Proposed → (Calibration & Review) → Active → Deprecated → Removed

Promotion from Proposed → Active requires a completed Activation Checklist:
1. Parameter table completeness & naming aligned with conventions.
2. Payoff branch taxonomy codes referenced and stable.
3. Step-down or structural extensions documented with backward compatibility notes.
4. Test vectors: minimum normative subset flagged (edge, baseline, KI recovery, physical).
5. Risk calibration review (scenario coverage & stress).
6. Implementation parity confirmation (engine or pricing model).
7. Changelog entry added (with difference summary).
8. Alias / naming conflicts resolved or flagged (deprecation policy integrated).
9. Lifecycle mapping (asset buckets / events) cross-checked.

## Rationale
- Provides gating for correctness & consistency.
- Test vectors ensure reproducible validation.
- Explicit alias auditing reduces semantic drift.

## Alternatives Considered
1. Simple “merge & declare Active” — Rejected (insufficient controls).
2. Heavy-weight change board for every minor revision — Rejected (adds latency, low agility).
3. Tag-based Git semantics only — Rejected (does not capture process artifacts like calibration sign-off).

## Consequences
### Positive
- High confidence in Active specs.
- Clear audit path.
### Negative
- Extra authoring effort early.
- Requires minimal automation to avoid manual drift.

## Metrics
- Average Proposed → Active cycle time.
- % of Active specs with complete normative test vector set.
- Drift incidents (implementation divergence) per quarter.

## Follow-up Tasks
- [ ] Create activation checklist template file.
- [ ] Add validator rule: Proposed spec must reference checklist issue ID.
- [ ] Tag normative test vectors with `normative: true`.

## Change Log
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1.0 | 2025-10-09 | siripong.s@yuanta.co.th | Initial draft |
