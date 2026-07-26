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
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.Lead
import tech.e258tech.nexora_assiduidade.data.model.LeadEstadoRequest
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.ui.auth.LoginActivity
import tech.e258tech.nexora_assiduidade.ui.gestor.crm.atividades.AtividadeFormFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.crm.atividades.AtividadesAdapter
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.PermissionUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Detalhe do Lead — GET /api/crm/leads/{id} (ERP).
 */
class DetalheLeadFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private lateinit var sessionManager: SessionManager

    /** Estados não-terminais (exclui "convertido", só alcançável via /converter). */
    private val estadosNaoTerminais = Lead.ESTADOS.keys.filter { it != "convertido" }

    companion object {
        private const val ARG_LEAD_ID = "lead_id"

        fun newInstance(leadId: Long): DetalheLeadFragment {
            return DetalheLeadFragment().apply {
                arguments = Bundle().apply { putLong(ARG_LEAD_ID, leadId) }
            }
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return inflater.inflate(R.layout.gestor_crm_detalhe_lead, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        sessionManager = SessionManager(requireContext())

        view.findViewById<View>(R.id.ivBack).setOnClickListener {
            parentFragmentManager.popBackStack()
        }

        val leadId = arguments?.getLong(ARG_LEAD_ID)
        if (leadId == null) {
            view.findViewById<TextView>(R.id.tvNome).text = "Lead inválido."
            return
        }

        carregarLead(view, leadId)
        carregarAtividades(view, leadId)

        view.findViewById<Button>(R.id.btnAdicionarAtividade).setOnClickListener {
            (activity as? LoginActivity)?.pushFragment(AtividadeFormFragment.newInstance(leadId = leadId))
        }
        view.findViewById<Button>(R.id.btnAdicionarAtividade).visibility =
            if (PermissionUtils.has(sessionManager, "crm", "gerir_atividades")) View.VISIBLE else View.GONE
    }

    override fun onResume() {
        super.onResume()
        val leadId = arguments?.getLong(ARG_LEAD_ID) ?: return
        view?.let {
            carregarLead(it, leadId)
            carregarAtividades(it, leadId)
        }
    }

    private fun carregarLead(view: View, leadId: Long) {
        val token = sessionManager.getToken()
        val tvNome = view.findViewById<TextView>(R.id.tvNome)
        if (token.isNullOrBlank()) {
            tvNome.text = "Sessão inválida. Faça login novamente."
            return
        }

        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getLead(ApiUtils.bearerToken(token), leadId)
                }
                if (!response.isSuccessful || response.body() == null) {
                    tvNome.text = ApiUtils.errorMessage(response)
                    return@launch
                }
                bindLead(view, response.body()!!, leadId)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvNome.text = "Não foi possível carregar o lead."
                Toast.makeText(context, "Falha ao consultar o ERP.", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun bindLead(view: View, lead: Lead, leadId: Long) {
        view.findViewById<TextView>(R.id.tvNome).text = lead.nome
        view.findViewById<TextView>(R.id.tvEmpresa).text = "Empresa: ${lead.empresa ?: "-"}"
        view.findViewById<TextView>(R.id.tvEmail).text = "Email: ${lead.email ?: "-"}"
        view.findViewById<TextView>(R.id.tvTelefone).text = "Telefone: ${lead.telefone ?: "-"}"
        view.findViewById<TextView>(R.id.tvOrigem).text = "Origem: ${Lead.origemLabel(lead.origem)}"
        view.findViewById<TextView>(R.id.tvResponsavel).text = "Responsável: ${lead.responsavel ?: "-"}"
        view.findViewById<TextView>(R.id.tvNotas).text = "Notas: ${lead.notas ?: "-"}"
        view.findViewById<TextView>(R.id.tvEstadoAtual).text = "Estado: ${Lead.estadoLabel(lead.estado)}"
        view.findViewById<TextView>(R.id.tvCriadoEm).text = "Criado em: ${lead.created_at}"

        val convertido = lead.estado == "convertido"

        val btnEditar = view.findViewById<Button>(R.id.btnEditar)
        btnEditar.visibility = if (PermissionUtils.has(sessionManager, "crm", "gerir_leads")) View.VISIBLE else View.GONE
        btnEditar.setOnClickListener {
            (activity as? LoginActivity)?.pushFragment(LeadFormFragment.newInstance(leadId))
        }

        val layoutEstado = view.findViewById<View>(R.id.layoutEstadoSection)
        val podeMoverEstado = PermissionUtils.has(sessionManager, "crm", "mover_leads") && !convertido
        layoutEstado.visibility = if (podeMoverEstado) View.VISIBLE else View.GONE
        if (podeMoverEstado) {
            val spEstado = view.findViewById<Spinner>(R.id.spEstadoNovo)
            spEstado.adapter = ArrayAdapter(
                requireContext(),
                android.R.layout.simple_spinner_dropdown_item,
                estadosNaoTerminais.map { Lead.estadoLabel(it) }
            )
            val idx = estadosNaoTerminais.indexOf(lead.estado)
            if (idx >= 0) spEstado.setSelection(idx)

            view.findViewById<Button>(R.id.btnActualizarEstado).setOnClickListener {
                actualizarEstado(view, leadId, estadosNaoTerminais[spEstado.selectedItemPosition])
            }
        }

        val btnConverter = view.findViewById<Button>(R.id.btnConverter)
        btnConverter.visibility =
            if (PermissionUtils.has(sessionManager, "crm", "converter_leads") && !convertido) View.VISIBLE else View.GONE
        btnConverter.setOnClickListener {
            (activity as? LoginActivity)?.pushFragment(ConverterLeadFragment.newInstance(leadId))
        }

        val btnEliminar = view.findViewById<Button>(R.id.btnEliminar)
        btnEliminar.visibility = if (PermissionUtils.has(sessionManager, "crm", "eliminar_leads")) View.VISIBLE else View.GONE
        btnEliminar.setOnClickListener {
            confirmarEliminar(view, leadId)
        }
    }

    private fun actualizarEstado(view: View, leadId: Long, novoEstado: String) {
        val token = sessionManager.getToken() ?: return
        val tvStatus = view.findViewById<TextView>(R.id.tvStatus)
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.moverLead(ApiUtils.bearerToken(token), leadId, LeadEstadoRequest(novoEstado))
                }
                if (response.isSuccessful) {
                    tvStatus.text = "Estado actualizado."
                    carregarLead(view, leadId)
                } else {
                    tvStatus.text = ApiUtils.errorMessage(response)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvStatus.text = "Falha ao actualizar o estado."
            }
        }
    }

    private fun confirmarEliminar(view: View, leadId: Long) {
        MaterialAlertDialogBuilder(requireContext())
            .setTitle("Eliminar lead")
            .setMessage("Eliminar este lead? Esta ação não pode ser desfeita.")
            .setNegativeButton("Cancelar", null)
            .setPositiveButton("Eliminar") { _, _ -> eliminar(view, leadId) }
            .show()
    }

    private fun eliminar(view: View, leadId: Long) {
        val token = sessionManager.getToken() ?: return
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.eliminarLead(ApiUtils.bearerToken(token), leadId)
                }
                if (response.isSuccessful) {
                    Toast.makeText(context, "Lead eliminado.", Toast.LENGTH_SHORT).show()
                    parentFragmentManager.popBackStack()
                } else {
                    view.findViewById<TextView>(R.id.tvStatus).text = ApiUtils.errorMessage(response)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                view.findViewById<TextView>(R.id.tvStatus).text = "Falha ao eliminar o lead."
            }
        }
    }

    private fun carregarAtividades(view: View, leadId: Long) {
        val token = sessionManager.getToken() ?: return
        val recyclerView = view.findViewById<RecyclerView>(R.id.recyclerViewAtividades)
        val tvEmpty = view.findViewById<TextView>(R.id.tvAtividadesEmpty)
        recyclerView.layoutManager = LinearLayoutManager(context)

        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getAtividades(ApiUtils.bearerToken(token), leadId = leadId)
                }
                val itens = response.body()?.data.orEmpty()
                if (itens.isEmpty()) {
                    tvEmpty.visibility = View.VISIBLE
                    recyclerView.visibility = View.GONE
                } else {
                    tvEmpty.visibility = View.GONE
                    recyclerView.visibility = View.VISIBLE
                    recyclerView.adapter = AtividadesAdapter(
                        items = itens,
                        onClick = null,
                        onConcluir = { atividade -> concluirAtividade(view, leadId, atividade.id) },
                        podeConcluir = PermissionUtils.has(sessionManager, "crm", "gerir_atividades")
                    )
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvEmpty.visibility = View.VISIBLE
                recyclerView.visibility = View.GONE
            }
        }
    }

    private fun concluirAtividade(view: View, leadId: Long, atividadeId: Long) {
        val token = sessionManager.getToken() ?: return
        uiScope.launch {
            try {
                withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.concluirAtividade(ApiUtils.bearerToken(token), atividadeId)
                }
                carregarAtividades(view, leadId)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                Toast.makeText(context, "Falha ao concluir a atividade.", Toast.LENGTH_SHORT).show()
            }
        }
    }
}
