---
title: FCN v1.1 Test Vector – Capital-at-Risk No-Memory – KI Loss with Physical Settlement (Placeholder)
doc_type: test-vector
status: Draft
version: 1.1.0
normative: false
branch_id: fcn-caprisk-nomem
spec_version: 1.1.0
owner: copilot
created: 2025-10-16
classification: Internal
tags: [structured-notes, fcn, test-vector, v1.1, capital-at-risk, no-memory, physical-settlement, placeholder]
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

**PLACEHOLDER TEST VECTOR** — Non-normative pending full implementation.

This test vector will demonstrate physical worst-of settlement mechanics per BR-025A when capital-at-risk mode is triggered with loss condition. Investor receives shares of worst-performing underlying plus residual cash.

## Scope

This vector validates:
- BR-025A: Physical settlement share count calculation (floor rounding)
- BR-025A: Residual cash calculation and threshold treatment
- BR-025: Capital-at-risk conditional loss logic
- BR-005: Knock-in detection

## Implementation Status

**Status**: Placeholder  
**Normative**: No (pending full scenario development)  
**Target Completion**: Q4 2025

## Planned Parameters

| name | value |
|------|-------|
| trade_date | TBD |
| issue_date | TBD |
| maturity_date | TBD |
| notional | 1_000_000 |
| currency | USD |
| issuer | SAMPLE_BANK_01 |
| underlying_symbols | ["AMZN.US", "ORCL.US", "PLTR.US"] |
| initial_levels | [180.00, 125.00, 35.00] |
| knock_in_barrier_pct | 0.60 |
| put_strike_pct | 0.80 |
| coupon_rate_pct | 0.04 |
| is_memory_coupon | false |
| barrier_monitoring_type | discrete |
| settlement_type | **physical-settlement** |
| recovery_mode | **capital-at-risk** |

## Expected Outcomes

### At Maturity (Planned)
- **KI Triggered**: Yes
- **Worst-of Final Ratio**: < 0.80 (below put strike)
- **Loss Condition**: Triggered
- **Physical Settlement**:
  - Deliver: `share_count_worst` shares of worst performer
  - Residual Cash: Calculated per BR-025A formula
  - Treatment: Separate payment if ≥ minimum_cash_dust_threshold

### Validation Points (Planned)

1. **BR-025**: Loss amount calculation
   - `loss_amount = notional × (put_strike_pct - worst_of_final_ratio) / put_strike_pct`

2. **BR-025A**: Share count calculation
   - `share_count_worst = floor(notional / (initial_level_worst × put_strike_pct))`
   
3. **BR-025A**: Residual cash
   - `residual_cash = notional - (share_count_worst × initial_level_worst × put_strike_pct)`

4. **BR-025A**: Threshold treatment
   - If residual_cash ≥ minimum_cash_dust_threshold: pay separately
   - Else: add to final coupon or principal

## Development Notes

### To Complete This Vector:
1. Define full observation schedule (6 dates recommended)
2. Create market path with KI event and loss condition
3. Calculate exact share count and residual cash
4. Validate against BR-025A mechanics
5. Add detailed cash flow table
6. Update normative flag to `true`
7. Add to manifest normative_vectors list

### Reference Implementation
See [Sample Scenario 3](../scenarios/fcn-v1.1-sample-scenarios.md#scenario-3-capital-at-risk-with-loss-physical-settlement) for similar mechanics.

See [Physical Worst-of Settlement Guideline](../settlement-physical-worst-of.md) for detailed formula and examples.

## Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-16 | copilot | Placeholder test vector created; normative=false pending full scenario development; references BR-025A |
