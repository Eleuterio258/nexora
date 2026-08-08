"""
Registo de chaves publicas dos dispositivos para validacao de assinatura de imagem.

Este servico e self-hosted: as chaves publicas Ed25519 dos dispositivos sao
armazenadas na base de dados do FaceClock e associadas ao tenant + device_id.
"""

from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.deps import ActorContext
from app.models import DevicePublicKey


def register_device_public_key(
    db: Session,
    actor: ActorContext,
    device_id: str,
    public_key_b64: str,
) -> DevicePublicKey:
    """Regista ou actualiza a chave publica de um dispositivo."""
    existing = db.scalar(
        select(DevicePublicKey).where(
            DevicePublicKey.tenant_id == actor.tenant_id,
            DevicePublicKey.device_id == device_id,
        )
    )
    if existing:
        existing.public_key_b64 = public_key_b64
        existing.status = "active"
        existing.revoked_at = None
        return existing

    record = DevicePublicKey(
        tenant_id=actor.tenant_id,
        device_id=device_id,
        public_key_b64=public_key_b64,
        status="active",
    )
    db.add(record)
    db.flush()
    return record


def get_device_public_key(
    db: Session,
    actor: ActorContext,
    device_id: str,
) -> str | None:
    """Devolve a chave publica activa de um dispositivo, ou None."""
    record = db.scalar(
        select(DevicePublicKey).where(
            DevicePublicKey.tenant_id == actor.tenant_id,
            DevicePublicKey.device_id == device_id,
            DevicePublicKey.status == "active",
        )
    )
    return record.public_key_b64 if record else None


def revoke_device_public_key(
    db: Session,
    actor: ActorContext,
    device_id: str,
) -> bool:
    """Revoga a chave publica de um dispositivo."""
    record = db.scalar(
        select(DevicePublicKey).where(
            DevicePublicKey.tenant_id == actor.tenant_id,
            DevicePublicKey.device_id == device_id,
            DevicePublicKey.status == "active",
        )
    )
    if record is None:
        return False
    record.status = "revoked"
    record.revoked_at = datetime.now(timezone.utc)
    return True
