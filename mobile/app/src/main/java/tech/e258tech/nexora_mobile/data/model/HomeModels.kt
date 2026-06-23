package tech.e258tech.nexora_mobile.data.model

import com.google.gson.annotations.SerializedName

data class HomeResponse(
    @SerializedName("saldo_ferias")      val saldoFerias: SaldoFerias,
    @SerializedName("assiduidade_mes")   val assiduidadeMes: ResumoMes,
    @SerializedName("pedidos_pendentes") val pedidosPendentes: Int,
    val notificacoes: List<Notificacao>,
    val comunicados: List<Comunicado>,
    val aniversarios: List<Aniversario>
)

data class SaldoFerias(
    @SerializedName("dias_atribuidos")  val diasAtribuidos: Double,
    @SerializedName("dias_usados")      val diasUsados: Double,
    @SerializedName("dias_disponiveis") val diasDisponiveis: Double
)

data class ResumoMes(
    @SerializedName("dias_trabalhados") val diasTrabalhados: Int,
    @SerializedName("horas_totais")     val horasTotais: Double,
    val atrasos: Int,
    val faltas: Int
)

data class Notificacao(
    val id: Long,
    val tipo: String,
    val titulo: String,
    val corpo: String?,
    val link: String?,
    @SerializedName("created_at") val criadoEm: String
)

data class Comunicado(
    val id: Long,
    val titulo: String,
    @SerializedName("created_at") val criadoEm: String,
    val lido: Boolean
)

data class Aniversario(
    val nome: String,
    val dia: Int,
    val mes: Int
)
