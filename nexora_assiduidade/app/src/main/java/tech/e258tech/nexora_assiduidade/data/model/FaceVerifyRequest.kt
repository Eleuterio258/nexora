package tech.e258tech.nexora_assiduidade.data.model

/**
 * Payload de POST /api/self-service/assiduidade/biometria/facial/verificar
 * (ERP). Sem `user_id`: o ERP resolve a identidade a partir do próprio
 * Authorization, nunca de um campo enviado pela app — evita que um
 * COLABORADOR se verifique como outro utilizador só por enviar um id
 * diferente (mesma protecção já aplicada em POST /clock/register).
 */
data class FaceVerifyRequest(
    val device_id: String,
    val image_base64: String,
    val geo_lat: Double? = null,
    val geo_lng: Double? = null
)
