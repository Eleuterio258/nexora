package tech.e258tech.nexora_mobile.data.model

import com.google.gson.annotations.SerializedName

data class PerfilResponse(
    @SerializedName("user_id")         val userId: Long,
    val nome: String,
    val email: String,
    val telefone: String?,
    @SerializedName("funcionario_id")  val funcionarioId: Long?,
    @SerializedName("nome_completo")   val nomeCompleto: String?,
    val cargo: String?,
    val departamento: String?,
    @SerializedName("data_admissao")   val dataAdmissao: String?,
    @SerializedName("tipo_contrato")   val tipoContrato: String?,
    @SerializedName("ultimo_login_em") val ultimoLoginEm: String?
)

data class ActualizarPerfilRequest(
    val nome: String? = null,
    val telefone: String? = null
)

data class AlterarSenhaRequest(
    @SerializedName("senha_actual") val senhaActual: String,
    @SerializedName("senha_nova")   val senhaNova: String
)

data class DocumentoPessoal(
    val id: Long,
    val tipo: String,
    val nome: String,
    val url: String,
    @SerializedName("created_at") val criadoEm: String
)
