from datetime import date, datetime, timezone
from uuid import uuid4

from sqlalchemy import JSON, Boolean, Date, DateTime, Enum, ForeignKey, Numeric, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.schemas.common import (
    AdjustmentStatus,
    DeviceStatus,
    DeviceType,
    EventType,
    LegalBasisType,
    SourceType,
    SyncStatus,
    TemplateStatus,
    UserRole,
    UserStatus,
)


def generate_uuid() -> str:
    return str(uuid4())


class Tenant(Base):
    __tablename__ = "tenants"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    external_id: Mapped[str | None] = mapped_column(String(100), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(150), nullable=False)
    code: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    settings_json: Mapped[dict | None] = mapped_column(JSON)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))


class Unit(Base):
    __tablename__ = "units"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    tenant_id: Mapped[str | None] = mapped_column(ForeignKey("tenants.id"), index=True)
    code: Mapped[str] = mapped_column(String(50), nullable=False)
    name: Mapped[str] = mapped_column(String(150), nullable=False)
    timezone: Mapped[str] = mapped_column(String(100), default="Africa/Maputo", nullable=False)
    active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    geo_lat: Mapped[float | None] = mapped_column(Numeric(10, 7))
    geo_lng: Mapped[float | None] = mapped_column(Numeric(10, 7))
    allowed_radius_meters: Mapped[int | None] = mapped_column(default=100)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    __table_args__ = (UniqueConstraint("tenant_id", "code", name="uix_tenant_unit_code"),)

    users: Mapped[list["User"]] = relationship(back_populates="unit")
    devices: Mapped[list["Device"]] = relationship(back_populates="unit")


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    tenant_id: Mapped[str | None] = mapped_column(ForeignKey("tenants.id"), index=True)
    erp_user_id: Mapped[str | None] = mapped_column(String(50), index=True)
    employee_code: Mapped[str] = mapped_column(String(50), nullable=False)
    full_name: Mapped[str] = mapped_column(String(200), nullable=False)
    email: Mapped[str | None] = mapped_column(String(200))
    phone: Mapped[str | None] = mapped_column(String(30))
    nfc_tag: Mapped[str | None] = mapped_column(String(100), unique=True)
    pin_hash: Mapped[str | None] = mapped_column(String(255))
    totp_secret: Mapped[str | None] = mapped_column(String(255))
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    unit_id: Mapped[str | None] = mapped_column(ForeignKey("units.id"))
    role: Mapped[UserRole] = mapped_column(Enum(UserRole), default=UserRole.COLABORADOR, nullable=False)
    status: Mapped[UserStatus] = mapped_column(Enum(UserStatus), default=UserStatus.ACTIVE, nullable=False)
    hired_at: Mapped[date | None] = mapped_column(Date)
    terminated_at: Mapped[date | None] = mapped_column(Date)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    __table_args__ = (UniqueConstraint("tenant_id", "employee_code", name="uix_tenant_employee_code"),)

    unit: Mapped[Unit | None] = relationship(back_populates="users")


class Device(Base):
    __tablename__ = "devices"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    tenant_id: Mapped[str | None] = mapped_column(ForeignKey("tenants.id"), index=True)
    device_code: Mapped[str] = mapped_column(String(100), nullable=False)
    display_name: Mapped[str] = mapped_column(String(150), nullable=False)
    unit_id: Mapped[str | None] = mapped_column(ForeignKey("units.id"))
    type: Mapped[DeviceType] = mapped_column(Enum(DeviceType), nullable=False)
    status: Mapped[DeviceStatus] = mapped_column(
        Enum(DeviceStatus), default=DeviceStatus.ACTIVE, nullable=False
    )
    last_seen_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    __table_args__ = (UniqueConstraint("tenant_id", "device_code", name="uix_tenant_device_code"),)

    unit: Mapped[Unit | None] = relationship(back_populates="devices")


class Consent(Base):
    __tablename__ = "consents"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    tenant_id: Mapped[str | None] = mapped_column(ForeignKey("tenants.id"), index=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), nullable=False)
    term_version: Mapped[str] = mapped_column(String(30), nullable=False)
    consent_hash: Mapped[str] = mapped_column(String(128), nullable=False)
    legal_basis: Mapped[LegalBasisType] = mapped_column(
        Enum(LegalBasisType), default=LegalBasisType.CONSENT, nullable=False
    )
    accepted_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))


class FaceTemplate(Base):
    __tablename__ = "face_templates"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    tenant_id: Mapped[str | None] = mapped_column(ForeignKey("tenants.id"), index=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), nullable=False)
    consent_id: Mapped[str] = mapped_column(ForeignKey("consents.id"), nullable=False)
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
    tenant_id: Mapped[str | None] = mapped_column(ForeignKey("tenants.id"), index=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), nullable=False)
    finger_type: Mapped[str] = mapped_column(String(50), default="right_thumb", nullable=False)
    template_base64: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))


class ClockRecordModel(Base):
    __tablename__ = "clock_records"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    tenant_id: Mapped[str | None] = mapped_column(ForeignKey("tenants.id"), index=True)
    idempotency_key: Mapped[str] = mapped_column(String(100), nullable=False)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), nullable=False)
    device_id: Mapped[str | None] = mapped_column(ForeignKey("devices.id"))
    event_type: Mapped[EventType] = mapped_column(Enum(EventType), nullable=False)
    source: Mapped[SourceType] = mapped_column(Enum(SourceType), nullable=False)
    sync_status: Mapped[SyncStatus] = mapped_column(Enum(SyncStatus), default=SyncStatus.SYNCED, nullable=False)
    recorded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    confidence_score: Mapped[float | None] = mapped_column(Numeric(5, 4))
    liveness_score: Mapped[float | None] = mapped_column(Numeric(5, 4))
    geo_lat: Mapped[float | None] = mapped_column(Numeric(10, 7))
    geo_lng: Mapped[float | None] = mapped_column(Numeric(10, 7))
    payload: Mapped[dict | None] = mapped_column(JSON)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    __table_args__ = (UniqueConstraint("tenant_id", "idempotency_key", name="uix_tenant_idempotency_key"),)


class AdjustmentRequestModel(Base):
    __tablename__ = "adjustment_requests"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    tenant_id: Mapped[str | None] = mapped_column(ForeignKey("tenants.id"), index=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), nullable=False)
    clock_record_id: Mapped[str | None] = mapped_column(ForeignKey("clock_records.id"))
    requested_event_type: Mapped[EventType | None] = mapped_column(Enum(EventType))
    requested_recorded_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[AdjustmentStatus] = mapped_column(
        Enum(AdjustmentStatus), default=AdjustmentStatus.PENDING, nullable=False
    )
    reviewer_id: Mapped[str | None] = mapped_column(ForeignKey("users.id"))
    review_notes: Mapped[str | None] = mapped_column(Text)
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))


class AuditLogModel(Base):
    __tablename__ = "audit_logs"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    tenant_id: Mapped[str | None] = mapped_column(ForeignKey("tenants.id"), index=True)
    actor_id: Mapped[str | None] = mapped_column(ForeignKey("users.id"))
    actor_type: Mapped[str] = mapped_column(String(50), nullable=False)
    action: Mapped[str] = mapped_column(String(100), nullable=False)
    entity_type: Mapped[str] = mapped_column(String(100), nullable=False)
    entity_id: Mapped[str | None] = mapped_column(String(36))
    payload_hash: Mapped[str] = mapped_column(String(128), nullable=False)
    previous_hash: Mapped[str | None] = mapped_column(String(128))
    metadata_json: Mapped[dict | None] = mapped_column("metadata", JSON)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))


class IntegrationBatchModel(Base):
    __tablename__ = "integration_batches"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    tenant_id: Mapped[str | None] = mapped_column(ForeignKey("tenants.id"), index=True)
    provider_name: Mapped[str] = mapped_column(String(100), nullable=False)
    requested_by: Mapped[str | None] = mapped_column(ForeignKey("users.id"))
    status: Mapped[str] = mapped_column(String(30), nullable=False)
    total_records: Mapped[int] = mapped_column(default=0, nullable=False)
    accepted_records: Mapped[int] = mapped_column(default=0, nullable=False)
    rejected_records: Mapped[int] = mapped_column(default=0, nullable=False)
    request_payload: Mapped[dict | None] = mapped_column(JSON)
    response_payload: Mapped[dict | None] = mapped_column(JSON)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    finished_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
