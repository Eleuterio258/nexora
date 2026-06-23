<?php

    $unidades = $app->nexora->call('GET', '/api/rh/unidades')['body'] ?? [];

    $tipoUnidadeLabels = [
        'departamento' => 'Departamento',
        'equipa'       => 'Equipa',
        'divisao'      => 'Divisão',
        'seccao'       => 'Secção',
        'direccao'     => 'Direção',
        'gabinete'     => 'Gabinete',
        'projeto'      => 'Projeto',
        'outro'        => 'Outro',
    ];

    $byParent = [];
    foreach ($unidades as $u) {
        $byParent[$u['parent_id'] ?? 0][] = $u;
    }

    function renderUnidadeNode(array $u, array $byParent, array $tipoUnidadeLabels): void
    {
        $children = $byParent[$u['id']] ?? [];
        ?>
        <li class="adm-tree-node">
            <div class="adm-tree-card">
                <div class="adm-tree-card-title"><?php echo htmlspecialchars($u['nome']) ?></div>
                <div class="adm-tree-card-meta">
                    <span class="adm-badge adm-badge--gray"><?php echo htmlspecialchars($tipoUnidadeLabels[$u['tipo']] ?? $u['tipo']) ?></span>
                    <?php if (!empty($u['responsavel_nome'])): ?>
                    <span class="adm-text-muted adm-text-xs"><?php echo htmlspecialchars($u['responsavel_nome']) ?></span>
                    <?php endif; ?>
                    <span class="adm-text-muted adm-text-xs"><?php echo (int) $u['num_funcionarios'] ?> func.</span>
                </div>
            </div>
            <?php if ($children): ?>
            <ul class="adm-tree-children">
                <?php foreach ($children as $c) renderUnidadeNode($c, $byParent, $tipoUnidadeLabels); ?>
            </ul>
            <?php endif; ?>
        </li>
        <?php
    }

    $pageTitle  = 'Organograma';
    $activePage = 'rh_organograma';
    $breadcrumb = [['Admin', '/nexora/'], ['Recursos Humanos', ''], ['Organograma', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Organograma</h1>
</div>

<div class="adm-card">
    <?php if ($unidades): ?>
    <div class="adm-tree-wrap">
        <ul class="adm-tree adm-tree-root">
            <?php foreach ($byParent[0] ?? [] as $raiz) renderUnidadeNode($raiz, $byParent, $tipoUnidadeLabels); ?>
        </ul>
    </div>
    <?php else: ?>
    <div class="adm-empty">
        <p class="adm-empty-title">Nenhuma unidade organizacional registada</p>
        <p class="adm-empty-sub">Adicione unidades organizacionais para visualizar o organograma.</p>
    </div>
    <?php endif; ?>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
