# Solution Architecture (SA) Artifacts

This directory contains Solution Architecture artifacts for products and systems.

## Quick Status Check

**❓ Can SA begin work on FCN v1.0?**  
**✅ YES** - See [SA Work Readiness Assessment](sa-work-readiness-assessment.md) for detailed analysis.

## Directory Structure

```
sa/
├── README.md                           (this file)
├── sa-work-readiness-assessment.md     (readiness analysis for FCN v1.0)
├── architecture/                       (architectural views & diagrams)
├── design-decisions/                   (ADRs and decision records)
├── handoff/                            (domain handoff packages from BA)
└── interfaces/                         (API specs & integration contracts)
```

## Key Documents

### Readiness Assessment
- **[SA Work Readiness Assessment](sa-work-readiness-assessment.md)** - Comprehensive analysis of whether SA can begin work based on current BA handoff

### Domain Handoffs
- **[FCN v1.0 Domain Handoff Package](handoff/domain-handoff-fcn-v1.0.md)** - Complete handoff from BA to SA for Fixed Coupon Note v1.0

### Architecture Decision Records (ADRs)
- [ADR-001: Documentation Governance](design-decisions/adr-001-documentation-governance.md)
- [ADR-002: Product Document Structure](design-decisions/adr-002-product-doc-structure.md)
- [ADR-003: FCN Version Activation & Promotion Workflow](design-decisions/adr-003-fcn-version-activation.md)
- [ADR-004: Parameter Alias & Deprecation Policy](design-decisions/adr-004-parameter-alias-policy.md)

## Current Focus: FCN v1.0

### Status
The BA has completed the domain handoff for FCN (Fixed Coupon Note) v1.0. The SA role is **ready to begin** the following work:

✅ **Ready Now:**
- API Design (OpenAPI/Swagger specifications)
- Data Model Design (physical schema)
- Integration Architecture
- Security Architecture

⚠️ **Requires Decisions:**
- Idempotency implementation (OQ-BR-002) - SA to decide
- Market data architecture (OQ-API-005) - SA to decide
- Historical replay support (OQ-API-003) - Needs assessment

🔄 **Collaborative:**
- Contract amendment support (OQ-API-001) - BA/SA/PO joint decision

### Next Steps for SA

1. **Week 1-2:** Review handoff, create OpenAPI spec, design database schema
2. **Week 2-3:** Resolve architectural decisions, document in ADRs
3. **Week 3-4:** Finalize designs, complete architecture artifacts
4. **Week 4-5:** Peer architecture review

See [SA Work Readiness Assessment](sa-work-readiness-assessment.md) for complete details.

## Related Documentation

- [BA Artifacts](../ba/) - Business Analysis documents
- [SA Lifecycle](../../lifecycle/sa-lifecycle.md) - SA document lifecycle stages
- [BA Lifecycle](../../lifecycle/ba-lifecycle.md) - BA document lifecycle stages
- [Roles and Responsibilities](../../_policies/roles-and-responsibilities.md) - Role definitions

## Contact

- **Owner:** siripong.s@yuanta.co.th
- **Role:** Solution Architect / Architecture Reviewer
