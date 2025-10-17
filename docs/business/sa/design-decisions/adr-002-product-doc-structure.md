---
title: Product Documentation Structure & Location
doc_type: decision-record
adr: 002
status: Accepted
version: 0.1.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-09
last_reviewed: 2025-10-17
decision_date: 2025-10-17
next_review: 2026-04-09
classification: Internal
tags: [architecture, decision, documentation, products, governance, versioning]
related:
  - ../../../../_policies/tagging-schema.md
  - ../../ba/products/structured-notes/fcn/specs/SUPERSEDED_INDEX.md
---

# Product Documentation Structure & Location

## Context
We need a consistent place and taxonomy for structured financial product knowledge (definitions, specs, lifecycle, test vectors, governance) that spans business and technical audiences.

## Decision
Adopt a BA-oriented product subtree:
`docs/business/ba/products/<product-family>/<product>/...`
Introduce new doc_types: `product-spec`, `product-definition`, `test-vector`.
Normative specs live under `specs/` directory; illustrative content segregated.

## Rationale
- Business origin: Product economics and compliance begin with BA.
- Separation of concerns: Architecture folder remains focused on system/solution viewpoints.
- Extensibility: Supports additional products (e.g., twin-win, bear-shark) without flattening.
- Validation ease: Predictable pattern aids automated indexing.

## Alternatives Considered
1. Place under SA architecture tree — Rejected (blurs economic vs system concerns).
2. Top-level `products/` — Rejected (breaks BA/SA distinction established in governance).
3. Embed alongside asset reporting model — Rejected (mixes product payoff semantics with account aggregation semantics).

## Consequences
### Positive
- Clear onboarding for authors.
- Validator can enforce doc_type + directory alignment.
- Easier product-level lifecycle version gating.

### Negative
- Cross-cutting architecture docs must reference product specs relatively.
- Future refactor required if product ownership shifts to a distinct team structure.

## Implementation Notes
Directory minimum for FCN:
```
products/structured-notes/common/
products/structured-notes/fcn/specs/
products/structured-notes/fcn/examples/
products/structured-notes/fcn/test-vectors/
products/structured-notes/fcn/lifecycle/
products/structured-notes/fcn/cases/
products/structured-notes/fcn/migrations/
```

Lifecycle artifacts include:
- **Supersession Index** (`SUPERSEDED_INDEX.md`): Tracks superseded specification versions for historical reference and audit purposes. Maintained in specs/ directory alongside active specifications.
- **Migration Scripts**: Version upgrade scripts and data harmonization utilities reside under `migrations/` subdirectory.
- **Diagnostic Views**: Schema diffs and validation reports stored under product schema directory for traceability.

See [SUPERSEDED_INDEX.md](../../ba/products/structured-notes/fcn/specs/SUPERSEDED_INDEX.md) for FCN specification lifecycle tracking.

## Follow-up Tasks
- [ ] Update tagging schema (doc_type list)
- [ ] Extend metadata validator (new doc_types)
- [ ] Import FCN baseline spec & examples

## Change Log
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1.0 | 2025-10-09 | siripong.s@yuanta.co.th | Initial draft |