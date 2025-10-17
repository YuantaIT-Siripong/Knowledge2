---
title: Parameter Alias & Deprecation Policy (Structured Notes)
doc_type: decision-record
adr: 004
status: Accepted
version: 0.2.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-09
last_reviewed: 2025-10-17
decision_date: 2025-10-17
next_review: 2026-04-09
classification: Internal
tags: [decision, naming, products, governance, versioning]
related:
  - ../../../../_policies/tagging-schema.md
  - ../../../../_policies/document-control-policy.md
  - adr-002-product-doc-structure.md
  - adr-003-fcn-version-activation.md
---

# Parameter Alias & Deprecation Policy (Structured Notes)

## Context
Legacy parameter `min_upside_guarantee_pct` no longer semantically accurate (symmetric absolute guarantee). Replacement: `min_abs_move_guarantee_pct`. Need controlled phased alias management synchronized with spec versions (v1.0 baseline vs v1.1+).

## Decision
Adopt a 4-stage alias life cycle:
1. Introduce: Both fields permitted; canonical = new name; legacy flagged with banner.
2. Stable Dual: At least one minor version cycle; tooling warns on new usage of legacy.
3. Deprecation Notice: Legacy marked “Deprecated – removal next major”.
4. Removal: Legacy eliminated in next major spec; changelog & schema updated.

Documentation Requirements:
- Conventions file lists alias mapping.
- Each spec containing alias includes “Alias Table” with: legacy_name, new_name, stage, first_version, removal_target.
- Test vectors stop referencing legacy once stage 3 begins.

## Rationale
- Prevents sudden breaking changes.
- Provides clarity for implementation / data migrations.
- Aligns with economic semantics clarity.

## Alternatives Considered
1. Immediate rename – risk of breaking downstream dependencies.
2. Permanent alias retention – increases cognitive & validation overhead.

## Enforcement
Automation phases:
- Phase 1: Lint warns if legacy appears without alias banner.
- Phase 2: Fails PR if legacy used past deprecation stage.
- Phase 3: Removal verified (no occurrences) before tagging new major.

## Active Alias Inventory

As of v1.1.0, **no active parameter aliases** exist in the FCN specification. The following historical alias events have been resolved:

### Completed Canonicalization

| Legacy Name | Canonical Name | Stage | Resolution Date | Notes |
|-------------|----------------|-------|-----------------|-------|
| settlement_type (alias variations) | settlement_type = 'physical-settlement' | Removed | 2025-10-17 | Pre-v1.1.0 harmonization consolidated all settlement_type variations to canonical 'physical-settlement' value |

### Settlement Type Canonicalization Note
Prior to v1.1.0 activation, the repository underwent settlement_type harmonization to eliminate semantic ambiguity. All specifications now use the canonical value `settlement_type = 'physical-settlement'`. See [SETTLEMENT_TYPE_FIX_SUMMARY.md](../../ba/products/structured-notes/fcn/migrations/SETTLEMENT_TYPE_FIX_SUMMARY.md) for migration details.

## Criteria for Future Alias Introduction

New parameter aliases may be introduced only under the following conditions:

### Semantic Extension Criteria
1. **New Settlement Semantics**: If a new settlement type (e.g., 'mixed-settlement', 'cash-optional') requires distinct parameter names or field aliases to clarify behavior, an alias MAY be introduced with explicit governance approval.
2. **Backward Compatibility Requirement**: Legacy parameter names from prior major versions may be aliased during a transition period (stages 1-3) to maintain compatibility.
3. **Regulatory or Market Requirement**: External standards or market conventions may necessitate alternative parameter naming.

### Governance Requirements
- **ADR Amendment**: Alias introduction requires an amendment to this ADR (ADR-004) documenting the alias rationale, lifecycle stages, and removal criteria.
- **Lifecycle Staging Alignment**: New aliases MUST follow the 4-stage lifecycle defined in this ADR.
- **Test Coverage**: Aliases MUST be covered by test vectors demonstrating equivalence with canonical parameters.
- **Documentation**: Alias mappings MUST be recorded in the conventions file and specification Alias Table.

### Example: Future 'mixed-settlement' Scenario
If 'mixed-settlement' is introduced requiring distinct allocation parameters (e.g., `cash_settlement_pct`, `physical_settlement_pct`), these would be NEW parameters (not aliases). However, if legacy `settlement_type` values need to be supported during transition, they would follow the 4-stage alias lifecycle.

## Automation Implementation Status

| Phase | Description | Status | Target Date | Implementation Notes |
|-------|-------------|--------|-------------|---------------------|
| Phase 1 | Alias Linter (Warn) | Pending | 2026-Q1 | Lint warns if legacy parameter name appears without explicit alias banner in spec |
| Phase 2 | Deprecation Gate (Fail) | Pending | 2026-Q2 | PR fails if legacy parameter used after stage 3 (Deprecation Notice) |
| Phase 3 | Removal Verification | Pending | 2026-Q3 | Pre-major-version gate: verify no legacy parameter occurrences in specs, test vectors, or migrations |
| Phase 4 | Alias Registry Automation | Planned | 2026-Q4 | Auto-generate alias mapping table from spec front-matter; validate consistency across versions |

## Follow-up Tasks
- [x] Add alias mapping section to conventions file (settlement_type canonicalization completed)
- [ ] Implement alias linter (Phase 1)
- [ ] Add spec checklist item “Alias Table present if any alias active.”

## Change Log
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1.0 | 2025-10-09 | siripong.s@yuanta.co.th | Initial draft || 0.2.0 | 2025-10-17 | siripong.s@yuanta.co.th | Status promoted to Accepted; added Active Alias Inventory (zero active aliases), Criteria for Future Alias Introduction, Automation Implementation Status table; documented settlement_type canonicalization |
