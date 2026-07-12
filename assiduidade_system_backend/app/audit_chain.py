"""
Cadeia de hash de auditoria.

No modelo stateless a auditoria é persistida no Nexora ERP, não no FaceClock.
Este módulo mantém uma função no-op para facilitar a remocao gradual das
referencias no código.
"""
from sqlalchemy.orm import Session


def chain_audit_hash(db: Session, payload_hash: str) -> str:
    """No-op: a cadeia de auditoria vive no ERP."""
    return payload_hash
