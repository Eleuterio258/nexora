from datetime import date, datetime, time, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.audit_chain import chain_audit_hash
from app.database import get_db
from app.deps import ActorContext, apply_tenant, get_actor
from app.models import AdjustmentRequestModel, AuditLogModel, ClockRecordModel, Device, User
from app.schemas.common import AdjustmentStatus, SourceType, SyncStatus
from app.schemas.requests import AdjustmentRequestInput, ClockRegisterRequest, ClockSyncRequest
from app.schemas.responses import (
    AdjustmentRequest,
    ClockRecord,
    ClockSyncResponse,
    PaginatedAdjustmentRequests,
    PaginatedClockRecords,
)


router = APIRouter(tags=["Clock"])


def _ensure_same_tenant(actor: ActorContext, resource_tenant_id: str | None) -> None:
    if actor.tenant_id and resource_tenant_id and actor.tenant_id != resource_tenant_id:
        raise HTTPException(status_code=403, detail="Acesso negado a recurso de outro tenant.")


@router.post(
    "/clock/register",
    response_model=ClockRecord,
    status_code=status.HTTP_201_CREATED,
)
def register_clock(
    payload: ClockRegisterRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> ClockRecord:
    user = db.scalar(
        apply_tenant(select(User).where(User.id == str(payload.user_id)), actor, User)
    )
    if not user:
        raise HTTPException(status_code=404, detail="Usuario nao encontrado.")

    duplicate = db.scalar(
        apply_tenant(
            select(ClockRecordModel).where(
                ClockRecordModel.idempotency_key == payload.idempotency_key
            ),
            actor,
            ClockRecordModel,
        )
    )
    if duplicate:
        raise HTTPException(status_code=409, detail="Chave idempotente ja utilizada.")

    device = db.scalar(
        apply_tenant(
            select(Device).where(Device.id == str(payload.device_id)),
            actor,
            Device,
        )
    )

    record = ClockRecordModel(
        tenant_id=actor.tenant_id,
        idempotency_key=payload.idempotency_key,
        user_id=str(payload.user_id),
        device_id=device.id if device else None,
        event_type=payload.event_type,
        recorded_at=payload.recorded_at,
        source=payload.source,
        sync_status=SyncStatus.PENDING if payload.source == SourceType.OFFLINE_SYNC else SyncStatus.SYNCED,
        confidence_score=payload.confidence_score,
        liveness_score=payload.liveness_score,
        geo_lat=payload.geo_lat,
        geo_lng=payload.geo_lng,
        payload={"sync_attempts": 0, "image_base64": payload.image_base64},
    )
    db.add(record)
    db.flush()

    # Update device last_seen
    if device:
        from app.utils import utc_now
        device.last_seen_at = utc_now()

    chained_hash = chain_audit_hash(db, payload.idempotency_key)
    db.add(
        AuditLogModel(
            tenant_id=actor.tenant_id,
            actor_type=actor.role,
            actor_id=actor.id or str(payload.user_id),
            action="CLOCK_REGISTER",
            entity_type="clock_record",
            entity_id=record.id,
            payload_hash=payload.idempotency_key,
            previous_hash=chained_hash,
        )
    )
    db.commit()
    db.refresh(record)
    return ClockRecord(
        id=record.id,
        user_id=record.user_id,
        device_id=record.device_id,
        event_type=record.event_type,
        recorded_at=record.recorded_at,
        source=record.source,
        sync_status=record.sync_status,
        confidence_score=float(record.confidence_score) if record.confidence_score is not None else None,
        liveness_score=float(record.liveness_score) if record.liveness_score is not None else None,
        created_at=record.created_at,
    )


@router.post("/clock/sync", response_model=ClockSyncResponse)
def sync_clock_records(
    payload: ClockSyncRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> ClockSyncResponse:
    synced_ids: list[str] = []
    not_found_ids: list[str] = []

    for record_id in payload.record_ids:
        record = db.scalar(
            apply_tenant(
                select(ClockRecordModel).where(ClockRecordModel.id == str(record_id)),
                actor,
                ClockRecordModel,
            )
        )
        if not record:
            not_found_ids.append(str(record_id))
            continue

        current_attempts = 0
        if isinstance(record.payload, dict):
            current_attempts = int(record.payload.get("sync_attempts", 0))

        record.sync_status = SyncStatus.SYNCED
        record.updated_at = func.now()
        record.payload = {
            **(record.payload or {}),
            "sync_attempts": current_attempts + 1,
            "synced_by": actor.id or "unknown",
        }
        synced_ids.append(record.id)
        db.add(
            AuditLogModel(
                tenant_id=actor.tenant_id,
                actor_type=actor.role,
                actor_id=actor.id or "unknown",
                action="CLOCK_SYNC",
                entity_type="clock_record",
                entity_id=record.id,
                payload_hash=record.idempotency_key,
                previous_hash=chain_audit_hash(db, record.idempotency_key),
            )
        )

    db.commit()
    return ClockSyncResponse(
        synced_record_ids=synced_ids,
        not_found_record_ids=not_found_ids,
        total_requested=len(payload.record_ids),
        total_synced=len(synced_ids),
    )


@router.get("/clock/me", response_model=PaginatedClockRecords)
def get_my_clock_records(
    user_id: str = Query(..., description="ID do utilizador, informado pelo chamador (ERP)."),
    start_date: date | None = Query(None),
    end_date: date | None = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> PaginatedClockRecords:
    user = db.scalar(apply_tenant(select(User).where(User.id == user_id), actor, User))
    if not user:
        raise HTTPException(status_code=404, detail="Usuario nao encontrado.")

    query = apply_tenant(
        select(ClockRecordModel).where(ClockRecordModel.user_id == user_id),
        actor,
        ClockRecordModel,
    )
    count_query = apply_tenant(
        select(func.count()).select_from(ClockRecordModel).where(
            ClockRecordModel.user_id == user_id
        ),
        actor,
        ClockRecordModel,
    )

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


@router.post(
    "/clock/adjustments",
    response_model=AdjustmentRequest,
    status_code=status.HTTP_201_CREATED,
)
def request_adjustment(
    payload: AdjustmentRequestInput,
    user_id: str = Query(..., description="ID do utilizador, informado pelo chamador (ERP)."),
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> AdjustmentRequest:
    user = db.scalar(apply_tenant(select(User).where(User.id == user_id), actor, User))
    if not user:
        raise HTTPException(status_code=404, detail="Usuario nao encontrado.")

    if not payload.clock_record_id and not payload.requested_recorded_at:
        raise HTTPException(
            status_code=422,
            detail="Informe clock_record_id ou requested_recorded_at para o ajuste.",
        )

    if payload.clock_record_id:
        record = db.scalar(
            apply_tenant(
                select(ClockRecordModel).where(
                    ClockRecordModel.id == str(payload.clock_record_id)
                ),
                actor,
                ClockRecordModel,
            )
        )
        if not record:
            raise HTTPException(status_code=404, detail="Registro de ponto nao encontrado.")
        if record.user_id != user_id:
            raise HTTPException(
                status_code=403,
                detail="Nao e permitido solicitar ajuste para registro de outro usuario.",
            )
    if payload.requested_recorded_at:
        recorded_at = payload.requested_recorded_at
        if recorded_at.tzinfo is None:
            recorded_at = recorded_at.replace(tzinfo=timezone.utc)
        now = datetime.now(timezone.utc)
        if recorded_at > now:
            raise HTTPException(
                status_code=422,
                detail="requested_recorded_at nao pode estar no futuro.",
            )
        delta = now - recorded_at
        if delta.days > 31:
            raise HTTPException(
                status_code=422,
                detail="requested_recorded_at fora da janela permitida de 31 dias.",
            )

    request_item = AdjustmentRequestModel(
        tenant_id=actor.tenant_id,
        user_id=user_id,
        clock_record_id=str(payload.clock_record_id) if payload.clock_record_id else None,
        requested_event_type=payload.requested_event_type,
        requested_recorded_at=payload.requested_recorded_at,
        reason=payload.reason,
        status=AdjustmentStatus.PENDING,
    )
    db.add(request_item)
    db.flush()

    adj_hash_value = str(payload.clock_record_id or payload.requested_recorded_at or request_item.id)
    chained_hash = chain_audit_hash(db, adj_hash_value)
    db.add(
        AuditLogModel(
            tenant_id=actor.tenant_id,
            actor_type=actor.role,
            actor_id=actor.id or user_id,
            action="ADJUSTMENT_CREATE",
            entity_type="adjustment_request",
            entity_id=request_item.id,
            payload_hash=adj_hash_value,
            previous_hash=chained_hash,
        )
    )
    db.commit()
    db.refresh(request_item)
    return AdjustmentRequest(
        id=request_item.id,
        user_id=request_item.user_id,
        clock_record_id=request_item.clock_record_id,
        requested_event_type=request_item.requested_event_type,
        requested_recorded_at=request_item.requested_recorded_at,
        reason=request_item.reason,
        status=request_item.status,
        review_notes=request_item.review_notes,
        reviewer_id=request_item.reviewer_id,
        reviewed_at=request_item.reviewed_at,
        created_at=request_item.created_at,
    )


@router.get("/clock/adjustments/me", response_model=PaginatedAdjustmentRequests)
def get_my_adjustments(
    user_id: str = Query(..., description="ID do utilizador, informado pelo chamador (ERP)."),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> PaginatedAdjustmentRequests:
    user = db.scalar(apply_tenant(select(User).where(User.id == user_id), actor, User))
    if not user:
        raise HTTPException(status_code=404, detail="Usuario nao encontrado.")

    query = apply_tenant(
        select(AdjustmentRequestModel).where(AdjustmentRequestModel.user_id == user_id),
        actor,
        AdjustmentRequestModel,
    )
    count_query = apply_tenant(
        select(func.count()).select_from(AdjustmentRequestModel).where(
            AdjustmentRequestModel.user_id == user_id
        ),
        actor,
        AdjustmentRequestModel,
    )

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


@router.delete("/clock/adjustments/{adjustment_id}", status_code=status.HTTP_204_NO_CONTENT)
def cancel_adjustment(
    adjustment_id: str,
    user_id: str = Query(..., description="ID do utilizador, informado pelo chamador (ERP)."),
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> None:
    """Permite ao colaborador cancelar sua propria solicitacao de ajuste pendente."""
    user = db.scalar(apply_tenant(select(User).where(User.id == user_id), actor, User))
    if not user:
        raise HTTPException(status_code=404, detail="Usuario nao encontrado.")

    adjustment = db.scalar(
        apply_tenant(
            select(AdjustmentRequestModel).where(AdjustmentRequestModel.id == adjustment_id),
            actor,
            AdjustmentRequestModel,
        )
    )
    if not adjustment:
        raise HTTPException(status_code=404, detail="Solicitacao nao encontrada.")

    if adjustment.user_id != user_id:
        raise HTTPException(
            status_code=403,
            detail="Nao e permitido cancelar ajuste de outro usuario.",
        )

    if adjustment.status != AdjustmentStatus.PENDING:
        raise HTTPException(
            status_code=409,
            detail=f"Solicitacao com status '{adjustment.status.value}' nao pode ser cancelada.",
        )

    adjustment.status = AdjustmentStatus.CANCELLED
    adjustment.updated_at = datetime.now(timezone.utc)

    db.add(
        AuditLogModel(
            tenant_id=actor.tenant_id,
            actor_type=actor.role,
            actor_id=actor.id or user_id,
            action="ADJUSTMENT_CANCEL",
            entity_type="adjustment_request",
            entity_id=adjustment.id,
            payload_hash=f"cancelled:{adjustment.id}",
            previous_hash=chain_audit_hash(db, f"cancelled:{adjustment.id}"),
        )
    )
    db.commit()
