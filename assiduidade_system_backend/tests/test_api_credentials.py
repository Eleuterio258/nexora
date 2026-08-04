"""Testes do serviço de gestão de credenciais Nexora."""

from datetime import datetime, timedelta, timezone

import pytest

from app.services.api_credentials import (
    create_credential,
    get_active_credential,
    revoke_credential,
    rotate_credential,
)


def test_create_credential_stores_encrypted_secret(db_session):
    cred, secret = create_credential(
        db=db_session,
        tenant_id="tenant-1",
        name="Terminal 1",
        permissions=["biometric:verify"],
    )

    assert cred.access_key_id.startswith("nexora_ak_")
    assert cred.encrypted_secret_access_key != secret
    assert cred.tenant_id == "tenant-1"
    assert cred.status == "active"
    assert "biometric:verify" in cred.permissions


def test_get_active_credential_returns_decrypted_secret(db_session):
    cred, secret = create_credential(
        db=db_session,
        tenant_id="tenant-1",
        permissions=["biometric:verify"],
    )

    result = get_active_credential(db_session, cred.access_key_id)
    assert result is not None
    found_cred, found_secret = result
    assert found_cred.id == cred.id
    assert found_secret == secret


def test_get_active_credential_rejects_unknown_key(db_session):
    result = get_active_credential(db_session, "nexora_ak_inexistente")
    assert result is None


def test_get_active_credential_rejects_revoked(db_session):
    cred, _ = create_credential(db=db_session, tenant_id="tenant-1", permissions=[])
    revoke_credential(db_session, cred.id)

    result = get_active_credential(db_session, cred.access_key_id)
    assert result is None


def test_get_active_credential_rejects_expired(db_session):
    cred, _ = create_credential(
        db=db_session,
        tenant_id="tenant-1",
        permissions=[],
        expires_at=datetime.now(timezone.utc) - timedelta(days=1),
    )

    result = get_active_credential(db_session, cred.access_key_id)
    assert result is None


def test_revoke_credential(db_session):
    cred, _ = create_credential(db=db_session, tenant_id="tenant-1", permissions=[])
    assert revoke_credential(db_session, cred.id) is True
    assert revoke_credential(db_session, "invalid-id") is False


def test_rotate_credential_creates_new_and_sets_overlap(db_session):
    old_cred, old_secret = create_credential(
        db=db_session,
        tenant_id="tenant-1",
        permissions=["biometric:verify"],
    )

    new_cred, new_secret = rotate_credential(db_session, old_cred.id, overlap_seconds=300)
    assert new_cred is not None
    assert new_cred.id != old_cred.id
    assert new_cred.tenant_id == old_cred.tenant_id

    # A credencial antiga ainda deve estar ativa durante o overlap
    result = get_active_credential(db_session, old_cred.access_key_id)
    assert result is not None

    # A nova também deve estar ativa
    result = get_active_credential(db_session, new_cred.access_key_id)
    assert result is not None
