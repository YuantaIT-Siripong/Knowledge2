---
title: FCN Coupon Rate Conversion Guideline
doc_type: guideline
status: Draft
version: 1.0.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-16
last_reviewed: 2025-10-16
next_review: 2026-04-16
classification: Internal
tags: [fcn, coupon, rate-conversion, annualized-rate, per-period-rate, guideline, structured-notes]
related:
  - business-rules.md
  - specs/fcn-v1.1.0.md
  - schemas/fcn-v1.1.0-parameters.schema.json
  - validators/parameter_validator.py
---

# FCN Coupon Rate Conversion Guideline

## 1. Purpose

This guideline defines the standard methodology for converting between **annual coupon rates** (expressed as percentage per annum) and **per-period coupon rates** used in FCN parameter specifications. It ensures consistent interpretation across trade documentation, parameter validation, and coupon calculation logic.

## 2. Scope

**Applicability**:
- All Fixed Coupon Note (FCN) products (v1.0, v1.1+)
- Trade parameter specification and validation
- Coupon payment calculation workflows
- Trade confirmation and investor documentation

**Key Use Cases**:
1. Converting quoted annual coupon rates to per-period rates for `coupon_rate_pct` parameter
2. Validating that parameter values represent per-period rates (not annual rates)
3. Handling different payment frequencies (monthly, quarterly, semi-annual, annual)
4. Addressing day count conventions and accrual period adjustments

## 3. FCN Parameter Convention

**FCN Schema Standard**: The `coupon_rate_pct` parameter represents the **per-period coupon rate** (not annualized).

**Example**:
- If a note pays 1.0833% **per month** (equivalent to ~13% per annum), the parameter value is:
  - `coupon_rate_pct: 0.010833` (per-period rate, expressed as decimal)
  
- **NOT**: `coupon_rate_pct: 0.13` (annual rate)

**Rationale**:
- Aligns with coupon calculation formula (BR-009): `coupon_amount = notional × coupon_rate_pct × (accrued_unpaid + 1)`
- Avoids implicit period-count assumptions in calculation logic
- Simplifies memory coupon accumulation mechanics

## 4. Conversion Formulae

### 4.1 Fixed Payment Frequency

When the note has a fixed payment frequency (e.g., monthly, quarterly) with consistent periods:

**Formula**:
```
per_period_coupon_rate = annual_coupon_rate_pct / periods_per_year
```

**Where**:
- `annual_coupon_rate_pct` = quoted annual coupon rate (as decimal, e.g., 0.13 for 13% p.a.)
- `periods_per_year` = number of payment periods per year:
  - Monthly: 12
  - Quarterly: 4
  - Semi-annual: 2
  - Annual: 1

**Example** (Monthly Coupon):
- Annual rate: 13% p.a. (0.13 as decimal)
- Periods per year: 12 (monthly payments)
- Per-period rate: `0.13 / 12 = 0.0108333...`
- `coupon_rate_pct` parameter: `0.010833` (rounded to 5 decimal places for internal calculation)

**Example** (Quarterly Coupon):
- Annual rate: 8% p.a. (0.08 as decimal)
- Periods per year: 4 (quarterly payments)
- Per-period rate: `0.08 / 4 = 0.02`
- `coupon_rate_pct` parameter: `0.02`

### 4.2 Day Count Convention (Accrual-Based)

When coupon accrual depends on actual calendar days (less common for FCN discrete observation, more typical for floating-rate notes):

**Formula**:
```
per_period_coupon_rate = annual_coupon_rate_pct × (days_in_period / day_count_basis_days)
```

**Where**:
- `days_in_period` = number of calendar days in the specific accrual period
- `day_count_basis_days` = day count convention denominator:
  - **ACT/365**: 365 days
  - **ACT/360**: 360 days
  - **30/360**: 360 days (with 30-day month adjustments)

**Example** (Quarterly with ACT/365):
- Annual rate: 8% p.a. (0.08 as decimal)
- Days in Q1 period: 90 days
- Day count basis: ACT/365 (365 days)
- Per-period rate: `0.08 × (90 / 365) = 0.019726...`
- `coupon_rate_pct` parameter: `0.019726` (rounded to 5 decimal places)

**Note**: Fixed payment frequency (section 4.1) is the standard for FCN products. Day count accrual is documented here for completeness but typically applies to floating-rate or bond-like structures.

## 5. Rounding Policy

### 5.1 Internal Calculation Precision

**Standard**: Use **5 decimal places** for internal per-period rate calculations.

**Rationale**:
- Balances precision with practical readability
- Sufficient accuracy for notional amounts up to $100M (error < $1 for typical coupon rates)
- Aligns with industry standard for interest rate representation

**Implementation**:
```python
per_period_rate = round(annual_rate / periods_per_year, 5)
```

### 5.2 Display & Documentation Precision

**Standard**: Display **2 decimal places** (basis points format) in investor-facing documentation.

**Example**:
- Internal calculation: `0.010833` (5 decimals)
- Display format: "1.08%" per month (2 decimal places as percentage)

**Rationale**:
- Standard market convention for coupon rate display
- Avoids confusion with excessive precision in customer communications
- Regulatory compliance with disclosure standards

### 5.3 Validation Tolerance

When validating recalculated rates against provided parameters, allow tolerance of **±0.00001** (1 basis point at 5 decimal precision) to account for rounding differences across systems.

## 6. Examples

### Example 1: Monthly 13% p.a. Coupon

**Given**:
- Annual coupon rate: 13% p.a.
- Payment frequency: Monthly
- Notional: $1,000,000

**Conversion**:
```
annual_rate = 0.13
periods_per_year = 12
per_period_rate = 0.13 / 12 = 0.0108333...
coupon_rate_pct (parameter) = 0.010833
```

**Coupon Calculation** (single period, no memory):
```
coupon_amount = notional × coupon_rate_pct
              = 1,000,000 × 0.010833
              = $10,833.33
```

**Display**:
- Investor documentation: "1.08% per month"
- Annualized equivalent: "~13% per annum"

### Example 2: Quarterly 6% p.a. Coupon

**Given**:
- Annual coupon rate: 6% p.a.
- Payment frequency: Quarterly
- Notional: $500,000

**Conversion**:
```
annual_rate = 0.06
periods_per_year = 4
per_period_rate = 0.06 / 4 = 0.015
coupon_rate_pct (parameter) = 0.015
```

**Coupon Calculation** (single period, no memory):
```
coupon_amount = notional × coupon_rate_pct
              = 500,000 × 0.015
              = $7,500.00
```

**Display**:
- Investor documentation: "1.50% per quarter"
- Annualized equivalent: "6% per annum"

### Example 3: Irregular Period (Day Count ACT/365)

**Given**:
- Annual coupon rate: 10% p.a.
- Payment frequency: Quarterly (irregular day count)
- Days in period: 92 days (Q2 example)
- Day count convention: ACT/365
- Notional: $2,000,000

**Conversion**:
```
annual_rate = 0.10
days_in_period = 92
day_count_basis = 365
per_period_rate = 0.10 × (92 / 365) = 0.025205...
coupon_rate_pct (parameter) = 0.025205
```

**Coupon Calculation**:
```
coupon_amount = 2,000,000 × 0.025205 = $50,410.00
```

**Display**:
- Investor documentation: "2.52% for 92-day period"
- Annualized equivalent: "~10% per annum (ACT/365 basis)"

## 7. Day Count Considerations

### 7.1 Standard FCN Practice

**Default Convention**: Fixed payment frequency (section 4.1) with equal period assumption.

**No Day Count Adjustment**: For typical FCN discrete observation schedules with fixed monthly/quarterly periods, day count accrual is **not** applied. Each period is treated as equal (1/12 or 1/4 of annual rate).

### 7.2 When Day Count Matters

Day count conventions (ACT/365, ACT/360, 30/360) should be applied when:
- Note documentation explicitly specifies day count accrual
- Irregular observation dates create variable-length periods
- Regulatory or market standards require ACT/365 basis (e.g., certain jurisdictions)

**Implementation Note**: If day count accrual is required, document the specific convention in trade confirmation and ensure `coupon_rate_pct` reflects the period-specific accrued rate.

### 7.3 ACT/365 vs ACT/360

| Convention | Denominator | Typical Use Case | Impact on Rate |
|------------|-------------|------------------|----------------|
| **ACT/365** | 365 days | Most common for equity-linked notes, GBP/EUR markets | Standard baseline |
| **ACT/360** | 360 days | US money market, USD LIBOR-based instruments | ~1.39% higher rate for same annual equivalent |
| **30/360** | 360 days (30-day months) | Bond markets, simplified accrual | Month-end adjustments apply |

**Example Impact**:
- 10% annual rate, 90-day period:
  - ACT/365: `0.10 × (90/365) = 0.024658` (2.47%)
  - ACT/360: `0.10 × (90/360) = 0.025000` (2.50%)
  - Difference: +0.34% (34 basis points) for ACT/360

## 8. Validation Implications

### 8.1 Heuristic Warning (parameter_validator.py)

**Problem**: Users may accidentally input annual rates instead of per-period rates in the `coupon_rate_pct` parameter, leading to drastically inflated coupon payments.

**Solution**: The parameter validator includes a heuristic check:

```python
if coupon_rate_pct > 0.20:
    warnings.append(
        "Potential annual rate supplied; ensure per-period conversion per coupon-rate-conversion.md"
    )
```

**Rationale**:
- Per-period rates for typical FCN products rarely exceed 20% (0.20 as decimal)
- A value > 0.20 likely indicates an annual rate (e.g., 24% p.a. entered as 0.24)
- Warning prompts user to verify conversion was performed correctly

**Example Triggering Scenarios**:
- Input: `coupon_rate_pct: 0.24` (likely 24% p.a., should be 0.02 for monthly)
- Input: `coupon_rate_pct: 0.15` (likely 15% p.a., should be 0.0125 for monthly)

**Non-Triggering Scenarios**:
- Input: `coupon_rate_pct: 0.010833` (1.08% per month, ~13% p.a.) — Valid
- Input: `coupon_rate_pct: 0.05` (5% per quarter, 20% p.a.) — Valid (edge case)

### 8.2 Schema Validation

**Current Schema**: `coupon_rate_pct` accepts any positive decimal (type: number, minimum: 0).

**Future Enhancement** (Phase 2):
- Add `maximum` constraint (e.g., 0.50) to catch extreme outliers
- Add metadata hint: `"hint": "Per-period rate (not annual); see coupon-rate-conversion.md"`
- Add schema-level warning annotation for values > 0.20

### 8.3 Test Vector Coverage

Test vectors should include:
- **Typical monthly rate**: `coupon_rate_pct: 0.01` (~12% p.a.)
- **High monthly rate**: `coupon_rate_pct: 0.03` (~36% p.a., high-risk product)
- **Quarterly rate**: `coupon_rate_pct: 0.025` (10% p.a.)
- **Edge case**: `coupon_rate_pct: 0.19` (should NOT trigger warning, but close)
- **Error case**: `coupon_rate_pct: 0.24` (should trigger heuristic warning)

## 9. Migration & Adoption

### 9.1 Existing Trades

**No Retroactive Changes**: Existing trade parameters remain valid. This guideline applies to:
- New trade bookings (going forward)
- Parameter validation heuristic (warning only, non-blocking)
- Documentation and investor communications

**Audit Recommendation**: Review existing trades where `coupon_rate_pct > 0.20` to verify correct interpretation.

### 9.2 Documentation Updates

**Investor Confirmations**: Include explicit language such as:
- "Coupon rate: X.XX% per [month/quarter], equivalent to approximately Y.Y% per annum"
- Reference this guideline in product disclosure documents

**Internal Systems**: Update trade entry screens with tooltips:
- "Enter per-period rate (e.g., 0.01 for 1% per month), not annual rate"

### 9.3 Training & Communication

**Stakeholder Training**:
- Product team: Understand annual vs. per-period rate distinction
- Operations: Validate trade confirmations match calculation expectations
- Risk: Ensure coupon cashflow projections use correct rate interpretation

**Communication Plan**:
- Distribute guideline to all stakeholders (Product, Risk, Ops, Trading)
- Add reference to onboarding materials for new team members
- Include in quarterly product review meetings

## 10. Related Business Rules

### BR-009: Coupon Calculation
**Rule**: `coupon_amount = notional × coupon_rate_pct × (accrued_unpaid + 1)`

**Dependency**: This guideline ensures `coupon_rate_pct` represents the **per-period rate**, so the formula produces correct per-period coupon amounts without additional period adjustment factors.

### BR-006: Coupon Condition
**Rule**: Coupon eligibility determined by underlyings vs. `coupon_condition_threshold_pct` at observation date.

**Implication**: The coupon **rate** (after conversion) is independent of coupon **eligibility**. This guideline addresses "how much" (rate), while BR-006 addresses "whether paid" (condition).

## 11. Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-16 | copilot | Initial guideline: conversion formulae (fixed frequency, day count accrual), rounding policy, examples (monthly 13% p.a., quarterly 6% p.a., irregular ACT/365), validation implications (parameter_validator.py heuristic warning), migration guidance, BR-009 integration |

## 12. References

- [Business Rules](business-rules.md) — BR-009 (Coupon Calculation), BR-006 (Coupon Condition)
- [FCN v1.1.0 Specification](specs/fcn-v1.1.0.md) — Coupon mechanics
- [FCN v1.1.0 Parameters Schema](schemas/fcn-v1.1.0-parameters.schema.json) — `coupon_rate_pct` definition
- [Parameter Validator](validators/parameter_validator.py) — Heuristic warning implementation
- [Overview & Migration Guidance](overview.md) — Product version migration
