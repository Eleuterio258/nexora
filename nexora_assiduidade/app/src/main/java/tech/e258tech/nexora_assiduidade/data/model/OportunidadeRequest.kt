package tech.e258tech.nexora_assiduidade.data.model

/** Corpo de POST/PUT /api/crm/oportunidades (oportunidades.go:35,
 * `oportunidadeInput`) — nunca inclui `estagio`: a criação assume "novo" no
 * servidor e a actualização nunca o altera (ver ActualizarOportunidade). */
data class OportunidadeRequest(
    val titulo: String,
    val lead_id: Long? = null,
    val cliente_id: Long? = null,
    val valor_estimado: Double? = null,
    val moeda: String? = null,
    val probabilidade: Int? = null,
    val data_fecho_prevista: String? = null,
    val responsavel: String? = null,
    val responsavel_id: Long? = null,
    val descricao: String? = null
)
