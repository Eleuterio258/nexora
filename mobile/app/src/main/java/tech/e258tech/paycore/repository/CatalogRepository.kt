package tech.e258tech.paycore.repository

import android.content.Context
import android.os.Handler
import android.os.Looper
import tech.e258tech.paycore.SincronizacaoManager

data class ProdutoCatalogo(
    val id: String,
    val nome: String,
    val categoria: String,
    val preco: Double,
    val barcode: String,
    val imagem: String?,
    val imagemLocal: String? = null,
    val drawableRes: Int? = null,
    val ativo: Boolean = true,
    val stock: Int? = null
)

/**
 * Catálogo (categorias/produtos) em memória — extraído do PosStore (ver plano de refactor
 * em fases: Fase 1 move Catálogo + Venda actual, Sessão/Permissões/Caixa/Transações/Sync
 * ficam para uma fase seguinte, com maior alcance e risco).
 *
 * Dependência é sempre num único sentido: CatalogRepository → SincronizacaoManager (só para
 * ler/escrever Room e rede). SincronizacaoManager não conhece este objecto — antes deste
 * refactor, SincronizacaoManager chamava de volta PosStore.atualizarCatalogoMemoria(), um
 * ciclo que aqui fica resolvido.
 */
object CatalogRepository {

    private val mainHandler = Handler(Looper.getMainLooper())
    private val categorias = mutableListOf<String>()
    private val produtos = mutableListOf<ProdutoCatalogo>()

    fun obterCategorias(): List<String> = synchronized(categorias) { categorias.toList() }
    fun obterProdutos(): List<ProdutoCatalogo> = synchronized(produtos) { produtos.toList() }
    fun produtoPorId(id: String): ProdutoCatalogo? =
        synchronized(produtos) { produtos.firstOrNull { it.id == id } }

    fun adicionarCategoria(nome: String) { synchronized(categorias) { categorias.add(nome) } }
    fun removerCategoria(nome: String) { synchronized(categorias) { categorias.remove(nome) } }
    fun adicionarProduto(produto: ProdutoCatalogo) { synchronized(produtos) { produtos.add(produto) } }
    fun removerProduto(id: String) { synchronized(produtos) { produtos.removeAll { it.id == id } } }

    /** Esvazia por completo (ao contrário de [atualizarCatalogoMemoria], não injecta "Todos") —
     * usado quando o cache deixa de ser válido (ex.: troca de tenant), para forçar
     * [carregarCatalogoAsync] a ir buscar dados novos em vez de devolver o cache antigo. */
    fun limparMemoria() {
        synchronized(categorias) { categorias.clear() }
        synchronized(produtos) { produtos.clear() }
    }

    fun atualizarCatalogoMemoria(novasCategorias: List<String>, novosProdutos: List<ProdutoCatalogo>) {
        synchronized(categorias) {
            categorias.clear()
            categorias.addAll(listOf("Todos") + novasCategorias.filter { it != "Todos" })
        }
        synchronized(produtos) {
            produtos.clear()
            produtos.addAll(novosProdutos)
        }
    }

    /** Lê o Room de forma síncrona (chamador tem de já estar fora da main thread) e actualiza
     * a memória. Usado no arranque (PosStore.init, já corre numa Thread própria) e internamente
     * por [carregarCatalogoAsync]/[refrescarAposSync]. */
    fun carregarDoRoomSync(context: Context) {
        val catalogo = SincronizacaoManager.catalogoDoRoom(context)
        if (catalogo.categorias.isNotEmpty() || catalogo.produtos.isNotEmpty()) {
            atualizarCatalogoMemoria(catalogo.categorias, catalogo.produtos)
        }
    }

    /** Reflete no cache em memória uma sincronização que já terminou (chamado a partir de um
     * callback de [SincronizacaoManager], que corre na main thread — por isso salta para uma
     * Thread própria antes de tocar no Room). */
    private fun refrescarAposSync(context: Context, callback: (List<String>, List<ProdutoCatalogo>) -> Unit) {
        Thread {
            carregarDoRoomSync(context)
            mainHandler.post { callback(obterCategorias(), obterProdutos()) }
        }.start()
    }

    fun carregarCatalogoAsync(context: Context, callback: (categorias: List<String>, produtos: List<ProdutoCatalogo>) -> Unit) {
        val cats  = obterCategorias()
        val prods = obterProdutos()
        if (cats.isNotEmpty()) { callback(cats, prods); return }

        // Nada em memória ainda — devolve já o que houver (possivelmente vazio) para a UI
        // mostrar o estado vazio/"a carregar" em vez de ficar sem resposta, enquanto tenta
        // Room e, se preciso, a rede em background.
        callback(cats, prods)

        Thread {
            carregarDoRoomSync(context)
            val catsDb  = obterCategorias()
            val prodsDb = obterProdutos()
            if (catsDb.isNotEmpty()) {
                mainHandler.post { callback(catsDb, prodsDb) }
                SincronizacaoManager.sincronizarSilencioso(context) { sucesso, _ ->
                    if (sucesso) refrescarAposSync(context, callback)
                }
                return@Thread
            }
            // Sem dados no Room — sincronizar com a rede
            SincronizacaoManager.sincronizarSilencioso(context) { sucesso, _ ->
                if (sucesso) refrescarAposSync(context, callback)
                else mainHandler.post { callback(obterCategorias(), obterProdutos()) }
            }
        }.start()
    }
}
