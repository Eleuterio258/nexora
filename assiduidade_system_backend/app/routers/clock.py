from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.config import settings
from app.deps import ActorContext, get_actor
from app.erp_client import ERPUnavailableError, erp_client
from app.schemas.common import SourceType
from app.schemas.requests import ClockBatchRegisterRequest, ClockRegisterRequest
from app.schemas.responses import ClockRecord
from app.services.attendance_validation import validar_metodo_assiduidade
from app.services.erp_attendance_forwarder import build_clock_event_payload, send_clock_event_to_erp
from app.utils import utc_now


router = APIRouter(tags=["Clock"])


_GESTOR_ROLES = ("ADMIN_SISTEMA", "GESTOR_RH")


async def _resolve_employee(actor: ActorContext, user_id: UUID) -> dict:
    """Obtem os dados do funcionário no ERP (com cache em memória simples)."""
    # TODO: substituir por cache TTL em memória ou Redis para não sobrecarregar o ERP
    try:
        employees = await erp_client.get_employees()
    except ERPUnavailableError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"ERP indisponivel para resolver funcionario: {exc}",
        ) from exc

    user_id_str = str(user_id)
    for employee in employees:
        if str(employee.get("id")) == user_id_str or str(employee.get("erp_user_id")) == user_id_str:
            return employee

    raise HTTPException(status_code=404, detail="Funcionario nao encontrado no ERP.")


async def _create_clock_record(
    payload: ClockRegisterRequest,
    actor: ActorContext,
) -> ClockRecord:
    if actor.id and actor.id != str(payload.user_id) and actor.role not in _GESTOR_ROLES:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Sem permissao para registar assiduidade por conta de outro utilizador.",
        )

    await validar_metodo_assiduidade(payload.source)

    employee = await _resolve_employee(actor, payload.user_id)
    employee_code = str(employee.get("employee_code", ""))
    if not employee_code:
        raise HTTPException(status_code=422, detail="Funcionario sem employee_code no ERP.")

    erp_payload = build_clock_event_payload(
        user_id=payload.user_id,
        employee_code=employee_code,
        device_code=None,  # TODO: obter device_code do ERP ou do header quando existir
        event_type=payload.event_type,
        recorded_at=payload.recorded_at,
        source=payload.source,
    )

    try:
        erp_result = await send_clock_event_to_erp(erp_payload)
    except ERPUnavailableError as exc:
        # No modelo stateless strict, sem ERP o registo falha.
        # TODO: se offline estiver activado, manter em fila temporária em memória.
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Falha ao enviar registo para o ERP: {exc}",
        ) from exc

    return ClockRecord(
        id=erp_result.get("id", "erp-" + utc_now().isoformat()),
        user_id=payload.user_id,
        device_id=payload.device_id,
        event_type=payload.event_type,
        recorded_at=payload.recorded_at,
        source=payload.source,
        sync_status="SYNCED",
        confidence_score=payload.confidence_score,
        liveness_score=payload.liveness_score,
        created_at=utc_now(),
    )


@router.post(
    "/clock/register",
    response_model=ClockRecord,
    status_code=status.HTTP_201_CREATED,
)
async def register_clock(
    payload: ClockRegisterRequest,
    actor: ActorContext = Depends(get_actor),
) -> ClockRecord:
    return await _create_clock_record(payload, actor)


@router.post("/clock/register/batch", status_code=status.HTTP_207_MULTI_STATUS)
async def register_clock_batch(
    payload: ClockBatchRegisterRequest,
    actor: ActorContext = Depends(get_actor),
) -> dict:
    accepted: list[dict] = []
    rejected: list[dict] = []

    for item in payload.records:
        try:
            record = await _create_clock_record(item, actor)
            accepted.append(
                {
                    "idempotency_key": item.idempotency_key,
                    "record_id": str(record.id),
                }
            )
        except HTTPException as exc:
            rejected.append(
                {
                    "idempotency_key": item.idempotency_key,
                    "status_code": exc.status_code,
                    "detail": exc.detail,
                }
            )

    return {
        "total": len(payload.records),
        "accepted": accepted,
        "rejected": rejected,
    }


@router.post("/clock/sync", status_code=status.HTTP_410_GONE)
def sync_clock_records() -> None:
    """Obsoleto: no modelo stateless não há registos locais para sincronizar."""
    raise HTTPException(
        status_code=410,
        detail="Endpoint obsoleto. Registos de ponto sao enviados directamente ao ERP.",
    )


@router.post("/clock/erp/retry-failed", status_code=status.HTTP_410_GONE)
def retry_failed_erp_forwarding() -> None:
    """Obsoleto: no modelo stateless não há registos locais pendentes."""
    raise HTTPException(
        status_code=410,
        detail="Endpoint obsoleto. Reenvio deve ser feito no Nexora ERP.",
    )


@router.get("/clock/me", status_code=status.HTTP_501_NOT_IMPLEMENTED)
def get_my_clock_records() -> None:
    """PROXY ERP: histórico de ponto foi movido para o Nexora ERP."""
    raise HTTPException(
        status_code=501,
        detail="Historico de ponto é consultado no Nexora ERP. Endpoint em construcao.",
    )


@router.post("/clock/adjustments", status_code=status.HTTP_501_NOT_IMPLEMENTED)
def request_adjustment() -> None:
    """PROXY ERP: pedidos de correção de ponto foram movidos para o Nexora ERP."""
    raise HTTPException(
        status_code=501,
        detail="Pedidos de correção de ponto são persistidos no Nexora ERP. Endpoint em construcao.",
    )


@router.get("/clock/adjustments/me", status_code=status.HTTP_501_NOT_IMPLEMENTED)
def get_my_adjustments() -> None:
    """PROXY ERP: consulta de pedidos de correção foi movida para o Nexora ERP."""
    raise HTTPException(
        status_code=501,
        detail="Pedidos de correção de ponto são consultados no Nexora ERP. Endpoint em construcao.",
    )


@router.delete("/clock/adjustments/{adjustment_id}", status_code=status.HTTP_501_NOT_IMPLEMENTED)
def cancel_adjustment() -> None:
    """PROXY ERP: cancelamento de pedidos de correção foi movido para o Nexora ERP."""
    raise HTTPException(
        status_code=501,
        detail="Cancelamento de correção de ponto é feito no Nexora ERP. Endpoint em construcao.",
    )
