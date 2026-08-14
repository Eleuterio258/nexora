package tech.e258tech.paycore.api

import retrofit2.Response
import retrofit2.http.*

interface ApiService {

    // ── Auth ─────────────────────────────────────────────────────────────────
    // Login do terminal (aparelho) continua usando pos/login.
    // Login do funcionário passa a usar auth/login do ERP.

    @POST("pos/login")
    suspend fun posLogin(@Body request: PosLoginRequest): Response<PosLoginResponse>

    @POST("pos/refresh")
    suspend fun posRefresh(@Body request: PosRefreshRequest): Response<PosLoginResponse>

    // Login do funcionário (ERP)
    @POST("auth/login")
    suspend fun authLogin(@Body request: AuthLoginRequest): Response<AuthLoginResponse>

    // Refresh do token do funcionário (ERP)
    @POST("auth/refresh")
    suspend fun authRefresh(@Body request: Map<String, String>): Response<AuthLoginResponse>

    // Recuperação de senha — envia email com link de reset
    @POST("auth/forgot-password")
    suspend fun forgotPassword(@Body request: ForgotPasswordRequest): Response<Unit>

    // Validação pública de chave de licença do app POS (antes do login)
    @POST("pos/licenca/validar")
    suspend fun validarLicencaApp(@Body request: ValidarLicencaRequest): Response<ValidarLicencaResponse>

    // Troca rápida de operador por PIN, dentro do tenant de quem chama
    // (tipicamente o terminal ou o funcionário cuja sessão ainda está em cache
    // — ver PinLoginActivity). Não mexe na sessão/token de quem chama.
    @POST("pos/login-operador")
    suspend fun loginOperadorPorPin(@Body request: PinOperadorRequest): Response<AuthLoginResponse>

    @POST("auth/logout")
    suspend fun logout(): Response<Unit>

    @GET("auth/me")
    suspend fun me(): Response<UserDTO>

    @GET("auth/me/acesso")
    suspend fun meAcesso(): Response<AcessoResponse>

    @GET("auth/utilizadores")
    suspend fun getUsers(): Response<List<UserDTO>>

    @POST("auth/utilizadores")
    suspend fun createUser(@Body request: UserUpsertRequest): Response<UserDTO>

    @PUT("auth/utilizadores/{id}")
    suspend fun updateUser(@Path("id") id: Long, @Body request: UserUpsertRequest): Response<UserDTO>

    // ERP não tem DELETE de utilizador, só desativação (soft, como o resto do ERP)
    @POST("auth/utilizadores/{id}/desactivar")
    suspend fun desactivarUser(@Path("id") id: Long): Response<Unit>

    // ── Catalogue (gestao-produtos) ───────────────────────────────────────────

    @GET("produtos/categorias")
    suspend fun getCategorias(): Response<List<CategoriaDTO>>

    // CriarCategoria só devolve {"id":...} — ver IdResponse.
    @POST("produtos/categorias")
    suspend fun createCategoria(
        @Body request: CategoriaUpsertRequest
    ): Response<IdResponse>

    @PUT("produtos/categorias/{id}")
    suspend fun updateCategoria(
        @Path("id") id: Long,
        @Body request: CategoriaUpsertRequest
    ): Response<Unit>

    @DELETE("produtos/categorias/{id}")
    suspend fun deleteCategoria(
        @Path("id") id: Long
    ): Response<Unit>

    @GET("produtos")
    suspend fun getProdutos(): Response<List<ProdutoDTO>>

    // CriarProduto só devolve {"id":...} — ver IdResponse.
    @POST("produtos")
    suspend fun createProduto(
        @Body request: ProdutoUpsertRequest
    ): Response<IdResponse>

    // ActualizarProduto devolve 204 sem corpo — não tentar desserializar um DTO.
    @PUT("produtos/{id}")
    suspend fun updateProduto(
        @Path("id") id: Long,
        @Body request: ProdutoUpsertRequest
    ): Response<Unit>

    // Preço vive em produtos.product_prices, não em produtos.products — é um
    // recurso à parte do produto (DefinirPrecoSeguro em catalogo_ext.go).
    @POST("produtos/{id}/precos")
    suspend fun definirPreco(
        @Path("id") id: Long,
        @Body request: DefinirPrecoRequest
    ): Response<IdResponse>

    // Idem para barcode — produtos.product_barcodes (AdicionarCodigoBarras).
    @POST("produtos/{id}/codigos-barras")
    suspend fun adicionarCodigoBarras(
        @Path("id") id: Long,
        @Body request: AdicionarCodigoBarrasRequest
    ): Response<IdResponse>

    // ERP não tem DELETE de produto, só desativação
    @POST("produtos/{id}/desactivar")
    suspend fun desactivarProduto(
        @Path("id") id: Long
    ): Response<Unit>

    // ── Terminais (módulo pos) ────────────────────────────────────────────────

    @GET("pos/terminais")
    suspend fun listTerminals(): Response<List<TerminalDTO>>

    // CriarTerminal só devolve {"id":...} — os outros campos do TerminalDTO
    // (nome/codigo/model/activationCode) ficam null na resposta; o repository
    // já usa os valores locais como fallback (ver AdminApiRepository.createTerminal).
    @POST("pos/terminais")
    suspend fun createTerminal(
        @Body request: CreateTerminalRequest
    ): Response<TerminalDTO>

    @POST("pos/terminais/{id}/activar")
    suspend fun activateTerminal(@Path("id") id: Long): Response<TerminalDTO>

    @POST("pos/terminais/{id}/desactivar")
    suspend fun deactivateTerminal(@Path("id") id: Long): Response<TerminalDTO>

    // ── Caixa (pos.sessoes) ───────────────────────────────────────────────────

    @GET("pos/sessoes")
    suspend fun getCashDrawers(
        @Query("status") status: String? = null,
        @Query("terminalId") terminalId: String? = null,
        @Query("limit") limit: Int = 100
    ): Response<List<CashDrawerDTO>>

    @POST("pos/sessoes")
    suspend fun abrirSessao(@Body request: AbrirSessaoRequest): Response<CashDrawerDTO>

    @GET("pos/sessoes/atual")
    suspend fun obterSessaoAtual(): Response<CashDrawerDTO>

    @POST("pos/sessoes/{id}/fechar")
    suspend fun fecharSessao(
        @Path("id") id: Long,
        @Body request: FecharSessaoRequest
    ): Response<FecharSessaoResponse>

    // Suprimento/sangria/depósito — só fazem sentido com a sessão aberta.
    @POST("pos/sessoes/{id}/movimentacoes")
    suspend fun registarMovimentoCaixa(
        @Path("id") id: Long,
        @Body request: MovimentoCaixaRequest
    ): Response<IdResponse>

    @GET("pos/sessoes/{id}/movimentacoes")
    suspend fun listarMovimentosCaixa(@Path("id") id: Long): Response<List<MovimentoCaixaDTO>>

    // ── Descontos (entidade POS autónoma, pos_discounts) ──────────────────────

    @GET("pos/descontos")
    suspend fun getDiscounts(@Query("active") active: Boolean? = null): Response<List<DiscountDTO>>

    @POST("pos/descontos")
    suspend fun createDiscount(@Body request: DiscountUpsertRequest): Response<DiscountDTO>

    @PUT("pos/descontos/{id}")
    suspend fun updateDiscount(
        @Path("id") id: Long,
        @Body request: DiscountUpsertRequest
    ): Response<DiscountDTO>

    @DELETE("pos/descontos/{id}")
    suspend fun deleteDiscount(@Path("id") id: Long): Response<Unit>

    // ── Sync incremental de catálogo (produtos/categorias) ────────────────────
    // "since": millis do último sync bem-sucedido (0 = catálogo completo).
    // Paginar enquanto has_more=true, usando next_cursor como próximo "since".

    @GET("pos/sync/download")
    suspend fun syncDownload(
        @Query("since")    since: Long,
        @Query("types")    types: String = "produtos,categorias"
    ): Response<SyncDownloadResponse>

    // ── Vendas (pos.sales) ─────────────────────────────────────────────────────

    @POST("pos/sales")
    suspend fun criarTransacao(
        @Body request: CriarVendaRequest
    ): Response<TransacaoResponse>

    // "id" é o id numérico do servidor (pos_sales.id), não a referência local
    // do Room — só faz sentido chamar depois da venda estar sincronizada
    // (ver PosStore.estornarTransacaoSelecionada/sincronizarEstornosPendentes).
    @POST("pos/sales/{id}/cancelar")
    suspend fun estornarTransacao(
        @Path("id")       id: Long,
        @Body request: EstornoRequest
    ): Response<TransacaoResponse>

    @GET("pos/sales/{id}")
    suspend fun obterVenda(@Path("id") id: Long): Response<VendaDetalheResponse>

    @POST("pos/sales/{id}/estorno-parcial")
    suspend fun estornoParcialVenda(
        @Path("id") id: Long,
        @Body request: EstornoParcialRequest
    ): Response<EstornoParcialResponse>

    // Dados completos para (re)impressão de recibo — ver ObterRecibo no
    // backend. Ao contrário de obterVenda, inclui o cabeçalho fiscal da
    // empresa e funciona a partir de qualquer terminal, não só do que criou
    // a venda.
    @GET("pos/sales/{id}/recibo")
    suspend fun obterRecibo(@Path("id") id: Long): Response<ReciboResponse>

    // "q" procura por número do documento, client_reference ou referência de
    // pagamento (ex.: ID de transação Mobile Money) — ver ListarVendas.
    @GET("pos/sales")
    suspend fun getTransacoes(
        @Query("limit")      limit: Int = 100,
        @Query("status")     estado: String? = null,
        @Query("q")          busca: String? = null
    ): Response<VendasListResponse>

    // ── Relatórios POS ───────────────────────────────────────────────────────

    @GET("pos/relatorios/vendas")
    suspend fun relatorioVendas(
        @Query("agrupar_por") agruparPor: String = "dia",
        @Query("from") from: String? = null,
        @Query("to") to: String? = null
    ): Response<RelatorioVendasResponse>

    @GET("pos/relatorios/top-produtos")
    suspend fun relatorioTopProdutos(
        @Query("from") from: String? = null,
        @Query("to") to: String? = null,
        @Query("limit") limit: Int = 10
    ): Response<RelatorioTopProdutosResponse>

    @GET("pos/relatorios/cancelamentos")
    suspend fun relatorioCancelamentos(
        @Query("from") from: String? = null,
        @Query("to") to: String? = null
    ): Response<RelatorioCancelamentosResponse>

    @GET("pos/relatorios/fecho-caixa")
    suspend fun relatorioFechoCaixa(
        @Query("from") from: String? = null,
        @Query("to") to: String? = null
    ): Response<RelatorioFechoCaixaResponse>

    @GET("pos/relatorios/terminais")
    suspend fun relatorioTerminais(): Response<List<RelatorioTerminalDTO>>

    // ── Tenant (superadmin) ────────────────────────────────────────────────────

    @GET("superadmin/tenants/{id}")
    suspend fun getTenant(@Path("id") tenantId: String): Response<TenantDTO>

    // ── Push token ──────────────────────────────────────────────────────────
    // Endpoint existe no backend, mas a app não tem cliente FCM nenhum ainda
    // — nunca é chamado. Ver docs/backend-go-gaps-paycore.md §3.7.

    @POST("auth/push-token")
    suspend fun registerPushToken(@Body request: PushTokenRequest): Response<Unit>

    // Envia um push a todos os dispositivos registados do tenant — exige
    // notificacoes:gerir_notificacoes (tipicamente gestão/admin).
    @POST("notificacoes/broadcast")
    suspend fun broadcastPush(@Body request: BroadcastPushRequest): Response<BroadcastPushResponse>
}
