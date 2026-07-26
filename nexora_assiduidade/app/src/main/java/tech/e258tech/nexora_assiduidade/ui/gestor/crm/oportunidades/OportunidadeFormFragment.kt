package tech.e258tech.nexora_assiduidade.ui.gestor.crm.oportunidades

import android.app.DatePickerDialog
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.google.android.material.textfield.TextInputEditText
import java.util.Calendar
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.OportunidadeRequest
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Criar/editar Oportunidade — POST/PUT /api/crm/oportunidades (ERP). Nunca
 * inclui o campo `estágio`: criação assume "novo", actualização não o altera
 * (mudança de estágio é uma acção dedicada no ecrã de detalhe).
 */
class OportunidadeFormFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    /** "YYYY-MM-DD" seleccionado no date picker, se algum. */
    private var dataFechoPrevista: String? = null

    companion object {
        private const val ARG_OPORTUNIDADE_ID = "oportunidade_id"
        private const val ARG_PRESET_LEAD_ID = "preset_lead_id"

        fun newInstance(oportunidadeId: Long? = null, presetLeadId: Long? = null): OportunidadeFormFragment {
            return OportunidadeFormFragment().apply {
                arguments = Bundle().apply {
                    oportunidadeId?.let { putLong(ARG_OPORTUNIDADE_ID, it) }
                    presetLeadId?.let { putLong(ARG_PRESET_LEAD_ID, it) }
                }
            }
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return inflater.inflate(R.layout.gestor_crm_oportunidade_form, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val oportunidadeId = arguments?.getLong(ARG_OPORTUNIDADE_ID)?.takeIf { it > 0 }
        val presetLeadId = arguments?.getLong(ARG_PRESET_LEAD_ID)?.takeIf { it > 0 }

        view.findViewById<View>(R.id.ivBack).setOnClickListener {
            parentFragmentManager.popBackStack()
        }

        view.findViewById<TextView>(R.id.tvTitle).text = if (oportunidadeId == null) "Nova Oportunidade" else "Editar Oportunidade"

        if (presetLeadId != null) {
            view.findViewById<TextInputEditText>(R.id.etLeadId).setText(presetLeadId.toString())
        }

        val etDataFecho = view.findViewById<TextInputEditText>(R.id.etDataFecho)
        etDataFecho.setOnClickListener { abrirDatePicker(etDataFecho) }

        if (oportunidadeId != null) {
            carregarOportunidade(view, oportunidadeId)
        }

        view.findViewById<Button>(R.id.btnGuardar).setOnClickListener {
            guardar(view, oportunidadeId)
        }
    }

    private fun abrirDatePicker(etDataFecho: TextInputEditText) {
        val cal = Calendar.getInstance()
        DatePickerDialog(
            requireContext(),
            { _, year, month, day ->
                dataFechoPrevista = DateTimeUtils.dateOnlyForApi(year, month, day)
                etDataFecho.setText(DateTimeUtils.formatDateOnly(dataFechoPrevista!!))
            },
            cal.get(Calendar.YEAR), cal.get(Calendar.MONTH), cal.get(Calendar.DAY_OF_MONTH)
        ).show()
    }

    private fun carregarOportunidade(view: View, oportunidadeId: Long) {
        val token = SessionManager(requireContext()).getToken() ?: return
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getOportunidade(ApiUtils.bearerToken(token), oportunidadeId)
                }
                if (!response.isSuccessful || response.body() == null) {
                    view.findViewById<TextView>(R.id.tvStatus).text = ApiUtils.errorMessage(response)
                    return@launch
                }
                val o = response.body()!!
                view.findViewById<TextInputEditText>(R.id.etTitulo).setText(o.titulo)
                view.findViewById<TextInputEditText>(R.id.etLeadId).setText(o.lead_id?.toString() ?: "")
                view.findViewById<TextInputEditText>(R.id.etClienteId).setText(o.cliente_id?.toString() ?: "")
                view.findViewById<TextInputEditText>(R.id.etValor).setText(o.valor_estimado.toString())
                view.findViewById<TextInputEditText>(R.id.etMoeda).setText(o.moeda)
                view.findViewById<TextInputEditText>(R.id.etProbabilidade).setText(o.probabilidade.toString())
                view.findViewById<TextInputEditText>(R.id.etResponsavel).setText(o.responsavel)
                view.findViewById<TextInputEditText>(R.id.etDescricao).setText(o.descricao)
                o.data_fecho_prevista?.let {
                    dataFechoPrevista = it
                    view.findViewById<TextInputEditText>(R.id.etDataFecho).setText(DateTimeUtils.formatDateOnly(it))
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                view.findViewById<TextView>(R.id.tvStatus).text = "Não foi possível carregar a oportunidade."
            }
        }
    }

    private fun guardar(view: View, oportunidadeId: Long?) {
        val token = SessionManager(requireContext()).getToken()
        val tvStatus = view.findViewById<TextView>(R.id.tvStatus)
        if (token.isNullOrBlank()) {
            tvStatus.text = "Sessão inválida. Faça login novamente."
            return
        }

        val titulo = view.findViewById<TextInputEditText>(R.id.etTitulo).text?.toString()?.trim()
        if (titulo.isNullOrBlank()) {
            tvStatus.text = "O título é obrigatório."
            return
        }

        val valor = view.findViewById<TextInputEditText>(R.id.etValor).text?.toString()?.trim()?.toDoubleOrNull()
        if (valor != null && valor < 0) {
            tvStatus.text = "O valor estimado não pode ser negativo."
            return
        }

        val probabilidade = view.findViewById<TextInputEditText>(R.id.etProbabilidade).text?.toString()?.trim()?.toIntOrNull()
        if (probabilidade != null && (probabilidade < 0 || probabilidade > 100)) {
            tvStatus.text = "A probabilidade deve estar entre 0 e 100."
            return
        }

        val request = OportunidadeRequest(
            titulo = titulo,
            lead_id = view.findViewById<TextInputEditText>(R.id.etLeadId).text?.toString()?.trim()?.toLongOrNull(),
            cliente_id = view.findViewById<TextInputEditText>(R.id.etClienteId).text?.toString()?.trim()?.toLongOrNull(),
            valor_estimado = valor,
            moeda = view.findViewById<TextInputEditText>(R.id.etMoeda).text?.toString()?.trim()?.takeIf { it.isNotBlank() },
            probabilidade = probabilidade,
            data_fecho_prevista = dataFechoPrevista,
            responsavel = view.findViewById<TextInputEditText>(R.id.etResponsavel).text?.toString()?.trim()?.takeIf { it.isNotBlank() },
            descricao = view.findViewById<TextInputEditText>(R.id.etDescricao).text?.toString()?.trim()?.takeIf { it.isNotBlank() }
        )

        val btnGuardar = view.findViewById<Button>(R.id.btnGuardar)
        btnGuardar.isEnabled = false
        tvStatus.text = "A guardar..."

        uiScope.launch {
            try {
                val successful = withContext(Dispatchers.IO) {
                    if (oportunidadeId == null) {
                        RetrofitClient.erpApiService.criarOportunidade(ApiUtils.bearerToken(token), request)
                    } else {
                        RetrofitClient.erpApiService.actualizarOportunidade(ApiUtils.bearerToken(token), oportunidadeId, request)
                    }
                }

                if (successful.isSuccessful) {
                    Toast.makeText(context, "Oportunidade guardada com sucesso.", Toast.LENGTH_SHORT).show()
                    parentFragmentManager.popBackStack()
                } else {
                    tvStatus.text = ApiUtils.errorMessage(successful)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvStatus.text = "Falha ao comunicar com o ERP."
            } finally {
                if (isAdded) btnGuardar.isEnabled = true
            }
        }
    }
}
