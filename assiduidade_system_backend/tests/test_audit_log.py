from app.models import BiometricAuditLog
from app.services.audit_log import record_audit_event


def test_record_audit_event_persists_row(db_session):
    entry = record_audit_event(
        db_session,
        tenant_id="tenant-1",
        event_type="verify_match",
        erp_user_id="erp-user-1",
        device_id="device-1",
        confidence_score=0.92,
        liveness_score=0.88,
    )
    db_session.commit()

    stored = db_session.get(BiometricAuditLog, entry.id)
    assert stored is not None
    assert stored.tenant_id == "tenant-1"
    assert stored.event_type == "verify_match"
    assert stored.erp_user_id == "erp-user-1"
    assert stored.device_id == "device-1"
    assert float(stored.confidence_score) == 0.92
    assert float(stored.liveness_score) == 0.88


def test_record_audit_event_optional_fields_default_none(db_session):
    entry = record_audit_event(db_session, tenant_id=None, event_type="enroll_success")
    db_session.commit()

    stored = db_session.get(BiometricAuditLog, entry.id)
    assert stored is not None
    assert stored.tenant_id is None
    assert stored.erp_user_id is None
    assert stored.device_id is None
    assert stored.reason is None
    assert stored.confidence_score is None
    assert stored.liveness_score is None
