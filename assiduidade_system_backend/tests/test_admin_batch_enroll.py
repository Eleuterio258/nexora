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
def admin_credential(db_session):
    cred, secret = create_credential(
        db=db_session,
        tenant_id="tenant-1",
        name="Test Admin",
        permissions=["biometric:admin"],
    )
    return cred, secret


class TestBatchEnroll:
    def test_requires_permission(self, client, db_session, fake_redis):
        cred, secret = create_credential(db=db_session, tenant_id="tenant-1", permissions=[])
        payload = {"enrollments": [{"user_id": str(uuid.uuid4()), "captures": []}]}
        headers, body = _sign(secret, cred.access_key_id, "POST", "/api/v1/admin/biometric/batch-enroll", payload=payload)
        response = client.post("/api/v1/admin/biometric/batch-enroll", content=body, headers=headers)
        assert response.status_code == 403

    def test_batch_enroll_rejects_item_with_too_few_captures(
        self, client, db_session, fake_redis, admin_credential
    ):
        # BatchEnrollRequest.enrollments e list[EnrollRequest]: um item que
        # nao cumpra EnrollRequest.captures (min_length=3) invalida o pedido
        # inteiro no Pydantic, antes de qualquer processamento.
        cred, secret = admin_credential
        payload = {
            "enrollments": [
                {"user_id": str(uuid.uuid4()), "captures": [{"image_base64": "fake", "angle": "front"}]},
            ]
        }
        headers, body = _sign(secret, cred.access_key_id, "POST", "/api/v1/admin/biometric/batch-enroll", payload=payload)
        response = client.post("/api/v1/admin/biometric/batch-enroll", content=body, headers=headers)
        assert response.status_code == 422

    def test_batch_enroll_multiple_users_succeed(
        self, client, db_session, fake_redis, admin_credential, monkeypatch
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

        cred, secret = admin_credential
        user_a = str(uuid.uuid4())
        user_b = str(uuid.uuid4())

        payload = {
            "enrollments": [
                {"user_id": user_a, "captures": [{"image_base64": "fake", "angle": "front"} for _ in range(3)]},
                {"user_id": user_b, "captures": [{"image_base64": "fake", "angle": "front"} for _ in range(3)]},
            ]
        }
        headers, body = _sign(secret, cred.access_key_id, "POST", "/api/v1/admin/biometric/batch-enroll", payload=payload)
        response = client.post("/api/v1/admin/biometric/batch-enroll", content=body, headers=headers)
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 2
        assert data["success_count"] == 2
        assert data["failure_count"] == 0

    def test_batch_enroll_one_failure_does_not_block_others(
        self, client, db_session, fake_redis, admin_credential, monkeypatch
    ):
        from app.routers import biometric as biometric_router

        call_count = {"n": 0}

        def _quality_side_effect(*args, **kwargs):
            call_count["n"] += 1
            # So a 1a chamada (1a captura do 1o utilizador) falha; a falha
            # aborta o resto das capturas desse utilizador (nao chega a
            # chamar de novo para ele), e o 2o utilizador usa so chamadas
            # posteriores, todas boas.
            if call_count["n"] == 1:
                return (0.10, "low_quality_capture")
            return (0.95, None)

        monkeypatch.setattr(biometric_router, "assess_capture_quality", _quality_side_effect)
        monkeypatch.setattr(biometric_router, "build_embedding", lambda *args, **kwargs: [0.5] * 512)
        monkeypatch.setattr(biometric_router, "estimate_liveness", lambda *args, **kwargs: 0.95)

        async def _fake_validar_consentimento(*args, **kwargs):
            return {"id": "fake"}

        monkeypatch.setattr(
            biometric_router.erp_client, "validar_consentimento_ativo", _fake_validar_consentimento
        )

        cred, secret = admin_credential
        user_fail = str(uuid.uuid4())
        user_success = str(uuid.uuid4())

        payload = {
            "enrollments": [
                {"user_id": user_fail, "captures": [{"image_base64": "fake", "angle": "front"} for _ in range(3)]},
                {"user_id": user_success, "captures": [{"image_base64": "fake", "angle": "front"} for _ in range(3)]},
            ]
        }
        headers, body = _sign(secret, cred.access_key_id, "POST", "/api/v1/admin/biometric/batch-enroll", payload=payload)
        response = client.post("/api/v1/admin/biometric/batch-enroll", content=body, headers=headers)
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 2
        assert data["success_count"] == 1
        assert data["failure_count"] == 1
        results_by_user = {r["user_id"]: r for r in data["results"]}
        assert results_by_user[user_fail]["success"] is False
        assert results_by_user[user_success]["success"] is True
