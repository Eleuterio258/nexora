package tech.e258tech.nexora_assiduidade.ui.funcionario.home

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.TextView
import androidx.cardview.widget.CardView
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.local.AppDatabase
import tech.e258tech.nexora_assiduidade.data.local.PendingEventEntity
import tech.e258tech.nexora_assiduidade.data.model.AgendaItem
import tech.e258tech.nexora_assiduidade.data.model.MarcarLidaRequest
import tech.e258tech.nexora_assiduidade.data.model.response.ComunicadoHome
import tech.e258tech.nexora_assiduidade.data.model.response.NotificacaoHome
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.ui.auth.LoginActivity
import tech.e258tech.nexora_assiduidade.ui.funcionario.agenda.AgendaFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.agenda.AgendaItemDetailFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.attendance.FacialAttendanceFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.attendance.FingerprintAttendanceFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.attendance.NfcAttendanceFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.attendance.PinAttendanceFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.attendance.QrCodeAttendanceFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.attendance.SelfieGpsAttendanceFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.registo.RegistoManualFragment
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils
import tech.e258tech.nexora_assiduidade.utils.PermissionUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import kotlinx.coroutines.CancellationException

/**
 * Tela Home do Funcionário
 * Exibe as opções de registro de presença, o resumo pessoal (saldo de
 * férias/assiduidade/pedidos pendentes/notificações/comunicados/
 * aniversários — GET /api/self-service/home) e a agenda da semana
 * (GET /api/utilizadores/{userId}/agenda).
 */
class HomeFuncionarioFragment : Fragment() {

    private lateinit var sessionManager: SessionManager
    private lateinit var tvPendingSync: TextView

    // Cards de método, guardados como campos (não só locais no
    // onViewCreated) para poderem ser escondidos/mostrados de forma
    // assíncrona por aplicarMetodosActivos(), depois de a config do tenant
    // chegar do ERP.
    private lateinit var cardManual: CardView
    private lateinit var cardQrCode: CardView
    private lateinit var cardFacial: CardView
    private lateinit var cardSelfieGps: CardView
    private lateinit var cardPin: CardView
    private lateinit var cardNfc: CardView
    private lateinit var cardFingerprint: CardView

    // Resumo pessoal (GET /api/self-service/home)
    private lateinit var tvSaldoFeriasDias: TextView
    private lateinit var tvSaldoFeriasTotal: TextView
    private lateinit var tvDiasTrabalhados: TextView
    private lateinit var tvHorasTrabalhadas: TextView
    private lateinit var tvAtrasos: TextView
    private lateinit var tvFaltas: TextView
    private lateinit var cardPedidosPendentes: View
    private lateinit var tvPedidosPendentesCount: TextView
    private lateinit var itemNotificacaoRecente: View
    private lateinit var tvNotificacaoTitulo: TextView
    private lateinit var tvNotificacaoCorpo: TextView
    private lateinit var tvNotificacaoData: TextView
    private lateinit var itemComunicadoRecente: View
    private lateinit var tvComunicadoTitulo: TextView
    private lateinit var tvComunicadoNovo: TextView
    private lateinit var tvComunicadoData: TextView
    private lateinit var tvAniversarioNome: TextView
    private lateinit var tvAniversarioSub: TextView

    private var notificacaoActual: NotificacaoHome? = null
    private var comunicadoActual: ComunicadoHome? = null

    // Agenda da semana (GET /api/utilizadores/{userId}/agenda)
    private lateinit var tvDiasSemana: List<TextView>
    private lateinit var recyclerViewEventosHome: RecyclerView
    private lateinit var tvEventosVazio: TextView

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.funcionario_home, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        sessionManager = SessionManager(requireContext())
        tvPendingSync = view.findViewById(R.id.tvPendingSync)

        view.findViewById<Button>(R.id.btnLogoutHome).setOnClickListener {
            sessionManager.clearSession()
            startActivity(Intent(requireContext(), LoginActivity::class.java))
            activity?.finish()
        }

        // Saudação
        view.findViewById<TextView>(R.id.tvGreeting).text =
            "Olá, ${sessionManager.getUserName() ?: "Funcionário"}!"

        // Configurar cliques nos cards de método
        cardManual = view.findViewById(R.id.cardManual)
        cardQrCode = view.findViewById(R.id.cardQrCode)
        cardFacial = view.findViewById(R.id.cardFacial)
        cardSelfieGps = view.findViewById(R.id.cardSelfieGps)
        cardPin = view.findViewById(R.id.cardPin)
        cardNfc = view.findViewById(R.id.cardNfc)
        cardFingerprint = view.findViewById(R.id.cardFingerprint)

        // Método manual na Home abre o registo de gestor (marcar em nome de
        // outro funcionário) e só é visível para gestores com permissão.
        val podeMarcarManual = PermissionUtils.has(sessionManager, "recursos-humanos", "gerir_funcionarios")
        cardManual.visibility = if (podeMarcarManual) View.VISIBLE else View.GONE

        cardManual.setOnClickListener { openFragment(RegistoManualFragment()) }
        cardQrCode.setOnClickListener { openFragment(QrCodeAttendanceFragment()) }
        cardFacial.setOnClickListener { openFragment(FacialAttendanceFragment()) }
        cardSelfieGps.setOnClickListener { openFragment(SelfieGpsAttendanceFragment()) }
        cardPin.setOnClickListener { openFragment(PinAttendanceFragment()) }
        cardNfc.setOnClickListener { openFragment(NfcAttendanceFragment()) }
        cardFingerprint.setOnClickListener { openFragment(FingerprintAttendanceFragment()) }

        // Resumo pessoal
        tvSaldoFeriasDias = view.findViewById(R.id.tvSaldoFeriasDias)
        tvSaldoFeriasTotal = view.findViewById(R.id.tvSaldoFeriasTotal)
        tvDiasTrabalhados = view.findViewById(R.id.tvDiasTrabalhados)
        tvHorasTrabalhadas = view.findViewById(R.id.tvHorasTrabalhadas)
        tvAtrasos = view.findViewById(R.id.tvAtrasos)
        tvFaltas = view.findViewById(R.id.tvFaltas)
        cardPedidosPendentes = view.findViewById(R.id.cardPedidosPendentes)
        tvPedidosPendentesCount = view.findViewById(R.id.tvPedidosPendentesCount)
        itemNotificacaoRecente = view.findViewById(R.id.itemNotificacaoRecente)
        tvNotificacaoTitulo = view.findViewById(R.id.tvNotificacaoTitulo)
        tvNotificacaoCorpo = view.findViewById(R.id.tvNotificacaoCorpo)
        tvNotificacaoData = view.findViewById(R.id.tvNotificacaoData)
        itemComunicadoRecente = view.findViewById(R.id.itemComunicadoRecente)
        tvComunicadoTitulo = view.findViewById(R.id.tvComunicadoTitulo)
        tvComunicadoNovo = view.findViewById(R.id.tvComunicadoNovo)
        tvComunicadoData = view.findViewById(R.id.tvComunicadoData)
        tvAniversarioNome = view.findViewById(R.id.tvAniversarioNome)
        tvAniversarioSub = view.findViewById(R.id.tvAniversarioSub)

        itemNotificacaoRecente.setOnClickListener { marcarNotificacaoLidaClicada() }
        itemComunicadoRecente.setOnClickListener { marcarComunicadoLidoClicado() }

        // Agenda da semana
        tvDiasSemana = listOf(
            R.id.tvDiaSemana1, R.id.tvDiaSemana2, R.id.tvDiaSemana3, R.id.tvDiaSemana4,
            R.id.tvDiaSemana5, R.id.tvDiaSemana6, R.id.tvDiaSemana7
        ).map { view.findViewById(it) }

        recyclerViewEventosHome = view.findViewById(R.id.recyclerViewEventosHome)
        recyclerViewEventosHome.layoutManager = LinearLayoutManager(context, LinearLayoutManager.HORIZONTAL, false)
        tvEventosVazio = view.findViewById(R.id.tvEventosVazio)

        view.findViewById<TextView>(R.id.tvVerTodosEventos).setOnClickListener {
            openFragment(AgendaFragment())
        }

        loadPendingEventsCount()
    }

    override fun onResume() {
        super.onResume()
        loadPendingEventsCount()
        aplicarMetodosActivos()
        loadHomeData()
        loadAgendaSemana()
    }

    /**
     * Esconde os cards de métodos que o gestor desactivou em
     * "Configuração de Assiduidade" (rh.assiduidade, GET
     * /api/self-service/assiduidade/metodos) — antes disto, os 7 métodos
     * apareciam sempre, independentemente da configuração do tenant.
     *
     * Falha aberta: se o pedido falhar (rede/sessão), os cards ficam como
     * estão (visíveis por omissão no XML) em vez de esconder tudo — mesmo
     * comportamento de fail-open já usado no resto da integração
     * FaceClock/ERP (validar_metodo_assiduidade, metodoFacialAtivo).
     */
    private fun aplicarMetodosActivos() {
        val token = sessionManager.getToken() ?: return
        lifecycleScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getMetodosAssiduidade(ApiUtils.bearerToken(token))
                }
                if (!isAdded) return@launch
                val body = response.body()
                if (!response.isSuccessful || body == null) return@launch

                val metodos = body.configuracao?.metodos.orEmpty()
                fun ativo(chave: String) = metodos[chave]?.ativo ?: true
                val podeMarcarManual = PermissionUtils.has(sessionManager, "recursos-humanos", "gerir_funcionarios")

                cardManual.visibility = if (ativo("manual") && podeMarcarManual) View.VISIBLE else View.GONE
                cardQrCode.visibility = if (ativo("qr_code")) View.VISIBLE else View.GONE
                cardFacial.visibility = if (ativo("facial")) View.VISIBLE else View.GONE
                cardSelfieGps.visibility = if (ativo("selfie")) View.VISIBLE else View.GONE
                cardPin.visibility = if (ativo("pin")) View.VISIBLE else View.GONE
                cardNfc.visibility = if (ativo("nfc")) View.VISIBLE else View.GONE
                cardFingerprint.visibility = if (ativo("fingerprint")) View.VISIBLE else View.GONE
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                // Falha de rede: mantém os cards como estavam (fail-open).
            }
        }
    }

    /**
     * Carrega o agregado do ecrã inicial (saldo de férias, assiduidade do
     * mês, pedidos pendentes, notificações/comunicados por ler e
     * aniversariantes da semana) — GET /api/self-service/home.
     */
    private fun loadHomeData() {
        val token = sessionManager.getToken() ?: return
        lifecycleScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getHome(ApiUtils.bearerToken(token))
                }
                if (!isAdded) return@launch
                val body = response.body()
                if (!response.isSuccessful || body == null) return@launch

                tvSaldoFeriasDias.text = formatDias(body.saldo_ferias.dias_disponiveis)
                tvSaldoFeriasTotal.text = "de ${formatDias(body.saldo_ferias.dias_atribuidos)} dias atribuídos"

                tvDiasTrabalhados.text = "${body.assiduidade_mes.dias_trabalhados} dias trabalhados"
                tvHorasTrabalhadas.text = "${formatDias(body.assiduidade_mes.horas_totais)} horas"

                tvAtrasos.text = "${body.assiduidade_mes.atrasos} atraso(s)"
                tvAtrasos.visibility = if (body.assiduidade_mes.atrasos > 0) View.VISIBLE else View.GONE

                tvFaltas.text = "${body.assiduidade_mes.faltas} falta(s)"
                tvFaltas.visibility = if (body.assiduidade_mes.faltas > 0) View.VISIBLE else View.GONE

                cardPedidosPendentes.visibility = if (body.pedidos_pendentes > 0) View.VISIBLE else View.GONE
                tvPedidosPendentesCount.text = "${body.pedidos_pendentes}"

                val notificacao = body.notificacoes.firstOrNull()
                notificacaoActual = notificacao
                if (notificacao == null) {
                    tvNotificacaoTitulo.text = "Sem notificações novas"
                    tvNotificacaoCorpo.visibility = View.GONE
                    tvNotificacaoData.visibility = View.GONE
                } else {
                    tvNotificacaoTitulo.text = notificacao.titulo
                    tvNotificacaoCorpo.visibility = View.VISIBLE
                    tvNotificacaoCorpo.text = notificacao.corpo ?: ""
                    tvNotificacaoData.visibility = View.VISIBLE
                    tvNotificacaoData.text = formatShortDate(notificacao.created_at)
                }

                val comunicado = body.comunicados.firstOrNull()
                comunicadoActual = comunicado
                if (comunicado == null) {
                    tvComunicadoTitulo.text = "Sem comunicados recentes"
                    tvComunicadoNovo.visibility = View.GONE
                    tvComunicadoData.visibility = View.GONE
                } else {
                    tvComunicadoTitulo.text = comunicado.titulo
                    tvComunicadoNovo.visibility = if (comunicado.lido) View.GONE else View.VISIBLE
                    tvComunicadoData.visibility = View.VISIBLE
                    tvComunicadoData.text = formatShortDate(comunicado.created_at)
                }

                val aniversario = body.aniversarios.firstOrNull()
                if (aniversario == null) {
                    tvAniversarioNome.text = "Sem aniversários esta semana"
                    tvAniversarioSub.visibility = View.GONE
                } else {
                    val dia = aniversario.dia.toString().padStart(2, '0')
                    val mes = aniversario.mes.toString().padStart(2, '0')
                    tvAniversarioNome.text = "${aniversario.nome} ($dia/$mes)"
                    tvAniversarioSub.visibility = View.VISIBLE
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                // Falha de rede: mantém o resumo pessoal como estava (última carga bem-sucedida).
            }
        }
    }

    private fun marcarNotificacaoLidaClicada() {
        val notificacao = notificacaoActual ?: return
        val token = sessionManager.getToken() ?: return
        lifecycleScope.launch {
            try {
                withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.marcarNotificacaoLida(
                        ApiUtils.bearerToken(token),
                        MarcarLidaRequest(notificacao.id)
                    )
                }
                if (!isAdded) return@launch
                loadHomeData()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                // Sem feedback bloqueante — o utilizador pode tentar novamente.
            }
        }
    }

    private fun marcarComunicadoLidoClicado() {
        val comunicado = comunicadoActual ?: return
        val token = sessionManager.getToken() ?: return
        lifecycleScope.launch {
            try {
                withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.marcarComunicadoLido(
                        ApiUtils.bearerToken(token),
                        MarcarLidaRequest(comunicado.id)
                    )
                }
                if (!isAdded) return@launch
                loadHomeData()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                // Sem feedback bloqueante — o utilizador pode tentar novamente.
            }
        }
    }

    /**
     * Carrega a semana corrente (segunda a domingo) e os eventos dessa
     * janela — GET /api/utilizadores/{userId}/agenda?desde=&ate=, mesmo
     * endpoint já usado pelo ecrã "Ver todos" (AgendaFragment). A faixa de
     * eventos é um RecyclerView horizontal (não fica limitada a 2 itens
     * fixos) — cada cartão é clicável e abre o detalhe real do evento.
     */
    private fun loadAgendaSemana() {
        val token = sessionManager.getToken() ?: return
        val userId = sessionManager.getUserId() ?: return

        val segunda = DateTimeUtils.startOfWeek()
        val hoje = Calendar.getInstance()
        val diasSemana = (0..6).map { offset ->
            (segunda.clone() as Calendar).apply { add(Calendar.DAY_OF_MONTH, offset) }
        }
        diasSemana.forEachIndexed { index, dia ->
            val tv = tvDiasSemana[index]
            tv.text = dia.get(Calendar.DAY_OF_MONTH).toString()
            val ehHoje = dia.get(Calendar.YEAR) == hoje.get(Calendar.YEAR) &&
                dia.get(Calendar.DAY_OF_YEAR) == hoje.get(Calendar.DAY_OF_YEAR)
            if (ehHoje) {
                tv.setBackgroundResource(R.drawable.day_selected_bg)
                tv.setTextColor(resources.getColor(R.color.white, null))
                tv.setTypeface(null, android.graphics.Typeface.BOLD)
            } else {
                tv.background = null
                tv.setTextColor(resources.getColor(R.color.text_primary, null))
                tv.setTypeface(null, android.graphics.Typeface.NORMAL)
            }
        }

        val desde = DateTimeUtils.formatApiDate(segunda)
        val ate = DateTimeUtils.formatApiDate(diasSemana.last())

        lifecycleScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getAgenda(
                        ApiUtils.bearerToken(token),
                        userId,
                        desde,
                        ate
                    )
                }
                if (!isAdded) return@launch
                val itens = if (response.isSuccessful) response.body().orEmpty() else emptyList()
                exibirEventos(itens)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                exibirEventos(emptyList())
            }
        }
    }

    private fun exibirEventos(itens: List<AgendaItem>) {
        if (itens.isEmpty()) {
            recyclerViewEventosHome.visibility = View.GONE
            tvEventosVazio.visibility = View.VISIBLE
        } else {
            tvEventosVazio.visibility = View.GONE
            recyclerViewEventosHome.visibility = View.VISIBLE
            recyclerViewEventosHome.adapter = EventosHomeAdapter(itens) { item -> abrirDetalheEvento(item) }
        }
    }

    private fun abrirDetalheEvento(item: AgendaItem) {
        val horario = if (item.hora_fim.isNullOrBlank()) {
            item.hora_inicio
        } else {
            "${item.hora_inicio} - ${item.hora_fim}"
        }
        openFragment(
            AgendaItemDetailFragment.newInstance(
                title = item.titulo,
                description = item.descricao ?: "Sem descrição",
                duration = horario
            )
        )
    }

    /** Formata um double sem casas decimais desnecessárias (14.0 -> "14", 14.5 -> "14.5"). */
    private fun formatDias(valor: Double): String {
        return if (valor == valor.toLong().toDouble()) {
            valor.toLong().toString()
        } else {
            String.format(Locale.getDefault(), "%.1f", valor)
        }
    }

    private val shortDateFormatter = SimpleDateFormat("dd MMM", Locale("pt", "PT"))
    private val isoParser = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault())

    /** Formata um timestamp ISO do ERP ("2026-07-28T10:26:05.65...Z") como "28 Jul". */
    private fun formatShortDate(iso: String): String {
        return try {
            val semFraccao = if (iso.length >= 19) iso.substring(0, 19) else iso
            isoParser.parse(semFraccao)?.let { shortDateFormatter.format(it) } ?: iso
        } catch (e: Exception) {
            iso
        }
    }

    private fun openFragment(fragment: Fragment) {
        parentFragmentManager.beginTransaction()
            .replace(R.id.fragment_container, fragment)
            .addToBackStack(null)
            .commit()
    }

    /**
     * Carrega a quantidade de eventos pendentes de sincronizacao e atualiza o indicador.
     */
    private fun loadPendingEventsCount() {
        lifecycleScope.launch {
            val count = withContext(Dispatchers.IO) {
                AppDatabase.getInstance(requireContext())
                    .pendingEventDao()
                    .countByStatus(PendingEventEntity.SyncStatus.PENDING)
            }

            if (count > 0) {
                tvPendingSync.visibility = View.VISIBLE
                tvPendingSync.text = if (count == 1) {
                    "1 registo pendente de sincronizacao"
                } else {
                    "$count registos pendentes de sincronizacao"
                }
            } else {
                tvPendingSync.visibility = View.GONE
            }
        }
    }
}
