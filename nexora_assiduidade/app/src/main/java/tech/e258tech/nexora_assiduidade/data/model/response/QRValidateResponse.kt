package tech.e258tech.nexora_assiduidade.data.model.response

data class QRValidateResponse(
    val valid: Boolean,
    val source: String,
    val payload: Map<String, Any>? = null,
    val message: String? = null
)
