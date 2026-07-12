package tech.e258tech.nexora_assiduidade.ui.gestor.equipa

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
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
}
