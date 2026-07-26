package tech.e258tech.nexora_assiduidade.ui.gestor.crm.atividades

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.Atividade
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.ui.auth.LoginActivity
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils
import tech.e258tech.nexora_assiduidade.utils.PermissionUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Detalhe da Atividade — GET /api/crm/atividades/{id} (ERP). Só alcançado
 * pela lista global (as secções embutidas em Lead/Oportunidade vão
 * directamente para editar, não há aqui informação adicional relevante além
 * de a que Lead/Oportunidade pertence).
 */
class DetalheAtividadeFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private lateinit var sessionManager: SessionManager

    companion object {
        private const val ARG_ATIVIDADE_ID = "atividade_id"

        fun newInstance(atividadeId: Long): DetalheAtividadeFragment {
            return DetalheAtividadeFragment().apply {
                arguments = Bundle().apply { putLong(ARG_ATIVIDADE_ID, atividadeId) }
            }
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return inflater.inflate(R.layout.gestor_crm_detalhe_atividade, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        sessionManager = SessionManager(requireContext())

        view.findViewById<View>(R.id.ivBack).setOnClickListener {
            parentFragmentManager.popBackStack()
        }

        val atividadeId = arguments?.getLong(ARG_ATIVIDADE_ID)
        if (atividadeId == null) {
            view.findViewById<TextView>(R.id.tvTitulo).text = "Atividade inválida."
            return
        }

        carregarAtividade(view, atividadeId)
    }

    override fun onResume() {
        super.onResume()
        val atividadeId = arguments?.getLong(ARG_ATIVIDADE_ID) ?: return
        view?.let { carregarAtividade(it, atividadeId) }
    }

    private fun carregarAtividade(view: View, atividadeId: Long) {
        val token = sessionManager.getToken()
        val tvTitulo = view.findViewById<TextView>(R.id.tvTitulo)
        if (token.isNullOrBlank()) {
            tvTitulo.text = "Sessão inválida. Faça login novamente."
            return
        }

        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getAtividade(ApiUtils.bearerToken(token), atividadeId)
                }
                if (!response.isSuccessful || response.body() == null) {
                    tvTitulo.text = ApiUtils.errorMessage(response)
                    return@launch
                }
                bindAtividade(view, response.body()!!, atividadeId)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvTitulo.text = "Não foi possível carregar a atividade."
                Toast.makeText(context, "Falha ao consultar o ERP.", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun bindAtividade(view: View, a: Atividade, atividadeId: Long) {
        view.findViewById<TextView>(R.id.tvTitulo).text = a.titulo
        view.findViewById<TextView>(R.id.tvTipo).text = "Tipo: ${Atividade.tipoLabel(a.tipo)}"
        view.findViewById<TextView>(R.id.tvAlvo).text = when {
            a.lead_id != null -> "Lead #${a.lead_id}"
            a.oportunidade_id != null -> "Oportunidade #${a.oportunidade_id}"
            else -> "-"
        }
        view.findViewById<TextView>(R.id.tvData).text =
            "Data: ${a.data_atividade?.let { DateTimeUtils.formatDateTime(it) } ?: "Sem data"}"
        view.findViewById<TextView>(R.id.tvDescricao).text = "Descrição: ${a.descricao ?: "-"}"
        view.findViewById<TextView>(R.id.tvResponsavel).text = "Responsável: ${a.responsavel ?: "-"}"
        view.findViewById<TextView>(R.id.tvConcluida).text = if (a.concluida) "Concluída" else "Pendente"

        val podeGerir = PermissionUtils.has(sessionManager, "crm", "gerir_atividades")

        val btnEditar = view.findViewById<Button>(R.id.btnEditar)
        btnEditar.visibility = if (podeGerir) View.VISIBLE else View.GONE
        btnEditar.setOnClickListener {
            (activity as? LoginActivity)?.pushFragment(AtividadeFormFragment.newInstance(atividadeId = atividadeId))
        }

        val btnConcluir = view.findViewById<Button>(R.id.btnConcluir)
        btnConcluir.visibility = if (podeGerir && !a.concluida) View.VISIBLE else View.GONE
        btnConcluir.setOnClickListener { concluir(view, atividadeId) }

        val btnEliminar = view.findViewById<Button>(R.id.btnEliminar)
        btnEliminar.visibility = if (podeGerir) View.VISIBLE else View.GONE
        btnEliminar.setOnClickListener { confirmarEliminar(atividadeId) }
    }

    private fun concluir(view: View, atividadeId: Long) {
        val token = sessionManager.getToken() ?: return
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.concluirAtividade(ApiUtils.bearerToken(token), atividadeId)
                }
                if (response.isSuccessful) {
                    carregarAtividade(view, atividadeId)
                } else {
                    view.findViewById<TextView>(R.id.tvStatus).text = ApiUtils.errorMessage(response)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                view.findViewById<TextView>(R.id.tvStatus).text = "Falha ao concluir a atividade."
            }
        }
    }

    private fun confirmarEliminar(atividadeId: Long) {
        MaterialAlertDialogBuilder(requireContext())
            .setTitle("Eliminar atividade")
            .setMessage("Eliminar esta atividade? Esta ação não pode ser desfeita.")
            .setNegativeButton("Cancelar", null)
            .setPositiveButton("Eliminar") { _, _ -> eliminar(atividadeId) }
            .show()
    }

    private fun eliminar(atividadeId: Long) {
        val token = sessionManager.getToken() ?: return
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.eliminarAtividade(ApiUtils.bearerToken(token), atividadeId)
                }
                if (response.isSuccessful) {
                    Toast.makeText(context, "Atividade eliminada.", Toast.LENGTH_SHORT).show()
                    parentFragmentManager.popBackStack()
                } else {
                    view?.findViewById<TextView>(R.id.tvStatus)?.text = ApiUtils.errorMessage(response)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                view?.findViewById<TextView>(R.id.tvStatus)?.text = "Falha ao eliminar a atividade."
            }
        }
    }
}
