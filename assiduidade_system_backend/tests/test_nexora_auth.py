"""Testes de integração da autenticação Nexora HMAC."""

import hashlib
import hmac
import json
import time
import uuid

import fakeredis
import pytest

from app.redis_client import set_redis_client
from app.security import NexoraAuth
from app.services.api_credentials import create_credential


def _sign(secret, access_key, method, path, query="", payload=None, timestamp=None, nonce=None):
    body = json.dumps(payload, separators=(",", ":"), sort_keys=True).encode("utf-8") if payload is not None else b""
    body_hash = hashlib.sha256(body).hexdigest()
    timestamp = timestamp or str(int(time.time()))
    nonce = nonce or str(uuid.uuid4())

    canonical = (
        f"{method.upper()}\n"
        f"{path}\n"
        f"{query}\n"
        f"{timestamp}\n"
        f"{nonce}\n"
        f"{body_hash}"
    )
    signature = hmac.new(secret.encode("utf-8"), canonical.encode("utf-8"), hashlib.sha256).hexdigest()

    return {
        "X-Nexora-Access-Key": access_key,
        "X-Nexora-Timestamp": timestamp,
        "X-Nexora-Nonce": nonce,
        "X-Nexora-Content-SHA256": body_hash,
        "X-Nexora-Signature": signature,
        "X-Nexora-Auth-Version": "NEXORA-HMAC-SHA256-V1",
        "Content-Type": "application/json",
    }, body


@pytest.fixture
def fake_redis():
    client = fakeredis.FakeStrictRedis(version=6)
    set_redis_client(client)
    yield client
    set_redis_client(None)


@pytest.fixture
def verify_credential(db_session):
    cred, secret = create_credential(
        db=db_session,
        tenant_id="tenant-1",
        permissions=["biometric:verify"],
    )
    return cred, secret


@pytest.fixture
def mock_biometric_verify(monkeypatch):
    """Mocka o pipeline biométrico para devolver match=False sem modelos."""
    from app.routers import biometric as biometric_router

    monkeypatch.setattr(biometric_router, "assess_capture_quality", lambda *args, **kwargs: (0.95, None))
    monkeypatch.setattr(biometric_router, "build_embedding", lambda *args, **kwargs: [0.5] * 512)
    monkeypatch.setattr(biometric_router, "estimate_liveness", lambda *args, **kwargs: 0.95)


def test_valid_signature_returns_200(client, fake_redis, verify_credential, mock_biometric_verify):
    cred, secret = verify_credential
    payload = {"user_id": "usr_123", "device_id": str(uuid.uuid4()), "image_base64": "fake"}
    headers, body = _sign(secret, cred.access_key_id, "POST", "/api/v1/biometric/verify", payload=payload)

    response = client.post("/api/v1/biometric/verify", content=body, headers=headers)
    assert response.status_code == 200


def test_unknown_access_key_returns_401(client, fake_redis, mock_biometric_verify):
    payload = {"user_id": "usr_123", "device_id": str(uuid.uuid4()), "image_base64": "fake"}
    headers, body = _sign("nexora_sk_test", "nexora_ak_inexistente", "POST", "/api/v1/biometric/verify", payload=payload)

    response = client.post("/api/v1/biometric/verify", content=body, headers=headers)
    assert response.status_code == 401
    assert "inválidas" in response.json()["detail"].lower()


def test_invalid_signature_returns_401(client, fake_redis, verify_credential, mock_biometric_verify):
    cred, secret = verify_credential
    payload = {"user_id": "usr_123", "device_id": str(uuid.uuid4()), "image_base64": "fake"}
    headers, body = _sign(secret, cred.access_key_id, "POST", "/api/v1/biometric/verify", payload=payload)
    headers["X-Nexora-Signature"] = "assinatura_invalida"

    response = client.post("/api/v1/biometric/verify", content=body, headers=headers)
    assert response.status_code == 401


def test_modified_body_returns_401(client, fake_redis, verify_credential, mock_biometric_verify):
    cred, secret = verify_credential
    payload = {"user_id": "usr_123", "device_id": str(uuid.uuid4()), "image_base64": "fake"}
    headers, _ = _sign(secret, cred.access_key_id, "POST", "/api/v1/biometric/verify", payload=payload)

    modified_body = json.dumps({"user_id": "usr_999", "device_id": str(uuid.uuid4()), "image_base64": "fake"}).encode("utf-8")
    response = client.post("/api/v1/biometric/verify", content=modified_body, headers=headers)
    assert response.status_code == 401


def test_expired_timestamp_returns_401(client, fake_redis, verify_credential, mock_biometric_verify):
    cred, secret = verify_credential
    payload = {"user_id": "usr_123", "device_id": str(uuid.uuid4()), "image_base64": "fake"}
    expired = str(int(time.time()) - 400)
    headers, body = _sign(secret, cred.access_key_id, "POST", "/api/v1/biometric/verify", payload=payload, timestamp=expired)

    response = client.post("/api/v1/biometric/verify", content=body, headers=headers)
    assert response.status_code == 401


def test_reused_nonce_returns_409(client, fake_redis, verify_credential, mock_biometric_verify):
    cred, secret = verify_credential
    payload = {"user_id": "usr_123", "device_id": str(uuid.uuid4()), "image_base64": "fake"}
    nonce = str(uuid.uuid4())
    headers1, body1 = _sign(secret, cred.access_key_id, "POST", "/api/v1/biometric/verify", payload=payload, nonce=nonce)

    response1 = client.post("/api/v1/biometric/verify", content=body1, headers=headers1)
    assert response1.status_code == 200

    headers2, body2 = _sign(secret, cred.access_key_id, "POST", "/api/v1/biometric/verify", payload=payload, nonce=nonce)
    response2 = client.post("/api/v1/biometric/verify", content=body2, headers=headers2)
    assert response2.status_code == 409


def test_revoked_credential_returns_401(client, db_session, fake_redis, verify_credential, mock_biometric_verify):
    from app.services.api_credentials import revoke_credential

    cred, secret = verify_credential
    revoke_credential(db_session, cred.id)

    payload = {"user_id": "usr_123", "device_id": str(uuid.uuid4()), "image_base64": "fake"}
    headers, body = _sign(secret, cred.access_key_id, "POST", "/api/v1/biometric/verify", payload=payload)

    response = client.post("/api/v1/biometric/verify", content=body, headers=headers)
    assert response.status_code == 401
