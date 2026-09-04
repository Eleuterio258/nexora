"""
Worker do Transactional Outbox — processo separado da API FastAPI (nunca uma
task no lifespan, ver docs/analise-transactional-outbox-backends.md secao
28.3). Corre em loop: recupera leases expiradas, reserva um lote de eventos
pendentes e entrega-os ao ERP, aplicando retry/backoff e dead-letter.

Arranque: `python -m app.workers.outbox` (ver entrypoint-worker.sh).
"""

import logging
import os
import socket
import time

import httpx

from app.config import settings
from app.database import SessionLocal
from app.services import outbox as outbox_service

logger = logging.getLogger("faceclock.outbox_worker")
if not logger.handlers:
    logging.basicConfig(level=logging.INFO, format="%(message)s")


def run() -> None:
    worker_id = f"{socket.gethostname()}-{os.getpid()}"
    logger.info("Outbox worker a arrancar (worker_id=%s)", worker_id)

    with httpx.Client(timeout=settings.erp_timeout_seconds) as http_client:
        while True:
            processed = 0
            db = SessionLocal()
            try:
                recovered = outbox_service.recover_expired_leases(
                    db, lease_timeout_seconds=settings.outbox_lease_seconds
                )
                if recovered:
                    logger.warning("Outbox worker: %d lease(s) expirada(s) recuperada(s)", recovered)
                processed = outbox_service.process_batch(
                    db,
                    worker_id=worker_id,
                    http_client=http_client,
                    limit=settings.outbox_batch_size,
                )
            except Exception:
                logger.exception("Outbox worker: erro no ciclo de processamento")
            finally:
                db.close()

            if processed == 0:
                time.sleep(settings.outbox_poll_interval_seconds)


if __name__ == "__main__":
    run()
