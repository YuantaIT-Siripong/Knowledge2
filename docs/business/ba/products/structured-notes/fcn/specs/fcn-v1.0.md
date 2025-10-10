---
title: Fixed Coupon Note (FCN) Specification v1.0
doc_type: product-spec
status: Draft
spec_version: 1.0.0
version: 1.0.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-09
last_reviewed: 2025-10-09
next_review: 2026-04-09
classification: Internal
tags: [structured-notes, fcn, product-spec, v1.0]
related:
  - ../../../common/conventions.md
  - ../../../common/payoff_types.md
  - ../../../common/governance.md
  - ../../../common/deprecation-alias-policy.md
  - ../../../sa/design-decisions/adr-002-product-doc-structure.md
  - ../../../sa/design-decisions/adr-003-fcn-version-activation.md
  - ../../../sa/design-decisions/adr-004-parameter-alias-policy.md
activation_checklist_issue: .github/ISSUE_TEMPLATE/fcn-v1.0-activation-checklist.md
normative_test_vector_set:
  - N1
  - N2
  - N3
  - N4
  - N5
---

# Fixed Coupon Note (FCN) – Baseline Specification (v1.0)

## 1. Overview
The baseline FCN v1.0 is a multi-underlying structured note paying periodic fixed coupons contingent on barrier conditions and offering conditional principal protection unless a knock-in (KI) event occurs. Settlement can be physical or cash; baseline normative branch uses physical settlement with memory coupons and a down-in barrier.

Scope of v1.0:
- Single or basket (equal-weight) underlying support
- Memory coupon feature (optional)
- Down-in (a.k.a. knock-in) barrier monitored on observation dates (no continuous monitoring)
- Physical settlement branch after KI with proportional underlying delivery OR par recovery branch (baseline selects par-recovery; proportional-loss may appear in examples but is not normative)
- No step-down or step-up barrier schedules in v1.0 (introduced in v1.1+)
- No alias parameter lifecycle active in v1.0 (aliases introduced earliest v1.1)

Non-goals (future versions):
- Step feature dynamics
- Advanced averaging or autocall features
- Complex recovery modes beyond par-recovery & proportional-loss
- Parameter alias transitions

## 2. Economic Description
Investor receives fixed coupons at defined coupon observation/payment dates provided coupon conditions are satisfied (e.g., underlying levels above a coupon threshold). Capital is protected at maturity unless a knock-in occurs (underlying breaches KI barrier). If KI event occurs, payoff may switch to recovery branch (baseline par recovery). If no KI event and final underlying(s) stay above redemption barrier, redemption at par (plus final coupon if payable).

## 3. Parameter Table

| name | type | required | default | constraints | description |
|------|------|----------|---------|-------------|-------------|
| trade_date | date | yes | - | ISO-8601 | Date of trade agreement |
| issue_date | date | yes | - | issue_date >= trade_date | Settlement / note inception date |
| maturity_date | date | yes | - | maturity_date > issue_date | Contract final maturity |
| underlying_symbols | string[] | yes | - | length >= 1; uppercase tickers | Underlying instrument identifiers |
| initial_levels | decimal[] | yes | - | length = length(underlying_symbols); each > 0 | Recorded initial spot/close for each underlying |
| notional_amount | decimal | yes | - | > 0 | Face amount in currency units |
| currency | string | yes | - | ISO-4217 (e.g., TWD, USD) | Settlement currency |
| observation_dates | date[] | yes | - | strictly increasing; all < maturity_date | Coupon & barrier observation schedule (excludes maturity if separately listed) |
| coupon_observation_offset_days | integer | no | 0 | >= 0 | Business day offset for observing coupon vs nominal schedule (0 = same day) |
| coupon_payment_dates | date[] | yes | - | length = length(observation_dates); each >= issue_date | When coupons (if any) are paid |
| coupon_rate_pct | decimal | yes | - | 0 < x <= 1 | Period coupon rate (ratio form; display ×100%) |
| is_memory_coupon | boolean | no | false | - | If true, missed coupons (due to barrier) can accrue and pay later when condition satisfied |
| memory_carry_cap_count | integer | conditional | null | if is_memory_coupon=true then >=0 else null | Limits number of unpaid coupons that can accumulate (null = unlimited) |
| knock_in_barrier_pct | decimal | yes | - | 0 < x < 1 | Barrier level as fraction of initial level (per underlying) triggering KI if breached |
| barrier_monitoring | string | yes | "discrete" | enum: discrete | Monitoring style; only discrete supported in v1.0 |
| knock_in_condition | string | yes | - | enum: any-underlying-breach | Condition logic: KI occurs if any underlying closes <= initial * knock_in_barrier_pct on any observation date |
| redemption_barrier_pct | decimal | yes | - | 0 < x <= 1 | Final redemption barrier (for par redemption) |
| settlement_type | string | yes | - | enum: physical-settlement | Allowed in v1.0 normative: physical-settlement (cash-settlement may appear in examples but is non-normative) |
| coupon_condition_threshold_pct | decimal | no | 1.0 | 0 < x <= 1 | Minimum fraction of initial level each underlying must stay above for coupon payment |
| recovery_mode | string | yes | "par-recovery" | enum: par-recovery | Baseline normative recovery branch (proportional-loss deferred) |
| day_count_convention | string | no | "ACT/365" | enum: ACT/365, ACT/360 | Used for accrual calculations if needed |
| business_day_calendar | string | no | "TARGET" | recognized calendar code | Calendar for date adjustments |
| fx_reference | string | conditional | null | required if underlying currency != settlement currency | FX rate source identifier |
| documentation_version | string | yes | "1.0.0" | equals spec_version | Traceability anchor |

Notes:
- For baskets, barrier test and coupon condition evaluate each underlying independently (any breach for KI; all above threshold for coupon).
- settlement_type constrained to physical-settlement for normative compliance; alternate settlement scenarios documented under examples.

## 4. Derived / Computed Fields (Non-Input)
| name | type | formula | description |
|------|------|---------|-------------|
| ki_triggered | boolean | OR over observation dates of breach condition | Whether KI event occurred |
| eligible_coupon | boolean[] | condition per observation | Whether coupon conditions satisfied each period |
| accrued_memory_count | integer[] | iterative accumulator | Count of unpaid coupons carried forward (if memory enabled) |

## 5. Payoff Pseudocode (Normative)

```
Initialization:
  ki_triggered = false
  accrued_unpaid = 0

For each observation_date i:
  level_ok = ALL( underlying_level_j(i) >= initial_level_j * coupon_condition_threshold_pct )
  barrier_breach = ANY( underlying_level_j(i) <= initial_level_j * knock_in_barrier_pct )
  if barrier_breach:
      ki_triggered = true
  if level_ok:
      pay_coupon(i, (accrued_unpaid + 1) * notional_amount * coupon_rate_pct)
      accrued_unpaid = 0
  else if is_memory_coupon:
      accrued_unpaid = accrued_unpaid + 1

At maturity:
  final_levels = underlying_levels_on(maturity_date)
  if ki_triggered:
      redemption_amount = notional_amount   # par-recovery (normative v1.0)
  else:
      condition_ok = ALL( final_level_j >= initial_level_j * redemption_barrier_pct )
      redemption_amount = notional_amount if condition_ok else notional_amount  # Baseline identical; future versions may differ
  pay_principal(redemption_amount)
```

Implementation Notes:
- Proportional-loss variant intentionally excluded from normative branch; may appear only in illustrative examples with explicit taxonomy code difference.
- Redemption logic identical for KI and non-KI in baseline par-recovery; purpose is to keep v1.0 simple while allowing extension.

## 6. Taxonomy & Branch Inventory

Declared taxonomy dimensions (see common/payoff_types.md):
- barrier_type: down-in
- settlement: physical-settlement
- coupon_memory: memory OR no-memory
- step_feature: no-step
- recovery_mode: par-recovery

Normative branches (v1.0):
| branch_id | barrier_type | settlement | coupon_memory | step_feature | recovery_mode | description |
|-----------|--------------|-----------|---------------|--------------|---------------|-------------|
| base_mem | down-in | physical-settlement | memory | no-step | par-recovery | Memory coupon configuration |
| base_nomem | down-in | physical-settlement | no-memory | no-step | par-recovery | Non-memory coupon configuration |

Non-normative (illustrative only) examples MAY add:
- settlement: cash-settlement
- recovery_mode: proportional-loss

## 7. Events & Lifecycle (Mapping Skeleton)
| event_code | trigger | description |
|------------|---------|-------------|
| TRADE | trade_date | Execution/booking |
| ISSUE | issue_date | Note issuance |
| OBS | each observation_date | Coupon & barrier evaluation |
| KI | first barrier breach | Knock-in event (if occurs) |
| MAT | maturity_date | Redemption and final settlement |

## 8. Versioning & Compatibility
- v1.0 is the baseline; no deprecated or alias parameters exist.
- Introduction of step-down features & alias lifecycle begins earliest v1.1 (see ADR-003 & ADR-004 for promotion requirements).
- Any new recovery_mode or settlement variations added in minors must not break existing parameter semantics.

## 9. Alias Table (Empty – No Active Aliases in v1.0)

| legacy_name | new_name | stage | first_version | removal_target | notes |
|-------------|----------|-------|---------------|----------------|-------|
| <!-- No aliases defined; table reserved for future versions --> |

## 10. Normative Test Vector Set (Planned)
Planned normative test vector files (will reside in `../test-vectors/`):
| id | filename | branch_id | scenario_focus |
|----|----------|-----------|----------------|
| N1 | fcn-v1.0-base-mem-baseline.md | base_mem | All coupons pay, no KI |
| N2 | fcn-v1.0-base-mem-single-miss.md | base_mem | One missed coupon, memory pays later |
| N3 | fcn-v1.0-base-mem-ki-event.md | base_mem | KI occurs early; par-recovery |
| N4 | fcn-v1.0-base-nomem-baseline.md | base_nomem | Non-memory coupon path |
| N5 | fcn-v1.0-base-mem-edge-barrier-touch.md | base_mem | Barrier touched exactly at threshold |

(normative_test_vector_set will list actual committed filenames once created)

## 11. Activation Checklist Reference
The activation checklist for promoting this specification from Draft to Proposed status is tracked via GitHub issue template: `.github/ISSUE_TEMPLATE/fcn-v1.0-activation-checklist.md`

This checklist is required for Proposed → Active promotion per ADR-003 and includes the following key gates:
- Normative test vector set (N1–N5) present and verified
- Taxonomy declared and matches all vector branch_ids
- Alias table empty and verified (v1.0 baseline)
- Governance reviewers confirmed (Product Owner, Risk, Technical, Documentation Steward)
- Automation lint status: metadata, taxonomy, memory logic checked
- Documentation review completed

Create a new issue using the template to track activation progress.

## 12. Open Items
| item | description | priority | target_version |
|------|-------------|----------|----------------|
| Clarify proportional-loss inclusion | Decide if supported or deferred | Medium | 1.1.0 |
| Add cash-settlement normative branch? | Evaluate need for settlement diversification | Low | 1.2.0 |
| Introduce alias for future parameter rename | Dependent on upcoming enhancements | Low | 1.1.0+ |

## 13. Test Vector Coverage
The following coverage matrix links normative dimensions to test vector IDs.

### 13.1 Dimension Coverage Matrix
| Dimension | Values Covered | Test Vectors |
|-----------|----------------|--------------|
| coupon_memory | memory | N1, N2, N3, N5 |
| coupon_memory | no-memory | N4 |
| KI state | no KI | N1, N2, N4 |
| KI state | KI (early) | N3 |
| KI state | KI (equality edge) | N5 |
| Coupon miss handling | none missed | N1 |
| Coupon miss handling | single miss recovered (memory) | N2 |
| Coupon miss handling | single miss forfeited (non-memory) | N4 |
| Coupon miss handling | miss then KI then recovery | N3 |
| Barrier edge condition | equality triggers KI | N5 |

### 13.2 Scenario Interaction Highlights
- Equality barrier condition (level == barrier) explicitly validated (N5).
- Memory accumulation with later payout both in KI and non-KI states (N2 vs N3).
- Difference between memory and non-memory forfeiture semantics (N2 vs N4).

### 13.3 Gaps / Planned Future Vectors
| Gap Category | Description | Planned Vector ID (proposed) | Target Version |
|--------------|-------------|------------------------------|----------------|
| Multiple consecutive misses | Two or more sequential coupon misses with later recovery | N6 (memory multi-miss) | 1.0.x |
| Memory cap behavior | Enforce `memory_carry_cap_count` limit | N7 (memory-cap) | 1.1.0 |
| Basket logic | Multi-underlying: KI triggered by any; coupon requires all | N8 (basket-baseline) | 1.1.0 |
| Final level below redemption barrier | Stress where final < redemption barrier (currently still par) | N9 (final-below-barrier) | 1.0.x |
| FX reference usage | Underlying currency differs from settlement currency | N10 (fx-cross) | 1.1.0 |
| Alternative settlement | Cash-settlement (non-normative example) | EX1 (cash-settle) | 1.1.0 (non-normative) |
| Alternative recovery | proportional-loss branch (illustrative) | EX2 (prop-loss) | 1.1.0 (non-normative) |
| Memory + equality + final stress | Combine edge barrier + final < redemption barrier | N11 (edge-final-stress) | 1.1.0 |

### 13.4 Coverage Statement
Current normative set (N1–N5) provides baseline validation for: coupon memory mechanics (single accrual), KI detection (standard & equality), and divergence between memory and non-memory coupon forfeiture. Extended stress, multi-miss, basket, FX, and alternative economic outcome scenarios are explicitly deferred and enumerated for traceable closure.

## 14. Change Log
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-09 | siripong.s@yuanta.co.th | Initial baseline specification draft |
| 1.0.0-doc-update | 2025-10-09 | siripong.s@yuanta.co.th | Added Test Vector Coverage section (documentation only) |