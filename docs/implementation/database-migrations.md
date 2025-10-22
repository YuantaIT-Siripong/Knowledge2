---
title: Database Migrations with Alembic
doc_type: implementation
status: Active
version: 1.0.0
date: 2025-10-22
owner: siripong.s@yuanta.co.th
classification: Internal
tags: [implementation, database, alembic, migrations, mssql]
related:
  - ../business/sa/design-decisions/adr-006-fcn-api-service-architecture.md
---

# Database Migrations with Alembic

## Overview

This document describes the database migration strategy for the FCN API service using Alembic with Microsoft SQL Server (MSSQL).

## Why Alembic?

Alembic is the de facto standard for SQLAlchemy-based schema migrations, providing:
- Version-controlled schema changes
- Upgrade and downgrade paths
- Auto-generation from ORM models
- Team collaboration support
- MSSQL dialect support

## Setup

### Prerequisites

- Python 3.9+
- SQLAlchemy 2.0+
- Alembic 1.12+
- pyodbc (MSSQL driver)
- ODBC Driver 18 for SQL Server

### Installation

Dependencies are included in `requirements.txt`:

```bash
pip install -r requirements.txt
```

### Configuration

Alembic configuration is in `alembic.ini`:

```ini
[alembic]
script_location = src/infra/db/alembic
sqlalchemy.url = mssql+pyodbc://sa:password@localhost:1433/fcn_db?driver=...
```

**Environment Override**: Set `DATABASE_URL` environment variable to override:

```bash
export DATABASE_URL="mssql+pyodbc://user:pass@host:port/db?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes"
```

## Core Tables

The initial migration (`20251022_0001_initial_core_schema.py`) creates:

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `fcn_template` | Product template definitions | `template_id`, `spec_version`, `status` |
| `fcn_trade` | Trade instances | `trade_id`, `template_id`, `spec_version` |
| `fcn_observation` | Observation records | `trade_id`, `observation_date` |
| `fcn_lifecycle_event` | Lifecycle event audit trail | `trade_id`, `event_type`, `event_date` |
| `fcn_idempotency_key` | Idempotency key store | `key_hash`, `expires_at` |

### Indexes

Strategic indexes for query performance:
- `fcn_template`: `(spec_version, status)` for active version queries
- `fcn_trade`: `(spec_version, status)` for trade filtering
- `fcn_observation`: `(trade_id, observation_date)` unique for deduplication
- `fcn_lifecycle_event`: `(trade_id, event_type)` for event lookups
- `fcn_idempotency_key`: `(key_hash)` unique, `(expires_at)` for cleanup

### Data Types

- **Timestamps**: `DATETIMEOFFSET` for timezone-aware storage
- **Decimals**: `DECIMAL(18,4)` for financial precision
- **JSON**: `TEXT` (NVARCHAR(MAX)) for JSON serialization
- **IDs**: `VARCHAR` for business keys, `INTEGER` for surrogate keys

## Usage

### Check Current Version

```bash
alembic current
```

### View Migration History

```bash
alembic history --verbose
```

### Upgrade to Latest

```bash
alembic upgrade head
```

### Upgrade to Specific Revision

```bash
alembic upgrade 20251022_0001
```

### Downgrade One Revision

```bash
alembic downgrade -1
```

### Downgrade to Base

```bash
alembic downgrade base
```

## Creating New Migrations

### Auto-Generate Migration

After modifying ORM models in `src/infra/db/models.py`:

```bash
alembic revision --autogenerate -m "Add new field to template table"
```

Alembic compares ORM models to current database schema and generates migration.

**Important**: Always review auto-generated migrations before applying!

### Manual Migration

For data migrations or complex schema changes:

```bash
alembic revision -m "Migrate legacy template format"
```

Edit the generated file in `src/infra/db/alembic/versions/`:

```python
def upgrade() -> None:
    # Custom SQL or SQLAlchemy Core operations
    op.execute("UPDATE fcn_template SET status = 'active' WHERE status IS NULL")

def downgrade() -> None:
    # Reverse operation
    pass
```

## Best Practices

### 1. Always Test Migrations

Test both upgrade and downgrade paths:

```bash
# Test upgrade
alembic upgrade head

# Test downgrade
alembic downgrade -1

# Re-upgrade
alembic upgrade head
```

### 2. Use Transactions

Alembic wraps migrations in transactions by default. For MSSQL, ensure:
- No DDL operations require explicit commits
- Use `op.execute()` for raw SQL when needed

### 3. Data Preservation

For destructive changes (column drops, type changes):
1. Create migration to add new column
2. Deploy and run data backfill
3. Create second migration to drop old column

### 4. Version Naming

Use descriptive names with date prefix:
- `20251022_0001_initial_core_schema.py`
- `20251025_0002_add_template_tags.py`
- `20251030_0003_backfill_trade_status.py`

### 5. Review Before Deploy

Always:
- Review auto-generated migrations for correctness
- Check index creation strategy (ONLINE if supported)
- Verify data type mappings
- Test on staging environment first

## CI/CD Integration

### Pre-Deployment Check

```bash
# Verify no pending migrations
alembic check

# Show SQL without executing
alembic upgrade head --sql > migration.sql
```

### Automated Deployment

```yaml
# Example CI/CD step
- name: Run Migrations
  run: |
    alembic upgrade head
  env:
    DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

## Rollback Strategy

### Safe Rollback

1. Always keep downgrade implementations
2. Test downgrade path in staging
3. Backup database before major migrations
4. Have rollback plan documented

### Emergency Rollback

```bash
# Downgrade to previous revision
alembic downgrade -1

# Or to specific known-good revision
alembic downgrade 20251022_0001
```

## MSSQL-Specific Considerations

### Connection String

Use `TrustServerCertificate=yes` for local development:

```
mssql+pyodbc://sa:password@localhost:1433/fcn_db?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes
```

### Indexes

MSSQL supports ONLINE index creation (Enterprise Edition):

```python
op.create_index(
    'ix_fcn_trade_spec_version',
    'fcn_trade',
    ['spec_version'],
    mssql_online=True  # Requires Enterprise Edition
)
```

### Constraints

Use explicit constraint naming for predictable drops:

```python
op.create_unique_constraint(
    'uq_fcn_template_template_id',
    'fcn_template',
    ['template_id']
)
```

## Troubleshooting

### Migration Fails Mid-Way

1. Check error message for SQL syntax issues
2. Verify MSSQL connection and permissions
3. Check for locking conflicts
4. Review Alembic logs in console output

### Schema Drift Detection

If manual changes made to database:

```bash
# Compare current DB to ORM models
alembic check
```

Fix by creating migration to align schema.

### Version Table Issues

If `alembic_version` table corrupted:

```sql
-- Check current version
SELECT * FROM alembic_version;

-- Manually set version (emergency only)
UPDATE alembic_version SET version_num = '20251022_0001';
```

## Cleanup

### Expired Idempotency Keys

Periodic cleanup job (future implementation):

```sql
DELETE FROM fcn_idempotency_key
WHERE expires_at < GETUTCDATE();
```

Consider SQL Server Agent job or application-level cleanup.

## References

- [Alembic Documentation](https://alembic.sqlalchemy.org/)
- [SQLAlchemy MSSQL Dialect](https://docs.sqlalchemy.org/en/20/dialects/mssql.html)
- ADR-006: FCN API Service Architecture

## Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-22 | siripong.s@yuanta.co.th | Initial migration documentation |
