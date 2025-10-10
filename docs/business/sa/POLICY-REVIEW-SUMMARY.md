---
title: Policy Review Summary for SA Role
doc_type: reference
role_primary: SA
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
status: Draft
version: 1.0.0
created: 2025-10-10
last_reviewed: 2025-10-10
next_review: 2025-11-10
classification: Internal
tags: [policy, review, summary, sa]
---

# Policy Review Summary for SA Role

## Purpose
This document provides a consolidated summary of all policy documents reviewed as part of SA role onboarding. It serves as a quick reference for key policy requirements.

---

## Policy Documents Reviewed

### 1. Document Control Policy
**Location:** `docs/_policies/document-control-policy.md`
**Status:** ✅ Reviewed
**Version:** 0.1.0

#### Key Takeaways:
- **Document Types:** policy, process, requirement-set, use-case, business-rule, architecture, interface-spec, decision-record, glossary, playbook, lifecycle, reference, product-spec, product-definition, test-vector
- **Classification Levels:** Public, Internal, Confidential, Restricted (Default: Internal)
- **Status Workflow:** Draft → In Review → Approved → Published → (Superseded | Archived)
- **Versioning:** MAJOR.MINOR.PATCH (semantic versioning)
  - MAJOR: Structural/meaningful changes
  - MINOR: Additions without invalidation
  - PATCH: Typos, formatting, clarifications

#### Review Cadences:
| Doc Type | Cadence |
|----------|---------|
| process, business-rule | 6 months |
| requirement-set | Per release or 6 months |
| architecture (context, logical) | 4 months |
| interface-spec | On change or 4 months |
| decision-record | Annual |
| policy | 12 months |

#### Change Request Process:
- **Minor change:** Direct PR, 1+ approver sign-off
- **Major change:** Issue with impact rationale, designated Approver + domain reviewer
- **Breaking decision:** New ADR, mark old ADR Superseded

---

### 2. Roles and Responsibilities
**Location:** `docs/_policies/roles-and-responsibilities.md`
**Status:** ✅ Reviewed
**Version:** 0.1.0

#### Key Roles:
| Role | Responsibilities |
|------|------------------|
| **Author** | Creates or updates documents, draft, update metadata |
| **Peer Reviewer** | Same discipline reviewer, provide review comments |
| **Approver** | Final authority for type, approve merge |
| **Document Steward** | Maintains policies & taxonomy, update standards, oversee compliance |
| **Knowledge Base Maintainer** | Maintains scripts & CI, implement validation, fix automation |
| **Security Reviewer** | Reviews security/classification, approve classification changes |
| **BA Lead** | Ensures BA docs recertified, track review dates |
| **Architecture Reviewer** | Ensures architectural consistency, gate architecture merges |

#### SA Role Responsibilities:
As **Author (Architect Author)**:
- Draft architectural artifacts (API specs, data models, integration designs)
- Update metadata in YAML front matter
- Ensure traceability to business requirements

As **Peer Reviewer** (when reviewing other architects):
- Validate architectural consistency
- Provide technical review comments
- Check for alignment with standards

#### Escalation Path:
Author → Peer Reviewer → Steward → Approver

---

### 3. Tagging Schema
**Location:** `docs/_policies/tagging-schema.md`
**Status:** ✅ Reviewed
**Version:** 0.1.0

#### Allowed doc_type Values:
`policy`, `process`, `requirement-set`, `use-case`, `business-rule`, `architecture`, `decision-record`, `interface-spec`, `glossary`, `playbook`, `lifecycle`, `reference`, `template`, `product-spec`, `product-definition`, `test-vector`

#### SA-Relevant doc_types:
- **architecture** - Architectural views and designs
- **decision-record** - ADRs documenting architectural decisions
- **interface-spec** - API specifications, integration contracts

#### Classification Values:
`Public`, `Internal`, `Confidential`, `Restricted`

#### Recommended Tags:
**Domain:** customer, account, product, pricing, risk, compliance, reporting, integration, security
**Discipline:** process, requirements, architecture, design, data, api, messaging, security

#### Tag Constraints:
- **Max 8 tags** per document
- **Lowercase only**
- **Kebab-case** for multi-word tags (e.g., `market-data`)

---

### 4. Taxonomy and Naming Standard
**Location:** `docs/_policies/taxonomy-and-naming.md`
**Status:** ✅ Reviewed
**Version:** 0.1.0

#### Folder Naming:
- Use `lowercase-with-dashes`
- Avoid abbreviations except widely accepted (e.g., `api`)

#### File Naming:
- **Stable docs:** `short-descriptive-name.md`
- **ADRs:** `adr-###-short-title.md` (zero-padded, sequential)
- **Time-specific:** `YYYY-MM-DD-short-title.md` (optional, when chronology matters)

#### ADR Numbering:
- **Sequential integers** (001, 002, 003, ...)
- **Zero-padded** to 3 digits
- **Monotonic** - never reuse retired numbers
- **No gaps** - increment by 1

#### SA Document Locations:
| Type | Folder |
|------|--------|
| architecture | `docs/business/sa/architecture/<view>/` |
| interface-spec | `docs/business/sa/interfaces/` |
| decision-record | `docs/business/sa/design-decisions/` |

#### Required Metadata Keys:
`doc_type`, `owner`, `approver`, `status`, `version`, `created`, `last_reviewed`, `next_review`, `classification`, `tags`

**Optional:** `related`, `supersedes`, `superseded_by`, `adr` (for ADRs)

---

### 5. SA Document Lifecycle
**Location:** `docs/lifecycle/sa-lifecycle.md`
**Status:** ✅ Reviewed
**Version:** 0.1.0

#### 9 Lifecycle Stages:
1. **Driver Captured** - Requirements gathered from BA
2. **Draft Models** - SA creates initial designs (CURRENT STAGE)
3. **Peer Architecture Review** - Peer architects review
4. **Cross-Functional Review** - Dev, Ops, Security review
5. **Decision Recording (ADR)** - Document decisions
6. **Approval** - Final approval
7. **Publication** - Artifacts published
8. **Drift Detection** - Quarterly reviews
9. **Refresh / Supersede** - Updates or replacements

#### Current Stage: Driver Captured → Draft Models
**SA Actions:**
- Create API specifications
- Design data models
- Document integration patterns
- Design security architecture
- Record architectural decisions in ADRs

#### ADR Criteria:
Create ADR if change affects:
- Cross-team dependencies
- Cost & capacity
- Security model
- Integration contracts
- Strategic quality attributes

#### RACI Matrix (Key Stages):
| Stage | Architect Author | Peer Architect | Security | BA Rep | Dev Lead | Ops |
|-------|------------------|----------------|----------|--------|----------|-----|
| **Driver Captured** | R | I | I | C | C | I |
| **Draft Models** | R | C | C | C | C | C |
| **Peer Arch Review** | C | R | C | I | C | I |
| **Cross-Functional** | C | C | R | C | C | C |
| **Decision Recording** | R | C | C | I | C | I |

**Legend:** R=Responsible, A=Accountable, C=Consulted, I=Informed

---

### 6. BA Document Lifecycle
**Location:** `docs/lifecycle/ba-lifecycle.md`
**Status:** ✅ Reviewed (for context)
**Version:** 0.1.0

#### Key Insight:
BA lifecycle precedes SA lifecycle. BA completes:
1. Identify Need
2. Draft
3. Peer Review
4. Stakeholder Review
5. Approval
6. Publication

**Then hands off to SA** via Domain Handoff Package.

---

## Architecture Decision Records Reviewed

### ADR-001: Documentation Governance Approach
**Location:** `docs/business/sa/design-decisions/adr-001-documentation-governance.md`
**Status:** ✅ Reviewed
**Decision:** Adopt structured taxonomy, mandatory metadata, role-specific lifecycles, ADR transparency

**Key Points:**
- Reduces fragmentation
- Enables automation
- Provides auditability

---

### ADR-002: Product Documentation Structure & Location
**Location:** `docs/business/sa/design-decisions/adr-002-product-doc-structure.md`
**Status:** ✅ Reviewed
**Decision:** Product docs under `docs/business/ba/products/<product-family>/<product>/`

**New doc_types:**
- `product-spec` - Normative versioned specifications
- `product-definition` - Illustrative descriptions
- `test-vector` - Validation scenarios

---

### ADR-003: FCN Version Activation & Promotion Workflow
**Location:** `docs/business/sa/design-decisions/adr-003-fcn-version-activation.md`
**Status:** ✅ Reviewed
**Decision:** Promotion pipeline: Concept → Proposed → Active → Deprecated → Removed

**Promotion from Proposed → Active requires:**
1. Parameter table complete
2. Taxonomy codes stable
3. Test vectors (normative subset)
4. Risk calibration review
5. Implementation parity
6. Changelog entry
7. Alias conflicts resolved
8. Lifecycle mapping verified

---

### ADR-004: Parameter Alias & Deprecation Policy
**Location:** `docs/business/sa/design-decisions/adr-004-parameter-alias-policy.md`
**Status:** ✅ Reviewed
**Decision:** 4-stage alias lifecycle: Introduce → Stable Dual → Deprecation Notice → Removal

**Requirements:**
- Conventions file lists alias mapping
- Each spec includes "Alias Table"
- Test vectors stop using legacy at stage 3

---

## Summary of Key Requirements for SA

### Document Creation Requirements:
1. ✅ Use proper doc_type (`architecture`, `decision-record`, `interface-spec`)
2. ✅ Include complete YAML front matter (all required fields)
3. ✅ Use semantic versioning (MAJOR.MINOR.PATCH)
4. ✅ Set appropriate classification (default: Internal)
5. ✅ Add relevant tags (max 8, lowercase, kebab-case)
6. ✅ Follow naming conventions (lowercase-with-dashes)
7. ✅ For ADRs: use sequential numbering (adr-###-title.md)

### Workflow Requirements:
1. ✅ Start at Draft status
2. ✅ Move through lifecycle stages (Draft → In Review → Approved → Published)
3. ✅ Get peer architect review before approval
4. ✅ Document all architectural decisions in ADRs
5. ✅ Update last_reviewed and next_review dates
6. ✅ Maintain traceability to business requirements

### Quality Requirements:
1. ✅ Use relative links for cross-references
2. ✅ Store diagram sources (.drawio, .plantuml, .mermaid)
3. ✅ Follow escalation path if issues arise
4. ✅ Update metadata when making changes
5. ✅ Run validators before committing

---

## Compliance Checklist for New SA Artifacts

Before creating any new architectural artifact, ensure:

- [ ] **doc_type** selected from allowed values
- [ ] **YAML front matter** complete with all required fields:
  - [ ] title
  - [ ] doc_type
  - [ ] owner
  - [ ] approver
  - [ ] status
  - [ ] version (0.1.0 for new drafts)
  - [ ] created (YYYY-MM-DD)
  - [ ] last_reviewed (YYYY-MM-DD)
  - [ ] next_review (based on doc_type cadence)
  - [ ] classification (usually Internal)
  - [ ] tags (relevant, max 8)
- [ ] **File name** follows conventions (lowercase-with-dashes)
- [ ] **Folder location** correct for doc_type
- [ ] **Cross-references** use relative links
- [ ] **Traceability** to business requirements documented
- [ ] **Diagrams** have source files stored adjacent
- [ ] **ADR** (if decision): sequential number assigned

---

## Quick Reference

### Most Common SA doc_types:
- `architecture` - For designs and models
- `decision-record` - For ADRs
- `interface-spec` - For API specifications

### Most Common SA tags:
- `architecture`, `design`, `api`, `integration`, `security`, `data`, `fcn`, `decision`

### Most Common SA statuses:
- `Draft` - Initial creation
- `In Review` - Under peer review
- `Approved` - Approved by peer + approver
- `Published` - Final, implementation-ready

### Document Locations:
- **Architecture:** `docs/business/sa/architecture/<view>/`
- **ADRs:** `docs/business/sa/design-decisions/`
- **API Specs:** `docs/business/sa/interfaces/`
- **Handoffs:** `docs/business/sa/handoff/`

---

## Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-10 | copilot | Initial policy review summary created |
