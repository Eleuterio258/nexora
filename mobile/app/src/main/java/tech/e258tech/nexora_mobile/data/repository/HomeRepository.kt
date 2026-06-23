package tech.e258tech.nexora_mobile.data.repository

import tech.e258tech.nexora_mobile.data.api.ApiService
import tech.e258tech.nexora_mobile.data.model.HomeResponse
import tech.e258tech.nexora_mobile.utils.Result
import tech.e258tech.nexora_mobile.utils.safeApiCall

class HomeRepository(private val api: ApiService) {

    suspend fun getHome(): Result<HomeResponse> = safeApiCall { api.getHome() }

    suspend fun marcarNotificacaoLida(id: Long): Result<Unit> =
        safeApiCall { api.marcarNotificacaoLida(mapOf("id" to id)) }

    suspend fun marcarComunicadoLido(id: Long): Result<Unit> =
        safeApiCall { api.marcarComunicadoLido(mapOf("id" to id)) }
}
