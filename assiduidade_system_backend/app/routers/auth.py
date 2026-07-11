"""
Router de autenticacao para a app Android.

Fornece endpoints de login e refresh com tokens JWT. Quando configurado,
valida as credenciais no ERP Omnisys; caso contrario, ou em modo fallback,
valida contra a base de dados local do FaceClock.
"""

from datetime import datetime, timedelta, timezone
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.erp_client import ERPAuthError, ERPUnavailableError, erp_client
from app.models import Tenant, User
from app.schemas.common import UserRole, UserStatus
from app.security import verify_password

router = APIRouter(tags=["Auth"])


class LoginRequest(BaseModel):
    username: str
    password: str


class AuthenticatedUser(BaseModel):
    id: str
    employee_code: str
    full_name: str
    role: str
    status: str
    tenant_id: str | None = None


class LoginResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str
    expires_in: int
    user: AuthenticatedUser


class RefreshRequest(BaseModel):
    refresh_token: str


def _create_token(
    subject: str,
    token_type: str,
    role: str | None = None,
    tenant_id: str | None = None,
    expires_delta: timedelta | None = None,
) -> tuple[str, int]:
    """Cria um token JWT com o subject, tipo, role e tenant indicados."""
    import jwt as pyjwt

    if expires_delta is None:
        expires_delta = timedelta(minutes=settings.access_token_expire_minutes)

    now = datetime.now(timezone.utc)
    expire = now + expires_delta
    to_encode: dict[str, Any] = {
        "sub": subject,
        "type": token_type,
        "iat": now,
        "exp": expire,
    }
    if role:
        to_encode["role"] = role
    if tenant_id:
        to_encode["tenant_id"] = tenant_id
    encoded = pyjwt.encode(to_encode, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)
    return encoded, int(expire.timestamp() - now.timestamp())


def create_access_token(user_id: str, role: str | None = None, tenant_id: str | None = None) -> tuple[str, int]:
    return _create_token(user_id, "access", role, tenant_id, timedelta(minutes=settings.access_token_expire_minutes))


def create_refresh_token(user_id: str, role: str | None = None, tenant_id: str | None = None) -> tuple[str, int]:
    return _create_token(user_id, "refresh", role, tenant_id, timedelta(days=7))


async def _authenticate_with_erp(username: str, password: str) -> dict[str, Any] | None:
    """Tenta autenticar no ERP. Retorna None se o ERP nao estiver configurado."""
    if not settings.erp_base_url:
        return None
    try:
        return await erp_client.authenticate_user(username, password)
    except ERPUnavailableError:
        if not settings.erp_fallback_local_login:
            raise
        return None
    except ERPAuthError:
        # Credenciais invalidas no ERP: nao tentar fallback local por seguranca.
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Credenciais invalidas.")


def _authenticate_local(db: Session, username: str, password: str) -> User | None:
    """Autentica localmente por employee_code ou email."""
    user = db.scalar(
        select(User).where(
            (User.employee_code == username) | (User.email == username)
        )
    )
    if not user or not verify_password(password, user.password_hash):
        return None
    return user


@router.post("/auth/login", response_model=LoginResponse)
async def login(request: LoginRequest, db: Session = Depends(get_db)) -> LoginResponse:
    """Autentica um utilizador por employee_code ou email e devolve tokens JWT."""
    user: User | None = None
    erp_user_id: str | None = None

    # 1. Tentar autenticar no ERP se configurado.
    erp_result = await _authenticate_with_erp(request.username, request.password)
    erp_tenant_id: str | None = None
    if erp_result:
        erp_user_id = str(erp_result.get("user_id") or erp_result.get("id"))
        erp_tenant_id = str(erp_result.get("tenant_id") or "") or None
        # Procurar utilizador local vinculado ao ERP.
        user = db.scalar(
            select(User).where(
                (User.erp_user_id == erp_user_id)
                | (User.employee_code == request.username)
                | (User.email == request.username)
            )
        )

    # 2. Fallback local se ERP nao respondeu ou nao esta configurado.
    if user is None and settings.erp_fallback_local_login:
        user = _authenticate_local(db, request.username, request.password)

    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Credenciais invalidas.")

    if user.status != UserStatus.ACTIVE:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Utilizador inativo.")

    # 3. Garantir tenant vinculado (cria se necessario a partir do ERP).
    if erp_tenant_id and user.tenant_id is None:
        tenant = db.scalar(select(Tenant).where(Tenant.external_id == erp_tenant_id))
        if not tenant:
            tenant_name = str(erp_result.get("tenant_name") or erp_result.get("company_name") or "Tenant")
            tenant = Tenant(
                external_id=erp_tenant_id,
                name=tenant_name,
                code=erp_tenant_id.lower()[:50],
            )
            db.add(tenant)
            db.flush()
        user.tenant_id = tenant.id
        db.commit()

    # Atualiza o vinculo com o ERP se necessario.
    if erp_user_id and user.erp_user_id is None:
        user.erp_user_id = erp_user_id
        db.commit()

    access_token, expires_in = create_access_token(str(user.id), user.role.value, user.tenant_id)
    refresh_token, _ = create_refresh_token(str(user.id), user.role.value, user.tenant_id)

    return LoginResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        expires_in=expires_in,
        user=AuthenticatedUser(
            id=str(user.id),
            employee_code=user.employee_code,
            full_name=user.full_name,
            role=user.role.value,
            status=user.status.value,
            tenant_id=user.tenant_id,
        ),
    )


@router.post("/auth/refresh", response_model=LoginResponse)
def refresh(request: RefreshRequest, db: Session = Depends(get_db)) -> LoginResponse:
    """Gera um novo access_token a partir de um refresh_token valido."""
    import jwt as pyjwt

    try:
        payload = pyjwt.decode(
            request.refresh_token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm]
        )
    except pyjwt.ExpiredSignatureError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token expirado.")
    except pyjwt.PyJWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token invalido.")

    if payload.get("type") != "refresh":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token invalido.")

    user_id = payload.get("sub")
    user = db.scalar(select(User).where(User.id == user_id))
    if not user or user.status != UserStatus.ACTIVE:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Utilizador invalido.")

    access_token, expires_in = create_access_token(str(user.id), user.role.value, user.tenant_id)
    refresh_token, _ = create_refresh_token(str(user.id), user.role.value, user.tenant_id)

    return LoginResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        expires_in=expires_in,
        user=AuthenticatedUser(
            id=str(user.id),
            employee_code=user.employee_code,
            full_name=user.full_name,
            role=user.role.value,
            status=user.status.value,
            tenant_id=user.tenant_id,
        ),
    )
