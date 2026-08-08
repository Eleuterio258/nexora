import base64
import json
import uuid

import pytest

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
        permissions=["biometric:enroll", "biometric:verify"],
    )
    return cred, secret


class TestExportTemplates:
    def test_requires_permission(self, client, db_session, fake_redis, system_credential):
        cred, secret = system_credential
        headers, _ = _sign(secret, cred.access_key_id, "GET", "/api/v1/admin/biometric/export-templates")
        response = client.get("/api/v1/admin/biometric/export-templates", headers=headers)
        assert response.status_code == 403

    def test_export_returns_ciphertext_and_metadata(
        self, client, db_session, fake_redis, system_credential, monkeypatch
    ):
        from app.routers import biometric as biometric_router

        monkeypatch.setattr(biometric_router, "assess_capture_quality", lambda *args, **kwargs: (0.95, None))
        monkeypatch.setattr(biometric_router, "build_embedding", lambda *args, **kwargs: [0.5] * 512)
        monkeypatch.setattr(biometric_router, "estimate_liveness", lambda *args, **kwargs: 0.95)

        async def _fake_validar_consentimento(*args, **kwargs):
            return {"id": "fake"}

        monkeypatch.setattr(
            biometric_router.erp_client, "validar_consentimento_ativo", _fake_validar_consentimento
        )

        cred, secret = system_credential
        cred.permissions = list(cred.permissions) + ["biometric:admin"]
        db_session.commit()

        user_uuid = str(uuid.uuid4())
        captures = [{"image_base64": "fake", "angle": "front"} for _ in range(3)]
        payload = {"user_id": user_uuid, "captures": captures}
        headers, body = _sign(secret, cred.access_key_id, "POST", "/api/v1/biometric/enroll", payload=payload)
        response = client.post("/api/v1/biometric/enroll", content=body, headers=headers)
        assert response.status_code == 201

        headers, _ = _sign(
            secret, cred.access_key_id, "GET", "/api/v1/admin/biometric/export-templates",
            query=f"erp_user_id={user_uuid}",
        )
        response = client.get(
            f"/api/v1/admin/biometric/export-templates?erp_user_id={user_uuid}", headers=headers
        )
        assert response.status_code == 200
        data = response.json()
        assert data["count"] == 1
        template = data["templates"][0]
        assert template["erp_user_id"] == user_uuid
        assert template["status"] == "ACTIVE"
        # embedding_b64 e o ciphertext (AES-GCM), nunca o vector em claro.
        raw = base64.b64decode(template["embedding_b64"])
        assert raw.startswith(b"enc:v2:") or raw.startswith(b"enc:v1:")

    def test_export_isolated_by_tenant(self, client, db_session, fake_redis, monkeypatch):
        from app.routers import biometric as biometric_router

        monkeypatch.setattr(biometric_router, "assess_capture_quality", lambda *args, **kwargs: (0.95, None))
        monkeypatch.setattr(biometric_router, "build_embedding", lambda *args, **kwargs: [0.5] * 512)
        monkeypatch.setattr(biometric_router, "estimate_liveness", lambda *args, **kwargs: 0.95)

        async def _fake_validar_consentimento(*args, **kwargs):
            return {"id": "fake"}

        monkeypatch.setattr(
            biometric_router.erp_client, "validar_consentimento_ativo", _fake_validar_consentimento
        )

        cred_a, secret_a = create_credential(
            db=db_session, tenant_id="tenant-export-a",
            permissions=["biometric:enroll", "biometric:admin"],
        )
        cred_b, secret_b = create_credential(
            db=db_session, tenant_id="tenant-export-b",
            permissions=["biometric:admin"],
        )

        user_uuid = str(uuid.uuid4())
        captures = [{"image_base64": "fake", "angle": "front"} for _ in range(3)]
        payload = {"user_id": user_uuid, "captures": captures}
        headers, body = _sign(secret_a, cred_a.access_key_id, "POST", "/api/v1/biometric/enroll", payload=payload)
        client.post("/api/v1/biometric/enroll", content=body, headers=headers)

        headers, _ = _sign(secret_b, cred_b.access_key_id, "GET", "/api/v1/admin/biometric/export-templates")
        response = client.get("/api/v1/admin/biometric/export-templates", headers=headers)
        assert response.json()["count"] == 0

        headers, _ = _sign(secret_a, cred_a.access_key_id, "GET", "/api/v1/admin/biometric/export-templates")
        response = client.get("/api/v1/admin/biometric/export-templates", headers=headers)
        assert response.json()["count"] == 1
