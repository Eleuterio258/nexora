package tech.e258tech.nexora_assiduidade.ui.gestor.crm.oportunidades

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
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.textfield.TextInputEditText
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.Oportunidade
import tech.e258tech.nexora_assiduidade.data.model.OportunidadeEstagioRequest
import tech.e258tech.nexora_assiduidade.data.model.OportunidadePerderRequest
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.ui.auth.LoginActivity
import tech.e258tech.nexora_assiduidade.ui.gestor.crm.atividades.AtividadeFormFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.crm.atividades.AtividadesAdapter
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils
import tech.e258tech.nexora_assiduidade.utils.PermissionUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Detalhe da Oportunidade — GET /api/crm/oportunidades/{id} (ERP).
 */
class DetalheOportunidadeFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private lateinit var sessionManager: SessionManager

    /** Estágios não-terminais, excluindo "perdido" de propósito — perder só
     * pelo fluxo dedicado (/perder), que exige motivo. */
    private val estagiosSelecionaveis = Oportunidade.ESTAGIOS.keys.filter { it != "perdido" }

    companion object {
        private const val ARG_OPORTUNIDADE_ID = "oportunidade_id"

        fun newInstance(oportunidadeId: Long): DetalheOportunidadeFragment {
            return DetalheOportunidadeFragment().apply {
                arguments = Bundle().apply { putLong(ARG_OPORTUNIDADE_ID, oportunidadeId) }
            }
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return inflater.inflate(R.layout.gestor_crm_detalhe_oportunidade, container, false)
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

        val oportunidadeId = arguments?.getLong(ARG_OPORTUNIDADE_ID)
        if (oportunidadeId == null) {
            view.findViewById<TextView>(R.id.tvTitulo).text = "Oportunidade inválida."
            return
        }

        carregarOportunidade(view, oportunidadeId)
        carregarAtividades(view, oportunidadeId)

        view.findViewById<Button>(R.id.btnAdicionarAtividade).setOnClickListener {
            (activity as? LoginActivity)?.pushFragment(AtividadeFormFragment.newInstance(oportunidadeId = oportunidadeId))
        }
        view.findViewById<Button>(R.id.btnAdicionarAtividade).visibility =
            if (PermissionUtils.has(sessionManager, "crm", "gerir_atividades")) View.VISIBLE else View.GONE
    }

    override fun onResume() {
        super.onResume()
        val oportunidadeId = arguments?.getLong(ARG_OPORTUNIDADE_ID) ?: return
        view?.let {
            carregarOportunidade(it, oportunidadeId)
            carregarAtividades(it, oportunidadeId)
        }
    }

    private fun carregarOportunidade(view: View, oportunidadeId: Long) {
        val token = sessionManager.getToken()
        val tvTitulo = view.findViewById<TextView>(R.id.tvTitulo)
        if (token.isNullOrBlank()) {
            tvTitulo.text = "Sessão inválida. Faça login novamente."
            return
        }

        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getOportunidade(ApiUtils.bearerToken(token), oportunidadeId)
                }
                if (!response.isSuccessful || response.body() == null) {
                    tvTitulo.text = ApiUtils.errorMessage(response)
                    return@launch
                }
                bindOportunidade(view, response.body()!!, oportunidadeId)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvTitulo.text = "Não foi possível carregar a oportunidade."
                Toast.makeText(context, "Falha ao consultar o ERP.", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun bindOportunidade(view: View, o: Oportunidade, oportunidadeId: Long) {
        view.findViewById<TextView>(R.id.tvTitulo).text = o.titulo
        view.findViewById<TextView>(R.id.tvValor).text = "Valor: ${o.moeda} ${"%.2f".format(o.valor_estimado)}"
        view.findViewById<TextView>(R.id.tvProbabilidade).text = "Probabilidade: ${o.probabilidade}%"
        view.findViewById<TextView>(R.id.tvDataFecho).text =
            "Fecho previsto: ${o.data_fecho_prevista?.let { DateTimeUtils.formatDateOnly(it) } ?: "-"}" +
                (o.data_fecho_real?.let { " · Fecho real: ${DateTimeUtils.formatDateOnly(it)}" } ?: "")
        view.findViewById<TextView>(R.id.tvResponsavel).text = "Responsável: ${o.responsavel ?: "-"}"
        view.findViewById<TextView>(R.id.tvDescricao).text = "Descrição: ${o.descricao ?: "-"}"
        view.findViewById<TextView>(R.id.tvEstagioAtual).text = "Estágio: ${Oportunidade.estagioLabel(o.estagio)}"

        val tvMotivoPerda = view.findViewById<TextView>(R.id.tvMotivoPerda)
        if (!o.motivo_perda.isNullOrBlank()) {
            tvMotivoPerda.text = "Motivo da perda: ${o.motivo_perda}"
            tvMotivoPerda.visibility = View.VISIBLE
        } else {
            tvMotivoPerda.visibility = View.GONE
        }

        val terminal = o.estagio in Oportunidade.TERMINAIS

        val btnEditar = view.findViewById<Button>(R.id.btnEditar)
        btnEditar.visibility = if (PermissionUtils.has(sessionManager, "crm", "gerir_oportunidades")) View.VISIBLE else View.GONE
        btnEditar.setOnClickListener {
            (activity as? LoginActivity)?.pushFragment(OportunidadeFormFragment.newInstance(oportunidadeId))
        }

        val layoutEstagio = view.findViewById<View>(R.id.layoutEstagioSection)
        val podeGerir = PermissionUtils.has(sessionManager, "crm", "gerir_oportunidades") && !terminal
        layoutEstagio.visibility = if (podeGerir) View.VISIBLE else View.GONE
        if (podeGerir) {
            val spEstagio = view.findViewById<Spinner>(R.id.spEstagioNovo)
            spEstagio.adapter = ArrayAdapter(
                requireContext(),
                android.R.layout.simple_spinner_dropdown_item,
                estagiosSelecionaveis.map { Oportunidade.estagioLabel(it) }
            )
            val idx = estagiosSelecionaveis.indexOf(o.estagio)
            if (idx >= 0) spEstagio.setSelection(idx)

            view.findViewById<Button>(R.id.btnActualizarEstagio).setOnClickListener {
                actualizarEstagio(view, oportunidadeId, estagiosSelecionaveis[spEstagio.selectedItemPosition])
            }

            val tilMotivo = view.findViewById<View>(R.id.tilMotivoPerda)
            val btnConfirmarPerdida = view.findViewById<Button>(R.id.btnConfirmarPerdida)
            view.findViewById<Button>(R.id.btnMostrarPerdida).setOnClickListener {
                tilMotivo.visibility = View.VISIBLE
                btnConfirmarPerdida.visibility = View.VISIBLE
            }
            btnConfirmarPerdida.setOnClickListener {
                marcarPerdida(view, oportunidadeId)
            }
        }

        val btnEliminar = view.findViewById<Button>(R.id.btnEliminar)
        // Sem permissão dedicada — o backend reutiliza "crm:eliminar_leads"
        // para DELETE /oportunidades/{id} (router.go:1668), replicado aqui.
        btnEliminar.visibility = if (PermissionUtils.has(sessionManager, "crm", "eliminar_leads")) View.VISIBLE else View.GONE
        btnEliminar.setOnClickListener {
            confirmarEliminar(view, oportunidadeId)
        }
    }

    private fun actualizarEstagio(view: View, oportunidadeId: Long, novoEstagio: String) {
        val token = sessionManager.getToken() ?: return
        val tvStatus = view.findViewById<TextView>(R.id.tvStatus)
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.moverOportunidade(
                        ApiUtils.bearerToken(token), oportunidadeId, OportunidadeEstagioRequest(novoEstagio)
                    )
                }
                if (response.isSuccessful) {
                    tvStatus.text = "Estágio actualizado."
                    carregarOportunidade(view, oportunidadeId)
                } else {
                    tvStatus.text = ApiUtils.errorMessage(response)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvStatus.text = "Falha ao actualizar o estágio."
            }
        }
    }

    private fun marcarPerdida(view: View, oportunidadeId: Long) {
        val token = sessionManager.getToken() ?: return
        val tvStatus = view.findViewById<TextView>(R.id.tvStatus)
        val motivo = view.findViewById<TextInputEditText>(R.id.etMotivoPerda).text?.toString()?.trim()
        if (motivo.isNullOrBlank()) {
            tvStatus.text = "Indique o motivo da perda."
            return
        }

        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.marcarOportunidadePerdida(
                        ApiUtils.bearerToken(token), oportunidadeId, OportunidadePerderRequest(motivo)
                    )
                }
                if (response.isSuccessful) {
                    tvStatus.text = "Oportunidade marcada como perdida."
                    carregarOportunidade(view, oportunidadeId)
                } else {
                    tvStatus.text = ApiUtils.errorMessage(response)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvStatus.text = "Falha ao marcar como perdida."
            }
        }
    }

    private fun confirmarEliminar(view: View, oportunidadeId: Long) {
        MaterialAlertDialogBuilder(requireContext())
            .setTitle("Eliminar oportunidade")
            .setMessage("Eliminar esta oportunidade? Esta ação não pode ser desfeita.")
            .setNegativeButton("Cancelar", null)
            .setPositiveButton("Eliminar") { _, _ -> eliminar(view, oportunidadeId) }
            .show()
    }

    private fun eliminar(view: View, oportunidadeId: Long) {
        val token = sessionManager.getToken() ?: return
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.eliminarOportunidade(ApiUtils.bearerToken(token), oportunidadeId)
                }
                if (response.isSuccessful) {
                    Toast.makeText(context, "Oportunidade eliminada.", Toast.LENGTH_SHORT).show()
                    parentFragmentManager.popBackStack()
                } else {
                    view.findViewById<TextView>(R.id.tvStatus).text = ApiUtils.errorMessage(response)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                view.findViewById<TextView>(R.id.tvStatus).text = "Falha ao eliminar a oportunidade."
            }
        }
    }

    private fun carregarAtividades(view: View, oportunidadeId: Long) {
        val token = sessionManager.getToken() ?: return
        val recyclerView = view.findViewById<RecyclerView>(R.id.recyclerViewAtividades)
        val tvEmpty = view.findViewById<TextView>(R.id.tvAtividadesEmpty)
        recyclerView.layoutManager = LinearLayoutManager(context)

        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getAtividades(ApiUtils.bearerToken(token), oportunidadeId = oportunidadeId)
                }
                val itens = response.body()?.data.orEmpty()
                if (itens.isEmpty()) {
                    tvEmpty.visibility = View.VISIBLE
                    recyclerView.visibility = View.GONE
                } else {
                    tvEmpty.visibility = View.GONE
                    recyclerView.visibility = View.VISIBLE
                    recyclerView.adapter = AtividadesAdapter(
                        items = itens,
                        onClick = null,
                        onConcluir = { atividade -> concluirAtividade(view, oportunidadeId, atividade.id) },
                        podeConcluir = PermissionUtils.has(sessionManager, "crm", "gerir_atividades")
                    )
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvEmpty.visibility = View.VISIBLE
                recyclerView.visibility = View.GONE
            }
        }
    }

    private fun concluirAtividade(view: View, oportunidadeId: Long, atividadeId: Long) {
        val token = sessionManager.getToken() ?: return
        uiScope.launch {
            try {
                withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.concluirAtividade(ApiUtils.bearerToken(token), atividadeId)
                }
                carregarAtividades(view, oportunidadeId)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                Toast.makeText(context, "Falha ao concluir a atividade.", Toast.LENGTH_SHORT).show()
            }
        }
    }
}
