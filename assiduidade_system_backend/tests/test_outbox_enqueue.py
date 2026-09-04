"""
Testes de atomicidade do outbox ao nivel de servico (app/services/outbox.py).
O caminho completo via HTTP (transicao para PENDING_REENROLL a enfileirar
exactamente um evento) esta coberto por
tests/test_api.py::TestBiometric::test_model_version_mismatch_enqueues_outbox_event_once.
Aqui cobre-se o que esse teste HTTP nao cobre: o comportamento de
enqueue() dentro da mesma unidade de trabalho do chamador, incluindo
rollback (secao 21 do documento de analise: "rollback da operacao tambem
remove o evento do outbox").
"""

from app.models import OutboxEvent
from app.services.outbox import enqueue


def test_enqueue_nao_comita_e_participa_da_transaccao_do_chamador(db_session):
    enqueue(
        db_session,
        tenant_id="tenant-1",
        event_type="biometric.reenroll_required.v1",
        aggregate_type="face_template",
        aggregate_id="template-1",
        payload={"erp_user_id": "1"},
        deduplication_key="reenroll:tenant-1:template-1:v2",
    )

    # Antes do commit do chamador, o evento ainda nao esta visivel numa
    # sessao/consulta que dependa de o registo estar persistido.
    db_session.rollback()
    assert db_session.query(OutboxEvent).count() == 0


def test_enqueue_fica_persistido_apos_commit_do_chamador(db_session):
    enqueue(
        db_session,
        tenant_id="tenant-1",
        event_type="biometric.reenroll_required.v1",
        aggregate_type="face_template",
        aggregate_id="template-1",
        payload={"erp_user_id": "1"},
        deduplication_key="reenroll:tenant-1:template-1:v2",
    )
    db_session.commit()

    events = db_session.query(OutboxEvent).all()
    assert len(events) == 1
    assert events[0].status == "pending"
    assert events[0].attempts == 0
    assert events[0].deduplication_key == "reenroll:tenant-1:template-1:v2"


def test_deduplication_key_duplicada_e_rejeitada_pela_constraint_unica(db_session):
    enqueue(
        db_session,
        tenant_id="tenant-1",
        event_type="biometric.reenroll_required.v1",
        aggregate_type="face_template",
        aggregate_id="template-1",
        payload={"erp_user_id": "1"},
        deduplication_key="reenroll:tenant-1:template-1:v2",
    )
    db_session.commit()

    enqueue(
        db_session,
        tenant_id="tenant-1",
        event_type="biometric.reenroll_required.v1",
        aggregate_type="face_template",
        aggregate_id="template-1",
        payload={"erp_user_id": "1"},
        deduplication_key="reenroll:tenant-1:template-1:v2",
    )
    try:
        db_session.commit()
        assert False, "commit deveria falhar por violar a UNIQUE(deduplication_key)"
    except Exception:
        db_session.rollback()

    assert db_session.query(OutboxEvent).count() == 1
