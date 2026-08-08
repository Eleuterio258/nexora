"""add device_public_keys

Revision ID: ac34e8883d12
Revises: 76692ef15c1a
Create Date: 2026-08-08 00:00:00.000003

Mesma causa de raiz que transform_version/embedding_vector (527f1cebd109,
a8f7d3ba8531): a tabela existe no modelo SQLAlchemy (DevicePublicKey) desde
a introducao da assinatura de imagem por dispositivo, mas nunca teve
migration propria — dependia de Base.metadata.create_all, que so cria
tabelas que ainda nao existem em bases de dados novas, nunca retrofits em
bases de dados ja existentes antes da feature ser introduzida.

Sem impacto imediato hoje (REQUIRE_IMAGE_SIGNATURE=false por omissao), mas
bloqueia _validate_image_signature/device_registry assim que a assinatura
de imagem por dispositivo for activada.
"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'ac34e8883d12'
down_revision = '76692ef15c1a'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'device_public_keys',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('tenant_id', sa.String(length=36), nullable=True),
        sa.Column('device_id', sa.String(length=64), nullable=False),
        sa.Column('public_key_b64', sa.Text(), nullable=False),
        sa.Column('status', sa.String(length=20), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('revoked_at', sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_device_public_keys_tenant_id'), 'device_public_keys', ['tenant_id'], unique=False)
    op.create_index(op.f('ix_device_public_keys_device_id'), 'device_public_keys', ['device_id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_device_public_keys_device_id'), table_name='device_public_keys')
    op.drop_index(op.f('ix_device_public_keys_tenant_id'), table_name='device_public_keys')
    op.drop_table('device_public_keys')
