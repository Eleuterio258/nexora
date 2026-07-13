package tech.e258tech.nexora_assiduidade.data.model.response

/**
 * GET /api/hardware/assiduidade/funcionarios no Nexora ERP
 * (`ListarFuncionariosIntegracao`) — autenticado por API Key de device.
 */
data class FuncionarioIntegracaoResponse(
    val id: Long,
    val employee_code: String,
    val full_name: String,
    val email: String?,
    val role: String,
    val is_active: Boolean,
    val tenant_id: Long
)
