---
title: FCN v1.0 Domain Overview
doc_type: product-overview
role_primary: BA
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
status: Draft
version: 1.0.0
created: 2025-10-10
last_reviewed: 2025-10-10
next_review: 2026-04-10
classification: Internal
tags: [structured-notes, fcn, product-overview, v1.0, kpi]
related:
  - specs/fcn-v1.0.md
  - validator-roadmap.md
  - er-fcn-v1.0.md
  - manifest.yaml
  - ../../common/governance.md
  - ../../../sa/design-decisions/adr-003-fcn-version-activation.md
---

# FCN v1.0 Domain Overview

## 1. Purpose

This document provides a high-level overview of the Fixed Coupon Note (FCN) v1.0 domain, including its scope, key features, stakeholders, and Key Performance Indicators (KPIs) for domain governance and operational excellence.

## 2. Product Summary

The Fixed Coupon Note (FCN) v1.0 is a multi-underlying structured note paying periodic fixed coupons contingent on barrier conditions and offering conditional principal protection unless a knock-in (KI) event occurs. The baseline v1.0 specification covers:

- Single or basket (equal-weight) underlying support
- Memory coupon feature (optional)
- Down-in (knock-in) barrier monitored on discrete observation dates
- Physical settlement with par-recovery mode (normative)
- No step-down/step-up barrier schedules (deferred to v1.1+)

**Current Status:** Draft  
**Specification Version:** 1.0.0  
**Target Activation:** Q2 2026

## 3. Key Stakeholders

| Role | Responsibilities | Owner/Contact |
|------|------------------|---------------|
| Product Owner | Defines economic behavior, approves specification | siripong.s@yuanta.co.th |
| Business Analyst | Documents requirements, validates test vectors | siripong.s@yuanta.co.th |
| Solution Architect | Designs API & data model, defines integration | siripong.s@yuanta.co.th |
| Backend Engineer | Implements pricing engine & lifecycle processing | TBD |
| QA Engineer | Validates test coverage & regression suite | TBD |
| Data Engineer | Implements persistence & reporting pipelines | TBD |

## 4. Document Inventory

### Specifications
- **[fcn-v1.0.md](specs/fcn-v1.0.md)**: Normative product specification including parameters, taxonomy, and payoff logic
- **[manifest.yaml](manifest.yaml)**: Product configuration and branch taxonomy definitions

### Technical Documentation
- **[er-fcn-v1.0.md](er-fcn-v1.0.md)**: Logical entity-relationship model for data persistence
- **[validator-roadmap.md](validator-roadmap.md)**: Phased validation and governance roadmap
- **[validators/README.md](validators/README.md)**: Automated validator implementation guide

### Test Artifacts
- **test-vectors/**: Normative test vector set for validation and regression testing
- **schemas/**: JSON Schema definitions for parameter validation

## 5. Key Performance Indicators (KPIs)

### 5.1 Time-to-Launch

**Definition:** Elapsed time from specification approval (status = Active) to production deployment readiness.

**Baseline Value:** 90 days  
**Target Value:** 60 days (v1.1+)  
**Measurement Frequency:** Per version release  
**Owner:** siripong.s@yuanta.co.th  
**Measurement Method:** Time between spec `status: Active` and activation checklist completion

**Tracking Notes:**
- Start: Date when specification status changes to "Active" in YAML front matter
- End: Date when all activation checklist items are completed and signed off
- Includes: Requirements finalization, test vector development, validator implementation, integration testing

---

### 5.2 Parameter Error Rate

**Definition:** Percentage of test vectors or trades that fail parameter validation due to constraint violations.

**Baseline Value:** 5%  
**Target Value:** <2% (production readiness threshold)  
**Measurement Frequency:** Per validation run (daily in CI)  
**Owner:** siripong.s@yuanta.co.th  
**Measurement Method:** (Failed validations / Total validations) × 100

**Validation Scope:**
- Required parameter presence
- Parameter value ranges and constraints
- Logical relationships between parameters
- Enumeration value conformance
- JSON Schema compliance

**Tracking Notes:**
- Measured via `parameter_validator.py` (Phase 2 validator)
- Reported in `param-validation.json` output
- Excludes intentional negative test cases tagged with `error-case`

---

### 5.3 Data Completeness

**Definition:** Percentage of branches in the taxonomy that have complete normative test vector coverage.

**Baseline Value:** 60%  
**Target Value:** ≥80% (required for production readiness per ADR-003)  
**Measurement Frequency:** Per validation run (daily in CI)  
**Owner:** siripong.s@yuanta.co.th  
**Measurement Method:** (Branches with complete normative vectors / Total branches) × 100

**Completeness Criteria (per branch):**
- Minimum 1 normative test vector per branch
- Required tags present: `baseline`, `edge`, `ki-event`
- All normative vectors pass expected output validation
- Test vector metadata complete and valid

**Tracking Notes:**
- Measured via `coverage_validator.py` (Phase 3 validator)
- Current branches defined in `manifest.yaml`
- Coverage matrix reported in `validation-summary.md`

---

## 6. KPI Dashboard & Reporting

### Current Measurement Tools
- **metadata_validator.py**: Phase 0 - Document structure and metadata completeness
- **taxonomy_validator.py**: Phase 1 - Branch taxonomy consistency
- **parameter_validator.py**: Phase 2 - Parameter constraint validation
- **coverage_validator.py**: Phase 3 - Test vector coverage measurement

### Reporting Outputs
1. **validation-summary.md**: Aggregated KPI status per validation phase
2. **coverage-matrix.html**: Visual heatmap of branch coverage
3. **param-validation.json**: Parameter error details and trends
4. **metadata-validation.json**: Document completeness status

### Dashboard Location (Planned)
TBD - Integration with CI/CD pipeline reporting dashboard

## 7. Success Criteria

**For Proposed → Active Promotion:**
- ✅ All Phase 0–2 validators passing
- ✅ Minimum 1 normative vector per branch
- ✅ No P0 violations in CI
- ✅ Parameter Error Rate ≤5%

**For Production Readiness:**
- ✅ All Phase 0–4 validators passing
- ✅ Data Completeness ≥80%
- ✅ Parameter Error Rate <2%
- ✅ Time-to-Launch documented and baseline established
- ✅ All normative vectors passing expected output validation
- ✅ Activation checklist completed and linked

## 8. Continuous Improvement

### Review Cycle
- **KPI Baselines:** Reviewed quarterly
- **Target Values:** Adjusted based on 2+ release cycles of historical data
- **Measurement Methods:** Validated against actual implementation experience

### Future Enhancements
- Automated KPI dashboard with trend visualization
- Real-time parameter error rate monitoring in production
- Comparative analysis across product versions (v1.0 vs v1.1+)
- Integration with trade booking system for production error tracking

## 9. Open Items

- [ ] Finalize backend engineer assignment for implementation KPI tracking
- [ ] Define production error rate measurement approach post-launch
- [ ] Establish KPI dashboard tooling and visualization platform
- [ ] Integrate KPI metrics with CI/CD pipeline reporting

## 10. Related Documentation

- **Governance:** [common/governance.md](../../common/governance.md)
- **Activation Requirements:** [ADR-003](../../../sa/design-decisions/adr-003-fcn-version-activation.md)
- **Validator Implementation:** [validators/README.md](validators/README.md)
- **Domain Handoff:** [domain-handoff-fcn-v1.0.md](../../../sa/handoff/domain-handoff-fcn-v1.0.md)

## 11. Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-10 | siripong.s@yuanta.co.th | Initial overview document with KPI baselines defined |
