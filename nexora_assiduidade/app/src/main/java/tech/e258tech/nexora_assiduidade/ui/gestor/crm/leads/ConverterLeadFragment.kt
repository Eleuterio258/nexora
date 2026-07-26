package tech.e258tech.nexora_assiduidade.ui.gestor.crm.leads

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.CheckBox
import android.widget.TextView
import androidx.fragment.app.Fragment
import com.google.android.material.textfield.TextInputEditText
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.LeadConverterRequest
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Converter Lead em Cliente (+ Oportunidade opcional) — POST /api/crm/leads/{id}/converter.
 */
class ConverterLeadFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    companion object {
        private const val ARG_LEAD_ID = "lead_id"

        fun newInstance(leadId: Long): ConverterLeadFragment {
            return ConverterLeadFragment().apply {
                arguments = Bundle().apply { putLong(ARG_LEAD_ID, leadId) }
            }
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return inflater.inflate(R.layout.gestor_crm_converter_lead, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        view.findViewById<View>(R.id.ivBack).setOnClickListener {
            parentFragmentManager.popBackStack()
        }

        val leadId = arguments?.getLong(ARG_LEAD_ID)
        val layoutCampos = view.findViewById<View>(R.id.layoutOportunidadeCampos)

        view.findViewById<CheckBox>(R.id.cbCriarOportunidade).setOnCheckedChangeListener { _, checked ->
            layoutCampos.visibility = if (checked) View.VISIBLE else View.GONE
        }

        view.findViewById<Button>(R.id.btnConverter).setOnClickListener {
            if (leadId == null) return@setOnClickListener
            converter(view, leadId)
        }

        view.findViewById<Button>(R.id.btnConcluido).setOnClickListener {
            // Volta duas vezes: fecha este ecrã e o detalhe do lead por baixo,
            // que ficou desactualizado (o lead já não está mais em estado
            // não-terminal depois de convertido).
            parentFragmentManager.popBackStack()
            parentFragmentManager.popBackStack()
        }
    }

    private fun converter(view: View, leadId: Long) {
        val token = SessionManager(requireContext()).getToken()
        val tvStatus = view.findViewById<TextView>(R.id.tvStatus)
        if (token.isNullOrBlank()) {
            tvStatus.text = "Sessão inválida. Faça login novamente."
            return
        }

        val criarOportunidade = view.findViewById<CheckBox>(R.id.cbCriarOportunidade).isChecked
        val titulo = view.findViewById<TextInputEditText>(R.id.etTitulo).text?.toString()?.trim()?.takeIf { it.isNotBlank() }
        val valorTexto = view.findViewById<TextInputEditText>(R.id.etValor).text?.toString()?.trim()
        val valor = valorTexto?.toDoubleOrNull()
        val moeda = view.findViewById<TextInputEditText>(R.id.etMoeda).text?.toString()?.trim()?.takeIf { it.isNotBlank() }

        val request = LeadConverterRequest(
            criar_oportunidade = criarOportunidade,
            oportunidade_titulo = if (criarOportunidade) titulo else null,
            valor_estimado = if (criarOportunidade) valor else null,
            moeda = if (criarOportunidade) moeda else null
        )

        val btnConverter = view.findViewById<Button>(R.id.btnConverter)
        btnConverter.isEnabled = false
        tvStatus.text = "A converter..."

        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.converterLead(ApiUtils.bearerToken(token), leadId, request)
                }

                if (response.isSuccessful && response.body() != null) {
                    val body = response.body()!!
                    tvStatus.text = buildString {
                        append("Lead convertido com sucesso.\n")
                        append("Cliente #${body.cliente_id ?: "-"}")
                        body.oportunidade_id?.let { append("\nOportunidade #$it criada.") }
                    }
                    btnConverter.visibility = View.GONE
                    view.findViewById<Button>(R.id.btnConcluido).visibility = View.VISIBLE
                } else {
                    tvStatus.text = ApiUtils.errorMessage(response)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvStatus.text = "Falha ao converter o lead."
            } finally {
                if (isAdded) btnConverter.isEnabled = true
            }
        }
    }
}
