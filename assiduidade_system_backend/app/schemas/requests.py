from uuid import UUID

from pydantic import BaseModel, Field


class CaptureInput(BaseModel):
    image_base64: str
    angle: str | None = None


class EnrollRequest(BaseModel):
    user_id: str
    captures: list[CaptureInput] = Field(min_length=3)


class VerifyRequest(BaseModel):
    user_id: str
    device_id: UUID
    image_base64: str
    geo_lat: float | None = None
    geo_lng: float | None = None


class LivenessChallengeRequest(BaseModel):
    user_id: str


class LivenessVerifyRequest(BaseModel):
    challenge_id: str
    user_id: str
    device_id: UUID
    frames_base64: list[str] = Field(min_length=4, max_length=20)
    geo_lat: float | None = None
    geo_lng: float | None = None
