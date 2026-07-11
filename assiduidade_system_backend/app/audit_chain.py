import hashlib
import threading
from sqlalchemy import desc
from sqlalchemy.orm import Session
from app.models import AuditLogModel


_lock = threading.Lock()


def get_latest_audit_hash(db: Session) -> str | None:
    """Retorna o payload_hash do ultimo registro de auditoria criado.
    DEVE ser chamado dentro do lock para evitar race conditions.
    """
    last_log = db.query(AuditLogModel).order_by(desc(AuditLogModel.created_at)).first()
    if last_log:
        return last_log.payload_hash
    return None


def chain_audit_hash(db: Session, payload_hash: str) -> str:
    """Cria um hash encadeado combinando o hash atual com o hash anterior da cadeia.
    Thread-safe via lock para evitar race conditions em requisições concorrentes.
    NOTA: Este lock é por processo. Em deploy com multiplas instancias,
    considerar lock via banco (SELECT ... FOR UPDATE) ou Redis.
    """
    with _lock:
        previous_hash = get_latest_audit_hash(db)
        if previous_hash:
            combined = f"{previous_hash}:{payload_hash}"
            return hashlib.sha256(combined.encode("utf-8")).hexdigest()
        return payload_hash
