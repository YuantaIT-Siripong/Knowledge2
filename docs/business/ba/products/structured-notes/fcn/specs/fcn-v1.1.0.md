---
title: Fixed Coupon Note (FCN) Specification v1.1.0
doc_type: product-spec
status: Draft
spec_version: 1.1.0
version: 1.1.0
supersedes: fcn-v1.0.md
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-16
last_reviewed: 2025-10-16
next_review: 2026-04-16
classification: Internal
tags: [structured-notes, fcn, product-spec, v1.1, autocall, issuer]
related:
  - ../non-functional.md
  - ../er-fcn-v1.0.md
  - ../../../common/conventions.md
  - ../../../common/payoff_types.md
  - ../../../common/governance.md
  - ../../../common/deprecation-alias-policy.md
  - ../../../sa/design-decisions/adr-002-product-doc-structure.md
  - ../../../sa/design-decisions/adr-003-fcn-version-activation.md
  - ../../../sa/design-decisions/adr-004-parameter-alias-policy.md
  - fcn-v1.0.md
  - ../schema-diff-v1.0-to-v1.1.md
activation_checklist_issue: TBD
normative_test_vector_set:
  - fcn-v1.1.0-nomem-autocall-baseline
  - fcn-v1.1.0-nomem-autocall-trigger
  - fcn-v1.1.0-nomem-autocall-no-trigger-edge
---

# Fixed Coupon Note (FCN) – Specification v1.1.0 (Autocall & Issuer Support)

## 1. Overview

This v1.1.0 specification supersedes v1.0 (see Supersession Statement in [schema-diff-v1.0-to-v1.1.md](../schema-diff-v1.0-to-v1.1.md)).

FCN v1.1.0 extends the baseline v1.0 specification with:
- **Autocall (Knock-Out) Feature**: Early redemption capability when all underlyings exceed a specified barrier level
- **Issuer Parameter**: Required issuer identifier for governance and risk management
- **Enhanced Payoff Logic**: Explicit precedence ordering for autocall, coupon condition, and knock-in evaluation

This version maintains **full backward compatibility** with v1.0 by making new parameters optional (except issuer) and preserving all existing parameter names, types, and constraints.

## 2. Version History

| Version | Date | Key Changes |
|---------|------|-------------|
| 1.0.0 | 2025-10-09 | Baseline: memory/no-memory coupons, knock-in barrier, par-recovery |
| 1.1.0 | 2025-10-16 | Added: autocall/knock-out barrier, issuer parameter, observation frequency helper |

## 3. Parameter Table

| name | type | required | default | constraints | description |
|------|------|----------|---------|-------------|-------------|
| trade_date | date | yes | - | ISO-8601 | Date of trade agreement |
| issue_date | date | yes | - | issue_date >= trade_date | Settlement / note inception date |
| maturity_date | date | yes | - | maturity_date > issue_date | Contract final maturity |
| underlying_symbols | string[] | yes | - | length >= 1; uppercase tickers | Underlying instrument identifiers |
| initial_levels | decimal[] | yes | - | length = length(underlying_symbols); each > 0 | Recorded initial spot/close for each underlying |
| notional_amount | decimal | yes | - | > 0; precision: 2 decimal places for standard currencies (USD, EUR, THB); 0 for zero-decimal currencies (JPY, KRW) | Face amount in currency units |
| currency | string | yes | - | ISO-4217 (e.g., TWD, USD) | Settlement currency |
| **issuer** | **string** | **yes** | **-** | **non-empty; must exist in approved issuer whitelist** | **Issuer identifier for counterparty risk and governance** |
| observation_dates | date[] | yes | - | strictly increasing; all < maturity_date | Coupon & barrier observation schedule (excludes maturity if separately listed) |
| **observation_frequency_months** | **integer** | **no** | **null** | **>= 1** | **Optional helper: monthly interval between observations (informational)** |
| coupon_observation_offset_days | integer | no | 0 | >= 0 | Business day offset for observing coupon vs nominal schedule (0 = same day) |
| coupon_payment_dates | date[] | yes | - | length = length(observation_dates); each >= issue_date | When coupons (if any) are paid |
| coupon_rate_pct | decimal | yes | - | 0 < x <= 1 | Period coupon rate (ratio form; display ×100%) |
| is_memory_coupon | boolean | no | false | - | If true, missed coupons (due to barrier) can accrue and pay later when condition satisfied |
| memory_carry_cap_count | integer | conditional | null | if is_memory_coupon=true then >=0 else null | Limits number of unpaid coupons that can accumulate (null = unlimited) |
| knock_in_barrier_pct | decimal | yes | - | 0 < x < 1 | Barrier level as fraction of initial level (per underlying) triggering KI if breached |
| **knock_out_barrier_pct** | **decimal** | **no** | **null** | **0 < x <= 1.30; if present then auto_call_observation_logic required** | **Autocall barrier level as fraction of initial; triggers early redemption when breached upward** |
| **auto_call_observation_logic** | **string** | **conditional** | **null** | **enum: all-underlyings; required if knock_out_barrier_pct present** | **Logic for autocall trigger: all-underlyings = ALL underlyings must close >= initial × knock_out_barrier_pct** |
| barrier_monitoring | string | yes | "discrete" | enum: discrete (v1.0), continuous (deferred to v1.1+) | Monitoring style; only discrete supported in v1.0/v1.1 |
| knock_in_condition | string | yes | - | enum: any-underlying-breach | Condition logic: KI occurs if any underlying closes <= initial * knock_in_barrier_pct on any observation date |
| redemption_barrier_pct | decimal | yes | - | 0 < x <= 1 | Final redemption barrier (for par redemption) |
| settlement_type | string | yes | - | enum: physical-settlement | Allowed in v1.0/v1.1 normative: physical-settlement (cash-settlement may appear in examples but is non-normative) |
| coupon_condition_threshold_pct | decimal | no | 1.0 | 0 < x <= 1 | Minimum fraction of initial level each underlying must stay above for coupon payment; **independent of knock_out_barrier_pct** |
| recovery_mode | string | yes | "par-recovery" | enum: par-recovery | Baseline normative recovery branch (proportional-loss deferred) |
| day_count_convention | string | no | "ACT/365" | enum: ACT/365, ACT/360 | Used for accrual calculations if needed |
| business_day_calendar | string | no | "TARGET" | recognized calendar code | Calendar for date adjustments |
| fx_reference | string | conditional | null | required if underlying currency != settlement currency | FX rate source identifier |
| documentation_version | string | yes | "1.1.0" | equals version | Traceability anchor (validated by BR-004 / BR-018) |

### 3.1 New Parameter Details

#### issuer (v1.1.0+)
- **Purpose**: Identify the note issuer for counterparty risk management and governance
- **Validation**: Must exist in the approved issuer whitelist maintained by risk management
- **Business Rule**: BR-022 enforces whitelist validation at booking time

#### knock_out_barrier_pct (v1.1.0+)
- **Purpose**: Define the upward barrier level that triggers early redemption (autocall)
- **Typical Range**: 100% to 130% of initial levels (1.0 to 1.30 in decimal form)
- **Interaction**: When specified, requires auto_call_observation_logic to be set
- **Business Rule**: BR-020 validates range; BR-021 defines autocall trigger logic

#### auto_call_observation_logic (v1.1.0+)
- **Purpose**: Specify the condition logic for autocall trigger
- **Current Support**: "all-underlyings" only (all underlyings must exceed barrier)
- **Future**: May extend to support "any-underlying", "worst-of", or custom logic
- **Business Rule**: BR-021 defines evaluation order and redemption behavior

#### observation_frequency_months (v1.1.0+)
- **Purpose**: Informational field indicating the regular interval between observation dates
- **Usage**: Helpful for schedule validation and documentation; not used in payoff calculations
- **Example**: 3 = quarterly observations, 1 = monthly observations

## 4. Payoff Evaluation Sequence

The payoff logic evaluates conditions in the following order on each observation date:

### Precedence Order (BR-021, BR-023):
1. **Autocall (Knock-Out) Check** – highest precedence
2. **Coupon Condition Evaluation** – if no autocall triggered
3. **Knock-In (Barrier Breach) Check** – independent monitoring

### Pseudocode:

```
FOR each observation_date in observation_dates:
    // Step 1: Check Autocall (if configured)
    IF knock_out_barrier_pct IS NOT NULL:
        all_above_ko = TRUE
        FOR each underlying in underlyings:
            current_level = get_market_close(underlying, observation_date)
            IF current_level < (underlying.initial_level * knock_out_barrier_pct):
                all_above_ko = FALSE
                BREAK
        
        IF all_above_ko AND auto_call_observation_logic == "all-underlyings":
            // Autocall triggered - early redemption
            due_coupon = check_coupon_condition(observation_date)
            redeem_amount = notional_amount + due_coupon
            RETURN EARLY_REDEMPTION(redeem_amount, observation_date)
            // No further observations after autocall
    
    // Step 2: Evaluate Coupon Condition (independent of KO barrier)
    all_above_coupon_threshold = TRUE
    FOR each underlying in underlyings:
        current_level = get_market_close(underlying, observation_date)
        IF current_level < (underlying.initial_level * coupon_condition_threshold_pct):
            all_above_coupon_threshold = FALSE
            BREAK
    
    IF all_above_coupon_threshold:
        pay_coupon(observation_date, notional_amount * coupon_rate_pct)
        IF is_memory_coupon:
            pay_accrued_unpaid_coupons()
    ELSE IF is_memory_coupon:
        accumulate_unpaid_coupon()
    
    // Step 3: Check Knock-In (continuous monitoring)
    FOR each underlying in underlyings:
        current_level = get_market_close(underlying, observation_date)
        IF current_level <= (underlying.initial_level * knock_in_barrier_pct):
            SET ki_triggered_flag = TRUE
            // Continue to maturity

// At Maturity (if not auto-called earlier)
final_coupon = check_coupon_condition(maturity_date)
IF NOT ki_triggered_flag OR recovery_mode == "par-recovery":
    settlement_amount = notional_amount + final_coupon
ELSE:
    // proportional-loss (non-normative in v1.1)
    worst_performance = calculate_worst_performance()
    settlement_amount = notional_amount * worst_performance + final_coupon

RETURN MATURITY_SETTLEMENT(settlement_amount)
```

### Key Notes:
- **Autocall takes precedence**: Once triggered, no further observations occur
- **Coupon condition is independent**: coupon_condition_threshold_pct can be ≤ knock_out_barrier_pct (BR-023)
- **Knock-in monitoring is continuous**: Can occur at any observation date, doesn't prevent autocall

## 5. Autocall Scenario Illustrations

The following scenarios demonstrate the autocall feature behavior:

### Scenario 1: Autocall Triggered Early
![Scenario 1](scenario-image-1)
- All underlyings exceed knock_out_barrier_pct on observation date 3
- Note redeems early: principal + due coupon paid
- No further observations after autocall

### Scenario 2: Autocall Not Triggered - One Underlying Below
![Scenario 2](scenario-image-2)
- Underlying 2 remains below knock_out_barrier_pct throughout
- Autocall never triggers despite Underlying 1 performing well
- Note proceeds to maturity with standard payoff evaluation

### Scenario 3: Autocall Triggered at Maturity Observation
![Scenario 3](scenario-image-3)
- All underlyings exceed barrier only on final observation
- Autocall triggers on maturity observation date
- Equivalent to par redemption plus final coupon

### Scenario 4: Edge Case - Near Barrier Level
![Scenario 4](scenario-image-4)
- One underlying hovers very close to knock_out_barrier_pct
- Demonstrates importance of precise barrier level definition
- Highlights need for clear equality handling (see OQ-BR-005)

## 6. Business Rules Reference

New business rules introduced in v1.1.0:

- **BR-020**: Validation of knock_out_barrier_pct range (0 < x ≤ 1.30)
- **BR-021**: Autocall logic and early redemption behavior
- **BR-022**: Issuer whitelist validation requirement
- **BR-023**: Independence of coupon_condition_threshold_pct from knock_out_barrier_pct

See [business-rules.md](../business-rules.md) for complete rule definitions and traceability.

## 7. Test Vector Inventory

Normative test vectors for v1.1.0 autocall branch:

| Vector ID | Description | Key Conditions |
|-----------|-------------|----------------|
| fcn-v1.1.0-nomem-autocall-baseline | Standard autocall trigger | All underlyings exceed KO barrier on observation date 3 |
| fcn-v1.1.0-nomem-autocall-trigger | Early autocall with memory coupons | Autocall triggered after missed coupon period |
| fcn-v1.1.0-nomem-autocall-no-trigger-edge | Near-miss scenario | One underlying 0.01% below barrier; proceeds to maturity |

**TODO**: Complete test vector definitions with market scenarios and expected outputs.

## 8. Migration from v1.0

Existing v1.0 trades remain fully valid under v1.1.0:
- All v1.0 parameters are preserved unchanged
- New parameters (knock_out_barrier_pct, auto_call_observation_logic, observation_frequency_months) are optional
- Exception: issuer is required for new v1.1.0 trades but can be backfilled for v1.0 trades during migration

See [schema-diff-v1.0-to-v1.1.md](../schema-diff-v1.0-to-v1.1.md) for detailed migration guidance.

## 9. Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.1.0 | 2025-10-16 | siripong.s | Initial draft: added autocall (knock-out barrier), issuer parameter, observation frequency helper; documented payoff precedence order; added scenario illustrations and test vector placeholders |

## 10. References

- [FCN v1.0 Specification](fcn-v1.0.md)
- [Business Rules](../business-rules.md)
- [Manifest](../manifest.yaml)
- [Parameter Schema v1.1.0](../schemas/fcn-v1.1.0-parameters.schema.json)
- [Migration Script m0002](../migrations/m0002-fcn-v1_1-autocall-extension.sql)
- [Schema Diff v1.0 to v1.1](../schema-diff-v1.0-to-v1.1.md)
