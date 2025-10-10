---
title: FCN v1.0 Business Rules
doc_type: business-rule
status: Draft
version: 1.0.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-10
last_reviewed: 2025-10-10
next_review: 2026-04-10
classification: Internal
tags: [fcn, business-rules, structured-notes, validation, v1.0]
related:
  - specs/fcn-v1.0.md
  - er-fcn-v1.0.md
  - manifest.yaml
  - ../../sa/handoff/domain-handoff-fcn-v1.0.md
  - ../../sa/design-decisions/adr-003-fcn-version-activation.md
  - ../../sa/design-decisions/adr-004-parameter-alias-policy.md
---

# FCN v1.0 Business Rules

## 1. Purpose

This document defines the complete set of business rules governing Fixed Coupon Note (FCN) v1.0 product validation, lifecycle processing, and data integrity. These rules ensure consistency across specification, API design, database constraints, and test coverage.

## 2. Scope

- **Input Validation Rules**: Constraint enforcement at trade booking
- **Business Logic Rules**: Knock-in detection, coupon eligibility, settlement calculation
- **Data Integrity Rules**: Referential consistency and computational correctness
- **Governance Rules**: Version control, test coverage, and change management

## 3. Business Rules Table

| Rule ID | Category | Description | Source / Owner | Priority | Status |
|---------|----------|-------------|----------------|----------|--------|
| BR-001 | Validation | trade_date ≤ issue_date < maturity_date | Spec fcn-v1.0.md §3 / BA (siripong.s@yuanta.co.th) | P0 | Draft |
| BR-002 | Validation | All initial_levels > 0 | Spec fcn-v1.0.md §3 (Parameter Table: initial_levels constraints) / BA (siripong.s@yuanta.co.th) | P0 | Draft |
| BR-003 | Validation | 0 < knock_in_barrier_pct < redemption_barrier_pct ≤ 1.0 | Spec fcn-v1.0.md §3 (Parameter Table: knock_in_barrier_pct, redemption_barrier_pct constraints) / BA (siripong.s@yuanta.co.th) | P0 | Draft |
| BR-004 | Validation | documentation_version must match active product version | Governance Policy (governance.md) + Spec fcn-v1.0.md §3 / BA (siripong.s@yuanta.co.th) | P1 | Draft |
| BR-005 | KI Logic | KI triggered if ANY underlying closes ≤ initial × knock_in_barrier_pct | Spec fcn-v1.0.md §5 (Payoff Pseudocode: barrier_breach condition) / BA (siripong.s@yuanta.co.th) | P0 | Draft |
| BR-006 | Coupon Logic | Coupon condition satisfied if ALL underlyings close ≥ initial × coupon_condition_threshold_pct | Spec fcn-v1.0.md §5 (Payoff Pseudocode: level_ok condition) / BA (siripong.s@yuanta.co.th) | P0 | Draft |
| BR-007 | Observation | Each observation date processed exactly once (idempotent) | Technical Design (domain-handoff-fcn-v1.0.md §7) / SA (siripong.s@yuanta.co.th) | P0 | Draft |
| BR-008 | Coupon Logic | Memory accumulation capped at memory_carry_cap_count (if set) | Spec fcn-v1.0.md §3 (Parameter Table: memory_carry_cap_count) + §5 (Payoff Pseudocode: accrued_unpaid logic) / BA (siripong.s@yuanta.co.th) | P1 | Draft |
| BR-009 | Coupon Calc | coupon_amount = notional × coupon_rate_pct × coupons_paid_count | Spec fcn-v1.0.md §5 (Payoff Pseudocode: pay_coupon calculation) / BA (siripong.s@yuanta.co.th) | P0 | Draft |
| BR-010 | Coupon Timing | Payment date from coupon_payment_dates array, indexed by observation | Spec fcn-v1.0.md §3 (Parameter Table: coupon_payment_dates) / BA (siripong.s@yuanta.co.th) | P0 | Draft |
| BR-011 | Settlement | Par recovery returns 100% notional at maturity (KI irrelevant) | Spec fcn-v1.0.md §2 (Economic Description) + §5 (Payoff Pseudocode: redemption_amount logic) / BA (siripong.s@yuanta.co.th) | P0 | Draft |
| BR-012 | Settlement | Physical settlement delivers pro-rata underlying units if KI & proportional-loss | Spec fcn-v1.0.md §2 (Economic Description) + §3 (Parameter Table: settlement_type, recovery_mode) / BA (siripong.s@yuanta.co.th) | P1 | Draft |
| BR-013 | Settlement | Final coupon evaluated separately from redemption logic | Spec fcn-v1.0.md §5 (Payoff Pseudocode: maturity section) / BA (siripong.s@yuanta.co.th) | P1 | Draft |
| BR-014 | Validation | Observation dates must be strictly increasing and < maturity_date | Spec fcn-v1.0.md §3 (Parameter Table: observation_dates constraints) / BA (siripong.s@yuanta.co.th) | P0 | Draft |
| BR-015 | Validation | underlying_symbols array length = initial_levels array length | Spec fcn-v1.0.md §3 (Parameter Table: initial_levels length constraint) / BA (siripong.s@yuanta.co.th) | P0 | Draft |
| BR-016 | Data Integrity | Basket weights sum to 1.0 (if explicit; default equal-weight) | Technical Design (domain-handoff-fcn-v1.0.md §7, er-fcn-v1.0.md §6) / SA (siripong.s@yuanta.co.th) | P2 | Draft |
| BR-017 | Test Coverage | Normative test vectors required for Proposed → Active promotion | ADR-003 (FCN Version Activation & Promotion Workflow) / SA (siripong.s@yuanta.co.th) | P0 | Draft |
| BR-018 | Versioning | Parameter schema changes require new product version | ADR-004 (Parameter Alias & Deprecation Policy) / SA (siripong.s@yuanta.co.th) | P1 | Draft |

## 4. Rule Categories

### 4.1 Validation Rules (BR-001 to BR-004, BR-014, BR-015)
Input constraint enforcement at trade booking time. These rules must be implemented in:
- API layer validation (request validation)
- Database schema constraints (check constraints, foreign keys)
- Test vector validation scripts

### 4.2 Business Logic Rules (BR-005 to BR-013)
Core product behavior and calculation logic. These rules define:
- Knock-in event detection (BR-005)
- Coupon eligibility and payment (BR-006, BR-008, BR-009, BR-010)
- Settlement and redemption (BR-011, BR-012, BR-013)
- Observation processing (BR-007)

### 4.3 Data Integrity Rules (BR-016)
Referential and computational consistency across entities. Enforced through:
- Database constraints and triggers
- Data quality validation scripts
- Reconciliation processes

### 4.4 Governance Rules (BR-017, BR-018)
Quality gates and change management policies. Enforced through:
- Promotion workflow (ADR-003)
- Version control and deprecation policy (ADR-004)
- Test coverage requirements

## 5. Implementation Mapping

### 5.1 API Layer
- **Validation Rules**: Implement in request validation middleware using JSON Schema
- **Business Logic**: Implement in pricing engine and lifecycle processing services
- **Error Messages**: Map rule violations to specific error codes and user-friendly messages

### 5.2 Database Layer
- **Validation Rules**: Implement as CHECK constraints, NOT NULL constraints, foreign keys
- **Data Integrity**: Implement as triggers, computed columns, and database functions
- **Audit Trail**: Log all rule violations with rule ID for traceability

### 5.3 Test Coverage
- **Unit Tests**: Cover each rule independently with edge cases
- **Integration Tests**: Cover rule interactions and dependencies
- **Normative Test Vectors**: Map each test vector to the rules it validates (see test-vectors/*.md)

## 6. Traceability Matrix

| Rule ID | Spec Section | ER Model Entity | JSON Schema Path | Test Vector(s) |
|---------|--------------|-----------------|------------------|----------------|
| BR-001 | fcn-v1.0.md §3 | Trade (trade_date, issue_date, maturity_date) | /properties/trade_date, /properties/issue_date, /properties/maturity_date | All normative vectors |
| BR-002 | fcn-v1.0.md §3 | Underlying_Asset (initial_level) | /properties/initial_levels/items | All normative vectors |
| BR-003 | fcn-v1.0.md §3 | Trade (knock_in_barrier_pct, redemption_barrier_pct) | /properties/knock_in_barrier_pct, /properties/redemption_barrier_pct | All normative vectors |
| BR-004 | fcn-v1.0.md §3 | Trade (documentation_version) | /properties/documentation_version | All normative vectors |
| BR-005 | fcn-v1.0.md §5 | Observation, Underlying_Level, Trade (ki_triggered) | Calculated field | fcn-v1.0-base-mem-ki-event.md |
| BR-006 | fcn-v1.0.md §5 | Coupon_Decision (condition_satisfied) | Calculated field | fcn-v1.0-base-mem-baseline.md, fcn-v1.0-base-mem-single-miss.md |
| BR-007 | domain-handoff §7 | Observation (is_processed) | Calculated field | All normative vectors |
| BR-008 | fcn-v1.0.md §3, §5 | Coupon_Decision (accumulated_unpaid) | /properties/memory_carry_cap_count | fcn-v1.0-base-mem-baseline.md |
| BR-009 | fcn-v1.0.md §5 | Coupon_Decision (coupon_amount) | Calculated field | All normative vectors |
| BR-010 | fcn-v1.0.md §3 | Coupon_Decision (payment_date) | /properties/coupon_payment_dates | All normative vectors |
| BR-011 | fcn-v1.0.md §2, §5 | Trade (recovery_mode) | /properties/recovery_mode | fcn-v1.0-base-mem-baseline.md |
| BR-012 | fcn-v1.0.md §2, §3 | Trade (settlement_type, recovery_mode) | /properties/settlement_type, /properties/recovery_mode | Future proportional-loss vectors |
| BR-013 | fcn-v1.0.md §5 | Coupon_Decision | Calculated field | All normative vectors |
| BR-014 | fcn-v1.0.md §3 | Observation (observation_date) | /properties/observation_dates/items | All normative vectors |
| BR-015 | fcn-v1.0.md §3 | Underlying_Asset | /properties/underlying_symbols, /properties/initial_levels | All normative vectors |
| BR-016 | domain-handoff §7 | Underlying_Asset (weight) | Calculated field | Future basket vectors |
| BR-017 | ADR-003 | Test_Vector | Test vector metadata | Activation checklist |
| BR-018 | ADR-004 | Product_Version | Version control | Governance process |

## 7. Rule Validation Strategy

### 7.1 Phase 0: Metadata & Structure (Completed)
- Validate spec file structure and required sections
- Validate parameter table completeness
- Validate JSON schema alignment

### 7.2 Phase 1: Taxonomy & Branch (Completed)
- Validate taxonomy dimensions
- Validate branch codes and inventories

### 7.3 Phase 2: Parameter Constraints (In Progress)
- Validate all validation rules (BR-001 to BR-004, BR-014, BR-015)
- Implement parameter validation scripts

### 7.4 Phase 3: Test Vector Coverage (In Progress)
- Map test vectors to business rules
- Validate normative test vector completeness (BR-017)

### 7.5 Phase 4: Business Logic Validation (Planned)
- Validate business logic rules (BR-005 to BR-013)
- Implement pricing engine validators
- Validate lifecycle processing correctness

## 8. Open Questions

| ID | Question | Owner | Target Resolution |
|----|----------|-------|-------------------|
| OQ-BR-001 | Should BR-003 allow knock_in_barrier_pct = redemption_barrier_pct for specific edge cases? | BA | Week 1 |
| OQ-BR-002 | Should BR-007 idempotency be enforced at database level (unique constraint) or application level? | SA | Week 2 |
| OQ-BR-003 | What is the exact error message format for rule violations? | BA + SA | Week 2 |
| OQ-BR-004 | Should BR-016 basket weight validation support tolerance (e.g., 0.9999 acceptable)? | BA | Week 1 |

## 9. Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-10 | siripong.s@yuanta.co.th | Initial business rules table with populated Source/Owner for all 18 rules |

## 10. References

- **Specification**: [FCN v1.0 Specification](specs/fcn-v1.0.md)
- **ER Model**: [FCN v1.0 Entity-Relationship Model](er-fcn-v1.0.md)
- **Domain Handoff**: [FCN v1.0 Domain Handoff Package](../../sa/handoff/domain-handoff-fcn-v1.0.md)
- **Governance**: [Structured Notes Documentation Governance](../common/governance.md)
- **ADR-003**: [FCN Version Activation & Promotion Workflow](../../sa/design-decisions/adr-003-fcn-version-activation.md)
- **ADR-004**: [Parameter Alias & Deprecation Policy](../../sa/design-decisions/adr-004-parameter-alias-policy.md)
- **Test Vectors**: [FCN v1.0 Test Vectors](test-vectors/)
