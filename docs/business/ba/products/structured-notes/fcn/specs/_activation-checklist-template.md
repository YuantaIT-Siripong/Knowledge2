---
title: FCN Specification Activation Checklist Template
doc_type: reference
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
status: Draft
version: 0.1.0
created: 2025-10-09
last_reviewed: 2025-10-09
next_review: 2026-04-09
classification: Internal
tags: [structured-notes, fcn, activation, checklist, governance]
related:
  - ../../../../sa/design-decisions/adr-003-fcn-version-activation.md
  - ../../../common/governance.md
  - fcn-v1.0.md
---

# FCN Specification Activation Checklist Template

## Purpose
This template provides a standardized checklist for promoting an FCN specification from **Proposed** to **Active** status, as required by ADR-003 (FCN Version Activation & Promotion Workflow).

## Instructions
1. Create a GitHub issue using this checklist for each specification version promotion.
2. Reference the issue ID in the spec's `activation_checklist_issue` front matter field.
3. Complete all checklist items before requesting promotion to Active status.
4. Obtain sign-offs from required reviewers (Product Owner, Risk Reviewer, Technical Reviewer).

---

## Activation Checklist for FCN Spec [VERSION]

### 1. Normative Test Vector Set
- [ ] **Normative test vectors present**: All test vectors listed in `normative_test_vector_set` are committed to the repository
- [ ] **Test vector IDs referenced**: Test vectors N1–N5 (or equivalent) are properly documented in Section 10 of the spec
- [ ] **Test vectors tagged normative**: Each test vector file has `normative: true` in its front matter
- [ ] **Test vector coverage verified**: Coverage matrix (Section 13) maps all normative dimensions to test vector IDs
- [ ] **Edge cases included**: Test vectors cover baseline, edge conditions (equality, barrier touch), and KI scenarios
- [ ] **Test vectors executable**: Test vectors include complete input parameters and expected outputs

### 2. Taxonomy & Branch Inventory
- [ ] **Taxonomy declared**: Section 6 includes complete taxonomy tuple for all payoff branches
- [ ] **Taxonomy codes stable**: All taxonomy codes are defined in `common/payoff_types.md`
- [ ] **Test vectors match taxonomy**: Every normative test vector `taxonomy:` block matches declared spec taxonomy
- [ ] **Branch inventory complete**: All payoff branches enumerated with taxonomy codes referenced
- [ ] **No unknown taxonomy codes**: Linter (if available) confirms no undefined taxonomy references

### 3. Alias Table
- [ ] **Alias table present**: Section 9 includes alias table (may be empty for v1.0)
- [ ] **Alias table verified empty** (for v1.0): Confirms no active aliases in baseline version
- [ ] **Future alias planning noted**: If parameter renames are anticipated, they are documented in Open Items (Section 12)
- [ ] **Alias policy compliance**: Alias handling follows deprecation-alias-policy.md conventions

### 4. Parameter & Metadata Completeness
- [ ] **Parameter table complete**: Section 3 includes all input parameters with types, constraints, and defaults
- [ ] **Naming conventions aligned**: Parameter names follow established naming conventions
- [ ] **Derived fields documented**: Section 4 enumerates all computed/derived fields (non-input)
- [ ] **Front matter complete**: All required front matter fields populated (title, doc_type, status, spec_version, owner, approver, dates, tags)
- [ ] **Related documents linked**: Related ADRs, policies, and common definitions referenced

### 5. Payoff & Lifecycle Mapping
- [ ] **Payoff pseudocode present**: Section 5 includes normative payoff calculation logic
- [ ] **Lifecycle events mapped**: Section 7 includes event codes, triggers, and descriptions
- [ ] **Settlement modes documented**: Physical/cash settlement modes clearly specified
- [ ] **Recovery modes defined**: Par-recovery and/or proportional-loss modes documented

### 6. Governance & Review
- [ ] **Product Owner sign-off**: Business semantics and economic correctness validated
  - Reviewer: ___________________ Date: ___________
- [ ] **Risk Reviewer sign-off**: Scenario coverage and stress calibration reviewed
  - Reviewer: ___________________ Date: ___________
- [ ] **Technical Reviewer sign-off**: Engine parity and naming conformity confirmed
  - Reviewer: ___________________ Date: ___________
- [ ] **Documentation Steward sign-off**: Metadata validity and alias oversight completed
  - Reviewer: ___________________ Date: ___________

### 7. Automation & Lint Status
- [ ] **Metadata validation passing**: Front matter schema validation successful (if automation available)
- [ ] **Taxonomy linter passing**: No undefined or mismatched taxonomy codes detected
- [ ] **Memory logic validated**: Memory coupon accumulation logic reviewed for correctness
- [ ] **Alias linter passing**: No orphan legacy names or missing alias banner (if applicable)
- [ ] **Link integrity verified**: All internal document references resolve correctly

### 8. Open Items & Gap Analysis
- [ ] **Open items documented**: Section 12 includes all known open items with priority and target version
- [ ] **Basket logic status**: Basket/multi-underlying support status clarified (e.g., deferred, planned)
- [ ] **Memory cap status**: Memory carry cap handling documented or deferred with rationale
- [ ] **FX reference status**: Cross-currency settlement handling clarified or deferred
- [ ] **Alternative settlement status**: Cash-settlement branch status (normative, non-normative, or deferred)
- [ ] **Step features status**: Step-down/step-up feature plans documented in versioning notes
- [ ] **Gap coverage plan**: Section 13.3 enumerates planned future test vectors and target versions

### 9. Versioning & Compatibility
- [ ] **Version number assigned**: Spec has clear semantic version (e.g., 1.0.0)
- [ ] **Backward compatibility noted**: Section 8 documents compatibility considerations and breaking changes (if any)
- [ ] **Deprecation plan present**: Any deprecated features or parameters are clearly marked
- [ ] **Migration guidance provided**: If breaking changes exist, migration notes are included

### 10. Implementation & Integration
- [ ] **Implementation parity confirmed**: Pricing engine or valuation model matches spec semantics
- [ ] **Regression testing planned**: Test vectors integrated into automated test suite (if applicable)
- [ ] **Documentation quality reviewed**: Clarity, completeness, and consistency validated
- [ ] **Stakeholder communication**: Affected teams notified of pending promotion

### 11. Final Review & Approval
- [ ] **Activation checklist reviewed**: All items above marked complete and verified
- [ ] **Changelog entry added**: Section 14 includes entry for this version promotion
- [ ] **Status promotion authorized**: Approver confirms readiness for Proposed → Active promotion
  - Approver: ___________________ Date: ___________
- [ ] **Front matter updated**: `status` field updated to `Active` and `activation_checklist_issue` reference confirmed

---

## Promotion Decision

**Recommendation**: [ ] Approve promotion to Active  [ ] Defer (specify blockers below)

**Blockers (if deferred)**:
- 

**Approver Comments**:


**Final Approval**:
- Name: ___________________
- Role: ___________________
- Date: ___________________
- Signature: ___________________

---

## References
- ADR-003: FCN Version Activation & Promotion Workflow
- Structured Notes Documentation Governance
- Deprecation & Alias Operational Policy
- Payoff Types & Taxonomy

## Change Log
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1.0 | 2025-10-09 | siripong.s@yuanta.co.th | Initial template creation |
