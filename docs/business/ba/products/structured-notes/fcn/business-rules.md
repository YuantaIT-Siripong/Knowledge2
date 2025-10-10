---
title: FCN v1.0 Business Rules and Data Mapping
doc_type: business-rules
status: Draft
version: 1.0.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-10
last_reviewed: 2025-10-10
next_review: 2026-04-10
classification: Internal
tags: [structured-notes, fcn, business-rules, data-mapping]
related:
  - specs/fcn-v1.0.md
  - er-fcn-v1.0.md
  - ../../sa/handoff/domain-handoff-fcn-v1.0.md
---

# FCN v1.0 Business Rules and Data Mapping

## 1. Purpose

This document provides a comprehensive mapping between:
- **JSON Schema Fields**: Input parameters defined in `fcn-v1.0-parameters.schema.json`
- **Business Rules**: Validation and logic rules (BR-001 through BR-018)
- **Data Model Attributes**: Persistent entities and attributes from the logical ER model

This mapping serves Solution Architecture, audit requirements, and traceability for FCN v1.0.

## 2. Rule-Schema-Data Mapping Table

| JSON Schema Field | Data Type | Required | Business Rule ID(s) | Data Model Entity.Attribute | Notes |
|-------------------|-----------|----------|---------------------|----------------------------|-------|
| trade_date | date | Yes | BR-001 | Trade.trade_date | Date of trade agreement; validated against issue_date |
| issue_date | date | Yes | BR-001 | Trade.issue_date | Settlement/note inception; must be ≥ trade_date and < maturity_date |
| maturity_date | date | Yes | BR-001, BR-014 | Trade.maturity_date | Final maturity; must be > issue_date and > all observation_dates |
| underlying_symbols | array[string] | Yes | BR-002, BR-015 | Underlying_Asset.symbol | Ticker/ISIN identifiers; length must match initial_levels |
| initial_levels | array[decimal] | Yes | BR-002, BR-015 | Underlying_Asset.initial_level | Reference levels at inception; all must be > 0 |
| notional_amount | decimal | Yes | BR-009 | Trade.notional | Face amount in currency units; used in coupon calculation |
| currency | string | Yes | - | Trade.currency | ISO-4217 settlement currency (e.g., USD, THB) |
| observation_dates | array[date] | Yes | BR-007, BR-014 | Observation.observation_date | Scheduled observation dates; must be strictly increasing and < maturity_date |
| coupon_observation_offset_days | integer | No | - | (Not persisted) | Business day offset for coupon observation timing |
| coupon_payment_dates | array[date] | Yes | BR-010 | (Related to Observation) | Payment dates indexed by observation; each ≥ issue_date |
| coupon_rate_pct | decimal | Yes | BR-009 | Trade.coupon_rate_pct | Period coupon rate as decimal; used in coupon amount calculation |
| is_memory_coupon | boolean | No | BR-008 | Trade.is_memory_coupon | Memory feature flag; enables missed coupon accumulation |
| memory_carry_cap_count | integer | No | BR-008 | (Business logic) | Limits accumulated unpaid coupons if is_memory_coupon=true; null = unlimited |
| knock_in_barrier_pct | decimal | Yes | BR-003, BR-005 | Trade.knock_in_barrier_pct | KI barrier level as decimal; must be < redemption_barrier_pct |
| barrier_monitoring | string | Yes | - | Trade.observation_style | Monitoring style; only "discrete" supported in v1.0 |
| knock_in_condition | string | Yes | BR-005 | (Business logic) | Condition logic; only "any-underlying-breach" in v1.0 |
| redemption_barrier_pct | decimal | Yes | BR-003 | (Business logic) | Final redemption barrier; must be > knock_in_barrier_pct and ≤ 1.0 |
| settlement_type | string | Yes | BR-012 | Trade.settlement_type | Physical or cash settlement; baseline uses "physical-settlement" |
| coupon_condition_threshold_pct | decimal | No | BR-006 | Trade.coupon_barrier_pct | Coupon eligibility threshold; defaults to 1.0 |
| recovery_mode | string | Yes | BR-011, BR-012 | Trade.recovery_mode | Post-KI payoff: "par-recovery" (baseline) or "proportional-loss" |
| day_count_convention | string | No | - | (Business logic) | Accrual convention (ACT/365, ACT/360); defaults to ACT/365 |
| business_day_calendar | string | No | - | (Business logic) | Calendar for date adjustments; defaults to TARGET |
| fx_reference | string | No | - | Trade.fx_reference | FX rate source; required if underlying currency ≠ settlement currency |
| documentation_version | string | Yes | BR-004 | Trade.documentation_version | Traceability anchor; must match active product version |

### Mapping Notes

1. **Array Fields**: `underlying_symbols` and `initial_levels` decompose into `Underlying_Asset` entity records with one-to-many relationship to `Trade`.

2. **Observation Dates**: `observation_dates` array creates multiple `Observation` entity records, each linked to the parent `Trade`.

3. **Business Logic Parameters**: Some fields (e.g., `knock_in_condition`, `memory_carry_cap_count`) drive business logic but may not persist as dedicated database columns; captured in constraints or computed fields.

4. **Conditional Requirements**: 
   - `memory_carry_cap_count` required only if `is_memory_coupon=true`
   - `fx_reference` required if underlying currency ≠ settlement currency

5. **Derived/Computed Fields**: Not in JSON schema but computed during lifecycle:
   - `ki_triggered` (boolean): Derived from observation processing (BR-005)
   - `eligible_coupon` (boolean[]): Per-period coupon eligibility (BR-006)
   - `accrued_memory_count` (integer[]): Running count of unpaid coupons (BR-008)

## 3. Business Rules Reference

The following business rules govern FCN v1.0 validation and lifecycle processing:

| Rule ID | Category | Description | Priority |
|---------|----------|-------------|----------|
| BR-001 | Validation | trade_date ≤ issue_date < maturity_date | P0 |
| BR-002 | Validation | All initial_levels > 0 | P0 |
| BR-003 | Validation | 0 < knock_in_barrier_pct < redemption_barrier_pct ≤ 1.0 | P0 |
| BR-004 | Validation | documentation_version must match active product version | P1 |
| BR-005 | KI Logic | KI triggered if ANY underlying closes ≤ initial × knock_in_barrier_pct | P0 |
| BR-006 | Coupon Logic | Coupon condition satisfied if ALL underlyings close ≥ initial × coupon_condition_threshold_pct | P0 |
| BR-007 | Observation | Each observation date processed exactly once (idempotent) | P0 |
| BR-008 | Coupon Logic | Memory accumulation capped at memory_carry_cap_count (if set) | P1 |
| BR-009 | Coupon Calc | coupon_amount = notional × coupon_rate_pct × coupons_paid_count | P0 |
| BR-010 | Coupon Timing | Payment date from coupon_payment_dates array, indexed by observation | P0 |
| BR-011 | Settlement | Par recovery returns 100% notional at maturity (KI irrelevant) | P0 |
| BR-012 | Settlement | Physical settlement delivers pro-rata underlying units if KI & proportional-loss | P1 |
| BR-013 | Settlement | Final coupon evaluated separately from redemption logic | P1 |
| BR-014 | Validation | Observation dates must be strictly increasing and < maturity_date | P0 |
| BR-015 | Validation | underlying_symbols array length = initial_levels array length | P0 |
| BR-016 | Data Integrity | Basket weights sum to 1.0 (if explicit; default equal-weight) | P2 |
| BR-017 | Test Coverage | Normative test vectors required for Proposed → Active promotion | P0 |
| BR-018 | Versioning | Parameter schema changes require new product version | P1 |

### Rule Categories
- **Validation**: Input constraint enforcement (BR-001, BR-002, BR-003, BR-004, BR-014, BR-015)
- **KI Logic**: Knock-in event determination (BR-005)
- **Coupon Logic**: Coupon eligibility and payment (BR-006, BR-008)
- **Coupon Calc**: Amount computation (BR-009)
- **Coupon Timing**: Payment scheduling (BR-010)
- **Settlement**: Maturity payoff calculation (BR-011, BR-012, BR-013)
- **Observation**: Market data processing (BR-007)
- **Data Integrity**: Referential and computational consistency (BR-016)
- **Test Coverage**: Quality gates (BR-017)
- **Versioning**: Change management (BR-018)

## 4. Data Model Entity Summary

The following entities persist FCN v1.0 trade data:

### Core Entities

**Product**: Product definition and versioning metadata
- Attributes: `product_id`, `product_code`, `product_name`, `spec_version`, `status`

**Product_Version**: Version-specific metadata and promotion state
- Attributes: `version_id`, `product_id`, `version`, `status`, `spec_file_path`, `parameter_schema_path`

**Branch**: Taxonomy-specific payoff branches
- Attributes: `branch_id`, `product_id`, `version_id`, `branch_code`, `barrier_type`, `settlement`, `coupon_memory`, `recovery_mode`

**Parameter_Definition**: Parameter metadata for a product version
- Attributes: `parameter_id`, `version_id`, `parameter_name`, `parameter_type`, `required`, `constraints`, `description`

### Trade Execution Entities

**Trade**: Individual FCN trade instance
- Attributes: `trade_id`, `product_id`, `branch_id`, `trade_date`, `issue_date`, `maturity_date`, `notional`, `currency`, `observation_style`, `knock_in_barrier_pct`, `coupon_rate_pct`, `coupon_barrier_pct`, `is_memory_coupon`, `recovery_mode`, `settlement_type`, `fx_reference`, `documentation_version`

**Underlying_Asset**: Links trades to underlying assets
- Attributes: `asset_id`, `trade_id`, `symbol`, `initial_level`, `weight`, `asset_type`

**Observation**: Scheduled observation dates and events
- Attributes: `observation_id`, `trade_id`, `observation_date`, `observation_index`, `is_processed`, `processed_at`

**Underlying_Level**: Observed underlying asset levels
- Attributes: `level_id`, `observation_id`, `asset_id`, `level`, `performance_pct`, `recorded_at`

**Coupon_Decision**: Coupon payment decisions per observation
- Attributes: `decision_id`, `observation_id`, `barrier_breached`, `coupon_paid`, `missed_coupons_accumulated`, `notes`

**Settlement**: Final settlement calculation
- Attributes: `settlement_id`, `trade_id`, `settlement_date`, `settlement_amount`, `ki_triggered`, `recovery_applied`, `physical_delivery_units`, `notes`

## 5. Validation Cross-Reference

### Schema Validation (parameter_validator.py)
The JSON schema enforces:
- Type conformance (string, number, boolean, date, array)
- Required field presence
- Numeric constraints (minimum, maximum, exclusiveMinimum, exclusiveMaximum)
- String patterns (e.g., ISO-4217 currency codes)
- Array constraints (minItems, item schemas)
- Enum domain restrictions (e.g., recovery_mode, settlement_type)

### Business Rule Validation
Business rules enforce cross-field logic not expressible in JSON schema:
- Date ordering (BR-001, BR-014)
- Array length consistency (BR-015)
- Numeric relationships (BR-003)
- Conditional requirements (memory_carry_cap_count, fx_reference)
- Basket weight summation (BR-016)

## 6. Usage for Solution Architecture and Audits

This mapping table supports:

1. **Implementation Guidance**: Maps input parameters to persistence layer attributes
2. **Test Coverage Planning**: Identifies which parameters exercise which business rules
3. **Audit Traceability**: Links business requirements to data structures and validation logic
4. **Change Impact Analysis**: Determines scope when modifying schemas, rules, or data models
5. **Documentation Completeness**: Ensures all required fields have business rule coverage

## 7. Related Documentation

- [FCN v1.0 Specification](specs/fcn-v1.0.md): Full product specification
- [FCN v1.0 Logical ER Model](er-fcn-v1.0.md): Detailed entity-relationship definitions
- [Domain Handoff FCN v1.0](../../sa/handoff/domain-handoff-fcn-v1.0.md): Initial business rules table
- [FCN Parameter Definitions Database](../../../../db/README.md): Database schema and field mapping
- [FCN Validators](validators/README.md): Validation scripts and CI integration
- [Structured Notes Conventions](../common/conventions.md): Naming and design conventions

## 8. Change Log

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2025-10-10 | 1.0.0 | siripong.s@yuanta.co.th | Initial mapping table creation; complete first pass for FCN v1.0 |

---

**Document Status**: Draft  
**Review Cycle**: Semi-annual  
**Next Review**: 2026-04-10
