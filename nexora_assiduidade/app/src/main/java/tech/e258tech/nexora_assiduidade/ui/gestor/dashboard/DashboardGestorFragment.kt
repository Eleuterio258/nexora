package tech.e258tech.nexora_assiduidade.ui.gestor.dashboard

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
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
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.ui.auth.LoginActivity
import tech.e258tech.nexora_assiduidade.ui.gestor.ocorrencias.OcorrenciasAdapter
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Dashboard principal do Gestor — combina GET /api/rh/relatorios (efectivo
 * total) com GET /api/rh/presencas (presentes hoje), ambos do ERP. Não
 * existe um endpoint único que agregue os dois.
 */
class DashboardGestorFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private lateinit var sessionManager: SessionManager

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.gestor_dashboard, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        sessionManager = SessionManager(requireContext())

        val tvTotal = view.findViewById<TextView>(R.id.tvTotalFuncionarios)
        val tvPresentes = view.findViewById<TextView>(R.id.tvPresentesHoje)
        val btnLogout = view.findViewById<Button>(R.id.btnLogoutGestor)
        val recyclerView = view.findViewById<RecyclerView>(R.id.recyclerViewDashboard)
        val tvOcorrenciasEmpty = view.findViewById<TextView>(R.id.tvDashboardOcorrenciasEmpty)
        recyclerView.layoutManager = LinearLayoutManager(context)

        btnLogout.setOnClickListener {
            sessionManager.clearSession()
            startActivity(Intent(requireContext(), LoginActivity::class.java))
            activity?.finish()
        }

        val token = sessionManager.getToken()
        if (token.isNullOrBlank()) {
            tvTotal.text = "-"
            tvPresentes.text = "-"
            tvOcorrenciasEmpty.visibility = View.VISIBLE
            tvOcorrenciasEmpty.text = "Sessão inválida. Faça login novamente."
            recyclerView.visibility = View.GONE
            return
        }

        loadTotalFuncionarios(tvTotal, token)
        loadPresentesHoje(tvPresentes, token)
        loadOcorrenciasHoje(recyclerView, tvOcorrenciasEmpty, token)
    }

    /** Atrasos/faltas de hoje — mesma fonte e filtro que AlertasFragment, aqui em resumo. */
    private fun loadOcorrenciasHoje(recyclerView: RecyclerView, tvEmpty: TextView, token: String) {
        val hoje = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getPresencasPorTipo(
                        ApiUtils.bearerToken(token),
                        tipo = "atraso,falta,saida_antecipada",
                        dataInicio = hoje,
                        dataFim = hoje,
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
                    tvEmpty.text = "Sem atrasos ou faltas hoje."
                    recyclerView.visibility = View.GONE
                    return@launch
                }

                tvEmpty.visibility = View.GONE
                recyclerView.visibility = View.VISIBLE
                recyclerView.adapter = OcorrenciasAdapter(items)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvEmpty.visibility = View.VISIBLE
                tvEmpty.text = "Não foi possível carregar os alertas."
                recyclerView.visibility = View.GONE
            }
        }
    }

    private fun loadTotalFuncionarios(tvTotal: TextView, token: String) {
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getRelatorioRH(ApiUtils.bearerToken(token))
                }
                if (response.isSuccessful && response.body() != null) {
                    tvTotal.text = response.body()!!.total_funcionarios.toString()
                } else {
                    tvTotal.text = "-"
                    if (isAdded && ApiUtils.isForbidden(response)) {
                        Toast.makeText(context, ApiUtils.errorMessage(response), Toast.LENGTH_SHORT).show()
                    }
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (isAdded) tvTotal.text = "-"
            }
        }
    }

    private fun loadPresentesHoje(tvPresentes: TextView, token: String) {
        val hoje = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getPresencasPorTipo(
                        ApiUtils.bearerToken(token),
                        tipo = "presente,atraso",
                        dataInicio = hoje,
                        dataFim = hoje,
                    )
                }
                tvPresentes.text = if (response.isSuccessful && response.body() != null) {
                    response.body()!!.size.toString()
                } else {
                    "-"
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvPresentes.text = "-"
                Toast.makeText(context, "Falha ao consultar o ERP.", Toast.LENGTH_SHORT).show()
            }
        }
    }
}
