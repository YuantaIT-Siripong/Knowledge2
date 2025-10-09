---
title: Document Control Policy
doc_type: policy
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
status: Draft
version: 0.1.0
created: 2025-10-09
last_reviewed: 2025-10-09
next_review: 2026-10-09
classification: Internal
tags: [governance, policy, documentation]
---

# Document Control Policy

## 1. Purpose
Establish standardized governance to ensure accuracy, currency, and trustworthiness of knowledge base documents.

## 2. Scope
Applies to all files under `docs/` except templates, archives, and automation scripts.

## 3. Definitions
- **Document**: Any governed Markdown file with YAML front matter.
- **Owner**: Role/team responsible for accuracy and recertification.
- **Approver**: Authorized individual/role granting publishing approval.
- **Status**: One of: Draft, In Review, Approved, Published, Superseded, Archived.
- **Version**: Semantic‐style MAJOR.MINOR.PATCH (see Section 7).
- **Recertification**: Scheduled review to validate continued correctness.

## 4. Roles & Responsibilities
| Role | Responsibilities |
|------|------------------|
| Author | Drafts/updates content, ensures metadata completeness. |
| Peer Reviewer | Validates clarity, completeness, consistency. |
| Approver | Final quality gate; ensures compliance with policy. |
| Document Steward | Maintains taxonomy & standards. |
| Knowledge Base Maintainer | Maintains validation & automation scripts. |
| Security Reviewer | Reviews classification changes & security-impacting docs. |
| BA Lead | Ensures BA docs recertified. |
| Architecture Reviewer | Ensures architectural consistency. |

## 5. Document Types
`policy`, `process`, `requirement-set`, `use-case`, `business-rule`, `architecture`, `interface-spec`, `decision-record`, `glossary`, `playbook`, `lifecycle`, `reference`.

## 6. Classification Levels
| Level | Description | Distribution |
|-------|-------------|-------------|
| Public | Safe for external visibility. | Unrestricted |
| Internal | Internal staff only. | Employees |
| Confidential | Sensitive operational/business detail. | Need-to-know |
| Restricted | Highly sensitive (security, legal). | Limited individuals |

Default: Internal.

## 7. Versioning
- **MAJOR**: Structural/meaningful changes altering decisions or processes.
- **MINOR**: Additions that do not invalidate prior meaning.
- **PATCH**: Typos, formatting, minor clarifications.

## 8. Status Workflow
Draft → In Review → Approved → Published → (Superseded | Archived)

- **Superseded**: Replaced by newer doc (link via `superseded_by`).
- **Archived**: No longer relevant; immutable snapshot moved under `archive/`.

## 9. Review & Recertification Cadence
| Doc Type | Cadence |
|----------|---------|
| process, business-rule | 6 months |
| requirement-set | Per release or 6 months |
| architecture (context, logical) | 4 months |
| interface-spec | On change or 4 months |
| decision-record | Annual touch (confirm still valid) |
| policy | 12 months |

Automation will flag overdue `next_review` dates.

## 10. Change Request Process
- **Minor change**: Direct PR, at least 1 approver sign-off.
- **Major change**: Open Issue with impact rationale; require designated Approver + domain reviewer.
- **Breaking decision change**: New ADR; mark old ADR Superseded.

## 11. Archiving
Criteria: deprecated system/process, replaced model, or obsolete policy.  
Procedure:
1. Update status to Superseded or Archived.
2. Move file to `docs/archive/YYYY/` retaining original file name.
3. Update `docs/_meta/index.yml`.

## 12. Exceptions
Submit Issue labeled `exception-request` including justification, scope, duration.

## 13. Automation Roadmap (Informative)
1. Front matter schema validation.
2. ADR numbering enforcement.
3. Stale review check.
4. Link integrity scanning.
5. Classification consistency check.

## 14. Non-Compliance
Repeated non-compliance escalated; merges may be blocked via CI.

## 15. Related Documents
- `taxonomy-and-naming.md`
- `roles-and-responsibilities.md`
- `tagging-schema.md`