from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.audit_chain import chain_audit_hash
from app.database import get_db
from app.deps import ActorContext, apply_tenant, get_actor
from app.models import AuditLogModel, Device, Unit
from app.schemas.requests import DeviceCreateRequest, DeviceUpdateRequest
from app.schemas.responses import DeviceResponse, PaginatedDevices


router = APIRouter(tags=["Devices"])


@router.post(
    "/admin/devices",
    response_model=DeviceResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_device(
    payload: DeviceCreateRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> DeviceResponse:
    existing = db.scalar(
        apply_tenant(
            select(Device).where(Device.device_code == payload.device_code),
            actor,
            Device,
        )
    )
    if existing:
        raise HTTPException(status_code=409, detail="Codigo de dispositivo ja existe.")

    if payload.unit_id:
        unit = db.scalar(
            apply_tenant(select(Unit).where(Unit.id == str(payload.unit_id)), actor, Unit)
        )
        if not unit:
            raise HTTPException(status_code=404, detail="Unidade nao encontrada.")

    device = Device(
        tenant_id=actor.tenant_id,
        device_code=payload.device_code,
        display_name=payload.display_name,
        unit_id=str(payload.unit_id) if payload.unit_id else None,
        type=payload.type,
    )
    db.add(device)
    db.flush()

    chained_hash = chain_audit_hash(db, device.device_code)
    db.add(
        AuditLogModel(
            tenant_id=actor.tenant_id,
            actor_type=actor.role,
            actor_id=actor.id or "unknown",
            action="DEVICE_CREATE",
            entity_type="device",
            entity_id=device.id,
            payload_hash=device.device_code,
            previous_hash=chained_hash,
        )
    )
    db.commit()
    db.refresh(device)
    return DeviceResponse.model_validate(device)


@router.get("/admin/devices", response_model=PaginatedDevices)
def list_devices(
    unit_id: str | None = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> PaginatedDevices:
    query = apply_tenant(select(Device), actor, Device)
    count_query = apply_tenant(select(func.count()).select_from(Device), actor, Device)

    if unit_id:
        query = query.where(Device.unit_id == unit_id)
        count_query = count_query.where(Device.unit_id == unit_id)

    total = db.scalar(count_query) or 0
    rows = db.scalars(
        query.order_by(Device.display_name.asc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    ).all()

    return PaginatedDevices(
        items=[DeviceResponse.model_validate(row) for row in rows],
        page=page,
        page_size=page_size,
        total=total,
    )


@router.get("/admin/devices/{device_id}", response_model=DeviceResponse)
def get_device(
    device_id: str,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> DeviceResponse:
    device = db.scalar(
        apply_tenant(select(Device).where(Device.id == device_id), actor, Device)
    )
    if not device:
        raise HTTPException(status_code=404, detail="Dispositivo nao encontrado.")
    return DeviceResponse.model_validate(device)


@router.patch("/admin/devices/{device_id}", response_model=DeviceResponse)
def update_device(
    device_id: str,
    payload: DeviceUpdateRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> DeviceResponse:
    device = db.scalar(
        apply_tenant(select(Device).where(Device.id == device_id), actor, Device)
    )
    if not device:
        raise HTTPException(status_code=404, detail="Dispositivo nao encontrado.")

    update_data = payload.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(device, field, value)

    device.updated_at = datetime.now(timezone.utc)

    device_hash = f"{device.device_code}:{device.updated_at.isoformat()}"
    chained_hash = chain_audit_hash(db, device_hash)
    db.add(
        AuditLogModel(
            tenant_id=actor.tenant_id,
            actor_type=actor.role,
            actor_id=actor.id or "unknown",
            action="DEVICE_UPDATE",
            entity_type="device",
            entity_id=device.id,
            payload_hash=device_hash,
            previous_hash=chained_hash,
        )
    )
    db.commit()
    db.refresh(device)
    return DeviceResponse.model_validate(device)


@router.delete("/admin/devices/{device_id}", status_code=status.HTTP_204_NO_CONTENT)
def deactivate_device(
    device_id: str,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> None:
    device = db.scalar(
        apply_tenant(select(Device).where(Device.id == device_id), actor, Device)
    )
    if not device:
        raise HTTPException(status_code=404, detail="Dispositivo nao encontrado.")

    from app.schemas.common import DeviceStatus
    device.status = DeviceStatus.INACTIVE
    device.updated_at = datetime.now(timezone.utc)

    chained_hash = chain_audit_hash(db, device.device_code)
    db.add(
        AuditLogModel(
            tenant_id=actor.tenant_id,
            actor_type=actor.role,
            actor_id=actor.id or "unknown",
            action="DEVICE_DEACTIVATE",
            entity_type="device",
            entity_id=device.id,
            payload_hash=device.device_code,
            previous_hash=chained_hash,
        )
    )
    db.commit()
