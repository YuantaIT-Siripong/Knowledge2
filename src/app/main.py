"""
FCN API main application.

FastAPI application with idempotency middleware, health endpoints,
and observability integration.
"""
from fastapi import FastAPI, Depends
from fastapi.responses import JSONResponse
from datetime import datetime, timezone
import os

from src.app.middleware.idempotency import IdempotencyMiddleware
from src.domain.services.idempotency import IdempotencyService
from src.infra.idempotency.mssql_store import MSSQLIdempotencyStore
from src.infra.db.base import SessionLocal


def utcnow():
    """Return current UTC time as timezone-aware datetime."""
    return datetime.now(timezone.utc)

# Create FastAPI application
app = FastAPI(
    title="FCN API Service",
    description="Fixed Coupon Note API with idempotency and tracing",
    version="0.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
)


# Initialize idempotency service with MSSQL backend
def get_session_factory():
    """Return session factory for dependency injection."""
    return SessionLocal


idempotency_store = MSSQLIdempotencyStore(session_factory=get_session_factory)
idempotency_service = IdempotencyService(store=idempotency_store)

# Register idempotency middleware
app.add_middleware(
    IdempotencyMiddleware,
    idempotency_service=idempotency_service,
    ttl_hours=24
)


@app.get("/health")
async def health_check():
    """
    Health check endpoint.
    
    Returns basic service health status.
    """
    return JSONResponse(
        status_code=200,
        content={
            "status": "healthy",
            "service": "fcn-api",
            "timestamp": utcnow().isoformat(),
            "version": "0.1.0"
        }
    )


@app.get("/health/ready")
async def readiness_check():
    """
    Readiness check endpoint.
    
    Verifies service is ready to accept requests (DB connectivity, etc.).
    """
    # TODO: Add DB connectivity check
    return JSONResponse(
        status_code=200,
        content={
            "status": "ready",
            "service": "fcn-api",
            "timestamp": utcnow().isoformat()
        }
    )


@app.post("/api/v1/templates")
async def create_template():
    """
    Create FCN template endpoint (stub).
    
    This endpoint will be implemented with full business logic.
    For now, it serves as a test endpoint for idempotency middleware.
    """
    return JSONResponse(
        status_code=201,
        content={
            "template_id": "TPL-001",
            "status": "created",
            "message": "Template created successfully"
        }
    )


@app.post("/api/v1/trades")
async def book_trade():
    """
    Book FCN trade endpoint (stub).
    
    This endpoint will be implemented with full business logic.
    For now, it serves as a test endpoint for idempotency middleware.
    """
    return JSONResponse(
        status_code=201,
        content={
            "trade_id": "TRD-001",
            "status": "booked",
            "message": "Trade booked successfully"
        }
    )


@app.post("/api/v1/observations")
async def record_observation():
    """
    Record observation endpoint (stub).
    
    This endpoint will be implemented with full business logic.
    For now, it serves as a test endpoint for idempotency middleware.
    """
    return JSONResponse(
        status_code=201,
        content={
            "observation_id": "OBS-001",
            "status": "recorded",
            "message": "Observation recorded successfully"
        }
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "src.app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
