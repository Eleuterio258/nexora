package tech.e258tech.nexora_assiduidade.ui.gestor.crm

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.cardview.widget.CardView
import androidx.fragment.app.Fragment
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.ui.auth.LoginActivity
import tech.e258tech.nexora_assiduidade.ui.gestor.crm.atividades.AtividadesFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.crm.leads.LeadsFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.crm.oportunidades.OportunidadesFragment

/**
 * Menu de escolha entre os 3 sub-módulos do CRM: Leads, Oportunidades e Atividades.
 */
class CrmMenuFragment : Fragment() {

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return inflater.inflate(R.layout.gestor_crm_menu, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        view.findViewById<View>(R.id.ivBack).setOnClickListener {
            parentFragmentManager.popBackStack()
        }

        view.findViewById<CardView>(R.id.cardLeads).setOnClickListener {
            (activity as? LoginActivity)?.pushFragment(LeadsFragment())
        }

        view.findViewById<CardView>(R.id.cardOportunidades).setOnClickListener {
            (activity as? LoginActivity)?.pushFragment(OportunidadesFragment())
        }

        view.findViewById<CardView>(R.id.cardAtividades).setOnClickListener {
            (activity as? LoginActivity)?.pushFragment(AtividadesFragment())
        }
    }
}
