package tech.e258tech.nexora_assiduidade.data.model

/**
 * POST /api/self-service/assiduidade/justificacoes no Nexora ERP
 * (`CriarJustificacao`). `tipo` deve ser "falta" ou "atraso" — qualquer outro
 * valor cai para "falta" do lado do ERP.
 */
data class JustificacaoRequest(
    val tipo: String,
    val data: String,
    val motivo: String,
    val ficheiro_url: String? = null
)
