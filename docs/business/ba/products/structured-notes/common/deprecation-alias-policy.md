---
title: Deprecation & Alias Operational Policy (Structured Notes)
doc_type: product-definition
status: Draft
version: 0.1.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-09
last_reviewed: 2025-10-09
next_review: 2026-04-09
classification: Internal
tags: [structured-notes, common, naming, deprecation]
related:
  - ../../../sa/design-decisions/adr-004-parameter-alias-policy.md
  - ../../../sa/design-decisions/adr-003-fcn-version-activation.md
---

# Deprecation & Alias Operational Policy

## Purpose
Operationalizes ADR-004 into concrete repository conventions and tooling hooks.

## Alias Table Format
| legacy_name | new_name | stage | first_version | removal_target | notes |
|-------------|----------|-------|---------------|----------------|-------|
| min_upside_guarantee_pct | min_abs_move_guarantee_pct | Introduce | 1.1.0 | 2.0.0 | Symmetric absolute guarantee rename |

## Stage Enforcement Summary
| Stage | Allowed Usage | Validation Behavior |
|-------|---------------|--------------------|
| Introduce | Both names | Warn if legacy lacks alias table reference |
| Stable Dual | New usage discouraged | Warn on new references (non-test) |
| Deprecation Notice | Legacy only for backward parsing | Fail new PR usage |
| Removal | Legacy disallowed | Fail if legacy occurs |

## File Annotations
Specs containing any Stage 1–3 alias must include:
```
<!-- alias-active: true -->
```
at top of body (after front matter) for lint detection.

## Lint Rules (Planned)
- [ ] Detect orphan legacy names (no table entry).
- [ ] Detect missing alias banner in affected specs.
- [ ] Enforce removal stage zero occurrences before major bump.

## Tooling Integration
A pre-merge GitHub Action will:
1. Scan changed spec/test-vector files.
2. Collect alias occurrences.
3. Compare against alias table YAML (future central registry).
4. Emit structured warnings/errors.

## Migration Guidance
Provide a short “Migration Notes” subsection in the first spec version that introduces the new parameter.

## Change Log
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1.0 | 2025-10-09 | siripong.s@yuanta.co.th | Initial draft |