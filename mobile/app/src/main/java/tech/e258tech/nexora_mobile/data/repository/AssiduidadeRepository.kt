package tech.e258tech.nexora_mobile.data.repository

import tech.e258tech.nexora_mobile.data.api.ApiService
import tech.e258tech.nexora_mobile.data.model.*
import tech.e258tech.nexora_mobile.utils.Result
import tech.e258tech.nexora_mobile.utils.safeApiCall

class AssiduidadeRepository(private val api: ApiService) {

    suspend fun listarRegistos(mes: String? = null, ano: String? = null): Result<List<RegistoPresenca>> =
        safeApiCall { api.listarAssiduidade(mes, ano) }

    suspend fun getResumo(mes: String? = null, ano: String? = null): Result<ResumoAssiduidadeResponse> =
        safeApiCall { api.getResumoAssiduidade(mes, ano) }

    suspend fun listarJustificacoes(): Result<List<Justificacao>> =
        safeApiCall { api.listarJustificacoes() }

    suspend fun criarJustificacao(
        tipo: String,
        data: String,
        motivo: String,
        ficheiroUrl: String? = null
    ): Result<CriarJustificacaoResponse> = safeApiCall {
        api.criarJustificacao(CriarJustificacaoRequest(tipo, data, motivo, ficheiroUrl))
    }
}
