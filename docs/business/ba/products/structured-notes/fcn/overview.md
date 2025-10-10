---
title: FCN Product Domain Overview
version: 0.1.0-draft
status: draft
owner: BA
updated: 2025-10-10
tags: [fcn, domain, overview]
---

# FCN (Fixed Coupon Note) – Domain Overview

## 1. Problem & Value Proposition
Describe the business problem FCN addresses, target clients, and value (e.g., revenue diversification, structured yield for investors).

## 2. Product Summary
Short narrative (2–3 sentences) describing FCN mechanics at a business level.

## 3. Target Users / Actors
- Investor Operations
- Structuring Desk
- Risk Control
- Regulatory Reporting
- External Market Data Provider

## 4. Success Metrics (Initial KPIs)
| KPI | Definition | Baseline | Target | Measurement Source |
|-----|------------|----------|--------|--------------------|
| Time-to-Launch | Days from term-sheet approval to system activation | TBD | TBD | Workflow logs |
| Parameter Error Rate | % trades rejected due to invalid parameters | TBD | < X% | Validation logs |
| Data Completeness | % mandatory attributes populated | TBD | > 99% | DB audit |

## 5. In Scope (v1)
- Example: Single-currency FCN issuance
- Memory / non-memory coupon logic
- Knock-in barrier events
- Coupon observation scheduling

## 6. Out of Scope (v1)
- Multi-currency settlement
- Exotic payoff variants (e.g., reverse convertible)
- Secondary lifecycle corporate actions

## 7. High-Level Capability Map
| Capability | Description | Included v1? | Notes |
|------------|-------------|--------------|-------|
| Product Parameter Capture | Capture FCN terms | Yes | Backed by JSON schema |
| Validation & Rules Engine | Enforce business rules | Yes | See business-rules.md |
| Event Scheduling | Generate observation / payment dates | Yes | |
| Lifecycle Monitoring | Track barrier / coupon events | Partial | Basic monitoring only |

## 8. Key Constraints / Drivers
- Regulatory classification of product type
- Need for auditable parameter provenance
- Performance: validation must be sub-second for desk workflow

## 9. Related Documents
- [Stakeholders](stakeholders.md)
- [Glossary](glossary.md)
- [Domain Model](domain-model.md)
- [Business Rules](business-rules.md)
- [Data Model](data-model.md)
- [Integrations](integrations.md)
- [Non-Functional Drivers](non-functional.md)
- [Decisions](decisions.md)
- [Open Questions](open-questions.md)

## 10. Assumptions
| ID | Assumption | Impact if False | Status |
|----|------------|-----------------|--------|
| A-01 | Single currency only in v1 | Data model may broaden | Open |

## 11. Revision History
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1.0-draft | 2025-10-10 | BA | Initial skeleton |