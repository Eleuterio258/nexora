package tech.e258tech.nexora_assiduidade.data.model.response

data class GeoValidateResponse(
    val valid: Boolean,
    val source: String,
    val distance_meters: Double? = null,
    val message: String? = null
)
