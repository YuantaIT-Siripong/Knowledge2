---
title: FCN v1.0 Business Rules
doc_type: business-rule
status: Draft
version: 1.0.3
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-10
last_reviewed: 2025-10-10
next_review: 2026-04-10
classification: Internal
tags: [fcn, business-rules, structured-notes, validation, v1.0]
related:
  - specs/fcn-v1.0.md
  - er-fcn-v1.0.md
  - manifest.yaml
  - ../../sa/handoff/domain-handoff-fcn-v1.0.md
  - ../../sa/design-decisions/adr-003-fcn-version-activation.md
  - ../../sa/design-decisions/adr-004-parameter-alias-policy.md
  - ../../sa/design-decisions/dec-011-notional-precision.md
---

# FCN v1.0 Business Rules

## 1. Purpose
Defines the authoritative rule set for FCN v1.0: validation, lifecycle logic, calculation, data integrity, and governance. Each rule includes source and owner for auditability and to support API, data model, validator, and lifecycle implementation.

## 2. Scope
- **Validation**: Structural / param constraints at booking.
- **Business Logic**: KI detection, coupon eligibility & amount, settlement.
- **Data Integrity**: Basket & referential consistency.
- **Governance**: Versioning & coverage gates.
- **Precision**: Currency-driven numeric scale (DEC-011).
- **Mapping**: End-to-end linkage from JSON schema → business rules → data model → runtime artifacts.

## 3. Business Rules Table

| Rule ID | Category | Description | Source / Owner | Priority | Status | Normative Scope |
|---------|----------|-------------|----------------|----------|--------|-----------------|
| BR-001 | Validation | `trade_date ≤ issue_date < maturity_date` ordering | Spec fcn-v1.0.md §3 / BA | P0 | Draft | Yes |
| BR-002 | Validation | All `initial_levels` > 0 | Spec §3 / BA | P0 | Draft | Yes |
| BR-003 | Validation | `0 < knock_in_barrier_pct < redemption_barrier_pct ≤ 1.0` | Spec §3 / BA | P0 | Draft | Yes |
| BR-004 | Validation | `documentation_version` equals active product version | Governance + Spec §3 / BA | P1 | Draft | Yes |
| BR-005 | KI Logic | KI triggers if ANY underlying close ≤ `initial × knock_in_barrier_pct` on obs date | Spec §5 / BA | P0 | Draft | Yes |
| BR-006 | Coupon Logic | Coupon condition: ALL closes ≥ `initial × coupon_condition_threshold_pct` | Spec §5 / BA | P0 | Draft | Yes |
| BR-007 | Observation | Each observation date processed exactly once (idempotent) | Domain Handoff §7 / SA | P0 | Draft | Yes |
| BR-008 | Coupon Logic | Memory accumulation capped by `memory_carry_cap_count` | Spec §3 & §5 / BA | P0 | Draft | Yes |
| BR-009 | Coupon Calc | `coupon_amount = notional_amount × coupon_rate_pct × (accrued_unpaid + 1)` | Spec §5 / BA | P0 | Draft | Yes |
| BR-010 | Coupon Timing | Payment date aligned by observation index → `coupon_payment_dates[i]` | Spec §3 / BA | P0 | Draft | Yes |
| BR-011 | Settlement | Par recovery pays 100% notional_amount at maturity regardless of KI | Spec §2, §5 / BA | P0 | Draft | Yes |
| BR-012 | Settlement | Proportional-loss (example only) delivers underlying units (non-normative) | Spec §2 (examples) / BA | P2 | Draft | Non-Normative |
| BR-013 | Settlement | Final coupon eligibility independent of redemption calc | Spec §5 / BA | P1 | Draft | Yes |
| BR-014 | Validation | Observation dates strictly increasing & each < maturity_date | Spec §3 / BA | P0 | Draft | Yes |
| BR-015 | Validation | `underlying_symbols` length = `initial_levels` length | Spec §3 / BA | P0 | Draft | Yes |
| BR-016 | Data Integrity | Basket weights (if provided) sum to 1.0 else equal-weight inferred | Domain Handoff §7, ER §6 / SA | P1 | Draft | Yes |
| BR-017 | Governance | Normative test vector coverage needed for Proposed → Active | ADR-003 / SA | P0 | Draft | Yes |
| BR-018 | Governance | Structural schema change requires new product version (alias policy) | ADR-004 / SA | P1 | Draft | Yes |
| BR-019 | Validation (Precision) | notional_amount precision: scale ≤2 (fractional), scale=0 (zero-decimal set) & >0 | DEC-011 + Spec §3 / SA | P0 | Draft | Yes |

### 3.1 Notes
- BR-012 is illustrative; excluded from v1.0 normative production flow.
- BR-019 supersedes earlier informal precision wording.

## 4. Rule Categories
(See table above for membership.)
- **Validation**: BR-001–004, 014, 015, 019
- **Business Logic**: BR-005–013 (BR-012 non-normative)
- **Data Integrity**: BR-016
- **Governance**: BR-017–018
- **Precision**: BR-019

## 5. Implementation Mapping

| Layer | Guidance |
|-------|----------|
| API / Ingress | JSON Schema + custom cross-field checks (ordering, relational inequalities, precision) |
| Domain Services | Lifecycle engine (KI, coupon, settlement); memory accumulator respecting cap |
| Persistence | CHECK constraints (ordering, barrier relation, scale), unique/composite for observation idempotency |
| Validation Scripts | Parameter validator implements BR-001–004, 014, 015, 019 early; logic validator later |
| Observability | Emit `rule.validation.failure` with `rule_id`, pointer, severity |
| Error Codes | Format: `ERR_FCN_<rule_id>` (e.g. BR-003 → ERR_FCN_BR_003) |

## 6. Rule–Schema–Data Mapping

| JSON Schema Field / Derived | Data Model Entity.Attribute | Rule IDs | Normative? | Enforcement Layer(s) | Notes |
|-----------------------------|-----------------------------|---------|-----------|----------------------|-------|
| trade_date | Trade.trade_date | BR-001 | Yes | API, DB | Ordering chain |
| issue_date | Trade.issue_date | BR-001 | Yes | API, DB |  |
| maturity_date | Trade.maturity_date | BR-001 | Yes | API, DB |  |
| initial_levels[] | Underlying_Asset.initial_level | BR-002, BR-015 | Yes | API, DB | Positive; length sync |
| underlying_symbols[] | Underlying_Asset.symbol | BR-015 | Yes | API, DB | Distinct; align lengths |
| knock_in_barrier_pct | Trade.knock_in_barrier_pct | BR-003, BR-005 | Yes | API, DB | Range + KI logic |
| redemption_barrier_pct | Trade.redemption_barrier_pct | BR-003 | Yes | API, DB | Upper bound relation |
| coupon_condition_threshold_pct | Trade.coupon_condition_threshold_pct | BR-006 | Yes | API | Level check factor |
| observation_dates[] | Observation.observation_date | BR-007, BR-014 | Yes | API, DB, Logic | Idempotency + ordering |
| coupon_payment_dates[] | Coupon_Decision.payment_date | BR-010 | Yes | API | Cardinality matches obs |
| memory_carry_cap_count | Coupon_Decision.memory_carry_cap_count | BR-008 | Yes | API | Conditional presence |
| is_memory_coupon (if present) | Trade.is_memory_coupon | BR-008, BR-009 | Yes | API | Drives accumulation path |
| coupon_rate_pct | Trade.coupon_rate_pct | BR-009 | Yes | API | >0 |
| notional_amount | Trade.notional | BR-009, BR-019 | Yes | API, DB | Parameter key vs DB column (`notional`) |
| currency | Trade.currency | BR-019 | Yes | API, DB | Determines scale policy |
| recovery_mode | Trade.recovery_mode | BR-011, BR-012 | Mixed | API | par normative; proportional non-norm |
| settlement_type | Trade.settlement_type | BR-012 | Non-Norm | API | Example only initially |
| basket_weights[] | Underlying_Asset.weight | BR-016 | Yes | API, DB | Optional sum=1.0 |
| documentation_version | Trade.documentation_version | BR-004, BR-018 | Yes | API | Governance alignment |
| accrued_unpaid (derived) | Coupon_Decision.accrued_unpaid | BR-008, BR-009 | Yes | Logic | Runtime state |
| coupon_amount (derived) | Coupon_Decision.coupon_amount | BR-009 | Yes | Logic | Calculated payout |
| ki_triggered (derived) | Trade.ki_triggered_flag | BR-005 | Yes | Logic | Event flag |
| version metadata | Product_Version.version_id | BR-018 | Yes | Governance | Promotion gate |
| test vector metadata | Test_Vector.coverage_map | BR-017 | Yes | CI / Governance | Coverage gating |

### 6.1 Coverage Metrics

| Metric | Current (est.) | Target | Definition |
|--------|----------------|--------|------------|
| Schema fields mapped → rule(s) | 100% | 100% | Schema fields with ≥1 rule link |
| Rules with schema or derived mapping | 100% | 100% | Each rule mapped to schema path or derived field |
| Normative rules with test vector linkage | 90% | 100% | BR-005–013 (excl. 012) + all validation rules |
| Governance rules automated checks | 50% | 100% | BR-017, BR-018 CI enforcement |

## 7. Traceability Matrix

| Rule ID | Source Section | ER Entity(Attributes) | JSON Schema Path(s) | Test Vector(s) |
|---------|----------------|-----------------------|--------------------|----------------|
| BR-001 | Spec §3 | Trade(trade_date, issue_date, maturity_date) | /trade_date /issue_date /maturity_date | All normative |
| BR-002 | Spec §3 | Underlying_Asset(initial_level) | /initial_levels/items | All normative |
| BR-003 | Spec §3 | Trade(knock_in_barrier_pct, redemption_barrier_pct) | /knock_in_barrier_pct /redemption_barrier_pct | All normative |
| BR-004 | Spec §3 | Trade(documentation_version) | /documentation_version | All normative |
| BR-005 | Spec §5 | Observation, Trade(ki_triggered) | (derived) | KI event vector |
| BR-006 | Spec §5 | Coupon_Decision(condition_satisfied) | (derived) | Baseline, single-miss |
| BR-007 | Domain Handoff §7 | Observation(is_processed) | (derived) | All normative |
| BR-008 | Spec §3, §5 | Coupon_Decision(accrued_unpaid) | /memory_carry_cap_count | Memory baseline |
| BR-009 | Spec §5 | Coupon_Decision(coupon_amount) | (derived; uses /notional_amount) | All normative |
| BR-010 | Spec §3 | Coupon_Decision(payment_date) | /coupon_payment_dates | All normative |
| BR-011 | Spec §2, §5 | Trade(recovery_mode) | /recovery_mode | Baseline |
| BR-012 | Spec §2 (example) | Trade(recovery_mode, settlement_type) | /recovery_mode /settlement_type | Future examples |
| BR-013 | Spec §5 | Coupon_Decision(final coupon) | (derived) | All normative |
| BR-014 | Spec §3 | Observation(observation_date) | /observation_dates/items | All normative |
| BR-015 | Spec §3 | Underlying_Asset(symbol, initial_level) | /underlying_symbols /initial_levels | All normative |
| BR-016 | Domain Handoff §7, ER §6 | Underlying_Asset(weight) | /basket_weights | Future basket |
| BR-017 | ADR-003 | Test_Vector(metadata) | (metadata) | Activation checklist |
| BR-018 | ADR-004 | Product_Version(version_id) | (version control) | Governance process |
| BR-019 | DEC-011, Spec §3 | Trade(notional) | /notional_amount | Precision tests |

## 8. Rule Validation Strategy

| Phase | Focus | Rules | Status |
|-------|-------|-------|--------|
| 0 | Structure / metadata | (pre) | Complete |
| 1 | Taxonomy & branch | BR-017 (gate) | Complete |
| 2 | Parameter constraints | BR-001–004, 014, 015, 019 | In Progress |
| 3 | Coverage mapping | BR-017 | In Progress |
| 4 | Business logic simulation | BR-005–013, 016 | Planned |
| 5 | Governance automation | BR-018 | Planned |

## 9. Open Questions

| ID | Question | Related Rule(s) | Owner | Target | Status |
|----|----------|-----------------|-------|--------|--------|
| OQ-BR-001 | Allow equality in BR-003 (`knock_in_barrier_pct == redemption_barrier_pct`) for niche structures? | BR-003 | BA | Week 1 | Open |
| OQ-BR-002 | DB vs application enforcement for idempotency (BR-007)? | BR-007 | SA | Week 2 | Open |
| OQ-BR-003 | Standard error payload schema fields (pointer, rule_id, severity)? | All | BA+SA | Week 2 | Open |
| OQ-BR-004 | Introduce tolerance epsilon for BR-016 sum=1.0 (e.g. 0.0001)? | BR-016 | BA | Week 1 | Open |

(Notional precision question removed — resolved by DEC-011 / BR-019.)

## Naming Note

API / Schema parameter key: `notional_amount`  
Persistence / ER attribute: `Trade.notional`  
All rule text, mapping rows, formulas, and validator logic referencing the input parameter MUST use `notional_amount` to avoid confusion with derived monetary values.

## 10. Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-10 | siripong.s | Initial rules BR-001–BR-018 |
| 1.0.1 | 2025-10-10 | siripong.s | Added BR-019 (precision), integrated mapping & traceability enhancements |
| 1.0.2 | 2025-10-10 | siripong.s | Consolidated schema–rule–data mapping (PR #26), added coverage metrics |
| 1.0.3 | 2025-10-10 | copilot | Hygiene: canonical parameter name notional_amount; mapping & traceability updates |

## 11. References
- [FCN v1.0 Specification](specs/fcn-v1.0.md)
- [FCN v1.0 Entity-Relationship Model](er-fcn-v1.0.md)
- [FCN v1.0 Domain Handoff Package](../../sa/handoff/domain-handoff-fcn-v1.0.md)
- [Structured Notes Documentation Governance](../common/governance.md)
- [ADR-003: Version Activation & Promotion Workflow](../../sa/design-decisions/adr-003-fcn-version-activation.md)
- [ADR-004: Parameter Alias & Deprecation Policy](../../sa/design-decisions/adr-004-parameter-alias-policy.md)
- [DEC-011: Notional Precision Policy](../../sa/design-decisions/dec-011-notional-precision.md)
- [Test Vectors](test-vectors/)