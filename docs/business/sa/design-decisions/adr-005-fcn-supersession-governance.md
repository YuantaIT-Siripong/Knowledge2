---
title: FCN Specification Supersession Governance
doc_type: decision-record
adr: 005
status: Accepted
version: 0.2.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-17
last_reviewed: 2025-10-17
next_review: 2026-04-17
classification: Internal
tags: [decision, governance, versioning, supersession, fcn]
related:
  - adr-003-fcn-version-activation.md
  - ../../ba/products/structured-notes/fcn/specs/SUPERSEDED_INDEX.md
  - ../../ba/products/structured-notes/fcn/schema-diff-v1.0-to-v1.1.md
---

# FCN Specification Supersession Governance

## Context

As FCN specifications evolve through versions (v1.0 → v1.1.0 → future), we need a formal process to mark older versions as Superseded while preserving them for historical audit and existing trade reference. Without clear supersession criteria and enforcement, teams may inadvertently create new trades using outdated specifications, leading to:
- Implementation drift (new code against old specs)
- Compliance gaps (missing mandatory parameters like issuer, put_strike_pct)
- Risk calculation errors (using deprecated settlement logic like BR-011 unconditional par recovery)
- Documentation fragmentation

This ADR establishes the governance framework for declaring a specification version as Superseded and enforcing its non-use in new business.

## Decision

**Adopt a formal supersession process with the following components:**

1. **Supersession Triggers**: Specification version is marked Superseded when:
   - A new normative version is activated (e.g., v1.1.0 Active → v1.0 Superseded)
   - Backward compatibility is maintained (additive-only changes)
   - Governance approval is obtained (BA + Risk + Technology sign-off)
   - Superseded index is updated ([SUPERSEDED_INDEX.md](../../ba/products/structured-notes/fcn/specs/SUPERSEDED_INDEX.md))
   - CI enforcement rules are activated to block new usage

2. **Supersession Registry**: Maintain machine-readable index of superseded specifications
   - Location: `docs/business/ba/products/structured-notes/fcn/specs/SUPERSEDED_INDEX.md`
   - Format: Markdown table + JSON metadata
   - Fields: version, status, superseded_by, supersession_date, spec_file, lifecycle
   - Consumer: CI/CD pipelines, validators, documentation generators

3. **Usage Restrictions**: Once Superseded:
   - **Prohibited**: New trade bookings, new templates, new migrations referencing superseded version
   - **Permitted**: Historical audit, existing trade queries, legacy data reconciliation
   - **Exception Path**: Explicit governance approval required (documented in supersession index notes)

4. **Enforcement Mechanisms**:
   - Phase 1 (Manual): Documentation banners marking superseded specs
   - Phase 2 (Semi-automated): CI checks warn on superseded spec references in PR diffs
   - Phase 3 (Automated): CI blocks merge if superseded spec referenced in new code paths (e.g., booking API, trade templates, test vectors)

## Rationale

**Why formal supersession governance?**
- **Correctness**: Ensures new trades incorporate latest business rules (e.g., BR-020–026 capital-at-risk settlement)
- **Compliance**: Enforces mandatory parameters (issuer, put_strike_pct) introduced in normative versions
- **Audit Trail**: Preserves superseded specifications for regulatory review and trade history reconstruction
- **Automation Readiness**: Machine-readable format enables CI/CD enforcement without manual oversight

**Why retain superseded specs?**
- Existing trades may reference superseded versions for life of product (up to 10 years)
- Audit and reconciliation require historical parameter definitions
- Facilitates incident investigation and dispute resolution

**Why strict enforcement?**
- Prevents accidental regression to deprecated settlement logic (e.g., unconditional par recovery)
- Reduces risk of parameter mismatch (e.g., missing issuer causing booking failure)
- Ensures consistent implementation across teams and systems

## Process Steps

### 1. Activation of New Normative Version

**Prerequisites** (per ADR-003):
- [ ] Activation checklist completed (parameter table, test vectors, issuer whitelist, settlement alignment, capital-at-risk constraints)
- [ ] Schema diff document published (e.g., schema-diff-v1.0-to-v1.1.md)
- [ ] Business rules updated with new BR-XXX entries
- [ ] Governance approval obtained (BA + Risk + Technology)

**Actions**:
- Update new spec status: `Proposed` → `Active`
- Tag spec file with normative version (e.g., `fcn-v1.1.0.md`)
- Update manifest.yaml active_version field

### 2. Supersession Declaration

**Trigger**: New normative version activated AND backward-compatible

**Actions**:
1. Update previous version status: `Active` → `Superseded`
2. Add entry to SUPERSEDED_INDEX.md:
   ```markdown
   | 1.0 | Superseded | fcn-v1.1.0.md | 2025-10-17 | fcn-v1.0.md |
   ```
3. Update JSON metadata block in SUPERSEDED_INDEX.md
4. Add supersession banner to superseded spec file header:
   ```markdown
   > **⚠️ SUPERSEDED**: This specification (v1.0) was superseded on 2025-10-17 by [fcn-v1.1.0.md](fcn-v1.1.0.md).
   > New trades must not reference this version without explicit governance approval.
   > See [SUPERSEDED_INDEX.md](SUPERSEDED_INDEX.md) for details.
   ```
5. Create git tag: `fcn-v1.0-superseded` (lightweight tag marking supersession date)

### 3. CI Rule Activation

**Objective**: Prevent new code from referencing superseded specifications

**Phase 1 (Immediate)**:
- Add linter rule: warn on file paths matching `fcn-v1.0.md` in modified lines (PR diffs only)
- Add documentation check: fail if new .md files link to superseded specs without disclaimer

**Phase 2 (3-month grace period)**:
- Upgrade warning to blocking error for:
  - New test vectors referencing superseded spec_version
  - New trade templates with superseded spec_version metadata
  - New API request examples using superseded parameter sets

**Phase 3 (Post-grace period)**:
- Block all references to superseded specs in:
  - Code comments (except historical context)
  - Configuration files (except legacy migrations)
  - Documentation (except schema diff and SUPERSEDED_INDEX.md)

### 4. Communication & Migration Support

**Stakeholder Notification**:
- [ ] Email to trading desk: "FCN v1.0 superseded; use v1.1.0 for new trades"
- [ ] Wiki update: FCN product page with supersession notice
- [ ] Architecture review: present supersession rationale and timeline

**Migration Guidance**:
- Publish schema diff document (e.g., [schema-diff-v1.0-to-v1.1.md](../../ba/products/structured-notes/fcn/schema-diff-v1.0-to-v1.1.md))
- Provide parameter mapping table (old → new)
- Document data migration strategy (backfill issuer, put_strike_pct for v1.0 trades if needed)
- Offer office hours for Q&A

## Lifecycle Flowchart (Textual)

```
┌─────────────┐
│  Concept    │ ← Initial idea, no spec yet
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Proposed   │ ← Spec draft created, activation checklist in progress
└──────┬──────┘
       │ (Activation checklist complete + governance approval)
       ▼
┌─────────────┐
│   Active    │ ← Normative version for new trades
└──────┬──────┘
       │ (New normative version activated + backward-compatible + supersession declared)
       ▼
┌─────────────┐
│ Superseded  │ ← Retained for historical audit; new usage prohibited
└──────┬──────┘
       │ (All referencing trades matured/closed + retention period expired)
       ▼
┌─────────────┐
│  Archived   │ ← Moved to archive directory; read-only access
└─────────────┘
```

**State Definitions**:
- **Concept**: Early design phase; no spec file yet
- **Proposed**: Spec file exists; activation checklist in progress; not approved for production
- **Active**: Normative specification for new trades; activation checklist complete
- **Superseded**: Replaced by newer Active version; prohibited for new trades; retained for historical reference
- **Archived**: All referencing trades closed; moved to archive directory (typical: 7-10 years post-supersession)

## Automation Hooks

### CI/CD Integration Points

1. **PR Validation Hook** (`pre-merge`):
   - Script: `scripts/validate-spec-references.sh` (TODO: create)
   - Input: PR diff, SUPERSEDED_INDEX.json
   - Output: Error if new code references superseded spec; Warning if comment/doc references without disclaimer
   - Enforcement: Blocking for Phase 2+

2. **Documentation Build Hook** (`post-commit`):
   - Script: `scripts/generate-spec-catalog.py` (TODO: create)
   - Input: SUPERSEDED_INDEX.json, spec file headers
   - Output: Auto-generated spec catalog HTML with status badges (Active, Superseded, Archived)
   - Enforcement: Informational only

3. **Trade Booking Validation Hook** (`runtime`):
   - Component: Booking API parameter validator
   - Input: Trade JSON payload `spec_version` field, SUPERSEDED_INDEX.json
   - Output: Reject booking if `spec_version` is Superseded (unless governance override flag present)
   - Enforcement: Blocking in production

### Data Quality Checks

1. **Weekly Audit Report**:
   - Query: Identify trades created in last 7 days with `spec_version` matching Superseded entries
   - Alert: Email to governance team if any found (indicates bypass or misconfiguration)

2. **Monthly Reconciliation**:
   - Query: Count trades by `spec_version` (Active vs Superseded)
   - Metric: Track % of Active trades (target: >95% within 6 months of supersession)

## Consequences

### Positive
- **Consistency**: All new trades use latest normative specification
- **Risk Reduction**: Prevents usage of deprecated settlement logic (e.g., BR-011 unconditional par recovery)
- **Compliance**: Enforces mandatory parameters (issuer, put_strike_pct) for governance and counterparty risk management
- **Auditability**: Clear lineage of specification changes and supersession rationale

### Negative
- **Complexity**: Adds governance process overhead for version transitions
- **Training**: Teams must learn new parameters and settlement logic (e.g., capital-at-risk vs par recovery)
- **Tooling Dependency**: Requires CI/CD automation to enforce without manual intervention

### Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Accidental use of superseded spec | High (wrong settlement, missing parameters) | Automated CI checks + trade booking validation |
| Incomplete migration guidance | Medium (confusion, support burden) | Comprehensive schema diff + office hours + examples |
| CI enforcement too strict (blocks legitimate historical references) | Low (developer friction) | Whitelist patterns (migrations/, test-vectors/legacy/, SUPERSEDED_INDEX.md) |
| Governance approval bottleneck | Low (delays supersession) | Pre-approval for minor/patch versions; only major versions require full review |

## Follow-up Tasks

- [ ] Create `scripts/validate-spec-references.sh` for CI integration (Phase 1 warning, Phase 2+ blocking)
- [ ] Create `scripts/generate-spec-catalog.py` for automated spec catalog HTML generation
- [ ] Add runtime validation in booking API to reject Superseded spec_version (with governance override flag)
- [ ] Schedule weekly audit report for Superseded spec usage detection
- [ ] Define governance override procedure and approval template
- [ ] Add CI whitelist for legitimate superseded spec references (migrations/, SUPERSEDED_INDEX.md, schema-diff files)

## References

- [ADR-003: FCN Version Activation & Promotion Workflow](adr-003-fcn-version-activation.md)
- [SUPERSEDED_INDEX.md](../../ba/products/structured-notes/fcn/specs/SUPERSEDED_INDEX.md)
- [Schema Diff v1.0 to v1.1](../../ba/products/structured-notes/fcn/schema-diff-v1.0-to-v1.1.md)
- [FCN v1.1.0 Specification](../../ba/products/structured-notes/fcn/specs/fcn-v1.1.0.md) (Active)
- [FCN v1.0 Specification](../../ba/products/structured-notes/fcn/specs/fcn-v1.0.md) (Superseded)

## Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1.0 | 2025-10-17 | siripong.s@yuanta.co.th | Initial draft documenting formal supersession criteria, process steps, lifecycle flowchart, automation hooks, and governance enforcement mechanisms |
| 0.2.0 | 2025-10-17 | siripong.s@yuanta.co.th | Accepted; governance framework operational with v1.0 supersession executed; SUPERSEDED_INDEX.md in place; automation hooks and enforcement mechanisms defined |
