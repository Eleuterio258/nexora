package tech.e258tech.nexora_assiduidade.data.network

import retrofit2.Call
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.DELETE
import retrofit2.http.Field
import retrofit2.http.FormUrlEncoded
import retrofit2.http.GET
import retrofit2.http.Header
import retrofit2.http.POST
import retrofit2.http.PUT
import retrofit2.http.Path
import retrofit2.http.Query
import tech.e258tech.nexora_assiduidade.data.model.AdminSetPinRequest
import tech.e258tech.nexora_assiduidade.data.model.AssiduidadeConfigRequest
import tech.e258tech.nexora_assiduidade.data.model.AgendaItem
import tech.e258tech.nexora_assiduidade.data.model.CaptureImage
import tech.e258tech.nexora_assiduidade.data.model.EnrollFacialRequest
import tech.e258tech.nexora_assiduidade.data.model.AgendaItemRequest
import tech.e258tech.nexora_assiduidade.data.model.Atividade
import tech.e258tech.nexora_assiduidade.data.model.AtividadeListResponse
import tech.e258tech.nexora_assiduidade.data.model.AtividadeRequest
import tech.e258tech.nexora_assiduidade.data.model.Ausencia
import tech.e258tech.nexora_assiduidade.data.model.ChatMessageRequest
import tech.e258tech.nexora_assiduidade.data.model.DispositivoErp
import tech.e258tech.nexora_assiduidade.data.model.FuncionarioDetalhe
import tech.e258tech.nexora_assiduidade.data.model.FuncionarioListResponse
import tech.e258tech.nexora_assiduidade.data.model.GenericHardwareEventRequest
import tech.e258tech.nexora_assiduidade.data.model.JustificacaoRequest
import tech.e258tech.nexora_assiduidade.data.model.Lead
import tech.e258tech.nexora_assiduidade.data.model.LeadConverterRequest
import tech.e258tech.nexora_assiduidade.data.model.LeadEstadoRequest
import tech.e258tech.nexora_assiduidade.data.model.LeadListResponse
import tech.e258tech.nexora_assiduidade.data.model.LeadRequest
import tech.e258tech.nexora_assiduidade.data.model.Notification
import tech.e258tech.nexora_assiduidade.data.model.Oportunidade
import tech.e258tech.nexora_assiduidade.data.model.OportunidadeEstagioRequest
import tech.e258tech.nexora_assiduidade.data.model.OportunidadeListResponse
import tech.e258tech.nexora_assiduidade.data.model.OportunidadePerderRequest
import tech.e258tech.nexora_assiduidade.data.model.OportunidadeRequest
import tech.e258tech.nexora_assiduidade.data.model.PinValidateRequest
import tech.e258tech.nexora_assiduidade.data.model.PresencaOcorrencia
import tech.e258tech.nexora_assiduidade.data.model.QRGenerateDeviceRequest
import tech.e258tech.nexora_assiduidade.data.model.QRValidateDeviceRequest
import tech.e258tech.nexora_assiduidade.data.model.RelatorioRH
import tech.e258tech.nexora_assiduidade.data.model.TotpSetupRequest
import tech.e258tech.nexora_assiduidade.data.model.TotpValidateRequest
import tech.e258tech.nexora_assiduidade.data.model.chat.Conversation
import tech.e258tech.nexora_assiduidade.utils.Constants
import tech.e258tech.nexora_assiduidade.data.model.response.AssiduidadeConfigResponse
import tech.e258tech.nexora_assiduidade.data.model.response.AtividadeCreateResponse
import tech.e258tech.nexora_assiduidade.data.model.response.EnrollFacialResponse
import tech.e258tech.nexora_assiduidade.data.model.response.ChatMessageListResponse
import tech.e258tech.nexora_assiduidade.data.model.response.ChatMessageResponse
import tech.e258tech.nexora_assiduidade.data.model.response.ConversationCreateResponse
import tech.e258tech.nexora_assiduidade.data.model.response.ConversationListResponse
import tech.e258tech.nexora_assiduidade.data.model.response.ErpAcessoResponse
import tech.e258tech.nexora_assiduidade.data.model.response.ErpLoginResponse
import tech.e258tech.nexora_assiduidade.data.model.response.ErpMeResponse
import tech.e258tech.nexora_assiduidade.data.model.response.OAuthTokenResponse
import tech.e258tech.nexora_assiduidade.data.model.response.EventoAssiduidadeResponse
import tech.e258tech.nexora_assiduidade.data.model.response.FuncionarioIntegracaoResponse
import tech.e258tech.nexora_assiduidade.data.model.response.GeofenceDeviceResponse
import tech.e258tech.nexora_assiduidade.data.model.response.HardwareEventResponse
import tech.e258tech.nexora_assiduidade.data.model.response.JustificacaoCreateResponse
import tech.e258tech.nexora_assiduidade.data.model.response.JustificacaoResponse
import tech.e258tech.nexora_assiduidade.data.model.response.LeadConverterResponse
import tech.e258tech.nexora_assiduidade.data.model.response.LeadCreateResponse
import tech.e258tech.nexora_assiduidade.data.model.response.NFCDeviceResponse
import tech.e258tech.nexora_assiduidade.data.model.response.OkResponse
import tech.e258tech.nexora_assiduidade.data.model.response.OportunidadeCreateResponse
import tech.e258tech.nexora_assiduidade.data.model.response.PresencaResponse
import tech.e258tech.nexora_assiduidade.data.model.response.QRGenerateDeviceResponse
import tech.e258tech.nexora_assiduidade.data.model.response.QRValidateDeviceResponse
import tech.e258tech.nexora_assiduidade.data.model.response.ResultadoDiarioResponse
import tech.e258tech.nexora_assiduidade.data.model.response.TotpSetupResponse

/**
 * Serviços da API do ERP (Nexora ERP, Go). Rotas reais confirmadas em
 * backend/internal/router/router.go — ver CONTRATO-INTEGRACAO-ERP.md secção 8
 * para o historial de correcções (esta interface tinha vários endpoints
 * especulativos, nunca correspondentes a rotas reais do ERP, corrigidos em
 * 2026-07-12 ao implementar os ecrãs de gestor).
 */
interface ErpApiService {

    // Login — Authorization Server OAuth2 do ERP (grant_type=password,
    // client_id=android-app, cliente público sem client_secret; ver
    // oauth_token.go). Substitui o antigo POST /api/auth/login: a resposta já
    // não traz `user`/`modulos`, por isso o login busca a identidade à parte
    // via getMe() e getMeuAcesso() (ver LoginActivity.performLogin).
    @FormUrlEncoded
    @POST("oauth/token")
    suspend fun oauthLogin(
        @Field("username") username: String,
        @Field("password") password: String,
        @Field("grant_type") grantType: String = "password",
        @Field("client_id") clientId: String = Constants.OAUTH_CLIENT_ID
    ): Response<OAuthTokenResponse>

    // Identidade do utilizador autenticado (auth.go:630) — só usada depois
    // do login via /oauth/token para obter id/nome/email (ver OAuthTokenResponse).
    @GET("api/auth/me")
    suspend fun getMe(@Header("Authorization") token: String): Response<ErpMeResponse>

    // Permissões RBAC em tempo real do utilizador autenticado (permissoes.go:14,
    // ObterAcessoUtilizador → models.LoadUserAccess) — chamado logo após o
    // login para obter `modulos` correcto mesmo que o login em produção
    // devolva esse campo desactualizado/vazio, ver ErpAcessoResponse.
    @GET("api/auth/me/acesso")
    suspend fun getMeuAcesso(@Header("Authorization") token: String): Response<ErpAcessoResponse>

    // Renovação de sessão — grant_type=refresh_token no Authorization Server
    // (substitui POST /api/auth/refresh). Versão síncrona (Call, não suspend)
    // porque é invocada a partir de AuthAuthenticator, que corre fora de uma
    // coroutine (callback OkHttp numa thread de background). O ERP RODA o
    // refresh_token a cada uso — a resposta traz sempre um novo, que tem de
    // ser persistido (ver AuthAuthenticator), nunca reutilizar o anterior.
    @FormUrlEncoded
    @POST("oauth/token")
    fun oauthRefreshSync(
        @Field("refresh_token") refreshToken: String,
        @Field("grant_type") grantType: String = "refresh_token",
        @Field("client_id") clientId: String = Constants.OAUTH_CLIENT_ID
    ): Call<OAuthTokenResponse>

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

    // QR Code pessoal do próprio colaborador (assiduidade_qr.go:GerarQRMe) —
    // autenticado por sessão (Authorization), nunca pela API Key de device,
    // porque o ERP precisa de saber QUEM está a pedir para vincular o token
    // ao funcionário certo.
    @GET("api/self-service/assiduidade/qr/me")
    suspend fun getMyQr(
        @Header("Authorization") token: String
    ): Response<QRGenerateDeviceResponse>

    // QR Code fixo do gestor (assiduidade_qr.go:GerarQRDevice) — exige a
    // permissão "recursos-humanos:ver_funcionarios" (a mesma que já esconde
    // este botão no menu da app de quem não é gestor), por isso corre
    // autenticado por sessão, nunca pela API Key de device partilhada.
    @POST("api/rh/assiduidade/qr/gerar")
    suspend fun generateQr(
        @Header("Authorization") token: String,
        @Body request: QRGenerateDeviceRequest
    ): Response<QRGenerateDeviceResponse>

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

    // Notificações do próprio utilizador (utilizadores/handlers/notificacoes.go)
    @GET("api/utilizadores/{userId}/notifications")
    suspend fun getNotifications(
        @Header("Authorization") token: String,
        @Path("userId") userId: String,
        @Query("lida") lida: Boolean? = null,
        @Query("limit") limit: Int = 50,
        @Query("offset") offset: Int = 0
    ): Response<List<Notification>>

    @POST("api/utilizadores/{userId}/notifications/{notificationId}/read")
    suspend fun markNotificationRead(
        @Header("Authorization") token: String,
        @Path("userId") userId: String,
        @Path("notificationId") notificationId: Long
    ): Response<Unit>

    @POST("api/utilizadores/{userId}/notifications/read-all")
    suspend fun markAllNotificationsRead(
        @Header("Authorization") token: String,
        @Path("userId") userId: String
    ): Response<Unit>

    // Agenda pessoal do próprio utilizador (utilizadores/handlers/agenda.go)
    @GET("api/utilizadores/{userId}/agenda")
    suspend fun getAgenda(
        @Header("Authorization") token: String,
        @Path("userId") userId: String,
        @Query("desde") desde: String? = null,
        @Query("ate") ate: String? = null
    ): Response<List<AgendaItem>>

    @POST("api/utilizadores/{userId}/agenda")
    suspend fun criarItemAgenda(
        @Header("Authorization") token: String,
        @Path("userId") userId: String,
        @Body request: AgendaItemRequest
    ): Response<Map<String, Long>>

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

    // Assiduidade (modelo novo) de um funcionário — eventos_assiduidade.go:
    // ListarEventosFuncionario / resultados_assiduidade.go:ListarResultadosFuncionario.
    // Sem data_inicio/data_fim, o ERP defaulta aos últimos 30 dias.
    @GET("api/rh/funcionarios/{id}/eventos")
    suspend fun getEventosFuncionario(
        @Header("Authorization") token: String,
        @Path("id") funcionarioId: Long,
        @Query("data_inicio") dataInicio: String? = null,
        @Query("data_fim") dataFim: String? = null
    ): Response<List<EventoAssiduidadeResponse>>

    @GET("api/rh/funcionarios/{id}/resultados")
    suspend fun getResultadosFuncionario(
        @Header("Authorization") token: String,
        @Path("id") funcionarioId: Long,
        @Query("data_inicio") dataInicio: String? = null,
        @Query("data_fim") dataFim: String? = null
    ): Response<List<ResultadoDiarioResponse>>

    // Enrollment facial de um funcionário, feito por gestor RH.
    // O ERP faz proxy para o FaceClock após validar consentimento LGPD e configuração do tenant.
    @POST("api/rh/funcionarios/{id}/biometria/facial/enroll")
    suspend fun enrollFacialFuncionario(
        @Header("Authorization") token: String,
        @Path("id") funcionarioId: Long,
        @Body request: EnrollFacialRequest
    ): Response<EnrollFacialResponse>

    // Configuração dos métodos de assiduidade activos para o tenant
    // (sistema-configuracao/handlers/assiduidade.go). GET exige
    // sistema-configuracao.ver_configuracoes, PUT exige editar_configuracoes.
    @GET("api/system/configuracao/tenant/feature/rh.assiduidade")
    suspend fun getConfigAssiduidade(
        @Header("Authorization") token: String
    ): Response<AssiduidadeConfigResponse>

    @PUT("api/system/configuracao/tenant/feature/rh.assiduidade")
    suspend fun guardarConfigAssiduidade(
        @Header("Authorization") token: String,
        @Body request: AssiduidadeConfigRequest
    ): Response<Unit>

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

    // ── CRM — Leads (crm/handlers/leads.go) ─────────────────────────────────
    @GET("api/crm/leads")
    suspend fun getLeads(
        @Header("Authorization") token: String,
        @Query("estado") estado: String? = null,
        @Query("origem") origem: String? = null,
        @Query("search") search: String? = null,
        @Query("page") page: Int = 1,
        @Query("limit") limit: Int = 20
    ): Response<LeadListResponse>

    @GET("api/crm/leads/{id}")
    suspend fun getLead(
        @Header("Authorization") token: String,
        @Path("id") id: Long
    ): Response<Lead>

    @POST("api/crm/leads")
    suspend fun criarLead(
        @Header("Authorization") token: String,
        @Body request: LeadRequest
    ): Response<LeadCreateResponse>

    @PUT("api/crm/leads/{id}")
    suspend fun actualizarLead(
        @Header("Authorization") token: String,
        @Path("id") id: Long,
        @Body request: LeadRequest
    ): Response<Unit>

    @PUT("api/crm/leads/{id}/estado")
    suspend fun moverLead(
        @Header("Authorization") token: String,
        @Path("id") id: Long,
        @Body request: LeadEstadoRequest
    ): Response<OkResponse>

    @POST("api/crm/leads/{id}/converter")
    suspend fun converterLead(
        @Header("Authorization") token: String,
        @Path("id") id: Long,
        @Body request: LeadConverterRequest
    ): Response<LeadConverterResponse>

    @DELETE("api/crm/leads/{id}")
    suspend fun eliminarLead(
        @Header("Authorization") token: String,
        @Path("id") id: Long
    ): Response<Unit>

    // ── CRM — Oportunidades (crm/handlers/oportunidades.go) ─────────────────
    @GET("api/crm/oportunidades")
    suspend fun getOportunidades(
        @Header("Authorization") token: String,
        @Query("estagio") estagio: String? = null,
        @Query("lead_id") leadId: Long? = null,
        @Query("cliente_id") clienteId: Long? = null,
        @Query("search") search: String? = null,
        @Query("page") page: Int = 1,
        @Query("limit") limit: Int = 20
    ): Response<OportunidadeListResponse>

    @GET("api/crm/oportunidades/{id}")
    suspend fun getOportunidade(
        @Header("Authorization") token: String,
        @Path("id") id: Long
    ): Response<Oportunidade>

    @POST("api/crm/oportunidades")
    suspend fun criarOportunidade(
        @Header("Authorization") token: String,
        @Body request: OportunidadeRequest
    ): Response<OportunidadeCreateResponse>

    @PUT("api/crm/oportunidades/{id}")
    suspend fun actualizarOportunidade(
        @Header("Authorization") token: String,
        @Path("id") id: Long,
        @Body request: OportunidadeRequest
    ): Response<Unit>

    @PUT("api/crm/oportunidades/{id}/estagio")
    suspend fun moverOportunidade(
        @Header("Authorization") token: String,
        @Path("id") id: Long,
        @Body request: OportunidadeEstagioRequest
    ): Response<OkResponse>

    @POST("api/crm/oportunidades/{id}/perder")
    suspend fun marcarOportunidadePerdida(
        @Header("Authorization") token: String,
        @Path("id") id: Long,
        @Body request: OportunidadePerderRequest
    ): Response<OkResponse>

    @DELETE("api/crm/oportunidades/{id}")
    suspend fun eliminarOportunidade(
        @Header("Authorization") token: String,
        @Path("id") id: Long
    ): Response<Unit>

    // ── CRM — Atividades (crm/handlers/atividades.go) ───────────────────────
    @GET("api/crm/atividades")
    suspend fun getAtividades(
        @Header("Authorization") token: String,
        @Query("lead_id") leadId: Long? = null,
        @Query("oportunidade_id") oportunidadeId: Long? = null,
        @Query("tipo") tipo: String? = null,
        @Query("concluida") concluida: Boolean? = null,
        @Query("search") search: String? = null,
        @Query("page") page: Int = 1,
        @Query("limit") limit: Int = 50
    ): Response<AtividadeListResponse>

    @GET("api/crm/atividades/{id}")
    suspend fun getAtividade(
        @Header("Authorization") token: String,
        @Path("id") id: Long
    ): Response<Atividade>

    @POST("api/crm/atividades")
    suspend fun criarAtividade(
        @Header("Authorization") token: String,
        @Body request: AtividadeRequest
    ): Response<AtividadeCreateResponse>

    @PUT("api/crm/atividades/{id}")
    suspend fun actualizarAtividade(
        @Header("Authorization") token: String,
        @Path("id") id: Long,
        @Body request: AtividadeRequest
    ): Response<Unit>

    @POST("api/crm/atividades/{id}/concluir")
    suspend fun concluirAtividade(
        @Header("Authorization") token: String,
        @Path("id") id: Long
    ): Response<OkResponse>

    @DELETE("api/crm/atividades/{id}")
    suspend fun eliminarAtividade(
        @Header("Authorization") token: String,
        @Path("id") id: Long
    ): Response<Unit>

    // Chat — conversas
    // O chat vive no grupo /api/self-service do ERP (ver router.go, r.Route
    // "/api/self-service" -> r.Route "/chat"), não na raiz: sem o prefixo estes
    // quatro pedidos davam 404 e o ecrã de chat ficava sempre vazio, apesar de
    // o WebSocket (/ws/chat) ligar bem e dar a impressão de estar tudo a
    // funcionar.
    @GET("api/self-service/chat/conversas")
    suspend fun getConversas(
        @Header("Authorization") token: String
    ): Response<ConversationListResponse>

    @POST("api/self-service/chat/conversas")
    suspend fun createConversa(
        @Header("Authorization") token: String,
        @Body request: Conversation
    ): Response<ConversationCreateResponse>

    // Chat — mensagens
    @GET("api/self-service/chat/conversas/{id}/mensagens")
    suspend fun getChatMessages(
        @Header("Authorization") token: String,
        @Path("id") conversaId: String
    ): Response<ChatMessageListResponse>

    @POST("api/self-service/chat/conversas/{id}/mensagens")
    suspend fun sendChatMessage(
        @Header("Authorization") token: String,
        @Path("id") conversaId: String,
        @Body request: ChatMessageRequest
    ): Response<ChatMessageResponse>
}
