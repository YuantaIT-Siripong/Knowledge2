---
---
title: FCN v1.0 Test Vector N1 – Base Memory – All Coupons Pay, No KI
doc_type: test-vector
status: Draft
version: 1.0.0
normative: true
branch_id: base_mem
spec_version: 1.0.0
owner: siripong.s@yuanta.co.th
created: 2025-10-09
classification: Internal
tags: [structured-notes, fcn, test-vector, v1.0, memory, baseline]
related:
  - ../specs/fcn-v1.0.md
taxonomy:
  barrier_type: down-in
  settlement: physical-settlement
  coupon_memory: memory
  step_feature: no-step
  recovery_mode: par-recovery
---

# Scenario Description
Baseline memory-coupon path. All observation levels stay above both coupon threshold (80% of initial) and knock-in barrier (70%), so:
- No knock-in (ki_triggered = false)
- Every coupon pays immediately (no memory accumulation)
- Redemption at par

## Parameters
| name | value |
|------|-------|
| trade_date | 2025-10-10 |
| issue_date | 2025-10-15 |
| maturity_date | 2026-12-30 |
| notional_amount | 1_000_000 |
| currency | USD |
| underlying_symbols | [ABC] |
| initial_levels | [100.00] |
| observation_dates | 2025-12-30, 2026-03-30, 2026-06-30, 2026-09-30, 2026-12-23 |
| coupon_payment_dates | 2025-12-30, 2026-03-30, 2026-06-30, 2026-09-30, 2026-12-30 |
| coupon_rate_pct | 0.05 |
| is_memory_coupon | true |
| memory_carry_cap_count | null |
| knock_in_barrier_pct | 0.70 |
| redemption_barrier_pct | 0.80 |
| coupon_condition_threshold_pct | 0.80 |
| settlement_type | physical-settlement |
| recovery_mode | par-recovery |
| day_count_convention | ACT/365 |
| business_day_calendar | TARGET |

## Underlying Path
| obs # | observation_date | level(ABC) | level / initial | Coupon Condition (>=80%) | Barrier Breach (<=70%) |
|-------|------------------|-----------|------------------|--------------------------|------------------------|
| 1 | 2025-12-30 | 104.0 | 1.040 | Yes | No |
| 2 | 2026-03-30 | 101.5 | 1.015 | Yes | No |
| 3 | 2026-06-30 | 102.2 | 1.022 | Yes | No |
| 4 | 2026-09-30 | 99.8  | 0.998 | Yes | No |
| 5 | 2026-12-23 | 103.1 | 1.031 | Yes | No |

Maturity reference level (2026-12-30) assumed 103.5 (> redemption barrier).

## Event Timeline
| seq | date | event | details |
|-----|------|-------|---------|
| 1 | 2025-10-10 | TRADE | Trade executed |
| 2 | 2025-10-15 | ISSUE | Note issued |
| 3 | 2025-12-30 | OBS | Coupon pays (period 1) |
| 4 | 2026-03-30 | OBS | Coupon pays (period 2) |
| 5 | 2026-06-30 | OBS | Coupon pays (period 3) |
| 6 | 2026-09-30 | OBS | Coupon pays (period 4) |
| 7 | 2026-12-23 | OBS | Coupon pays (period 5) |
| 8 | 2026-12-30 | MAT | Principal redemption |

## Cash Flows
Coupon amount each period = notional * coupon_rate_pct = 1,000,000 * 0.05 = 50,000.

| date | type | amount | description |
|------|------|--------|-------------|
| 2025-12-30 | coupon | 50,000 | Period 1 coupon |
| 2026-03-30 | coupon | 50,000 | Period 2 coupon |
| 2026-06-30 | coupon | 50,000 | Period 3 coupon |
| 2026-09-30 | coupon | 50,000 | Period 4 coupon |
| 2026-12-30 | coupon | 50,000 | Period 5 coupon (paid on maturity payment date) |
| 2026-12-30 | principal | 1,000,000 | Redemption (no KI) |

Total coupons: 250,000; Total redemption: 1,000,000.

## Outcome Summary
- ki_triggered: false
- accrued_unpaid never > 0
- memory feature unused but enabled

## Validation Points
- Each period’s coupon condition satisfied
- Barrier never breached
- Redemption barrier satisfied -> par redemption
