package tech.e258tech.nexora_assiduidade.data.model

data class GeoValidateRequest(
    val latitude: Double,
    val longitude: Double,
    val unit_id: String? = null,
    val radius_meters: Double = 100.0
)
