---
title: FCN Glossary
version: 0.1.0-draft
status: draft
owner: BA
updated: 2025-10-10
tags: [fcn, glossary]
---

# Glossary

| Term | Definition | Notes | Source |
|------|------------|-------|--------|
| FCN (Fixed Coupon Note) | Structured note paying fixed (sometimes conditional) coupons subject to barrier conditions | v1 supports memory & non-memory | TBD |
| Memory Coupon | Coupon feature allowing missed coupons to accrue if conditions met later | Enabled via flag | TBD |
| Knock-In (KI) Barrier | Price level whose breach activates downside payoff | Observed continuously or discretely | TBD |
| Observation Date | Date on which coupon condition is tested | Array ordered ascending | Schema property |
| Coupon Payment Date | Date coupon is paid (may follow observation) | Must align cardinality with observation dates | Rule |
| Underlying Symbol | Ticker/identifier of underlying asset | Single or basket | TBD |
| Initial Level | Reference level at issuance | Sourced from market data | TBD |
| Settlement Currency | Currency of cash flows | Single currency in v1 | TBD |
| Notional | Principal amount used for coupon calculations | Decimal precision TBD | TBD |
| Memory Carry Cap Count | Maximum number of missed coupons that can accrue | Null when memory disabled | Rule |

## Open Glossary Gaps
| ID | Term | Owner | Needed By | Status |
|----|------|------|-----------|--------|
| G-01 | Define exact KI observation mode options | Risk | 2025-10-15 | Open |