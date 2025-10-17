# FCN Patch Settlement Type Alignment - Test Plan

## Test Objective
Verify that the patch migration `fcn_patch_settlement_type_alignment.sql` correctly migrates settlement_type values from legacy format to canonical format.

## Test Environment Requirements
- SQL Server instance with fcn_schema_consolidated_v1_1.sql applied
- fcn_settlement table with test data

## Test Scenarios

### Scenario 1: Empty Table (Idempotency Check)
**Setup:**
- Fresh database with consolidated schema
- No data in fcn_settlement

**Expected Result:**
- Patch runs successfully
- No errors
- Constraint created: chk_fcn_settlement_type_canonical
- Index created: idx_fcn_settlement_type
- Message: "No legacy values found. Skipping data migration."

**SQL Verification:**
```sql
-- Should return empty result
SELECT DISTINCT settlement_type FROM fcn_settlement;

-- Should return the canonical constraint
SELECT name, definition 
FROM sys.check_constraints 
WHERE parent_object_id = OBJECT_ID('dbo.fcn_settlement') 
  AND name = 'chk_fcn_settlement_type_canonical';
```

### Scenario 2: Legacy 'cash' Values
**Setup:**
```sql
-- Create test trade
INSERT INTO fcn_trade (trade_id, spec_version, documentation_version, trade_date, issue_date, maturity_date, 
                       notional, currency, knock_in_barrier_pct, coupon_rate_pct, coupon_condition_threshold_pct,
                       recovery_mode, settlement_type)
VALUES (NEWID(), 'v1.1', 'v1.1', '2024-01-01', '2024-01-15', '2024-12-31', 
        1000000, 'USD', 0.65, 0.05, 1.0, 'capital-at-risk', 'cash-settlement');

-- Create test settlement with legacy 'cash' (temporarily disable constraint)
ALTER TABLE fcn_settlement NOCHECK CONSTRAINT ALL;
INSERT INTO fcn_settlement (settlement_id, trade_id, settlement_type, settlement_date, cash_amount)
SELECT NEWID(), trade_id, 'cash', '2024-12-31', 1000000.00
FROM fcn_trade WHERE spec_version = 'v1.1';
ALTER TABLE fcn_settlement CHECK CONSTRAINT ALL;
```

**Expected Result:**
- Migration succeeds
- 'cash' → 'cash-settlement'
- Message: "Migrated 1 rows: 'cash' -> 'cash-settlement'"
- updated_at timestamp updated

**SQL Verification:**
```sql
-- Should return only 'cash-settlement'
SELECT DISTINCT settlement_type FROM fcn_settlement;
-- Expected: cash-settlement

-- Should return 1
SELECT COUNT(*) FROM fcn_settlement WHERE settlement_type = 'cash-settlement';
```

### Scenario 3: Legacy 'physical' Values
**Setup:**
```sql
-- Similar to Scenario 2, but use 'physical'
ALTER TABLE fcn_settlement NOCHECK CONSTRAINT ALL;
INSERT INTO fcn_settlement (settlement_id, trade_id, settlement_type, settlement_date, 
                           delivery_underlying_symbol, delivery_shares)
SELECT NEWID(), trade_id, 'physical', '2024-12-31', 'AAPL', 1000.00
FROM fcn_trade WHERE spec_version = 'v1.1';
ALTER TABLE fcn_settlement CHECK CONSTRAINT ALL;
```

**Expected Result:**
- Migration succeeds
- 'physical' → 'physical-settlement'
- Message: "Migrated 1 rows: 'physical' -> 'physical-settlement'"

**SQL Verification:**
```sql
SELECT DISTINCT settlement_type FROM fcn_settlement;
-- Expected: physical-settlement

SELECT COUNT(*) FROM fcn_settlement WHERE settlement_type = 'physical-settlement';
-- Expected: count > 0
```

### Scenario 4: Legacy 'mixed' with Share Delivery
**Setup:**
```sql
ALTER TABLE fcn_settlement NOCHECK CONSTRAINT ALL;
-- Mixed settlement WITH delivery_shares (should map to physical-settlement)
INSERT INTO fcn_settlement (settlement_id, trade_id, settlement_type, settlement_date,
                           cash_amount, delivery_underlying_symbol, delivery_shares)
SELECT NEWID(), trade_id, 'mixed', '2024-12-31', 10000.00, 'AAPL', 500.00
FROM fcn_trade WHERE spec_version = 'v1.1';
ALTER TABLE fcn_settlement CHECK CONSTRAINT ALL;
```

**Expected Result:**
- Migration succeeds
- 'mixed' → 'physical-settlement' (because delivery_shares IS NOT NULL)
- Message: "Migrated 1 rows: 'mixed' -> deterministic mapping"

**SQL Verification:**
```sql
-- Should map to physical-settlement
SELECT settlement_type, delivery_shares 
FROM fcn_settlement 
WHERE delivery_shares IS NOT NULL;
-- Expected: settlement_type = 'physical-settlement'
```

### Scenario 5: Legacy 'mixed' without Share Delivery
**Setup:**
```sql
ALTER TABLE fcn_settlement NOCHECK CONSTRAINT ALL;
-- Mixed settlement WITHOUT delivery_shares (should map to cash-settlement)
INSERT INTO fcn_settlement (settlement_id, trade_id, settlement_type, settlement_date, cash_amount)
SELECT NEWID(), trade_id, 'mixed', '2024-12-31', 1000000.00
FROM fcn_trade WHERE spec_version = 'v1.1';
ALTER TABLE fcn_settlement CHECK CONSTRAINT ALL;
```

**Expected Result:**
- Migration succeeds
- 'mixed' → 'cash-settlement' (because delivery_shares IS NULL)
- Message: "Migrated 1 rows: 'mixed' -> deterministic mapping"

**SQL Verification:**
```sql
-- Should map to cash-settlement
SELECT settlement_type, delivery_shares, cash_amount
FROM fcn_settlement 
WHERE cash_amount IS NOT NULL AND delivery_shares IS NULL;
-- Expected: settlement_type = 'cash-settlement'
```

### Scenario 6: Mixed Legacy Values
**Setup:**
- Combination of 'cash', 'physical', and 'mixed' values

**Expected Result:**
- All values migrated correctly
- Final distinct values: only 'cash-settlement' and 'physical-settlement'

**SQL Verification:**
```sql
-- Should return exactly 2 rows (or fewer if only one type exists)
SELECT settlement_type, COUNT(*) as count
FROM fcn_settlement
GROUP BY settlement_type
ORDER BY settlement_type;

-- Should return 0 non-canonical values
SELECT COUNT(*) 
FROM fcn_settlement 
WHERE settlement_type NOT IN ('cash-settlement', 'physical-settlement');
-- Expected: 0
```

### Scenario 7: Already Canonical Values (Idempotency)
**Setup:**
- Database with canonical values already in place
- Run patch again

**Expected Result:**
- Patch detects canonical constraint exists
- Message: "SUCCESS: All settlement_type values are already canonical. No action needed."
- No data modification
- Patch execution completes early

**SQL Verification:**
```sql
-- Should still return only canonical values
SELECT DISTINCT settlement_type FROM fcn_settlement
ORDER BY settlement_type;
```

### Scenario 8: Constraint Verification
**Setup:**
- After successful migration

**Expected Result:**
- Constraint name: chk_fcn_settlement_type_canonical
- Constraint allows: 'cash-settlement', 'physical-settlement'
- Constraint rejects: 'cash', 'physical', 'mixed', or any other value

**SQL Verification:**
```sql
-- Verify constraint exists
SELECT name, definition 
FROM sys.check_constraints 
WHERE parent_object_id = OBJECT_ID('dbo.fcn_settlement')
  AND name = 'chk_fcn_settlement_type_canonical';

-- Test constraint enforcement (should fail)
INSERT INTO fcn_settlement (settlement_id, trade_id, settlement_type, settlement_date)
VALUES (NEWID(), (SELECT TOP 1 trade_id FROM fcn_trade), 'cash', GETDATE());
-- Expected: Error - CHECK constraint violation

-- Test canonical value (should succeed)
INSERT INTO fcn_settlement (settlement_id, trade_id, settlement_type, settlement_date)
VALUES (NEWID(), (SELECT TOP 1 trade_id FROM fcn_trade), 'cash-settlement', GETDATE());
-- Expected: Success
```

### Scenario 9: Index Verification
**Setup:**
- After successful migration

**Expected Result:**
- Index exists: idx_fcn_settlement_type
- Index on column: settlement_type

**SQL Verification:**
```sql
-- Verify index exists
SELECT i.name, i.type_desc, c.name as column_name
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.object_id = OBJECT_ID('dbo.fcn_settlement')
  AND i.name = 'idx_fcn_settlement_type';
-- Expected: One row with type_desc = NONCLUSTERED
```

### Scenario 10: Transaction Rollback on Error
**Setup:**
- Simulate error during migration (e.g., foreign key violation)

**Expected Result:**
- Transaction rolls back
- No partial updates
- Error message displayed
- Data remains in pre-migration state

## Acceptance Criteria Summary

1. ✓ Patch migration file created: fcn_patch_settlement_type_alignment.sql
2. ✓ Consolidated schema updated with canonical constraint
3. ✓ Data migration logic handles all three legacy values correctly
4. ✓ Deterministic mapping for 'mixed' values implemented
5. ✓ Constraint standardized: chk_fcn_settlement_type_canonical
6. ✓ Index added: idx_fcn_settlement_type
7. ✓ Idempotent execution (safe to run multiple times)
8. ✓ Extended property updated with canonical documentation
9. ✓ README.md updated with patch history and usage
10. ✓ All BEGIN/END blocks balanced
11. ✓ All GO batch separators properly placed
12. ✓ Error handling and rollback implemented

## Manual Testing Checklist

- [ ] Run consolidated schema on clean SQL Server database
- [ ] Insert test data with legacy settlement_type values
- [ ] Run patch migration
- [ ] Verify all scenarios above pass
- [ ] Re-run patch migration (idempotency check)
- [ ] Verify constraint enforcement with INSERT tests
- [ ] Test joins between fcn_settlement and fcn_trade on settlement_type
- [ ] Verify index improves query performance on settlement_type

## Notes

- This is a SQL Server-specific migration
- Requires appropriate permissions to ALTER TABLE and CREATE INDEX
- Should be tested in non-production environment first
- Backup database before applying patch migration
