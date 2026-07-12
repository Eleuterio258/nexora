package tech.e258tech.nexora_assiduidade.ui.gestor.ocorrencias

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
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Ocorrências e Anomalias — atrasos/faltas da equipa nos últimos 30 dias
 * (GET /api/rh/presencas, ERP).
 */
class OcorrenciasFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.gestor_ocorrencias, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val recyclerView = view.findViewById<RecyclerView>(R.id.recyclerViewOcorrencias)
        val tvEmpty = view.findViewById<TextView>(R.id.tvOcorrenciasEmpty)
        recyclerView.layoutManager = LinearLayoutManager(context)

        val token = SessionManager(requireContext()).getToken()
        if (token.isNullOrBlank()) {
            tvEmpty.visibility = View.VISIBLE
            tvEmpty.text = "Sessão inválida. Faça login novamente."
            return
        }

        val formatter = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val hoje = formatter.format(Date())
        val ha30Dias = formatter.format(
            Calendar.getInstance().apply { add(Calendar.DAY_OF_MONTH, -30) }.time
        )

        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getPresencasPorTipo(
                        ApiUtils.bearerToken(token),
                        tipo = "atraso,falta,saida_antecipada",
                        dataInicio = ha30Dias,
                        dataFim = hoje,
                    )
                }

                if (!response.isSuccessful || response.body() == null) {
                    tvEmpty.visibility = View.VISIBLE
                    tvEmpty.text = ApiUtils.errorMessage(response)
                    recyclerView.visibility = View.GONE
                    return@launch
                }

                val items = response.body().orEmpty()
                if (items.isEmpty()) {
                    tvEmpty.visibility = View.VISIBLE
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
                tvEmpty.text = "Não foi possível carregar as ocorrências."
                recyclerView.visibility = View.GONE
                Toast.makeText(context, "Falha ao consultar o ERP.", Toast.LENGTH_LONG).show()
            }
        }
    }
}
