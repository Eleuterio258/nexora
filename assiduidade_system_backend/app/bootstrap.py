"""
Bootstrap do FaceClock.

No modelo stateless não há dados mestres locais para criar.
A aplicação depende do Nexora ERP para funcionários, tenants, unidades e
dispositivos.
"""

from sqlalchemy.orm import Session


def seed_data(db: Session) -> None:
    """Não cria dados locais no modelo stateless."""
    return
