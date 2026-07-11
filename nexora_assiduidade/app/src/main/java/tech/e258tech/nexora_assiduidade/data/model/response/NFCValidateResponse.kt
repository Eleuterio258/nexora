package tech.e258tech.nexora_assiduidade.data.model.response

data class NFCValidateResponse(
    val valid: Boolean,
    val source: String,
    val user_id: String? = null,
    val message: String? = null
)
