---
title: FCN v1.1 Test Vector – Autocall Trigger Standard
doc_type: test-vector
status: Draft
version: 1.1.0
normative: true
branch_id: fcn-caprisk-nomem-autocall
spec_version: 1.1.0
owner: copilot
created: 2025-10-16
classification: Internal
tags: [structured-notes, fcn, test-vector, v1.1, autocall, knock-out]
related:
  - ../specs/fcn-v1.1.0.md
taxonomy:
  barrier_type: down-in
  settlement: physical-settlement
  coupon_memory: no-memory
  step_feature: autocall
  recovery_mode: capital-at-risk
---

# Scenario Description
Standard autocall scenario: all underlyings reach 110% barrier at observation period 3, triggering early redemption (BR-021). No KI event. Capital-at-risk settlement never evaluated.

## Parameters
| name | value |
|------|-------|
| notional | 1_000_000 |
| currency | USD |
| issuer | SAMPLE_BANK_01 |
| underlying_symbols | ["AMZN.US", "ORCL.US", "PLTR.US"] |
| initial_levels | [180.00, 125.00, 35.00] |
| knock_in_barrier_pct | 0.60 |
| put_strike_pct | 0.80 |
| knock_out_barrier_pct | 1.10 |
| auto_call_observation_logic | all-underlyings |
| coupon_rate_pct | 0.04 |
| is_memory_coupon | false |
| barrier_monitoring_type | discrete |
| recovery_mode | capital-at-risk |

## Expected Events
- ki_triggered: false
- autocall_triggered: true (obs 3)
- autocall_date: obs 3 when all >= 110%
- redemption_amount: 100% notional + period 3 coupon

## Validation Points
- BR-020: knock_out_barrier_pct validation
- BR-021: Autocall trigger logic (all-underlyings >= initial × 1.10)
- BR-023: Autocall precedence over KI/capital-at-risk

## Notes
- Early redemption ceases further observations
- Capital-at-risk parameters present but unused (no maturity settlement)
