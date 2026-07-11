package tech.e258tech.nexora_assiduidade.ui.funcionario.attendance

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.Toast
import androidx.fragment.app.Fragment
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.AdjustmentRequestInput
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

class JustifyAbsenceFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return inflater.inflate(R.layout.funcionario_justify_absence, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val etMotivo = view.findViewById<EditText>(R.id.etMotivo)
        val etDescricao = view.findViewById<EditText>(R.id.etDescricao)
        val btnSubmit = view.findViewById<Button>(R.id.btnSubmitJustification)
        val sessionManager = SessionManager(requireContext())

        btnSubmit.setOnClickListener {
            val motivo = etMotivo.text.toString().trim()
            val descricao = etDescricao.text.toString().trim()
            val token = sessionManager.getToken()

            if (motivo.isEmpty() || descricao.isEmpty()) {
                Toast.makeText(context, "Preencha todos os campos", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            if (token.isNullOrBlank()) {
                Toast.makeText(context, "Sessao invalida. Faca login novamente.", Toast.LENGTH_LONG)
                    .show()
                return@setOnClickListener
            }

            btnSubmit.isEnabled = false
            submitAdjustment(token, "$motivo: $descricao", btnSubmit)
        }
    }

    private fun submitAdjustment(token: String, reason: String, button: Button) {
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.assiduidadeApiService.createAdjustment(
                        ApiUtils.bearerToken(token),
                        AdjustmentRequestInput(
                            requested_recorded_at = DateTimeUtils.nowForApi(),
                            reason = reason
                        )
                    )
                }

                if (!response.isSuccessful || response.body() == null) {
                    Toast.makeText(
                        context,
                        ApiUtils.errorMessage(response),
                        Toast.LENGTH_LONG
                    ).show()
                    return@launch
                }

                Toast.makeText(
                    context,
                    "Justificativa enviada com sucesso.",
                    Toast.LENGTH_SHORT
                ).show()
                parentFragmentManager.popBackStack()
            } catch (_: Exception) {
                Toast.makeText(
                    context,
                    "Nao foi possivel enviar a justificativa.",
                    Toast.LENGTH_LONG
                ).show()
            } finally {
                button.isEnabled = true
            }
        }
    }
}
