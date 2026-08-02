package tech.e258tech.nexora_assiduidade.ui.gestor.registo

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.Spinner
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.google.android.material.button.MaterialButtonToggleGroup
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.MarcarPontoGestorRequest
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils
import tech.e258tech.nexora_assiduidade.utils.PermissionUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Registo Manual de Assiduidade — o gestor marca ponto em nome de um
 * funcionário (ex.: esqueceu o telemóvel, avaria de dispositivo).
 *
 * Este ecrã só deve ser acessível a utilizadores com a permissão
 * `recursos-humanos:gerir_funcionarios` (validada também no backend em
 * `podeGerirFuncionario`). A navegação já a esconde em [ModulesFragment] e
 * [MaisFragment]; a verificação defensiva aqui impede abertura directa.
 *
 * Envia `POST /api/rh/eventos` autenticado pelo token do utilizador, com o
 * tipo de evento (`entrada` ou `saida`) escolhido explicitamente.
 */
class RegistoManualFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private lateinit var spFuncionario: Spinner
    private var funcionarioIds: List<Long> = emptyList()

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.gestor_registo_manual, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        spFuncionario = view.findViewById(R.id.spFuncionario)
        val btnRegister = view.findViewById<Button>(R.id.btnRegister)
        val rgEventType = view.findViewById<MaterialButtonToggleGroup>(R.id.rgEventType)
        val tvStatus = view.findViewById<TextView>(R.id.tvRegistoStatus)
        val sessionManager = SessionManager(requireContext())

        view.findViewById<View>(R.id.ivBack).setOnClickListener {
            parentFragmentManager.popBackStack()
        }

        if (!PermissionUtils.has(sessionManager, "recursos-humanos", "gerir_funcionarios")) {
            tvStatus.text = "Não tem permissão para registar assiduidade manualmente."
            spFuncionario.isEnabled = false
            view.findViewById<View>(R.id.rbEntry).isEnabled = false
            view.findViewById<View>(R.id.rbExit).isEnabled = false
            btnRegister.isEnabled = false
            return
        }

        carregarFuncionarios(tvStatus)

        btnRegister.setOnClickListener {
            val tipoEventoCodigo = when (rgEventType.checkedButtonId) {
                R.id.rbEntry -> "entrada"
                R.id.rbExit -> "saida"
                else -> {
                    tvStatus.text = "Seleccione o tipo de evento: Entrada ou Saída."
                    return@setOnClickListener
                }
            }

            val funcionarioId = funcionarioIds.getOrNull(spFuncionario.selectedItemPosition)
            if (funcionarioId == null) {
                tvStatus.text = "Não há funcionários disponíveis para seleccionar."
                return@setOnClickListener
            }

            registar(funcionarioId, tipoEventoCodigo, tvStatus, btnRegister, sessionManager)
        }
    }

    private fun carregarFuncionarios(tvStatus: TextView) {
        val token = SessionManager(requireContext()).getToken() ?: return
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getFuncionariosAtivos(ApiUtils.bearerToken(token))
                }
                if (!isAdded) return@launch
                if (!response.isSuccessful) {
                    tvStatus.text = ApiUtils.errorMessage(response)
                    return@launch
                }

                val funcionarios = response.body().orEmpty()
                funcionarioIds = funcionarios.map { it.id }
                spFuncionario.adapter = ArrayAdapter(
                    requireContext(),
                    android.R.layout.simple_spinner_dropdown_item,
                    funcionarios.map { f ->
                        f.numero_funcionario?.let { "${f.nome_completo} (Nº $it)" } ?: f.nome_completo
                    }
                )
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvStatus.text = "Não foi possível carregar a lista de funcionários."
            }
        }
    }

    private fun registar(
        funcionarioId: Long,
        tipoEventoCodigo: String,
        tvStatus: TextView,
        btnRegister: Button,
        sessionManager: SessionManager
    ) {
        val token = sessionManager.getToken()
        if (token.isNullOrBlank()) {
            tvStatus.text = "Sessão inválida. Faça login novamente."
            return
        }

        btnRegister.isEnabled = false
        tvStatus.text = "A registar..."

        uiScope.launch {
            try {
                val request = MarcarPontoGestorRequest(
                    funcionario_id = funcionarioId,
                    tipo_evento_codigo = tipoEventoCodigo,
                    metodo_codigo = "manual",
                    origem = "app",
                    data_referencia = DateTimeUtils.todayForApi(),
                    ocorrido_em = DateTimeUtils.nowUtcForApi(),
                    observacoes = "Registo manual via app"
                )
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.criarEventoAssiduidade(
                        ApiUtils.bearerToken(token),
                        request
                    )
                }

                tvStatus.text = if (response.isSuccessful) {
                    "Registo criado com sucesso."
                } else {
                    ApiUtils.errorMessage(response)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvStatus.text = "Falha ao comunicar com o ERP."
                Toast.makeText(context, "Não foi possível registar.", Toast.LENGTH_LONG).show()
            } finally {
                if (isAdded) btnRegister.isEnabled = true
            }
        }
    }
}
