from dataclasses import dataclass
from typing import Any

from fastapi import Header, HTTPException, status


@dataclass
class ActorContext:
    """Identidade do chamador, informada por JWT (app) ou pelo ERP/gateway
    via headers X-User-Id/X-User-Role.
    """

    id: str | None
    role: str
    tenant_id: str | None = None


def _get_actor_from_jwt(authorization: str | None) -> ActorContext | None:
    """Tenta extrair o actor de um Bearer token JWT."""
    if not authorization or not authorization.lower().startswith("bearer "):
        return None

    import jwt as pyjwt

    from app.config import settings

    token = authorization[7:]
    try:
        payload = pyjwt.decode(token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm])
    except pyjwt.PyJWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de autenticacao invalido.",
        )

    if payload.get("type") != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Tipo de token invalido.",
        )

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token sem identificacao de utilizador.",
        )

    role = payload.get("role") or "COLABORADOR"
    tenant_id = payload.get("tenant_id")
    return ActorContext(id=user_id, role=role, tenant_id=tenant_id)


def get_actor(
    authorization: str | None = Header(default=None, alias="Authorization"),
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    x_user_role: str | None = Header(default=None, alias="X-User-Role"),
    x_tenant_id: str | None = Header(default=None, alias="X-Tenant-Id"),
) -> ActorContext:
    jwt_actor = _get_actor_from_jwt(authorization)
    if jwt_actor:
        return jwt_actor
    return ActorContext(id=x_user_id, role=x_user_role or "SYSTEM", tenant_id=x_tenant_id)


def apply_tenant(stmt, actor: ActorContext, model) -> Any:
    """Aplica filtro por tenant a uma query SQLAlchemy quando o actor tiver tenant_id."""
    if actor.tenant_id:
        return stmt.where(model.tenant_id == actor.tenant_id)
    return stmt
