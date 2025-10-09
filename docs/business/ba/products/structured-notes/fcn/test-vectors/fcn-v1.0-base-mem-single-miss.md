---
---
title: FCN v1.0 Test Vector N2 – Base Memory – Single Miss Recovered
doc_type: test-vector
status: Draft
version: 1.0.0
normative: true
branch_id: base_mem
spec_version: 1.0.0
owner: siripong.s@yuanta.co.th
created: 2025-10-09
classification: Internal
tags: [structured-notes, fcn, test-vector, v1.0, memory, recovery]
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
Exactly one observation (period 2) falls below coupon threshold (80%) but remains above knock-in barrier (70%). Missed coupon is stored and paid together at period 3 when conditions are again satisfied.

## Parameters (differences from N1 highlighted)
Same as N1 except underlying path.

## Underlying Path
| obs # | observation_date | level | level / initial | Coupon Condition (>=80%) | Barrier Breach (<=70%) |
|-------|------------------|-------|------------------|--------------------------|------------------------|
| 1 | 2025-12-30 | 101.0 | 1.010 | Yes | No |
| 2 | 2026-03-30 | 75.5  | 0.755 | No  | No |
| 3 | 2026-06-30 | 95.0  | 0.950 | Yes | No |
| 4 | 2026-09-30 | 96.2  | 0.962 | Yes | No |
| 5 | 2026-12-23 | 100.8 | 1.008 | Yes | No |

Maturity level 101.2.

## Memory Accrual Trace
| obs # | eligible_coupon | accrued_unpaid (start) | action | accrued_unpaid (end) | coupon_paid |
|-------|-----------------|------------------------|--------|----------------------|-------------|
| 1 | true  | 0 | Pay 1x | 0 | 50,000 |
| 2 | false | 0 | Accrue | 1 | 0 |
| 3 | true  | 1 | Pay (1+1)x | 0 | 100,000 |
| 4 | true  | 0 | Pay 1x | 0 | 50,000 |
| 5 | true  | 0 | Pay 1x | 0 | 50,000 |

## Cash Flows
| date | type | amount | description |
|------|------|--------|-------------|
| 2025-12-30 | coupon | 50,000 | Period 1 |
| 2026-06-30 | coupon | 100,000 | Periods 2+3 (memory catch-up) |
| 2026-09-30 | coupon | 50,000 | Period 4 |
| 2026-12-30 | coupon | 50,000 | Period 5 (paid on maturity date) |
| 2026-12-30 | principal | 1,000,000 | Redemption |

Total coupons: 250,000 (same aggregate as N1).

## Outcome Summary
- ki_triggered: false
- One missed coupon correctly aggregated.

## Validation Points
- Barrier not breached despite coupon miss
- Memory payment multiple = accrued_unpaid + 1 when regained
