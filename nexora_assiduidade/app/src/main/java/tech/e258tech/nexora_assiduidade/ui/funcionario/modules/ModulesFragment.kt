package tech.e258tech.nexora_assiduidade.ui.funcionario.modules

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.DividerItemDecoration
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.ui.funcionario.attendance.JustifyAbsenceFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.notifications.NotificationsFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.dashboard.DashboardGestorFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.dispositivos.DispositivosFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.equipa.EquipaGestorFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.ferias.PedidosFeriasFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.ocorrencias.AlertasFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.ocorrencias.OcorrenciasFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.registo.RegistoManualFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.relatorios.RelatoriosGestorFragment
import tech.e258tech.nexora_assiduidade.utils.PermissionUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Módulos disponíveis para o utilizador — filtrados pelas permissões reais
 * do login (`modulos`/`acoes`), tal como o dashboard do ERP web faz
 * (ver frontend/src/View/templates/pages/dashboard.php, `canModule()`, e o
 * mapa de módulos/acções em frontend/src/View/templates/partials/modules.php).
 *
 * Inclui também os ecrãs de Gestor (Dashboard, Equipa, Relatórios,
 * Dispositivos, Ocorrências/Alertas, Registo Manual, Aprovar Férias) — desde
 * que deixou de haver uma barra de navegação própria para Gestor (todos os
 * logins usam a barra de Colaborador), este é o único sítio onde alguém com
 * essas permissões consegue lá chegar.
 */
class ModulesFragment : Fragment() {

    private lateinit var sessionManager: SessionManager

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.funcionario_modules, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        sessionManager = SessionManager(requireContext())

        val recyclerView = view.findViewById<RecyclerView>(R.id.recyclerViewModules)
        val tvEmpty = view.findViewById<View>(R.id.tvModulesEmpty)
        recyclerView.layoutManager = LinearLayoutManager(context)
        recyclerView.addItemDecoration(DividerItemDecoration(context, DividerItemDecoration.VERTICAL))

        val items = buildAvailableItems()
        if (items.isEmpty()) {
            recyclerView.visibility = View.GONE
            tvEmpty.visibility = View.VISIBLE
        } else {
            recyclerView.visibility = View.VISIBLE
            tvEmpty.visibility = View.GONE
            recyclerView.adapter = ModuleMenuAdapter(items)
        }
    }

    private fun temPermissao(modulo: String, acao: String): Boolean =
        PermissionUtils.has(sessionManager, modulo, acao)

    private fun buildAvailableItems(): List<ModuleMenuItem> {
        val items = mutableListOf<ModuleMenuItem>()

        // "perfil:ver_perfil" é a mesma permissão que o backend exige em
        // GET /api/utilizadores/{userId}/notifications (ver notificacoes.go).
        if (temPermissao("perfil", "ver_perfil")) {
            items += ModuleMenuItem(
                "Notificações",
                android.R.drawable.ic_popup_reminder
            ) { openFragment(NotificationsFragment()) }
        }

        // "assiduidade:justificar" — acção do módulo em modules.php.
        if (temPermissao("assiduidade", "justificar")) {
            items += ModuleMenuItem(
                "Justificar Falta",
                R.drawable.ic_method_manual
            ) { openFragment(JustifyAbsenceFragment()) }
        }

        // Ecrãs de Gestor — "recursos-humanos:ver_funcionarios" (router.go:1675-1719)
        // é a mesma permissão que já gerija Dashboard/Equipa/Relatórios na antiga
        // barra de navegação de Gestor.
        if (temPermissao("recursos-humanos", "ver_funcionarios")) {
            items += ModuleMenuItem(
                "Dashboard de Gestor",
                android.R.drawable.ic_menu_recent_history
            ) { openFragment(DashboardGestorFragment()) }
            items += ModuleMenuItem(
                "Equipa",
                android.R.drawable.ic_menu_myplaces
            ) { openFragment(EquipaGestorFragment()) }
            items += ModuleMenuItem(
                "Relatórios",
                android.R.drawable.ic_menu_report_image
            ) { openFragment(RelatoriosGestorFragment()) }
            items += ModuleMenuItem(
                "Ocorrências",
                android.R.drawable.ic_menu_close_clear_cancel
            ) { openFragment(OcorrenciasFragment()) }
            items += ModuleMenuItem(
                "Alertas",
                android.R.drawable.ic_dialog_alert
            ) { openFragment(AlertasFragment()) }
        }

        // "recursos-humanos:aprovar_ausencias" — a mesma acção que antes
        // determinava se o utilizador era "Gestor" (RoleUtils.fromErpLogin).
        if (temPermissao("recursos-humanos", "aprovar_ausencias")) {
            items += ModuleMenuItem(
                "Aprovar Pedidos de Férias",
                R.drawable.ic_nav_vacation
            ) { openFragment(PedidosFeriasFragment()) }
        }

        // "recursos-humanos:gerir_funcionarios" — registar assiduidade em nome
        // de um funcionário é uma acção de edição, não só de consulta.
        if (temPermissao("recursos-humanos", "gerir_funcionarios")) {
            items += ModuleMenuItem(
                "Registo Manual de Assiduidade",
                android.R.drawable.ic_menu_add
            ) { openFragment(RegistoManualFragment()) }
        }

        // "hardware:ver_dispositivos" (router.go:2500).
        if (temPermissao("hardware", "ver_dispositivos")) {
            items += ModuleMenuItem(
                "Dispositivos",
                android.R.drawable.ic_menu_manage
            ) { openFragment(DispositivosFragment()) }
        }

        return items
    }

    private fun openFragment(fragment: Fragment) {
        parentFragmentManager.beginTransaction()
            .replace(R.id.fragment_container, fragment)
            .addToBackStack(null)
            .commit()
    }
}
