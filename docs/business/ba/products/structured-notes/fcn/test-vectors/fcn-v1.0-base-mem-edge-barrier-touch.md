---
---
title: FCN v1.0 Test Vector N5 – Base Memory – Edge Barrier Touch (Equals Threshold)
doc_type: test-vector
status: Draft
version: 1.0.0
normative: true
branch_id: base_mem
spec_version: 1.0.0
owner: siripong.s@yuanta.co.th
created: 2025-10-09
classification: Internal
tags: [structured-notes, fcn, test-vector, v1.0, memory, edge-case]
related:
  - ../specs/fcn-v1.0.md
taxonomy:
  barrier_type: down-in
  settlement: physical-settlement
  coupon_memory: memory
  step_feature: no-step
  recovery_mode: par-recovery
---

# Scenario Description
Edge case: Underlying hits the knock-in barrier EXACTLY (level = 70% of initial) at observation 3. Specification defines barrier breach condition as level <= initial * barrier_pct, so equality triggers knock-in. Demonstrates proper KI recognition on equality boundary.

## Underlying Path
| obs # | obs date | level | level/initial | Coupon Cond (>=80%) | Barrier Breach (<=70%) | Notes |
|-------|----------|-------|---------------|---------------------|------------------------|-------|
| 1 | 2025-12-30 | 95.0 | 0.950 | Yes | No | Above threshold |
| 2 | 2026-03-30 | 88.0 | 0.880 | Yes | No | - |
| 3 | 2026-06-30 | 70.0 | 0.700 | No  | Yes (touch) | Equality triggers KI |
| 4 | 2026-09-30 | 83.0 | 0.830 | Yes | Already KI | Recovery coupon |
| 5 | 2026-12-23 | 86.0 | 0.860 | Yes | Already KI | - |

Maturity level 84.0 (>= redemption_barrier_pct 0.80).

## Memory & KI Trace
| obs # | eligible_coupon | ki_triggered(after) | accrued_unpaid(start) | action | accrued_unpaid(end) | coupon_paid |
|-------|-----------------|---------------------|-----------------------|--------|---------------------|-------------|
| 1 | true  | false | 0 | Pay 1x | 0 | 50,000 |
| 2 | true  | false | 0 | Pay 1x | 0 | 50,000 |
| 3 | false | true  | 0 | Accrue | 1 | 0 |
| 4 | true  | true  | 1 | Pay (1+1)x | 0 | 100,000 |
| 5 | true  | true  | 0 | Pay 1x | 0 | 50,000 |

## Cash Flows
| date | type | amount | description |
|------|------|--------|-------------|
| 2025-12-30 | coupon | 50,000 | Period 1 |
| 2026-03-30 | coupon | 50,000 | Period 2 |
| 2026-09-30 | coupon | 100,000 | Periods 3+4 (memory catch-up after KI) |
| 2026-12-30 | coupon | 50,000 | Period 5 |
| 2026-12-30 | principal | 1,000,000 | Redemption (par-recovery) |

Total coupons: 250,000.

## Outcome Summary
- ki_triggered: true at equality boundary
- Memory payout unaffected
- Redemption at par (baseline recovery)

## Validation Points
- Equality inclusion in breach condition
- Correct accumulation & release pattern post KI
- Distinguishes from scenario where level > barrier by smallest increment
