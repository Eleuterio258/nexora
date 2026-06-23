<?php

    $nivel = $app->request->queryEnum('nivel', ['info', 'warning', 'error', 'critical', 'debug']);

    $systemLogs = $app->nexora->call('GET', '/api/system/logs', null, ['nivel' => $nivel ?: null])['body'] ?? [];
    $apiLogs    = $app->nexora->call('GET', '/api/system/api-logs')['body'] ?? [];

    $nivelBadges = [
        'error'    => ['adm-badge--red', 'Erro'],
        'critical' => ['adm-badge--red', 'Crítico'],
        'warning'  => ['adm-badge--yellow', 'Aviso'],
        'info'     => ['adm-badge--blue', 'Info'],
        'debug'    => ['adm-badge--gray', 'Debug'],
    ];

    $pageTitle  = 'Logs do Sistema';
    $activePage = 'sistema_logs';
    $breadcrumb = [['Admin', '/nexora/'], ['Sistema', ''], ['Logs do Sistema', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Logs do Sistema</h1>
</div>

<div class="adm-tabs" id="mainTabs">
    <button class="adm-tab active" onclick="switchTab('sistema',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
        Sistema
        <?php if (count($systemLogs)): ?><span class="adm-tab-badge"><?php echo count($systemLogs) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('api',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>
        API
        <?php if (count($apiLogs)): ?><span class="adm-tab-badge"><?php echo count($apiLogs) ?></span><?php endif; ?>
    </button>
</div>

<!-- ── Logs do Sistema ────────────────────────────────────── -->
<div class="adm-tab-panel active" id="tab-sistema">
    <div class="adm-card">
        <div class="adm-filter-bar">
            <select class="adm-select" id="nivelFiltro" onchange="location.href='?nivel=' + this.value + '#sistema'" style="width:200px">
                <option value="">Todos os níveis</option>
                <?php foreach ($nivelBadges as $key => [, $label]): ?>
                <option value="<?php echo $key ?>" <?php echo $nivel === $key ? 'selected' : '' ?>><?php echo $label ?></option>
                <?php endforeach; ?>
            </select>
            <span class="adm-filter-count"><?php echo count($systemLogs) ?> registos</span>
        </div>

        <?php if ($systemLogs): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Nível</th><th>Módulo</th><th>Mensagem</th><th>Data</th></tr>
                </thead>
                <tbody>
                <?php foreach ($systemLogs as $l):
                    $badge = $nivelBadges[$l['nivel']] ?? ['adm-badge--gray', $l['nivel']];
                ?>
                <tr>
                    <td><span class="adm-badge <?php echo $badge[0] ?>"><?php echo $badge[1] ?></span></td>
                    <td class="adm-text-muted"><?php echo $l['modulo'] ? htmlspecialchars($l['modulo']) : '—' ?></td>
                    <td class="adm-text-sm"><?php echo htmlspecialchars($l['mensagem']) ?></td>
                    <td class="adm-text-muted adm-text-sm"><?php echo date('d/m/Y H:i:s', strtotime($l['created_at'])) ?></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum registo encontrado</p>
            <p class="adm-empty-sub">Os eventos do sistema aparecem aqui à medida que ocorrem.</p>
        </div>
        <?php endif; ?>
    </div>
</div>

<!-- ── Logs de API ────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-api">
    <div class="adm-card">
        <div class="adm-filter-bar">
            <div class="adm-search-wrap">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
                </svg>
                <input class="adm-input" type="search" id="apiSearch" placeholder="Pesquisar rotas…" oninput="filterApiTable()">
            </div>
            <span class="adm-filter-count" id="apiCount"><?php echo count($apiLogs) ?> registos</span>
        </div>

        <?php if ($apiLogs): ?>
        <div class="adm-table-wrap">
            <table class="adm-table" id="apiLogsTable">
                <thead>
                    <tr><th>Método</th><th>Rota</th><th>Estado</th><th>Duração</th><th>Data</th></tr>
                </thead>
                <tbody>
                <?php foreach ($apiLogs as $l):
                    $status = $l['status_code'];
                    if ($status === null) {
                        $statusBadge = ['adm-badge--gray', '—'];
                    } elseif ($status >= 500) {
                        $statusBadge = ['adm-badge--red', (string) $status];
                    } elseif ($status >= 400) {
                        $statusBadge = ['adm-badge--yellow', (string) $status];
                    } else {
                        $statusBadge = ['adm-badge--green', (string) $status];
                    }
                ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($l['metodo']) ?></td>
                    <td class="adm-text-sm"><?php echo htmlspecialchars($l['rota']) ?></td>
                    <td><span class="adm-badge <?php echo $statusBadge[0] ?>"><?php echo $statusBadge[1] ?></span></td>
                    <td class="adm-text-muted"><?php echo $l['duracao_ms'] !== null ? $l['duracao_ms'] . ' ms' : '—' ?></td>
                    <td class="adm-text-muted adm-text-sm"><?php echo date('d/m/Y H:i:s', strtotime($l['created_at'])) ?></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum registo encontrado</p>
            <p class="adm-empty-sub">Os pedidos à API aparecem aqui à medida que ocorrem.</p>
        </div>
        <?php endif; ?>
    </div>
</div>

<script>
// ── Tabs ─────────────────────────────────────────────────────
function switchTab(name, btn) {
    document.querySelectorAll('.adm-tab-panel').forEach(p => p.classList.remove('active'));
    document.querySelectorAll('.adm-tab').forEach(b => b.classList.remove('active'));
    document.getElementById('tab-' + name).classList.add('active');
    btn.classList.add('active');
}

document.addEventListener('DOMContentLoaded', () => {
    const tabs = ['sistema', 'api'];
    const hash = location.hash.replace('#', '');
    const idx  = tabs.indexOf(hash);
    if (idx > 0) {
        const btn = document.querySelectorAll('#mainTabs .adm-tab')[idx];
        if (btn) switchTab(hash, btn);
    }
});

// ── Logs de API ──────────────────────────────────────────────
function filterApiTable() {
    const q    = document.getElementById('apiSearch').value.toLowerCase();
    const rows = document.querySelectorAll('#apiLogsTable tbody tr');
    let vis = 0;
    rows.forEach(row => {
        const show = !q || row.textContent.toLowerCase().includes(q);
        row.style.display = show ? '' : 'none';
        if (show) vis++;
    });
    document.getElementById('apiCount').textContent = vis + ' registo' + (vis !== 1 ? 's' : '');
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
