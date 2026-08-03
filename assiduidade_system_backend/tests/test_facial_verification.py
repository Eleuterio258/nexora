from uuid import UUID

import jwt

from app.config import settings
from app.security.facial_verification import (
    AUDIENCE,
    ISSUER,
    issue_facial_verification_token,
)


def test_verification_token_is_bound_to_identity_tenant_and_device():
    token = issue_facial_verification_token(
        tenant_id="17",
        user_id="42",
        device_id="mobile-device-1",
        confidence_score=0.93,
        liveness_score=0.88,
    )

    claims = jwt.decode(
        token,
        settings.facial_verification_secret,
        algorithms=["HS256"],
        issuer=ISSUER,
        audience=AUDIENCE,
    )

    assert claims["sub"] == "42"
    assert claims["tid"] == "17"
    assert claims["device_id"] == "mobile-device-1"
    assert claims["purpose"] == "facial_attendance"
    assert claims["confidence_score"] == 0.93
    assert claims["liveness_score"] == 0.88
    UUID(claims["jti"])
    assert 0 < claims["exp"] - claims["iat"] <= settings.facial_verification_ttl_seconds
