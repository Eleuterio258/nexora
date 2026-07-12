from datetime import datetime, timezone
from uuid import uuid4

from sqlalchemy import DateTime, Enum, ForeignKey, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base
from app.schemas.common import TemplateStatus


def generate_uuid() -> str:
    return str(uuid4())


class FaceTemplate(Base):
    __tablename__ = "face_templates"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    tenant_id: Mapped[str | None] = mapped_column(String(36), index=True)
    erp_user_id: Mapped[str] = mapped_column(String(50), index=True, nullable=False)
    erp_funcionario_id: Mapped[str | None] = mapped_column(String(50), index=True)
    consent_version: Mapped[str | None] = mapped_column(String(30))
    model_version: Mapped[str] = mapped_column(String(50), nullable=False)
    embedding: Mapped[bytes] = mapped_column(nullable=False)
    quality_score: Mapped[float | None] = mapped_column(Numeric(5, 4))
    status: Mapped[TemplateStatus] = mapped_column(
        Enum(TemplateStatus), default=TemplateStatus.ACTIVE, nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class FingerprintTemplate(Base):
    __tablename__ = "fingerprint_templates"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    tenant_id: Mapped[str | None] = mapped_column(String(36), index=True)
    erp_user_id: Mapped[str] = mapped_column(String(50), index=True, nullable=False)
    erp_funcionario_id: Mapped[str | None] = mapped_column(String(50), index=True)
    finger_type: Mapped[str] = mapped_column(String(50), default="right_thumb", nullable=False)
    template_base64: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
