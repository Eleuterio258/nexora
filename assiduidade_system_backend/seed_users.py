"""
Seed script to create default admin and test users in the database.
Run this after initial migrations to have users available for login.

Usage:
    cd D:\\projecto\\u-tech\\2026\\omnisyserp\\controle
    D:\\projecto\\u-tech\\2026\\omnisyserp\\assiduidade_system\\backend\\venv\\Scripts\\python.exe seed_users.py
"""

import sys
import os

# Add project root to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy import select
from app.database import SessionLocal, engine, Base
from app.models import User, Unit
from app.security import get_password_hash
from datetime import date, UTC, datetime
import uuid


def seed_users():
    """Create default admin and test users."""
    print("🌱 Seeding database with default users...")
    
    db = SessionLocal()
    
    try:
        # Check if admin user already exists
        existing_admin = db.scalar(
            select(User).where(User.employee_code == "ADMIN_SISTEMA")
        )
        if existing_admin:
            print("✅ Admin user already exists, skipping...")
            return
        
        # Create default unit
        default_unit = Unit(
            id=str(uuid.uuid4()),
            code="HQ001",
            name="Sede Principal",
            timezone="Africa/Luanda",
            active=True,
            created_at=datetime.now(UTC),
            updated_at=datetime.now(UTC),
        )
        db.add(default_unit)
        db.flush()
        print(f"✅ Created unit: {default_unit.name}")
        
        # Create admin user
        admin_user = User(
            id=str(uuid.uuid4()),
            employee_code="ADMIN_SISTEMA",
            full_name="Administrador do Sistema",
            email="admin@omnisyserp.tech",
            phone="+244 923 000 000",
            password_hash=get_password_hash("Admin@2026"),
            unit_id=default_unit.id,
            role="ADMIN_SISTEMA",
            status="ACTIVE",
            hired_at=date(2024, 1, 1),
            created_at=datetime.now(UTC),
            updated_at=datetime.now(UTC),
        )
        db.add(admin_user)
        print("✅ Created admin user:")
        print("   👤 Employee Code: ADMIN_SISTEMA")
        print("   🔑 Password: Admin@2026")
        print("   📧 Email: admin@omnisyserp.tech")
        
        # Create RH manager user
        rh_user = User(
            id=str(uuid.uuid4()),
            employee_code="GESTOR_RH",
            full_name="Gestor de Recursos Humanos",
            email="rh@omnisyserp.tech",
            phone="+244 923 000 001",
            password_hash=get_password_hash("RH@2026"),
            unit_id=default_unit.id,
            role="GESTOR_RH",
            status="ACTIVE",
            hired_at=date(2024, 1, 15),
            created_at=datetime.now(UTC),
            updated_at=datetime.now(UTC),
        )
        db.add(rh_user)
        print("\n✅ Created RH manager user:")
        print("   👤 Employee Code: GESTOR_RH")
        print("   🔑 Password: RH@2026")
        print("   📧 Email: rh@omnisyserp.tech")
        
        # Create test collaborator
        test_user = User(
            id=str(uuid.uuid4()),
            employee_code="COLAB_001",
            full_name="João Teste Silva",
            email="joao.teste@omnisyserp.tech",
            phone="+244 923 000 002",
            password_hash=get_password_hash("Test@2026"),
            unit_id=default_unit.id,
            role="COLABORADOR",
            status="ACTIVE",
            hired_at=date(2024, 2, 1),
            created_at=datetime.now(UTC),
            updated_at=datetime.now(UTC),
        )
        db.add(test_user)
        print("\n✅ Created test collaborator:")
        print("   👤 Employee Code: COLAB_001")
        print("   🔑 Password: Test@2026")
        print("   📧 Email: joao.teste@omnisyserp.tech")
        
        db.commit()
        print("\n✅ Database seeding completed successfully!")
        print("\n📝 You can now login with any of these credentials:")
        print("   - Admin: ADMIN_SISTEMA / Admin@2026")
        print("   - RH Manager: GESTOR_RH / RH@2026")
        print("   - Collaborator: COLAB_001 / Test@2026")
        
    except Exception as e:
        db.rollback()
        print(f"\n❌ Error seeding database: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed_users()
