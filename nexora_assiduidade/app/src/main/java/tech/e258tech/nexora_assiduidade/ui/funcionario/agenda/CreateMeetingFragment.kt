package tech.e258tech.nexora_assiduidade.ui.funcionario.agenda

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import com.google.android.material.textfield.TextInputLayout
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.AgendaItemRequest
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager
import java.text.SimpleDateFormat
import java.util.Locale

/**
 * Tela de Criação de Reunião — POST /api/utilizadores/{userId}/agenda
 * (backend/internal/modules/utilizadores/handlers/agenda.go).
 */
class CreateMeetingFragment : Fragment() {

    private lateinit var sessionManager: SessionManager

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.funcionario_create_meeting, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        sessionManager = SessionManager(requireContext())

        val etTitle = view.findViewById<TextInputLayout>(R.id.etMeetingTitle)
        val etDate = view.findViewById<TextInputLayout>(R.id.etMeetingDate)
        val etTime = view.findViewById<TextInputLayout>(R.id.etMeetingTime)
        val btnCreate = view.findViewById<Button>(R.id.btnCreateMeeting)

        btnCreate.setOnClickListener {
            val title = etTitle.editText?.text?.toString().orEmpty()
            val date = etDate.editText?.text?.toString().orEmpty()
            val time = etTime.editText?.text?.toString().orEmpty()

            if (title.isEmpty() || date.isEmpty() || time.isEmpty()) {
                Toast.makeText(context, "Preencha os campos obrigatórios", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            val dataApi = toApiDate(date)
            if (dataApi == null) {
                etDate.error = "Data inválida"
                return@setOnClickListener
            }
            etDate.error = null

            criarReuniao(title, dataApi, time, btnCreate)
        }
    }

    private fun criarReuniao(titulo: String, data: String, horaInicio: String, btnCreate: Button) {
        val token = sessionManager.getToken()
        val userId = sessionManager.getUserId()
        if (token.isNullOrBlank() || userId.isNullOrBlank()) {
            Toast.makeText(context, "Sessão inválida. Faça login novamente.", Toast.LENGTH_LONG).show()
            return
        }

        btnCreate.isEnabled = false
        lifecycleScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.criarItemAgenda(
                        ApiUtils.bearerToken(token),
                        userId,
                        AgendaItemRequest(
                            titulo = titulo,
                            descricao = null,
                            data = data,
                            hora_inicio = horaInicio,
                            hora_fim = null
                        )
                    )
                }

                if (!isAdded) return@launch

                if (!response.isSuccessful) {
                    Toast.makeText(context, ApiUtils.errorMessage(response), Toast.LENGTH_LONG).show()
                    btnCreate.isEnabled = true
                    return@launch
                }

                Toast.makeText(context, "Reunião criada com sucesso!", Toast.LENGTH_SHORT).show()
                parentFragmentManager.popBackStack()
            } catch (e: Exception) {
                if (!isAdded) return@launch
                Toast.makeText(context, "Falha ao consultar o ERP.", Toast.LENGTH_LONG).show()
                btnCreate.isEnabled = true
            }
        }
    }

    /** Converte "dd/MM/yyyy" (inputType="date" do formulário) para "yyyy-MM-dd" (campo `data DATE` do ERP). */
    private fun toApiDate(value: String): String? {
        return try {
            val input = SimpleDateFormat("dd/MM/yyyy", Locale.getDefault())
            input.isLenient = false
            val parsed = input.parse(value) ?: return null
            SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(parsed)
        } catch (_: Exception) {
            null
        }
    }
}
