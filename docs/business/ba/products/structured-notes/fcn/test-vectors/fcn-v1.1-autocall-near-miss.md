---
title: FCN v1.1 Test Vector – Autocall Near Miss (Proceeds to Maturity)
doc_type: test-vector
status: Draft
version: 1.1.0
normative: true
branch_id: fcn-caprisk-nomem-autocall
spec_version: 1.1.0
owner: copilot
created: 2025-10-16
classification: Internal
tags: [structured-notes, fcn, test-vector, v1.1, autocall, near-miss]
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
Autocall near-miss: one or more underlyings approach but never all reach 110% barrier simultaneously. Product proceeds to maturity. No KI. Capital-at-risk settlement applies (100% redemption since no KI).

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
- autocall_triggered: false (near-miss: not all underlyings >= 110% at any observation)
- Example path: obs 2 AMZN 1.12, ORCL 1.09 (miss), PLTR 1.05; obs 3 AMZN 1.08, ORCL 1.11, PLTR 1.03 (miss)
- Final redemption: 100% notional at maturity (no KI)

## Validation Points
- BR-021: Autocall requires ALL underlyings >= 110% (not just majority)
- BR-023: Since no autocall, maturity settlement proceeds normally
- BR-025: No KI → 100% redemption

## Notes
- Demonstrates "all-underlyings" autocall logic strictness
- Near-miss scenarios important for risk assessment
- Maturity reached despite autocall feature enabled
