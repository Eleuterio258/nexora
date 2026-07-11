from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.schemas.common import AdjustmentStatus, DeviceStatus, DeviceType, EventType, LegalBasisType, SourceType, UserStatus


class ConsentPayload(BaseModel):
    term_version: str
    consent_hash: str
    accepted_at: datetime


class ConsentCreateRequest(BaseModel):
    user_id: UUID
    term_version: str
    consent_hash: str
    accepted_at: datetime
    legal_basis: LegalBasisType = LegalBasisType.CONSENT


class CaptureInput(BaseModel):
    image_base64: str
    angle: str | None = None


class EnrollRequest(BaseModel):
    user_id: UUID
    captures: list[CaptureInput] = Field(min_length=3)


class VerifyRequest(BaseModel):
    user_id: UUID
    device_id: UUID
    image_base64: str
    geo_lat: float | None = None
    geo_lng: float | None = None


class ClockRegisterRequest(BaseModel):
    idempotency_key: str
    user_id: UUID
    device_id: UUID
    event_type: EventType
    recorded_at: datetime
    source: SourceType
    confidence_score: float | None = None
    liveness_score: float | None = None
    geo_lat: float | None = None
    geo_lng: float | None = None
    image_base64: str | None = None


class ClockSyncRequest(BaseModel):
    record_ids: list[UUID] = Field(min_length=1)


class AdjustmentRequestInput(BaseModel):
    clock_record_id: UUID | None = None
    requested_event_type: EventType | None = None
    requested_recorded_at: datetime | None = None
    reason: str


class AdjustmentReviewRequest(BaseModel):
    status: AdjustmentStatus
    review_notes: str


class PayrollPushRequest(BaseModel):
    provider_name: str
    records: list["ClockRecordInput"]


class ClockRecordInput(BaseModel):
    id: UUID
    user_id: UUID
    device_id: UUID | None = None
    event_type: EventType
    recorded_at: datetime
    source: SourceType
    sync_status: str
    confidence_score: float | None = None
    liveness_score: float | None = None
    created_at: datetime | None = None


PayrollPushRequest.model_rebuild()


class UnitCreateRequest(BaseModel):
    code: str
    name: str
    timezone: str = "Africa/Maputo"
    geo_lat: float | None = None
    geo_lng: float | None = None


class UnitUpdateRequest(BaseModel):
    name: str | None = None
    timezone: str | None = None
    active: bool | None = None
    geo_lat: float | None = None
    geo_lng: float | None = None


class DeviceCreateRequest(BaseModel):
    device_code: str
    display_name: str
    unit_id: UUID | None = None
    type: DeviceType


class DeviceUpdateRequest(BaseModel):
    display_name: str | None = None
    unit_id: UUID | None = None
    type: DeviceType | None = None
    status: DeviceStatus | None = None


class UserCreateRequest(BaseModel):
    employee_code: str
    full_name: str
    email: str | None = None
    phone: str | None = None
    nfc_tag: str | None = None
    password: str
    unit_id: UUID | None = None
    role: str = "COLABORADOR"
    status: UserStatus = UserStatus.ACTIVE
    hired_at: datetime | None = None
    pin: str | None = None


class UserUpdateRequest(BaseModel):
    full_name: str | None = None
    email: str | None = None
    phone: str | None = None
    nfc_tag: str | None = None
    unit_id: UUID | None = None
    role: str | None = None
    status: UserStatus | None = None
    hired_at: datetime | None = None
    password: str | None = None
    pin: str | None = None
