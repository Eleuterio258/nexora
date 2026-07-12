import asyncio
import uuid
from datetime import datetime, timezone
from uuid import UUID

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.database import Base, get_db
from app.main import app
from app.schemas.common import EventType, SourceType, TemplateStatus

SQLALCHEMY_DATABASE_URL = "sqlite:///./test_faceclock.db"

engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def _clean_qr_store():
    from app.routers.methods import _qr_store
    _qr_store.clear()


@pytest.fixture(autouse=True)
def setup_and_teardown_db():
    _clean_qr_store()
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)
    _clean_qr_store()


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


@pytest.fixture
def sample_face_template(db_session, erp_user_id):
    from app.models import FaceTemplate
    from app.services.biometric import serialize_embedding

    template = FaceTemplate(
        tenant_id=None,
        erp_user_id=erp_user_id,
        erp_funcionario_id=None,
        model_version="test-v1",
        embedding=serialize_embedding([0.1] * 512),
        quality_score=0.9,
        status=TemplateStatus.ACTIVE,
    )
    db_session.add(template)
    db_session.commit()
    db_session.refresh(template)
    return template




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
# TESTES: Consents (apenas efeito local nos templates)
# ============================================================
class TestConsents:
    def test_revoke_consent_deactivates_face_templates(
        self, client, admin_headers, erp_user_id, sample_face_template, db_session
    ):
        response = client.post(
            f"/api/v1/consents/users/{erp_user_id}/revoke",
            headers=admin_headers,
        )
        assert response.status_code == 200
        db_session.refresh(sample_face_template)
        assert sample_face_template.status == TemplateStatus.REVOKED

    def test_delete_biometric_data_removes_templates(
        self, client, admin_headers, erp_user_id, db_session
    ):
        from app.models import FaceTemplate, FingerprintTemplate
        from app.services.biometric import serialize_embedding

        face = FaceTemplate(
            tenant_id=None,
            erp_user_id=erp_user_id,
            model_version="test-v1",
            embedding=serialize_embedding([0.2] * 512),
        )
        finger = FingerprintTemplate(
            tenant_id=None,
            erp_user_id=erp_user_id,
            finger_type="right_thumb",
            template_base64="dGVzdA==",
        )
        db_session.add_all([face, finger])
        db_session.commit()

        response = client.delete(
            f"/api/v1/consents/users/{erp_user_id}/biometric-data",
            headers=admin_headers,
        )
        assert response.status_code == 204
        assert db_session.query(FaceTemplate).count() == 0
        assert db_session.query(FingerprintTemplate).count() == 0


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
# TESTES: QR Code (em memoria)
# ============================================================
class TestQRCode:
    def test_generate_and_validate_qr(self, client, admin_headers):
        response = client.post(
            "/api/v1/qr/generate",
            json={"location_id": "sala-1", "session_duration_seconds": 60},
            headers=admin_headers,
        )
        assert response.status_code == 201
        data = response.json()
        qr_code = data["qr_code"]

        response = client.post(
            "/api/v1/qr/validate",
            json={"qr_code": qr_code},
            headers=admin_headers,
        )
        assert response.status_code == 200
        assert response.json()["valid"] is True

    def test_validate_used_qr_fails(self, client, admin_headers):
        response = client.post(
            "/api/v1/qr/generate",
            json={"session_duration_seconds": 60},
            headers=admin_headers,
        )
        qr_code = response.json()["qr_code"]

        client.post(
            "/api/v1/qr/validate",
            json={"qr_code": qr_code},
            headers=admin_headers,
        )
        response = client.post(
            "/api/v1/qr/validate",
            json={"qr_code": qr_code},
            headers=admin_headers,
        )
        assert response.status_code == 400


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
# TESTES: Attendance Config (proxy ERP)
# ============================================================
class TestAttendanceConfig:
    def test_get_tenant_attendance_config_erp_unavailable(self, client, admin_headers, monkeypatch):
        from app.erp_client import ERPUnavailableError
        from app.routers import attendance_config

        async def fail():
            raise ERPUnavailableError("ERP offline")

        monkeypatch.setattr(attendance_config, "_get_config_cached", lambda: fail())
        response = client.get("/api/v1/tenant/attendance-config", headers=admin_headers)
        assert response.status_code == 503


# ============================================================
# TESTES: Metodos delegados / obsoletos
# ============================================================
class TestDelegatedOrObsoleteEndpoints:
    def test_clock_sync_is_gone(self, client, admin_headers):
        response = client.post("/api/v1/clock/sync", json={"record_ids": []}, headers=admin_headers)
        assert response.status_code == 410

    def test_audit_logs_is_not_implemented(self, client, admin_headers):
        response = client.get("/api/v1/audit/logs", headers=admin_headers)
        assert response.status_code == 501

    def test_consents_create_is_not_implemented(self, client, admin_headers):
        response = client.post(
            "/api/v1/consents",
            json={
                "user_id": str(uuid.uuid4()),
                "term_version": "1",
                "consent_hash": "abc",
                "accepted_at": "2026-01-01T00:00:00Z",
            },
            headers=admin_headers,
        )
        assert response.status_code == 501


# ============================================================
# TESTES: ERP Client
# ============================================================
class TestErpClientBatch:
    def test_send_attendance_events_batch_empty_list_short_circuits(self):
        from app.erp_client import ERPClient

        client = ERPClient()
        client.base_url = "http://erp.invalido.local"
        result = asyncio.run(client.send_attendance_events_batch([]))
        assert result == {"total": 0, "processed": 0, "failed": 0, "results": []}

    def test_send_attendance_events_batch_rejects_over_100(self):
        from app.erp_client import ERPClient

        client = ERPClient()
        client.base_url = "http://erp.invalido.local"
        with pytest.raises(ValueError):
            asyncio.run(client.send_attendance_events_batch([{"EmployeeNo": "x"}] * 101))


# ============================================================
# TESTES: ERP Attendance Forwarder
# ============================================================
class TestErpAttendanceForwarderPayload:
    def test_build_clock_event_payload(self):
        from datetime import datetime
        from app.services.erp_attendance_forwarder import build_clock_event_payload

        dt = datetime.now(timezone.utc)
        user_id = UUID("12345678-1234-5678-1234-567812345678")
        payload = build_clock_event_payload(
            user_id=user_id,
            employee_code="EMP001",
            device_code="TOTEM-01",
            event_type=EventType.ENTRY,
            recorded_at=dt,
            source=SourceType.FACIAL,
        )
        assert payload["device_serial"] == "TOTEM-01"
        assert payload["employee_no"] == "EMP001"
        assert payload["direction"] == "in"
        assert payload["credential_type"] == "face"
