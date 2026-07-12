package tech.e258tech.nexora_assiduidade.ui.funcionario.modules

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.ui.funcionario.agenda.AgendaFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.attendance.JustifyAbsenceFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.notifications.NotificationsFragment

class ModulesFragment : Fragment() {

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.funcionario_modules, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        view.findViewById<View>(R.id.rowAgenda).setOnClickListener {
            openFragment(AgendaFragment())
        }
        view.findViewById<View>(R.id.rowNotifications).setOnClickListener {
            openFragment(NotificationsFragment())
        }
        view.findViewById<View>(R.id.rowJustify).setOnClickListener {
            openFragment(JustifyAbsenceFragment())
        }
    }

    private fun openFragment(fragment: Fragment) {
        parentFragmentManager.beginTransaction()
            .replace(R.id.fragment_container, fragment)
            .addToBackStack(null)
            .commit()
    }
}
