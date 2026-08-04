from dataclasses import dataclass
from typing import Any

from fastapi import HTTPException, status


@dataclass
class ActorContext:
    """Identidade do chamador."""

    id: str | None
    role: str
    tenant_id: str | None = None


def apply_tenant(stmt, actor: ActorContext, model) -> Any:
    """Aplica filtro por tenant a uma query SQLAlchemy.

    ADMIN_SISTEMA pode legitimamente nao ter tenant_id (acesso cross-tenant).
    Qualquer outro role sem tenant_id e uma anomalia — falha fechado (403).
    """
    if actor.role == "ADMIN_SISTEMA":
        return stmt
    if not actor.tenant_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Actor sem tenant identificado.",
        )
    return stmt.where(model.tenant_id == actor.tenant_id)


def require_self_or_manager(actor: ActorContext, target_user_id: str) -> None:
    """Impede que um COLABORADOR actue em nome de outro utilizador.

    Qualquer role de gestor pode operar em nome de outrem do seu tenant;
    um colaborador comum só pode operar sobre a própria identidade.
    Chamadas serviço-a-serviço autenticadas por Nexora HMAC usam role SYSTEM
    e podem operar em nome de qualquer utilizador do tenant.
    """
    if actor.id == target_user_id:
        return
    if actor.role in ("ADMIN_SISTEMA", "GESTOR_RH", "SYSTEM"):
        return
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="Nao pode realizar esta operacao em nome de outro utilizador.",
    )
