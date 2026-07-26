package tech.e258tech.nexora_assiduidade.ui.gestor.crm.atividades

import android.app.DatePickerDialog
import android.app.TimePickerDialog
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.Spinner
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
import tech.e258tech.nexora_assiduidade.data.model.Atividade
import tech.e258tech.nexora_assiduidade.data.model.AtividadeRequest
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Criar/editar Atividade — POST/PUT /api/crm/atividades (ERP). Na criação,
 * exige exactamente um de lead_id/oportunidade_id (validado aqui antes do
 * pedido, espelhando a validação do backend). Em modo de edição, o
 * lead/oportunidade a que pertence não é exposto como editável.
 */
class AtividadeFormFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val tipos = Atividade.TIPOS.keys.toList()

    private var dataSelecionada: Calendar? = null

    companion object {
        private const val ARG_ATIVIDADE_ID = "atividade_id"
        private const val ARG_LEAD_ID = "lead_id"
        private const val ARG_OPORTUNIDADE_ID = "oportunidade_id"

        fun newInstance(
            atividadeId: Long? = null,
            leadId: Long? = null,
            oportunidadeId: Long? = null
        ): AtividadeFormFragment {
            return AtividadeFormFragment().apply {
                arguments = Bundle().apply {
                    atividadeId?.let { putLong(ARG_ATIVIDADE_ID, it) }
                    leadId?.let { putLong(ARG_LEAD_ID, it) }
                    oportunidadeId?.let { putLong(ARG_OPORTUNIDADE_ID, it) }
                }
            }
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return inflater.inflate(R.layout.gestor_crm_atividade_form, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val atividadeId = arguments?.getLong(ARG_ATIVIDADE_ID)?.takeIf { it > 0 }
        val leadId = arguments?.getLong(ARG_LEAD_ID)?.takeIf { it > 0 }
        val oportunidadeId = arguments?.getLong(ARG_OPORTUNIDADE_ID)?.takeIf { it > 0 }

        view.findViewById<View>(R.id.ivBack).setOnClickListener {
            parentFragmentManager.popBackStack()
        }

        view.findViewById<TextView>(R.id.tvTitle).text = if (atividadeId == null) "Nova Atividade" else "Editar Atividade"
        view.findViewById<TextView>(R.id.tvAlvo).text = when {
            leadId != null -> "Associada ao Lead #$leadId"
            oportunidadeId != null -> "Associada à Oportunidade #$oportunidadeId"
            atividadeId != null -> "" // preenchido depois de carregar, em bindAtividade
            else -> ""
        }

        val spTipo = view.findViewById<Spinner>(R.id.spTipo)
        spTipo.adapter = ArrayAdapter(
            requireContext(),
            android.R.layout.simple_spinner_dropdown_item,
            tipos.map { Atividade.tipoLabel(it) }
        )

        val etData = view.findViewById<TextInputEditText>(R.id.etData)
        val etHora = view.findViewById<TextInputEditText>(R.id.etHora)
        etData.setOnClickListener { abrirDatePicker(etData) }
        etHora.setOnClickListener { abrirTimePicker(etHora) }

        if (atividadeId != null) {
            carregarAtividade(view, atividadeId)
        }

        view.findViewById<Button>(R.id.btnGuardar).setOnClickListener {
            guardar(view, atividadeId, leadId, oportunidadeId)
        }
    }

    private fun abrirDatePicker(etData: TextInputEditText) {
        val cal = dataSelecionada ?: Calendar.getInstance()
        DatePickerDialog(
            requireContext(),
            { _, year, month, day ->
                val novaData = (dataSelecionada ?: Calendar.getInstance()).apply {
                    set(Calendar.YEAR, year)
                    set(Calendar.MONTH, month)
                    set(Calendar.DAY_OF_MONTH, day)
                }
                dataSelecionada = novaData
                etData.setText("%02d/%02d/%04d".format(day, month + 1, year))
            },
            cal.get(Calendar.YEAR), cal.get(Calendar.MONTH), cal.get(Calendar.DAY_OF_MONTH)
        ).show()
    }

    private fun abrirTimePicker(etHora: TextInputEditText) {
        val cal = dataSelecionada ?: Calendar.getInstance()
        TimePickerDialog(
            requireContext(),
            { _, hour, minute ->
                val novaData = (dataSelecionada ?: Calendar.getInstance()).apply {
                    set(Calendar.HOUR_OF_DAY, hour)
                    set(Calendar.MINUTE, minute)
                }
                dataSelecionada = novaData
                etHora.setText("%02d:%02d".format(hour, minute))
            },
            cal.get(Calendar.HOUR_OF_DAY), cal.get(Calendar.MINUTE), true
        ).show()
    }

    private fun carregarAtividade(view: View, atividadeId: Long) {
        val token = SessionManager(requireContext()).getToken() ?: return
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getAtividade(ApiUtils.bearerToken(token), atividadeId)
                }
                if (!response.isSuccessful || response.body() == null) {
                    view.findViewById<TextView>(R.id.tvStatus).text = ApiUtils.errorMessage(response)
                    return@launch
                }
                bindAtividade(view, response.body()!!)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                view.findViewById<TextView>(R.id.tvStatus).text = "Não foi possível carregar a atividade."
            }
        }
    }

    private fun bindAtividade(view: View, a: Atividade) {
        view.findViewById<TextInputEditText>(R.id.etTitulo).setText(a.titulo)
        view.findViewById<TextInputEditText>(R.id.etDescricao).setText(a.descricao)
        view.findViewById<TextInputEditText>(R.id.etResponsavel).setText(a.responsavel)
        view.findViewById<TextView>(R.id.tvAlvo).text = when {
            a.lead_id != null -> "Associada ao Lead #${a.lead_id}"
            a.oportunidade_id != null -> "Associada à Oportunidade #${a.oportunidade_id}"
            else -> ""
        }
        val idx = tipos.indexOf(a.tipo)
        if (idx >= 0) view.findViewById<Spinner>(R.id.spTipo).setSelection(idx)

        a.data_atividade?.let {
            view.findViewById<TextInputEditText>(R.id.etData).setText(DateTimeUtils.formatDate(it))
            view.findViewById<TextInputEditText>(R.id.etHora).setText(DateTimeUtils.formatDateTime(it).substringAfter(" "))
        }
    }

    private fun guardar(view: View, atividadeId: Long?, leadId: Long?, oportunidadeId: Long?) {
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

        // Espelha a validação do backend (atividades.go:136): exige
        // exactamente um de lead_id/oportunidade_id na criação. Na edição não
        // se aplica — o alvo já está definido e não é editável aqui.
        if (atividadeId == null && leadId == null && oportunidadeId == null) {
            tvStatus.text = "Indique a que Lead ou Oportunidade esta atividade pertence."
            return
        }

        val dataAtividade = dataSelecionada?.let {
            DateTimeUtils.localDateTimeForApi(
                it.get(Calendar.YEAR), it.get(Calendar.MONTH), it.get(Calendar.DAY_OF_MONTH),
                it.get(Calendar.HOUR_OF_DAY), it.get(Calendar.MINUTE)
            )
        }

        val request = AtividadeRequest(
            lead_id = leadId,
            oportunidade_id = oportunidadeId,
            tipo = tipos.getOrNull(view.findViewById<Spinner>(R.id.spTipo).selectedItemPosition),
            titulo = titulo,
            descricao = view.findViewById<TextInputEditText>(R.id.etDescricao).text?.toString()?.trim()?.takeIf { it.isNotBlank() },
            data_atividade = dataAtividade,
            responsavel = view.findViewById<TextInputEditText>(R.id.etResponsavel).text?.toString()?.trim()?.takeIf { it.isNotBlank() }
        )

        val btnGuardar = view.findViewById<Button>(R.id.btnGuardar)
        btnGuardar.isEnabled = false
        tvStatus.text = "A guardar..."

        uiScope.launch {
            try {
                val successful = withContext(Dispatchers.IO) {
                    if (atividadeId == null) {
                        RetrofitClient.erpApiService.criarAtividade(ApiUtils.bearerToken(token), request)
                    } else {
                        RetrofitClient.erpApiService.actualizarAtividade(ApiUtils.bearerToken(token), atividadeId, request)
                    }
                }

                if (successful.isSuccessful) {
                    Toast.makeText(context, "Atividade guardada com sucesso.", Toast.LENGTH_SHORT).show()
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
