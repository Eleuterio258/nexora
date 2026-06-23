package tech.e258tech.nexora_mobile

import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.text.TextUtils
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import androidx.coordinatorlayout.widget.CoordinatorLayout
import androidx.core.content.ContextCompat
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import com.google.android.material.appbar.AppBarLayout
import tech.e258tech.nexora_mobile.databinding.ActivityMainBinding
import tech.e258tech.nexora_mobile.databinding.ItemActivityRowBinding
import tech.e258tech.nexora_mobile.databinding.ItemQuickAccessBinding

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private lateinit var homeViews: List<View>

    private var currentBottomInset = 0
    private var activeChatContact: ChatContact? = null
    private var chatInputBar: LinearLayout? = null
    private var chatHeaderView: LinearLayout? = null

    // ── Chat data ─────────────────────────────────────────────────────────────

    private val chatContacts = listOf(
        ChatContact("EC", "Equipa Comercial", "Nova mensagem sobre a factura FT-2026-0038", "09:42", 3, 0xFF2563EB.toInt()),
        ChatContact("SU", "Suporte Técnico", "Pedido de ajuda no módulo de stock", "08:15", 1, 0xFF7C3AED.toInt()),
        ChatContact("AD", "Administração", "Reunião de fecho mensal marcada", "Ontem", 0, 0xFF059669.toInt()),
        ChatContact("FI", "Financeiro", "Confirmação de pagamento M-Pesa", "Ontem", 0, 0xFFD97706.toInt()),
        ChatContact("NE", "Nexora ERP", "Bem-vindo ao chat da plataforma!", "Seg", 0, 0xFF2563EB.toInt()),
    )

    private val chatMessages: Map<String, List<ChatMsg>> = mapOf(
        "Equipa Comercial" to listOf(
            ChatMsg("Olá, a factura FT-2026-0038 já foi enviada ao cliente?", false, "09:30"),
            ChatMsg("Sim, foi enviada por email às 09:15. Já confirmei com o cliente.", true, "09:32"),
            ChatMsg("O cliente pediu para reenviar com o NIF correcto.", false, "09:38"),
            ChatMsg("Qual é o NIF correcto?", true, "09:40"),
            ChatMsg("400 123 456 7E8", false, "09:41"),
            ChatMsg("Perfeito, obrigado! Reenvio em 2 minutos.", true, "09:42"),
        ),
        "Suporte Técnico" to listOf(
            ChatMsg("Bom dia! Estou com dificuldade no módulo de stock.", false, "08:10"),
            ChatMsg("Bom dia! Em que posso ajudar?", true, "08:12"),
            ChatMsg("Ao criar um movimento, aparece um erro 422.", false, "08:14"),
            ChatMsg("Vou verificar. Pode enviar uma captura de ecrã?", true, "08:15"),
        ),
        "Administração" to listOf(
            ChatMsg("A reunião de fecho mensal está marcada para amanhã às 10h.", false, "14:30"),
            ChatMsg("Confirmado, estarei presente.", true, "14:35"),
        ),
        "Financeiro" to listOf(
            ChatMsg("O pagamento M-Pesa de 8.900 MT foi confirmado pelo sistema.", false, "11:00"),
            ChatMsg("Excelente! Já actualizo o registo no ERP.", true, "11:05"),
        ),
        "Nexora ERP" to listOf(
            ChatMsg("Bem-vindo ao Nexora ERP! Estamos aqui para ajudar com qualquer questão.", false, "09:00"),
        ),
    )

    private data class ChatContact(
        val initials: String, val name: String, val lastMessage: String,
        val time: String, val unread: Int, val color: Int,
    )

    private data class ChatMsg(val text: String, val isMe: Boolean, val time: String)

    // ── Vacation data ─────────────────────────────────────────────────────────

    private enum class VacStatus { PENDING, APPROVED, REJECTED }

    private data class VacationRequest(
        val initials: String, val name: String, val dateRange: String,
        val days: Int, val status: VacStatus, val color: Int,
    )

    private val vacationRequests = listOf(
        VacationRequest("AM", "Ana Muacanhia",   "03 Jun – 07 Jun", 5,  VacStatus.PENDING,  0xFF7C3AED.toInt()),
        VacationRequest("CM", "Carlos Macuácua", "10 Jun – 14 Jun", 5,  VacStatus.APPROVED, 0xFF2563EB.toInt()),
        VacationRequest("FM", "Fátima Mondlane", "17 Jun – 21 Jun", 5,  VacStatus.APPROVED, 0xFF059669.toInt()),
        VacationRequest("JN", "João Nhantumbo",  "01 Jul – 15 Jul", 15, VacStatus.PENDING,  0xFFD97706.toInt()),
    )

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setupSystemBars()
        setupDashboard()
        homeViews = (0 until binding.mainContent.childCount).map { binding.mainContent.getChildAt(it) }
        setupNavigation()
        setupBackPress()
    }

    private fun setupBackPress() {
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                if (activeChatContact != null) {
                    activeChatContact = null
                    showChatPage()
                } else {
                    isEnabled = false
                    onBackPressedDispatcher.onBackPressed()
                    isEnabled = true
                }
            }
        })
    }

    // ── System bars ───────────────────────────────────────────────────────────

    private fun setupSystemBars() {
        window.statusBarColor = getColor(R.color.primary_blue)
        window.navigationBarColor = getColor(R.color.white)

        WindowInsetsControllerCompat(window, window.decorView).apply {
            isAppearanceLightStatusBars = false
            isAppearanceLightNavigationBars = true
        }

        val baseAppBarTopPadding = binding.appBarLayout.paddingTop
        val baseNavPaddingTop = binding.bottomNav.paddingTop
        val baseNavPaddingBottom = binding.bottomNav.paddingBottom

        ViewCompat.setOnApplyWindowInsetsListener(binding.root) { _, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            currentBottomInset = systemBars.bottom

            binding.appBarLayout.setPadding(
                binding.appBarLayout.paddingLeft,
                baseAppBarTopPadding + systemBars.top,
                binding.appBarLayout.paddingRight,
                binding.appBarLayout.paddingBottom,
            )

            binding.bottomNav.setPadding(
                binding.bottomNav.paddingLeft,
                baseNavPaddingTop,
                binding.bottomNav.paddingRight,
                baseNavPaddingBottom + systemBars.bottom,
            )

            binding.mainContent.setPadding(
                binding.mainContent.paddingLeft,
                binding.mainContent.paddingTop,
                binding.mainContent.paddingRight,
                dp(78) + systemBars.bottom,
            )

            insets
        }
        ViewCompat.requestApplyInsets(binding.root)
    }

    // ── Dashboard ─────────────────────────────────────────────────────────────

    private fun setupDashboard() {
        binding.tvUserName.text = "Administrador"
        binding.tvMonthRevenue.text = "245.800 MT"
        binding.tvInvoiceCount.text = "38"
        binding.tvClientCount.text = "124"
        binding.tvPendingCount.text = "7"

        configureQuickAccess(binding.qaFacturas, "Facturas", android.R.drawable.ic_menu_agenda)
        configureQuickAccess(binding.qaClientes, "Clientes", android.R.drawable.ic_menu_myplaces)
        configureQuickAccess(binding.qaEstoque, "Stock", android.R.drawable.ic_menu_sort_by_size)
        configureQuickAccess(binding.qaRelatorios, "Relatorios", android.R.drawable.ic_menu_view)
        configureQuickAccess(binding.qaVendas, "Vendas", android.R.drawable.ic_menu_send)
        configureQuickAccess(binding.qaFornecedores, "Fornecedores", android.R.drawable.ic_menu_upload)
        configureQuickAccess(binding.qaFuncionarios, "Equipa", android.R.drawable.ic_menu_manage)
        configureQuickAccess(binding.qaDefinicoes, "Definicoes", android.R.drawable.ic_menu_preferences)

        configureActivity(binding.row1, "Factura #FT-2026-0038", "Cliente: Empresa ABC", "12.500 MT")
        configureActivity(binding.row2, "Pagamento recebido", "M-Pesa confirmado", "8.900 MT")
        configureActivity(binding.row3, "Stock baixo", "Produto: Papel A4", "12 un.")
    }

    private fun configureQuickAccess(item: ItemQuickAccessBinding, label: String, iconRes: Int) {
        item.tvQuickLabel.text = label
        item.ivQuickIcon.setImageResource(iconRes)
        item.root.setOnClickListener { Toast.makeText(this, label, Toast.LENGTH_SHORT).show() }
    }

    private fun configureActivity(item: ItemActivityRowBinding, title: String, subtitle: String, amount: String) {
        item.tvActivityTitle.text = title
        item.tvActivitySub.text = subtitle
        item.tvActivityAmount.text = amount
    }

    // ── Navigation ────────────────────────────────────────────────────────────

    private fun setupNavigation() {
        val items = listOf(
            InternalNavItem(binding.navHome, binding.navHomeIcon, binding.navHomeLabel, InternalPage.HOME),
            InternalNavItem(binding.navModules, binding.navModulesIcon, binding.navModulesLabel, InternalPage.MODULES),
            InternalNavItem(binding.navChat, binding.navChatIcon, binding.navChatLabel, InternalPage.CHAT),
            InternalNavItem(binding.navVacation, binding.navVacationIcon, binding.navVacationLabel, InternalPage.VACATION),
            InternalNavItem(binding.navAttendance, binding.navAttendanceIcon, binding.navAttendanceLabel, InternalPage.ATTENDANCE),
            InternalNavItem(binding.navProfile, binding.navProfileIcon, binding.navProfileLabel, InternalPage.PROFILE),
        )

        fun selectItem(selected: InternalNavItem) {
            items.forEach { item ->
                val color = getColor(if (item == selected) R.color.primary_blue else R.color.text_hint)
                item.icon.setColorFilter(color)
                item.label.setTextColor(color)
            }
        }

        items.forEach { item ->
            item.container.setOnClickListener {
                selectItem(item)
                showPage(item.page)
            }
        }

        selectItem(items.first())
        showPage(InternalPage.HOME)
    }

    private fun showPage(page: InternalPage) {
        if (page != InternalPage.CHAT) {
            hideChatInputBar()
            restoreNormalHeader()
            activeChatContact = null
        }
        when (page) {
            InternalPage.HOME -> showHomePage()
            InternalPage.MODULES -> showModulesPage()
            InternalPage.CHAT -> showChatPage()
            InternalPage.VACATION -> showVacationPage()
            InternalPage.ATTENDANCE -> showAttendancePage()
            InternalPage.PROFILE -> showProfilePage()
        }
    }

    private fun showHomePage() {
        binding.mainContent.setPadding(0, 0, 0, dp(78) + currentBottomInset)
        binding.mainContent.removeAllViews()
        homeViews.forEach { binding.mainContent.addView(it) }
    }

    private fun showModulesPage() {
        renderListPage(
            title = "Módulos",
            subtitle = "Acesse rapidamente as áreas operacionais do ERP.",
            rows = listOf(
                PageRow("Faturação", "Facturas, recibos, proformas e pagamentos", "Activo"),
                PageRow("Clientes", "Cadastro, histórico e contas a receber", "124"),
                PageRow("Stock", "Produtos, movimentos e alertas de ruptura", "12 alertas"),
                PageRow("Recursos Humanos", "Funcionários, férias e assiduidade", "32"),
                PageRow("Relatórios", "Indicadores comerciais e financeiros", "Hoje"),
            ),
        )
    }

    private fun showVacationPage() {
        binding.mainContent.setPadding(0, 0, 0, dp(78) + currentBottomInset)
        binding.mainContent.removeAllViews()

        binding.mainContent.addView(buildVacationBanner())
        binding.mainContent.addView(buildVacationKpiRow())
        binding.mainContent.addView(buildVacationRequestsSection())
        binding.mainContent.addView(buildRequestVacationButton())
    }

    private fun buildVacationBanner(): View {
        val totalDays = 30
        val usedDays = 12
        val availableDays = totalDays - usedDays

        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(getColor(R.color.primary_blue))
            setPadding(dp(20), dp(20), dp(20), dp(32))

            // Linha topo: título + ícone calendário
            addView(LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL

                addView(textView("Saldo de Férias", 13f, R.color.white).apply {
                    alpha = 0.8f
                    layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
                })

                addView(textView("2026", 12f, R.color.white).apply {
                    alpha = 0.7f
                    setPadding(dp(10), dp(4), dp(10), dp(4))
                    background = GradientDrawable().apply {
                        setColor(Color.argb(40, 255, 255, 255))
                        cornerRadius = dp(12).toFloat()
                    }
                })
            })

            // Número grande de dias disponíveis
            addView(textView("$availableDays", 56f, R.color.white, bold = true).apply {
                setPadding(0, dp(4), 0, 0)
                includeFontPadding = false
            })

            addView(textView("dias disponíveis de $totalDays", 13f, R.color.white).apply {
                alpha = 0.75f
                setPadding(0, dp(2), 0, dp(14))
            })

            // Barra de progresso
            addView(LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                background = GradientDrawable().apply {
                    setColor(Color.argb(40, 255, 255, 255))
                    cornerRadius = dp(4).toFloat()
                }
                layoutParams = LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, dp(6)
                )

                val usedFraction = usedDays.toFloat() / totalDays
                addView(View(context).apply {
                    layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, usedFraction)
                    background = GradientDrawable().apply {
                        setColor(Color.WHITE)
                        cornerRadius = dp(4).toFloat()
                    }
                })
                addView(View(context).apply {
                    layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1f - usedFraction)
                })
            })

            addView(LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setPadding(0, dp(6), 0, 0)

                addView(textView("$usedDays dias usados", 11f, R.color.white).apply {
                    alpha = 0.65f
                    layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
                })
                addView(textView("$availableDays restantes", 11f, R.color.white).apply {
                    alpha = 0.65f
                })
            })
        }
    }

    private fun buildVacationKpiRow(): View {
        data class KpiItem(val label: String, val value: String, val sub: String, val color: Int)

        val pending = vacationRequests.count { it.status == VacStatus.PENDING }
        val approved = vacationRequests.count { it.status == VacStatus.APPROVED }

        val items = listOf(
            KpiItem("Usados", "12", "dias", getColor(R.color.primary_blue)),
            KpiItem("Pendentes", "$pending", "pedido${if (pending != 1) "s" else ""}", Color.parseColor("#D97706")),
            KpiItem("Aprovados", "$approved", "este ano", Color.parseColor("#059669")),
        )

        return LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(dp(16), 0, dp(16), 0)
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = -dp(16) }

            items.forEachIndexed { index, item ->
                addView(LinearLayout(context).apply {
                    orientation = LinearLayout.VERTICAL
                    layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
                        when (index) {
                            0 -> marginEnd = dp(6)
                            1 -> { marginStart = dp(6); marginEnd = dp(6) }
                            2 -> marginStart = dp(6)
                        }
                    }
                    background = GradientDrawable().apply {
                        setColor(Color.WHITE)
                        cornerRadius = dp(10).toFloat()
                    }
                    elevation = dp(4).toFloat()
                    setPadding(dp(12), dp(14), dp(12), dp(14))

                    addView(textView(item.label, 11f, R.color.text_secondary))
                    addView(textView(item.value, 22f, R.color.text_primary, bold = true).apply {
                        setTextColor(item.color)
                        setPadding(0, dp(4), 0, 0)
                    })
                    addView(textView(item.sub, 10f, R.color.text_hint).apply {
                        setPadding(0, dp(2), 0, 0)
                    })
                })
            }
        }
    }

    private fun buildVacationRequestsSection(): View {
        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(20), dp(28), dp(20), 0)

            // Cabeçalho da secção
            addView(LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL

                addView(textView("Pedidos de Férias", 15f, R.color.text_primary, bold = true).apply {
                    layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
                })

                val pending = vacationRequests.count { it.status == VacStatus.PENDING }
                if (pending > 0) {
                    addView(textView("$pending pendente${if (pending != 1) "s" else ""}", 11f, R.color.white, bold = true).apply {
                        setPadding(dp(10), dp(5), dp(10), dp(5))
                        background = GradientDrawable().apply {
                            setColor(Color.parseColor("#D97706"))
                            cornerRadius = dp(12).toFloat()
                        }
                    })
                }
            })

            // Cards de pedidos
            vacationRequests.forEach { req ->
                addView(buildVacationCard(req))
            }
        }
    }

    private fun buildVacationCard(req: VacationRequest): View {
        val statusColor = when (req.status) {
            VacStatus.PENDING  -> Color.parseColor("#D97706")
            VacStatus.APPROVED -> Color.parseColor("#059669")
            VacStatus.REJECTED -> Color.parseColor("#DC2626")
        }
        val statusBg = when (req.status) {
            VacStatus.PENDING  -> Color.parseColor("#FEF3C7")
            VacStatus.APPROVED -> Color.parseColor("#ECFDF5")
            VacStatus.REJECTED -> Color.parseColor("#FEF2F2")
        }
        val statusLabel = when (req.status) {
            VacStatus.PENDING  -> "Pendente"
            VacStatus.APPROVED -> "Aprovado"
            VacStatus.REJECTED -> "Rejeitado"
        }

        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dp(12) }
            background = GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadius = dp(14).toFloat()
            }
            elevation = dp(2).toFloat()
            setPadding(dp(14), dp(14), dp(14), dp(14))

            // Linha principal: avatar + nome/data + badge
            addView(LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL

                // Avatar
                addView(textView(req.initials, 13f, R.color.white, bold = true).apply {
                    gravity = Gravity.CENTER
                    includeFontPadding = false
                    layoutParams = LinearLayout.LayoutParams(dp(42), dp(42)).apply { marginEnd = dp(12) }
                    background = oval(req.color)
                })

                // Nome + intervalo de datas
                addView(LinearLayout(context).apply {
                    orientation = LinearLayout.VERTICAL
                    layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
                    addView(textView(req.name, 15f, R.color.text_primary, bold = true))
                    addView(LinearLayout(context).apply {
                        orientation = LinearLayout.HORIZONTAL
                        gravity = Gravity.CENTER_VERTICAL
                        setPadding(0, dp(4), 0, 0)
                        addView(textView(req.dateRange, 12f, R.color.text_secondary))
                        addView(textView("  ·  ${req.days} dias", 12f, R.color.text_hint))
                    })
                })

                // Badge de status
                addView(textView(statusLabel, 11f, R.color.text_primary, bold = true).apply {
                    setTextColor(statusColor)
                    setPadding(dp(10), dp(5), dp(10), dp(5))
                    background = GradientDrawable().apply {
                        setColor(statusBg)
                        cornerRadius = dp(10).toFloat()
                    }
                })
            })

            // Botões de acção para pedidos pendentes
            if (req.status == VacStatus.PENDING) {
                addView(View(context).apply {
                    layoutParams = LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT, dp(1)
                    ).apply { topMargin = dp(12); bottomMargin = dp(12) }
                    setBackgroundColor(getColor(R.color.border_color))
                })

                addView(LinearLayout(context).apply {
                    orientation = LinearLayout.HORIZONTAL
                    gravity = Gravity.END

                    addView(textView("Rejeitar", 13f, R.color.text_secondary, bold = true).apply {
                        setPadding(dp(16), dp(8), dp(16), dp(8))
                        background = GradientDrawable().apply {
                            setColor(getColor(R.color.background))
                            cornerRadius = dp(8).toFloat()
                            setStroke(dp(1), getColor(R.color.border_color))
                        }
                        layoutParams = LinearLayout.LayoutParams(
                            ViewGroup.LayoutParams.WRAP_CONTENT,
                            ViewGroup.LayoutParams.WRAP_CONTENT,
                        ).apply { marginEnd = dp(10) }
                        setOnClickListener { Toast.makeText(context, "Pedido rejeitado", Toast.LENGTH_SHORT).show() }
                    })

                    addView(textView("Aprovar", 13f, R.color.white, bold = true).apply {
                        setPadding(dp(16), dp(8), dp(16), dp(8))
                        background = GradientDrawable().apply {
                            setColor(Color.parseColor("#059669"))
                            cornerRadius = dp(8).toFloat()
                        }
                        setOnClickListener { Toast.makeText(context, "Pedido aprovado", Toast.LENGTH_SHORT).show() }
                    })
                })
            }
        }
    }

    private fun buildRequestVacationButton(): View {
        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(20), dp(24), dp(20), dp(8))

            addView(textView("+ Solicitar Férias", 15f, R.color.white, bold = true).apply {
                gravity = Gravity.CENTER
                setPadding(0, dp(14), 0, dp(14))
                background = GradientDrawable().apply {
                    setColor(getColor(R.color.primary_blue))
                    cornerRadius = dp(14).toFloat()
                }
                layoutParams = LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                )
                setOnClickListener { Toast.makeText(context, "Novo pedido de férias", Toast.LENGTH_SHORT).show() }
            })
        }
    }

    private fun showAttendancePage() {
        renderListPage(
            title = "Assiduidade",
            subtitle = "Registos de presença, atrasos e horas trabalhadas.",
            rows = listOf(
                PageRow("Hoje", "28 presenças registadas", "87%"),
                PageRow("Atrasos", "3 colaboradores chegaram após a hora", "3"),
                PageRow("Ausências", "2 ausências por justificar", "2"),
                PageRow("Horas extra", "14h acumuladas esta semana", "14h"),
            ),
        )
    }

    private fun showProfilePage() {
        renderListPage(
            title = "Perfil",
            subtitle = "Dados da conta, empresa e preferências.",
            rows = listOf(
                PageRow("Administrador", "admin@nexora.co.mz", "Online"),
                PageRow("Empresa", "Nexora ERP Demo", "Maputo"),
                PageRow("Perfil de acesso", "Administrador geral", "Total"),
                PageRow("Segurança", "Password e sessões activas", "Gerir"),
            ),
        )
    }

    // ── Chat list ─────────────────────────────────────────────────────────────

    private fun showChatPage() {
        activeChatContact = null
        hideChatInputBar()
        restoreNormalHeader()

        binding.mainContent.removeAllViews()
        binding.mainContent.setPadding(0, 0, 0, dp(78) + currentBottomInset)

        binding.mainContent.addView(buildChatListHeader())

        chatContacts.forEachIndexed { index, contact ->
            binding.mainContent.addView(buildConversationItem(contact))
            if (index < chatContacts.lastIndex) {
                binding.mainContent.addView(View(this).apply {
                    layoutParams = LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT, dp(1)
                    ).apply { marginStart = dp(76) }
                    setBackgroundColor(getColor(R.color.border_color))
                })
            }
        }
    }

    private fun buildChatListHeader(): View {
        return LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(20), dp(20), dp(20), dp(16))

            addView(LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
                addView(textView("Mensagens", 22f, R.color.text_primary, bold = true))
                val totalUnread = chatContacts.sumOf { it.unread }
                val sub = if (totalUnread > 0) "$totalUnread novas mensagens" else "Todas as mensagens"
                addView(textView(sub, 13f, R.color.text_secondary).apply {
                    setPadding(0, dp(3), 0, 0)
                })
            })

            addView(ImageView(context).apply {
                setImageResource(android.R.drawable.ic_menu_search)
                setColorFilter(getColor(R.color.primary_blue))
                layoutParams = LinearLayout.LayoutParams(dp(40), dp(40))
                background = oval(getColor(R.color.background))
                setPadding(dp(8), dp(8), dp(8), dp(8))
            })
        }
    }

    private fun buildConversationItem(contact: ChatContact): View {
        val rippleValue = TypedValue()
        theme.resolveAttribute(android.R.attr.selectableItemBackground, rippleValue, true)

        return LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(16), dp(14), dp(16), dp(14))
            background = ContextCompat.getDrawable(context, rippleValue.resourceId)

            // Avatar + online dot
            addView(FrameLayout(context).apply {
                layoutParams = LinearLayout.LayoutParams(dp(52), dp(52))

                addView(textView(contact.initials, 15f, R.color.white, bold = true).apply {
                    gravity = Gravity.CENTER
                    layoutParams = FrameLayout.LayoutParams(dp(48), dp(48)).apply {
                        gravity = Gravity.CENTER
                    }
                    background = oval(contact.color)
                })

                if (contact.unread > 0) {
                    addView(View(context).apply {
                        layoutParams = FrameLayout.LayoutParams(dp(13), dp(13)).apply {
                            gravity = Gravity.BOTTOM or Gravity.END
                        }
                        background = GradientDrawable().apply {
                            shape = GradientDrawable.OVAL
                            setColor(Color.parseColor("#10B981"))
                            setStroke(dp(2), Color.WHITE)
                        }
                    })
                }
            })

            // Name + last message
            addView(LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
                    setMargins(dp(12), 0, dp(8), 0)
                }
                addView(textView(contact.name, 15f, R.color.text_primary, bold = true))
                addView(textView(contact.lastMessage, 13f, R.color.text_secondary).apply {
                    setPadding(0, dp(3), 0, 0)
                    maxLines = 1
                    ellipsize = TextUtils.TruncateAt.END
                })
            })

            // Time + unread badge
            addView(LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.END
                layoutParams = LinearLayout.LayoutParams(dp(52), ViewGroup.LayoutParams.WRAP_CONTENT)

                addView(textView(contact.time, 11f, R.color.text_hint).apply {
                    gravity = Gravity.END
                })

                if (contact.unread > 0) {
                    addView(textView(contact.unread.toString(), 11f, R.color.white, bold = true).apply {
                        gravity = Gravity.CENTER
                        includeFontPadding = false
                        layoutParams = LinearLayout.LayoutParams(dp(20), dp(20)).apply {
                            topMargin = dp(5)
                            gravity = Gravity.END
                        }
                        background = oval(getColor(R.color.primary_blue))
                    })
                }
            })

            setOnClickListener { showChatDetail(contact) }
        }
    }

    // ── Chat detail ───────────────────────────────────────────────────────────

    private fun showChatDetail(contact: ChatContact) {
        activeChatContact = contact
        setupChatDetailHeader(contact)

        binding.mainContent.removeAllViews()

        val inputBarHeight = dp(64)
        binding.mainContent.setPadding(0, 0, 0, inputBarHeight + dp(16) + currentBottomInset)

        binding.mainContent.addView(buildDateSeparator("Hoje"))

        val messages = chatMessages[contact.name] ?: emptyList()
        messages.forEach { msg -> binding.mainContent.addView(buildChatBubble(msg, contact)) }

        showChatInputBar()

        binding.dashboardScroll.post { binding.dashboardScroll.fullScroll(View.FOCUS_DOWN) }
    }

    private fun buildDateSeparator(label: String): View {
        return LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(20), dp(16), dp(20), dp(8))

            addView(View(context).apply {
                layoutParams = LinearLayout.LayoutParams(0, dp(1), 1f)
                setBackgroundColor(getColor(R.color.border_color))
            })

            addView(textView(label, 11f, R.color.text_hint).apply {
                setPadding(dp(12), dp(5), dp(12), dp(5))
                background = GradientDrawable().apply {
                    setColor(getColor(R.color.white))
                    cornerRadius = dp(12).toFloat()
                    setStroke(dp(1), getColor(R.color.border_color))
                }
            })

            addView(View(context).apply {
                layoutParams = LinearLayout.LayoutParams(0, dp(1), 1f)
                setBackgroundColor(getColor(R.color.border_color))
            })
        }
    }

    private fun buildChatBubble(msg: ChatMsg, contact: ChatContact): View {
        val r = dp(16).toFloat()
        val flat = dp(3).toFloat()
        val sentRadii = floatArrayOf(r, r, r, r, flat, flat, r, r)
        val receivedRadii = floatArrayOf(r, r, r, r, r, r, flat, flat)

        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply { setMargins(dp(12), dp(3), dp(12), dp(3)) }

            val row = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = if (msg.isMe) Gravity.END else Gravity.START
                layoutParams = LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                )
            }

            // Avatar para mensagens recebidas
            if (!msg.isMe) {
                row.addView(textView(contact.initials, 10f, R.color.white, bold = true).apply {
                    gravity = Gravity.CENTER
                    includeFontPadding = false
                    layoutParams = LinearLayout.LayoutParams(dp(28), dp(28)).apply {
                        marginEnd = dp(6)
                        gravity = Gravity.BOTTOM
                    }
                    background = oval(contact.color)
                })
            }

            // Coluna com bolha + hora
            val bubbleCol = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                gravity = if (msg.isMe) Gravity.END else Gravity.START
                layoutParams = LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                )
            }

            bubbleCol.addView(textView(msg.text, 14f, if (msg.isMe) R.color.white else R.color.text_primary).apply {
                setPadding(dp(12), dp(8), dp(12), dp(8))
                maxWidth = (resources.displayMetrics.widthPixels * 0.70).toInt()
                background = GradientDrawable().apply {
                    setColor(if (msg.isMe) getColor(R.color.primary_blue) else Color.WHITE)
                    cornerRadii = if (msg.isMe) sentRadii else receivedRadii
                    if (!msg.isMe) setStroke(dp(1), getColor(R.color.border_color))
                }
            })

            bubbleCol.addView(textView(msg.time, 10f, R.color.text_hint).apply {
                setPadding(dp(4), dp(3), dp(4), 0)
                gravity = if (msg.isMe) Gravity.END else Gravity.START
            })

            row.addView(bubbleCol)
            addView(row)
        }
    }

    // ── Chat input bar ────────────────────────────────────────────────────────

    private fun showChatInputBar() {
        hideChatInputBar()

        val navHeight = if (binding.bottomNav.height > 0) binding.bottomNav.height
        else dp(62) + currentBottomInset

        val editText = EditText(this).apply {
            hint = "Escrever mensagem…"
            setHintTextColor(getColor(R.color.text_hint))
            setTextColor(getColor(R.color.text_primary))
            textSize = 14f
            maxLines = 3
            background = GradientDrawable().apply {
                setColor(getColor(R.color.background))
                cornerRadius = dp(24).toFloat()
                setStroke(dp(1), getColor(R.color.border_color))
            }
            setPadding(dp(16), dp(10), dp(16), dp(10))
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
                marginEnd = dp(10)
            }
        }

        val bar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(12), dp(10), dp(12), dp(10))
            setBackgroundColor(Color.WHITE)
            elevation = dp(12).toFloat()

            addView(editText)

            addView(ImageView(context).apply {
                setImageResource(R.drawable.ic_send)
                layoutParams = LinearLayout.LayoutParams(dp(46), dp(46))
                background = oval(getColor(R.color.primary_blue))
                setPadding(dp(11), dp(11), dp(11), dp(11))
                setOnClickListener {
                    val msg = editText.text.toString().trim()
                    if (msg.isNotEmpty()) {
                        editText.setText("")
                        Toast.makeText(context, "Mensagem enviada!", Toast.LENGTH_SHORT).show()
                    }
                }
            })
        }

        val params = CoordinatorLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        ).apply {
            gravity = Gravity.BOTTOM
            bottomMargin = navHeight
        }

        chatInputBar = bar
        binding.root.addView(bar, params)
    }

    private fun hideChatInputBar() {
        chatInputBar?.let { binding.root.removeView(it) }
        chatInputBar = null
    }

    // ── Chat header ───────────────────────────────────────────────────────────

    private fun setupChatDetailHeader(contact: ChatContact) {
        removeChatHeaderView()
        binding.normalHeader.visibility = View.GONE

        val rippleValue = TypedValue()
        theme.resolveAttribute(android.R.attr.selectableItemBackgroundBorderless, rippleValue, true)

        val header = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(4), 0, dp(12), 0)
            layoutParams = AppBarLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(64)
            ).apply {
                scrollFlags = AppBarLayout.LayoutParams.SCROLL_FLAG_SCROLL or
                        AppBarLayout.LayoutParams.SCROLL_FLAG_ENTER_ALWAYS
            }

            // Botão voltar
            addView(ImageView(context).apply {
                setImageResource(R.drawable.ic_arrow_back)
                layoutParams = LinearLayout.LayoutParams(dp(48), dp(48))
                background = ContextCompat.getDrawable(context, rippleValue.resourceId)
                setPadding(dp(12), dp(12), dp(12), dp(12))
                setOnClickListener { activeChatContact = null; showChatPage() }
            })

            // Avatar do contacto
            addView(textView(contact.initials, 13f, R.color.white, bold = true).apply {
                gravity = Gravity.CENTER
                includeFontPadding = false
                layoutParams = LinearLayout.LayoutParams(dp(38), dp(38)).apply {
                    marginStart = dp(2)
                    marginEnd = dp(10)
                }
                background = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(contact.color)
                    setStroke(dp(2), Color.argb(70, 255, 255, 255))
                }
            })

            // Nome + estado
            addView(LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
                addView(textView(contact.name, 16f, R.color.white, bold = true))
                addView(textView(
                    if (contact.unread > 0) "Online" else "Última vez ontem",
                    11f, R.color.white
                ).apply {
                    alpha = 0.75f
                    setPadding(0, dp(2), 0, 0)
                })
            })

            // Mais opções
            addView(ImageView(context).apply {
                setImageResource(android.R.drawable.ic_menu_more)
                setColorFilter(Color.WHITE)
                layoutParams = LinearLayout.LayoutParams(dp(40), dp(40))
                background = ContextCompat.getDrawable(context, rippleValue.resourceId)
                setPadding(dp(8), dp(8), dp(8), dp(8))
            })
        }

        binding.appBarLayout.addView(header)
        chatHeaderView = header
    }

    private fun removeChatHeaderView() {
        chatHeaderView?.let { binding.appBarLayout.removeView(it) }
        chatHeaderView = null
    }

    private fun restoreNormalHeader() {
        removeChatHeaderView()
        binding.normalHeader.visibility = View.VISIBLE
    }

    // ── Generic list page ─────────────────────────────────────────────────────

    private fun renderListPage(title: String, subtitle: String, rows: List<PageRow>) {
        binding.mainContent.setPadding(0, 0, 0, dp(78) + currentBottomInset)
        binding.mainContent.removeAllViews()
        binding.mainContent.addView(buildPageTitle(title, subtitle))
        rows.forEach { binding.mainContent.addView(buildPageCard(it)) }
    }

    private fun buildPageTitle(title: String, subtitle: String): LinearLayout {
        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(20), dp(24), dp(20), dp(8))
            addView(textView(title, 24f, R.color.text_primary, bold = true))
            addView(textView(subtitle, 14f, R.color.text_secondary).apply {
                setPadding(0, dp(6), 0, 0)
            })
        }
    }

    private fun buildPageCard(row: PageRow): LinearLayout {
        return LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(16), dp(14), dp(16), dp(14))
            background = GradientDrawable().apply {
                setColor(getColor(R.color.white))
                cornerRadius = dp(12).toFloat()
            }
            elevation = dp(2).toFloat()
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply { setMargins(dp(16), dp(8), dp(16), dp(8)) }

            addView(LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
                addView(textView(row.title, 15f, R.color.text_primary, bold = true))
                addView(textView(row.subtitle, 12f, R.color.text_secondary).apply {
                    setPadding(0, dp(4), 0, 0)
                })
            })

            addView(textView(row.value, 12f, R.color.primary_blue, bold = true).apply {
                gravity = Gravity.CENTER
                setPadding(dp(10), dp(6), dp(10), dp(6))
                background = GradientDrawable().apply {
                    setColor(getColor(R.color.background))
                    cornerRadius = dp(16).toFloat()
                }
            })
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private fun textView(
        value: String, size: Float, colorRes: Int, bold: Boolean = false
    ): TextView = TextView(this).apply {
        text = value
        textSize = size
        setTextColor(getColor(colorRes))
        includeFontPadding = false
        if (bold) typeface = Typeface.DEFAULT_BOLD
    }

    private fun oval(color: Int): GradientDrawable = GradientDrawable().apply {
        shape = GradientDrawable.OVAL
        setColor(color)
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()

    // ── Data types ────────────────────────────────────────────────────────────

    private data class PageRow(val title: String, val subtitle: String, val value: String)

    private enum class InternalPage {
        HOME, MODULES, CHAT, VACATION, ATTENDANCE, PROFILE
    }

    private data class InternalNavItem(
        val container: LinearLayout,
        val icon: ImageView,
        val label: TextView,
        val page: InternalPage,
    )
}
