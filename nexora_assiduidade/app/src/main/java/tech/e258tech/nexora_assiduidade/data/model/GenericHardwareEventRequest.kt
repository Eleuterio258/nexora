package tech.e258tech.nexora_assiduidade.data.model

/**
 * POST /api/hardware/events/generic no Nexora ERP (`GenericPayload`,
 * backend/internal/modules/hardware/adapters/generic_rest.go) — autenticado
 * por API Key de device. Substitui `build_clock_event_payload` do FaceClock
 * (removido em 2026-07-13, a app monta este payload agora).
 */
data class GenericHardwareEventRequest(
    val device_serial: String,
    val employee_no: String,
    val event_time: String,
    val event_type: String,
    val direction: String,
    val credential_type: String
)
