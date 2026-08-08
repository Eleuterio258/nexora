package tech.e258tech.nexora_assiduidade.data.model

/**
 * Payload de POST /api/rh/assiduidade/ponto — marcação manual de ponto por um
 * gestor/RH em nome de um funcionário.
 *
 * O ERP infere entrada/saída automaticamente quando [tipo_evento_codigo] é
 * omitido (ou vazio), com base na paridade dos eventos do dia.
 */
data class MarcarPontoGestorAssiduidadeRequest(
    val funcionario_id: Long,
    val data: String,
    val hora: String? = null,
    val tipo_evento_codigo: String? = null,
    val latitude: Double? = null,
    val longitude: Double? = null,
    val observacoes: String? = null
)
