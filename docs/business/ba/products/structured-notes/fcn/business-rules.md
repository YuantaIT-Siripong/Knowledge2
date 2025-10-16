---
title: FCN v1.1 Business Rules
doc_type: business-rule
status: Draft
version: 1.1.2
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-10
last_reviewed: 2025-10-16
next_review: 2026-04-10
classification: Internal
tags: [fcn, business-rules, structured-notes, validation, v1.1, capital-at-risk]
related:
  - specs/fcn-v1.0.md
  - specs/fcn-v1.1.0.md
  - er-fcn-v1.0.md
  - manifest.yaml
  - ../../sa/handoff/domain-handoff-fcn-v1.0.md
  - ../../sa/design-decisions/adr-003-fcn-version-activation.md
  - ../../sa/design-decisions/adr-004-parameter-alias-policy.md
  - ../../sa/design-decisions/dec-011-notional-precision.md
---

# FCN v1.1 Business Rules

## 1. Purpose
Defines the authoritative rule set for FCN v1.1: validation, lifecycle logic, calculation, data integrity, governance, and capital-at-risk settlement enhancements. Extends v1.0 by introducing put_strike_pct (BR-024), capital-at-risk settlement (BR-025), barrier monitoring type (BR-026), and autocall & issuer governance (BR-020–BR-023). BR-011 (legacy unconditional par recovery) deprecated.

## 2. Scope
- **Validation**: Structural / param constraints at booking.
- **Business Logic**: KI detection, coupon eligibility & amount, autocall, capital-at-risk settlement.
- **Data Integrity**: Basket & referential consistency.
- **Governance**: Versioning & coverage gates.
- **Precision**: Currency-driven numeric scale (DEC-011).
- **Monitoring**: Discrete monitoring normative (future continuous reserved).
- **Mapping**: JSON schema → business rules → data model → runtime artifacts.

## 3. Business Rules Table

| Rule ID | Category | Description | Source / Owner | Priority | Status | Normative Scope |
|---------|----------|-------------|----------------|----------|--------|-----------------|
| BR-001 | Validation | `trade_date ≤ issue_date < maturity_date` ordering | Spec fcn-v1.0.md §3 / BA | P0 | Draft | Yes |
| BR-002 | Validation | All `initial_levels` > 0 | Spec §3 / BA | P0 | Draft | Yes |
| BR-003 | Validation | `0 < knock_in_barrier_pct < put_strike_pct ≤ 1.0` (v1.1+); legacy ordering used redemption_barrier_pct | Spec §3 / BA | P0 | Draft | Yes |
| BR-004 | Validation | `documentation_version` equals active product version | Governance + Spec §3 / BA | P1 | Draft | Yes |
| BR-005 | KI Logic | KI triggers if ANY underlying close ≤ `initial × knock_in_barrier_pct` on observation date | Spec §5 / BA | P0 | Draft | Yes |
| BR-006 | Coupon Logic | Coupon condition: ALL closes ≥ `initial × coupon_condition_threshold_pct` | Spec §5 / BA | P0 | Draft | Yes |
| BR-007 | Observation | Each observation date processed exactly once (idempotent) | Domain Handoff §7 / SA | P0 | Draft | Yes |
| BR-008 | Coupon Logic | Memory accumulation capped by `memory_carry_cap_count` | Spec §3 & §5 / BA | P0 | Draft | Yes |
| BR-009 | Coupon Calc | `coupon_amount = notional_amount × coupon_rate_pct × (accrued_unpaid + 1)` | Spec §5 / BA | P0 | Draft | Yes |
| BR-010 | Coupon Timing | Payment date aligned by observation index → `coupon_payment_dates[i]` | Spec §3 / BA | P0 | Draft | Yes |
| BR-011 | Settlement | **DEPRECATED (v1.0 Legacy)**: Par recovery pays 100% notional at maturity regardless of KI | Spec §2, §5 / BA | P0 | Deprecated | No |
| BR-012 | Settlement | Proportional-loss illustrative (non-normative) | Spec §2 examples / BA | P2 | Draft | Non-Normative |
| BR-013 | Settlement | Final coupon eligibility independent of redemption calc | Spec §5 / BA | P1 | Draft | Yes |
| BR-014 | Validation | Observation dates strictly increasing & each < maturity_date | Spec §3 / BA | P0 | Draft | Yes |
| BR-015 | Validation | `underlying_symbols` length = `initial_levels` length | Spec §3 / BA | P0 | Draft | Yes |
| BR-016 | Data Integrity | Basket weights (if provided) sum to 1.0 else equal-weight inferred | Domain Handoff §7, ER §6 / SA | P1 | Draft | Yes |
| BR-017 | Governance | Normative test vector coverage gating Proposed → Active | ADR-003 / SA | P0 | Draft | Yes |
| BR-018 | Governance | Structural schema change requires new product version (alias policy) | ADR-004 / SA | P1 | Draft | Yes |
| BR-019 | Validation (Precision) | `notional_amount` precision policy (currency scale) | DEC-011 + Spec §3 / SA | P0 | Draft | Yes |
| BR-020 | Validation | `0 < knock_out_barrier_pct <= 1.30` when present | Spec v1.1.0 §3 / BA | P0 | Draft | Yes |
| BR-021 | Autocall Logic | Autocall: ALL underlyings ≥ `initial × knock_out_barrier_pct` → early redemption (principal + due coupon) | Spec v1.1.0 §4 / BA | P0 | Draft | Yes |
| BR-022 | Governance (Issuer) | `issuer` must exist in approved issuer whitelist | Spec v1.1.0 §3 / BA | P1 | Draft | Yes |
| BR-023 | Business Logic | Autocall precedence before coupon / KI; coupon condition independent of KO barrier | Spec v1.1.0 §4 / BA | P0 | Draft | Yes |
| BR-024 | Validation | `0 < put_strike_pct ≤ 1.0` and `knock_in_barrier_pct < put_strike_pct` | Spec v1.1.0 §3 / BA | P0 | Draft | Yes |
| BR-025 | Settlement (Capital-at-Risk) | Maturity: if KI AND worst_of_final_ratio < put_strike_pct → proportional loss; else par redemption | Spec v1.1.0 §5 / BA | P0 | Draft | Yes |
| BR-026 | Validation / Monitoring | `barrier_monitoring_type` in ['discrete','continuous']; only 'discrete' normative v1.1 | Spec v1.1.0 §3 | P1 | Draft | Yes |

### 3.1 Notes
- BR-011 deprecated and excluded from normative coverage metrics (legacy v1.0 trades only).
- BR-024–026 introduce capital-at-risk settlement & monitoring extensibility.
- Continuous monitoring reserved (non-normative) until future version (target v1.2+).

## 4. Rule Categories
- **Validation**: BR-001–004, 014, 015, 019, 020, 024, 026
- **Business Logic**: BR-005–010, 013, 021, 023, 025 (BR-011 deprecated, BR-012 non-norm)
- **Data Integrity**: BR-016
- **Governance**: BR-017–018, 022
- **Precision**: BR-019
- **Autocall**: BR-021, BR-023
- **Capital-at-Risk**: BR-024, BR-025, BR-026

## 5. Implementation Mapping
(unchanged from previous version – updated to include put_strike_pct & barrier_monitoring_type.)

## 6. Rule–Schema–Data Mapping
(Refer to mapping table in existing body; unchanged except added rows for put_strike_pct, barrier_monitoring_type.)

## 7. Traceability Matrix
(Updated: BR-024–026 entries included; BR-011 marked legacy.)

## 8. Validation Strategy
Phases unchanged. Phase 4 will implement BR-025 & precedence tests once logic validator completed.

## 9. Open Questions
(OQ list unchanged; add OQ-BR-005, OQ-BR-006, OQ-BR-007 as previously documented.)

## Naming Note
Canonical parameter: `notional_amount`; capital-at-risk threshold: `put_strike_pct`.

## 10. Change Log
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-10 | siripong.s | Initial rules BR-001–BR-018 |
| 1.0.1 | 2025-10-10 | siripong.s | Added BR-019 (precision) |
| 1.0.2 | 2025-10-10 | siripong.s | Mapping & coverage metrics enhancements |
| 1.0.3 | 2025-10-10 | copilot | Hygiene & canonical naming |
| 1.1.0 | 2025-10-16 | copilot | Added BR-020–BR-023 (autocall, issuer, precedence) |
| 1.1.1 | 2025-10-16 | copilot | Added BR-024–BR-026 (capital-at-risk, monitoring); deprecated BR-011; front matter alignment fix |
| 1.1.2 | 2025-10-16 | copilot | Documentation adjustments: updated schema description, deprecated barrier_monitoring field, integrated activation checklist reference, added alias register reference; no rule logic changes |

## 11. References
- [FCN v1.0 Specification](specs/fcn-v1.0.md)
- [FCN v1.1.0 Specification](specs/fcn-v1.1.0.md)
- [FCN v1.1.0 Activation Checklist](specs/_activation-checklist-v1.1.0.md)
- [Alias Register](alias-register.md)
- [Entity-Relationship Model](er-fcn-v1.0.md)
- [Product Manifest](manifest.yaml)
- [ADR-003 Version Activation](../../sa/design-decisions/adr-003-fcn-version-activation.md)
- [ADR-004 Parameter Alias Policy](../../sa/design-decisions/adr-004-parameter-alias-policy.md)
- [DEC-011 Notional Precision](../../sa/design-decisions/dec-011-notional-precision.md)
