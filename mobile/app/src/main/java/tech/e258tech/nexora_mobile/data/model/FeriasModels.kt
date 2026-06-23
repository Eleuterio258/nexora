package tech.e258tech.nexora_mobile.data.model

import com.google.gson.annotations.SerializedName

data class TipoAusencia(
    val id: Long,
    val nome: String,
    @SerializedName("dias_anuais") val diasAnuais: Double?,
    val remunerada: Boolean,
    @SerializedName("afeta_saldo") val afetaSaldo: Boolean
)

data class PedidoFerias(
    val id: Long,
    @SerializedName("tipo_nome")   val tipoNome: String?,
    @SerializedName("data_inicio") val dataInicio: String,
    @SerializedName("data_fim")    val dataFim: String,
    val dias: Int?,
    val motivo: String?,
    val estado: String,           // pendente | aprovado | rejeitado | cancelado
    @SerializedName("criado_em")  val criadoEm: String
)

data class CriarPedidoFeriasRequest(
    @SerializedName("tipo_id")     val tipoId: Long,
    @SerializedName("data_inicio") val dataInicio: String,
    @SerializedName("data_fim")    val dataFim: String,
    val motivo: String? = null
)

data class CriarPedidoFeriasResponse(
    val id: Long
)
