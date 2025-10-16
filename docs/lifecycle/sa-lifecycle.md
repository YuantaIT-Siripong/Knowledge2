---
title: SA Document Lifecycle
doc_type: lifecycle
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
status: Draft
version: 0.2.0
created: 2025-10-09
last_reviewed: 2025-10-10
next_review: 2026-02-09
classification: Internal
tags: [lifecycle, architecture]
---

# SA Document Lifecycle

## Overview

The Solution Architecture (SA) document lifecycle ensures that architecture artifacts are properly reviewed, approved, and maintained throughout their lifetime. This lifecycle applies to all SA artifacts including architecture views, design decisions (ADRs), integration specifications, and technical handoff documents.

## Stages

### 1. Driver Captured

**Purpose**: Identify and document the business/technical drivers that require architectural attention.

**Activities**:
- Identify architectural drivers (new features, quality attributes, constraints)
- Document stakeholder concerns and quality attribute requirements
- Assess impact on existing architecture
- Create initial issue or work item

**Inputs**:
- Business requirements from BA
- Technical constraints
- Quality attribute requirements
- Regulatory/compliance requirements

**Outputs**:
- Architecture driver document or issue
- Initial scope definition
- Stakeholder list

**Duration**: 1-2 days

**Entry Criteria**: Business requirement or technical need identified

**Exit Criteria**: Architectural driver documented and approved for design work

---

### 2. Draft Models

**Purpose**: Create initial architecture views and models.

**Activities**:
- Develop context, logical, integration, security, and infrastructure views
- Create diagrams (C4, sequence, component, deployment)
- Document quality attributes and design principles
- Identify risks and technical debt
- Draft initial ADRs for significant decisions

**Artifacts Created**:
- Context view (system boundary, external actors)
- Logical view (components, responsibilities)
- Integration view (APIs, protocols, messages)
- Security view (authentication, authorization, data protection)
- Infrastructure view (deployment, environments)

**Tools**:
- Mermaid for diagrams
- Markdown for documentation
- Architecture templates from `docs/_templates/`

**Duration**: 1-2 weeks

**Entry Criteria**: Architecture driver approved

**Exit Criteria**: All required views drafted, self-review complete

---

### 3. Peer Architecture Review

**Purpose**: Obtain feedback from peer architects to improve quality and consistency.

**Activities**:
- Present architecture to peer architects
- Review alignment with enterprise standards
- Validate technical approaches
- Identify gaps or inconsistencies
- Document review feedback

**Review Checklist**:
- [ ] All views present and complete
- [ ] Diagrams follow C4 or standard notation
- [ ] Quality attributes explicitly stated
- [ ] Integration contracts defined
- [ ] Security considerations addressed
- [ ] Risks and mitigations documented
- [ ] Decisions traceable to ADRs
- [ ] Consistent with existing architecture

**Participants**: 2-3 peer architects (minimum)

**Duration**: 3-5 days (including rework)

**Entry Criteria**: Draft models complete

**Exit Criteria**: Peer review feedback addressed, architect approval obtained

---

### 4. Cross-Functional Review

**Purpose**: Validate architecture with stakeholders from other disciplines.

**Activities**:
- Present to BA representatives (business alignment)
- Review with Security team (security posture)
- Consult with Dev Leads (implementation feasibility)
- Review with Ops (operational considerations)
- Document cross-functional feedback

**Stakeholders**:
- **BA Rep**: Validate business alignment, data model consistency
- **Security**: Validate security controls, compliance requirements
- **Dev Lead**: Assess implementation complexity, technical debt
- **Ops**: Evaluate operational impact, monitoring, disaster recovery

**Duration**: 1 week (including rework)

**Entry Criteria**: Peer architecture review complete

**Exit Criteria**: Cross-functional concerns addressed, stakeholder signoffs

---

### 5. Decision Recording (ADR)

**Purpose**: Document significant architectural decisions with rationale.

**Activities**:
- Identify decisions requiring ADR
- Write ADR using standard template
- Document context, decision, rationale, alternatives, consequences
- Link ADRs to architecture views

**ADR Criteria**:
Create ADR if change affects:
- Cross-team dependencies
- Cost & capacity planning
- Security model or threat surface
- Integration contracts or APIs
- Strategic quality attributes (performance, scalability, availability)
- Technology stack or platform choices
- Data architecture or persistence strategy

**ADR Template**: Use `docs/_templates/template-decision-record.md`

**Duration**: 1-2 days per ADR

**Entry Criteria**: Significant decision identified during architecture design

**Exit Criteria**: ADR documented, reviewed, and linked to architecture

---

### 6. Approval

**Purpose**: Obtain formal approval from designated approvers.

**Activities**:
- Submit architecture package for approval
- Address any final questions or concerns
- Obtain approver signatures/signoffs
- Update status to "Approved"

**Approvers**:
- Architecture Lead (mandatory)
- Security Lead (for security-sensitive changes)
- Infrastructure Lead (for infrastructure changes)

**Duration**: 2-3 days

**Entry Criteria**: All reviews complete, ADRs documented

**Exit Criteria**: Formal approval obtained, status updated

---

### 7. Publication

**Purpose**: Make architecture available to broader audience.

**Activities**:
- Update document status to "Published"
- Merge to main branch
- Update architecture index
- Announce to stakeholders
- Archive previous version (if superseding)

**Outputs**:
- Published architecture in repository
- Updated index (`docs/_meta/index.yml`)
- Communication to stakeholders

**Duration**: 1 day

**Entry Criteria**: Approval obtained

**Exit Criteria**: Architecture published and accessible

---

### 8. Drift Detection

**Purpose**: Identify divergence between documented architecture and actual implementation.

**Activities**:
- Quarterly review of architecture vs. reality
- Compare diagrams to runtime inventory
- Check API contracts vs. implementation
- Review security controls in production
- Open issues for identified drift

**Drift Examples**:
- New components not in architecture diagrams
- API changes not reflected in integration view
- Security controls not implemented as designed
- Infrastructure topology differs from documented

**Review Frequency**: Quarterly

**Outputs**:
- Drift detection report
- Issues for remediation
- Update prioritization

**Entry Criteria**: Architecture published for at least 1 quarter

**Exit Criteria**: Drift identified, issues created, remediation planned

---

### 9. Refresh / Supersede

**Purpose**: Update architecture to reflect changes or create new version.

**Activities**:
- Assess need for update (minor) vs. new version (major)
- Update architecture views
- Create new ADRs for changed decisions
- Mark old version as "Superseded" if major change
- Go through lifecycle stages 2-7 for significant changes

**Triggers**:
- Significant drift identified
- New features or quality attributes
- Technology evolution
- Regulatory changes
- Post-incident learnings

**Versioning**:
- Minor updates (0.1.0 → 0.2.0): Small changes, no review cycle
- Major updates (0.x.0 → 1.0.0): Significant changes, full review cycle

**Entry Criteria**: Need for architecture update identified

**Exit Criteria**: Updated architecture published or new version created

---

## Drift Detection

### Detection Methods
1. **Automated Scanning**:
   - Infrastructure as Code (IaC) diff vs. documented topology
   - API schema validation against published contracts
   - Security control verification

2. **Manual Review**:
   - Walkthrough with implementation team
   - Code review alignment check
   - Architecture decision validation

3. **Monitoring**:
   - Service dependency mapping
   - Integration pattern analysis
   - Technology stack inventory

### Drift Remediation
1. **Update Documentation**: If implementation is correct but documentation stale
2. **Update Implementation**: If documentation is correct but implementation drifted
3. **Resolve Conflict**: If both need adjustment (requires ADR)

### Metrics
- Drift items identified per quarter
- Average time to remediate drift
- Percentage of components with drift
- Architecture review coverage

---

## Document Status Values

| Status | Description | Lifecycle Stage |
|--------|-------------|-----------------|
| **Draft** | Work in progress, not reviewed | 1-2 |
| **In Review** | Under peer or cross-functional review | 3-4 |
| **Approved** | Approved but not yet published | 6 |
| **Published** | Active and authoritative | 7 |
| **Superseded** | Replaced by newer version | 9 |
| **Archived** | Historical, no longer applicable | 9 |

## RACI
| Stage | Architect Author | Peer Architect | Security | BA Rep | Dev Lead | Ops |
|-------|------------------|----------------|----------|--------|----------|-----|
| Driver Captured | R | I | I | C | C | I |
| Draft Models | R | C | C | C | C | C |
| Peer Arch Review | C | R | C | I | C | I |
| Cross-Functional | C | C | R | C | C | C |
| Decision Recording | R | C | C | I | C | I |
| Approval | C | C | I | I | I | I |
| Publication | R | I | I | I | I | I |
| Drift Detection | R | C | C | I | C | C |
| Refresh/Supersede | R | C | C | I | C | C |
