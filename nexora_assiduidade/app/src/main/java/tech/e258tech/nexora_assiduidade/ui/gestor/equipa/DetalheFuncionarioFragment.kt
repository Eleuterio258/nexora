package tech.e258tech.nexora_assiduidade.ui.gestor.equipa

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
import tech.e258tech.nexora_assiduidade.data.model.response.ResultadoDiarioResponse
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Detalhe do Funcionário — GET /api/rh/funcionarios/{id} (ERP).
 */
class DetalheFuncionarioFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    companion object {
        private const val ARG_FUNCIONARIO_ID = "funcionario_id"

        fun newInstance(funcionarioId: Long): DetalheFuncionarioFragment {
            return DetalheFuncionarioFragment().apply {
                arguments = Bundle().apply { putLong(ARG_FUNCIONARIO_ID, funcionarioId) }
            }
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.gestor_detalhe_funcionario, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val funcionarioId = arguments?.getLong(ARG_FUNCIONARIO_ID)
        val token = SessionManager(requireContext()).getToken()
        val tvName = view.findViewById<TextView>(R.id.tvEmployeeName)

        if (funcionarioId == null || token.isNullOrBlank()) {
            tvName.text = "Não foi possível carregar o funcionário."
            return
        }

        loadFuncionario(view, funcionarioId, token)
        loadAssiduidade(view, funcionarioId, token)
    }

    private fun loadFuncionario(view: View, funcionarioId: Long, token: String) {
        val tvName = view.findViewById<TextView>(R.id.tvEmployeeName)
        val tvEmail = view.findViewById<TextView>(R.id.tvEmployeeEmail)
        val tvCargo = view.findViewById<TextView>(R.id.tvEmployeeCargo)
        val tvUnidade = view.findViewById<TextView>(R.id.tvEmployeeUnidade)
        val tvNumero = view.findViewById<TextView>(R.id.tvEmployeeNumero)
        val tvTelefone = view.findViewById<TextView>(R.id.tvEmployeeTelefone)
        val tvAdmissao = view.findViewById<TextView>(R.id.tvEmployeeAdmissao)
        val tvEstado = view.findViewById<TextView>(R.id.tvEmployeeEstado)

        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getFuncionarioDetalhe(
                        ApiUtils.bearerToken(token),
                        funcionarioId
                    )
                }

                if (!response.isSuccessful || response.body() == null) {
                    tvName.text = ApiUtils.errorMessage(response)
                    return@launch
                }

                val f = response.body()!!
                tvName.text = f.nome_completo
                tvEmail.text = f.email ?: "Sem email registado"
                tvCargo.text = f.cargo ?: "Sem cargo definido"
                tvUnidade.text = "Unidade: ${f.unidade_nome ?: "Sem unidade"}"
                tvNumero.text = "Número: ${f.numero_funcionario ?: "-"}"
                tvTelefone.text = "Telefone: ${f.telefone ?: "-"}"
                tvAdmissao.text = "Admissão: ${f.data_admissao ?: "-"}"
                tvEstado.text = "Estado: ${
                    when (f.estado) {
                        "ativo" -> "Activo"
                        "suspenso" -> "Suspenso"
                        "licenca" -> "Em licença"
                        "desligado" -> "Desligado"
                        else -> f.estado
                    }
                }"
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvName.text = "Não foi possível carregar o funcionário."
                Toast.makeText(context, "Falha ao consultar o ERP.", Toast.LENGTH_LONG).show()
            }
        }
    }

    /**
     * Carrega o resumo do resultado mais recente + os últimos eventos do
     * funcionário (modelo novo, rh.eventos_assiduidade/resultados_diarios).
     * Falha isoladamente desta secção não deve afectar o resto do ecrã
     * (dados do funcionário já carregados por loadFuncionario).
     */
    private fun loadAssiduidade(view: View, funcionarioId: Long, token: String) {
        val tvResultadoData = view.findViewById<TextView>(R.id.tvResultadoData)
        val tvResultadoHoras = view.findViewById<TextView>(R.id.tvResultadoHoras)
        val tvResultadoEstado = view.findViewById<TextView>(R.id.tvResultadoEstado)
        val tvEventosEmpty = view.findViewById<TextView>(R.id.tvEventosEmpty)
        val recyclerViewEventos = view.findViewById<RecyclerView>(R.id.recyclerViewEventos)
        recyclerViewEventos.layoutManager = LinearLayoutManager(context)

        uiScope.launch {
            try {
                val resultadosResponse = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getResultadosFuncionario(
                        ApiUtils.bearerToken(token), funcionarioId
                    )
                }
                bindResultadoResumo(
                    resultadosResponse.body()?.firstOrNull(),
                    tvResultadoData, tvResultadoHoras, tvResultadoEstado
                )

                val eventosResponse = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getEventosFuncionario(
                        ApiUtils.bearerToken(token), funcionarioId
                    )
                }
                val eventos = eventosResponse.body().orEmpty()
                if (eventos.isEmpty()) {
                    tvEventosEmpty.visibility = View.VISIBLE
                    recyclerViewEventos.visibility = View.GONE
                } else {
                    tvEventosEmpty.visibility = View.GONE
                    recyclerViewEventos.visibility = View.VISIBLE
                    recyclerViewEventos.adapter = FuncionarioEventosAdapter(eventos)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvResultadoData.text = "Assiduidade indisponível"
                tvResultadoHoras.text = ""
                tvResultadoEstado.text = ""
                tvEventosEmpty.visibility = View.VISIBLE
                recyclerViewEventos.visibility = View.GONE
            }
        }
    }

    private fun bindResultadoResumo(
        resultado: ResultadoDiarioResponse?,
        tvData: TextView,
        tvHoras: TextView,
        tvEstado: TextView
    ) {
        if (resultado == null) {
            tvData.text = "Sem resultados calculados"
            tvHoras.text = ""
            tvEstado.text = ""
            return
        }
        tvData.text = DateTimeUtils.formatDate(resultado.data_referencia)
        tvHoras.text = "Trabalhadas: ${ResultadoDiarioResponse.formatNanosAsHours(resultado.horas_trabalhadas)}" +
            " · Extra: ${ResultadoDiarioResponse.formatNanosAsHours(resultado.horas_extra)}" +
            " · Atraso: ${resultado.atraso_minutos}min"
        tvEstado.text = when {
            resultado.falta_injustificada -> "Falta injustificada"
            resultado.falta_justificada -> "Falta justificada"
            resultado.ausencia -> "Ausência"
            else -> "Presente"
        }
    }
}
