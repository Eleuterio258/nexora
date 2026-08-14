package tech.e258tech.paycore

import android.os.Bundle
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.lifecycle.lifecycleScope
import com.google.android.material.button.MaterialButton
import com.google.android.material.textfield.TextInputEditText
import com.google.gson.Gson
import com.google.zxing.BarcodeFormat
import com.journeyapps.barcodescanner.BarcodeEncoder
import kotlinx.coroutines.launch
import tech.e258tech.paycore.api.Permissoes
import tech.e258tech.paycore.utils.PermissaoHelper.tratarSemPermissao
import tech.e258tech.paycore.utils.PermissaoHelper.verificarPermissaoOuFechar

class AdminTerminalCriarActivity : AppCompatActivity() {

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

        setContentView(R.layout.activity_admin_terminal_criar)

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.layout_header)) { view, insets ->
            val sb = insets.getInsets(WindowInsetsCompat.Type.statusBars())
            view.setPadding(view.paddingLeft, sb.top, view.paddingRight, view.paddingBottom)
            insets
        }

        findViewById<MaterialButton>(R.id.btn_admin_terminal_criar_voltar).setOnClickListener { finish() }
        findViewById<MaterialButton>(R.id.btn_admin_terminal_gerar).setOnClickListener {
            val nome = findViewById<TextInputEditText>(R.id.et_admin_terminal_nome).text?.toString().orEmpty().trim()
            val serial = findViewById<TextInputEditText>(R.id.et_admin_terminal_serial).text?.toString().orEmpty().trim()
            val modelo = findViewById<TextInputEditText>(R.id.et_admin_terminal_modelo).text?.toString().orEmpty().trim()
            val resultadoView = findViewById<TextView>(R.id.tv_admin_terminal_codigo)

            if (nome.isBlank() || serial.isBlank()) {
                resultadoView.text = "Preencha nome e serial antes de enviar."
                return@setOnClickListener
            }

            resultadoView.text = "A criar terminal..."

            lifecycleScope.launch {
                AdminApiRepository.createTerminal(nome, serial, modelo)
                    .onSuccess { terminal ->
                        resultadoView.text = """
                            Terminal criado:
                            Nome: ${terminal.nome}
                            Serial: ${terminal.serial}
                            Modelo: ${terminal.modelo.ifBlank { "N/D" }}
                            activationCode: ${terminal.activationCode}
                        """.trimIndent()
                        mostrarQrDeActivacao(terminal.serial, terminal.activationCode)
                        Toast.makeText(this@AdminTerminalCriarActivity, "Terminal criado via API", Toast.LENGTH_SHORT).show()
                    }
                    .onFailure {
                        resultadoView.text = """
                            Falha ao criar via API.
                            Nome: $nome
                            Serial: $serial
                            Modelo: ${modelo.ifBlank { "N/D" }}
                        """.trimIndent()
                        Toast.makeText(this@AdminTerminalCriarActivity, "Nao foi possivel criar terminal na API", Toast.LENGTH_SHORT).show()
                    }
                    .tratarSemPermissao(this@AdminTerminalCriarActivity)
            }
        }
    }

    /**
     * Desenha o QR que o ecrã de login do terminal (LoginTerminalActivity) lê.
     *
     * O formato tem de ser exactamente o que lá é desserializado —
     * {"serialNumber":"…","activationCode":"…"} — por isso usa-se o Gson em vez
     * de compor a string à mão: garante o escape correcto se o serial trouxer
     * aspas ou acentos.
     *
     * Só há uma oportunidade de o mostrar. A partir daqui o código de activação
     * existe apenas como hash bcrypt no servidor, e nem o ERP nem este app o
     * conseguem recuperar para gerar o QR mais tarde.
     */
    private fun mostrarQrDeActivacao(serial: String, activationCode: String) {
        val imagem = findViewById<ImageView>(R.id.iv_admin_terminal_qr)
        val ajuda = findViewById<TextView>(R.id.tv_admin_terminal_qr_ajuda)

        val conteudo = Gson().toJson(QrActivacao(serial, activationCode))

        try {
            // 640px é o suficiente para ser lido do ecrã de outro aparelho sem
            // que o bitmap fique pesado de manter em memória.
            val bitmap = BarcodeEncoder().encodeBitmap(conteudo, BarcodeFormat.QR_CODE, 640, 640)
            imagem.setImageBitmap(bitmap)
            imagem.visibility = View.VISIBLE
            ajuda.visibility = View.VISIBLE
        } catch (e: Exception) {
            // O código em texto continua no ecrã: a falha do QR não impede a
            // activação manual do terminal.
            imagem.visibility = View.GONE
            ajuda.visibility = View.GONE
        }
    }

    /** Espelha o QrPayload lido em LoginTerminalActivity. */
    private data class QrActivacao(
        val serialNumber: String,
        val activationCode: String
    )
}
