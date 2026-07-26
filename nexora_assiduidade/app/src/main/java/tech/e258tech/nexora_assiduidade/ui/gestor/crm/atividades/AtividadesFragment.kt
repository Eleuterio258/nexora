package tech.e258tech.nexora_assiduidade.ui.gestor.crm.atividades

import android.os.Bundle
import android.text.InputType
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.EditText
import android.widget.Spinner
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.textfield.TextInputEditText
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.Atividade
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.ui.auth.LoginActivity
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.PermissionUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Lista global de Atividades (todos os leads/oportunidades) — GET /api/crm/atividades,
 * sem lead_id/oportunidade_id, ordenada pelo backend por próxima data primeiro.
 */
class AtividadesFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private lateinit var sessionManager: SessionManager

    private val tipoOpcoes = listOf(null) + Atividade.TIPOS.keys.toList()
    /** null=Todas, false=Pendentes, true=Concluídas. */
    private val concluidaOpcoes = listOf(null, false, true)

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return inflater.inflate(R.layout.gestor_crm_atividades, container, false)
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

        val recyclerView = view.findViewById<RecyclerView>(R.id.recyclerViewAtividades)
        recyclerView.layoutManager = LinearLayoutManager(context)

        val spTipo = view.findViewById<Spinner>(R.id.spTipoFiltro)
        spTipo.adapter = ArrayAdapter(
            requireContext(),
            android.R.layout.simple_spinner_dropdown_item,
            listOf("Todos os tipos") + tipoOpcoes.drop(1).map { Atividade.tipoLabel(it!!) }
        )

        val spConcluida = view.findViewById<Spinner>(R.id.spConcluidaFiltro)
        spConcluida.adapter = ArrayAdapter(
            requireContext(),
            android.R.layout.simple_spinner_dropdown_item,
            listOf("Todas", "Pendentes", "Concluídas")
        )

        val btnNovaAtividade = view.findViewById<Button>(R.id.btnNovaAtividade)
        btnNovaAtividade.visibility = if (PermissionUtils.has(sessionManager, "crm", "gerir_atividades")) View.VISIBLE else View.GONE
        btnNovaAtividade.setOnClickListener {
            escolherAlvoENavegar()
        }

        view.findViewById<Button>(R.id.btnSearch).setOnClickListener {
            loadAtividades(view)
        }

        val listener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>?, v: View?, position: Int, id: Long) {
                loadAtividades(view)
            }
            override fun onNothingSelected(parent: AdapterView<*>?) {}
        }
        spTipo.onItemSelectedListener = listener
        spConcluida.onItemSelectedListener = listener

        loadAtividades(view)
    }

    override fun onResume() {
        super.onResume()
        view?.let { loadAtividades(it) }
    }

    /** "+ Nova Atividade" no ecrã global: sem contexto de lead/oportunidade
     * herdado, por isso pergunta primeiro a qual associar. */
    private fun escolherAlvoENavegar() {
        MaterialAlertDialogBuilder(requireContext())
            .setTitle("Associar a...")
            .setItems(arrayOf("Um Lead", "Uma Oportunidade")) { _, which ->
                if (which == 0) pedirIdEAbrirFormulario(isLead = true) else pedirIdEAbrirFormulario(isLead = false)
            }
            .show()
    }

    private fun pedirIdEAbrirFormulario(isLead: Boolean) {
        val input = EditText(requireContext())
        input.inputType = InputType.TYPE_CLASS_NUMBER
        input.hint = if (isLead) "ID do Lead" else "ID da Oportunidade"

        MaterialAlertDialogBuilder(requireContext())
            .setTitle(if (isLead) "ID do Lead" else "ID da Oportunidade")
            .setView(input)
            .setNegativeButton("Cancelar", null)
            .setPositiveButton("Continuar") { _, _ ->
                val id = input.text?.toString()?.trim()?.toLongOrNull()
                if (id == null) {
                    Toast.makeText(context, "ID inválido.", Toast.LENGTH_SHORT).show()
                    return@setPositiveButton
                }
                val fragment = if (isLead) {
                    AtividadeFormFragment.newInstance(leadId = id)
                } else {
                    AtividadeFormFragment.newInstance(oportunidadeId = id)
                }
                (activity as? LoginActivity)?.pushFragment(fragment)
            }
            .show()
    }

    private fun loadAtividades(view: View) {
        val token = sessionManager.getToken()
        val recyclerView = view.findViewById<RecyclerView>(R.id.recyclerViewAtividades)
        val tvEmpty = view.findViewById<TextView>(R.id.tvEmpty)
        val spTipo = view.findViewById<Spinner>(R.id.spTipoFiltro)
        val spConcluida = view.findViewById<Spinner>(R.id.spConcluidaFiltro)
        val etSearch = view.findViewById<TextInputEditText>(R.id.etSearch)

        if (token.isNullOrBlank()) {
            tvEmpty.visibility = View.VISIBLE
            tvEmpty.text = "Sessão inválida. Faça login novamente."
            return
        }

        val tipoSelecionado = tipoOpcoes.getOrNull(spTipo.selectedItemPosition)
        val concluidaSelecionada = concluidaOpcoes.getOrNull(spConcluida.selectedItemPosition)
        val search = etSearch.text?.toString()?.trim()?.takeIf { it.isNotBlank() }
        val podeConcluir = PermissionUtils.has(sessionManager, "crm", "gerir_atividades")

        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getAtividades(
                        ApiUtils.bearerToken(token),
                        tipo = tipoSelecionado,
                        concluida = concluidaSelecionada,
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
                    tvEmpty.text = "Sem atividades para mostrar."
                    recyclerView.visibility = View.GONE
                } else {
                    tvEmpty.visibility = View.GONE
                    recyclerView.visibility = View.VISIBLE
                    recyclerView.adapter = AtividadesAdapter(
                        items = items,
                        onClick = { atividade ->
                            (activity as? LoginActivity)?.pushFragment(DetalheAtividadeFragment.newInstance(atividade.id))
                        },
                        onConcluir = { atividade -> concluirAtividade(view, atividade.id) },
                        podeConcluir = podeConcluir
                    )
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvEmpty.visibility = View.VISIBLE
                tvEmpty.text = "Não foi possível carregar as atividades."
                recyclerView.visibility = View.GONE
                Toast.makeText(context, "Falha ao consultar o ERP.", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun concluirAtividade(view: View, atividadeId: Long) {
        val token = sessionManager.getToken() ?: return
        uiScope.launch {
            try {
                withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.concluirAtividade(ApiUtils.bearerToken(token), atividadeId)
                }
                loadAtividades(view)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                Toast.makeText(context, "Falha ao concluir a atividade.", Toast.LENGTH_SHORT).show()
            }
        }
    }
}
