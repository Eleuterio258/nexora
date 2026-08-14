package tech.e258tech.paycore

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.RecyclerView
import androidx.viewpager2.widget.ViewPager2
import com.google.android.material.button.MaterialButton

class OnboardingActivity : AppCompatActivity() {

    companion object {
        const val PREFS_APP = "paycore_app"
        const val KEY_ONBOARDING_VISTO = "onboarding_visto"
    }

    private data class Slide(val imagemRes: Int, val titulo: String, val descricao: String)

    private val slides = listOf(
        Slide(R.drawable.paycore_pos,         "O Seu Negócio,\nMais Simples e Poderoso", "Bem-vindo ao PayCore POS, a solução completa e intuitiva para gerir o seu ponto de venda."),
        Slide(R.drawable.onboarding_pagamento,  "Múltiplos Métodos\nde Pagamento",          "Aceite Cartão, Dinheiro, M-Pesa, e-Mola e QR Code num só terminal."),
        Slide(R.drawable.paycore_dashboard,    "Controlo Total do\nSeu Negócio",          "Gerencie seu estoque em tempo real e acesse relatórios financeiros detalhados."),
        Slide(R.drawable.paycore_illustration, "A Sua Marca,\nO Seu Controlo",            "Personalize a aplicação com a sua marca e gira terminais remotamente de qualquer lugar.")
    )

    private lateinit var viewPager: ViewPager2
    private lateinit var btnProximo: MaterialButton
    private lateinit var llIndicadores: LinearLayout

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_onboarding)

        viewPager     = findViewById(R.id.vp_onboarding)
        btnProximo    = findViewById(R.id.btn_proximo)
        llIndicadores = findViewById(R.id.ll_indicadores)

        viewPager.adapter = SlideAdapter()
        configurarIndicadores()

        viewPager.registerOnPageChangeCallback(object : ViewPager2.OnPageChangeCallback() {
            override fun onPageSelected(position: Int) {
                atualizarIndicadores(position)
                btnProximo.text = if (position == slides.lastIndex) "Começar Agora" else "Próximo"
            }
        })

        btnProximo.setOnClickListener {
            val proximo = viewPager.currentItem + 1
            if (proximo < slides.size) {
                viewPager.currentItem = proximo
            } else {
                // Marca o onboarding como visto — só aparece na primeira vez.
                getSharedPreferences(PREFS_APP, MODE_PRIVATE).edit()
                    .putBoolean(KEY_ONBOARDING_VISTO, true).apply()
                // Sem licença/tenant activado neste aparelho ainda → activação primeiro
                // (mesma verificação que a SplashActivity faz no arranque).
                val tenantId = getSharedPreferences(tech.e258tech.paycore.ui.LoginTerminalActivity.PREFS_TERMINAL, MODE_PRIVATE)
                    .getString(tech.e258tech.paycore.ui.LoginTerminalActivity.KEY_TENANT_ID, "").orEmpty()
                val destino = if (tenantId.isEmpty()) AtivacaoLicencaActivity::class.java else LoginActivity::class.java
                startActivity(Intent(this, destino))
                finish()
            }
        }
    }

    private fun configurarIndicadores() {
        val params = LinearLayout.LayoutParams(16, 16).apply { setMargins(6, 0, 6, 0) }
        repeat(slides.size) { i ->
            val dot = View(this).apply {
                layoutParams = params
                setBackgroundResource(if (i == 0) R.drawable.dot_ativo else R.drawable.dot_inativo)
            }
            llIndicadores.addView(dot)
        }
    }

    private fun atualizarIndicadores(posicao: Int) {
        for (i in 0 until llIndicadores.childCount) {
            llIndicadores.getChildAt(i)
                .setBackgroundResource(if (i == posicao) R.drawable.dot_ativo else R.drawable.dot_inativo)
        }
    }

    private inner class SlideAdapter : RecyclerView.Adapter<RecyclerView.ViewHolder>() {

        private val TIPO_NORMAL   = 0
        private val TIPO_CONTROLO = 1
        private val TIPO_PAGAMENTO = 2

        inner class SlideVH(view: View) : RecyclerView.ViewHolder(view) {
            val imagem: ImageView   = view.findViewById(R.id.iv_slide_imagem)
            val titulo: TextView    = view.findViewById(R.id.tv_slide_titulo)
            val descricao: TextView = view.findViewById(R.id.tv_slide_descricao)
        }

        inner class PagamentoVH(view: View) : RecyclerView.ViewHolder(view)

        override fun getItemViewType(position: Int) = when {
            position == 1                      -> TIPO_PAGAMENTO
            position >= slides.size - 2        -> TIPO_CONTROLO
            else                               -> TIPO_NORMAL
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
            val inflater = LayoutInflater.from(parent.context)
            return when (viewType) {
                TIPO_PAGAMENTO -> PagamentoVH(inflater.inflate(R.layout.item_onboarding_slide_pagamento, parent, false))
                TIPO_CONTROLO  -> SlideVH(inflater.inflate(R.layout.item_onboarding_slide_controlo, parent, false))
                else           -> SlideVH(inflater.inflate(R.layout.item_onboarding_slide, parent, false))
            }
        }

        override fun getItemCount() = slides.size

        override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
            if (holder is SlideVH) {
                val slide = slides[position]
                holder.imagem.setImageResource(slide.imagemRes)
                holder.titulo.text    = slide.titulo
                holder.descricao.text = slide.descricao
            }
            // PagamentoVH: texto e ícones estão hardcoded no layout
        }
    }
}

