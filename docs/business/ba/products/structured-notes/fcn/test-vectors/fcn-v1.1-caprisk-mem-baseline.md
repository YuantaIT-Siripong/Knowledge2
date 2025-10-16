---
title: FCN v1.1 Test Vector – Capital-at-Risk Memory – Baseline (No KI, Memory Unused)
doc_type: test-vector
status: Draft
version: 1.1.0
normative: true
branch_id: fcn-caprisk-mem
spec_version: 1.1.0
owner: copilot
created: 2025-10-16
classification: Internal
tags: [structured-notes, fcn, test-vector, v1.1, capital-at-risk, memory, baseline]
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
Memory variant baseline with capital-at-risk. All coupons pay immediately (memory feature enabled but unused). No KI, 100% redemption.

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
- ki_triggered: false
- accrued_unpaid: 0 (memory feature present but unused)
- Final redemption: 100% notional

## Notes
- Validates memory feature compatibility with capital-at-risk settlement
- BR-025: No KI → 100% redemption
