---
title: FCN v1.1 Sample Scenarios – Discrete Monitoring with 6-Month Monthly Schedule
doc_type: scenario
status: Draft
version: 1.0.0
owner: copilot
created: 2025-10-16
classification: Internal
tags: [fcn, scenarios, capital-at-risk, discrete-monitoring, v1.1]
related:
  - ../specs/fcn-v1.1.0.md
  - ../business-rules.md
  - ../settlement-physical-worst-of.md
---

# FCN v1.1 Sample Scenarios

## Overview

This document presents four revised sample scenarios for Fixed Coupon Note (FCN) v1.1 with discrete observation monitoring. All scenarios use a standard 6-month monthly observation schedule with observations on the 17th of each month (or nearest business day).

**Key Updates from Previous Versions**:
- Observation dates changed from 10th to **17th of each month**
- Added **6th observation date** (17/03/2026, maturity date) to complete the 6-month monthly schedule
- All scenarios use **discrete monitoring** (no mid-month knock-in events)
- Scenario 4 clarifies that autocall triggers when ALL underlyings **≥** knock-out barrier (equality allowed per BR-021)

## Standard 6-Month Monthly Observation Schedule

| Observation # | Date | Notes |
|---------------|------|-------|
| 1 | 2025-10-17 | Month 0 (issue month) |
| 2 | 2025-11-17 | Month 1 |
| 3 | 2025-12-17 | Month 2 |
| 4 | 2026-01-17 | Month 3 |
| 5 | 2026-02-17 | Month 4 |
| 6 | 2026-03-17 | Month 5 (maturity) |

**Schedule Characteristics**:
- **Frequency**: Monthly (1-month intervals)
- **Day of Month**: 17th (business day adjustment if needed)
- **Total Duration**: 6 months from issue to maturity
- **Monitoring Type**: Discrete (observations only on scheduled dates)

## Common Trade Parameters (All Scenarios)

| Parameter | Value |
|-----------|-------|
| product_code | FCN |
| spec_version | 1.1.0 |
| trade_date | 2025-10-10 |
| issue_date | 2025-10-17 |
| maturity_date | 2026-03-17 |
| notional | 1,000,000 |
| currency | USD |
| issuer | SAMPLE_BANK_01 |
| underlying_symbols | ["AMZN.US", "ORCL.US", "PLTR.US"] |
| initial_levels | [180.00, 125.00, 35.00] |
| observation_dates | [2025-10-17, 2025-11-17, 2025-12-17, 2026-01-17, 2026-02-17, 2026-03-17] |
| coupon_payment_dates | [2025-10-17, 2025-11-17, 2025-12-17, 2026-01-17, 2026-02-17, 2026-03-17] |
| coupon_rate_pct | 0.04 (4% per period) |
| knock_in_barrier_pct | 0.60 (60%) |
| put_strike_pct | 0.80 (80%) |
| coupon_condition_threshold_pct | 0.85 (85%) |
| barrier_monitoring_type | discrete |
| settlement_type | physical-settlement |
| day_count_convention | ACT/365 |

---

## Scenario 1: Capital-at-Risk Baseline (No KI, Par Recovery)

### Description
No knock-in event occurs during the note's lifecycle. All underlyings stay above the KI barrier (60%) at all observation dates. Investor receives all coupons and 100% notional at maturity.

### Market Path

| Observation | Date | AMZN | ORCL | PLTR | Min Ratio | Coupon? | KI Event? |
|-------------|------|------|------|------|-----------|---------|-----------|
| 1 | 2025-10-17 | 185.0 | 130.0 | 38.0 | 1.029 | Yes | No |
| 2 | 2025-11-17 | 188.0 | 132.0 | 39.5 | 1.029 | Yes | No |
| 3 | 2025-12-17 | 192.0 | 135.0 | 41.0 | 1.044 | Yes | No |
| 4 | 2026-01-17 | 195.0 | 138.0 | 43.0 | 1.067 | Yes | No |
| 5 | 2026-02-17 | 198.0 | 140.0 | 45.0 | 1.083 | Yes | No |
| 6 | 2026-03-17 | 200.0 | 142.0 | 46.0 | 1.100 | Yes | No |

### Settlement at Maturity
- **KI Triggered**: No
- **Worst-of Final Ratio**: 1.100 (AMZN)
- **Redemption**: 100% notional = $1,000,000 per BR-025
- **Total Coupons**: 6 × $40,000 = $240,000
- **Settlement Type**: Cash (no share delivery since no loss condition)

### Business Rules Validated
- BR-005: KI not triggered (no underlying ≤ 60% barrier)
- BR-006: All coupons eligible (all underlyings ≥ 85% threshold)
- BR-025: No KI → 100% notional redemption

---

## Scenario 2: Capital-at-Risk with KI but No Loss

### Description
Knock-in event occurs at observation 3 (17/12/2025) when PLTR drops to 20.0 (57.1% of initial). However, at maturity, worst performer recovers above put_strike_pct (80%), so investor receives 100% notional despite KI trigger.

### Market Path

| Observation | Date | AMZN | ORCL | PLTR | Min Ratio | Coupon? | KI Event? |
|-------------|------|------|------|------|-----------|---------|-----------|
| 1 | 2025-10-17 | 182.0 | 128.0 | 37.0 | 1.011 | Yes | No |
| 2 | 2025-11-17 | 178.0 | 125.0 | 32.0 | 0.914 | Yes | No |
| 3 | 2025-12-17 | 175.0 | 122.0 | 20.0 | 0.571 | No | **Yes (PLTR)** |
| 4 | 2026-01-17 | 180.0 | 125.0 | 25.0 | 0.714 | No | - |
| 5 | 2026-02-17 | 185.0 | 130.0 | 28.0 | 0.800 | No | - |
| 6 | 2026-03-17 | 188.0 | 135.0 | 30.0 | 0.857 | Yes | - |

### Settlement at Maturity
- **KI Triggered**: Yes (observation 3)
- **Worst-of Final Ratio**: 0.857 (PLTR: 30.0 / 35.0)
- **Put Strike**: 0.80 (80%)
- **Condition**: 0.857 > 0.80 → **No loss incurred**
- **Redemption**: 100% notional = $1,000,000 per BR-025
- **Total Coupons**: 3 × $40,000 = $120,000 (observations 1, 2, 6 only)
- **Settlement Type**: Cash

### Business Rules Validated
- BR-005: KI triggered when PLTR ≤ 60% barrier (observation 3)
- BR-006: Coupon condition evaluated independently
- BR-025: KI + worst_of_final ≥ put_strike_pct → 100% redemption

---

## Scenario 3: Capital-at-Risk with Loss (Physical Settlement)

### Description
Knock-in event occurs and worst performer finishes below put_strike_pct at maturity. Investor incurs proportional loss. Physical settlement delivers worst-performing shares per BR-025A.

### Market Path

| Observation | Date | AMZN | ORCL | PLTR | Min Ratio | Coupon? | KI Event? |
|-------------|------|------|------|------|-----------|---------|-----------|
| 1 | 2025-10-17 | 178.0 | 126.0 | 36.0 | 0.989 | Yes | No |
| 2 | 2025-11-17 | 172.0 | 122.0 | 28.0 | 0.800 | No | No |
| 3 | 2025-12-17 | 168.0 | 118.0 | 20.0 | 0.571 | No | **Yes (PLTR)** |
| 4 | 2026-01-17 | 170.0 | 120.0 | 22.0 | 0.629 | No | - |
| 5 | 2026-02-17 | 172.0 | 122.0 | 24.0 | 0.686 | No | - |
| 6 | 2026-03-17 | 175.0 | 125.0 | 25.0 | 0.714 | No | - |

### Settlement at Maturity
- **KI Triggered**: Yes (observation 3)
- **Worst-of Final Ratio**: 0.714 (PLTR: 25.0 / 35.0)
- **Put Strike**: 0.80 (80%)
- **Condition**: 0.714 < 0.80 → **Loss incurred**
- **Loss Calculation** (BR-025):
  - loss_amount = 1,000,000 × (0.80 - 0.714) / 0.80 = $107,500
  - redemption_amount = 1,000,000 - 107,500 = $892,500
- **Physical Settlement** (BR-025A):
  - Worst performer: PLTR (initial_level = 35.00)
  - share_count_worst = floor(1,000,000 / (35.00 × 0.80)) = floor(35,714.29) = **35,714 shares**
  - residual_cash = 1,000,000 - (35,714 × 28.00) = $8.00
- **Total Coupons**: 1 × $40,000 = $40,000 (observation 1 only)
- **Settlement**: Deliver 35,714 shares of PLTR + $8.00 residual cash

### Business Rules Validated
- BR-005: KI triggered
- BR-025: KI + worst_of_final < put_strike_pct → proportional loss
- BR-025A: Physical settlement share count with floor rounding, residual cash calculation

---

## Scenario 4: Autocall Trigger with Equality (Early Redemption)

### Description
Autocall (knock-out) feature present. At observation 4 (17/01/2026), ALL underlyings close **exactly at or above** the knock-out barrier (110% of initial). Autocall triggers per BR-021 with **equality allowed** (≥), causing early redemption of principal plus due coupon.

### Market Path

| Observation | Date | AMZN | ORCL | PLTR | Min Ratio | Autocall Check | Coupon? | Event |
|-------------|------|------|------|------|-----------|----------------|---------|-------|
| 1 | 2025-10-17 | 185.0 | 130.0 | 38.0 | 1.029 | Below KO | Yes | - |
| 2 | 2025-11-17 | 192.0 | 135.0 | 40.0 | 1.044 | Below KO | Yes | - |
| 3 | 2025-12-17 | 195.0 | 136.0 | 38.0 | 1.067 | Below KO | Yes | - |
| 4 | 2026-01-17 | 198.0 | 137.5 | 38.5 | 1.100 | **≥ KO (110%)** | Yes | **Autocall** |
| 5 | 2026-02-17 | - | - | - | - | N/A | - | Note terminated |
| 6 | 2026-03-17 | - | - | - | - | N/A | - | Note terminated |

### Additional Parameters (Autocall-Specific)
- knock_out_barrier_pct: 1.10 (110%)
- auto_call_observation_logic: all-underlyings
- recovery_mode: capital-at-risk (not relevant; autocall preempts)

### Settlement at Observation 4 (Early Redemption)
- **Autocall Triggered**: Yes (all underlyings ≥ 110% at observation 4)
- **Equality Semantics**: AMZN = 198.0 / 180.0 = 1.100 (exactly 110%, triggers per BR-021)
- **Redemption**: 100% notional = $1,000,000
- **Coupon at Autocall**: $40,000 (observation 4 coupon)
- **Total Coupons Paid**: 4 × $40,000 = $160,000
- **Total Settlement**: $1,000,000 principal + $40,000 coupon = $1,040,000
- **No Further Observations**: Note terminates; observations 5-6 skipped

### Business Rules Validated
- BR-021: Autocall triggers when ALL underlyings close **≥** initial × knock_out_barrier_pct (equality triggers)
- BR-023: Autocall precedence preempts maturity settlement (capital-at-risk logic not evaluated)
- BR-006: Coupon eligibility independent of autocall barrier

---

## Key Observations

### Discrete Monitoring Semantics
- All scenarios use **discrete monitoring** (barrier_monitoring_type = 'discrete')
- KI and autocall events only evaluated at scheduled observation dates
- No mid-month or intraday events possible
- Consistent with BR-026 normative requirement for v1.1

### 6-Month Monthly Schedule
- Standard schedule: 6 observations over 6 months (including maturity)
- Observation dates: 17th of each month (Oct → Mar)
- Maturity observation date (6th) is critical for final settlement determination

### Autocall Equality Semantics (BR-021)
- Autocall triggers when ALL underlyings ≥ knock_out_barrier_pct
- **Equality is sufficient** to trigger (not strictly greater-than)
- Scenario 4 demonstrates exact 110% level triggering autocall
- Important for edge case testing and investor communication

### Physical Settlement (BR-025A)
- Share delivery based on worst performer at maturity
- Strike cost calculation: initial_level_worst × put_strike_pct
- Floor rounding ensures whole shares only
- Residual cash paid separately if ≥ threshold

## References

- [FCN v1.1.0 Specification](../specs/fcn-v1.1.0.md)
- [Business Rules](../business-rules.md) — BR-005, BR-006, BR-021, BR-023, BR-025, BR-025A
- [Physical Worst-of Settlement Guideline](../settlement-physical-worst-of.md) — BR-025A operationalization
- [Test Vectors](../test-vectors/README.md) — Normative validation scenarios

## Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-16 | copilot | Initial scenarios: revised observation dates to 17th, added 6th observation (maturity), clarified discrete monitoring, updated autocall equality semantics per BR-021 |
