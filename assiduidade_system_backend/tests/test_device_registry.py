from app.deps import ActorContext
from app.services.device_registry import (
    get_device_public_key,
    register_device_public_key,
    revoke_device_public_key,
)


def test_register_and_get_device_key(db_session):
    actor = ActorContext(id="admin", role="ADMIN_SISTEMA", tenant_id="tenant-1")
    record = register_device_public_key(
        db=db_session,
        actor=actor,
        device_id="device-1",
        public_key_b64="cHVibGljLWtleQ==",
    )
    db_session.commit()

    assert record.device_id == "device-1"
    assert record.public_key_b64 == "cHVibGljLWtleQ=="

    public_key = get_device_public_key(db_session, actor, "device-1")
    assert public_key == "cHVibGljLWtleQ=="


def test_update_existing_device_key(db_session):
    actor = ActorContext(id="admin", role="ADMIN_SISTEMA", tenant_id="tenant-1")
    register_device_public_key(db_session, actor, "device-1", "key-v1")
    record = register_device_public_key(db_session, actor, "device-1", "key-v2")
    db_session.commit()

    assert record.public_key_b64 == "key-v2"
    assert get_device_public_key(db_session, actor, "device-1") == "key-v2"


def test_revoke_device_key(db_session):
    actor = ActorContext(id="admin", role="ADMIN_SISTEMA", tenant_id="tenant-1")
    register_device_public_key(db_session, actor, "device-1", "key-v1")
    db_session.commit()

    assert revoke_device_public_key(db_session, actor, "device-1") is True
    db_session.commit()
    assert get_device_public_key(db_session, actor, "device-1") is None


def test_revoke_unknown_device_key(db_session):
    actor = ActorContext(id="admin", role="ADMIN_SISTEMA", tenant_id="tenant-1")
    assert revoke_device_public_key(db_session, actor, "device-unknown") is False
