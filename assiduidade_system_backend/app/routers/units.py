from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.audit_chain import chain_audit_hash
from app.database import get_db
from app.deps import ActorContext, apply_tenant, get_actor
from app.models import AuditLogModel, Unit
from app.schemas.requests import UnitCreateRequest, UnitUpdateRequest
from app.schemas.responses import PaginatedUnits, UnitResponse


router = APIRouter(tags=["Units"])


@router.post(
    "/admin/units",
    response_model=UnitResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_unit(
    payload: UnitCreateRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> UnitResponse:
    existing = db.scalar(
        apply_tenant(
            select(Unit).where(Unit.code == payload.code),
            actor,
            Unit,
        )
    )
    if existing:
        raise HTTPException(status_code=409, detail="Codigo de unidade ja existe.")

    unit = Unit(
        tenant_id=actor.tenant_id,
        code=payload.code,
        name=payload.name,
        timezone=payload.timezone,
        geo_lat=payload.geo_lat,
        geo_lng=payload.geo_lng,
    )
    db.add(unit)
    db.flush()

    chained_hash = chain_audit_hash(db, unit.code)
    db.add(
        AuditLogModel(
            tenant_id=actor.tenant_id,
            actor_type=actor.role,
            actor_id=actor.id or "unknown",
            action="UNIT_CREATE",
            entity_type="unit",
            entity_id=unit.id,
            payload_hash=unit.code,
            previous_hash=chained_hash,
        )
    )
    db.commit()
    db.refresh(unit)
    return UnitResponse.model_validate(unit)


@router.get("/admin/units", response_model=PaginatedUnits)
def list_units(
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    active_only: bool = Query(True),
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> PaginatedUnits:
    query = apply_tenant(select(Unit), actor, Unit)
    count_query = apply_tenant(select(func.count()).select_from(Unit), actor, Unit)

    if active_only:
        query = query.where(Unit.active.is_(True))
        count_query = count_query.where(Unit.active.is_(True))

    total = db.scalar(count_query) or 0
    rows = db.scalars(
        query.order_by(Unit.name.asc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    ).all()

    return PaginatedUnits(
        items=[UnitResponse.model_validate(row) for row in rows],
        page=page,
        page_size=page_size,
        total=total,
    )


@router.get("/admin/units/{unit_id}", response_model=UnitResponse)
def get_unit(
    unit_id: str,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> UnitResponse:
    unit = db.scalar(
        apply_tenant(select(Unit).where(Unit.id == unit_id), actor, Unit)
    )
    if not unit:
        raise HTTPException(status_code=404, detail="Unidade nao encontrada.")
    return UnitResponse.model_validate(unit)


@router.patch("/admin/units/{unit_id}", response_model=UnitResponse)
def update_unit(
    unit_id: str,
    payload: UnitUpdateRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> UnitResponse:
    unit = db.scalar(
        apply_tenant(select(Unit).where(Unit.id == unit_id), actor, Unit)
    )
    if not unit:
        raise HTTPException(status_code=404, detail="Unidade nao encontrada.")

    update_data = payload.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(unit, field, value)

    unit.updated_at = datetime.now(timezone.utc)

    unit_hash = f"{unit.code}:{unit.updated_at.isoformat()}"
    chained_hash = chain_audit_hash(db, unit_hash)
    db.add(
        AuditLogModel(
            tenant_id=actor.tenant_id,
            actor_type=actor.role,
            actor_id=actor.id or "unknown",
            action="UNIT_UPDATE",
            entity_type="unit",
            entity_id=unit.id,
            payload_hash=unit_hash,
            previous_hash=chained_hash,
        )
    )
    db.commit()
    db.refresh(unit)
    return UnitResponse.model_validate(unit)


@router.delete("/admin/units/{unit_id}", status_code=status.HTTP_204_NO_CONTENT)
def deactivate_unit(
    unit_id: str,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> None:
    unit = db.scalar(
        apply_tenant(select(Unit).where(Unit.id == unit_id), actor, Unit)
    )
    if not unit:
        raise HTTPException(status_code=404, detail="Unidade nao encontrada.")

    unit.active = False
    unit.updated_at = datetime.now(timezone.utc)

    chained_hash = chain_audit_hash(db, unit.code)
    db.add(
        AuditLogModel(
            tenant_id=actor.tenant_id,
            actor_type=actor.role,
            actor_id=actor.id or "unknown",
            action="UNIT_DEACTIVATE",
            entity_type="unit",
            entity_id=unit.id,
            payload_hash=unit.code,
            previous_hash=chained_hash,
        )
    )
    db.commit()
