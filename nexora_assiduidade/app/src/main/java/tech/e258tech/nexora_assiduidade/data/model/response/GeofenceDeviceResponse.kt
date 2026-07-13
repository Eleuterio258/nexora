package tech.e258tech.nexora_assiduidade.data.model.response

data class GeofenceDeviceResponse(
    val valid: Boolean,
    val unit_name: String? = null,
    val distance_meters: Double? = null,
    val radius_meters: Double? = null,
    val reason: String? = null
)
