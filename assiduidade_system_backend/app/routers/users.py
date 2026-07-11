from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.audit_chain import chain_audit_hash
from app.database import get_db
from app.deps import ActorContext, apply_tenant, get_actor
from app.models import AuditLogModel, User
from app.schemas.common import UserRole, UserStatus
from app.schemas.requests import UserCreateRequest, UserUpdateRequest
from app.schemas.responses import PaginatedUsers, UserDetail
from app.security import get_password_hash, validate_password_strength


router = APIRouter(tags=["Users"])


@router.post(
    "/admin/users",
    response_model=UserDetail,
    status_code=status.HTTP_201_CREATED,
)
def create_user(
    payload: UserCreateRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> UserDetail:
    existing = db.scalar(
        apply_tenant(
            select(User).where(User.employee_code == payload.employee_code),
            actor,
            User,
        )
    )
    if existing:
        raise HTTPException(status_code=409, detail="Codigo de funcionario ja existe.")

    if payload.email:
        existing_email = db.scalar(
            apply_tenant(
                select(User).where(User.email == payload.email),
                actor,
                User,
            )
        )
        if existing_email:
            raise HTTPException(status_code=409, detail="Email ja registrado.")

    if payload.nfc_tag:
        existing_nfc = db.scalar(
            apply_tenant(
                select(User).where(User.nfc_tag == payload.nfc_tag),
                actor,
                User,
            )
        )
        if existing_nfc:
            raise HTTPException(status_code=409, detail="Tag NFC ja registrada.")

    password_error = validate_password_strength(payload.password)
    if password_error:
        raise HTTPException(status_code=422, detail=password_error)

    try:
        role = UserRole(payload.role)
    except ValueError:
        raise HTTPException(status_code=422, detail=f"Papel invalido: {payload.role}")

    pin_hash = None
    if payload.pin:
        if len(payload.pin) != 6 or not payload.pin.isdigit():
            raise HTTPException(status_code=422, detail="PIN deve ter exatamente 6 digitos numericos.")
        from app.security import get_password_hash as hash_pin
        pin_hash = hash_pin(payload.pin)

    user = User(
        tenant_id=actor.tenant_id,
        employee_code=payload.employee_code,
        full_name=payload.full_name,
        email=payload.email,
        phone=payload.phone,
        nfc_tag=payload.nfc_tag,
        password_hash=get_password_hash(payload.password),
        pin_hash=pin_hash,
        unit_id=str(payload.unit_id) if payload.unit_id else None,
        role=role,
        status=payload.status,
        hired_at=payload.hired_at,
    )
    db.add(user)
    db.flush()

    chained_hash = chain_audit_hash(db, user.employee_code)
    db.add(
        AuditLogModel(
            tenant_id=actor.tenant_id,
            actor_type=actor.role,
            actor_id=actor.id or "unknown",
            action="USER_CREATE",
            entity_type="user",
            entity_id=user.id,
            payload_hash=user.employee_code,
            previous_hash=chained_hash,
        )
    )
    db.commit()
    db.refresh(user)
    return UserDetail.model_validate(user)


@router.get("/admin/users", response_model=PaginatedUsers)
def list_users(
    unit_id: str | None = Query(None),
    role: UserRole | None = Query(None),
    status: UserStatus | None = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> PaginatedUsers:
    query = apply_tenant(select(User), actor, User)
    count_query = apply_tenant(select(func.count()).select_from(User), actor, User)

    if unit_id:
        query = query.where(User.unit_id == unit_id)
        count_query = count_query.where(User.unit_id == unit_id)
    if role:
        query = query.where(User.role == role)
        count_query = count_query.where(User.role == role)
    if status:
        query = query.where(User.status == status)
        count_query = count_query.where(User.status == status)

    total = db.scalar(count_query) or 0
    rows = db.scalars(
        query.order_by(User.full_name.asc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    ).all()

    return PaginatedUsers(
        items=[UserDetail.model_validate(row) for row in rows],
        page=page,
        page_size=page_size,
        total=total,
    )


@router.get("/admin/users/{user_id}", response_model=UserDetail)
def get_user(
    user_id: str,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> UserDetail:
    user = db.scalar(
        apply_tenant(select(User).where(User.id == user_id), actor, User)
    )
    if not user:
        raise HTTPException(status_code=404, detail="Usuario nao encontrado.")
    return UserDetail.model_validate(user)


@router.patch("/admin/users/{user_id}", response_model=UserDetail)
def update_user(
    user_id: str,
    payload: UserUpdateRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> UserDetail:
    user = db.scalar(
        apply_tenant(select(User).where(User.id == user_id), actor, User)
    )
    if not user:
        raise HTTPException(status_code=404, detail="Usuario nao encontrado.")

    update_data = payload.model_dump(exclude_unset=True)

    if "password" in update_data and update_data["password"] is not None:
        password_error = validate_password_strength(update_data["password"])
        if password_error:
            raise HTTPException(status_code=422, detail=password_error)
        update_data["password_hash"] = get_password_hash(update_data.pop("password"))

    if "pin" in update_data:
        if update_data["pin"] is None:
            update_data["pin_hash"] = None
            update_data.pop("pin")
        elif len(update_data["pin"]) != 6 or not update_data["pin"].isdigit():
            raise HTTPException(status_code=422, detail="PIN deve ter exatamente 6 digitos numericos.")
        else:
            update_data["pin_hash"] = get_password_hash(update_data.pop("pin"))

    if "role" in update_data and update_data["role"] is not None:
        try:
            update_data["role"] = UserRole(update_data["role"])
        except ValueError:
            raise HTTPException(status_code=422, detail=f"Papel invalido: {update_data['role']}")

    if "password" in update_data and update_data["password"] is not None:
        update_data["password_hash"] = get_password_hash(update_data.pop("password"))

    if "status" in update_data and update_data["status"] == UserStatus.TERMINATED:
        update_data["terminated_at"] = datetime.now(timezone.utc).date()

    for field, value in update_data.items():
        setattr(user, field, value)

    user.updated_at = datetime.now(timezone.utc)

    user_hash = f"{user.employee_code}:{user.updated_at.isoformat()}"
    chained_hash = chain_audit_hash(db, user_hash)
    db.add(
        AuditLogModel(
            tenant_id=actor.tenant_id,
            actor_type=actor.role,
            actor_id=actor.id or "unknown",
            action="USER_UPDATE",
            entity_type="user",
            entity_id=user.id,
            payload_hash=user_hash,
            previous_hash=chained_hash,
        )
    )
    db.commit()
    db.refresh(user)
    return UserDetail.model_validate(user)


@router.delete("/admin/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def deactivate_user(
    user_id: str,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> None:
    user = db.scalar(
        apply_tenant(select(User).where(User.id == user_id), actor, User)
    )
    if not user:
        raise HTTPException(status_code=404, detail="Usuario nao encontrado.")

    user.status = UserStatus.INACTIVE
    user.updated_at = datetime.now(timezone.utc)

    chained_hash = chain_audit_hash(db, user.employee_code)
    db.add(
        AuditLogModel(
            tenant_id=actor.tenant_id,
            actor_type=actor.role,
            actor_id=actor.id or "unknown",
            action="USER_DEACTIVATE",
            entity_type="user",
            entity_id=user.id,
            payload_hash=user.employee_code,
            previous_hash=chained_hash,
        )
    )
    db.commit()
