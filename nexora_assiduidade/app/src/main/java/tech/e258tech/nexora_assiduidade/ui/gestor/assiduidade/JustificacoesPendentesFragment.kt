package tech.e258tech.nexora_assiduidade.ui.gestor.assiduidade

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.response.JustificacaoPendenteResponse
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Aprovação de justificações de falta/atraso — GET /api/rh/justificacoes,
 * POST /api/rh/justificacoes/{id}/aprovar|rejeitar (ERP). Mesmo padrão de
 * [tech.e258tech.nexora_assiduidade.ui.gestor.ferias.PedidosFeriasFragment];
 * antes destas rotas existirem, uma justificação submetida pelo colaborador
 * ficava "pendente" para sempre, sem ninguém a poder decidir.
 */
class JustificacoesPendentesFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var token: String? = null

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.gestor_justificacoes, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val recyclerView = view.findViewById<RecyclerView>(R.id.recyclerViewJustificacoes)
        val tvEmpty = view.findViewById<TextView>(R.id.tvJustificacoesEmpty)
        recyclerView.layoutManager = LinearLayoutManager(context)

        token = SessionManager(requireContext()).getToken()
        val currentToken = token
        if (currentToken.isNullOrBlank()) {
            tvEmpty.visibility = View.VISIBLE
            tvEmpty.text = "Sessão inválida. Faça login novamente."
            return
        }

        loadJustificacoes(recyclerView, tvEmpty, currentToken)
    }

    private fun loadJustificacoes(recyclerView: RecyclerView, tvEmpty: TextView, token: String) {
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getJustificacoesPendentes(ApiUtils.bearerToken(token))
                }

                if (!response.isSuccessful || response.body() == null) {
                    tvEmpty.visibility = View.VISIBLE
                    tvEmpty.text = ApiUtils.errorMessage(response)
                    recyclerView.visibility = View.GONE
                    return@launch
                }

                val items = response.body().orEmpty().toMutableList()
                if (items.isEmpty()) {
                    tvEmpty.visibility = View.VISIBLE
                    recyclerView.visibility = View.GONE
                    return@launch
                }

                tvEmpty.visibility = View.GONE
                recyclerView.visibility = View.VISIBLE
                recyclerView.adapter = JustificacoesPendentesAdapter(
                    items,
                    onAprovar = { item -> resolver(item, recyclerView, aprovar = true) },
                    onRejeitar = { item -> resolver(item, recyclerView, aprovar = false) },
                )
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvEmpty.visibility = View.VISIBLE
                tvEmpty.text = "Não foi possível carregar as justificações."
                recyclerView.visibility = View.GONE
                Toast.makeText(context, "Falha ao consultar o ERP.", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun resolver(item: JustificacaoPendenteResponse, recyclerView: RecyclerView, aprovar: Boolean) {
        val currentToken = token ?: return
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    val bearer = ApiUtils.bearerToken(currentToken)
                    if (aprovar) {
                        RetrofitClient.erpApiService.aprovarJustificacao(bearer, item.id)
                    } else {
                        RetrofitClient.erpApiService.rejeitarJustificacao(bearer, item.id)
                    }
                }

                if (!response.isSuccessful) {
                    Toast.makeText(context, ApiUtils.errorMessage(response), Toast.LENGTH_LONG).show()
                    return@launch
                }

                Toast.makeText(
                    context,
                    if (aprovar) "Justificação aprovada." else "Justificação rejeitada.",
                    Toast.LENGTH_SHORT
                ).show()
                (recyclerView.adapter as? JustificacoesPendentesAdapter)?.removeItem(item)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                Toast.makeText(context, "Falha ao comunicar com o ERP.", Toast.LENGTH_LONG).show()
            }
        }
    }
}
