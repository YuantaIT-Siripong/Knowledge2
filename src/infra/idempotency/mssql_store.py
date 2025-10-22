"""
MSSQL-backed idempotency store implementation.

Provides durable storage for idempotency keys using Microsoft SQL Server.
"""
from datetime import datetime, timezone
from typing import Optional
from sqlalchemy.orm import Session
from src.domain.services.idempotency import IdempotencyStore, IdempotencyRecord
from src.infra.db.models import IdempotencyKeyORM


def utcnow():
    """Return current UTC time as timezone-aware datetime."""
    return datetime.now(timezone.utc)


class MSSQLIdempotencyStore(IdempotencyStore):
    """
    MSSQL implementation of idempotency store.
    
    Uses fcn_idempotency_key table for persistent storage.
    """
    
    def __init__(self, session_factory):
        """
        Initialize MSSQL idempotency store.
        
        Args:
            session_factory: Callable that returns SQLAlchemy Session
        """
        self.session_factory = session_factory
    
    async def get(self, key_hash: str) -> Optional[IdempotencyRecord]:
        """
        Retrieve idempotency record from MSSQL.
        
        Args:
            key_hash: SHA256 hash of idempotency key
            
        Returns:
            IdempotencyRecord if found and not expired, None otherwise
        """
        with self.session_factory() as session:
            orm_record = session.query(IdempotencyKeyORM).filter(
                IdempotencyKeyORM.key_hash == key_hash,
                IdempotencyKeyORM.expires_at > utcnow()
            ).first()
            
            if not orm_record:
                return None
            
            return IdempotencyRecord(
                key_hash=orm_record.key_hash,
                request_fingerprint=orm_record.request_fingerprint,
                request_method=orm_record.request_method,
                request_path=orm_record.request_path,
                response_status=orm_record.response_status,
                response_snapshot=orm_record.response_snapshot,
                created_at=orm_record.created_at,
                expires_at=orm_record.expires_at,
            )
    
    async def set(self, record: IdempotencyRecord) -> None:
        """
        Store idempotency record in MSSQL.
        
        Args:
            record: IdempotencyRecord to store
        """
        with self.session_factory() as session:
            orm_record = IdempotencyKeyORM(
                key_hash=record.key_hash,
                request_fingerprint=record.request_fingerprint,
                request_method=record.request_method,
                request_path=record.request_path,
                response_status=record.response_status,
                response_snapshot=record.response_snapshot,
                created_at=record.created_at,
                expires_at=record.expires_at,
            )
            session.add(orm_record)
            session.commit()
    
    async def delete(self, key_hash: str) -> None:
        """
        Delete idempotency record from MSSQL.
        
        Args:
            key_hash: SHA256 hash of idempotency key
        """
        with self.session_factory() as session:
            session.query(IdempotencyKeyORM).filter(
                IdempotencyKeyORM.key_hash == key_hash
            ).delete()
            session.commit()
