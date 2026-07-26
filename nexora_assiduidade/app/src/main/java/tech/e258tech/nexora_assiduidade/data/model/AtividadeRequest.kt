package tech.e258tech.nexora_assiduidade.data.model

/** Corpo de POST/PUT /api/crm/atividades (atividades.go:29, `atividadeInput`)
 * — na criação, exactamente um de lead_id/oportunidade_id tem de vir
 * preenchido (validado pelo backend e também client-side antes do pedido). */
data class AtividadeRequest(
    val lead_id: Long? = null,
    val oportunidade_id: Long? = null,
    val tipo: String? = null,
    val titulo: String,
    val descricao: String? = null,
    val data_atividade: String? = null,
    val responsavel: String? = null
)
