---
title: SA Document Lifecycle
doc_type: lifecycle
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
status: Draft
version: 0.1.0
created: 2025-10-09
last_reviewed: 2025-10-09
next_review: 2026-02-09
classification: Internal
tags: [lifecycle, architecture]
---

# SA Document Lifecycle

## Stages
1. Driver Captured
2. Draft Models
3. Peer Architecture Review
4. Cross-Functional Review
5. Decision Recording (ADR)
6. Approval
7. Publication
8. Drift Detection
9. Refresh / Supersede

## ADR Criteria
Create ADR if change affects: cross-team dependencies, cost & capacity, security model, integration contracts, strategic quality attributes.

## Drift Detection
Quarterly review of diagrams vs. runtime inventory; issues opened for mismatches.

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
