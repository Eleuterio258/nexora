from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class ORMBaseModel(BaseModel):
    model_config = {"from_attributes": True}


class EnrollResponse(ORMBaseModel):
    template_id: UUID
    user_id: str
    model_version: str
    status: str


class VerifyResponse(ORMBaseModel):
    match: bool
    user_id: str | None = None
    confidence_score: float
    liveness_score: float
    timestamp: datetime
    reason: str | None = None
