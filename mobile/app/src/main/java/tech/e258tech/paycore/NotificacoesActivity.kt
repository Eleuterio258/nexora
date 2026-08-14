package tech.e258tech.paycore

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.button.MaterialButton
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.paycore.db.AppDatabase
import tech.e258tech.paycore.db.NotificacaoEntity

class NotificacoesActivity : AppCompatActivity() {

    private val notificacoes = mutableListOf<NotificacaoEntity>()
    private lateinit var adapter: NotificacaoAdapter

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = android.graphics.Color.TRANSPARENT
        window.navigationBarColor = android.graphics.Color.WHITE
        WindowInsetsControllerCompat(window, window.decorView).apply {
            isAppearanceLightStatusBars = true
            isAppearanceLightNavigationBars = true
        }

        setContentView(R.layout.activity_notificacoes)

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.layout_header)) { view, insets ->
            val sb = insets.getInsets(WindowInsetsCompat.Type.statusBars())
            view.setPadding(view.paddingLeft, sb.top, view.paddingRight, view.paddingBottom)
            insets
        }

        findViewById<android.widget.ImageButton>(R.id.btn_voltar).setOnClickListener { finish() }

        val rv = findViewById<RecyclerView>(R.id.rv_notificacoes)
        val layoutVazio = findViewById<View>(R.id.layout_vazio)
        adapter = NotificacaoAdapter(notificacoes)

        rv.layoutManager = LinearLayoutManager(this)
        rv.adapter = adapter

        carregarNotificacoes(rv, layoutVazio)

        findViewById<MaterialButton>(R.id.btn_marcar_todas).setOnClickListener {
            lifecycleScope.launch {
                withContext(Dispatchers.IO) {
                    AppDatabase.getInstance(this@NotificacoesActivity).notificacaoDao().marcarTodasLidas()
                }
                notificacoes.replaceAll { it.copy(lida = true) }
                adapter.notifyDataSetChanged()
            }
        }
    }

    private fun carregarNotificacoes(rv: View, vazio: View) {
        lifecycleScope.launch {
            val itens = withContext(Dispatchers.IO) {
                AppDatabase.getInstance(this@NotificacoesActivity).notificacaoDao().getAll()
            }
            notificacoes.clear()
            notificacoes.addAll(itens)
            adapter.notifyDataSetChanged()
            atualizarVazio(rv, vazio)
        }
    }

    private fun atualizarVazio(rv: View, vazio: View) {
        val temItens = notificacoes.isNotEmpty()
        rv.visibility    = if (temItens) View.VISIBLE else View.GONE
        vazio.visibility = if (temItens) View.GONE    else View.VISIBLE
    }

    private inner class NotificacaoAdapter(
        private val itens: List<NotificacaoEntity>
    ) : RecyclerView.Adapter<NotificacaoAdapter.VH>() {

        inner class VH(view: View) : RecyclerView.ViewHolder(view) {
            val dot:      View     = view.findViewById(R.id.view_dot)
            val titulo:   TextView = view.findViewById(R.id.tv_notif_titulo)
            val mensagem: TextView = view.findViewById(R.id.tv_notif_mensagem)
            val hora:     TextView = view.findViewById(R.id.tv_notif_hora)
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int) = VH(
            LayoutInflater.from(parent.context).inflate(R.layout.item_notificacao, parent, false)
        )

        override fun getItemCount() = itens.size

        override fun onBindViewHolder(holder: VH, position: Int) {
            val notif = itens[position]
            holder.titulo.text   = notif.titulo
            holder.mensagem.text = notif.mensagem
            holder.hora.text     = PosStore.formatarDataHora(notif.dataHora)
            holder.dot.visibility = if (notif.lida) View.INVISIBLE else View.VISIBLE
            holder.titulo.alpha   = if (notif.lida) 0.5f else 1.0f
            holder.mensagem.alpha = if (notif.lida) 0.5f else 1.0f
        }
    }
}
