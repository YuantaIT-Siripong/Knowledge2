---
title: SA Role Onboarding Checklist - FCN v1.0
doc_type: playbook
role_primary: SA
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
status: Draft
version: 1.0.0
created: 2025-10-10
last_reviewed: 2025-10-10
next_review: 2025-11-10
classification: Internal
tags: [sa, onboarding, checklist, fcn]
related:
  - sa-work-readiness-assessment.md
  - handoff/domain-handoff-fcn-v1.0.md
  - ../../lifecycle/sa-lifecycle.md
  - ../../_policies/roles-and-responsibilities.md
---

# SA Role Onboarding Checklist - FCN v1.0

## Purpose
This checklist guides Solution Architects through the onboarding process for FCN v1.0 work, ensuring all policies are reviewed and initial work is properly organized.

---

## Part 1: Policy Review (Complete First)

### 1.1 Core Policies
- [x] **Document Control Policy** (`docs/_policies/document-control-policy.md`)
  - [x] Understand document types, statuses, and versioning
  - [x] Review classification levels
  - [x] Understand review and recertification cadence
  - [x] Review change request process
- [x] **Roles and Responsibilities** (`docs/_policies/roles-and-responsibilities.md`)
  - [x] Understand SA role: Architect Author responsibilities
  - [x] Identify peer review requirements (Peer Architect)
  - [x] Understand approval gates (Approver)
  - [x] Note escalation path
- [x] **Tagging Schema** (`docs/_policies/tagging-schema.md`)
  - [x] Review allowed doc_type values
  - [x] Understand classification values
  - [x] Review discipline and domain tags
  - [x] Note tag constraints (max 8, lowercase, kebab-case)
- [x] **Taxonomy and Naming Standard** (`docs/_policies/taxonomy-and-naming.md`)
  - [x] Understand folder naming conventions
  - [x] Review file naming patterns
  - [x] Understand ADR numbering (sequential, zero-padded)
  - [x] Review document type to folder mappings

### 1.2 Lifecycle Documents
- [x] **SA Document Lifecycle** (`docs/lifecycle/sa-lifecycle.md`)
  - [x] Review 9 lifecycle stages
  - [x] Understand ADR criteria
  - [x] Review RACI matrix for each stage
  - [x] Understand drift detection process
- [x] **BA Document Lifecycle** (`docs/lifecycle/ba-lifecycle.md`)
  - [x] Understand BA workflow for context
  - [x] Identify handoff points between BA and SA

---

## Part 2: FCN v1.0 Context Review

### 2.1 Architecture Decision Records
- [x] **ADR-001: Documentation Governance** (`design-decisions/adr-001-documentation-governance.md`)
  - [x] Understand governance approach
  - [x] Review follow-up tasks
- [x] **ADR-002: Product Doc Structure** (`design-decisions/adr-002-product-doc-structure.md`)
  - [x] Understand product documentation organization
  - [x] Note new doc_types: product-spec, product-definition, test-vector
- [x] **ADR-003: FCN Version Activation** (`design-decisions/adr-003-fcn-version-activation.md`)
  - [x] Understand promotion pipeline (Proposed → Active → Deprecated)
  - [x] Review activation checklist requirements
- [x] **ADR-004: Parameter Alias Policy** (`design-decisions/adr-004-parameter-alias-policy.md`)
  - [x] Understand 4-stage alias lifecycle
  - [x] Review documentation requirements

### 2.2 BA Handoff Artifacts
- [x] **SA Work Readiness Assessment** (`sa-work-readiness-assessment.md`)
  - [x] Confirm SA can begin work (Answer: YES)
  - [x] Review available BA handoff artifacts
  - [x] Identify ready-to-start activities
  - [x] Note partially-ready activities requiring decisions
  - [x] Review recommended work plan (Phases 1-4)
- [x] **Domain Handoff Package** (`handoff/domain-handoff-fcn-v1.0.md`)
  - [x] Review overview and scope
  - [x] Understand stakeholders and actors
  - [x] Review FCN-specific glossary
  - [x] Study conceptual domain model
  - [x] Review business rules
  - [x] Understand core processes
- [ ] **FCN v1.0 Specification** (`../ba/products/structured-notes/fcn/specs/fcn-v1.0.md`)
  - [ ] Review parameter definitions
  - [ ] Understand taxonomy branches
  - [ ] Study payoff logic
- [ ] **Business Rules** (`../ba/products/structured-notes/fcn/business-rules.md`)
  - [ ] Review all 19 business rules (BR-001 to BR-019)
  - [ ] Identify rules requiring architectural decisions
- [ ] **ER Model** (`../ba/products/structured-notes/fcn/er-fcn-v1.0.md`)
  - [ ] Review conceptual entity-relationship model
  - [ ] Identify entities for physical database design
- [ ] **API Integration Resources** (`../ba/products/structured-notes/fcn/integrations.md`)
  - [ ] Review API resource candidates
  - [ ] Understand integration touchpoints

---

## Part 3: SA Work Environment Setup

### 3.1 Workspace Organization
- [ ] Create working branch for SA artifacts (if not already on one)
- [ ] Verify directory structure exists:
  - [ ] `docs/business/sa/architecture/` (with subdirectories)
  - [ ] `docs/business/sa/design-decisions/`
  - [ ] `docs/business/sa/handoff/`
  - [ ] `docs/business/sa/interfaces/`

### 3.2 Tool Familiarization
- [ ] Review existing validator scripts (`docs/scripts/`)
- [ ] Understand metadata validation requirements
- [ ] Identify tools needed for diagram creation (drawio, plantuml, mermaid)

---

## Part 4: Initial SA Work Plan (Phase 1 - Weeks 1-2)

Based on SA Work Readiness Assessment, the following activities are **ready to start immediately**:

### 4.1 API Design
- [ ] Create OpenAPI 3.0 specification file
  - [ ] Define `/contracts` resource (POST, GET operations)
  - [ ] Define `/parameters/validation` resource
  - [ ] Define `/observations` resource (POST, GET operations)
  - [ ] Define `/coupons` resource (GET operations)
  - [ ] Define `/cash-flows` resource (GET operations)
  - [ ] Document HTTP methods, status codes, error responses
  - [ ] Design pagination, filtering, sorting strategies
  - [ ] Document authentication/authorization requirements

### 4.2 Data Model Design
- [ ] Create physical database schema design document
  - [ ] Design table definitions for core entities:
    - [ ] contracts table
    - [ ] underlying_assets table
    - [ ] observations table
    - [ ] coupon_decisions table
    - [ ] cash_flows table
  - [ ] Define column types and constraints
  - [ ] Design primary and foreign keys
  - [ ] Plan indexes for performance
  - [ ] Design audit/history tables
  - [ ] Define data retention policies

### 4.3 Integration Architecture
- [ ] Create integration architecture document
  - [ ] Design trade booking system integration
  - [ ] Design market data provider integration
  - [ ] Design settlement system integration
  - [ ] Design reporting system integration
  - [ ] Define message formats and protocols
  - [ ] Create integration sequence diagrams
  - [ ] Design error handling and retry logic

### 4.4 Security Architecture
- [ ] Create security architecture document
  - [ ] Design authentication/authorization model (OAuth2/JWT/API keys)
  - [ ] Define API security requirements
  - [ ] Design data encryption strategy
  - [ ] Document RBAC requirements
  - [ ] Create security ADR

---

## Part 5: Decision Making (Phase 2 - Weeks 2-3)

These open questions require SA architectural decisions:

### 5.1 Idempotency Implementation (OQ-BR-002)
- [ ] Analyze Option A: Database unique constraint
- [ ] Analyze Option B: Application-level locking
- [ ] Document comparison (pros/cons, performance, complexity)
- [ ] Make architectural decision
- [ ] Create **ADR-005: Idempotency Implementation Strategy**

### 5.2 Market Data Architecture (OQ-API-005)
- [ ] Design Option A: Internal service
- [ ] Design Option B: External integration
- [ ] Analyze trade-offs (data sovereignty, latency, cost, reliability)
- [ ] Make architectural decision
- [ ] Create **ADR-006: Market Data Integration Architecture**

### 5.3 Historical Observation Replay (OQ-API-003)
- [ ] Assess technical feasibility
- [ ] Document complexity and cost implications
- [ ] Provide recommendation to BA/Product Owner
- [ ] Create technical assessment document

### 5.4 Contract Amendment Support (OQ-API-001) - Collaborative
- [ ] Provide technical assessment (complexity, effort, risk)
- [ ] Collaborate with BA on business justification
- [ ] Support Product Owner decision
- [ ] Document decision outcome

---

## Part 6: Peer Review Preparation (Phase 3-4 - Weeks 3-5)

### 6.1 Artifact Finalization
- [ ] Finalize OpenAPI specification (v1.0)
- [ ] Finalize database schema DDL (v1.0)
- [ ] Complete integration sequence diagrams
- [ ] Create infrastructure architecture diagram
- [ ] Document deployment architecture
- [ ] Update all metadata (status, version, dates)

### 6.2 Quality Checks
- [ ] Validate all documents have proper YAML front matter
- [ ] Check cross-references are valid
- [ ] Ensure all ADRs follow template structure
- [ ] Verify traceability to business rules
- [ ] Run metadata validators

### 6.3 Peer Architecture Review
- [ ] Submit for Peer Architecture Review (SA Lifecycle Stage 3)
- [ ] Address review comments
- [ ] Cross-functional review with Dev Lead, Ops, Security
- [ ] Finalize all architectural artifacts

---

## Part 7: Completion Criteria

### 7.1 Deliverables Checklist
- [ ] OpenAPI 3.0 specification (v1.0, status: Approved)
- [ ] Database schema DDL with documentation (v1.0, status: Approved)
- [ ] Integration architecture document (v1.0, status: Approved)
- [ ] Security architecture document with ADR (v1.0, status: Approved)
- [ ] Infrastructure architecture diagram
- [ ] Deployment guide
- [ ] ADR-005: Idempotency Implementation Strategy
- [ ] ADR-006: Market Data Integration Architecture
- [ ] Technical assessment: Historical Replay Support

### 7.2 Quality Gates
- [ ] All documents have valid YAML front matter
- [ ] All documents follow naming conventions
- [ ] API design follows RESTful best practices
- [ ] Database schema normalized and performant
- [ ] Integration architecture addresses failure scenarios
- [ ] Security architecture meets organizational standards
- [ ] All decisions documented in ADRs
- [ ] Traceability to business rules maintained
- [ ] Peer architecture review passed
- [ ] Cross-functional review passed

### 7.3 Readiness for Implementation
- [ ] Backend engineers can begin implementation from OpenAPI spec
- [ ] Data engineers can create ETL pipelines from schema design
- [ ] QA engineers can create API test cases from OpenAPI spec
- [ ] Ops engineers can prepare infrastructure from architecture docs

---

## Part 8: Support and Escalation

### 8.1 Points of Contact
- **SA Owner:** siripong.s@yuanta.co.th
- **BA Contact:** siripong.s@yuanta.co.th (for handoff clarifications)
- **Peer Architect:** TBD (for peer review)
- **Security Reviewer:** TBD (for security architecture review)

### 8.2 Escalation Path
Following the escalation path from roles-and-responsibilities.md:
1. **Author (SA)** → 2. **Peer Reviewer (Peer Architect)** → 3. **Steward (Document Steward)** → 4. **Approver**

### 8.3 Resources
- **Documentation Root:** `/docs/`
- **Policies:** `/docs/_policies/`
- **SA Artifacts:** `/docs/business/sa/`
- **BA Artifacts:** `/docs/business/ba/`
- **Scripts/Validators:** `/docs/scripts/`

---

## Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-10 | copilot | Initial onboarding checklist created for SA role startup |
