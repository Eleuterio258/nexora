package tech.e258tech.nexora_mobile.data.repository

import tech.e258tech.nexora_mobile.data.api.ApiService
import tech.e258tech.nexora_mobile.data.model.*
import tech.e258tech.nexora_mobile.utils.Result
import tech.e258tech.nexora_mobile.utils.safeApiCall

class PerfilRepository(private val api: ApiService) {

    suspend fun getPerfil(): Result<PerfilResponse> =
        safeApiCall { api.getPerfil() }

    suspend fun actualizarPerfil(nome: String?, telefone: String?): Result<Unit> =
        safeApiCall { api.actualizarPerfil(ActualizarPerfilRequest(nome, telefone)) }

    suspend fun alterarSenha(senhaActual: String, senhaNova: String): Result<Unit> =
        safeApiCall { api.alterarSenha(AlterarSenhaRequest(senhaActual, senhaNova)) }

    suspend fun listarDocumentos(): Result<List<DocumentoPessoal>> =
        safeApiCall { api.listarDocumentos() }
}
