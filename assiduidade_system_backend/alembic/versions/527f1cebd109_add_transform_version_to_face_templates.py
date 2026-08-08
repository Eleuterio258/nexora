"""add transform_version to face_templates

Revision ID: 527f1cebd109
Revises: 87ec326d6235
Create Date: 2026-08-08 00:00:00.000000

face_templates.transform_version foi adicionado ao modelo SQLAlchemy sem
nunca ter tido uma migration propria (dependia de Base.metadata.create_all,
que so cria tabelas novas, nunca faz ALTER numa tabela ja existente). Sem
esta coluna, qualquer INSERT/SELECT em FaceTemplate falha em bases de dados
onde face_templates ja existia antes desta alteracao ser introduzida.

Nota: embedding_vector (tipo `vector(512)`, para pesquisa 1:N) NAO faz parte
desta migration porque requer a extensao pgvector instalada no servidor
Postgres, que pode nao estar disponivel em todos os ambientes — ver
migration separada quando a extensao estiver confirmada.
"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '527f1cebd109'
down_revision = '87ec326d6235'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        'face_templates',
        sa.Column('transform_version', sa.String(length=30), nullable=True),
    )


def downgrade() -> None:
    op.drop_column('face_templates', 'transform_version')
