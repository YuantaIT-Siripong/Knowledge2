"""
Idempotency service domain abstraction.

Provides interface for idempotency key management and request deduplication.
"""
from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime
from typing import Optional
import hashlib
import json


@dataclass
class IdempotencyRecord:
    """
    Idempotency record containing request and response data.
    """
    key_hash: str
    request_fingerprint: str
    request_method: str
    request_path: str
    response_status: int
    response_snapshot: str
    created_at: datetime
    expires_at: datetime


class IdempotencyStore(ABC):
    """
    Abstract interface for idempotency key storage backend.
    """
    
    @abstractmethod
    async def get(self, key_hash: str) -> Optional[IdempotencyRecord]:
        """
        Retrieve idempotency record by key hash.
        
        Args:
            key_hash: SHA256 hash of idempotency key
            
        Returns:
            IdempotencyRecord if found and not expired, None otherwise
        """
        pass
    
    @abstractmethod
    async def set(self, record: IdempotencyRecord) -> None:
        """
        Store idempotency record.
        
        Args:
            record: IdempotencyRecord to store
        """
        pass
    
    @abstractmethod
    async def delete(self, key_hash: str) -> None:
        """
        Delete idempotency record by key hash.
        
        Args:
            key_hash: SHA256 hash of idempotency key
        """
        pass


class IdempotencyService:
    """
    Idempotency service for request deduplication.
    
    Provides methods to compute canonical fingerprints and manage
    idempotency keys with pluggable storage backends.
    """
    
    def __init__(self, store: IdempotencyStore):
        """
        Initialize idempotency service.
        
        Args:
            store: Storage backend for idempotency records
        """
        self.store = store
    
    @staticmethod
    def hash_key(idempotency_key: str) -> str:
        """
        Hash idempotency key using SHA256.
        
        Args:
            idempotency_key: Raw idempotency key from request header
            
        Returns:
            Hex-encoded SHA256 hash
        """
        return hashlib.sha256(idempotency_key.encode('utf-8')).hexdigest()
    
    @staticmethod
    def compute_fingerprint(method: str, path: str, body: bytes) -> str:
        """
        Compute canonical fingerprint of request.
        
        Creates deterministic hash of request method, path, and body
        for conflict detection (same key, different payload).
        
        Args:
            method: HTTP method (POST, PUT, etc.)
            path: Request path
            body: Raw request body bytes
            
        Returns:
            Hex-encoded SHA256 hash of canonical request
        """
        # Create canonical representation: METHOD|PATH|BODY_HASH
        body_hash = hashlib.sha256(body).hexdigest()
        canonical = f"{method.upper()}|{path}|{body_hash}"
        return hashlib.sha256(canonical.encode('utf-8')).hexdigest()
    
    async def get_record(self, idempotency_key: str) -> Optional[IdempotencyRecord]:
        """
        Retrieve idempotency record by key.
        
        Args:
            idempotency_key: Raw idempotency key
            
        Returns:
            IdempotencyRecord if found, None otherwise
        """
        key_hash = self.hash_key(idempotency_key)
        return await self.store.get(key_hash)
    
    async def store_record(self, record: IdempotencyRecord) -> None:
        """
        Store idempotency record.
        
        Args:
            record: IdempotencyRecord to store
        """
        await self.store.set(record)
    
    def check_conflict(
        self,
        existing: IdempotencyRecord,
        request_fingerprint: str
    ) -> bool:
        """
        Check if request conflicts with existing record.
        
        Returns True if same key but different payload (conflict).
        
        Args:
            existing: Existing idempotency record
            request_fingerprint: Fingerprint of current request
            
        Returns:
            True if conflict detected, False if replay of same request
        """
        return existing.request_fingerprint != request_fingerprint
