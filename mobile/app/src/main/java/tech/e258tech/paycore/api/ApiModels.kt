package tech.e258tech.paycore.api

import com.google.gson.annotations.SerializedName

// ─────────────────────────────────────────────
// Auth — login único (utilizador + terminal)
//
// Um só endpoint (POST pos/login) para os dois momentos de login que já
// existem na UX: o operador (tipo=utilizador, a cada turno) e o terminal
// (tipo=terminal, uma vez, na configuração do aparelho). O terminal é
// autenticado no backend como uma conta comum (auth.users + cargo "Terminal
// POS"), por isso a resposta reaproveita o mesmo envelope de tokens.
// ─────────────────────────────────────────────

object Permissoes {
    const val MODULO_POS = "pos"

    const val OPERAR_POS = "operar_pos"
    const val SUPERVISIONAR_POS = "supervisionar_pos"
    const val GERIR_TERMINAIS = "gerir_terminais"
    const val GERIR_CATALOGO = "gerir_catalogo"
    const val GERIR_DESCONTOS = "gerir_descontos"
    const val RELATORIOS = "relatorios"
    const val VER_VENDAS = "ver_vendas"

    // Gestão de utilizadores vive no módulo "autorizacao" do ERP
    // (POST/GET /api/auth/utilizadores exige autorizacao:gerir_utilizadores).
    const val MODULO_AUTORIZACAO = "autorizacao"
    const val GERIR_UTILIZADORES = "gerir_utilizadores"

    // Catálogo/inventário do lado do ERP. O módulo "produtos" do backend usa
    // acções do stock: ver_stock (listar), gerir_produtos (criar/editar),
    // gerir_categorias (categorias) — NÃO pos:gerir_catalogo (esse é o catálogo
    // POS, /api/pos/catalogo).
    const val MODULO_STOCK = "stock"
    const val VER_STOCK = "ver_stock"
    const val GERIR_PRODUTOS = "gerir_produtos"
    const val GERIR_CATEGORIAS = "gerir_categorias"

    // Broadcast push — POST /api/notificacoes/broadcast.
    const val MODULO_NOTIFICACOES = "notificacoes"
    const val GERIR_NOTIFICACOES = "gerir_notificacoes"
}

data class PosLoginRequest(
    val tipo: String, // "utilizador" | "terminal"
    val email: String? = null,
    val password: String? = null,
    @SerializedName("tenant_slug") val tenantSlug: String? = null,
    @SerializedName("codigo_terminal") val codigoTerminal: String? = null,
    @SerializedName("activation_code") val activationCode: String? = null
)

data class PosRefreshRequest(
    val tipo: String, // "utilizador" | "terminal"
    @SerializedName("refresh_token") val refreshToken: String? = null,
    @SerializedName("terminal_token") val terminalToken: String? = null
)

// Nomes de campo em snake_case porque é isso que o handler Go devolve
// literalmente (issueFuncionarioTokens/issueTerminalTokens em
// internal/modules/auth/handlers) — não é o mesmo formato do antigo backend
// Node (que usava camelCase).
data class PosLoginResponse(
    val tipo: String? = null,
    // ramo utilizador
    @SerializedName("access_token") val accessToken: String? = null,
    @SerializedName("refresh_token") val refreshToken: String? = null,
    val user: UserDTO? = null,
    val tenant: TenantInfo? = null,
    // ramo terminal
    @SerializedName("terminal_token") val terminalToken: String? = null,
    @SerializedName("terminal_refresh_token") val terminalRefreshToken: String? = null,
    val terminal: TerminalInfo? = null,
    @SerializedName("expires_in") val expiresIn: Int = 0,
    // 2FA pendente (ramo utilizador) — não implementado no ramo POS ainda
    val requires2FA: Boolean = false,
    val tempToken: String? = null,
    val twoFactorMethod: String? = null
) {
    // Alias para compatibilidade com LoginActivity
    val twoFactorRequired: Boolean get() = requires2FA
}

// ─────────────────────────────────────────────
// Auth — login do funcionário (endpoint ERP /api/auth/login)
//
// Separado do login do terminal. Devolve accessToken/refreshToken do
// funcionário, que são usados nas chamadas ERP subsequentes.
// ─────────────────────────────────────────────

data class AuthLoginRequest(
    val email: String,
    val password: String
)

data class ForgotPasswordRequest(val email: String)

data class ValidarLicencaRequest(val chave: String)

data class ValidarLicencaResponse(
    val valida: Boolean = false,
    val motivo: String? = null,
    val plano: String? = null,
    val status: String? = null,
    @SerializedName("expira_em") val expiraEm: String? = null,
    @SerializedName("tenant_id") val tenantId: Long? = null,
    @SerializedName("tenant_nome") val tenantNome: String? = null,
    @SerializedName("tenant_slug") val tenantSlug: String? = null
)

// POST pos/login-operador (troca rápida de operador por PIN, ver
// LoginOperadorPorPIN no backend) — devolve o mesmo shape de AuthLoginResponse
// porque o backend reaproveita issueFuncionarioTokens, tal como auth/login.
data class PinOperadorRequest(val pin: String)

data class AuthLoginResponse(
    val user: UserDTO? = null,
    val tenant: TenantInfo? = null,
    @SerializedName("access_token") val accessToken: String? = null,
    @SerializedName("refresh_token") val refreshToken: String? = null,
    @SerializedName("requires_2fa") val requires2FA: Boolean = false,
    @SerializedName("temp_token") val tempToken: String? = null,
    @SerializedName("two_factor_method") val twoFactorMethod: String? = null,
    @SerializedName("partial_user") val partialUser: UserDTO? = null,
    @SerializedName("modulos") val modulosRaw: List<ModuloAcessoDTO> = emptyList()
) {
    val twoFactorRequired: Boolean get() = requires2FA

    /** Converte o array de módulos/acções no mapa usado por PosStore. */
    val modulos: Map<String, List<String>>
        get() = modulosRaw.associate { it.modulo to it.acoes }
}

// O ERP (GET /api/auth/me/acesso → handler ObterAcessoUtilizador) devolve o
// objecto UserAccess cru, em que `modulos` é um ARRAY de objectos:
//   {"modulos":[{"modulo":"pos","cor":"#EF4444","acoes":["operar_pos",...]}], ...}
// — e NÃO um mapa. Desserializar directamente para Map<String,List<String>>
// fazia o Gson lançar JsonSyntaxException; como a chamada está dentro de um
// runCatching{}.getOrNull(), o erro era engolido e o funcionário ficava sem
// nenhuma permissão. Mapeamos o array para o Map que o resto da app espera.
data class ModuloAcessoDTO(
    val modulo: String = "",
    val cor: String? = null,
    val acoes: List<String> = emptyList()
)

data class AcessoResponse(
    @SerializedName("modulos") val modulosRaw: List<ModuloAcessoDTO> = emptyList()
) {
    /** Converte o array do ERP no mapa modulo→acções usado por PosStore. */
    val modulos: Map<String, List<String>>
        get() = modulosRaw.associate { it.modulo to it.acoes }
}

data class TenantInfo(
    val id: Long,
    val name: String,
    val slug: String
)

// Vários endpoints de criação (categoria, produto, terminal) só devolvem
// {"id": ...} no corpo — não o registo completo. Ver comentários em cada
// handler Go (CriarProduto/CriarCategoria/CriarTerminal): só fazem
// `jsonOK(w, map[string]any{"id": id}, http.StatusCreated)`. Desserializar
// a resposta directamente para o DTO completo (como o código fazia antes)
// deixa todos os outros campos null, mesmo os não-anuláveis em Kotlin — o
// Gson não respeita null-safety em tempo de execução.
data class IdResponse(val id: Long)

// id é Long porque o ERP usa bigserial (auth.users.id), não UUID/string como
// o antigo backend Node — atenção ao converter para SharedPreferences (String).
data class UserDTO(
    val id: Long,
    val email: String,
    @SerializedName(value = "name", alternate = ["nome"]) val name: String,
    val role: String? = null,
    val twoFactorEnabled: Boolean = false,
    val active: Boolean? = null,
    val phoneNumber: String? = null
)

data class UserUpsertRequest(
    val email: String,
    val name: String,
    val password: String? = null,
    val role: String? = null,
    val active: Boolean = true,
    val phoneNumber: String? = null
)

// Endpoint ainda não existe no backend para utilizadores ERP — o serviço
// internal/push já aceita user_id genérico, só falta o endpoint HTTP (item 6).
data class PushTokenRequest(
    val token: String,
    val platform: String = "android"
)

data class TerminalInfo(
    val id: Long,
    @SerializedName(value = "codigo", alternate = ["serialNumber"]) val codigo: String,
    @SerializedName(value = "nome", alternate = ["name"]) val nome: String,
    val status: String
)

// Espelha pos_sessions (pos.ListarSessoes/ObterSessaoAtual) — não tem opened_by_name nem
// final_amount/initial_amount, esses nomes eram do backend Node antigo.
data class CashDrawerDTO(
    val id: Long,
    @SerializedName("terminal_id") val terminalId: Long,
    @SerializedName("user_id") val userId: Long,
    @SerializedName("opened_at") val openedAt: String? = null,
    @SerializedName("closed_at") val closedAt: String? = null,
    @SerializedName("opening_amount") val openingAmount: Double? = null,
    @SerializedName("closing_amount") val closingAmount: Double? = null,
    val status: String? = null
)

data class AbrirSessaoRequest(
    @SerializedName("terminal_id") val terminalId: Long,
    @SerializedName("opening_amount") val openingAmount: Double
)

data class FecharSessaoRequest(
    @SerializedName("closing_amount") val closingAmount: Double,
    // Obrigatória no backend quando há diferença não-trivial entre o valor
    // contado e o esperado (ver FecharSessao em pos.go) — sem isto, o fecho
    // é rejeitado com 422 em vez de aceitar a diferença em silêncio.
    val justificativa: String? = null,
    // Chave = valor da nota/moeda (ex. "1000", "500"), valor = quantidade.
    // Opcional — se enviada, o backend valida que a soma bate com closing_amount.
    @SerializedName("contagem_notas") val contagemNotas: Map<String, Int>? = null
)

data class FecharSessaoResponse(
    val id: Long = 0,
    @SerializedName("valor_esperado") val valorEsperado: Double,
    val diferenca: Double,
    val status: String? = null,
    // Vendas concluídas da sessão por método de pagamento — informativo, só
    // "numerario" entra no cálculo de valor_esperado (é o único fisicamente
    // contável na gaveta).
    @SerializedName("detalhamento_metodos") val detalhamentoMetodos: Map<String, Double>? = null,
    // Resumo dos movimentos de caixa da sessão (suprimentos/sangrias/depósitos).
    val movimentos: Map<String, Double>? = null
)

// Movimento de caixa (suprimento/sangria/depósito/outro) dentro de uma sessão
// aberta — ver RegistarMovimentoCaixa/ListarMovimentosCaixa em
// pos/handlers/movimentacoes.go. Só suprimento/sangria/depósito entram no
// cálculo automático do valor esperado do fecho; "outro" é só registo.
data class MovimentoCaixaRequest(
    val tipo: String,
    val valor: Double,
    val motivo: String? = null
)

data class MovimentoCaixaDTO(
    val id: Long,
    val tipo: String,
    val valor: Double,
    val motivo: String? = null,
    @SerializedName("created_by") val createdBy: Long? = null,
    @SerializedName("operador_nome") val operadorNome: String? = null,
    @SerializedName("created_at") val createdAt: String? = null
)

// Entidade autónoma de desconto POS ainda não existe no backend (hoje só há
// desconto por produto e por cliente, desligados entre si) — pos/descontos é
// o caminho previsto no plano, pendente de implementação.
data class DiscountDTO(
    val id: Long,
    val name: String,
    val description: String? = null,
    val type: String? = null,
    val value: Double? = null,
    val active: Boolean? = null,
    @SerializedName("min_amount") val minAmount: Double? = null,
    @SerializedName("max_amount") val maxAmount: Double? = null,
    @SerializedName("valid_from") val validFrom: String? = null,
    @SerializedName("valid_until") val validUntil: String? = null
)

data class DiscountUpsertRequest(
    val name: String,
    val description: String? = null,
    val type: String,
    val value: Double,
    @SerializedName("min_amount") val minAmount: Double? = null,
    @SerializedName("max_amount") val maxAmount: Double? = null,
    @SerializedName("valid_from") val validFrom: String? = null,
    @SerializedName("valid_until") val validUntil: String? = null,
    val active: Boolean = true
)

// ─────────────────────────────────────────────
// Tenant
// ─────────────────────────────────────────────

data class TenantDTO(
    val id: Long,
    @SerializedName(value = "nome", alternate = ["name"]) val nome: String,
    val slug: String,
    val status: String
)

data class TerminalDTO(
    val id: Long,
    @SerializedName(value = "nome", alternate = ["name"]) val nome: String? = null,
    // "codigo" é o identificador lógico atribuído pelo admin (pos_terminals.codigo);
    // manter alternate=serial_number só para não perder dados de instalações antigas.
    @SerializedName(value = "codigo", alternate = ["serial_number"]) val codigo: String? = null,
    val status: String? = null,
    val model: String? = null,
    @SerializedName("activation_code") val activationCode: String? = null
)

// Espelha o body exigido por CriarTerminal (pos.go): codigo e nome
// obrigatórios; activation_code também é obrigatório — o backend não gera
// nenhum, só guarda o hash bcrypt do que enviarmos, por isso o código tem de
// ser gerado no cliente (ver AdminApiRepository.createTerminal). "model" não
// existe no schema de pos_terminals — o backend ignora-o silenciosamente.
data class CreateTerminalRequest(
    val codigo: String,
    val nome: String,
    @SerializedName("activation_code") val activationCode: String
)

// ─────────────────────────────────────────────
// Catalogue
// ─────────────────────────────────────────────

data class CategoriaDTO(
    val id: Long,
    @SerializedName(value = "nome", alternate = ["name"]) val nome: String,
    @SerializedName(value = "descricao", alternate = ["description"]) val descricao: String? = null,
    @SerializedName(value = "ordem", alternate = ["order", "order_index"]) val ordem: Int = 0
)

// Espelha o body de CriarCategoria (produtos.go): só "nome" é obrigatório;
// "codigo"/"descricao" são opcionais. Não existe coluna "ordem" nem "ativo"
// em produtos.product_categories — enviá-los não fazia mal (Go ignora campos
// desconhecidos), mas também nunca teve efeito nenhum no servidor.
data class CategoriaUpsertRequest(
    val codigo: String? = null,
    val nome: String,
    val descricao: String? = null
)

data class ProdutoDTO(
    val id: Long,
    // "codigo" é obrigatório para criar/editar (ver ProdutoUpsertRequest) mas
    // só vem preenchido quando o DTO é construído a partir de GET /produtos
    // (a resposta de criação só tem {"id":...} — ver IdResponse).
    val codigo: String? = null,
    @SerializedName(value = "nome", alternate = ["name"]) val nome: String,
    @SerializedName(value = "descricao", alternate = ["description"]) val descricao: String? = null,
    @SerializedName("product_category_id") val categoriaId: Long? = null,
    @SerializedName(value = "categoria_nome", alternate = ["category_name"]) val categoriaNome: String? = null,
    @SerializedName("preco_venda")    val precoVenda: Double? = null,
    @SerializedName(value = "preco", alternate = ["price"]) val preco: Double? = null,
    val barcode: String? = null,
    @SerializedName("imagem_url")     val imagemUrl: String? = null,
    @SerializedName(value = "ativo", alternate = ["active"]) val activo: Boolean? = null
)

// Espelha o body de CriarProduto (produtos.go): "codigo" e "nome" são
// obrigatórios. O backend NÃO aceita preço nem barcode aqui — produtos.products
// não tem essas colunas. Preço vive em produtos.product_prices
// (POST /produtos/{id}/precos, ver DefinirPrecoRequest) e barcode em
// produtos.product_barcodes (POST /produtos/{id}/codigos-barras, ver
// AdicionarCodigoBarrasRequest) — por isso AdminApiRepository.saveProduto
// encadeia três chamadas em vez de uma só.
data class ProdutoUpsertRequest(
    val codigo: String,
    val nome: String,
    val descricao: String? = null,
    @SerializedName("product_category_id") val categoryId: Long? = null,
    val ativo: Boolean = true
)

data class DefinirPrecoRequest(
    @SerializedName("tipo_preco") val tipoPreco: String = "venda",
    val moeda: String = "MZN",
    val valor: Double
)

data class AdicionarCodigoBarrasRequest(
    val barcode: String,
    val principal: Boolean = true
)

// ─────────────────────────────────────────────
// Transactions
// ─────────────────────────────────────────────

data class CriarVendaRequest(
    @SerializedName("pos_session_id") val posSessionId: Long,
    @SerializedName("customer_id") val customerId: Long? = null,
    // UUID local da transação (TransacaoPDVEntity.id) — permite ao backend
    // detectar retries de sync offline e devolver a venda já criada em vez
    // de duplicar (ver client_reference em pos_sales, migração 20260808120000).
    @SerializedName("client_reference") val clientReference: String? = null,
    val itens: List<VendaItemRequest>,
    val pagamentos: List<VendaPagamentoRequest>
)

data class VendaItemRequest(
    @SerializedName("product_id") val productId: Long,
    @SerializedName("product_variant_id") val productVariantId: Long? = null,
    val descricao: String? = null,
    val quantidade: Double,
    @SerializedName("preco_unitario") val precoUnitario: Double,
    @SerializedName("desconto_percent") val descontoPercent: Double = 0.0,
    @SerializedName("imposto_percent") val impostoPercent: Double = 0.0
)

data class VendaPagamentoRequest(
    val tipo: String,
    val valor: Double,
    val referencia: String? = null,
    @SerializedName("payment_method_id") val paymentMethodId: Long? = null
)

// Espelha pos_sales (pos.ListarVendas/ObterVenda) — "estado" aqui é o campo
// "status" do backend (concluida/cancelada), não o antigo enum APROVADO/etc.
data class TransacaoResponse(
    val id: Long,
    val numero: String,
    @SerializedName(value = "status", alternate = ["estado"]) val estado: String = "concluida",
    @SerializedName("terminal_id") val terminalId: Long? = null,
    val total: Double? = null,
    @SerializedName("valor_recebido") val valorRecebido: Double? = null,
    val troco: Double? = null,
    @SerializedName("created_at") val createdAt: String? = null,
    @SerializedName("sold_at") val soldAt: String? = null
) {
    // Alias para compatibilidade com código existente que lia "referencia"
    // (o backend não tem esse conceito separado do número do documento)
    val referencia: String get() = numero
}

// GET pos/sales devolve {"data": [...], "meta": {...}}, não um array simples.
data class VendasListResponse(
    val data: List<TransacaoResponse> = emptyList(),
    val meta: ListMeta = ListMeta()
)

// GET pos/sales/{id} — venda com itens, necessário para o estorno parcial
// poder mostrar ao operador o que ainda está disponível para devolver.
data class VendaDetalheResponse(
    val venda: TransacaoResponse,
    val itens: List<VendaItemDetalheDTO> = emptyList()
)

data class VendaItemDetalheDTO(
    val id: Long,
    @SerializedName("product_id") val productId: Long,
    val descricao: String? = null,
    val quantidade: Double,
    @SerializedName("preco_unitario") val precoUnitario: Double,
    val total: Double,
    @SerializedName("quantidade_devolvida") val quantidadeDevolvida: Double = 0.0
)

// POST pos/sales/{id}/estorno-parcial — ver EstornoParcialVenda no backend.
data class EstornoParcialItemRequest(
    @SerializedName("item_id") val itemId: Long,
    val quantidade: Double
)

data class EstornoParcialRequest(
    val itens: List<EstornoParcialItemRequest>,
    val motivo: String,
    val metodo: String
)

data class EstornoParcialResponse(
    val id: Long,
    @SerializedName("valor_devolvido") val valorDevolvido: Double,
    @SerializedName("status_venda") val statusVenda: String? = null,
    @SerializedName("credit_note_id") val creditNoteId: Long? = null,
    @SerializedName("credit_note_numero") val creditNoteNumero: String? = null
)

data class ListMeta(
    val total: Int = 0,
    val page: Int = 1,
    val limit: Int = 20
)

// GET pos/sales/{id}/recibo — dados completos para (re)impressão, incluindo
// o cabeçalho fiscal da empresa. Ao contrário de VendaDetalheResponse, este
// endpoint existe para poder reimprimir a partir de QUALQUER terminal, não
// só do aparelho que criou a venda (ver ObterRecibo no backend).
data class ReciboResponse(
    val venda: ReciboVendaDTO,
    val itens: List<ReciboItemDTO> = emptyList(),
    val pagamentos: List<ReciboPagamentoDTO> = emptyList(),
    val empresa: ReciboEmpresaDTO = ReciboEmpresaDTO()
)

data class ReciboVendaDTO(
    val id: Long,
    val numero: String,
    val status: String = "concluida",
    val moeda: String = "MZN",
    val subtotal: Double = 0.0,
    @SerializedName("desconto_total") val descontoTotal: Double = 0.0,
    @SerializedName("imposto_total") val impostoTotal: Double = 0.0,
    val total: Double = 0.0,
    @SerializedName("valor_recebido") val valorRecebido: Double = 0.0,
    val troco: Double = 0.0,
    @SerializedName("sold_at") val soldAt: String? = null,
    @SerializedName("invoice_numero") val invoiceNumero: String? = null
)

data class ReciboItemDTO(
    val descricao: String? = null,
    val quantidade: Double,
    @SerializedName("preco_unitario") val precoUnitario: Double,
    val total: Double,
    @SerializedName("quantidade_devolvida") val quantidadeDevolvida: Double = 0.0
)

data class ReciboPagamentoDTO(
    val tipo: String,
    val valor: Double,
    val referencia: String? = null
)

data class ReciboEmpresaDTO(
    val nome: String = "",
    val nuit: String? = null,
    val endereco: String? = null
)

// POST notificacoes/broadcast — envia um push a todos os dispositivos
// registados do tenant (ver push.Service.SendToTenant no backend).
data class BroadcastPushRequest(
    val titulo: String? = null,
    val corpo: String
)

data class BroadcastPushResponse(
    val id: Long,
    val dispositivos: Int = 0
)

data class EstornoRequest(@SerializedName("reason") val motivo: String)

// ─────────────────────────────────────────────
// Relatórios POS — GET /api/pos/relatorios/*
// ─────────────────────────────────────────────

data class RelatorioVendasResponse(
    @SerializedName("agrupar_por") val agruparPor: String = "dia",
    val from: String? = null,
    val to: String? = null,
    val data: List<RelatorioVendasRow> = emptyList()
)

data class RelatorioVendasRow(
    val chave: String = "",
    val rotulo: String = "",
    @SerializedName("total_vendas") val totalVendas: Int = 0,
    @SerializedName("total_valor") val totalValor: Double = 0.0
)

data class RelatorioTopProdutosResponse(
    val from: String? = null,
    val to: String? = null,
    val data: List<RelatorioTopProdutoRow> = emptyList()
)

data class RelatorioTopProdutoRow(
    @SerializedName("product_id") val productId: Long = 0,
    val nome: String = "",
    @SerializedName("quantidade_total") val quantidadeTotal: Double = 0.0,
    @SerializedName("valor_total") val valorTotal: Double = 0.0
)

data class RelatorioCancelamentosResponse(
    val from: String? = null,
    val to: String? = null,
    val data: List<RelatorioCancelamentoRow> = emptyList()
)

data class RelatorioCancelamentoRow(
    val id: Long = 0,
    val numero: String = "",
    @SerializedName("terminal_id") val terminalId: Long = 0,
    val total: Double = 0.0,
    @SerializedName("motivo_cancelamento") val motivoCancelamento: String? = null,
    @SerializedName("sold_at") val soldAt: String? = null,
    @SerializedName("created_by") val createdBy: Long? = null,
    @SerializedName("operador_nome") val operadorNome: String = ""
)

data class RelatorioFechoCaixaResponse(
    val from: String? = null,
    val to: String? = null,
    val data: List<RelatorioFechoCaixaRow> = emptyList()
)

data class RelatorioFechoCaixaRow(
    val id: Long = 0,
    @SerializedName("terminal_id") val terminalId: Long = 0,
    @SerializedName("terminal_nome") val terminalNome: String = "",
    @SerializedName("user_id") val userId: Long = 0,
    @SerializedName("operador_nome") val operadorNome: String = "",
    @SerializedName("opened_at") val openedAt: String? = null,
    @SerializedName("closed_at") val closedAt: String? = null,
    @SerializedName("opening_amount") val openingAmount: Double = 0.0,
    @SerializedName("closing_amount") val closingAmount: Double? = null,
    val diferenca: Double? = null
)

data class RelatorioTerminalDTO(
    val id: Long = 0,
    val codigo: String = "",
    val nome: String = "",
    val activo: Boolean = true,
    @SerializedName("ultima_sessao_status") val ultimaSessaoStatus: String? = null,
    @SerializedName("ultima_sessao_em") val ultimaSessaoEm: String? = null
)

// ─────────────────────────────────────────────
// Sync — GET pos/sync/download (SyncDownload em pos/handlers/sync.go)
// ─────────────────────────────────────────────

data class SyncDownloadResponse(
    val produtos: List<ProdutoDTO> = emptyList(),
    val categorias: List<CategoriaDTO> = emptyList(),
    @SerializedName("has_more")    val hasMore: Boolean = false,
    // "next_cursor" é sempre um timestamp (millis) em formato string — passar
    // directamente como o próximo valor de "since" para continuar a paginação.
    @SerializedName("next_cursor") val nextCursor: String? = null,
    // Relógio do servidor no momento do pedido — usar isto (não
    // System.currentTimeMillis() do aparelho) para gravar o "since" da
    // próxima sincronização, para não perder alterações por desvio de
    // relógio entre o terminal e o backend.
    @SerializedName("server_time") val serverTime: Long? = null
)
