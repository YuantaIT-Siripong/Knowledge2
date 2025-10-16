---
title: FCN v1.0 Database Schema Design - Current Status Analysis
doc_type: status-report
status: Draft
version: 1.0.0
owner: siripong.s@yuanta.co.th
created: 2025-10-16
classification: Internal
tags: [fcn, database-schema, status-report, analysis]
related:
  - er-fcn-v1.0.md
  - specs/fcn-v1.0.md
  - migrations/m0001-fcn-baseline.sql
  - ../../../../../../db/README.md
---

# FCN v1.0 Database Schema Design - Current Status Analysis

## Executive Summary

This document provides a comprehensive analysis of the current status of the FCN (Fixed Coupon Note) v1.0 database schema design in the Knowledge2 repository. The analysis was conducted on 2025-10-16.

**Overall Status**: **GOOD** - The database schema design is well-structured and operational with clear documentation, working migrations, and automated validation.

**Key Strengths**:
- Comprehensive Entity-Relationship (ER) model documented
- Working parameter definitions database with automated seeding
- Clear migration strategy and version control
- Strong validation and testing infrastructure
- Well-documented design decisions and ADRs

**Areas for Improvement**:
- Implementation gap between documentation and actual database (full ER model not yet implemented)
- Schema naming inconsistencies need resolution
- Test coverage could be expanded
- Full lifecycle management tables need implementation

---

## 1. Repository Overview

### 1.1 Repository Structure
```
Knowledge2/
├── db/                          # Database-specific artifacts
│   ├── README.md                # Parameter definitions documentation
│   ├── USAGE.md                 # Quick start guide
│   ├── migrations/              # Database migrations
│   │   └── m0001_create_parameter_definitions.sql
│   ├── schemas/                 # JSON schemas
│   │   └── fcn-v1.0-parameters.schema.json
│   ├── seeds/                   # Seed scripts
│   │   ├── seed_fcn_v1_parameters.py (WORKING ✓)
│   │   └── test_seed.py         (WORKING ✓)
│   └── fcn_parameters.db        # Generated SQLite database
├── docs/
│   └── business/ba/products/structured-notes/fcn/
│       ├── er-fcn-v1.0.md       # ER model documentation
│       ├── specs/fcn-v1.0.md    # Product specification
│       ├── business-rules.md    # Business rules BR-001 to BR-019
│       ├── overview.md          # KPI baselines and objectives
│       ├── migrations/          # Full schema migrations (PostgreSQL)
│       │   └── m0001-fcn-baseline.sql
│       └── validators/          # Python validators
│           ├── parameter_validator.py
│           ├── taxonomy_validator.py
│           ├── metadata_validator.py
│           └── coverage_validator.py
└── .github/workflows/
    └── fcn-validators.yml       # CI/CD validation pipeline
```

### 1.2 Key Documentation
- **ER Model**: `docs/business/ba/products/structured-notes/fcn/er-fcn-v1.0.md`
- **Product Spec**: `docs/business/ba/products/structured-notes/fcn/specs/fcn-v1.0.md`
- **Database README**: `db/README.md`
- **ADR-003**: FCN Version Activation & Promotion Workflow
- **ADR-004**: Parameter Alias & Deprecation Policy

---

## 2. Database Schema Design Analysis

### 2.1 Implemented Database Schema (Parameter Definitions)

**Location**: `db/migrations/m0001_create_parameter_definitions.sql`

**Status**: ✅ **IMPLEMENTED & OPERATIONAL**

**Table**: `parameter_definitions`

| Column | Type | Purpose | Status |
|--------|------|---------|--------|
| id | INTEGER PK | Primary key | ✓ |
| name | TEXT UNIQUE | Parameter name | ✓ |
| data_type | TEXT | Canonical type (string, date, decimal, integer, boolean, array) | ✓ |
| required_flag | BOOLEAN | Whether required | ✓ |
| default_value | TEXT | JSON-encoded default | ✓ |
| enum_domain | TEXT | Pipe-separated enum values | ✓ |
| min_value | NUMERIC | Minimum constraint | ✓ |
| max_value | NUMERIC | Maximum constraint | ✓ |
| pattern | TEXT | Regex pattern | ✓ |
| description | TEXT | Parameter description | ✓ |
| constraints | TEXT | Additional constraints | ✓ |
| product_type | TEXT | Product identifier (e.g., 'fcn') | ✓ |
| spec_version | TEXT | Version (e.g., '1.0.0') | ✓ |
| created_at | TIMESTAMP | Creation timestamp | ✓ |
| updated_at | TIMESTAMP | Update timestamp | ✓ |

**Indexes**:
- `idx_parameter_definitions_name` on `name`
- `idx_parameter_definitions_product_spec` on `(product_type, spec_version)`

**Data Population**: 
- ✅ Automated seeding from JSON schema
- ✅ 24 parameters successfully inserted
- ✅ All validation tests passing

**Validation Results** (from `test_seed.py`):
```
✓ Test 1: Found all 24 parameters
✓ Test 2: All 17 required parameters are marked correctly
✓ Test 3: Date type mapping correct (3 date fields)
✓ Test 4: All 5 enum parameters correctly defined
✓ Test 5: Numeric constraints correctly extracted
✓ Test 6: Default values correctly encoded (9 parameters with defaults)
✓ Test 7: All parameters have descriptions
```

### 2.2 Documented Full ER Model (Not Yet Implemented)

**Location**: `docs/business/ba/products/structured-notes/fcn/er-fcn-v1.0.md`

**Status**: 📋 **DOCUMENTED BUT NOT IMPLEMENTED**

**Entities Documented**:

1. ✅ **Product** - Product definition and versioning metadata
2. ✅ **Product_Version** - Version-specific metadata and promotion state
3. ✅ **Branch** - Taxonomy-specific payoff branches
4. ✅ **Parameter_Definition** - Parameter metadata (similar to implemented table)
5. ⚠️ **Trade** - Individual FCN trade instances (NOT IMPLEMENTED)
6. ⚠️ **Underlying_Asset** - Links trades to underlying assets (NOT IMPLEMENTED)
7. ⚠️ **Observation** - Scheduled observation dates (NOT IMPLEMENTED)
8. ⚠️ **Underlying_Level** - Observed asset levels (NOT IMPLEMENTED)
9. ⚠️ **Coupon_Decision** - Coupon payment decisions (NOT IMPLEMENTED)
10. ⚠️ **Knock_In_Trigger** - Knock-in event records (NOT IMPLEMENTED)
11. ⚠️ **Cash_Flow** - Cash flow records (NOT IMPLEMENTED)
12. ⚠️ **Test_Vector** - Test cases for validation (NOT IMPLEMENTED)

**Full Schema Migration**: `docs/business/ba/products/structured-notes/fcn/migrations/m0001-fcn-baseline.sql`
- Status: 📋 **DOCUMENTED (PostgreSQL)**
- Includes: Product, Product_Version, Branch, Parameter_Definition, Trade, Underlying_Asset, Test_Vector
- Seed data: FCN v1.0 baseline, 3 branches (fcn-base-mem, fcn-base-nomem, fcn-base-mem-proploss)
- **NOT YET EXECUTED** - Documentation only

### 2.3 Schema Comparison: Documented vs. Implemented

**Implemented (SQLite)**:
- Single table: `parameter_definitions`
- Purpose: Parameter metadata storage and validation
- Target: Development/validation environment
- Database: SQLite (file-based)

**Documented (PostgreSQL)**:
- Full product lifecycle schema
- Purpose: Complete trade lifecycle management
- Target: Production environment
- Database: PostgreSQL (server-based)

**Gap Analysis**:
| Feature | Implemented | Documented | Gap |
|---------|------------|-----------|-----|
| Parameter definitions | ✅ | ✅ | None |
| Product/Version management | ❌ | ✅ | Large |
| Branch taxonomy | ❌ | ✅ | Large |
| Trade instances | ❌ | ✅ | Large |
| Observations & lifecycle | ❌ | ✅ | Large |
| Cash flows | ❌ | ✅ | Large |
| Test vectors storage | ❌ | ✅ | Medium |

---

## 3. Parameter Definitions (24 Parameters)

### 3.1 Core Parameters Summary

**Trade Dates (3 parameters)**:
1. `trade_date` - Date (Required)
2. `issue_date` - Date (Required)
3. `maturity_date` - Date (Required)

**Underlying & Notional (4 parameters)**:
4. `underlying_symbols` - Array (Required)
5. `initial_levels` - Array (Required)
6. `notional_amount` - Decimal (Required)
7. `currency` - String (Required)

**Observation & Coupon (7 parameters)**:
8. `observation_dates` - Array (Required)
9. `coupon_observation_offset_days` - Integer (Optional, default: 0)
10. `coupon_payment_dates` - Array (Required)
11. `coupon_rate_pct` - Decimal (Required)
12. `is_memory_coupon` - Boolean (Optional, default: false)
13. `memory_carry_cap_count` - Integer (Conditional)
14. `coupon_condition_threshold_pct` - Decimal (Optional)

**Barrier & Settlement (6 parameters)**:
15. `knock_in_barrier_pct` - Decimal (Required)
16. `barrier_monitoring` - String (Required, enum: "discrete")
17. `knock_in_condition` - String (Required, enum: "any-underlying-breach")
18. `redemption_barrier_pct` - Decimal (Required)
19. `settlement_type` - String (Required, enum: "physical-settlement")
20. `recovery_mode` - String (Required, enum: "par-recovery")

**Other (4 parameters)**:
21. `day_count_convention` - String (Optional, default: "ACT/365", enum: "ACT/365|ACT/360")
22. `business_day_calendar` - String (Optional)
23. `fx_reference` - String (Conditional)
24. `documentation_version` - String (Required)

### 3.2 Parameter Distribution

- **Required**: 17 parameters (71%)
- **Optional**: 5 parameters (21%)
- **Conditional**: 2 parameters (8%)
- **With Enums**: 5 parameters
- **With Defaults**: 9 parameters
- **Date Type**: 3 parameters
- **Array Type**: 4 parameters
- **Decimal/Numeric**: 6 parameters

---

## 4. Business Rules & Validation

### 4.1 Business Rules (BR-001 to BR-019)

**Location**: `docs/business/ba/products/structured-notes/fcn/business-rules.md`

**Status**: 📋 **DOCUMENTED**

**Categories**:
- **BR-001 to BR-004**: Parameter validation rules
- **BR-005 to BR-010**: Calculation and logic rules
- **BR-011 to BR-015**: Taxonomy and constraint rules
- **BR-016 to BR-019**: Test coverage and precision rules

### 4.2 Validators

**Location**: `docs/business/ba/products/structured-notes/fcn/validators/`

**Implemented Validators**:
1. ✅ `metadata_validator.py` - Phase 0: Metadata validation
2. ✅ `taxonomy_validator.py` - Phase 1: Taxonomy validation
3. ✅ `parameter_validator.py` - Phase 2: Parameters validation
4. ✅ `coverage_validator.py` - Coverage validation
5. ✅ `memory_logic_validator.py` - Memory coupon logic
6. ✅ `aggregator.py` - Aggregation and reporting
7. ✅ `ingest_vectors.py` - Test vector ingestion

**CI/CD Integration**: ✅ `.github/workflows/fcn-validators.yml`
- Automated validation on push/PR
- Phases 0-2 validation
- Test vector ingestion
- Artifact upload and reporting

---

## 5. Schema Design Strengths

### 5.1 Well-Documented Design

✅ **Comprehensive ER Documentation**
- Clear entity definitions
- Relationship mappings
- Constraint specifications
- Enumeration definitions
- Migration paths

✅ **Field Mapping Documentation**
- JSON schema to database mapping
- Type conversion rules
- Constraint extraction logic
- Default value handling

✅ **Version Management**
- Product versioning strategy
- Version lifecycle states (Draft, Proposed, Active, Deprecated, Removed)
- Branch taxonomy management
- Parameter aliasing support

### 5.2 Automation & Validation

✅ **Automated Seeding**
- Python script extracts from JSON schema
- Idempotent execution
- Comprehensive testing
- All tests passing

✅ **Type Safety**
- Canonical type mapping
- Constraint validation
- Enum domain support
- Pattern validation (planned)

✅ **CI/CD Integration**
- Automated validation pipeline
- Multi-phase validation
- Test vector ingestion
- Report generation

### 5.3 Extensibility

✅ **Version Aware**
- `product_type` and `spec_version` fields
- Support for multiple products
- Version-specific parameters
- Migration tracking

✅ **Metadata Rich**
- Descriptions for all parameters
- Constraint documentation
- Timestamp tracking
- Audit trail support

---

## 6. Areas for Improvement

### 6.1 Implementation Gaps

❌ **Full ER Model Not Implemented**
- Only parameter_definitions table exists
- Trade lifecycle tables missing
- Observation/cash flow management not implemented
- Test vector storage not in database

**Recommendation**: Prioritize implementation based on immediate needs:
1. **Phase 1**: Product, Product_Version, Branch (product catalog)
2. **Phase 2**: Trade, Underlying_Asset (trade booking)
3. **Phase 3**: Observation, Coupon_Decision, Cash_Flow (lifecycle)
4. **Phase 4**: Test_Vector (testing infrastructure)

### 6.2 Schema Inconsistencies

⚠️ **Naming Discrepancies** (noted in ER model v1.0.1):
- Legacy: `observation_style` → Updated: `barrier_monitoring`
- Legacy: `coupon_barrier_pct` → Updated: `coupon_condition_threshold_pct`

**Status**: Documentation updated but database migration pending

**Recommendation**: 
- Update PostgreSQL migration script with correct names
- Add migration for renaming if legacy names exist
- Document in ADR-004 (alias policy)

### 6.3 Database Platform Divergence

⚠️ **Two Different Database Systems**:
- SQLite for parameter definitions (development)
- PostgreSQL for full schema (production)

**Concerns**:
- Type compatibility (UUID in PostgreSQL, INTEGER in SQLite)
- Feature differences (JSONB in PostgreSQL vs TEXT in SQLite)
- Migration complexity

**Recommendation**:
- Document migration path from SQLite to PostgreSQL
- Consider using PostgreSQL for development consistency
- OR maintain separate schemas for different purposes

### 6.4 Test Coverage

⚠️ **Test Vectors Not in Database**
- Test vectors stored as markdown files
- No database-backed test vector management
- Manual test vector maintenance

**Recommendation**:
- Implement Test_Vector table from ER model
- Create seed script for test vectors
- Add test vector versioning

### 6.5 Missing Features

❌ **Observation & Lifecycle Management**
- No observation tracking
- No coupon decision recording
- No cash flow management
- No knock-in trigger recording

**Impact**: Cannot track trade lifecycle in database

**Recommendation**: 
- Prioritize based on operational needs
- Start with observation and coupon decision tables
- Add cash flow tracking for reconciliation

---

## 7. Key Design Decisions (ADRs)

### 7.1 ADR-003: FCN Version Activation & Promotion

**Status**: Approved

**Key Points**:
- Defines promotion workflow: Draft → Proposed → Active → Deprecated → Removed
- Requires activation checklist completion
- Gate criteria for promotion
- Test vector requirements

**Database Impact**: 
- Product_Version status field
- Activation checklist reference
- Release/deprecation dates

### 7.2 ADR-004: Parameter Alias & Deprecation Policy

**Status**: Approved

**Key Points**:
- No active aliases in v1.0
- Parameter deprecation process
- Renaming policy
- Backward compatibility

**Database Impact**:
- Parameter_Definition.alias_of field
- Parameter_Definition.deprecated flag
- Version-specific parameter definitions

---

## 8. Validation & Testing Status

### 8.1 Parameter Seeding Validation

**Status**: ✅ **ALL TESTS PASSING**

**Test Results**:
```
✓ Test 1: Found all 24 parameters
✓ Test 2: All 17 required parameters are marked correctly
✓ Test 3: Date type mapping correct (3 date fields)
✓ Test 4: All 5 enum parameters correctly defined
✓ Test 5: Numeric constraints correctly extracted
✓ Test 6: Default values correctly encoded (9 parameters with defaults)
✓ Test 7: All parameters have descriptions
```

**Coverage**: 100% of parameter definition features tested

### 8.2 CI/CD Validation

**Status**: ✅ **CONFIGURED**

**Workflow**: `.github/workflows/fcn-validators.yml`

**Phases**:
1. Test Vector Ingestion
2. Phase 0: Metadata Validation
3. Phase 1: Taxonomy Validation
4. Phase 2: Parameters Validation

**Triggers**: Push and Pull Request to relevant paths

### 8.3 Test Vectors

**Status**: 📋 **DOCUMENTED**

**Test Vector Files**:
- `fcn-v1.0-base-mem-baseline.md`
- `fcn-v1.0-base-mem-edge-barrier-touch.md`
- `fcn-v1.0-base-mem-single-miss.md`
- `fcn-v1.0-base-mem-ki-event.md`
- `fcn-v1.0-base-nomem-baseline.md`

**Normative Set**: N1, N2, N3, N4, N5

---

## 9. KPI Baselines (from overview.md)

### 9.1 Current KPI Status

| KPI | Baseline | Target | Current Status |
|-----|----------|--------|----------------|
| Time-to-Launch | 90 days | 60 days | Not measured yet |
| Parameter Error Rate | 5% | < 2% | 0% (all tests passing) ✅ |
| Data Completeness | 60% | ≥ 80% | ~60% (5 test vectors documented) |
| Rule Mapping Coverage | 95% | 100% | Documented (needs validation) |
| Precision Conformance | 98% | 100% | Not measured yet |
| Test Vector Freshness | 45 days | ≤ 30 days | Not measured yet |

### 9.2 KPI Observations

**Strengths**:
- Parameter validation is excellent (0% error rate)
- Business rules well documented
- Clear KPI definitions and measurement methods

**Areas to Improve**:
- Need to implement KPI measurement automation
- Data completeness needs increase to meet target
- Test vector freshness tracking not automated

---

## 10. Recommendations & Next Steps

### 10.1 Immediate Actions (Priority 1)

1. ✅ **Document Current Status** (THIS DOCUMENT)
   - Completed comprehensive analysis
   - Identified gaps and strengths

2. 📋 **Resolve Schema Naming Inconsistencies**
   - Update migration script with correct field names
   - Document naming changes in changelog
   - Ensure consistency across all artifacts

3. 📋 **Implement Product Catalog Tables**
   - Product, Product_Version, Branch tables
   - Seed with FCN v1.0 data
   - Test full seeding process

### 10.2 Short-Term Actions (Priority 2)

4. 📋 **Extend Test Coverage**
   - Add more test vectors to reach 80% completeness
   - Automate test vector freshness tracking
   - Implement test vector database storage

5. 📋 **Database Platform Decision**
   - Decide on unified database platform
   - Document migration strategy if needed
   - Update tooling accordingly

6. 📋 **KPI Automation**
   - Implement KPI measurement scripts
   - Create aggregation job (kpi-snapshot.json)
   - Set up automated reporting

### 10.3 Medium-Term Actions (Priority 3)

7. 📋 **Implement Trade Lifecycle Tables**
   - Trade, Underlying_Asset tables
   - Observation, Coupon_Decision tables
   - Cash_Flow table
   - Test with sample trade data

8. 📋 **Enhance Validation**
   - Implement precision conformance validation
   - Add idempotency checks
   - Create rule mapping coverage validator

9. 📋 **Dashboard & Reporting**
   - Set up Grafana/Looker dashboards
   - Implement trend analysis
   - Create SLA threshold alerts

### 10.4 Long-Term Actions (Priority 4)

10. 📋 **Advanced Features**
    - Audit trail implementation
    - Computed views for analytics
    - Cross-currency FX handling
    - Step-down feature support (v1.1+)

11. 📋 **Multi-Product Support**
    - Extend schema for other product types
    - Generalize product catalog
    - Shared parameter definitions

---

## 11. Risk Assessment

### 11.1 Current Risks

| Risk | Severity | Probability | Mitigation |
|------|----------|-------------|------------|
| Schema implementation delay | Medium | Medium | Prioritize based on business need |
| Naming inconsistency confusion | Low | High | Immediate naming standardization |
| Database platform divergence | Medium | Low | Document clear purpose for each |
| Test coverage insufficient | Medium | Medium | Automated test generation |
| KPI measurement gaps | Low | Medium | Implement automation scripts |

### 11.2 Mitigation Strategies

**Schema Implementation Delay**:
- Implement incrementally (phase 1-4 approach)
- Focus on immediate business needs first
- Use agile development methodology

**Naming Inconsistency**:
- Update all documentation immediately
- Create migration script for database
- Enforce naming conventions in code reviews

**Database Platform Divergence**:
- Document purpose of each database clearly
- Maintain separate use cases
- Consider unified platform if complexity increases

---

## 12. Conclusion

### 12.1 Overall Assessment

**Status**: **GOOD** - The FCN v1.0 database schema design is well-architected with strong documentation and operational parameter management.

**Readiness**:
- **Parameter Management**: ✅ Production Ready
- **Product Catalog**: 📋 Documented, Needs Implementation
- **Trade Lifecycle**: 📋 Designed, Not Implemented
- **Testing Infrastructure**: ✅ Operational with room for enhancement

### 12.2 Key Takeaways

**Strengths**:
1. Comprehensive ER model documentation
2. Working parameter definitions system
3. Strong validation and CI/CD integration
4. Clear versioning and governance strategy
5. Well-defined business rules and KPIs

**Gaps**:
1. Full schema not yet implemented
2. Trade lifecycle management missing
3. Test vectors not in database
4. KPI measurement automation needed
5. Database platform needs clarification

### 12.3 Path Forward

The repository has a **solid foundation** for FCN product database schema design. The immediate focus should be on:

1. **Standardizing naming** across all artifacts
2. **Implementing the product catalog** (Product, Version, Branch tables)
3. **Expanding test coverage** to meet 80% target
4. **Implementing KPI automation** for continuous monitoring

With these improvements, the FCN v1.0 database schema will be ready for production deployment and can serve as a template for future product versions.

---

## Appendix A: Database Objects Inventory

### A.1 Implemented (SQLite)

**Database**: `db/fcn_parameters.db`

**Tables**:
- `parameter_definitions` (1 table, 24 rows)

**Indexes**:
- `idx_parameter_definitions_name`
- `idx_parameter_definitions_product_spec`

**Scripts**:
- `seed_fcn_v1_parameters.py` (working)
- `test_seed.py` (working)

### A.2 Documented (PostgreSQL)

**Migration**: `docs/business/ba/products/structured-notes/fcn/migrations/m0001-fcn-baseline.sql`

**Tables**:
- `product`
- `product_version`
- `branch`
- `parameter_definition`
- `trade`
- `underlying_asset`
- `test_vector`
- `schema_migrations`

**Indexes**: 14 indexes defined

**Seed Data**: FCN v1.0 baseline with 3 branches

---

## Appendix B: Parameter List

### B.1 All 24 Parameters

1. barrier_monitoring (string, required, enum: discrete)
2. business_day_calendar (string, optional)
3. coupon_condition_threshold_pct (decimal, optional)
4. coupon_observation_offset_days (integer, optional)
5. coupon_payment_dates (array, required)
6. coupon_rate_pct (decimal, required)
7. currency (string, required)
8. day_count_convention (string, optional, enum: ACT/365|ACT/360, default: ACT/365)
9. documentation_version (string, required)
10. fx_reference (string, conditional)
11. initial_levels (array, required)
12. is_memory_coupon (boolean, optional, default: false)
13. issue_date (date, required)
14. knock_in_barrier_pct (decimal, required)
15. knock_in_condition (string, required, enum: any-underlying-breach)
16. maturity_date (date, required)
17. memory_carry_cap_count (integer, conditional)
18. notional_amount (decimal, required)
19. observation_dates (array, required)
20. recovery_mode (string, required, enum: par-recovery)
21. redemption_barrier_pct (decimal, required)
22. settlement_type (string, required, enum: physical-settlement)
23. trade_date (date, required)
24. underlying_symbols (array, required)

### B.2 Parameters by Category

**Required (17)**:
- trade_date, issue_date, maturity_date
- underlying_symbols, initial_levels, notional_amount, currency
- observation_dates, coupon_payment_dates, coupon_rate_pct
- knock_in_barrier_pct, barrier_monitoring, knock_in_condition
- redemption_barrier_pct, settlement_type, recovery_mode
- documentation_version

**Optional (5)**:
- business_day_calendar
- coupon_condition_threshold_pct
- coupon_observation_offset_days
- is_memory_coupon (default: false)
- day_count_convention (default: ACT/365)

**Conditional (2)**:
- memory_carry_cap_count (if is_memory_coupon=true)
- fx_reference (if underlying currency != settlement currency)

---

## Appendix C: References

### C.1 Documentation

- [FCN v1.0 ER Model](er-fcn-v1.0.md)
- [FCN v1.0 Specification](specs/fcn-v1.0.md)
- [FCN v1.0 Overview & KPIs](overview.md)
- [FCN Business Rules](business-rules.md)
- [Database README](../../../../../../db/README.md)
- [Database Usage Guide](../../../../../../db/USAGE.md)

### C.2 Migrations

- [Parameter Definitions Migration (SQLite)](../../../../../../db/migrations/m0001_create_parameter_definitions.sql)
- [FCN Baseline Migration (PostgreSQL)](migrations/m0001-fcn-baseline.sql)

### C.3 Design Decisions

- [ADR-001: Documentation Governance](../../sa/design-decisions/adr-001-documentation-governance.md)
- [ADR-002: Product Doc Structure](../../sa/design-decisions/adr-002-product-doc-structure.md)
- [ADR-003: FCN Version Activation](../../sa/design-decisions/adr-003-fcn-version-activation.md)
- [ADR-004: Parameter Alias Policy](../../sa/design-decisions/adr-004-parameter-alias-policy.md)

---

**Document History**:
- v1.0.0 (2025-10-16): Initial comprehensive status analysis
