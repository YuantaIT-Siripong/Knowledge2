"""
ORM models for FCN API core tables.
"""
from datetime import datetime, timezone
from sqlalchemy import (
    Column, String, Integer, Boolean, DateTime, DECIMAL, Text, JSON, Index
)
from sqlalchemy.dialects.mssql import DATETIMEOFFSET
from .base import Base


def utcnow():
    """Return current UTC time as timezone-aware datetime."""
    return datetime.now(timezone.utc)


class TemplateORM(Base):
    """
    FCN template definitions.
    Stores product templates with parameters and configuration.
    """
    __tablename__ = "fcn_template"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    template_id = Column(String(100), unique=True, nullable=False, index=True)
    name = Column(String(255), nullable=False)
    spec_version = Column(String(20), nullable=False, index=True)
    status = Column(String(20), nullable=False, default="active", index=True)  # active, deprecated
    issuer = Column(String(100), nullable=False)
    parameters = Column(Text, nullable=False)  # JSON string for parameter arrays
    created_at = Column(DATETIMEOFFSET, nullable=False, default=utcnow)
    updated_at = Column(DATETIMEOFFSET, nullable=False, default=utcnow, onupdate=utcnow)
    
    __table_args__ = (
        Index("ix_fcn_template_spec_version_status", "spec_version", "status"),
    )


class TradeORM(Base):
    """
    FCN trade instances.
    Records individual trade bookings with lifecycle flags.
    """
    __tablename__ = "fcn_trade"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    trade_id = Column(String(100), unique=True, nullable=False, index=True)
    template_id = Column(String(100), nullable=False, index=True)
    spec_version = Column(String(20), nullable=False, index=True)
    trade_date = Column(DateTime, nullable=False)
    maturity_date = Column(DateTime, nullable=False)
    notional = Column(DECIMAL(18, 4), nullable=False)
    currency = Column(String(3), nullable=False)
    status = Column(String(20), nullable=False, default="active", index=True)  # active, terminated, matured
    autocall_triggered = Column(Boolean, nullable=False, default=False)
    ki_triggered = Column(Boolean, nullable=False, default=False)
    trade_params = Column(Text, nullable=False)  # JSON string
    created_at = Column(DATETIMEOFFSET, nullable=False, default=utcnow)
    updated_at = Column(DATETIMEOFFSET, nullable=False, default=utcnow, onupdate=utcnow)
    
    __table_args__ = (
        Index("ix_fcn_trade_spec_version_status", "spec_version", "status"),
    )


class ObservationORM(Base):
    """
    FCN observation records.
    Stores per-observation data for autocall/KI/coupon evaluation.
    """
    __tablename__ = "fcn_observation"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    trade_id = Column(String(100), nullable=False, index=True)
    observation_date = Column(DateTime, nullable=False)
    observation_type = Column(String(20), nullable=False)  # autocall, coupon, ki, maturity
    underlying_prices = Column(Text, nullable=False)  # JSON array
    autocall_triggered = Column(Boolean, nullable=False, default=False)
    coupon_eligible = Column(Boolean, nullable=False, default=False)
    ki_triggered = Column(Boolean, nullable=False, default=False)
    observation_data = Column(Text, nullable=True)  # JSON string for additional data
    created_at = Column(DATETIMEOFFSET, nullable=False, default=utcnow)
    
    __table_args__ = (
        Index("ix_fcn_observation_trade_date", "trade_id", "observation_date", unique=True),
    )


class LifecycleEventORM(Base):
    """
    FCN lifecycle event log.
    Audit trail of all trade lifecycle events.
    """
    __tablename__ = "fcn_lifecycle_event"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    trade_id = Column(String(100), nullable=False, index=True)
    event_type = Column(String(50), nullable=False, index=True)  # autocall, coupon_payment, ki_breach, maturity
    event_date = Column(DateTime, nullable=False)
    event_payload = Column(Text, nullable=False)  # JSON string
    created_at = Column(DATETIMEOFFSET, nullable=False, default=utcnow)
    
    __table_args__ = (
        Index("ix_fcn_lifecycle_trade_type", "trade_id", "event_type"),
    )


class IdempotencyKeyORM(Base):
    """
    Idempotency key store for request deduplication.
    Captures request fingerprints and response snapshots.
    """
    __tablename__ = "fcn_idempotency_key"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    key_hash = Column(String(64), unique=True, nullable=False, index=True)  # SHA256 hash of idempotency key
    request_fingerprint = Column(String(64), nullable=False)  # SHA256 hash of canonical request payload
    request_method = Column(String(10), nullable=False)
    request_path = Column(String(500), nullable=False)
    response_status = Column(Integer, nullable=False)
    response_snapshot = Column(Text, nullable=False)  # JSON response body
    created_at = Column(DATETIMEOFFSET, nullable=False, default=utcnow)
    expires_at = Column(DATETIMEOFFSET, nullable=False)  # TTL for cleanup
    
    __table_args__ = (
        Index("ix_fcn_idempotency_expires", "expires_at"),
    )
