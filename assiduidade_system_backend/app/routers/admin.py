import asyncio
import csv
import io
from datetime import date, datetime, time, timezone
from urllib.parse import urlencode

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import PlainTextResponse
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.audit_chain import chain_audit_hash
from app.database import get_db
from app.deps import ActorContext, apply_tenant, get_actor
from app.models import AdjustmentRequestModel, AuditLogModel, ClockRecordModel, User
from app.notifications import NotificationChannel, NotificationType, send_notification
from app.retention import cleanup_old_records
from app.schemas.common import AdjustmentStatus, EventType, SourceType, SyncStatus
from app.schemas.requests import AdjustmentReviewRequest
from app.schemas.responses import (
    AdjustmentRequest,
    ClockRecord,
    ExportResponse,
    PaginatedAdjustmentRequests,
    PaginatedClockRecords,
)


router = APIRouter(tags=["Admin"])


@router.get("/admin/clock-records", response_model=PaginatedClockRecords)
def list_clock_records(
    user_id: str | None = Query(None),
    unit_id: str | None = Query(None),
    event_type: EventType | None = Query(None),
    start_date: date | None = Query(None),
    end_date: date | None = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> PaginatedClockRecords:
    query = select(ClockRecordModel)
    count_query = select(func.count()).select_from(ClockRecordModel)

    if actor.tenant_id:
        query = query.where(ClockRecordModel.tenant_id == actor.tenant_id)
        count_query = count_query.where(ClockRecordModel.tenant_id == actor.tenant_id)

    if unit_id:
        query = query.join(User, User.id == ClockRecordModel.user_id).where(User.unit_id == unit_id)
        count_query = count_query.join(User, User.id == ClockRecordModel.user_id).where(
            User.unit_id == unit_id
        )
    if user_id:
        query = query.where(ClockRecordModel.user_id == user_id)
        count_query = count_query.where(ClockRecordModel.user_id == user_id)
    if event_type:
        query = query.where(ClockRecordModel.event_type == event_type)
        count_query = count_query.where(ClockRecordModel.event_type == event_type)
    if start_date:
        start_dt = datetime.combine(start_date, time.min)
        query = query.where(ClockRecordModel.recorded_at >= start_dt)
        count_query = count_query.where(ClockRecordModel.recorded_at >= start_dt)
    if end_date:
        end_dt = datetime.combine(end_date, time.max)
        query = query.where(ClockRecordModel.recorded_at <= end_dt)
        count_query = count_query.where(ClockRecordModel.recorded_at <= end_dt)

    total = db.scalar(count_query) or 0
    rows = db.scalars(
        query.order_by(ClockRecordModel.recorded_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    ).all()
    items = [
        ClockRecord(
            id=row.id,
            user_id=row.user_id,
            device_id=row.device_id,
            event_type=row.event_type,
            recorded_at=row.recorded_at,
            source=row.source,
            sync_status=row.sync_status,
            confidence_score=float(row.confidence_score) if row.confidence_score is not None else None,
            liveness_score=float(row.liveness_score) if row.liveness_score is not None else None,
            created_at=row.created_at,
        )
        for row in rows
    ]
    return PaginatedClockRecords(
        items=items,
        page=page,
        page_size=page_size,
        total=total,
    )


@router.get("/admin/reports/export", response_model=ExportResponse)
def export_report(
    unit_id: str | None = Query(None),
    start_date: date | None = Query(None),
    end_date: date | None = Query(None),
) -> ExportResponse:
    params = {}
    if unit_id:
        params["unit_id"] = unit_id
    if start_date:
        params["start_date"] = start_date.isoformat()
    if end_date:
        params["end_date"] = end_date.isoformat()
    query = urlencode(params)
    download_url = "/api/v1/admin/reports/export.csv"
    if query:
        download_url = f"{download_url}?{query}"
    return ExportResponse(
        download_url=download_url,
        format="csv",
    )


@router.get("/admin/reports/export.csv", response_class=PlainTextResponse)
def export_report_csv(
    user_id: str | None = Query(None),
    unit_id: str | None = Query(None),
    event_type: EventType | None = Query(None),
    start_date: date | None = Query(None),
    end_date: date | None = Query(None),
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> PlainTextResponse:
    query = select(ClockRecordModel)

    if actor.tenant_id:
        query = query.where(ClockRecordModel.tenant_id == actor.tenant_id)

    if unit_id:
        query = query.join(User, User.id == ClockRecordModel.user_id).where(User.unit_id == unit_id)
    if user_id:
        query = query.where(ClockRecordModel.user_id == user_id)
    if event_type:
        query = query.where(ClockRecordModel.event_type == event_type)
    if start_date:
        query = query.where(ClockRecordModel.recorded_at >= datetime.combine(start_date, time.min))
    if end_date:
        query = query.where(ClockRecordModel.recorded_at <= datetime.combine(end_date, time.max))

    rows = db.scalars(query.order_by(ClockRecordModel.recorded_at.desc())).all()

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(
        [
            "id",
            "user_id",
            "device_id",
            "event_type",
            "recorded_at",
            "source",
            "sync_status",
            "confidence_score",
            "liveness_score",
            "created_at",
        ]
    )
    for row in rows:
        writer.writerow(
            [
                row.id,
                row.user_id,
                row.device_id or "",
                row.event_type.value if hasattr(row.event_type, "value") else row.event_type,
                row.recorded_at.isoformat() if row.recorded_at else "",
                row.source.value if hasattr(row.source, "value") else row.source,
                row.sync_status.value if hasattr(row.sync_status, "value") else row.sync_status,
                float(row.confidence_score) if row.confidence_score is not None else "",
                float(row.liveness_score) if row.liveness_score is not None else "",
                row.created_at.isoformat() if row.created_at else "",
            ]
        )

    return PlainTextResponse(
        content=output.getvalue(),
        media_type="text/csv",
        headers={"content-disposition": 'attachment; filename="clock-records.csv"'},
    )


@router.get("/admin/adjustments", response_model=PaginatedAdjustmentRequests)
def list_adjustments(
    status: AdjustmentStatus | None = Query(None),
    user_id: str | None = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> PaginatedAdjustmentRequests:
    query = apply_tenant(select(AdjustmentRequestModel), actor, AdjustmentRequestModel)
    count_query = apply_tenant(
        select(func.count()).select_from(AdjustmentRequestModel), actor, AdjustmentRequestModel
    )

    if status:
        query = query.where(AdjustmentRequestModel.status == status)
        count_query = count_query.where(AdjustmentRequestModel.status == status)
    if user_id:
        query = query.where(AdjustmentRequestModel.user_id == user_id)
        count_query = count_query.where(AdjustmentRequestModel.user_id == user_id)

    total = db.scalar(count_query) or 0
    rows = db.scalars(
        query.order_by(AdjustmentRequestModel.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    ).all()

    return PaginatedAdjustmentRequests(
        items=[
            AdjustmentRequest(
                id=row.id,
                user_id=row.user_id,
                clock_record_id=row.clock_record_id,
                requested_event_type=row.requested_event_type,
                requested_recorded_at=row.requested_recorded_at,
                reason=row.reason,
                status=row.status,
                review_notes=row.review_notes,
                reviewer_id=row.reviewer_id,
                reviewed_at=row.reviewed_at,
                created_at=row.created_at,
            )
            for row in rows
        ],
        page=page,
        page_size=page_size,
        total=total,
    )


@router.patch("/admin/adjustments/{adjustment_id}", response_model=AdjustmentRequest)
def review_adjustment(
    adjustment_id: str,
    payload: AdjustmentReviewRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> AdjustmentRequest:
    if payload.status.value not in {"APPROVED", "REJECTED"}:
        raise HTTPException(status_code=422, detail="Status de revisao invalido.")

    adjustment = db.scalar(
        apply_tenant(
            select(AdjustmentRequestModel).where(AdjustmentRequestModel.id == adjustment_id),
            actor,
            AdjustmentRequestModel,
        )
    )
    if not adjustment:
        raise HTTPException(status_code=404, detail="Solicitacao nao encontrada.")
    if adjustment.status in {AdjustmentStatus.APPROVED, AdjustmentStatus.REJECTED}:
        raise HTTPException(
            status_code=409,
            detail="Solicitacao ja revisada e nao pode ser reprocessada.",
        )

    adjustment.status = payload.status
    adjustment.review_notes = payload.review_notes
    adjustment.reviewer_id = actor.id
    adjustment.reviewed_at = datetime.now(timezone.utc)
    adjustment.updated_at = datetime.now(timezone.utc)

    # Buscar usuario para notificacao (dentro do mesmo tenant)
    user = db.scalar(
        apply_tenant(select(User).where(User.id == adjustment.user_id), actor, User)
    )

    if payload.status == AdjustmentStatus.APPROVED:
        if adjustment.clock_record_id:
            clock_record = db.scalar(
                apply_tenant(
                    select(ClockRecordModel).where(ClockRecordModel.id == adjustment.clock_record_id),
                    actor,
                    ClockRecordModel,
                )
            )
            if clock_record:
                if adjustment.requested_event_type:
                    clock_record.event_type = adjustment.requested_event_type
                if adjustment.requested_recorded_at:
                    clock_record.recorded_at = adjustment.requested_recorded_at
                clock_record.updated_at = datetime.now(timezone.utc)
                if not isinstance(clock_record.payload, dict):
                    clock_record.payload = {}
                clock_record.payload["adjusted_by_review"] = True
                clock_record.payload["adjustment_request_id"] = adjustment.id
        elif adjustment.requested_recorded_at:
            new_record = ClockRecordModel(
                tenant_id=actor.tenant_id,
                idempotency_key=f"adj-{adjustment.id}",
                user_id=adjustment.user_id,
                device_id=None,
                event_type=adjustment.requested_event_type or EventType.ENTRY,
                recorded_at=adjustment.requested_recorded_at,
                source=SourceType.MANUAL,
                sync_status=SyncStatus.SYNCED,
                confidence_score=None,
                liveness_score=None,
                payload={"created_by_adjustment": True, "adjustment_request_id": adjustment.id},
            )
            db.add(new_record)

    review_hash = f"{payload.status.value}:{adjustment.id}"
    chained_hash = chain_audit_hash(db, review_hash)
    db.add(
        AuditLogModel(
            tenant_id=actor.tenant_id,
            actor_type=actor.role,
            actor_id=actor.id or "unknown",
            action="ADJUSTMENT_REVIEW",
            entity_type="adjustment_request",
            entity_id=adjustment.id,
            payload_hash=review_hash,
            previous_hash=chained_hash,
        )
    )
    db.commit()
    db.refresh(adjustment)

    # Enviar notificacao ao colaborador sobre o resultado
    email = user.email if user else ""
    if payload.status == AdjustmentStatus.APPROVED:
        asyncio.create_task(
            send_notification(
                channel=NotificationChannel.EMAIL,
                recipient=email,
                subject="Ajuste de ponto aprovado",
                body=f"Seu ajuste de ponto foi aprovado. Justificativa: {payload.review_notes or 'N/A'}",
                notification_type=NotificationType.ADJUSTMENT_APPROVED,
                metadata={"adjustment_id": adjustment.id, "reviewer_id": actor.id or "unknown"},
            )
        )
    else:
        asyncio.create_task(
            send_notification(
                channel=NotificationChannel.EMAIL,
                recipient=email,
                subject="Ajuste de ponto rejeitado",
                body=f"Seu ajuste de ponto foi rejeitado. Justificativa: {payload.review_notes or 'N/A'}",
                notification_type=NotificationType.ADJUSTMENT_REJECTED,
                metadata={"adjustment_id": adjustment.id, "reviewer_id": actor.id or "unknown"},
            )
        )

    return AdjustmentRequest(
        id=adjustment.id,
        user_id=adjustment.user_id,
        clock_record_id=adjustment.clock_record_id,
        requested_event_type=adjustment.requested_event_type,
        requested_recorded_at=adjustment.requested_recorded_at,
        reason=adjustment.reason,
        status=adjustment.status,
        review_notes=adjustment.review_notes,
        reviewer_id=adjustment.reviewer_id,
        reviewed_at=adjustment.reviewed_at,
        created_at=adjustment.created_at,
    )


@router.post(
    "/admin/retention/cleanup",
    response_model=dict[str, int],
    status_code=status.HTTP_200_OK,
)
def trigger_retention_cleanup(
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> dict[str, int]:
    """Aciona a limpeza de dados antigos conforme politica de retencao."""
    results = cleanup_old_records(db, tenant_id=actor.tenant_id)
    return results
