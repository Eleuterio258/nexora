"""add hnsw index on face_templates.embedding_vector

Revision ID: 76692ef15c1a
Revises: a8f7d3ba8531
Create Date: 2026-08-08 00:00:00.000002

Acelera a pesquisa 1:N (identify_biometric usa
FaceTemplate.embedding_vector.cosine_distance(...), i.e. distancia cosseno),
por isso o indice usa vector_cosine_ops para corresponder ao operador
realmente usado nas queries.
"""
from alembic import op


# revision identifiers, used by Alembic.
revision = '76692ef15c1a'
down_revision = 'a8f7d3ba8531'
branch_labels = None
depends_on = None

INDEX_NAME = "ix_face_templates_embedding_vector_hnsw"


def upgrade() -> None:
    op.execute(
        f"CREATE INDEX IF NOT EXISTS {INDEX_NAME} "
        "ON face_templates USING hnsw (embedding_vector vector_cosine_ops) "
        "WITH (m = 16, ef_construction = 64)"
    )


def downgrade() -> None:
    op.execute(f"DROP INDEX IF EXISTS {INDEX_NAME}")
