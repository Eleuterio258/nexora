"""
Router de sincronização com o ERP Omnisys.

Permite importar/atualizar funcionários do ERP para a base de dados local
do FaceClock, mantendo os campos essenciais para registo de presença e
vinculando cada utilizador a um tenant.
"""

from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import ActorContext, get_actor
from app.erp_client import ERPUnavailableError, erp_client
from app.models import Tenant, Unit, User
from app.schemas.common import UserRole, UserStatus
from app.security import get_password_hash

router = APIRouter(tags=["Sync"])


class SyncEmployeesResponse(BaseModel):
    synced: int
    updated: int
    total: int
    tenant_id: str | None
    message: str


class SyncEmployeeResponse(BaseModel):
    id: str
    employee_code: str
    full_name: str
    email: str | None
    role: str
    status: str
    tenant_id: str | None


def _map_role(role: str | None) -> UserRole:
    if not role:
        return UserRole.COLABORADOR
    try:
        return UserRole(role.upper())
    except ValueError:
        return UserRole.COLABORADOR


def _get_or_create_default_unit(db: Session, tenant_id: str | None) -> Unit:
    stmt = select(Unit).where(Unit.code == "HQ")
    if tenant_id:
        stmt = stmt.where(Unit.tenant_id == tenant_id)
    unit = db.scalar(stmt)
    if not unit:
        unit = Unit(code="HQ", name="Headquarters", timezone="Africa/Maputo", tenant_id=tenant_id)
        db.add(unit)
        db.flush()
    return unit


def _get_or_create_tenant(db: Session, external_id: str | None, name: str | None) -> str | None:
    if not external_id:
        return None
    tenant = db.scalar(select(Tenant).where(Tenant.external_id == external_id))
    if not tenant:
        tenant = Tenant(
            external_id=external_id,
            name=name or "Tenant",
            code=external_id.lower()[:50],
        )
        db.add(tenant)
        db.flush()
    return str(tenant.id)


@router.post("/sync/employees", response_model=SyncEmployeesResponse)
async def sync_employees(
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> SyncEmployeesResponse:
    """Sincroniza todos os funcionários do ERP para a base de dados local."""
    try:
        employees = await erp_client.get_employees()
    except ERPUnavailableError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"ERP indisponivel: {exc}",
        )

    # Determina tenant a partir do actor autenticado ou do primeiro funcionario.
    tenant_id = actor.tenant_id
    if not tenant_id and employees:
        first_emp = employees[0]
        ext_tenant = first_emp.get("tenant_id")
        tenant_name = first_emp.get("tenant_name") or first_emp.get("company_name")
        tenant_id = _get_or_create_tenant(db, ext_tenant, tenant_name)

    unit = _get_or_create_default_unit(db, tenant_id)
    synced = 0
    updated = 0

    for emp_data in employees:
        erp_id = str(emp_data.get("id") or emp_data.get("user_id") or emp_data.get("employee_id") or "")
        employee_code = str(emp_data.get("employee_code") or emp_data.get("username") or erp_id)
        full_name = str(emp_data.get("full_name") or emp_data.get("name") or employee_code)
        email = emp_data.get("email")
        phone = emp_data.get("phone")
        is_active = emp_data.get("is_active", True)
        role = _map_role(emp_data.get("role"))

        stmt = select(User).where(
            (User.erp_user_id == erp_id) | (User.employee_code == employee_code)
        )
        if tenant_id:
            stmt = stmt.where(User.tenant_id == tenant_id)
        user = db.scalar(stmt)

        if user:
            user.full_name = full_name
            user.email = email
            user.phone = phone
            user.status = UserStatus.ACTIVE if is_active else UserStatus.INACTIVE
            user.unit_id = unit.id
            user.tenant_id = tenant_id
            if erp_id:
                user.erp_user_id = erp_id
            updated += 1
        else:
            user = User(
                tenant_id=tenant_id,
                erp_user_id=erp_id or None,
                employee_code=employee_code,
                full_name=full_name,
                email=email,
                phone=phone,
                password_hash=get_password_hash(employee_code),
                unit_id=unit.id,
                role=role,
                status=UserStatus.ACTIVE if is_active else UserStatus.INACTIVE,
            )
            db.add(user)
            synced += 1

    db.commit()

    return SyncEmployeesResponse(
        synced=synced,
        updated=updated,
        total=len(employees),
        tenant_id=tenant_id,
        message="Sincronizacao concluida com sucesso.",
    )


@router.post("/sync/employees/{employee_id}", response_model=SyncEmployeeResponse)
async def sync_single_employee(
    employee_id: str,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> SyncEmployeeResponse:
    """Sincroniza um único funcionário do ERP para a base de dados local."""
    try:
        emp_data = await erp_client.get_employee(employee_id)
    except ERPUnavailableError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"ERP indisponivel: {exc}",
        )

    erp_id = str(emp_data.get("id") or emp_data.get("user_id") or emp_data.get("employee_id") or employee_id)
    employee_code = str(emp_data.get("employee_code") or emp_data.get("username") or erp_id)
    full_name = str(emp_data.get("full_name") or emp_data.get("name") or employee_code)
    email = emp_data.get("email")
    phone = emp_data.get("phone")
    is_active = emp_data.get("is_active", True)
    role = _map_role(emp_data.get("role"))

    tenant_id = actor.tenant_id
    if not tenant_id:
        ext_tenant = emp_data.get("tenant_id")
        tenant_name = emp_data.get("tenant_name") or emp_data.get("company_name")
        tenant_id = _get_or_create_tenant(db, ext_tenant, tenant_name)

    unit = _get_or_create_default_unit(db, tenant_id)

    stmt = select(User).where(
        (User.erp_user_id == erp_id) | (User.employee_code == employee_code)
    )
    if tenant_id:
        stmt = stmt.where(User.tenant_id == tenant_id)
    user = db.scalar(stmt)

    if user:
        user.full_name = full_name
        user.email = email
        user.phone = phone
        user.status = UserStatus.ACTIVE if is_active else UserStatus.INACTIVE
        user.unit_id = unit.id
        user.tenant_id = tenant_id
        if erp_id:
            user.erp_user_id = erp_id
    else:
        user = User(
            tenant_id=tenant_id,
            erp_user_id=erp_id,
            employee_code=employee_code,
            full_name=full_name,
            email=email,
            phone=phone,
            password_hash=get_password_hash(employee_code),
            unit_id=unit.id,
            role=role,
            status=UserStatus.ACTIVE if is_active else UserStatus.INACTIVE,
        )
        db.add(user)

    db.commit()
    db.refresh(user)

    return SyncEmployeeResponse(
        id=str(user.id),
        employee_code=user.employee_code,
        full_name=user.full_name,
        email=user.email,
        role=user.role.value,
        status=user.status.value,
        tenant_id=user.tenant_id,
    )
