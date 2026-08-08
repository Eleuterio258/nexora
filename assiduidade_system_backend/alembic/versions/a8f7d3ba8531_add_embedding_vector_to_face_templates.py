"""add embedding_vector to face_templates

Revision ID: a8f7d3ba8531
Revises: 527f1cebd109
Create Date: 2026-08-08 00:00:00.000001

Mesma causa de raiz que transform_version (527f1cebd109): a coluna existe no
modelo SQLAlchemy mas nunca teve migration propria, dependendo de
Base.metadata.create_all (que nao faz ALTER em tabelas ja existentes).

Requer a extensao pgvector instalada no servidor Postgres (nao so o pacote
Python `pgvector`). Se a extensao nao estiver disponivel, esta migration
falha alto em vez de degradar em silencio — corrigir a extensao antes de
tentar novamente, nao contornar aqui.

O indice HNSW para pesquisa 1:N e adicionado numa migration separada.
"""
from alembic import op
import sqlalchemy as sa

try:
    from pgvector.sqlalchemy import Vector
except ImportError:  # pragma: no cover
    Vector = None


# revision identifiers, used by Alembic.
revision = 'a8f7d3ba8531'
down_revision = '527f1cebd109'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("CREATE EXTENSION IF NOT EXISTS vector")
    op.add_column(
        'face_templates',
        sa.Column('embedding_vector', Vector(512), nullable=True),
    )


def downgrade() -> None:
    op.drop_column('face_templates', 'embedding_vector')
