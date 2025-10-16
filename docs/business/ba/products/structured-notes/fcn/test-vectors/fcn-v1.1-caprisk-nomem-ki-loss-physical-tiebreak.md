---
title: FCN v1.1 Test Vector – Capital-at-Risk No-Memory – KI Loss Physical Tie-Break
doc_type: test-vector
status: Draft
version: 1.0.0
normative: true
branch_id: fcn-caprisk-nomem
spec_version: 1.1.0
owner: copilot
created: 2025-10-16
classification: Internal
tags: [structured-notes, fcn, test-vector, v1.1, capital-at-risk, no-memory, physical-settlement, tie-break]
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

Capital-at-risk scenario with physical worst-of settlement where two underlyings share identical worst_of_final_ratio below put_strike. Validates BR-025B deterministic tie-breaking: first asset in array selected for share delivery.

## Parameters

| name | value |
|------|-------|
| trade_date | 2025-10-16 |
| issue_date | 2025-10-20 |
| maturity_date | 2026-04-20 |
| notional | 1_000_000 |
| currency | USD |
| issuer | SAMPLE_BANK_01 |
| underlying_symbols | ["ABC.US", "XYZ.US", "DEF.US"] |
| initial_levels | [100.00, 100.00, 120.00] |
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

| obs # | observation_date | ABC.US | XYZ.US | DEF.US | Worst Performance | Coupon Condition (>=85%) | KI Breach (<=60%) |
|-------|------------------|--------|--------|--------|-------------------|--------------------------|-------------------|
| 1 | 2025-11-20 | 98.0 | 97.0 | 118.0 | 0.970 (XYZ) | Yes | No |
| 2 | 2025-12-20 | 55.0 | 62.0 | 100.0 | **0.550 (ABC)** | No | **Yes (ABC)** |
| 3 | 2026-01-20 | 62.0 | 65.0 | 105.0 | 0.620 (ABC) | No | No (already triggered) |
| 4 | 2026-02-20 | 65.0 | 66.0 | 108.0 | 0.650 (ABC) | No | No |
| 5 | 2026-03-20 | 68.0 | 69.0 | 110.0 | 0.680 (ABC) | No | No |
| 6 | 2026-04-15 | 70.0 | 70.0 | 115.0 | **0.700 (ABC=XYZ TIE)** | No | No |

Maturity final levels (2026-04-20 = observation 6): ABC 70.0 (0.700), XYZ 70.0 (0.700), DEF 115.0 (0.958)

**Tie-Break Scenario**: Both ABC and XYZ have identical worst_of_final_ratio = 0.700

## Event Timeline

| seq | date | event | details |
|-----|------|-------|---------|
| 1 | 2025-10-16 | TRADE | Trade executed |
| 2 | 2025-10-20 | ISSUE | Note issued |
| 3 | 2025-11-20 | OBS | Coupon pays (period 1) |
| 4 | 2025-12-20 | OBS | **KI TRIGGERED** (ABC breaches 60%); no coupon |
| 5 | 2026-01-20 | OBS | No coupon (condition not met) |
| 6 | 2026-02-20 | OBS | No coupon (condition not met) |
| 7 | 2026-03-20 | OBS | No coupon (condition not met) |
| 8 | 2026-04-15 | OBS | No coupon (condition not met); ABC and XYZ tie at 0.700 |
| 9 | 2026-04-20 | MAT | **Physical settlement** with tie-break (ABC selected) |

## Expected Events

- ki_triggered: **true** (obs 2, ABC breaches 60%)
- autocall_triggered: false
- worst_of_final_ratio: **0.700** (ABC and XYZ both: 70.0 / 100.0)
- worst_performer_selected_symbol: **ABC.US** (first in array, per BR-025B)
- worst_of_final_ratio < put_strike_pct (0.700 < 0.80) → **Loss incurred, physical settlement**

## Capital-at-Risk Physical Settlement Calculation (BR-025A, BR-025B)

Given:
- notional = 1,000,000
- put_strike_pct = 0.80
- worst_of_final_ratio = 0.700 (tied: ABC and XYZ)
- **worst_performer_selected_symbol = ABC.US** (first in underlying_symbols array per BR-025B)
- initial_level_worst = 100.00 (ABC)

### Tie-Break Resolution (BR-025B)
```
Candidates with worst_of_final_ratio = 0.700:
  - ABC.US: 70.0 / 100.0 = 0.700 (index 0)
  - XYZ.US: 70.0 / 100.0 = 0.700 (index 1)

Selection: ABC.US (first occurrence in underlying_symbols array)
```

### Share Count Calculation (BR-025A)
```
share_count_worst = floor( notional / (initial_level_worst × put_strike_pct) )
                  = floor( 1,000,000 / (100.00 × 0.80) )
                  = floor( 1,000,000 / 80.00 )
                  = floor( 12,500.0 )
                  = 12,500 shares (ABC.US)
```

### Residual Cash Calculation (BR-025A)
```
residual_cash = notional - (share_count_worst × initial_level_worst × put_strike_pct)
              = 1,000,000 - (12,500 × 80.00)
              = 1,000,000 - 1,000,000
              = $0.00
```

### Loss Amount Calculation (BR-025)
```
loss_amount = notional × (put_strike_pct - worst_of_final_ratio) / put_strike_pct
            = 1,000,000 × (0.80 - 0.700) / 0.80
            = 1,000,000 × 0.10 / 0.80
            = 1,000,000 × 0.125
            = 125,000

redemption_amount = notional - loss_amount
                  = 1,000,000 - 125,000
                  = 875,000
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
| 2026-04-20 | shares | **12,500 ABC.US shares** | Physical delivery of worst performer (ABC selected per BR-025B) |
| 2026-04-20 | cash | **$0.00** | No residual cash (exact share delivery) |

Total coupons: $10,833; Physical delivery: 12,500 ABC.US shares (no residual).

## Outcome Summary

- **Final redemption type**: Physical settlement with loss and tie-break
- **Share delivery**: 12,500 shares of ABC.US (first in array, per BR-025B)
- **Residual cash**: $0.00 (exact share delivery, no fractional remainder)
- **Settlement logic**: KI triggered AND worst_of_final_ratio (0.700) < put_strike_pct (0.80) → Physical delivery per BR-025A
- **Tie-break logic**: ABC.US and XYZ.US both 0.700; ABC.US selected (first occurrence) per BR-025B
- **Loss equivalent**: $125,000 (12.5% of notional) — investor receives assets worth $875,000 at maturity

## Validation Points (Business Rules)

- BR-005: KI triggered at obs 2 when ABC = 55.0 (0.550 < 0.60 threshold) ✓
- BR-006: Coupon conditions not met for periods 2-6 ✓
- BR-014: Observation dates strictly increasing and < maturity_date ✓
- BR-024: put_strike_pct (0.80) > knock_in_barrier_pct (0.60) ✓
- BR-025: KI triggered AND worst_of_final (0.700) < put_strike_pct (0.80) → Loss = 125,000 ✓
- BR-025A: share_count_worst = floor(1,000,000 / 80.00) = 12,500 shares ✓
- BR-025A: residual_cash = 1,000,000 - 1,000,000 = $0.00 ✓
- **BR-025B: Tie-break selection of ABC.US (first in array) when ABC and XYZ both 0.700 ✓**

## Notes

- Primary purpose: Validate BR-025B deterministic tie-breaking when multiple underlyings share identical worst_of_final_ratio
- Tie scenario: ABC.US (index 0) and XYZ.US (index 1) both have final_ratio = 0.700; ABC.US selected per first-in-array rule
- DEF.US (index 2) has higher performance (0.958), not a tie candidate
- Initial levels intentionally set equal (ABC=XYZ=100.00) and final levels equal (ABC=XYZ=70.0) to create exact tie
- Zero residual cash (exact share delivery) simplifies validation but does not affect tie-break logic
- Contrasts with fcn-v1.1-caprisk-nomem-ki-loss-physical.md where single clear worst performer exists
- Monthly coupon schedule (6 observations including maturity)
- Coupon rate 0.010833 per period ≈ 13% p.a. (0.010833 × 12 = 0.13)

## Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-16 | copilot | Initial normative test vector: tie-break scenario with ABC.US and XYZ.US both at 0.700 final ratio; validates BR-025B first-in-array selection; physical settlement with 12,500 ABC shares; normative=true |
