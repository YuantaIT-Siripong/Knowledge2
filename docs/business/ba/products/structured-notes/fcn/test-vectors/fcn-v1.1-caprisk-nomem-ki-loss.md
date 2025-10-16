---
title: FCN v1.1 Test Vector – Capital-at-Risk No-Memory – KI Triggered With Loss
doc_type: test-vector
status: Draft
version: 1.1.0
normative: true
branch_id: fcn-caprisk-nomem
spec_version: 1.1.0
owner: copilot
created: 2025-10-16
classification: Internal
tags: [structured-notes, fcn, test-vector, v1.1, capital-at-risk, no-memory, ki-loss]
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
Capital-at-risk scenario where KI is triggered and at maturity worst_of_final_ratio < put_strike_pct. Result: Proportional principal loss per BR-025 formula.

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
| 1 | 2026-01-20 | 175.0 | 120.0 | 32.0 | 0.914 (PLTR) | Yes | No |
| 2 | 2026-04-20 | 160.0 | 105.0 | 19.0 | **0.543 (PLTR)** | No | **Yes (PLTR)** |
| 3 | 2026-07-20 | 165.0 | 110.0 | 21.0 | 0.600 (PLTR) | No | No (already triggered) |
| 4 | 2026-10-15 | 170.0 | 115.0 | 24.0 | 0.686 (PLTR) | No | No |

Maturity final levels (2026-10-20): AMZN 172.0 (0.956), ORCL 117.0 (0.936), PLTR 25.0 (0.714)

## Event Timeline
| seq | date | event | details |
|-----|------|-------|---------|
| 1 | 2025-10-16 | TRADE | Trade executed |
| 2 | 2025-10-20 | ISSUE | Note issued |
| 3 | 2026-01-20 | OBS | Coupon pays (period 1) |
| 4 | 2026-04-20 | OBS | **KI TRIGGERED** (PLTR breaches 60%); no coupon |
| 5 | 2026-07-20 | OBS | No coupon (condition not met) |
| 6 | 2026-10-15 | OBS | No coupon (condition not met) |
| 7 | 2026-10-20 | MAT | **Principal loss** (worst_of_final < put_strike) |

## Expected Events
- ki_triggered: **true** (obs 2, PLTR breaches 60%)
- autocall_triggered: false
- worst_of_final_ratio: **0.714** (PLTR: 25.0 / 35.0)
- worst_of_final_ratio < put_strike_pct (0.714 < 0.80) → **Loss incurred**

## Capital-at-Risk Loss Calculation (BR-025)
Given:
- notional = 1,000,000
- put_strike_pct = 0.80
- worst_of_final_ratio = 0.714

Loss formula (BR-025):
```
loss_amount = notional × (put_strike_pct - worst_of_final_ratio) / put_strike_pct
            = 1,000,000 × (0.80 - 0.714) / 0.80
            = 1,000,000 × 0.086 / 0.80
            = 1,000,000 × 0.1075
            = 107,500

redemption_amount = notional - loss_amount
                  = 1,000,000 - 107,500
                  = 892,500
```

## Cash Flows
| date | type | amount | description |
|------|------|--------|-------------|
| 2026-01-20 | coupon | 40,000 | Period 1 coupon |
| 2026-04-20 | coupon | 0 | Period 2 missed (condition not met) |
| 2026-07-20 | coupon | 0 | Period 3 missed (condition not met) |
| 2026-10-20 | coupon | 0 | Period 4 missed (condition not met) |
| 2026-10-20 | principal | **892,500** | Redemption with loss per BR-025 |
| 2026-10-20 | loss | **(107,500)** | Capital-at-risk loss |

Total coupons: 40,000; Total redemption: 892,500; **Total loss: 107,500 (10.75% of notional)**.

## Outcome Summary
- **Final redemption type**: Loss (89.25% of notional)
- **Settlement logic**: KI triggered AND worst_of_final_ratio (0.714) < put_strike_pct (0.80) → Proportional loss per BR-025

## Validation Points (Business Rules)
- BR-024: put_strike_pct (0.80) > knock_in_barrier_pct (0.60) ✓
- BR-025: KI triggered AND worst_of_final (0.714) < put_strike_pct (0.80) → Loss = notional × (0.80 - 0.714) / 0.80 = 107,500
- BR-005: KI triggered at obs 2 when PLTR = 19.0 (0.543 < 0.60 threshold)
- BR-006: Coupon conditions not met for periods 2-4

## Notes
- Demonstrates core capital-at-risk settlement with principal loss
- Loss percentage: (put_strike - worst_of_final) / put_strike = 10.75%
- Worst performer (PLTR) drives loss calculation: 25.0 / 35.0 = 71.4% of initial
- Contrasts with deprecated BR-011 (v1.0 par recovery) which would return 100% regardless of performance
