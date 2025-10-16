---
title: FCN v1.1 Test Vector – Capital-at-Risk Memory – KI With Loss
doc_type: test-vector
status: Draft
version: 1.1.0
normative: true
branch_id: fcn-caprisk-mem
spec_version: 1.1.0
owner: copilot
created: 2025-10-16
classification: Internal
tags: [structured-notes, fcn, test-vector, v1.1, capital-at-risk, memory, ki-loss]
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
Memory variant with KI trigger and capital-at-risk loss at maturity. Demonstrates memory coupon logic (BR-008, BR-009) combined with capital-at-risk settlement (BR-025).

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
| memory_carry_cap_count | null |
| knock_in_barrier_pct | 0.60 |
| put_strike_pct | 0.80 |
| coupon_condition_threshold_pct | 0.85 |
| barrier_monitoring_type | discrete |
| recovery_mode | capital-at-risk |

## Expected Events
- ki_triggered: true (period 2, worst performer breaches 60%)
- worst_of_final_ratio: 0.700 (< put_strike_pct 0.80)
- Loss calculation (BR-025):
  - loss_amount = 1,000,000 × (0.80 - 0.70) / 0.80 = 125,000
  - redemption_amount = 875,000
- Memory feature: accrued coupons paid when conditions improve

## Validation Points
- BR-005: KI trigger detection
- BR-008, BR-009: Memory accumulation and release
- BR-025: Capital-at-risk loss calculation with KI and worst_of_final < put_strike

## Notes
- Demonstrates full feature interaction: memory + capital-at-risk + KI
- Loss independent of coupon payments (BR-013)
- Final redemption: 875,000 (87.5% of notional)
