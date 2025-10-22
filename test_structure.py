#!/usr/bin/env python3
"""
Test script to verify FCN API structure and configuration.
"""
import sys
sys.path.insert(0, '.')

print("=" * 70)
print("FCN API Structure Verification")
print("=" * 70)

# Test 1: Import all core modules
print("\n1. Testing module imports...")
try:
    from src.infra.db.models import (
        TemplateORM, TradeORM, ObservationORM, 
        LifecycleEventORM, IdempotencyKeyORM
    )
    print("   ✓ ORM models imported")
    
    from src.domain.services.idempotency import (
        IdempotencyService, IdempotencyRecord, IdempotencyStore
    )
    print("   ✓ Idempotency service imported")
    
    from src.infra.idempotency.mssql_store import MSSQLIdempotencyStore
    print("   ✓ MSSQL store imported")
    
    from src.infra.idempotency.redis_store import RedisIdempotencyStore
    print("   ✓ Redis store imported")
    
    from src.app.middleware.idempotency import IdempotencyMiddleware
    print("   ✓ Idempotency middleware imported")
    
    from src.app.main import app
    print("   ✓ FastAPI app imported")
    
except Exception as e:
    print(f"   ✗ Import failed: {e}")
    sys.exit(1)

# Test 2: Verify FastAPI configuration
print("\n2. Testing FastAPI configuration...")
print(f"   App title: {app.title}")
print(f"   App version: {app.version}")
print(f"   Routes registered: {sum(1 for r in app.routes if hasattr(r, 'path'))}")

# Test 3: Verify idempotency logic
print("\n3. Testing idempotency service logic...")
from datetime import datetime, timedelta, timezone

def utcnow():
    """Return current UTC time as timezone-aware datetime."""
    return datetime.now(timezone.utc)

# Test key hashing
key = "test-key-12345"
hash1 = IdempotencyService.hash_key(key)
hash2 = IdempotencyService.hash_key(key)
assert hash1 == hash2, "Key hashing not deterministic"
assert len(hash1) == 64, "Hash length incorrect"
print(f"   ✓ Key hashing: {key[:20]}... -> {hash1[:16]}...")

# Test fingerprint
body1 = b'{"template_id": "TPL-001"}'
body2 = b'{"template_id": "TPL-002"}'
fp1 = IdempotencyService.compute_fingerprint("POST", "/api/v1/trades", body1)
fp2 = IdempotencyService.compute_fingerprint("POST", "/api/v1/trades", body1)
fp3 = IdempotencyService.compute_fingerprint("POST", "/api/v1/trades", body2)
assert fp1 == fp2, "Fingerprint not deterministic"
assert fp1 != fp3, "Different payloads should have different fingerprints"
print(f"   ✓ Fingerprint generation: deterministic and unique")

# Test conflict detection
record = IdempotencyRecord(
    key_hash=hash1,
    request_fingerprint=fp1,
    request_method="POST",
    request_path="/api/v1/trades",
    response_status=201,
    response_snapshot='{"trade_id": "TRD-001"}',
    created_at=utcnow(),
    expires_at=utcnow() + timedelta(hours=24)
)

service = IdempotencyService(store=None)
assert not service.check_conflict(record, fp1), "Same fingerprint incorrectly flagged as conflict"
assert service.check_conflict(record, fp3), "Different fingerprint not detected as conflict"
print(f"   ✓ Conflict detection: working correctly")

# Test 4: List available endpoints
print("\n4. Available API endpoints:")
endpoints = []
for route in app.routes:
    if hasattr(route, 'methods') and hasattr(route, 'path'):
        for method in sorted(route.methods):
            if method != "HEAD":  # Skip HEAD methods
                endpoints.append((method, route.path))

for method, path in sorted(endpoints):
    print(f"   [{method:6s}] {path}")

# Test 5: Verify middleware stack
print("\n5. Middleware stack:")
for middleware in app.user_middleware:
    print(f"   - {middleware.cls.__name__}")

# Test 6: Verify ORM models structure
print("\n6. ORM models structure:")
models = [TemplateORM, TradeORM, ObservationORM, LifecycleEventORM, IdempotencyKeyORM]
for model in models:
    table_name = model.__tablename__
    column_count = len(model.__table__.columns)
    print(f"   - {table_name:25s} ({column_count} columns)")

print("\n" + "=" * 70)
print("✓ All structure verification tests passed!")
print("=" * 70)
print("\nNext steps:")
print("  1. Set up MSSQL database")
print("  2. Run: alembic upgrade head")
print("  3. Start server: python src/app/main.py")
print("  4. Access docs: http://localhost:8000/docs")
print("=" * 70)
