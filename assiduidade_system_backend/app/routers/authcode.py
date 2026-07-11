"""
Router para códigos de autenticação auxiliares: PIN e TOTP.

O TOTP é gerado a partir de um segredo partilhado com o utilizador. O PIN
é um código numérico de 6 digitos armazenado como hash bcrypt.

Em producao, o segredo TOTP deve ser apresentado ao utilizador como QR Code
ou enviado por canal seguro. Aqui mantem-se o essencial para validacao.
"""

from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

import pyotp

from app.database import get_db
from app.deps import ActorContext, apply_tenant, get_actor
from app.models import User
from app.security import get_password_hash, verify_password

router = APIRouter(tags=["Auth Code"])


class PinValidateRequest(BaseModel):
    user_id: str
    pin: str = Field(..., min_length=4, max_length=20)


class TotpValidateRequest(BaseModel):
    user_id: str
    code: str = Field(..., min_length=6, max_length=6)


class AuthCodeResponse(BaseModel):
    valid: bool
    method: str
    message: str


class TotpSetupResponse(BaseModel):
    secret: str
    provisioning_uri: str
    message: str


def _get_user(db: Session, user_id: str, actor: ActorContext) -> User:
    user = db.scalar(
        apply_tenant(select(User).where(User.id == user_id), actor, User)
    )
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Utilizador nao encontrado.")
    return user


@router.post("/authcode/pin/validate", response_model=AuthCodeResponse)
def validate_pin(
    request: PinValidateRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> AuthCodeResponse:
    """Valida um PIN numerico associado ao utilizador."""
    user = _get_user(db, request.user_id, actor)

    if not user.pin_hash:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="PIN nao configurado para este utilizador.",
        )

    if not verify_password(request.pin, user.pin_hash):
        return AuthCodeResponse(valid=False, method="PIN", message="PIN invalido.")

    return AuthCodeResponse(valid=True, method="PIN", message="PIN valido.")


@router.post("/authcode/totp/setup", response_model=TotpSetupResponse)
def setup_totp(
    user_id: str,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> TotpSetupResponse:
    """Gera um novo segredo TOTP para o utilizador."""
    user = _get_user(db, user_id, actor)

    secret = pyotp.random_base32()
    user.totp_secret = secret
    db.commit()

    issuer = "FaceClock"
    provisioning_uri = pyotp.totp.TOTP(secret).provisioning_uri(
        name=user.email or user.employee_code,
        issuer_name=issuer,
    )

    return TotpSetupResponse(
        secret=secret,
        provisioning_uri=provisioning_uri,
        message="Segredo TOTP gerado. Escaneie o QR Code ou guarde o segredo de forma segura.",
    )


@router.post("/authcode/totp/validate", response_model=AuthCodeResponse)
def validate_totp(
    request: TotpValidateRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> AuthCodeResponse:
    """Valida um codigo TOTP de 6 digitos."""
    user = _get_user(db, request.user_id, actor)

    if not user.totp_secret:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="TOTP nao configurado para este utilizador.",
        )

    totp = pyotp.TOTP(user.totp_secret)
    if totp.verify(request.code, valid_window=1):
        return AuthCodeResponse(valid=True, method="TOTP", message="Codigo TOTP valido.")

    return AuthCodeResponse(valid=False, method="TOTP", message="Codigo TOTP invalido.")


@router.post("/authcode/admin/set-pin")
def admin_set_pin(
    user_id: str,
    pin: str = Query(..., min_length=4, max_length=20),
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> dict[str, Any]:
    """Endpoint administrativo para configurar o PIN de um utilizador."""
    if actor.role not in ("ADMIN_SISTEMA", "GESTOR_RH"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sem permissao.")

    user = _get_user(db, user_id, actor)
    user.pin_hash = get_password_hash(pin)
    db.commit()

    return {"success": True, "message": "PIN configurado com sucesso."}
