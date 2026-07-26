package tech.e258tech.nexora_assiduidade.ui.gestor.crm.oportunidades

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
import tech.e258tech.nexora_assiduidade.data.model.Oportunidade
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.ui.auth.LoginActivity
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.PermissionUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Lista de Oportunidades — GET /api/crm/oportunidades (ERP).
 */
class OportunidadesFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private lateinit var sessionManager: SessionManager

    private val estagioOpcoes = listOf(null) + Oportunidade.ESTAGIOS.keys.toList()
    private var leadIdFiltro: Long? = null

    companion object {
        private const val ARG_LEAD_ID = "lead_id"

        fun newInstance(leadId: Long? = null): OportunidadesFragment {
            return OportunidadesFragment().apply {
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
        return inflater.inflate(R.layout.gestor_crm_oportunidades, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        sessionManager = SessionManager(requireContext())
        leadIdFiltro = arguments?.getLong(ARG_LEAD_ID)?.takeIf { it > 0 }

        view.findViewById<View>(R.id.ivBack).setOnClickListener {
            parentFragmentManager.popBackStack()
        }

        val recyclerView = view.findViewById<RecyclerView>(R.id.recyclerViewOportunidades)
        recyclerView.layoutManager = LinearLayoutManager(context)

        val spEstagio = view.findViewById<Spinner>(R.id.spEstagioFiltro)
        spEstagio.adapter = ArrayAdapter(
            requireContext(),
            android.R.layout.simple_spinner_dropdown_item,
            listOf("Todos os estágios") + estagioOpcoes.drop(1).map { Oportunidade.estagioLabel(it!!) }
        )

        val btnNova = view.findViewById<Button>(R.id.btnNovaOportunidade)
        btnNova.visibility = if (PermissionUtils.has(sessionManager, "crm", "gerir_oportunidades")) View.VISIBLE else View.GONE
        btnNova.setOnClickListener {
            (activity as? LoginActivity)?.pushFragment(OportunidadeFormFragment.newInstance())
        }

        view.findViewById<Button>(R.id.btnSearch).setOnClickListener {
            loadOportunidades(view)
        }

        spEstagio.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>?, v: View?, position: Int, id: Long) {
                loadOportunidades(view)
            }
            override fun onNothingSelected(parent: AdapterView<*>?) {}
        }

        loadOportunidades(view)
    }

    override fun onResume() {
        super.onResume()
        view?.let { loadOportunidades(it) }
    }

    private fun loadOportunidades(view: View) {
        val token = sessionManager.getToken()
        val recyclerView = view.findViewById<RecyclerView>(R.id.recyclerViewOportunidades)
        val tvEmpty = view.findViewById<TextView>(R.id.tvEmpty)
        val spEstagio = view.findViewById<Spinner>(R.id.spEstagioFiltro)
        val etSearch = view.findViewById<TextInputEditText>(R.id.etSearch)

        if (token.isNullOrBlank()) {
            tvEmpty.visibility = View.VISIBLE
            tvEmpty.text = "Sessão inválida. Faça login novamente."
            return
        }

        val estagioSelecionado = estagioOpcoes.getOrNull(spEstagio.selectedItemPosition)
        val search = etSearch.text?.toString()?.trim()?.takeIf { it.isNotBlank() }

        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getOportunidades(
                        ApiUtils.bearerToken(token),
                        estagio = estagioSelecionado,
                        leadId = leadIdFiltro,
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
                    tvEmpty.text = "Sem oportunidades para mostrar."
                    recyclerView.visibility = View.GONE
                } else {
                    tvEmpty.visibility = View.GONE
                    recyclerView.visibility = View.VISIBLE
                    recyclerView.adapter = OportunidadesAdapter(items) { oportunidade ->
                        (activity as? LoginActivity)?.pushFragment(DetalheOportunidadeFragment.newInstance(oportunidade.id))
                    }
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvEmpty.visibility = View.VISIBLE
                tvEmpty.text = "Não foi possível carregar as oportunidades."
                recyclerView.visibility = View.GONE
                Toast.makeText(context, "Falha ao consultar o ERP.", Toast.LENGTH_LONG).show()
            }
        }
    }
}
