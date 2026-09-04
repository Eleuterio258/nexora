"""
Testes do worker do outbox (app/services/outbox.py): claim/lease, entrega via
httpx.MockTransport (nativo do httpx, sem dependencia extra de teste),
classificacao de resposta, retry com backoff e dead-letter — secao 21 do
documento de analise ("testes do worker").
"""

from datetime import datetime, timedelta, timezone

import httpx
import pytest

from app.config import settings as app_settings
from app.services import outbox as outbox_service


def _novo_evento(db_session, **overrides):
    defaults = dict(
        tenant_id="tenant-1",
        event_type="biometric.reenroll_required.v1",
        aggregate_type="face_template",
        aggregate_id="template-1",
        payload={"erp_user_id": "1", "new_model_version": "v2"},
        deduplication_key=f"reenroll:tenant-1:template-1:{overrides.get('aggregate_id', 'template-1')}",
    )
    defaults.update(overrides)
    event = outbox_service.enqueue(db_session, **defaults)
    db_session.commit()
    return event


class TestClaimBatch:
    def test_claim_marca_processing_e_nao_reapanha_a_mesma_linha(self, db_session):
        _novo_evento(db_session, aggregate_id="t1", deduplication_key="dedup-1")
        _novo_evento(db_session, aggregate_id="t2", deduplication_key="dedup-2")

        first_batch = outbox_service.claim_batch(db_session, worker_id="w1", limit=1)
        assert len(first_batch) == 1
        assert first_batch[0].status == "processing"
        assert first_batch[0].locked_by == "w1"

        second_batch = outbox_service.claim_batch(db_session, worker_id="w1", limit=10)
        assert len(second_batch) == 1
        assert second_batch[0].deduplication_key != first_batch[0].deduplication_key

    def test_claim_ignora_eventos_com_available_at_no_futuro(self, db_session):
        event = _novo_evento(db_session, deduplication_key="dedup-futuro")
        event.available_at = datetime.now(timezone.utc) + timedelta(hours=1)
        db_session.commit()

        batch = outbox_service.claim_batch(db_session, worker_id="w1")
        assert batch == []


class TestRecoverExpiredLeases:
    def test_lease_expirada_volta_a_pending(self, db_session):
        event = _novo_evento(db_session, deduplication_key="dedup-lease")
        event.status = "processing"
        event.locked_at = datetime.now(timezone.utc) - timedelta(seconds=600)
        event.locked_by = "worker-morto"
        db_session.commit()

        recovered = outbox_service.recover_expired_leases(db_session, lease_timeout_seconds=300)
        assert recovered == 1

        db_session.refresh(event)
        assert event.status == "pending"
        assert event.locked_at is None
        assert event.locked_by is None

    def test_lease_ainda_valida_nao_e_recuperada(self, db_session):
        event = _novo_evento(db_session, deduplication_key="dedup-lease-valida")
        event.status = "processing"
        event.locked_at = datetime.now(timezone.utc)
        event.locked_by = "worker-vivo"
        db_session.commit()

        recovered = outbox_service.recover_expired_leases(db_session, lease_timeout_seconds=300)
        assert recovered == 0


class TestClassifyResponse:
    @pytest.mark.parametrize("status_code", [200, 201, 202, 204, 409])
    def test_sucesso(self, status_code):
        assert outbox_service.classify_response(status_code, None) == "success"

    @pytest.mark.parametrize("status_code", [408, 425, 429, 500, 502, 503])
    def test_retry(self, status_code):
        assert outbox_service.classify_response(status_code, None) == "retry"

    def test_erro_de_rede_e_retry(self):
        assert outbox_service.classify_response(None, httpx.ConnectError("falhou")) == "retry"

    @pytest.mark.parametrize("status_code", [400, 401, 403, 404])
    def test_erro_permanente_e_dead(self, status_code):
        assert outbox_service.classify_response(status_code, None) == "dead"


class TestBackoffSeconds:
    def test_cresce_com_as_tentativas(self):
        assert outbox_service.backoff_seconds(1) == pytest.approx(30, rel=0.25)
        assert outbox_service.backoff_seconds(5) == pytest.approx(600, rel=0.25)

    def test_fica_fixo_no_ultimo_valor_da_tabela(self):
        muitas_tentativas = outbox_service.backoff_seconds(100)
        assert muitas_tentativas == pytest.approx(43200, rel=0.25)


class TestProcessBatch:
    def test_200_marca_published(self, db_session, monkeypatch):
        monkeypatch.setattr(app_settings, "erp_reenroll_webhook_url", "https://erp.test/webhook")
        event = _novo_evento(db_session, deduplication_key="dedup-200")

        def handler(request: httpx.Request) -> httpx.Response:
            assert request.headers.get("Content-Type") == "application/json"
            return httpx.Response(200, json={"status": "accepted"})

        http_client = httpx.Client(transport=httpx.MockTransport(handler))
        processed = outbox_service.process_batch(db_session, worker_id="w1", http_client=http_client)

        assert processed == 1
        db_session.refresh(event)
        assert event.status == "published"
        assert event.published_at is not None

    def test_429_agenda_retry(self, db_session, monkeypatch):
        monkeypatch.setattr(app_settings, "erp_reenroll_webhook_url", "https://erp.test/webhook")
        event = _novo_evento(db_session, deduplication_key="dedup-429")

        http_client = httpx.Client(
            transport=httpx.MockTransport(lambda request: httpx.Response(429))
        )
        outbox_service.process_batch(db_session, worker_id="w1", http_client=http_client)

        db_session.refresh(event)
        assert event.status == "pending"
        assert event.attempts == 1
        # SQLite (usado nos testes) nao preserva tzinfo em DateTime(timezone=True)
        # depois de um round-trip — Postgres (producao) preserva. Normaliza antes
        # de comparar para nao confundir isso com um bug do calculo de backoff.
        available_at = event.available_at
        if available_at.tzinfo is None:
            available_at = available_at.replace(tzinfo=timezone.utc)
        assert available_at > datetime.now(timezone.utc)

    def test_400_marca_dead(self, db_session, monkeypatch):
        monkeypatch.setattr(app_settings, "erp_reenroll_webhook_url", "https://erp.test/webhook")
        event = _novo_evento(db_session, deduplication_key="dedup-400")

        http_client = httpx.Client(
            transport=httpx.MockTransport(lambda request: httpx.Response(400))
        )
        outbox_service.process_batch(db_session, worker_id="w1", http_client=http_client)

        db_session.refresh(event)
        assert event.status == "dead"
        assert event.last_error == "HTTP 400"

    def test_timeout_de_rede_agenda_retry(self, db_session, monkeypatch):
        monkeypatch.setattr(app_settings, "erp_reenroll_webhook_url", "https://erp.test/webhook")
        event = _novo_evento(db_session, deduplication_key="dedup-timeout")

        def handler(request: httpx.Request) -> httpx.Response:
            raise httpx.ConnectTimeout("timeout simulado")

        http_client = httpx.Client(transport=httpx.MockTransport(handler))
        outbox_service.process_batch(db_session, worker_id="w1", http_client=http_client)

        db_session.refresh(event)
        assert event.status == "pending"
        assert event.attempts == 1

    def test_evento_transporta_event_id_no_corpo_do_pedido(self, db_session, monkeypatch):
        monkeypatch.setattr(app_settings, "erp_reenroll_webhook_url", "https://erp.test/webhook")
        event = _novo_evento(db_session, deduplication_key="dedup-event-id")

        captured = {}

        def handler(request: httpx.Request) -> httpx.Response:
            import json

            captured["body"] = json.loads(request.content)
            return httpx.Response(200)

        http_client = httpx.Client(transport=httpx.MockTransport(handler))
        outbox_service.process_batch(db_session, worker_id="w1", http_client=http_client)

        assert captured["body"]["event_id"] == event.id
        assert captured["body"]["erp_user_id"] == "1"
