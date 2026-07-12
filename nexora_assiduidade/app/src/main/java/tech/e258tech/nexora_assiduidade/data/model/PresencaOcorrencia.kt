package tech.e258tech.nexora_assiduidade.data.model

/**
 * GET /api/rh/presencas (ERP, Go) — ver
 * backend/internal/modules/recursos-humanos/handlers/presencas.go
 * (`ListarPresencasPorTipo`). Alimenta o ecrã de Ocorrências/Alertas do
 * gestor (atrasos/faltas cross-equipa, não só de um funcionário).
 */
data class PresencaOcorrencia(
    val id: Long,
    val funcionario_id: Long,
    val funcionario_nome: String,
    val unit_id: Long?,
    val unidade_nome: String?,
    val data: String,
    val hora_entrada: String?,
    val hora_saida: String?,
    val tipo: String?, // "presente", "atraso", "falta", "saida_antecipada"
    val observacoes: String?
)
