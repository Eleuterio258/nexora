"""add api_credentials

Revision ID: 7ea9ac864a65
Revises: 8f610dec7ea3
Create Date: 2026-08-04 00:00:00.000000
"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '7ea9ac864a65'
down_revision = '8f610dec7ea3'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'api_credentials',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('access_key_id', sa.String(length=64), nullable=False),
        sa.Column('encrypted_secret_access_key', sa.String(length=255), nullable=False),
        sa.Column('name', sa.String(length=150), nullable=True),
        sa.Column('tenant_id', sa.String(length=36), nullable=False),
        sa.Column('permissions', sa.JSON(), nullable=False),
        sa.Column('status', sa.String(length=20), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('last_used_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('revoked_at', sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('access_key_id'),
    )
    op.create_index(op.f('ix_api_credentials_access_key_id'), 'api_credentials', ['access_key_id'], unique=False)
    op.create_index(op.f('ix_api_credentials_tenant_id'), 'api_credentials', ['tenant_id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_api_credentials_tenant_id'), table_name='api_credentials')
    op.drop_index(op.f('ix_api_credentials_access_key_id'), table_name='api_credentials')
    op.drop_table('api_credentials')
