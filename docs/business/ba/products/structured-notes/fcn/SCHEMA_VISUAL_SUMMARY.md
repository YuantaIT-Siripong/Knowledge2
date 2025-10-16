---
title: FCN v1.0 Database Schema - Visual Summary
doc_type: reference
status: Draft
version: 1.0.0
owner: siripong.s@yuanta.co.th
created: 2025-10-16
classification: Internal
tags: [fcn, database-schema, visual, reference]
related:
  - STATUS_REPORT.md
  - er-fcn-v1.0.md
---

# FCN v1.0 Database Schema - Visual Summary

## 1. Database Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    FCN v1.0 Database Schema                     │
│                                                                 │
│  ┌─────────────────┐         ┌─────────────────┐              │
│  │   IMPLEMENTED   │         │   DOCUMENTED    │              │
│  │    (SQLite)     │         │  (PostgreSQL)   │              │
│  └─────────────────┘         └─────────────────┘              │
│          │                            │                         │
│          │                            │                         │
│          ▼                            ▼                         │
│  ┌───────────────┐          ┌──────────────────┐              │
│  │  parameter_   │          │ Full ER Model:   │              │
│  │  definitions  │          │ • Product        │              │
│  │  (24 params)  │          │ • Product_Version│              │
│  │      ✓        │          │ • Branch         │              │
│  └───────────────┘          │ • Trade          │              │
│                             │ • Observation    │              │
│                             │ • Cash_Flow      │              │
│                             │ • etc. (12 total)│              │
│                             │      📋          │              │
│                             └──────────────────┘              │
└─────────────────────────────────────────────────────────────────┘

Legend: ✓ = Implemented & Tested  |  📋 = Documented Only
```

## 2. Implemented Schema (Current State)

```
┌─────────────────────────────────────────────────────────────────┐
│                    parameter_definitions                        │
├────────────────────┬──────────────┬──────────────────────────────┤
│ id                 │ INTEGER      │ PK                          │
│ name               │ TEXT         │ UNIQUE                      │
│ data_type          │ TEXT         │ string/date/decimal/etc     │
│ required_flag      │ BOOLEAN      │ Is required?                │
│ default_value      │ TEXT         │ JSON-encoded                │
│ enum_domain        │ TEXT         │ Pipe-separated values       │
│ min_value          │ NUMERIC      │ Minimum constraint          │
│ max_value          │ NUMERIC      │ Maximum constraint          │
│ pattern            │ TEXT         │ Regex pattern               │
│ description        │ TEXT         │ Parameter description       │
│ constraints        │ TEXT         │ Additional constraints      │
│ product_type       │ TEXT         │ 'fcn'                       │
│ spec_version       │ TEXT         │ '1.0.0'                     │
│ created_at         │ TIMESTAMP    │ Creation time               │
│ updated_at         │ TIMESTAMP    │ Update time                 │
└────────────────────┴──────────────┴──────────────────────────────┘

Indexes:
  • idx_parameter_definitions_name (name)
  • idx_parameter_definitions_product_spec (product_type, spec_version)

Data: 24 parameters, all validated ✓
```

## 3. Documented Full ER Model (Target State)

### 3.1 Product Catalog Layer

```
┌──────────────┐
│   Product    │
│   (FCN)      │
└──────┬───────┘
       │
       │ 1:M
       ▼
┌──────────────────┐
│ Product_Version  │
│  (1.0.0)         │
└──────┬───────────┘
       │
       │ 1:M
       ▼
┌──────────────────┐
│     Branch       │
│ • fcn-base-mem   │
│ • fcn-base-nomem │
│ • fcn-base-mem-  │
│   proploss       │
└──────────────────┘
```

### 3.2 Trade Management Layer

```
┌──────────────┐
│    Trade     │
│              │
│ • trade_date │
│ • issue_date │
│ • maturity   │
│ • notional   │
│ • barriers   │
└──────┬───────┘
       │
       │ 1:M
       ▼
┌─────────────────┐
│ Underlying_Asset│
│                 │
│ • symbol        │
│ • initial_level │
│ • weight        │
└─────────────────┘
```

### 3.3 Lifecycle Management Layer

```
┌──────────────┐
│    Trade     │
└──────┬───────┘
       │
       │ 1:M
       ▼
┌──────────────────┐
│   Observation    │◄───┐
│                  │    │
│ • obs_date       │    │
│ • obs_index      │    │
│ • is_processed   │    │
└──────┬───────────┘    │
       │                │
       │ 1:M            │ M:1
       ▼                │
┌────────────────────┐  │
│ Underlying_Level   │──┘
│                    │
│ • level            │
│ • performance_pct  │
└────────────────────┘
       │
       │ 1:1
       ▼
┌──────────────────┐
│ Coupon_Decision  │
│                  │
│ • barrier_breach │
│ • coupon_paid    │
│ • missed_coupons │
└──────────────────┘
       │
       │ 1:M
       ▼
┌──────────────────┐
│   Cash_Flow      │
│                  │
│ • flow_type      │
│ • flow_date      │
│ • amount         │
└──────────────────┘
```

### 3.4 Complete Entity Relationship

```
                    Product
                       │
                       │ 1:M
                       ▼
                 Product_Version ──────► Parameter_Definition
                       │
                       │ 1:M
                       ▼
    Test_Vector ◄──   Branch
                       │
                       │ 1:M
                       ▼
                     Trade
                       │
            ┌──────────┼──────────┐
            │          │          │
         1:M│       1:M│       0:1│
            ▼          ▼          ▼
    Underlying_  Observation  Knock_In_
       Asset        │          Trigger
                    │
              ┌─────┼─────┐
              │           │
           1:M│        1:1│
              ▼           ▼
       Underlying_   Coupon_
          Level      Decision
                         │
                      1:M│
                         ▼
                    Cash_Flow
```

## 4. Parameter Distribution

### 4.1 By Type

```
Parameters by Data Type (24 total)
═══════════════════════════════════

String    ████████     8 params (33%)
Decimal   ██████       6 params (25%)
Date      ███          3 params (13%)
Array     ████         4 params (17%)
Boolean   █            1 param  (4%)
Integer   ██           2 params (8%)
```

### 4.2 By Requirement Status

```
Parameters by Required Status
═══════════════════════════════

Required     ████████████████  17 params (71%)
Optional     █████             5 params  (21%)
Conditional  ██                2 params  (8%)
```

### 4.3 By Category

```
Trade Dates            │ ███         │ 3 params
Underlying & Notional  │ ████        │ 4 params
Observation & Coupon   │ ███████     │ 7 params
Barrier & Settlement   │ ██████      │ 6 params
Other                  │ ████        │ 4 params
```

## 5. Implementation Status Matrix

```
┌─────────────────────────┬──────────────┬────────────┬────────┐
│ Entity                  │ Documented   │ Implemented│ Status │
├─────────────────────────┼──────────────┼────────────┼────────┤
│ parameter_definitions   │      ✓       │     ✓      │   ✓    │
│ Product                 │      ✓       │     ✗      │   📋   │
│ Product_Version         │      ✓       │     ✗      │   📋   │
│ Branch                  │      ✓       │     ✗      │   📋   │
│ Trade                   │      ✓       │     ✗      │   📋   │
│ Underlying_Asset        │      ✓       │     ✗      │   📋   │
│ Observation             │      ✓       │     ✗      │   📋   │
│ Underlying_Level        │      ✓       │     ✗      │   📋   │
│ Coupon_Decision         │      ✓       │     ✗      │   📋   │
│ Knock_In_Trigger        │      ✓       │     ✗      │   📋   │
│ Cash_Flow               │      ✓       │     ✗      │   📋   │
│ Test_Vector             │      ✓       │     ✗      │   📋   │
└─────────────────────────┴──────────────┴────────────┴────────┘

Legend: ✓ = Done  |  ✗ = Not Yet  |  📋 = Documentation Phase
```

## 6. Validation Pipeline

```
┌───────────────────────────────────────────────────────────┐
│              FCN Validation Pipeline (CI/CD)              │
└───────────────────────────────────────────────────────────┘

     ┌──────────────────────┐
     │ Test Vector Ingest   │
     │   ingest_vectors.py  │
     └──────────┬───────────┘
                │
                ▼
     ┌──────────────────────┐
     │  Phase 0: Metadata   │
     │   metadata_validator │
     └──────────┬───────────┘
                │
                ▼
     ┌──────────────────────┐
     │  Phase 1: Taxonomy   │
     │  taxonomy_validator  │
     └──────────┬───────────┘
                │
                ▼
     ┌──────────────────────┐
     │  Phase 2: Parameters │
     │  parameter_validator │
     └──────────┬───────────┘
                │
                ▼
     ┌──────────────────────┐
     │   Generate Reports   │
     │   Upload Artifacts   │
     └──────────────────────┘

Status: ✅ All Phases Operational
```

## 7. Data Flow

### 7.1 Parameter Definition Flow

```
┌──────────────────┐
│  JSON Schema     │
│  fcn-v1.0-       │
│  parameters.     │
│  schema.json     │
└────────┬─────────┘
         │
         │ Python Script
         │ seed_fcn_v1_parameters.py
         │
         ▼
┌────────────────────┐
│  SQLite Database   │
│  fcn_parameters.db │
│                    │
│  • 24 parameters   │
│  • All validated ✓ │
└────────────────────┘
         │
         │ Used by
         │
         ▼
┌────────────────────┐
│   Validators       │
│   • parameter      │
│   • taxonomy       │
│   • metadata       │
└────────────────────┘
```

### 7.2 Trade Lifecycle Flow (Planned)

```
Trade Booking
     │
     ▼
┌─────────────────┐
│     Trade       │
│   (created)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Observation    │
│   (scheduled)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Market Levels   │
│  (captured)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Coupon        │
│   Decision      │
│  (evaluated)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Cash Flow     │
│  (generated)    │
└─────────────────┘
```

## 8. Branch Taxonomy

```
FCN v1.0 Branches (3 branches defined)
═══════════════════════════════════════

┌─────────────────────────────────────────────────────────┐
│ fcn-base-mem                                            │
│ ────────────────────────────────────────────────────── │
│ • Barrier: down-in                                      │
│ • Settlement: physical-settlement                       │
│ • Coupon Memory: memory                                 │
│ • Step: no-step                                         │
│ • Recovery: par-recovery                                │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ fcn-base-nomem                                          │
│ ────────────────────────────────────────────────────── │
│ • Barrier: down-in                                      │
│ • Settlement: physical-settlement                       │
│ • Coupon Memory: no-memory                              │
│ • Step: no-step                                         │
│ • Recovery: par-recovery                                │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ fcn-base-mem-proploss                                   │
│ ────────────────────────────────────────────────────── │
│ • Barrier: down-in                                      │
│ • Settlement: physical-settlement                       │
│ • Coupon Memory: memory                                 │
│ • Step: no-step                                         │
│ • Recovery: proportional-loss                           │
└─────────────────────────────────────────────────────────┘
```

## 9. Version Lifecycle

```
Draft → Proposed → Active → Deprecated → Removed
  │        │         │          │           │
  │        │         │          │           └─► No new trades
  │        │         │          └─────────────► Phase-out
  │        │         └────────────────────────► Production
  │        └──────────────────────────────────► Ready for approval
  └───────────────────────────────────────────► Development

Current Status: FCN v1.0 = Proposed (per m0001 seed data)
```

## 10. Key Metrics

```
┌────────────────────────────────────────────────────┐
│              Current Implementation                │
├────────────────────────────────────────────────────┤
│ Entities Implemented:      1 / 12    (8%)         │
│ Parameters Defined:        24 / 24   (100%)       │
│ Test Vectors:              5 documented           │
│ Validators:                7 implemented          │
│ Business Rules:            19 documented          │
│ Test Pass Rate:            100%                   │
│ CI/CD Integration:         ✓ Configured           │
│ Documentation:             ✓ Comprehensive        │
└────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────┐
│                  Quality Metrics                   │
├────────────────────────────────────────────────────┤
│ Parameter Error Rate:      0%      (Target: <2%)  │
│ Data Completeness:         ~60%    (Target: ≥80%) │
│ Rule Mapping Coverage:     95%     (Target: 100%) │
└────────────────────────────────────────────────────┘
```

## 11. Next Implementation Steps

```
Priority 1: Product Catalog
┌─────────────────────────┐
│ ☐ Product table         │
│ ☐ Product_Version table │
│ ☐ Branch table          │
│ ☐ Seed FCN v1.0 data    │
└─────────────────────────┘

Priority 2: Trade Management
┌─────────────────────────┐
│ ☐ Trade table           │
│ ☐ Underlying_Asset      │
│ ☐ Sample trade data     │
└─────────────────────────┘

Priority 3: Lifecycle
┌─────────────────────────┐
│ ☐ Observation table     │
│ ☐ Coupon_Decision       │
│ ☐ Cash_Flow             │
│ ☐ Knock_In_Trigger      │
└─────────────────────────┘

Priority 4: Testing
┌─────────────────────────┐
│ ☐ Test_Vector table     │
│ ☐ Seed test vectors     │
│ ☐ Enhance validators    │
└─────────────────────────┘
```

## 12. File Locations Quick Reference

```
📁 Database Files
├── db/
│   ├── README.md                        # Parameter definitions docs
│   ├── USAGE.md                         # Quick start guide
│   ├── migrations/
│   │   └── m0001_create_parameter_definitions.sql  ✓
│   ├── schemas/
│   │   └── fcn-v1.0-parameters.schema.json         ✓
│   ├── seeds/
│   │   ├── seed_fcn_v1_parameters.py               ✓
│   │   └── test_seed.py                            ✓
│   └── fcn_parameters.db                           ✓ (generated)

📁 FCN Documentation
├── docs/business/ba/products/structured-notes/fcn/
│   ├── er-fcn-v1.0.md                   # ER model          ✓
│   ├── specs/fcn-v1.0.md                # Specification     ✓
│   ├── overview.md                      # KPIs & overview   ✓
│   ├── business-rules.md                # BR-001 to BR-019  ✓
│   ├── STATUS_REPORT.md                 # This analysis     ✓
│   ├── SCHEMA_VISUAL_SUMMARY.md         # Visual guide      ✓
│   ├── migrations/
│   │   └── m0001-fcn-baseline.sql       # Full schema      📋
│   └── validators/                      # Python validators ✓

📁 Workflows
└── .github/workflows/
    └── fcn-validators.yml               # CI/CD pipeline    ✓

Legend: ✓ = Exists & Working  |  📋 = Documented Only
```

---

## Conclusion

This visual summary provides an at-a-glance overview of the FCN v1.0 database schema design status. Key takeaways:

**✅ Strengths**:
- Well-documented comprehensive design
- Working parameter management system
- Strong validation infrastructure
- Clear implementation roadmap

**📋 In Progress**:
- Full ER model implementation
- Trade lifecycle management
- Test vector database storage
- KPI automation

For detailed analysis, see [STATUS_REPORT.md](STATUS_REPORT.md).

---

**Document History**:
- v1.0.0 (2025-10-16): Initial visual summary
