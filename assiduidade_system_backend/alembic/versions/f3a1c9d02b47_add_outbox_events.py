"""add outbox_events

Revision ID: f3a1c9d02b47
Revises: ac34e8883d12
Create Date: 2026-09-03 00:00:00.000000

Transactional Outbox (Fase 1 de
docs/analise-transactional-outbox-backends.md): eventos que o FaceClock
precisa de entregar ao ERP com garantia de entrega, gravados na mesma
transacao que a alteracao de negocio que os origina e entregues por um
worker separado (app/workers/outbox.py), nunca pelo pedido HTTP que os gerou.
"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'f3a1c9d02b47'
down_revision = 'ac34e8883d12'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'outbox_events',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('tenant_id', sa.String(length=36), nullable=True),
        sa.Column('event_type', sa.String(length=120), nullable=False),
        sa.Column('aggregate_type', sa.String(length=80), nullable=False),
        sa.Column('aggregate_id', sa.String(length=100), nullable=False),
        sa.Column('schema_version', sa.Integer(), nullable=False),
        sa.Column('payload', sa.JSON(), nullable=False),
        sa.Column('deduplication_key', sa.String(length=200), nullable=False),
        sa.Column('status', sa.String(length=20), nullable=False),
        sa.Column('attempts', sa.Integer(), nullable=False),
        sa.Column('available_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('locked_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('locked_by', sa.String(length=100), nullable=True),
        sa.Column('published_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('last_error', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('deduplication_key', name='uq_outbox_deduplication_key'),
    )
    op.create_index(op.f('ix_outbox_events_tenant_id'), 'outbox_events', ['tenant_id'], unique=False)
    op.create_index(op.f('ix_outbox_events_event_type'), 'outbox_events', ['event_type'], unique=False)
    op.create_index('ix_outbox_pending', 'outbox_events', ['status', 'available_at'], unique=False)


def downgrade() -> None:
    op.drop_index('ix_outbox_pending', table_name='outbox_events')
    op.drop_index(op.f('ix_outbox_events_event_type'), table_name='outbox_events')
    op.drop_index(op.f('ix_outbox_events_tenant_id'), table_name='outbox_events')
    op.drop_table('outbox_events')
