package tech.e258tech.paycore.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import tech.e258tech.paycore.repository.CatalogRepository
import tech.e258tech.paycore.repository.ItemVenda
import tech.e258tech.paycore.repository.Pedido
import tech.e258tech.paycore.repository.ProdutoCatalogo
import tech.e258tech.paycore.repository.SaleRepository

/**
 * Primeiro ViewModel do projecto (ver plano de refactor em fases) — expõe para
 * NovaVendaActivity exactamente as operações de catálogo/carrinho que antes vinham
 * directamente do PosStore, agora sobre CatalogRepository/SaleRepository.
 */
class NovaVendaViewModel(application: Application) : AndroidViewModel(application) {

    fun carregarCatalogoAsync(callback: (categorias: List<String>, produtos: List<ProdutoCatalogo>) -> Unit) {
        CatalogRepository.carregarCatalogoAsync(getApplication(), callback)
    }

    fun adicionarItem(nome: String, preco: Double, imagem: String? = null, produtoId: String? = null): Boolean =
        SaleRepository.adicionarItem(nome, preco, imagem, produtoId)

    fun incrementarItem(nome: String, produtoId: String? = null): Boolean =
        SaleRepository.incrementarItem(nome, produtoId)

    fun decrementarItem(nome: String, produtoId: String? = null) =
        SaleRepository.decrementarItem(nome, produtoId)

    fun itensVendaAtual(): List<ItemVenda> = SaleRepository.itensVendaAtual()
    fun limparVendaAtual() = SaleRepository.limparVendaAtual()
    fun subtotalVendaAtual(): Double = SaleRepository.subtotalVendaAtual()
    fun totalVendaAtual(): Double = SaleRepository.totalVendaAtual()
    fun podePagarVendaAtual(): Boolean = SaleRepository.podePagarVendaAtual()
    fun guardarPedidoAtual(): Pedido? = SaleRepository.guardarPedidoAtual()
}
