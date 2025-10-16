---
title: FCN v1.1 Test Vector – Capital-at-Risk Memory – Accrual and Release
doc_type: test-vector
status: Draft
version: 1.1.0
normative: true
branch_id: fcn-caprisk-mem
spec_version: 1.1.0
owner: copilot
created: 2025-10-16
classification: Internal
tags: [structured-notes, fcn, test-vector, v1.1, capital-at-risk, memory, accrual]
related:
  - ../specs/fcn-v1.1.0.md
taxonomy:
  barrier_type: down-in
  settlement: physical-settlement
  coupon_memory: memory
  step_feature: no-step
  recovery_mode: capital-at-risk
---

# Scenario Description
Memory variant where coupons accrue during poor performance periods and release when conditions improve. No KI triggered, 100% redemption. Demonstrates memory accumulation logic (BR-008, BR-009) independent of capital-at-risk feature.

## Parameters
| name | value |
|------|-------|
| notional | 1_000_000 |
| currency | USD |
| issuer | SAMPLE_BANK_01 |
| underlying_symbols | ["AMZN.US", "ORCL.US", "PLTR.US"] |
| initial_levels | [180.00, 125.00, 35.00] |
| coupon_rate_pct | 0.04 |
| is_memory_coupon | true |
| memory_carry_cap_count | 3 |
| knock_in_barrier_pct | 0.60 |
| put_strike_pct | 0.80 |
| coupon_condition_threshold_pct | 0.85 |
| barrier_monitoring_type | discrete |
| recovery_mode | capital-at-risk |

## Expected Events
- ki_triggered: false
- accrued_unpaid: varies (max 2 periods accumulate, then release)
- Example: Period 2-3 miss, period 4 pays 3 coupons (current + 2 accrued)
- Final redemption: 100% notional

## Validation Points
- BR-008: Memory carry cap respected (max 3 accrued)
- BR-009: Coupon calculation includes accrued_unpaid
- BR-025: No KI → 100% redemption

## Notes
- Demonstrates memory feature orthogonality to capital-at-risk settlement
- Aggregate coupons equal total periods despite timing differences
