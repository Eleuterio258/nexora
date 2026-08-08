"""add biometric_audit_logs

Revision ID: 87ec326d6235
Revises: 7ea9ac864a65
Create Date: 2026-08-08 00:00:00.000000
"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '87ec326d6235'
down_revision = '7ea9ac864a65'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'biometric_audit_logs',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('tenant_id', sa.String(length=36), nullable=True),
        sa.Column('event_type', sa.String(length=50), nullable=False),
        sa.Column('erp_user_id', sa.String(length=50), nullable=True),
        sa.Column('device_id', sa.String(length=64), nullable=True),
        sa.Column('reason', sa.String(length=100), nullable=True),
        sa.Column('confidence_score', sa.Numeric(precision=5, scale=4), nullable=True),
        sa.Column('liveness_score', sa.Numeric(precision=5, scale=4), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_biometric_audit_logs_tenant_id'), 'biometric_audit_logs', ['tenant_id'], unique=False)
    op.create_index(op.f('ix_biometric_audit_logs_event_type'), 'biometric_audit_logs', ['event_type'], unique=False)
    op.create_index(op.f('ix_biometric_audit_logs_erp_user_id'), 'biometric_audit_logs', ['erp_user_id'], unique=False)
    op.create_index(op.f('ix_biometric_audit_logs_device_id'), 'biometric_audit_logs', ['device_id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_biometric_audit_logs_device_id'), table_name='biometric_audit_logs')
    op.drop_index(op.f('ix_biometric_audit_logs_erp_user_id'), table_name='biometric_audit_logs')
    op.drop_index(op.f('ix_biometric_audit_logs_event_type'), table_name='biometric_audit_logs')
    op.drop_index(op.f('ix_biometric_audit_logs_tenant_id'), table_name='biometric_audit_logs')
    op.drop_table('biometric_audit_logs')
