package tech.e258tech.nexora_assiduidade.ui.auth

import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.Button
import android.widget.EditText
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.fragment.app.Fragment
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import tech.e258tech.nexora_assiduidade.BuildConfig
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.ErpLoginRequest
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.ui.funcionario.attendance.NfcAttendanceFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.chat.ChatFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.history.HistoryFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.home.HomeFuncionarioFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.modules.ModulesFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.profile.ProfileFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.requests.RequestsFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.dashboard.DashboardGestorFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.equipa.EquipaGestorFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.ferias.PedidosFeriasFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.mais.MaisFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.relatorios.RelatoriosGestorFragment
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.PermissionUtils
import tech.e258tech.nexora_assiduidade.utils.RoleUtils
import tech.e258tech.nexora_assiduidade.work.SyncAttendanceWorker
import tech.e258tech.nexora_assiduidade.utils.Constants.DEMO_FUNCIONARIO_EMAIL
import tech.e258tech.nexora_assiduidade.utils.Constants.DEMO_FUNCIONARIO_PASSWORD
import tech.e258tech.nexora_assiduidade.utils.Constants.DEMO_GESTOR_EMAIL
import tech.e258tech.nexora_assiduidade.utils.Constants.DEMO_GESTOR_PASSWORD

import tech.e258tech.nexora_assiduidade.utils.SessionManager

private const val TAG = "LoginActivity"

enum class BottomTab { HOME, MODULES, CHAT, VACATION, ATTENDANCE, PROFILE }

enum class GestorTab { DASHBOARD, EQUIPA, FERIAS, RELATORIOS, MAIS }

/**
 * Login + conteúdo pós-login na mesma Activity (sem MainActivity separado,
 * removido a pedido explícito): depois de autenticar, troca o próprio
 * setContentView de auth_activity_login para common_activity_main e monta a
 * navegação (Colaborador ou Gestor) aqui mesmo, em vez de arrancar outra
 * Activity.
 */
class LoginActivity : AppCompatActivity() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private lateinit var sessionManager: SessionManager

    // ── Formulário de login ───────────────────────────────────────────────
    private lateinit var etEmail: EditText
    private lateinit var etPassword: EditText
    private lateinit var btnLogin: Button
    private lateinit var btnDemoFuncionario: View
    private lateinit var btnDemoGestor: View
    private lateinit var progressBar: ProgressBar

    // ── Navegação pós-login (antigo MainActivity) ─────────────────────────
    private var activeTab: BottomTab? = null
    private var activeGestorTab: GestorTab? = null
    private lateinit var navItems: List<NavItem>
    private lateinit var gestorNavItems: List<GestorNavItem>
    private lateinit var bottomNav: View
    private lateinit var gestorBottomNav: View

    /** Barra visível quando estamos numa tab raiz (Home/Histórico/Chat/Pedidos/Perfil
     *  ou o equivalente de Gestor) — escondida em ecrãs secundários empilhados
     *  no back stack (ex.: Agenda, Criar Reunião, check-in, detalhe de item). */
    private lateinit var activeNavContainer: View

    private data class NavItem(
        val container: LinearLayout,
        val icon: ImageView,
        val label: TextView,
        val tab: BottomTab,
        val fragment: () -> Fragment,
    )

    private data class GestorNavItem(
        val container: LinearLayout,
        val icon: ImageView,
        val label: TextView,
        val tab: GestorTab,
        val fragment: () -> Fragment,
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        sessionManager = SessionManager(this)
        sessionManager.getOrCreateDeviceId()

        if (sessionManager.isLoggedIn()) {
            showMainContent(savedInstanceState)
        } else {
            showLoginForm()
        }
    }

    override fun onDestroy() {
        uiScope.cancel()
        super.onDestroy()
    }

    // ── Ecrã de login ──────────────────────────────────────────────────────

    private fun showLoginForm() {
        setContentView(R.layout.auth_activity_login)
        initViews()
        setupListeners()
    }

    private fun initViews() {
        etEmail = findViewById(R.id.etEmail)
        etPassword = findViewById(R.id.etPassword)
        btnLogin = findViewById(R.id.btnLogin)
        btnDemoFuncionario = findViewById(R.id.btnDemoFuncionario)
        btnDemoGestor = findViewById(R.id.btnDemoGestor)
        progressBar = findViewById(R.id.progressBar)
    }

    private fun setupListeners() {
        btnLogin.setOnClickListener {
            val username = etEmail.text.toString().trim()
            val password = etPassword.text.toString().trim()

            if (username.isEmpty() || password.isEmpty()) {
                Toast.makeText(this, "Preencha todos os campos", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            performLogin(username, password)
        }

        // Botões de atalho com credenciais fixas — só em builds de debug,
        // nunca em release (ver plano "alinhar login ao backend").
        if (!BuildConfig.DEBUG) {
            btnDemoFuncionario.visibility = View.GONE
            btnDemoGestor.visibility = View.GONE
            return
        }

        btnDemoFuncionario.setOnClickListener {
            etEmail.setText(DEMO_FUNCIONARIO_EMAIL)
            etPassword.setText(DEMO_FUNCIONARIO_PASSWORD)
        }

        btnDemoGestor.setOnClickListener {
            etEmail.setText(DEMO_GESTOR_EMAIL)
            etPassword.setText(DEMO_GESTOR_PASSWORD)
        }
    }

    private fun performLogin(email: String, password: String) {
        setLoading(true)
        Log.d(TAG, "performLogin: a iniciar POST /api/auth/login")

        uiScope.launch {
            try {
                // Fase 6: login passa a ser feito directamente no Nexora ERP
                // (nao no FaceClock) — ver ErpLoginRequest/ErpLoginResponse.
                // Limite de 20s: o OkHttpClient já tem timeouts de 30s por fase
                // (connect/read/write, ver RetrofitClient.baseOkHttpClient), mas
                // um limite aqui garante que nunca fica preso indefinidamente
                // nem que o utilizador espera mais de 20s sem feedback de erro.
                val response = withTimeoutOrNull(20000L) {
                    withContext(Dispatchers.IO) {
                        RetrofitClient.erpApiService.login(
                            ErpLoginRequest(email = email, password = password)
                        )
                    }
                }
                if (response == null) {
                    Log.w(TAG, "performLogin: login excedeu o limite de 20s — a desistir")
                    Toast.makeText(
                        this@LoginActivity,
                        "O servidor demorou demasiado tempo a responder. Tenta novamente.",
                        Toast.LENGTH_LONG
                    ).show()
                    return@launch
                }
                Log.d(TAG, "performLogin: resposta do login recebida, status=${response.code()}")

                if (!response.isSuccessful || response.body() == null) {
                    Toast.makeText(
                        this@LoginActivity,
                        ApiUtils.errorMessage(response),
                        Toast.LENGTH_LONG
                    ).show()
                    return@launch
                }

                val payload = response.body() ?: return@launch

                // O `modulos` da resposta de login pode vir desactualizado/vazio
                // em produção (observado: /api/auth/login e /api/auth/me/acesso
                // usam a mesma LoadUserAccess mas devolvem resultados diferentes,
                // aponta para o binário do login estar atrasado) — confirma-se
                // sempre com /me/acesso, a fonte em tempo real. Limite de 5s:
                // esta chamada é só um enriquecimento, nunca deve bloquear o
                // login — se demorar ou falhar, segue com o modulos do login.
                Log.d(TAG, "performLogin: a consultar /api/auth/me/acesso")
                val modulos = withTimeoutOrNull(5000L) {
                    withContext(Dispatchers.IO) {
                        try {
                            val acessoResponse = RetrofitClient.erpApiService.getMeuAcesso(
                                ApiUtils.bearerToken(payload.access_token)
                            )
                            acessoResponse.body()?.modulos
                        } catch (e: Exception) {
                            Log.w(TAG, "performLogin: /me/acesso falhou, a usar modulos do login", e)
                            null
                        }
                    }
                } ?: payload.modulos
                Log.d(TAG, "performLogin: modulos resolvido (${modulos.size} modulo(s))")

                val role = RoleUtils.fromErpLogin(modulos)
                sessionManager.saveSession(
                    token = payload.access_token,
                    refreshToken = payload.refresh_token,
                    userId = payload.user.id.toString(),
                    userName = payload.user.nome,
                    userEmail = payload.user.email,
                    userRole = role,
                    employeeCode = payload.user.email,
                    modulos = modulos
                )
                Toast.makeText(
                    this@LoginActivity,
                    "Login realizado com sucesso.",
                    Toast.LENGTH_SHORT
                ).show()
                Log.d(TAG, "performLogin: a trocar para o conteudo principal (role=$role)")
                showMainContent(null)
            } catch (e: Exception) {
                Log.e(TAG, "performLogin: excepcao nao tratada", e)
                Toast.makeText(
                    this@LoginActivity,
                    "Nao foi possivel ligar ao ERP.",
                    Toast.LENGTH_LONG
                ).show()
            } finally {
                setLoading(false)
            }
        }
    }

    private fun setLoading(isLoading: Boolean) {
        progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
        btnLogin.isEnabled = !isLoading
        btnLogin.text = if (isLoading) "A autenticar..." else "Entrar"
    }

    // ── Conteúdo pós-login (antigo MainActivity) ──────────────────────────

    private fun showMainContent(savedInstanceState: Bundle?) {
        setContentView(R.layout.common_activity_main)
        SyncAttendanceWorker.schedulePeriodic(this)

        // Independentemente do papel (Gestor/Colaborador), todos usam a
        // barra e o ecrã inicial de Colaborador (HomeFuncionarioFragment) —
        // a barra/ecrãs de Gestor deixaram de ser o destino automático pós-
        // login, por pedido explícito. O código de Gestor mantém-se (ainda
        // acessível por quem entrar directamente nesses fragments).
        bottomNav = findViewById(R.id.bottomNavContainer)
        gestorBottomNav = findViewById(R.id.gestorBottomNavContainer)
        val fragmentContainer = findViewById<View>(R.id.fragment_container)

        gestorBottomNav.visibility = View.GONE
        activeNavContainer = bottomNav
        applyEdgeInsets(fragmentContainer, top = true, bottom = false)
        applyEdgeInsets(bottomNav, top = false, bottom = true)
        setupBottomNav()

        // Ecrãs secundários (push com addToBackStack) escondem a barra —
        // só as 5 tabs raiz (Home/Histórico/Chat/Pedidos/Perfil, ou o
        // equivalente de Gestor) a mostram, ver docs/design_prompts.md
        // ("Persistent chrome"). selectTab/selectGestorTab limpam o back
        // stack antes de trocar de tab, por isso count == 0 identifica
        // sempre uma tab raiz, independentemente de o ecrã secundário ter
        // sido empilhado via pushFragment ou directamente por um fragment.
        supportFragmentManager.addOnBackStackChangedListener {
            activeNavContainer.visibility =
                if (supportFragmentManager.backStackEntryCount == 0) View.VISIBLE else View.GONE
        }

        if (savedInstanceState == null) {
            selectTab(BottomTab.HOME)
        }
    }

    /** Empurra a view para dentro da área segura (status bar e/ou gesture/nav bar do sistema, modo edge-to-edge). */
    private fun applyEdgeInsets(view: View, top: Boolean, bottom: Boolean) {
        val basePaddingTop = view.paddingTop
        val basePaddingBottom = view.paddingBottom
        ViewCompat.setOnApplyWindowInsetsListener(view) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(
                v.paddingLeft,
                if (top) basePaddingTop + systemBars.top else v.paddingTop,
                v.paddingRight,
                if (bottom) basePaddingBottom + systemBars.bottom else v.paddingBottom,
            )
            insets
        }
        ViewCompat.requestApplyInsets(view)
    }

    private fun setupBottomNav() {
        val items = listOf(
            NavItem(
                findViewById(R.id.navHome), findViewById(R.id.navHomeIcon), findViewById(R.id.navHomeLabel),
                BottomTab.HOME, { HomeFuncionarioFragment() }
            ),
            NavItem(
                findViewById(R.id.navModules), findViewById(R.id.navModulesIcon), findViewById(R.id.navModulesLabel),
                BottomTab.MODULES, { ModulesFragment() }
            ),
            NavItem(
                findViewById(R.id.navChat), findViewById(R.id.navChatIcon), findViewById(R.id.navChatLabel),
                BottomTab.CHAT, { ChatFragment() }
            ),
            NavItem(
                findViewById(R.id.navVacation), findViewById(R.id.navVacationIcon), findViewById(R.id.navVacationLabel),
                BottomTab.VACATION, { RequestsFragment() }
            ),
            NavItem(
                findViewById(R.id.navAttendance), findViewById(R.id.navAttendanceIcon), findViewById(R.id.navAttendanceLabel),
                BottomTab.ATTENDANCE, { HistoryFragment() }
            ),
            NavItem(
                findViewById(R.id.navProfile), findViewById(R.id.navProfileIcon), findViewById(R.id.navProfileLabel),
                BottomTab.PROFILE, { ProfileFragment() }
            ),
        )

        items.forEach { item ->
            item.container.setOnClickListener {
                selectTab(item.tab)
            }
        }

        this.navItems = items
    }

    private fun selectTab(tab: BottomTab) {
        if (activeTab == tab) return
        activeTab = tab

        navItems.forEach { item ->
            val color = getColor(if (item.tab == tab) R.color.brand_accent else R.color.text_muted)
            item.icon.setColorFilter(color)
            item.label.setTextColor(color)
        }

        activeNavContainer = bottomNav
        gestorBottomNav.visibility = View.GONE
        bottomNav.visibility = View.VISIBLE

        val target = navItems.first { it.tab == tab }
        supportFragmentManager.popBackStack(null, androidx.fragment.app.FragmentManager.POP_BACK_STACK_INCLUSIVE)
        loadFragment(target.fragment())
    }

    private fun setupGestorBottomNav() {
        val items = listOf(
            GestorNavItem(
                findViewById(R.id.navGestorDashboard), findViewById(R.id.navGestorDashboardIcon), findViewById(R.id.navGestorDashboardLabel),
                GestorTab.DASHBOARD, { DashboardGestorFragment() }
            ),
            GestorNavItem(
                findViewById(R.id.navGestorEquipa), findViewById(R.id.navGestorEquipaIcon), findViewById(R.id.navGestorEquipaLabel),
                GestorTab.EQUIPA, { EquipaGestorFragment() }
            ),
            GestorNavItem(
                findViewById(R.id.navGestorFerias), findViewById(R.id.navGestorFeriasIcon), findViewById(R.id.navGestorFeriasLabel),
                GestorTab.FERIAS, { PedidosFeriasFragment() }
            ),
            GestorNavItem(
                findViewById(R.id.navGestorRelatorios), findViewById(R.id.navGestorRelatoriosIcon), findViewById(R.id.navGestorRelatoriosLabel),
                GestorTab.RELATORIOS, { RelatoriosGestorFragment() }
            ),
            GestorNavItem(
                findViewById(R.id.navGestorMais), findViewById(R.id.navGestorMaisIcon), findViewById(R.id.navGestorMaisLabel),
                GestorTab.MAIS, { MaisFragment() }
            ),
        )

        // Dashboard/Equipa/Relatorios exigem recursos-humanos.ver_funcionarios
        // no backend (router.go:1675-1719) — distinto de aprovar_ausencias,
        // que já define o modo gestor (RoleUtils.fromErpLogin). Sem essa
        // permissão, escondemos a tab em vez de deixar aparecer 403 dentro
        // dela. Ferias/Mais mantêm-se sempre (Ferias é a própria razão de
        // estar em modo gestor; Mais tem o seu próprio filtro por cartão).
        val temVerFuncionarios = PermissionUtils.has(sessionManager, "recursos-humanos", "ver_funcionarios")
        val tabsQueExigemVerFuncionarios = setOf(GestorTab.DASHBOARD, GestorTab.EQUIPA, GestorTab.RELATORIOS)
        items.forEach { item ->
            if (item.tab in tabsQueExigemVerFuncionarios && !temVerFuncionarios) {
                item.container.visibility = View.GONE
            }
        }

        items.forEach { item ->
            item.container.setOnClickListener {
                selectGestorTab(item.tab)
            }
        }

        this.gestorNavItems = items
    }

    /** Primeira tab de gestor visível — usada como destino inicial quando Dashboard está escondida por falta de permissão. */
    private fun firstVisibleGestorTab(): GestorTab =
        gestorNavItems.firstOrNull { it.container.visibility == View.VISIBLE }?.tab ?: GestorTab.MAIS

    private fun selectGestorTab(tab: GestorTab) {
        if (activeGestorTab == tab) return
        activeGestorTab = tab

        gestorNavItems.forEach { item ->
            val color = getColor(if (item.tab == tab) R.color.brand_accent else R.color.text_muted)
            item.icon.setColorFilter(color)
            item.label.setTextColor(color)
        }

        activeNavContainer = gestorBottomNav
        bottomNav.visibility = View.GONE
        gestorBottomNav.visibility = View.VISIBLE

        val target = gestorNavItems.first { it.tab == tab }
        supportFragmentManager.popBackStack(null, androidx.fragment.app.FragmentManager.POP_BACK_STACK_INCLUSIVE)
        loadFragment(target.fragment())
    }

    private fun loadFragment(fragment: Fragment) {
        supportFragmentManager.beginTransaction()
            .replace(R.id.fragment_container, fragment)
            .commit()
    }

    /** Empurra um ecrã secundário (ex.: detalhe de funcionário, a partir da
     * Equipa) para cima da tab actual, mantendo-a no back stack — ao
     * contrário de [loadFragment], usado só para trocar de tab. */
    fun pushFragment(fragment: Fragment) {
        supportFragmentManager.beginTransaction()
            .replace(R.id.fragment_container, fragment)
            .addToBackStack(null)
            .commit()
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        intent ?: return
        val current = supportFragmentManager.findFragmentById(R.id.fragment_container)
        if (current is NfcAttendanceFragment) {
            current.onNewIntent(intent)
        }
    }
}
