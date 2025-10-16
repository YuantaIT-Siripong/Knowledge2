---
title: FCN v1.1 Test Vector – Capital-at-Risk No-Memory – KI Loss with Physical Settlement
doc_type: test-vector
status: Draft
version: 1.1.0
normative: true
branch_id: fcn-caprisk-nomem
spec_version: 1.1.0
owner: copilot
created: 2025-10-16
classification: Internal
tags: [structured-notes, fcn, test-vector, v1.1, capital-at-risk, no-memory, physical-settlement]
related:
  - ../specs/fcn-v1.1.0.md
  - ../business-rules.md
  - ../settlement-physical-worst-of.md
taxonomy:
  barrier_type: down-in
  settlement: physical-settlement
  coupon_memory: no-memory
  step_feature: no-step
  recovery_mode: capital-at-risk
---

# Scenario Description

Capital-at-risk scenario with physical worst-of settlement. KI is triggered and at maturity worst_of_final_ratio < put_strike_pct. Investor receives shares of worst-performing underlying plus residual cash per BR-025A.

## Parameters

| name | value |
|------|-------|
| trade_date | 2025-10-16 |
| issue_date | 2025-10-20 |
| maturity_date | 2026-04-20 |
| notional | 1_000_000 |
| currency | USD |
| issuer | SAMPLE_BANK_01 |
| underlying_symbols | ["AMZN.US", "ORCL.US", "PLTR.US"] |
| initial_levels | [180.00, 125.00, 35.00] |
| observation_dates | 2025-11-20, 2025-12-20, 2026-01-20, 2026-02-20, 2026-03-20, 2026-04-15 |
| coupon_payment_dates | 2025-11-20, 2025-12-20, 2026-01-20, 2026-02-20, 2026-03-20, 2026-04-20 |
| coupon_rate_pct | 0.010833 |
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
| 1 | 2025-11-20 | 177.0 | 122.0 | 33.0 | 0.943 (PLTR) | Yes | No |
| 2 | 2025-12-20 | 165.0 | 110.0 | 19.0 | **0.543 (PLTR)** | No | **Yes (PLTR)** |
| 3 | 2026-01-20 | 170.0 | 115.0 | 21.0 | 0.600 (PLTR) | No | No (already triggered) |
| 4 | 2026-02-20 | 172.0 | 118.0 | 23.0 | 0.657 (PLTR) | No | No |
| 5 | 2026-03-20 | 175.0 | 120.0 | 24.0 | 0.686 (PLTR) | No | No |
| 6 | 2026-04-15 | 172.0 | 117.0 | 25.0 | 0.714 (PLTR) | No | No |

Maturity final levels (2026-04-20 = observation 6): AMZN 172.0 (0.956), ORCL 117.0 (0.936), PLTR 25.0 (0.714)

## Event Timeline

| seq | date | event | details |
|-----|------|-------|---------|
| 1 | 2025-10-16 | TRADE | Trade executed |
| 2 | 2025-10-20 | ISSUE | Note issued |
| 3 | 2025-11-20 | OBS | Coupon pays (period 1) |
| 4 | 2025-12-20 | OBS | **KI TRIGGERED** (PLTR breaches 60%); no coupon |
| 5 | 2026-01-20 | OBS | No coupon (condition not met) |
| 6 | 2026-02-20 | OBS | No coupon (condition not met) |
| 7 | 2026-03-20 | OBS | No coupon (condition not met) |
| 8 | 2026-04-15 | OBS | No coupon (condition not met) |
| 9 | 2026-04-20 | MAT | **Physical settlement** (worst_of_final < put_strike) |

## Expected Events

- ki_triggered: **true** (obs 2, PLTR breaches 60%)
- autocall_triggered: false
- worst_of_final_ratio: **0.714** (PLTR: 25.0 / 35.0)
- worst_of_final_ratio < put_strike_pct (0.714 < 0.80) → **Loss incurred, physical settlement**

## Capital-at-Risk Physical Settlement Calculation (BR-025A)

Given:
- notional = 1,000,000
- put_strike_pct = 0.80
- worst_of_final_ratio = 0.714
- worst_performer = PLTR
- initial_level_worst = 35.00

### Share Count Calculation (BR-025A)
```
share_count_worst = floor( notional / (initial_level_worst × put_strike_pct) )
                  = floor( 1,000,000 / (35.00 × 0.80) )
                  = floor( 1,000,000 / 28.00 )
                  = floor( 35,714.285... )
                  = 35,714 shares
```

### Residual Cash Calculation (BR-025A)
```
residual_cash = notional - (share_count_worst × initial_level_worst × put_strike_pct)
              = 1,000,000 - (35,714 × 28.00)
              = 1,000,000 - 999,992
              = $8.00
```

### Loss Amount Calculation (BR-025)
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
| 2025-11-20 | coupon | 10,833 | Period 1 coupon (notional × 0.010833) |
| 2025-12-20 | coupon | 0 | Period 2 missed (condition not met) |
| 2026-01-20 | coupon | 0 | Period 3 missed (condition not met) |
| 2026-02-20 | coupon | 0 | Period 4 missed (condition not met) |
| 2026-03-20 | coupon | 0 | Period 5 missed (condition not met) |
| 2026-04-20 | coupon | 0 | Period 6 missed (condition not met) |
| 2026-04-20 | shares | **35,714 PLTR shares** | Physical delivery of worst performer |
| 2026-04-20 | cash | **$8.00** | Residual cash (≥ $0.01 threshold, paid separately) |

Total coupons: $10,833; Physical delivery: 35,714 PLTR shares + $8 residual cash.

## Outcome Summary

- **Final redemption type**: Physical settlement with loss
- **Share delivery**: 35,714 shares of PLTR (worst performer)
- **Residual cash**: $8.00 (paid separately, above dust threshold)
- **Settlement logic**: KI triggered AND worst_of_final_ratio (0.714) < put_strike_pct (0.80) → Physical delivery per BR-025A
- **Loss equivalent**: $107,500 (10.75% of notional) — investor receives assets worth ~$892,500 at maturity

## Validation Points (Business Rules)

- BR-005: KI triggered at obs 2 when PLTR = 19.0 (0.543 < 0.60 threshold) ✓
- BR-006: Coupon conditions not met for periods 2-6 ✓
- BR-014: Observation dates strictly increasing and < maturity_date ✓
- BR-024: put_strike_pct (0.80) > knock_in_barrier_pct (0.60) ✓
- BR-025: KI triggered AND worst_of_final (0.714) < put_strike_pct (0.80) → Loss = 107,500
- BR-025A: share_count_worst = floor(1,000,000 / 28.00) = 35,714 shares ✓
- BR-025A: residual_cash = 1,000,000 - 999,992 = $8.00 ✓
- BR-025A: residual_cash ($8.00) ≥ threshold ($0.01) → paid separately ✓

## Notes

- Demonstrates complete physical worst-of settlement mechanics with share delivery
- Monthly coupon schedule (6 observations including maturity)
- Coupon rate 0.010833 per period ≈ 13% p.a. (0.010833 × 12 = 0.13)
- Share count and residual cash match guideline example exactly (35,714 shares + $8)
- Worst performer (PLTR) drives settlement: 25.0 / 35.0 = 71.4% of initial
- Loss percentage: (put_strike - worst_of_final) / put_strike = 10.75%
- Contrasts with cash settlement (fcn-v1.1-caprisk-nomem-ki-loss.md) where redemption is cash

## Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-16 | copilot | Placeholder test vector created; normative=false pending full scenario development; references BR-025A |
| 1.1.0 | 2025-10-16 | copilot | Completed normative test vector with full scenario: 6-month monthly schedule, KI trigger at obs 2, physical settlement with 35,714 PLTR shares + $8 residual; validates BR-005, BR-025, BR-025A; normative=true |
