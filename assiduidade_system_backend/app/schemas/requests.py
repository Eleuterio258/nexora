from uuid import UUID

from pydantic import BaseModel, Field, model_validator


class CaptureInput(BaseModel):
    image_base64: str | None = None
    image_url: str | None = None
    angle: str | None = None

    @model_validator(mode="after")
    def _check_image_source(self) -> "CaptureInput":
        if not self.image_base64 and not self.image_url:
            raise ValueError("Forneca image_base64 ou image_url.")
        if self.image_base64 and self.image_url:
            raise ValueError("Forneca apenas image_base64 ou image_url, nao ambos.")
        return self


class EnrollRequest(BaseModel):
    user_id: str
    captures: list[CaptureInput] = Field(min_length=3)


class VerifyRequest(BaseModel):
    user_id: str
    device_id: UUID
    image_base64: str | None = None
    image_url: str | None = None
    geo_lat: float | None = None
    geo_lng: float | None = None

    @model_validator(mode="after")
    def _check_image_source(self) -> "VerifyRequest":
        if not self.image_base64 and not self.image_url:
            raise ValueError("Forneca image_base64 ou image_url.")
        if self.image_base64 and self.image_url:
            raise ValueError("Forneca apenas image_base64 ou image_url, nao ambos.")
        return self


class LivenessChallengeRequest(BaseModel):
    user_id: str


class LivenessVerifyRequest(BaseModel):
    challenge_id: str
    user_id: str
    device_id: UUID
    frames_base64: list[str] = Field(min_length=4, max_length=20)
    geo_lat: float | None = None
    geo_lng: float | None = None
