"""
Router para métodos alternativos de registo de presença:
- QR Code
- NFC
- Geofencing / Geolocalização

Estes endpoints validam o método escolhido. O registo final do ponto continua
a ser feito via /clock/register com o source apropriado.
"""

from datetime import datetime, timedelta
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import ActorContext, apply_tenant, get_actor
from app.models import Device, Unit, User
from app.schemas.common import SourceType

router = APIRouter(tags=["Attendance Methods"])


# ══════════════════════════════════════════════════════════════════════════════
# QR Code
# ══════════════════════════════════════════════════════════════════════════════

class QRValidateRequest(BaseModel):
    qr_code: str = Field(..., min_length=1)
    user_id: str | None = None


class QRValidateResponse(BaseModel):
    valid: bool
    source: str = SourceType.QR_CODE.value
    payload: dict[str, Any] | None = None
    message: str | None = None


# Store ativo em memória; em produção usar Redis.
_qr_store: dict[str, dict[str, Any]] = {}


def generate_qr_code_data(tenant_id: str, location_id: str | None = None, session_duration_seconds: int = 60) -> tuple[str, dict[str, Any]]:
    """Gera dados de QR Code (utilitário para outros routers/admin)."""
    timestamp = datetime.utcnow().isoformat()
    expires_at = (datetime.utcnow() + timedelta(seconds=session_duration_seconds)).isoformat()
    payload = {
        "tenant_id": tenant_id,
        "location_id": location_id,
        "timestamp": timestamp,
        "expires_at": expires_at,
    }
    qr_hash = f"qr:{tenant_id}:{timestamp}:{location_id or ''}"
    _qr_store[qr_hash] = {"payload": payload, "used": False}
    return qr_hash, payload


@router.post("/qr/validate", response_model=QRValidateResponse)
def validate_qr(
    request: QRValidateRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> QRValidateResponse:
    """Valida um QR Code de presença."""
    data = _qr_store.get(request.qr_code)
    if not data:
        raise HTTPException(status_code=400, detail="QR Code invalido.")

    if data["used"]:
        raise HTTPException(status_code=400, detail="QR Code ja utilizado.")

    payload = data["payload"]
    expires_at = payload.get("expires_at")
    if expires_at and datetime.utcnow() > datetime.fromisoformat(expires_at):
        raise HTTPException(status_code=400, detail="QR Code expirado.")

    qr_tenant_id = payload.get("tenant_id")
    if actor.tenant_id and qr_tenant_id and actor.tenant_id != qr_tenant_id:
        raise HTTPException(status_code=403, detail="QR Code pertence a outro tenant.")

    data["used"] = True
    return QRValidateResponse(valid=True, payload=payload, message="QR Code valido.")


# ══════════════════════════════════════════════════════════════════════════════
# NFC
# ══════════════════════════════════════════════════════════════════════════════

class NFCValidateRequest(BaseModel):
    nfc_tag: str = Field(..., min_length=1)


class NFCValidateResponse(BaseModel):
    valid: bool
    source: str = SourceType.NFC.value
    user_id: str | None = None
    message: str | None = None


@router.post("/nfc/validate", response_model=NFCValidateResponse)
def validate_nfc(
    request: NFCValidateRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> NFCValidateResponse:
    """Valida uma tag NFC vinculada a um utilizador."""
    user = db.scalar(
        apply_tenant(select(User).where(User.nfc_tag == request.nfc_tag), actor, User)
    )
    if not user:
        raise HTTPException(status_code=400, detail="Tag NFC nao associada a nenhum utilizador.")

    return NFCValidateResponse(
        valid=True,
        user_id=str(user.id),
        message="Tag NFC valida.",
    )


# ══════════════════════════════════════════════════════════════════════════════
# Geolocalização / Geofencing
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


def _haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calcula distância em metros entre duas coordenadas (fórmula de Haversine)."""
    from math import asin, cos, radians, sin, sqrt

    R = 6371000  # raio da Terra em metros
    phi1, phi2 = radians(lat1), radians(lat2)
    dphi = radians(lat2 - lat1)
    dlambda = radians(lon2 - lon1)
    a = sin(dphi / 2) ** 2 + cos(phi1) * cos(phi2) * sin(dlambda / 2) ** 2
    return 2 * R * asin(sqrt(a))


@router.post("/geolocation/validate", response_model=GeoValidateResponse)
def validate_geolocation(
    request: GeoValidateRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> GeoValidateResponse:
    """Valida se a coordenada GPS está dentro do raio permitido de uma unidade."""
    if request.unit_id:
        unit = db.scalar(
            apply_tenant(select(Unit).where(Unit.id == request.unit_id), actor, Unit)
        )
    else:
        # Se nenhuma unidade for especificada, usa a primeira ativa do tenant com coordenadas.
        unit = db.scalar(
            apply_tenant(
                select(Unit).where(Unit.active == True).order_by(Unit.created_at.asc()),
                actor,
                Unit,
            )
        )

    if not unit or unit.geo_lat is None or unit.geo_lng is None:
        # Sem unidade configurada, aceita a localizacao (modo permissivo).
        return GeoValidateResponse(
            valid=True,
            message="Nenhuma unidade com geofencing configurado. Localizacao aceita.",
        )

    distance = _haversine_distance(
        request.latitude, request.longitude, float(unit.geo_lat), float(unit.geo_lng)
    )
    valid = distance <= request.radius_meters

    if not valid:
        raise HTTPException(
            status_code=400,
            detail=f"Localizacao fora do raio permitido. Distancia: {distance:.0f}m",
        )

    return GeoValidateResponse(
        valid=True,
        distance_meters=round(distance, 2),
        message=f"Localizacao dentro do raio permitido ({distance:.0f}m).",
    )
