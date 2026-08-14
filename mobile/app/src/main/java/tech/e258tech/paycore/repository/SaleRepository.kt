package tech.e258tech.paycore.repository

import java.util.UUID

data class ItemVenda(
    val nome: String,
    var quantidade: Int,
    val precoUnitario: Double,
    val imagem: String? = null,
    val produtoId: String? = null
)

data class Pedido(
    val id: String,
    val numero: Int,
    val nota: String,
    val itens: List<ItemVenda>,
    val total: Double,
    val dataHora: Long,
    val estado: String = "Pendente"
)

/**
 * Carrinho da venda actual + pedidos em espera — extraído do PosStore (ver plano de refactor
 * em fases). Quase mono-consumidor (NovaVendaActivity/PagamentoActivity para o carrinho,
 * PedidosActivity para os pedidos), por isso foi o primeiro bloco a sair do PosStore.
 *
 * `processarPagamento` (criação da TransacaoPDV a partir do carrinho) continua no PosStore
 * nesta fase — pertence ao bloco de Transações/Sessão de Caixa, fora do âmbito desta entrega
 * — mas passa a ler o carrinho a partir daqui em vez de uma lista privada duplicada.
 */
object SaleRepository {

    private val itensVendaAtual = mutableListOf<ItemVenda>()
    private val pedidos = mutableListOf<Pedido>()

    // ── Sale basket ──────────────────────────────────────────────────────────

    /** true = quantidade respeitada; false = o produto tem stock definido (ver
     * ProdutoEntity.stock) e a quantidade pedida excede-o. Produtos sem stock controlado
     * (null) nunca bloqueiam. */
    private fun respeitaStock(produtoId: String?, quantidadeDesejada: Int): Boolean {
        if (produtoId == null) return true
        val stock = CatalogRepository.produtoPorId(produtoId)?.stock ?: return true
        return quantidadeDesejada <= stock
    }

    /** Retorna false (e não adiciona) se a quantidade pedida exceder o stock do produto. */
    fun adicionarItem(nome: String, preco: Double, imagem: String? = null, produtoId: String? = null): Boolean {
        val existente = if (produtoId != null) {
            itensVendaAtual.firstOrNull { it.produtoId == produtoId }
        } else {
            itensVendaAtual.firstOrNull { it.nome == nome }
        }
        val quantidadeDesejada = (existente?.quantidade ?: 0) + 1
        if (!respeitaStock(produtoId, quantidadeDesejada)) return false
        if (existente != null) {
            existente.quantidade += 1
        } else {
            itensVendaAtual.add(ItemVenda(nome, 1, preco, imagem, produtoId))
        }
        return true
    }

    /** Retorna false (e não incrementa) se a quantidade pedida exceder o stock do produto. */
    fun incrementarItem(nome: String, produtoId: String? = null): Boolean {
        val item = if (produtoId != null) {
            itensVendaAtual.firstOrNull { it.produtoId == produtoId }
        } else {
            itensVendaAtual.firstOrNull { it.nome == nome }
        }
        item ?: return false
        if (!respeitaStock(produtoId, item.quantidade + 1)) return false
        item.quantidade += 1
        return true
    }

    fun decrementarItem(nome: String, produtoId: String? = null) {
        val item = if (produtoId != null) {
            itensVendaAtual.firstOrNull { it.produtoId == produtoId }
        } else {
            itensVendaAtual.firstOrNull { it.nome == nome }
        } ?: return
        item.quantidade -= 1
        if (item.quantidade <= 0) itensVendaAtual.remove(item)
    }

    fun removerItem(nome: String, produtoId: String? = null) {
        if (produtoId != null) {
            itensVendaAtual.removeAll { it.produtoId == produtoId }
        } else {
            itensVendaAtual.removeAll { it.nome == nome }
        }
    }

    fun limparVendaAtual() { itensVendaAtual.clear() }
    fun itensVendaAtual(): List<ItemVenda> = itensVendaAtual.toList()

    fun resumoItensVendaAtual(): String {
        if (itensVendaAtual.isEmpty()) return "Nenhum item adicionado"
        return itensVendaAtual.joinToString("\n") {
            "${it.quantidade}x ${it.nome}  ${tech.e258tech.paycore.PosStore.formatarValor(it.quantidade * it.precoUnitario)}"
        }
    }

    fun subtotalVendaAtual(): Double = itensVendaAtual.sumOf { it.quantidade * it.precoUnitario }

    fun descontoVendaAtual(): Double {
        val sub = subtotalVendaAtual()
        return if (sub >= 5000.0) sub * 0.05 else 0.0
    }

    fun totalVendaAtual(): Double = subtotalVendaAtual() - descontoVendaAtual()
    fun podePagarVendaAtual(): Boolean = itensVendaAtual.isNotEmpty()

    // ── Orders ───────────────────────────────────────────────────────────────

    fun guardarPedidoAtual(nota: String = ""): Pedido? {
        if (itensVendaAtual.isEmpty()) return null
        val numero = synchronized(pedidos) { pedidos.size + 1 }
        val pedido = Pedido(
            id       = UUID.randomUUID().toString(),
            numero   = numero,
            nota     = nota,
            itens    = itensVendaAtual().map { it.copy() },
            total    = totalVendaAtual(),
            dataHora = System.currentTimeMillis()
        )
        synchronized(pedidos) { pedidos.add(0, pedido) }
        limparVendaAtual()
        return pedido
    }

    fun retomarPedido(id: String) {
        val pedido = synchronized(pedidos) { pedidos.firstOrNull { it.id == id } } ?: return
        limparVendaAtual()
        pedido.itens.forEach { item ->
            repeat(item.quantidade) { adicionarItem(item.nome, item.precoUnitario, item.imagem, item.produtoId) }
        }
        cancelarPedido(id)
    }

    fun cancelarPedido(id: String) { synchronized(pedidos) { pedidos.removeAll { it.id == id } } }
    fun pedidosAtivos(): List<Pedido> = synchronized(pedidos) { pedidos.toList() }
    fun limparPedidos() { synchronized(pedidos) { pedidos.clear() } }
}
