package tech.e258tech.nexora_assiduidade.data.repository

import android.content.Context
import java.io.IOException
import java.util.UUID
import tech.e258tech.nexora_assiduidade.data.local.AppDatabase
import tech.e258tech.nexora_assiduidade.data.local.PendingEventEntity
import tech.e258tech.nexora_assiduidade.data.model.MarcarPontoSimplesRequest
import tech.e258tech.nexora_assiduidade.data.model.response.EventoAssiduidadeResponse
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils
import tech.e258tech.nexora_assiduidade.utils.OfflineEventCrypto
import tech.e258tech.nexora_assiduidade.utils.SessionManager
import tech.e258tech.nexora_assiduidade.work.SyncAttendanceWorker

/**
 * Registo de presenca por PIN e impressao digital.
 *
 * Chama `POST /api/self-service/assiduidade/ponto` com o JWT do colaborador
 * (o ERP verifica o PIN no mesmo pedido que grava o evento). Ate 2026-09-26
 * usava `POST /api/hardware/events/generic` com a API Key de device embutida
 * no APK.
 *
 * Sem conectividade, ou com o servidor indisponivel, a marcacao fica na fila
 * local (Room, campos cifrados) e o [SyncAttendanceWorker] envia-a depois em
 * lote para `POST /api/self-service/assiduidade/ponto/batch`, com a hora real
 * da marcacao (o ERP aceita ate 72h e assinala o evento como offline).
 */
class AttendanceRepository(context: Context) {

    private val appContext = context.applicationContext
    private val erpApiService = RetrofitClient.erpApiService
    private val sessionManager = SessionManager(appContext)
    private val pendingEventDao = AppDatabase.getInstance(appContext).pendingEventDao()

    /** Metodos que podem ser marcados por este repositorio (e sincronizados offline). */
    object Metodo {
        const val PIN = "pin"
        const val FINGERPRINT = "fingerprint"
    }

    sealed class RegisterResult {
        data class Success(val response: EventoAssiduidadeResponse) : RegisterResult()
        data class SavedOffline(val pendingId: Long) : RegisterResult()
        data class Error(val message: String) : RegisterResult()
    }

    /**
     * @param tipoEventoCodigo "entrada", "saida", "intervalo_inicio" ou
     * "intervalo_fim"; null deixa o ERP alternar entrada/saida.
     */
    suspend fun marcarPonto(
        metodo: String,
        pin: String? = null,
        tipoEventoCodigo: String? = null
    ): RegisterResult {
        val token = sessionManager.getToken()
        if (token.isNullOrBlank()) {
            return RegisterResult.Error("Sessao invalida. Faca login novamente.")
        }
        val userId = sessionManager.getUserId()
            ?: return RegisterResult.Error("Sessao invalida. Faca login novamente.")

        // A hora e fixada aqui, antes do pedido: se ficar offline, e esta a
        // hora que o lote envia, nao a da sincronizacao.
        val ocorridoEm = DateTimeUtils.nowForApi()

        return try {
            val response = erpApiService.marcarPontoSimplesSelfService(
                ApiUtils.bearerToken(token),
                MarcarPontoSimplesRequest(metodo = metodo, pin = pin, tipo_evento_codigo = tipoEventoCodigo)
            )
            val body = response.body()
            when {
                response.isSuccessful && body != null -> RegisterResult.Success(body)
                shouldSaveOffline(response.code()) ->
                    saveOffline(userId, metodo, pin, tipoEventoCodigo, ocorridoEm, ApiUtils.errorMessage(response))
                else -> RegisterResult.Error(ApiUtils.errorMessage(response))
            }
        } catch (e: IOException) {
            // Inclui SocketTimeoutException e UnknownHostException.
            saveOffline(userId, metodo, pin, tipoEventoCodigo, ocorridoEm, e.message)
        } catch (e: Exception) {
            RegisterResult.Error(e.message ?: "Erro desconhecido")
        }
    }

    private suspend fun saveOffline(
        userId: String,
        metodo: String,
        pin: String?,
        tipoEventoCodigo: String?,
        ocorridoEm: String,
        errorMessage: String?
    ): RegisterResult {
        val deviceId = sessionManager.getOrCreateDeviceId()
        val idempotencyKey = UUID.randomUUID().toString()
        val entity = PendingEventEntity(
            userId = OfflineEventCrypto.encrypt(userId) ?: userId,
            deviceId = OfflineEventCrypto.encrypt(deviceId) ?: deviceId,
            eventType = OfflineEventCrypto.encrypt(tipoEventoCodigo.orEmpty()) ?: tipoEventoCodigo.orEmpty(),
            recordedAt = OfflineEventCrypto.encrypt(ocorridoEm) ?: ocorridoEm,
            source = OfflineEventCrypto.encrypt(metodo) ?: metodo,
            // Nunca em claro: o ERP so aceita a marcacao depois de verificar
            // este PIN na sincronizacao; a linha e apagada a seguir.
            pin = OfflineEventCrypto.encrypt(pin),
            idempotencyKey = OfflineEventCrypto.encrypt(idempotencyKey) ?: idempotencyKey,
            syncStatus = PendingEventEntity.SyncStatus.PENDING,
            errorMessage = errorMessage
        )
        val id = pendingEventDao.insert(entity)
        SyncAttendanceWorker.scheduleImmediate(appContext)
        return RegisterResult.SavedOffline(id)
    }

    /** So falhas transitorias (timeout, rate limit, 5xx) vao para a fila offline. */
    private fun shouldSaveOffline(code: Int): Boolean {
        return code == 408 || code == 429 || code >= 500
    }
}
