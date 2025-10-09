---
---
title: FCN v1.0 Test Vector N3 – Base Memory – Early Knock-In Event
doc_type: test-vector
status: Draft
version: 1.0.0
normative: true
branch_id: base_mem
spec_version: 1.0.0
owner: siripong.s@yuanta.co.th
created: 2025-10-09
classification: Internal
tags: [structured-notes, fcn, test-vector, v1.0, memory, knock-in]
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
Knock-in event occurs at period 2 (level breaches barrier <= 70%). Coupons still evaluated normally afterward. Under par-recovery baseline, final redemption is still at notional (no loss), demonstrating that KI does not alter principal in v1.0 normative branch.

## Underlying Path
| obs # | obs date | level | level/initial | Coupon Cond (>=80%) | Barrier Breach (<=70%) |
|-------|----------|-------|---------------|---------------------|------------------------|
| 1 | 2025-12-30 | 98.0 | 0.980 | Yes | No |
| 2 | 2026-03-30 | 69.5 | 0.695 | No  | Yes (KI triggers) |
| 3 | 2026-06-30 | 85.0 | 0.850 | Yes | (already KI) |
| 4 | 2026-09-30 | 82.0 | 0.820 | Yes | - |
| 5 | 2026-12-23 | 87.4 | 0.874 | Yes | - |

Maturity level 88.0 (still above redemption barrier 80%).

## Memory & KI Trace
| obs # | eligible_coupon | ki_triggered (after) | accrued_unpaid (start) | action | accrued_unpaid (end) | coupon_paid |
|-------|-----------------|----------------------|------------------------|--------|----------------------|-------------|
| 1 | true  | false | 0 | Pay 1x | 0 | 50,000 |
| 2 | false | true  | 0 | Accrue | 1 | 0 |
| 3 | true  | true  | 1 | Pay (1+1)x | 0 | 100,000 |
| 4 | true  | true  | 0 | Pay 1x | 0 | 50,000 |
| 5 | true  | true  | 0 | Pay 1x | 0 | 50,000 |

## Cash Flows
| date | type | amount | description |
|------|------|--------|-------------|
| 2025-12-30 | coupon | 50,000 | Period 1 |
| 2026-06-30 | coupon | 100,000 | Periods 2+3 (memory) |
| 2026-09-30 | coupon | 50,000 | Period 4 |
| 2026-12-30 | coupon | 50,000 | Period 5 |
| 2026-12-30 | principal | 1,000,000 | Redemption (par-recovery despite KI) |

Total coupons: 250,000.

## Outcome Summary
- ki_triggered: true (from period 2)
- Principal unaffected due to par-recovery normative rule
- Memory logic unaffected by KI status

## Validation Points
- KI detection at correct observation
- Redemption remains par
- Memory payout after KI remains permissible
