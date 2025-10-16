---
title: FCN v1.1 Test Vector – Autocall Late Trigger (Final Observation)
doc_type: test-vector
status: Draft
version: 1.1.0
normative: true
branch_id: fcn-caprisk-nomem-autocall
spec_version: 1.1.0
owner: copilot
created: 2025-10-16
classification: Internal
tags: [structured-notes, fcn, test-vector, v1.1, autocall, late-trigger]
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
Late autocall trigger: autocall condition met at final observation (just before maturity). Demonstrates autocall precedence even at last opportunity (BR-021, BR-023). No KI event.

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
- autocall_triggered: true (final obs, all >= 110%)
- autocall_date: final observation date (e.g., obs 4 or obs 5)
- redemption: 100% notional + final coupon on maturity date

## Validation Points
- BR-021: Autocall evaluates at each observation including final
- BR-023: Even at final observation, autocall takes precedence over maturity settlement
- BR-025: Capital-at-risk settlement bypassed due to autocall

## Notes
- Edge case: autocall at last moment before maturity
- Timing: autocall observation vs maturity date (may coincide)
- Demonstrates autocall doesn't require "early" in absolute sense, just precedence over settlement logic
- Result identical to maturity with no KI (100% notional), but mechanism differs (autocall vs capital-at-risk)
