---
title: SA Work Readiness Assessment - FCN v1.0
doc_type: assessment
role_primary: SA
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
status: Draft
version: 1.0.0
created: 2025-10-10
last_reviewed: 2025-10-10
next_review: 2025-11-10
classification: Internal
tags: [sa, readiness, assessment, fcn, handoff]
related:
  - handoff/domain-handoff-fcn-v1.0.md
  - ../ba/products/structured-notes/fcn/overview.md
  - ../ba/products/structured-notes/fcn/integrations.md
  - ../../lifecycle/sa-lifecycle.md
---

# SA Work Readiness Assessment - FCN v1.0

## 1. Executive Summary

**Question:** From current status, is it possible to do job in role SA?

**Answer:** **YES - with qualifications**

The Solution Architect role **CAN BEGIN WORK** on FCN v1.0 based on the current documentation state. The BA has successfully completed the Domain Handoff Package, providing sufficient information for SA to start architectural design work. However, some SA activities are conditional on resolving specific open questions.

### Quick Status
- ✅ **Ready to Start:** API Design, Data Model Design, Integration Architecture
- ⚠️ **Partially Ready:** Implementation details pending open question resolution
- 🔄 **Collaborative:** Some decisions require BA/SA joint resolution

---

## 2. Assessment Framework

Based on the SA Document Lifecycle (docs/lifecycle/sa-lifecycle.md), the SA role progresses through these stages:

1. ✅ **Driver Captured** - BA has provided requirements
2. 🔄 **Draft Models** - SA can begin (THIS STAGE)
3. ⏳ **Peer Architecture Review** - Future
4. ⏳ **Cross-Functional Review** - Future
5. ⏳ **Decision Recording (ADR)** - In progress
6. ⏳ **Approval** - Future
7. ⏳ **Publication** - Future
8. ⏳ **Drift Detection** - Future
9. ⏳ **Refresh / Supersede** - Future

**Current Position:** SA is ready to transition from "Driver Captured" to "Draft Models" stage.

---

## 3. Available BA Handoff Artifacts

The following artifacts are **AVAILABLE** and provide sufficient input for SA work:

### 3.1 Core Documentation
| Artifact | Status | Completeness | SA Usability |
|----------|--------|--------------|--------------|
| Domain Handoff Package (domain-handoff-fcn-v1.0.md) | Draft v1.0.2 | High (90%) | ✅ Ready |
| FCN v1.0 Specification (specs/fcn-v1.0.md) | Draft | High | ✅ Ready |
| Business Rules (business-rules.md) | Draft | High | ✅ Ready |
| ER Model (er-fcn-v1.0.md) | Draft | High | ✅ Ready |
| API Integration Resources (integrations.md) | Draft | Medium | ✅ Ready |
| Overview & KPI Baselines (overview.md) | Draft v1.0.0 | High | ✅ Ready |

### 3.2 Key Information Provided
- ✅ **Domain Model:** Conceptual entities, relationships, attributes
- ✅ **Business Rules:** 19 rules (BR-001 to BR-019) with priorities
- ✅ **Core Processes:** Trade capture, observation, coupon decision, settlement
- ✅ **Data Entities:** Trade, Underlying Asset, Observation, Coupon Decision, Cash Flow
- ✅ **API Resource Candidates:** Contracts, Parameters, Observations, Coupons, Cash Flows, Market Data
- ✅ **Non-Functional Requirements:** Available in non-functional.md
- ✅ **Glossary & Terminology:** Comprehensive definitions
- ✅ **Stakeholder Map:** Roles and responsibilities identified

---

## 4. SA Work Categories - Readiness Status

### 4.1 ✅ READY TO START (No Blockers)

The following SA activities can **begin immediately**:

#### A. API Design
**Status:** ✅ Ready to start

**Available Inputs:**
- API resource candidates from integrations.md
- Business operations defined for each resource
- Minimal required fields documented
- CRUD operations scoped

**SA Actions:**
1. Create OpenAPI/Swagger specifications for:
   - `/contracts` resource
   - `/parameters/validation` resource
   - `/observations` resource
   - `/coupons` resource
   - `/cash-flows` resource
2. Define HTTP methods, status codes, error responses
3. Design pagination, filtering, sorting strategies
4. Document authentication/authorization requirements

**Dependencies:** None

**Deliverables:**
- OpenAPI 3.0 specification file(s)
- API design documentation
- Error handling strategy document

---

#### B. Data Model Design
**Status:** ✅ Ready to start

**Available Inputs:**
- Conceptual ER diagram in domain handoff
- Entity definitions with attributes
- Business rules constraining data integrity
- Parameter schema references

**SA Actions:**
1. Design physical database schema:
   - Table definitions
   - Column types and constraints
   - Primary and foreign keys
   - Indexes for performance
2. Map conceptual model to database technology (PostgreSQL, MongoDB, etc.)
3. Design audit/history tables
4. Define data retention policies

**Dependencies:** None (technology choice may need approval)

**Deliverables:**
- Physical database schema (DDL scripts)
- Data model documentation
- Migration strategy document

---

#### C. Integration Architecture
**Status:** ✅ Ready to start

**Available Inputs:**
- System actors identified (trade capture, market data, pricing, settlement)
- Integration touchpoints defined
- Business processes mapped

**SA Actions:**
1. Design integration patterns for:
   - Trade booking system integration
   - Market data provider integration
   - Settlement system integration
   - Reporting system integration
2. Define message formats and protocols
3. Create integration sequence diagrams
4. Design error handling and retry logic

**Dependencies:** None (external system details may need clarification)

**Deliverables:**
- Integration architecture document
- Sequence diagrams
- Message format specifications
- Integration ADRs

---

#### D. Security Architecture
**Status:** ✅ Ready to start

**Available Inputs:**
- Classification: Internal
- PII considerations mentioned
- RBAC requirements implied

**SA Actions:**
1. Design authentication/authorization model
2. Define API security (OAuth2, JWT, API keys)
3. Design data encryption strategy
4. Create security ADR

**Dependencies:** None (organizational security standards may need input)

**Deliverables:**
- Security architecture document
- Authentication/authorization design
- Security ADR

---

### 4.2 ⚠️ PARTIALLY READY (Minor Blockers)

These activities can start but require **specific decisions** to complete:

#### E. Idempotency Implementation Design
**Status:** ⚠️ Needs decision

**Blocker:** **OQ-BR-002** - "DB vs application enforcement for idempotency (BR-007)?"

**Impact:** Medium - Affects BR-007 (observation processing idempotency)

**SA Actions Available:**
1. Document both implementation options:
   - Option A: Database unique constraint
   - Option B: Application-level locking
2. Create comparison table (pros/cons)
3. Recommend preferred approach

**SA Action Blocked:**
- Final implementation specification

**Recommendation:** SA should analyze both options and make architectural decision, then document in ADR. This falls within SA responsibility and can be resolved without BA.

---

#### F. Historical Observation Replay
**Status:** ⚠️ Needs decision

**Blocker:** **OQ-API-003** - "Should historical observation replay be supported for backdated trades?"

**Impact:** Medium - Affects API design complexity

**SA Actions Available:**
1. Design API with/without replay capability
2. Document complexity and cost implications
3. Recommend approach

**SA Action Blocked:**
- Final API endpoint specification for replay

**Recommendation:** SA should assess technical feasibility and cost, then collaborate with BA/Product Owner for final decision.

---

#### G. Market Data Source Architecture
**Status:** ⚠️ Needs decision

**Blocker:** **OQ-API-005** - "Should market data resource be internal service or external integration?"

**Impact:** High - Affects integration architecture

**SA Actions Available:**
1. Design both architectural options
2. Analyze trade-offs (data sovereignty, latency, cost, reliability)
3. Recommend preferred approach

**SA Action Blocked:**
- Final integration architecture specification

**Recommendation:** This is a core SA responsibility. SA should analyze options and make architectural decision based on organizational constraints, then document in ADR.

---

### 4.3 🔄 COLLABORATIVE (Requires BA/SA Joint Work)

These items require **joint resolution** between BA and SA:

#### H. Contract Amendment Support
**Status:** 🔄 Collaborative decision

**Item:** **OQ-API-001** - "Should contract amendments be supported in v1.0 (PUT /contracts/{id})?"

**Impact:** High - Affects API scope, data model, business rules

**Why Collaborative:**
- Business implications (trade amendment policies)
- Technical complexity (audit trail, validation)
- Regulatory considerations

**Recommendation:** 
1. SA provides technical assessment (complexity, effort, risk)
2. BA provides business justification and rules
3. Product Owner makes final scope decision
4. Document decision in ADR

---

## 5. Open Questions Summary - SA Responsibility

| ID | Question | SA Can Resolve? | Priority | Recommendation |
|----|----------|-----------------|----------|----------------|
| OQ-BR-002 | DB vs application enforcement for idempotency | ✅ Yes | P0 | SA decides & documents ADR |
| OQ-API-003 | Historical observation replay support | ⚠️ Partial | P1 | SA assesses, BA/PO decides |
| OQ-API-005 | Market data resource internal vs external | ✅ Yes | P0 | SA decides & documents ADR |
| OQ-API-001 | Contract amendment support in v1.0 | 🔄 Joint | P1 | Joint BA/SA/PO decision |

---

## 6. Recommended SA Work Plan

Based on the readiness assessment, the following work plan is recommended:

### Phase 1: Immediate Start (Week 1-2)
**No dependencies - begin immediately:**

1. ✅ Review all BA handoff artifacts
2. ✅ Create OpenAPI specification for core resources
3. ✅ Design physical database schema
4. ✅ Document integration architecture patterns
5. ✅ Create security architecture document

**Deliverables:**
- OpenAPI 3.0 spec (draft v0.1)
- Database schema DDL (draft v0.1)
- Integration architecture diagram
- Security ADR

---

### Phase 2: Decision Making (Week 2-3)
**Resolve architectural decisions:**

1. ⚠️ Analyze and decide **OQ-BR-002** (idempotency approach)
   - Document analysis
   - Create ADR-005 (Idempotency Implementation Strategy)
2. ⚠️ Analyze and decide **OQ-API-005** (market data architecture)
   - Document analysis
   - Create ADR-006 (Market Data Integration Architecture)
3. ⚠️ Assess **OQ-API-003** (historical replay)
   - Technical feasibility report
   - Recommend to BA/PO for scope decision

**Deliverables:**
- ADR-005: Idempotency Implementation Strategy
- ADR-006: Market Data Integration Architecture
- Technical assessment: Historical Replay Support

---

### Phase 3: Refinement (Week 3-4)
**Complete designs based on decisions:**

1. ✅ Finalize API specification (incorporate decisions)
2. ✅ Finalize database schema (incorporate idempotency design)
3. ✅ Complete integration sequence diagrams
4. ✅ Create infrastructure architecture diagram
5. ✅ Document deployment architecture

**Deliverables:**
- OpenAPI 3.0 spec (v1.0)
- Database schema DDL (v1.0)
- Infrastructure architecture document
- Deployment guide

---

### Phase 4: Peer Review (Week 4-5)
**SA Lifecycle Stage 3:**

1. ✅ Submit for Peer Architecture Review
2. ✅ Address review comments
3. ✅ Cross-functional review with Dev Lead, Ops, Security
4. ✅ Finalize all architectural artifacts

**Deliverables:**
- Reviewed and approved architecture artifacts
- Implementation readiness checklist

---

## 7. Prerequisites and Dependencies

### 7.1 Information Available ✅
- [x] Business requirements (specs, rules)
- [x] Domain model
- [x] Business processes
- [x] API resource candidates
- [x] Non-functional requirements
- [x] Test vectors roadmap

### 7.2 Decisions Needed ⚠️
- [ ] Idempotency implementation approach (OQ-BR-002) - **SA decides**
- [ ] Market data architecture (OQ-API-005) - **SA decides**
- [ ] Historical replay support (OQ-API-003) - **SA assesses, BA/PO decides**
- [ ] Contract amendments in v1.0 (OQ-API-001) - **Joint decision**

### 7.3 External Inputs Helpful (Not Blocking) 💡
- Database technology preference (PostgreSQL, MongoDB, etc.)
- Cloud infrastructure platform (AWS, Azure, GCP)
- Organizational security standards
- API gateway/management platform
- Monitoring and observability tools

---

## 8. Risk Assessment

### 8.1 Low Risk Items ✅
**SA can proceed confidently:**
- API design foundations (RESTful patterns are standard)
- Data model design (domain model is clear)
- Security architecture (standard patterns apply)
- Integration patterns (well-defined touchpoints)

### 8.2 Medium Risk Items ⚠️
**May require iteration:**
- Idempotency implementation (needs careful design)
- Market data integration (depends on external system capabilities)
- Historical replay (complexity vs value trade-off)

### 8.3 Mitigation Strategy
1. **Document assumptions clearly** in all architectural artifacts
2. **Create ADRs** for key decisions to enable future review
3. **Design for flexibility** where requirements may change
4. **Prototype critical components** (e.g., idempotency mechanism)
5. **Maintain regular sync** with BA and stakeholders

---

## 9. Success Criteria

SA work will be considered successful when:

### 9.1 Deliverables Complete
- [x] All Phase 1 deliverables created
- [ ] All Phase 2 decisions documented
- [ ] All Phase 3 artifacts finalized
- [ ] Peer architecture review passed
- [ ] Cross-functional review passed

### 9.2 Quality Gates
- [ ] API design follows RESTful best practices
- [ ] Database schema normalized and performant
- [ ] Integration architecture addresses failure scenarios
- [ ] Security architecture meets organizational standards
- [ ] All decisions documented in ADRs
- [ ] Traceability to business rules maintained

### 9.3 Readiness for Implementation
- [ ] Backend engineers can begin implementation
- [ ] Data engineers can create ETL pipelines
- [ ] QA engineers can create API test cases
- [ ] Ops engineers can prepare infrastructure

---

## 10. Conclusion

### Answer to Original Question

**"From current status, is it possible to do job in role SA?"**

**YES.** The SA role **CAN and SHOULD begin work immediately.**

### Rationale

1. **Sufficient Information:** The BA Domain Handoff Package provides all necessary inputs for SA to start architectural design.

2. **Clear Scope:** Business requirements, rules, and processes are well-defined.

3. **Minor Blockers Only:** Open questions are either:
   - Within SA authority to resolve (OQ-BR-002, OQ-API-005)
   - Can be worked around while awaiting decision (OQ-API-003, OQ-API-001)

4. **Standard Stage Transition:** Moving from BA handoff to SA draft models is the expected workflow per SA lifecycle.

### Recommendation

**The SA should:**
1. ✅ **Immediately begin** Phase 1 work (API design, data model, integration architecture)
2. ✅ **Resolve** architectural decisions within SA authority (OQ-BR-002, OQ-API-005)
3. ⚠️ **Collaborate** with BA/PO on scope decisions (OQ-API-001, OQ-API-003)
4. ✅ **Document** all decisions in ADRs for transparency
5. ✅ **Maintain** regular communication with BA to clarify any ambiguities

**There is no reason to wait.** The current documentation state fully enables SA work to proceed.

---

## 11. Next Actions

### For SA (Immediate)
1. Review domain-handoff-fcn-v1.0.md thoroughly
2. Set up SA working branch
3. Begin OpenAPI specification draft
4. Begin database schema design
5. Schedule kickoff with peer architects

### For BA (Support)
1. Make yourself available for SA clarification questions
2. Participate in joint decisions (OQ-API-001)
3. Provide business context for technical trade-offs

### For Product Owner
1. Prepare for scope decisions (OQ-API-001, OQ-API-003)
2. Review SA architecture proposals when ready
3. Approve ADRs affecting business capabilities

---

## 12. References

- [Domain Handoff Package](handoff/domain-handoff-fcn-v1.0.md)
- [SA Document Lifecycle](../../lifecycle/sa-lifecycle.md)
- [BA Document Lifecycle](../../lifecycle/ba-lifecycle.md)
- [FCN v1.0 Overview](../ba/products/structured-notes/fcn/overview.md)
- [FCN v1.0 API Integration Resources](../ba/products/structured-notes/fcn/integrations.md)
- [FCN v1.0 Business Rules](../ba/products/structured-notes/fcn/business-rules.md)
- [Roles and Responsibilities](../../_policies/roles-and-responsibilities.md)

---

## 13. Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-10 | copilot | Initial readiness assessment created |
