package tech.e258tech.nexora_mobile.data.model

import com.google.gson.annotations.SerializedName

data class RegistoPresenca(
    val id: Long,
    val data: String,
    @SerializedName("hora_entrada")       val horaEntrada: String?,
    @SerializedName("hora_saida")         val horaSaida: String?,
    @SerializedName("horas_trabalhadas")  val horasTrabalhadas: Double?,
    val tipo: String,                     // presente | atraso | falta | saida_antecipada
    val latitude: Double?,
    val longitude: Double?,
    val observacao: String?
)

data class ResumoAssiduidadeResponse(
    val mes: String,
    val ano: String,
    @SerializedName("dias_trabalhados") val diasTrabalhados: Int,
    @SerializedName("horas_totais")     val horasTotais: Double,
    val atrasos: Int,
    val faltas: Int,
    @SerializedName("horas_extra")      val horasExtra: Int
)

data class Justificacao(
    val id: Long,
    val tipo: String,   // falta | atraso
    val data: String,
    val motivo: String,
    val estado: String, // pendente | aprovado | rejeitado
    @SerializedName("created_at") val criadoEm: String
)

data class CriarJustificacaoRequest(
    val tipo: String,
    val data: String,
    val motivo: String,
    @SerializedName("ficheiro_url") val ficheiroUrl: String? = null
)

data class CriarJustificacaoResponse(
    val id: Long
)
