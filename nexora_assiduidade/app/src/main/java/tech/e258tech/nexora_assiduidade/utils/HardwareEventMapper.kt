package tech.e258tech.nexora_assiduidade.utils

import tech.e258tech.nexora_assiduidade.BuildConfig
import tech.e258tech.nexora_assiduidade.data.model.ClockRegisterRequest
import tech.e258tech.nexora_assiduidade.data.model.GenericHardwareEventRequest
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient

/**
 * Traduz um `ClockRegisterRequest` (contrato antigo do FaceClock) para o
 * `GenericPayload` que o Nexora ERP espera em
 * `POST /api/hardware/events/generic` — substitui `build_clock_event_payload`
 * do FaceClock (removido em 2026-07-13, ver
 * assiduidade_system_backend/app/services/erp_attendance_forwarder.py no
 * histórico).
 *
 * Resolve tambem o `employee_no` (numero_funcionario do ERP) a partir do
 * email da sessao — a app so guarda o `auth.users.id` numerico e o email
 * apos login, nao o numero de funcionario, por isso e preciso ir busca-lo a
 * `GET /api/hardware/assiduidade/funcionarios` (mesma pesquisa que
 * `_resolve_employee` fazia no FaceClock).
 */
object HardwareEventMapper {

    private const val DEVICE_SERIAL = "nexora-assiduidade-mobile"

    private val directionByEventType = mapOf(
        "ENTRY" to "in",
        "BREAK_END" to "in",
        "EXIT" to "out",
        "BREAK_START" to "out"
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

    suspend fun resolveEmployeeCode(sessionManager: SessionManager): String? {
        val email = sessionManager.getUserEmail() ?: return null
        val response = RetrofitClient.erpApiService.getFuncionariosDevice(BuildConfig.DEVICE_API_KEY)
        if (!response.isSuccessful) return null
        return response.body()
            ?.firstOrNull { it.email?.equals(email, ignoreCase = true) == true }
            ?.employee_code
    }

    /**
     * Resolve o employee_code de um funcionário específico pelo seu
     * `rh.funcionarios.id` — usado no registo manual do gestor (por conta de
     * outro colaborador, não de si próprio, por isso não dá para resolver
     * por email da sessão).
     */
    suspend fun resolveEmployeeCodeById(funcionarioId: Long): String? {
        val response = RetrofitClient.erpApiService.getFuncionariosDevice(BuildConfig.DEVICE_API_KEY)
        if (!response.isSuccessful) return null
        return response.body()?.firstOrNull { it.id == funcionarioId }?.employee_code
    }

    fun toGenericHardwareEvent(request: ClockRegisterRequest, employeeCode: String): GenericHardwareEventRequest {
        return GenericHardwareEventRequest(
            device_serial = DEVICE_SERIAL,
            employee_no = employeeCode,
            event_time = request.recorded_at,
            event_type = request.event_type,
            direction = directionByEventType[request.event_type] ?: "unknown",
            credential_type = credentialTypeBySource[request.source] ?: "unknown"
        )
    }
}
