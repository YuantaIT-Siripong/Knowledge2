# FCN Database Migrations

This directory contains database migration scripts for the Fixed Coupon Note (FCN) product schema.

## Current Schema (Recommended)

**For new environments, use the consolidated migration:**

- **`fcn_schema_consolidated_v1_1.sql`** - Single authoritative SQL Server schema for FCN v1.1
  - Full data model including issuer whitelist, template layer, and trade layer
  - Harmonized naming conventions (settlement_type: 'cash-settlement', 'physical-settlement')
  - Default recovery_mode: 'capital-at-risk'
  - Validation procedures and triggers included
  - Idempotent (safe to run multiple times)
  - Consolidates all functionality from legacy migrations m0001–m0004

## Template Layer Enhancements (SQL Server)

The `sqlserver/` subdirectory contains additional migrations for the template layer:

- **m0009-fcn-template-schema.sql** - Template layer tables (fcn_template, fcn_template_underlying, fcn_template_observation_schedule)
- **m0010-fcn-template-validation.sql** - Validation stored procedures and triggers
- **m0011-fcn-trade-link-template.sql** - Links trades to templates via template_id
- **m0012-fcn-template-harmonization.sql** - Harmonizes naming to align with canonical schema
- **m0012-fcn-template-harmonization-test.sql** - Test cases for harmonization

**Note:** These template migrations are complementary to the consolidated schema. Apply them after the consolidated migration if you need the template layer functionality.

## Legacy Migrations (Archive)

The `archive/` subdirectory contains obsolete incremental migrations that have been superseded by the consolidated schema:

- m0001-fcn-baseline.sql (OBSOLETE)
- m0002-fcn-v1_1-autocall-extension.sql (OBSOLETE)
- m0003-fcn-v1_1-put-strike-extension.sql (OBSOLETE)
- m0004-fcn-v1_1-capital-at-risk-recovery-mode.sql (OBSOLETE)

**These files are retained for historical audit purposes only. DO NOT apply them to new environments.**

## Migration Strategy

### For New Environments

1. Apply `fcn_schema_consolidated_v1_1.sql` on a clean SQL Server database
2. Optionally apply template layer migrations from `sqlserver/` if needed
3. Run `examples/sql/fcn-sample-product-insertion.sql` to test the schema

### For Existing Environments

If your environment already has FCN tables from legacy migrations:

- **DO NOT** run the consolidated migration (it may conflict with existing objects)
- Continue using incremental migrations if already applied
- Consider migrating to the consolidated schema in a future maintenance window

## Consolidation Rationale

The legacy incremental migrations (m0001–m0004) were consolidated into a single authoritative schema file for the following reasons:

1. **Simplified Deployment** - Single script for new environments instead of four separate migrations
2. **Harmonized Naming** - Consistent naming conventions across all schema objects
3. **Reduced Maintenance** - One file to update instead of tracking changes across multiple files
4. **Clear Defaults** - Explicit defaults for recovery_mode and settlement_type
5. **Complete Validation** - All business rules enforced through constraints and procedures

## Harmonized Naming Conventions

The consolidated schema uses standardized naming:

- **settlement_type**: 'cash-settlement', 'physical-settlement' (not 'cash' or 'physical-worst-of')
- **recovery_mode**: Default is 'capital-at-risk' (not 'par-recovery')
- **Share delivery**: Requires physical-settlement + capital-at-risk + put_strike_pct

## Testing

After applying migrations, verify with:

```sql
-- Check tables exist
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME LIKE 'fcn%'
ORDER BY TABLE_NAME;

-- Verify settlement_type values
SELECT DISTINCT settlement_type FROM fcn_template;

-- Verify recovery_mode default
SELECT name, definition 
FROM sys.default_constraints 
WHERE parent_object_id = OBJECT_ID('dbo.fcn_template')
  AND parent_column_id = (SELECT column_id FROM sys.columns 
                          WHERE object_id = OBJECT_ID('dbo.fcn_template') 
                          AND name = 'recovery_mode');
```

## Support

For questions or issues with migrations, contact:
- **Author**: siripong.s@yuanta.co.th
- **Documentation**: See `../business-rules.md` for business rules and constraints
