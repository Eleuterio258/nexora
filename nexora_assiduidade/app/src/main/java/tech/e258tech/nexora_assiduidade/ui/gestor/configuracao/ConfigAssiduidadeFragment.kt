package tech.e258tech.nexora_assiduidade.ui.gestor.configuracao

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.ProgressBar
import android.widget.TextView
import androidx.fragment.app.Fragment
import com.google.android.material.switchmaterial.SwitchMaterial
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.AssiduidadeConfigRequest
import tech.e258tech.nexora_assiduidade.data.model.response.ConfiguracaoAssiduidade
import tech.e258tech.nexora_assiduidade.data.model.response.MetodoAssiduidadeConfig
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Configuração dos métodos de assiduidade activos para o tenant — gestor
 * liga/desliga cada método (Facial, Impressão Digital, QR Code, NFC, PIN,
 * Selfie+GPS, Manual) e a assiduidade como um todo.
 *
 * GET/PUT /api/system/configuracao/tenant/feature/rh.assiduidade (ERP), ver
 * sistema-configuracao/handlers/assiduidade.go. As chaves do mapa `metodos`
 * são as mesmas de `_SOURCE_TO_METODO` em
 * assiduidade_system_backend/app/services/attendance_validation.py — um
 * método sem entrada aí é tratado como activo por omissão (fail-open).
 */
class ConfigAssiduidadeFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private lateinit var sessionManager: SessionManager

    private lateinit var switchActivo: SwitchMaterial
    private lateinit var switchFacial: SwitchMaterial
    private lateinit var switchFingerprint: SwitchMaterial
    private lateinit var switchQrCode: SwitchMaterial
    private lateinit var switchNfc: SwitchMaterial
    private lateinit var switchPin: SwitchMaterial
    private lateinit var switchGeolocation: SwitchMaterial
    private lateinit var switchManual: SwitchMaterial
    private lateinit var btnGuardar: Button
    private lateinit var progressBar: ProgressBar
    private lateinit var tvStatus: TextView

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.gestor_config_assiduidade, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        sessionManager = SessionManager(requireContext())

        switchActivo = view.findViewById(R.id.switchActivo)
        switchFacial = view.findViewById(R.id.switchFacial)
        switchFingerprint = view.findViewById(R.id.switchFingerprint)
        switchQrCode = view.findViewById(R.id.switchQrCode)
        switchNfc = view.findViewById(R.id.switchNfc)
        switchPin = view.findViewById(R.id.switchPin)
        switchGeolocation = view.findViewById(R.id.switchGeolocation)
        switchManual = view.findViewById(R.id.switchManual)
        btnGuardar = view.findViewById(R.id.btnGuardarConfig)
        progressBar = view.findViewById(R.id.progressBarConfig)
        tvStatus = view.findViewById(R.id.tvConfigStatus)

        val token = sessionManager.getToken()
        if (token.isNullOrBlank()) {
            tvStatus.text = "Sessão inválida. Faça login novamente."
            btnGuardar.isEnabled = false
            return
        }

        btnGuardar.setOnClickListener { guardar(token) }

        carregar(token)
    }

    private fun carregar(token: String) {
        setLoading(true)
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getConfigAssiduidade(ApiUtils.bearerToken(token))
                }
                if (!response.isSuccessful || response.body() == null) {
                    tvStatus.text = ApiUtils.errorMessage(response)
                    setLoading(false)
                    return@launch
                }

                val body = response.body()!!
                val metodos = body.configuracao?.metodos.orEmpty()
                switchActivo.isChecked = body.activo
                switchFacial.isChecked = metodos["facial"]?.ativo ?: true
                switchFingerprint.isChecked = metodos["fingerprint"]?.ativo ?: true
                switchQrCode.isChecked = metodos["qr_code"]?.ativo ?: true
                switchNfc.isChecked = metodos["nfc"]?.ativo ?: true
                switchPin.isChecked = metodos["pin"]?.ativo ?: true
                switchGeolocation.isChecked = metodos["geolocation"]?.ativo ?: true
                switchManual.isChecked = metodos["manual"]?.ativo ?: true
                setLoading(false)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvStatus.text = "Não foi possível carregar a configuração."
                setLoading(false)
            }
        }
    }

    private fun guardar(token: String) {
        setLoading(true)
        tvStatus.text = ""

        val metodos = mapOf(
            "facial" to MetodoAssiduidadeConfig(switchFacial.isChecked),
            "fingerprint" to MetodoAssiduidadeConfig(switchFingerprint.isChecked),
            "qr_code" to MetodoAssiduidadeConfig(switchQrCode.isChecked),
            "nfc" to MetodoAssiduidadeConfig(switchNfc.isChecked),
            "pin" to MetodoAssiduidadeConfig(switchPin.isChecked),
            "geolocation" to MetodoAssiduidadeConfig(switchGeolocation.isChecked),
            "manual" to MetodoAssiduidadeConfig(switchManual.isChecked)
        )
        val request = AssiduidadeConfigRequest(
            activo = switchActivo.isChecked,
            configuracao = ConfiguracaoAssiduidade(metodos = metodos)
        )

        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.guardarConfigAssiduidade(
                        ApiUtils.bearerToken(token),
                        request
                    )
                }
                setLoading(false)
                if (response.isSuccessful) {
                    tvStatus.text = "Configuração guardada."
                } else {
                    tvStatus.text = ApiUtils.errorMessage(response)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                setLoading(false)
                tvStatus.text = "Não foi possível guardar a configuração."
            }
        }
    }

    private fun setLoading(isLoading: Boolean) {
        progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
        btnGuardar.isEnabled = !isLoading
    }
}
