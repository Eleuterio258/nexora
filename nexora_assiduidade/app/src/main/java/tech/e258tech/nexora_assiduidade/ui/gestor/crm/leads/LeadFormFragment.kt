package tech.e258tech.nexora_assiduidade.ui.gestor.crm.leads

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.Spinner
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.google.android.material.textfield.TextInputEditText
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.Lead
import tech.e258tech.nexora_assiduidade.data.model.LeadRequest
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Criar/editar Lead — POST/PUT /api/crm/leads (ERP).
 */
class LeadFormFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val origens = Lead.ORIGENS.keys.toList()

    companion object {
        private const val ARG_LEAD_ID = "lead_id"

        fun newInstance(leadId: Long? = null): LeadFormFragment {
            return LeadFormFragment().apply {
                arguments = Bundle().apply {
                    leadId?.let { putLong(ARG_LEAD_ID, it) }
                }
            }
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return inflater.inflate(R.layout.gestor_crm_lead_form, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val leadId = arguments?.getLong(ARG_LEAD_ID)?.takeIf { it > 0 }

        view.findViewById<View>(R.id.ivBack).setOnClickListener {
            parentFragmentManager.popBackStack()
        }

        val spOrigem = view.findViewById<Spinner>(R.id.spOrigem)
        spOrigem.adapter = ArrayAdapter(
            requireContext(),
            android.R.layout.simple_spinner_dropdown_item,
            origens.map { Lead.origemLabel(it) }
        )

        view.findViewById<TextView>(R.id.tvTitle).text = if (leadId == null) "Novo Lead" else "Editar Lead"

        if (leadId != null) {
            carregarLead(view, leadId)
        }

        view.findViewById<Button>(R.id.btnGuardar).setOnClickListener {
            guardar(view, leadId)
        }
    }

    private fun carregarLead(view: View, leadId: Long) {
        val token = SessionManager(requireContext()).getToken() ?: return
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getLead(ApiUtils.bearerToken(token), leadId)
                }
                if (!response.isSuccessful || response.body() == null) {
                    view.findViewById<TextView>(R.id.tvStatus).text = ApiUtils.errorMessage(response)
                    return@launch
                }
                val lead = response.body()!!
                view.findViewById<TextInputEditText>(R.id.etNome).setText(lead.nome)
                view.findViewById<TextInputEditText>(R.id.etEmpresa).setText(lead.empresa)
                view.findViewById<TextInputEditText>(R.id.etEmail).setText(lead.email)
                view.findViewById<TextInputEditText>(R.id.etTelefone).setText(lead.telefone)
                view.findViewById<TextInputEditText>(R.id.etResponsavel).setText(lead.responsavel)
                view.findViewById<TextInputEditText>(R.id.etNotas).setText(lead.notas)
                val idx = origens.indexOf(lead.origem)
                if (idx >= 0) view.findViewById<Spinner>(R.id.spOrigem).setSelection(idx)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                view.findViewById<TextView>(R.id.tvStatus).text = "Não foi possível carregar o lead."
            }
        }
    }

    private fun guardar(view: View, leadId: Long?) {
        val token = SessionManager(requireContext()).getToken()
        if (token.isNullOrBlank()) {
            Toast.makeText(context, "Sessão inválida. Faça login novamente.", Toast.LENGTH_LONG).show()
            return
        }

        val nome = view.findViewById<TextInputEditText>(R.id.etNome).text?.toString()?.trim()
        val tvStatus = view.findViewById<TextView>(R.id.tvStatus)
        if (nome.isNullOrBlank()) {
            tvStatus.text = "O nome é obrigatório."
            return
        }

        val request = LeadRequest(
            nome = nome,
            empresa = view.findViewById<TextInputEditText>(R.id.etEmpresa).text?.toString()?.trim()?.takeIf { it.isNotBlank() },
            email = view.findViewById<TextInputEditText>(R.id.etEmail).text?.toString()?.trim()?.takeIf { it.isNotBlank() },
            telefone = view.findViewById<TextInputEditText>(R.id.etTelefone).text?.toString()?.trim()?.takeIf { it.isNotBlank() },
            origem = origens.getOrNull(view.findViewById<Spinner>(R.id.spOrigem).selectedItemPosition),
            responsavel = view.findViewById<TextInputEditText>(R.id.etResponsavel).text?.toString()?.trim()?.takeIf { it.isNotBlank() },
            notas = view.findViewById<TextInputEditText>(R.id.etNotas).text?.toString()?.trim()?.takeIf { it.isNotBlank() }
        )

        val btnGuardar = view.findViewById<Button>(R.id.btnGuardar)
        btnGuardar.isEnabled = false
        tvStatus.text = "A guardar..."

        uiScope.launch {
            try {
                val successful = withContext(Dispatchers.IO) {
                    if (leadId == null) {
                        RetrofitClient.erpApiService.criarLead(ApiUtils.bearerToken(token), request)
                    } else {
                        RetrofitClient.erpApiService.actualizarLead(ApiUtils.bearerToken(token), leadId, request)
                    }
                }

                if (successful.isSuccessful) {
                    Toast.makeText(context, "Lead guardado com sucesso.", Toast.LENGTH_SHORT).show()
                    parentFragmentManager.popBackStack()
                } else {
                    tvStatus.text = ApiUtils.errorMessage(successful)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvStatus.text = "Falha ao comunicar com o ERP."
            } finally {
                if (isAdded) btnGuardar.isEnabled = true
            }
        }
    }
}
