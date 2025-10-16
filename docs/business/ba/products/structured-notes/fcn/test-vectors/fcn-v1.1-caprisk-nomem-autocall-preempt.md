---
title: FCN v1.1 Test Vector – Capital-at-Risk No-Memory – Autocall Preempts Settlement
doc_type: test-vector
status: Draft
version: 1.1.0
normative: true
branch_id: fcn-caprisk-nomem-autocall
spec_version: 1.1.0
owner: copilot
created: 2025-10-16
classification: Internal
tags: [structured-notes, fcn, test-vector, v1.1, capital-at-risk, no-memory, autocall-precedence]
related:
  - ../specs/fcn-v1.1.0.md
  - ../business-rules.md
taxonomy:
  barrier_type: down-in
  settlement: physical-settlement
  coupon_memory: no-memory
  step_feature: autocall
  recovery_mode: capital-at-risk
---

# Scenario Description
Demonstrates precedence: autocall (knock-out) triggers before maturity, preempting capital-at-risk settlement evaluation. Even though KI was previously triggered, autocall takes priority and investor receives 100% notional plus due coupon (BR-021, BR-023).

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
| knock_out_barrier_pct | 1.10 |
| auto_call_observation_logic | all-underlyings |
| coupon_condition_threshold_pct | 0.85 |
| barrier_monitoring_type | discrete |
| settlement_type | physical-settlement |
| recovery_mode | capital-at-risk |

## Underlying Path
| obs # | observation_date | AMZN.US | ORCL.US | PLTR.US | Worst | Best | Coupon | KI | Autocall |
|-------|------------------|---------|---------|---------|-------|------|--------|----|----|
| 1 | 2026-01-20 | 185.0 | 130.0 | 32.0 | 0.914 | 1.028 | Yes | No | No (not all >= 110%) |
| 2 | 2026-04-20 | 170.0 | 120.0 | 20.0 | **0.571** | 0.960 | No | **Yes** | No |
| 3 | 2026-07-20 | 195.0 | 140.0 | 38.0 | 1.086 | 1.120 | Yes | - | No (PLTR < 110%) |
| 4 | 2026-10-15 | **200.0** | **140.0** | **39.0** | **1.114** | **1.120** | Yes | - | **Yes (all >= 110%)** |

## Event Timeline
| seq | date | event | details |
|-----|------|-------|---------|
| 1 | 2025-10-16 | TRADE | Trade executed |
| 2 | 2025-10-20 | ISSUE | Note issued |
| 3 | 2026-01-20 | OBS | Coupon pays (period 1) |
| 4 | 2026-04-20 | OBS | KI TRIGGERED (PLTR breaches 60%); no coupon |
| 5 | 2026-07-20 | OBS | Coupon pays (period 3) |
| 6 | 2026-10-15 | OBS | **AUTOCALL TRIGGERED** (all underlyings >= 110%); coupon pays; early redemption |
| 7 | 2026-10-15 | SETTLEMENT | Early redemption: 100% principal + period 4 coupon |

## Expected Events
- ki_triggered: **true** (obs 2, PLTR breached)
- autocall_triggered: **true** (obs 4, all underlyings >= 110%)
- worst_of_final_ratio: **N/A** (autocall preempts maturity settlement)
- redemption_type: **Autocall** (priority over capital-at-risk)

## Cash Flows
| date | type | amount | description |
|------|------|--------|-------------|
| 2026-01-20 | coupon | 40,000 | Period 1 coupon |
| 2026-04-20 | coupon | 0 | Period 2 missed (condition not met) |
| 2026-07-20 | coupon | 40,000 | Period 3 coupon |
| 2026-10-15 | coupon | 40,000 | Period 4 coupon (paid on autocall) |
| 2026-10-15 | principal | 1,000,000 | **Early redemption via autocall (BR-021)** |

Total coupons: 120,000; Total redemption: 1,000,000 (early).

## Outcome Summary
- **Final redemption type**: Autocall (early redemption)
- **Settlement logic**: Autocall (BR-021) takes precedence over capital-at-risk settlement (BR-025) per BR-023

## Validation Points (Business Rules)
- BR-020: knock_out_barrier_pct (1.10) in valid range ✓
- BR-021: Autocall triggers when ALL underlyings >= initial × 1.10 at obs 4
- BR-023: Autocall evaluated BEFORE capital-at-risk settlement; preempts maturity evaluation
- BR-024: put_strike_pct (0.80) > knock_in_barrier_pct (0.60) ✓
- BR-025: Capital-at-risk settlement NOT evaluated due to autocall

## Notes
- Demonstrates payoff precedence: KO → Coupon → KI → Capital-at-Risk Settlement
- Even though KI triggered (loss potential), autocall provides full principal recovery
- Autocall obs 4: AMZN 200.0/180.0=1.111, ORCL 140.0/125.0=1.120, PLTR 39.0/35.0=1.114 (all >= 1.10)
- Capital-at-risk settlement never evaluated due to early termination
- Contrasts with fcn-v1.1-caprisk-nomem-ki-loss where no autocall and loss incurred
