package tech.e258tech.paycore

import android.os.Bundle
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.app.AlertDialog
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.lifecycle.lifecycleScope
import com.google.android.material.button.MaterialButton
import kotlinx.coroutines.launch
import tech.e258tech.paycore.api.Permissoes
import tech.e258tech.paycore.repository.SessionRepository
import tech.e258tech.paycore.utils.PermissaoHelper.tratarSemPermissao
import tech.e258tech.paycore.utils.PermissaoHelper.verificarPermissaoOuFechar

class AdminTerminalDetalheActivity : AppCompatActivity() {

    override fun onResume() {
        super.onResume()
        atualizarDetalhe()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!verificarPermissaoOuFechar(Permissoes.MODULO_POS, Permissoes.GERIR_TERMINAIS)) return
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = android.graphics.Color.TRANSPARENT
        window.navigationBarColor = android.graphics.Color.WHITE
        WindowInsetsControllerCompat(window, window.decorView).apply {
            isAppearanceLightStatusBars = true
            isAppearanceLightNavigationBars = true
        }

        setContentView(R.layout.activity_admin_terminal_detalhe)

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.layout_header)) { view, insets ->
            val sb = insets.getInsets(WindowInsetsCompat.Type.statusBars())
            view.setPadding(view.paddingLeft, sb.top, view.paddingRight, view.paddingBottom)
            insets
        }

        findViewById<MaterialButton>(R.id.btn_admin_terminal_detalhe_voltar).setOnClickListener { finish() }
        findViewById<MaterialButton>(R.id.btn_admin_terminal_status).setOnClickListener { escolherEstado() }
        findViewById<MaterialButton>(R.id.btn_admin_terminal_eliminar).setOnClickListener { eliminarTerminal() }
    }

    private fun atualizarDetalhe() {
        val detalheView = findViewById<TextView>(R.id.tv_admin_terminal_detalhe)
        val terminal = AdminApiRepository.selectedTerminal

        detalheView.text = if (terminal != null) {
            """
            Nome: ${AdminApiRepository.terminalTitle(terminal)}
            Codigo: ${terminal.codigo ?: "N/D"}
            Estado: ${AdminApiRepository.terminalStatus(terminal)}
            Activation code: ${terminal.activationCode ?: "N/D"}
            Modelo: ${terminal.model ?: "N/D"}
            Tenant: ${SessionRepository.tenantNome.ifEmpty { "PayCore" }}
            """.trimIndent()
        } else {
            val fallback = AdminFixtures.terminais.first()
            """
            Nome: ${fallback.nome}
            Serial: ${fallback.serial}
            Estado: ${fallback.estado}
            Activation code: ${fallback.activationCode}
            Tenant: ${SessionRepository.tenantNome.ifEmpty { "PayCore" }}
            """.trimIndent()
        }
    }

    private fun escolherEstado() {
        val opcoes = arrayOf("ACTIVE", "INACTIVE", "BLOCKED", "MAINTENANCE", "OFFLINE")
        AlertDialog.Builder(this)
            .setTitle("Alterar estado do terminal")
            .setItems(opcoes) { _, which ->
                atualizarEstado(opcoes[which])
            }
            .setNegativeButton("Cancelar", null)
            .show()
    }

    private fun atualizarEstado(status: String) {
        val detalheView = findViewById<TextView>(R.id.tv_admin_terminal_detalhe)
        detalheView.text = "A atualizar estado para $status..."

        lifecycleScope.launch {
            AdminApiRepository.updateSelectedTerminalStatus(status)
                .onSuccess {
                    atualizarDetalhe()
                    Toast.makeText(
                        this@AdminTerminalDetalheActivity,
                        "Estado do terminal atualizado",
                        Toast.LENGTH_SHORT
                    ).show()
                }
                .onFailure {
                    atualizarDetalhe()
                    Toast.makeText(
                        this@AdminTerminalDetalheActivity,
                        "Nao foi possivel alterar o estado do terminal",
                        Toast.LENGTH_SHORT
                    ).show()
                }
                .tratarSemPermissao(this@AdminTerminalDetalheActivity)
        }
    }

    private fun eliminarTerminal() {
        AlertDialog.Builder(this)
            .setTitle("Eliminar terminal")
            .setMessage("Esta operacao remove o terminal selecionado.")
            .setPositiveButton("Eliminar") { _, _ ->
                val detalheView = findViewById<TextView>(R.id.tv_admin_terminal_detalhe)
                detalheView.text = "A eliminar terminal..."

                lifecycleScope.launch {
                    AdminApiRepository.deleteSelectedTerminal()
                        .onSuccess {
                            Toast.makeText(
                                this@AdminTerminalDetalheActivity,
                                "Terminal eliminado",
                                Toast.LENGTH_SHORT
                            ).show()
                            finish()
                        }
                        .onFailure {
                            atualizarDetalhe()
                            Toast.makeText(
                                this@AdminTerminalDetalheActivity,
                                "Nao foi possivel eliminar o terminal",
                                Toast.LENGTH_SHORT
                            ).show()
                        }
                        .tratarSemPermissao(this@AdminTerminalDetalheActivity)
                }
            }
            .setNegativeButton("Cancelar", null)
            .show()
    }
}
