<?php

    $taxGroups = $app->nexora->call('GET', '/api/contabilidade/tax-groups')['body'] ?? [];
    $taxas     = $app->nexora->call('GET', '/api/contabilidade/taxes')['body'] ?? [];

    foreach ($taxas as &$t) {
        $detail = $app->nexora->call('GET', '/api/contabilidade/taxes/' . $t['id'])['body'] ?? [];
        $t['regras'] = $detail['regras'] ?? [];
    }
    unset($t);

    $taxGroupLabels = array_column($taxGroups, 'nome', 'id');

    $tipoLabels = [
        'iva'    => 'IVA',
        'isento' => 'Isento',
        'zero'   => 'Taxa Zero',
        'outro'  => 'Outro',
    ];

    $regrasPorTaxa = [];
    foreach ($taxas as $t) {
        $regrasPorTaxa[$t['id']] = $t['regras'];
    }

    $fiscalPeriods   = $app->nexora->call('GET', '/api/contabilidade/fiscal-periods')['body'] ?? [];
    $taxTransactions = $app->nexora->call('GET', '/api/contabilidade/tax-transactions')['body'] ?? [];

    $taxaLabels = [];
    foreach ($taxas as $t) {
        $taxaLabels[$t['id']] = $t['codigo'] . ' - ' . $t['nome'];
    }

    $periodoLabels = [];
    foreach ($fiscalPeriods as $p) {
        $periodoLabels[$p['id']] = sprintf('%02d/%d', $p['mes'], $p['ano']);
    }

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Impostos';
    $activePage = 'contab_impostos';
    $breadcrumb = [['Admin', '/nexora/'], ['Contabilidade', ''], ['Impostos', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Impostos</h1>
</div>

<div class="adm-tabs" id="mainTabs">
    <button class="adm-tab active" onclick="switchTab('grupos',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg>
        Grupos
        <?php if (count($taxGroups)): ?><span class="adm-tab-badge"><?php echo count($taxGroups) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('taxas',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="19" y1="5" x2="5" y2="19"/><circle cx="6.5" cy="6.5" r="2.5"/><circle cx="17.5" cy="17.5" r="2.5"/></svg>
        Taxas
        <?php if (count($taxas)): ?><span class="adm-tab-badge"><?php echo count($taxas) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('transacoes',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 3v18h18"/><path d="M18.7 8l-5.1 5.2-2.8-2.7L7 14.3"/></svg>
        Transações
        <?php if (count($taxTransactions)): ?><span class="adm-tab-badge"><?php echo count($taxTransactions) ?></span><?php endif; ?>
    </button>
</div>

<!-- ── Grupos de Imposto ──────────────────────────────────────── -->
<div class="adm-tab-panel active" id="tab-grupos">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Grupos de Imposto</h2></div>
        <?php if ($taxGroups): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Código</th><th>Nome</th><th>Estado</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($taxGroups as $g): ?>
                <tr data-id="<?php echo (int) $g['id'] ?>"
                    data-codigo="<?php echo htmlspecialchars($g['codigo']) ?>"
                    data-nome="<?php echo htmlspecialchars($g['nome']) ?>"
                    data-ativo="<?php echo $g['ativo'] ? '1' : '0' ?>">
                    <td class="adm-text-muted"><?php echo htmlspecialchars($g['codigo']) ?></td>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($g['nome']) ?></td>
                    <td><span class="adm-badge <?php echo $g['ativo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $g['ativo'] ? 'Ativo' : 'Inativo' ?></span></td>
                    <td>
                        <div class="adm-actions">
                            <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" onclick="editGrupo(this)">Editar</button>
                        </div>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum grupo de imposto criado</p>
            <p class="adm-empty-sub">Adicione grupos para organizar as taxas de imposto.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title" id="grupoFormTitle">Adicionar Grupo</h2></div>
        <div class="adm-card-body">
            <input type="hidden" id="g-id" value="">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="g-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="g-codigo" maxlength="20" placeholder="ex: IVA">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="g-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="g-nome" maxlength="100" placeholder="ex: Imposto sobre o Valor Acrescentado">
                </div>
            </div>
            <label class="adm-toggle" id="g-ativo-wrap" style="margin-bottom:var(--adm-sp-4);display:none">
                <input type="checkbox" id="g-ativo" checked>
                <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                <span class="adm-toggle-label">Ativo</span>
            </label>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-outline" type="button" onclick="resetGrupoForm()">Limpar</button>
                <button class="adm-btn adm-btn-primary" type="button" id="btnGrupoSave" onclick="saveGrupo()">Adicionar Grupo</button>
            </div>
        </div>
    </div>
</div>

<!-- ── Taxas ──────────────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-taxas">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Taxas</h2></div>
        <?php if ($taxas): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Código</th><th>Nome</th><th>Taxa</th><th>Tipo</th><th>Grupo</th><th>Estado</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($taxas as $t): ?>
                <tr data-id="<?php echo (int) $t['id'] ?>"
                    data-codigo="<?php echo htmlspecialchars($t['codigo']) ?>"
                    data-nome="<?php echo htmlspecialchars($t['nome']) ?>"
                    data-taxa="<?php echo (float) $t['taxa'] ?>"
                    data-tipo="<?php echo htmlspecialchars($t['tipo']) ?>"
                    data-tax-group-id="<?php echo $t['tax_group_id'] !== null ? (int) $t['tax_group_id'] : '' ?>"
                    data-ativo="<?php echo $t['ativo'] ? '1' : '0' ?>">
                    <td class="adm-text-muted"><?php echo htmlspecialchars($t['codigo']) ?></td>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($t['nome']) ?></td>
                    <td><?php echo number_format((float) $t['taxa'], 2, ',', '.') ?>%</td>
                    <td><?php echo htmlspecialchars($tipoLabels[$t['tipo']] ?? $t['tipo']) ?></td>
                    <td class="adm-text-muted"><?php echo htmlspecialchars($t['tax_group_id'] !== null ? ($taxGroupLabels[$t['tax_group_id']] ?? ('#' . $t['tax_group_id'])) : '—') ?></td>
                    <td><span class="adm-badge <?php echo $t['ativo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $t['ativo'] ? 'Ativo' : 'Inativo' ?></span></td>
                    <td>
                        <div class="adm-actions">
                            <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" onclick="editTaxa(this)">Editar</button>
                        </div>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhuma taxa criada</p>
            <p class="adm-empty-sub">Adicione taxas para aplicar a documentos e transações.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title" id="taxaFormTitle">Adicionar Taxa</h2></div>
        <div class="adm-card-body">
            <input type="hidden" id="x-id" value="">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="x-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="x-codigo" maxlength="30" placeholder="ex: IVA16">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="x-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="x-nome" maxlength="120" placeholder="ex: IVA 16%">
                </div>
            </div>
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="x-taxa">Taxa % <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="number" id="x-taxa" min="0" step="0.0001" placeholder="0.00">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="x-tipo">Tipo</label>
                    <select class="adm-select" id="x-tipo">
                        <?php foreach ($tipoLabels as $key => $label): ?>
                        <option value="<?php echo $key ?>"><?php echo $label ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="x-grupo">Grupo</label>
                    <select class="adm-select" id="x-grupo">
                        <option value="">— Nenhum —</option>
                        <?php foreach ($taxGroups as $g): ?>
                        <option value="<?php echo (int) $g['id'] ?>"><?php echo htmlspecialchars($g['codigo'] . ' - ' . $g['nome']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
            </div>
            <label class="adm-toggle" id="x-ativo-wrap" style="margin-bottom:var(--adm-sp-4);display:none">
                <input type="checkbox" id="x-ativo" checked>
                <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                <span class="adm-toggle-label">Ativo</span>
            </label>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-outline" type="button" onclick="resetTaxaForm()">Limpar</button>
                <button class="adm-btn adm-btn-primary" type="button" id="btnTaxaSave" onclick="saveTaxa()">Adicionar Taxa</button>
            </div>
        </div>
    </div>

    <div class="adm-card">
        <div class="adm-card-header"><h2 class="adm-card-title">Faixas de Taxa</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-group">
                <label class="adm-label" for="r-taxa">Taxa</label>
                <select class="adm-select" id="r-taxa" onchange="loadRegras()">
                    <option value="">Seleciona uma taxa</option>
                    <?php foreach ($taxas as $t): ?>
                    <option value="<?php echo (int) $t['id'] ?>"><?php echo htmlspecialchars($t['codigo'] . ' - ' . $t['nome']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>

            <div class="adm-table-wrap adm-mb-4">
                <table class="adm-table">
                    <thead>
                        <tr><th>Valor Mínimo</th><th>Valor Máximo</th><th>Taxa</th><th>Ordem</th></tr>
                    </thead>
                    <tbody id="regrasBody">
                        <tr><td colspan="4" class="adm-text-muted">Seleciona uma taxa para ver as faixas.</td></tr>
                    </tbody>
                </table>
            </div>

            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="rg-min">Valor Mínimo</label>
                    <input class="adm-input" type="number" id="rg-min" min="0" step="0.01" placeholder="0.00">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="rg-max">Valor Máximo</label>
                    <input class="adm-input" type="number" id="rg-max" min="0" step="0.01" placeholder="(sem limite)">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="rg-taxa">Taxa % <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="number" id="rg-taxa" min="0" step="0.0001" placeholder="0.00">
                </div>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="rg-ordem">Ordem</label>
                <input class="adm-input" type="number" id="rg-ordem" min="0" step="1" placeholder="0" style="max-width:200px">
            </div>
            <button class="adm-btn adm-btn-primary" type="button" onclick="addRegra()">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                Adicionar Regra
            </button>
        </div>
    </div>
</div>

<!-- ── Transações de Imposto ──────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-transacoes">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Transações de Imposto</h2></div>
        <?php if ($taxTransactions): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Data</th><th>Taxa</th><th>Referência</th><th>Período</th><th>Base Tributável</th><th>Taxa Aplicada</th><th>Valor Imposto</th></tr>
                </thead>
                <tbody>
                <?php foreach ($taxTransactions as $tt): ?>
                <tr>
                    <td><?php echo htmlspecialchars(substr((string) $tt['transaction_date'], 0, 10)) ?></td>
                    <td><?php echo htmlspecialchars($taxaLabels[$tt['tax_id']] ?? ('#' . $tt['tax_id'])) ?></td>
                    <td class="adm-text-muted"><?php echo htmlspecialchars($tt['referencia_tipo'] . ($tt['referencia_id'] !== null ? ' #' . $tt['referencia_id'] : '')) ?></td>
                    <td class="adm-text-muted"><?php echo htmlspecialchars($tt['fiscal_period_id'] !== null ? ($periodoLabels[$tt['fiscal_period_id']] ?? ('#' . $tt['fiscal_period_id'])) : '—') ?></td>
                    <td><?php echo number_format((float) $tt['base_tributavel'], 2, ',', '.') ?></td>
                    <td><?php echo number_format((float) $tt['taxa_aplicada'], 2, ',', '.') ?>%</td>
                    <td class="adm-fw-600"><?php echo number_format((float) $tt['valor_imposto'], 2, ',', '.') ?></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhuma transação de imposto registada</p>
            <p class="adm-empty-sub">Registe transações para apurar o imposto devido.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card">
        <div class="adm-card-header"><h2 class="adm-card-title">Registar Transação</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="tt-taxa">Taxa <span style="color:var(--adm-red)">*</span></label>
                    <select class="adm-select" id="tt-taxa">
                        <option value="">Seleciona uma taxa</option>
                        <?php foreach ($taxas as $t): ?>
                        <option value="<?php echo (int) $t['id'] ?>"><?php echo htmlspecialchars($t['codigo'] . ' - ' . $t['nome']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="tt-data">Data <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="date" id="tt-data">
                </div>
            </div>
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="tt-tipo">Tipo de Referência <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="tt-tipo" maxlength="30" placeholder="ex: venda, compra, manual">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="tt-ref-id">ID da Referência</label>
                    <input class="adm-input" type="number" id="tt-ref-id" min="1" placeholder="opcional">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="tt-periodo">Período Fiscal</label>
                    <select class="adm-select" id="tt-periodo">
                        <option value="">— Nenhum —</option>
                        <?php foreach ($fiscalPeriods as $p): ?>
                        <option value="<?php echo (int) $p['id'] ?>"><?php echo htmlspecialchars(sprintf('%02d/%d', $p['mes'], $p['ano'])) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="tt-base">Base Tributável <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="number" id="tt-base" min="0" step="0.01" placeholder="0.00">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="tt-taxa-aplicada">Taxa Aplicada %</label>
                    <input class="adm-input" type="number" id="tt-taxa-aplicada" min="0" step="0.0001" placeholder="Automático (faixas)">
                </div>
            </div>
            <button class="adm-btn adm-btn-primary" type="button" onclick="registarTransacao()">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                Registar Transação
            </button>
        </div>
    </div>
</div>

<script>
const CSRF = '<?php echo $csrf ?>';
const REGRAS_POR_TAXA = <?php echo json_encode($regrasPorTaxa, JSON_UNESCAPED_UNICODE) ?>;

// ── Tabs ─────────────────────────────────────────────────────
function switchTab(name, btn) {
    document.querySelectorAll('.adm-tab-panel').forEach(p => p.classList.remove('active'));
    document.querySelectorAll('.adm-tab').forEach(b => b.classList.remove('active'));
    document.getElementById('tab-' + name).classList.add('active');
    btn.classList.add('active');
}

document.addEventListener('DOMContentLoaded', () => {
    const tabs = ['grupos', 'taxas', 'transacoes'];
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

// ── Grupos ───────────────────────────────────────────────────
function resetGrupoForm() {
    document.getElementById('g-id').value = '';
    document.getElementById('g-codigo').value = '';
    document.getElementById('g-codigo').disabled = false;
    document.getElementById('g-nome').value = '';
    document.getElementById('g-ativo-wrap').style.display = 'none';
    document.getElementById('g-ativo').checked = true;
    document.getElementById('grupoFormTitle').textContent = 'Adicionar Grupo';
    document.getElementById('btnGrupoSave').textContent = 'Adicionar Grupo';
}

function editGrupo(btn) {
    const row = btn.closest('tr');
    document.getElementById('g-id').value = row.dataset.id;
    document.getElementById('g-codigo').value = row.dataset.codigo;
    document.getElementById('g-codigo').disabled = true;
    document.getElementById('g-nome').value = row.dataset.nome;
    document.getElementById('g-ativo-wrap').style.display = '';
    document.getElementById('g-ativo').checked = row.dataset.ativo === '1';
    document.getElementById('grupoFormTitle').textContent = 'Editar Grupo';
    document.getElementById('btnGrupoSave').textContent = 'Guardar';
    document.getElementById('grupoFormTitle').scrollIntoView({behavior: 'smooth', block: 'end'});
}

function saveGrupo() {
    const id     = document.getElementById('g-id').value;
    const codigo = document.getElementById('g-codigo').value.trim();
    const nome   = document.getElementById('g-nome').value.trim();

    if (!id && (!codigo || !nome)) { showToast('Código e nome são obrigatórios.', 'error'); return; }
    if (id && !nome) { showToast('O nome é obrigatório.', 'error'); return; }

    const payload = { id: id ? Number(id) : null, nome, csrf: CSRF };
    if (!id) {
        payload.codigo = codigo;
    } else {
        payload.codigo = codigo;
        payload.ativo  = document.getElementById('g-ativo').checked;
    }

    postJSON('/nexora/api/contab_grupo_imposto_save', payload, 'grupos');
}

// ── Taxas ────────────────────────────────────────────────────
function resetTaxaForm() {
    document.getElementById('x-id').value = '';
    document.getElementById('x-codigo').value = '';
    document.getElementById('x-codigo').disabled = false;
    document.getElementById('x-nome').value = '';
    document.getElementById('x-taxa').value = '';
    document.getElementById('x-tipo').value = 'iva';
    document.getElementById('x-grupo').value = '';
    document.getElementById('x-ativo-wrap').style.display = 'none';
    document.getElementById('x-ativo').checked = true;
    document.getElementById('taxaFormTitle').textContent = 'Adicionar Taxa';
    document.getElementById('btnTaxaSave').textContent = 'Adicionar Taxa';
}

function editTaxa(btn) {
    const row = btn.closest('tr');
    document.getElementById('x-id').value = row.dataset.id;
    document.getElementById('x-codigo').value = row.dataset.codigo;
    document.getElementById('x-codigo').disabled = true;
    document.getElementById('x-nome').value = row.dataset.nome;
    document.getElementById('x-taxa').value = row.dataset.taxa;
    document.getElementById('x-tipo').value = row.dataset.tipo;
    document.getElementById('x-grupo').value = row.dataset.taxGroupId || '';
    document.getElementById('x-ativo-wrap').style.display = '';
    document.getElementById('x-ativo').checked = row.dataset.ativo === '1';
    document.getElementById('taxaFormTitle').textContent = 'Editar Taxa';
    document.getElementById('btnTaxaSave').textContent = 'Guardar';
    document.getElementById('taxaFormTitle').scrollIntoView({behavior: 'smooth', block: 'end'});
}

function saveTaxa() {
    const id     = document.getElementById('x-id').value;
    const codigo = document.getElementById('x-codigo').value.trim();
    const nome   = document.getElementById('x-nome').value.trim();
    const taxa   = document.getElementById('x-taxa').value;

    if (!id && (!codigo || !nome)) { showToast('Código e nome são obrigatórios.', 'error'); return; }
    if (id && !nome) { showToast('O nome é obrigatório.', 'error'); return; }

    const grupo = document.getElementById('x-grupo').value;
    const payload = {
        id: id ? Number(id) : null,
        codigo,
        nome,
        taxa: Number(taxa || 0),
        tipo: document.getElementById('x-tipo').value,
        tax_group_id: grupo ? Number(grupo) : null,
        csrf: CSRF
    };
    if (id) payload.ativo = document.getElementById('x-ativo').checked;

    postJSON('/nexora/api/contab_taxa_save', payload, 'taxas');
}

// ── Faixas de Taxa ───────────────────────────────────────────
function loadRegras() {
    const taxId = document.getElementById('r-taxa').value;
    const body  = document.getElementById('regrasBody');
    if (!taxId) {
        body.innerHTML = '<tr><td colspan="4" class="adm-text-muted">Seleciona uma taxa para ver as faixas.</td></tr>';
        return;
    }
    const regras = REGRAS_POR_TAXA[taxId] || [];
    if (!regras.length) {
        body.innerHTML = '<tr><td colspan="4" class="adm-text-muted">Nenhuma faixa definida.</td></tr>';
        return;
    }
    body.innerHTML = regras.map(r => `
        <tr>
            <td>${Number(r.valor_minimo).toFixed(2)}</td>
            <td>${r.valor_maximo === null ? 'Sem limite' : Number(r.valor_maximo).toFixed(2)}</td>
            <td>${Number(r.taxa).toFixed(2)}%</td>
            <td>${r.ordem}</td>
        </tr>
    `).join('');
}

function addRegra() {
    const taxId = document.getElementById('r-taxa').value;
    const taxaPct = document.getElementById('rg-taxa').value;

    if (!taxId) { showToast('Seleciona uma taxa.', 'error'); return; }
    if (taxaPct === '') { showToast('A taxa da faixa é obrigatória.', 'error'); return; }

    const max = document.getElementById('rg-max').value;
    const payload = {
        id: Number(taxId),
        valor_minimo: Number(document.getElementById('rg-min').value || 0),
        valor_maximo: max === '' ? null : Number(max),
        taxa: Number(taxaPct),
        ordem: Number(document.getElementById('rg-ordem').value || 0),
        csrf: CSRF
    };

    postJSON('/nexora/api/contab_regra_taxa_save', payload, 'taxas');
}

// ── Transações de Imposto ─────────────────────────────────────
function registarTransacao() {
    const taxId = document.getElementById('tt-taxa').value;
    const tipo  = document.getElementById('tt-tipo').value.trim();
    const data  = document.getElementById('tt-data').value;
    const base  = document.getElementById('tt-base').value;

    if (!taxId) { showToast('Seleciona uma taxa.', 'error'); return; }
    if (!tipo) { showToast('O tipo de referência é obrigatório.', 'error'); return; }
    if (!data) { showToast('A data é obrigatória.', 'error'); return; }
    if (base === '') { showToast('A base tributável é obrigatória.', 'error'); return; }

    const refId    = document.getElementById('tt-ref-id').value;
    const periodo  = document.getElementById('tt-periodo').value;
    const taxaApl  = document.getElementById('tt-taxa-aplicada').value;

    const payload = {
        tax_id: Number(taxId),
        referencia_tipo: tipo,
        referencia_id: refId === '' ? null : Number(refId),
        fiscal_period_id: periodo === '' ? null : Number(periodo),
        base_tributavel: Number(base),
        taxa_aplicada: taxaApl === '' ? null : Number(taxaApl),
        transaction_date: data,
        csrf: CSRF
    };

    postJSON('/nexora/api/contab_transacao_imposto_save', payload, 'transacoes');
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
