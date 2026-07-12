"""qr_code_tokens

Revision ID: 202607120001
Revises: 9658837a74c9
Create Date: 2026-07-12 00:01:00
"""
from alembic import op
import sqlalchemy as sa


revision = "202607120001"
down_revision = "9658837a74c9"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "qr_code_tokens",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("tenant_id", sa.String(length=36), nullable=True),
        sa.Column("token", sa.String(length=255), nullable=False),
        sa.Column("location_id", sa.String(length=100), nullable=True),
        sa.Column("payload", sa.JSON(), nullable=True),
        sa.Column("used", sa.Boolean(), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("used_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["tenant_id"], ["tenants.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_qr_code_tokens_tenant_id"), "qr_code_tokens", ["tenant_id"], unique=False)
    op.create_index(op.f("ix_qr_code_tokens_token"), "qr_code_tokens", ["token"], unique=True)


def downgrade() -> None:
    op.drop_index(op.f("ix_qr_code_tokens_token"), table_name="qr_code_tokens")
    op.drop_index(op.f("ix_qr_code_tokens_tenant_id"), table_name="qr_code_tokens")
    op.drop_table("qr_code_tokens")
