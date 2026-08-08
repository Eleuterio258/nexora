package tech.e258tech.nexora_assiduidade.utils

import tech.e258tech.nexora_assiduidade.data.model.ClockRegisterRequest
import tech.e258tech.nexora_assiduidade.data.model.GenericHardwareEventRequest

/**
 * Traduz um `ClockRegisterRequest` (contrato antigo do FaceClock) para o
 * `GenericPayload` que o Nexora ERP espera em
 * `POST /api/hardware/events/generic` — substitui `build_clock_event_payload`
 * do FaceClock (removido em 2026-07-13, ver
 * assiduidade_system_backend/app/services/erp_attendance_forwarder.py no
 * histórico).
 *
 * O `employee_no` deixa de ser resolvido via `GET /api/hardware/assiduidade/funcionarios`
 * (autenticado pela API Key de device partilhada no APK). A app já o guarda
 * na sessão cifrada (`SessionManager.getEmployeeCode()`) aquando do login,
 * por isso basta recuperá-lo localmente.
 */
object HardwareEventMapper {

    private const val DEVICE_SERIAL = "nexora-assiduidade-mobile"

    private val directionByEventType = mapOf(
        "ENTRY" to "entry",
        "BREAK_END" to "entry",
        "EXIT" to "exit",
        "BREAK_START" to "exit"
    )

    private val credentialTypeBySource = mapOf(
        "FACIAL" to "face",
        "FINGERPRINT" to "fingerprint",
        "QR_CODE" to "qr",
        "NFC" to "nfc",
        "PIN" to "pin",
        "SELFIE_GPS" to "geolocation",
        "GEOLOCATION" to "geolocation",
        "MANUAL" to "manual"
    )

    fun resolveEmployeeCode(sessionManager: SessionManager): String? {
        return sessionManager.getEmployeeCode()
    }

    fun toGenericHardwareEvent(request: ClockRegisterRequest, employeeCode: String): GenericHardwareEventRequest {
        return GenericHardwareEventRequest(
            device_serial = DEVICE_SERIAL,
            employee_no = employeeCode,
            event_time = request.recorded_at,
            event_type = request.event_type,
            direction = directionByEventType[request.event_type] ?: "unknown",
            credential_type = credentialTypeBySource[request.source] ?: "unknown",
            qr_token_id = request.qr_token_id,
            latitude = request.geo_lat,
            longitude = request.geo_lng,
            localidade_id = request.localidade_id,
            registered_by = request.registered_by,
            foto_url = null // Base64 não é URL; upload de imagem fica para melhoria futura
        )
    }
}
