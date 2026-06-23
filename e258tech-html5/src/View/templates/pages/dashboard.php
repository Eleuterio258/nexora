<?php

// ── Módulos acessíveis pelo utilizador actual (via permissões sincronizadas com a API) ──
$todosModulos = require dirname(__DIR__) . '/partials/modules.php';

// Filtra apenas os módulos que o utilizador tem acesso (canModule) e que têm rota
$moduloRotaMap = [
    'recrutamento'         => ['rota' => 'dashboard',              'label' => 'Recrutamento',          'icon' => 'fa-briefcase'],
    'crm'                  => ['rota' => 'leads',                  'label' => 'CRM',                   'icon' => 'fa-handshake'],
    'clientes'             => ['rota' => 'clientes',               'label' => 'Clientes',              'icon' => 'fa-user-tie'],
    'faturacao'            => ['rota' => 'faturas',                'label' => 'Faturação',             'icon' => 'fa-file-invoice-dollar'],
    'pos'                  => ['rota' => 'pos',                    'label' => 'POS',                   'icon' => 'fa-cash-register'],
    'stock'                => ['rota' => 'stock',                  'label' => 'Stock',                 'icon' => 'fa-warehouse'],
    'compras'              => ['rota' => 'compras',                'label' => 'Compras',               'icon' => 'fa-cart-shopping'],
    'logistica'            => ['rota' => 'logistica',              'label' => 'Logística',             'icon' => 'fa-truck'],
    'financeiro'           => ['rota' => 'financeiro',             'label' => 'Financeiro',            'icon' => 'fa-coins'],
    'tesouraria'           => ['rota' => 'tesouraria',             'label' => 'Tesouraria',            'icon' => 'fa-building-columns'],
    'contabilidade'        => ['rota' => 'contab_plano_contas',   'label' => 'Contabilidade',         'icon' => 'fa-book'],
    'impostos'             => ['rota' => 'impostos_avancados',    'label' => 'Impostos',              'icon' => 'fa-percent'],
    'multi-moeda'          => ['rota' => 'multi_moeda',           'label' => 'Multi-Moeda',           'icon' => 'fa-globe'],
    'centros-custo'        => ['rota' => 'centros_custo',         'label' => 'Centros de Custo',      'icon' => 'fa-building'],
    'recursos-humanos'     => ['rota' => 'rh_funcionarios',       'label' => 'Recursos Humanos',      'icon' => 'fa-person-chalkboard'],
    'gestao-escolar'       => ['rota' => 'escolar_dashboard',     'label' => 'Gestão Escolar',        'icon' => 'fa-graduation-cap'],
    'assinaturas'          => ['rota' => 'assinaturas',           'label' => 'Assinaturas',           'icon' => 'fa-file-contract'],
    'notificacoes'         => ['rota' => 'notificacoes',          'label' => 'Notificações',          'icon' => 'fa-bell'],
    'seguranca'            => ['rota' => 'seguranca',             'label' => 'Segurança',             'icon' => 'fa-shield-halved'],
    'sistema-configuracao' => ['rota' => 'sistema_geral',         'label' => 'Sistema',               'icon' => 'fa-gear'],
    'autorizacao'          => ['rota' => 'utilizadores',          'label' => 'Utilizadores',          'icon' => 'fa-users'],
    'empresa'              => ['rota' => 'empresa',               'label' => 'Empresa & Licença',     'icon' => 'fa-building'],
    'auditoria'            => ['rota' => 'auditoria',             'label' => 'Auditoria',             'icon' => 'fa-clipboard-list'],
    // Self-service
    'chat'                 => ['rota' => 'chat',                  'label' => 'Chat',                  'icon' => 'fa-comments'],
    'pedido-ferias'        => ['rota' => 'pedido_ferias',         'label' => 'Pedido de Férias',      'icon' => 'fa-umbrella-beach'],
    'assiduidade'          => ['rota' => 'minha_assiduidade',     'label' => 'Assiduidade',           'icon' => 'fa-clock'],
    'perfil'               => ['rota' => 'meu_perfil',            'label' => 'Meu Perfil',            'icon' => 'fa-user-circle'],
];

$modulosAcessiveis = [];
foreach ($moduloRotaMap as $modKey => $info) {
    if ($app->session->canModule($modKey)) {
        $cor = $todosModulos[$modKey]['cor'] ?? '#64748B';
        $modulosAcessiveis[$modKey] = $info + ['cor' => $cor];
    }
}

// ── Bloco de recrutamento (só se tiver permissão) ────────────────────────────
$dash = [];
if ($app->session->canModule('recrutamento')) {
    $resp = $app->nexora->call('GET', '/api/recrutamento/dashboard');
    if ($resp['status'] === 200 && is_array($resp['body'])) {
        $dash = $resp['body'];
    }
}

$totalVagas  = (int) ($dash['total_vagas'] ?? 0);
$vagasAtivas = (int) ($dash['vagas_ativas'] ?? 0);
$totalCandid = (int) ($dash['total_candidaturas'] ?? 0);
$taxaAprov   = $dash['taxa_aprovacao'] ?? 0;
$funnel      = array_fill_keys(['recebida','em_analise','entrevista','aprovada','rejeitada'], 0);
foreach ($dash['funil'] ?? [] as $k => $n) { if (isset($funnel[$k])) $funnel[$k] = (int)$n; }
$novasCandid = $funnel['recebida'];
$funnelMax   = max(array_sum($funnel), 1);
$recentes    = $dash['recentes'] ?? [];
$prazosProximos = $dash['prazos_proximos'] ?? [];

// ── Info do utilizador ────────────────────────────────────────────────────────
$loggedUser = $app->session->user();
$adminNome  = $loggedUser['nome'] ?? $loggedUser['email'] ?? 'Utilizador';
$hora       = (int) date('H');
$saudacao   = $hora < 12 ? 'Bom dia' : ($hora < 18 ? 'Boa tarde' : 'Boa noite');

$pageTitle  = 'Dashboard';
$activePage = 'dashboard';
$breadcrumb = [['Admin', '/nexora/'], ['Dashboard', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<!-- Boas-vindas -->
<div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:var(--adm-sp-6)">
    <div>
        <h1 class="adm-page-title" style="margin-bottom:var(--adm-sp-1)">
            <?= $saudacao ?>, <?= htmlspecialchars(explode(' ', $adminNome)[0]) ?>!
        </h1>
        <p class="adm-text-sm adm-text-muted">
            <?= date('l, d \d\e F \d\e Y') ?>
            · <?= count($modulosAcessiveis) ?> módulo<?= count($modulosAcessiveis) !== 1 ? 's' : '' ?> disponíve<?= count($modulosAcessiveis) !== 1 ? 'is' : 'l' ?>
        </p>
    </div>
</div>

<?php if ($app->session->canModule('recrutamento')): ?>
<!-- ── Stats de Recrutamento ─────────────────────────────────────────────── -->
<div class="adm-stats-grid" style="margin-bottom:var(--adm-sp-6)">
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--green"><i class="fa-solid fa-briefcase" style="font-size:1rem"></i></div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= $vagasAtivas ?></div>
            <div class="adm-stat-label">Vagas Abertas</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--blue"><i class="fa-solid fa-users" style="font-size:1rem"></i></div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= $totalCandid ?></div>
            <div class="adm-stat-label">Candidaturas</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--yellow"><i class="fa-solid fa-bell" style="font-size:1rem"></i></div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= $novasCandid ?></div>
            <div class="adm-stat-label">Novas</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--red"><i class="fa-solid fa-chart-line" style="font-size:1rem"></i></div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= $taxaAprov ?>%</div>
            <div class="adm-stat-label">Taxa Aprovação</div>
        </div>
    </div>
</div>
<?php endif; ?>

<!-- ── Grelha de Módulos Acessíveis ─────────────────────────────────────── -->
<?php if (!empty($modulosAcessiveis)): ?>
<div class="adm-section-header" style="margin-bottom:var(--adm-sp-4)">
    <h2 class="adm-section-title">Os meus módulos</h2>
</div>
<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:var(--adm-sp-4);margin-bottom:var(--adm-sp-8)">
    <?php foreach ($modulosAcessiveis as $key => $mod): ?>
    <?php
        try { $href = $app->routes->path($mod['rota']); } catch (\Exception $e) { continue; }
    ?>
    <a href="<?= htmlspecialchars($href) ?>"
       class="adm-module-card"
       style="--adm-module-color:<?= htmlspecialchars($mod['cor']) ?>40">
        <div class="adm-module-card-icon"
             style="background:<?= htmlspecialchars($mod['cor']) ?>18">
            <i class="fa-solid <?= htmlspecialchars($mod['icon']) ?>"
               style="font-size:1.05rem;color:<?= htmlspecialchars($mod['cor']) ?>"></i>
        </div>
        <span class="adm-module-card-label">
            <?= htmlspecialchars($mod['label']) ?>
        </span>
    </a>
    <?php endforeach; ?>
</div>
<?php elseif (!$app->session->isSuperAdmin()): ?>
<div class="adm-empty" style="padding:var(--adm-sp-12)">
    <i class="fa-solid fa-lock" style="font-size:2rem;opacity:.2"></i>
    <p class="adm-empty-title">Sem módulos atribuídos</p>
    <p class="adm-text-sm adm-text-muted">Contacte o administrador para obter acesso aos módulos do sistema.</p>
</div>
<?php endif; ?>

<?php if ($app->session->canModule('recrutamento') && (!empty($recentes) || !empty($prazosProximos))): ?>
<!-- ── Candidaturas recentes + Prazos ────────────────────────────────────── -->
<div style="display:grid;grid-template-columns:1fr 280px;gap:var(--adm-sp-6);align-items:start">

    <div class="adm-section">
        <div class="adm-section-header">
            <h2 class="adm-section-title">Candidaturas Recentes</h2>
            <div class="adm-card-actions">
                <a href="/nexora/recrutamento/candidaturas" class="adm-btn adm-btn-outline adm-btn-sm">Ver todas</a>
            </div>
        </div>
        <?php if ($recentes): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead><tr><th>Candidato</th><th>Vaga</th><th>Estado</th><th>Data</th><th></th></tr></thead>
                <tbody>
                <?php foreach (array_slice($recentes, 0, 5) as $c):
                    $eb = match($c['estado'] ?? '') {
                        'em_analise' => ['adm-badge--blue','Em Análise'],
                        'entrevista' => ['adm-badge--indigo','Entrevista'],
                        'aprovada'   => ['adm-badge--green','Aprovada'],
                        'rejeitada'  => ['adm-badge--red','Rejeitada'],
                        default      => ['adm-badge--yellow','Recebida'],
                    }; ?>
                <tr>
                    <td>
                        <div class="adm-fw-600 adm-truncate" style="max-width:150px"><?= htmlspecialchars($c['nome'] ?? '') ?></div>
                        <div class="adm-text-xs adm-text-muted"><?= htmlspecialchars($c['email'] ?? '') ?></div>
                    </td>
                    <td class="adm-truncate" style="max-width:130px"><?= htmlspecialchars($c['vaga_titulo'] ?? '—') ?></td>
                    <td><span class="adm-badge <?= $eb[0] ?>"><?= $eb[1] ?></span></td>
                    <td class="adm-text-muted"><?= !empty($c['created_at']) ? date('d/m/y', strtotime($c['created_at'])) : '—' ?></td>
                    <td>
                        <a href="/nexora/recrutamento/candidaturas/ver?id=<?= (int)($c['id'] ?? 0) ?>" class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon">
                            <i class="fa-solid fa-eye"></i>
                        </a>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty"><p class="adm-empty-title">Sem candidaturas ainda</p></div>
        <?php endif; ?>
    </div>

    <div class="adm-section">
        <div class="adm-section-header"><h2 class="adm-section-title">Prazos a Vencer</h2></div>
        <?php if ($prazosProximos): ?>
        <?php foreach ($prazosProximos as $v): ?>
        <div style="display:flex;align-items:center;gap:var(--adm-sp-3);padding:var(--adm-sp-3) 0;border-bottom:1px solid var(--adm-gray-100)">
            <div style="flex:1;min-width:0">
                <div class="adm-fw-600 adm-truncate"><?= htmlspecialchars($v['titulo']) ?></div>
                <div class="adm-text-xs adm-text-muted"><?= htmlspecialchars($v['area']) ?></div>
            </div>
            <span class="adm-badge <?= $v['dias'] <= 1 ? 'adm-badge--red' : ($v['dias'] <= 3 ? 'adm-badge--yellow' : 'adm-badge--blue') ?>">
                <?= $v['dias'] === 0 ? 'Hoje!' : $v['dias'] . 'd' ?>
            </span>
        </div>
        <?php endforeach; ?>
        <div style="padding-top:var(--adm-sp-3)">
            <a href="/nexora/recrutamento/vagas" class="adm-btn adm-btn-outline adm-btn-sm" style="width:100%;justify-content:center">
                Gerir vagas (<?= $totalVagas ?>)
            </a>
        </div>
        <?php else: ?>
        <div class="adm-empty" style="padding:var(--adm-sp-6)">
            <p class="adm-empty-title">Sem prazos urgentes</p>
        </div>
        <?php endif; ?>
    </div>
</div>
<?php endif; ?>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
