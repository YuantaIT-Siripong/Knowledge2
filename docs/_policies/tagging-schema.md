---
title: Tagging Schema
doc_type: policy
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
status: Draft
version: 0.1.0
created: 2025-10-09
last_reviewed: 2025-10-09
next_review: 2026-10-09
classification: Internal
tags: [taxonomy, tags]
---

# Tagging Schema

## 1. Allowed doc_type Values
`policy`, `process`, `requirement-set`, `use-case`, `business-rule`, `architecture`, `decision-record`, `interface-spec`, `glossary`, `playbook`, `lifecycle`, `reference`.

## 2. Classification Values
`Public`, `Internal`, `Confidential`, `Restricted`.

## 3. Recommended Domain Tags
`customer`, `account`, `product`, `pricing`, `risk`, `compliance`, `reporting`, `integration`, `security`.

## 4. Discipline Tags
`process`, `requirements`, `architecture`, `design`, `data`, `api`, `messaging`, `security`.

## 5. Constraints
Max 8 tags; all lowercase; kebab-case if multi-word.

## 6. Validation
Automation will flag unknown tags; propose via Issue `tag-add-proposal`.
