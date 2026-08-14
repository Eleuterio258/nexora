package tech.e258tech.paycore

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import com.google.android.material.button.MaterialButton
import tech.e258tech.paycore.api.Permissoes
import tech.e258tech.paycore.utils.PermissaoHelper.verificarPermissaoOuFechar

class ComprovativoActivity : AppCompatActivity() {

    private val requestBluetooth = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) mostrarSeletorImpressora()
        else Toast.makeText(this, "Permissao Bluetooth negada", Toast.LENGTH_SHORT).show()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!verificarPermissaoOuFechar(Permissoes.MODULO_POS, Permissoes.OPERAR_POS)) return
        setContentView(R.layout.activity_comprovativo)

        val transacao = PosStore.obterTransacao(intent.getStringExtra("transacao_id"))
        val tvStatus = findViewById<TextView>(R.id.tv_comprovativo_estado)
        val tvDetalhes = findViewById<TextView>(R.id.tv_comprovativo_detalhes)

        if (transacao != null) {
            tvStatus.text = transacao.estado
            tvDetalhes.text = buildString {
                appendLine("Referencia: ${transacao.referencia}")
                appendLine("Data / Hora: ${PosStore.formatarDataHora(transacao.dataHora)}")
                appendLine("Metodo: ${transacao.metodo}")
                appendLine("Operador: ${transacao.operadorNome}")
                append("Valor: ${PosStore.formatarValor(transacao.total)}")
            }
        }

        findViewById<MaterialButton>(R.id.btn_imprimir_comprovativo).setOnClickListener {
            iniciarImpressao()
        }

        findViewById<MaterialButton>(R.id.btn_comprovativo_nova_venda).setOnClickListener {
            startActivity(Intent(this, NovaVendaActivity::class.java))
        }
        findViewById<MaterialButton>(R.id.btn_comprovativo_inicio).setOnClickListener {
            startActivity(Intent(this, DashboardActivity::class.java))
        }
    }

    private fun iniciarImpressao() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT)
                != PackageManager.PERMISSION_GRANTED
            ) {
                requestBluetooth.launch(Manifest.permission.BLUETOOTH_CONNECT)
                return
            }
        }
        mostrarSeletorImpressora()
    }

    private fun mostrarSeletorImpressora() {
        val transacao = PosStore.obterTransacao(intent.getStringExtra("transacao_id")) ?: return
        val dispositivos = BluetoothPrinterHelper.dispositivosVinculados()

        if (dispositivos.isEmpty()) {
            Toast.makeText(this, "Nenhuma impressora Bluetooth vinculada", Toast.LENGTH_LONG).show()
            return
        }

        @Suppress("MissingPermission")
        val nomes = dispositivos.map { it.name ?: it.address }.toTypedArray()

        AlertDialog.Builder(this)
            .setTitle("Selecionar impressora")
            .setItems(nomes) { _, index ->
                val device = dispositivos[index]
                Toast.makeText(this, "A imprimir...", Toast.LENGTH_SHORT).show()
                Thread {
                    val resultado = BluetoothPrinterHelper.imprimir(device, transacao)
                    runOnUiThread {
                        if (resultado.isSuccess) {
                            Toast.makeText(this, "Impresso com sucesso", Toast.LENGTH_SHORT).show()
                        } else {
                            Toast.makeText(
                                this,
                                "Erro: ${resultado.exceptionOrNull()?.message}",
                                Toast.LENGTH_LONG
                            ).show()
                        }
                    }
                }.start()
            }
            .setNegativeButton("Cancelar", null)
            .show()
    }
}
