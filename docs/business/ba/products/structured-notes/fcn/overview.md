---
title: Fixed Coupon Note (FCN) Product Overview
doc_type: product-definition
status: Draft
version: 0.1.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-10
last_reviewed: 2025-10-10
next_review: 2026-04-10
classification: Internal
tags: [structured-notes, fcn, product-definition, overview]
related:
  - specs/fcn-v1.0.md
  - ../common/governance.md
  - ../common/deprecation-alias-policy.md
  - ../../sa/design-decisions/adr-003-fcn-version-activation.md
  - ../../sa/design-decisions/adr-004-parameter-alias-policy.md
  - ../../../../_policies/document-control-policy.md
---

# Fixed Coupon Note (FCN) Product Overview

## 1. Introduction

Fixed Coupon Notes (FCN) are structured notes that pay periodic fixed coupons contingent on barrier conditions and offer conditional principal protection unless a knock-in (KI) event occurs. This document provides an overview of the FCN product family, with emphasis on versioning, change management, and governance practices.

## 2. Product Summary

FCN products feature:
- Single or basket underlying support
- Memory or non-memory coupon structures
- Down-in (knock-in) barrier monitoring
- Physical or cash settlement options
- Conditional principal protection

The baseline v1.0 specification establishes the normative foundation for all FCN implementations across the organization.

## 3. Versioning & Change Strategy

### 3.1 Version Introduction Strategy

FCN specifications follow semantic versioning (MAJOR.MINOR.PATCH):

**MAJOR versions** (e.g., v1.0 → v2.0):
- Introduce breaking changes to parameter semantics
- Require migration of existing implementations
- Remove deprecated parameters (after completion of alias lifecycle)
- May restructure payoff taxonomy or settlement logic
- Require new activation checklist completion

**MINOR versions** (e.g., v1.0 → v1.1):
- Add new features without breaking existing parameter semantics
- Introduce new optional parameters
- Begin parameter alias lifecycle (Stage 1: Introduce)
- Add new recovery modes or settlement variations
- Extend functionality (e.g., step-down barriers, autocall features)
- Backward compatible with previous minor versions within same major

**PATCH versions** (e.g., v1.0.0 → v1.0.1):
- Documentation corrections and clarifications
- Fix typos or formatting issues
- Add examples or test vectors
- No parameter table changes
- No impact on implementations

### 3.2 Parameter Change Management

Parameter changes are governed by the [Parameter Alias & Deprecation Policy](../../sa/design-decisions/adr-004-parameter-alias-policy.md) and follow a controlled 4-stage lifecycle:

**Stage 1: Introduce (First version)**
- Both legacy and new parameter names are valid
- New name is canonical; legacy flagged with deprecation banner
- Documentation includes alias mapping table
- Test vectors may use either name

**Stage 2: Stable Dual (Minimum one minor version cycle)**
- Both names remain valid
- Tooling emits warnings on new usage of legacy name
- Existing implementations given time to migrate
- Test vectors updated to prefer new name

**Stage 3: Deprecation Notice (Next minor version)**
- Legacy name marked "Deprecated – removal in next major"
- Only backward compatibility parsing allowed
- New usage fails validation
- Test vectors must exclusively use new name

**Stage 4: Removal (Next major version)**
- Legacy name eliminated from specification
- Schema and validation updated
- Changelog documents removal
- Migration guide provided

**Parameter Addition**:
- New optional parameters can be added in minor versions
- Must not alter existing parameter semantics
- Default values ensure backward compatibility
- Documented in version's changelog

**Parameter Modification**:
- Type changes require major version bump
- Constraint changes (ranges, enums) assessed for breaking impact
- Non-breaking refinements allowed in minor versions

### 3.3 Documentation Versioning Practices

All FCN documentation artifacts follow [Document Control Policy](../../../../_policies/document-control-policy.md) standards:

**Specification Documents** (`specs/fcn-v*.md`):
- Each spec version is a separate file (e.g., `fcn-v1.0.md`, `fcn-v1.1.md`)
- Front matter includes `spec_version` and `version` fields
- Status lifecycle: Draft → Proposed → Active → Deprecated → Archived
- Cross-references maintained via `related` field in front matter

**Test Vectors** (`test-vectors/fcn-v*-*.md`):
- Namespaced by spec version (e.g., `fcn-v1.0-baseline.md`)
- Normative subset tagged in spec front matter (`normative_test_vector_set`)
- Must pass validation before spec promotion to Active
- Legacy test vectors archived when spec deprecated

**Examples and Cases** (`examples/`, `cases/`):
- May span multiple spec versions
- Front matter indicates applicable version range
- Updated when parameters or features change
- Deprecated examples moved to archive

**Lifecycle Maps** (`lifecycle/*.md`):
- Version-specific event mappings
- Synchronized with spec releases
- Changes tracked in changelog

### 3.4 Version Activation & Review Process

The [FCN Version Activation & Promotion Workflow](../../sa/design-decisions/adr-003-fcn-version-activation.md) establishes a governed promotion pipeline:

**Draft → Proposed**:
- Initial specification authored
- Basic completeness check
- Author and Product Owner review

**Proposed → Active** (requires completion of [Activation Checklist](specs/_activation-checklist-template.md)):
1. **Parameter Completeness**: All parameters defined with types, constraints, defaults
2. **Naming Conformity**: Aligned with structured notes conventions
3. **Taxonomy Stability**: Payoff branch codes referenced and stable
4. **Test Coverage**: Normative test vector subset complete (N1-N5 minimum)
   - Baseline scenarios (no barrier breach)
   - Edge cases (barrier touch, single-period scenarios)
   - KI event and recovery paths
   - Multi-underlying basket scenarios
5. **Risk Calibration**: Scenario coverage and stress testing reviewed
6. **Implementation Parity**: Engine or pricing model alignment confirmed
7. **Alias Management**: Naming conflicts resolved, deprecation policy applied
8. **Lifecycle Mapping**: Event codes and asset buckets cross-checked
9. **Changelog Entry**: Version differences documented
10. **Sign-off**: Product Owner, Risk Reviewer, Technical Reviewer approval

**Active → Deprecated**:
- New major version supersedes previous
- Transition period specified (typically 6-12 months)
- Migration guide provided
- Support timeline communicated

**Deprecated → Archived**:
- After transition period ends
- All implementations migrated
- Specification moved to `archive/YYYY/`
- Front matter updated with `superseded_by` reference

### 3.5 Review & Recertification Cadence

Per [Structured Notes Documentation Governance](../common/governance.md):

| Document Type | Review Frequency | Trigger Events |
|---------------|------------------|----------------|
| Product Spec (Active) | 6 months | Parameter changes, feature additions |
| Product Spec (Deprecated) | Annual | Confirm migration progress |
| Test Vectors | Per spec change | New spec version, parameter updates |
| Examples | 6 months | Spec changes, user feedback |
| Lifecycle Maps | 4 months | Event model changes |

**Review Roles**:
- **Product Owner**: Business semantics and economic correctness
- **Risk Reviewer**: Scenario coverage and stress calibration
- **Technical Reviewer**: Engine parity and naming conformity
- **Documentation Steward**: Metadata validity and alias oversight

**Review Actions**:
- Validate continued accuracy of parameters and descriptions
- Check for alignment with latest conventions
- Update examples to reflect current best practices
- Verify normative test vectors remain comprehensive
- Update front matter `last_reviewed` and `next_review` dates

### 3.6 Deprecation Process

When a specification version is superseded:

**1. Deprecation Announcement** (T+0):
- Spec status changed to "Deprecated"
- Deprecation notice added to spec document
- New version referenced via `superseded_by` field
- Communication sent to stakeholders

**2. Transition Period** (T+0 to T+6 months):
- Both old and new versions supported
- Migration guide published
- Implementation teams update systems
- Dual-running test coverage maintained

**3. Sunset Warning** (T+6 months):
- Reminder communications sent
- Support for deprecated version reduced
- Only critical bug fixes applied

**4. Removal** (T+12 months):
- Deprecated spec moved to archive
- Support ended
- Legacy test vectors archived
- Validation rules updated to reject old version

**Early Deprecation Criteria**:
- Critical security or compliance issues discovered
- Severe economic miscalculation identified
- Superseded by emergency patch

## 4. Governance & Compliance

### 4.1 Change Request Process

**Minor Changes** (documentation, examples, non-breaking additions):
- Direct pull request
- Minimum 1 approver sign-off
- Standard CI/CD validation

**Major Changes** (breaking changes, new versions):
- GitHub issue with impact rationale
- Designated Approver + domain reviewer required
- Activation checklist completion
- Extended review period

**Emergency Changes** (critical fixes):
- Fast-track approval process
- Post-implementation review within 1 week
- Root cause analysis documented

### 4.2 Tooling & Automation

Current and planned automation:

**Implemented**:
- Front matter schema validation
- Parameter validation against spec
- Test vector validation

**Planned** (see [Governance - Automation Roadmap](../common/governance.md)):
- [ ] Alias lifecycle linter (Phase 1)
- [ ] Metadata schema validation (doc_type-directory alignment)
- [ ] Taxonomy tuple validator
- [ ] Normative test vector tagging enforcement
- [ ] Stale review date checker
- [ ] Link integrity scanning

### 4.3 Metrics & Monitoring

Tracked governance metrics:
- Spec promotion lead time (Draft → Active)
- Activation checklist completion rate
- Incomplete checklist rejections
- Alias lifecycle adherence (on-time removals)
- Documentation recertification compliance
- Implementation divergence incidents per quarter

## 5. Related Documentation

**Specifications**:
- [FCN v1.0 Specification](specs/fcn-v1.0.md) - Baseline specification

**Governance & Policy**:
- [Structured Notes Documentation Governance](../common/governance.md) - Product documentation governance
- [Document Control Policy](../../../../_policies/document-control-policy.md) - Organization-wide documentation standards
- [Deprecation & Alias Operational Policy](../common/deprecation-alias-policy.md) - Parameter naming and deprecation
- [ADR-003: FCN Version Activation & Promotion Workflow](../../sa/design-decisions/adr-003-fcn-version-activation.md) - Activation decision record
- [ADR-004: Parameter Alias & Deprecation Policy](../../sa/design-decisions/adr-004-parameter-alias-policy.md) - Alias policy decision record

**Supporting Artifacts**:
- [Activation Checklist Template](specs/_activation-checklist-template.md) - Spec promotion checklist
- [Structured Notes Conventions](../common/conventions.md) - Naming and parameter conventions
- [Payoff Types](../common/payoff_types.md) - Product taxonomy

## 6. Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1.0 | 2025-10-10 | siripong.s@yuanta.co.th | Initial overview document with versioning and change strategy section |
