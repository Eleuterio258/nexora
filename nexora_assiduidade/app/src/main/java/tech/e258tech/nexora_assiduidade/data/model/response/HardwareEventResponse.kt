package tech.e258tech.nexora_assiduidade.data.model.response

/**
 * POST /api/hardware/events/generic no Nexora ERP (`ReceberEventoGenerico`)
 * — autenticado por API Key de device.
 */
data class HardwareEventResponse(
    val id: Long,
    val processed: Boolean,
    val presenca_id: Long? = null,
    val attendance_id: Long? = null,
    val error: String? = null
)
