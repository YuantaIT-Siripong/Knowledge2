"""
Idempotency middleware for FastAPI.

Intercepts POST requests with Idempotency-Key header and ensures
idempotent processing with response capture.
"""
from datetime import datetime, timedelta
from typing import Callable
import json
from fastapi import Request, Response
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp
import io

from src.domain.services.idempotency import IdempotencyService, IdempotencyRecord


class IdempotencyMiddleware(BaseHTTPMiddleware):
    """
    Middleware for handling idempotent POST requests.
    
    Captures request/response and replays cached responses for duplicate
    idempotency keys. Returns 409 Conflict if same key used with different payload.
    """
    
    def __init__(
        self,
        app: ASGIApp,
        idempotency_service: IdempotencyService,
        ttl_hours: int = 24
    ):
        """
        Initialize idempotency middleware.
        
        Args:
            app: ASGI application
            idempotency_service: Service for idempotency key management
            ttl_hours: Time-to-live for idempotency records in hours
        """
        super().__init__(app)
        self.idempotency_service = idempotency_service
        self.ttl_hours = ttl_hours
        self.idempotency_header = "Idempotency-Key"
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """
        Process request with idempotency handling.
        
        Args:
            request: Incoming request
            call_next: Next middleware/handler in chain
            
        Returns:
            Response (cached or fresh)
        """
        # Only process POST requests with idempotency key
        if request.method != "POST":
            return await call_next(request)
        
        idempotency_key = request.headers.get(self.idempotency_header)
        if not idempotency_key:
            return await call_next(request)
        
        # Read request body for fingerprint computation
        body = await request.body()
        
        # Compute request fingerprint
        request_fingerprint = self.idempotency_service.compute_fingerprint(
            method=request.method,
            path=str(request.url.path),
            body=body
        )
        
        # Check for existing record
        existing = await self.idempotency_service.get_record(idempotency_key)
        
        if existing:
            # Check for conflict (same key, different payload)
            if self.idempotency_service.check_conflict(existing, request_fingerprint):
                return JSONResponse(
                    status_code=409,
                    content={
                        "error": {
                            "code": "IDEMPOTENCY_KEY_CONFLICT",
                            "message": "Idempotency key reused with different payload",
                            "details": {
                                "idempotency_key": idempotency_key,
                                "original_request": {
                                    "method": existing.request_method,
                                    "path": existing.request_path,
                                    "timestamp": existing.created_at.isoformat()
                                }
                            }
                        }
                    }
                )
            
            # Replay cached response
            cached_response = json.loads(existing.response_snapshot)
            return JSONResponse(
                status_code=existing.response_status,
                content=cached_response,
                headers={"X-Idempotency-Replay": "true"}
            )
        
        # Process request and capture response
        response = await call_next(request)
        
        # Only cache successful responses (2xx)
        if 200 <= response.status_code < 300:
            # Read response body
            response_body = b""
            async for chunk in response.body_iterator:
                response_body += chunk
            
            # Parse JSON response
            try:
                response_json = json.loads(response_body.decode('utf-8'))
            except (json.JSONDecodeError, UnicodeDecodeError):
                # If response is not JSON, don't cache
                return Response(
                    content=response_body,
                    status_code=response.status_code,
                    headers=dict(response.headers),
                    media_type=response.media_type
                )
            
            # Store idempotency record
            key_hash = self.idempotency_service.hash_key(idempotency_key)
            now = datetime.utcnow()
            record = IdempotencyRecord(
                key_hash=key_hash,
                request_fingerprint=request_fingerprint,
                request_method=request.method,
                request_path=str(request.url.path),
                response_status=response.status_code,
                response_snapshot=json.dumps(response_json),
                created_at=now,
                expires_at=now + timedelta(hours=self.ttl_hours)
            )
            
            try:
                await self.idempotency_service.store_record(record)
            except Exception as e:
                # Log error but don't fail request
                print(f"Failed to store idempotency record: {e}")
            
            # Return response with captured body
            return JSONResponse(
                status_code=response.status_code,
                content=response_json,
                headers=dict(response.headers)
            )
        
        # Return non-2xx responses as-is (don't cache)
        return response
