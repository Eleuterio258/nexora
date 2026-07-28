package tech.e258tech.nexora_assiduidade.data.model

import com.google.gson.annotations.SerializedName

/**
 * Consentimento LGPD biométrico activo de um funcionário.
 * GET /api/rh/funcionarios/{id}/consentimento
 */
data class ConsentimentoLGPD(
    val id: Long,
    @SerializedName("funcionario_id")
    val funcionarioId: Long,
    @SerializedName("termo_versao")
    val termoVersao: String,
    @SerializedName("termo_hash")
    val termoHash: String,
    @SerializedName("aceite_em")
    val aceiteEm: String,
    @SerializedName("revogado_em")
    val revogadoEm: String?,
    @SerializedName("created_at")
    val createdAt: String
)

/**
 * Payload para criação/registo de consentimento LGPD biométrico.
 * POST /api/rh/funcionarios/{id}/consentimento
 */
data class ConsentimentoLGPDRequest(
    @SerializedName("termo_versao")
    val termoVersao: String = "v1",
    @SerializedName("termo_hash")
    val termoHash: String = "sha256-termo-v1"
)
