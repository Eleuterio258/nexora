from typing import Any

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import ActorContext
from app.erp_client import erp_client
from app.erp_proxy import call_erp
from app.security import require_nexora_signature

router = APIRouter(tags=["Audit"])


@router.get("/audit/logs")
async def list_audit_logs(
    modulo: str | None = Query(default=None),
    user_id: str | None = Query(default=None),
    entidade: str | None = Query(default=None),
    entidade_id: str | None = Query(default=None),
    acao: str | None = Query(default=None),
    page: int | None = Query(default=None, ge=1),
    limit: int | None = Query(default=None, ge=1, le=100),
    db: Session = Depends(get_db),
    actor: ActorContext = require_nexora_signature("audit:read"),
) -> dict[str, Any]:
    """Logs de auditoria, delegado no Nexora ERP (`GET /api/audit-logs`).

    Autenticado por Nexora HMAC. O ERP é quem decide quem pode ver auditoria.
    """
    return await call_erp(
        lambda: erp_client.list_audit_logs(
            modulo=modulo,
            user_id=user_id,
            entidade=entidade,
            entidade_id=entidade_id,
            acao=acao,
            page=page,
            limit=limit,
        )
    )
