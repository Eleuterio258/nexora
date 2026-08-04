import json
import uuid

import pytest
from fastapi.testclient import TestClient

from app.redis_client import set_redis_client
from app.security import NexoraAuth
from app.services.api_credentials import create_credential


def _sign(secret, access_key, method, path, query="", payload=None):
    body = (
        json.dumps(payload, separators=(",", ":"), sort_keys=True).encode("utf-8")
        if payload is not None
        else b""
    )
    auth = NexoraAuth(access_key, secret)
    return auth.sign_request(method, path, query=query, body=body), body


@pytest.fixture
def fake_redis():
    import fakeredis

    client = fakeredis.FakeStrictRedis(version=6)
    set_redis_client(client)
    yield client
    set_redis_client(None)


@pytest.fixture
def system_credential(db_session):
    cred, secret = create_credential(
        db=db_session,
        tenant_id="tenant-1",
        name="Test System",
        permissions=[
            "biometric:enroll",
            "biometric:verify",
            "fingerprint:enroll",
            "fingerprint:identify",
            "fingerprint:delete",
            "liveness:challenge",
            "liveness:verify",
        ],
    )
    return cred, secret


# ============================================================
# TESTES: Health Check
# ============================================================
class TestHealthCheck:
    def test_health_returns_ok(self, client):
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"
        assert "version" in data


# ============================================================
# TESTES: Fingerprint
# ============================================================
class TestFingerprint:
    def test_enroll_and_identify(self, client, db_session, fake_redis, system_credential):
        cred, secret = system_credential
        payload = {
            "user_id": "erp-user-123",
            "finger_type": "right_thumb",
            "template_base64": "dGVzdDE=",
        }
        headers, body = _sign(secret, cred.access_key_id, "POST", "/api/v1/fingerprint/enroll", payload=payload)

        response = client.post("/api/v1/fingerprint/enroll", content=body, headers=headers)
        assert response.status_code == 201
        data = response.json()
        assert data["success"] is True
        assert data["template_id"] is not None
        assert data["user_id"] == "erp-user-123"

        headers, body = _sign(
            secret,
            cred.access_key_id,
            "POST",
            "/api/v1/fingerprint/identify",
            payload={"template_base64": "dGVzdDE="},
        )
        response = client.post("/api/v1/fingerprint/identify", content=body, headers=headers)
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["user_id"] == "erp-user-123"

    def test_delete_fingerprint_enrollment(self, client, db_session, fake_redis, system_credential):
        cred, secret = system_credential
        payload = {
            "user_id": "erp-user-123",
            "finger_type": "right_thumb",
            "template_base64": "dGVzdDE=",
        }
        headers, body = _sign(secret, cred.access_key_id, "POST", "/api/v1/fingerprint/enroll", payload=payload)
        client.post("/api/v1/fingerprint/enroll", content=body, headers=headers)

        headers, body = _sign(
            secret,
            cred.access_key_id,
            "DELETE",
            "/api/v1/fingerprint/enroll/erp-user-123",
        )
        response = client.delete("/api/v1/fingerprint/enroll/erp-user-123", headers=headers)
        assert response.status_code == 200
        assert response.json()["success"] is True

    def test_enroll_rejects_invalid_base64(self, client, db_session, fake_redis, system_credential):
        cred, secret = system_credential
        payload = {
            "user_id": "erp-user-123",
            "finger_type": "right_thumb",
            "template_base64": "not-valid-base64!!!",
        }
        headers, body = _sign(secret, cred.access_key_id, "POST", "/api/v1/fingerprint/enroll", payload=payload)
        response = client.post("/api/v1/fingerprint/enroll", content=body, headers=headers)
        assert response.status_code == 422


# ============================================================
# TESTES: Biometric (mockado)
# ============================================================
class TestBiometric:
    def test_enroll_and_verify_with_mocked_pipeline(
        self, client, db_session, fake_redis, system_credential, monkeypatch
    ):
        from app.routers import biometric as biometric_router

        fixed_embedding = [0.5] * 512
        user_uuid = str(uuid.uuid4())

        monkeypatch.setattr(biometric_router, "assess_capture_quality", lambda *args, **kwargs: (0.95, None))
        monkeypatch.setattr(biometric_router, "build_embedding", lambda *args, **kwargs: fixed_embedding)
        monkeypatch.setattr(biometric_router, "estimate_liveness", lambda *args, **kwargs: 0.95)

        cred, secret = system_credential
        captures = [{"image_base64": "fake", "angle": "front"} for _ in range(3)]
        payload = {"user_id": user_uuid, "captures": captures}
        headers, body = _sign(secret, cred.access_key_id, "POST", "/api/v1/biometric/enroll", payload=payload)

        response = client.post("/api/v1/biometric/enroll", content=body, headers=headers)
        assert response.status_code == 201
        data = response.json()
        assert data["user_id"] == user_uuid

        payload = {
            "user_id": user_uuid,
            "device_id": str(uuid.uuid4()),
            "image_base64": "fake",
        }
        headers, body = _sign(secret, cred.access_key_id, "POST", "/api/v1/biometric/verify", payload=payload)
        response = client.post("/api/v1/biometric/verify", content=body, headers=headers)
        assert response.status_code == 200
        data = response.json()
        assert data["match"] is True
        assert data["user_id"] == user_uuid

    def test_verify_without_enrollment_returns_not_enrolled(
        self, client, db_session, fake_redis, system_credential, monkeypatch
    ):
        from app.routers import biometric as biometric_router

        user_uuid = str(uuid.uuid4())

        monkeypatch.setattr(biometric_router, "assess_capture_quality", lambda *args, **kwargs: (0.95, None))
        monkeypatch.setattr(biometric_router, "build_embedding", lambda *args, **kwargs: [0.5] * 512)
        monkeypatch.setattr(biometric_router, "estimate_liveness", lambda *args, **kwargs: 0.95)

        cred, secret = system_credential
        payload = {
            "user_id": user_uuid,
            "device_id": str(uuid.uuid4()),
            "image_base64": "fake",
        }
        headers, body = _sign(secret, cred.access_key_id, "POST", "/api/v1/biometric/verify", payload=payload)
        response = client.post("/api/v1/biometric/verify", content=body, headers=headers)
        assert response.status_code == 200
        assert response.json()["reason"] == "user_not_enrolled"


# ============================================================
# TESTES: Controlo de acesso via HMAC
# ============================================================
class TestAccessControlHMAC:
    def test_anonymous_request_rejected(self, client, fake_redis):
        response = client.post(
            "/api/v1/fingerprint/enroll",
            json={
                "user_id": "erp-user-123",
                "finger_type": "right_thumb",
                "template_base64": "dGVzdDE=",
            },
        )
        assert response.status_code == 401

    def test_credential_without_permission_rejected(self, client, db_session, fake_redis):
        cred, secret = create_credential(
            db=db_session,
            tenant_id="tenant-1",
            permissions=["biometric:verify"],  # não tem fingerprint:enroll
        )
        payload = {
            "user_id": "erp-user-123",
            "finger_type": "right_thumb",
            "template_base64": "dGVzdDE=",
        }
        headers, body = _sign(secret, cred.access_key_id, "POST", "/api/v1/fingerprint/enroll", payload=payload)
        response = client.post("/api/v1/fingerprint/enroll", content=body, headers=headers)
        assert response.status_code == 403


# ============================================================
# TESTES: Auditoria (proxy ERP) — protegido por Nexora HMAC
# ============================================================
class TestAuditLogsProxy:
    def test_audit_logs_requires_hmac(self, client, fake_redis):
        response = client.get("/api/v1/audit/logs")
        assert response.status_code == 401

    def test_audit_logs_proxies_to_erp(self, client, db_session, fake_redis, system_credential, monkeypatch):
        from app import erp_client as erp_client_module

        async def fake_list_audit_logs(**kwargs):
            return {"data": [], "meta": {"total": 0, "page": 1, "limit": 50}}

        # Garantir permissão audit:read
        cred, secret = system_credential
        cred.permissions = ["audit:read"]
        db_session.commit()

        monkeypatch.setattr(erp_client_module.erp_client, "list_audit_logs", fake_list_audit_logs)

        headers, _ = _sign(secret, cred.access_key_id, "GET", "/api/v1/audit/logs")
        response = client.get("/api/v1/audit/logs", headers=headers)
        assert response.status_code == 200
        assert response.json() == {"data": [], "meta": {"total": 0, "page": 1, "limit": 50}}
