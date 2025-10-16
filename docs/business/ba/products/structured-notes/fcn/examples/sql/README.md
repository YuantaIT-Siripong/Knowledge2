---
title: FCN SQL Examples
doc_type: reference
status: Draft
version: 1.0.0
owner: siripong.s@yuanta.co.th
created: 2025-10-16
last_reviewed: 2025-10-16
classification: Internal
tags: [fcn, sql, examples, scenarios, templates, trades]
related:
  - ../../business-rules.md
  - ../../coupon-rate-conversion.md
  - ../../migrations/sqlserver/m0009-fcn-template-schema.sql
  - ../../migrations/sqlserver/m0010-fcn-template-validation.sql
  - ../../migrations/sqlserver/m0011-fcn-trade-link-template.sql
---

# FCN SQL Examples

## 1. Purpose

This directory contains SQL Server example scripts demonstrating FCN (Fixed Coupon Note) product templates and trade instance creation. The examples align with the two-layer data model introduced in migrations m0009–m0011, separating reusable product shelf templates from individual trade instances.

**Primary Goals**:
- Illustrate how to define FCN product templates with step-down knock-out barriers, settlement configurations, and observation schedules
- Show how to instantiate trades from templates while maintaining lineage
- Provide reference scenarios covering key FCN payoff patterns (physical loss, KI no loss, baseline, tie-break, autocall equality)
- Serve as executable documentation for DEV/SANDBOX environments

## 2. Directory Structure

```
examples/sql/
├── README.md                           # This file
├── fcn-example-physical-loss.sql       # Scenario: Physical worst-of settlement with capital loss
├── fcn-example-ki-no-loss.sql          # Scenario: Knock-in triggered but no loss (par recovery)
├── fcn-example-baseline.sql            # Scenario: Standard FCN without autocall or KI
├── fcn-example-tie-break.sql           # Scenario: Multiple underlyings at identical levels
├── fcn-example-autocall-equality.sql   # Scenario: Autocall barrier exactly met
└── (future scripts as needed)
```

**Note**: The scenario script files referenced above are placeholders for future development. This README establishes the structure and usage patterns.

## 3. Template vs Trade Flow

### Template Layer (Product Shelf)

Templates define reusable product structures with standardized parameters:
- **fcn_template**: Core product metadata (tenor, barriers, coupon settings, settlement type, step-down config)
- **fcn_template_underlying**: Basket composition (underlying codes, weights)
- **fcn_template_observation_schedule**: Observation dates with optional step-down KO barriers

Templates serve as blueprints for generating multiple trades with consistent parameters.

### Trade Layer (Instance)

Trades are individual booking instances:
- **fcn_trade**: Trade-specific details (notional, trade date, issue date, actual underlying fixings, counterparty)
- **template_id**: Optional foreign key linking trade to its source template for lineage and audit

**Relationship**:
```
Template (1) ----< Trade (N)
   |
   ├── Template Underlying (N)
   └── Template Observation Schedule (N)
```

**Workflow**:
1. Define template with product parameters
2. Add underlying basket composition
3. Add observation schedule (autocall/coupon/maturity dates)
4. Validate template (step-down barriers, maturity flag, weight sum)
5. Activate template (status = 'Active')
6. Create trade instances referencing template_id
7. Populate trade-specific data (notional, fixings, counterparty)

## 4. Scenario Scripts Summary

The following table outlines the planned scenario scripts. Each script demonstrates a specific FCN payoff behavior and edge case.

| Script Name                        | Scenario Description                                                                 | Key Features                                                                 | Business Rules Tested          |
|------------------------------------|--------------------------------------------------------------------------------------|------------------------------------------------------------------------------|--------------------------------|
| `fcn-example-physical-loss.sql`    | Physical worst-of settlement with capital loss at maturity                           | `settlement_type='physical-worst-of'`, `recovery_mode='capital-at-risk'`     | BR-025A, BR-003, BR-005        |
| `fcn-example-ki-no-loss.sql`       | Knock-in triggered but final level above put strike (par recovery)                  | `recovery_mode='par-recovery'`, KI barrier breached, final > put strike      | BR-005, BR-010, BR-003         |
| `fcn-example-baseline.sql`         | Standard FCN without autocall or knock-in (all coupons paid, par redemption)        | No `knock_out_barrier_pct`, all observations above thresholds                | BR-006, BR-007, BR-001         |
| `fcn-example-tie-break.sql`        | Multiple underlyings at identical levels (worst-of selection when tied)             | Two underlyings at exact same performance                                    | BR-005, BR-006, tie-break logic|
| `fcn-example-autocall-equality.sql`| Autocall barrier exactly met (boundary condition testing)                            | Final level = `initial × knock_out_barrier_pct` (exact match)                | BR-020, BR-021, boundary test  |

**Status**: Scripts are currently placeholders. Implementation will follow this README once approved.

## 5. Execution Workflow (DEV/SANDBOX)

### Prerequisites

1. **Database Setup**: SQL Server instance (2019+ recommended)
2. **Schema Migrations**: Apply migrations in order:
   - `m0009-fcn-template-schema.sql`
   - `m0010-fcn-template-validation.sql`
   - `m0011-fcn-trade-link-template.sql`
3. **Permissions**: User requires `CREATE TABLE`, `CREATE PROCEDURE`, `INSERT`, `UPDATE` permissions

### Execution Steps

```sql
-- Step 1: Apply schema migrations (if not already applied)
:r migrations/sqlserver/m0009-fcn-template-schema.sql
GO
:r migrations/sqlserver/m0010-fcn-template-validation.sql
GO
:r migrations/sqlserver/m0011-fcn-trade-link-template.sql
GO

-- Step 2: Verify tables created
SELECT name FROM sys.tables WHERE name LIKE 'fcn_template%' OR name = 'fcn_trade';
GO

-- Step 3: Run scenario scripts
:r examples/sql/fcn-example-baseline.sql
GO
:r examples/sql/fcn-example-physical-loss.sql
GO
-- (continue with other scenarios as needed)

-- Step 4: Verify data
SELECT template_code, status FROM fcn_template;
SELECT trade_code, template_id FROM fcn_trade;
GO
```

### Verification Queries

```sql
-- Check template validation status
EXEC usp_FCN_ValidateTemplate @template_id = '<template-guid>';

-- Find trades linked to a template
SELECT t.*
FROM fcn_trade t
INNER JOIN fcn_template tpl ON t.template_id = tpl.template_id
WHERE tpl.template_code = 'FCN-BASELINE-2025';

-- Verify observation schedules
SELECT 
    tpl.template_code,
    obs.observation_type,
    obs.observation_offset_months,
    obs.step_down_ko_barrier_pct,
    obs.is_maturity
FROM fcn_template_observation_schedule obs
INNER JOIN fcn_template tpl ON obs.template_id = tpl.template_id
ORDER BY tpl.template_code, obs.observation_offset_months;
```

## 6. Safety & Idempotency

### Idempotency Caution

**WARNING**: Unlike the schema migrations (m0009–m0011), the scenario scripts are **NOT fully idempotent**. Running them multiple times may result in:
- Duplicate templates with unique GUIDs (different `template_id` for same `template_code`)
- Duplicate trades with incremented trade codes
- Constraint violations if unique constraints exist on `template_code` or `trade_code`

### Recommended Practices

1. **Clean State**: Run scenarios in a fresh DEV/SANDBOX environment or use transactions:
   ```sql
   BEGIN TRANSACTION;
   -- Run scenario script
   -- Verify results
   ROLLBACK TRANSACTION;  -- Or COMMIT if satisfied
   ```

2. **Manual Cleanup**: Before re-running scenarios:
   ```sql
   -- Delete trades first (due to FK constraint)
   DELETE FROM fcn_trade WHERE template_id IN (
       SELECT template_id FROM fcn_template WHERE template_code LIKE 'FCN-EXAMPLE-%'
   );
   
   -- Delete templates
   DELETE FROM fcn_template WHERE template_code LIKE 'FCN-EXAMPLE-%';
   ```

3. **Conditional Insert**: Use `IF NOT EXISTS` checks in scripts:
   ```sql
   IF NOT EXISTS (SELECT 1 FROM fcn_template WHERE template_code = 'FCN-EXAMPLE-001')
   BEGIN
       INSERT INTO fcn_template (...) VALUES (...);
   END
   ```

4. **Test Isolation**: Use unique suffixes or timestamps in template codes:
   ```sql
   -- Example: FCN-EXAMPLE-001-20251016
   ```

### Migration vs Example Scripts

| Aspect              | Migrations (m0009–m0011)          | Scenario Scripts                     |
|---------------------|-----------------------------------|--------------------------------------|
| Idempotency         | Fully idempotent (safe to re-run) | Not idempotent (use transactions)    |
| Purpose             | Schema definition                 | Sample data / documentation          |
| Production Use      | Applied to all environments       | DEV/SANDBOX only                     |
| Rollback Strategy   | Manual (DROP tables if needed)    | Transaction ROLLBACK or manual DELETE|

## 7. Future Extensions

### Planned Enhancements

1. **Scenario Scripts Implementation**:
   - Complete the five planned scenario scripts
   - Add edge cases (zero coupon, barrier at 100%, etc.)
   - Include data validation queries in each script

2. **Parametric Templates**:
   - Create reusable template generators with variable parameters
   - Support for tenor variations (6M, 12M, 18M)
   - Multi-currency templates

3. **Trade Lifecycle Examples**:
   - Observation processing (autocall, coupon payment)
   - Settlement calculation (physical vs cash)
   - Trade modification and cancellation workflows

4. **Performance Testing**:
   - Bulk template creation (100+ templates)
   - Trade generation from templates (1000+ trades)
   - Query optimization examples

5. **Integration Examples**:
   - JSON import/export for template definitions
   - API payload mapping to SQL schema
   - Reporting queries (by issuer, by tenor, by status)

### Contribution Guidelines

To add new scenario scripts:
1. Follow naming convention: `fcn-example-<scenario-name>.sql`
2. Include header comment block (purpose, scenario, expected outcome)
3. Use consistent template code prefix: `FCN-EXAMPLE-`
4. Document business rules tested
5. Add entry to scenario summary table (Section 4)
6. Include verification queries at end of script

## 8. References

### Related Documentation

- **Business Rules**: [business-rules.md](../../business-rules.md) - Authoritative validation and calculation rules (BR-001 through BR-025A)
- **Coupon Conversion**: [coupon-rate-conversion.md](../../coupon-rate-conversion.md) - Annual vs per-period rate conversion methodology
- **Spec Documents**: 
  - [fcn-v1.0.md](../../specs/fcn-v1.0.md) - Baseline FCN specification
  - [fcn-v1.1.0.md](../../specs/fcn-v1.1.0.md) - Autocall, put strike, capital-at-risk extensions
- **Schema Migrations**:
  - [m0009-fcn-template-schema.sql](../../migrations/sqlserver/m0009-fcn-template-schema.sql) - Template schema definition
  - [m0010-fcn-template-validation.sql](../../migrations/sqlserver/m0010-fcn-template-validation.sql) - Validation logic
  - [m0011-fcn-trade-link-template.sql](../../migrations/sqlserver/m0011-fcn-trade-link-template.sql) - Template-trade linkage

### External References

- **SQL Server Documentation**: [Microsoft SQL Server Docs](https://learn.microsoft.com/en-us/sql/)
- **Structured Notes Standards**: ISDA, FICN industry conventions
- **Yuanta Internal**: Product governance policies, risk management guidelines

## 9. Support and Feedback

For questions, issues, or enhancement requests:
- **Owner**: siripong.s@yuanta.co.th
- **Repository**: YuantaIT-Siripong/Knowledge2
- **Issue Tracker**: GitHub Issues (use tag `fcn-sql-examples`)

---

**Document Version**: 1.0.0  
**Last Updated**: 2025-10-16  
**Next Review**: 2026-04-16
