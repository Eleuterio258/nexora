package tech.e258tech.nexora_assiduidade.data.model.response

/**
 * GET /api/rh/justificacoes (ERP, Go) — ver
 * backend/internal/modules/recursos-humanos/handlers/justificacoes.go
 * (ListarJustificacoesPendentes). Visão de gestor, cross-equipa, diferente de
 * [tech.e258tech.nexora_assiduidade.data.model.response.JustificacaoResponse]
 * (self-service, só as próprias).
 */
data class JustificacaoPendenteResponse(
    val id: Long,
    val funcionario_id: Long,
    val funcionario_nome: String,
    val tipo: String,
    val data: String,
    val motivo: String,
    val ficheiro_url: String?,
    val created_at: String
)
