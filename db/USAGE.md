# FCN v1.0 Parameter Seeding - Quick Start Guide

## Prerequisites

- Python 3.7 or higher
- SQLite3 (typically included with Python)
- No additional dependencies required (uses standard library only)

## Quick Start

### 1. Run the Seed Script

From the repository root:

```bash
python3 db/seeds/seed_fcn_v1_parameters.py
```

This will:
- Create `db/fcn_parameters.db` (SQLite database)
- Run migration m0001 to create the schema
- Populate the `parameter_definitions` table with 24 parameters from FCN v1.0

### 2. Verify the Seeding

Run the test script to validate:

```bash
python3 db/seeds/test_seed.py
```

Expected output:
```
✓ Test 1: Found all 24 parameters
✓ Test 2: All 17 required parameters are marked correctly
✓ Test 3: Date type mapping correct (3 date fields)
✓ Test 4: All 5 enum parameters correctly defined
✓ Test 5: Numeric constraints correctly extracted
✓ Test 6: Default values correctly encoded (9 parameters with defaults)
✓ Test 7: All parameters have descriptions

============================================================
ALL TESTS PASSED!
============================================================
```

## Example Queries

### View All Parameters

```bash
sqlite3 db/fcn_parameters.db "SELECT name, data_type, required_flag FROM parameter_definitions ORDER BY name;"
```

### Get Required Parameters Only

```bash
sqlite3 db/fcn_parameters.db "SELECT name, data_type, description FROM parameter_definitions WHERE required_flag = 1 ORDER BY name;"
```

### View Enum Parameters

```bash
sqlite3 db/fcn_parameters.db "SELECT name, enum_domain, default_value FROM parameter_definitions WHERE enum_domain IS NOT NULL ORDER BY name;"
```

### Get Parameter Details

```bash
sqlite3 db/fcn_parameters.db "SELECT * FROM parameter_definitions WHERE name = 'knock_in_barrier_pct';"
```

## Output Example

When you run the seed script, you'll see output like:

```
Loading schema from: /path/to/Knowledge2/db/schemas/fcn-v1.0-parameters.schema.json
Extracting parameters from schema...
  Found 24 parameters

Creating database and running migration: /path/to/Knowledge2/db/migrations/m0001_create_parameter_definitions.sql

Seeding parameters into database: /path/to/Knowledge2/db/fcn_parameters.db
  Inserted 24 parameter definitions

============================================================
SEED SUMMARY
============================================================

Name                                Type         Req   Enum                
--------------------------------------------------------------------------------
barrier_monitoring                  string       Yes   discrete            
business_day_calendar               string       No                        
coupon_condition_threshold_pct      decimal      No                        
coupon_observation_offset_days      integer      No                        
coupon_payment_dates                array        Yes                       
coupon_rate_pct                     decimal      Yes                       
currency                            string       Yes                       
day_count_convention                string       No    ACT/365|ACT/360     
documentation_version               string       Yes                       
fx_reference                        string       No                        
initial_levels                      array        Yes                       
is_memory_coupon                    boolean      No                        
issue_date                          date         Yes                       
knock_in_barrier_pct                decimal      Yes                       
knock_in_condition                  string       Yes   any-underlying-br...
maturity_date                       date         Yes                       
memory_carry_cap_count              integer      No                        
notional_amount                     decimal      Yes                       
observation_dates                   array        Yes                       
recovery_mode                       string       Yes   par-recovery        
redemption_barrier_pct              decimal      Yes                       
settlement_type                     string       Yes   physical-settlement 
trade_date                          date         Yes                       
underlying_symbols                  array        Yes                       

============================================================
Seed completed successfully!
Database: /path/to/Knowledge2/db/fcn_parameters.db
============================================================
```

## Re-running the Script

The seed script is **idempotent** - you can run it multiple times safely:
- It clears existing FCN v1.0 parameters before inserting
- The database will be recreated if it doesn't exist
- No manual cleanup is needed

## Troubleshooting

### Schema File Not Found

**Error**: `Error: Schema file not found`

**Solution**: Ensure you're running from the repository root, or that the schema file exists at:
`db/schemas/fcn-v1.0-parameters.schema.json`

### Migration File Not Found

**Error**: `Error: Migration file not found`

**Solution**: Ensure the migration file exists at:
`db/migrations/m0001_create_parameter_definitions.sql`

### Permission Denied

**Error**: Permission denied when creating database

**Solution**: Ensure the `db/` directory is writable, or run with appropriate permissions

## Integration with Migration m0001

The seed script automatically:
1. Checks if migration m0001 exists
2. Runs the migration to create the table schema
3. Seeds the parameters

You don't need to run the migration separately unless you want to create an empty database.

## Next Steps

After seeding:
1. Use the database for parameter validation in other tools
2. Query parameter definitions for documentation generation
3. Integrate with FCN instance validators
4. Use as reference for test vector generation

## Related Documentation

- [Full README](README.md) - Detailed field mapping documentation
- [FCN v1.0 Specification](../docs/business/ba/products/structured-notes/fcn/specs/fcn-v1.0.md)
- [Migration m0001](migrations/m0001_create_parameter_definitions.sql)
- [JSON Schema](schemas/fcn-v1.0-parameters.schema.json)
