package tech.e258tech.nexora_assiduidade.ui.funcionario.agenda

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.floatingactionbutton.FloatingActionButton
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.AgendaItem
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Tela de Agenda — GET /api/utilizadores/{userId}/agenda
 * (backend/internal/modules/utilizadores/handlers/agenda.go).
 */
class AgendaFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private lateinit var sessionManager: SessionManager

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.funcionario_agenda, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        sessionManager = SessionManager(requireContext())

        val recyclerView = view.findViewById<RecyclerView>(R.id.recyclerViewAgenda)
        val tvEmpty = view.findViewById<TextView>(R.id.tvEmptyAgenda)
        val fabNewMeeting = view.findViewById<FloatingActionButton>(R.id.fabNewMeeting)

        recyclerView.layoutManager = LinearLayoutManager(context)

        fabNewMeeting.setOnClickListener {
            parentFragmentManager.beginTransaction()
                .replace(R.id.fragment_container, CreateMeetingFragment())
                .addToBackStack(null)
                .commit()
        }

        val token = sessionManager.getToken()
        val userId = sessionManager.getUserId()
        if (token.isNullOrBlank() || userId.isNullOrBlank()) {
            tvEmpty.visibility = View.VISIBLE
            tvEmpty.text = "Sessão inválida. Faça login novamente."
            return
        }

        loadAgenda(recyclerView, tvEmpty, token, userId)
    }

    override fun onResume() {
        super.onResume()
        val token = sessionManager.getToken()
        val userId = sessionManager.getUserId()
        if (!token.isNullOrBlank() && !userId.isNullOrBlank()) {
            view?.let {
                loadAgenda(
                    it.findViewById(R.id.recyclerViewAgenda),
                    it.findViewById(R.id.tvEmptyAgenda),
                    token,
                    userId
                )
            }
        }
    }

    private fun loadAgenda(recyclerView: RecyclerView, tvEmpty: TextView, token: String, userId: String) {
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getAgenda(
                        ApiUtils.bearerToken(token),
                        userId
                    )
                }

                if (!isAdded) return@launch

                if (!response.isSuccessful || response.body() == null) {
                    tvEmpty.visibility = View.VISIBLE
                    tvEmpty.text = ApiUtils.errorMessage(response)
                    recyclerView.visibility = View.GONE
                    return@launch
                }

                val items = response.body().orEmpty()
                if (items.isEmpty()) {
                    tvEmpty.visibility = View.VISIBLE
                    tvEmpty.text = "Sem eventos agendados"
                    recyclerView.visibility = View.GONE
                    return@launch
                }

                tvEmpty.visibility = View.GONE
                recyclerView.visibility = View.VISIBLE
                recyclerView.adapter = AgendaAdapter(items) { item -> openDetail(item) }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvEmpty.visibility = View.VISIBLE
                tvEmpty.text = "Não foi possível carregar a agenda."
                recyclerView.visibility = View.GONE
                Toast.makeText(context, "Falha ao consultar o ERP.", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun openDetail(item: AgendaItem) {
        val horario = if (item.hora_fim.isNullOrBlank()) {
            item.hora_inicio
        } else {
            "${item.hora_inicio} - ${item.hora_fim}"
        }
        parentFragmentManager.beginTransaction()
            .replace(
                R.id.fragment_container,
                AgendaItemDetailFragment.newInstance(
                    title = item.titulo,
                    description = item.descricao ?: "Sem descrição",
                    duration = horario
                )
            )
            .addToBackStack(null)
            .commit()
    }
}
