# FCN API Service

FastAPI-based service for Fixed Coupon Note (FCN) product lifecycle management.

## Architecture

Following modular monolith pattern with clear layer separation:

```
src/
├── app/               # Application layer (FastAPI, controllers, middleware)
│   ├── middleware/    # Request/response middleware (idempotency, tracing)
│   └── main.py        # FastAPI application entry point
├── domain/            # Domain layer (business logic, services)
│   └── services/      # Domain services (idempotency, lifecycle)
├── infra/             # Infrastructure layer (database, external services)
│   ├── db/            # Database ORM models and migrations
│   │   ├── alembic/   # Alembic migration scripts
│   │   ├── base.py    # SQLAlchemy base configuration
│   │   └── models.py  # ORM models
│   └── idempotency/   # Idempotency storage backends
└── observability/     # Observability (tracing, metrics, logging) [future]
```

## Quick Start

### Prerequisites

- Python 3.9+
- Microsoft SQL Server (local or remote)
- ODBC Driver 18 for SQL Server

### Installation

```bash
# Install dependencies
pip install -r requirements.txt

# Copy environment template
cp .env.example .env

# Edit .env with your database credentials
```

### Database Setup

```bash
# Run migrations to create schema
alembic upgrade head

# Verify migration
alembic current
```

### Run Application

```bash
# Development mode with auto-reload
python src/app/main.py

# Or using uvicorn directly
uvicorn src.app.main:app --reload --host 0.0.0.0 --port 8000
```

### Access API

- **API Docs**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **Health Check**: http://localhost:8000/health

## API Endpoints

### Health Endpoints

```bash
# Basic health check
curl http://localhost:8000/health

# Readiness check
curl http://localhost:8000/health/ready
```

### Template Management (Stub)

```bash
# Create template
curl -X POST http://localhost:8000/api/v1/templates \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: $(uuidgen)" \
  -d '{"name": "FCN Template"}'
```

### Trade Booking (Stub)

```bash
# Book trade
curl -X POST http://localhost:8000/api/v1/trades \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: $(uuidgen)" \
  -d '{"template_id": "TPL-001"}'
```

### Observation Recording (Stub)

```bash
# Record observation
curl -X POST http://localhost:8000/api/v1/observations \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: $(uuidgen)" \
  -d '{"trade_id": "TRD-001"}'
```

## Idempotency

All POST endpoints support idempotency using the `Idempotency-Key` header:

```bash
# First request - creates resource
curl -X POST http://localhost:8000/api/v1/trades \
  -H "Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000" \
  -H "Content-Type: application/json" \
  -d '{"template_id": "TPL-001"}'
# Response: 201 Created

# Duplicate request - returns cached response
curl -X POST http://localhost:8000/api/v1/trades \
  -H "Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000" \
  -H "Content-Type: application/json" \
  -d '{"template_id": "TPL-001"}'
# Response: 200 OK (cached)
# Header: X-Idempotency-Replay: true

# Conflicting request - different payload with same key
curl -X POST http://localhost:8000/api/v1/trades \
  -H "Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000" \
  -H "Content-Type: application/json" \
  -d '{"template_id": "TPL-002"}'
# Response: 409 Conflict
```

See [docs/implementation/idempotency-design.md](../docs/implementation/idempotency-design.md) for details.

## Database Migrations

### Common Commands

```bash
# Check current migration version
alembic current

# View migration history
alembic history --verbose

# Upgrade to latest
alembic upgrade head

# Downgrade one revision
alembic downgrade -1

# Create new migration
alembic revision --autogenerate -m "Add new field"
```

See [docs/implementation/database-migrations.md](../docs/implementation/database-migrations.md) for details.

## Configuration

Environment variables (see `.env.example`):

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | MSSQL connection string | mssql+pyodbc://... |
| `REDIS_URL` | Redis connection string (optional) | redis://localhost:6379/0 |
| `IDEMPOTENCY_TTL_HOURS` | Idempotency record TTL | 24 |
| `APP_ENV` | Environment (development/production) | development |
| `LOG_LEVEL` | Logging level | info |

## Testing

```bash
# Run tests (future)
pytest

# Run with coverage (future)
pytest --cov=src --cov-report=html
```

## Development

### Code Structure

- **Models**: ORM models in `src/infra/db/models.py`
- **Services**: Domain services in `src/domain/services/`
- **Middleware**: Request/response middleware in `src/app/middleware/`
- **Routes**: API routes in `src/app/main.py` (will be extracted to separate routers)

### Adding New Migrations

1. Modify ORM models in `src/infra/db/models.py`
2. Generate migration: `alembic revision --autogenerate -m "description"`
3. Review generated migration in `src/infra/db/alembic/versions/`
4. Test: `alembic upgrade head` and `alembic downgrade -1`
5. Commit migration script

## References

- [ADR-006: FCN API Service Architecture](../docs/business/sa/design-decisions/adr-006-fcn-api-service-architecture.md)
- [Database Migrations](../docs/implementation/database-migrations.md)
- [Idempotency Design](../docs/implementation/idempotency-design.md)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Alembic Documentation](https://alembic.sqlalchemy.org/)
