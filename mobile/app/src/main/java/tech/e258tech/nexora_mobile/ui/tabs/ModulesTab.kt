package tech.e258tech.nexora_mobile.ui.tabs

import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.ViewGroup
import android.widget.GridLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.Toast
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch
import tech.e258tech.nexora_mobile.R
import tech.e258tech.nexora_mobile.app
import tech.e258tech.nexora_mobile.data.model.ModuloAcesso
import tech.e258tech.nexora_mobile.ui.screens.main.MainActivity

internal data class ModuleItem(
    val name: String,
    val description: String,
    val status: String,
    val iconRes: Int,
    val iconTint: Int,
)

internal class ModulesTab(private val activity: MainActivity) {


    fun show() {
        activity.lifecycleScope.launch {
            val modules = loadPermittedModules()
            renderModules(modules)
        }
    }

    private suspend fun loadPermittedModules(): List<ModuleItem> {
        // Busca SEMPRE da API — garante que permissões revogadas são reflectidas imediatamente
        val modulos = activity.app.authRepository.getModulosActuais()
        return modulos.map { it.toModuleItem() }
    }

    private fun renderModules(modules: List<ModuleItem>) {
        val main = activity.binding.mainContent
        main.removeAllViews()
        main.setPadding(0, 0, 0, activity.dp(78) + activity.currentBottomInset)
        main.addView(activity.buildPageTitle("Modulos", "Modulos permitidos pela API."))

        if (modules.isEmpty()) {
            main.addView(activity.textView("Sem modulos permitidos.", 14f, R.color.text_secondary).apply {
                gravity = Gravity.CENTER
                setPadding(activity.dp(20), activity.dp(40), activity.dp(20), activity.dp(40))
                layoutParams = LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                )
            })
            return
        }

        val grid = GridLayout(activity).apply {
            columnCount = 2
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply {
                setMargins(activity.dp(12), activity.dp(8), activity.dp(12), activity.dp(12))
            }
        }

        modules.forEach { module ->
            grid.addView(buildModuleCard(module).apply {
                layoutParams = GridLayout.LayoutParams(
                    GridLayout.spec(GridLayout.UNDEFINED, 1f),
                    GridLayout.spec(GridLayout.UNDEFINED, 1f),
                ).apply {
                    width = 0
                    height = ViewGroup.LayoutParams.WRAP_CONTENT
                    setMargins(activity.dp(4), activity.dp(4), activity.dp(4), activity.dp(8))
                }
            })
        }

        main.addView(grid)
    }

    private fun ModuloAcesso.toModuleItem(): ModuleItem {
        val key = modulo.lowercase()
        return ModuleItem(
            name = moduleName(key),
            description = moduleDescription(key),
            status = "${acoes.size} acoes",
            iconRes = moduleIcon(key),
            iconTint = moduleColor(key),
        )
    }

    private fun moduleName(key: String): String = when (key) {
        "faturacao" -> "Faturacao"
        "gestao-stock", "stock" -> "Stock"
        "recursos-humanos", "rh" -> "RH"
        "gestao-escolar", "escolar" -> "Escolar"
        "sistema-configuracao" -> "Configuracao"
        "notificacoes" -> "Notificacoes"
        else -> key.split("-", "_").joinToString(" ") { part ->
            part.replaceFirstChar { it.uppercaseChar() }
        }
    }

    private fun moduleDescription(key: String): String = when (key) {
        "faturacao" -> "Facturas, recibos e pagamentos"
        "clientes" -> "Cadastro e historico de clientes"
        "gestao-stock", "stock" -> "Produtos, movimentos e alertas"
        "compras" -> "Fornecedores, pedidos e recepcoes"
        "financeiro" -> "Pagamentos, contas e tesouraria"
        "recursos-humanos", "rh" -> "Funcionarios, ferias e assiduidade"
        "gestao-escolar", "escolar" -> "Alunos, turmas e propinas"
        "crm" -> "Leads, oportunidades e actividades"
        "relatorios" -> "Indicadores e analises"
        "notificacoes" -> "Avisos e comunicacoes"
        "sistema-configuracao" -> "Parametros do sistema"
        else -> "Permissoes configuradas na API"
    }

    private fun moduleIcon(key: String): Int = when (key) {
        "clientes" -> android.R.drawable.ic_menu_myplaces
        "gestao-stock", "stock" -> android.R.drawable.ic_menu_agenda
        "compras" -> android.R.drawable.ic_input_add
        "financeiro" -> android.R.drawable.ic_menu_compass
        "recursos-humanos", "rh", "sistema-configuracao" -> android.R.drawable.ic_menu_manage
        "gestao-escolar", "escolar" -> android.R.drawable.ic_menu_info_details
        "crm", "relatorios" -> android.R.drawable.ic_menu_sort_by_size
        "notificacoes" -> android.R.drawable.ic_dialog_email
        else -> android.R.drawable.ic_dialog_info
    }

    private fun moduleColor(key: String): Int = when (key) {
        "compras" -> 0xFFDC2626.toInt()
        "financeiro" -> 0xFF1D4ED8.toInt()
        "recursos-humanos", "rh" -> 0xFFD97706.toInt()
        "crm", "gestao-escolar", "escolar" -> 0xFF7C3AED.toInt()
        "relatorios" -> 0xFF3730A3.toInt()
        else -> 0xFF059669.toInt()
    }

    private fun buildModuleCard(module: ModuleItem): LinearLayout =
        LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(activity.dp(12), activity.dp(14), activity.dp(12), activity.dp(12))
            background = GradientDrawable().apply {
                setColor(activity.getColor(R.color.white))
                cornerRadius = activity.dp(8).toFloat()
                setStroke(activity.dp(1), activity.getColor(R.color.border_color))
            }
            minimumHeight = activity.dp(132)
            isClickable = true
            isFocusable = true
            setOnClickListener { Toast.makeText(activity, module.name, Toast.LENGTH_SHORT).show() }

            addView(ImageView(context).apply {
                setImageResource(module.iconRes)
                setColorFilter(module.iconTint)
                layoutParams = LinearLayout.LayoutParams(activity.dp(34), activity.dp(34))
                setPadding(activity.dp(4), activity.dp(4), activity.dp(4), activity.dp(4))
            })

            addView(activity.textView(module.name, 14f, R.color.text_primary, bold = true).apply {
                gravity = Gravity.CENTER
                setPadding(0, activity.dp(10), 0, 0)
                maxLines = 1
            })

            addView(activity.textView(module.description, 11f, R.color.text_secondary).apply {
                gravity = Gravity.CENTER
                setPadding(0, activity.dp(5), 0, 0)
                maxLines = 2
            })

            addView(activity.textView(module.status, 11f, R.color.primary_blue, bold = true).apply {
                gravity = Gravity.CENTER
                setPadding(0, activity.dp(8), 0, 0)
            })
        }
}
