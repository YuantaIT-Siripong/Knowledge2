---
title: FCN v1.0 Business Rules - Coupon Calculation and Redemption
doc_type: business-rules
role_primary: BA
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
status: Draft
version: 1.0.0
created: 2025-10-10
last_reviewed: 2025-10-10
next_review: 2026-04-10
classification: Internal
tags: [structured-notes, fcn, business-rules, coupon, redemption, v1.0]
related:
  - specs/fcn-v1.0.md
  - ../../../sa/handoff/domain-handoff-fcn-v1.0.md
  - validator-roadmap.md
---

# FCN v1.0 Business Rules - Coupon Calculation and Redemption

## 1. Purpose

This document defines the comprehensive business rules for Fixed Coupon Note (FCN) v1.0, specifically covering:
- Coupon calculation logic
- Early redemption scenarios (placeholders for future versions)
- Maturity redemption scenarios

Each rule is marked with its v1.0 scope status and references relevant product SME documentation or regulatory sources.

---

## 2. Scope and Version Status

**In-Scope for v1.0 (Normative):**
- Coupon calculation and payment logic
- Memory coupon accumulation and payment
- Knock-in barrier monitoring
- Par-recovery redemption at maturity
- Physical settlement (normative branch)

**Deferred from v1.0 (Non-Normative / Future Versions):**
- Early redemption / autocall features
- Step-down barrier schedules
- Proportional-loss recovery mode (may appear in examples but not normative)
- Cash settlement (may appear in examples but not normative)
- Continuous barrier monitoring

---

## 3. Coupon Calculation Rules (v1.0 In-Scope)

### 3.1 Coupon Eligibility Determination

| Rule ID | Description | Formula | Source | v1.0 Status |
|---------|-------------|---------|--------|-------------|
| **BR-CPN-001** | Coupon condition satisfied if ALL underlyings remain at or above coupon threshold | `level_ok = ALL(underlying_level_j(i) >= initial_level_j × coupon_condition_threshold_pct)` | [Spec §5](specs/fcn-v1.0.md#5-payoff-pseudocode-normative) | ✅ Normative |
| **BR-CPN-002** | Coupon condition evaluated independently for each observation date | Each observation_date i processed exactly once | [Spec §5](specs/fcn-v1.0.md#5-payoff-pseudocode-normative) | ✅ Normative |
| **BR-CPN-003** | Default coupon threshold is 100% of initial level if not specified | `coupon_condition_threshold_pct = 1.0` (default) | [Spec §3](specs/fcn-v1.0.md#3-parameter-table) | ✅ Normative |
| **BR-CPN-004** | Observation dates must be strictly increasing and before maturity | `observation_dates[i] < observation_dates[i+1] < maturity_date` | [Spec §3](specs/fcn-v1.0.md#3-parameter-table) | ✅ Normative |

**Product SME Reference:** As per FCN term sheet standard (Physical Settlement, Memory Coupon variant)

---

### 3.2 Coupon Amount Calculation

| Rule ID | Description | Formula | Source | v1.0 Status |
|---------|-------------|---------|--------|-------------|
| **BR-CPN-005** | Coupon amount for single period (no memory) | `coupon_amount = notional_amount × coupon_rate_pct` | [Spec §5](specs/fcn-v1.0.md#5-payoff-pseudocode-normative) | ✅ Normative |
| **BR-CPN-006** | Coupon amount with memory accumulation | `coupon_amount = notional_amount × coupon_rate_pct × (accrued_unpaid + 1)` | [Spec §5](specs/fcn-v1.0.md#5-payoff-pseudocode-normative) | ✅ Normative |
| **BR-CPN-007** | Coupon rate must be positive and ≤ 1.0 (100%) | `0 < coupon_rate_pct ≤ 1.0` | [Spec §3](specs/fcn-v1.0.md#3-parameter-table) | ✅ Normative |
| **BR-CPN-008** | Coupon payment date determined from coupon_payment_dates array | `payment_date = coupon_payment_dates[observation_index]` | [Spec §3](specs/fcn-v1.0.md#3-parameter-table) | ✅ Normative |

**Product SME Reference:** Standard fixed coupon structured note conventions, aligned with ISDA structured products documentation

---

### 3.3 Memory Coupon Logic

| Rule ID | Description | Formula | Source | v1.0 Status |
|---------|-------------|---------|--------|-------------|
| **BR-CPN-009** | Memory coupon feature enabled via is_memory_coupon flag | If `is_memory_coupon = true`, missed coupons accumulate | [Spec §3](specs/fcn-v1.0.md#3-parameter-table) | ✅ Normative |
| **BR-CPN-010** | Memory accumulation counter initialization | `accrued_unpaid = 0` at initialization | [Spec §5](specs/fcn-v1.0.md#5-payoff-pseudocode-normative) | ✅ Normative |
| **BR-CPN-011** | Memory accumulation increment when coupon condition fails | If `!level_ok AND is_memory_coupon`: `accrued_unpaid = accrued_unpaid + 1` | [Spec §5](specs/fcn-v1.0.md#5-payoff-pseudocode-normative) | ✅ Normative |
| **BR-CPN-012** | Memory accumulation reset upon coupon payment | If `level_ok`: pay coupon and set `accrued_unpaid = 0` | [Spec §5](specs/fcn-v1.0.md#5-payoff-pseudocode-normative) | ✅ Normative |
| **BR-CPN-013** | Memory carry cap enforcement (if specified) | If `memory_carry_cap_count` is set, `accrued_unpaid ≤ memory_carry_cap_count` | [Spec §3](specs/fcn-v1.0.md#3-parameter-table) | ✅ Normative |
| **BR-CPN-014** | Non-memory coupon: missed coupons are forfeited | If `!is_memory_coupon AND !level_ok`: no payment, no accumulation | [Spec §5](specs/fcn-v1.0.md#5-payoff-pseudocode-normative) | ✅ Normative |

**Product SME Reference:** Memory feature follows market standard for equity-linked notes (Asian/European structured products conventions)

---

### 3.4 Coupon Day Count and Accrual (Supporting Rules)

| Rule ID | Description | Formula | Source | v1.0 Status |
|---------|-------------|---------|--------|-------------|
| **BR-CPN-015** | Day count convention for accrual calculations | Default: `ACT/365`; Allowed: `ACT/365`, `ACT/360` | [Spec §3](specs/fcn-v1.0.md#3-parameter-table) | ✅ Normative |
| **BR-CPN-016** | Business day calendar for date adjustments | Default: `TARGET`; follows standard calendar conventions | [Spec §3](specs/fcn-v1.0.md#3-parameter-table) | ✅ Normative |
| **BR-CPN-017** | Coupon observation offset handling | `coupon_observation_offset_days` applied for observation timing | [Spec §3](specs/fcn-v1.0.md#3-parameter-table) | ✅ Normative |

**Regulatory Reference:** Day count conventions per ISDA definitions and local market practice

---

## 4. Knock-In Barrier Rules (v1.0 In-Scope)

### 4.1 Barrier Monitoring

| Rule ID | Description | Formula | Source | v1.0 Status |
|---------|-------------|---------|--------|-------------|
| **BR-KI-001** | KI triggered if ANY underlying breaches barrier | `barrier_breach = ANY(underlying_level_j(i) ≤ initial_level_j × knock_in_barrier_pct)` | [Spec §5](specs/fcn-v1.0.md#5-payoff-pseudocode-normative) | ✅ Normative |
| **BR-KI-002** | KI status persists once triggered | If `barrier_breach`: `ki_triggered = true` (remains true) | [Spec §5](specs/fcn-v1.0.md#5-payoff-pseudocode-normative) | ✅ Normative |
| **BR-KI-003** | KI barrier must be less than redemption barrier | `0 < knock_in_barrier_pct < redemption_barrier_pct ≤ 1.0` | [Spec §3](specs/fcn-v1.0.md#3-parameter-table) | ✅ Normative |
| **BR-KI-004** | Barrier monitoring is discrete (observation dates only) | `barrier_monitoring = "discrete"` (continuous not supported in v1.0) | [Spec §3](specs/fcn-v1.0.md#3-parameter-table) | ✅ Normative |
| **BR-KI-005** | Barrier breach includes equality (≤ not <) | Breach occurs when level is exactly at or below barrier | [Spec §5](specs/fcn-v1.0.md#5-payoff-pseudocode-normative) | ✅ Normative |

**Product SME Reference:** Standard knock-in barrier conventions for barrier options and structured notes

---

## 5. Maturity Redemption Rules (v1.0 In-Scope)

### 5.1 Par-Recovery Mode (Normative Branch)

| Rule ID | Description | Formula | Source | v1.0 Status |
|---------|-------------|---------|--------|-------------|
| **BR-RED-001** | Par-recovery: 100% notional returned regardless of KI status | `redemption_amount = notional_amount` (always) | [Spec §5](specs/fcn-v1.0.md#5-payoff-pseudocode-normative) | ✅ Normative |
| **BR-RED-002** | Redemption barrier evaluation at maturity | `condition_ok = ALL(final_level_j ≥ initial_level_j × redemption_barrier_pct)` | [Spec §5](specs/fcn-v1.0.md#5-payoff-pseudocode-normative) | ✅ Normative |
| **BR-RED-003** | Final underlying levels observed at maturity date | `final_levels = underlying_levels_on(maturity_date)` | [Spec §5](specs/fcn-v1.0.md#5-payoff-pseudocode-normative) | ✅ Normative |
| **BR-RED-004** | Redemption amount identical for KI and non-KI in par-recovery | Baseline v1.0 always returns par (100% notional) | [Spec §5](specs/fcn-v1.0.md#5-payoff-pseudocode-normative) | ✅ Normative |
| **BR-RED-005** | Settlement type normative: physical-settlement | `settlement_type = "physical-settlement"` for v1.0 normative branch | [Spec §3](specs/fcn-v1.0.md#3-parameter-table) | ✅ Normative |

**Product SME Reference:** Par-recovery structure aligns with principal-protected notes offering downside mitigation

---

### 5.2 Proportional-Loss Mode (Non-Normative in v1.0)

| Rule ID | Description | Formula | Source | v1.0 Status |
|---------|-------------|---------|--------|-------------|
| **BR-RED-006** | Proportional-loss: redemption based on worst-performing underlying | `redemption_amount = notional × min(final_level_j / initial_level_j)` (if KI) | [Spec §2](specs/fcn-v1.0.md#2-economic-description) | ⚠️ Non-Normative (Examples Only) |
| **BR-RED-007** | Physical delivery of underlying if proportional-loss and KI | Deliver pro-rata units of worst-performing underlying | [Spec §2](specs/fcn-v1.0.md#2-economic-description) | ⚠️ Non-Normative (Examples Only) |
| **BR-RED-008** | Proportional-loss requires explicit taxonomy code difference | Must be tagged with different branch code (not baseline) | [Spec §5](specs/fcn-v1.0.md#5-payoff-pseudocode-normative) | ⚠️ Non-Normative (Examples Only) |

**Product SME Reference:** Proportional-loss follows market standard for participation notes (equity-linked products)

**Note:** Proportional-loss mode is intentionally excluded from v1.0 normative branch to keep baseline simple. May appear in illustrative examples with explicit taxonomy distinction.

---

### 5.3 Final Coupon Evaluation

| Rule ID | Description | Formula | Source | v1.0 Status |
|---------|-------------|---------|--------|-------------|
| **BR-RED-009** | Final coupon evaluated separately from redemption logic | Maturity observation follows same coupon rules as periodic observations | [Spec §5](specs/fcn-v1.0.md#5-payoff-pseudocode-normative) | ✅ Normative |
| **BR-RED-010** | Final coupon can be paid even if KI triggered | Coupon eligibility independent of redemption amount calculation | [Spec §5](specs/fcn-v1.0.md#5-payoff-pseudocode-normative) | ✅ Normative |

**Product SME Reference:** Standard separation of coupon and principal cash flows in structured note documentation

---

## 6. Early Redemption Rules (Deferred from v1.0)

### 6.1 Autocall / Early Redemption (Future Versions)

| Rule ID | Description | Formula | Source | v1.0 Status |
|---------|-------------|---------|--------|-------------|
| **BR-EARLY-001** | Autocall barrier monitoring | TBD - monitoring frequency and barrier level | Future Spec | ❌ Deferred (v1.1+) |
| **BR-EARLY-002** | Autocall redemption amount calculation | TBD - typically par + accrued coupons | Future Spec | ❌ Deferred (v1.1+) |
| **BR-EARLY-003** | Autocall trigger date determination | TBD - observation date when barrier breached upward | Future Spec | ❌ Deferred (v1.1+) |
| **BR-EARLY-004** | Autocall payment timing | TBD - settlement offset from trigger date | Future Spec | ❌ Deferred (v1.1+) |
| **BR-EARLY-005** | Step-down autocall barrier schedule | TBD - declining barrier levels over time | Future Spec | ❌ Deferred (v1.1+) |

**Placeholder Notes:**
- Early redemption features (autocall) are explicitly out-of-scope for v1.0
- Step-down barrier schedules deferred to v1.1 or later
- Requires extension of observation logic and cash flow termination rules
- Must maintain backward compatibility with v1.0 parameter schema

**Product SME Reference:** To be defined in consultation with product structuring team and market standards for autocallable notes

---

### 6.2 Issuer Call / Put Options (Future Versions)

| Rule ID | Description | Formula | Source | v1.0 Status |
|---------|-------------|---------|--------|-------------|
| **BR-EARLY-006** | Issuer call option exercise conditions | TBD - issuer discretion, notice period, call price | Future Spec | ❌ Deferred (v1.1+) |
| **BR-EARLY-007** | Investor put option exercise conditions | TBD - investor discretion, notice period, put price | Future Spec | ❌ Deferred (v1.1+) |
| **BR-EARLY-008** | Early redemption notice period | TBD - standard market convention (e.g., 30 days) | Future Spec | ❌ Deferred (v1.1+) |
| **BR-EARLY-009** | Early redemption price adjustment | TBD - accrued interest, make-whole provisions | Future Spec | ❌ Deferred (v1.1+) |

**Placeholder Notes:**
- Call/put optionality not included in v1.0 baseline
- Requires additional parameters for exercise windows and pricing
- Must consider tax and regulatory implications

**Regulatory Reference:** To be aligned with local securities regulations and ISDA embedded option provisions

---

## 7. Validation and Data Integrity Rules

### 7.1 Input Validation

| Rule ID | Description | Formula | Source | v1.0 Status |
|---------|-------------|---------|--------|-------------|
| **BR-VAL-001** | Date ordering constraint | `trade_date ≤ issue_date < maturity_date` | [Spec §3](specs/fcn-v1.0.md#3-parameter-table) | ✅ Normative |
| **BR-VAL-002** | Initial levels positivity | `initial_levels[j] > 0` for all j | [Spec §3](specs/fcn-v1.0.md#3-parameter-table) | ✅ Normative |
| **BR-VAL-003** | Array length consistency | `length(underlying_symbols) = length(initial_levels)` | [Spec §3](specs/fcn-v1.0.md#3-parameter-table) | ✅ Normative |
| **BR-VAL-004** | Coupon payment dates alignment | `length(coupon_payment_dates) = length(observation_dates)` | [Spec §3](specs/fcn-v1.0.md#3-parameter-table) | ✅ Normative |
| **BR-VAL-005** | Documentation version matching | `documentation_version` must match active product version | [Spec §3](specs/fcn-v1.0.md#3-parameter-table) | ✅ Normative |

**Source:** [Domain Handoff FCN v1.0 - Business Rules Table](../../sa/handoff/domain-handoff-fcn-v1.0.md#6-initial-business-rules-table)

---

## 8. Implementation Priority and Dependencies

### Priority Classification

- **P0 (Critical):** Required for v1.0 Active status and production deployment
  - All coupon calculation rules (BR-CPN-001 through BR-CPN-017)
  - All knock-in barrier rules (BR-KI-001 through BR-KI-005)
  - All par-recovery redemption rules (BR-RED-001 through BR-RED-005)
  - All validation rules (BR-VAL-001 through BR-VAL-005)

- **P1 (High):** Required for full feature completeness but may have workarounds
  - Memory carry cap enforcement (BR-CPN-013)
  - Final coupon evaluation rules (BR-RED-009, BR-RED-010)

- **P2 (Medium):** Supporting features that enhance functionality
  - Proportional-loss mode rules (BR-RED-006 through BR-RED-008) - examples only

- **Deferred (Future Versions):** Not in v1.0 scope
  - All early redemption rules (BR-EARLY-001 through BR-EARLY-009)

---

## 9. Testing and Validation Requirements

### 9.1 Normative Test Vector Coverage

All P0 business rules must be validated against normative test vectors:
- **N1:** Baseline memory coupon, no KI, all coupons paid
- **N2:** Memory coupon with single miss and recovery
- **N3:** Memory coupon with KI event triggering par-recovery
- **N4:** Non-memory coupon with missed coupon forfeiture
- **N5:** Barrier equality edge case (level = barrier triggers KI)

**Reference:** [FCN v1.0 Test Vector Coverage](specs/fcn-v1.0.md#13-test-vector-coverage)

---

### 9.2 Validator Scripts

| Validator | Rules Covered | Priority | Status |
|-----------|---------------|----------|--------|
| `coupon_decision_validator.py` | BR-CPN-001 through BR-CPN-008 | P0 | Planned |
| `memory_logic_validator.py` | BR-CPN-009 through BR-CPN-014 | P0 | Planned |
| `knock_in_validator.py` | BR-KI-001 through BR-KI-005 | P0 | Planned |
| `redemption_validator.py` | BR-RED-001 through BR-RED-005 | P0 | Planned |
| `parameter_validator.py` | BR-VAL-001 through BR-VAL-005 | P0 | Planned |

**Reference:** [FCN v1.0 Validator Roadmap](validator-roadmap.md)

---

## 10. Regulatory and Compliance Considerations

### 10.1 Market Standards Alignment

- **ISDA Structured Products:** Coupon and redemption logic follows standard ISDA structured product definitions
- **Local Market Practice:** Day count conventions and business day adjustments follow TARGET calendar conventions (European market standard)
- **Barrier Option Standards:** Knock-in barrier monitoring follows standard barrier option conventions

### 10.2 Disclosure Requirements

- Coupon payment conditions must be clearly disclosed in term sheets
- Knock-in barrier levels and monitoring frequency must be explicitly stated
- Memory coupon mechanics and accumulation caps must be documented
- Par-recovery vs. proportional-loss mode must be clearly distinguished

### 10.3 Future Regulatory Considerations

Early redemption features (when implemented in future versions) must comply with:
- Local securities regulations on callable structured products
- Notice period requirements for issuer calls
- Investor protection requirements for put options

---

## 11. Cross-References

### Related Documents

- **Product Specification:** [FCN v1.0 Specification](specs/fcn-v1.0.md)
- **Domain Handoff:** [FCN v1.0 Domain Handoff Package](../../sa/handoff/domain-handoff-fcn-v1.0.md)
- **Validator Roadmap:** [FCN v1.0 Validator Roadmap](validator-roadmap.md)
- **ER Model:** [FCN v1.0 Logical Entity-Relationship Model](er-fcn-v1.0.md)

### Architecture Decision Records

- **ADR-003:** [FCN Version Activation Process](../../sa/design-decisions/adr-003-fcn-version-activation.md)
- **ADR-004:** [Parameter Alias Policy](../../sa/design-decisions/adr-004-parameter-alias-policy.md)

---

## 12. Open Items and Future Enhancements

### 12.1 v1.0 Open Items

1. **Memory Carry Cap Tolerance:** Define behavior when memory accumulation approaches cap
2. **Final Coupon Timing:** Clarify payment date for final coupon vs. redemption amount
3. **FX Conversion Rules:** Detailed rules for multi-currency scenarios (if underlying currency ≠ settlement currency)

### 12.2 Future Version Considerations

1. **v1.1+:** Autocall / early redemption features (BR-EARLY-001 through BR-EARLY-009)
2. **v1.1+:** Step-down barrier schedules
3. **v1.1+:** Proportional-loss mode promotion to normative status (if market demand)
4. **v1.1+:** Continuous barrier monitoring option
5. **v1.2+:** Cash settlement mode promotion to normative status

---

## 13. Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-10 | siripong.s@yuanta.co.th | Initial business rules document for FCN v1.0 covering coupon calculation and redemption scenarios |

---

## 14. Approval and Sign-Off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Product Owner | siripong.s@yuanta.co.th | Pending | - |
| BA Lead | siripong.s@yuanta.co.th | Pending | - |
| SA Lead | TBD | Pending | - |
| Compliance Review | TBD | Pending | - |

---

**Document Status:** Draft  
**Next Review:** 2026-04-10
