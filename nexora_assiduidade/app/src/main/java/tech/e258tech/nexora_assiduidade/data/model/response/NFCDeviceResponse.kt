package tech.e258tech.nexora_assiduidade.data.model.response

data class NFCDeviceResponse(
    val valid: Boolean,
    val erp_user_id: Long? = null,
    val funcionario: String? = null,
    val reason: String? = null
)
