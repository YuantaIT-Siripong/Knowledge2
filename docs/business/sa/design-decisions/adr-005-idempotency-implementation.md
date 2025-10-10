---
title: Idempotency Implementation Strategy
doc_type: decision-record
adr: 005
status: Proposed
version: 0.1.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-10
last_reviewed: 2025-10-10
next_review: 2026-04-10
classification: Internal
tags: [architecture, decision, idempotency, fcn]
related:
  - ../../../../_policies/document-control-policy.md
  - ../handoff/domain-handoff-fcn-v1.0.md
  - ../../ba/products/structured-notes/fcn/business-rules.md
---

# Idempotency Implementation Strategy

## Status
**Proposed** - Pending architectural decision (OQ-BR-002)

## Context
The FCN v1.0 specification includes **BR-007** (Observation Processing Idempotency):
> "An observation must be processed exactly once per observation_date × contract_id tuple to prevent duplicate coupon logic or cash flow generation."

We need to decide on the implementation strategy to enforce this idempotency guarantee. The choice affects:
- Data model design (constraints)
- Application logic complexity
- Error handling approach
- Performance characteristics
- Distributed system behavior

## Decision
**[DECISION PENDING - Analysis in progress]**

Two primary options are being analyzed:
1. **Database-enforced idempotency** (unique constraint)
2. **Application-enforced idempotency** (distributed locking)

## Options Analysis

### Option A: Database Unique Constraint

**Approach:**
Create a unique constraint on `fcn_observations` table:
```sql
CREATE TABLE fcn_observations (
    id UUID PRIMARY KEY,
    contract_id UUID NOT NULL,
    observation_date DATE NOT NULL,
    underlying_id UUID NOT NULL,
    observed_level NUMERIC(18, 4) NOT NULL,
    ...
    CONSTRAINT uq_observation_per_contract_date 
        UNIQUE (contract_id, observation_date, underlying_id)
);
```

**Pros:**
- ✅ **Simple implementation** - No application-level locking logic required
- ✅ **Database-guaranteed** - Constraint enforced at DBMS level, atomic
- ✅ **No race conditions** - Database handles concurrent inserts correctly
- ✅ **Minimal code** - Application only needs to handle unique constraint violation error
- ✅ **Reliable** - Works correctly in distributed application instances

**Cons:**
- ⚠️ **Database-specific** - Relies on DB unique constraint feature (portable but error codes vary)
- ⚠️ **Error handling** - Application must catch and interpret constraint violation exceptions
- ⚠️ **Limited context** - Error message may be generic DB constraint violation
- ⚠️ **Partial data** - In basket products, one underlying may succeed while another fails (requires transaction management)

**Error Handling Example:**
```python
try:
    db.insert_observation(observation)
except UniqueViolationError as e:
    if is_idempotent_duplicate(e):
        logger.info("Observation already processed - idempotent duplicate")
        return existing_observation
    else:
        raise
```

---

### Option B: Application-Level Locking

**Approach:**
Implement distributed lock before observation processing:
```python
lock_key = f"observation:{contract_id}:{observation_date}:{underlying_id}"
with distributed_lock(lock_key, timeout=30):
    existing = db.find_observation(contract_id, observation_date, underlying_id)
    if existing:
        return existing  # Idempotent duplicate
    observation = process_observation(...)
    db.insert_observation(observation)
```

**Pros:**
- ✅ **Portable** - Not tied to specific database features
- ✅ **Flexible error handling** - Can return user-friendly error messages
- ✅ **Better logging** - Explicit handling allows detailed audit trail
- ✅ **Atomicity control** - Can handle basket products as single unit
- ✅ **Business logic visible** - Idempotency logic explicit in application code

**Cons:**
- ⚠️ **Complex implementation** - Requires distributed locking infrastructure (Redis, Zookeeper, etc.)
- ⚠️ **Additional infrastructure** - Redis or equivalent needed
- ⚠️ **Lock management** - Must handle lock expiration, renewal, deadlocks
- ⚠️ **Performance overhead** - Network round-trip for lock acquisition/release
- ⚠️ **Failure modes** - Lock service unavailability affects all processing
- ⚠️ **Race condition risk** - If lock expires during processing, duplicates possible

**Infrastructure Required:**
- Distributed lock service (Redis with Redlock algorithm)
- Lock expiration and renewal logic
- Monitoring and alerting for lock contention

---

## Comparison Matrix

| Criterion | Option A (DB Constraint) | Option B (App Locking) |
|-----------|--------------------------|------------------------|
| **Simplicity** | ⭐⭐⭐⭐⭐ Very Simple | ⭐⭐ Complex |
| **Reliability** | ⭐⭐⭐⭐⭐ Database-guaranteed | ⭐⭐⭐ Depends on lock service |
| **Performance** | ⭐⭐⭐⭐ Fast (single DB op) | ⭐⭐⭐ Slower (lock + DB ops) |
| **Error Handling** | ⭐⭐⭐ Generic DB errors | ⭐⭐⭐⭐ Custom messages |
| **Portability** | ⭐⭐⭐⭐ Standard SQL | ⭐⭐⭐⭐⭐ No DB dependency |
| **Infrastructure** | ⭐⭐⭐⭐⭐ Just database | ⭐⭐ Needs lock service |
| **Maintenance** | ⭐⭐⭐⭐⭐ Minimal | ⭐⭐ Requires monitoring |
| **Distributed System** | ⭐⭐⭐⭐⭐ Works perfectly | ⭐⭐⭐ Lock service SPOF |

---

## Rationale
**[ANALYSIS IN PROGRESS - Decision pending]**

### Key Considerations:
1. **Business criticality** - BR-007 is critical; duplicate processing could result in incorrect cash flows
2. **System scale** - Initial volume expected to be moderate; extreme concurrency unlikely
3. **Infrastructure complexity** - Prefer simpler solutions when sufficient
4. **Development velocity** - Faster to implement and test simple approach
5. **Operational maturity** - Team experience with distributed systems

### Preliminary Recommendation:
**Option A (Database Unique Constraint)** is recommended for v1.0 based on:
- Sufficient guarantee for business requirement (BR-007)
- Significantly simpler implementation and maintenance
- Lower infrastructure cost and complexity
- Proven reliability of database constraints
- Faster development and testing cycle

**Option B** could be considered for future versions if:
- Extreme concurrency requires lock-based coordination
- More sophisticated error handling is required
- Distributed lock infrastructure is already available

---

## Alternatives Considered

### Option C: Hybrid Approach
Application checks for existing observation first, then inserts with unique constraint as safety net.

**Rejected because:**
- Adds complexity without significant benefit
- Two database round-trips per operation
- Still requires handling constraint violation
- False sense of security (race condition still possible between check and insert)

### Option D: UUID-based Idempotency Keys
Client generates deterministic UUID based on (contract_id, observation_date, underlying_id).

**Rejected because:**
- Requires client to implement key generation logic
- Key generation must be perfectly consistent
- Doesn't prevent duplicate processing, only duplicate IDs
- Still needs uniqueness enforcement (back to Option A or B)

---

## Consequences

### Positive (Option A - if chosen)
- Simple codebase, easy to understand and maintain
- High reliability (database guarantees)
- Fast performance (single DB operation)
- No additional infrastructure costs
- Easy to test

### Negative (Option A - if chosen)
- Generic error messages (requires error code interpretation)
- Database-specific error handling (though portable)
- Transaction management needed for basket products

### Positive (Option B - if chosen)
- Explicit business logic
- Custom error messages
- Flexible control flow

### Negative (Option B - if chosen)
- Additional infrastructure (Redis)
- Complex implementation
- More failure modes
- Operational overhead

---

## Implementation Notes

### For Option A (if chosen):
```sql
-- Migration: Add unique constraint to observations table
ALTER TABLE fcn_observations
ADD CONSTRAINT uq_observation_per_contract_date
UNIQUE (contract_id, observation_date, underlying_id);

-- Index for query performance
CREATE INDEX idx_observations_contract_date 
ON fcn_observations (contract_id, observation_date);
```

### For Option B (if chosen):
- Implement Redis-based distributed locking
- Define lock timeout (recommended: 30 seconds)
- Implement lock renewal for long-running operations
- Add monitoring for lock contention
- Document failure recovery procedures

---

## Testing Strategy

### Test Cases (regardless of option):
1. **Idempotent duplicate** - Same observation submitted twice → second returns existing
2. **Concurrent submissions** - Two processes submit same observation simultaneously → one succeeds, one detects duplicate
3. **Different underlyings** - Multiple underlyings for same contract/date → all succeed
4. **Error recovery** - Failed observation can be retried without duplicate
5. **Performance** - Measure latency and throughput under load

---

## Follow-up Tasks
- [ ] Complete analysis and make architectural decision
- [ ] Update database schema design with chosen approach
- [ ] Update API specification with idempotency behavior documentation
- [ ] Create implementation guide for developers
- [ ] Define test cases for idempotency validation
- [ ] Update business rule BR-007 traceability

---

## Decision Log

| Date | Author | Action |
|------|--------|--------|
| 2025-10-10 | copilot | Created ADR with options analysis (status: Proposed) |
| TBD | SA | Complete analysis and make decision |
| TBD | SA | Update status to Active after approval |

---

## References
- [Business Rules](../../ba/products/structured-notes/fcn/business-rules.md) - BR-007
- [Domain Handoff Package](../handoff/domain-handoff-fcn-v1.0.md) - Open Question OQ-BR-002
- [SA Work Tracker](../sa-work-tracker-fcn-v1.0.md) - Phase 2 decision tracking

---

## Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1.0 | 2025-10-10 | copilot | Initial ADR created with options analysis |
