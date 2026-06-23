<?php

    $filtroCategoria = $app->request->queryInt('categoria_id', 0) ?: 0;
    $filtroMarca     = $app->request->queryInt('marca_id', 0) ?: 0;
    $filtroTipo      = $app->request->queryEnum('tipo', ['simples', 'variavel', 'kit', 'servico']);
    $filtroAtivo     = $app->request->queryEnum('ativo', ['true', 'false']);

    $query = ['limit' => 100];
    if ($filtroCategoria)    $query['categoria_id'] = $filtroCategoria;
    if ($filtroMarca)        $query['marca_id']     = $filtroMarca;
    if ($filtroTipo)         $query['tipo']         = $filtroTipo;
    if ($filtroAtivo !== '') $query['ativo']        = $filtroAtivo;

    $resp     = $app->nexora->call('GET', '/api/produtos', null, $query);
    $produtos = $resp['body']['data'] ?? [];

    $categoriasResp = $app->nexora->call('GET', '/api/produtos/categorias');
    $categorias     = $categoriasResp['body'] ?? [];
    $categoriaNomes = array_column($categorias, 'nome', 'id');

    $marcasResp = $app->nexora->call('GET', '/api/produtos/marcas');
    $marcas     = $marcasResp['body'] ?? [];
    $marcaNomes = array_column($marcas, 'nome', 'id');

    $tipoLabels = [
        'simples'  => 'Simples',
        'variavel' => 'Variável',
        'kit'      => 'Kit',
        'servico'  => 'Serviço',
    ];

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Produtos';
    $activePage = 'produtos';
    $breadcrumb = [['Admin', '/nexora/'], ['Produtos', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Produtos</h1>
    <div class="adm-page-header-actions">
        <a href="<?php echo htmlspecialchars($app->routes->path('produto_categorias')) ?>" class="adm-btn adm-btn-outline">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"/>
                <line x1="7" y1="7" x2="7.01" y2="7"/>
            </svg>
            Categorias / Marcas / Unidades
        </a>
        <a href="<?php echo htmlspecialchars($app->routes->path('produto_form')) ?>" class="adm-btn adm-btn-primary">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
            Novo Produto
        </a>
    </div>
</div>

<div class="adm-card">
    <div class="adm-filter-bar">
        <div class="adm-search-wrap">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
            </svg>
            <input class="adm-input" type="search" id="produtoSearch" placeholder="Pesquisar produtos…" oninput="filterTable()">
        </div>
        <select class="adm-select" id="produtoCategoria" onchange="filterTable()" style="width:180px">
            <option value="">Todas as categorias</option>
            <?php foreach ($categorias as $c): ?>
            <option value="<?php echo $c['id'] ?>" <?php echo $filtroCategoria === (int) $c['id'] ? 'selected' : '' ?>><?php echo htmlspecialchars($c['nome']) ?></option>
            <?php endforeach; ?>
        </select>
        <select class="adm-select" id="produtoMarca" onchange="filterTable()" style="width:180px">
            <option value="">Todas as marcas</option>
            <?php foreach ($marcas as $m): ?>
            <option value="<?php echo $m['id'] ?>" <?php echo $filtroMarca === (int) $m['id'] ? 'selected' : '' ?>><?php echo htmlspecialchars($m['nome']) ?></option>
            <?php endforeach; ?>
        </select>
        <select class="adm-select" id="produtoTipo" onchange="filterTable()" style="width:140px">
            <option value="">Todos os tipos</option>
            <?php foreach ($tipoLabels as $key => $label): ?>
            <option value="<?php echo $key ?>" <?php echo $filtroTipo === $key ? 'selected' : '' ?>><?php echo $label ?></option>
            <?php endforeach; ?>
        </select>
        <select class="adm-select" id="produtoAtivo" onchange="filterTable()" style="width:140px">
            <option value="">Todos os estados</option>
            <option value="true" <?php echo $filtroAtivo === 'true' ? 'selected' : '' ?>>Ativo</option>
            <option value="false" <?php echo $filtroAtivo === 'false' ? 'selected' : '' ?>>Inativo</option>
        </select>
        <span class="adm-filter-count" id="produtoCount"><?php echo count($produtos) ?> produtos</span>
    </div>

    <?php if ($produtos): ?>
    <div class="adm-table-wrap">
        <table class="adm-table" id="produtosTable">
            <thead>
                <tr>
                    <th>Código</th>
                    <th>Nome</th>
                    <th>Tipo</th>
                    <th>Categoria</th>
                    <th>Marca</th>
                    <th>IVA %</th>
                    <th>Estado</th>
                    <th>Ações</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($produtos as $p):
                    $categoriaNome = $categoriaNomes[$p['product_category_id']] ?? null;
                    $marcaNome     = $marcaNomes[$p['product_brand_id']] ?? null;
            ?>
            <tr data-categoria="<?php echo (int) ($p['product_category_id'] ?? 0) ?>" data-marca="<?php echo (int) ($p['product_brand_id'] ?? 0) ?>" data-tipo="<?php echo htmlspecialchars($p['tipo']) ?>" data-ativo="<?php echo $p['ativo'] ? 'true' : 'false' ?>">
                <td class="adm-text-muted"><?php echo htmlspecialchars($p['codigo']) ?></td>
                <td class="adm-fw-600"><?php echo htmlspecialchars($p['nome']) ?></td>
                <td><?php echo $tipoLabels[$p['tipo']] ?? htmlspecialchars($p['tipo']) ?></td>
                <td><?php echo $categoriaNome ? htmlspecialchars($categoriaNome) : '—' ?></td>
                <td><?php echo $marcaNome ? htmlspecialchars($marcaNome) : '—' ?></td>
                <td><?php echo number_format((float) $p['iva_percentual'], 2, ',', '.') ?></td>
                <td><span class="adm-badge <?php echo $p['ativo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $p['ativo'] ? 'Ativo' : 'Inativo' ?></span></td>
                <td>
                    <div class="adm-actions">
                        <a href="<?php echo htmlspecialchars($app->routes->path('produto_form', ['id' => $p['id']])) ?>" class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Ver / Editar">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                            </svg>
                        </a>
                    </div>
                </td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="adm-empty">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/>
            <polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/>
        </svg>
        <p class="adm-empty-title">Nenhum produto criado</p>
        <p class="adm-empty-sub">Começa por criar o primeiro produto do catálogo.</p>
        <a href="<?php echo htmlspecialchars($app->routes->path('produto_form')) ?>" class="adm-btn adm-btn-primary">Criar Produto</a>
    </div>
    <?php endif; ?>
</div>

<script>
function filterTable() {
    const q        = document.getElementById('produtoSearch').value.toLowerCase();
    const categoria = document.getElementById('produtoCategoria').value;
    const marca    = document.getElementById('produtoMarca').value;
    const tipo     = document.getElementById('produtoTipo').value;
    const ativo    = document.getElementById('produtoAtivo').value;
    const rows     = document.querySelectorAll('#produtosTable tbody tr');
    let vis = 0;
    rows.forEach(row => {
        const txt = row.textContent.toLowerCase();
        const show = (!q || txt.includes(q))
            && (!categoria || row.dataset.categoria === categoria)
            && (!marca || row.dataset.marca === marca)
            && (!tipo || row.dataset.tipo === tipo)
            && (!ativo || row.dataset.ativo === ativo);
        row.style.display = show ? '' : 'none';
        if (show) vis++;
    });
    document.getElementById('produtoCount').textContent = vis + ' produto' + (vis !== 1 ? 's' : '');
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
