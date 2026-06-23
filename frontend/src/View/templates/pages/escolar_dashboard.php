<?php
declare(strict_types=1);

$pageTitle  = 'Dashboard Escolar';
$activePage = 'escolar_dashboard';
$breadcrumb = [['Admin', '/nexora/'], ['Gestão Escolar', '/nexora/gestao-escolar/dashboard'], ['Dashboard', '']];

try {
    $raw = $app->nexora->call('GET', '/api/escolar/dashboard/direction')['body'] ?? [];
} catch (\Throwable) {
    $raw = [];
}

$ind = [];
foreach ((array) $raw as $row) {
    $key       = $row['indicador'] ?? $row['nome'] ?? '';
    $ind[$key] = (int) ($row['valor'] ?? $row['total'] ?? 0);
}

$g = static fn(string ...$keys): int => (int) max(array_map(fn($k) => $ind[$k] ?? 0, $keys));

$r = $app->routes;

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Dashboard Escolar</h1>
</div>

<!-- Stats -->
<div class="adm-stats-grid" style="margin-bottom:var(--adm-sp-8)">
<?php
$statCards = [
    ['num' => $g('Anos lectivos','anos_lectivos'), 'label' => 'Anos Lectivos',  'route' => 'escolar_anos_lectivos',  'icon' => 'fa-solid fa-calendar-days',       'bg' => '#eff6ff', 'color' => '#2563eb'],
    ['num' => $g('Alunos','alunos'),               'label' => 'Alunos',         'route' => 'escolar_alunos',         'icon' => 'fa-solid fa-user-graduate',        'bg' => '#f0fdf4', 'color' => '#16a34a'],
    ['num' => $g('Turmas','turmas'),               'label' => 'Turmas',         'route' => 'escolar_turmas',         'icon' => 'fa-solid fa-people-group',         'bg' => '#faf5ff', 'color' => '#7c3aed'],
    ['num' => $g('Cobranças','cobrancas'),          'label' => 'Cobranças',      'route' => 'escolar_cobrancas',      'icon' => 'fa-solid fa-file-invoice-dollar',  'bg' => '#fffbeb', 'color' => '#d97706'],
    ['num' => $g('Inadimplência','inadimplencia'),  'label' => 'Inadimplência',  'route' => 'escolar_inadimplencia',  'icon' => 'fa-solid fa-triangle-exclamation', 'bg' => '#fef2f2', 'color' => '#dc2626'],
];
?>
<?php foreach ($statCards as $card): ?>
<a href="<?= htmlspecialchars($r->path($card['route'])) ?>" class="escolar-stat-card">
    <div class="escolar-stat-icon" style="background:<?= $card['bg'] ?>;color:<?= $card['color'] ?>">
        <i class="<?= $card['icon'] ?>" style="font-size:1.1rem"></i>
    </div>
    <div class="escolar-stat-num" style="color:<?= $card['color'] ?>"><?= $card['num'] ?></div>
    <div class="escolar-stat-label"><?= $card['label'] ?></div>
</a>
<?php endforeach; ?>
</div>

<!-- Secções -->
<div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:var(--adm-sp-6);align-items:start">

    <!-- Académico -->
    <div class="adm-section">
        <div class="adm-section-header">
            <h2 class="adm-section-title">Académico</h2>
        </div>
        <?php
        $academico = [
            ['Turmas',       'turmas',       'escolar_turmas'],
            ['Disciplinas',  'disciplinas',  'escolar_disciplinas'],
            ['Matrículas',   'matriculas',   'escolar_matriculas'],
            ['Atribuições',  'atribuicoes',  'escolar_atribuicoes'],
            ['Frequência',   'frequencia',   'escolar_frequencia'],
            ['Avaliações',   'avaliacoes',   'escolar_avaliacoes'],
        ];
        foreach ($academico as [$label, $key, $route]): ?>
        <div style="display:flex;align-items:center;justify-content:space-between;padding:var(--adm-sp-3) 0;border-bottom:1px solid var(--adm-gray-100)">
            <a href="<?= htmlspecialchars($r->path($route)) ?>" class="adm-text-sm adm-link"><?= $label ?></a>
            <span class="adm-badge adm-badge--gray"><?= $g($label, $key) ?></span>
        </div>
        <?php endforeach; ?>
        <div style="padding-top:var(--adm-sp-4)">
            <a href="<?= htmlspecialchars($r->path('escolar_anos_lectivos')) ?>" class="adm-btn adm-btn-outline adm-btn-sm" style="width:100%;justify-content:center">
                Anos Lectivos (<?= $g('Anos lectivos','anos_lectivos') ?>)
            </a>
        </div>
    </div>

    <!-- Financeiro -->
    <div class="adm-section">
        <div class="adm-section-header">
            <h2 class="adm-section-title">Financeiro</h2>
        </div>
        <?php
        $financeiro = [
            ['Planos de cobrança', 'planos_cobranca',  'escolar_planos_cobranca'],
            ['Cobranças',          'cobrancas',         'escolar_cobrancas'],
            ['Pagamentos',         'pagamentos',        'escolar_pagamentos'],
            ['Resumo financeiro',  'resumo_financeiro', 'escolar_resumo_financeiro'],
            ['Inadimplência',      'inadimplencia',     'escolar_inadimplencia'],
        ];
        foreach ($financeiro as [$label, $key, $route]): ?>
        <div style="display:flex;align-items:center;justify-content:space-between;padding:var(--adm-sp-3) 0;border-bottom:1px solid var(--adm-gray-100)">
            <a href="<?= htmlspecialchars($r->path($route)) ?>" class="adm-text-sm adm-link"><?= $label ?></a>
            <span class="adm-badge <?= $label === 'Inadimplência' && $g($label,$key) > 0 ? 'adm-badge--red' : 'adm-badge--gray' ?>"><?= $g($label, $key) ?></span>
        </div>
        <?php endforeach; ?>
        <div style="padding-top:var(--adm-sp-4)">
            <a href="<?= htmlspecialchars($r->path('escolar_resumo_academico')) ?>" class="adm-btn adm-btn-outline adm-btn-sm" style="width:100%;justify-content:center">
                Ver resumo académico
            </a>
        </div>
    </div>

    <!-- Outros -->
    <div class="adm-section">
        <div class="adm-section-header">
            <h2 class="adm-section-title">Biblioteca & Comunicação</h2>
        </div>
        <?php
        $outros = [
            ['Livros',       'livros',       'escolar_biblioteca'],
            ['Empréstimos',  'emprestimos',  'escolar_emprestimos'],
            ['Comunicação',  'comunicacao',  'escolar_comunicacao'],
        ];
        foreach ($outros as [$label, $key, $route]): ?>
        <div style="display:flex;align-items:center;justify-content:space-between;padding:var(--adm-sp-3) 0;border-bottom:1px solid var(--adm-gray-100)">
            <a href="<?= htmlspecialchars($r->path($route)) ?>" class="adm-text-sm adm-link"><?= $label ?></a>
            <span class="adm-badge adm-badge--gray"><?= $g($label, $key) ?></span>
        </div>
        <?php endforeach; ?>
        <div style="padding-top:var(--adm-sp-4);display:flex;flex-direction:column;gap:var(--adm-sp-2)">
            <a href="<?= htmlspecialchars($r->path('escolar_boletins')) ?>" class="adm-btn adm-btn-outline adm-btn-sm" style="width:100%;justify-content:center">Boletins</a>
            <a href="<?= htmlspecialchars($r->path('escolar_notas')) ?>" class="adm-btn adm-btn-outline adm-btn-sm" style="width:100%;justify-content:center">Notas (<?= $g('Notas','notas') ?>)</a>
        </div>
    </div>

</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
