package tech.e258tech.nexora_mobile.data.api

import retrofit2.Response
import retrofit2.http.*
import tech.e258tech.nexora_mobile.data.model.*

interface ApiService {

    // ── Auth ──────────────────────────────────────────────────────────────────

    @POST("api/auth/login")
    suspend fun login(@Body request: LoginRequest): Response<LoginResponse>

    @POST("api/auth/refresh")
    suspend fun refresh(@Body request: RefreshRequest): Response<RefreshResponse>

    @POST("api/auth/logout")
    suspend fun logout(): Response<Unit>

    /** Permissões actuais do utilizador autenticado (sempre frescos da BD). */
    @GET("api/auth/me/acesso")
    suspend fun getMeuAcesso(): Response<MeuAcessoResponse>

    // ── Self-Service: Home ────────────────────────────────────────────────────

    @GET("api/self-service/home")
    suspend fun getHome(): Response<HomeResponse>

    @POST("api/self-service/notificacoes/lida")
    suspend fun marcarNotificacaoLida(@Body body: Map<String, Long>): Response<Unit>

    @POST("api/self-service/comunicados/lido")
    suspend fun marcarComunicadoLido(@Body body: Map<String, Long>): Response<Unit>

    // ── Self-Service: Férias ──────────────────────────────────────────────────

    @GET("api/pedido-ferias/")
    suspend fun listarPedidosFerias(): Response<List<PedidoFerias>>

    @GET("api/pedido-ferias/tipos")
    suspend fun listarTiposAusencia(): Response<List<TipoAusencia>>

    @POST("api/pedido-ferias/")
    suspend fun criarPedidoFerias(@Body request: CriarPedidoFeriasRequest): Response<CriarPedidoFeriasResponse>

    @POST("api/pedido-ferias/{id}/cancelar")
    suspend fun cancelarPedidoFerias(@Path("id") id: Long): Response<Unit>

    // ── Self-Service: Assiduidade ─────────────────────────────────────────────

    @GET("api/self-service/assiduidade/")
    suspend fun listarAssiduidade(
        @Query("mes") mes: String? = null,
        @Query("ano") ano: String? = null
    ): Response<List<RegistoPresenca>>

    @GET("api/self-service/assiduidade/resumo")
    suspend fun getResumoAssiduidade(
        @Query("mes") mes: String? = null,
        @Query("ano") ano: String? = null
    ): Response<ResumoAssiduidadeResponse>

    @GET("api/self-service/assiduidade/justificacoes")
    suspend fun listarJustificacoes(): Response<List<Justificacao>>

    @POST("api/self-service/assiduidade/justificacoes")
    suspend fun criarJustificacao(@Body request: CriarJustificacaoRequest): Response<CriarJustificacaoResponse>

    // ── Self-Service: Perfil ──────────────────────────────────────────────────

    @GET("api/self-service/perfil/")
    suspend fun getPerfil(): Response<PerfilResponse>

    @PUT("api/self-service/perfil/")
    suspend fun actualizarPerfil(@Body request: ActualizarPerfilRequest): Response<Unit>

    @POST("api/self-service/perfil/senha")
    suspend fun alterarSenha(@Body request: AlterarSenhaRequest): Response<Unit>

    @GET("api/self-service/perfil/documentos")
    suspend fun listarDocumentos(): Response<List<DocumentoPessoal>>

    // ── Chat (REST — histórico) ───────────────────────────────────────────────

    @GET("api/self-service/chat/conversas")
    suspend fun listarConversas(): Response<List<Conversa>>

    @POST("api/self-service/chat/conversas")
    suspend fun criarConversa(@Body request: CriarConversaRequest): Response<CriarConversaResponse>

    @GET("api/self-service/chat/conversas/{id}/mensagens")
    suspend fun listarMensagens(@Path("id") conversaId: Long): Response<List<Mensagem>>

    @POST("api/self-service/chat/conversas/{id}/mensagens")
    suspend fun enviarMensagem(
        @Path("id") conversaId: Long,
        @Body request: EnviarMensagemRequest
    ): Response<Map<String, Long>>
}
