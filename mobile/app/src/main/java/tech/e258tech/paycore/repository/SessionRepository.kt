package tech.e258tech.paycore.repository

import android.content.Context
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import tech.e258tech.paycore.Operador
import tech.e258tech.paycore.api.ApiClient
import tech.e258tech.paycore.api.Permissoes
import tech.e258tech.paycore.api.UserDTO
import tech.e258tech.paycore.db.AppDatabase
import tech.e258tech.paycore.db.UsuarioSessaoEntity
import java.util.Locale

/**
 * Sessão do FUNCIONÁRIO (auth/permissões) — extraída do PosStore (ver plano de refactor em
 * fases, Fase 2). Não confundir com sessão de CAIXA (sessaoAtualId/sessaoAtualLocalId), que
 * fica no PosStore por ser um bloco à parte.
 *
 * Não importa `ui.LoginTerminalActivity` nem `PosStore` de propósito — duplica localmente as
 * chaves de SharedPreferences de que precisa (mesmo padrão que o PosStore já usa para as suas
 * próprias prefs) para não fechar o ciclo repository → ui → api → root(Login) → repository já
 * identificado no refactor da Fase 1 para o ApiClient.
 */
object SessionRepository {

    private const val PREFS_TERMINAL      = "terminal_prefs"
    private const val KEY_TENANT_ID       = "tenant_id"
    private const val KEY_TENANT_NOME     = "tenant_nome"
    private const val KEY_TERMINAL_ID     = "terminal_id"
    private const val KEY_TERMINAL_NOME   = "terminal_nome"

    private const val PREFS_SESSAO         = "session_prefs"
    private const val KEY_UID              = "uid"
    private const val KEY_NOME             = "nome"
    private const val KEY_ROLE             = "role"
    private const val KEY_EMAIL            = "email"
    private const val KEY_TENANT_ID_SESSAO = "tenant_id"
    private const val KEY_MODULOS_JSON     = "modulos_json"

    private val gson = Gson()

    private lateinit var appContext: Context

    fun init(context: Context) {
        appContext = context.applicationContext
    }

    var tenantId: String = ""
    var tenantNome: String = ""
    var terminalId: String = ""
    var terminalNome: String = ""
    var utilizadorRole: String = ""
        private set

    private val modulosPermissao = mutableMapOf<String, MutableList<String>>()

    var operadorAtual: Operador? = null
        private set

    /** Restaura tenant/terminal a partir da SharedPreferences — chamado sincronamente em
     * PosStore.init(), antes de qualquer Thread em background (leituras simples de prefs,
     * seguro em qualquer thread, incl. a principal). */
    fun restaurarDoPrefs() {
        val prefs = appContext.getSharedPreferences(PREFS_TERMINAL, Context.MODE_PRIVATE)
        tenantId     = prefs.getString(KEY_TENANT_ID, "").orEmpty()
        tenantNome   = prefs.getString(KEY_TENANT_NOME, "").orEmpty()
        terminalId   = prefs.getString(KEY_TERMINAL_ID, "").orEmpty()
        terminalNome = prefs.getString(KEY_TERMINAL_NOME, "").orEmpty()
    }

    /** Chamado após login do funcionário bem-sucedido. */
    fun sincronizarSessaoApi(
        user: UserDTO,
        tenantIdApi: String = "",
        modulos: Map<String, List<String>> = emptyMap()
    ) {
        val tenantIdParaSessao = tenantIdApi.ifBlank { tenantId }
        val role = user.role.orEmpty()
        val modulosJson = gson.toJson(modulos)

        appContext.getSharedPreferences(PREFS_SESSAO, Context.MODE_PRIVATE).edit()
            .putString(KEY_UID,              user.id.toString())
            .putString(KEY_NOME,             user.name)
            .putString(KEY_ROLE,             role)
            .putString(KEY_EMAIL,            user.email)
            .putString(KEY_TENANT_ID_SESSAO, tenantIdParaSessao)
            .putString(KEY_MODULOS_JSON,     modulosJson)
            .apply()

        if (tenantIdApi.isNotBlank() && tenantId.isBlank()) {
            tenantId = tenantIdApi
        }
        utilizadorRole = role
        definirModulosPermissao(modulos)
        operadorAtual  = Operador(user.id.toString(), user.name, "", perfilPorRole(role))

        // Persistir no Room para funcionar offline (com migração destrutiva ativa)
        try {
            AppDatabase.getInstance(appContext).usuarioSessaoDao().upsert(
                UsuarioSessaoEntity(
                    uid = user.id.toString(),
                    nome = user.name,
                    email = user.email,
                    role = role,
                    tenantId = tenantIdParaSessao,
                    modulosJson = modulosJson,
                    updatedAt = System.currentTimeMillis()
                )
            )
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun definirModulosPermissao(modulos: Map<String, List<String>>) {
        synchronized(modulosPermissao) {
            modulosPermissao.clear()
            modulos.forEach { (modulo, perms) ->
                modulosPermissao[modulo] = perms.toMutableList()
            }
        }
    }

    /** Verifica se o funcionário tem uma permissão específica. */
    fun temPermissao(modulo: String, permissao: String): Boolean {
        return synchronized(modulosPermissao) {
            modulosPermissao[modulo]?.any { it.equals(permissao, ignoreCase = true) } == true
        }
    }

    /**
     * Verifica se o funcionário tem alguma permissão administrativa — em
     * qualquer módulo que tenha um cartão no hub AdminInicio. Tem de incluir
     * todas as permissões que abrem algum ecrã de administração, senão um
     * funcionário só com, p.ex., autorizacao:gerir_utilizadores fica bloqueado
     * já no gate de entrada do hub (AdminInicioActivity), antes de sequer
     * chegar ao ecrã cuja permissão granular tem.
     */
    fun temPermissaoAdmin(): Boolean = listOf(
        Permissoes.MODULO_POS to Permissoes.GERIR_TERMINAIS,
        Permissoes.MODULO_POS to Permissoes.GERIR_CATALOGO,
        Permissoes.MODULO_POS to Permissoes.GERIR_DESCONTOS,
        Permissoes.MODULO_POS to Permissoes.SUPERVISIONAR_POS,
        Permissoes.MODULO_POS to Permissoes.RELATORIOS,
        Permissoes.MODULO_POS to Permissoes.VER_VENDAS,
        Permissoes.MODULO_AUTORIZACAO to Permissoes.GERIR_UTILIZADORES,
        Permissoes.MODULO_STOCK to Permissoes.VER_STOCK,
        Permissoes.MODULO_STOCK to Permissoes.GERIR_PRODUTOS,
        Permissoes.MODULO_STOCK to Permissoes.GERIR_CATEGORIAS,
        Permissoes.MODULO_NOTIFICACOES to Permissoes.GERIR_NOTIFICACOES
    ).any { temPermissao(it.first, it.second) }

    /**
     * Há quanto tempo as permissões em cache não são confirmadas junto do ERP
     * (via login ou 403 -> re-sync, ver [atualizarPermissoes]) — usado para
     * bloquear acções sensíveis (estorno, desconto manual) quando o terminal
     * está offline há tempo de mais para confiar cegamente no cache local.
     * Sem registo em Room (nunca fez login nesta instalação) não bloqueia —
     * outra validação (login em si) já teria falhado antes de chegar aqui.
     */
    fun permissoesEstaoDesactualizadas(maxAgeMs: Long = 24 * 60 * 60 * 1000L): Boolean {
        val atualizadoEm = try {
            AppDatabase.getInstance(appContext).usuarioSessaoDao().getAtual()?.updatedAt
        } catch (e: Exception) {
            null
        } ?: return false
        return System.currentTimeMillis() - atualizadoEm > maxAgeMs
    }

    /** Atualiza permissões em memória (ex. após receber 403). */
    fun atualizarPermissoes(modulos: Map<String, List<String>>) {
        definirModulosPermissao(modulos)
        val prefs = appContext.getSharedPreferences(PREFS_SESSAO, Context.MODE_PRIVATE)
        val uid = prefs.getString(KEY_UID, "").orEmpty()
        prefs.edit().putString(KEY_MODULOS_JSON, gson.toJson(modulos)).apply()
        if (uid.isNotEmpty()) {
            try {
                AppDatabase.getInstance(appContext).usuarioSessaoDao().getAtual()?.let { atual ->
                    AppDatabase.getInstance(appContext).usuarioSessaoDao().upsert(
                        atual.copy(modulosJson = gson.toJson(modulos), updatedAt = System.currentTimeMillis())
                    )
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    /** Melhor esforço — só actualiza se [permissoesEstaoDesactualizadas]. Ao contrário do
     * refresh feito em `PermissaoHelper.aoReceber403` (sempre incondicional, porque um 403
     * já é prova de que as permissões em cache estão erradas), este é para chamadas
     * periódicas em background (ver SyncWorker) onde não vale a pena um pedido de rede se
     * a cache ainda estiver fresca. */
    suspend fun revalidarPermissoesSeNecessario(maxAgeMs: Long = 24 * 60 * 60 * 1000L) {
        if (!permissoesEstaoDesactualizadas(maxAgeMs)) return
        val modulos = runCatching { ApiClient.service.meAcesso() }.getOrNull()?.body()?.modulos ?: return
        atualizarPermissoes(modulos)
    }

    fun carregarSessaoUtilizador() {
        val prefs = appContext.getSharedPreferences(PREFS_SESSAO, Context.MODE_PRIVATE)
        val uid   = prefs.getString(KEY_UID, "").orEmpty()
        if (uid.isEmpty()) return
        val nome          = prefs.getString(KEY_NOME, "").orEmpty().ifBlank { uid }
        val role          = prefs.getString(KEY_ROLE, "").orEmpty()
        val tenantIdSessao = prefs.getString(KEY_TENANT_ID_SESSAO, "").orEmpty()
        if (tenantId.isNotEmpty() && tenantIdSessao.isNotEmpty() && tenantIdSessao != tenantId) return

        val modulosJson = prefs.getString(KEY_MODULOS_JSON, "").orEmpty()
        val modulos = carregarModulosDeJson(modulosJson)
        definirModulosPermissao(modulos)

        utilizadorRole = role
        operadorAtual  = Operador(uid, nome, "", perfilPorRole(role))
    }

    private fun carregarModulosDeJson(json: String): Map<String, List<String>> {
        if (json.isBlank()) return emptyMap()
        return try {
            val type = object : TypeToken<Map<String, List<String>>>() {}.type
            gson.fromJson<Map<String, List<String>>>(json, type)
        } catch (e: Exception) {
            emptyMap()
        }
    }

    fun autenticarComBiometria(): Boolean {
        if (operadorAtual != null) return true
        carregarSessaoUtilizador()
        return operadorAtual != null
    }

    /** Limpa só o bloco de autenticação (operador/role/permissões/tokens/Room de sessão) —
     * chamado por PosStore.logoutFuncionario(), que orquestra também a limpeza do carrinho
     * (SaleRepository) e da sessão de CAIXA (bloco à parte, continua no PosStore). */
    fun limparSessaoAuth() {
        operadorAtual  = null
        utilizadorRole = ""
        synchronized(modulosPermissao) { modulosPermissao.clear() }
        ApiClient.clearEmployeeTokens()
        appContext.getSharedPreferences(PREFS_SESSAO, Context.MODE_PRIVATE).edit().clear().apply()
        try {
            AppDatabase.getInstance(appContext).usuarioSessaoDao().deleteAll()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /** Remove a configuração do terminal (aparelho). */
    fun desativarTerminal() {
        terminalId = ""
        terminalNome = ""
        ApiClient.clearTerminalTokens()
        appContext.getSharedPreferences(PREFS_TERMINAL, Context.MODE_PRIVATE)
            .edit().clear().apply()
    }

    private fun perfilPorRole(role: String): String = when (role.lowercase(Locale.ROOT)) {
        "super_admin", "super-admin" -> "Super Admin"
        "admin"   -> "Administrador"
        "manager" -> "Gerente"
        else      -> role.ifBlank { "Operador" }
    }
}
