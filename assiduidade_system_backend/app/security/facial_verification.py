"""Emissao de comprovativos curtos para vincular o match facial ao ponto no ERP."""

from datetime import datetime, timedelta, timezone
from uuid import uuid4

import jwt

from app.config import settings
ISSUER = "faceclock"
AUDIENCE = "nexora-facial-attendance"


def issue_facial_verification_token(
    *,
    tenant_id: str,
    user_id: str,
    device_id: str,
    confidence_score: float,
    liveness_score: float,
) -> str:
    """Assina uma prova de match vinculada ao actor, tenant e dispositivo."""
    if not tenant_id:
        raise ValueError("template_without_tenant")

    now = datetime.now(timezone.utc)
    expires_at = now + timedelta(seconds=settings.facial_verification_ttl_seconds)
    claims = {
        "iss": ISSUER,
        "aud": AUDIENCE,
        "sub": str(user_id),
        "tid": str(tenant_id),
        "device_id": str(device_id),
        "purpose": "facial_attendance",
        "confidence_score": float(confidence_score),
        "liveness_score": float(liveness_score),
        "jti": str(uuid4()),
        "iat": now,
        "nbf": now,
        "exp": expires_at,
    }
    return jwt.encode(claims, settings.facial_verification_secret, algorithm="HS256")
