import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.database import Base, get_db
from app.main import app
from app.security import get_password_hash

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
def admin_user(db_session):
    from app.models import User
    from app.schemas.common import UserRole, UserStatus

    user = User(
        employee_code="TESTADM",
        full_name="Test Admin",
        email="testadmin@faceclock.local",
        password_hash=get_password_hash("admin123"),
        role=UserRole.ADMIN_SISTEMA,
        status=UserStatus.ACTIVE,
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture
def admin_headers(admin_user):
    """Identidade do chamador, informada por quem autenticou (ERP), nao por token.
    Este servico confia no cabecalho X-User-Id/X-User-Role."""
    return {"X-User-Id": admin_user.id, "X-User-Role": "ADMIN_SISTEMA"}


@pytest.fixture
def collab_user(db_session):
    from app.models import User
    from app.schemas.common import UserRole, UserStatus

    user = User(
        employee_code="TESTCOL",
        full_name="Test Colaborador",
        email="testcol@faceclock.local",
        password_hash=get_password_hash("colab123"),
        role=UserRole.COLABORADOR,
        status=UserStatus.ACTIVE,
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture
def collab_headers(collab_user):
    return {"X-User-Id": collab_user.id, "X-User-Role": "COLABORADOR"}


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
# TESTES: Units CRUD
# ============================================================
class TestUnitsCRUD:
    def test_create_unit(self, client, admin_headers):
        response = client.post(
            "/api/v1/admin/units",
            json={"code": "TEST01", "name": "Test Unit"},
            headers=admin_headers,
        )
        assert response.status_code == 201
        data = response.json()
        assert data["code"] == "TEST01"
        assert data["active"] is True

    def test_create_unit_duplicate_code(self, client, admin_headers):
        client.post(
            "/api/v1/admin/units",
            json={"code": "DUP01", "name": "First"},
            headers=admin_headers,
        )
        response = client.post(
            "/api/v1/admin/units",
            json={"code": "DUP01", "name": "Second"},
            headers=admin_headers,
        )
        assert response.status_code == 409

    def test_list_units(self, client, admin_headers):
        client.post(
            "/api/v1/admin/units",
            json={"code": "LIST01", "name": "List Unit"},
            headers=admin_headers,
        )
        response = client.get("/api/v1/admin/units", headers=admin_headers)
        assert response.status_code == 200
        data = response.json()
        assert data["total"] >= 1

    def test_update_unit(self, client, admin_headers):
        create_resp = client.post(
            "/api/v1/admin/units",
            json={"code": "UPD01", "name": "Update Me"},
            headers=admin_headers,
        )
        unit_id = create_resp.json()["id"]

        response = client.patch(
            f"/api/v1/admin/units/{unit_id}",
            json={"name": "Updated Name"},
            headers=admin_headers,
        )
        assert response.status_code == 200
        assert response.json()["name"] == "Updated Name"

    def test_deactivate_unit(self, client, admin_headers):
        create_resp = client.post(
            "/api/v1/admin/units",
            json={"code": "DEL01", "name": "Delete Me"},
            headers=admin_headers,
        )
        unit_id = create_resp.json()["id"]

        response = client.delete(
            f"/api/v1/admin/units/{unit_id}",
            headers=admin_headers,
        )
        assert response.status_code == 204


# ============================================================
# TESTES: Users CRUD
# ============================================================
class TestUsersCRUD:
    def test_create_user(self, client, admin_headers):
        response = client.post(
            "/api/v1/admin/users",
            json={
                "employee_code": "NEWUSER",
                "full_name": "New User",
                "email": "newuser@test.com",
                "password": "password123",
            },
            headers=admin_headers,
        )
        assert response.status_code == 201
        data = response.json()
        assert data["employee_code"] == "NEWUSER"

    def test_create_user_duplicate_code(self, client, admin_headers, admin_user):
        response = client.post(
            "/api/v1/admin/users",
            json={
                "employee_code": "TESTADM",
                "full_name": "Duplicate",
                "password": "pass123",
            },
            headers=admin_headers,
        )
        assert response.status_code == 409

    def test_list_users(self, client, admin_headers):
        response = client.get("/api/v1/admin/users", headers=admin_headers)
        assert response.status_code == 200
        assert response.json()["total"] >= 1

    def test_update_user_password(self, client, admin_headers, collab_user):
        response = client.patch(
            f"/api/v1/admin/users/{collab_user.id}",
            json={"password": "newpassword456"},
            headers=admin_headers,
        )
        assert response.status_code == 200

    def test_deactivate_user(self, client, admin_headers, collab_user):
        response = client.delete(
            f"/api/v1/admin/users/{collab_user.id}",
            headers=admin_headers,
        )
        assert response.status_code == 204


# ============================================================
# TESTES: Devices CRUD
# ============================================================
class TestDevicesCRUD:
    def test_create_device(self, client, admin_headers):
        response = client.post(
            "/api/v1/admin/devices",
            json={
                "device_code": "DEV001",
                "display_name": "Device 001",
                "type": "TOTEM",
            },
            headers=admin_headers,
        )
        assert response.status_code == 201
        data = response.json()
        assert data["device_code"] == "DEV001"

    def test_create_device_duplicate_code(self, client, admin_headers):
        client.post(
            "/api/v1/admin/devices",
            json={"device_code": "DUPDEV", "display_name": "First", "type": "WEB"},
            headers=admin_headers,
        )
        response = client.post(
            "/api/v1/admin/devices",
            json={"device_code": "DUPDEV", "display_name": "Second", "type": "WEB"},
            headers=admin_headers,
        )
        assert response.status_code == 409


# ============================================================
# TESTES: Consents
# ============================================================
class TestConsents:
    def test_create_consent(self, client, admin_headers, collab_user):
        response = client.post(
            "/api/v1/consents",
            json={
                "user_id": collab_user.id,
                "term_version": "1.0.0",
                "consent_hash": "abc123def456",
                "accepted_at": "2026-01-01T00:00:00Z",
            },
            headers=admin_headers,
        )
        assert response.status_code == 201

    def test_revoke_consent(self, client, admin_headers, collab_user):
        client.post(
            "/api/v1/consents",
            json={
                "user_id": collab_user.id,
                "term_version": "1.0.0",
                "consent_hash": "revoke123",
                "accepted_at": "2026-01-01T00:00:00Z",
            },
            headers=admin_headers,
        )
        response = client.post(
            f"/api/v1/consents/users/{collab_user.id}/revoke",
            headers=admin_headers,
        )
        assert response.status_code == 200
        assert response.json()["revoked_at"] is not None


# ============================================================
# TESTES: Biometric
# ============================================================
class TestBiometric:
    def test_enroll_rejects_capture_with_low_liveness(
        self,
        client,
        admin_headers,
        collab_user,
        monkeypatch,
    ):
        client.post(
            "/api/v1/consents",
            json={
                "user_id": collab_user.id,
                "term_version": "1.0.0",
                "consent_hash": "bio-consent-123",
                "accepted_at": "2026-01-01T00:00:00Z",
            },
            headers=admin_headers,
        )

        monkeypatch.setattr(
            "app.routers.biometric.assess_capture_quality",
            lambda _: (0.95, None),
        )
        monkeypatch.setattr(
            "app.routers.biometric.build_embedding",
            lambda _: [0.1] * 512,
        )
        monkeypatch.setattr(
            "app.routers.biometric.estimate_liveness",
            lambda _, quality_score=None: 0.10,
        )

        response = client.post(
            "/api/v1/biometric/enroll",
            json={
                "user_id": collab_user.id,
                "captures": [
                    {"image_base64": "aGVsbG8="},
                    {"image_base64": "d29ybGQ="},
                    {"image_base64": "dGVzdA=="},
                ],
            },
            headers=admin_headers,
        )

        assert response.status_code == 400
        assert "liveness_failed" in response.json()["detail"]


# ============================================================
# TESTES: Clock Records
# ============================================================
class TestClockRecords:
    def test_register_clock(self, client, collab_headers, collab_user):
        response = client.post(
            "/api/v1/clock/register",
            json={
                "idempotency_key": "test-001",
                "user_id": collab_user.id,
                "device_id": "00000000-0000-0000-0000-000000000000",
                "event_type": "ENTRY",
                "recorded_at": "2026-04-13T08:00:00Z",
                "source": "ONLINE",
            },
            headers=collab_headers,
        )
        assert response.status_code == 201
        data = response.json()
        assert data["event_type"] == "ENTRY"

    def test_register_duplicate_idempotent(self, client, collab_headers, collab_user):
        client.post(
            "/api/v1/clock/register",
            json={
                "idempotency_key": "dup-key-001",
                "user_id": collab_user.id,
                "device_id": "00000000-0000-0000-0000-000000000000",
                "event_type": "ENTRY",
                "recorded_at": "2026-04-13T08:00:00Z",
                "source": "ONLINE",
            },
            headers=collab_headers,
        )
        response = client.post(
            "/api/v1/clock/register",
            json={
                "idempotency_key": "dup-key-001",
                "user_id": collab_user.id,
                "device_id": "00000000-0000-0000-0000-000000000000",
                "event_type": "ENTRY",
                "recorded_at": "2026-04-13T08:00:00Z",
                "source": "ONLINE",
            },
            headers=collab_headers,
        )
        assert response.status_code == 409

    def test_get_my_clock_records(self, client, collab_headers, collab_user):
        response = client.get(
            "/api/v1/clock/me",
            params={"user_id": collab_user.id},
            headers=collab_headers,
        )
        assert response.status_code == 200
        assert "items" in response.json()


# ============================================================
# TESTES: Adjustment Requests
# ============================================================
class TestAdjustments:
    def test_request_adjustment(self, client, collab_headers, collab_user):
        response = client.post(
            "/api/v1/clock/adjustments",
            params={"user_id": collab_user.id},
            json={
                "requested_recorded_at": "2026-04-13T08:00:00Z",
                "reason": "Esqueci de bater ponto",
            },
            headers=collab_headers,
        )
        assert response.status_code == 201
        data = response.json()
        assert data["status"] == "PENDING"

    def test_cancel_adjustment(self, client, collab_headers, collab_user):
        create_resp = client.post(
            "/api/v1/clock/adjustments",
            params={"user_id": collab_user.id},
            json={
                "requested_recorded_at": "2026-04-14T08:00:00Z",
                "reason": "Cancel test",
            },
            headers=collab_headers,
        )
        adj_id = create_resp.json()["id"]

        response = client.delete(
            f"/api/v1/clock/adjustments/{adj_id}",
            params={"user_id": collab_user.id},
            headers=collab_headers,
        )
        assert response.status_code == 204


# ============================================================
# TESTES: Audit Logs
# ============================================================
class TestAuditLogs:
    def test_list_audit_logs(self, client, admin_headers):
        response = client.get("/api/v1/audit/logs", headers=admin_headers)
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert "total" in data


# ============================================================
# TESTES: Metrics
# ============================================================
class TestMetrics:
    def test_metrics_endpoint(self, client):
        response = client.get("/metrics")
        assert response.status_code == 200
        assert response.headers["content-type"] == "text/plain; charset=utf-8"
        assert "http_requests_total" in response.text
