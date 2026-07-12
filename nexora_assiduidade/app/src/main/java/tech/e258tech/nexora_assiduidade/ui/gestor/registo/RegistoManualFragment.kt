package tech.e258tech.nexora_assiduidade.ui.gestor.registo

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.RadioGroup
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
import tech.e258tech.nexora_assiduidade.data.model.ClockRegisterRequest
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager
import java.util.UUID

/**
 * Registo Manual de Assiduidade — o gestor marca ponto em nome de um
 * funcionário (ex.: esqueceu o telemóvel, avaria de dispositivo). Chama
 * POST /clock/register do FaceClock com `user_id` diferente do do próprio
 * gestor — só permitido a ADMIN_SISTEMA/GESTOR_RH (ver
 * app/routers/clock.py, `_create_clock_record`, verificação adicionada
 * nesta mesma sessão).
 *
 * Nota de risco conhecido: o FaceClock está a meio de uma reescrita
 * "stateless" (ver CONTRATO-INTEGRACAO-ERP.md) e o contrato exacto de
 * `user_id` (espaço de IDs do ERP vs FaceClock) ainda pode mudar — usa-se
 * aqui o ID numérico do funcionário tal como devolvido por
 * GET /api/rh/funcionarios (ecrã Equipa), convertido para string.
 */
class RegistoManualFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

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

        val etEmployeeId = view.findViewById<EditText>(R.id.etEmployeeId)
        val rgEventType = view.findViewById<RadioGroup>(R.id.rgEventType)
        val btnRegister = view.findViewById<Button>(R.id.btnRegister)
        val tvStatus = view.findViewById<TextView>(R.id.tvRegistoStatus)

        btnRegister.setOnClickListener {
            val funcionarioId = etEmployeeId.text?.toString()?.trim()
            if (funcionarioId.isNullOrEmpty()) {
                tvStatus.text = "Indique o ID do funcionário."
                return@setOnClickListener
            }

            val eventType = if (rgEventType.checkedRadioButtonId == R.id.rbSaida) "EXIT" else "ENTRY"
            registar(funcionarioId, eventType, tvStatus, btnRegister)
        }
    }

    private fun registar(funcionarioId: String, eventType: String, tvStatus: TextView, btnRegister: Button) {
        val token = SessionManager(requireContext()).getToken()
        if (token.isNullOrBlank()) {
            tvStatus.text = "Sessão inválida. Faça login novamente."
            return
        }

        btnRegister.isEnabled = false
        tvStatus.text = "A registar..."

        uiScope.launch {
            try {
                val request = ClockRegisterRequest(
                    idempotency_key = UUID.randomUUID().toString(),
                    user_id = funcionarioId,
                    device_id = "00000000-0000-0000-0000-000000000000",
                    event_type = eventType,
                    recorded_at = DateTimeUtils.nowForApi(),
                    source = "MANUAL",
                )
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.assiduidadeApiService.registerClock(ApiUtils.bearerToken(token), request)
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
                tvStatus.text = "Falha ao comunicar com o FaceClock."
                Toast.makeText(context, "Não foi possível registar.", Toast.LENGTH_LONG).show()
            } finally {
                if (isAdded) btnRegister.isEnabled = true
            }
        }
    }
}
