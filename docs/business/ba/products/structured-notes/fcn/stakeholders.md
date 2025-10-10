---
title: FCN v1.0 Stakeholder Register
doc_type: product-definition
status: Draft
version: 1.0.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-10
last_reviewed: 2025-10-10
next_review: 2026-04-10
classification: Internal
tags: [fcn, stakeholders, governance, contacts]
related:
  - ../../../sa/handoff/domain-handoff-fcn-v1.0.md
  - specs/fcn-v1.0.md
  - manifest.yaml
---

# FCN v1.0 Stakeholder Register

## Purpose
This document maintains the official stakeholder register for the Fixed Coupon Note (FCN) v1.0 product, including roles, responsibilities, primary contacts, and engagement levels. This register serves as the single source of truth for stakeholder communication and escalation paths.

## Scope
Covers all human stakeholders involved in FCN v1.0 product development, implementation, and operational lifecycle from requirements gathering through production support.

---

## Stakeholder Table

| Role | Responsibilities | Primary Contact | Interest Level | Engagement Type |
|------|------------------|-----------------|----------------|-----------------|
| Product Owner | Defines economic behavior, approves specification | siripong.s@yuanta.co.th | High | Decision Maker |
| Business Analyst | Documents requirements, validates test vectors | siripong.s@yuanta.co.th | High | Contributor |
| Solution Architect | Designs API & data model, defines integration | siripong.s@yuanta.co.th | High | Contributor |
| Backend Engineer | Implements pricing engine & lifecycle processing | engineering@yuanta.co.th | High | Implementer |
| Data Engineer | Implements persistence & reporting pipelines | data-engineering@yuanta.co.th | Medium | Implementer |
| Risk Manager | Reviews calibration scenarios & stress tests | risk@yuanta.co.th | Medium | Reviewer |
| Compliance Officer | Validates regulatory alignment & audit trails | compliance@yuanta.co.th | Medium | Reviewer |
| QA Engineer | Validates test coverage & regression suite | qa@yuanta.co.th | High | Validator |
| Front Office Trader | Books trades, monitors positions | trading@yuanta.co.th | Medium | End User |
| Middle Office Operations | Validates settlements & lifecycle events | operations@yuanta.co.th | Medium | End User |

---

## Open Stakeholder Issues

### ~~STK-01: Compliance SME Gap~~ (CLOSED)

**Status:** CLOSED (2025-10-10)

**Original Issue:**
Compliance Officer role identified but specific Subject Matter Expert (SME) contact not established for FCN v1.0 regulatory review.

**Resolution:**
Primary contact for Compliance Officer role established as `compliance@yuanta.co.th`. This contact serves as the entry point for:
- Regulatory alignment validation
- Audit trail requirements review
- Documentation compliance checks
- Escalation path for compliance-related questions (OQ-008)

**Assigned SME:** Compliance department team (compliance@yuanta.co.th)

**Follow-up Actions:**
- [ ] Schedule initial compliance review session (target: Week 7-8 per domain handoff)
- [ ] Confirm audit trail detail level requirements (resolve OQ-008)
- [ ] Validate regulatory reporting requirements for FCN product
- [ ] Review data retention and privacy requirements

---

## Engagement Guidelines

### Communication Channels
- **Email:** Primary contact addresses listed in stakeholder table
- **Documentation:** This repository (GitHub)
- **Issue Tracking:** GitHub Issues with appropriate stakeholder labels
- **Decision Records:** ADR documents in `docs/business/sa/design-decisions/`

### Escalation Path
1. **Level 1:** Direct contact with role-specific primary contact
2. **Level 2:** Product Owner (siripong.s@yuanta.co.th)
3. **Level 3:** Department head or executive sponsor

### Review Cadence
- **Weekly:** Product Owner, Business Analyst, Solution Architect (active development)
- **Bi-weekly:** Backend Engineer, Data Engineer, QA Engineer (implementation phase)
- **Monthly:** Risk Manager, Compliance Officer (review phase)
- **As-needed:** Front Office Trader, Middle Office Operations (UAT and operational readiness)

---

## System Actors (Non-Human)

For reference, the following system actors interact with FCN v1.0 but are not stakeholders in the governance sense:

- **Trade Capture System**: Sources trade bookings
- **Market Data Provider**: Delivers underlying levels for observations
- **Pricing Engine**: Computes valuations and payoff scenarios
- **Settlement System**: Processes cash flows and physical deliveries
- **Reporting System**: Generates client statements and risk reports
- **Audit Trail System**: Records all lifecycle events for compliance

---

## Related Open Questions

The following open questions from the domain handoff package involve specific stakeholders:

| Question ID | Question | Assigned Stakeholder | Target Date |
|-------------|----------|---------------------|-------------|
| OQ-003 | Business day adjustment convention for observation dates | Middle Office Operations | 2025-10-17 |
| OQ-007 | Test vector scope (positive vs. negative cases) | QA Engineer | 2025-10-20 |
| OQ-008 | Audit trail detail level for regulatory reporting | Compliance Officer | 2025-10-25 |

---

## Contact Update Process

To update stakeholder contact information:

1. Create a GitHub issue with label `stakeholder-update`
2. Specify role and new contact information
3. Obtain approval from Product Owner
4. Update this document via pull request
5. Notify affected parties of the change

---

## Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-10 | siripong.s@yuanta.co.th | Initial stakeholder register with primary contacts populated; STK-01 closed |

---

## References

- [FCN v1.0 Domain Handoff Package](../../../sa/handoff/domain-handoff-fcn-v1.0.md)
- [FCN v1.0 Specification](specs/fcn-v1.0.md)
- [Document Control Policy](../../../../_policies/document-control-policy.md)
