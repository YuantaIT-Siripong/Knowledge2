---
title: Taxonomy and Naming Standard
doc_type: policy
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
status: Draft
version: 0.1.0
created: 2025-10-09
last_reviewed: 2025-10-09
next_review: 2026-10-09
classification: Internal
tags: [taxonomy, naming, policy]
---

# Taxonomy and Naming Standard

## 1. Folder Naming
Use `lowercase-with-dashes`. Avoid abbreviations except widely accepted ones (e.g., `api`).

## 2. File Naming
- Stable docs: `short-descriptive-name.md`
- Time-sequenced decisions: `adr-###-short-title.md` (zero-padded, monotonic).
- Time-specific records (optional): `YYYY-MM-DD-short-title.md` where chronology matters.

## 3. ADR Numbering
Increment next integer. Former numbers never reused.

## 4. Document Types to Folders
| Type | Folder |
|------|--------|
| process | `docs/business/ba/processes/` |
| requirement-set | `docs/business/ba/requirements/` |
| use-case | `docs/business/ba/use-cases/` |
| business-rule | `docs/business/ba/business-rules/` |
| architecture | `docs/business/sa/architecture/<view>/` |
| interface-spec | `docs/business/sa/interfaces/` |
| decision-record | `docs/business/sa/design-decisions/` |
| glossary | `docs/_reference/` |
| lifecycle | `docs/lifecycle/` |
| policy | `docs/_policies/` |
| playbook | `docs/playbooks/` |
| reference | `docs/_reference/` |

## 5. Tagging
Tags reflect domain, discipline, thematic aspects. Avoid redundancy.

## 6. Glossary Terms
Add only if not duplicative; steward approval required.

## 7. Cross-Linking Convention
Use relative links.

## 8. Metadata Keys Consistency
`doc_type`, `owner`, `approver`, `status`, `version`, `created`, `last_reviewed`, `next_review`, `classification`, `tags`, optional: `related`, `supersedes`, `superseded_by`.

## 9. Diagrams
Store editable sources (`.drawio`, `.plantuml`, `.mermaid`) adjacent to `.md`.

## 10. Deprecation
Mark heading with `(Deprecated)` and set status to Superseded before archive move.
