package tech.e258tech.nexora_assiduidade.ui.gestor.relatorios

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
import tech.e258tech.nexora_assiduidade.data.model.RelatorioRH
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Relatórios do Gestor — GET /api/rh/relatorios (ERP). Única fonte de
 * relatórios: o FaceClock deixou de expor os seus próprios (arquitectura
 * stateless em curso).
 */
class RelatoriosGestorFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.gestor_relatorios, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val recyclerView = view.findViewById<RecyclerView>(R.id.recyclerViewRelatorios)
        val tvEmpty = view.findViewById<TextView>(R.id.tvRelatoriosEmpty)
        recyclerView.layoutManager = LinearLayoutManager(context)

        val token = SessionManager(requireContext()).getToken()
        if (token.isNullOrBlank()) {
            tvEmpty.visibility = View.VISIBLE
            tvEmpty.text = "Sessão inválida. Faça login novamente."
            return
        }

        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getRelatorioRH(ApiUtils.bearerToken(token))
                }

                if (!response.isSuccessful || response.body() == null) {
                    tvEmpty.visibility = View.VISIBLE
                    tvEmpty.text = ApiUtils.errorMessage(response)
                    recyclerView.visibility = View.GONE
                    return@launch
                }

                tvEmpty.visibility = View.GONE
                recyclerView.visibility = View.VISIBLE
                recyclerView.adapter = RelatoriosAdapter(buildRows(response.body()!!))
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvEmpty.visibility = View.VISIBLE
                tvEmpty.text = "Não foi possível carregar os relatórios."
                recyclerView.visibility = View.GONE
                Toast.makeText(context, "Falha ao consultar o ERP.", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun buildRows(r: RelatorioRH): List<RelatorioRow> {
        val rows = mutableListOf<RelatorioRow>()

        rows += RelatorioRow.Header("Efectivo")
        rows += RelatorioRow.Linha("Total de funcionários", r.total_funcionarios.toString())
        r.por_estado.forEach { rows += RelatorioRow.Linha(it.label, it.total.toString()) }

        rows += RelatorioRow.Header("Por unidade")
        r.por_unidade.forEach { rows += RelatorioRow.Linha(it.label, it.total.toString()) }

        rows += RelatorioRow.Header("Por cargo")
        r.por_cargo.forEach { rows += RelatorioRow.Linha(it.label, it.total.toString()) }

        if (r.absentismo.isNotEmpty()) {
            rows += RelatorioRow.Header("Absentismo")
            r.absentismo.forEach {
                rows += RelatorioRow.Linha(it.tipo, "${it.total} pedidos, ${it.dias} dias")
            }
        }

        rows += RelatorioRow.Header("Processos disciplinares")
        r.processos_disciplinares.forEach { (estado, total) -> rows += RelatorioRow.Linha(estado, total.toString()) }

        rows += RelatorioRow.Header("Formações")
        r.formacoes.forEach { (estado, total) -> rows += RelatorioRow.Linha(estado, total.toString()) }

        return rows
    }
}
