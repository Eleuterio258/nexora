from datetime import date, datetime, time

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import ActorContext, apply_tenant, get_actor
from app.models import AuditLogModel
from app.schemas.responses import AuditLog, PaginatedAuditLogs


router = APIRouter(tags=["Audit"])


@router.get("/audit/logs", response_model=PaginatedAuditLogs)
def list_audit_logs(
    entity_type: str | None = Query(None),
    entity_id: str | None = Query(None),
    action: str | None = Query(None),
    start_date: date | None = Query(None),
    end_date: date | None = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> PaginatedAuditLogs:
    query = apply_tenant(select(AuditLogModel), actor, AuditLogModel)
    count_query = apply_tenant(
        select(func.count()).select_from(AuditLogModel), actor, AuditLogModel
    )

    if entity_type:
        query = query.where(AuditLogModel.entity_type == entity_type)
        count_query = count_query.where(AuditLogModel.entity_type == entity_type)
    if entity_id:
        query = query.where(AuditLogModel.entity_id == entity_id)
        count_query = count_query.where(AuditLogModel.entity_id == entity_id)
    if action:
        query = query.where(AuditLogModel.action == action)
        count_query = count_query.where(AuditLogModel.action == action)
    if start_date:
        start_dt = datetime.combine(start_date, time.min)
        query = query.where(AuditLogModel.created_at >= start_dt)
        count_query = count_query.where(AuditLogModel.created_at >= start_dt)
    if end_date:
        end_dt = datetime.combine(end_date, time.max)
        query = query.where(AuditLogModel.created_at <= end_dt)
        count_query = count_query.where(AuditLogModel.created_at <= end_dt)

    total = db.scalar(count_query) or 0
    rows = db.scalars(
        query.order_by(AuditLogModel.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    ).all()
    items = [
        AuditLog(
            id=row.id,
            actor_type=row.actor_type,
            actor_id=row.actor_id,
            action=row.action,
            entity_type=row.entity_type,
            entity_id=row.entity_id,
            payload_hash=row.payload_hash,
            previous_hash=row.previous_hash,
            created_at=row.created_at,
        )
        for row in rows
    ]
    return PaginatedAuditLogs(
        items=items,
        page=page,
        page_size=page_size,
        total=total,
    )
