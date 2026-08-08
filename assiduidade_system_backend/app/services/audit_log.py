"""
Registo local de eventos de auditoria biometrica (BiometricAuditLog).

Complementa app/routers/audit.py, que so delega a auditoria para o ERP —
este log fica disponivel mesmo que o ERP esteja indisponivel, e cobre
apenas eventos biometricos (enroll/verify/identify/liveness), nao acoes
administrativas.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from app.models import BiometricAuditLog

if TYPE_CHECKING:
    from sqlalchemy.orm import Session


def record_audit_event(
    db: "Session",
    tenant_id: str | None,
    event_type: str,
    erp_user_id: str | None = None,
    device_id: str | None = None,
    reason: str | None = None,
    confidence_score: float | None = None,
    liveness_score: float | None = None,
) -> BiometricAuditLog:
    """Cria (mas nao comita) uma entrada de audit log. O chamador comita,
    tipicamente na mesma transaccao da operacao biometrica."""
    entry = BiometricAuditLog(
        tenant_id=tenant_id,
        event_type=event_type,
        erp_user_id=erp_user_id,
        device_id=device_id,
        reason=reason,
        confidence_score=confidence_score,
        liveness_score=liveness_score,
    )
    db.add(entry)
    return entry
