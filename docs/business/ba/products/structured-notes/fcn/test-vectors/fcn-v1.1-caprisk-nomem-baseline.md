---
title: FCN v1.1 Test Vector – Capital-at-Risk No-Memory – Baseline (No KI, No Loss)
doc_type: test-vector
status: Draft
version: 1.1.0
normative: true
branch_id: fcn-caprisk-nomem
spec_version: 1.1.0
owner: copilot
created: 2025-10-16
classification: Internal
tags: [structured-notes, fcn, test-vector, v1.1, capital-at-risk, no-memory, baseline]
related:
  - ../specs/fcn-v1.1.0.md
  - ../business-rules.md
taxonomy:
  barrier_type: down-in
  settlement: physical-settlement
  coupon_memory: no-memory
  step_feature: no-step
  recovery_mode: capital-at-risk
---

# Scenario Description
Capital-at-risk baseline scenario with no-memory coupons. All observations stay above KI barrier, so no knock-in event occurs. At maturity, investor receives 100% notional despite capital-at-risk structure since KI was not triggered (BR-025).

## Parameters
| name | value |
|------|-------|
| trade_date | 2025-10-16 |
| issue_date | 2025-10-20 |
| maturity_date | 2026-10-20 |
| notional | 1_000_000 |
| currency | USD |
| issuer | SAMPLE_BANK_01 |
| underlying_symbols | ["AMZN.US", "ORCL.US", "PLTR.US"] |
| initial_levels | [180.00, 125.00, 35.00] |
| observation_dates | 2026-01-20, 2026-04-20, 2026-07-20, 2026-10-15 |
| coupon_payment_dates | 2026-01-20, 2026-04-20, 2026-07-20, 2026-10-20 |
| coupon_rate_pct | 0.04 |
| is_memory_coupon | false |
| memory_carry_cap_count | null |
| knock_in_barrier_pct | 0.60 |
| put_strike_pct | 0.80 |
| coupon_condition_threshold_pct | 0.85 |
| barrier_monitoring_type | discrete |
| settlement_type | physical-settlement |
| recovery_mode | capital-at-risk |
| day_count_convention | ACT/365 |

## Underlying Path
| obs # | observation_date | AMZN.US | ORCL.US | PLTR.US | Worst Performance | Coupon Condition (>=85%) | KI Breach (<=60%) |
|-------|------------------|---------|---------|---------|-------------------|--------------------------|-------------------|
| 1 | 2026-01-20 | 185.0 | 130.0 | 38.0 | 1.029 (AMZN) | Yes | No |
| 2 | 2026-04-20 | 178.0 | 127.0 | 36.5 | 0.989 (AMZN) | Yes | No |
| 3 | 2026-07-20 | 188.0 | 135.0 | 42.0 | 1.044 (AMZN) | Yes | No |
| 4 | 2026-10-15 | 192.0 | 140.0 | 45.0 | 1.067 (AMZN) | Yes | No |

Maturity final levels (2026-10-20): AMZN 195.0 (1.083), ORCL 142.0 (1.136), PLTR 46.0 (1.314)

## Event Timeline
| seq | date | event | details |
|-----|------|-------|---------|
| 1 | 2025-10-16 | TRADE | Trade executed |
| 2 | 2025-10-20 | ISSUE | Note issued |
| 3 | 2026-01-20 | OBS | Coupon pays (period 1) |
| 4 | 2026-04-20 | OBS | Coupon pays (period 2) |
| 5 | 2026-07-20 | OBS | Coupon pays (period 3) |
| 6 | 2026-10-15 | OBS | Coupon pays (period 4) |
| 7 | 2026-10-20 | MAT | Principal redemption (100% - no KI) |

## Expected Events
- ki_triggered: **false**
- autocall_triggered: false (no autocall feature in this branch)
- worst_of_final_ratio: 1.083 (AMZN: 195.0 / 180.0)

## Cash Flows
Coupon amount each period = notional × coupon_rate_pct = 1,000,000 × 0.04 = 40,000.

| date | type | amount | description |
|------|------|--------|-------------|
| 2026-01-20 | coupon | 40,000 | Period 1 coupon |
| 2026-04-20 | coupon | 40,000 | Period 2 coupon |
| 2026-07-20 | coupon | 40,000 | Period 3 coupon |
| 2026-10-20 | coupon | 40,000 | Period 4 coupon (paid on maturity) |
| 2026-10-20 | principal | 1,000,000 | Redemption (no KI, 100% notional per BR-025) |

Total coupons: 160,000; Total redemption: 1,000,000.

## Outcome Summary
- **Final redemption type**: Par (100% notional)
- **Settlement logic**: KI not triggered → 100% notional per BR-025

## Validation Points (Business Rules)
- BR-024: put_strike_pct (0.80) > knock_in_barrier_pct (0.60) ✓
- BR-025: No KI triggered → 100% redemption regardless of worst_of_final_ratio
- BR-026: barrier_monitoring_type = 'discrete' (normative)
- BR-005: No underlying breaches 60% KI barrier
- BR-006: All coupons eligible (all underlyings >= 85% threshold)

## Notes
- Demonstrates baseline capital-at-risk scenario with no loss
- Worst_of_final_ratio (1.083) > put_strike_pct (0.80), but irrelevant since KI not triggered
- No-memory variant: missed coupons (if any) not accumulated
