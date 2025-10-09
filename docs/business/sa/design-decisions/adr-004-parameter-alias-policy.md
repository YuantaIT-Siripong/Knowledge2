---
title: Parameter Alias & Deprecation Policy (Structured Notes)
doc_type: decision-record
adr: 004
status: Draft
version: 0.1.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-09
last_reviewed: 2025-10-09
next_review: 2026-04-09
classification: Internal
tags: [decision, naming, products, governance]
related:
  - ../../../../_policies/tagging-schema.md
  - ../../../../_policies/document-control-policy.md
  - adr-002-product-doc-structure.md
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

## Follow-up Tasks
- [ ] Add alias mapping section to conventions file.
- [ ] Implement alias linter (Phase 1).
- [ ] Add spec checklist item “Alias Table present if any alias active.”

## Change Log
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1.0 | 2025-10-09 | siripong.s@yuanta.co.th | Initial draft |