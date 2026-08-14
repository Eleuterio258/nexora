package tech.e258tech.paycore

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.text.InputType
import android.widget.ArrayAdapter
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.Spinner
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import com.google.android.material.button.MaterialButton
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.paycore.api.ApiClient
import tech.e258tech.paycore.api.EstornoParcialItemRequest
import tech.e258tech.paycore.api.EstornoParcialRequest
import tech.e258tech.paycore.api.Permissoes
import tech.e258tech.paycore.api.VendaItemDetalheDTO
import tech.e258tech.paycore.db.AppDatabase
import tech.e258tech.paycore.utils.PermissaoHelper.verificarPermissaoOuFechar

class DetalheTransacaoActivity : AppCompatActivity() {

    private val requestBluetooth = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) mostrarSeletorImpressora()
        else Toast.makeText(this, "Permissao Bluetooth negada", Toast.LENGTH_SHORT).show()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!verificarPermissaoOuFechar(Permissoes.MODULO_POS, Permissoes.OPERAR_POS)) return
        setContentView(R.layout.activity_detalhe_transacao)

        val transacao = PosStore.obterTransacao(intent.getStringExtra("transacao_id"))
        val tvDetalhes = findViewById<TextView>(R.id.tv_detalhe_transacao)
        if (transacao != null) {
            tvDetalhes.text = buildString {
                appendLine("Referencia: ${transacao.referencia}")
                appendLine("Data / Hora: ${PosStore.formatarDataHora(transacao.dataHora)}")
                appendLine("Metodo: ${transacao.metodo}")
                appendLine("Estado: ${transacao.estado}")
                appendLine("Operador: ${transacao.operadorNome}")
                append("Valor: ${PosStore.formatarValor(transacao.total)}")
            }
        }

        findViewById<MaterialButton>(R.id.btn_reimprimir_transacao).setOnClickListener {
            iniciarImpressao()
        }

        findViewById<MaterialButton>(R.id.btn_estornar_transacao).setOnClickListener {
            startActivity(Intent(this, EstornoActivity::class.java))
        }

        findViewById<MaterialButton>(R.id.btn_devolver_item).setOnClickListener {
            abrirDevolucaoItem()
        }
    }

    // Devolução de itens específicos — diferente do estorno total acima.
    // Só disponível depois da venda ter sincronizado (precisa do id de
    // servidor para GET pos/sales/{id} e POST .../estorno-parcial).
    private fun abrirDevolucaoItem() {
        val localId = intent.getStringExtra("transacao_id") ?: return
        lifecycleScope.launch {
            val serverId = AppDatabase.getInstance(this@DetalheTransacaoActivity)
                .transacaoDao().getById(localId)?.serverId
            if (serverId == null) {
                Toast.makeText(this@DetalheTransacaoActivity, "Venda ainda não sincronizada com o servidor.", Toast.LENGTH_LONG).show()
                return@launch
            }

            val resposta = runCatching { ApiClient.service.obterVenda(serverId) }.getOrNull()
            val detalhe = resposta?.takeIf { it.isSuccessful }?.body()
            if (detalhe == null) {
                Toast.makeText(this@DetalheTransacaoActivity, "Não foi possível obter os itens da venda.", Toast.LENGTH_LONG).show()
                return@launch
            }

            val disponiveis = detalhe.itens.filter { it.quantidade - it.quantidadeDevolvida > 0.0005 }
            if (disponiveis.isEmpty()) {
                Toast.makeText(this@DetalheTransacaoActivity, "Não há itens disponíveis para devolução.", Toast.LENGTH_LONG).show()
                return@launch
            }

            mostrarDialogDevolucao(serverId, disponiveis)
        }
    }

    private fun mostrarDialogDevolucao(vendaId: Long, itens: List<VendaItemDetalheDTO>) {
        val rotulos = itens.map { item ->
            val disponivel = item.quantidade - item.quantidadeDevolvida
            "${item.descricao ?: "Produto #${item.productId}"} ($disponivel disponível)"
        }.toTypedArray()
        val metodosTipo = arrayOf("numerario", "transferencia", "tpa", "mpesa", "emola", "outro")
        val metodosRotulo = arrayOf("Numerário", "Transferência", "TPA", "M-Pesa", "e-Mola", "Outro")

        val spinnerItem = Spinner(this).apply {
            adapter = ArrayAdapter(this@DetalheTransacaoActivity, android.R.layout.simple_spinner_dropdown_item, rotulos)
        }
        val etQuantidade = EditText(this).apply {
            hint = "Quantidade a devolver"
            inputType = InputType.TYPE_CLASS_NUMBER or InputType.TYPE_NUMBER_FLAG_DECIMAL
        }
        val spinnerMetodo = Spinner(this).apply {
            adapter = ArrayAdapter(this@DetalheTransacaoActivity, android.R.layout.simple_spinner_dropdown_item, metodosRotulo)
        }
        val etMotivo = EditText(this).apply { hint = "Motivo da devolução" }
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            val pad = (16 * resources.displayMetrics.density).toInt()
            setPadding(pad, pad, pad, 0)
            addView(spinnerItem)
            addView(etQuantidade)
            addView(spinnerMetodo)
            addView(etMotivo)
        }

        AlertDialog.Builder(this)
            .setTitle("Devolver item")
            .setView(container)
            .setPositiveButton("Devolver") { _, _ ->
                val item = itens[spinnerItem.selectedItemPosition]
                val disponivel = item.quantidade - item.quantidadeDevolvida
                val quantidade = etQuantidade.text.toString().toDoubleOrNull()
                val motivo = etMotivo.text.toString().trim()
                if (quantidade == null || quantidade <= 0 || quantidade > disponivel + 0.0005) {
                    Toast.makeText(this, "Quantidade inválida (máximo $disponivel)", Toast.LENGTH_SHORT).show()
                    return@setPositiveButton
                }
                if (motivo.isBlank()) {
                    Toast.makeText(this, "Indique o motivo da devolução", Toast.LENGTH_SHORT).show()
                    return@setPositiveButton
                }
                val metodo = metodosTipo[spinnerMetodo.selectedItemPosition]

                lifecycleScope.launch {
                    val resultado = runCatching {
                        ApiClient.service.estornoParcialVenda(
                            vendaId,
                            EstornoParcialRequest(
                                itens = listOf(EstornoParcialItemRequest(itemId = item.id, quantidade = quantidade)),
                                motivo = motivo,
                                metodo = metodo
                            )
                        )
                    }
                    val resposta = resultado.getOrNull()
                    if (resposta?.isSuccessful == true) {
                        val corpo = resposta.body()
                        Toast.makeText(
                            this@DetalheTransacaoActivity,
                            "Devolvido ${PosStore.formatarValor(corpo?.valorDevolvido ?: 0.0)}" +
                                (corpo?.creditNoteNumero?.let { " — nota de crédito $it" } ?: ""),
                            Toast.LENGTH_LONG
                        ).show()
                    } else {
                        Toast.makeText(this@DetalheTransacaoActivity, "Não foi possível registar a devolução.", Toast.LENGTH_LONG).show()
                    }
                }
            }
            .setNegativeButton("Cancelar", null)
            .show()
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
                lifecycleScope.launch {
                    // Tenta buscar o recibo actualizado do servidor (inclui
                    // cabeçalho fiscal e devoluções entretanto registadas);
                    // se a venda ainda não sincronizou ou o pedido falhar,
                    // imprime a partir dos dados locais como antes.
                    val serverId = AppDatabase.getInstance(this@DetalheTransacaoActivity)
                        .transacaoDao().getById(intent.getStringExtra("transacao_id") ?: "")?.serverId
                    val recibo = serverId?.let {
                        runCatching { ApiClient.service.obterRecibo(it) }
                            .getOrNull()?.takeIf { r -> r.isSuccessful }?.body()
                    }

                    val resultado = withContext(Dispatchers.IO) {
                        if (recibo != null) {
                            BluetoothPrinterHelper.imprimir(device, recibo)
                        } else {
                            BluetoothPrinterHelper.imprimir(device, transacao)
                        }
                    }
                    if (resultado.isSuccess) {
                        Toast.makeText(this@DetalheTransacaoActivity, "Impresso com sucesso", Toast.LENGTH_SHORT).show()
                    } else {
                        Toast.makeText(
                            this@DetalheTransacaoActivity,
                            "Erro: ${resultado.exceptionOrNull()?.message}",
                            Toast.LENGTH_LONG
                        ).show()
                    }
                }
            }
            .setNegativeButton("Cancelar", null)
            .show()
    }
}
