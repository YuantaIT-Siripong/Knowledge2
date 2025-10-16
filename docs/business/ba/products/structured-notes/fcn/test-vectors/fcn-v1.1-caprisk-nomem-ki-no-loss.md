---
title: FCN v1.1 Test Vector – Capital-at-Risk No-Memory – KI Triggered But No Loss
doc_type: test-vector
status: Draft
version: 1.1.0
normative: true
branch_id: fcn-caprisk-nomem
spec_version: 1.1.0
owner: copilot
created: 2025-10-16
classification: Internal
tags: [structured-notes, fcn, test-vector, v1.1, capital-at-risk, no-memory, ki-no-loss]
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
Capital-at-risk scenario where KI is triggered during observation period, but at maturity the worst_of_final_ratio recovers above put_strike_pct. Result: 100% notional redemption despite KI event (BR-025).

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
| knock_in_barrier_pct | 0.60 |
| put_strike_pct | 0.80 |
| coupon_condition_threshold_pct | 0.85 |
| barrier_monitoring_type | discrete |
| settlement_type | physical-settlement |
| recovery_mode | capital-at-risk |

## Underlying Path
| obs # | observation_date | AMZN.US | ORCL.US | PLTR.US | Worst Performance | Coupon Condition (>=85%) | KI Breach (<=60%) |
|-------|------------------|---------|---------|---------|-------------------|--------------------------|-------------------|
| 1 | 2026-01-20 | 175.0 | 120.0 | 30.0 | 0.857 (PLTR) | Yes | No |
| 2 | 2026-04-20 | 165.0 | 110.0 | 20.0 | **0.571 (PLTR)** | No | **Yes (PLTR)** |
| 3 | 2026-07-20 | 172.0 | 115.0 | 28.0 | 0.800 (PLTR) | No | No (already triggered) |
| 4 | 2026-10-15 | 180.0 | 125.0 | 32.0 | 0.914 (PLTR) | Yes | No |

Maturity final levels (2026-10-20): AMZN 185.0 (1.028), ORCL 130.0 (1.040), PLTR 30.0 (0.857)

## Event Timeline
| seq | date | event | details |
|-----|------|-------|---------|
| 1 | 2025-10-16 | TRADE | Trade executed |
| 2 | 2025-10-20 | ISSUE | Note issued |
| 3 | 2026-01-20 | OBS | Coupon pays (period 1) |
| 4 | 2026-04-20 | OBS | **KI TRIGGERED** (PLTR breaches 60%); no coupon (condition not met) |
| 5 | 2026-07-20 | OBS | No coupon (condition not met) |
| 6 | 2026-10-15 | OBS | Coupon pays (period 4) |
| 7 | 2026-10-20 | MAT | Principal redemption (100% - worst_of_final >= put_strike) |

## Expected Events
- ki_triggered: **true** (obs 2, PLTR breaches 60%)
- autocall_triggered: false
- worst_of_final_ratio: **0.857** (PLTR: 30.0 / 35.0)
- worst_of_final_ratio >= put_strike_pct (0.857 >= 0.80) → **No loss**

## Cash Flows
| date | type | amount | description |
|------|------|--------|-------------|
| 2026-01-20 | coupon | 40,000 | Period 1 coupon |
| 2026-04-20 | coupon | 0 | Period 2 missed (condition not met) |
| 2026-07-20 | coupon | 0 | Period 3 missed (condition not met) |
| 2026-10-20 | coupon | 40,000 | Period 4 coupon (condition met) |
| 2026-10-20 | principal | 1,000,000 | Redemption (KI triggered but worst_of_final >= put_strike per BR-025) |

Total coupons: 80,000; Total redemption: 1,000,000.

## Outcome Summary
- **Final redemption type**: Par (100% notional)
- **Settlement logic**: KI triggered BUT worst_of_final_ratio (0.857) >= put_strike_pct (0.80) → 100% redemption per BR-025

## Validation Points (Business Rules)
- BR-024: put_strike_pct (0.80) > knock_in_barrier_pct (0.60) ✓
- BR-025: KI triggered AND worst_of_final (0.857) >= put_strike_pct (0.80) → 100% redemption (no loss)
- BR-005: KI triggered at obs 2 when PLTR = 20.0 (0.571 < 0.60 threshold)
- BR-006: Coupon condition evaluation independent of KI status

## Notes
- Demonstrates "close call" scenario: KI triggered but performance recovers by maturity
- Critical threshold: worst_of_final_ratio (0.857) just above put_strike_pct (0.80)
- Illustrates protective nature of put strike: allows partial recovery without loss
- No-memory: missed coupons in periods 2-3 not recovered
