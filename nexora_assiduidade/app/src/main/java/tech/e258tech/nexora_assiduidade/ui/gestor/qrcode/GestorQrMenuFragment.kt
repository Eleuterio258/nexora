package tech.e258tech.nexora_assiduidade.ui.gestor.qrcode

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.cardview.widget.CardView
import androidx.fragment.app.Fragment
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.ui.auth.LoginActivity

/**
 * Menu de escolha entre os dois modos de QR Code:
 * 1. Gerar QR Fixo (gestor gera, funcionário lê)
 * 2. Ler QR do Funcionário (funcionário mostra, gestor lê)
 */
class GestorQrMenuFragment : Fragment() {

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return inflater.inflate(R.layout.gestor_qr_menu, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        view.findViewById<View>(R.id.ivBack).setOnClickListener {
            parentFragmentManager.popBackStack()
        }

        view.findViewById<CardView>(R.id.cardGerarQr).setOnClickListener {
            (activity as? LoginActivity)?.pushFragment(GestorGerarQrFragment())
        }

        view.findViewById<CardView>(R.id.cardLerQr).setOnClickListener {
            (activity as? LoginActivity)?.pushFragment(GestorLerQrFragment())
        }
    }
}
