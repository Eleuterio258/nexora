package tech.e258tech.paycore.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import tech.e258tech.paycore.PosStore
import tech.e258tech.paycore.TransacaoPDV
import tech.e258tech.paycore.repository.SaleRepository

/** `processarPagamento` continua no PosStore nesta fase — pertence ao bloco de
 * Transações/Sessão de Caixa (ver plano de refactor em fases), não ao carrinho. */
class PagamentoViewModel(application: Application) : AndroidViewModel(application) {

    fun totalVendaAtual(): Double = SaleRepository.totalVendaAtual()

    fun processarPagamento(metodo: String): TransacaoPDV = PosStore.processarPagamento(metodo)
}
