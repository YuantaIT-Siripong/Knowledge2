---
title: FCN v1.0 Overview & KPI Baselines
doc_type: overview
status: Draft
version: 1.0.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-10
last_reviewed: 2025-10-10
next_review: 2026-01-10
classification: Internal
tags: [fcn, overview, kpi, governance, structured-notes, v1.0]
related:
  - specs/fcn-v1.0.md
  - business-rules.md
  - er-fcn-v1.0.md
  - ../../sa/handoff/domain-handoff-fcn-v1.0.md
  - ../../sa/design-decisions/adr-003-fcn-version-activation.md
  - ../../sa/design-decisions/adr-004-parameter-alias-policy.md
  - ../../sa/design-decisions/dec-011-notional-precision.md
  - ../../sa/design-decisions/dec-011-notional-precision.md
---

# 1. Product Summary

Fixed Coupon Note (FCN) v1.0 baseline defines a structured note paying periodic fixed coupons conditional on underlying performance (discrete observation dates). Knock-in (KI) monitoring determines protective vs. example (non-normative) settlement behavior. This overview consolidates domain context and establishes KPI baselines used by governance (ADR-003) to evaluate readiness for promotion (Draft → Proposed → Active).

# 2. Objectives

1. Provide a single accessible synopsis for stakeholders (Product, Risk, Engineering).
2. Establish measurable KPI baselines for continuous improvement.
3. Link KPIs to normative rules (e.g., BR-017 coverage, BR-019 precision) ensuring traceability.
4. Enable earlier detection of specification or parameter quality regressions.

# 3. Stakeholders (Summary)

| Role | Responsibility Focus | Primary Contact |
|------|----------------------|-----------------|
| Product Owner | Feature scope & commercial prioritization | siripong.s@yuanta.co.th |
| Business Analyst | Specification integrity & rules traceability | siripong.s@yuanta.co.th |
| Solution Architect | Integration & lifecycle design | siripong.s@yuanta.co.th |
| Risk Manager | Scenario / stress assumptions validation | risk@yuanta.co.th |
| Compliance Officer | Regulatory record & audit alignment | compliance@yuanta.co.th |
| QA Engineer | Test vector & functional coverage | qa@yuanta.co.th |
| Data Engineer | Data ingestion & lineage | data-engineering@yuanta.co.th |
| Operations (Middle Office) | Post-trade events & reconciliation | operations@yuanta.co.th |
| Trader (Front Office) | Trade entry accuracy | trading@yuanta.co.th |
| Backend Engineer | Services & validation logic implementation | engineering@yuanta.co.th |

(Full detail lives in stakeholders.md.)

# 4. Document Inventory (Selected)

| Artifact | Purpose | Status | Link |
|----------|---------|--------|------|
| Specification (specs/fcn-v1.0.md) | Parameter & payoff definition | Draft | specs/fcn-v1.0.md |
| Business Rules (business-rules.md) | Rules BR-001..BR-019 | Draft | business-rules.md |
| ER Model (er-fcn-v1.0.md) | Logical data representation | Draft | er-fcn-v1.0.md |
| Domain Handoff | SA consumption package | Draft | ../../sa/handoff/domain-handoff-fcn-v1.0.md |
| ADR-003 | Version activation workflow | Approved | ../../sa/design-decisions/adr-003-fcn-version-activation.md |
| ADR-004 | Alias & deprecation policy | Approved | ../../sa/design-decisions/adr-004-parameter-alias-policy.md |
| DEC-011 | Notional precision decision | Approved | ../../sa/design-decisions/dec-011-notional-precision.md |
| Test Vectors | Normative coverage set | In Progress | test-vectors/ |

# 5. KPI Baselines

## 5.1 KPI Table

| KPI | Baseline | Target (v1.0 Active Gate) | Owner | Measurement Method | Tool / Source | Frequency |
|-----|----------|---------------------------|-------|--------------------|---------------|-----------|
| Time-to-Launch (Spec Approval → Production Readiness) | 90 days | 60 days (v1.1 improvement goal) | Product Owner | Timestamp delta (spec approval vs. readiness checklist pass) | Governance checklist (ADR-003) | Per release |
| Parameter Error Rate | 5% | < 2% | QA Engineer | Failed parameter validations / total validation attempts (rolling 30d) | parameter_validator.py (BR-001–004, 014, 015, 019) | Daily CI |
| Data Completeness (Normative Branch Coverage) | 60% | ≥ 80% | Business Analyst | (# normative branches with full test vectors) / (total normative branches) | coverage_validator.py (BR-017 gating) | Per commit & Release |
| Rule Mapping Coverage | 95% | 100% | Business Analyst | Mapped rules / total normative rules | mapping_report.json (schema-rule scan) | Weekly |
| Precision Conformance (Notional) | 98% | 100% | Solution Architect | Valid precision payloads / total payloads | precision_audit.log (BR-019) | Daily |
| Observation Idempotency Incidents | N/A (new) | 0 | Operations | Duplicate observation process attempts | lifecycle_engine logs (BR-007) | Real-time alert |
| Test Vector Freshness (Avg Age) | 45 days | ≤ 30 days | QA Engineer | Mean days since last vector update (normative set) | repo metadata + CI report | Weekly |

## 5.2 KPI Definitions

- Parameter Error Rate: Only counts violations against normative validation rules (BR-001–004, BR-014, BR-015, BR-019). Governance or non-normative examples excluded.
- Data Completeness: Normative branch definition per taxonomy finalization; excludes non-normative (e.g., proportional-loss).
- Rule Mapping Coverage: Ensures each rule appears in at least one of: schema path mapping OR derived logic descriptor.
- Precision Conformance: Enforces DEC-011 currency-aware scale before persistence.

## 5.3 KPI Dependencies

| KPI | Dependent Rules / Decisions | Blocking Artifact |
|-----|-----------------------------|-------------------|
| Parameter Error Rate | BR-001..004, 014, 015, 019 | parameter_validator.py |
| Data Completeness | BR-017 | Test vectors set |
| Precision Conformance | BR-019 / DEC-011 | precision checker |
| Observation Idempotency | BR-007 | lifecycle processing design |
| Rule Mapping Coverage | BR-001..019 | mapping extraction script |
| Test Vector Freshness | BR-017 | CI coverage metadata |
| Time-to-Launch | ADR-003, ADR-004 | Activation checklist |

# 6. Reporting & Dashboard

Phased rollout:
1. Phase A (Current): Raw JSON artifacts (param-validation.json, coverage_report.json, precision_audit.log).
2. Phase B (Upcoming): Aggregation job producing kpi-snapshot.json (daily).
3. Phase C (Future): Grafana / Looker dashboards with historical trend lines & SLA threshold coloration.

Data retention for KPI snapshots follows DEC-011 storage tiers for alignment with audit expectations.

# 7. Governance Integration

- Promotion Gate (Proposed → Active) requires:
  - Data Completeness ≥ Target (BR-017)
  - Parameter Error Rate < Target
  - Precision Conformance = 100%
- Regression triggers automatic “Needs Review” flag if:
  - Parameter Error Rate ≥ Baseline × 1.5 for two consecutive days
  - Data Completeness drops >10 percentage points week-over-week
  - Any P0 rule loses mapping coverage

# 8. Continuous Improvement Backlog

| Ref | Improvement | KPI Impact | Priority | Owner |
|-----|------------|-----------|----------|-------|
| IMP-01 | Automate rule → schema diff check in CI | Rule Mapping Coverage | P1 | BA |
| IMP-02 | Add precision validator to pre-commit hook | Precision Conformance | P2 | SA |
| IMP-03 | Generate synthetic vectors for edge coupon memory cases | Data Completeness | P1 | QA |
| IMP-04 | Add lifecycle idempotency audit job | Observation Idempotency | P2 | Ops |
| IMP-05 | Introduce KPI trend anomaly detection (EWMA) | All (early drift) | P2 | Data Eng |

# 9. Risks & Mitigations

| Risk | Category | Mitigation |
|------|----------|------------|
| Underestimated branch explosion delaying coverage | Delivery | Enforce early taxonomy freeze (ADR-003 Stage) |
| Hidden precision drift in downstream rounding | Data Quality | BR-019 strict ingress validation + nightly reconciliation |
| Idempotency gaps causing duplicate coupon logic | Operational | Introduce unique index (observation_id, trade_id) OR application lock (decide OQ-BR-002) |
| Over-complex KPI set diluting focus | Process | Quarterly pruning—drop KPIs without decision utility |

# 10. Open Questions

| ID | Question | Dependency | Owner | Target |
|----|----------|-----------|-------|--------|
| OQ-KPI-001 | Should Time-to-Launch exclude governance drafting time? | ADR-003 metrics scope | Product | Week 2 |
| OQ-KPI-002 | Do we snapshot KPI data before or after nightly ETL? | Data completeness accuracy | Data Eng | Week 1 |
| OQ-KPI-003 | SLA thresholds for alerting (warn vs critical) | Dashboard design | BA + Ops | Week 3 |

# 11. Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-10 | siripong.s@yuanta.co.th | Initial overview & KPI baselines established |

# 12. References

- [FCN v1.0 Specification](specs/fcn-v1.0.md)
- [Business Rules](business-rules.md)
- [Entity-Relationship Model](er-fcn-v1.0.md)
- [Domain Handoff](../../sa/handoff/domain-handoff-fcn-v1.0.md)
- [ADR-003 Version Activation & Promotion](../../sa/design-decisions/adr-003-fcn-version-activation.md)
- [ADR-004 Parameter Alias & Deprecation Policy](../../sa/design-decisions/adr-004-parameter-alias-policy.md)
- [DEC-011 Notional Precision Policy](../../sa/design-decisions/dec-011-notional-precision.md)
- KPI Scripts (parameter_validator.py, coverage_validator.py, precision audit utilities)
