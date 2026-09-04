"""
Metricas do Transactional Outbox (app/models.py:OutboxEvent), servidas via
GET /metrics. Ao contrario de biometric_metrics/erp_sync_metrics (contadores
em memoria do processo da API), estas sao calculadas por query directa à
tabela: o worker que entrega os eventos corre num processo separado, e um
contador em memoria do worker nunca apareceria no /metrics da API. A propria
tabela outbox_events e a fonte de verdade — mesma filosofia do documento de
analise (secao 18).
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import TYPE_CHECKING

from sqlalchemy import func, select

from app.models import OutboxEvent

if TYPE_CHECKING:
    from sqlalchemy.orm import Session


def query_outbox_metrics(db: "Session") -> list[str]:
    counts_by_status = dict(
        db.execute(select(OutboxEvent.status, func.count()).group_by(OutboxEvent.status)).all()
    )

    oldest_pending_seconds = 0.0
    oldest_pending_at = db.scalar(
        select(func.min(OutboxEvent.available_at)).where(OutboxEvent.status == "pending")
    )
    if oldest_pending_at is not None:
        if oldest_pending_at.tzinfo is None:
            oldest_pending_at = oldest_pending_at.replace(tzinfo=timezone.utc)
        oldest_pending_seconds = max(
            0.0, (datetime.now(timezone.utc) - oldest_pending_at).total_seconds()
        )

    return [
        f"outbox_pending_total {counts_by_status.get('pending', 0)}",
        f"outbox_processing_total {counts_by_status.get('processing', 0)}",
        f"outbox_published_total {counts_by_status.get('published', 0)}",
        f"outbox_dead_total {counts_by_status.get('dead', 0)}",
        f"outbox_oldest_pending_seconds {oldest_pending_seconds:.2f}",
    ]
