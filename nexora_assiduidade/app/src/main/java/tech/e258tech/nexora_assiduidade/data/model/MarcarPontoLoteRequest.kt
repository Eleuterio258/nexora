package tech.e258tech.nexora_assiduidade.data.model

/**
 * Marcação por PIN ou impressão digital em
 * `POST /api/self-service/assiduidade/ponto` (MarcarPonto no ERP). O PIN é
 * verificado pelo ERP no mesmo pedido que grava o evento.
 */
data class MarcarPontoSimplesRequest(
    val metodo: String,
    val pin: String? = null,
    val tipo_evento_codigo: String? = null
)

/**
 * Lote de marcações feitas offline para
 * `POST /api/self-service/assiduidade/ponto/batch` (MarcarPontoLote no ERP).
 * Só PIN e impressão digital podem ser sincronizados; a hora do telemóvel é
 * aceite até 72h no passado e o evento fica assinalado como offline.
 */
data class MarcarPontoLoteRequest(
    val eventos: List<MarcacaoOfflineRequest>
)

data class MarcacaoOfflineRequest(
    val idempotency_key: String,
    val metodo: String,
    val ocorrido_em: String,
    val device_id: String,
    val pin: String? = null,
    val tipo_evento_codigo: String? = null,
    val latitude: Double? = null,
    val longitude: Double? = null
)

data class MarcarPontoLoteResponse(
    val resultados: List<ResultadoMarcacaoOffline> = emptyList()
)

data class ResultadoMarcacaoOffline(
    val idempotency_key: String,
    /** "registado", "duplicado" (já sincronizado antes) ou "rejeitado" (definitivo). */
    val estado: String,
    val evento_id: Long? = null,
    val erro: String? = null
) {
    val sincronizado: Boolean get() = estado == "registado" || estado == "duplicado"
}
