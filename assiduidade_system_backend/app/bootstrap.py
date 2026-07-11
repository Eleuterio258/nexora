from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Device, Tenant, Unit, User
from app.schemas.common import DeviceStatus, DeviceType, UserRole, UserStatus
from app.security import get_password_hash


DEFAULT_TENANT_CODE = "default"
DEFAULT_TENANT_NAME = "Tenant Padrão"


def _get_or_create_default_tenant(db: Session) -> Tenant:
    tenant = db.scalar(select(Tenant).where(Tenant.code == DEFAULT_TENANT_CODE))
    if not tenant:
        tenant = Tenant(
            code=DEFAULT_TENANT_CODE,
            name=DEFAULT_TENANT_NAME,
            external_id="default",
        )
        db.add(tenant)
        db.flush()
    return tenant


def seed_data(db: Session) -> None:
    tenant = _get_or_create_default_tenant(db)

    unit = db.scalar(
        select(Unit).where(Unit.code == "HQ", Unit.tenant_id == tenant.id)
    )
    if not unit:
        unit = Unit(
            code="HQ",
            name="Headquarters",
            timezone="Africa/Maputo",
            tenant_id=tenant.id,
        )
        db.add(unit)
        db.flush()

    demo_users = [
        ("ADMIN_SISTEMA", "Administrador do Sistema", "admin@faceclock.local", UserRole.ADMIN_SISTEMA, "Admin@2026"),
        ("GESTOR_RH", "Gestor de RH", "rh@faceclock.local", UserRole.GESTOR_RH, "RH@2026"),
        ("COLAB_001", "Colaborador Demo", "colaborador@faceclock.local", UserRole.COLABORADOR, "Test@2026"),
    ]

    for employee_code, full_name, email, role, password in demo_users:
        existing = db.scalar(
            select(User).where(
                User.employee_code == employee_code,
                User.tenant_id == tenant.id,
            )
        )
        if existing:
            continue
        db.add(
            User(
                tenant_id=tenant.id,
                employee_code=employee_code,
                full_name=full_name,
                email=email,
                password_hash=get_password_hash(password),
                unit_id=unit.id,
                role=role,
                status=UserStatus.ACTIVE,
            )
        )

    device = db.scalar(
        select(Device).where(
            Device.device_code == "TOTEM-MZ-01",
            Device.tenant_id == tenant.id,
        )
    )
    if not device:
        db.add(
            Device(
                tenant_id=tenant.id,
                device_code="TOTEM-MZ-01",
                display_name="Totem Maputo 01",
                unit_id=unit.id,
                type=DeviceType.TOTEM,
                status=DeviceStatus.ACTIVE,
            )
        )

    db.commit()
