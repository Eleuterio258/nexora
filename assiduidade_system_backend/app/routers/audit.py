from typing import Any

from fastapi import APIRouter, Header, Query

from app.erp_client import erp_client
from app.erp_proxy import call_erp, require_authorization

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
    authorization: str | None = Header(default=None, alias="Authorization"),
) -> dict[str, Any]:
    """Logs de auditoria, delegado no Nexora ERP (`GET /api/audit-logs`).

    O ERP é quem decide quem pode ver auditoria (`auditoria:ver_logs`, via
    `RequirePermission`) — não há verificação de papel adicional aqui.
    """
    token = require_authorization(authorization)
    return await call_erp(
        lambda: erp_client.list_audit_logs(
            token,
            modulo=modulo,
            user_id=user_id,
            entidade=entidade,
            entidade_id=entidade_id,
            acao=acao,
            page=page,
            limit=limit,
        )
    )
