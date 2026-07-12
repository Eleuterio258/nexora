"""
Envio de eventos de ponto para o Nexora ERP.

No modelo stateless o FaceClock não persiste clock_records. Este módulo expõe
funções auxiliares para construir o payload ERP a partir dos dados recebidos no
pedido e enviá-lo via `erp_client`.
"""

import logging
import time
from typing import Any
from uuid import UUID

from app.erp_client import ERPUnavailableError, erp_client
from app.erp_sync_metrics import erp_sync_metrics
from app.schemas.common import EventType, SourceType

logger = logging.getLogger("faceclock.erp_forwarder")

# SourceType do FaceClock -> credential_type esperado por GenericPayload no ERP
_CREDENTIAL_TYPE_MAP: dict[SourceType, str] = {
    SourceType.FACIAL: "face",
    SourceType.FINGERPRINT: "fingerprint",
    SourceType.QR_CODE: "qr",
    SourceType.NFC: "nfc",
    SourceType.PIN: "pin",
    SourceType.SELFIE_GPS: "geolocation",
    SourceType.GEOLOCATION: "geolocation",
    SourceType.MANUAL: "manual",
}

# EventType do FaceClock -> direction esperado por GenericPayload no ERP.
_DIRECTION_MAP: dict[str, str] = {
    "ENTRY": "in",
    "BREAK_END": "in",
    "EXIT": "out",
    "BREAK_START": "out",
}


def _enum_value(value: Any) -> str:
    return value.value if hasattr(value, "value") else str(value)


def build_clock_event_payload(
    *,
    user_id: UUID,
    employee_code: str,
    device_code: str | None,
    event_type: EventType,
    recorded_at: Any,
    source: SourceType,
) -> dict[str, Any]:
    """GenericPayload (snake_case) para envio via `/api/hardware/events/generic`."""
    event_type_str = _enum_value(event_type)
    return {
        "device_serial": device_code or "faceclock",
        "employee_no": employee_code,
        "event_time": recorded_at.isoformat() if hasattr(recorded_at, "isoformat") else str(recorded_at),
        "event_type": event_type_str,
        "direction": _DIRECTION_MAP.get(event_type_str, "unknown"),
        "credential_type": _CREDENTIAL_TYPE_MAP.get(source, "unknown"),
        "metadata": {"erp_user_id": str(user_id)},
    }


async def send_clock_event_to_erp(payload: dict[str, Any]) -> dict[str, Any]:
    """Envia um evento de ponto para o ERP e regista métricas.

    Levanta `ERPUnavailableError` em caso de indisponibilidade do ERP para que
    o chamador decida se aceita perder o evento ou mantém em fila temporária.
    """
    start = time.perf_counter()
    try:
        result = await erp_client.send_attendance_event(payload)
        erp_sync_metrics.record_success((time.perf_counter() - start) * 1000)
        return {"success": True, "erp_response": result}
    except ERPUnavailableError as exc:
        erp_sync_metrics.record_failure((time.perf_counter() - start) * 1000)
        logger.warning("Falha ao enviar evento de ponto para o ERP: %s", exc)
        raise
    except Exception as exc:  # noqa: BLE001
        erp_sync_metrics.record_failure((time.perf_counter() - start) * 1000)
        logger.exception("Erro inesperado ao enviar evento de ponto para o ERP")
        raise ERPUnavailableError(str(exc)) from exc
