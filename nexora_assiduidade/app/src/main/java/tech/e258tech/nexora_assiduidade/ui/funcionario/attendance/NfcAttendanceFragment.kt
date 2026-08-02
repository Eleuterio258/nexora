package tech.e258tech.nexora_assiduidade.ui.funcionario.attendance

import android.app.PendingIntent
import android.content.Intent
import android.content.IntentFilter
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ProgressBar
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
import tech.e258tech.nexora_assiduidade.data.model.MarcarPontoNfcSelfServiceRequest
import tech.e258tech.nexora_assiduidade.data.model.NfcPontoDados
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Tela de registo de presenca por cartao NFC.
 *
 * Aguarda a descoberta de uma tag NFC e envia o identificador para
 * `POST /api/self-service/assiduidade/ponto`, autenticado pelo colaborador.
 * O ERP valida se a tag está activa e pertence ao próprio utilizador antes
 * de criar o evento.
 */
class NfcAttendanceFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private lateinit var sessionManager: SessionManager

    private lateinit var tvNfcInfo: TextView
    private lateinit var progressBar: ProgressBar
    private var isLoading = false

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

        tvNfcInfo = view.findViewById(R.id.tvNfcInfo)
        progressBar = view.findViewById(R.id.progressBar)

        view.findViewById<View>(R.id.ivBack).setOnClickListener {
            parentFragmentManager.popBackStack()
        }

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
                validateNfcAndRegister(nfcId)
            }
        }
    }

    private fun validateNfcAndRegister(nfcId: String) {
        if (isLoading) return

        val token = sessionManager.getToken()
        if (token.isNullOrBlank()) {
            Toast.makeText(context, "Sessao invalida. Faca login novamente.", Toast.LENGTH_LONG).show()
            return
        }

        setLoading(true)
        tvNfcInfo.text = "A validar cartao NFC..."

        uiScope.launch {
            try {
                val request = MarcarPontoNfcSelfServiceRequest(
                    dados = NfcPontoDados(nfc_tag_id = nfcId)
                )
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.marcarPontoNfcSelfService(
                        ApiUtils.bearerToken(token),
                        request
                    )
                }

                if (response.isSuccessful) {
                    tvNfcInfo.text = "Registo de presença realizado com sucesso."
                    Toast.makeText(context, "Registo de presença realizado com sucesso.", Toast.LENGTH_SHORT).show()
                    parentFragmentManager.popBackStack()
                } else {
                    tvNfcInfo.text = "Não foi possível validar o cartão."
                    Toast.makeText(context, ApiUtils.errorMessage(response), Toast.LENGTH_LONG).show()
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                tvNfcInfo.text = "Falha ao comunicar com o ERP. Tente novamente."
                Toast.makeText(context, "Falha ao comunicar com o ERP.", Toast.LENGTH_LONG).show()
            } finally {
                if (isAdded) setLoading(false)
            }
        }
    }

    private fun setLoading(isLoading: Boolean) {
        this.isLoading = isLoading
        progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
    }
}
