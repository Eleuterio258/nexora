<?php
    // Requires: $pageTitle, $activePage

    // ── Permissões ERP — canModule() verifica o módulo independente do nome da acção ──
    $canRecrutamento = $app->session->canModule('recrutamento');
    $canCrm          = $app->session->canModule('crm');
    $canClientes     = $app->session->canModule('clientes');
    $canFaturacao    = $app->session->canModule('faturacao');
    $canPos          = $app->session->canModule('pos');
    $canProdutos     = $app->session->canModule('stock');
    $canUtilizadores = $app->session->canModule('autorizacao');
    $canCargos       = $app->session->canModule('autorizacao');
    $canEmpresa      = $app->session->canModule('empresa');
    $canSessoes      = $app->session->canModule('auth');
    $canAuditoria    = $app->session->canModule('auditoria');
    $canSistema      = $app->session->canModule('sistema-configuracao');
    $canRH           = $app->session->canModule('recursos-humanos');
    $canAssinaturaDigital = $app->session->canModule('assinatura-digital');
    $canContab       = $app->session->canModule('contabilidade');
    $canCentrosCusto = $app->session->canModule('centros-custo');
    $canTesouraria   = $app->session->canModule('tesouraria');
    $canLogistica    = $app->session->canModule('logistica');

    // ── Permissões Self-Service (da API — revogáveis sem logout) ───────────────
    $canChat         = $app->session->can('chat',         'ver_conversas');
    $canPedidoFerias = $app->session->can('pedido-ferias','ver_pedidos');
    $canAssiduidade  = $app->session->can('assiduidade',  'ver_assiduidade');
    $canPerfil       = $app->session->can('perfil',       'ver_perfil');
    $canAssinaturas  = $app->session->can('assinaturas');
    $canFinanceiro   = $app->session->can('financeiro');
    $canMultiMoeda   = $app->session->can('multi-moeda');
    $canNotificacoes = $app->session->can('notificacoes');
    $canSeguranca    = $app->session->can('seguranca');
    $canCompras      = $app->session->can('compras');
    $canImpostos     = $app->session->can('impostos');
    $canTarefas      = $app->session->can('tarefas');
    $canAdmGroup     = $canUtilizadores || $canCargos || $canEmpresa || $canSessoes || $canAuditoria;
    $isSuperAdmin    = $app->session->isSuperAdmin();

    if (!$isSuperAdmin && $canRecrutamento && (! isset($dash) || ! is_array($dash))) {
        $dash = $app->nexora->call('GET', '/api/recrutamento/dashboard')['body'] ?? [];
    }
    $dash = $dash ?? [];

    $sidebarVagasCount = (int) ($dash['vagas_ativas'] ?? 0) ?: null;
    $sidebarNovasCount = (int) ($dash['funil']['recebida'] ?? 0) ?: null;

    $loggedUser = $app->session->user();
    $adminUser  = $loggedUser['nome'] ?? $loggedUser['email'] ?? 'admin';
    $initials   = strtoupper(substr($adminUser, 0, 1));
    $userRole   = $app->session->isSuperAdmin() ? 'Admin Global' : ($loggedUser['cargo'] ?? 'Funcionário');

    $ap = $activePage ?? '';

    $recrutamentoOpen  = in_array($ap, ['recrutamento_dashboard','pipeline','relatorios','vagas','vaga_form','candidaturas','candidatura_ver','recrutamento_configuracao','recrutamento_contactos'], true);
    $crmOpen           = in_array($ap, ['leads','lead_form','crm_leads_pipeline','oportunidades','oportunidade_form','crm_pipeline'], true);
    $faturacaoOpen     = in_array($ap, ['faturacao_series','orcamentos','orcamento_form','encomendas','faturas','fatura_form','recibos','notas_credito'], true);
    $posOpen           = in_array($ap, ['pos','pos_dashboard','pos_vendas','pos_venda_ver','pos_terminais','pos_catalogo','pos_relatorios','pos_devolucoes'], true);
    $sistemaOpen       = in_array($ap, ['sistema_geral','sistema_templates','sistema_logs'], true);
    $rhOpen            = str_starts_with($ap, 'rh_');
    $contabOpen        = in_array($ap, ['contab_plano_contas','contab_periodos','contab_lancamentos','contab_lancamento','contab_impostos','contab_ativos_fixos','contab_amortizacoes','contab_orcamentos','contab_encerramento','contab_relatorios'], true);
    $produtosOpen      = in_array($ap, ['produtos','produto_form','produto_categorias'], true);
    $adminOpen         = in_array($ap, ['utilizadores','utilizador_form','cargos','cargo_form','empresa','sessoes','auditoria'], true);
    $superadminOpen    = in_array($ap, ['superadmin_dashboard','superadmin_tenants','superadmin_plans','superadmin_modules','superadmin_users','superadmin_settings'], true);
?>
<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo htmlspecialchars($pageTitle ?? 'Admin') ?> · E258Tech</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700;800&family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="/assets/css/nexora.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.7.2/css/all.min.css" crossorigin="anonymous" referrerpolicy="no-referrer">
    <style>
    .notif-wrapper{position:relative}
    .notif-badge{position:absolute;top:2px;right:2px;background:#e53e3e;color:#fff;border-radius:999px;font-size:.6rem;font-weight:700;min-width:16px;height:16px;display:flex;align-items:center;justify-content:center;padding:0 4px;pointer-events:none;line-height:1}
    .notif-panel{position:absolute;top:calc(100% + 8px);right:0;width:320px;background:var(--adm-surface,#fff);border:1px solid var(--adm-border,#e2e8f0);border-radius:8px;box-shadow:0 8px 24px rgba(0,0,0,.12);z-index:1000;overflow:hidden}
    .notif-panel-header{display:flex;align-items:center;justify-content:space-between;padding:12px 16px;border-bottom:1px solid var(--adm-border,#e2e8f0);font-weight:600;font-size:.875rem}
    .notif-list{list-style:none;margin:0;padding:0;max-height:360px;overflow-y:auto}
    .notif-item{padding:12px 16px;border-bottom:1px solid var(--adm-border,#f1f5f9);cursor:pointer;transition:background .15s}
    .notif-item:hover{background:var(--adm-hover,#f8fafc)}
    .notif-item.notif-unread{background:#eff6ff}
    .notif-item.notif-unread:hover{background:#dbeafe}
    .notif-item-titulo{font-weight:600;font-size:.8125rem;color:var(--adm-text,#1e293b)}
    .notif-item-msg{font-size:.75rem;color:var(--adm-text-muted,#64748b);margin-top:2px}
    .notif-empty{padding:24px;text-align:center;color:var(--adm-text-muted,#64748b);font-size:.875rem}
    </style>
<script>
(function(){
    var _k1=<?= $app->id->k1() ?>,_k2=<?= $app->id->k2() ?>;
    var B36='0123456789abcdefghijklmnopqrstuvwxyz';
    function rotl32(x,n){return(((x<<n)|(x>>>(32-n)))>>>0);}
    function toB36(n){if(!n)return'0';var s='';n=n>>>0;while(n>0){s=B36[n%36]+s;n=Math.floor(n/36);}return s;}
    window.nexoraEncodeId=function(id){
        if(!id||id<=0)return'0';
        return toB36(rotl32((id^_k1)>>>0,13)^_k2);
    };
})();
</script>
</head>
<body>
<div class="adm-wrapper">

    <!-- ── Sidebar ── -->
    <aside class="adm-sidebar" id="admSidebar">
        <div class="adm-sidebar-logo">
            <img src="/assets/images/e258tech-logo.png" alt="E258Tech">
            <span>Nexora</span>
        </div>

        <nav class="adm-nav">

            <?php $chevron = '<svg class="adm-nav-chevron" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 6 15 12 9 18"/></svg>'; ?>

            <?php if (!$isSuperAdmin): ?>

            <!-- ── Recrutamento ── -->
            <?php if ($canRecrutamento): ?>
            <div class="adm-nav-section">
                <details class="adm-nav-group" <?= $recrutamentoOpen ? 'open' : '' ?>>
                    <summary class="adm-nav-group-title">
                        <i class="fa-solid fa-briefcase fa-fw"></i> Recrutamento <?= $chevron ?>
                    </summary>
                    <div class="adm-nav-submenu">
                        <a href="<?= htmlspecialchars($app->routes->path('recrutamento_dashboard')) ?>" class="adm-nav-item <?= $ap === 'recrutamento_dashboard' ? 'active' : '' ?>">
                            <i class="fa-solid fa-table-cells-large fa-fw"></i> Dashboard
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('pipeline')) ?>" class="adm-nav-item <?= $ap === 'pipeline' ? 'active' : '' ?>">
                            <i class="fa-solid fa-filter fa-fw"></i> Pipeline
                            <?php if (! empty($sidebarNovasCount)): ?><span class="adm-nav-badge"><?= $sidebarNovasCount ?></span><?php endif; ?>
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('relatorios')) ?>" class="adm-nav-item <?= $ap === 'relatorios' ? 'active' : '' ?>">
                            <i class="fa-solid fa-chart-bar fa-fw"></i> Relatórios
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('vagas')) ?>" class="adm-nav-item <?= in_array($ap, ['vagas','vaga_form'], true) ? 'active' : '' ?>">
                            <i class="fa-solid fa-briefcase fa-fw"></i> Gerir Vagas
                            <?php if (! empty($sidebarVagasCount)): ?><span class="adm-nav-badge"><?= $sidebarVagasCount ?></span><?php endif; ?>
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('candidaturas')) ?>" class="adm-nav-item <?= in_array($ap, ['candidaturas','candidatura_ver'], true) ? 'active' : '' ?>">
                            <i class="fa-solid fa-users fa-fw"></i> Todos os Candidatos
                            <?php if (! empty($sidebarNovasCount)): ?><span class="adm-nav-badge"><?= $sidebarNovasCount ?></span><?php endif; ?>
                        </a>
                        <?php if ($app->session->can('recrutamento', 'configurar_recrutamento')): ?>
                        <a href="<?= htmlspecialchars($app->routes->path('recrutamento_configuracao')) ?>" class="adm-nav-item <?= $ap === 'recrutamento_configuracao' ? 'active' : '' ?>">
                            <i class="fa-solid fa-sliders fa-fw"></i> Configuração
                        </a>
                        <?php endif; ?>
                        <a href="<?= htmlspecialchars($app->routes->path('recrutamento_contactos')) ?>" class="adm-nav-item <?= $ap === 'recrutamento_contactos' ? 'active' : '' ?>">
                            <i class="fa-solid fa-envelope fa-fw"></i> Contactos
                        </a>
                    </div>
                </details>
            </div>
            <?php endif; ?>

            <!-- ── CRM ── -->
            <?php if ($canCrm): ?>
            <div class="adm-nav-section">
                <details class="adm-nav-group" <?= $crmOpen ? 'open' : '' ?>>
                    <summary class="adm-nav-group-title">
                        <i class="fa-solid fa-handshake fa-fw"></i> CRM <?= $chevron ?>
                    </summary>
                    <div class="adm-nav-submenu">
                        <a href="<?= htmlspecialchars($app->routes->path('leads')) ?>" class="adm-nav-item <?= in_array($ap, ['leads','lead_form'], true) ? 'active' : '' ?>">
                            <i class="fa-solid fa-user-tag fa-fw"></i> Leads
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('crm_leads_pipeline')) ?>" class="adm-nav-item <?= $ap === 'crm_leads_pipeline' ? 'active' : '' ?>">
                            <i class="fa-solid fa-filter fa-fw"></i> Pipeline de Leads
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('oportunidades')) ?>" class="adm-nav-item <?= in_array($ap, ['oportunidades','oportunidade_form'], true) ? 'active' : '' ?>">
                            <i class="fa-solid fa-coins fa-fw"></i> Oportunidades
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('crm_pipeline')) ?>" class="adm-nav-item <?= $ap === 'crm_pipeline' ? 'active' : '' ?>">
                            <i class="fa-solid fa-chart-line fa-fw"></i> Pipeline de Vendas
                        </a>
                    </div>
                </details>
            </div>
            <?php endif; ?>

            <!-- ── Clientes ── -->
            <?php if ($canClientes): ?>
            <div class="adm-nav-section">
                <p class="adm-nav-label">Clientes</p>
                <a href="<?= htmlspecialchars($app->routes->path('clientes')) ?>" class="adm-nav-item <?= in_array($ap, ['clientes','cliente_form'], true) ? 'active' : '' ?>">
                    <i class="fa-solid fa-user-tie fa-fw"></i> Clientes
                </a>
            </div>
            <?php endif; ?>

            <!-- ── Faturação ── -->
            <?php if ($canFaturacao): ?>
            <div class="adm-nav-section">
                <details class="adm-nav-group" <?= $faturacaoOpen ? 'open' : '' ?>>
                    <summary class="adm-nav-group-title">
                        <i class="fa-solid fa-file-invoice-dollar fa-fw"></i> Faturação <?= $chevron ?>
                    </summary>
                    <div class="adm-nav-submenu">
                        <a href="<?= htmlspecialchars($app->routes->path('faturacao_series')) ?>" class="adm-nav-item <?= $ap === 'faturacao_series' ? 'active' : '' ?>">
                            <i class="fa-solid fa-list-ol fa-fw"></i> Séries
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('orcamentos')) ?>" class="adm-nav-item <?= in_array($ap, ['orcamentos','orcamento_form'], true) ? 'active' : '' ?>">
                            <i class="fa-solid fa-file-lines fa-fw"></i> Orçamentos
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('encomendas')) ?>" class="adm-nav-item <?= $ap === 'encomendas' ? 'active' : '' ?>">
                            <i class="fa-solid fa-box fa-fw"></i> Encomendas
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('faturas')) ?>" class="adm-nav-item <?= in_array($ap, ['faturas','fatura_form'], true) ? 'active' : '' ?>">
                            <i class="fa-solid fa-credit-card fa-fw"></i> Faturas
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('recibos')) ?>" class="adm-nav-item <?= $ap === 'recibos' ? 'active' : '' ?>">
                            <i class="fa-solid fa-circle-check fa-fw"></i> Recibos
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('notas_credito')) ?>" class="adm-nav-item <?= $ap === 'notas_credito' ? 'active' : '' ?>">
                            <i class="fa-solid fa-file-circle-minus fa-fw"></i> Notas de Crédito
                        </a>
                    </div>
                </details>
            </div>
            <?php endif; ?>

            <!-- ── POS ── -->
            <?php if ($canPos): ?>
            <div class="adm-nav-section">
                <details class="adm-nav-group" <?= $posOpen ? 'open' : '' ?>>
                    <summary class="adm-nav-group-title">
                        <i class="fa-solid fa-cash-register fa-fw"></i> POS <?= $chevron ?>
                    </summary>
                    <div class="adm-nav-submenu">
                        <a href="<?= htmlspecialchars($app->routes->path('pos')) ?>" class="adm-nav-item <?= $ap === 'pos' ? 'active' : '' ?>">
                            <i class="fa-solid fa-cash-register fa-fw"></i> Ponto de Venda
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('pos_dashboard')) ?>" class="adm-nav-item <?= $ap === 'pos_dashboard' ? 'active' : '' ?>">
                            <i class="fa-solid fa-gauge fa-fw"></i> Dashboard
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('pos_vendas')) ?>" class="adm-nav-item <?= in_array($ap, ['pos_vendas','pos_venda_ver'], true) ? 'active' : '' ?>">
                            <i class="fa-solid fa-bag-shopping fa-fw"></i> Vendas
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('pos_relatorios')) ?>" class="adm-nav-item <?= $ap === 'pos_relatorios' ? 'active' : '' ?>">
                            <i class="fa-solid fa-chart-bar fa-fw"></i> Relatórios
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('pos_devolucoes')) ?>" class="adm-nav-item <?= $ap === 'pos_devolucoes' ? 'active' : '' ?>">
                            <i class="fa-solid fa-rotate-left fa-fw"></i> Devoluções
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('pos_terminais')) ?>" class="adm-nav-item <?= $ap === 'pos_terminais' ? 'active' : '' ?>">
                            <i class="fa-solid fa-desktop fa-fw"></i> Terminais
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('pos_catalogo')) ?>" class="adm-nav-item <?= $ap === 'pos_catalogo' ? 'active' : '' ?>">
                            <i class="fa-solid fa-list fa-fw"></i> Catálogo
                        </a>
                    </div>
                </details>
            </div>
            <?php endif; ?>

            <!-- ── Produtos ── -->
            <?php if ($canProdutos): ?>
            <div class="adm-nav-section">
                <details class="adm-nav-group" <?= $produtosOpen ? 'open' : '' ?>>
                    <summary class="adm-nav-group-title">
                        <i class="fa-solid fa-box fa-fw"></i> Produtos <?= $chevron ?>
                    </summary>
                    <div class="adm-nav-submenu">
                        <a href="<?= htmlspecialchars($app->routes->path('produtos')) ?>" class="adm-nav-item <?= in_array($ap, ['produtos','produto_form'], true) ? 'active' : '' ?>">
                            <i class="fa-solid fa-box-open fa-fw"></i> Catálogo
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('produto_categorias')) ?>" class="adm-nav-item <?= $ap === 'produto_categorias' ? 'active' : '' ?>">
                            <i class="fa-solid fa-tags fa-fw"></i> Categorias &amp; Marcas
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('stock')) ?>" class="adm-nav-item <?= $ap === 'stock' ? 'active' : '' ?>">
                            <i class="fa-solid fa-warehouse fa-fw"></i> Gestão de Stock
                        </a>
                    </div>
                </details>
            </div>
            <?php endif; ?>

            <!-- ── Compras ── -->
            <?php if ($canCompras): ?>
            <div class="adm-nav-section">
                <p class="adm-nav-label">Compras</p>
                <a href="<?= htmlspecialchars($app->routes->path('compras')) ?>" class="adm-nav-item <?= $ap === 'compras' ? 'active' : '' ?>">
                    <i class="fa-solid fa-cart-shopping fa-fw"></i> Gestão de Compras
                </a>
            </div>
            <?php endif; ?>

            <!-- ── Financeiro ── -->
            <?php if ($canTesouraria): ?>
            <div class="adm-nav-section">
                <p class="adm-nav-label">Tesouraria</p>
                <a href="<?= htmlspecialchars($app->routes->path('tesouraria')) ?>" class="adm-nav-item <?= $ap === 'tesouraria' ? 'active' : '' ?>">
                    <i class="fa-solid fa-building-columns fa-fw"></i> Tesouraria
                </a>
            </div>
            <?php endif; ?>

            <?php if ($canLogistica): ?>
            <div class="adm-nav-section">
                <p class="adm-nav-label">Logística</p>
                <a href="<?= htmlspecialchars($app->routes->path('logistica')) ?>" class="adm-nav-item <?= $ap === 'logistica' ? 'active' : '' ?>">
                    <i class="fa-solid fa-truck fa-fw"></i> Logística
                </a>
            </div>
            <?php endif; ?>

            <?php if ($canFinanceiro): ?>
            <div class="adm-nav-section">
                <p class="adm-nav-label">Financeiro</p>
                <a href="<?= htmlspecialchars($app->routes->path('financeiro')) ?>" class="adm-nav-item <?= $ap === 'financeiro' ? 'active' : '' ?>">
                    <i class="fa-solid fa-coins fa-fw"></i> Financeiro
                </a>
            </div>
            <?php endif; ?>

            <?php if ($canMultiMoeda): ?>
            <div class="adm-nav-section">
                <p class="adm-nav-label">Multi-Moeda</p>
                <a href="<?= htmlspecialchars($app->routes->path('multi_moeda')) ?>" class="adm-nav-item <?= $ap === 'multi_moeda' ? 'active' : '' ?>">
                    <i class="fa-solid fa-globe fa-fw"></i> Multi-Moeda
                </a>
            </div>
            <?php endif; ?>

            <?php if ($canCentrosCusto): ?>
            <div class="adm-nav-section">
                <p class="adm-nav-label">Centros de Custo</p>
                <a href="<?= htmlspecialchars($app->routes->path('centros_custo')) ?>" class="adm-nav-item <?= $ap === 'centros_custo' ? 'active' : '' ?>">
                    <i class="fa-solid fa-building fa-fw"></i> Centros de Custo
                </a>
            </div>
            <?php endif; ?>

            <?php if ($canImpostos): ?>
            <div class="adm-nav-section">
                <p class="adm-nav-label">Impostos</p>
                <a href="<?= htmlspecialchars($app->routes->path('impostos_avancados')) ?>" class="adm-nav-item <?= $ap === 'impostos_avancados' ? 'active' : '' ?>">
                    <i class="fa-solid fa-percent fa-fw"></i> Impostos Avançados
                </a>
            </div>
            <?php endif; ?>

            <!-- ── Contabilidade ── -->
            <?php if ($canContab): ?>
            <div class="adm-nav-section">
                <details class="adm-nav-group" <?= $contabOpen ? 'open' : '' ?>>
                    <summary class="adm-nav-group-title">
                        <i class="fa-solid fa-book fa-fw"></i> Contabilidade <?= $chevron ?>
                    </summary>
                    <div class="adm-nav-submenu">
                        <a href="<?= htmlspecialchars($app->routes->path('contab_plano_contas')) ?>" class="adm-nav-item <?= $ap === 'contab_plano_contas' ? 'active' : '' ?>">
                            <i class="fa-solid fa-sitemap fa-fw"></i> Plano de Contas
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('contab_periodos')) ?>" class="adm-nav-item <?= $ap === 'contab_periodos' ? 'active' : '' ?>">
                            <i class="fa-solid fa-calendar fa-fw"></i> Anos e Períodos Fiscais
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('contab_lancamentos')) ?>" class="adm-nav-item <?= in_array($ap, ['contab_lancamentos','contab_lancamento'], true) ? 'active' : '' ?>">
                            <i class="fa-solid fa-pen-to-square fa-fw"></i> Lançamentos
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('contab_impostos')) ?>" class="adm-nav-item <?= $ap === 'contab_impostos' ? 'active' : '' ?>">
                            <i class="fa-solid fa-percent fa-fw"></i> Impostos
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('contab_ativos_fixos')) ?>" class="adm-nav-item <?= $ap === 'contab_ativos_fixos' ? 'active' : '' ?>">
                            <i class="fa-solid fa-building fa-fw"></i> Ativos Fixos
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('contab_amortizacoes')) ?>" class="adm-nav-item <?= $ap === 'contab_amortizacoes' ? 'active' : '' ?>">
                            <i class="fa-solid fa-rotate fa-fw"></i> Amortizações
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('contab_orcamentos')) ?>" class="adm-nav-item <?= $ap === 'contab_orcamentos' ? 'active' : '' ?>">
                            <i class="fa-solid fa-file-lines fa-fw"></i> Orçamentos
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('contab_encerramento')) ?>" class="adm-nav-item <?= $ap === 'contab_encerramento' ? 'active' : '' ?>">
                            <i class="fa-solid fa-lock fa-fw"></i> Encerramento
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('contab_relatorios')) ?>" class="adm-nav-item <?= $ap === 'contab_relatorios' ? 'active' : '' ?>">
                            <i class="fa-solid fa-chart-bar fa-fw"></i> Relatórios
                        </a>
                    </div>
                </details>
            </div>
            <?php endif; ?>

            <!-- ── RH ── -->
            <?php if ($canRH): ?>
            <?php $rhBase = $app->routes->path('rh_funcionarios'); ?>
            <div class="adm-nav-section">
                <details class="adm-nav-group" <?= $rhOpen ? 'open' : '' ?>>
                    <summary class="adm-nav-group-title">
                        <i class="fa-solid fa-person-chalkboard fa-fw"></i> Recursos Humanos <?= $chevron ?>
                    </summary>
                    <div class="adm-nav-submenu">
                        <a href="<?= htmlspecialchars($rhBase) ?>" class="adm-nav-item <?= in_array($ap, ['rh_funcionarios','rh_funcionario'], true) ? 'active' : '' ?>">
                            <i class="fa-solid fa-users fa-fw"></i> Funcionários
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('rh_ausencias')) ?>" class="adm-nav-item <?= $ap === 'rh_ausencias' ? 'active' : '' ?>">
                            <i class="fa-solid fa-calendar-xmark fa-fw"></i> Ausências
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('rh_organograma')) ?>" class="adm-nav-item <?= $ap === 'rh_organograma' ? 'active' : '' ?>">
                            <i class="fa-solid fa-sitemap fa-fw"></i> Organograma
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('rh_relatorios')) ?>" class="adm-nav-item <?= $ap === 'rh_relatorios' ? 'active' : '' ?>">
                            <i class="fa-solid fa-chart-bar fa-fw"></i> Relatórios
                        </a>
                        <span class="adm-nav-sublabel">Configuração</span>
                        <a href="<?= htmlspecialchars($app->routes->path('rh_unidades')) ?>" class="adm-nav-item <?= $ap === 'rh_unidades' ? 'active' : '' ?>">
                            <i class="fa-solid fa-building fa-fw"></i> Unidades Organizacionais
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('rh_periodos')) ?>" class="adm-nav-item <?= $ap === 'rh_periodos' ? 'active' : '' ?>">
                            <i class="fa-solid fa-calendar fa-fw"></i> Períodos de Avaliação
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('rh_cargos')) ?>" class="adm-nav-item <?= $ap === 'rh_cargos' ? 'active' : '' ?>">
                            <i class="fa-solid fa-id-badge fa-fw"></i> Cargos
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('rh_horarios')) ?>" class="adm-nav-item <?= $ap === 'rh_horarios' ? 'active' : '' ?>">
                            <i class="fa-solid fa-clock fa-fw"></i> Horários
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('rh_componentes_salariais')) ?>" class="adm-nav-item <?= $ap === 'rh_componentes_salariais' ? 'active' : '' ?>">
                            <i class="fa-solid fa-coins fa-fw"></i> Componentes Salariais
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('rh_beneficios')) ?>" class="adm-nav-item <?= $ap === 'rh_beneficios' ? 'active' : '' ?>">
                            <i class="fa-solid fa-hand-holding-heart fa-fw"></i> Benefícios
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('rh_tipos_ausencia')) ?>" class="adm-nav-item <?= $ap === 'rh_tipos_ausencia' ? 'active' : '' ?>">
                            <i class="fa-solid fa-calendar-xmark fa-fw"></i> Tipos de Ausência
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('rh_criterios_avaliacao')) ?>" class="adm-nav-item <?= $ap === 'rh_criterios_avaliacao' ? 'active' : '' ?>">
                            <i class="fa-solid fa-star-half-stroke fa-fw"></i> Critérios de Avaliação
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('rh_formacoes')) ?>" class="adm-nav-item <?= $ap === 'rh_formacoes' ? 'active' : '' ?>">
                            <i class="fa-solid fa-graduation-cap fa-fw"></i> Formações
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('rh_processamento_salarial')) ?>" class="adm-nav-item <?= $ap === 'rh_processamento_salarial' ? 'active' : '' ?>">
                            <i class="fa-solid fa-money-bill-wave fa-fw"></i> Processamento Salarial
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('rh_configuracoes')) ?>" class="adm-nav-item <?= $ap === 'rh_configuracoes' ? 'active' : '' ?>">
                            <i class="fa-solid fa-gear fa-fw"></i> Configurações
                        </a>
                    </div>
                </details>
            </div>
            <?php endif; ?>

            <!-- ── Assinaturas ── -->
            <?php if ($canAssinaturas): ?>
            <div class="adm-nav-section">
                <p class="adm-nav-label">Assinaturas</p>
                <a href="<?= htmlspecialchars($app->routes->path('assinaturas')) ?>" class="adm-nav-item <?= $ap === 'assinaturas' ? 'active' : '' ?>">
                    <i class="fa-solid fa-file-contract fa-fw"></i> Assinaturas
                </a>
            </div>
            <?php endif; ?>

            <!-- ── Assinatura Digital ── -->
            <?php if ($canAssinaturaDigital): ?>
            <div class="adm-nav-section">
                <p class="adm-nav-label">Assinatura Digital</p>
                <a href="<?= htmlspecialchars($app->routes->path('assinatura_digital')) ?>" class="adm-nav-item <?= $ap === 'assinatura_digital' ? 'active' : '' ?>">
                    <i class="fa-solid fa-signature fa-fw"></i> Documentos para assinar
                </a>
            </div>
            <?php endif; ?>

            <!-- ── Notificações ── -->
            <?php if ($canNotificacoes): ?>
            <div class="adm-nav-section">
                <p class="adm-nav-label">Notificações</p>
                <a href="<?= htmlspecialchars($app->routes->path('notificacoes')) ?>" class="adm-nav-item <?= $ap === 'notificacoes' ? 'active' : '' ?>">
                    <i class="fa-solid fa-bell fa-fw"></i> Notificações
                </a>
            </div>
            <?php endif; ?>

            <!-- ── Segurança ── -->
            <?php if ($canSeguranca): ?>
            <div class="adm-nav-section">
                <p class="adm-nav-label">Segurança</p>
                <a href="<?= htmlspecialchars($app->routes->path('seguranca')) ?>" class="adm-nav-item <?= $ap === 'seguranca' ? 'active' : '' ?>">
                    <i class="fa-solid fa-shield-halved fa-fw"></i> Segurança
                </a>
            </div>
            <?php endif; ?>

            <!-- ── Tarefas / Kanban ── -->
            <?php if ($canTarefas): ?>
            <div class="adm-nav-section">
                <p class="adm-nav-label">Tarefas</p>
                <a href="<?= htmlspecialchars($app->routes->path('tarefas')) ?>" class="adm-nav-item <?= in_array($ap, ['tarefas','tarefas_quadro','tarefas_cartao'], true) ? 'active' : '' ?>">
                    <i class="fa-solid fa-table-columns fa-fw"></i> Quadros Kanban
                </a>
            </div>
            <?php endif; ?>

            <!-- ── Sistema ── -->
            <?php if ($canSistema): ?>
            <div class="adm-nav-section">
                <details class="adm-nav-group" <?= $sistemaOpen ? 'open' : '' ?>>
                    <summary class="adm-nav-group-title">
                        <i class="fa-solid fa-gear fa-fw"></i> Sistema <?= $chevron ?>
                    </summary>
                    <div class="adm-nav-submenu">
                        <a href="<?= htmlspecialchars($app->routes->path('sistema_geral')) ?>" class="adm-nav-item <?= $ap === 'sistema_geral' ? 'active' : '' ?>">
                            <i class="fa-solid fa-sliders fa-fw"></i> Configurações Gerais
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('sistema_templates')) ?>" class="adm-nav-item <?= $ap === 'sistema_templates' ? 'active' : '' ?>">
                            <i class="fa-solid fa-envelope fa-fw"></i> Modelos &amp; Integrações
                        </a>
                        <a href="<?= htmlspecialchars($app->routes->path('sistema_logs')) ?>" class="adm-nav-item <?= $ap === 'sistema_logs' ? 'active' : '' ?>">
                            <i class="fa-solid fa-file-lines fa-fw"></i> Logs do Sistema
                        </a>
                    </div>
                </details>
            </div>
            <?php endif; ?>

            <!-- ── Administração ── -->
            <?php if ($canAdmGroup): ?>
            <div class="adm-nav-section">
                <details class="adm-nav-group" <?= $adminOpen ? 'open' : '' ?>>
                    <summary class="adm-nav-group-title">
                        <i class="fa-solid fa-shield fa-fw"></i> Administração <?= $chevron ?>
                    </summary>
                    <div class="adm-nav-submenu">
                        <?php if ($canUtilizadores): ?>
                        <a href="<?= htmlspecialchars($app->routes->path('utilizadores')) ?>" class="adm-nav-item <?= in_array($ap, ['utilizadores','utilizador_form'], true) ? 'active' : '' ?>">
                            <i class="fa-solid fa-users fa-fw"></i> Utilizadores
                        </a>
                        <?php endif; ?>
                        <?php if ($canCargos): ?>
                        <a href="<?= htmlspecialchars($app->routes->path('cargos')) ?>" class="adm-nav-item <?= in_array($ap, ['cargos','cargo_form'], true) ? 'active' : '' ?>">
                            <i class="fa-solid fa-user-shield fa-fw"></i> Cargos &amp; Permissões
                        </a>
                        <?php endif; ?>
                        <?php if ($canEmpresa): ?>
                        <a href="<?= htmlspecialchars($app->routes->path('empresa')) ?>" class="adm-nav-item <?= $ap === 'empresa' ? 'active' : '' ?>">
                            <i class="fa-solid fa-building fa-fw"></i> Empresa &amp; Licença
                        </a>
                        <?php endif; ?>
                        <?php if ($canSessoes): ?>
                        <a href="<?= htmlspecialchars($app->routes->path('sessoes')) ?>" class="adm-nav-item <?= $ap === 'sessoes' ? 'active' : '' ?>">
                            <i class="fa-solid fa-desktop fa-fw"></i> Sessões
                        </a>
                        <?php endif; ?>
                        <?php if ($canAuditoria): ?>
                        <a href="<?= htmlspecialchars($app->routes->path('auditoria')) ?>" class="adm-nav-item <?= $ap === 'auditoria' ? 'active' : '' ?>">
                            <i class="fa-solid fa-clipboard-list fa-fw"></i> Auditoria
                        </a>
                        <?php endif; ?>
                    </div>
                </details>
            </div>
            <?php endif; ?>

            <!-- ── Self-Service Portal ── -->
            <?php if ($canChat || $canPedidoFerias || $canAssiduidade || $canPerfil): ?>
            <div class="adm-nav-section">
                <p class="adm-nav-label">Self-Service</p>
                <?php if ($canChat): ?>
                <a href="<?= htmlspecialchars($app->routes->path('chat')) ?>" class="adm-nav-item <?= $ap === 'chat' ? 'active' : '' ?>">
                    <i class="fa-solid fa-comments fa-fw"></i> Chat
                </a>
                <?php endif; ?>
                <?php if ($canPedidoFerias): ?>
                <a href="<?= htmlspecialchars($app->routes->path('pedido_ferias')) ?>" class="adm-nav-item <?= $ap === 'pedido_ferias' ? 'active' : '' ?>">
                    <i class="fa-solid fa-umbrella-beach fa-fw"></i> Pedido de Férias
                </a>
                <?php endif; ?>
                <?php if ($canAssiduidade): ?>
                <a href="<?= htmlspecialchars($app->routes->path('minha_assiduidade')) ?>" class="adm-nav-item <?= $ap === 'minha_assiduidade' ? 'active' : '' ?>">
                    <i class="fa-solid fa-clock fa-fw"></i> Assiduidade
                </a>
                <?php endif; ?>
                <a href="<?= htmlspecialchars($app->routes->path('meus_recibos')) ?>" class="adm-nav-item <?= in_array($ap, ['meus_recibos','meu_recibo'], true) ? 'active' : '' ?>">
                    <i class="fa-solid fa-file-invoice-dollar fa-fw"></i> Meus Recibos
                </a>
                <?php if ($canPerfil): ?>
                <a href="<?= htmlspecialchars($app->routes->path('meu_perfil')) ?>" class="adm-nav-item <?= $ap === 'meu_perfil' ? 'active' : '' ?>">
                    <i class="fa-solid fa-user-circle fa-fw"></i> Meu Perfil
                </a>
                <?php endif; ?>
            </div>
            <?php endif; ?>

            <?php endif; // !$isSuperAdmin ?>

            <!-- ── Plataforma (superadmin) ── -->
            <?php if ($isSuperAdmin): ?>
            <div class="adm-nav-section">
                <a href="<?= htmlspecialchars($app->routes->path('superadmin_dashboard')) ?>" class="adm-nav-item <?= $ap === 'superadmin_dashboard' ? 'active' : '' ?>">
                    <i class="fa-solid fa-table-cells-large fa-fw"></i> Dashboard
                </a>
                <a href="<?= htmlspecialchars($app->routes->path('superadmin_tenants')) ?>" class="adm-nav-item <?= $ap === 'superadmin_tenants' ? 'active' : '' ?>">
                    <i class="fa-solid fa-building fa-fw"></i> Tenants
                </a>
                <a href="<?= htmlspecialchars($app->routes->path('superadmin_plans')) ?>" class="adm-nav-item <?= $ap === 'superadmin_plans' ? 'active' : '' ?>">
                    <i class="fa-solid fa-layer-group fa-fw"></i> Planos
                </a>
                <a href="<?= htmlspecialchars($app->routes->path('superadmin_modules')) ?>" class="adm-nav-item <?= $ap === 'superadmin_modules' ? 'active' : '' ?>">
                    <i class="fa-solid fa-cubes fa-fw"></i> Módulos
                </a>
                <a href="<?= htmlspecialchars($app->routes->path('superadmin_users')) ?>" class="adm-nav-item <?= $ap === 'superadmin_users' ? 'active' : '' ?>">
                    <i class="fa-solid fa-users fa-fw"></i> Utilizadores
                </a>
                <a href="<?= htmlspecialchars($app->routes->path('superadmin_settings')) ?>" class="adm-nav-item <?= $ap === 'superadmin_settings' ? 'active' : '' ?>">
                    <i class="fa-solid fa-sliders fa-fw"></i> Configurações
                </a>
            </div>
            <?php endif; ?>

            <!-- ── Site ── -->
            <?php if (!$isSuperAdmin): ?>
            <div class="adm-nav-section">
                <p class="adm-nav-label">Site</p>
                <a href="/vagas" target="_blank" class="adm-nav-item">
                    <i class="fa-solid fa-earth-africa fa-fw"></i> Ver Site
                    <i class="fa-solid fa-arrow-up-right-from-square fa-fw" style="margin-left:auto;opacity:.4;font-size:.7rem"></i>
                </a>
            </div>
            <?php endif; ?>

        </nav>

        <div class="adm-sidebar-footer">
            <div class="adm-sidebar-user">
                <div class="adm-sidebar-avatar"><?= $initials ?></div>
                <div class="adm-sidebar-uinfo">
                    <div class="adm-sidebar-uname"><?= htmlspecialchars($adminUser) ?></div>
                    <div class="adm-sidebar-urole"><?= htmlspecialchars($userRole) ?></div>
                </div>
                <a href="/nexora/logout" class="adm-sidebar-logout" title="Sair">
                    <i class="fa-solid fa-right-from-bracket"></i>
                </a>
            </div>
        </div>
    </aside>

    <!-- ── Main ── -->
    <div class="adm-main">
        <header class="adm-header">
            <button class="adm-btn adm-btn-ghost adm-btn-icon" id="sidebarToggle" title="Menu" style="display:none">
                <i class="fa-solid fa-bars"></i>
            </button>
            <nav class="adm-header-breadcrumb">
                <?php foreach ($breadcrumb ?? [] as $i => [$label, $href]): ?>
                    <?php echo $i > 0 ? '<span class="sep">/</span>' : '' ?>
                    <?php if ($href && $i < count($breadcrumb) - 1): ?>
                        <a href="<?php echo htmlspecialchars($href) ?>"><?php echo htmlspecialchars($label) ?></a>
                    <?php else: ?>
                        <span class="current"><?php echo htmlspecialchars($label) ?></span>
                    <?php endif; ?>
                <?php endforeach; ?>
            </nav>
            <?php if (!$isSuperAdmin): ?>
            <div class="adm-header-actions">
                <?php if ($app->session->isBoth() && $app->session->canModule('gestao-escolar')): ?>
                <a href="/escola" class="adm-btn adm-btn-outline adm-btn-sm" style="margin-right:var(--adm-sp-2)">
                    <i class="fa-solid fa-graduation-cap"></i> Painel Escolar
                </a>
                <?php endif; ?>
                <a href="/vagas" target="_blank" class="adm-btn adm-btn-outline adm-btn-sm">
                    <i class="fa-solid fa-eye"></i> Ver Vagas
                </a>
                <?php if ($canPerfil): ?>
                <div class="notif-wrapper" id="notifWrapper" style="margin-left:var(--adm-sp-2)">
                    <button class="adm-btn adm-btn-ghost adm-btn-icon" id="notifBtn" title="Notificações" style="position:relative">
                        <i class="fa-solid fa-bell"></i>
                        <span class="notif-badge" id="notifBadge" style="display:none">0</span>
                    </button>
                    <div class="notif-panel" id="notifPanel" style="display:none">
                        <div class="notif-panel-header">
                            <span>Notificações</span>
                            <button class="adm-btn adm-btn-ghost adm-btn-sm" id="notifMarkAll" style="font-size:.75rem">Marcar todas lidas</button>
                        </div>
                        <ul class="notif-list" id="notifList">
                            <li class="notif-empty">A carregar...</li>
                        </ul>
                    </div>
                </div>
                <?php endif; ?>
            </div>
            <?php endif; ?>
        </header>

        <main class="adm-content">
<?php if (!$isSuperAdmin && $canPerfil): ?>
<script>
(function(){
    const WS_TOKEN = <?= json_encode($_SESSION['nexora_access_token'] ?? '') ?>;
    const USER_ID  = <?= json_encode((int)($loggedUser['id'] ?? 0)) ?>;
    if (!WS_TOKEN || !USER_ID) return;

    const badge   = document.getElementById('notifBadge');
    const btn     = document.getElementById('notifBtn');
    const panel   = document.getElementById('notifPanel');
    const list    = document.getElementById('notifList');
    const markAll = document.getElementById('notifMarkAll');
    if (!btn) return;

    let ws, count = 0, loaded = false;

    function setBadge(n) {
        count = Math.max(0, n);
        badge.textContent = count > 99 ? '99+' : count;
        badge.style.display = count > 0 ? '' : 'none';
    }

    function esc(s) {
        return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
    }

    function buildItem(n) {
        const li = document.createElement('li');
        li.className = 'notif-item' + (n.lida ? '' : ' notif-unread');
        li.dataset.id = n.id;
        li.innerHTML = '<div class="notif-item-titulo">' + esc(n.titulo) + '</div>'
                     + '<div class="notif-item-msg">'    + esc(n.mensagem) + '</div>';
        li.addEventListener('click', function() {
            if (ws && ws.readyState === WebSocket.OPEN)
                ws.send(JSON.stringify({type:'mark_read', notif_id: n.id}));
            li.classList.remove('notif-unread');
        });
        return li;
    }

    function loadNotifs() {
        if (loaded) return;
        loaded = true;
        fetch('/api/utilizadores/' + USER_ID + '/notifications?limit=15', {
            headers: {'Authorization': 'Bearer ' + WS_TOKEN}
        })
        .then(function(r){ return r.json(); })
        .then(function(data) {
            list.innerHTML = '';
            if (!Array.isArray(data) || data.length === 0) {
                list.innerHTML = '<li class="notif-empty">Sem notificações</li>';
                return;
            }
            data.forEach(function(n){ list.appendChild(buildItem(n)); });
        })
        .catch(function(){ list.innerHTML = '<li class="notif-empty">Erro ao carregar</li>'; });
    }

    btn.addEventListener('click', function(e) {
        e.stopPropagation();
        var open = panel.style.display !== 'none';
        panel.style.display = open ? 'none' : '';
        if (!open) loadNotifs();
    });

    document.addEventListener('click', function(e) {
        var w = document.getElementById('notifWrapper');
        if (w && !w.contains(e.target)) panel.style.display = 'none';
    });

    markAll.addEventListener('click', function() {
        if (ws && ws.readyState === WebSocket.OPEN)
            ws.send(JSON.stringify({type:'mark_all_read'}));
        list.querySelectorAll('.notif-unread').forEach(function(el){ el.classList.remove('notif-unread'); });
        setBadge(0);
    });

    var proto = location.protocol === 'https:' ? 'wss:' : 'ws:';
    function connect() {
        ws = new WebSocket(proto + '//' + location.host + '/ws/chat?token=' + encodeURIComponent(WS_TOKEN));
        ws.onmessage = function(e) {
            try {
                var msg = JSON.parse(e.data);
                if (msg.type === 'notification_count') {
                    setBadge(msg.data.total);
                } else if (msg.type === 'notification') {
                    setBadge(count + 1);
                    if (panel.style.display !== 'none') {
                        var empty = list.querySelector('.notif-empty');
                        if (empty) empty.remove();
                        list.prepend(buildItem(msg.data));
                    } else {
                        loaded = false; // forçar reload próxima abertura
                    }
                }
            } catch(ex) {}
        };
        ws.onclose = function() { setTimeout(connect, 5000); };
    }
    connect();
})();
</script>
<?php endif; ?>
