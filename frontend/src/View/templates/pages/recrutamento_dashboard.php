<?php

$resp = $app->nexora->call('GET', '/api/recrutamento/dashboard');
$dash = $resp['body'] ?? [];

$pageTitle  = 'Recrutamento - Dashboard';
$activePage = 'recrutamento_dashboard';
$breadcrumb = [['Recrutamento', ''], ['Dashboard', '']];

include dirname(__DIR__) . '/layouts/top.php';

$funil       = $dash['funil'] ?? [];
$totalCandid = (int) ($dash['total_candidaturas'] ?? 0);
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Recrutamento</h1>
    <div class="adm-page-header-actions">
        <a href="<?= htmlspecialchars($app->routes->path('vaga_form')) ?>" class="adm-btn adm-btn-primary">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
            Nova Vaga
        </a>
    </div>
</div>

<!-- Indicadores principais -->
<div class="adm-grid adm-grid-4">
    <div class="adm-card">
        <div class="adm-stat">
            <div class="adm-stat-label">Total de Vagas</div>
            <div class="adm-stat-value"><?= (int) ($dash['total_vagas'] ?? 0) ?></div>
        </div>
    </div>
    <div class="adm-card">
        <div class="adm-stat">
            <div class="adm-stat-label">Vagas Ativas</div>
            <div class="adm-stat-value" style="color:var(--adm-green)"><?= (int) ($dash['vagas_ativas'] ?? 0) ?></div>
        </div>
    </div>
    <div class="adm-card">
        <div class="adm-stat">
            <div class="adm-stat-label">Total Candidaturas</div>
            <div class="adm-stat-value"><?= $totalCandid ?></div>
        </div>
    </div>
    <div class="adm-card">
        <div class="adm-stat">
            <div class="adm-stat-label">Candidaturas Hoje</div>
            <div class="adm-stat-value" style="color:var(--adm-blue)"><?= (int) ($dash['candidaturas_hoje'] ?? 0) ?></div>
        </div>
    </div>
</div>

<div class="adm-grid adm-grid-2" style="margin-top:var(--adm-sp-5)">
    <!-- Funil de candidaturas -->
    <div class="adm-card">
        <div class="adm-card-header">
            <h3 class="adm-card-title">Funil de Candidaturas</h3>
        </div>
        <div class="adm-card-body">
        <?php
        $etapas = [
            'recebida'   => ['label' => 'Recebidas',    'badge' => 'adm-badge--blue'],
            'em_analise' => ['label' => 'Em Análise',   'badge' => 'adm-badge--yellow'],
            'entrevista' => ['label' => 'Entrevista',   'badge' => 'adm-badge--purple'],
            'aprovada'   => ['label' => 'Aprovadas',    'badge' => 'adm-badge--green'],
            'rejeitada'  => ['label' => 'Rejeitadas',   'badge' => 'adm-badge--red'],
        ];
        $maxVal = max(1, max(array_values($funil) ?: [0]));
        foreach ($etapas as $key => $info):
            $count = (int) ($funil[$key] ?? 0);
            $pct   = round($count / $maxVal * 100);
        ?>
        <div style="margin-bottom:var(--adm-sp-3)">
            <div class="adm-flex-between" style="margin-bottom:.3rem">
                <span class="adm-text-sm adm-fw-600"><?= $info['label'] ?></span>
                <span class="adm-badge <?= $info['badge'] ?>"><?= $count ?></span>
            </div>
            <div style="background:var(--adm-surface-alt);border-radius:4px;height:7px;overflow:hidden">
                <div style="width:<?= $pct ?>%;height:100%;background:var(--adm-blue);border-radius:4px;transition:width .4s ease"></div>
            </div>
        </div>
        <?php endforeach; ?>
        <div class="adm-text-muted adm-text-sm" style="margin-top:var(--adm-sp-4);padding-top:var(--adm-sp-3);border-top:1px solid var(--adm-gray-100)">
            Taxa de aprovação: <strong style="color:var(--adm-green-dark)"><?= number_format((float)($dash['taxa_aprovacao'] ?? 0), 1) ?>%</strong>
        </div>
        </div>
    </div>

    <!-- Prazos próximos -->
    <div class="adm-card">
        <div class="adm-card-header">
            <h3 class="adm-card-title">Prazos nos Próximos 7 Dias</h3>
            <div class="adm-card-actions">
                <a href="<?= htmlspecialchars($app->routes->path('vagas')) ?>" class="adm-btn adm-btn-ghost adm-btn-sm">Ver todas</a>
            </div>
        </div>
        <div class="adm-card-body" style="padding-top:0">
        <?php $prazos = $dash['prazos_proximos'] ?? []; ?>
        <?php if ($prazos): ?>
        <ul class="adm-list">
            <?php foreach ($prazos as $p): ?>
            <li>
                <div>
                    <div class="adm-fw-600"><?= htmlspecialchars($p['titulo']) ?></div>
                    <div class="adm-text-muted adm-text-sm"><?= htmlspecialchars($p['area']) ?></div>
                </div>
                <span class="adm-badge <?= $p['dias'] <= 2 ? 'adm-badge--red' : 'adm-badge--yellow' ?>">
                    <?= $p['dias'] == 0 ? 'Hoje!' : $p['dias'] . ' dia' . ($p['dias'] != 1 ? 's' : '') ?>
                </span>
            </li>
            <?php endforeach; ?>
        </ul>
        <?php else: ?>
        <div class="adm-empty" style="padding:var(--adm-sp-6) 0">
            <p class="adm-empty-title">Sem prazos urgentes</p>
        </div>
        <?php endif; ?>
        </div>
    </div>
</div>

<!-- Candidaturas recentes -->
<div class="adm-card" style="margin-top:var(--adm-sp-5)">
    <div class="adm-card-header">
        <h3 class="adm-card-title">Candidaturas Recentes</h3>
        <div class="adm-card-actions">
            <a href="<?= htmlspecialchars($app->routes->path('candidaturas')) ?>" class="adm-btn adm-btn-ghost adm-btn-sm">Ver todas</a>
        </div>
    </div>
    <?php $recentes = $dash['recentes'] ?? []; ?>
    <?php if ($recentes): ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr>
                    <th>Candidato</th>
                    <th>Vaga</th>
                    <th>Estado</th>
                    <th>Data</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($recentes as $c):
                $estadoBadge = match ($c['estado'] ?? '') {
                    'recebida'   => ['adm-badge--blue',   'Recebida'],
                    'em_analise' => ['adm-badge--yellow', 'Em Análise'],
                    'entrevista' => ['adm-badge--purple', 'Entrevista'],
                    'aprovada'   => ['adm-badge--green',  'Aprovada'],
                    'rejeitada'  => ['adm-badge--red',    'Rejeitada'],
                    default      => ['adm-badge--gray',   $c['estado'] ?? '—'],
                };
            ?>
            <tr>
                <td>
                    <div class="adm-fw-600"><?= htmlspecialchars($c['nome'] ?? '') ?></div>
                    <div class="adm-text-muted adm-text-sm"><?= htmlspecialchars($c['email'] ?? '') ?></div>
                </td>
                <td><?= htmlspecialchars($c['vaga_titulo'] ?? '—') ?></td>
                <td><span class="adm-badge <?= $estadoBadge[0] ?>"><?= $estadoBadge[1] ?></span></td>
                <td class="adm-text-muted"><?= !empty($c['created_at']) ? date('d/m/Y H:i', strtotime($c['created_at'])) : '—' ?></td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="adm-empty" style="padding:var(--adm-sp-10)">
        <p class="adm-empty-title">Nenhuma candidatura recebida ainda.</p>
    </div>
    <?php endif; ?>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
