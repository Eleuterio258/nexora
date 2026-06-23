<?php

    $filtroEstado  = $app->request->queryEnum('status', ['rascunho', 'confirmada', 'parcial', 'entregue', 'cancelada']);
    $filtroCliente = $app->request->queryInt('customer_id', 0) ?: 0;

    $query = ['limit' => 100];
    if ($filtroEstado)  $query['status']      = $filtroEstado;
    if ($filtroCliente) $query['customer_id'] = $filtroCliente;

    $resp       = $app->nexora->call('GET', '/api/faturacao/orders', null, $query);
    $encomendas = $resp['body'] ?? [];

    $clientesResp = $app->nexora->call('GET', '/api/clientes', null, ['limit' => 200]);
    $clientes     = $clientesResp['body']['data'] ?? [];
    $clienteNomes = array_column($clientes, 'nome', 'id');

    $estadoBadges = [
        'rascunho'   => ['adm-badge--gray',   'Rascunho'],
        'confirmada' => ['adm-badge--blue',   'Confirmada'],
        'parcial'    => ['adm-badge--yellow', 'Parcial'],
        'entregue'   => ['adm-badge--green',  'Entregue'],
        'cancelada'  => ['adm-badge--red',    'Cancelada'],
    ];

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Encomendas';
    $activePage = 'encomendas';
    $breadcrumb = [['Admin', '/nexora/'], ['Faturação', ''], ['Encomendas', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Encomendas</h1>
    <div class="adm-page-header-actions">
        <button class="adm-btn adm-btn-primary" onclick="openEncomendaModal()">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
            Nova Encomenda
        </button>
    </div>
</div>

<div class="adm-card">
    <div class="adm-filter-bar">
        <div class="adm-search-wrap">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
            </svg>
            <input class="adm-input" type="search" id="encomendaSearch" placeholder="Pesquisar encomendas…" oninput="filterTable()">
        </div>
        <select class="adm-select" id="encomendaEstado" onchange="filterTable()" style="width:160px">
            <option value="">Todos os estados</option>
            <?php foreach ($estadoBadges as $key => [$cls, $label]): ?>
            <option value="<?php echo $key ?>" <?php echo $filtroEstado === $key ? 'selected' : '' ?>><?php echo $label ?></option>
            <?php endforeach; ?>
        </select>
        <select class="adm-select" id="encomendaCliente" onchange="filterTable()" style="width:200px">
            <option value="">Todos os clientes</option>
            <?php foreach ($clientes as $c): ?>
            <option value="<?php echo $c['id'] ?>" <?php echo $filtroCliente === (int) $c['id'] ? 'selected' : '' ?>><?php echo htmlspecialchars($c['nome']) ?></option>
            <?php endforeach; ?>
        </select>
        <span class="adm-filter-count" id="encomendaCount"><?php echo count($encomendas) ?> encomendas</span>
    </div>

    <?php if ($encomendas): ?>
    <div class="adm-table-wrap">
        <table class="adm-table" id="encomendasTable">
            <thead>
                <tr>
                    <th>Número</th>
                    <th>Cliente</th>
                    <th>Data</th>
                    <th>Total</th>
                    <th>Moeda</th>
                    <th>Estado</th>
                    <th>Ações</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($encomendas as $e):
                    $estadoBadge = $estadoBadges[$e['status']] ?? ['adm-badge--gray', $e['status']];
                    $clienteNome = $clienteNomes[$e['customer_id']] ?? ('#' . $e['customer_id']);
            ?>
            <tr data-estado="<?php echo htmlspecialchars($e['status']) ?>" data-cliente="<?php echo (int) $e['customer_id'] ?>">
                <td class="adm-fw-600"><?php echo htmlspecialchars($e['numero']) ?></td>
                <td><?php echo htmlspecialchars($clienteNome) ?></td>
                <td class="adm-text-muted"><?php echo $e['created_at'] ? date('d/m/Y', strtotime($e['created_at'])) : '—' ?></td>
                <td class="adm-fw-600"><?php echo number_format((float) $e['total'], 2, ',', '.') ?></td>
                <td><?php echo htmlspecialchars($e['moeda']) ?></td>
                <td><span class="adm-badge <?php echo $estadoBadge[0] ?>"><?php echo $estadoBadge[1] ?></span></td>
                <td>
                    <div class="adm-actions">
                        <?php if ($e['status'] === 'rascunho'): ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" style="color:var(--adm-green-dark)"
                                onclick="changeEstado(<?php echo (int) $e['id'] ?>, 'confirmar', '<?php echo htmlspecialchars(addslashes($e['numero'])) ?>')">
                            Confirmar
                        </button>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" style="color:var(--adm-red)"
                                onclick="changeEstado(<?php echo (int) $e['id'] ?>, 'cancelar', '<?php echo htmlspecialchars(addslashes($e['numero'])) ?>')">
                            Cancelar
                        </button>
                        <?php elseif (in_array($e['status'], ['confirmada', 'parcial'], true)): ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" style="color:var(--adm-red)"
                                onclick="changeEstado(<?php echo (int) $e['id'] ?>, 'cancelar', '<?php echo htmlspecialchars(addslashes($e['numero'])) ?>')">
                            Cancelar
                        </button>
                        <?php else: ?>
                        <span class="adm-text-muted">—</span>
                        <?php endif; ?>
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
            <path d="M16 16l2 2 4-4"/><path d="M21 12V7a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 7v10a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0"/>
        </svg>
        <p class="adm-empty-title">Nenhuma encomenda criada</p>
        <p class="adm-empty-sub">Começa por criar a primeira encomenda.</p>
    </div>
    <?php endif; ?>
</div>

<!-- Nova Encomenda Modal -->
<div class="adm-modal-overlay" id="encomendaModal">
    <div class="adm-modal" style="max-width:560px">
        <p class="adm-modal-title">Nova Encomenda</p>

        <div class="adm-form-row">
            <div class="adm-form-group">
                <label class="adm-label" for="e-customer_id">Cliente <span style="color:var(--adm-red)">*</span></label>
                <select class="adm-select" id="e-customer_id">
                    <option value="">Seleciona um cliente</option>
                    <?php foreach ($clientes as $c): ?>
                    <option value="<?php echo $c['id'] ?>"><?php echo htmlspecialchars($c['nome']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="e-moeda">Moeda</label>
                <select class="adm-select" id="e-moeda">
                    <?php foreach (['MZN', 'USD', 'EUR', 'ZAR'] as $m): ?>
                    <option value="<?php echo $m ?>" <?php echo $m === 'MZN' ? 'selected' : '' ?>><?php echo $m ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
        </div>
        <p class="adm-text-muted adm-text-sm">O número será atribuído automaticamente pela série activa (Faturação → Séries Documentais).</p>
        <div class="adm-form-group">
            <label class="adm-label" for="e-observacoes">Observações</label>
            <textarea class="adm-textarea" id="e-observacoes" rows="3"></textarea>
        </div>

        <div class="adm-modal-footer">
            <button class="adm-btn adm-btn-outline" onclick="closeEncomendaModal()">Fechar</button>
            <button class="adm-btn adm-btn-primary" onclick="saveEncomenda()">Criar Encomenda</button>
        </div>
    </div>
</div>

<script>
const CSRF = '<?php echo $csrf ?>';

function filterTable() {
    const q       = document.getElementById('encomendaSearch').value.toLowerCase();
    const estado  = document.getElementById('encomendaEstado').value;
    const cliente = document.getElementById('encomendaCliente').value;
    const rows    = document.querySelectorAll('#encomendasTable tbody tr');
    let vis = 0;
    rows.forEach(row => {
        const txt  = row.textContent.toLowerCase();
        const est  = row.dataset.estado;
        const cli  = row.dataset.cliente;
        const show = (!q || txt.includes(q)) && (!estado || est === estado) && (!cliente || cli === cliente);
        row.style.display = show ? '' : 'none';
        if (show) vis++;
    });
    document.getElementById('encomendaCount').textContent = vis + ' encomenda' + (vis !== 1 ? 's' : '');
}

// ── Estado da encomenda ──────────────────────────────────────
const ESTADO_VERBOS = { confirmar: 'confirmar', cancelar: 'cancelar' };

function changeEstado(id, action, numero) {
    openConfirm(
        'Alterar estado',
        'Pretende ' + ESTADO_VERBOS[action] + ' a encomenda "' + numero + '"?',
        async () => {
            try {
                const res  = await fetch('/nexora/api/encomenda_estado', {
                    method: 'POST',
                    headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({id, action, csrf: CSRF})
                });
                const data = await res.json();
                if (data.ok) {
                    showToast('Estado actualizado');
                    setTimeout(() => location.reload(), 700);
                } else {
                    showToast(data.erro || 'Erro', 'error');
                }
            } catch { showToast('Erro de ligação', 'error'); }
        }
    );
}

// ── Nova Encomenda ───────────────────────────────────────────
function openEncomendaModal() {
    document.getElementById('encomendaModal').classList.add('open');
}
function closeEncomendaModal() {
    document.getElementById('encomendaModal').classList.remove('open');
}
document.getElementById('encomendaModal').addEventListener('click', e => {
    if (e.target === e.currentTarget) closeEncomendaModal();
});

async function saveEncomenda() {
    const customerId = document.getElementById('e-customer_id').value;
    if (!customerId) { showToast('O cliente é obrigatório.', 'error'); return; }

    const payload = {
        customer_id: Number(customerId),
        moeda: document.getElementById('e-moeda').value,
        observacoes: document.getElementById('e-observacoes').value.trim() || null,
        csrf: CSRF
    };

    try {
        const res  = await fetch('/nexora/api/encomenda_save', {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            showToast('Encomenda ' + (data.numero || '') + ' criada com sucesso.');
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
