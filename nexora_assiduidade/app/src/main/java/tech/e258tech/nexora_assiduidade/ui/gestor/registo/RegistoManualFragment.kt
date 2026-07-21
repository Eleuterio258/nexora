package tech.e258tech.nexora_assiduidade.ui.gestor.registo

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
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
import tech.e258tech.nexora_assiduidade.BuildConfig
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.ClockRegisterRequest
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.Constants
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils
import tech.e258tech.nexora_assiduidade.utils.HardwareEventMapper
import tech.e258tech.nexora_assiduidade.utils.SessionManager
import java.util.UUID

/**
 * Registo Manual de Assiduidade — o gestor marca ponto em nome de um
 * funcionário (ex.: esqueceu o telemóvel, avaria de dispositivo). Desde
 * 2026-07-13 chama `POST /api/hardware/events/generic` directamente no
 * Nexora ERP (API Key de device embutida no APK) — deixou de passar pelo
 * proxy do FaceClock. O `funcionarioId` introduzido é o ID numérico tal como
 * devolvido por GET /api/rh/funcionarios (ecrã Equipa) — `rh.funcionarios.id`,
 * resolvido para `employee_no` via `HardwareEventMapper.resolveEmployeeCodeById`.
 *
 * Não pede para escolher Entrada/Saída — o ERP decide sozinho (ver
 * `registarEventoAssiduidade`/`inferirTipoEventoCodigo` em
 * backend/internal/modules/hardware/service/processor.go): grava em
 * rh.eventos_assiduidade, usando event.Direction quando o adapter o souber
 * indicar ou, na ausência disso, alternando entrada/saída pela paridade dos
 * eventos já registados nesse dia — já não perde marcações a partir da 3ª
 * como a lógica antiga baseada em rh.presencas perdia. O `event_type`
 * enviado aqui não influencia esse cálculo, é só metadado do log bruto
 * (hardware.device_events).
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
        val btnRegister = view.findViewById<Button>(R.id.btnRegister)
        val tvStatus = view.findViewById<TextView>(R.id.tvRegistoStatus)

        btnRegister.setOnClickListener {
            val funcionarioId = etEmployeeId.text?.toString()?.trim()
            if (funcionarioId.isNullOrEmpty()) {
                tvStatus.text = "Indique o ID do funcionário."
                return@setOnClickListener
            }

            registar(funcionarioId, tvStatus, btnRegister)
        }
    }

    private fun registar(funcionarioId: String, tvStatus: TextView, btnRegister: Button) {
        val token = SessionManager(requireContext()).getToken()
        if (token.isNullOrBlank()) {
            tvStatus.text = "Sessão inválida. Faça login novamente."
            return
        }

        btnRegister.isEnabled = false
        tvStatus.text = "A registar..."

        uiScope.launch {
            try {
                val funcionarioIdLong = funcionarioId.toLongOrNull()
                if (funcionarioIdLong == null) {
                    tvStatus.text = "ID do funcionário inválido."
                    return@launch
                }

                val employeeCode = withContext(Dispatchers.IO) {
                    HardwareEventMapper.resolveEmployeeCodeById(funcionarioIdLong)
                }
                if (employeeCode == null) {
                    tvStatus.text = "Funcionário não encontrado no ERP."
                    return@launch
                }

                val request = ClockRegisterRequest(
                    idempotency_key = UUID.randomUUID().toString(),
                    user_id = funcionarioId,
                    device_id = "00000000-0000-0000-0000-000000000000",
                    event_type = Constants.EVENT_AUTO,
                    recorded_at = DateTimeUtils.nowForApi(),
                    source = "MANUAL",
                )
                val eventRequest = HardwareEventMapper.toGenericHardwareEvent(request, employeeCode)
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.registerEventDevice(BuildConfig.DEVICE_API_KEY, eventRequest)
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
