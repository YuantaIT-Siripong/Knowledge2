---
title: FCN Version Activation & Promotion Workflow
doc_type: decision-record
adr: 003
status: Accepted
version: 0.2.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-09
last_reviewed: 2025-10-17
decision_date: 2025-10-17
next_review: 2026-04-09
classification: Internal
tags: [decision, products, governance, versioning, lifecycle]
related:
  - adr-002-product-doc-structure.md
  - adr-005-supersession-lifecycle-enforcement.md
  - ../../../../_policies/document-control-policy.md
  - ../../ba/products/structured-notes/fcn/specs/SUPERSEDED_INDEX.md
  - ../../ba/products/structured-notes/fcn/specs/fcn-v1.1.0.md
  - ../../ba/products/structured-notes/fcn/specs/_activation-checklist-v1.1.0.md
---

# FCN Version Activation & Promotion Workflow

## Current State

**Active Version**: FCN v1.1.0 (documentation_version: "1.1.0")  
**Superseded Version**: FCN v1.0 (Superseded as of 2025-10-17)

FCN v1.1.0 is the normative specification for all new trades, templates, and migrations. The v1.0 specification is retained in [SUPERSEDED_INDEX.md](../../ba/products/structured-notes/fcn/specs/SUPERSEDED_INDEX.md) for historical reference and existing trade audit purposes. New bookings or template creation against v1.0 require explicit governance approval.

### Key Enhancements in v1.1.0
- **Autocall (Knock-Out) Feature** (BR-020, BR-021): Early redemption when all underlyings exceed specified barrier
- **Issuer Parameter** (BR-022): Required issuer identifier with whitelist governance
- **Capital-at-Risk Settlement** (BR-024, BR-025): put_strike_pct parameter enabling proportional loss mechanics
- **Barrier Monitoring Type** (BR-026): Explicit barrier_monitoring_type parameter (discrete normative, continuous reserved)
- **Coupon Independence** (BR-023): Coupon condition independent of knock-out barrier with explicit precedence ordering

See [fcn-v1.1.0.md](../../ba/products/structured-notes/fcn/specs/fcn-v1.1.0.md) and [schema-diff-v1.0-to-v1.1.md](../../ba/products/structured-notes/fcn/schema-diff-v1.0-to-v1.1.md) for complete specification details.

## Context
FCN specifications evolve (v1.0 baseline, v1.1 step-down extension). We require a governed path from Proposed → Active → Deprecated to ensure economic, risk, and implementation alignment.

## Decision
Establish a promotion pipeline:
Concept → Proposed → (Calibration & Review) → Active → Deprecated → Removed

Promotion from Proposed → Active requires a completed Activation Checklist:
1. Parameter table completeness & naming aligned with conventions.
2. Payoff branch taxonomy codes referenced and stable.
3. Step-down or structural extensions documented with backward compatibility notes.
4. Test vectors: minimum normative subset flagged (edge, baseline, KI recovery, physical).
5. Risk calibration review (scenario coverage & stress).
6. Implementation parity confirmation (engine or pricing model).
7. Changelog entry added (with difference summary).
8. Alias / naming conflicts resolved or flagged (deprecation policy integrated).
9. Lifecycle mapping (asset buckets / events) cross-checked.

## Rationale
- Provides gating for correctness & consistency.
- Test vectors ensure reproducible validation.
- Explicit alias auditing reduces semantic drift.

## Alternatives Considered
1. Simple “merge & declare Active” — Rejected (insufficient controls).
2. Heavy-weight change board for every minor revision — Rejected (adds latency, low agility).
3. Tag-based Git semantics only — Rejected (does not capture process artifacts like calibration sign-off).

## Consequences
### Positive
- High confidence in Active specs.
- Clear audit path.
### Negative
- Extra authoring effort early.
- Requires minimal automation to avoid manual drift.

## Version Events Timeline

| Date | Event | Version | Description |
|------|-------|---------|-------------|
| 2025-10-09 | Baseline | v1.0 | Initial FCN specification baseline with memory/no-memory coupons, knock-in barrier, par-recovery |
| 2025-10-16 | Introduction | v1.1.0 | v1.1.0 specification drafted with autocall, issuer parameter, capital-at-risk settlement |
| 2025-10-17 | Supersession | v1.0 → Superseded | v1.0 formally superseded by v1.1.0; SUPERSEDED_INDEX.md created |
| 2025-10-17 | Activation | v1.1.0 → Active | v1.1.0 promoted to Active (pending completion of activation checklist) |

## Activation Checklist Table

The following table tracks activation requirements for FCN v1.1.0 promotion from Proposed to Active status. Based on [_activation-checklist-v1.1.0.md](../../ba/products/structured-notes/fcn/specs/_activation-checklist-v1.1.0.md).

| Item | Description | Status | Artifact Path / Evidence |
|------|-------------|--------|--------------------------|
| Parameter Completeness | All parameters defined with types, constraints, defaults | Done | specs/fcn-v1.1.0.md §3 |
| Payoff Branch Taxonomy | Autocall, capital-at-risk branches documented | Done | specs/fcn-v1.1.0.md §4 |
| Backward Compatibility | v1.0 trades remain valid under v1.1.0 | Done | schema-diff-v1.0-to-v1.1.md §7 |
| Test Vectors (Baseline) | Normative test vectors for autocall scenarios | Done | specs/_activation-checklist-v1.1.0.md §3 |
| Risk Calibration Review | Autocall & capital-at-risk scenarios reviewed | Pending | coverage_report.json |
| Implementation Parity | Pricing model supports new parameters | Pending | engine validation |
| Changelog Entry | Version history and changes documented | Done | specs/fcn-v1.1.0.md §9 |
| Alias Conflicts Resolution | settlement_type canonicalized; no active aliases | Done | adr-004-parameter-alias-policy.md |
| Lifecycle Mapping | Observation events, autocall redemption flows | Pending | runbook.md |
| Business Rules Validation | BR-020 through BR-026 implemented | Pending | business-rules.md |
| Schema Published | fcn-v1.1.0-parameters.schema.json validated | Pending | schemas/ |
| Migration Scripts | m0002, m0003 tested in staging | Pending | migrations/ |
| Issuer Whitelist Process | BR-022 governance documented | Pending | issuer_whitelist.md |
| Supersession Index | v1.0 recorded in SUPERSEDED_INDEX.md | Done | specs/SUPERSEDED_INDEX.md |

## Reserved Features Governance

The following features are reserved for future FCN specification versions and require new ADRs or specification amendments before implementation:

### barrier_monitoring_type = 'continuous'
- **Current Status**: Reserved (non-normative in v1.1.0)
- **Normative Version**: v1.1.0 supports only 'discrete' monitoring (BR-026)
- **Future Scope**: v1.2+ may introduce continuous barrier monitoring with intraday observation requirements
- **Requirements for Activation**:
  - Market data infrastructure supporting intraday tick capture
  - Pricing model extension for continuous monitoring calculations
  - Test vector suite covering continuous monitoring edge cases
  - Risk calibration review for monitoring frequency impact
  - New ADR documenting continuous monitoring governance

### Autocall Logic Extensions
- **Current Support**: auto_call_observation_logic = 'all-underlyings' only (BR-021)
- **Reserved Extensions**:
  - **'any-underlying'**: Autocall triggers if ANY underlying exceeds barrier (not just all)
  - **'worst-of'**: Autocall based on worst-performing underlying only
  - **'custom-logic'**: Configurable weighted or conditional autocall rules
- **Requirements for Activation**:
  - Specification amendment defining new logic semantics
  - Test vectors for each new logic type
  - Pricing model implementation
  - Business rule updates (BR-021 extension)

### Settlement Type Extensions
- **Current Normative**: settlement_type = 'physical-settlement' (v1.0, v1.1.0)
- **Reserved Extensions**:
  - **'mixed-settlement'**: Hybrid physical/cash settlement with allocation rules
  - **'cash-optional'**: Counterparty-selected settlement at maturity
- **Requirements for Activation**:
  - New ADR documenting mixed settlement semantics and governance
  - Alias policy update (ADR-004) defining criteria for settlement_type extensions
  - Legal review for settlement optionality contracts
  - Operations runbook for settlement election process
  - Test vectors covering settlement allocation edge cases

### Governance Process for Reserved Features
1. **Proposal**: Submit RFC (Request for Comments) with business justification and impact analysis
2. **Technical Review**: SA/BA review of specification impact, backward compatibility, and implementation scope
3. **ADR Authoring**: Create or amend ADR documenting feature governance, lifecycle, and validation requirements
4. **Activation Checklist**: Complete feature-specific activation checklist (following ADR-003 workflow)
5. **Approval**: Product, Risk, Compliance, Engineering sign-off before promotion to Active

## CI Enforcement Actions

The following CI/CD pipeline enforcement actions are planned or in-progress to ensure specification lifecycle governance:

### Implemented
- **Schema Version Validation**: Reject commits with invalid documentation_version values
- **Metadata Completeness**: Enforce required front-matter fields in specification documents

### Planned (Phase 1)
- **Superseded Version Gating**: Block new trades or templates referencing documentation_version in SUPERSEDED_INDEX.md without explicit governance approval flag
- **Supersession Metadata Validation**: Validate presence of superseded_by / supersedes keys in spec front-matter
- **Settlement Type Canonicalization**: Lint for non-canonical settlement_type values (enforce 'physical-settlement' vs deprecated aliases)

### Planned (Phase 2)
- **Alias Linter**: Warn on usage of deprecated parameter names (see ADR-004)
- **Business Rule Coverage**: Validate that each normative business rule (BR-xxx) maps to at least one test vector
- **Reserved Feature Guard**: Block commits introducing reserved features (continuous monitoring, mixed-settlement) without ADR approval

### Planned (Phase 3)
- **Activation Checklist Automation**: Auto-generate activation checklist status from artifact references
- **Version Promotion Gate**: Require all activation checklist items status=Done before allowing status: Active promotion
- **Supersession Workflow Automation**: Auto-update SUPERSEDED_INDEX.md on version supersession events

See [ARCHITECTURE_INDEX.md](../architecture/ARCHITECTURE_INDEX.md) for CI enforcement implementation guidance.

## Metrics
- Average Proposed → Active cycle time.
- % of Active specs with complete normative test vector set.
- Drift incidents (implementation divergence) per quarter.

## Follow-up Tasks
- [x] Create activation checklist template file
- [x] Create v1.1.0 activation checklist
- [ ] Add validator rule: Proposed spec must reference checklist issue ID
- [ ] Tag normative test vectors with `normative: true`
- [x] Document supersession event in SUPERSEDED_INDEX.md
- [ ] Implement Phase 1 CI enforcement actions

## Change Log
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1.0 | 2025-10-09 | siripong.s@yuanta.co.th | Initial draft |
| 0.2.0 | 2025-10-17 | siripong.s@yuanta.co.th | Status promoted to Accepted; added Current State, Version Events Timeline, Activation Checklist Table, Reserved Features Governance, CI Enforcement sections; documented v1.0 supersession and v1.1.0 activation |
