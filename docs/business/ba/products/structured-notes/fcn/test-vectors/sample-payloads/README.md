# FCN v1.0 Sample Payloads

This directory contains JSON payloads for FCN v1.0 parameter validation testing.

## Purpose

These payloads are used by the Phase 2 Parameter Schema Conformance Validator (`docs/scripts/validate-fcn-params.py`) to test:
- JSON Schema compliance
- Cross-field business rule validation
- Data type and format validation
- Constraint validation

## Valid Payloads

These payloads conform to the FCN v1.0 specification and pass all validation rules:

### `fcn-v1.0-n1-payload.json`
- Based on test vector N1 (Base Memory – All Coupons Pay, No KI)
- Single underlying (ABC)
- Memory coupon enabled
- All observation dates trigger coupon payments
- No knock-in event

### `fcn-v1.0-n2-payload.json`
- Based on test vector N2 (Base Memory – Single Miss Recovered)
- Single underlying (ABC)
- Memory coupon enabled
- Demonstrates memory accumulation and recovery

### `fcn-v1.0-n4-payload.json`
- Based on test vector N4 (Base Non-Memory – Baseline With Miss)
- Single underlying (ABC)
- Memory coupon disabled (`is_memory_coupon: false`)
- Demonstrates non-memory behavior

### `fcn-v1.0-multi-underlying-payload.json`
- Basket product with three underlyings (ABC, XYZ, DEF)
- Memory coupon enabled with cap (`memory_carry_cap_count: 3`)
- Demonstrates multi-underlying array length validation

## Invalid Payloads (for Testing)

These payloads intentionally contain violations to test the validator's error detection:

### `fcn-v1.0-invalid-payload.json`
Contains multiple violations:
1. **Array Length Mismatch**: `underlying_symbols` has 2 items but `initial_levels` has only 1
2. **Non-Strictly Increasing Dates**: `observation_dates[3]` equals `observation_dates[2]` (2026-06-30)
3. **Array Length Mismatch**: `coupon_payment_dates` has 4 items but `observation_dates` has 5
4. **Conditional Null Violation**: `memory_carry_cap_count` is non-null when `is_memory_coupon` is false

## Validation

To validate all payloads in this directory:

```bash
python3 docs/scripts/validate-fcn-params.py
```

The validator will:
- Test all JSON files in this directory
- Check against the JSON Schema at `docs/business/ba/products/structured-notes/fcn/schemas/fcn-v1.0-schema.json`
- Apply cross-field business rules
- Generate `param-validation.json` in the repository root

## Related Documentation

- FCN v1.0 Specification: `../../specs/fcn-v1.0.md`
- JSON Schema: `../../schemas/fcn-v1.0-schema.json`
- Test Vectors: `../` (parent directory)
- Validator Documentation: `../../../../../scripts/README.md`
