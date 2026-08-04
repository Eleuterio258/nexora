"""Gestão de credenciais Nexora (ApiCredential).

Inclui criação, rotação, revogação e recuperação segura de credenciais
serviço-a-serviço. A chave secreta é cifrada em repouso com Fernet e uma
chave mestra externa à base de dados (NEXORA_CREDENTIAL_ENCRYPTION_KEY).
"""

import base64
import hashlib
import secrets
from datetime import datetime, timedelta, timezone
from typing import Any

from cryptography.fernet import Fernet
from sqlalchemy.orm import Session

from app.config import settings
from app.models import ApiCredential


def _get_fernet() -> Fernet:
    """Devolve uma instância Fernet configurada com a chave mestra.

    A chave pode ser uma string arbitrária (é derivada via SHA-256) ou uma
    chave Fernet válida (32 bytes raw ou 44 caracteres base64-urlsafe).
    """
    key_material = settings.nexora_credential_encryption_key.encode("utf-8")

    # Se já for uma chave Fernet válida (44 chars), usa diretamente.
    try:
        decoded = base64.urlsafe_b64decode(key_material + b"=" * (-len(key_material) % 4))
        if len(decoded) == 32:
            return Fernet(key_material)
    except Exception:
        pass

    # Caso contrário, deriva uma chave de 32 bytes e codifica em base64-urlsafe.
    derived = hashlib.sha256(key_material).digest()
    fernet_key = base64.urlsafe_b64encode(derived)
    return Fernet(fernet_key)


def _generate_access_key_id() -> str:
    """Gera um access key id público, único e facilmente reconhecível."""
    random_part = base64.urlsafe_b64encode(secrets.token_bytes(24)).decode("ascii").rstrip("=")
    return f"nexora_ak_{random_part}"


def _generate_secret_access_key() -> str:
    """Gera uma chave secreta criptograficamente segura."""
    random_part = base64.urlsafe_b64encode(secrets.token_bytes(32)).decode("ascii").rstrip("=")
    return f"nexora_sk_{random_part}"


def _encrypt_secret(secret: str) -> str:
    """Cifra a chave secreta com Fernet."""
    return _get_fernet().encrypt(secret.encode("utf-8")).decode("ascii")


def _decrypt_secret(encrypted: str) -> str:
    """Decifra a chave secreta com Fernet."""
    return _get_fernet().decrypt(encrypted.encode("ascii")).decode("utf-8")


def create_credential(
    db: Session,
    tenant_id: str,
    name: str | None = None,
    permissions: list[str] | None = None,
    expires_at: datetime | None = None,
) -> tuple[ApiCredential, str]:
    """Cria uma nova credencial Nexora.

    Devolve um tuplo (ApiCredential, secret_access_key). A chave secreta é
    apresentada apenas uma vez neste momento; depois fica cifrada na BD.
    """
    access_key_id = _generate_access_key_id()
    secret_access_key = _generate_secret_access_key()

    credential = ApiCredential(
        access_key_id=access_key_id,
        encrypted_secret_access_key=_encrypt_secret(secret_access_key),
        name=name,
        tenant_id=tenant_id,
        permissions=list(permissions) if permissions else [],
        status="active",
        expires_at=expires_at,
    )
    db.add(credential)
    db.commit()
    db.refresh(credential)
    return credential, secret_access_key


def get_active_credential(db: Session, access_key_id: str) -> tuple[ApiCredential, str] | None:
    """Busca uma credencial ativa e devolve (credential, secret_decifrada).

    Rejeita credenciais revogadas ou expiradas.
    """
    credential = (
        db.query(ApiCredential)
        .filter(
            ApiCredential.access_key_id == access_key_id,
            ApiCredential.status == "active",
        )
        .first()
    )
    if not credential:
        return None

    now = datetime.now(timezone.utc)
    if credential.revoked_at is not None:
        return None
    if credential.expires_at is not None:
        expires_at = credential.expires_at
        if expires_at.tzinfo is None:
            expires_at = expires_at.replace(tzinfo=timezone.utc)
        if expires_at <= now:
            return None

    try:
        secret = _decrypt_secret(credential.encrypted_secret_access_key)
    except Exception:
        return None

    return credential, secret


def revoke_credential(db: Session, credential_id: str) -> bool:
    """Revoga imediatamente uma credencial."""
    credential = db.query(ApiCredential).filter(ApiCredential.id == credential_id).first()
    if not credential:
        return False

    credential.status = "revoked"
    credential.revoked_at = datetime.now(timezone.utc)
    db.commit()
    return True


def rotate_credential(
    db: Session,
    credential_id: str,
    overlap_seconds: int = 300,
    name: str | None = None,
    permissions: list[str] | None = None,
    expires_at: datetime | None = None,
) -> tuple[ApiCredential, str] | None:
    """Rota uma credencial existente.

    A credencial antiga permanece válida durante overlap_seconds. A nova
    credencial é criada para o mesmo tenant.
    """
    old = db.query(ApiCredential).filter(ApiCredential.id == credential_id).first()
    if not old:
        return None

    now = datetime.now(timezone.utc)
    old_overlap = now + timedelta(seconds=overlap_seconds)
    if old.expires_at is None or old.expires_at > old_overlap:
        old.expires_at = old_overlap
        db.commit()
        db.refresh(old)

    new_cred, secret = create_credential(
        db=db,
        tenant_id=old.tenant_id,
        name=name or old.name,
        permissions=permissions or old.permissions,
        expires_at=expires_at,
    )
    return new_cred, secret


def touch_last_used(db: Session, credential: ApiCredential) -> None:
    """Atualiza o último uso da credencial."""
    credential.last_used_at = datetime.now(timezone.utc)
    db.commit()
