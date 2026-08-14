package tech.e258tech.paycore

import android.os.Bundle
import android.view.View
import android.widget.ScrollView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.google.android.material.button.MaterialButton
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.paycore.db.AppDatabase
import tech.e258tech.paycore.repository.CatalogRepository
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class SincronizacaoActivity : AppCompatActivity() {

    private lateinit var tvUltimoSync  : TextView
    private lateinit var tvPendencias  : TextView
    private lateinit var tvSyncEstado  : TextView
    private lateinit var tvSyncLog     : TextView
    private lateinit var layoutProgress: View
    private lateinit var scrollLog     : ScrollView
    private lateinit var btnSincronizar: MaterialButton
    private val logBuilder = StringBuilder()

    override fun onResume() {
        super.onResume()
        atualizarPendencias()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_sincronizacao)

        tvUltimoSync   = findViewById(R.id.tv_ultimo_sync)
        tvPendencias   = findViewById(R.id.tv_pendencias)
        tvSyncEstado   = findViewById(R.id.tv_sync_estado)
        tvSyncLog      = findViewById(R.id.tv_sync_log)
        layoutProgress = findViewById(R.id.layout_sync_progress)
        scrollLog      = findViewById(R.id.scroll_log)
        btnSincronizar = findViewById(R.id.btn_sincronizar_agora)

        atualizarUltimoSync()

        btnSincronizar.setOnClickListener { iniciarSincronizacao() }
    }

    private fun atualizarUltimoSync() {
        val ts = SincronizacaoManager.ultimoSync(this)
        tvUltimoSync.text = if (ts == 0L) {
            "Nunca sincronizado"
        } else {
            "Ultimo sync: ${SimpleDateFormat("dd/MM/yyyy HH:mm", Locale.getDefault()).format(Date(ts))}"
        }
    }

    /** Só leitura — sem acções (retry manual fica fora do âmbito, o SyncWorker já tenta
     * automaticamente tudo o que não estiver FALHADO, ver PosStore.sincronizarSessoesCaixaPendentes). */
    private fun atualizarPendencias() {
        lifecycleScope.launch {
            val texto = withContext(Dispatchers.IO) {
                val db = AppDatabase.getInstance(applicationContext)
                val vendasPendentes  = db.transacaoDao().contarPendentes()
                val vendasFalhadas   = db.transacaoDao().contarFalhadas()
                val estornosPendentes = db.estornoDao().contarPendentes()
                val estornosFalhados  = db.estornoDao().contarFalhados()
                val sessoesPendentes = db.sessaoCaixaDao().getPendentesAbertura().size +
                    db.sessaoCaixaDao().getPendentesFecho().size
                val sessoesFalhadas  = db.sessaoCaixaDao().contarFalhados()
                val ultimoErro = db.transacaoDao().ultimoErroFalhado()
                    ?: db.estornoDao().ultimoErroFalhado()
                    ?: db.sessaoCaixaDao().ultimoErroFalhado()

                buildString {
                    append("$vendasPendentes vendas pendentes")
                    if (vendasFalhadas > 0) append(" ($vendasFalhadas com falha)")
                    append(" · $estornosPendentes estornos pendentes")
                    if (estornosFalhados > 0) append(" ($estornosFalhados com falha)")
                    append(" · $sessoesPendentes sessões de caixa pendentes")
                    if (sessoesFalhadas > 0) append(" ($sessoesFalhadas com falha)")
                    if (ultimoErro != null) append("\nÚltimo erro: $ultimoErro")
                }
            }
            tvPendencias.text = texto
        }
    }

    private fun iniciarSincronizacao() {
        logBuilder.clear()
        tvSyncLog.text = ""
        layoutProgress.visibility = View.VISIBLE
        btnSincronizar.isEnabled  = false

        SincronizacaoManager.sincronizar(
            context     = this,
            onLog       = { msg ->
                logBuilder.appendLine(msg)
                tvSyncEstado.text = msg
                tvSyncLog.text    = logBuilder.toString()
                scrollLog.post { scrollLog.fullScroll(View.FOCUS_DOWN) }
            },
            onConcluido = { sucesso, erro ->
                layoutProgress.visibility = View.GONE
                btnSincronizar.isEnabled  = true
                if (sucesso) {
                    // SincronizacaoManager só escreve no Room — quem mantém o cache em
                    // memória do catálogo actualizado é o CatalogRepository.
                    Thread { CatalogRepository.carregarDoRoomSync(applicationContext) }.start()
                    atualizarUltimoSync()
                } else {
                    logBuilder.appendLine("ERRO: $erro")
                    tvSyncLog.text = logBuilder.toString()
                }
            }
        )
    }
}
