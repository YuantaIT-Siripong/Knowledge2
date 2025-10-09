---
title: Structured Notes Documentation Governance
doc_type: product-definition
status: Draft
version: 0.1.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-09
last_reviewed: 2025-10-09
next_review: 2026-04-09
classification: Internal
tags: [structured-notes, common, governance]
related:
  - ../../../sa/design-decisions/adr-002-product-doc-structure.md
  - ../../../sa/design-decisions/adr-003-fcn-version-activation.md
  - ../../../sa/design-decisions/adr-004-parameter-alias-policy.md
---

# Structured Notes Documentation Governance

## Objectives
- Ensure consistent quality and traceability of product specifications.
- Provide auditable promotion pathway (see ADR-003).
- Manage naming and alias lifecycle (see ADR-004).

## Artifact Types
| Artifact | Directory Pattern | doc_type | Promotion Control |
|----------|-------------------|----------|------------------|
| Product Spec | `fcn/specs/*.md` | product-spec | Version activation workflow |
| Examples | `fcn/examples/*.md` | product-definition | Reviewed for clarity |
| Test Vectors | `fcn/test-vectors/*.md` | test-vector | Normative subset required |
| Lifecycle Maps | `fcn/lifecycle/*.md` | product-definition | Cross-check events |
| Cases / Use Narratives | `fcn/cases/*.md` | product-definition | Informational |

## Promotion Gates
See ADR-003 checklist. Governance ensures checklist issue link is present in front matter of Proposed specs moving to Active.

## Roles
| Role | Responsibility |
|------|---------------|
| Product Owner | Business semantics, economic correctness |
| Risk Reviewer | Scenario coverage & stress calibration |
| Technical Reviewer | Engine parity & naming conformity |
| Documentation Steward | Metadata validity & alias oversight |

## Review Cadence
- Draft → Proposed: Author + Product Owner
- Proposed → Active: Full triad (Product, Risk, Technical)
- Active → Deprecated: Steward initiates based on alias or supersession decision

## Automation Roadmap
- [ ] Metadata schema validation (doc_type-directory alignment)
- [ ] Alias linter (Phase 1)
- [ ] Taxonomy tuple validator
- [ ] Normative test vector tagging enforcement

## Metrics
- Spec promotion lead time
- Incomplete checklist rejections
- Alias lifecycle adherence (on-time removals)

## Change Log
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1.0 | 2025-10-09 | siripong.s@yuanta.co.th | Initial draft |