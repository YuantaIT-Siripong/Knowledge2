---
title: FCN Data Model (Logical – Draft)
version: 0.1.0-draft
status: draft
owner: BA
updated: 2025-10-10
tags: [fcn, data, model]
---

# Logical Data Model (Draft)

## 1. Entities & Attributes (Logical Level)

### 1.1 FCNContract
| Attribute | Description | Type (Logical) | Required | Related Rules | Sensitive | Notes |
|-----------|-------------|----------------|----------|---------------|----------|-------|
| id | Unique identifier | Identifier | Yes | — | No | System-generated |
| issueDate | Formal issuance date | Date | Yes | BR-* | No | ISO 8601 |
| notional | Contract notional | Decimal | Yes | BR-05 | Possibly | Precision TBD |
| status | Lifecycle status | Enum(draft, active, matured, terminated) | Yes | BR-* | No | |
| productVersion | Spec version | String | Yes | — | No | e.g., 1.0.0 |

### 1.2 Underlying
| Attribute | Description | Type | Required | Rules | Notes |
|-----------|-------------|------|---------|-------|-------|
| symbol | Asset code | String | Yes | BR-* | Market data feed |
| type | Equity/Index/etc. | Enum | Yes | — | |

### 1.3 Observation
| Attribute | Description | Type | Required | Rules | Notes |
|-----------|-------------|------|---------|-------|-------|
| date | Scheduled check date | Date | Yes | BR-01 | Ascending |
| result | Outcome (meetsCouponCondition?) | Boolean | No | — | Derived |

### 1.4 CouponPayment
| Attribute | Description | Type | Required | Rules | Notes |
|-----------|-------------|------|---------|-------|-------|
| paymentDate | Date funds due | Date | Yes | BR-02 | |
| amount | Coupon amount | Decimal | Yes | Calc | Derived from notional & rate |
| status | pending/paid | Enum | Yes | — | |

### 1.5 Barrier
| Attribute | Description | Type | Required | Rules | Notes |
|-----------|-------------|------|---------|-------|-------|
| level | KI threshold | Decimal | Yes | BR-04 | |
| monitoringType | discrete/continuous | Enum | Yes | BR-* | |

### 1.6 MemoryFeature
| Attribute | Description | Type | Required | Rules | Notes |
|-----------|-------------|------|---------|-------|-------|
| isMemoryCoupon | Memory enabled | Boolean | Yes | BR-03 | |
| memoryCarryCapCount | Accrual cap | Integer | Conditional | BR-03 | Null if disabled |

## 2. Reference / Enumerations (Draft)
| Enum Name | Values (Draft) | Notes |
|-----------|----------------|-------|
| Status | draft, active, matured, terminated | May add redeemed |
| MonitoringType | discrete, continuous | Validate support |
| Currency (v1) | <single currency code> | Multi-currency later |

## 3. Attribute Open Questions
| ID | Question | Entity | Owner | Due | Status |
|----|----------|--------|-------|-----|--------|
| DAT-01 | Decimal precision for notional? | FCNContract | Product | 2025-10-18 | Open |

## 4. Mapping to Schema (To Complete)
Plan: Add column referencing JSON Pointers for each attribute once schema stable.

## 5. Data Quality Dimensions (Targets)
| Dimension | Target | Notes |
|-----------|--------|-------|
| Completeness | ≥ 99% required fields | |
| Validity | 100% schema-compliant | |
| Consistency | No conflicting barrier/observation definitions | |