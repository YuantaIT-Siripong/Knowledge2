---
title: FCN Parameter Alias Register
doc_type: alias-register
status: Draft
version: 1.0.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-16
last_reviewed: 2025-10-16
next_review: 2026-04-16
classification: Internal
tags: [fcn, alias, deprecation, governance, structured-notes]
related:
  - business-rules.md
  - schemas/fcn-v1.1.0-parameters.schema.json
  - ../../sa/design-decisions/adr-004-parameter-alias-policy.md
---

# FCN Parameter Alias Register

## 1. Purpose
This document maintains the authoritative registry of deprecated, legacy, and aliased parameters for the Fixed Coupon Note (FCN) product family. It ensures backward compatibility transparency and provides migration guidance for system integrators and data consumers.

## 2. Scope
Covers all FCN specification versions (v1.0+) and tracks parameter lifecycle stages as defined in ADR-004 (Parameter Alias & Deprecation Policy):
- **Stage 1 (Introduce)**: Both fields permitted; canonical field identified
- **Stage 2 (Stable Dual)**: Dual support maintained; warnings on legacy usage
- **Stage 3 (Deprecation Notice)**: Legacy marked for removal in next major version
- **Stage 4 (Removal)**: Legacy field eliminated from schema

## 3. Alias Mapping Table

| Legacy Field | Canonical Field | Stage | First Appeared | Removal Target | Notes |
|--------------|-----------------|-------|----------------|----------------|-------|
| `barrier_monitoring` | `barrier_monitoring_type` | Stage 3 (Deprecated) | v1.0.0 | v2.0.0 | Deprecated in v1.1; use `barrier_monitoring_type` for clarity and consistency with monitoring nomenclature (ADR-004) |
| `redemption_barrier_pct` | `put_strike_pct` | Reserved (Legacy v1.0) | v1.0.0 | N/A | Reserved for backward compatibility; no payoff effect in v1.1 capital-at-risk mode; superseded by `put_strike_pct` for capital-at-risk settlement (BR-011 legacy mode) |

## 4. Governance Process

### 4.1 Deprecation Workflow
1. Business Analyst proposes alias deprecation with rationale (semantic clarity, naming conventions, functional supersession)
2. Solution Architect assesses backward compatibility impact
3. Approval by Product Owner required for Stage 3 transition
4. Schema updated with deprecation notice; test vectors stop using legacy field
5. Migration guide published in relevant specification version

### 4.2 Monitoring & Enforcement
- Parameter validators emit warnings when deprecated fields detected (Stage 3+)
- CI/CD pipeline fails if legacy fields appear in new test vectors (Stage 3+)
- Usage metrics tracked via parameter validation logs (BR-018 compliance)

### 4.3 Documentation Updates
When alias status changes:
- Update this register
- Update parameter schema description
- Update relevant specification version documentation
- Notify stakeholders via change log entry

## 5. Migration Guidance

### 5.1 barrier_monitoring → barrier_monitoring_type
**Status**: DEPRECATED (Stage 3) as of v1.1.0  
**Action Required**: Update all new trade bookings and scripts to use `barrier_monitoring_type`  
**Backward Compatibility**: `barrier_monitoring` still accepted in v1.1.x for existing integrations  
**Removal Timeline**: Planned for v2.0.0 (target: 2026+)

**Migration Example**:
```json
// OLD (deprecated)
{
  "barrier_monitoring": "discrete"
}

// NEW (canonical)
{
  "barrier_monitoring_type": "discrete"
}
```

### 5.2 redemption_barrier_pct (Legacy v1.0)
**Status**: Reserved / Legacy (no payoff effect in v1.1+)  
**Action Required**: For v1.1+ trades, use `put_strike_pct` for capital-at-risk settlement threshold  
**Backward Compatibility**: Field retained in schema for v1.0 trade data compatibility; no validation error if present  
**Payoff Impact**: None in v1.1+ capital-at-risk mode; BR-011 unconditional par recovery deprecated

**Migration Example**:
```json
// v1.0 (legacy par recovery mode)
{
  "knock_in_barrier_pct": 0.70,
  "redemption_barrier_pct": 0.80,
  "recovery_mode": "par-recovery"
}

// v1.1+ (capital-at-risk settlement)
{
  "knock_in_barrier_pct": 0.70,
  "put_strike_pct": 0.80,
  "recovery_mode": "capital-at-risk",
  "barrier_monitoring_type": "discrete"
}
```

## 6. Related Business Rules
- **BR-011**: DEPRECATED (v1.0 Legacy) — Par recovery pays 100% notional regardless of KI (superseded by BR-025 capital-at-risk logic)
- **BR-024**: Validation constraint: `0 < put_strike_pct ≤ 1.0` and `knock_in_barrier_pct < put_strike_pct`
- **BR-025**: Capital-at-risk settlement logic at maturity
- **BR-026**: Barrier monitoring type validation: `barrier_monitoring_type` in ['discrete', 'continuous']

## 7. Open Questions
| ID | Question | Owner | Target Resolution |
|----|----------|-------|-------------------|
| OQ-ALIAS-001 | Should v2.0.0 removal of `barrier_monitoring` be accompanied by automated migration scripts? | SA | Q1 2026 |
| OQ-ALIAS-002 | Should `redemption_barrier_pct` be removed from schema in v2.0.0 or retained indefinitely as reserved? | BA | Q1 2026 |

## 8. Change Log
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-16 | copilot | Initial alias register: documented `barrier_monitoring` deprecation (Stage 3), `redemption_barrier_pct` legacy reservation; established governance workflow per ADR-004 |
