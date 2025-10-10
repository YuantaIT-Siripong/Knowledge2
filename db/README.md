# FCN v1.0 Parameter Definitions Database

This directory contains database schemas, migrations, and seed scripts for managing FCN (Fixed Coupon Note) parameter definitions.

## Structure

```
db/
├── migrations/          # Database migration scripts
│   └── m0001_create_parameter_definitions.sql
├── schemas/            # JSON schemas for parameters
│   └── fcn-v1.0-parameters.schema.json
├── seeds/              # Seed scripts
│   └── seed_fcn_v1_parameters.py
├── fcn_parameters.db   # SQLite database (generated)
└── README.md           # This file
```

## Database Schema

### parameter_definitions Table

Stores metadata about FCN parameters including type information, constraints, and documentation.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| name | TEXT | Parameter name (unique) |
| data_type | TEXT | Canonical data type (string, date, decimal, integer, boolean, array) |
| required_flag | BOOLEAN | Whether parameter is required |
| default_value | TEXT | Default value (JSON-encoded) |
| enum_domain | TEXT | Pipe-separated enum values |
| min_value | NUMERIC | Minimum value constraint |
| max_value | NUMERIC | Maximum value constraint |
| pattern | TEXT | Regular expression pattern (if applicable) |
| description | TEXT | Parameter description |
| constraints | TEXT | Additional constraints (semicolon-separated) |
| product_type | TEXT | Product type identifier (e.g., 'fcn') |
| spec_version | TEXT | Specification version (e.g., '1.0.0') |
| created_at | TIMESTAMP | Creation timestamp |
| updated_at | TIMESTAMP | Last update timestamp |

## JSON Schema to Database Field Mapping

The seed script (`seed_fcn_v1_parameters.py`) extracts parameter definitions from the JSON schema and maps them to database columns using the following logic:

### Type Mapping

JSON Schema types are mapped to canonical database types:

| JSON Schema Type | Database Type | Notes |
|-----------------|---------------|-------|
| string | string | Default string type |
| string (format: date) | date | Date fields use ISO-8601 format |
| number | decimal | Floating-point numbers |
| integer | integer | Whole numbers |
| boolean | boolean | True/false values |
| array | array | Array/list types |
| ["type", "null"] | type (nullable) | Nullable types extracted from first non-null type |

### Field Extraction Rules

1. **name**: Extracted from JSON schema property key
   - Direct mapping from property name
   - Example: `"trade_date"` → `name = "trade_date"`

2. **data_type**: Determined by JSON schema `type` field
   - Special handling for date format: `type: "string", format: "date"` → `data_type = "date"`
   - Nullable types: `type: ["integer", "null"]` → `data_type = "integer"`
   - Array types preserve array type regardless of items

3. **required_flag**: Extracted from `required` array in schema root
   - `true` if parameter name appears in required array
   - `false` otherwise (optional parameters)

4. **default_value**: Extracted from `default` field
   - Stored as JSON-encoded string
   - Example: `default: false` → `default_value = "false"`
   - Example: `default: "ACT/365"` → `default_value = "\"ACT/365\""`
   - `null` if no default specified

5. **enum_domain**: Extracted from `enum` array
   - Values joined with pipe separator: `|`
   - Example: `enum: ["discrete"]` → `enum_domain = "discrete"`
   - Example: `enum: ["ACT/365", "ACT/360"]` → `enum_domain = "ACT/365|ACT/360"`
   - `null` if no enum constraint

6. **min_value**: Extracted from numeric constraints
   - Uses `minimum` field directly
   - Uses `exclusiveMinimum` field (but notes exclusivity in constraints)
   - Example: `minimum: 0` → `min_value = 0`
   - `null` if no minimum constraint

7. **max_value**: Extracted from numeric constraints
   - Uses `maximum` field directly
   - Uses `exclusiveMaximum` field (but notes exclusivity in constraints)
   - Example: `maximum: 1` → `max_value = 1`
   - `null` if no maximum constraint

8. **pattern**: Extracted from `pattern` field
   - Regular expression pattern for string validation
   - Currently not used in FCN v1.0 schema
   - `null` if no pattern constraint

9. **description**: Extracted from `description` field
   - Direct copy of description text
   - Empty string if not provided

10. **constraints**: Composite field built from multiple sources
    - Custom `constraints` field from schema (if present)
    - Array constraints: `minItems`, `maxItems`
    - Exclusive boundaries: `exclusiveMinimum`, `exclusiveMaximum`
    - Format constraints: `format` field value
    - Multiple constraints joined with `; ` separator
    - Example: `"0 < x < 1; exclusiveMinimum: 0; exclusiveMaximum: 1"`

### Conditional Parameters

Some parameters have conditional requirements based on other parameters:

- `memory_carry_cap_count`: Required only if `is_memory_coupon=true`
- `fx_reference`: Required if underlying currency != settlement currency

These conditions are documented in the `constraints` field using natural language.

## Usage

### Running the Migration

To create the database schema:

```bash
sqlite3 db/fcn_parameters.db < db/migrations/m0001_create_parameter_definitions.sql
```

### Running the Seed Script

To populate the parameter_definitions table:

```bash
python3 db/seeds/seed_fcn_v1_parameters.py
```

The script will:
1. Load the JSON schema from `db/schemas/fcn-v1.0-parameters.schema.json`
2. Create the database (if not exists) and run the migration
3. Extract parameter definitions using the mapping rules above
4. Clear existing FCN v1.0 parameters (if any)
5. Insert all 24 parameters
6. Display a summary of inserted parameters

### Output

The script outputs:
- Loading and extraction progress
- Number of parameters found
- Database creation confirmation
- Number of rows inserted
- Detailed summary table showing all parameters

Example output:
```
Loading schema from: .../fcn-v1.0-parameters.schema.json
Extracting parameters from schema...
  Found 24 parameters

Creating database and running migration: .../m0001_create_parameter_definitions.sql

Seeding parameters into database: .../fcn_parameters.db
  Inserted 24 parameter definitions

============================================================
SEED SUMMARY
============================================================

Name                                Type         Req   Enum                
--------------------------------------------------------------------------------
barrier_monitoring                  string       Yes   discrete            
business_day_calendar               string       No                        
...
```

## Querying Parameter Definitions

Example SQL queries:

### Get all required parameters
```sql
SELECT name, data_type, description 
FROM parameter_definitions 
WHERE required_flag = 1 
ORDER BY name;
```

### Get all enum parameters with their domains
```sql
SELECT name, enum_domain, default_value 
FROM parameter_definitions 
WHERE enum_domain IS NOT NULL 
ORDER BY name;
```

### Get numeric parameters with constraints
```sql
SELECT name, data_type, min_value, max_value, constraints 
FROM parameter_definitions 
WHERE data_type IN ('decimal', 'integer') 
  AND (min_value IS NOT NULL OR max_value IS NOT NULL)
ORDER BY name;
```

### Get all parameters for FCN v1.0
```sql
SELECT * 
FROM parameter_definitions 
WHERE product_type = 'fcn' 
  AND spec_version = '1.0.0'
ORDER BY name;
```

## Validation

The seed script ensures:
- All required fields from the FCN v1.0 spec are included
- Type mappings are consistent and canonical
- Constraints are properly extracted and documented
- Enum domains are correctly formatted
- Default values are JSON-encoded for consistency

## Future Extensions

For future product versions:
1. Add new JSON schema file in `db/schemas/`
2. Update seed script to support multiple product types/versions
3. Maintain version history in parameter_definitions table
4. Add parameter change tracking and migration logic

## Related Documentation

- FCN v1.0 Specification: `docs/business/ba/products/structured-notes/fcn/specs/fcn-v1.0.md`
- Structured Notes Conventions: `docs/business/ba/products/structured-notes/common/conventions.md`
- ADR-003: FCN Version Activation & Promotion Workflow

## Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-10 | System | Initial implementation for FCN v1.0 parameter seeding |
