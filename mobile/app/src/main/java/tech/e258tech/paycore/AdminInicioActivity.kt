package tech.e258tech.paycore

import android.content.Intent
import android.os.Bundle
import android.text.InputType
import android.view.View
import android.widget.EditText
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch
import tech.e258tech.paycore.api.ApiClient
import tech.e258tech.paycore.api.BroadcastPushRequest
import tech.e258tech.paycore.api.Permissoes
import tech.e258tech.paycore.repository.SessionRepository
import tech.e258tech.paycore.utils.PermissaoHelper
import tech.e258tech.paycore.utils.PermissaoHelper.tratarSemPermissao

class AdminInicioActivity : androidx.appcompat.app.AppCompatActivity() {


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = android.graphics.Color.TRANSPARENT
        window.navigationBarColor = android.graphics.Color.WHITE
        WindowInsetsControllerCompat(window, window.decorView).apply {
            isAppearanceLightStatusBars = true
            isAppearanceLightNavigationBars = true
        }

        setContentView(R.layout.activity_admin_inicio)

        // Se não tem nenhuma permissão admin, fecha imediatamente
        if (!SessionRepository.temPermissaoAdmin()) {
            PermissaoHelper.mostrarSemPermissaoEFechar(this)
            return
        }

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.header_inicio)) { view, insets ->
            val statusBar = insets.getInsets(WindowInsetsCompat.Type.statusBars())
            view.setPadding(view.paddingLeft, statusBar.top, view.paddingRight, view.paddingBottom)
            insets
        }

        val tenant  = SessionRepository.tenantNome.ifEmpty { "PayCore" }
        val operador = SessionRepository.operadorAtual?.nome ?: "Administrador"

        findViewById<TextView>(R.id.tv_inicio_tenant).text = tenant
        findViewById<TextView>(R.id.tv_inicio_boas_vindas).text = operador
        findViewById<TextView>(R.id.tv_inicio_vendas_valor).text = "A carregar..."
        findViewById<TextView>(R.id.tv_inicio_terminais_valor).text = "—"
        findViewById<TextView>(R.id.tv_inicio_produtos_valor).text = "—"

        findViewById<ImageButton>(R.id.btn_admin_logout).setOnClickListener {
            AlertDialog.Builder(this)
                .setTitle("Terminar sessão")
                .setMessage("Tem a certeza que quer sair? O terminal permanecerá configurado.")
                .setPositiveButton("Sair") { _, _ ->
                    PosStore.logoutFuncionario()
                    startActivity(
                        Intent(this, LoginActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                        }
                    )
                }
                .setNegativeButton("Cancelar", null)
                .show()
        }

        // Cards de operações
        val cardTransacoes = findViewById<View>(R.id.card_inicio_transacoes)
        val cardRelatorios = findViewById<View>(R.id.card_inicio_relatorios)
        val cardCaixa      = findViewById<View>(R.id.card_inicio_caixa)
        val cardProdutos   = findViewById<View>(R.id.card_inicio_produtos)
        val cardCategorias = findViewById<View>(R.id.card_inicio_categorias)
        val cardImpressora = findViewById<View>(R.id.card_inicio_impressora)

        // Transacões / Caixa: operar_pos ou alguma permissão admin
        val podeVerTransacoes = SessionRepository.temPermissao(Permissoes.MODULO_POS, Permissoes.OPERAR_POS) ||
                                SessionRepository.temPermissaoAdmin()
        configurarCard(cardTransacoes, podeVerTransacoes) {
            startActivity(Intent(this, AdminTransacoesActivity::class.java))
        }
        configurarCard(cardCaixa, podeVerTransacoes) {
            startActivity(Intent(this, AdminCaixaActivity::class.java))
        }

        // Relatórios: operar_pos ou admin
        configurarCard(cardRelatorios, podeVerTransacoes) {
            startActivity(Intent(this, AdminRelatorioActivity::class.java))
        }

        // Produtos: stock:ver_stock (listar) · Categorias: stock:gerir_categorias
        // — as permissões que o módulo /api/produtos do ERP realmente exige.
        val podeVerProdutos     = SessionRepository.temPermissao(Permissoes.MODULO_STOCK, Permissoes.VER_STOCK)
        val podeGerirCategorias = SessionRepository.temPermissao(Permissoes.MODULO_STOCK, Permissoes.GERIR_CATEGORIAS)
        configurarCard(cardProdutos, podeVerProdutos) {
            startActivity(Intent(this, AdminProdutosActivity::class.java))
        }
        configurarCard(cardCategorias, podeGerirCategorias) {
            startActivity(Intent(this, AdminCategoriasActivity::class.java))
        }

        // Impressora: qualquer utilizador autenticado pode configurar
        configurarCard(cardImpressora, true) {
            startActivity(Intent(this, ImpressoraActivity::class.java))
        }

        // Notificar todos: envia um push a todos os dispositivos registados
        // do tenant — exige notificacoes:gerir_notificacoes.
        val podeNotificarTodos = SessionRepository.temPermissao(Permissoes.MODULO_NOTIFICACOES, Permissoes.GERIR_NOTIFICACOES)
        configurarCard(findViewById(R.id.card_inicio_broadcast), podeNotificarTodos) {
            abrirDialogBroadcast()
        }

        // Utilizadores: gestão de funcionários — autorizacao:gerir_utilizadores.
        val podeGerirUtilizadores = SessionRepository.temPermissao(Permissoes.MODULO_AUTORIZACAO, Permissoes.GERIR_UTILIZADORES)
        configurarCard(findViewById(R.id.card_inicio_utilizadores), podeGerirUtilizadores) {
            startActivity(Intent(this, AdminUtilizadoresActivity::class.java))
        }

        // Terminais (resumo no topo): abre a gestão de terminais.
        findViewById<View>(R.id.card_inicio_terminais).setOnClickListener {
            startActivity(Intent(this, AdminTerminaisActivity::class.java))
        }
    }

    private fun abrirDialogBroadcast() {
        val etTitulo = EditText(this).apply { hint = "Título (opcional)" }
        val etCorpo = EditText(this).apply {
            hint = "Mensagem"
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_MULTI_LINE
            minLines = 3
        }
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            val pad = (16 * resources.displayMetrics.density).toInt()
            setPadding(pad, pad, pad, 0)
            addView(etTitulo)
            addView(etCorpo)
        }

        AlertDialog.Builder(this)
            .setTitle("Notificar todos os dispositivos")
            .setView(container)
            .setPositiveButton("Enviar") { _, _ ->
                val corpo = etCorpo.text.toString().trim()
                if (corpo.isBlank()) {
                    Toast.makeText(this, "Indique a mensagem", Toast.LENGTH_SHORT).show()
                    return@setPositiveButton
                }
                val titulo = etTitulo.text.toString().trim().takeIf { it.isNotEmpty() }
                lifecycleScope.launch {
                    val resposta = runCatching {
                        ApiClient.service.broadcastPush(BroadcastPushRequest(titulo = titulo, corpo = corpo))
                    }.getOrNull()
                    if (resposta?.isSuccessful == true) {
                        val dispositivos = resposta.body()?.dispositivos ?: 0
                        Toast.makeText(this@AdminInicioActivity, "Enviado a $dispositivos dispositivo(s)", Toast.LENGTH_LONG).show()
                    } else {
                        Toast.makeText(this@AdminInicioActivity, "Não foi possível enviar a notificação.", Toast.LENGTH_LONG).show()
                    }
                }
            }
            .setNegativeButton("Cancelar", null)
            .show()
    }

    private fun configurarCard(card: View, visivel: Boolean, onClick: () -> Unit) {
        card.visibility = if (visivel) View.VISIBLE else View.GONE
        if (visivel) {
            card.setOnClickListener { onClick() }
        }
    }

    override fun onResume() {
        super.onResume()
        lifecycleScope.launch {
            AdminApiRepository.loadDashboard()
                .onSuccess { snap ->
                    findViewById<TextView>(R.id.tv_inicio_vendas_valor).text =
                        PosStore.formatarValor(snap.totalVendas)
                    findViewById<TextView>(R.id.tv_inicio_terminais_valor).text =
                        "${snap.terminaisAtivos} ativos"
                    findViewById<TextView>(R.id.tv_inicio_produtos_valor).text =
                        "${snap.totalProdutos} itens"
                }
                .onFailure {
                    findViewById<TextView>(R.id.tv_inicio_vendas_valor).text =
                        PosStore.formatarValor(PosStore.totalVendasHoje())
                    findViewById<TextView>(R.id.tv_inicio_terminais_valor).text =
                        "${AdminFixtures.terminais.count { it.estado == "Ativo" }} ativos"
                    findViewById<TextView>(R.id.tv_inicio_produtos_valor).text =
                        "${AdminFixtures.produtos.size} itens"
                }
                .tratarSemPermissao(this@AdminInicioActivity)
        }
    }

    @Suppress("MissingSuperCall")
    override fun onBackPressed() {
        // navegação para trás bloqueada — usar bottom nav
    }
}

