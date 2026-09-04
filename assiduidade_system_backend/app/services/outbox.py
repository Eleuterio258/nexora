"""
Transactional Outbox: camada de servico que grava, reserva e entrega
OutboxEvent (app/models.py). Ver docs/analise-transactional-outbox-backends.md,
secoes 14-15 e 28-30.

enqueue() nunca comita: participa da transaccao do chamador (ex.:
app/routers/biometric.py, junto com a mudanca de FaceTemplate.status). As
restantes funcoes gerem a sua propria unidade de trabalho, porque correm no
worker separado (app/workers/outbox.py), sem transaccao de chamador para
participar.
"""

from __future__ import annotations

import logging
import random
from datetime import datetime, timedelta, timezone
from typing import TYPE_CHECKING, Literal

from sqlalchemy import select, update

from app.models import OutboxEvent

if TYPE_CHECKING:
    import httpx
    from sqlalchemy.orm import Session

log = logging.getLogger(__name__)

# Sequencia de backoff da secao 15.2 do documento: 30s, 1m, 2m, 5m, 10m, 30m,
# 1h, 3h, 6h, 12h — tentativas alem da tabela ficam fixas no ultimo valor.
_BACKOFF_SECONDS = [30, 60, 120, 300, 600, 1800, 3600, 10800, 21600, 43200]


def enqueue(
    db: "Session",
    *,
    tenant_id: str | None,
    event_type: str,
    aggregate_type: str,
    aggregate_id: str,
    payload: dict,
    deduplication_key: str,
) -> OutboxEvent:
    """Cria (mas nao comita) um evento no outbox. O chamador comita, na mesma
    transaccao da alteracao de negocio que o originou."""
    event = OutboxEvent(
        tenant_id=tenant_id,
        event_type=event_type,
        aggregate_type=aggregate_type,
        aggregate_id=aggregate_id,
        payload=payload,
        deduplication_key=deduplication_key,
    )
    db.add(event)
    return event


def claim_batch(db: "Session", *, worker_id: str, limit: int = 50) -> list[OutboxEvent]:
    """Reserva ate `limit` eventos pendentes e vencidos para este worker.

    FOR UPDATE SKIP LOCKED so se aplica em Postgres: SQLite (usado nos
    testes) nao suporta a clausula e nao precisa dela, um unico processo de
    teste nunca disputa a mesma linha.
    """
    now = datetime.now(timezone.utc)
    query = (
        select(OutboxEvent)
        .where(OutboxEvent.status == "pending", OutboxEvent.available_at <= now)
        .order_by(OutboxEvent.created_at)
        .limit(limit)
    )
    if db.get_bind().dialect.name != "sqlite":
        query = query.with_for_update(skip_locked=True)

    events = list(db.scalars(query))
    for event in events:
        event.status = "processing"
        event.locked_at = now
        event.locked_by = worker_id
    db.commit()
    return events


def recover_expired_leases(db: "Session", *, lease_timeout_seconds: int) -> int:
    """Devolve a `pending` eventos `processing` cujo lease expirou — worker
    que morreu a meio do envio nao perde o evento (secao 15.3)."""
    threshold = datetime.now(timezone.utc) - timedelta(seconds=lease_timeout_seconds)
    result = db.execute(
        update(OutboxEvent)
        .where(OutboxEvent.status == "processing", OutboxEvent.locked_at < threshold)
        .values(status="pending", locked_at=None, locked_by=None)
    )
    db.commit()
    return result.rowcount or 0


def classify_response(
    status_code: int | None, exc: Exception | None
) -> Literal["success", "retry", "dead"]:
    """Tabela da secao 15.1 do documento."""
    if exc is not None:
        return "retry"
    if status_code in (200, 201, 202, 204, 409):
        return "success"
    if status_code in (408, 425, 429) or (status_code is not None and status_code >= 500):
        return "retry"
    return "dead"


def backoff_seconds(attempts: int) -> int:
    """Sequencia da secao 15.2, com jitter de ate +-20% para nao sincronizar
    retries de varias instancias."""
    index = min(max(attempts - 1, 0), len(_BACKOFF_SECONDS) - 1)
    base = _BACKOFF_SECONDS[index]
    jitter = base * random.uniform(-0.2, 0.2)
    return max(1, round(base + jitter))


def mark_published(db: "Session", event: OutboxEvent) -> None:
    event.status = "published"
    event.published_at = datetime.now(timezone.utc)
    event.locked_at = None
    event.locked_by = None
    db.commit()


def mark_retry(db: "Session", event: OutboxEvent, *, error: str) -> None:
    event.attempts += 1
    event.status = "pending"
    event.available_at = datetime.now(timezone.utc) + timedelta(seconds=backoff_seconds(event.attempts))
    event.last_error = error[:2000]
    event.locked_at = None
    event.locked_by = None
    db.commit()


def mark_dead(db: "Session", event: OutboxEvent, *, error: str) -> None:
    event.status = "dead"
    event.last_error = error[:2000]
    event.locked_at = None
    event.locked_by = None
    db.commit()


# event_type -> (settings attr da URL de destino, tipo de evento no payload)
_DELIVERY_TARGETS = {
    "biometric.reenroll_required.v1": "erp_reenroll_webhook_url",
}


def deliver(
    event: OutboxEvent, http_client: "httpx.Client"
) -> tuple[int | None, Exception | None]:
    """Envia um evento ao ERP. Nunca levanta excecao: devolve
    (status_code, None) em caso de resposta HTTP, ou (None, excecao) em caso
    de falha de rede/timeout — process_batch usa classify_response para
    decidir o proximo estado a partir daqui."""
    from app.config import settings
    from app.erp_client import erp_client

    url_attr = _DELIVERY_TARGETS.get(event.event_type)
    webhook_url = getattr(settings, url_attr, "") if url_attr else ""
    if not webhook_url:
        return None, RuntimeError(f"sem URL de destino configurada para {event.event_type}")

    body = {**event.payload, "event_id": event.id}
    try:
        response = http_client.post(webhook_url, headers=erp_client.device_headers(), json=body)
        return response.status_code, None
    except Exception as exc:  # httpx.RequestError e afins
        return None, exc


def process_batch(
    db: "Session",
    *,
    worker_id: str,
    http_client: "httpx.Client",
    limit: int = 50,
) -> int:
    """Reserva e entrega um lote de eventos pendentes. Cada evento comita a
    sua propria transicao de estado — uma falha num evento nao bloqueia os
    restantes do lote. Devolve o numero de eventos processados."""
    events = claim_batch(db, worker_id=worker_id, limit=limit)
    for event in events:
        status_code, exc = deliver(event, http_client)
        outcome = classify_response(status_code, exc)
        if outcome == "success":
            mark_published(db, event)
        elif outcome == "retry":
            error = str(exc) if exc else f"HTTP {status_code}"
            mark_retry(db, event, error=error)
            log.warning(
                "outbox: evento %s (%s) agendado para retry: %s",
                event.id, event.event_type, error,
            )
        else:
            error = str(exc) if exc else f"HTTP {status_code}"
            mark_dead(db, event, error=error)
            log.error(
                "outbox: evento %s (%s) marcado como dead-letter: %s",
                event.id, event.event_type, error,
            )
    return len(events)
