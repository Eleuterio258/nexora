from fastapi import APIRouter, Depends, HTTPException

from app.deps import get_actor, require_role


router = APIRouter(tags=["Audit"])


@router.get(
    "/audit/logs",
    dependencies=[Depends(require_role("ADMIN_SISTEMA", "GESTOR_RH", "AUDITOR"))],
)
def list_audit_logs() -> None:
    """PROXY ERP: auditoria foi movida para o Nexora ERP.

    Implementar proxy para GET /api/audit-logs/ do ERP (Fase 6).
    """
    raise HTTPException(
        status_code=501,
        detail="Auditoria é consultada no Nexora ERP. Endpoint em construcao.",
    )
