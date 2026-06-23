package tech.e258tech.nexora_mobile.data.repository

import tech.e258tech.nexora_mobile.data.api.ApiService
import tech.e258tech.nexora_mobile.data.model.*
import tech.e258tech.nexora_mobile.utils.Result
import tech.e258tech.nexora_mobile.utils.safeApiCall

class FeriasRepository(private val api: ApiService) {

    suspend fun listarPedidos(): Result<List<PedidoFerias>> =
        safeApiCall { api.listarPedidosFerias() }

    suspend fun listarTipos(): Result<List<TipoAusencia>> =
        safeApiCall { api.listarTiposAusencia() }

    suspend fun criarPedido(
        tipoId: Long,
        dataInicio: String,
        dataFim: String,
        motivo: String?
    ): Result<CriarPedidoFeriasResponse> = safeApiCall {
        api.criarPedidoFerias(CriarPedidoFeriasRequest(tipoId, dataInicio, dataFim, motivo))
    }

    suspend fun cancelarPedido(id: Long): Result<Unit> =
        safeApiCall { api.cancelarPedidoFerias(id) }
}
