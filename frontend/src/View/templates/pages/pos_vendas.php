<?php

    $filtroEstado = $app->request->queryEnum('status', ['concluida', 'cancelada', 'rascunho']);

    $query = ['limit' => 100];
    if ($filtroEstado) {
        $query['status'] = $filtroEstado;
    }

    $resp   = $app->nexora->call('GET', '/api/pos/sales', null, $query);
    $vendas = $resp['body']['data'] ?? [];

    $termResp  = $app->nexora->call('GET', '/api/pos/terminais');
    $terminais = $termResp['body'] ?? [];
    $terminalMap = [];
    foreach ($terminais as $t) {
        $terminalMap[(int) $t['id']] = $t;
    }

    $estadoBadges = [
        'concluida' => ['adm-badge--green', 'Concluída'],
        'cancelada' => ['adm-badge--red',   'Cancelada'],
        'rascunho'  => ['adm-badge--gray',  'Rascunho'],
    ];

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Vendas POS';
    $activePage = 'pos_vendas';
    $breadcrumb = [['Admin', '/nexora/'], ['POS', ''], ['Vendas', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Vendas POS</h1>
</div>

<div class="adm-card">
    <div class="adm-filter-bar">
        <div class="adm-search-wrap">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
            </svg>
            <input class="adm-input" type="search" id="vendaSearch" placeholder="Pesquisar vendas…" oninput="filterTable()">
        </div>
        <select class="adm-select" id="vendaEstado" onchange="filterTable()" style="width:180px">
            <option value="">Todos os estados</option>
            <?php foreach ($estadoBadges as $key => [$cls, $label]): ?>
            <option value="<?php echo $key ?>" <?php echo $filtroEstado === $key ? 'selected' : '' ?>><?php echo $label ?></option>
            <?php endforeach; ?>
        </select>
        <span class="adm-filter-count" id="vendaCount"><?php echo count($vendas) ?> vendas</span>
    </div>

    <?php if ($vendas): ?>
    <div class="adm-table-wrap">
        <table class="adm-table" id="vendasTable">
            <thead>
                <tr>
                    <th>Número</th>
                    <th>Terminal</th>
                    <th>Data</th>
                    <th>Total</th>
                    <th>Troco</th>
                    <th>Estado</th>
                    <th>Ações</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($vendas as $v):
                    $estadoBadge = $estadoBadges[$v['status']] ?? ['adm-badge--gray', $v['status']];
                    $terminal    = $terminalMap[(int) $v['terminal_id']] ?? null;
                    $terminalLbl = $terminal ? $terminal['codigo'] . ' - ' . $terminal['nome'] : ('#' . $v['terminal_id']);
            ?>
            <tr data-estado="<?php echo htmlspecialchars($v['status']) ?>">
                <td class="adm-fw-600"><?php echo htmlspecialchars($v['numero']) ?></td>
                <td><?php echo htmlspecialchars($terminalLbl) ?></td>
                <td class="adm-text-muted"><?php echo $v['sold_at'] ? date('d/m/Y H:i', strtotime($v['sold_at'])) : date('d/m/Y H:i', strtotime($v['created_at'])) ?></td>
                <td class="adm-fw-600"><?php echo number_format((float) $v['total'], 2, ',', '.') ?> <?php echo htmlspecialchars($v['moeda']) ?></td>
                <td><?php echo number_format((float) $v['troco'], 2, ',', '.') ?></td>
                <td><span class="adm-badge <?php echo $estadoBadge[0] ?>"><?php echo $estadoBadge[1] ?></span></td>
                <td>
                    <div class="adm-actions">
                        <a href="<?php echo htmlspecialchars($app->routes->path('pos_venda_ver', ['id' => $v['id']])) ?>" class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Ver">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
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
            <path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"/><line x1="3" y1="6" x2="21" y2="6"/><path d="M16 10a4 4 0 0 1-8 0"/>
        </svg>
        <p class="adm-empty-title">Nenhuma venda registada</p>
        <p class="adm-empty-sub">As vendas registadas no Ponto de Venda aparecem aqui.</p>
    </div>
    <?php endif; ?>
</div>

<script>
function filterTable() {
    const q      = document.getElementById('vendaSearch').value.toLowerCase();
    const estado = document.getElementById('vendaEstado').value;
    const rows   = document.querySelectorAll('#vendasTable tbody tr');
    let vis = 0;
    rows.forEach(row => {
        const txt  = row.textContent.toLowerCase();
        const est  = row.dataset.estado;
        const show = (!q || txt.includes(q)) && (!estado || est === estado);
        row.style.display = show ? '' : 'none';
        if (show) vis++;
    });
    document.getElementById('vendaCount').textContent = vis + ' venda' + (vis !== 1 ? 's' : '');
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
