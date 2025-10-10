---
title: FCN v1.0 Glossary & Controlled Terms
doc_type: glossary
status: Draft
version: 1.0.0
owner: siripong.s@yuanta.co.th
approver: siripong.s@yuanta.co.th
created: 2025-10-10
last_reviewed: 2025-10-10
next_review: 2026-04-10
classification: Internal
tags: [fcn, glossary, terminology, structured-notes, v1.0]
related:
  - specs/fcn-v1.0.md
  - business-rules.md
  - er-fcn-v1.0.md
  - overview.md
  - ../../sa/handoff/domain-handoff-fcn-v1.0.md
  - ../../sa/design-decisions/adr-003-fcn-version-activation.md
  - ../../sa/design-decisions/adr-004-parameter-alias-policy.md
  - ../../sa/design-decisions/dec-011-notional-precision.md
---

# FCN v1.0 Glossary & Controlled Terms

This glossary defines canonical FCN v1.0 product, governance, and KPI terminology.  
Columns:
- **Term** – Canonical label (use “Term” spelling in docs & code comments).
- **Definition** – Authoritative meaning (first sentence stands alone).
- **Normative** – Yes = in-scope & enforced for v1.0; No = illustrative / deferred.
- **Source / Rule / Decision** – Primary reference (Spec section, BR-*, ADR, DEC).
- **Notes** – Clarifications, scope flags, or implementation hints.

> If a term changes meaning in future versions, record alias lifecycle per ADR-004 and update this table (new version row in Change Log).

## 1. Core Product Concepts

| Term | Definition | Normative | Source / Rule / Decision | Notes |
|------|------------|-----------|---------------------------|-------|
| Fixed Coupon Note (FCN) | Structured note paying periodic fixed coupons conditional on underlying performance and barrier conditions. | Yes | Spec §1 | Product family label. |
| Underlying | Asset (equity, index, etc.) whose performance drives coupons & KI. | Yes | Spec §3 | Basket allowed (equal-weight baseline). |
| Basket | Collection of multiple underlyings forming a single payoff unit. | Yes | Spec §3 | Equal-weight default unless weights supplied. |
| Knock-In (KI) | Event when any underlying breaches the knock-in barrier on an observation date. | Yes | BR-005 | Sets recovery context (par-recovery normative). |
| Knock-In Barrier (%) | Percentage of initial level defining KI breach threshold. | Yes | Spec §3 / BR-003 | Must be < redemption barrier. |
| Redemption Barrier (%) | Threshold tested at maturity to determine redemption conditions (par baseline). | Yes | Spec §3 / BR-003 | In v1.0 par-recovery yields same payout; future variants may diverge. |
| Coupon Condition Threshold (%) | Minimum fraction of initial level each underlying must meet for a coupon to be paid. | Yes | Spec §3 / BR-006 | Applied to all underlyings (ALL). |
| Memory Coupon | Feature allowing unpaid coupons to accumulate and pay later when condition satisfied. | Yes (optional) | BR-008, BR-009 | Controlled by `is_memory_coupon` and cap parameter. |
| Memory Carry Cap Count | Maximum number of unpaid coupons that can accrue (if set). | Yes (optional) | BR-008 | Null = unlimited accumulation. |
| Recovery Mode | Method for principal treatment after KI or at maturity. | Par only normative | Spec §3 / BR-011,012 | `par-recovery` normative; `proportional-loss` illustrative. |
| Par Recovery | Recovery mode returning 100% notional at maturity irrespective of KI. | Yes | BR-011 | Default simpler baseline risk profile. |
| Proportional Loss | Recovery mode delivering underlying exposure proportionally to performance. | No (illustrative) | BR-012 | Non-normative examples only. |
| Settlement Type | Method of final delivery (assets or cash). | Physical normative | Spec §3 / BR-012 | `physical-settlement` normative; cash illustrative. |
| Barrier Monitoring (Type) | Mechanism for evaluating barrier: discrete (scheduled dates) vs continuous (intraday). | Discrete only normative | Spec §3.1 | Continuous deferred (requires intraday data infra). |
| Knock-In Condition | Logical condition for KI evaluation across basket. | Yes | Spec §3.1 | Only `any-underlying-breach` in v1.0. |
| Observation Date | Scheduled date used for coupon condition and KI evaluation. | Yes | BR-007, BR-014 | Must be strictly increasing & < maturity. |
| Branch (Taxonomy Branch) | Canonical combination of payoff dimensions (e.g., memory vs non-memory). | Yes | Spec §6 | Drives normative test vector coverage requirements. |
| Normative Feature | Functionality required for promotion to Active status. | Yes | ADR-003 | Must have test vectors & validation coverage. |
| Non-Normative Feature | Illustrative or future-scope functionality not required for Active gating. | No | ADR-003 | May appear in examples; excluded from coverage metrics. |
| Documentation Version | Explicit spec version string tied to each trade for audit. | Yes | BR-004, BR-018 | Must match active product version. |

## 2. Parameters & Data Integrity

| Term | Definition | Normative | Source / Rule / Decision | Notes |
|------|------------|-----------|---------------------------|-------|
| Notional Amount | Principal amount used to compute coupon and redemption amounts. | Yes | Spec §3 | Positive > 0. |
| Notional Amount Precision | Currency-driven scale: 2 decimals standard; 0 for zero-decimal currencies. | Yes | DEC-011 / BR-019 | Enforced at validation ingress & persistence. |
| Zero-Decimal Currency | ISO currency without fractional minor units (e.g., JPY, KRW; future: VND, CLP). | Yes | DEC-011 | Extend list via config file. |
| Basket Weight | Relative weight assigned to an underlying in a basket. | Optional | BR-016 | Sum must equal 1.0 if provided; else equal-weight assumption. |
| Documentation Version Constraint | Validation ensuring `documentation_version` equals current active spec version. | Yes | BR-004 / BR-018 | Governance gate; mismatch blocks booking. |
| Parameter Schema | JSON Schema defining allowed fields, types, and constraints for a trade. | Yes | ADR-004 / BR-018 | Structural changes may require version increment. |
| Derived Field | Computed runtime field (e.g., `ki_triggered`, `coupon_amount`) not directly input. | Yes | Mapping Table | Must map to at least one business rule. |
| Observation Idempotency | Guarantee that each observation date is processed exactly once. | Yes | BR-007 | DB unique composite or application lock. |

## 3. Business Rules & Governance

| Term | Definition | Normative | Source / Rule / Decision | Notes |
|------|------------|-----------|---------------------------|-------|
| Business Rule (BR) | Canonically identified constraint or logic element controlling product behavior. | Yes | business-rules.md | IDs BR-001..BR-019 (zero-padded). |
| Validation Rule | Rule governing input integrity (ordering, ranges, presence). | Yes | BR-001..004, 014, 015, 019 | Enforced at API / parameter validation stage. |
| Business Logic Rule | Rule determining dynamic lifecycle behavior (KI, coupon, settlement). | Yes | BR-005..013 | Tested via simulation / test vectors. |
| Data Integrity Rule | Rule ensuring aggregate consistency (weights sum, referential cohesion). | Yes | BR-016 | Persistence-level or derived checks. |
| Governance Rule | Rule defining promotion, versioning, coverage thresholds. | Yes | BR-017, BR-018 | Gating criteria for Proposed → Active. |
| Precision Rule | Validation rule constraining numeric formatting per currency policy. | Yes | BR-019 / DEC-011 | Special-case rule category. |
| Activation Checklist | Structured set of evidence items required to promote version to Active status. | Yes | ADR-003 | Tracked by GitHub issue reference. |
| Alias Lifecycle | Process for introducing, co-existing, and deprecating parameter names. | Deferred | ADR-004 | No active aliases in v1.0 baseline. |

## 4. KPIs & Quality Metrics

| Term | Definition | Normative | Source / Rule / Decision | Notes |
|------|------------|-----------|---------------------------|-------|
| Time-to-Launch (KPI) | Elapsed time from spec approval to production readiness (checklist completion). | Yes | Overview KPIs / ADR-003 | Improvement target tracked each release. |
| Parameter Error Rate (KPI) | Rolling ratio of failed parameter validations over attempts (normative rules only). | Yes | Overview KPIs / BR-001..004,014,015,019 | Target < 2%. |
| Data Completeness (KPI) | % of normative branches with full test vector coverage. | Yes | Overview KPIs / BR-017 | Gate ≥ 80% for Active. |
| Rule Mapping Coverage (KPI) | % of normative rules mapped to at least one schema field or derived path + test vector. | Yes | Overview KPIs | Target 100%. |
| Precision Conformance (KPI) | % of payloads meeting notional precision policy. | Yes | Overview KPIs / DEC-011 / BR-019 | Target 100%. |
| Observation Idempotency Incidents (KPI) | Count of duplicate observation process attempts. | Yes | Overview KPIs / BR-007 | Target zero. |
| Test Vector Freshness (KPI) | Average age (days) since last update of normative test vectors. | Yes | Overview KPIs / BR-017 | Target ≤ 30 days. |
| KPI Snapshot | Aggregated JSON record of current KPI values & thresholds. | Deferred automation | Overview Roadmap | Will feed dashboard & alerting. |

## 5. Testing & Coverage

| Term | Definition | Normative | Source / Rule / Decision | Notes |
|------|------------|-----------|---------------------------|-------|
| Normative Test Vector | Required test case validating a normative branch & ruleset for activation gating. | Yes | BR-017 / ADR-003 | Listed N1–N5 baseline. |
| Negative Test Vector | Test intentionally violating rule(s) to confirm rejection. | Optional | Validator Strategy | Not counted toward normative coverage. |
| Coverage Matrix | Mapping of taxonomy dimensions to vector IDs demonstrating scenario breadth. | Yes | Spec §13 | Updated when new vectors added. |
| Coverage Metric (Rule→Vector) | Computed ratio of normative rules exercised by at least one vector. | Yes | Business Rules Mapping | Target 100% before Active promotion. |

## 6. Decisions & Architecture

| Term | Definition | Normative | Source / Rule / Decision | Notes |
|------|------------|-----------|---------------------------|-------|
| Architecture Decision Record (ADR) | Persistent record of architectural/governance decision & rationale. | Yes | ADR-003, ADR-004 | Immutable after acceptance (append change log). |
| DEC (Decision Record) | Product or data policy decision outside full ADR scope. | Yes | DEC-011 | Shares naming pattern DEC-###. |
| Version Promotion Workflow | Formal stages Draft → Proposed → Active → Deprecated → Removed. | Yes | ADR-003 | Status definitions documented in ER & spec. |
| Deprecation Timeline | Multi-phase process for retiring versions or parameters. | Yes | ADR-003 / ADR-004 | Provides migration window. |

## 7. Operational & Observability Terms

| Term | Definition | Normative | Source / Rule / Decision | Notes |
|------|------------|-----------|---------------------------|-------|
| Idempotent Processing | Guarantee that repeated identical observation processing does not alter final state beyond first successful execution. | Yes | BR-007 | Enables safe retry. |
| Validation Phase (Phase 2) | Stage executing parameter-level constraints (ordering, ranges, precision). | Yes | Validator Roadmap | Must pass before logical simulation. |
| Business Logic Validation (Phase 4) | Simulation stage executing coupon & redemption calculations for vector outputs. | Yes | Validator Roadmap | Ensures determinism & correctness. |
| Precision Audit Log | Structured log capturing precision validation outcomes (pass/fail). | Yes | KPI Infrastructure | Drives Precision Conformance KPI. |

## 8. Abbreviations

| Abbrev | Expansion | Notes |
|--------|-----------|-------|
| FCN | Fixed Coupon Note | Product name |
| KI | Knock-In | Event type |
| ADR | Architecture Decision Record | Governance artifact |
| DEC | Decision Record | Lightweight decision |
| KPI | Key Performance Indicator | Governance metric |
| SLA | Service Level Agreement | Non-functional metric boundary |
| ER | Entity-Relationship | Data modeling artifact |

## 9. Usage Guidelines

1. Always use canonical term forms in specification texts, code generation, and validator error messages.
2. Introduce new terms via PR adding a glossary entry (include Normative flag & reference).
3. For future alias introduction (v1.1+), maintain an “Aliases” subsection linking legacy term → new term with lifecycle stage.

## 10. Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-10 | siripong.s@yuanta.co.th | Initial glossary draft (core product, governance, KPI & decision terms) |

## 11. References

- [FCN v1.0 Specification](specs/fcn-v1.0.md)
- [Business Rules](business-rules.md)
- [Overview & KPIs](overview.md)
- [ER Model](er-fcn-v1.0.md)
- [Domain Handoff](../../sa/handoff/domain-handoff-fcn-v1.0.md)
- [ADR-003 Version Activation & Promotion Workflow](../../sa/design-decisions/adr-003-fcn-version-activation.md)
- [ADR-004 Parameter Alias & Deprecation Policy](../../sa/design-decisions/adr-004-parameter-alias-policy.md)
- [DEC-011 Notional Precision Policy](../../sa/design-decisions/dec-011-notional-precision.md)