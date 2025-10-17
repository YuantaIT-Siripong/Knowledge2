---
title: Fixed Coupon Note (FCN) Specification v1.0
doc_type: product-spec
status: Superseded
version: 1.0.0
superseded_by: fcn-v1.1.0.md
deprecation_date: 2025-10-17
lifecycle: historical
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-09
last_reviewed: 2025-10-09
next_review: 2026-04-09
classification: Internal
tags: [structured-notes, fcn, product-spec, v1.0]
related:
  - ../non-functional.md
  - ../er-fcn-v1.0.md
  - ../../../common/conventions.md
  - ../../../common/payoff_types.md
  - ../../../common/governance.md
  - ../../../common/deprecation-alias-policy.md
  - ../../../sa/design-decisions/adr-002-product-doc-structure.md
  - ../../../sa/design-decisions/adr-003-fcn-version-activation.md
  - ../../../sa/design-decisions/adr-004-parameter-alias-policy.md
activation_checklist_issue: https://github.com/YuantaIT-Siripong/Knowledge2/issues/3
normative_test_vector_set:
  - N1
  - N2
  - N3
  - N4
  - N5
---

> **NOTE**: This v1.0 specification is retained for historical reference only. All new FCN templates, trades, and migrations MUST use v1.1.0 or later. Do not introduce new trades referencing documentation_version '1.0.0' after 2025-10-17 without explicit governance approval.

# Fixed Coupon Note (FCN) – Baseline Specification (v1.0)

## Supersession Note

**As of 2025-10-17**, this v1.0 specification has been superseded by v1.1.0. All new FCN trades, templates, and migrations must use v1.1.0 or later. This document is retained for historical reference and audit purposes only.

For details on the changes between v1.0 and v1.1.0, see [schema-diff-v1.0-to-v1.1.md](../schema-diff-v1.0-to-v1.1.md).

(… unchanged sections above parameter table …)

## 3. Parameter Table

| name | type | required | default | constraints | description |
|------|------|----------|---------|-------------|-------------|
| trade_date | date | yes | - | ISO-8601 | Date of trade agreement |
| issue_date | date | yes | - | issue_date >= trade_date | Settlement / note inception date |
| maturity_date | date | yes | - | maturity_date > issue_date | Contract final maturity |
| underlying_symbols | string[] | yes | - | length >= 1; uppercase tickers | Underlying instrument identifiers |
| initial_levels | decimal[] | yes | - | length = length(underlying_symbols); each > 0 | Recorded initial spot/close for each underlying |
| notional_amount | decimal | yes | - | > 0; precision: 2 decimal places for standard currencies (USD, EUR, THB); 0 for zero-decimal currencies (JPY, KRW) | Face amount in currency units |
| currency | string | yes | - | ISO-4217 (e.g., TWD, USD) | Settlement currency |
| observation_dates | date[] | yes | - | strictly increasing; all < maturity_date | Coupon & barrier observation schedule (excludes maturity if separately listed) |
| coupon_observation_offset_days | integer | no | 0 | >= 0 | Business day offset for observing coupon vs nominal schedule (0 = same day) |
| coupon_payment_dates | date[] | yes | - | length = length(observation_dates); each >= issue_date | When coupons (if any) are paid |
| coupon_rate_pct | decimal | yes | - | 0 < x <= 1 | Period coupon rate (ratio form; display ×100%) |
| is_memory_coupon | boolean | no | false | - | If true, missed coupons (due to barrier) can accrue and pay later when condition satisfied |
| memory_carry_cap_count | integer | conditional | null | if is_memory_coupon=true then >=0 else null | Limits number of unpaid coupons that can accumulate (null = unlimited) |
| knock_in_barrier_pct | decimal | yes | - | 0 < x < 1 | Barrier level as fraction of initial level (per underlying) triggering KI if breached |
| barrier_monitoring | string | yes | "discrete" | enum: discrete (v1.0), continuous (deferred to v1.1+) | Monitoring style; only discrete supported in v1.0. Continuous monitoring deferred to future versions. |
| knock_in_condition | string | yes | - | enum: any-underlying-breach | Condition logic: KI occurs if any underlying closes <= initial * knock_in_barrier_pct on any observation date |
| redemption_barrier_pct | decimal | yes | - | 0 < x <= 1 | Final redemption barrier (for par redemption) |
| settlement_type | string | yes | - | enum: physical-settlement | Allowed in v1.0 normative: physical-settlement (cash-settlement may appear in examples but is non-normative) |
| coupon_condition_threshold_pct | decimal | no | 1.0 | 0 < x <= 1 | Minimum fraction of initial level each underlying must stay above for coupon payment |
| recovery_mode | string | yes | "par-recovery" | enum: par-recovery | Baseline normative recovery branch (proportional-loss deferred) |
| day_count_convention | string | no | "ACT/365" | enum: ACT/365, ACT/360 | Used for accrual calculations if needed |
| business_day_calendar | string | no | "TARGET" | recognized calendar code | Calendar for date adjustments |
| fx_reference | string | conditional | null | required if underlying currency != settlement currency | FX rate source identifier |
| documentation_version | string | yes | "1.0.0" | equals version | Traceability anchor (validated by BR-004 / BR-018) |

(… remainder of file unchanged …)