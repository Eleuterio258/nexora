<?php

declare(strict_types=1);

$filtroEstado = $app->request->queryEnum('estado', ['ativo', 'inativo', 'bloqueado']);
$filtroGrupo  = $app->request->queryInt('grupo_id', 0) ?: 0;
$filtroQ      = $app->request->queryString('q');
$page         = max(1, $app->request->queryInt('page', 1) ?? 1);
$limit        = 50;

// O backend filtra por `status` (não `estado`) e pesquisa por `search`.
$query = [];
if ($filtroEstado !== '') {
    $query['status'] = $filtroEstado;
}
if ($filtroGrupo) {
    $query['grupo_id'] = $filtroGrupo;
}
if ($filtroQ !== '') {
    $query['search'] = $filtroQ;
}

$resp     = $app->nexora->call('GET', '/api/clientes', null, array_merge($query, ['page' => $page, 'limit' => $limit]));
$clientes = ($resp['status'] === 200 && is_array($resp['body']['data'] ?? null)) ? $resp['body']['data'] : [];
$meta     = $resp['body']['meta'] ?? ['total' => 0, 'page' => $page, 'limit' => $limit];
$totalPages = max(1, (int) ceil(((int) $meta['total']) / $limit));

$gruposResp = $app->nexora->call('GET', '/api/clientes/grupos');
$grupos     = ($gruposResp['status'] === 200 && is_array($gruposResp['body']) && array_is_list($gruposResp['body'])) ? $gruposResp['body'] : [];
$grupoNomes = array_column($grupos, 'nome', 'id');

$estadoBadges = [
    'ativo'     => ['adm-badge--green', 'Ativo'],
    'inativo'   => ['adm-badge--gray',  'Inativo'],
    'bloqueado' => ['adm-badge--red',   'Bloqueado'],
];

$estadoActions = [
    'ativo'     => ['bloquear',    'Bloquear',    'var(--adm-red)'],
    'bloqueado' => ['desbloquear', 'Desbloquear', 'var(--adm-green)'],
    'inativo'   => ['activar',     'Activar',     'var(--adm-green)'],
];

$csrf             = $app->security->csrfToken();
$canGerirClientes = $app->session->can('clientes', 'gerir_clientes');
$canGerirGrupos   = $app->session->can('clientes', 'gerir_grupos');
$pageTitle        = 'Clientes';
$activePage       = 'clientes';
$breadcrumb       = [['Admin', '/nexora/'], ['Clientes', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Clientes</h1>
    <?php if ($canGerirClientes): ?>
    <div class="adm-page-header-actions">
        <?php if ($canGerirGrupos): ?>
        <button class="adm-btn adm-btn-outline" type="button" onclick="openGruposModal()">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"/>
                <line x1="7" y1="7" x2="7.01" y2="7"/>
            </svg>
            Grupos
        </button>
        <?php endif; ?>
        <a href="<?= htmlspecialchars($app->routes->path('cliente_form')) ?>" class="adm-btn adm-btn-primary">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
            Novo Cliente
        </a>
    </div>
    <?php endif; ?>
</div>

<?php if ($app->request->queryString('msg') !== ''): ?>
<div class="adm-alert adm-alert--success">
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
    <?= htmlspecialchars($app->request->queryString('msg')) ?>
</div>
<?php endif; ?>

<div class="adm-card">
    <div class="adm-filter-bar">
        <div class="adm-search-wrap">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
            </svg>
            <input class="adm-input" type="search" id="clienteSearch" placeholder="Pesquisar por nome, email ou NUIT…" value="<?= htmlspecialchars($filtroQ) ?>" onkeydown="if(event.key==='Enter') applyFiltros()">
        </div>
        <select class="adm-select" id="clienteEstado" onchange="applyFiltros()" style="width:160px">
            <option value="">Todos os estados</option>
            <?php foreach ($estadoBadges as $key => [, $label]): ?>
            <option value="<?= $key ?>" <?= $filtroEstado === $key ? 'selected' : '' ?>><?= $label ?></option>
            <?php endforeach; ?>
        </select>
        <select class="adm-select" id="clienteGrupo" onchange="applyFiltros()" style="width:180px">
            <option value="">Todos os grupos</option>
            <?php foreach ($grupos as $g): ?>
            <option value="<?= (int) $g['id'] ?>" <?= $filtroGrupo === (int) $g['id'] ? 'selected' : '' ?>><?= htmlspecialchars($g['nome']) ?></option>
            <?php endforeach; ?>
        </select>
        <button class="adm-btn adm-btn-outline adm-btn-sm" type="button" onclick="applyFiltros()">Filtrar</button>
        <?php if ($query): ?>
        <a class="adm-btn adm-btn-ghost adm-btn-sm" href="/nexora/clientes">Limpar</a>
        <?php endif; ?>
        <span class="adm-filter-count"><?= (int) $meta['total'] ?> cliente<?= (int) $meta['total'] !== 1 ? 's' : '' ?></span>
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
                    <?php if ($canGerirClientes): ?><th>Ações</th><?php endif; ?>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($clientes as $c):
                $estadoBadge  = $estadoBadges[$c['estado']] ?? ['adm-badge--gray', $c['estado']];
                $estadoAction = $estadoActions[$c['estado']] ?? null;
                $grupoNome    = $grupoNomes[$c['customer_group_id']] ?? null;
            ?>
            <tr>
                <td class="adm-text-muted"><?= $app->view->field($c, 'codigo', '—') ?></td>
                <td class="adm-fw-600"><?= htmlspecialchars($c['nome']) ?></td>
                <td><?= $app->view->field($c, 'nuit', '—') ?></td>
                <td>
                    <?php if (!empty($c['email'])): ?><div class="adm-text-sm"><?= htmlspecialchars($c['email']) ?></div><?php endif; ?>
                    <?php if (!empty($c['telefone'])): ?><div class="adm-text-xs adm-text-muted"><?= htmlspecialchars($c['telefone']) ?></div><?php endif; ?>
                    <?php if (empty($c['email']) && empty($c['telefone'])): ?><span class="adm-text-muted">—</span><?php endif; ?>
                </td>
                <td><?= $grupoNome ? htmlspecialchars($grupoNome) : '—' ?></td>
                <td><span class="adm-badge <?= $estadoBadge[0] ?>"><?= htmlspecialchars($estadoBadge[1]) ?></span></td>
                <?php if ($canGerirClientes): ?>
                <td>
                    <div class="adm-actions">
                        <a href="<?= htmlspecialchars($app->routes->path('cliente_form', ['id' => $app->id->encode((int) $c['id'])])) ?>" class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Ver / Editar">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                            </svg>
                        </a>
                        <?php if ($estadoAction): [$action, $label, $color] = $estadoAction; ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" title="<?= $label ?>" style="color:<?= $color ?>"
                                onclick="changeEstado(<?= (int) $c['id'] ?>, '<?= $action ?>', <?= htmlspecialchars(json_encode($c['nome'], JSON_UNESCAPED_UNICODE), ENT_QUOTES) ?>)">
                            <?= $label ?>
                        </button>
                        <?php endif; ?>
                    </div>
                </td>
                <?php endif; ?>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>

    <?php if ($totalPages > 1): ?>
    <div style="display:flex;justify-content:center;gap:var(--adm-sp-3);padding:var(--adm-sp-5)">
        <?php if ($page > 1): ?>
        <a href="<?= htmlspecialchars($app->view->queryLink('/nexora/clientes', $app->request->query(), ['page' => $page - 1])) ?>" class="adm-btn adm-btn-outline adm-btn-sm">« Anterior</a>
        <?php endif; ?>
        <span class="adm-text-sm adm-text-muted" style="align-self:center">Página <?= $page ?> de <?= $totalPages ?></span>
        <?php if ($page < $totalPages): ?>
        <a href="<?= htmlspecialchars($app->view->queryLink('/nexora/clientes', $app->request->query(), ['page' => $page + 1])) ?>" class="adm-btn adm-btn-outline adm-btn-sm">Seguinte »</a>
        <?php endif; ?>
    </div>
    <?php endif; ?>

    <?php else: ?>
    <div class="adm-empty">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
            <circle cx="9" cy="7" r="4"/>
            <path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>
        </svg>
        <p class="adm-empty-title"><?= $query ? 'Nenhum cliente encontrado' : 'Nenhum cliente criado' ?></p>
        <p class="adm-empty-sub"><?= $query ? 'Nenhum resultado para os filtros aplicados.' : 'Começa por criar o primeiro cliente.' ?></p>
        <?php if (!$query && $canGerirClientes): ?>
        <a href="<?= htmlspecialchars($app->routes->path('cliente_form')) ?>" class="adm-btn adm-btn-primary">Criar Cliente</a>
        <?php endif; ?>
    </div>
    <?php endif; ?>
</div>

<?php if ($canGerirGrupos): ?>
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
                <tr data-id="<?= (int) $g['id'] ?>"
                    data-codigo="<?= htmlspecialchars($g['codigo']) ?>"
                    data-nome="<?= htmlspecialchars($g['nome']) ?>"
                    data-descricao="<?= htmlspecialchars((string) ($g['descricao'] ?? '')) ?>"
                    data-ativo="<?= $g['ativo'] ? '1' : '0' ?>">
                    <td><?= htmlspecialchars($g['codigo']) ?></td>
                    <td><?= htmlspecialchars($g['nome']) ?></td>
                    <td class="adm-text-sm adm-text-muted"><?= $g['descricao'] ? htmlspecialchars($g['descricao']) : '—' ?></td>
                    <td><span class="adm-badge <?= $g['ativo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?= $g['ativo'] ? 'Ativo' : 'Inativo' ?></span></td>
                    <td><button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" onclick="editGrupo(this)">Editar</button></td>
                </tr>
                <?php endforeach; ?>
                <?php if (!$grupos): ?>
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
            <button class="adm-btn adm-btn-outline" type="button" onclick="resetGrupoForm()">Limpar</button>
            <button class="adm-btn adm-btn-outline" type="button" onclick="closeGruposModal()">Fechar</button>
            <button class="adm-btn adm-btn-primary" type="button" id="btnGrupoSave" onclick="saveGrupo()">Adicionar</button>
        </div>
    </div>
</div>
<?php endif; ?>

<script>
const CSRF = '<?= $csrf ?>';

function applyFiltros() {
    const params = new URLSearchParams();
    const q      = document.getElementById('clienteSearch').value.trim();
    const estado = document.getElementById('clienteEstado').value;
    const grupo  = document.getElementById('clienteGrupo').value;
    if (q)      params.set('q', q);
    if (estado) params.set('estado', estado);
    if (grupo)  params.set('grupo_id', grupo);
    const qs = params.toString();
    location.href = '/nexora/clientes' + (qs ? '?' + qs : '');
}

<?php if ($canGerirClientes): ?>
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
<?php endif; ?>

<?php if ($canGerirGrupos): ?>
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
<?php endif; ?>
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
