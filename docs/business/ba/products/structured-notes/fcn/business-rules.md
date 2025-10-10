---
title: FCN Business Rules
version: 0.1.0-draft
status: draft
owner: BA
updated: 2025-10-10
tags: [fcn, rules]
---

# Business Rules

## 1. Rule Table
| Rule ID | Description | Applies To (Entity/Process) | Type (Validation/Calc/Compliance) | Priority (Must/Should) | Source / Owner | Schema Field (JSON Pointer) | Notes |
|---------|-------------|-----------------------------|-----------------------------------|------------------------|----------------|-----------------------------|-------|
| BR-01 | observation_dates must be strictly ascending | Observation scheduling | Validation | Must | Structuring | /observation_dates | |
| BR-02 | coupon_payment_dates cardinality must match observation_dates | Coupon payout | Validation | Must | Ops | /coupon_payment_dates | |
| BR-03 | memory_carry_cap_count required only if is_memory_coupon = true | Memory feature | Validation | Must | Product | /memory_carry_cap_count | Conditional |
| BR-04 | Knock-in barrier level > 0 | Barrier | Validation | Must | Risk | /barrier/level | |
| BR-05 | Notional > 0 | FCNContract | Validation | Must | Product | /notional | |

## 2. Conditional / Cross-Field Rules
| Rule ID | Condition Logic | Pseudocode |
|---------|-----------------|-----------|
| BR-03 | is_memory_coupon=true ⇒ memory_carry_cap_count != null | if is_memory_coupon and memory_carry_cap_count is null -> error |

## 3. Rule Coverage Status
| Coverage Area | Total Rules | Drafted | Approved | Notes |
|---------------|------------|---------|----------|-------|
| Parameter Validation | TBD | TBD | TBD | |

## 4. Open Rule Questions
| ID | Question | Owner | Needed By | Status |
|----|----------|-------|-----------|--------|
| BRQ-01 | Are negative coupons ever permitted? | Product | 2025-10-18 | Open |