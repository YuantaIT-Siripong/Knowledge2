---
title: FCN Decision Log
version: 0.1.0-draft
status: draft
owner: BA
updated: 2025-10-10
tags: [fcn, decisions, adr]
---

# Decision Log (Lightweight ADRs)

| ID | Date | Decision | Options Considered | Rationale | Impact | Status |
|----|------|----------|--------------------|-----------|--------|--------|
| DEC-01 | 2025-10-10 | Store validation rules as JSON schema + supplemental rule table | Schema only; Code-only rules | Hybrid improves transparency | Affects validation design | Draft |
| DEC-02 | 2025-10-10 | Single currency support v1 | Multi-currency; single | Reduce complexity | Data model simplification | Draft |

## Pending Decisions
| ID | Topic | Needed By | Owner | Notes |
|----|-------|-----------|-------|-------|
| PDEC-01 | Event model vs. polling for lifecycle events | 2025-10-25 | Architecture | |