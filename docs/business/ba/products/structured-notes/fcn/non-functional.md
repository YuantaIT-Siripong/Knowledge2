---
title: FCN Non-Functional Drivers
version: 0.1.0-draft
status: draft
owner: BA
updated: 2025-10-10
tags: [fcn, nfr]
---

# Non-Functional Requirements (Architecture-Relevant Only)

| ID | Category | Requirement (Draft) | Rationale | Priority | Status |
|----|----------|---------------------|-----------|----------|--------|
| NFR-01 | Performance | Validation API P95 < 800 ms | Desk workflow efficiency | Must | Draft |
| NFR-02 | Availability | Core API 99.5% monthly | Business continuity | Must | Draft |
| NFR-03 | Security | All data in transit TLS 1.2+ | Compliance | Must | Draft |
| NFR-04 | Auditability | Changes to parameters immutable log | Regulatory trace | Must | Draft |
| NFR-05 | Data Retention | FCN records retained 7 years | Regulation | Must | Draft |
| NFR-06 | Scalability | Support 5x projected daily trades without redesign | Growth | Should | Draft |
| NFR-07 | Observability | Emit structured events for validation outcomes | Monitoring | Should | Draft |

## Open NFR Questions
| ID | Question | Owner | Needed By | Status |
| ID | Question | Owner | Needed By | Status |
| NFRQ-01 | Confirm retention exact period | Compliance | 2025-10-18 | Open |