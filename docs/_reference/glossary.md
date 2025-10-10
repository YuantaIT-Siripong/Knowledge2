---
title: FCN Glossary
version: 1.0.1
status: Draft
owner: siripong.s@yuanta.co.th
tags: [fcn, glossary, v1.0]
related:
  - ../specs/fcn-v1.0.md
  - ../business-rules.md
  - ../../../../sa/design-decisions/dec-011-notional-precision.md
---

# Glossary (delta excerpt)

| Term | Definition | Notes | Source |
|------|------------|-------|--------|
| Notional Amount | Principal amount on which coupon and redemption values are computed. Precision constrained by currency (BR-019 / DEC-011): 2 decimals for fractional currencies; 0 decimals for zero-decimal ISO currencies. | Rounding applied at external interfaces; internal calc may keep higher precision. | DEC-011, Spec §3 |
| Notional Precision (Decision) | Policy defining scale allowed per ISO 4217 currency classification. | Drives DB schema & validation script enforcement. | DEC-011 |
| Memory Carry Cap Count | Maximum accumulated unpaid coupons allowed when memory feature on. | Null when feature disabled. | Spec §3 |

# Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2025-10-10 | Initial glossary |
| 1.0.1 | 2025-10-10 | Added notional precision definitions (BR-019, DEC-011) |