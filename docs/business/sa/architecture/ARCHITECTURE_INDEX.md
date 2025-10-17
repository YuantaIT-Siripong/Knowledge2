# Solution Architecture - Architecture Index

## Overview

This index provides a consolidated view of all Architecture Decision Records (ADRs) and their governance scope for the Knowledge2 repository. ADRs document significant architectural and design decisions affecting product specifications, documentation governance, versioning, and lifecycle management.

## Architecture Decision Records (ADRs)

| ADR | Title | Status | Decision Date | Scope | Key Topics |
|-----|-------|--------|---------------|-------|------------|
| [ADR-001](../design-decisions/adr-001-documentation-governance.md) | Documentation Governance Approach | Accepted | 2025-10-17 | Documentation Framework | Structured taxonomy, mandatory metadata, role-specific lifecycles, ADR transparency |
| [ADR-002](../design-decisions/adr-002-product-doc-structure.md) | Product Documentation Structure & Location | Accepted | 2025-10-17 | Product Knowledge | BA-oriented product subtree, doc_types (product-spec, test-vector), normative specs directory, supersession index placement |
| [ADR-003](../design-decisions/adr-003-fcn-version-activation.md) | FCN Version Activation & Promotion Workflow | Accepted | 2025-10-17 | Version Lifecycle | Promotion pipeline (Concept → Proposed → Active → Deprecated), activation checklist, reserved features governance, CI enforcement |
| [ADR-004](../design-decisions/adr-004-parameter-alias-policy.md) | Parameter Alias & Deprecation Policy | Accepted | 2025-10-17 | Naming & Aliases | 4-stage alias lifecycle, settlement_type canonicalization, future alias criteria, automation implementation roadmap |
| [ADR-005](../design-decisions/adr-005-supersession-lifecycle-enforcement.md) | Supersession & Lifecycle Enforcement | Accepted | 2025-10-17 | Specification Supersession | SUPERSEDED_INDEX.md governance, metadata validation rules, exception process, booking-time validation (BR-004 extension) |

## ADR Status Legend

- **Accepted**: Decision adopted and actively followed by teams
- **Draft**: Decision under review; not yet binding
- **Superseded**: Decision replaced by newer ADR (see superseded_by metadata)
- **Deprecated**: Decision no longer recommended but not formally superseded

## Cross-Cutting Themes

### Documentation Governance
- **ADR-001**: Foundation for structured, trustworthy documentation base
- **ADR-002**: Product documentation structure and lifecycle artifact placement

### Versioning & Lifecycle
- **ADR-003**: Version promotion workflow and activation gating
- **ADR-004**: Parameter naming and alias lifecycle management
- **ADR-005**: Specification supersession and enforcement

### Business Rules Integration
- **BR-004**: documentation_version validation (extended by ADR-005)
- **BR-022**: Issuer whitelist governance (v1.1.0+ requirement)
- **BR-020–BR-026**: v1.1.0 business rules requiring lifecycle tracking

## Current FCN Specification State

| Version | Status | Supersession Date | Active Since | Key Features |
|---------|--------|-------------------|--------------|--------------|
| v1.0 | Superseded | 2025-10-17 | 2025-10-09 | Baseline: memory/no-memory coupons, knock-in barrier, par-recovery |
| v1.1.0 | Active | N/A | 2025-10-17 | Autocall, issuer parameter, capital-at-risk settlement, barrier monitoring type |

See [SUPERSEDED_INDEX.md](../../ba/products/structured-notes/fcn/specs/SUPERSEDED_INDEX.md) for complete supersession history.

## CI/CD Pipeline Guidance

The following CI/CD enforcement rules are planned or in-progress to support ADR governance. Teams implementing CI pipelines should reference this guidance.

### Phase 1: Specification Validation (Planned 2026-Q1)

```yaml
# .github/workflows/spec-validation.yml
name: Specification Validation

on:
  pull_request:
    paths:
      - 'docs/business/ba/products/**/specs/*.md'
      - 'docs/business/ba/products/**/SUPERSEDED_INDEX.md'

jobs:
  validate-spec-version:
    runs-on: ubuntu-latest
    steps:
      - name: Check Superseded Version Usage
        run: |
          # Extract documentation_version from spec files
          # Check against SUPERSEDED_INDEX.md
          # Fail if new spec or template references superseded version
          
          echo "Validating specification versions..."
          
          # Example validation logic:
          # - Parse YAML front-matter from specs
          # - Extract documentation_version or spec_version
          # - Load SUPERSEDED_INDEX.md (JSON or markdown table)
          # - Reject if version found in superseded list without governance override flag
          
          # Pseudo-code:
          # if version in SUPERSEDED_INDEX and not governance_override_ticket_id:
          #   exit 1  # Block PR
          
      - name: Validate Supersession Metadata
        run: |
          # Check specs with status: Superseded have superseded_by field
          # Check specs with status: Active do NOT have superseded_by field
          # Verify supersedes chain is valid
          
          echo "Validating supersession metadata..."
          
          # Example checks:
          # - grep for 'status: Superseded' in specs
          # - Verify 'superseded_by:' field is present
          # - Verify referenced file exists
```

### Phase 2: Settlement Type & Alias Validation (Planned 2026-Q2)

```yaml
  validate-canonical-values:
    runs-on: ubuntu-latest
    steps:
      - name: Check Settlement Type Canonicalization
        run: |
          # Enforce settlement_type canonical value: 'physical-settlement'
          # Reject non-canonical values or deprecated aliases
          
          echo "Validating settlement_type canonicalization..."
          
          # Example validation:
          # grep -r "settlement_type.*:" specs/
          # Check values match canonical list
          # Fail if deprecated alias found
          
      - name: Validate Alias Usage
        run: |
          # Warn if deprecated parameter name appears
          # Fail if deprecated parameter used after stage 3 (ADR-004)
          
          echo "Validating parameter alias policy..."
          
          # Example checks:
          # - Load alias registry (from ADR-004 or conventions file)
          # - Scan specs for deprecated parameter names
          # - Check alias lifecycle stage
          # - Warn (stage 1-2) or Fail (stage 3+)
```

### Phase 3: Business Rule Coverage (Planned 2026-Q3)

```yaml
  validate-business-rule-coverage:
    runs-on: ubuntu-latest
    steps:
      - name: Check Test Vector Coverage
        run: |
          # Verify each normative business rule (BR-xxx) maps to at least one test vector
          # Enforce minimum coverage threshold (80%)
          
          echo "Validating business rule test coverage..."
          
          # Example validation:
          # - Parse business-rules.md for normative rules (Status: Draft, Normative Scope: Yes)
          # - Parse test vector files for BR-xxx references
          # - Calculate coverage percentage
          # - Fail if coverage < 80%
          
      - name: Block Reserved Features
        run: |
          # Reject commits introducing reserved features without ADR approval
          # Example: barrier_monitoring_type='continuous', mixed-settlement
          
          echo "Validating reserved feature governance..."
          
          # Example checks:
          # - grep for barrier_monitoring_type.*continuous
          # - grep for settlement_type.*mixed
          # - If found, check for ADR approval reference
          # - Fail if no approval documented
```

### Implementation Notes

- **Validation Scripts**: Store reusable validation scripts in `.github/scripts/` directory
- **Configuration**: Maintain allowed values and superseded version lists in `.github/config/` JSON files
- **Error Messages**: Provide clear error messages with links to relevant ADRs and governance documentation
- **Override Mechanism**: Support governance_override_ticket_id in spec metadata to bypass validations with explicit approval

## Automation Roadmap

| Phase | Target Date | Focus Area | Key Deliverables |
|-------|-------------|------------|------------------|
| Phase 1 | 2026-Q1 | Specification Version Validation | Superseded version gating, metadata validation |
| Phase 2 | 2026-Q2 | Canonical Values & Aliases | Settlement type enforcement, alias linter |
| Phase 3 | 2026-Q3 | Business Rule Governance | Test coverage validation, reserved feature guards |
| Phase 4 | 2026-Q4 | Activation Workflow Automation | Checklist status tracking, version promotion gates |

## Related Documentation

- [Document Control Policy](../../../_policies/document-control-policy.md): Repository-wide documentation governance
- [Tagging Schema](../../../_policies/tagging-schema.md): Metadata tagging conventions
- [FCN Business Rules](../../ba/products/structured-notes/fcn/business-rules.md): Business rule definitions and traceability
- [FCN v1.1.0 Specification](../../ba/products/structured-notes/fcn/specs/fcn-v1.1.0.md): Current active specification
- [SUPERSEDED_INDEX.md](../../ba/products/structured-notes/fcn/specs/SUPERSEDED_INDEX.md): FCN specification supersession tracking

## Maintenance

**Review Frequency**: Quarterly review of ADR index and CI/CD guidance  
**Owner**: Solution Architect (siripong.s@yuanta.co.th)  
**Last Updated**: 2025-10-17  
**Next Review**: 2026-01-17

## Change Log

| Date | Author | Change |
|------|--------|--------|
| 2025-10-17 | siripong.s@yuanta.co.th | Initial architecture index: documented 5 ADRs (001-005), CI/CD guidance, automation roadmap |
