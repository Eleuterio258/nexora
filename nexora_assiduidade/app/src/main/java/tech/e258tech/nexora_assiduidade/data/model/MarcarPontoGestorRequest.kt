package tech.e258tech.nexora_assiduidade.data.model

/**
 * Payload de POST /api/rh/eventos — criação de um evento de assiduidade
 * manual feita por um gestor/RH em nome de um funcionário.
 *
 * Por ser um registo manual, o tipo do evento é sempre definido explicitamente
 * pelo utilizador como `entrada` ou `saida`.
 */
data class MarcarPontoGestorRequest(
    val funcionario_id: Long,
    val tipo_evento_codigo: String,
    val metodo_codigo: String = "manual",
    val origem: String = "app",
    val data_referencia: String,
    val ocorrido_em: String,
    val latitude: Double? = null,
    val longitude: Double? = null,
    val observacoes: String? = null
)
