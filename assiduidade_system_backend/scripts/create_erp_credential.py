#!/usr/bin/env python3
"""Cria uma credencial Nexora para autenticar o ERP no FaceClock.

Uso:
    cd assiduidade_system_backend
    python scripts/create_erp_credential.py <tenant_id>

O script lê DATABASE_URL e NEXORA_CREDENTIAL_ENCRYPTION_KEY do ambiente
(ou do ficheiro .env na raiz do projecto).

Exemplo de saída:
    Access Key ID:  nexora_ak_...
    Secret Key:     nexora_sk_...

Guarde o Secret Key em segurança — não é possível recuperá-lo depois.
No Nexora ERP configure:
    FACECLOCK_ACCESS_KEY_ID=<Access Key ID>
    FACECLOCK_SECRET_ACCESS_KEY=<Secret Key>
"""

import os
import sys

# Adicionar a raiz do projecto ao path para importar app
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, project_root)

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.config import settings
from app.database import Base
from app.services.api_credentials import create_credential


def main() -> None:
    load_dotenv(os.path.join(project_root, ".env"))

    if len(sys.argv) != 2:
        print(f"Uso: {sys.argv[0]} <tenant_id>", file=sys.stderr)
        sys.exit(1)

    tenant_id = sys.argv[1]

    engine = create_engine(settings.database_url)
    Base.metadata.create_all(bind=engine)
    Session = sessionmaker(bind=engine)
    db = Session()

    try:
        cred, secret = create_credential(
            db=db,
            tenant_id=tenant_id,
            name="Nexora ERP",
            permissions=[
                "biometric:enroll",
                "biometric:verify",
                "liveness:challenge",
                "liveness:verify",
            ],
        )
        print("Credencial criada com sucesso.")
        print(f"Tenant ID:      {tenant_id}")
        print(f"Access Key ID:  {cred.access_key_id}")
        print(f"Secret Key:     {secret}")
        print("\nConfigure no Nexora ERP:")
        print(f"  FACECLOCK_ACCESS_KEY_ID={cred.access_key_id}")
        print(f"  FACECLOCK_SECRET_ACCESS_KEY={secret}")
    finally:
        db.close()


if __name__ == "__main__":
    main()
