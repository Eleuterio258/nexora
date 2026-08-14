package tech.e258tech.paycore

import android.content.Intent
import android.os.Bundle
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.ViewModelProvider
import com.google.android.material.card.MaterialCardView
import tech.e258tech.paycore.api.Permissoes
import tech.e258tech.paycore.utils.PermissaoHelper.verificarPermissaoOuFechar
import tech.e258tech.paycore.viewmodel.ApplicationViewModelFactory
import tech.e258tech.paycore.viewmodel.PagamentoViewModel

class PagamentoActivity : AppCompatActivity() {

    private val viewModel by lazy {
        ViewModelProvider(this, ApplicationViewModelFactory { PagamentoViewModel(application) })[PagamentoViewModel::class.java]
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!verificarPermissaoOuFechar(Permissoes.MODULO_POS, Permissoes.OPERAR_POS)) return
        setContentView(R.layout.activity_pagamento)

        // sessaoAtualLocalId (não sessaoAtualId, que só existe depois de sincronizar) —
        // uma caixa aberta offline também deve permitir pagar.
        if (PosStore.sessaoAtualLocalId == null) {
            startActivity(Intent(this, AberturaCaixaActivity::class.java))
            finish()
            return
        }

        findViewById<TextView>(R.id.tv_pagamento_total).text =
            PosStore.formatarValor(viewModel.totalVendaAtual())

        findViewById<android.widget.ImageButton>(R.id.btn_voltar).setOnClickListener { finish() }

        val abrirComprovativo = { metodo: String ->
            val transacao = viewModel.processarPagamento(metodo)
            startActivity(
                Intent(this, ComprovativoActivity::class.java)
                    .putExtra("transacao_id", transacao.id)
            )
            finish()
        }

        findViewById<MaterialCardView>(R.id.btn_pagamento_cartao).setOnClickListener { abrirComprovativo("Cartao") }
        findViewById<MaterialCardView>(R.id.btn_pagamento_dinheiro).setOnClickListener { abrirComprovativo("Dinheiro") }
        findViewById<MaterialCardView>(R.id.btn_pagamento_mpesa).setOnClickListener { abrirComprovativo("M-Pesa") }
        findViewById<MaterialCardView>(R.id.btn_pagamento_emola).setOnClickListener { abrirComprovativo("e-Mola") }
        findViewById<MaterialCardView>(R.id.btn_pagamento_qr).setOnClickListener { abrirComprovativo("QR Code") }
    }
}
