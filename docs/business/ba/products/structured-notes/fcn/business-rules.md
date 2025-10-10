---
title: FCN v1.0 Business Rules
doc_type: business-rule
status: Draft
version: 1.0.1
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

This document defines the authoritative set of business rules governing Fixed Coupon Note (FCN) v1.0 product validation, lifecycle processing, data integrity, and governance. Each rule has an explicit source, owner, and priority to enable traceability, implementation planning, and audit readiness.

## 2. Scope

- **Validation Rules**: Input & structural constraints at booking / parameter submission.
- **Business Logic Rules**: Knock-in detection, coupon eligibility & calculation, settlement logic.
- **Data Integrity Rules**: Referential and quantitative consistency across entities (e.g., basket weights).
- **Governance Rules**: Test coverage gates, versioning & change-management.
- **Precision / Formatting Rules**: Currency / numeric formatting (added via notional precision decision).

## 3. Business Rules Table

| Rule ID | Category | Description | Source / Owner | Priority | Status | Normative Scope |
|---------|----------|-------------|----------------|----------|--------|-----------------|
| BR-001 | Validation | `trade_date ≤ issue_date < maturity_date` | Spec fcn-v1.0.md §3 / BA | P0 | Draft | Yes |
| BR-002 | Validation | All `initial_levels` > 0 | Spec fcn-v1.0.md §3 (parameter table) / BA | P0 | Draft | Yes |
| BR-003 | Validation | `0 < knock_in_barrier_pct < redemption_barrier_pct ≤ 1.0` | Spec fcn-v1.0.md §3 / BA | P0 | Draft | Yes |
| BR-004 | Validation | `documentation_version` must equal active product version | Governance (governance.md) + Spec §3 / BA | P1 | Draft | Yes |
| BR-005 | KI Logic | KI triggered if ANY underlying close ≤ `initial_level × knock_in_barrier_pct` on observation date | Spec §5 (Payoff pseudocode) / BA | P0 | Draft | Yes |
| BR-006 | Coupon Logic | Coupon condition satisfied if ALL underlying closes ≥ `initial_level × coupon_condition_threshold_pct` | Spec §5 / BA | P0 | Draft | Yes |
| BR-007 | Observation | Each observation date processed exactly once (idempotent) | Domain Handoff §7 / SA | P0 | Draft | Yes |
| BR-008 | Coupon Logic | Memory accumulation capped at `memory_carry_cap_count` (if provided) | Spec §3 & §5 / BA | P0 | Draft | Yes |
| BR-009 | Coupon Calc | `coupon_amount = notional × coupon_rate_pct × (accrued_unpaid + 1)` (memory aware) | Spec §5 / BA | P0 | Draft | Yes |
| BR-010 | Coupon Timing | Coupon payment date = element in `coupon_payment_dates` aligned by observation index | Spec §3 / BA | P0 | Draft | Yes |
| BR-011 | Settlement | Par recovery returns 100% notional at maturity (KI irrelevant) if `recovery_mode = par-recovery` | Spec §2, §5 / BA | P0 | Draft | Yes |
| BR-012 | Settlement | Proportional-loss settlement delivers underlying units (example only) if `recovery_mode = proportional-loss` | Spec §2, §3 (non-normative examples) / BA | P2 | Draft | Non-Normative |
| BR-013 | Settlement | Final coupon eligibility evaluated independently of redemption calculation | Spec §5 / BA | P1 | Draft | Yes |
| BR-014 | Validation | Observation dates strictly increasing AND each < `maturity_date` | Spec §3 / BA | P0 | Draft | Yes |
| BR-015 | Validation | `underlying_symbols` length = `initial_levels` length | Spec §3 / BA | P0 | Draft | Yes |
| BR-016 | Data Integrity | If basket weights provided: sum(weights) = 1.0 (exact) else assume equal-weight | Domain Handoff §7, ER §6 / SA | P1 | Draft | Yes |
| BR-017 | Governance | Normative test vector coverage required for Proposed → Active promotion | ADR-003 / SA | P0 | Draft | Yes |
| BR-018 | Governance | Parameter schema structural change requires new product version per alias policy | ADR-004 / SA | P1 | Draft | Yes |
| BR-019 | Validation (Precision) | Notional precision: 2 decimals for standard currencies; 0 decimals for zero-decimal currencies (ISO 4217) | DEC-011 (Notional Precision) + Spec §3 update / SA | P0 | Draft | Yes |

### 3.1 Rule Notes
- BR-012 is retained for documentation clarity but is non-normative (out of v1.0 production scope).
- BR-019 consolidates the precision decision—removes need for separate open question on notional precision.

## 4. Rule Categories

### 4.1 Validation Rules (BR-001, BR-002, BR-003, BR-004, BR-014, BR-015, BR-019)
Applied at parameter submission & persisted via DB constraints.

### 4.2 Business Logic Rules (BR-005 .. BR-013 excluding 012 normative vs non-normative)
Define runtime financial behavior and lifecycle transitions.

### 4.3 Data Integrity Rules (BR-016)
Quantitative consistency & referential soundness.

### 4.4 Governance Rules (BR-017, BR-018)
Promotion workflow & versioning constraints.

### 4.5 Precision / Formatting (Embedded in BR-019)
Ensures downstream valuation & reporting alignment.

## 5. Implementation Mapping

| Layer | Implementation Guidance |
|-------|-------------------------|
| API Request Validation | JSON Schema + custom cross-field validators (BR-001/003/014/015/019) |
| Domain Services | Lifecycle engine (BR-005–BR-013), memory logic aggregator (BR-008/009) |
| Persistence | CHECK constraints (dates ordering, barrier inequality, precision), triggers (idempotent obs flag for BR-007 if chosen DB-level) |
| Observability | Emit structured event: `rule.validation.failure` with `rule_id`, severity, payload pointer |
| Error Model | Map each rule to `ERR_FCN_<rule_id>` for consistency (e.g., BR-003 → ERR_FCN_BR_003) |

## 6. Rule–Schema–Data Mapping (Merged with Mapping Table from PR #26)

| JSON Schema Field / Derived | Data Model Entity.Attribute | Rule IDs | Normative? | Notes |
|-----------------------------|-----------------------------|---------|-----------|-------|
| trade_date | Trade.trade_date | BR-001 | Yes | Must satisfy ordering chain |
| issue_date | Trade.issue_date | BR-001 | Yes |  |
| maturity_date | Trade.maturity_date | BR-001 | Yes |  |
| initial_levels[] | Underlying_Asset.initial_level | BR-002, BR-015 | Yes | Each > 0; array length sync |
| underlying_symbols[] | Underlying_Asset.symbol | BR-015 | Yes | 1:1 with initial_levels |
| knock_in_barrier_pct | Trade.knock_in_barrier_pct | BR-003, BR-005 | Yes | Range & KI logic |
| redemption_barrier_pct | Trade.redemption_barrier_pct | BR-003 | Yes | Upper bound relationship |
| coupon_condition_threshold_pct | Trade.coupon_condition_threshold_pct | BR-006 | Yes | Drives level_ok |
| observation_dates[] | Observation.observation_date | BR-007, BR-014 | Yes | Strictly increasing |
| coupon_payment_dates[] | Coupon_Decision.payment_date | BR-010 | Yes | Indexed alignment |
| memory_carry_cap_count | Coupon_Decision.memory_carry_cap_count | BR-008 | Yes | Optional; governs cap |
| coupon_rate_pct | Trade.coupon_rate_pct | BR-009 | Yes | Used in coupon formula |
| recovery_mode | Trade.recovery_mode | BR-011, BR-012 | Mixed | par-recovery normative |
| settlement_type | Trade.settlement_type | BR-012 | Non-Normative | Used only in examples now |
| documentation_version | Trade.documentation_version | BR-004 | Yes | Version parity |
| basket_weights[] | Underlying_Asset.weight | BR-016 | Yes | Optional; else inferred |
| is_memory_coupon (if present) | Trade.is_memory_coupon | BR-008, BR-009 | Yes | Controls accumulation path |
| notional | Trade.notional | BR-009, BR-019 | Yes | Precision & calc input |
| accrued_unpaid (derived) | Coupon_Decision.accrued_unpaid | BR-008, BR-009 | Yes | Derived runtime state |
| ki_triggered (derived) | Trade.ki_triggered_flag | BR-005 | Yes | Event flag |
| coupon_amount (derived) | Coupon_Decision.coupon_amount | BR-009 | Yes | Computed per observation |
| version metadata | Product_Version.version_id | BR-018 | Yes | Version gating |
| test_vector metadata | Test_Vector.coverage_map | BR-017 | Yes | Coverage enforcement |

Coverage: 100% of current schema & derived runtime fields mapped.

## 7. Traceability Matrix

| Rule ID | Spec / Source Section | ER Entity(Attributes) | JSON Schema Path(s) | Test Vector(s) |
|---------|-----------------------|------------------------|--------------------|----------------|
| BR-001 | Spec §3 | Trade(trade_date, issue_date, maturity_date) | /trade_date, /issue_date, /maturity_date | All normative |
| BR-002 | Spec §3 | Underlying_Asset(initial_level) | /initial_levels/items | All normative |
| BR-003 | Spec §3 | Trade(knock_in_barrier_pct, redemption_barrier_pct) | /knock_in_barrier_pct, /redemption_barrier_pct | All normative |
| BR-004 | Spec §3, governance.md | Trade(documentation_version) | /documentation_version | All normative |
| BR-005 | Spec §5 | Observation, Underlying_Level, Trade(ki_triggered) | (derived) | KI event vector |
| BR-006 | Spec §5 | Coupon_Decision(condition_satisfied) | (derived) | Baseline, single-miss |
| BR-007 | Domain Handoff §7 | Observation(is_processed) | (derived) | All normative |
| BR-008 | Spec §3, §5 | Coupon_Decision(accrued_unpaid) | /memory_carry_cap_count | Memory baseline |
| BR-009 | Spec §5 | Coupon_Decision(coupon_amount) | (derived) | All normative |
| BR-010 | Spec §3 | Coupon_Decision(payment_date) | /coupon_payment_dates | All normative |
| BR-011 | Spec §2, §5 | Trade(recovery_mode) | /recovery_mode | Baseline |
| BR-012 | Spec §2, §3 (non-norm.) | Trade(settlement_type, recovery_mode) | /settlement_type, /recovery_mode | Future examples |
| BR-013 | Spec §5 | Coupon_Decision(final coupon evaluation) | (derived) | All normative |
| BR-014 | Spec §3 | Observation(observation_date) | /observation_dates/items | All normative |
| BR-015 | Spec §3 | Underlying_Asset(symbol, initial_level) | /underlying_symbols, /initial_levels | All normative |
| BR-016 | Domain Handoff §7, ER §6 | Underlying_Asset(weight) | (derived or /basket_weights) | Future basket |
| BR-017 | ADR-003 | Test_Vector(metadata) | (test metadata) | Activation checklist |
| BR-018 | ADR-004 | Product_Version(versioning) | (version control) | Governance process |
| BR-019 | DEC-011, Spec §3 | Trade(notional) | /notional | Precision tests |

## 8. Rule Validation Strategy

| Phase | Focus | Relevant Rules | Status |
|-------|-------|---------------|--------|
| 0 | Metadata & structure | (pre-rules) | Completed |
| 1 | Taxonomy & branch validation | BR-017 (gating) | Completed |
| 2 | Parameter constraints | BR-001–004, 014, 015, 019 | In Progress |
| 3 | Test vector coverage | BR-017 | In Progress |
| 4 | Business logic simulation | BR-005–013, 016 | Planned |
| 5 | Governance & versioning enforcement | BR-018 | Planned |

## 9. Open Questions

| ID | Question | Related Rule(s) | Owner | Target Resolution | Status |
|----|----------|-----------------|-------|-------------------|--------|
| OQ-BR-001 | Should BR-003 allow equality (`knock_in_barrier_pct == redemption_barrier_pct`) for rare payoff variants? | BR-003 | BA | Week 1 | Open |
| OQ-BR-002 | Enforce BR-007 idempotency at DB (unique composite) vs application layer? | BR-007 | SA | Week 2 | Open |
| OQ-BR-003 | Standardized error payload format (fields: rule_id, pointer, severity)? | All | BA+SA | Week 2 | Open |
| OQ-BR-004 | Tolerance for BR-016 basket weight sum (allow ε = 0.0001)? | BR-016 | BA | Week 1 | Open |

(Former notional precision question removed—resolved by BR-019 / DEC-011.)

## 10. Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-10 | siripong.s@yuanta.co.th | Initial business rules table with populated Source/Owner for BR-001–BR-018 |
| 1.0.1 | 2025-10-10 | siripong.s@yuanta.co.th | Added BR-019 (Notional precision), integrated mapping table & traceability, unified IDs, consolidated from concurrent branches |

## 11. References

- **Specification**: [FCN v1.0 Specification](specs/fcn-v1.0.md)
- **ER Model**: [FCN v1.0 Entity-Relationship Model](er-fcn-v1.0.md)
- **Domain Handoff**: [FCN v1.0 Domain Handoff Package](../../sa/handoff/domain-handoff-fcn-v1.0.md)
- **Governance**: [Structured Notes Documentation Governance](../common/governance.md)
- **ADR-003**: [FCN Version Activation & Promotion Workflow](../../sa/design-decisions/adr-003-fcn-version-activation.md)
- **ADR-004**: [Parameter Alias & Deprecation Policy](../../sa/design-decisions/adr-004-parameter-alias-policy.md)
- **DEC-011**: Notional Precision Decision (added in notional precision PR)
- **Test Vectors**: [FCN v1.0 Test Vectors](test-vectors/)