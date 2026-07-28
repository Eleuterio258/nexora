package tech.e258tech.nexora_assiduidade.ui.gestor.funcionarios

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.ProgressBar
import android.widget.TextView
import androidx.fragment.app.Fragment
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.AdminSetPinRequest
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Ecrã de gestor/admin para definir o PIN de assiduidade de um funcionário —
 * POST /api/authcode/admin/set-pin (auth.AdminDefinirPIN, ERP), protegido por
 * `auth:pin_admin`. Sem isto não existia NENHUMA forma na app de criar a
 * linha `auth.user_auth_codes` (tipo='pin') que o método PIN de marcação de
 * ponto (`PinAttendanceFragment` → POST /api/authcode/pin/validate) precisa —
 * o método ficava sempre a falhar com "Credenciais inválidas" por falta de
 * PIN configurado, para qualquer funcionário.
 */
class DefinirPinFuncionarioFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    companion object {
        private const val ARG_USER_ID = "user_id"
        private const val PIN_MIN_LENGTH = 6

        fun newInstance(userId: Long): DefinirPinFuncionarioFragment {
            return DefinirPinFuncionarioFragment().apply {
                arguments = Bundle().apply { putLong(ARG_USER_ID, userId) }
            }
        }
    }

    private var userId: Long = 0L
    private lateinit var sessionManager: SessionManager

    private lateinit var etNovoPin: EditText
    private lateinit var etConfirmarPin: EditText
    private lateinit var tvStatus: TextView
    private lateinit var btnGuardar: Button
    private lateinit var progressBar: ProgressBar

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        userId = arguments?.getLong(ARG_USER_ID) ?: 0L
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.gestor_definir_pin, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        sessionManager = SessionManager(requireContext())
        etNovoPin = view.findViewById(R.id.etNovoPin)
        etConfirmarPin = view.findViewById(R.id.etConfirmarPin)
        tvStatus = view.findViewById(R.id.tvDefinirPinStatus)
        btnGuardar = view.findViewById(R.id.btnGuardarPin)
        progressBar = view.findViewById(R.id.progressBarDefinirPin)

        view.findViewById<View>(R.id.ivBack).setOnClickListener {
            parentFragmentManager.popBackStack()
        }

        btnGuardar.setOnClickListener { guardarPin() }
    }

    private fun guardarPin() {
        tvStatus.text = ""

        if (userId <= 0L) {
            tvStatus.text = "Este funcionário não tem conta de utilizador associada — não é possível definir PIN."
            return
        }

        val pin = etNovoPin.text.toString().trim()
        val confirmacao = etConfirmarPin.text.toString().trim()

        if (pin.length < PIN_MIN_LENGTH) {
            tvStatus.text = "O PIN deve ter no mínimo $PIN_MIN_LENGTH dígitos."
            return
        }
        if (pin != confirmacao) {
            tvStatus.text = "Os PINs não coincidem."
            return
        }

        val token = sessionManager.getToken()
        if (token.isNullOrBlank()) {
            tvStatus.text = "Sessão inválida. Faça login novamente."
            return
        }

        setLoading(true)
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.setAdminPin(
                        ApiUtils.bearerToken(token),
                        AdminSetPinRequest(user_id = userId, pin = pin)
                    )
                }
                setLoading(false)
                if (response.isSuccessful) {
                    tvStatus.text = ""
                    parentFragmentManager.popBackStack()
                } else {
                    tvStatus.text = ApiUtils.errorMessage(response)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                setLoading(false)
                tvStatus.text = "Não foi possível guardar o PIN."
            }
        }
    }

    private fun setLoading(isLoading: Boolean) {
        progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
        btnGuardar.isEnabled = !isLoading
    }
}
