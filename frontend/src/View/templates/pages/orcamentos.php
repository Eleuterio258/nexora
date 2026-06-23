<?php

    $filtroEstado   = $app->request->queryEnum('status', ['rascunho', 'enviado', 'aprovado', 'rejeitado', 'convertido', 'expirado']);
    $filtroCliente  = $app->request->queryInt('customer_id', 0) ?: 0;

    $query = ['limit' => 100];
    if ($filtroEstado)  $query['status']      = $filtroEstado;
    if ($filtroCliente) $query['customer_id'] = $filtroCliente;

    $resp      = $app->nexora->call('GET', '/api/faturacao/quotes', null, $query);
    $orcamentos = $resp['body'] ?? [];

    $clientesResp = $app->nexora->call('GET', '/api/clientes', null, ['limit' => 200]);
    $clientes     = $clientesResp['body']['data'] ?? [];
    $clienteNomes = array_column($clientes, 'nome', 'id');

    $estadoBadges = [
        'rascunho'   => ['adm-badge--gray',   'Rascunho'],
        'enviado'    => ['adm-badge--blue',   'Enviado'],
        'aprovado'   => ['adm-badge--green',  'Aprovado'],
        'rejeitado'  => ['adm-badge--red',    'Rejeitado'],
        'convertido' => ['adm-badge--indigo', 'Convertido'],
        'expirado'   => ['adm-badge--yellow', 'Expirado'],
    ];

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Orçamentos';
    $activePage = 'orcamentos';
    $breadcrumb = [['Admin', '/nexora/'], ['Faturação', ''], ['Orçamentos', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Orçamentos</h1>
    <div class="adm-page-header-actions">
        <a href="<?php echo htmlspecialchars($app->routes->path('orcamento_form')) ?>" class="adm-btn adm-btn-primary">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
            Novo Orçamento
        </a>
    </div>
</div>

<div class="adm-card">
    <div class="adm-filter-bar">
        <div class="adm-search-wrap">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
            </svg>
            <input class="adm-input" type="search" id="orcamentoSearch" placeholder="Pesquisar orçamentos…" oninput="filterTable()">
        </div>
        <select class="adm-select" id="orcamentoEstado" onchange="filterTable()" style="width:160px">
            <option value="">Todos os estados</option>
            <?php foreach ($estadoBadges as $key => [$cls, $label]): ?>
            <option value="<?php echo $key ?>" <?php echo $filtroEstado === $key ? 'selected' : '' ?>><?php echo $label ?></option>
            <?php endforeach; ?>
        </select>
        <select class="adm-select" id="orcamentoCliente" onchange="filterTable()" style="width:200px">
            <option value="">Todos os clientes</option>
            <?php foreach ($clientes as $c): ?>
            <option value="<?php echo $c['id'] ?>" <?php echo $filtroCliente === (int) $c['id'] ? 'selected' : '' ?>><?php echo htmlspecialchars($c['nome']) ?></option>
            <?php endforeach; ?>
        </select>
        <span class="adm-filter-count" id="orcamentoCount"><?php echo count($orcamentos) ?> orçamentos</span>
    </div>

    <?php if ($orcamentos): ?>
    <div class="adm-table-wrap">
        <table class="adm-table" id="orcamentosTable">
            <thead>
                <tr>
                    <th>Número</th>
                    <th>Cliente</th>
                    <th>Data</th>
                    <th>Validade</th>
                    <th>Total</th>
                    <th>Moeda</th>
                    <th>Estado</th>
                    <th>Ações</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($orcamentos as $o):
                    $estadoBadge = $estadoBadges[$o['status']] ?? ['adm-badge--gray', $o['status']];
                    $clienteNome = $clienteNomes[$o['customer_id']] ?? ('#' . $o['customer_id']);
            ?>
            <tr data-estado="<?php echo htmlspecialchars($o['status']) ?>" data-cliente="<?php echo (int) $o['customer_id'] ?>">
                <td class="adm-fw-600"><?php echo htmlspecialchars($o['numero']) ?></td>
                <td><?php echo htmlspecialchars($clienteNome) ?></td>
                <td class="adm-text-muted"><?php echo $o['created_at'] ? date('d/m/Y', strtotime($o['created_at'])) : '—' ?></td>
                <td class="adm-text-muted"><?php echo $o['validade'] ? date('d/m/Y', strtotime($o['validade'])) : '—' ?></td>
                <td class="adm-fw-600"><?php echo number_format((float) $o['total'], 2, ',', '.') ?></td>
                <td><?php echo htmlspecialchars($o['moeda']) ?></td>
                <td><span class="adm-badge <?php echo $estadoBadge[0] ?>"><?php echo $estadoBadge[1] ?></span></td>
                <td>
                    <div class="adm-actions">
                        <a href="<?php echo htmlspecialchars($app->routes->path('orcamento_form', ['id' => $o['id']])) ?>" class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Ver / Editar">
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
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/>
            <line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/>
        </svg>
        <p class="adm-empty-title">Nenhum orçamento criado</p>
        <p class="adm-empty-sub">Começa por criar o primeiro orçamento.</p>
        <a href="<?php echo htmlspecialchars($app->routes->path('orcamento_form')) ?>" class="adm-btn adm-btn-primary">Criar Orçamento</a>
    </div>
    <?php endif; ?>
</div>

<script>
function filterTable() {
    const q       = document.getElementById('orcamentoSearch').value.toLowerCase();
    const estado  = document.getElementById('orcamentoEstado').value;
    const cliente = document.getElementById('orcamentoCliente').value;
    const rows    = document.querySelectorAll('#orcamentosTable tbody tr');
    let vis = 0;
    rows.forEach(row => {
        const txt  = row.textContent.toLowerCase();
        const est  = row.dataset.estado;
        const cli  = row.dataset.cliente;
        const show = (!q || txt.includes(q)) && (!estado || est === estado) && (!cliente || cli === cliente);
        row.style.display = show ? '' : 'none';
        if (show) vis++;
    });
    document.getElementById('orcamentoCount').textContent = vis + ' orçamento' + (vis !== 1 ? 's' : '');
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
