#!/usr/bin/env python3
"""
Seed script for FCN v1.0 parameter definitions

Extracts parameter definitions from fcn-v1.0-parameters.schema.json and
populates the parameter_definitions table.

Field Mapping:
- name: property name from JSON schema
- data_type: mapped from JSON schema type
- required_flag: from required array in schema
- default_value: from default field in schema
- enum_domain: from enum array (pipe-separated)
- min_value: from minimum/exclusiveMinimum
- max_value: from maximum/exclusiveMaximum
- pattern: from pattern field (if present)
- description: from description field
- constraints: from constraints field (custom)

Type Mapping:
- string → string (or date if format=date)
- number → decimal
- integer → integer
- boolean → boolean
- array → array
- ["type", "null"] → nullable type
"""

import json
import sqlite3
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple


def get_canonical_type(prop: Dict[str, Any]) -> str:
    """
    Map JSON schema type to canonical database type.
    
    Args:
        prop: Property definition from JSON schema
        
    Returns:
        Canonical type string
    """
    json_type = prop.get('type')
    
    # Handle nullable types
    if isinstance(json_type, list):
        # Get the non-null type
        types = [t for t in json_type if t != 'null']
        if types:
            json_type = types[0]
        else:
            json_type = 'string'
    
    # Check for date format
    if json_type == 'string' and prop.get('format') == 'date':
        return 'date'
    
    # Map to canonical types
    type_map = {
        'string': 'string',
        'number': 'decimal',
        'integer': 'integer',
        'boolean': 'boolean',
        'array': 'array'
    }
    
    return type_map.get(json_type, 'string')


def extract_enum_domain(prop: Dict[str, Any]) -> Optional[str]:
    """
    Extract enum values as pipe-separated string.
    
    Args:
        prop: Property definition from JSON schema
        
    Returns:
        Pipe-separated enum values or None
    """
    enum_values = prop.get('enum')
    if enum_values:
        return '|'.join(str(v) for v in enum_values)
    return None


def extract_min_value(prop: Dict[str, Any]) -> Optional[float]:
    """
    Extract minimum value constraint.
    
    Args:
        prop: Property definition from JSON schema
        
    Returns:
        Minimum value or None
    """
    if 'minimum' in prop:
        return prop['minimum']
    # exclusiveMinimum means value must be strictly greater
    # Store the boundary but note it's exclusive in constraints
    if 'exclusiveMinimum' in prop:
        return prop['exclusiveMinimum']
    return None


def extract_max_value(prop: Dict[str, Any]) -> Optional[float]:
    """
    Extract maximum value constraint.
    
    Args:
        prop: Property definition from JSON schema
        
    Returns:
        Maximum value or None
    """
    if 'maximum' in prop:
        return prop['maximum']
    # exclusiveMaximum means value must be strictly less
    # Store the boundary but note it's exclusive in constraints
    if 'exclusiveMaximum' in prop:
        return prop['exclusiveMaximum']
    return None


def extract_constraints(prop: Dict[str, Any]) -> str:
    """
    Build constraints string from various JSON schema fields.
    
    Args:
        prop: Property definition from JSON schema
        
    Returns:
        Constraints string
    """
    constraints = []
    
    # Add custom constraints field if present
    if 'constraints' in prop:
        constraints.append(prop['constraints'])
    
    # Add minItems for arrays
    if 'minItems' in prop:
        constraints.append(f"minItems: {prop['minItems']}")
    
    # Add maxItems for arrays
    if 'maxItems' in prop:
        constraints.append(f"maxItems: {prop['maxItems']}")
    
    # Note exclusive boundaries
    if 'exclusiveMinimum' in prop:
        constraints.append(f"exclusiveMinimum: {prop['exclusiveMinimum']}")
    
    if 'exclusiveMaximum' in prop:
        constraints.append(f"exclusiveMaximum: {prop['exclusiveMaximum']}")
    
    # Add format constraint
    if 'format' in prop:
        constraints.append(f"format: {prop['format']}")
    
    return '; '.join(constraints) if constraints else None


def load_schema(schema_path: Path) -> Dict[str, Any]:
    """
    Load JSON schema from file.
    
    Args:
        schema_path: Path to JSON schema file
        
    Returns:
        Parsed JSON schema
    """
    with open(schema_path, 'r', encoding='utf-8') as f:
        return json.load(f)


def extract_parameters(schema: Dict[str, Any]) -> List[Tuple]:
    """
    Extract parameter definitions from JSON schema.
    
    Args:
        schema: Parsed JSON schema
        
    Returns:
        List of tuples for database insertion
    """
    properties = schema.get('properties', {})
    required_fields = set(schema.get('required', []))
    parameters = []
    
    for name, prop in properties.items():
        # Extract fields
        data_type = get_canonical_type(prop)
        required_flag = name in required_fields
        default_value = json.dumps(prop['default']) if 'default' in prop else None
        enum_domain = extract_enum_domain(prop)
        min_value = extract_min_value(prop)
        max_value = extract_max_value(prop)
        pattern = prop.get('pattern')
        description = prop.get('description', '')
        constraints = extract_constraints(prop)
        
        # Create parameter tuple
        param = (
            name,
            data_type,
            required_flag,
            default_value,
            enum_domain,
            min_value,
            max_value,
            pattern,
            description,
            constraints,
            'fcn',  # product_type
            '1.0.0'  # spec_version
        )
        
        parameters.append(param)
    
    return parameters


def create_database(db_path: Path, migration_path: Path) -> sqlite3.Connection:
    """
    Create database and run migration.
    
    Args:
        db_path: Path to database file
        migration_path: Path to migration SQL file
        
    Returns:
        Database connection
    """
    conn = sqlite3.connect(db_path)
    
    # Run migration
    with open(migration_path, 'r', encoding='utf-8') as f:
        migration_sql = f.read()
    
    conn.executescript(migration_sql)
    conn.commit()
    
    return conn


def seed_parameters(conn: sqlite3.Connection, parameters: List[Tuple]) -> int:
    """
    Insert parameters into database.
    
    Args:
        conn: Database connection
        parameters: List of parameter tuples
        
    Returns:
        Number of rows inserted
    """
    cursor = conn.cursor()
    
    # Clear existing FCN v1.0 parameters
    cursor.execute(
        "DELETE FROM parameter_definitions WHERE product_type = ? AND spec_version = ?",
        ('fcn', '1.0.0')
    )
    
    # Insert parameters
    insert_sql = """
        INSERT INTO parameter_definitions (
            name, data_type, required_flag, default_value, enum_domain,
            min_value, max_value, pattern, description, constraints,
            product_type, spec_version
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """
    
    cursor.executemany(insert_sql, parameters)
    conn.commit()
    
    return cursor.rowcount


def main():
    """Main entry point."""
    # Determine paths
    script_dir = Path(__file__).parent.resolve()
    repo_root = script_dir.parent.parent
    schema_path = repo_root / 'db/schemas/fcn-v1.0-parameters.schema.json'
    migration_path = repo_root / 'db/migrations/m0001_create_parameter_definitions.sql'
    db_path = repo_root / 'db/fcn_parameters.db'
    
    # Check if schema file exists
    if not schema_path.exists():
        print(f"Error: Schema file not found: {schema_path}", file=sys.stderr)
        sys.exit(1)
    
    # Check if migration file exists
    if not migration_path.exists():
        print(f"Error: Migration file not found: {migration_path}", file=sys.stderr)
        sys.exit(1)
    
    print(f"Loading schema from: {schema_path}")
    schema = load_schema(schema_path)
    
    print(f"Extracting parameters from schema...")
    parameters = extract_parameters(schema)
    print(f"  Found {len(parameters)} parameters")
    
    print(f"\nCreating database and running migration: {migration_path}")
    conn = create_database(db_path, migration_path)
    
    print(f"\nSeeding parameters into database: {db_path}")
    rows_inserted = seed_parameters(conn, parameters)
    print(f"  Inserted {rows_inserted} parameter definitions")
    
    # Display summary
    print("\n" + "="*60)
    print("SEED SUMMARY")
    print("="*60)
    
    cursor = conn.cursor()
    cursor.execute("""
        SELECT name, data_type, required_flag, enum_domain, description
        FROM parameter_definitions
        WHERE product_type = 'fcn' AND spec_version = '1.0.0'
        ORDER BY name
    """)
    
    print(f"\n{'Name':<35} {'Type':<12} {'Req':<5} {'Enum':<20}")
    print("-" * 80)
    
    for row in cursor.fetchall():
        name, data_type, required_flag, enum_domain, description = row
        req = 'Yes' if required_flag else 'No'
        enum_str = enum_domain[:17] + '...' if enum_domain and len(enum_domain) > 20 else (enum_domain or '')
        print(f"{name:<35} {data_type:<12} {req:<5} {enum_str:<20}")
    
    print("\n" + "="*60)
    print(f"Seed completed successfully!")
    print(f"Database: {db_path}")
    print("="*60)
    
    conn.close()


if __name__ == '__main__':
    main()
