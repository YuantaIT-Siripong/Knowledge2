---
title: Structured Notes Conventions
doc_type: product-definition
status: Draft
version: 0.1.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-09
last_reviewed: 2025-10-09
next_review: 2026-04-09
classification: Internal
tags: [structured-notes, common, conventions]
related:
  - ../../../sa/design-decisions/adr-002-product-doc-structure.md
  - ../../../sa/design-decisions/adr-003-fcn-version-activation.md
  - ../../../sa/design-decisions/adr-004-parameter-alias-policy.md
---

# Structured Notes Conventions

## Purpose
Defines shared naming, parameter formatting, date handling, and payoff expression rules applied across all structured note product specifications (e.g., FCN, future twin-win).

## Scope
Applies to:
- Parameter tables in `specs/`
- Test vectors under `test-vectors/`
- Examples under `examples/`
- Lifecycle event mapping files under `lifecycle/`

## Naming Conventions
| Aspect | Convention | Example |
|--------|------------|---------|
| Parameter snake_case | Lowercase with underscores | `knock_in_barrier_pct` |
| Percentage fields | Suffix `_pct` (store as decimal ratio; display ×100%) | `coupon_step_down_pct` |
| Boolean flags | Prefix `is_` | `is_memory_coupon` |
| Date fields | Suffix `_date` (ISO-8601) | `trade_date` |
| Enumerations | Lowercase, hyphen-separated tokens | `american`, `european`, `physical-settlement` |

## Parameter Table Requirements
1. Column order: name, type, required, default, constraints, description.
2. Constraints use a concise DSL (e.g., `0 < x <= 1`, `enum: physical-settlement|cash-settlement`).
3. Every parameter referenced in payoff pseudocode must appear in the table.

## Payoff Expression Guidelines
- Express payoff logic as normalized pseudocode with consistently named sections: Initialization, Observation, Barrier Evaluation, Coupon Accrual, Settlement.
- Use explicit branch taxonomy codes if referenced (see `payoff_types.md`).
- Avoid embedding market data acquisition logic (that belongs to engine docs).

## Versioning Notes
- Add new parameters only in minor versions if backward compatible.
- Deprecations must follow ADR-004 alias lifecycle and appear in Alias Table sections.

## Cross-Referencing
Use relative links to spec files (e.g., `../fcn/specs/fcn-v1.0.md` once available).

## Follow-up Tasks
- [ ] Integrate a parameter table validator rule set.
- [ ] Automate detection of missing description fields.
- [ ] Add alias table injection hook (post-processor).

## Change Log
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1.0 | 2025-10-09 | siripong.s@yuanta.co.th | Initial draft
