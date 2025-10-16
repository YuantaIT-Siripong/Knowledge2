---
title: Physical Worst-of Settlement Guideline
doc_type: guideline
status: Draft
version: 1.0.1
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-16
last_reviewed: 2025-10-16
next_review: 2026-04-16
classification: Internal
tags: [fcn, physical-settlement, capital-at-risk, worst-of, settlement, guideline]
related:
  - business-rules.md
  - specs/fcn-v1.1.0.md
  - schemas/fcn-v1.1.0-parameters.schema.json
---

# Physical Worst-of Settlement Guideline

## 1. Purpose

This guideline defines the mechanics for physical settlement of Fixed Coupon Notes (FCN) when the capital-at-risk recovery mode is triggered and physical delivery of worst-performing underlying shares is required. It operationalizes BR-025A by specifying share count calculation, residual cash treatment, and rounding policies.

## 2. Applicability

This guideline applies when **all** of the following conditions are met:

1. **Product**: Fixed Coupon Note (FCN) v1.1+
2. **Recovery Mode**: `recovery_mode = 'capital-at-risk'`
3. **Settlement Type**: `settlement_type = 'physical-settlement'`
4. **Loss Condition**: Knock-in triggered AND `worst_of_final_ratio < put_strike_pct` at maturity

If any condition is not met, this guideline does not apply (e.g., cash settlement follows different mechanics, par recovery does not deliver shares).

## 3. Formula (BR-025A)

When physical worst-of settlement is triggered, the following calculations determine share delivery and residual cash:

### 3.1 Identify Worst-Performing Underlying

```
worst_performer = arg min(final_level_i / initial_level_i) for i in [1..N]
initial_level_worst = initial_level[worst_performer]
```

Where:
- N = total number of underlyings in basket
- final_level_i = closing price of underlying i at maturity observation
- initial_level_i = initial fixing price of underlying i at issue

**Tie-Breaking Rule** (Deterministic Ordering):
When multiple underlyings share the exact same worst_of_final_ratio (i.e., final_level_i / initial_level_i are identical to machine precision), the worst performer is selected based on the **first occurrence in the underlying_assets array**.

**Rationale**:
- Ensures deterministic, reproducible settlement calculations across systems
- Avoids ambiguity and operational disputes
- Aligns with standard industry practice for worst-of instruments
- Leverages the canonical ordering already defined in trade parameters
- No dependency on external factors (alphabetical sorting, market cap, etc.)

**Implementation**:
- Iterate through underlying_assets array in order (index 0, 1, 2, ...)
- Track the minimum final_ratio and corresponding index
- If tie occurs, the first-encountered index wins (no override)
- Related business rule: BR-025B (Worst-of Tie-Break Policy)

### 3.2 Calculate Share Count

```
share_count_worst = floor( notional / (initial_level_worst × put_strike_pct) )
```

**Rationale**: Investor receives shares based on "strike cost" — the notional divided by the effective strike price (initial level × put strike percentage). Floor function ensures delivery of whole shares only.

### 3.3 Calculate Residual Cash

```
residual_cash = notional - (share_count_worst × initial_level_worst × put_strike_pct)
```

**Interpretation**: Residual cash represents the fractional share amount that cannot be delivered physically.

### 3.4 Residual Cash Treatment

- **If** `residual_cash ≥ minimum_cash_dust_threshold`:
  - Residual cash paid separately as cash settlement component
  
- **Else** (residual cash < threshold):
  - Residual cash added to final coupon payment (if any) or paid with principal
  - Avoids micro-payments and operational friction

**Default Threshold**: `minimum_cash_dust_threshold = 0.01` (1 cent in settlement currency)  
**Configurable**: May be adjusted per issuer/market practice

## 4. Examples

### Example 1: Standard Physical Settlement

**Trade Parameters**:
- Notional: $1,000,000
- Currency: USD
- Underlying basket: 3 assets (AMZN, ORCL, PLTR)
- Initial levels: [180.00, 125.00, 35.00]
- put_strike_pct: 0.80 (80%)
- knock_in_barrier_pct: 0.60 (60%)

**Market Outcome at Maturity**:
- Final levels: [172.0, 117.0, 25.0]
- Final ratios: [0.956, 0.936, 0.714]
- Worst performer: PLTR (ratio 0.714)

**Calculation**:
1. initial_level_worst = 35.00 (PLTR)
2. share_count_worst = floor(1,000,000 / (35.00 × 0.80))
                     = floor(1,000,000 / 28.00)
                     = floor(35,714.285...)
                     = **35,714 shares**

3. residual_cash = 1,000,000 - (35,714 × 28.00)
                 = 1,000,000 - 999,992
                 = **$8.00**

4. Since $8.00 ≥ $0.01 threshold, residual cash paid separately

**Settlement**:
- Deliver: 35,714 shares of PLTR
- Cash: $8.00 (residual)
- Final coupon (if applicable): paid per normal coupon schedule

### Example 2: Multiple Underlyings, Dust Residual

**Trade Parameters**:
- Notional: $500,000
- Underlying: 2 assets (SPY, QQQ)
- Initial levels: [450.00, 380.00]
- put_strike_pct: 0.75 (75%)

**Market Outcome**:
- Final levels: [445.0, 330.0]
- Final ratios: [0.989, 0.868]
- Worst performer: QQQ (ratio 0.868)

**Calculation**:
1. initial_level_worst = 380.00 (QQQ)
2. share_count_worst = floor(500,000 / (380.00 × 0.75))
                     = floor(500,000 / 285.00)
                     = floor(1,754.385...)
                     = **1,754 shares**

3. residual_cash = 500,000 - (1,754 × 285.00)
                 = 500,000 - 499,890
                 = **$110.00**

4. Since $110.00 ≥ $0.01 threshold, residual cash paid separately

**Settlement**:
- Deliver: 1,754 shares of QQQ
- Cash: $110.00 (residual)

### Example 3: Sub-Threshold Residual (Added to Coupon)

**Trade Parameters**:
- Notional: $250,000
- Underlying: 1 asset (AAPL)
- Initial level: [175.00]
- put_strike_pct: 0.85 (85%)
- Final coupon due: $2,500

**Market Outcome**:
- Final level: [160.0]
- Final ratio: [0.914]
- Worst performer: AAPL (only asset)

**Calculation**:
1. initial_level_worst = 175.00 (AAPL)
2. share_count_worst = floor(250,000 / (175.00 × 0.85))
                     = floor(250,000 / 148.75)
                     = floor(1,680.672...)
                     = **1,680 shares**

3. residual_cash = 250,000 - (1,680 × 148.75)
                 = 250,000 - 249,900
                 = **$100.00**

4. Since $100.00 ≥ $0.01 threshold, residual cash paid separately
   (Note: if residual were < $0.01, it would be added to coupon payment)

**Settlement**:
- Deliver: 1,680 shares of AAPL
- Cash (residual): $100.00
- Final coupon: $2,500 (separate payment)

## 5. Rounding & Residual Policy

### 5.1 Share Count Rounding

**Policy**: Always use **floor** function (round down to nearest integer)

**Rationale**:
- Ensures delivery of whole shares only
- Prevents over-delivery (investor receives slightly less than full notional equivalent)
- Standard market practice for physical settlement
- Residual captured as cash, protecting both parties

### 5.2 Residual Cash Handling

**Threshold-Based Approach**:

| Residual Amount | Treatment | Rationale |
|-----------------|-----------|-----------|
| ≥ minimum_cash_dust_threshold | Paid separately as cash component | Material amount warrants separate payment |
| < minimum_cash_dust_threshold | Added to final coupon (if any) or paid with principal | Avoids micro-payments, operational efficiency |

**Default Threshold**: $0.01 (USD) or equivalent in settlement currency

**Configuration**:
- May be adjusted per issuer policy
- Market-specific thresholds (e.g., JPY: ¥1, EUR: €0.01)
- Documented in trade confirmation

### 5.3 Edge Case: No Final Coupon

If residual cash < threshold AND no final coupon is due (e.g., coupon condition not met), residual cash is:
- Still paid with principal delivery
- Included in settlement confirmation
- Treated as part of principal redemption (not coupon)

## 6. Open Questions

### OQ-PHYS-001: Tie-Breaking for Multiple Worst Assets [RESOLVED]
**Question**: If multiple underlyings have identical worst_of_final_ratio, which asset is delivered?

**Resolution** (2025-10-16):
**Selected Option**: Order in underlying_assets array (first occurrence)

**Policy**: When multiple underlyings share the exact same worst_of_final_ratio, the tie is resolved by selecting the **first occurrence in the underlying_assets array**. This ensures deterministic ordering, avoids operational ambiguity, and aligns with standard industry practice.

**Implementation**: See section 3.1 for detailed tie-breaking rule and rationale. Related business rule: BR-025B.

**Status**: RESOLVED

### OQ-PHYS-002: Corporate Action Adjustments
**Question**: How are corporate actions (splits, dividends, mergers) handled during note lifecycle?

**Considerations**:
- Adjustment of initial_level_worst
- Share count recalculation
- Documentation requirements

**Owner**: Risk + Legal  
**Target Resolution**: Q1 2026

### OQ-PHYS-003: Fractional Share Jurisdictions
**Question**: In jurisdictions allowing fractional shares, should floor rounding still apply?

**Considerations**:
- Market practice varies (US: whole shares, EU: some allow fractional)
- Operational complexity of fractional delivery
- Investor preference and custodian support

**Owner**: Operations + SA  
**Target Resolution**: Q1 2026

### OQ-PHYS-004: Currency Conversion for Multi-Currency Structures
**Question**: If underlying trades in different currency than settlement currency, when is FX conversion applied?

**Options**:
1. Convert initial_level_worst at issue date FX rate
2. Convert at maturity FX rate
3. Hybrid approach (initial level at issue, final at maturity)

**Owner**: Risk  
**Target Resolution**: Q4 2025

## 7. Validation & Testing

Physical settlement scenarios must be validated against:

- **BR-025A**: Formula correctness (share_count_worst, residual_cash)
- **BR-025**: Conditional loss logic (KI + worst_of_final_ratio < put_strike_pct)
- **Rounding**: Floor function applied consistently
- **Threshold**: Residual cash treatment logic correct
- **Edge Cases**: Single underlying, equal weights, tie-breaking

Test vectors covering physical settlement:
- `fcn-v1.1-caprisk-nomem-ki-loss-physical.md` (normative pending)

## 8. References

- **Business Rules**: [business-rules.md](business-rules.md) — BR-025A normative definition
- **Specification**: [specs/fcn-v1.1.0.md](specs/fcn-v1.1.0.md) — Capital-at-risk settlement
- **Schema**: [schemas/fcn-v1.1.0-parameters.schema.json](schemas/fcn-v1.1.0-parameters.schema.json) — Parameter definitions
- **Test Vectors**: [test-vectors/README.md](test-vectors/README.md) — Settlement scenarios

## 9. Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-16 | copilot | Initial guideline: BR-025A operationalization with formula, examples, rounding policy, open questions |
| 1.0.1 | 2025-10-16 | copilot | Resolved OQ-PHYS-001 (tie-breaking rule): added definitive policy for worst-of tie resolution using underlying_assets array order (first occurrence); updated section 3.1 with tie-breaking rule, rationale, and implementation guidance; marked OQ-PHYS-001 as RESOLVED; related to new BR-025B |
