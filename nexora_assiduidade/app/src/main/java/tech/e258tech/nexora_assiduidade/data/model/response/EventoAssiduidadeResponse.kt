package tech.e258tech.nexora_assiduidade.data.model.response

/**
 * Um evento independente de assiduidade (modelo novo), tal como devolvido por
 * GET /api/rh/funcionarios/{id}/eventos no Nexora ERP
 * (`ListarEventosFuncionario`, backend/internal/modules/recursos-humanos/handlers/eventos_assiduidade.go).
 * Substitui gradualmente PresencaResponse (modelo antigo, 1 registo/dia) —
 * aqui cada marcação (entrada, saída, intervalo, etc.) é uma linha própria.
 */
data class EventoAssiduidadeResponse(
    val id: Long,
    val tipo_evento_codigo: String,
    val tipo_evento_nome: String,
    val metodo_codigo: String?,
    val ocorrido_em: String,
    val data_referencia: String,
    val origem: String,
    val estado: String,
    val latitude: Double?,
    val longitude: Double?,
    val dentro_geofence: Boolean?,
    val motivo: String?,
    val observacoes: String?
)
