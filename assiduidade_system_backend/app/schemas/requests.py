from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.schemas.common import EventType, SourceType


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


class LivenessChallengeRequest(BaseModel):
    user_id: UUID


class LivenessVerifyRequest(BaseModel):
    challenge_id: str
    user_id: UUID
    device_id: UUID
    frames_base64: list[str] = Field(min_length=4, max_length=20)
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


class ClockBatchRegisterRequest(BaseModel):
    records: list[ClockRegisterRequest] = Field(min_length=1, max_length=100)


class ClockSyncRequest(BaseModel):
    record_ids: list[UUID] = Field(min_length=1)
