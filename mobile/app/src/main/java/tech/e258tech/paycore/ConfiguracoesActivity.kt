package tech.e258tech.paycore

import android.content.Intent
import android.os.Bundle
import android.widget.LinearLayout
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.button.MaterialButton
import tech.e258tech.paycore.ui.LoginTerminalActivity

class ConfiguracoesActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_configuracoes)

        findViewById<LinearLayout>(R.id.item_impressora).setOnClickListener {
            startActivity(Intent(this, ImpressoraActivity::class.java))
        }

        findViewById<MaterialButton>(R.id.btn_logs).setOnClickListener {
            startActivity(Intent(this, SincronizacaoActivity::class.java))
        }

        // Sair: termina apenas a sessão do funcionário. O terminal continua configurado.
        findViewById<MaterialButton>(R.id.btn_logout).setOnClickListener {
            PosStore.logoutFuncionario()
            startActivity(
                Intent(this, LoginActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                }
            )
            finish()
        }

        // Desassociar terminal: limpa também os dados do terminal (aparelho).
        findViewById<MaterialButton>(R.id.btn_desassociar_terminal).setOnClickListener {
            AlertDialog.Builder(this)
                .setTitle("Desassociar terminal")
                .setMessage("Tem a certeza que deseja remover a configuração deste aparelho? Será necessário activar o terminal novamente.")
                .setPositiveButton("Desassociar") { _, _ ->
                    PosStore.logout()
                    startActivity(
                        Intent(this, LoginTerminalActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                        }
                    )
                    finish()
                }
                .setNegativeButton("Cancelar", null)
                .show()
        }
    }
}






