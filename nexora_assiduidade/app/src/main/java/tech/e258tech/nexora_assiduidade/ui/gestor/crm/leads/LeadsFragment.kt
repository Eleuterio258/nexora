package tech.e258tech.nexora_assiduidade.ui.gestor.crm.leads

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.Spinner
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
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
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.ui.auth.LoginActivity
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.PermissionUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Lista de Leads — GET /api/crm/leads (ERP).
 */
class LeadsFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private lateinit var sessionManager: SessionManager

    private val estadoOpcoes = listOf(null) + Lead.ESTADOS.keys.toList()

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return inflater.inflate(R.layout.gestor_crm_leads, container, false)
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

        val recyclerView = view.findViewById<RecyclerView>(R.id.recyclerViewLeads)
        recyclerView.layoutManager = LinearLayoutManager(context)

        val spEstado = view.findViewById<Spinner>(R.id.spEstadoFiltro)
        spEstado.adapter = ArrayAdapter(
            requireContext(),
            android.R.layout.simple_spinner_dropdown_item,
            listOf("Todos os estados") + estadoOpcoes.drop(1).map { Lead.estadoLabel(it!!) }
        )

        val btnNovoLead = view.findViewById<Button>(R.id.btnNovoLead)
        btnNovoLead.visibility = if (PermissionUtils.has(sessionManager, "crm", "gerir_leads")) View.VISIBLE else View.GONE
        btnNovoLead.setOnClickListener {
            (activity as? LoginActivity)?.pushFragment(LeadFormFragment.newInstance())
        }

        view.findViewById<Button>(R.id.btnSearch).setOnClickListener {
            loadLeads(view)
        }

        spEstado.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>?, v: View?, position: Int, id: Long) {
                loadLeads(view)
            }
            override fun onNothingSelected(parent: AdapterView<*>?) {}
        }

        loadLeads(view)
    }

    override fun onResume() {
        super.onResume()
        view?.let { loadLeads(it) }
    }

    private fun loadLeads(view: View) {
        val token = sessionManager.getToken()
        val recyclerView = view.findViewById<RecyclerView>(R.id.recyclerViewLeads)
        val tvEmpty = view.findViewById<TextView>(R.id.tvEmpty)
        val spEstado = view.findViewById<Spinner>(R.id.spEstadoFiltro)
        val etSearch = view.findViewById<TextInputEditText>(R.id.etSearch)

        if (token.isNullOrBlank()) {
            tvEmpty.visibility = View.VISIBLE
            tvEmpty.text = "Sessão inválida. Faça login novamente."
            return
        }

        val estadoSelecionado = estadoOpcoes.getOrNull(spEstado.selectedItemPosition)
        val search = etSearch.text?.toString()?.trim()?.takeIf { it.isNotBlank() }

        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getLeads(
                        ApiUtils.bearerToken(token),
                        estado = estadoSelecionado,
                        search = search,
                        limit = 50
                    )
                }

                if (!response.isSuccessful || response.body() == null) {
                    tvEmpty.visibility = View.VISIBLE
                    tvEmpty.text = ApiUtils.errorMessage(response)
                    recyclerView.visibility = View.GONE
                    return@launch
                }

                val items = response.body()?.data.orEmpty()
                if (items.isEmpty()) {
                    tvEmpty.visibility = View.VISIBLE
                    tvEmpty.text = "Sem leads para mostrar."
                    recyclerView.visibility = View.GONE
                } else {
                    tvEmpty.visibility = View.GONE
                    recyclerView.visibility = View.VISIBLE
                    recyclerView.adapter = LeadsAdapter(items) { lead ->
                        (activity as? LoginActivity)?.pushFragment(DetalheLeadFragment.newInstance(lead.id))
                    }
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvEmpty.visibility = View.VISIBLE
                tvEmpty.text = "Não foi possível carregar os leads."
                recyclerView.visibility = View.GONE
                Toast.makeText(context, "Falha ao consultar o ERP.", Toast.LENGTH_LONG).show()
            }
        }
    }
}
