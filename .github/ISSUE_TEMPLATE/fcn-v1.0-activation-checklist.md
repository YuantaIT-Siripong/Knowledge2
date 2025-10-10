---
name: FCN v1.0 Activation Checklist
about: Track activation requirements for FCN v1.0 specification promotion from Draft to Proposed
title: 'FCN v1.0 Activation Checklist'
labels: ['activation', 'fcn', 'structured-notes', 'spec-promotion']
assignees: ''
---

# FCN v1.0 Specification Activation Checklist

## Overview
This issue tracks the activation checklist for **FCN v1.0 Baseline Specification**, as required for promotion from **Draft** to **Proposed** status per ADR-003 (FCN Version Activation & Promotion Workflow).

## Reference Documentation
- Specification: `docs/business/ba/products/structured-notes/fcn/specs/fcn-v1.0.md`
- Template: `docs/business/ba/products/structured-notes/fcn/specs/_activation-checklist-template.md`
- ADR-003: FCN Version Activation & Promotion Workflow

---

## Activation Gates

### 1. Normative Test Vector Set (N1–N5)
- [ ] **Normative test vectors present**: All test vectors N1–N5 listed in `normative_test_vector_set` are committed to the repository
- [ ] **Test vector IDs referenced**: Test vectors N1–N5 are properly documented in Section 10 of the spec
- [ ] **Test vectors tagged normative**: Each test vector file has `normative: true` in its front matter
- [ ] **Test vector coverage verified**: Coverage matrix (Section 13) maps all normative dimensions to test vector IDs
- [ ] **Edge cases included**: Test vectors cover baseline, edge conditions (equality, barrier touch), and KI scenarios

### 2. Taxonomy Declared and Matches All Vector branch_ids
- [ ] **Taxonomy declared**: Section 6 includes complete taxonomy tuple for all payoff branches
- [ ] **Taxonomy codes stable**: All taxonomy codes are defined in `common/payoff_types.md`
- [ ] **Test vectors match taxonomy**: Every normative test vector `taxonomy:` block matches declared spec taxonomy
- [ ] **Branch inventory complete**: All payoff branches enumerated with taxonomy codes referenced
- [ ] **No unknown taxonomy codes**: Linter (if available) confirms no undefined taxonomy references

### 3. Alias Table Empty and Verified
- [ ] **Alias table present**: Section 9 includes alias table (empty for v1.0)
- [ ] **Alias table verified empty**: Confirms no active aliases in baseline version
- [ ] **Future alias planning noted**: Parameter renames (if anticipated) are documented in Open Items (Section 12)
- [ ] **Alias policy compliance**: Alias handling follows deprecation-alias-policy.md conventions

### 4. Governance Reviewers Confirmed
- [ ] **Product Owner sign-off**: Business semantics and economic correctness validated
  - Reviewer: ___________________ Date: ___________
- [ ] **Risk Reviewer sign-off**: Scenario coverage and stress calibration reviewed
  - Reviewer: ___________________ Date: ___________
- [ ] **Technical Reviewer sign-off**: Engine parity and naming conformity confirmed
  - Reviewer: ___________________ Date: ___________
- [ ] **Documentation Steward sign-off**: Metadata validity and alias oversight completed
  - Reviewer: ___________________ Date: ___________

### 5. Automation Lint Status
- [ ] **Metadata validation passing**: Front matter schema validation successful (if automation available)
- [ ] **Taxonomy linter passing**: No undefined or mismatched taxonomy codes detected
- [ ] **Memory logic validated**: Memory coupon accumulation logic reviewed for correctness
- [ ] **Alias linter passing**: No orphan legacy names or missing alias banner (if applicable)
- [ ] **Link integrity verified**: All internal document references resolve correctly

### 6. Documentation Review Completed
- [ ] **Documentation quality reviewed**: Clarity, completeness, and consistency validated
- [ ] **Parameter table complete**: Section 3 includes all input parameters with types, constraints, and defaults
- [ ] **Derived fields documented**: Section 4 enumerates all computed/derived fields (non-input)
- [ ] **Front matter complete**: All required front matter fields populated
- [ ] **Related documents linked**: Related ADRs, policies, and common definitions referenced
- [ ] **Changelog entry added**: Section 14 includes entry for this version

---

## Promotion Decision

**Recommendation**: [ ] Approve promotion to Proposed  [ ] Defer (specify blockers below)

**Blockers (if deferred)**:
- 

**Approver Comments**:


**Final Approval**:
- Name: ___________________
- Role: ___________________
- Date: ___________________

---

## Notes
- This checklist must be completed before the specification can be promoted from Draft to Proposed status
- All checklist items should be verified and marked complete
- Any blockers should be clearly documented with remediation plans
