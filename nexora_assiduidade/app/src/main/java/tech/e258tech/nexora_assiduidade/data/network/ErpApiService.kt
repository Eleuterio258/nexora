package tech.e258tech.nexora_assiduidade.data.network

import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.Header
import retrofit2.http.POST
import retrofit2.http.Path
import retrofit2.http.Query
import tech.e258tech.nexora_assiduidade.data.model.AdminSetPinRequest
import tech.e258tech.nexora_assiduidade.data.model.Ausencia
import tech.e258tech.nexora_assiduidade.data.model.ChatMessageRequest
import tech.e258tech.nexora_assiduidade.data.model.DispositivoErp
import tech.e258tech.nexora_assiduidade.data.model.ErpLoginRequest
import tech.e258tech.nexora_assiduidade.data.model.FuncionarioDetalhe
import tech.e258tech.nexora_assiduidade.data.model.FuncionarioListResponse
import tech.e258tech.nexora_assiduidade.data.model.GenericHardwareEventRequest
import tech.e258tech.nexora_assiduidade.data.model.JustificacaoRequest
import tech.e258tech.nexora_assiduidade.data.model.PinValidateRequest
import tech.e258tech.nexora_assiduidade.data.model.PresencaOcorrencia
import tech.e258tech.nexora_assiduidade.data.model.QRGenerateDeviceRequest
import tech.e258tech.nexora_assiduidade.data.model.QRValidateDeviceRequest
import tech.e258tech.nexora_assiduidade.data.model.RelatorioRH
import tech.e258tech.nexora_assiduidade.data.model.TotpSetupRequest
import tech.e258tech.nexora_assiduidade.data.model.TotpValidateRequest
import tech.e258tech.nexora_assiduidade.data.model.chat.Conversation
import tech.e258tech.nexora_assiduidade.data.model.response.ChatMessageListResponse
import tech.e258tech.nexora_assiduidade.data.model.response.ChatMessageResponse
import tech.e258tech.nexora_assiduidade.data.model.response.ConversationCreateResponse
import tech.e258tech.nexora_assiduidade.data.model.response.ConversationListResponse
import tech.e258tech.nexora_assiduidade.data.model.response.ErpLoginResponse
import tech.e258tech.nexora_assiduidade.data.model.response.FuncionarioIntegracaoResponse
import tech.e258tech.nexora_assiduidade.data.model.response.GeofenceDeviceResponse
import tech.e258tech.nexora_assiduidade.data.model.response.HardwareEventResponse
import tech.e258tech.nexora_assiduidade.data.model.response.JustificacaoCreateResponse
import tech.e258tech.nexora_assiduidade.data.model.response.JustificacaoResponse
import tech.e258tech.nexora_assiduidade.data.model.response.NFCDeviceResponse
import tech.e258tech.nexora_assiduidade.data.model.response.PresencaResponse
import tech.e258tech.nexora_assiduidade.data.model.response.QRGenerateDeviceResponse
import tech.e258tech.nexora_assiduidade.data.model.response.QRValidateDeviceResponse
import tech.e258tech.nexora_assiduidade.data.model.response.TotpSetupResponse

/**
 * Serviços da API do ERP (Nexora ERP, Go). Rotas reais confirmadas em
 * backend/internal/router/router.go — ver CONTRATO-INTEGRACAO-ERP.md secção 8
 * para o historial de correcções (esta interface tinha vários endpoints
 * especulativos, nunca correspondentes a rotas reais do ERP, corrigidos em
 * 2026-07-12 ao implementar os ecrãs de gestor).
 */
interface ErpApiService {

    // Login (Fase 6 — identidade vem sempre do ERP, ver ErpLoginRequest)
    @POST("api/auth/login")
    suspend fun login(@Body request: ErpLoginRequest): Response<ErpLoginResponse>

    // Login alternativo por PIN/TOTP (authcode.go) — chamado directamente no
    // ERP desde 2026-07-12 (deixou de passar pelo proxy do FaceClock).
    // pin/validate e totp/validate sao publicos no ERP (sem Authorization) —
    // devolvem o mesmo payload de tokens que /api/auth/login.
    @POST("api/authcode/pin/validate")
    suspend fun validatePin(@Body request: PinValidateRequest): Response<ErpLoginResponse>

    @POST("api/authcode/totp/validate")
    suspend fun validateTotp(@Body request: TotpValidateRequest): Response<ErpLoginResponse>

    @POST("api/authcode/totp/setup")
    suspend fun setupTotp(
        @Header("Authorization") token: String,
        @Body request: TotpSetupRequest
    ): Response<TotpSetupResponse>

    @POST("api/authcode/admin/set-pin")
    suspend fun setAdminPin(
        @Header("Authorization") token: String,
        @Body request: AdminSetPinRequest
    ): Response<Unit>

    // Assiduidade do proprio colaborador (self-service/handlers/assiduidade.go)
    // — chamado directamente no ERP desde 2026-07-13 (deixou de passar pelo
    // proxy do FaceClock). Substitui GET clock/me e POST/GET clock/adjustments.
    @GET("api/self-service/assiduidade/")
    suspend fun getMinhaAssiduidade(
        @Header("Authorization") token: String,
        @Query("mes") mes: String? = null,
        @Query("ano") ano: String? = null
    ): Response<List<PresencaResponse>>

    @POST("api/self-service/assiduidade/justificacoes")
    suspend fun criarJustificacao(
        @Header("Authorization") token: String,
        @Body request: JustificacaoRequest
    ): Response<JustificacaoCreateResponse>

    @GET("api/self-service/assiduidade/justificacoes")
    suspend fun getMinhasJustificacoes(
        @Header("Authorization") token: String
    ): Response<List<JustificacaoResponse>>

    // ── Endpoints de device (X-API-Key, nao Authorization) ──────────────────
    // Chamados directamente pela app desde 2026-07-13 com a API Key de device
    // do FaceClock embutida no APK (BuildConfig.DEVICE_API_KEY) — risco de
    // seguranca aceite explicitamente para os metodos alternativos de
    // assiduidade, ver comentario em app/build.gradle.kts.

    @GET("api/hardware/assiduidade/config")
    suspend fun getAttendanceConfigDevice(
        @Header("X-API-Key") apiKey: String
    ): Response<Map<String, Any>>

    @GET("api/hardware/assiduidade/funcionarios")
    suspend fun getFuncionariosDevice(
        @Header("X-API-Key") apiKey: String
    ): Response<List<FuncionarioIntegracaoResponse>>

    @POST("api/hardware/events/generic")
    suspend fun registerEventDevice(
        @Header("X-API-Key") apiKey: String,
        @Body request: GenericHardwareEventRequest
    ): Response<HardwareEventResponse>

    @POST("api/hardware/assiduidade/qr/gerar")
    suspend fun generateQrDevice(
        @Header("X-API-Key") apiKey: String,
        @Body request: QRGenerateDeviceRequest
    ): Response<QRGenerateDeviceResponse>

    @POST("api/hardware/assiduidade/qr/validar")
    suspend fun validateQrDevice(
        @Header("X-API-Key") apiKey: String,
        @Body request: QRValidateDeviceRequest
    ): Response<QRValidateDeviceResponse>

    @GET("api/hardware/assiduidade/nfc/validar")
    suspend fun validateNfcDevice(
        @Header("X-API-Key") apiKey: String,
        @Query("tag_uid") tagUid: String
    ): Response<NFCDeviceResponse>

    @GET("api/hardware/assiduidade/geofence/validar")
    suspend fun validateGeofenceDevice(
        @Header("X-API-Key") apiKey: String,
        @Query("unidade_id") unidadeId: String,
        @Query("latitude") latitude: Double,
        @Query("longitude") longitude: Double
    ): Response<GeofenceDeviceResponse>

    // Equipa — lista de funcionários (rh.go:157, ListarFuncionarios)
    @GET("api/rh/funcionarios")
    suspend fun getFuncionarios(
        @Header("Authorization") token: String,
        @Query("page") page: Int = 1,
        @Query("limit") limit: Int = 50,
        @Query("unit_id") unitId: Long? = null,
        @Query("estado") estado: String? = null,
        @Query("q") q: String? = null
    ): Response<FuncionarioListResponse>

    // Equipa — detalhe do funcionário (rh.go:360, ObterFuncionario)
    @GET("api/rh/funcionarios/{id}")
    suspend fun getFuncionarioDetalhe(
        @Header("Authorization") token: String,
        @Path("id") funcionarioId: Long
    ): Response<FuncionarioDetalhe>

    // Pedidos de férias/ausências (rh.go:1090, ListarAusencias)
    @GET("api/rh/ausencias")
    suspend fun getAusencias(
        @Header("Authorization") token: String,
        @Query("funcionario_id") funcionarioId: Long? = null,
        @Query("estado") estado: String? = null
    ): Response<List<Ausencia>>

    @POST("api/rh/ausencias/{id}/aprovar")
    suspend fun aprovarAusencia(
        @Header("Authorization") token: String,
        @Path("id") ausenciaId: Long
    ): Response<Unit>

    @POST("api/rh/ausencias/{id}/rejeitar")
    suspend fun rejeitarAusencia(
        @Header("Authorization") token: String,
        @Path("id") ausenciaId: Long
    ): Response<Unit>

    // Dispositivos — cadastro real dos leitores biométricos (hardware/handlers/devices.go)
    @GET("api/hardware/devices")
    suspend fun getDispositivos(
        @Header("Authorization") token: String
    ): Response<List<DispositivoErp>>

    // Ocorrências/Alertas — presenças (atraso/falta) cross-equipa (rh/handlers/presencas.go)
    @GET("api/rh/presencas")
    suspend fun getPresencasPorTipo(
        @Header("Authorization") token: String,
        @Query("tipo") tipo: String? = null,
        @Query("data_inicio") dataInicio: String? = null,
        @Query("data_fim") dataFim: String? = null,
        @Query("unit_id") unitId: Long? = null
    ): Response<List<PresencaOcorrencia>>

    // Relatórios agregados de RH (única fonte — o FaceClock não expõe mais relatórios)
    @GET("api/rh/relatorios")
    suspend fun getRelatorioRH(
        @Header("Authorization") token: String
    ): Response<RelatorioRH>

    // Chat — conversas
    @GET("chat/conversas")
    suspend fun getConversas(
        @Header("Authorization") token: String
    ): Response<ConversationListResponse>

    @POST("chat/conversas")
    suspend fun createConversa(
        @Header("Authorization") token: String,
        @Body request: Conversation
    ): Response<ConversationCreateResponse>

    // Chat — mensagens
    @GET("chat/conversas/{id}/mensagens")
    suspend fun getChatMessages(
        @Header("Authorization") token: String,
        @Path("id") conversaId: String
    ): Response<ChatMessageListResponse>

    @POST("chat/conversas/{id}/mensagens")
    suspend fun sendChatMessage(
        @Header("Authorization") token: String,
        @Path("id") conversaId: String,
        @Body request: ChatMessageRequest
    ): Response<ChatMessageResponse>
}
