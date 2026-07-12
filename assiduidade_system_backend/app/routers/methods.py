"""
Router para métodos alternativos de registo de presença:
- QR Code (em memória)
- NFC (delegado no ERP)
- Geofencing / Geolocalização (delegado no ERP)

O registo final do ponto continua a ser feito via /clock/register com o source
apropriado.
"""

import secrets
from datetime import datetime, timedelta, timezone
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from app.deps import ActorContext, get_actor
from app.schemas.common import SourceType
from app.services.attendance_validation import validar_metodo_assiduidade

router = APIRouter(tags=["Attendance Methods"])


# ══════════════════════════════════════════════════════════════════════════════
# QR Code (em memória)
# ══════════════════════════════════════════════════════════════════════════════

class QRValidateRequest(BaseModel):
    qr_code: str = Field(..., min_length=1)
    user_id: str | None = None


class QRValidateResponse(BaseModel):
    valid: bool
    source: str = SourceType.QR_CODE.value
    payload: dict[str, Any] | None = None
    message: str | None = None


class QRGenerateRequest(BaseModel):
    location_id: str | None = None
    session_duration_seconds: int = Field(60, ge=10, le=300)


class QRGenerateResponse(BaseModel):
    qr_code: str
    payload: dict[str, Any]
    expires_at: datetime


_qr_store: dict[str, dict[str, Any]] = {}


@router.post("/qr/generate", response_model=QRGenerateResponse, status_code=status.HTTP_201_CREATED)
async def generate_qr(
    request: QRGenerateRequest,
    actor: ActorContext = Depends(get_actor),
) -> QRGenerateResponse:
    await validar_metodo_assiduidade(SourceType.QR_CODE)

    tenant_id = actor.tenant_id or "default"
    issued_at = datetime.now(timezone.utc)
    expires_at = issued_at + timedelta(seconds=request.session_duration_seconds)
    payload = {
        "tenant_id": tenant_id,
        "location_id": request.location_id,
        "timestamp": issued_at.isoformat(),
        "expires_at": expires_at.isoformat(),
    }
    token = f"qr:{tenant_id}:{secrets.token_urlsafe(32)}"
    _qr_store[token] = {"payload": payload, "used": False}

    return QRGenerateResponse(qr_code=token, payload=payload, expires_at=expires_at)


@router.post("/qr/validate", response_model=QRValidateResponse)
async def validate_qr(
    request: QRValidateRequest,
    actor: ActorContext = Depends(get_actor),
) -> QRValidateResponse:
    """Valida um QR Code de presença gerado em memória."""
    await validar_metodo_assiduidade(SourceType.QR_CODE)

    data = _qr_store.get(request.qr_code)
    if not data:
        raise HTTPException(status_code=400, detail="QR Code invalido.")

    if data["used"]:
        raise HTTPException(status_code=400, detail="QR Code ja utilizado.")

    payload = data["payload"]
    expires_at = payload.get("expires_at")
    if expires_at and datetime.now(timezone.utc) > datetime.fromisoformat(expires_at):
        raise HTTPException(status_code=400, detail="QR Code expirado.")

    qr_tenant_id = payload.get("tenant_id")
    if actor.tenant_id and qr_tenant_id and actor.tenant_id != qr_tenant_id:
        raise HTTPException(status_code=403, detail="QR Code pertence a outro tenant.")

    data["used"] = True
    return QRValidateResponse(valid=True, payload=payload, message="QR Code valido.")


# ══════════════════════════════════════════════════════════════════════════════
# NFC (delegado no ERP)
# ══════════════════════════════════════════════════════════════════════════════

class NFCValidateRequest(BaseModel):
    nfc_tag: str = Field(..., min_length=1)


class NFCValidateResponse(BaseModel):
    valid: bool
    source: str = SourceType.NFC.value
    user_id: str | None = None
    message: str | None = None


@router.post("/nfc/validate", status_code=status.HTTP_501_NOT_IMPLEMENTED)
def validate_nfc() -> None:
    """PROXY ERP: validação de NFC requer consulta ao Nexora ERP."""
    raise HTTPException(
        status_code=501,
        detail="Validacao de NFC é feita no Nexora ERP. Endpoint em construcao.",
    )


# ══════════════════════════════════════════════════════════════════════════════
# Geolocalização / Geofencing (delegado no ERP)
# ══════════════════════════════════════════════════════════════════════════════

class GeoValidateRequest(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    unit_id: str | None = None
    radius_meters: float = Field(100, ge=1)


class GeoValidateResponse(BaseModel):
    valid: bool
    source: str = SourceType.GEOLOCATION.value
    distance_meters: float | None = None
    message: str | None = None


@router.post("/geolocation/validate", response_model=GeoValidateResponse)
async def validate_geolocation(
    request: GeoValidateRequest,
    actor: ActorContext = Depends(get_actor),
) -> GeoValidateResponse:
    """Valida coordenadas GPS.

    No modelo stateless a configuração de unidades e geofencing vive no ERP.
    Por enquanto opera em modo permissivo; futuramente consultará o ERP.
    """
    await validar_metodo_assiduidade(SourceType.GEOLOCATION)

    # TODO: consultar configuração de unidades/geofencing no ERP (Fase 6)
    return GeoValidateResponse(
        valid=True,
        message="Geolocalizacao aceita (configuracao ERP pendente).",
    )
