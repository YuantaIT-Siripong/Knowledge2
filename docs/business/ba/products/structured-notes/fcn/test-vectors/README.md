# FCN Test Vectors

## Overview

This directory contains normative test vectors for Fixed Coupon Note (FCN) product validation across all supported versions and branches. Test vectors provide reference scenarios with explicit parameter sets, market paths, and expected cash flows/outcomes for deterministic validation.

## Version Coverage

### v1.0 Test Vectors (Legacy)
- **fcn-v1.0-base-mem-baseline.md**: Memory variant, all coupons pay, no KI
- **fcn-v1.0-base-mem-edge-barrier-touch.md**: Barrier edge case (exact touch)
- **fcn-v1.0-base-mem-ki-event.md**: KI triggered, memory accumulation
- **fcn-v1.0-base-mem-single-miss.md**: Single coupon miss with memory recovery
- **fcn-v1.0-base-nomem-baseline.md**: No-memory variant with coupon miss

**Settlement Mode**: Legacy par recovery (BR-011, deprecated in v1.1)  
**Key Feature**: Unconditional 100% notional redemption at maturity regardless of KI

### v1.1 Test Vectors (Current)

#### Capital-at-Risk No-Memory Branch (`fcn-caprisk-nomem`)
1. **fcn-v1.1-caprisk-nomem-baseline.md**: No KI, no loss (baseline scenario)
2. **fcn-v1.1-caprisk-nomem-ki-no-loss.md**: KI triggered but worst_of_final ≥ put_strike_pct (no loss)
3. **fcn-v1.1-caprisk-nomem-ki-loss.md**: KI triggered and worst_of_final < put_strike_pct (loss incurred, cash settlement)
4. **fcn-v1.1-caprisk-nomem-ki-loss-physical.md**: KI triggered and worst_of_final < put_strike_pct (loss incurred, physical settlement) — Normative for BR-025A
5. **fcn-v1.1-caprisk-nomem-ki-loss-physical-tiebreak.md**: KI triggered with tie-break scenario (two underlyings identical worst_of_final_ratio) — Normative for BR-025B

#### Capital-at-Risk Memory Branch (`fcn-caprisk-mem`)
6. **fcn-v1.1-caprisk-mem-baseline.md**: Memory variant baseline, no KI
7. **fcn-v1.1-caprisk-mem-accrual-release.md**: Coupon accrual and release pattern
8. **fcn-v1.1-caprisk-mem-ki-loss.md**: Memory + capital-at-risk loss

#### Capital-at-Risk + Autocall Branch (`fcn-caprisk-nomem-autocall`)
9. **fcn-v1.1-caprisk-nomem-autocall-preempt.md**: Autocall preempts capital-at-risk (precedence)
10. **fcn-v1.1-autocall-trigger.md**: Standard autocall trigger (mid-lifecycle)
11. **fcn-v1.1-autocall-near-miss.md**: Autocall near-miss (proceeds to maturity)
12. **fcn-v1.1-autocall-late-trigger.md**: Autocall at final observation

**Settlement Mode**: Capital-at-risk (BR-025)  
**Key Feature**: Conditional loss if KI triggered AND worst_of_final_ratio < put_strike_pct

## Capital-at-Risk Settlement Logic (BR-025 & BR-025A)

### Overview
Capital-at-risk settlement replaces unconditional par recovery (deprecated BR-011) with conditional principal loss exposure. BR-025A extends this with physical worst-of settlement mechanics for share delivery.

### Formula (Cash Settlement)
At maturity:

1. **If KI NOT triggered**:
   - Redemption = 100% notional (full principal return)

2. **If KI triggered**:
   - Calculate `worst_of_final_ratio = min(final_level / initial_level)` across all underlyings
   - **If worst_of_final_ratio ≥ put_strike_pct**:
     - Redemption = 100% notional (recovery above put strike)
   - **If worst_of_final_ratio < put_strike_pct**:
     - `loss_amount = notional × (put_strike_pct - worst_of_final_ratio) / put_strike_pct`
     - `redemption_amount = notional - loss_amount`

### Example Calculation
Given:
- notional = 1,000,000
- put_strike_pct = 0.80 (80%)
- knock_in_barrier_pct = 0.60 (60%)
- Underlying basket: 3 assets with initial levels [180.00, 125.00, 35.00]

**Scenario**: KI triggered at observation 2, final levels [172.0, 117.0, 25.0]

**Calculation**:
```
1. Compute final ratios:
   - Asset 1: 172.0 / 180.0 = 0.956
   - Asset 2: 117.0 / 125.0 = 0.936
   - Asset 3: 25.0 / 35.0 = 0.714  ← worst performer

2. worst_of_final_ratio = 0.714

3. Check: 0.714 < 0.80 (put_strike_pct) → Loss incurred

4. loss_amount = 1,000,000 × (0.80 - 0.714) / 0.80
              = 1,000,000 × 0.086 / 0.80
              = 1,000,000 × 0.1075
              = 107,500

5. redemption_amount = 1,000,000 - 107,500 = 892,500 (89.25% of notional)
```

**Loss Percentage**: (put_strike_pct - worst_of_final_ratio) / put_strike_pct = 10.75%

### Physical Settlement Mechanics (BR-025A)

For `settlement_type=physical-settlement` AND `recovery_mode=capital-at-risk` AND loss condition triggered:

**Share Count Calculation**:
```
share_count_worst = floor( notional_amount / (initial_level_worst × put_strike_pct) )
```

**Residual Cash**:
```
residual_cash = notional_amount - (share_count_worst × initial_level_worst × put_strike_pct)
```

**Treatment**:
- Deliver `share_count_worst` shares of worst-performing underlying
- Pay `residual_cash` separately if ≥ minimum_cash_dust_threshold
- Otherwise, add residual to final coupon or principal payment

See [Physical Worst-of Settlement Guideline](../settlement-physical-worst-of.md) for detailed mechanics.

### Key Observations
- Loss is **conditional**: requires both KI trigger AND poor recovery
- Put strike (80%) provides cushion above KI barrier (60%)
- Worst performer drives loss calculation (basket "floor")
- Loss is proportional, not binary (can be anywhere from 0% to 100% depending on worst_of_final_ratio)
- Physical settlement delivers shares based on strike cost (BR-025A)

## Payoff Precedence (BR-023)

When multiple features present, evaluation order:

1. **Autocall (Knock-Out)** — Highest priority (BR-021)
   - If all underlyings ≥ initial × knock_out_barrier_pct (equality triggers), early redemption
   - Ceases further observations; preempts maturity settlement

2. **Coupon Eligibility** (BR-006)
   - Independent of autocall barrier
   - Evaluated at each observation (if trade not terminated)

3. **Knock-In Monitoring** (BR-005)
   - Continuous throughout lifecycle (discrete observations in v1.1)
   - Once triggered, KI flag persists

4. **Capital-at-Risk Settlement** (BR-025) — Lowest priority (maturity only)
   - Only evaluated if no autocall occurred
   - Depends on KI status and worst_of_final_ratio

## Legacy vs Capital-at-Risk Comparison

| Aspect | v1.0 Legacy Par Recovery (BR-011) | v1.1 Capital-at-Risk (BR-025) |
|--------|-----------------------------------|-------------------------------|
| **Status** | Deprecated in v1.1 | Normative in v1.1 |
| **KI Impact** | None (100% notional regardless) | Conditional loss if worst_of_final < put_strike_pct |
| **Parameters** | redemption_barrier_pct (no payoff effect) | put_strike_pct (loss threshold) |
| **Settlement** | Always par at maturity | Proportional loss if KI + poor recovery |
| **Risk Profile** | Principal-protected (simpler) | Principal-at-risk (realistic downside) |
| **Use Case** | v1.0 trades only (grandfathered) | All new v1.1+ trades |

## Worst-of Final Ratio Computation

The `worst_of_final_ratio` is a **derived field** representing the minimum performance across all underlyings at maturity:

```
worst_of_final_ratio = min( final_level_i / initial_level_i ) for i in [1..N]
```

Where:
- N = number of underlyings in basket
- final_level_i = closing level of underlying i at maturity
- initial_level_i = initial fixing level of underlying i at issue

**Example**:
- 3 underlyings: AMZN, ORCL, PLTR
- Initial: [180.00, 125.00, 35.00]
- Final: [195.0, 142.0, 30.0]
- Ratios: [1.083, 1.136, 0.857]
- **worst_of_final_ratio = 0.857** (PLTR worst performer)

This value is compared against `put_strike_pct` in capital-at-risk settlement (BR-025).

## Test Vector Structure

Each test vector includes:

### Front Matter (YAML)
- version, branch_id, spec_version, normative flag, taxonomy

### Sections
1. **Scenario Description**: High-level summary
2. **Parameters**: Complete trade parameter set
3. **Underlying Path**: Market observation data with calculations
4. **Event Timeline**: Chronological event sequence
5. **Expected Events**: Key flags (ki_triggered, autocall_triggered, worst_of_final_ratio)
6. **Cash Flows**: Detailed coupon and principal payments
7. **Outcome Summary**: Final redemption type and settlement logic applied
8. **Validation Points**: Business rules validated by this vector
9. **Notes**: Additional context and edge case notes

## Validation Usage

Test vectors serve as:

1. **Parameter Validation** (Phase 2): Verify schema conformance (BR-001–004, BR-014, BR-015, BR-019, BR-020, BR-024, BR-026)
2. **Logic Validation** (Phase 4): Simulate payoff calculations and compare to expected outcomes (BR-005–010, BR-013, BR-021, BR-023, BR-025)
3. **Regression Testing**: Ensure behavioral consistency across code changes
4. **Documentation**: Reference scenarios for stakeholders and training

## Coverage Requirements (BR-017)

For version promotion to **Active** status:

- Normative branches must have ≥80% test vector coverage
- Each normative business rule must link to ≥1 test vector
- Capital-at-risk settlement (BR-025) requires:
  - At least 1 no-loss scenario (KI but recovery)
  - At least 1 loss scenario (KI and poor recovery)
  - At least 1 autocall precedence scenario
- Physical settlement (BR-025A) requires:
  - At least 1 normative physical settlement vector with share_count_worst and residual_cash
- Tie-break coverage (BR-025B):
  - At least 1 normative tie-break vector demonstrating first-in-array selection

Current v1.1 coverage: **12 vectors** across 3 capital-at-risk branches (target: met).

**Normative Physical Settlement Coverage**:
- BR-025A: `fcn-v1.1-caprisk-nomem-ki-loss-physical.md` (35,714 shares + $8 residual)
- BR-025B: `fcn-v1.1-caprisk-nomem-ki-loss-physical-tiebreak.md` (tie-break: ABC.US selected)

## Sample Payloads

See `/sample-payloads/` subdirectory for JSON parameter examples suitable for API/ingress testing.

## Maintenance

- Test vectors updated when:
  - New business rules added
  - Parameter schema changes
  - Edge cases discovered
  - Stakeholder requests specific scenarios

- Version discipline:
  - v1.0 vectors immutable (historical reference)
  - v1.1 vectors evolving until version Active
  - Future versions: new directories or branch prefixes

## References

- [FCN v1.1 Specification](../specs/fcn-v1.1.0.md)
- [Business Rules](../business-rules.md) — Complete rule set with traceability
- [Schema Diff v1.0→v1.1](../schema-diff-v1.0-to-v1.1.md) — Migration guide
- [Manifest](../manifest.yaml) — Product metadata and branch taxonomy
- [Glossary](../glossary.md) — Controlled terminology including capital-at-risk terms

## Change Log

| Date | Author | Change |
|------|--------|--------|
| 2025-10-09 | siripong.s | Initial v1.0 test vectors (5 vectors) |
| 2025-10-16 | copilot | Added v1.1 capital-at-risk test vectors (10 vectors); documented worst_of_final_ratio computation and capital-at-risk settlement logic |
| 2025-10-16 | copilot | Activation Readiness: added normative physical settlement vectors (fcn-v1.1-caprisk-nomem-ki-loss-physical.md, fcn-v1.1-caprisk-nomem-ki-loss-physical-tiebreak.md); updated coverage requirements to include BR-025A and BR-025B; total vectors now 12; clarified normative evidence for physical settlement mechanics and tie-break policy |
