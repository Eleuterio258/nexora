from datetime import datetime
from uuid import UUID

from pydantic import BaseModel

from app.schemas.common import AdjustmentStatus, DeviceStatus, DeviceType, EventType, LegalBasisType, SourceType, SyncStatus, UserRole, UserStatus


class ORMBaseModel(BaseModel):
    model_config = {"from_attributes": True}


class UserSummary(ORMBaseModel):
    id: UUID
    employee_code: str
    full_name: str
    role: UserRole
    status: UserStatus


class EnrollResponse(ORMBaseModel):
    template_id: UUID
    user_id: UUID
    model_version: str
    status: str


class ConsentResponse(ORMBaseModel):
    id: UUID
    user_id: UUID
    term_version: str
    consent_hash: str
    legal_basis: LegalBasisType
    accepted_at: datetime
    revoked_at: datetime | None = None
    created_at: datetime


class VerifyResponse(ORMBaseModel):
    match: bool
    user_id: UUID | None = None
    confidence_score: float
    liveness_score: float
    timestamp: datetime
    reason: str | None = None


class ClockRecord(ORMBaseModel):
    id: UUID
    user_id: UUID
    device_id: UUID | None = None
    event_type: EventType
    recorded_at: datetime
    source: SourceType
    sync_status: SyncStatus
    confidence_score: float | None = None
    liveness_score: float | None = None
    created_at: datetime


class ClockSyncResponse(ORMBaseModel):
    synced_record_ids: list[UUID]
    not_found_record_ids: list[UUID]
    total_requested: int
    total_synced: int


class AdjustmentRequest(ORMBaseModel):
    id: UUID
    user_id: UUID
    clock_record_id: UUID | None = None
    requested_event_type: EventType | None = None
    requested_recorded_at: datetime | None = None
    reason: str
    status: AdjustmentStatus
    review_notes: str | None = None
    reviewer_id: UUID | None = None
    reviewed_at: datetime | None = None
    created_at: datetime


class PaginatedClockRecords(ORMBaseModel):
    items: list[ClockRecord]
    page: int
    page_size: int
    total: int


class PaginatedAdjustmentRequests(ORMBaseModel):
    items: list[AdjustmentRequest]
    page: int
    page_size: int
    total: int


class ExportResponse(ORMBaseModel):
    download_url: str
    format: str


class AuditLog(ORMBaseModel):
    id: UUID
    actor_type: str
    actor_id: UUID | None = None
    action: str
    entity_type: str
    entity_id: UUID | None = None
    payload_hash: str
    previous_hash: str | None = None
    created_at: datetime


class PaginatedAuditLogs(ORMBaseModel):
    items: list[AuditLog]
    page: int
    page_size: int
    total: int


class PayrollPushResponse(ORMBaseModel):
    batch_id: UUID
    accepted_records: int
    rejected_records: int
    status: str


class UnitResponse(ORMBaseModel):
    id: UUID
    code: str
    name: str
    timezone: str
    active: bool
    geo_lat: float | None = None
    geo_lng: float | None = None
    created_at: datetime
    updated_at: datetime


class PaginatedUnits(ORMBaseModel):
    items: list[UnitResponse]
    page: int
    page_size: int
    total: int


class DeviceResponse(ORMBaseModel):
    id: UUID
    device_code: str
    display_name: str
    unit_id: UUID | None = None
    type: DeviceType
    status: DeviceStatus
    last_seen_at: datetime | None = None
    created_at: datetime
    updated_at: datetime


class PaginatedDevices(ORMBaseModel):
    items: list[DeviceResponse]
    page: int
    page_size: int
    total: int


class UserDetail(ORMBaseModel):
    id: UUID
    employee_code: str
    full_name: str
    email: str | None = None
    phone: str | None = None
    unit_id: UUID | None = None
    role: UserRole
    status: UserStatus
    hired_at: datetime | None = None
    terminated_at: datetime | None = None
    created_at: datetime
    updated_at: datetime


class PaginatedUsers(ORMBaseModel):
    items: list[UserDetail]
    page: int
    page_size: int
    total: int


class PaginatedConsents(ORMBaseModel):
    items: list[ConsentResponse]
    page: int
    page_size: int
    total: int


class BatchSummary(ORMBaseModel):
    id: UUID
    provider_name: str
    status: str
    total_records: int
    accepted_records: int
    rejected_records: int
    created_at: datetime
    finished_at: datetime | None = None


class BatchListResponse(ORMBaseModel):
    items: list[BatchSummary]
    page: int
    page_size: int
    total: int
