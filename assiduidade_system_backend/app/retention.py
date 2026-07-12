"""
Politica de retencao e limpeza automatica de dados.

No modelo stateless o FaceClock não persiste registos de ponto, auditoria ou
batches — esses dados vivem no Nexora ERP. Apenas templates biométricos ficam
localmente; a sua remocao é feita via endpoints de consentimento/LGPD.
"""
import logging

from sqlalchemy.orm import Session


logger = logging.getLogger("faceclock.retention")


def cleanup_old_records(db: Session, tenant_id: str | None = None) -> dict[str, int]:
    """No modelo stateless não há registos locais para limpar."""
    return {}
