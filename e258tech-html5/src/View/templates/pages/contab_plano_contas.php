<?php

    $tiposConta = $app->nexora->call('GET', '/api/contabilidade/account-types')['body'] ?? [];
    $contas     = $app->nexora->call('GET', '/api/contabilidade/accounts')['body'] ?? [];

    $classeLabels = [
        'ativo'      => 'Ativo',
        'passivo'    => 'Passivo',
        'capital'    => 'Capital',
        'rendimento' => 'Rendimento',
        'gasto'      => 'Gasto',
    ];

    $naturezaLabels = [
        'devedora' => 'Devedora',
        'credora'  => 'Credora',
    ];

    $byParent = [];
    foreach ($contas as $c) {
        $byParent[$c['parent_id'] ?? 0][] = $c;
    }

    function renderContaNode(array $c, array $byParent, array $classeLabels): void
    {
        $children = $byParent[$c['id']] ?? [];
        ?>
        <li class="adm-tree-node">
            <div class="adm-tree-card"
                 data-id="<?php echo (int) $c['id'] ?>"
                 data-parent-id="<?php echo $c['parent_id'] !== null ? (int) $c['parent_id'] : '' ?>"
                 data-codigo="<?php echo htmlspecialchars($c['codigo']) ?>"
                 data-nome="<?php echo htmlspecialchars($c['nome']) ?>"
                 data-account-type-id="<?php echo $c['account_type_id'] !== null ? (int) $c['account_type_id'] : '' ?>"
                 data-aceita-lancamento="<?php echo $c['aceita_lancamento'] ? '1' : '0' ?>"
                 data-ativo="<?php echo $c['ativo'] ? '1' : '0' ?>">
                <div class="adm-tree-card-title"><?php echo htmlspecialchars($c['codigo'] . ' - ' . $c['nome']) ?></div>
                <div class="adm-tree-card-meta">
                    <?php if (! empty($c['account_type_nome'])): ?>
                    <span class="adm-badge adm-badge--blue"><?php echo htmlspecialchars($c['account_type_nome']) ?></span>
                    <?php endif; ?>
                    <?php if (! empty($c['classe'])): ?>
                    <span class="adm-text-muted adm-text-xs"><?php echo htmlspecialchars($classeLabels[$c['classe']] ?? $c['classe']) ?></span>
                    <?php endif; ?>
                    <?php if (! $c['aceita_lancamento']): ?>
                    <span class="adm-badge adm-badge--gray">Sem lançamentos</span>
                    <?php endif; ?>
                    <?php if (! $c['ativo']): ?>
                    <span class="adm-badge adm-badge--gray">Inativo</span>
                    <?php endif; ?>
                </div>
                <div class="adm-actions" style="margin-top:var(--adm-sp-2)">
                    <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" onclick="editConta(this)">Editar</button>
                    <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-red)" onclick="deleteConta(this)">Eliminar</button>
                </div>
            </div>
            <?php if ($children): ?>
            <ul class="adm-tree-children">
                <?php foreach ($children as $ch) renderContaNode($ch, $byParent, $classeLabels); ?>
            </ul>
            <?php endif; ?>
        </li>
        <?php
    }

    function renderContaOptions(array $byParent, int $parentKey = 0, int $depth = 0): void
    {
        foreach ($byParent[$parentKey] ?? [] as $c) {
            $prefix = str_repeat('— ', $depth);
            ?>
            <option value="<?php echo (int) $c['id'] ?>"><?php echo htmlspecialchars($prefix . $c['codigo'] . ' - ' . $c['nome']) ?></option>
            <?php
            renderContaOptions($byParent, (int) $c['id'], $depth + 1);
        }
    }

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Plano de Contas';
    $activePage = 'contab_plano_contas';
    $breadcrumb = [['Admin', '/nexora/'], ['Contabilidade', ''], ['Plano de Contas', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Plano de Contas</h1>
</div>

<div class="adm-tabs" id="mainTabs">
    <button class="adm-tab active" onclick="switchTab('tipos',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 9h18"/><path d="M9 21V9"/></svg>
        Tipos de Conta
        <?php if (count($tiposConta)): ?><span class="adm-tab-badge"><?php echo count($tiposConta) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('contas',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"/><line x1="7" y1="7" x2="7.01" y2="7"/></svg>
        Plano de Contas
        <?php if (count($contas)): ?><span class="adm-tab-badge"><?php echo count($contas) ?></span><?php endif; ?>
    </button>
</div>

<!-- ── Tipos de Conta ─────────────────────────────────────────── -->
<div class="adm-tab-panel active" id="tab-tipos">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Tipos de Conta</h2></div>
        <?php if ($tiposConta): ?>
        <div class="adm-table-wrap">
            <table class="adm-table" id="tiposContaTable">
                <thead>
                    <tr><th>Código</th><th>Nome</th><th>Classe</th><th>Natureza</th><th>Estado</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($tiposConta as $t): ?>
                <tr data-id="<?php echo (int) $t['id'] ?>"
                    data-codigo="<?php echo htmlspecialchars($t['codigo']) ?>"
                    data-nome="<?php echo htmlspecialchars($t['nome']) ?>"
                    data-classe="<?php echo htmlspecialchars($t['classe']) ?>"
                    data-natureza="<?php echo htmlspecialchars($t['natureza']) ?>"
                    data-ativo="<?php echo $t['ativo'] ? '1' : '0' ?>">
                    <td class="adm-text-muted"><?php echo htmlspecialchars($t['codigo']) ?></td>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($t['nome']) ?></td>
                    <td><span class="adm-badge adm-badge--blue"><?php echo htmlspecialchars($classeLabels[$t['classe']] ?? $t['classe']) ?></span></td>
                    <td><?php echo htmlspecialchars($naturezaLabels[$t['natureza']] ?? $t['natureza']) ?></td>
                    <td><span class="adm-badge <?php echo $t['ativo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $t['ativo'] ? 'Ativo' : 'Inativo' ?></span></td>
                    <td>
                        <div class="adm-actions">
                            <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" onclick="editTipoConta(this)">Editar</button>
                            <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-red)"
                                    onclick="deleteTipoConta(<?php echo (int) $t['id'] ?>, '<?php echo htmlspecialchars(addslashes($t['nome'])) ?>')">Eliminar</button>
                        </div>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum tipo de conta criado</p>
            <p class="adm-empty-sub">Adicione tipos de conta para classificar o plano de contas.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title" id="tipoContaFormTitle">Adicionar Tipo de Conta</h2></div>
        <div class="adm-card-body">
            <input type="hidden" id="t-id" value="">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="t-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="t-codigo" maxlength="20" placeholder="ex: ATV-FIXO">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="t-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="t-nome" maxlength="100" placeholder="ex: Ativo Fixo">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="t-classe">Classe <span style="color:var(--adm-red)">*</span></label>
                    <select class="adm-select" id="t-classe">
                        <?php foreach ($classeLabels as $key => $label): ?>
                        <option value="<?php echo $key ?>"><?php echo $label ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="t-natureza">Natureza <span style="color:var(--adm-red)">*</span></label>
                    <select class="adm-select" id="t-natureza">
                        <?php foreach ($naturezaLabels as $key => $label): ?>
                        <option value="<?php echo $key ?>"><?php echo $label ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
            </div>
            <label class="adm-toggle" style="margin-bottom:var(--adm-sp-4)">
                <input type="checkbox" id="t-ativo" checked>
                <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                <span class="adm-toggle-label">Ativo</span>
            </label>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-outline" type="button" onclick="resetTipoContaForm()">Limpar</button>
                <button class="adm-btn adm-btn-primary" type="button" id="btnTipoContaSave" onclick="saveTipoConta()">Adicionar Tipo de Conta</button>
            </div>
        </div>
    </div>
</div>

<!-- ── Plano de Contas ────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-contas">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Plano de Contas</h2></div>
        <?php if ($contas): ?>
        <div class="adm-tree-wrap">
            <ul class="adm-tree adm-tree-root">
                <?php foreach ($byParent[0] ?? [] as $raiz) renderContaNode($raiz, $byParent, $classeLabels); ?>
            </ul>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhuma conta criada</p>
            <p class="adm-empty-sub">Adicione contas para construir o plano de contas.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6" id="contaFormCard">
        <div class="adm-card-header"><h2 class="adm-card-title" id="contaFormTitle">Adicionar Conta</h2></div>
        <div class="adm-card-body">
            <input type="hidden" id="a-id" value="">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="a-parent">Conta Pai</label>
                    <select class="adm-select" id="a-parent">
                        <option value="">— Raiz —</option>
                        <?php renderContaOptions($byParent); ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="a-account-type">Tipo de Conta</label>
                    <select class="adm-select" id="a-account-type">
                        <option value="">— Nenhum —</option>
                        <?php foreach ($tiposConta as $t): ?>
                        <option value="<?php echo (int) $t['id'] ?>"><?php echo htmlspecialchars($t['codigo'] . ' - ' . $t['nome']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="a-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="a-codigo" maxlength="20" placeholder="ex: 1.1.1">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="a-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="a-nome" maxlength="100" placeholder="ex: Caixa">
                </div>
            </div>
            <label class="adm-toggle" style="margin-bottom:var(--adm-sp-3)">
                <input type="checkbox" id="a-aceita-lancamento" checked>
                <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                <span class="adm-toggle-label">Aceita lançamentos</span>
            </label>
            <label class="adm-toggle" id="a-ativo-wrap" style="margin-bottom:var(--adm-sp-4);display:none">
                <input type="checkbox" id="a-ativo" checked>
                <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                <span class="adm-toggle-label">Ativo</span>
            </label>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-outline" type="button" onclick="resetContaForm()">Limpar</button>
                <button class="adm-btn adm-btn-primary" type="button" id="btnContaSave" onclick="saveConta()">Adicionar Conta</button>
            </div>
        </div>
    </div>
</div>

<script>
const CSRF = '<?php echo $csrf ?>';

// ── Tabs ─────────────────────────────────────────────────────
function switchTab(name, btn) {
    document.querySelectorAll('.adm-tab-panel').forEach(p => p.classList.remove('active'));
    document.querySelectorAll('.adm-tab').forEach(b => b.classList.remove('active'));
    document.getElementById('tab-' + name).classList.add('active');
    btn.classList.add('active');
}

document.addEventListener('DOMContentLoaded', () => {
    const tabs = ['tipos', 'contas'];
    const hash = location.hash.replace('#', '');
    const idx  = tabs.indexOf(hash);
    if (idx > 0) {
        const btn = document.querySelectorAll('#mainTabs .adm-tab')[idx];
        if (btn) switchTab(hash, btn);
    }
});

async function postJSON(url, payload, tab) {
    try {
        const res  = await fetch(url, {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            showToast(data.msg || 'Guardado com sucesso.');
            location.hash = tab;
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}

// ── Tipos de Conta ───────────────────────────────────────────
function resetTipoContaForm() {
    document.getElementById('t-id').value = '';
    document.getElementById('t-codigo').value = '';
    document.getElementById('t-codigo').disabled = false;
    document.getElementById('t-nome').value = '';
    document.getElementById('t-classe').value = 'ativo';
    document.getElementById('t-natureza').value = 'devedora';
    document.getElementById('t-ativo').checked = true;
    document.getElementById('tipoContaFormTitle').textContent = 'Adicionar Tipo de Conta';
    document.getElementById('btnTipoContaSave').textContent = 'Adicionar Tipo de Conta';
}

function editTipoConta(btn) {
    const row = btn.closest('tr');
    document.getElementById('t-id').value = row.dataset.id;
    document.getElementById('t-codigo').value = row.dataset.codigo;
    document.getElementById('t-codigo').disabled = true;
    document.getElementById('t-nome').value = row.dataset.nome;
    document.getElementById('t-classe').value = row.dataset.classe;
    document.getElementById('t-natureza').value = row.dataset.natureza;
    document.getElementById('t-ativo').checked = row.dataset.ativo === '1';
    document.getElementById('tipoContaFormTitle').textContent = 'Editar Tipo de Conta';
    document.getElementById('btnTipoContaSave').textContent = 'Guardar';
    document.getElementById('tab-tipos').scrollIntoView({behavior: 'smooth', block: 'end'});
}

function saveTipoConta() {
    const id     = document.getElementById('t-id').value;
    const codigo = document.getElementById('t-codigo').value.trim();
    const nome   = document.getElementById('t-nome').value.trim();

    if (!id && (!codigo || !nome)) { showToast('Código e nome são obrigatórios.', 'error'); return; }
    if (id && !nome) { showToast('O nome é obrigatório.', 'error'); return; }

    const payload = {
        id: id ? Number(id) : null,
        nome,
        classe: document.getElementById('t-classe').value,
        natureza: document.getElementById('t-natureza').value,
        ativo: document.getElementById('t-ativo').checked,
        csrf: CSRF
    };
    if (!id) payload.codigo = codigo;

    postJSON('/nexora/api/contab_tipo_conta_save', payload, 'tipos');
}

function deleteTipoConta(id, nome) {
    openConfirm(
        'Eliminar tipo de conta',
        'Eliminar o tipo de conta "' + nome + '"? Esta ação não pode ser revertida.',
        () => postJSON('/nexora/api/contab_tipo_conta_remover', { id, csrf: CSRF }, 'tipos')
    );
}

// ── Plano de Contas ────────────────────────────────────────────
function resetContaForm() {
    document.getElementById('a-id').value = '';
    document.getElementById('a-parent').value = '';
    document.getElementById('a-codigo').value = '';
    document.getElementById('a-codigo').disabled = false;
    document.getElementById('a-nome').value = '';
    document.getElementById('a-account-type').value = '';
    document.getElementById('a-aceita-lancamento').checked = true;
    document.getElementById('a-ativo-wrap').style.display = 'none';
    document.getElementById('a-ativo').checked = true;
    document.getElementById('contaFormTitle').textContent = 'Adicionar Conta';
    document.getElementById('btnContaSave').textContent = 'Adicionar Conta';
}

function editConta(btn) {
    const el = btn.closest('.adm-tree-card');
    document.getElementById('a-id').value = el.dataset.id;
    document.getElementById('a-parent').value = el.dataset.parentId || '';
    document.getElementById('a-codigo').value = el.dataset.codigo;
    document.getElementById('a-codigo').disabled = true;
    document.getElementById('a-nome').value = el.dataset.nome;
    document.getElementById('a-account-type').value = el.dataset.accountTypeId || '';
    document.getElementById('a-aceita-lancamento').checked = el.dataset.aceitaLancamento === '1';
    document.getElementById('a-ativo-wrap').style.display = '';
    document.getElementById('a-ativo').checked = el.dataset.ativo === '1';
    document.getElementById('contaFormTitle').textContent = 'Editar Conta';
    document.getElementById('btnContaSave').textContent = 'Guardar';
    document.getElementById('contaFormCard').scrollIntoView({behavior: 'smooth', block: 'end'});
}

function saveConta() {
    const id     = document.getElementById('a-id').value;
    const codigo = document.getElementById('a-codigo').value.trim();
    const nome   = document.getElementById('a-nome').value.trim();

    if (!id && (!codigo || !nome)) { showToast('Código e nome são obrigatórios.', 'error'); return; }
    if (id && !nome) { showToast('O nome é obrigatório.', 'error'); return; }

    const parent      = document.getElementById('a-parent').value;
    const accountType = document.getElementById('a-account-type').value;

    const payload = {
        id: id ? Number(id) : null,
        nome,
        parent_id: parent ? Number(parent) : null,
        account_type_id: accountType ? Number(accountType) : null,
        aceita_lancamento: document.getElementById('a-aceita-lancamento').checked,
        csrf: CSRF
    };
    if (!id) {
        payload.codigo = codigo;
    } else {
        payload.ativo = document.getElementById('a-ativo').checked;
    }

    postJSON('/nexora/api/contab_conta_save', payload, 'contas');
}

function deleteConta(btn) {
    const el   = btn.closest('.adm-tree-card');
    const id   = Number(el.dataset.id);
    const nome = el.dataset.nome;
    openConfirm(
        'Eliminar conta',
        'Eliminar a conta "' + nome + '"? Esta ação não pode ser revertida.',
        () => postJSON('/nexora/api/contab_conta_remover', { id, csrf: CSRF }, 'contas')
    );
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
