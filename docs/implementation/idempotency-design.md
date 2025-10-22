---
title: Idempotency Design and Implementation
doc_type: implementation
status: Active
version: 1.0.0
date: 2025-10-22
owner: siripong.s@yuanta.co.th
classification: Internal
tags: [implementation, idempotency, middleware, fastapi]
related:
  - ../business/sa/design-decisions/adr-006-fcn-api-service-architecture.md
---

# Idempotency Design and Implementation

## Overview

This document describes the idempotency mechanism implemented for the FCN API service to ensure safe retry behavior for POST requests (template creation, trade booking, observation recording).

## Why Idempotency?

Financial operations must be idempotent to prevent:
- Duplicate trades from network retries
- Duplicate coupon payments
- Multiple observations for same date
- Double-charging or double-booking

Idempotency ensures that repeated identical requests produce the same result without side effects.

## Architecture

### Components

```
┌─────────────────────────────────────────────────────┐
│                   FastAPI App                       │
│                                                     │
│  ┌────────────────────────────────────────────┐   │
│  │      IdempotencyMiddleware                 │   │
│  │  - Intercepts POST requests                │   │
│  │  - Checks Idempotency-Key header           │   │
│  │  - Captures & caches responses             │   │
│  └──────────────┬─────────────────────────────┘   │
│                 │                                   │
│                 ▼                                   │
│  ┌────────────────────────────────────────────┐   │
│  │      IdempotencyService                    │   │
│  │  - Hash key computation                    │   │
│  │  - Fingerprint generation                  │   │
│  │  - Conflict detection                      │   │
│  └──────────────┬─────────────────────────────┘   │
│                 │                                   │
│                 ▼                                   │
│  ┌────────────────────────────────────────────┐   │
│  │      IdempotencyStore (Interface)          │   │
│  │  - get(key_hash)                           │   │
│  │  - set(record)                             │   │
│  │  - delete(key_hash)                        │   │
│  └──────┬──────────────────────────────┬──────┘   │
│         │                               │          │
└─────────┼───────────────────────────────┼──────────┘
          │                               │
          ▼                               ▼
┌──────────────────┐          ┌──────────────────┐
│  MSSQLStore      │          │   RedisStore     │
│  (Durable)       │          │   (Fast)         │
└──────────────────┘          └──────────────────┘
```

### Flow Diagram

```
Client Request
     │
     ├─ Has Idempotency-Key header?
     │  ├─ No  → Process normally
     │  └─ Yes → Continue
     │
     ├─ Compute key_hash = SHA256(idempotency_key)
     ├─ Compute fingerprint = SHA256(method|path|body_hash)
     │
     ├─ Existing record in store?
     │  ├─ No  → Continue
     │  └─ Yes → Check conflict
     │           ├─ Same fingerprint → Return cached response (200)
     │           └─ Different fingerprint → Return 409 Conflict
     │
     ├─ Process request
     │
     ├─ Response 2xx?
     │  ├─ Yes → Cache response + Store record
     │  └─ No  → Don't cache
     │
     └─ Return response
```

## Implementation Details

### 1. Idempotency-Key Header

Clients include `Idempotency-Key` header in POST requests:

```http
POST /api/v1/trades
Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000
Content-Type: application/json

{ "template_id": "TPL-001", ... }
```

**Key Requirements**:
- Unique per request intent
- Typically UUID v4
- Client-generated and client-managed
- Optional (middleware bypassed if absent)

### 2. Key Hashing

Raw idempotency key is hashed using SHA256:

```python
key_hash = hashlib.sha256(idempotency_key.encode('utf-8')).hexdigest()
```

**Why hash?**
- Normalize key length (always 64 hex chars)
- Privacy (obfuscate client key structure)
- Index efficiency (fixed-width string)

### 3. Request Fingerprinting

To detect conflicts (same key, different payload):

```python
body_hash = hashlib.sha256(body_bytes).hexdigest()
canonical = f"{method.upper()}|{path}|{body_hash}"
fingerprint = hashlib.sha256(canonical.encode('utf-8')).hexdigest()
```

**Components**:
- HTTP method (POST)
- Request path (/api/v1/trades)
- Body hash (SHA256 of raw body)

**Conflict Detection**:
- Same key + same fingerprint → Replay cached response
- Same key + different fingerprint → Return 409 Conflict

### 4. Response Capture

Middleware captures response body for successful (2xx) requests:

```python
if 200 <= response.status_code < 300:
    # Read and parse JSON response
    response_body = await response.body()
    response_json = json.loads(response_body)
    
    # Store record with JSON snapshot
    record = IdempotencyRecord(
        key_hash=key_hash,
        response_snapshot=json.dumps(response_json),
        ...
    )
```

**Limitations**:
- Only JSON responses captured (Content-Type: application/json)
- Non-JSON or streaming responses not cached
- Non-2xx responses never cached

### 5. TTL and Expiration

Records expire after configurable TTL (default 24 hours):

```python
expires_at = created_at + timedelta(hours=24)
```

**Cleanup**:
- MSSQL: Periodic cleanup job (future implementation)
- Redis: Automatic TTL-based expiration

## Storage Backends

### MSSQL Store (Default)

**Pros**:
- Durable persistence
- Transactional consistency
- No additional infrastructure
- Aligns with ADR-006

**Cons**:
- Slower than Redis (disk I/O)
- Requires cleanup job for expiration

**Table**: `fcn_idempotency_key`

```sql
SELECT * FROM fcn_idempotency_key
WHERE key_hash = '...' AND expires_at > GETUTCDATE();
```

### Redis Store (Optional)

**Pros**:
- Very fast (in-memory)
- Automatic TTL expiration
- High throughput

**Cons**:
- Ephemeral (data loss on restart)
- Requires Redis infrastructure
- Additional operational complexity

**Configuration**:

```python
import redis
from src.infra.idempotency.redis_store import RedisIdempotencyStore

redis_client = redis.Redis(host='localhost', port=6379, db=0)
store = RedisIdempotencyStore(redis_client)
```

**Key Pattern**: `fcn:idempotency:{key_hash}`

## API Behavior

### Scenario 1: First Request

```http
POST /api/v1/trades
Idempotency-Key: uuid-1
Content-Type: application/json

{ "template_id": "TPL-001" }
```

**Response**: 201 Created

```json
{
  "trade_id": "TRD-001",
  "status": "booked"
}
```

Record stored with response snapshot.

### Scenario 2: Duplicate Request (Replay)

```http
POST /api/v1/trades
Idempotency-Key: uuid-1
Content-Type: application/json

{ "template_id": "TPL-001" }
```

**Response**: 200 OK (cached)

```json
{
  "trade_id": "TRD-001",
  "status": "booked"
}
```

**Headers**: `X-Idempotency-Replay: true`

### Scenario 3: Conflicting Request

```http
POST /api/v1/trades
Idempotency-Key: uuid-1
Content-Type: application/json

{ "template_id": "TPL-002" }  // Different payload!
```

**Response**: 409 Conflict

```json
{
  "error": {
    "code": "IDEMPOTENCY_KEY_CONFLICT",
    "message": "Idempotency key reused with different payload",
    "details": {
      "idempotency_key": "uuid-1",
      "original_request": {
        "method": "POST",
        "path": "/api/v1/trades",
        "timestamp": "2025-10-22T10:30:00Z"
      }
    }
  }
}
```

## Configuration

### Environment Variables

```bash
# Database URL for MSSQL store
export DATABASE_URL="mssql+pyodbc://..."

# Redis URL for Redis store (optional)
export REDIS_URL="redis://localhost:6379/0"

# Idempotency TTL in hours (default: 24)
export IDEMPOTENCY_TTL_HOURS=24
```

### Middleware Registration

In `src/app/main.py`:

```python
from src.app.middleware.idempotency import IdempotencyMiddleware
from src.domain.services.idempotency import IdempotencyService
from src.infra.idempotency.mssql_store import MSSQLIdempotencyStore

# Initialize store and service
store = MSSQLIdempotencyStore(session_factory=SessionLocal)
service = IdempotencyService(store=store)

# Register middleware
app.add_middleware(
    IdempotencyMiddleware,
    idempotency_service=service,
    ttl_hours=24
)
```

## Testing

### Unit Tests

Test idempotency service methods:

```python
def test_hash_key():
    key = "test-key-123"
    hash1 = IdempotencyService.hash_key(key)
    hash2 = IdempotencyService.hash_key(key)
    assert hash1 == hash2
    assert len(hash1) == 64  # SHA256 hex

def test_compute_fingerprint():
    fp1 = IdempotencyService.compute_fingerprint("POST", "/api/v1/trades", b"{}")
    fp2 = IdempotencyService.compute_fingerprint("POST", "/api/v1/trades", b"{}")
    assert fp1 == fp2
```

### Integration Tests

Test middleware behavior:

```python
async def test_idempotency_replay():
    # First request
    response1 = await client.post(
        "/api/v1/trades",
        headers={"Idempotency-Key": "key-1"},
        json={"template_id": "TPL-001"}
    )
    assert response1.status_code == 201
    
    # Second request (replay)
    response2 = await client.post(
        "/api/v1/trades",
        headers={"Idempotency-Key": "key-1"},
        json={"template_id": "TPL-001"}
    )
    assert response2.status_code == 200
    assert response2.headers.get("X-Idempotency-Replay") == "true"
    assert response2.json() == response1.json()
```

### Conflict Test

```python
async def test_idempotency_conflict():
    # First request
    await client.post(
        "/api/v1/trades",
        headers={"Idempotency-Key": "key-2"},
        json={"template_id": "TPL-001"}
    )
    
    # Different payload, same key
    response = await client.post(
        "/api/v1/trades",
        headers={"Idempotency-Key": "key-2"},
        json={"template_id": "TPL-002"}
    )
    assert response.status_code == 409
    assert "IDEMPOTENCY_KEY_CONFLICT" in response.json()["error"]["code"]
```

## Security Considerations

### Key Privacy

Keys hashed before storage (SHA256) to prevent:
- Reverse engineering client key generation
- Exposure of client-side identifiers

### Request Tampering

Fingerprint includes body hash to detect payload modification.

### Replay Attacks

TTL limits window for cached response replay (default 24h).

### Information Disclosure

409 Conflict response reveals original request metadata (path, timestamp) but not payload.

## Performance

### MSSQL Backend

- **Lookup**: ~5-15 ms (indexed query)
- **Insert**: ~10-20 ms (transaction commit)
- **Throughput**: 100-500 req/s (single instance)

### Redis Backend

- **Lookup**: ~1-2 ms (in-memory)
- **Insert**: ~1-2 ms (in-memory)
- **Throughput**: 5,000-10,000 req/s

**Recommendation**: Use MSSQL for durability, Redis for high-volume scenarios.

## Future Enhancements

### 1. Cleanup Job

Automated expiration cleanup for MSSQL:

```sql
-- SQL Server Agent job (daily)
DELETE FROM fcn_idempotency_key
WHERE expires_at < GETUTCDATE();
```

### 2. Hybrid Backend

Use Redis for hot path, MSSQL for durability:
- Write to both Redis (fast lookup) and MSSQL (backup)
- Read from Redis first, fallback to MSSQL

### 3. Streaming Response Capture

Extend middleware to capture streaming/SSE responses using buffer.

### 4. Metrics

Add Prometheus metrics:
- `fcn_idempotency_hits_total` (cache hits)
- `fcn_idempotency_misses_total` (cache misses)
- `fcn_idempotency_conflicts_total` (409 responses)

### 5. Distributed Tracing

Add OpenTelemetry spans:
- `idempotency.check`
- `idempotency.store.get`
- `idempotency.store.set`

## References

- [RFC 9110 - HTTP Semantics](https://www.rfc-editor.org/rfc/rfc9110.html#name-idempotent-methods)
- [Stripe Idempotency Guide](https://stripe.com/docs/api/idempotent_requests)
- ADR-006: FCN API Service Architecture

## Change Log

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2025-10-22 | siripong.s@yuanta.co.th | Initial idempotency design documentation |
