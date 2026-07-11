package tech.e258tech.nexora_assiduidade.ui.funcionario.attendance

import android.app.PendingIntent
import android.content.Intent
import android.content.IntentFilter
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.Ndef
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.RadioGroup
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import java.util.UUID
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.ClockRegisterRequest
import tech.e258tech.nexora_assiduidade.data.model.NFCValidateRequest
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.data.repository.AttendanceRepository
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.Constants
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Tela de registo de presenca por cartao NFC.
 *
 * Aguarda a descoberta de uma tag NFC, extrai o identificador e envia para
 * o backend /nfc/validate. Se valido, regista o ponto.
 */
class NfcAttendanceFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private lateinit var sessionManager: SessionManager
    private lateinit var attendanceRepository: AttendanceRepository

    private lateinit var radioGroupType: RadioGroup
    private lateinit var tvNfcInfo: TextView

    private var nfcAdapter: NfcAdapter? = null
    private var pendingIntent: PendingIntent? = null
    private var intentFilters: Array<IntentFilter>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        nfcAdapter = NfcAdapter.getDefaultAdapter(context)
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return inflater.inflate(R.layout.funcionario_nfc_attendance, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        sessionManager = SessionManager(requireContext())
        attendanceRepository = AttendanceRepository(requireContext())

        radioGroupType = view.findViewById(R.id.radioGroupType)
        tvNfcInfo = view.findViewById(R.id.tvNfcInfo)

        if (nfcAdapter == null) {
            tvNfcInfo.text = "NFC nao disponivel neste dispositivo"
            return
        }

        if (!nfcAdapter!!.isEnabled) {
            tvNfcInfo.text = "Por favor, ative o NFC nas configuracoes"
        } else {
            tvNfcInfo.text = "Aproxime o cartao NFC do dispositivo"
        }

        pendingIntent = PendingIntent.getActivity(
            requireContext(),
            0,
            Intent(requireContext(), requireActivity()::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_MUTABLE
        )

        val ndef = IntentFilter(NfcAdapter.ACTION_NDEF_DISCOVERED).apply {
            try {
                addDataType("*/*")
            } catch (_: IntentFilter.MalformedMimeTypeException) {
            }
        }
        val tag = IntentFilter(NfcAdapter.ACTION_TAG_DISCOVERED)
        intentFilters = arrayOf(ndef, tag)
    }

    override fun onResume() {
        super.onResume()
        nfcAdapter?.enableForegroundDispatch(requireActivity(), pendingIntent, intentFilters, null)
    }

    override fun onPause() {
        super.onPause()
        nfcAdapter?.disableForegroundDispatch(requireActivity())
    }

    fun onNewIntent(intent: Intent) {
        if (NfcAdapter.ACTION_NDEF_DISCOVERED == intent.action ||
            NfcAdapter.ACTION_TAG_DISCOVERED == intent.action
        ) {
            val tag: Tag? = intent.getParcelableExtra(NfcAdapter.EXTRA_TAG)
            if (tag != null) {
                val nfcId = tag.id?.joinToString("") { "%02X".format(it) } ?: return
                val ndefPayload = readNdefPayload(tag)
                val selectedId = radioGroupType.checkedRadioButtonId
                if (selectedId == -1) {
                    Toast.makeText(context, "Selecione Entrada ou Saida", Toast.LENGTH_SHORT).show()
                    return
                }
                val eventType = if (selectedId == R.id.radioEntrada) {
                    Constants.EVENT_ENTRY
                } else {
                    Constants.EVENT_EXIT
                }
                validateNfcAndRegister(nfcId, ndefPayload, eventType)
            }
        }
    }

    private fun readNdefPayload(tag: Tag): String? {
        return try {
            val ndef = Ndef.get(tag) ?: return null
            ndef.connect()
            val record = ndef.ndefMessage?.records?.firstOrNull()
            val payload = record?.payload?.let { bytes ->
                String(bytes, Charsets.UTF_8)
            }
            ndef.close()
            payload
        } catch (_: Exception) {
            null
        }
    }

    private fun validateNfcAndRegister(nfcId: String, payload: String?, eventType: String) {
        val userId = sessionManager.getUserId()
        val token = sessionManager.getToken()
        if (userId.isNullOrBlank() || token.isNullOrBlank()) {
            Toast.makeText(context, "Sessao invalida. Faca login novamente.", Toast.LENGTH_LONG).show()
            return
        }

        setLoading(true)
        tvNfcInfo.text = "A validar cartao NFC..."

        uiScope.launch {
            val validateResult: Pair<Boolean, String?> = withContext(Dispatchers.IO) {
                try {
                    val response = RetrofitClient.assiduidadeApiService.validateNFC(
                        ApiUtils.bearerToken(token),
                        NFCValidateRequest(nfc_tag = payload ?: nfcId)
                    )
                    if (response.isSuccessful && response.body() != null) {
                        val body = response.body()!!
                        body.valid to body.message
                    } else {
                        false to ApiUtils.errorMessage(response)
                    }
                } catch (e: Exception) {
                    false to (e.message ?: "Erro na validacao NFC")
                }
            }

            val valid = validateResult.first
            val message = validateResult.second

            if (!valid) {
                setLoading(false)
                tvNfcInfo.text = "Cartao NFC invalido."
                Toast.makeText(context, message ?: "Cartao NFC invalido.", Toast.LENGTH_LONG).show()
                return@launch
            }

            val request = ClockRegisterRequest(
                idempotency_key = UUID.randomUUID().toString(),
                user_id = userId,
                device_id = sessionManager.getOrCreateDeviceId(),
                event_type = eventType,
                recorded_at = DateTimeUtils.nowForApi(),
                source = Constants.SOURCE_NFC
            )

            val registerResult = withContext(Dispatchers.IO) {
                attendanceRepository.registerClock(request)
            }

            setLoading(false)
            val action = if (eventType == Constants.EVENT_ENTRY) "entrada" else "saida"

            when (registerResult) {
                is AttendanceRepository.RegisterResult.Success -> {
                    tvNfcInfo.text = "Registo de $action realizado com sucesso."
                    Toast.makeText(context, "Registo de $action realizado com sucesso.", Toast.LENGTH_SHORT).show()
                    parentFragmentManager.popBackStack()
                }
                is AttendanceRepository.RegisterResult.SavedOffline -> {
                    tvNfcInfo.text = "Sem internet. Registo guardado."
                    Toast.makeText(context, "Sem internet. Registo de $action guardado e sera sincronizado automaticamente.", Toast.LENGTH_LONG).show()
                    parentFragmentManager.popBackStack()
                }
                is AttendanceRepository.RegisterResult.Error -> {
                    tvNfcInfo.text = registerResult.message
                    Toast.makeText(context, registerResult.message, Toast.LENGTH_LONG).show()
                }
            }
        }
    }

    private fun setLoading(isLoading: Boolean) {
        // Nenhum botao de accao directa; o estado e apresentado no tvNfcInfo.
    }
}
