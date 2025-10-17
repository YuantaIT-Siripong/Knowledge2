---
title: Supersession & Lifecycle Enforcement
doc_type: decision-record
adr: 005
status: Accepted
version: 0.1.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-17
last_reviewed: 2025-10-17
decision_date: 2025-10-17
next_review: 2026-04-17
classification: Internal
tags: [architecture, decision, governance, versioning, lifecycle, supersession]
related:
  - adr-002-product-doc-structure.md
  - adr-003-fcn-version-activation.md
  - ../../ba/products/structured-notes/fcn/specs/SUPERSEDED_INDEX.md
  - ../../ba/products/structured-notes/fcn/specs/fcn-v1.1.0.md
  - ../../ba/products/structured-notes/fcn/business-rules.md
---

# Supersession & Lifecycle Enforcement

## Context

As product specifications evolve through versions (e.g., FCN v1.0 → v1.1.0), we need a formal process to:
- Mark older versions as Superseded while preserving them for audit and historical reference
- Prevent new trades or templates from inadvertently referencing superseded versions
- Maintain traceability between specification versions
- Enforce governance approval for any exceptions to supersession policy

Without formal supersession tracking, teams may:
- Continue booking trades against outdated specifications
- Lose visibility into which specification version governs existing trades
- Face audit challenges when reconciling historical trade behavior against current specifications

## Decision

Adopt a formal **Supersession & Lifecycle Enforcement** framework with the following components:

### 1. Supersession Index
Maintain a centralized **SUPERSEDED_INDEX.md** file in the product specs directory tracking:
- Superseded specification versions
- Supersession dates
- Superseding (replacement) versions
- Links to historical spec files

### 2. Specification Metadata
All product specifications MUST include front-matter metadata:
- `status`: Active | Superseded | Proposed | Deprecated
- `supersedes`: Reference to previous version file (if applicable)
- `superseded_by`: Reference to replacement version file (when status=Superseded)
- `spec_version`: Machine-readable version identifier

### 3. Governance Roles & Triggers

**Supersession Event Triggers**:
- Major version release introducing breaking changes or significant new features
- Specification version promotion from Proposed → Active (previous Active version becomes Superseded)
- Regulatory or compliance requirement necessitating specification retirement

**Roles & Responsibilities**:

| Role | Responsibility |
|------|----------------|
| Product Owner | Approve supersession event; sign off on replacement version |
| Business Analyst | Update SUPERSEDED_INDEX.md; update spec metadata; document supersession rationale |
| Solution Architect | Review backward compatibility impact; update ADRs referencing superseded specs |
| Risk Management | Assess impact on existing trades; approve exception requests for legacy version usage |
| Compliance | Validate regulatory alignment; approve supersession timeline |
| Engineering | Implement validation rules; update CI/CD pipelines |

### 4. Data Validation Rules

**Booking-Time Validation (BR-004 Extension)**:
- **Rule**: `documentation_version` MUST NOT reference a version listed in SUPERSEDED_INDEX.md unless explicit governance approval flag is present
- **Implementation**: Validation engine checks documentation_version against SUPERSEDED_INDEX.md on trade booking
- **Exception Handling**: Governance approval flag (e.g., `governance_override_ticket_id`) required for superseded version bookings

**Specification Metadata Validation**:
- **Rule**: Specifications with status=Superseded MUST have `superseded_by` field populated
- **Rule**: Specifications with status=Active MUST NOT have `superseded_by` field
- **Rule**: `supersedes` chain MUST be valid (referenced versions exist and form valid dependency graph)
- **Implementation**: Pre-commit hook validates spec metadata consistency

**Template & Migration Validation**:
- **Rule**: New trade templates MUST reference Active specification versions only
- **Rule**: Migration scripts MUST document source and target specification versions
- **Implementation**: CI/CD pipeline rejects PRs creating templates or migrations against superseded versions

### 5. Exception Process

Requests to use superseded specifications require:

1. **Written Justification**: Business rationale for using superseded version (e.g., client-specific contract requirements, regulatory carve-out)
2. **Risk Assessment**: Impact analysis from Risk Management on using outdated specification
3. **Approval**: Sign-off from Product Owner, Risk Management, and Compliance
4. **Audit Trail**: Approval ticket ID recorded in trade metadata (`governance_override_ticket_id`)
5. **Expiration**: Exception approval valid for limited period (default: 6 months; renewable with re-approval)

## Rationale

### Benefits
- **Audit Clarity**: Clear record of which specification version governs each trade
- **Operational Safety**: Prevents accidental use of outdated specifications
- **Compliance**: Demonstrates governance controls for regulatory reviews
- **Maintainability**: Reduces confusion about "current" vs "legacy" specifications

### Trade-offs
- **Process Overhead**: Supersession events require coordination across multiple teams
- **Exception Management**: Exception process adds complexity for edge cases
- **Tooling Dependency**: Automated validation requires CI/CD pipeline maintenance

## Alternatives Considered

1. **Git Tag-Based Versioning Only**
   - Rejected: Tags provide version history but lack governance metadata and validation hooks
   - Gap: No enforcement mechanism to prevent superseded version usage

2. **Delete Superseded Specifications**
   - Rejected: Loss of historical audit trail
   - Gap: Cannot reconcile existing trade behavior against original specification

3. **Manual Governance Only (No Automation)**
   - Rejected: High risk of human error; difficult to enforce consistently
   - Gap: No real-time validation at booking time

## Consequences

### Positive
- High confidence that new trades use current, approved specifications
- Clear audit path for specification evolution
- Reduced risk of compliance violations from outdated specification usage
- Improved traceability for historical trades

### Negative
- Additional authoring effort for specification metadata maintenance
- Requires CI/CD pipeline updates for validation enforcement
- Exception process may add latency for edge cases
- Team training required on supersession workflow

## Implementation Guidance

### SUPERSEDED_INDEX.md Structure
```markdown
## Superseded Specifications

| Version | Status | Superseded By | Supersession Date | Spec File |
|---------|--------|---------------|-------------------|-----------|
| 1.0 | Superseded | fcn-v1.1.0.md | 2025-10-17 | fcn-v1.0.md |
```

### Machine-Readable Format
Provide JSON representation for automated tooling:
```json
{
  "superseded_specs": [
    {
      "version": "1.0",
      "status": "Superseded",
      "superseded_by": "fcn-v1.1.0.md",
      "supersession_date": "2025-10-17",
      "spec_file": "fcn-v1.0.md",
      "lifecycle": "historical"
    }
  ]
}
```

### Business Rules Reference

- **BR-004 (Extended)**: `documentation_version` must equal active product version unless explicit governance approval
- **BR-022**: Issuer whitelist validation (v1.1.0+ requirement)
- **BR-020–BR-026**: Business rules introduced in v1.1.0 requiring specification supersession

See [business-rules.md](../../ba/products/structured-notes/fcn/business-rules.md) for complete rule definitions.

## Metrics & Monitoring

Track the following supersession lifecycle metrics:

| Metric | Target | Measurement |
|--------|--------|-------------|
| Time to supersession (version release → SUPERSEDED_INDEX update) | < 1 business day | Automated timestamp tracking |
| Exception request approval time | < 5 business days | Ticket system SLA |
| Superseded version usage rate | < 2% of new trades | Booking system analytics |
| Specification metadata completeness | 100% | Pre-commit validation pass rate |

## Follow-up Tasks
- [x] Create SUPERSEDED_INDEX.md for FCN
- [x] Document supersession event (v1.0 → Superseded)
- [ ] Implement BR-004 extension for documentation_version validation
- [ ] Add pre-commit hook for specification metadata validation
- [ ] Create exception request template and approval workflow
- [ ] Configure CI/CD pipeline rules for superseded version gating
- [ ] Update team onboarding documentation with supersession workflow
- [ ] Establish quarterly supersession index review process

## References

- [SUPERSEDED_INDEX.md](../../ba/products/structured-notes/fcn/specs/SUPERSEDED_INDEX.md): FCN specification supersession tracking
- [ADR-003](adr-003-fcn-version-activation.md): FCN Version Activation & Promotion Workflow
- [ADR-002](adr-002-product-doc-structure.md): Product Documentation Structure & Location
- [FCN v1.1.0 Specification](../../ba/products/structured-notes/fcn/specs/fcn-v1.1.0.md): Current active specification
- [FCN Business Rules](../../ba/products/structured-notes/fcn/business-rules.md): BR-004, BR-022

## Change Log
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1.0 | 2025-10-17 | siripong.s@yuanta.co.th | Initial version: defined supersession framework, governance roles, validation rules, exception process; documented SUPERSEDED_INDEX.md structure and business rule references |
