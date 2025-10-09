---
title: Payoff Types & Taxonomy (Structured Notes)
doc_type: product-definition
status: Draft
version: 0.1.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-09
last_reviewed: 2025-10-09
next_review: 2026-04-09
classification: Internal
tags: [structured-notes, common, taxonomy, payoff]
related:
  - ../../../sa/design-decisions/adr-002-product-doc-structure.md
  - ../../../sa/design-decisions/adr-003-fcn-version-activation.md
---

# Payoff Types & Taxonomy

## Purpose
Provides canonical taxonomy codes used by product specs to classify payoff branches and structural features.

## Taxonomy Dimensions
| Dimension | Code Examples | Description |
|-----------|---------------|-------------|
| Barrier Type | `down-in`, `down-and-in`, `down-and-out`, `up-and-in` | Structural barrier classification |
| Settlement | `physical-settlement`, `cash-settlement` | Mode of final settlement |
| Coupon Memory | `memory`, `no-memory` | Coupon accumulation style |
| Step Feature | `step-down`, `no-step` | Barrier or coupon step evolution |
| Knock-In Recovery | `par-recovery`, `proportional-loss` | Post knock-in payoff mode |

## Branch Coding
Each payoff branch path in a spec should map to a tuple: (barrier_type, settlement, coupon_memory, step_feature, recovery_mode).

Example encoding (FCN baseline):
```
(barrier_type=down-in,
 settlement=physical-settlement,
 coupon_memory=memory,
 step_feature=no-step,
 recovery_mode=par-recovery)
```

## Usage Rules
1. Every normative test vector includes a `taxonomy:` block referencing the tuple.
2. Specs MUST define any new taxonomy values before use.
3. Deprecated taxonomy codes require explicit deprecation notice and replacement mapping.

## Extension Mechanism
Additional dimensions can be introduced in minor spec versions if non-breaking; add a “Dimension Introduction” note.

## Validation Hooks (Planned)
- [ ] Lint unknown codes.
- [ ] Enforce tuple completeness.
- [ ] Cross-check test vectors vs declared spec taxonomy inventory.

## Change Log
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1.0 | 2025-10-09 | siripong.s@yuanta.co.th | Initial draft