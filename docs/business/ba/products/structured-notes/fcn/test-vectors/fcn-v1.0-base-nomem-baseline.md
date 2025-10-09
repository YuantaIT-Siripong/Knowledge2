---
---
title: FCN v1.0 Test Vector N4 – Base Non-Memory – Baseline With Miss
doc_type: test-vector
status: Draft
version: 1.0.0
normative: true
branch_id: base_nomem
spec_version: 1.0.0
owner: siripong.s@yuanta.co.th
created: 2025-10-09
classification: Internal
tags: [structured-notes, fcn, test-vector, v1.0, non-memory]
related:
  - ../specs/fcn-v1.0.md
taxonomy:
  barrier_type: down-in
  settlement: physical-settlement
  coupon_memory: no-memory
  step_feature: no-step
  recovery_mode: par-recovery
---

# Scenario Description
Non-memory variant: one coupon opportunity is missed and not recovered. Demonstrates divergence from memory branch aggregate coupon total.

## Parameters (differences)
Same as memory baseline except is_memory_coupon = false.

## Underlying Path
| obs # | obs date | level | level/initial | Coupon Eligible | Barrier Breach |
|-------|----------|-------|---------------|-----------------|----------------|
| 1 | 2025-12-30 | 100.5 | 1.005 | Yes | No |
| 2 | 2026-03-30 | 77.0  | 0.770 | No  | No |
| 3 | 2026-06-30 | 90.0  | 0.900 | Yes | No |
| 4 | 2026-09-30 | 92.5  | 0.925 | Yes | No |
| 5 | 2026-12-23 | 101.3 | 1.013 | Yes | No |

Maturity level 101.7.

## Cash Flows
| date | type | amount | description |
|------|------|--------|-------------|
| 2025-12-30 | coupon | 50,000 | Period 1 |
| 2026-03-30 | coupon | 0      | Period 2 missed (no memory) |
| 2026-06-30 | coupon | 50,000 | Period 3 |
| 2026-09-30 | coupon | 50,000 | Period 4 |
| 2026-12-30 | coupon | 50,000 | Period 5 |
| 2026-12-30 | principal | 1,000,000 | Redemption |

Total coupons: 200,000 (lower than memory scenario with identical path aside from miss).

## Outcome Summary
- ki_triggered: false
- Missed coupon permanently forfeited

## Validation Points
- No memory accumulation logic present
- Aggregate coupon delta vs memory variant (N2-like path) = one period value
