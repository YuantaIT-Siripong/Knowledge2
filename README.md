# Knowledge Base Repository

This repository serves as the authoritative internal knowledge base.

## Objectives
- Single source of truth for business analysis (BA) and solution/software architecture (SA) artifacts.
- Enforced document governance (versioning, lifecycle, recertification).
- Discoverability via consistent taxonomy, metadata, and indexing.

## Structure (High Level)
```
docs/
  _policies/
  _templates/
  _reference/
  business/
    ba/
      processes/
      requirements/
      use-cases/
      business-rules/
    sa/
      architecture/
        context/
        logical/
        integration/
        security/
        infrastructure/
      design-decisions/
      interfaces/
  lifecycle/
  playbooks/
  reviews/
  archive/
  _meta/
scripts/
```

See `docs/_policies/document-control-policy.md` for governance, and `docs/playbooks/contribution-guide.md` for how to add or update documents.

## Quick Start
1. Create an Issue (label: `new-doc` or `doc-change`).
2. Use the correct template from `docs/_templates/`.
3. Fill YAML front matter completely.
4. Open a PR referencing the Issue.
5. Obtain required approvals per CODEOWNERS/policy.

## Core Principles
- Policy before content.
- Templates for consistency.
- Metadata drives automation.
- Lifecycles differ by role (BA vs SA).
- Decision transparency via ADRs.

## Index
Machine‑readable index lives in `docs/_meta/index.yml`.

## Classification
See `docs/_policies/document-control-policy.md` and `docs/_policies/tagging-schema.md`.

## FCN Product Database Schema

**Status**: Well-designed with operational parameter management

For the current status of FCN (Fixed Coupon Note) v1.0 database schema design:
- 📊 **[Executive Summary](FCN_DATABASE_SCHEMA_STATUS.md)** - Quick overview and key metrics
- 📋 **[Detailed Status Report](docs/business/ba/products/structured-notes/fcn/STATUS_REPORT.md)** - Comprehensive analysis
- 📈 **[Visual Summary](docs/business/ba/products/structured-notes/fcn/SCHEMA_VISUAL_SUMMARY.md)** - Diagrams and quick reference

**Quick Stats**:
- ✅ 24 parameters defined and validated (100% tests passing)
- ✅ 7 validators operational with CI/CD integration
- 📋 12 entities documented (1 implemented, 11 pending)
- 🎯 Next: Implement product catalog and trade management tables

See [db/README.md](db/README.md) for database setup and usage.
