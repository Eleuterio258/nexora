from datetime import datetime
from uuid import UUID

from pydantic import BaseModel

from app.schemas.common import EventType, SourceType


class ORMBaseModel(BaseModel):
    model_config = {"from_attributes": True}


class EnrollResponse(ORMBaseModel):
    template_id: UUID
    user_id: UUID
    model_version: str
    status: str


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
    sync_status: str
    confidence_score: float | None = None
    liveness_score: float | None = None
    created_at: datetime
