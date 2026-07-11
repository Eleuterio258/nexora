package tech.e258tech.nexora_assiduidade.ui.funcionario.history

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

class HistoryFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return inflater.inflate(R.layout.funcionario_history, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val recyclerView = view.findViewById<RecyclerView>(R.id.recyclerViewHistory)
        val tvEmpty = view.findViewById<TextView>(R.id.tvEmpty)
        val sessionManager = SessionManager(requireContext())
        val token = sessionManager.getToken()

        recyclerView.layoutManager = LinearLayoutManager(context)

        if (token.isNullOrBlank()) {
            tvEmpty.visibility = View.VISIBLE
            tvEmpty.text = "Sessao invalida. Faca login novamente."
            return
        }

        loadHistory(recyclerView, tvEmpty, token)
    }

    private fun loadHistory(recyclerView: RecyclerView, tvEmpty: TextView, token: String) {
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.assiduidadeApiService.getMyClockRecords(
                        ApiUtils.bearerToken(token)
                    )
                }

                if (!response.isSuccessful || response.body() == null) {
                    tvEmpty.visibility = View.VISIBLE
                    tvEmpty.text = ApiUtils.errorMessage(response)
                    recyclerView.visibility = View.GONE
                    return@launch
                }

                val items = response.body()?.items.orEmpty()
                if (items.isEmpty()) {
                    tvEmpty.visibility = View.VISIBLE
                    recyclerView.visibility = View.GONE
                    return@launch
                }

                tvEmpty.visibility = View.GONE
                recyclerView.visibility = View.VISIBLE
                recyclerView.adapter = HistoryAdapter(items)
            } catch (_: Exception) {
                tvEmpty.visibility = View.VISIBLE
                tvEmpty.text = "Nao foi possivel carregar o historico."
                recyclerView.visibility = View.GONE
                Toast.makeText(
                    context,
                    "Falha ao consultar o backend de assiduidade.",
                    Toast.LENGTH_LONG
                ).show()
            }
        }
    }
}
