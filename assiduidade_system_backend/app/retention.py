"""
Politica de retencao e limpeza automatica de dados.
Remove dados antigos conforme configuracoes de retencao.
"""
import logging
from datetime import datetime, timedelta, timezone

from sqlalchemy import select, delete
from sqlalchemy.orm import Session

from app.models import AuditLogModel, ClockRecordModel, IntegrationBatchModel


logger = logging.getLogger("faceclock.retention")


DEFAULT_RETENTION = {
    "audit_logs_days": 3650,  # 10 anos para auditoria
    "clock_records_days": 1825,  # 5 anos para registros de ponto
    "integration_batches_days": 90,  # 3 meses para batches
    "temp_images_hours": 24,  # imagens temporarias nao persistidas
}


def get_retention_days(config_key: str) -> int:
    import os
    env_key = f"RETENTION_{config_key.upper()}"
    return int(os.getenv(env_key, str(DEFAULT_RETENTION[config_key])))


def cleanup_old_records(db: Session, tenant_id: str | None = None) -> dict[str, int]:
    """
    Remove registros mais antigos que o periodo de retencao configurado.
    Se tenant_id for informado, limita a limpeza ao tenant.
    Retorna contagem de registros removidos por tabela.
    """
    results = {}

    # Clock records
    clock_retention_days = get_retention_days("clock_records_days")
    cutoff_clock = datetime.now(timezone.utc) - timedelta(days=clock_retention_days)
    clock_query = select(ClockRecordModel).where(ClockRecordModel.created_at < cutoff_clock)
    if tenant_id:
        clock_query = clock_query.where(ClockRecordModel.tenant_id == tenant_id)
    clock_ids = [row.id for row in db.scalars(clock_query).all()]
    if clock_ids:
        deleted = db.execute(
            delete(ClockRecordModel).where(ClockRecordModel.id.in_(clock_ids))
        )
        results["clock_records"] = deleted.rowcount
    else:
        results["clock_records"] = 0

    # Audit logs (mantem apenas os dentro do periodo)
    audit_retention_days = get_retention_days("audit_logs_days")
    cutoff_audit = datetime.now(timezone.utc) - timedelta(days=audit_retention_days)
    audit_query = select(AuditLogModel).where(AuditLogModel.created_at < cutoff_audit)
    if tenant_id:
        audit_query = audit_query.where(AuditLogModel.tenant_id == tenant_id)
    audit_ids = [row.id for row in db.scalars(audit_query).all()]
    if audit_ids:
        deleted = db.execute(
            delete(AuditLogModel).where(AuditLogModel.id.in_(audit_ids))
        )
        results["audit_logs"] = deleted.rowcount
    else:
        results["audit_logs"] = 0

    # Integration batches
    batch_retention_days = get_retention_days("integration_batches_days")
    cutoff_batch = datetime.now(timezone.utc) - timedelta(days=batch_retention_days)
    batch_query = select(IntegrationBatchModel).where(IntegrationBatchModel.created_at < cutoff_batch)
    if tenant_id:
        batch_query = batch_query.where(IntegrationBatchModel.tenant_id == tenant_id)
    batch_ids = [row.id for row in db.scalars(batch_query).all()]
    if batch_ids:
        deleted = db.execute(
            delete(IntegrationBatchModel).where(IntegrationBatchModel.id.in_(batch_ids))
        )
        results["integration_batches"] = deleted.rowcount
    else:
        results["integration_batches"] = 0

    db.commit()

    if any(v > 0 for v in results.values()):
        logger.info("Retention cleanup completed: %s", results)

    return results
