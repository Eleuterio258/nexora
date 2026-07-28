package tech.e258tech.nexora_assiduidade.ui.funcionario.attendance

import android.app.DatePickerDialog
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.JustificacaoRequest
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager
import java.util.Calendar

/**
 * Justificação de falta ou atraso, submetida directamente ao Nexora ERP
 * (POST /api/self-service/assiduidade/justificacoes). Reescrito para corrigir
 * duas lacunas funcionais que existiam aqui, não só estéticas:
 * 1) o ecrã não tinha selector de `tipo` — enviava sempre "falta" ao ERP
 *    mesmo que o colaborador estivesse a justificar um atraso;
 * 2) não havia selector de data — enviava sempre a data de hoje, tornando
 *    impossível justificar uma falta de um dia anterior.
 * Também passou a mostrar o histórico (GET .../justificacoes) com o estado
 * de cada pedido — antes disto era "enviar e esquecer", sem forma de saber
 * se tinha sido aprovado ou rejeitado.
 */
class JustifyAbsenceFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private lateinit var sessionManager: SessionManager

    private lateinit var etData: EditText
    private lateinit var etDescricao: EditText
    private lateinit var btnTipoFalta: Button
    private lateinit var btnTipoAtraso: Button
    private lateinit var tvJustifyErro: TextView
    private lateinit var btnSubmit: Button
    private lateinit var progressBar: ProgressBar
    private lateinit var recyclerViewHistorico: RecyclerView
    private lateinit var tvHistoricoVazio: TextView

    private var tipoSelecionado = "falta"
    private var dataSelecionada: Calendar = Calendar.getInstance()

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

        sessionManager = SessionManager(requireContext())

        view.findViewById<View>(R.id.ivBack).setOnClickListener {
            parentFragmentManager.popBackStack()
        }

        etData = view.findViewById(R.id.etData)
        etDescricao = view.findViewById(R.id.etDescricao)
        btnTipoFalta = view.findViewById(R.id.btnTipoFalta)
        btnTipoAtraso = view.findViewById(R.id.btnTipoAtraso)
        tvJustifyErro = view.findViewById(R.id.tvJustifyErro)
        btnSubmit = view.findViewById(R.id.btnSubmitJustification)
        progressBar = view.findViewById(R.id.progressBarJustify)
        recyclerViewHistorico = view.findViewById(R.id.recyclerViewMinhasJustificacoes)
        recyclerViewHistorico.layoutManager = LinearLayoutManager(context)
        tvHistoricoVazio = view.findViewById(R.id.tvHistoricoVazio)

        btnTipoFalta.setOnClickListener { selecionarTipo("falta") }
        btnTipoAtraso.setOnClickListener { selecionarTipo("atraso") }
        selecionarTipo("falta")

        atualizarTextoData()
        etData.setOnClickListener { abrirDatePicker() }

        btnSubmit.setOnClickListener { submeter() }

        carregarHistorico()
    }

    override fun onResume() {
        super.onResume()
        carregarHistorico()
    }

    private fun selecionarTipo(tipo: String) {
        tipoSelecionado = tipo
        val corAccent = resources.getColor(R.color.brand_accent, null)
        val corBranco = resources.getColor(R.color.white, null)
        val corTransparente = resources.getColor(android.R.color.transparent, null)

        fun aplicarEstado(button: Button, selecionado: Boolean) {
            button.backgroundTintList = android.content.res.ColorStateList.valueOf(
                if (selecionado) corAccent else corTransparente
            )
            button.setTextColor(if (selecionado) corBranco else corAccent)
        }
        aplicarEstado(btnTipoFalta, tipo == "falta")
        aplicarEstado(btnTipoAtraso, tipo == "atraso")
    }

    private fun atualizarTextoData() {
        etData.setText(
            "%02d/%02d/%04d".format(
                dataSelecionada.get(Calendar.DAY_OF_MONTH),
                dataSelecionada.get(Calendar.MONTH) + 1,
                dataSelecionada.get(Calendar.YEAR)
            )
        )
    }

    private fun abrirDatePicker() {
        DatePickerDialog(
            requireContext(),
            { _, year, month, day ->
                dataSelecionada = Calendar.getInstance().apply {
                    set(Calendar.YEAR, year)
                    set(Calendar.MONTH, month)
                    set(Calendar.DAY_OF_MONTH, day)
                }
                atualizarTextoData()
            },
            dataSelecionada.get(Calendar.YEAR),
            dataSelecionada.get(Calendar.MONTH),
            dataSelecionada.get(Calendar.DAY_OF_MONTH)
        ).apply {
            datePicker.maxDate = System.currentTimeMillis()
        }.show()
    }

    private fun submeter() {
        tvJustifyErro.visibility = View.GONE
        val descricao = etDescricao.text.toString().trim()
        val token = sessionManager.getToken()

        if (descricao.isEmpty()) {
            mostrarErro("Descreva o motivo da $tipoSelecionado.")
            return
        }
        if (token.isNullOrBlank()) {
            mostrarErro("Sessão inválida. Faça login novamente.")
            return
        }

        setLoading(true)
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.criarJustificacao(
                        ApiUtils.bearerToken(token),
                        JustificacaoRequest(
                            tipo = tipoSelecionado,
                            data = DateTimeUtils.dateOnlyForApi(
                                dataSelecionada.get(Calendar.YEAR),
                                dataSelecionada.get(Calendar.MONTH),
                                dataSelecionada.get(Calendar.DAY_OF_MONTH)
                            ),
                            motivo = descricao
                        )
                    )
                }

                setLoading(false)
                if (!response.isSuccessful || response.body() == null) {
                    mostrarErro(ApiUtils.errorMessage(response))
                    return@launch
                }

                Toast.makeText(context, "Justificação enviada com sucesso.", Toast.LENGTH_SHORT).show()
                etDescricao.setText("")
                carregarHistorico()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                setLoading(false)
                mostrarErro("Não foi possível enviar a justificação. Verifique a ligação.")
            }
        }
    }

    private fun carregarHistorico() {
        val token = sessionManager.getToken() ?: return
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getMinhasJustificacoes(ApiUtils.bearerToken(token))
                }
                if (!isAdded) return@launch
                val itens = if (response.isSuccessful) response.body().orEmpty() else emptyList()

                if (itens.isEmpty()) {
                    recyclerViewHistorico.visibility = View.GONE
                    tvHistoricoVazio.visibility = View.VISIBLE
                } else {
                    tvHistoricoVazio.visibility = View.GONE
                    recyclerViewHistorico.visibility = View.VISIBLE
                    recyclerViewHistorico.adapter = MinhasJustificacoesAdapter(itens)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                // Falha de rede: mantém o histórico como estava.
            }
        }
    }

    private fun mostrarErro(mensagem: String) {
        tvJustifyErro.text = mensagem
        tvJustifyErro.visibility = View.VISIBLE
    }

    private fun setLoading(isLoading: Boolean) {
        progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
        btnSubmit.isEnabled = !isLoading
    }
}
