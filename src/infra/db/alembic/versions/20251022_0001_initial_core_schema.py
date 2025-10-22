"""Initial core schema for FCN API

Revision ID: 20251022_0001
Revises: 
Create Date: 2025-10-22 06:30:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import mssql

# revision identifiers, used by Alembic.
revision = '20251022_0001'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    """
    Create core FCN API tables:
    - fcn_template: Product template definitions
    - fcn_trade: Trade instances
    - fcn_observation: Observation records
    - fcn_lifecycle_event: Lifecycle event audit trail
    - fcn_idempotency_key: Idempotency key store
    """
    
    # fcn_template table
    op.create_table(
        'fcn_template',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('template_id', sa.String(length=100), nullable=False),
        sa.Column('name', sa.String(length=255), nullable=False),
        sa.Column('spec_version', sa.String(length=20), nullable=False),
        sa.Column('status', sa.String(length=20), nullable=False),
        sa.Column('issuer', sa.String(length=100), nullable=False),
        sa.Column('parameters', sa.Text(), nullable=False),
        sa.Column('created_at', mssql.DATETIMEOFFSET(), nullable=False),
        sa.Column('updated_at', mssql.DATETIMEOFFSET(), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_fcn_template_template_id', 'fcn_template', ['template_id'], unique=True)
    op.create_index('ix_fcn_template_spec_version', 'fcn_template', ['spec_version'])
    op.create_index('ix_fcn_template_status', 'fcn_template', ['status'])
    op.create_index('ix_fcn_template_spec_version_status', 'fcn_template', ['spec_version', 'status'])
    
    # fcn_trade table
    op.create_table(
        'fcn_trade',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('trade_id', sa.String(length=100), nullable=False),
        sa.Column('template_id', sa.String(length=100), nullable=False),
        sa.Column('spec_version', sa.String(length=20), nullable=False),
        sa.Column('trade_date', sa.DateTime(), nullable=False),
        sa.Column('maturity_date', sa.DateTime(), nullable=False),
        sa.Column('notional', sa.DECIMAL(precision=18, scale=4), nullable=False),
        sa.Column('currency', sa.String(length=3), nullable=False),
        sa.Column('status', sa.String(length=20), nullable=False),
        sa.Column('autocall_triggered', sa.Boolean(), nullable=False),
        sa.Column('ki_triggered', sa.Boolean(), nullable=False),
        sa.Column('trade_params', sa.Text(), nullable=False),
        sa.Column('created_at', mssql.DATETIMEOFFSET(), nullable=False),
        sa.Column('updated_at', mssql.DATETIMEOFFSET(), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_fcn_trade_trade_id', 'fcn_trade', ['trade_id'], unique=True)
    op.create_index('ix_fcn_trade_template_id', 'fcn_trade', ['template_id'])
    op.create_index('ix_fcn_trade_spec_version', 'fcn_trade', ['spec_version'])
    op.create_index('ix_fcn_trade_status', 'fcn_trade', ['status'])
    op.create_index('ix_fcn_trade_spec_version_status', 'fcn_trade', ['spec_version', 'status'])
    
    # fcn_observation table
    op.create_table(
        'fcn_observation',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('trade_id', sa.String(length=100), nullable=False),
        sa.Column('observation_date', sa.DateTime(), nullable=False),
        sa.Column('observation_type', sa.String(length=20), nullable=False),
        sa.Column('underlying_prices', sa.Text(), nullable=False),
        sa.Column('autocall_triggered', sa.Boolean(), nullable=False),
        sa.Column('coupon_eligible', sa.Boolean(), nullable=False),
        sa.Column('ki_triggered', sa.Boolean(), nullable=False),
        sa.Column('observation_data', sa.Text(), nullable=True),
        sa.Column('created_at', mssql.DATETIMEOFFSET(), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_fcn_observation_trade_id', 'fcn_observation', ['trade_id'])
    op.create_index('ix_fcn_observation_trade_date', 'fcn_observation', ['trade_id', 'observation_date'], unique=True)
    
    # fcn_lifecycle_event table
    op.create_table(
        'fcn_lifecycle_event',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('trade_id', sa.String(length=100), nullable=False),
        sa.Column('event_type', sa.String(length=50), nullable=False),
        sa.Column('event_date', sa.DateTime(), nullable=False),
        sa.Column('event_payload', sa.Text(), nullable=False),
        sa.Column('created_at', mssql.DATETIMEOFFSET(), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_fcn_lifecycle_event_trade_id', 'fcn_lifecycle_event', ['trade_id'])
    op.create_index('ix_fcn_lifecycle_event_event_type', 'fcn_lifecycle_event', ['event_type'])
    op.create_index('ix_fcn_lifecycle_trade_type', 'fcn_lifecycle_event', ['trade_id', 'event_type'])
    
    # fcn_idempotency_key table
    op.create_table(
        'fcn_idempotency_key',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('key_hash', sa.String(length=64), nullable=False),
        sa.Column('request_fingerprint', sa.String(length=64), nullable=False),
        sa.Column('request_method', sa.String(length=10), nullable=False),
        sa.Column('request_path', sa.String(length=500), nullable=False),
        sa.Column('response_status', sa.Integer(), nullable=False),
        sa.Column('response_snapshot', sa.Text(), nullable=False),
        sa.Column('created_at', mssql.DATETIMEOFFSET(), nullable=False),
        sa.Column('expires_at', mssql.DATETIMEOFFSET(), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_fcn_idempotency_key_key_hash', 'fcn_idempotency_key', ['key_hash'], unique=True)
    op.create_index('ix_fcn_idempotency_expires', 'fcn_idempotency_key', ['expires_at'])


def downgrade() -> None:
    """
    Drop all core FCN API tables in reverse order.
    """
    op.drop_table('fcn_idempotency_key')
    op.drop_table('fcn_lifecycle_event')
    op.drop_table('fcn_observation')
    op.drop_table('fcn_trade')
    op.drop_table('fcn_template')
