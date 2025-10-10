---
title: FCN Stakeholders & Actors
version: 0.1.0-draft
status: draft
owner: BA
updated: 2025-10-10
tags: [fcn, stakeholders]
---

# Stakeholders & Actors

## 1. Stakeholder Register
| Role / Group | Description / Interest | Influence (H/M/L) | Interest (H/M/L) | Primary Contact | Notes |
|--------------|-----------------------|-------------------|------------------|-----------------|-------|
| Structuring Desk | Defines product terms | H | H | TBD | Originators |
| Trading / Execution | Books trades | H | M | TBD | |
| Risk Control | Validates risk parameters | H | H | TBD | |
| Operations | Lifecycle events, settlements | M | H | TBD | |
| Compliance | Regulatory classification | H | M | TBD | |
| IT Architecture | API & data model design | H | H | TBD | |
| Data Management | Reference & master data | M | M | TBD | |

## 2. Actor Definitions
| Actor | Type (Human/System) | Responsibilities | Triggers / Interactions |
|-------|---------------------|------------------|-------------------------|
| Structurer | Human | Captures FCN terms | Create FCN |
| Validation Engine | System | Applies schema + business rules | On submission |
| Lifecycle Monitor | System | Observes market events | Scheduled / event-driven |

## 3. RACI (Illustrative)
| Activity | Structurer | Risk | Ops | Architecture | Compliance |
|----------|-----------|------|-----|-------------|-----------|
| Define Parameters | R | C | C | C | I |
| Approve Rules | C | A | C | C | R |
| Schema Versioning | C | C | C | A | I |

Legend: R = Responsible, A = Accountable, C = Consulted, I = Informed

## 4. Communication Cadence
| Forum | Participants | Purpose | Frequency |
|-------|-------------|---------|-----------|
| Domain Sync | BA + SA + Risk | Clarify rules & data | Weekly |
| Design Review | SA + Architecture | Approve API/data | Ad hoc |
| Issue Triage | BA + Dev | Resolve blocking questions | 2x Weekly |

## 5. Open Stakeholder Issues
| ID | Issue | Owner | Due | Status |
|----|-------|-------|-----|--------|
| STK-01 | Identify compliance SME | BA | TBD | Open |