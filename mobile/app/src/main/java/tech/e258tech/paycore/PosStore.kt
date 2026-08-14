package tech.e258tech.paycore

import android.content.Context
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import retrofit2.Response
import tech.e258tech.paycore.db.AppDatabase
import tech.e258tech.paycore.db.EstornoEntity
import tech.e258tech.paycore.db.SessaoCaixaEntity
import tech.e258tech.paycore.db.SyncStatus
import tech.e258tech.paycore.db.TransacaoPDVEntity
import tech.e258tech.paycore.repository.CatalogRepository
import tech.e258tech.paycore.repository.ItemVenda
import tech.e258tech.paycore.repository.SaleRepository
import tech.e258tech.paycore.repository.SessionRepository
import tech.e258tech.paycore.utils.TerminalTokenManager
import tech.e258tech.paycore.work.SyncWorker
import tech.e258tech.paycore.api.AbrirSessaoRequest
import tech.e258tech.paycore.api.ApiClient
import tech.e258tech.paycore.api.CriarVendaRequest
import tech.e258tech.paycore.api.EstornoRequest
import tech.e258tech.paycore.api.FecharSessaoRequest
import tech.e258tech.paycore.api.VendaItemRequest
import tech.e258tech.paycore.api.VendaPagamentoRequest
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID

data class Operador(
    val id: String,
    val nome: String,
    val pin: String,
    val perfil: String = "Operador de Caixa"
)

data class TransacaoPDV(
    val id: String,
    val referencia: String,
    val metodo: String,
    val operadorId: String,
    val operadorNome: String,
    val dataHora: Long,
    val itens: List<ItemVenda>,
    val subtotal: Double,
    val desconto: Double,
    val total: Double,
    var estado: String = "Aprovado"
)

object PosStore {

    private const val PREFS_SESSAO        = "session_prefs"
    private const val KEY_UID             = "uid"
    private const val KEY_NOME            = "nome"
    private const val KEY_ROLE            = "role"
    private const val KEY_EMAIL           = "email"
    private const val KEY_TENANT_ID_SESSAO = "tenant_id"
    private const val KEY_MODULOS_JSON    = "modulos_json"

    private val gson = Gson()

    private val currencyFormat = java.text.DecimalFormat(
        "#,##0.00 'MT'",
        java.text.DecimalFormatSymbols(Locale("pt", "MZ"))
    )
    private val dateFormat  = SimpleDateFormat("dd/MM/yyyy HH:mm", Locale.getDefault())
    private val ioScope     = CoroutineScope(Dispatchers.IO)

    private lateinit var appContext: Context

    private val transacoes      = mutableListOf<TransacaoPDV>()

    var transacaoSelecionadaId: String? = null

    /** Id da sessão de caixa no SERVIDOR — null enquanto a abertura ainda não sincronizou. */
    var sessaoAtualId: Long? = null
        private set

    /** Id ESTÁVEL da sessão de caixa activa (local, gerado no cliente) — é isto que a UI usa
     * para decidir se pode vender, não [sessaoAtualId], que fica null até sincronizar (ver
     * NovaVendaActivity/PagamentoActivity). Fica definido assim que a caixa "abre", online ou não. */
    var sessaoAtualLocalId: String? = null
        private set

    /**
     * Fonte de verdade da sessão de caixa é sempre o Room (sessoes_caixa), não SharedPreferences
     * — evita duas cópias de estado a divergir. Chamado no arranque (init) e sempre que a sessão
     * activa muda (abrir/fechar, sincronizar).
     */
    private fun carregarSessaoCaixa() {
        val sessao = try {
            AppDatabase.getInstance(appContext).sessaoCaixaDao().getAberta()
        } catch (e: Exception) {
            null
        }
        sessaoAtualLocalId = sessao?.localId
        sessaoAtualId = sessao?.serverId
    }

    /** Regista a abertura de uma nova sessão de caixa — chamado tanto quando abrirSessao()
     * teve sucesso no momento (serverId já conhecido) como quando falhou por falta de rede
     * (serverId null, resolvido mais tarde pelo SyncWorker). */
    fun registarAberturaCaixa(terminalId: Long, openingAmount: Double, serverId: Long?): String {
        val localId = UUID.randomUUID().toString()
        AppDatabase.getInstance(appContext).sessaoCaixaDao().insert(
            SessaoCaixaEntity(
                localId = localId,
                serverId = serverId,
                terminalId = terminalId,
                openingAmount = openingAmount,
                abertaEm = System.currentTimeMillis(),
                status = "ABERTA",
                aberturaSincronizada = serverId != null
            )
        )
        sessaoAtualLocalId = localId
        sessaoAtualId = serverId
        return localId
    }

    /** Fecha a sessão activa. Se [diferencaOficial] vier preenchida (fecho confirmado pelo
     * servidor na hora), grava-a directamente; caso contrário calcula uma estimativa local a
     * partir das vendas já registadas nesta sessão (ver [FechoCaixaActivity] para a UI de aviso). */
    fun registarFechoCaixa(closingAmount: Double, diferencaOficial: Double? = null, justificativa: String? = null): SessaoCaixaEntity? {
        val localId = sessaoAtualLocalId ?: return null
        val dao = AppDatabase.getInstance(appContext).sessaoCaixaDao()
        val sessao = dao.getById(localId) ?: return null
        val diferenca = diferencaOficial ?: run {
            val totalVendas = AppDatabase.getInstance(appContext).transacaoDao()
                .getAprovadasPorSessao(localId).sumOf { it.total }
            closingAmount - (sessao.openingAmount + totalVendas)
        }
        dao.registarFechoLocal(localId, closingAmount, System.currentTimeMillis(), diferenca, justificativa?.ifBlank { null })
        if (diferencaOficial != null) dao.marcarFechoSincronizado(localId, diferencaOficial)
        sessaoAtualLocalId = null
        sessaoAtualId = null
        return dao.getById(localId)
    }

    var savedPrinterAddress: String = ""
        private set

    fun salvarImpressora(address: String) {
        savedPrinterAddress = address
        appContext.getSharedPreferences(PREFS_SESSAO, Context.MODE_PRIVATE)
            .edit().putString("printer_address", address).apply()
    }

    // ── Init ─────────────────────────────────────────────────────────────────

    fun init(context: Context) {
        appContext = context.applicationContext
        SessionRepository.init(appContext)
        SessionRepository.restaurarDoPrefs()

        savedPrinterAddress = appContext.getSharedPreferences(PREFS_SESSAO, Context.MODE_PRIVATE)
            .getString("printer_address", "").orEmpty()

        Thread {
            verificarTrocaTenant()
            SessionRepository.carregarSessaoUtilizador()
            carregarSessaoCaixa()
            // 1. Load from Room immediately (works offline)
            CatalogRepository.carregarDoRoomSync(appContext)
            carregarTransacoesDoRoom()
            // 2. Try background sync if online
            if (SessionRepository.tenantId.isNotEmpty()) {
                SincronizacaoManager.sincronizarSilencioso(appContext) { sucesso, _ ->
                    // Via WorkManager (não chamada directa) — respeita a constraint de rede
                    // automaticamente e cobre o caso de a rede cair outra vez entretanto.
                    if (sucesso) {
                        Thread { CatalogRepository.carregarDoRoomSync(appContext) }.start()
                        SyncWorker.enqueueOneTime(appContext)
                    }
                }
            }
        }.start()
    }

    private fun carregarTransacoesDoRoom() {
        val db = AppDatabase.getInstance(appContext)
        val type = object : TypeToken<List<ItemVenda>>() {}.type
        val list = db.transacaoDao().getAll().map { e ->
            TransacaoPDV(
                id           = e.id,
                referencia   = e.referencia,
                metodo       = e.metodo,
                operadorId   = e.operadorId,
                operadorNome = e.operadorNome,
                dataHora     = e.dataHora,
                itens        = gson.fromJson(e.itensJson, type),
                subtotal     = e.subtotal,
                desconto     = e.desconto,
                total        = e.total,
                estado       = e.estado
            )
        }
        synchronized(transacoes) {
            transacoes.clear()
            transacoes.addAll(list)
        }
    }

    /**
     * Mapeia o método de pagamento usado pela UI/local para o enum aceite
     * pelo backend em pos.CriarVenda: numerario|transferencia|tpa|mpesa|emola|outro
     */
    private fun metodoPagamentoParaBackend(metodo: String): String = when (metodo.uppercase(Locale.ROOT)) {
        "DINHEIRO", "CASH", "NUMERARIO"              -> "numerario"
        "CARTAO", "CARTÃO", "CARD"                 -> "tpa"
        "NFC / CONTACTLESS", "NFC", "CONTACTLESS"  -> "tpa"
        "QR CODE", "QR_CODE", "QR"                 -> "outro"
        "TRANSFERENCIA", "TRANSFERÊNCIA"           -> "transferencia"
        "MPESA", "M-PESA", "M_PESA"               -> "mpesa"
        "EMOLA", "E-MOLA", "E_MOLA"               -> "emola"
        else                                       -> "outro"
    }

    /**
     * Sincroniza vendas pendentes — chamado directamente (dentro de uma coroutine, ver
     * [sincronizarSessoesCaixaPendentes]) em vez de lançar a sua própria [ioScope.launch], para
     * que quem orquestra (SyncWorker, ou o próprio [init]) possa aguardar que termine antes de
     * avançar para o passo seguinte (estornos, fecho de caixa).
     */
    suspend fun sincronizarTransacoesPendentes() {
        val db = AppDatabase.getInstance(appContext)
        val pendentes = db.transacaoDao().getPendentes()
        if (pendentes.isEmpty()) return
        val type = object : TypeToken<List<ItemVenda>>() {}.type
        for (entity in pendentes) {
            val itens: List<ItemVenda> = gson.fromJson(entity.itensJson, type)
            // Cada venda resolve a SUA sessão (não a "actual") — importante quando há mais
            // do que uma sessão de caixa por sincronizar (ex.: abriu e fechou o caixa duas
            // vezes offline antes de voltar a ter rede). Linhas anteriores à coluna
            // sessaoLocalId (migração 7->8, sessaoLocalId="") caem no caminho antigo.
            val sessionId = resolverServerSessionId(entity.sessaoLocalId)
            if (sessionId == null) {
                // Dependência a aguardar (a sessão desta venda ainda não sincronizou) — não é
                // um erro da própria venda, fica EM_RETRY até a sessão resolver.
                db.transacaoDao().registarTentativaFalhada(
                    entity.id, SyncStatus.EM_RETRY, "Sessão de caixa ainda não sincronizada", System.currentTimeMillis()
                )
                continue
            }
            val itensValidos = itens.filter { !it.produtoId.isNullOrBlank() }
            if (itensValidos.size != itens.size) {
                // Estruturalmente inválido — nunca vai suceder sozinho, mesmo repetindo.
                db.transacaoDao().registarTentativaFalhada(
                    entity.id, SyncStatus.FALHADO, "Item sem produtoId válido", System.currentTimeMillis()
                )
                continue
            }

            val result = runCatching {
                ApiClient.service.criarTransacao(
                    CriarVendaRequest(
                        posSessionId = sessionId,
                        clientReference = entity.id,
                        itens = itensValidos.map {
                            VendaItemRequest(
                                productId = it.produtoId!!.toLong(),
                                descricao = it.nome,
                                quantidade = it.quantidade.toDouble(),
                                precoUnitario = it.precoUnitario
                            )
                        },
                        pagamentos = listOf(
                            VendaPagamentoRequest(
                                tipo = metodoPagamentoParaBackend(entity.metodo),
                                valor = entity.total
                            )
                        )
                    )
                )
            }
            val respostaVenda = result.getOrNull()
            if (respostaVenda?.isSuccessful == true) {
                val serverId = respostaVenda.body()?.id
                if (serverId != null) db.transacaoDao().marcarSincronizado(entity.id, serverId)
                else db.transacaoDao().marcarSincronizado(entity.id)
            } else {
                db.transacaoDao().registarTentativaFalhada(
                    entity.id, classificarFalha(respostaVenda),
                    result.exceptionOrNull()?.message ?: "HTTP ${respostaVenda?.code()}",
                    System.currentTimeMillis()
                )
            }
        }
    }

    private fun resolverServerSessionId(sessaoLocalId: String): Long? {
        if (sessaoLocalId.isBlank()) return sessaoAtualId
        return AppDatabase.getInstance(appContext).sessaoCaixaDao().getById(sessaoLocalId)?.serverId
    }

    /** Classifica uma falha de sincronização (ver SyncStatus): 4xx do backend é tratado como
     * definitivo (regra de negócio rejeitada — não se resolve sozinha repetindo); excepção de
     * rede ou 5xx é transitório e continua a ser tentado nas próximas rondas. */
    private fun classificarFalha(resposta: Response<*>?): String {
        val codigo = resposta?.code()
        return if (codigo != null && codigo in 400..499) SyncStatus.FALHADO else SyncStatus.EM_RETRY
    }

    /**
     * Puxa o histórico de vendas do ERP (GET pos/sales) e faz merge com o Room local —
     * usado pelo ecrã de Histórico (ver [HistoricoActivity]) para mostrar vendas feitas
     * noutros terminais, além das já conhecidas localmente. Vendas já presentes (por
     * serverId) só têm o estado actualizado, para reflectir um estorno feito por outro
     * canal; as novas ficam gravadas sem itens (a listagem do backend não os inclui —
     * só é possível obtê-los um a um via GET pos/sales/{id}, custoso demais para uma
     * sincronização de lista). Devolve false se não há rede/tenant, sem lançar excepção.
     */
    suspend fun sincronizarHistoricoDoServidor(): Boolean {
        if (SessionRepository.tenantId.isBlank()) return false
        val resposta = runCatching { ApiClient.service.getTransacoes(limit = 100) }.getOrNull()
        val lista = resposta?.takeIf { it.isSuccessful }?.body()?.data ?: return false

        withContext(Dispatchers.IO) {
            val db = AppDatabase.getInstance(appContext)
            val dao = db.transacaoDao()
            val existentesPorServerId = dao.getAll().filter { it.serverId != null }.associateBy { it.serverId }

            val novas = lista.mapNotNull { venda ->
                val existente = existentesPorServerId[venda.id]
                if (existente != null) {
                    val estadoNormalizado = normalizarEstadoServidor(venda.estado)
                    if (existente.estado != estadoNormalizado) dao.updateEstado(existente.id, estadoNormalizado)
                    null
                } else {
                    TransacaoPDVEntity(
                        id = "srv-${venda.id}",
                        referencia = venda.numero,
                        metodo = "",
                        operadorId = "",
                        operadorNome = "",
                        dataHora = parseDataServidor(venda.soldAt ?: venda.createdAt),
                        itensJson = "[]",
                        subtotal = venda.total ?: 0.0,
                        desconto = 0.0,
                        total = venda.total ?: 0.0,
                        estado = normalizarEstadoServidor(venda.estado),
                        syncPendente = false,
                        serverId = venda.id
                    )
                }
            }
            if (novas.isNotEmpty()) dao.insertAll(novas)
            carregarTransacoesDoRoom()
        }
        return true
    }

    private fun normalizarEstadoServidor(status: String): String = when (status.lowercase(Locale.ROOT)) {
        "cancelada" -> "Estornada"
        "concluida" -> "Aprovado"
        else -> status.replaceFirstChar { it.uppercase(Locale.ROOT) }
    }

    private val formatosDataServidor = listOf(
        "yyyy-MM-dd'T'HH:mm:ssXXX",
        "yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
        "yyyy-MM-dd'T'HH:mm:ss'Z'"
    )

    private fun parseDataServidor(valor: String?): Long {
        if (valor.isNullOrBlank()) return System.currentTimeMillis()
        for (padrao in formatosDataServidor) {
            try {
                val sdf = SimpleDateFormat(padrao, Locale.getDefault())
                if (padrao.endsWith("'Z'")) sdf.timeZone = java.util.TimeZone.getTimeZone("UTC")
                return sdf.parse(valor)?.time ?: continue
            } catch (e: Exception) {
                // tenta o próximo formato
            }
        }
        return System.currentTimeMillis()
    }

    /**
     * Reenvia estornos que ficaram por confirmar (ver [estornarTransacaoSelecionada]) — mesmo
     * padrão de [sincronizarTransacoesPendentes], sem corpo a montar além da referência.
     */
    suspend fun sincronizarEstornosPendentes() {
        val db = AppDatabase.getInstance(appContext)
        val dao = db.estornoDao()
        for (estorno in dao.getPendentes()) {
            // A própria venda ainda pode não ter sincronizado (sem id de
            // servidor) — nesse caso fica para a próxima ronda, depois de
            // sincronizarTransacoesPendentes lhe atribuir um serverId.
            val serverId = db.transacaoDao().getById(estorno.transacaoId)?.serverId
            if (serverId == null) {
                dao.registarTentativaFalhada(
                    estorno.transacaoId, SyncStatus.EM_RETRY, "Venda ainda não sincronizada", System.currentTimeMillis()
                )
                continue
            }
            val result = runCatching {
                ApiClient.service.estornarTransacao(serverId, EstornoRequest(estorno.motivo))
            }
            val resposta = result.getOrNull()
            if (resposta?.isSuccessful == true) {
                dao.marcarSincronizado(estorno.transacaoId)
            } else {
                dao.registarTentativaFalhada(
                    estorno.transacaoId, classificarFalha(resposta),
                    result.exceptionOrNull()?.message ?: "HTTP ${resposta?.code()}",
                    System.currentTimeMillis()
                )
            }
        }
    }

    /**
     * Orquestrador único de sincronização — chamado pelo SyncWorker (periódico/reconexão) e
     * pelo próprio arranque da app. Ordem importa: o backend só permite uma sessão de caixa
     * aberta por utilizador, por isso cada sessão pendente tem de ficar completamente
     * resolvida (aberta -> vendas -> estornos -> fechada) antes de tentar a seguinte.
     */
    suspend fun sincronizarSessoesCaixaPendentes() {
        val dao = AppDatabase.getInstance(appContext).sessaoCaixaDao()

        for (sessao in dao.getPendentesAbertura()) {
            val serverId = resolverOuAbrirSessaoNoServidor(sessao)
            if (serverId == null) {
                // Falha transitória (rede/backend em baixo) — regista e avança para a
                // próxima sessão pendente, em vez de bloquear o lote inteiro (uma sessão
                // presa deixava de sincronizar TODAS as outras, incl. as suas vendas).
                dao.registarTentativaFalhada(
                    sessao.localId, SyncStatus.EM_RETRY,
                    "Não foi possível abrir/resolver sessão no servidor", System.currentTimeMillis()
                )
                continue
            }
            dao.marcarAberturaSincronizada(sessao.localId, serverId)
            if (sessaoAtualLocalId == sessao.localId) sessaoAtualId = serverId
        }

        sincronizarTransacoesPendentes()
        sincronizarEstornosPendentes()

        for (sessao in dao.getPendentesFecho()) {
            val serverId = dao.getById(sessao.localId)?.serverId
            val closingAmount = sessao.closingAmount
            if (serverId == null || closingAmount == null) {
                // abertura ainda não sincronizada, ou fecho local incompleto — dependência a aguardar.
                dao.registarTentativaFalhada(
                    sessao.localId, SyncStatus.EM_RETRY,
                    "Abertura ainda não sincronizada ou fecho incompleto", System.currentTimeMillis()
                )
                continue
            }
            val result = runCatching {
                ApiClient.service.fecharSessao(
                    serverId,
                    FecharSessaoRequest(closingAmount = closingAmount, justificativa = sessao.justificativaDiferenca)
                )
            }
            val resposta = result.getOrNull()
            val body = resposta?.takeIf { it.isSuccessful }?.body()
            if (body != null) {
                dao.marcarFechoSincronizado(sessao.localId, body.diferenca)
            } else {
                dao.registarTentativaFalhada(
                    sessao.localId, classificarFalha(resposta),
                    result.exceptionOrNull()?.message ?: "HTTP ${resposta?.code()}",
                    System.currentTimeMillis()
                )
            }
        }
    }

    /**
     * Reconcilia uma sessão de caixa aberta offline: pergunta primeiro se já existe uma sessão
     * aberta no servidor (obterSessaoAtual — cobre o caso de uma tentativa anterior ter criado a
     * sessão mas perdido a resposta) antes de tentar criar uma nova. O backend só aceita uma
     * sessão aberta por utilizador de cada vez, por isso isto é seguro para retries.
     */
    private suspend fun resolverOuAbrirSessaoNoServidor(sessao: SessaoCaixaEntity): Long? {
        val actual = runCatching { ApiClient.service.obterSessaoAtual() }.getOrNull()
        if (actual?.isSuccessful == true) {
            actual.body()?.id?.let { return it }
        }
        val criado = runCatching {
            ApiClient.service.abrirSessao(
                AbrirSessaoRequest(terminalId = sessao.terminalId, openingAmount = sessao.openingAmount)
            )
        }.getOrNull()
        return criado?.takeIf { it.isSuccessful }?.body()?.id
    }

    private fun verificarTrocaTenant() {
        if (SessionRepository.tenantId.isEmpty()) return
        val prefs = appContext.getSharedPreferences("posstore_prefs", Context.MODE_PRIVATE)
        val tenantAnterior = prefs.getString("ultimo_tenant_id", "").orEmpty()
        if (tenantAnterior != SessionRepository.tenantId) {
            CatalogRepository.limparMemoria()
            synchronized(transacoes)  { transacoes.clear() }
            SaleRepository.limparPedidos()
            val db = AppDatabase.getInstance(appContext)
            db.categoriaDao().deleteAll()
            db.produtoDao().deleteAll()
            db.transacaoDao().deleteAll()
            db.usuarioSessaoDao().deleteAll()
            db.sessaoCaixaDao().deleteAll()
            db.estornoDao().deleteAll()
            sessaoAtualLocalId = null
            sessaoAtualId = null
            // Sessão do funcionário fica inválida porque as permissões são do tenant anterior
            logoutFuncionario()
            prefs.edit().putString("ultimo_tenant_id", SessionRepository.tenantId).apply()
        }
    }

    /** Logout do FUNCIONÁRIO — mantém o terminal configurado. Orquestra a limpeza dos 3 blocos
     * afectados (carrinho, sessão de caixa, autenticação) — fica no PosStore por ser
     * inerentemente transversal, tal como [verificarTrocaTenant]. */
    fun logoutFuncionario() {
        SaleRepository.limparVendaAtual()
        // Esquece o ponteiro da sessão activa (mesmo comportamento de sempre) — não apaga a
        // linha em Room, para não perder uma sessão ainda por sincronizar.
        sessaoAtualLocalId = null
        sessaoAtualId = null
        SessionRepository.limparSessaoAuth()
    }

    /** Logout completo: funcionário + terminal. */
    fun logout() {
        logoutFuncionario()
        SessionRepository.desativarTerminal()
    }

    // ── Transactions ─────────────────────────────────────────────────────────

    fun processarPagamento(metodo: String): TransacaoPDV {
        val operador   = requireNotNull(SessionRepository.operadorAtual) { "Operador nao autenticado" }
        val agora      = System.currentTimeMillis()
        val referencia = "TXN-${UUID.randomUUID().toString().take(8).uppercase()}"
        val transacao  = TransacaoPDV(
            id           = UUID.randomUUID().toString(),
            referencia   = referencia,
            metodo       = metodo,
            operadorId   = operador.id,
            operadorNome = operador.nome,
            dataHora     = agora,
            itens        = SaleRepository.itensVendaAtual().map { it.copy() },
            subtotal     = SaleRepository.subtotalVendaAtual(),
            desconto     = SaleRepository.descontoVendaAtual(),
            total        = SaleRepository.totalVendaAtual()
        )
        synchronized(transacoes) { transacoes.add(0, transacao) }
        transacaoSelecionadaId = transacao.id
        SaleRepository.limparVendaAtual()

        // Persist locally first (works offline)
        val entity = TransacaoPDVEntity(
            id           = transacao.id,
            referencia   = transacao.referencia,
            metodo       = transacao.metodo,
            operadorId   = transacao.operadorId,
            operadorNome = transacao.operadorNome,
            dataHora     = transacao.dataHora,
            itensJson    = gson.toJson(transacao.itens),
            subtotal     = transacao.subtotal,
            desconto     = transacao.desconto,
            total        = transacao.total,
            estado       = transacao.estado,
            syncPendente = true,
            sessaoLocalId = sessaoAtualLocalId.orEmpty()
        )
        ioScope.launch {
            AppDatabase.getInstance(appContext).transacaoDao().insert(entity)

            // Try to sync immediately only when we have a valid POS session and all items
            // have a backend product id. Otherwise it stays as syncPendente=true for retry
            // (SyncWorker/sincronizarSessoesCaixaPendentes resolve sessionId mais tarde,
            // inclusive quando a caixa foi aberta offline e ainda não tem serverId).
            val sessionId = sessaoAtualId
            val itensComId = transacao.itens.filter { !it.produtoId.isNullOrBlank() }
            if (SessionRepository.tenantId.isNotEmpty() && sessionId != null && itensComId.size == transacao.itens.size) {
                val result = runCatching {
                    ApiClient.service.criarTransacao(
                        CriarVendaRequest(
                            posSessionId = sessionId,
                            clientReference = transacao.id,
                            itens = itensComId.map {
                                VendaItemRequest(
                                    productId = it.produtoId!!.toLong(),
                                    descricao = it.nome,
                                    quantidade = it.quantidade.toDouble(),
                                    precoUnitario = it.precoUnitario
                                )
                            },
                            pagamentos = listOf(
                                VendaPagamentoRequest(
                                    tipo = metodoPagamentoParaBackend(transacao.metodo),
                                    valor = transacao.total
                                )
                            )
                        )
                    )
                }
                val respostaVenda = result.getOrNull()
                if (respostaVenda?.isSuccessful == true) {
                    val dao = AppDatabase.getInstance(appContext).transacaoDao()
                    val serverId = respostaVenda.body()?.id
                    if (serverId != null) dao.marcarSincronizado(transacao.id, serverId)
                    else dao.marcarSincronizado(transacao.id)
                    Log.i("PayCore_Venda", "Venda sincronizada com sucesso. serverId=$serverId")
                } else {
                    val parsed = tech.e258tech.paycore.utils.ApiErrorParser.parse(respostaVenda)
                    Log.e("PayCore_Venda", "Falha ao sincronizar venda: ${parsed.rawMessage}")
                    Log.e("PayCore_Venda", "Mensagem para utilizador: ${parsed.userMessage}")
                    // A venda continua gravada localmente (syncPendente=true) e será
                    // retentada pelo SyncWorker quando as condições do backend melhorarem
                    // (a menos que classificarFalha considere isto definitivo — ver SyncStatus).
                    AppDatabase.getInstance(appContext).transacaoDao().registarTentativaFalhada(
                        transacao.id, classificarFalha(respostaVenda), parsed.rawMessage, System.currentTimeMillis()
                    )
                }
            }
        }

        return transacao
    }

    fun estornarTransacaoSelecionada(motivo: String = "Estorno pelo operador"): TransacaoPDV? {
        val transacao = obterTransacao(transacaoSelecionadaId) ?: return null
        transacao.estado = "Estornada"

        // Grava sempre localmente primeiro (Room + fila de estornos pendentes) antes de
        // tentar a rede — antes disto o estorno era fire-and-forget e perdia-se em
        // silêncio sem ligação; agora fica syncPendente-equivalente até confirmar.
        ioScope.launch {
            val db = AppDatabase.getInstance(appContext)
            db.transacaoDao().updateEstado(transacao.id, "Estornada")
            db.estornoDao().insert(
                EstornoEntity(transacaoId = transacao.id, motivo = motivo, criadoEm = System.currentTimeMillis())
            )
            // "id" no endpoint é o id numérico do servidor, não a referência local
            // — só tenta já se a venda já tiver sincronizado; caso contrário fica
            // em sincronizarEstornosPendentes até a venda em si sincronizar.
            val serverId = db.transacaoDao().getById(transacao.id)?.serverId
            if (SessionRepository.tenantId.isNotEmpty() && serverId != null) {
                val result = runCatching {
                    ApiClient.service.estornarTransacao(serverId, EstornoRequest(motivo))
                }
                if (result.getOrNull()?.isSuccessful == true) {
                    db.estornoDao().marcarSincronizado(transacao.id)
                }
            }
        }
        return transacao
    }

    fun transacoesRecentes(): List<TransacaoPDV> =
        synchronized(transacoes) { transacoes.toList() }

    fun obterTransacao(id: String?): TransacaoPDV? {
        val targetId = id ?: transacaoSelecionadaId
        return synchronized(transacoes) { transacoes.firstOrNull { it.id == targetId } }
    }

    fun selecionarTransacao(id: String) { transacaoSelecionadaId = id }

    fun totalVendasHoje(): Double =
        synchronized(transacoes) { transacoes.filter { it.estado == "Aprovado" }.sumOf { it.total } }

    fun quantidadeVendasHoje(): Int =
        synchronized(transacoes) { transacoes.count { it.estado == "Aprovado" } }

    fun totaisPorMetodo(): Map<String, Double> {
        val base = linkedMapOf(
            "Cartao"          to 0.0,
            "NFC / Contactless" to 0.0,
            "QR Code"         to 0.0,
            "Dinheiro"        to 0.0
        )
        synchronized(transacoes) {
            transacoes.filter { it.estado == "Aprovado" }.forEach { t ->
                base[t.metodo] = (base[t.metodo] ?: 0.0) + t.total
            }
        }
        return base
    }

    /** Vendas aprovadas da sessão de caixa ACTUAL (não de sempre) — usadas pelo Dashboard
     * e pelo Fecho de Caixa, que precisam do total desta sessão, não do total histórico do
     * aparelho. Reaproveita a mesma query já usada por [registarFechoCaixa] para calcular a
     * diferença de caixa. */
    private fun vendasAprovadasDaSessaoAtual(): List<TransacaoPDVEntity> {
        val localId = sessaoAtualLocalId ?: return emptyList()
        return AppDatabase.getInstance(appContext).transacaoDao().getAprovadasPorSessao(localId)
    }

    fun totalVendasSessaoAtual(): Double =
        vendasAprovadasDaSessaoAtual().sumOf { it.total }

    fun quantidadeVendasSessaoAtual(): Int =
        vendasAprovadasDaSessaoAtual().size

    fun totaisPorMetodoSessaoAtual(): Map<String, Double> {
        val base = linkedMapOf(
            "Cartao"          to 0.0,
            "NFC / Contactless" to 0.0,
            "QR Code"         to 0.0,
            "Dinheiro"        to 0.0
        )
        vendasAprovadasDaSessaoAtual().forEach { t ->
            base[t.metodo] = (base[t.metodo] ?: 0.0) + t.total
        }
        return base
    }

    // ── Catalogue / Sale basket / Orders ────────────────────────────────────────
    // Movidos para tech.e258tech.paycore.repository.CatalogRepository/SaleRepository
    // (ver plano de refactor em fases — Fase 1). Único consumidor directo que
    // continua aqui é processarPagamento() acima, via SaleRepository.

    // ── Session/Auth/Permissões ──────────────────────────────────────────────
    // Movidos para tech.e258tech.paycore.repository.SessionRepository (Fase 2).
    // logoutFuncionario()/logout()/verificarTrocaTenant() ficam aqui por serem
    // orquestração transversal (carrinho + sessão de caixa + autenticação).

    // ── Formatting ───────────────────────────────────────────────────────────

    fun formatarValor(valor: Double): String = currencyFormat.format(valor)
    fun formatarDataHora(timestamp: Long): String = dateFormat.format(Date(timestamp))
}
