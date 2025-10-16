----
````markdown name=_activation-checklist-v1.1.0.md
---
title: FCN v1.1.0 Activation Checklist
doc_type: activation-checklist
status: Draft
version: 1.1.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-16
last_reviewed: 2025-10-16
next_review: 2025-11-01
classification: Internal
tags: [fcn, activation, governance, checklist, v1.1]
related:
  - ../business-rules.md
  - ../manifest.yaml
  - fcn-v1.1.0.md
  - ../schema-diff-v1.0-to-v1.1.md
  - ../../../../sa/design-decisions/adr-003-fcn-version-activation.md
  - ../../../../sa/design-decisions/adr-004-parameter-alias-policy.md
  - ../../../../sa/design-decisions/dec-011-notional-precision.md
---

# FCN v1.1.0 Activation Checklist

Purpose: Formal gating list for promoting FCN v1.1.0 from Proposed → Active. All P0 and P1 items MUST be completed or explicitly waived (with rationale) before status change.

## 1. Scope Summary
- Enhancements: Autocall (BR-020–021), Issuer Governance (BR-022), Precedence Clarification (BR-023), Capital-at-Risk Settlement (BR-024–025), Barrier Monitoring Type (BR-026)
- Deprecations: Legacy par recovery (BR-011), redemption_barrier_pct payoff role (reserved), barrier_monitoring legacy alias (deprecated)

## 2. Readiness Matrix
| Ref | Category | Item | Rule(s) / Artifact | Priority | Owner | Status | Evidence Link |
|-----|----------|------|--------------------|----------|-------|--------|---------------|
| R-001 | Rules | All normative rules implemented (BR-001–010,013,016–026 excl BR-011 & BR-012) | business-rules.md | P0 | BA | Pending |  |
| R-002 | Schema | v1.1.0 parameter schema published & validated | fcn-v1.1.0-parameters.schema.json | P0 | SA | Pending |  |
| R-003 | Schema | put_strike_pct ordering enforced (DB + validator strategy documented) | BR-024 | P0 | SA | Pending |  |
| R-004 | Migration | m0002 & m0003 dry-run executed in staging | migrations/m0002, m0003 | P0 | DevOps | Pending |  |
| R-005 | Migration | Backward compatibility smoke (v1.0 trades load OK) | Schema Diff §7 | P0 | QA | Pending |  |
| R-006 | Coverage | Normative test vector coverage ≥80% branches | BR-017 | P0 | QA | Pending | coverage_report.json |
| R-007 | Coverage | Each normative rule mapped to ≥1 test vector | BR-017 | P0 | QA | Pending | mapping_report.json |
| R-008 | KPI | Parameter Error Rate < 2% (rolling 7d) | KPIs | P0 | QA | Pending | param-validation.json |
| R-009 | KPI | Precision Conformance = 100% (rolling 7d) | BR-019 | P0 | QA | Pending | precision_audit.log |
| R-010 | KPI | Data Completeness ≥80% normative branches | BR-017 | P0 | BA | Pending | coverage_report.json |
| R-011 | Governance | Issuer whitelist process documented & audited | BR-022 | P0 | Risk | Pending | issuer_whitelist.md |
| R-012 | Governance | Alias/deprecation register updated (BR-011, redemption_barrier_pct, barrier_monitoring) | ADR-004 | P1 | BA | Pending | alias-register.md |
| R-013 | Observability | Rule failure events emit ERR_FCN_BR_* codes | business-rules §5 | P1 | Eng | Pending | log sample |
| R-014 | Logic | Autocall precedence test vectors pass (KO before coupon/KI) | BR-021, BR-023 | P0 | QA | Pending | test run report |
| R-015 | Logic | Capital-at-risk loss & no-loss vectors pass | BR-025 | P0 | QA | Pending | test run report |
| R-016 | Security | Migration scripts reviewed for injection/DDL safety | m0002,m0003 | P1 | SecEng | Pending | review ticket |
| R-017 | Data | Worst-of final ratio derived field spec documented | BR-025 | P1 | BA | Pending | data-dictionary.md |
| R-018 | Ops | Runbook updated (autocall + cap-at-risk flows) | Runbook | P1 | Ops | Pending | runbook.md |
| R-019 | Docs | Activation checklist PR approved | This file | P0 | Approver | Pending | PR link |
| R-020 | Sign-off | Product sign-off recorded | ADR-003 | P0 | Product | Pending | signoff.md |
| R-021 | Sign-off | Risk sign-off recorded | ADR-003 | P0 | Risk | Pending | signoff.md |
| R-022 | Sign-off | Compliance sign-off recorded | ADR-003 | P0 | Compliance | Pending | signoff.md |
| R-023 | Sign-off | Engineering sign-off recorded | ADR-003 | P0 | Eng Lead | Pending | signoff.md |
| R-024 | Sign-off | QA sign-off recorded | ADR-003 | P0 | QA Lead | Pending | signoff.md |
| R-025 | Post-Activation | Monitoring alert thresholds configured (KPI drift) | KPIs §7 | P1 | BA+Ops | Pending | monitoring-config.yaml |

## 3. Test Vector Coverage Targets
- Capital-at-Risk: ≥ 1 loss, ≥1 no-loss, ≥1 autocall-preempt scenario
- Memory Feature: accrual + release under capital-at-risk
- Autocall Edge: early, near-miss, late trigger

## 4. Risk Mitigations Verification
| Risk | Mitigation | Verification Method | Status |
|------|-----------|---------------------|--------|
| Mis-calculated worst_of_final_ratio | Unit tests + QA vectors | Calculation unit test suite | Pending |
| Incomplete issuer whitelist | Governance workflow & audit trail | Checklist review | Pending |
| Ordering constraint bypass | DB constraint + validator warning | Staging DDL inspect | Pending |

## 5. Deviation / Waiver Log
| ID | Item | Deviation | Rationale | Approved By | Date |
|----|------|----------|-----------|------------|------|
| W-001 | (example) |  |  |  |  |

## 6. Sign-Off Summary
All P0 items MUST be Complete before signature.

| Role | Name | Date | Status | Comments |
|------|------|------|--------|----------|
| Product |  |  |  |  |
| Risk |  |  |  |  |
| Compliance |  |  |  |  |
| Engineering Lead |  |  |  |  |
| QA Lead |  |  |  |  |
| Operations |  |  |  |  |

## 7. Change Log
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.1.0 | 2025-10-16 | copilot | Initial activation checklist draft |

## 8. References
- Business Rules (BR-024–026) capital-at-risk scope
- KPI definitions (overview.md)
- Manifest (branches & migrations)
- Schema diff
- ADR-003 (Activation Workflow)
- ADR-004 (Alias & Deprecation Policy)
- DEC-011 (Precision Policy)
```