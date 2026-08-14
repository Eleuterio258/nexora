package tech.e258tech.paycore

import android.content.Context
import android.os.Handler
import android.os.Looper
import tech.e258tech.paycore.api.ApiClient
import tech.e258tech.paycore.api.ProdutoDTO
import tech.e258tech.paycore.db.AppDatabase
import tech.e258tech.paycore.db.CategoriaEntity
import tech.e258tech.paycore.db.ProdutoEntity
import tech.e258tech.paycore.repository.ProdutoCatalogo
import tech.e258tech.paycore.repository.SessionRepository
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL

/** Catálogo tal como está persistido no Room, sem qualquer noção de cache em memória —
 * quem chama (ver [tech.e258tech.paycore.repository.CatalogRepository]) decide o que
 * fazer com os dados. SincronizacaoManager não conhece o CatalogRepository nem o
 * PosStore, para não reintroduzir o ciclo Catálogo ↔ Sincronização. */
data class CatalogoRoom(val categorias: List<String>, val produtos: List<ProdutoCatalogo>)

object SincronizacaoManager {

    private val mainHandler = Handler(Looper.getMainLooper())
    private const val PREFS_NAME    = "sync_prefs"
    private const val KEY_ULTIMO_SYNC = "ultimo_sync"

    fun ultimoSync(context: Context): Long =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getLong(KEY_ULTIMO_SYNC, 0L)

    // ── Read from Room (offline-first, no network, no side effects) ───────────

    fun catalogoDoRoom(context: Context): CatalogoRoom {
        val db = AppDatabase.getInstance(context)
        val cats  = db.categoriaDao().getAll().map { it.nome }
        val prods = db.produtoDao().getAll().map {
            ProdutoCatalogo(
                id          = it.id,
                nome        = it.nome,
                categoria   = it.categoriaNome,
                preco       = it.preco,
                barcode     = it.barcode,
                imagem      = it.imagem,
                imagemLocal = it.imagemLocal,
                ativo       = it.ativo,
                stock       = it.stock
            )
        }
        return CatalogoRoom(cats, prods)
    }

    // ── Sync from API → save to Room → update memory ──────────────────────────

    fun sincronizarSilencioso(
        context: Context,
        onConcluido: ((sucesso: Boolean, erro: String?) -> Unit)? = null
    ) {
        sincronizar(
            context    = context,
            onLog      = {},
            onConcluido = { sucesso, erro -> onConcluido?.invoke(sucesso, erro) }
        )
    }

    // Máximo de páginas seguidas a pedir a /pos/sync/download numa única
    // sincronização — só existe para não entrar em loop infinito se alguma
    // vez houver um bug de paginação no servidor; um catálogo real nunca
    // deve chegar perto disto (300 produtos alterados por página).
    private const val MAX_PAGINAS_SYNC = 50

    fun sincronizar(
        context: Context,
        onLog: (String) -> Unit,
        onConcluido: (sucesso: Boolean, erro: String?) -> Unit
    ) {
        val imagesDir = File(context.filesDir, "images").also { it.mkdirs() }

        fun log(msg: String) = mainHandler.post { onLog(msg) }
        // "proximoSince" é o relógio do SERVIDOR devolvido pela última página de
        // /pos/sync/download (ver SyncDownloadResponse.serverTime) — nunca o
        // relógio do aparelho, para não perder alterações por desvio de relógio.
        fun done(ok: Boolean, err: String? = null, proximoSince: Long? = null) {
            if (ok && proximoSince != null) {
                context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    .edit().putLong(KEY_ULTIMO_SYNC, proximoSince).apply()
            }
            mainHandler.post { onConcluido(ok, err) }
        }

        val tenantId = SessionRepository.tenantId
        if (tenantId.isEmpty()) {
            done(false, "Tenant nao definido. Reative o terminal.")
            return
        }

        log("A sincronizar com servidor [${SessionRepository.tenantNome}]...")

        Thread {
            // Categorias continuam a ser sempre puxadas por inteiro: a tabela
            // local (CategoriaEntity) só guarda "nome" como chave — sem um id
            // estável não há como reconciliar um delta (rename/desactivação)
            // sem arriscar deixar entradas órfãs. A lista é sempre pequena,
            // por isso o custo de a trazer inteira a cada sync é irrelevante.
            //
            // Usa /pos/sync/download (since=0 força a lista completa, não o
            // delta) em vez de GET /produtos/categorias: esse endpoint exige
            // stock:gerir_categorias, que uma sessão de terminal não tem (só
            // pos:operar_pos) — chamá-lo aqui devolvia 403 e travava o sync
            // inteiro de categorias para qualquer terminal.
            val catResult = runCatching {
                kotlinx.coroutines.runBlocking { ApiClient.service.syncDownload(since = 0, types = "categorias") }
            }
            val catResponse = catResult.getOrNull()
            if (catResponse == null || !catResponse.isSuccessful) {
                done(false, "Erro categorias: ${catResult.exceptionOrNull()?.message ?: catResponse?.code()}")
                return@Thread
            }

            val catDtos = catResponse.body()?.categorias.orEmpty().sortedBy { it.ordem }
            val categorias = catDtos.map { it.nome }
            mainHandler.post { log("${categorias.size} categorias recebidas") }

            // Produtos: sync incremental via /pos/sync/download, paginado por
            // "since" (ver ApiModels.SyncDownloadResponse). id de produto é
            // estável e desactivação é reflectida no campo "ativo" do próprio
            // delta, por isso aqui não é preciso deleteAll — REPLACE por id
            // chega para reconciliar correctamente.
            val since = ultimoSync(context)
            val prodDtos = mutableListOf<ProdutoDTO>()
            var cursor = since
            var paginas = 0
            var serverTime: Long? = null
            while (true) {
                paginas++
                val syncResult = runCatching {
                    kotlinx.coroutines.runBlocking {
                        ApiClient.service.syncDownload(since = cursor, types = "produtos")
                    }
                }
                val syncResponse = syncResult.getOrNull()
                if (syncResponse == null || !syncResponse.isSuccessful) {
                    done(false, "Erro produtos: ${syncResult.exceptionOrNull()?.message ?: syncResponse?.code()}")
                    return@Thread
                }
                val body = syncResponse.body() ?: break
                prodDtos += body.produtos
                serverTime = body.serverTime ?: serverTime
                if (!body.hasMore || body.nextCursor == null || paginas >= MAX_PAGINAS_SYNC) break
                cursor = body.nextCursor.toLongOrNull() ?: break
            }
            mainHandler.post { log("${prodDtos.size} produtos alterados desde o último sync") }

            val db = AppDatabase.getInstance(context)

            db.categoriaDao().deleteAll()
            db.categoriaDao().insertAll(
                catDtos.mapIndexed { idx, dto -> CategoriaEntity(dto.nome, idx) }
            )

            if (prodDtos.isNotEmpty()) {
                mainHandler.post { log("A descarregar imagens localmente...") }
                var imagensOk = 0
                val produtosAlterados = prodDtos.map { dto ->
                    val imagemUrl = dto.imagemUrl
                    val imagemLocal = if (!imagemUrl.isNullOrBlank()) {
                        val destino = File(imagesDir, "${dto.id}.jpg")
                        val local = downloadImagem(imagemUrl, destino)
                        if (local != null) imagensOk++
                        local
                    } else null

                    ProdutoEntity(
                        id = dto.id.toString(),
                        nome = dto.nome,
                        categoriaNome = dto.categoriaNome ?: "",
                        preco = dto.precoVenda ?: dto.preco ?: 0.0,
                        barcode = dto.barcode ?: "",
                        imagem = imagemUrl,
                        imagemLocal = imagemLocal,
                        ativo = dto.activo ?: true
                    )
                }
                db.produtoDao().insertAll(produtosAlterados)
                mainHandler.post { log("$imagensOk/${produtosAlterados.size} imagens guardadas localmente") }
            }

            mainHandler.post { log("Sincronizacao concluida!") }
            done(true, proximoSince = serverTime ?: since)
        }.start()
    }

    private fun downloadImagem(url: String, destino: File): String? {
        if (destino.exists() && destino.length() > 0) return destino.absolutePath
        return try {
            val conn = (URL(url).openConnection() as HttpURLConnection).apply {
                connectTimeout = 15_000
                readTimeout    = 15_000
                instanceFollowRedirects = true
                doInput = true
            }
            conn.connect()
            if (conn.responseCode in 200..299) {
                conn.inputStream.use { input ->
                    FileOutputStream(destino).use { output -> input.copyTo(output) }
                }
                destino.absolutePath
            } else null
        } catch (_: Exception) {
            null
        }
    }
}
