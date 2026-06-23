<?php

    $filtroEstado = $app->request->queryEnum('estado', ['ativo', 'inativo', 'bloqueado']);
    $filtroGrupo  = $app->request->queryInt('grupo_id', 0) ?: 0;

    $query = ['limit' => 100];
    if ($filtroEstado) $query['estado']   = $filtroEstado;
    if ($filtroGrupo)  $query['grupo_id'] = $filtroGrupo;

    $resp     = $app->nexora->call('GET', '/api/clientes', null, $query);
    $clientes = $resp['body']['data'] ?? [];

    $gruposResp = $app->nexora->call('GET', '/api/clientes/grupos');
    $grupos     = $gruposResp['body'] ?? [];
    $grupoNomes = array_column($grupos, 'nome', 'id');

    $estadoBadges = [
        'ativo'     => ['adm-badge--green', 'Ativo'],
        'inativo'   => ['adm-badge--gray',  'Inativo'],
        'bloqueado' => ['adm-badge--red',   'Bloqueado'],
    ];

    $estadoActions = [
        'ativo'     => ['bloquear',   'Bloquear',    'var(--adm-red)'],
        'bloqueado' => ['desbloquear', 'Desbloquear', 'var(--adm-green)'],
        'inativo'   => ['activar',    'Activar',     'var(--adm-green)'],
    ];

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Clientes';
    $activePage = 'clientes';
    $breadcrumb = [['Admin', '/nexora/'], ['Clientes', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Clientes</h1>
    <div class="adm-page-header-actions">
        <button class="adm-btn adm-btn-outline" onclick="openGruposModal()">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"/>
                <line x1="7" y1="7" x2="7.01" y2="7"/>
            </svg>
            Grupos
        </button>
        <a href="<?php echo htmlspecialchars($app->routes->path('cliente_form')) ?>" class="adm-btn adm-btn-primary">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
            Novo Cliente
        </a>
    </div>
</div>

<?php if ($app->request->queryString('msg') !== ''): ?>
<div class="adm-alert adm-alert--success">
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
    <?php echo htmlspecialchars($app->request->queryString('msg')) ?>
</div>
<?php endif; ?>

<div class="adm-card">
    <div class="adm-filter-bar">
        <div class="adm-search-wrap">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
            </svg>
            <input class="adm-input" type="search" id="clienteSearch" placeholder="Pesquisar clientes…" oninput="filterTable()">
        </div>
        <select class="adm-select" id="clienteEstado" onchange="filterTable()" style="width:160px">
            <option value="">Todos os estados</option>
            <?php foreach ($estadoBadges as $key => [$cls, $label]): ?>
            <option value="<?php echo $key ?>" <?php echo $filtroEstado === $key ? 'selected' : '' ?>><?php echo $label ?></option>
            <?php endforeach; ?>
        </select>
        <select class="adm-select" id="clienteGrupo" onchange="filterTable()" style="width:180px">
            <option value="">Todos os grupos</option>
            <?php foreach ($grupos as $g): ?>
            <option value="<?php echo $g['id'] ?>" <?php echo $filtroGrupo === (int) $g['id'] ? 'selected' : '' ?>><?php echo htmlspecialchars($g['nome']) ?></option>
            <?php endforeach; ?>
        </select>
        <span class="adm-filter-count" id="clienteCount"><?php echo count($clientes) ?> clientes</span>
    </div>

    <?php if ($clientes): ?>
    <div class="adm-table-wrap">
        <table class="adm-table" id="clientesTable">
            <thead>
                <tr>
                    <th>Código</th>
                    <th>Nome</th>
                    <th>NUIT</th>
                    <th>Contacto</th>
                    <th>Grupo</th>
                    <th>Estado</th>
                    <th>Ações</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($clientes as $c):
                    $estadoBadge  = $estadoBadges[$c['estado']] ?? ['adm-badge--gray', $c['estado']];
                    $estadoAction = $estadoActions[$c['estado']] ?? null;
                    $grupoNome    = $grupoNomes[$c['customer_group_id']] ?? null;
            ?>
            <tr data-estado="<?php echo htmlspecialchars($c['estado']) ?>" data-grupo="<?php echo (int) ($c['customer_group_id'] ?? 0) ?>">
                <td class="adm-text-muted"><?php echo $app->view->field($c, 'codigo', '—') ?></td>
                <td class="adm-fw-600"><?php echo htmlspecialchars($c['nome']) ?></td>
                <td><?php echo $app->view->field($c, 'nuit', '—') ?></td>
                <td>
                    <?php if (! empty($c['email'])): ?><div class="adm-text-sm"><?php echo htmlspecialchars($c['email']) ?></div><?php endif; ?>
                    <?php if (! empty($c['telefone'])): ?><div class="adm-text-xs adm-text-muted"><?php echo htmlspecialchars($c['telefone']) ?></div><?php endif; ?>
                    <?php if (empty($c['email']) && empty($c['telefone'])): ?><span class="adm-text-muted">—</span><?php endif; ?>
                </td>
                <td><?php echo $grupoNome ? htmlspecialchars($grupoNome) : '—' ?></td>
                <td><span class="adm-badge <?php echo $estadoBadge[0] ?>"><?php echo $estadoBadge[1] ?></span></td>
                <td>
                    <div class="adm-actions">
                        <a href="<?php echo htmlspecialchars($app->routes->path('cliente_form', ['id' => $c['id']])) ?>" class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Ver / Editar">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                            </svg>
                        </a>
                        <?php if ($estadoAction): [$action, $label, $color] = $estadoAction; ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" title="<?php echo $label ?>" style="color:<?php echo $color ?>"
                                onclick="changeEstado(<?php echo (int) $c['id'] ?>, '<?php echo $action ?>', '<?php echo htmlspecialchars(addslashes($c['nome'])) ?>')">
                            <?php echo $label ?>
                        </button>
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
            <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
            <circle cx="9" cy="7" r="4"/>
            <path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>
        </svg>
        <p class="adm-empty-title">Nenhum cliente criado</p>
        <p class="adm-empty-sub">Começa por criar o primeiro cliente.</p>
        <a href="<?php echo htmlspecialchars($app->routes->path('cliente_form')) ?>" class="adm-btn adm-btn-primary">Criar Cliente</a>
    </div>
    <?php endif; ?>
</div>

<!-- Grupos Modal -->
<div class="adm-modal-overlay" id="gruposModal">
    <div class="adm-modal" style="max-width:640px">
        <p class="adm-modal-title">Grupos de Clientes</p>

        <div class="adm-table-wrap" style="margin-bottom:var(--adm-sp-4)">
            <table class="adm-table" id="gruposTable">
                <thead>
                    <tr><th>Código</th><th>Nome</th><th>Descrição</th><th>Estado</th><th></th></tr>
                </thead>
                <tbody>
                <?php foreach ($grupos as $g): ?>
                <tr data-id="<?php echo (int) $g['id'] ?>"
                    data-codigo="<?php echo htmlspecialchars($g['codigo']) ?>"
                    data-nome="<?php echo htmlspecialchars($g['nome']) ?>"
                    data-descricao="<?php echo htmlspecialchars((string) ($g['descricao'] ?? '')) ?>"
                    data-ativo="<?php echo $g['ativo'] ? '1' : '0' ?>">
                    <td><?php echo htmlspecialchars($g['codigo']) ?></td>
                    <td><?php echo htmlspecialchars($g['nome']) ?></td>
                    <td class="adm-text-sm adm-text-muted"><?php echo $g['descricao'] ? htmlspecialchars($g['descricao']) : '—' ?></td>
                    <td><span class="adm-badge <?php echo $g['ativo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $g['ativo'] ? 'Ativo' : 'Inativo' ?></span></td>
                    <td><button class="adm-btn adm-btn-ghost adm-btn-sm" onclick="editGrupo(this)">Editar</button></td>
                </tr>
                <?php endforeach; ?>
                <?php if (! $grupos): ?>
                <tr><td colspan="5" class="adm-text-muted adm-text-sm" style="text-align:center;padding:var(--adm-sp-4)">Nenhum grupo criado.</td></tr>
                <?php endif; ?>
                </tbody>
            </table>
        </div>

        <form id="grupoForm">
            <input type="hidden" id="g-id" value="">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="g-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="g-codigo" maxlength="50">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="g-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="g-nome" maxlength="120">
                </div>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="g-descricao">Descrição</label>
                <textarea class="adm-textarea" id="g-descricao" rows="2"></textarea>
            </div>
            <label class="adm-toggle" style="margin-bottom:0">
                <input type="checkbox" id="g-ativo" checked>
                <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                <span class="adm-toggle-label">Ativo</span>
            </label>
        </form>

        <div class="adm-modal-footer">
            <button class="adm-btn adm-btn-outline" onclick="resetGrupoForm()">Limpar</button>
            <button class="adm-btn adm-btn-outline" onclick="closeGruposModal()">Fechar</button>
            <button class="adm-btn adm-btn-primary" id="btnGrupoSave" onclick="saveGrupo()">Adicionar</button>
        </div>
    </div>
</div>

<script>
const CSRF = '<?php echo $csrf ?>';

function filterTable() {
    const q      = document.getElementById('clienteSearch').value.toLowerCase();
    const estado = document.getElementById('clienteEstado').value;
    const grupo  = document.getElementById('clienteGrupo').value;
    const rows   = document.querySelectorAll('#clientesTable tbody tr');
    let vis = 0;
    rows.forEach(row => {
        const txt   = row.textContent.toLowerCase();
        const est   = row.dataset.estado;
        const grp   = row.dataset.grupo;
        const show  = (!q || txt.includes(q)) && (!estado || est === estado) && (!grupo || grp === grupo);
        row.style.display = show ? '' : 'none';
        if (show) vis++;
    });
    document.getElementById('clienteCount').textContent = vis + ' cliente' + (vis !== 1 ? 's' : '');
}

// ── Estado do cliente ────────────────────────────────────────
const ESTADO_VERBOS = { activar: 'activar', bloquear: 'bloquear', desbloquear: 'desbloquear' };

function changeEstado(id, action, nome) {
    openConfirm(
        'Alterar estado',
        'Pretende ' + ESTADO_VERBOS[action] + ' o cliente "' + nome + '"?',
        async () => {
            try {
                const res  = await fetch('/nexora/api/cliente_estado', {
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

// ── Grupos ───────────────────────────────────────────────────
function openGruposModal() {
    document.getElementById('gruposModal').classList.add('open');
}
function closeGruposModal() {
    document.getElementById('gruposModal').classList.remove('open');
    resetGrupoForm();
}
document.getElementById('gruposModal').addEventListener('click', e => {
    if (e.target === e.currentTarget) closeGruposModal();
});

function resetGrupoForm() {
    document.getElementById('g-id').value = '';
    document.getElementById('g-codigo').value = '';
    document.getElementById('g-codigo').disabled = false;
    document.getElementById('g-nome').value = '';
    document.getElementById('g-descricao').value = '';
    document.getElementById('g-ativo').checked = true;
    document.getElementById('btnGrupoSave').textContent = 'Adicionar';
}

function editGrupo(btn) {
    const row = btn.closest('tr');
    document.getElementById('g-id').value = row.dataset.id;
    document.getElementById('g-codigo').value = row.dataset.codigo;
    document.getElementById('g-codigo').disabled = true;
    document.getElementById('g-nome').value = row.dataset.nome;
    document.getElementById('g-descricao').value = row.dataset.descricao;
    document.getElementById('g-ativo').checked = row.dataset.ativo === '1';
    document.getElementById('btnGrupoSave').textContent = 'Guardar';
}

async function saveGrupo() {
    const id     = document.getElementById('g-id').value;
    const codigo = document.getElementById('g-codigo').value.trim();
    const nome   = document.getElementById('g-nome').value.trim();

    if (!id && (!codigo || !nome)) { showToast('Código e nome são obrigatórios.', 'error'); return; }
    if (id && !nome) { showToast('O nome é obrigatório.', 'error'); return; }

    const payload = {
        id: id ? Number(id) : null,
        nome,
        descricao: document.getElementById('g-descricao').value.trim() || null,
        ativo: document.getElementById('g-ativo').checked,
        csrf: CSRF
    };
    if (!id) payload.codigo = codigo;

    try {
        const res  = await fetch('/nexora/api/cliente_grupo_save', {
            method: 'POST',
            headers: {'Content-Type':'application/json'},
            body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            showToast(data.msg || 'Grupo guardado com sucesso.');
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
