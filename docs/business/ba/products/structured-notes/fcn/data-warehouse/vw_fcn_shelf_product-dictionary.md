---
title: FCN Shelf Product View Data Dictionary
doc_type: reference
status: Draft
version: 0.1.0
owner: siripong.s@yuanta.co.th
created: 2025-10-22
last_reviewed: 2025-10-22
classification: Internal
tags: [fcn, data-warehouse, view, dictionary]
related:
  - ../specs/fcn-v1.1.0.md
  - ../specs/SUPERSEDED_INDEX.md
  - ../../../../sa/interfaces/fcn-template-api.md
  - ../../../../sa/interfaces/fcn-trade-api.md
---

# FCN Shelf Product View Data Dictionary (`vw_fcn_shelf_product`)

## 1. Purpose
This document defines the denormalized data warehouse presentation layer view for FCN shelf (template) products. Grain: 1 row per `template_id`.

## 2. Column Definitions
Legend Types: string | decimal(p,s) | int | date | timestamp | bool/flag (0/1)

| Column | Type | Detailed Description | Range / Enumeration | Derivation Logic | Validation / Quality Notes | Example |
|--------|------|----------------------|---------------------|------------------|----------------------------|---------|
| template_id | string | Unique identifier for the FCN shelf product (source PK). | UUID; non-null unique | Direct from `fcn_template` | Must be unique; not null | fcntmp-3f4d8c90-5bd7-44b5-9d7e-2e7e4d11aaa |
| template_code | string | Business mnemonic or short code. | ≤64 chars; nullable | Direct | Null => fallback to template_id in UI | FCN_QTR_BUFFER_80_110 |
| product_type | string | Product family discriminator. | 'fcn' | Constant | No nulls | fcn |
| spec_version | string | Specification semantic version. | \d+.\d+.\d+ (e.g. 1.1.0) | Direct | Should be Active (or rare Superseded for legacy) | 1.1.0 |
| issuer | string | Issuing entity code. | Uppercase alphanumeric | Direct | Must exist in whitelist; else DQ flag | YUANTA |
| issuer_class | string | Risk tier / origin classification. | internal | external | partner | tier1 | tier2 | Join to issuer reference | Null until mapping available | internal |
| underlying_count | int | Number of underlying assets. | ≥1 typical ≤10 | COUNT(*) underlying table | Should equal length of underlying_symbols split | 2 |
| underlying_symbols | string | Comma-separated ordered tickers. | Each ticker pattern ^[A-Z0-9._-]{1,12}$ | STRING_AGG ORDER BY symbol | No leading/trailing comma; deterministic order | AAPL,TSLA |
| observation_count | int | Total scheduled observation dates. | ≥1 (4–24 common) | COUNT(*) schedule | 0 => invalid | 5 |
| first_observation_date | date | Earliest observation date. | >= issue_date; < last_observation_date | MIN(date) | If equals last while count>1 => anomaly | 2025-11-01 |
| last_observation_date | date | Latest observation date (near maturity). | > first when count>1 | MAX(date) | Large tenor (>5y typical) flagged | 2026-11-01 |
| observation_frequency_months | int | Months between observations (regular cadence). | 1,3,6,12 common; nullable | Direct | Null + regular intervals => inference candidate | 3 |
| coupon_rate_pct_period | decimal | Per-period coupon rate (fraction). | >0; usually ≤0.20 | Direct | <=0 or >0.50 flagged | 0.045 |
| coupon_rate_pct_annualized | decimal | Annualized coupon (period * periods/year). | Derived; typical ≤0.30 | rate * (12 / freq) | Null if freq null | 0.18 |
| coupon_condition_threshold_pct | decimal | Performance threshold for coupon eligibility. | 0.60–1.05 typical | Direct | < KI barrier => INCONSISTENT_THRESHOLDS | 0.85 |
| is_memory_coupon | bool/flag | Memory feature indicator. | 0 or 1 | Direct | If 1 and cap=0 invalid | 1 |
| memory_carry_cap_count | int | Max missed coupons recoverable; null=unlimited. | ≥1 or null | Direct | Present only if memory active | (null) |
| knock_in_barrier_pct | decimal | Downside KI barrier level fraction. | 0 < x < 1 (0.50–0.80 common) | Direct | >= coupon threshold => inconsistency | 0.60 |
| put_strike_pct | decimal | Capital-at-risk soft protection strike. | KI barrier < strike ≤ 1.0 | Direct | Required if recovery_mode='capital-at-risk'; else null | 0.80 |
| knock_out_barrier_pct | decimal | Autocall (KO) barrier. | Typically 1.05–1.30 | Direct | If present logic must exist; <=1.0 requires explanation | 1.10 |
| auto_call_logic | string | Autocall evaluation logic. | all-underlyings (current) | Direct | Null while KO barrier present => MISSING_AUTOCALL_LOGIC | all-underlyings |
| barrier_monitoring_type | string | Barrier observation mode. | discrete (current) | Direct | Unknown value => flag | discrete |
| settlement_type | string | Settlement modality. | cash-settlement | physical-settlement | Direct | Must be canonical; else patch required | cash-settlement |
| recovery_mode | string | Downside regime after KI. | par-recovery | proportional-loss | capital-at-risk | Direct | If capital-at-risk & strike null => MISSING_STRIKE | capital-at-risk |
| has_autocall_flag | int | Presence of KO feature. | 0/1 | KO barrier not null | Logic present if 1 | 1 |
| is_capital_at_risk_flag | int | Capital-at-risk regime indicator. | 0/1 | recovery_mode match | Strike must exist when 1 | 1 |
| protection_buffer_pct | decimal | Strike - KI barrier distance (buffer width). | >0 typical 0.05–0.30 | strike - KI barrier | Negative => NEGATIVE_BUFFER | 0.20 |
| downside_slope_factor | decimal | Post-KI payoff slope multiplier. | par=0; proportional=1; capital-at-risk ≥1 | CASE by recovery_mode | slope <1 for capital-at-risk => anomaly | 1.25 |
| risk_profile_bucket | string | BI classification of downside profile. | Protected | Buffered-Deep | Buffered-Shallow | Linear | Unknown | CASE rules | Unknown => UNKNOWN_CLASSIFICATION | Buffered-Deep |
| normative_coupon_flag | int | Threshold meets normative criteria (>=80%). | 0/1 | threshold >=0.80 | Null threshold => 0 | 1 |
| status | string | Template lifecycle state. | active | deprecated | superseded | inactive | Direct | Superseded optionally filtered | active |
| currency | string | Settlement currency. | ISO-4217 uppercase | Direct | Non-ISO => flag | USD |
| created_at | timestamp | Creation timestamp (UTC). | Past <= updated_at | Direct | Future timestamp => anomaly | 2025-10-16T08:15:00Z |
| updated_at | timestamp | Last update timestamp (UTC). | >= created_at | Direct | Diff >> expected -> stale candidate | 2025-10-17T02:00:00Z |
| data_quality_warnings | string | Semicolon list of detected data issues. | Values: MISSING_STRIKE; MISSING_AUTOCALL_LOGIC; MISSING_FREQ; INCONSISTENT_THRESHOLDS; NEGATIVE_BUFFER; UNKNOWN_CLASSIFICATION | Aggregation from CASE rules | Null => clean row | (null) |

## 3. Derived Classification Rules
- risk_profile_bucket:
  - par-recovery => Protected
  - capital-at-risk & protection_buffer_pct >= 0.15 => Buffered-Deep
  - capital-at-risk & protection_buffer_pct < 0.15 => Buffered-Shallow
  - proportional-loss => Linear
  - else => Unknown

## 4. Data Quality Rule Summary
| Rule | Condition | Warning Code |
|------|-----------|--------------|
| Missing Strike | recovery_mode='capital-at-risk' AND put_strike_pct IS NULL | MISSING_STRIKE |
| Missing Autocall Logic | knock_out_barrier_pct IS NOT NULL AND auto_call_logic IS NULL | MISSING_AUTOCALL_LOGIC |
| Missing Frequency | observation_frequency_months IS NULL AND observation_count > 1 | MISSING_FREQ |
| Inconsistent Thresholds | coupon_condition_threshold_pct <= knock_in_barrier_pct | INCONSISTENT_THRESHOLDS |
| Negative Buffer | protection_buffer_pct < 0 | NEGATIVE_BUFFER |
| Unknown Classification | risk_profile_bucket='Unknown' | UNKNOWN_CLASSIFICATION |

## 5. Sample Row
```
template_id: fcntmp-3f4d8c90-5bd7-44b5-9d7e-2e7e4d11aaa
template_code: FCN_QTR_BUFFER_80_110
product_type: fcn
spec_version: 1.1.0
issuer: YUANTA
issuer_class: internal
underlying_count: 2
underlying_symbols: AAPL,TSLA
observation_count: 5
first_observation_date: 2025-11-01
last_observation_date: 2026-11-01
observation_frequency_months: 3
coupon_rate_pct_period: 0.045
coupon_rate_pct_annualized: 0.18
coupon_condition_threshold_pct: 0.85
is_memory_coupon: 1
memory_carry_cap_count: null
knock_in_barrier_pct: 0.60
put_strike_pct: 0.80
knock_out_barrier_pct: 1.10
auto_call_logic: all-underlyings
barrier_monitoring_type: discrete
settlement_type: cash-settlement
recovery_mode: capital-at-risk
has_autocall_flag: 1
is_capital_at_risk_flag: 1
protection_buffer_pct: 0.20
downside_slope_factor: 1.25
risk_profile_bucket: Buffered-Deep
normative_coupon_flag: 1
status: active
currency: USD
created_at: 2025-10-16T08:15:00Z
updated_at: 2025-10-17T02:00:00Z
data_quality_warnings: null
```

## 6. Future Enhancements
- Add `tenor_months` derived via DATEDIFF.
- Introduce `annual_coupon_yield_score` normalization metric.
- Add `strike_distance_to_par_pct = 1 - put_strike_pct`.
- JSON column `underlyings_json` for BI tool ingestion.
- Reference dimension joins for issuer_class enrichment.

## 7. Change Log
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1.0 | 2025-10-22 | siripong.s@yuanta.co.th | Initial draft data dictionary for vw_fcn_shelf_product |