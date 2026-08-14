package tech.e258tech.paycore

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageButton
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.chip.Chip
import kotlinx.coroutines.launch
import tech.e258tech.paycore.api.Permissoes
import tech.e258tech.paycore.utils.PermissaoHelper.verificarPermissaoOuFechar
import java.util.Calendar

private enum class PeriodoHistorico { HOJE, SEMANA, MES }

class HistoricoActivity : AppCompatActivity() {

    private lateinit var rvHistorico: RecyclerView
    private lateinit var tvVazio: TextView
    private lateinit var tvTotal: TextView
    private lateinit var chipHoje: Chip
    private lateinit var chipSemana: Chip
    private lateinit var chipMes: Chip
    private lateinit var adapter: TransacaoAdapter

    private var periodo = PeriodoHistorico.HOJE

    override fun onResume() {
        super.onResume()
        atualizarLista()
        // Puxa histórico actualizado do ERP em segundo plano — o que já está
        // em Room/memória aparece de imediato, isto só complementa com vendas
        // feitas noutros terminais (ver PosStore.sincronizarHistoricoDoServidor).
        lifecycleScope.launch {
            if (PosStore.sincronizarHistoricoDoServidor()) atualizarLista()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!verificarPermissaoOuFechar(Permissoes.MODULO_POS, Permissoes.OPERAR_POS)) return
        setContentView(R.layout.activity_historico)

        rvHistorico = findViewById(R.id.rv_historico)
        tvVazio     = findViewById(R.id.tv_historico_vazio)
        tvTotal     = findViewById(R.id.tv_total_periodo)
        chipHoje    = findViewById(R.id.chip_hoje)
        chipSemana  = findViewById(R.id.chip_semana)
        chipMes     = findViewById(R.id.chip_mes)

        rvHistorico.layoutManager = LinearLayoutManager(this)
        adapter = TransacaoAdapter { transacao ->
            PosStore.selecionarTransacao(transacao.id)
            startActivity(Intent(this, DetalheTransacaoActivity::class.java))
        }
        rvHistorico.adapter = adapter

        findViewById<ImageButton>(R.id.btn_voltar).setOnClickListener { finish() }

        chipHoje.setOnClickListener { selecionarPeriodo(PeriodoHistorico.HOJE) }
        chipSemana.setOnClickListener { selecionarPeriodo(PeriodoHistorico.SEMANA) }
        chipMes.setOnClickListener { selecionarPeriodo(PeriodoHistorico.MES) }
    }

    private fun selecionarPeriodo(novo: PeriodoHistorico) {
        if (periodo == novo) return
        periodo = novo
        atualizarLista()
    }

    private fun atualizarLista() {
        atualizarChips()

        val desde = inicioDoPeriodo(periodo)
        val transacoes = PosStore.transacoesRecentes().filter { it.dataHora >= desde }

        adapter.atualizar(transacoes)
        tvVazio.visibility      = if (transacoes.isEmpty()) View.VISIBLE else View.GONE
        rvHistorico.visibility  = if (transacoes.isEmpty()) View.GONE else View.VISIBLE

        val total = transacoes.filter { it.estado == "Aprovado" }.sumOf { it.total }
        tvTotal.text = PosStore.formatarValor(total)
    }

    private fun inicioDoPeriodo(periodo: PeriodoHistorico): Long {
        val cal = Calendar.getInstance()
        when (periodo) {
            PeriodoHistorico.HOJE -> {
                cal.set(Calendar.HOUR_OF_DAY, 0)
                cal.set(Calendar.MINUTE, 0)
                cal.set(Calendar.SECOND, 0)
                cal.set(Calendar.MILLISECOND, 0)
            }
            PeriodoHistorico.SEMANA -> cal.add(Calendar.DAY_OF_YEAR, -7)
            PeriodoHistorico.MES    -> cal.add(Calendar.DAY_OF_YEAR, -30)
        }
        return cal.timeInMillis
    }

    private fun atualizarChips() {
        val chips = listOf(chipHoje to PeriodoHistorico.HOJE, chipSemana to PeriodoHistorico.SEMANA, chipMes to PeriodoHistorico.MES)
        for ((chip, valor) in chips) {
            val selecionado = valor == periodo
            chip.isChecked = selecionado
            chip.chipBackgroundColor = ContextCompat.getColorStateList(this, if (selecionado) R.color.colorPrimary else R.color.white)
            chip.setTextColor(ContextCompat.getColor(this, if (selecionado) R.color.white else R.color.text_secondary))
            chip.chipStrokeColor = ContextCompat.getColorStateList(this, if (selecionado) R.color.colorPrimary else R.color.divider)
        }
    }

    private inner class TransacaoAdapter(
        private val onClick: (TransacaoPDV) -> Unit
    ) : RecyclerView.Adapter<TransacaoAdapter.VH>() {

        private val itens = mutableListOf<TransacaoPDV>()

        inner class VH(view: View) : RecyclerView.ViewHolder(view) {
            val tvReferencia: TextView = view.findViewById(R.id.tv_item_transacao_referencia)
            val tvSubtitulo : TextView = view.findViewById(R.id.tv_item_transacao_subtitulo)
            val tvValor     : TextView = view.findViewById(R.id.tv_item_transacao_valor)
            val tvEstado    : TextView = view.findViewById(R.id.tv_item_transacao_estado)
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int) = VH(
            LayoutInflater.from(parent.context).inflate(R.layout.item_transacao, parent, false)
        )

        override fun getItemCount() = itens.size

        fun atualizar(novos: List<TransacaoPDV>) {
            itens.clear()
            itens.addAll(novos)
            notifyDataSetChanged()
        }

        override fun onBindViewHolder(holder: VH, position: Int) {
            val transacao = itens[position]
            val aprovada = transacao.estado == "Aprovado"

            holder.tvReferencia.text = transacao.referencia
            holder.tvSubtitulo.text = listOf(transacao.metodo, PosStore.formatarDataHora(transacao.dataHora))
                .filter { it.isNotBlank() }
                .joinToString(" · ")
            holder.tvValor.text = PosStore.formatarValor(transacao.total)
            holder.tvEstado.text = transacao.estado
            holder.tvEstado.setTextColor(
                ContextCompat.getColor(holder.itemView.context, if (aprovada) R.color.colorSuccess else R.color.colorError)
            )
            holder.itemView.setOnClickListener { onClick(transacao) }
        }
    }
}
