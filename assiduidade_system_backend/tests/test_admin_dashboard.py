import json
import uuid

import pytest

from app.biometric_metrics import BiometricMetrics
from app.redis_client import set_redis_client
from app.security import NexoraAuth
from app.services.api_credentials import create_credential
from app.services.suspicious_activity import (
    MemorySuspiciousActivityStore,
    set_suspicious_activity_store,
)


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
        permissions=["biometric:verify"],
    )
    return cred, secret


class TestMetricsDashboard:
    def test_dashboard_requires_permission(self, client, db_session, fake_redis, system_credential):
        cred, secret = system_credential
        headers, _ = _sign(secret, cred.access_key_id, "GET", "/api/v1/admin/biometric/metrics-dashboard")
        response = client.get("/api/v1/admin/biometric/metrics-dashboard", headers=headers)
        assert response.status_code == 403

    def test_dashboard_returns_expected_shape(self, client, db_session, fake_redis, system_credential, monkeypatch):
        import app.routers.admin as admin_router

        # Singleton global do processo: isolar o estado deste teste.
        fresh_metrics = BiometricMetrics()
        monkeypatch.setattr(admin_router, "biometric_metrics", fresh_metrics)
        fresh_metrics.record_verify_match(0.9, 0.85, liveness_passed=True)
        fresh_metrics.record_verify_rejection("match_below_threshold", 0.4, 0.85, liveness_passed=True)

        set_suspicious_activity_store(MemorySuspiciousActivityStore())

        cred, secret = system_credential
        cred.permissions = list(cred.permissions) + ["biometric:admin"]
        db_session.commit()

        headers, _ = _sign(secret, cred.access_key_id, "GET", "/api/v1/admin/biometric/metrics-dashboard")
        response = client.get("/api/v1/admin/biometric/metrics-dashboard", headers=headers)
        assert response.status_code == 200
        data = response.json()

        assert data["biometric_metrics"]["scope"] == "process-wide"
        assert data["biometric_metrics"]["total_verify_attempts"] == 2
        assert data["biometric_metrics"]["total_verify_matches"] == 1
        assert "suspicious_activity" in data
        assert data["suspicious_activity"]["threshold"] > 0
        assert "audit_summary_24h" in data

    def test_dashboard_audit_summary_isolated_by_tenant(
        self, client, db_session, fake_redis, system_credential, monkeypatch
    ):
        from app.routers import biometric as biometric_router
        from app.services.api_credentials import create_credential

        monkeypatch.setattr(biometric_router, "assess_capture_quality", lambda *args, **kwargs: (0.95, None))
        monkeypatch.setattr(biometric_router, "build_embedding", lambda *args, **kwargs: [0.5] * 512)
        monkeypatch.setattr(biometric_router, "estimate_liveness", lambda *args, **kwargs: 0.95)

        cred_a, secret_a = create_credential(
            db=db_session, tenant_id="tenant-dash-a",
            permissions=["biometric:verify", "biometric:admin"],
        )
        cred_b, secret_b = create_credential(
            db=db_session, tenant_id="tenant-dash-b",
            permissions=["biometric:verify", "biometric:admin"],
        )

        payload = {"user_id": str(uuid.uuid4()), "device_id": str(uuid.uuid4()), "image_base64": "fake"}
        headers, body = _sign(secret_a, cred_a.access_key_id, "POST", "/api/v1/biometric/verify", payload=payload)
        client.post("/api/v1/biometric/verify", content=body, headers=headers)

        headers, _ = _sign(secret_b, cred_b.access_key_id, "GET", "/api/v1/admin/biometric/metrics-dashboard")
        response = client.get("/api/v1/admin/biometric/metrics-dashboard", headers=headers)
        assert response.status_code == 200
        assert response.json()["audit_summary_24h"] == {}

        headers, _ = _sign(secret_a, cred_a.access_key_id, "GET", "/api/v1/admin/biometric/metrics-dashboard")
        response = client.get("/api/v1/admin/biometric/metrics-dashboard", headers=headers)
        assert response.status_code == 200
        assert response.json()["audit_summary_24h"].get("verify_rejection") == 1
