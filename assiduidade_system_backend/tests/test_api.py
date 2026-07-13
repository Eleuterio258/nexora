import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.database import Base, get_db
from app.main import app
from app.schemas.common import SourceType, TemplateStatus

SQLALCHEMY_DATABASE_URL = "sqlite:///./test_faceclock.db"

engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(autouse=True)
def setup_and_teardown_db():
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


@pytest.fixture
def db_session():
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture
def client(db_session):
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()


@pytest.fixture
def admin_headers():
    return {"X-Auth-User-Id": "admin-erp-42", "X-Auth-User-Role": "ADMIN_SISTEMA"}


@pytest.fixture
def collab_headers():
    return {"X-Auth-User-Id": "collab-erp-99", "X-Auth-User-Role": "COLABORADOR"}


@pytest.fixture
def erp_user_id():
    return "erp-user-123"


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
    def test_enroll_and_identify(self, client, admin_headers, erp_user_id):
        response = client.post(
            "/api/v1/fingerprint/enroll",
            json={
                "user_id": erp_user_id,
                "finger_type": "right_thumb",
                "template_base64": "dGVzdDE=",
            },
            headers=admin_headers,
        )
        assert response.status_code == 200
        assert response.json()["success"] is True

        response = client.post(
            "/api/v1/fingerprint/identify",
            json={"template_base64": "dGVzdDE="},
            headers=admin_headers,
        )
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["user_id"] == erp_user_id

    def test_delete_fingerprint_enrollment(self, client, admin_headers, erp_user_id):
        client.post(
            "/api/v1/fingerprint/enroll",
            json={
                "user_id": erp_user_id,
                "finger_type": "right_thumb",
                "template_base64": "dGVzdDE=",
            },
            headers=admin_headers,
        )
        response = client.delete(
            f"/api/v1/fingerprint/enroll/{erp_user_id}",
            headers=admin_headers,
        )
        assert response.status_code == 200
        assert response.json()["success"] is True


# ============================================================
# TESTES: Biometric (mockado)
# ============================================================
class TestBiometric:
    def test_enroll_and_verify_with_mocked_pipeline(
        self, client, admin_headers, monkeypatch
    ):
        from app.routers import biometric as biometric_router

        fixed_embedding = [0.5] * 512
        user_uuid = str(uuid.uuid4())

        monkeypatch.setattr(biometric_router, "assess_capture_quality", lambda _: (0.95, None))
        monkeypatch.setattr(biometric_router, "build_embedding", lambda _: fixed_embedding)
        monkeypatch.setattr(biometric_router, "estimate_liveness", lambda _, **kw: 0.95)

        captures = [{"image_base64": "fake", "angle": "front"} for _ in range(3)]
        response = client.post(
            "/api/v1/biometric/enroll",
            json={"user_id": user_uuid, "captures": captures},
            headers=admin_headers,
        )
        assert response.status_code == 201
        data = response.json()
        assert data["user_id"] == user_uuid
        assert data["status"] == TemplateStatus.ACTIVE

        response = client.post(
            "/api/v1/biometric/verify",
            json={
                "user_id": user_uuid,
                "device_id": str(uuid.uuid4()),
                "image_base64": "fake",
            },
            headers=admin_headers,
        )
        assert response.status_code == 200
        data = response.json()
        assert data["match"] is True
        assert data["user_id"] == user_uuid

    def test_verify_without_enrollment_returns_not_enrolled(
        self, client, admin_headers, monkeypatch
    ):
        from app.routers import biometric as biometric_router

        user_uuid = str(uuid.uuid4())

        monkeypatch.setattr(biometric_router, "assess_capture_quality", lambda _: (0.95, None))
        monkeypatch.setattr(biometric_router, "build_embedding", lambda _: [0.5] * 512)
        monkeypatch.setattr(biometric_router, "estimate_liveness", lambda _, **kw: 0.95)

        response = client.post(
            "/api/v1/biometric/verify",
            json={
                "user_id": user_uuid,
                "device_id": str(uuid.uuid4()),
                "image_base64": "fake",
            },
            headers=admin_headers,
        )
        assert response.status_code == 200
        assert response.json()["reason"] == "user_not_enrolled"


# ============================================================
# TESTES: Auditoria (proxy ERP)
# ============================================================
class TestAuditLogsProxy:
    def test_audit_logs_requires_authorization(self, client):
        response = client.get("/api/v1/audit/logs")
        assert response.status_code == 401

    def test_audit_logs_proxies_to_erp(self, client, monkeypatch):
        from app import erp_client as erp_client_module

        async def fake_list_audit_logs(authorization, **kwargs):
            assert authorization == "Bearer tok123"
            return {"data": [], "meta": {"total": 0, "page": 1, "limit": 50}}

        monkeypatch.setattr(erp_client_module.erp_client, "list_audit_logs", fake_list_audit_logs)
        response = client.get("/api/v1/audit/logs", headers={"Authorization": "Bearer tok123"})
        assert response.status_code == 200
        assert response.json() == {"data": [], "meta": {"total": 0, "page": 1, "limit": 50}}

