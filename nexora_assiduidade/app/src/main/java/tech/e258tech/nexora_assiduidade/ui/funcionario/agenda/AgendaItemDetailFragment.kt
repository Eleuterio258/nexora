package tech.e258tech.nexora_assiduidade.ui.funcionario.agenda

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.fragment.app.Fragment
import tech.e258tech.nexora_assiduidade.R

/**
 * Tela de Detalhe do Item de Agenda
 * Exibe detalhes de um item específico da agenda
 */
class AgendaItemDetailFragment : Fragment() {

    companion object {
        private const val ARG_TITLE = "arg_title"
        private const val ARG_DESCRIPTION = "arg_description"
        private const val ARG_DURATION = "arg_duration"

        fun newInstance(title: String, description: String, duration: String) =
            AgendaItemDetailFragment().apply {
                arguments = Bundle().apply {
                    putString(ARG_TITLE, title)
                    putString(ARG_DESCRIPTION, description)
                    putString(ARG_DURATION, duration)
                }
            }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.funcionario_agenda_item_detail, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val tvTitle = view.findViewById<TextView>(R.id.tvItemTitle)
        val tvDescription = view.findViewById<TextView>(R.id.tvItemDescription)
        val tvDuration = view.findViewById<TextView>(R.id.tvItemDuration)

        tvTitle.text = arguments?.getString(ARG_TITLE) ?: "Título do Item"
        tvDescription.text = arguments?.getString(ARG_DESCRIPTION) ?: "Descrição do item de agenda"
        tvDuration.text = arguments?.getString(ARG_DURATION) ?: "Duração: 30 minutos"
    }
}
