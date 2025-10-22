"""
Redis-backed idempotency store implementation.

Provides fast, ephemeral storage for idempotency keys using Redis.
"""
from datetime import datetime
from typing import Optional
import json
import redis
from src.domain.services.idempotency import IdempotencyStore, IdempotencyRecord


class RedisIdempotencyStore(IdempotencyStore):
    """
    Redis implementation of idempotency store.
    
    Uses Redis with TTL for automatic expiration.
    """
    
    def __init__(self, redis_client: redis.Redis):
        """
        Initialize Redis idempotency store.
        
        Args:
            redis_client: Redis client instance
        """
        self.redis = redis_client
        self.key_prefix = "fcn:idempotency:"
    
    def _make_key(self, key_hash: str) -> str:
        """Generate Redis key with prefix."""
        return f"{self.key_prefix}{key_hash}"
    
    async def get(self, key_hash: str) -> Optional[IdempotencyRecord]:
        """
        Retrieve idempotency record from Redis.
        
        Args:
            key_hash: SHA256 hash of idempotency key
            
        Returns:
            IdempotencyRecord if found, None otherwise
        """
        redis_key = self._make_key(key_hash)
        data = self.redis.get(redis_key)
        
        if not data:
            return None
        
        record_dict = json.loads(data)
        return IdempotencyRecord(
            key_hash=record_dict["key_hash"],
            request_fingerprint=record_dict["request_fingerprint"],
            request_method=record_dict["request_method"],
            request_path=record_dict["request_path"],
            response_status=record_dict["response_status"],
            response_snapshot=record_dict["response_snapshot"],
            created_at=datetime.fromisoformat(record_dict["created_at"]),
            expires_at=datetime.fromisoformat(record_dict["expires_at"]),
        )
    
    async def set(self, record: IdempotencyRecord) -> None:
        """
        Store idempotency record in Redis with TTL.
        
        Args:
            record: IdempotencyRecord to store
        """
        redis_key = self._make_key(record.key_hash)
        
        # Serialize record to JSON
        record_dict = {
            "key_hash": record.key_hash,
            "request_fingerprint": record.request_fingerprint,
            "request_method": record.request_method,
            "request_path": record.request_path,
            "response_status": record.response_status,
            "response_snapshot": record.response_snapshot,
            "created_at": record.created_at.isoformat(),
            "expires_at": record.expires_at.isoformat(),
        }
        
        # Calculate TTL in seconds
        ttl_seconds = int((record.expires_at - datetime.utcnow()).total_seconds())
        if ttl_seconds > 0:
            self.redis.setex(
                redis_key,
                ttl_seconds,
                json.dumps(record_dict)
            )
    
    async def delete(self, key_hash: str) -> None:
        """
        Delete idempotency record from Redis.
        
        Args:
            key_hash: SHA256 hash of idempotency key
        """
        redis_key = self._make_key(key_hash)
        self.redis.delete(redis_key)
