<?php

$companiesResp = $app->nexora->call('GET', '/api/companies');
$companies     = $companiesResp['body'] ?? [];
$company       = $companies[0] ?? null;

$csrf       = $app->security->csrfToken();
$pageTitle  = 'Empresa & Licença';
$activePage = 'empresa';
$breadcrumb = [['Admin', '/nexora/'], ['Administração', ''], ['Empresa & Licença', '']];

$tax      = null;
$branches = [];
$licenses = [];

if ($company) {
    $companyId = $company['id'];

    $taxResp = $app->nexora->call('GET', "/api/companies/$companyId/tax-info");
    $tax     = $taxResp['status'] === 200 ? $taxResp['body'] : null;

    $branchesResp = $app->nexora->call('GET', "/api/companies/$companyId/branches");
    $branches     = $branchesResp['body'] ?? [];

    $licensesResp = $app->nexora->call('GET', "/api/companies/$companyId/licenses");
    $licenses     = $licensesResp['body'] ?? [];
}

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Empresa &amp; Licença</h1>
</div>

<?php if ($app->request->queryString('msg') !== ''): ?>
<div class="adm-alert adm-alert--success">
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
    <?= htmlspecialchars($app->request->queryString('msg')) ?>
</div>
<?php endif; ?>

<?php if (! $company): ?>

<div class="adm-card">
    <div class="adm-empty">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M3 21h18"/><path d="M5 21V7l8-4v18"/><path d="M19 21V11l-6-4"/>
        </svg>
        <p class="adm-empty-title">Nenhuma empresa encontrada</p>
        <p class="adm-empty-sub">A conta de serviço não está associada a nenhuma empresa.</p>
    </div>
</div>

<?php else: ?>

<div id="formMsg"></div>

<div class="adm-tabs" id="mainTabs">
    <button class="adm-tab active" onclick="switchTab('dados',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 21h18"/><path d="M5 21V7l8-4v18"/><path d="M19 21V11l-6-4"/></svg>
        Dados
    </button>
    <button class="adm-tab" onclick="switchTab('fiscal',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
        Fiscal
    </button>
    <button class="adm-tab" onclick="switchTab('filiais',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 21h18"/><path d="M5 21V7l4-4 4 4v14"/><path d="M13 21V11l4-2 4 2v10"/></svg>
        Filiais
        <?php if (count($branches)): ?><span class="adm-tab-badge"><?= count($branches) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('licencas',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
        Licenças
        <?php if (count($licenses)): ?><span class="adm-tab-badge"><?= count($licenses) ?></span><?php endif; ?>
    </button>
</div>

<!-- Tab: Dados -->
<div class="adm-tab-panel active" id="tab-dados">
    <form id="empresaForm">
        <input type="hidden" name="csrf_token" value="<?= $csrf ?>">
        <div class="adm-card adm-mb-6">
            <div class="adm-card-header"><h2 class="adm-card-title">Dados da Empresa</h2></div>
            <div class="adm-card-body">
                <div class="adm-form-row">
                    <div class="adm-form-group">
                        <label class="adm-label">Código</label>
                        <input class="adm-input" type="text" value="<?= $app->view->field($company, 'codigo') ?>" disabled>
                    </div>
                    <div class="adm-form-group">
                        <label class="adm-label">Tipo</label>
                        <input class="adm-input" type="text" value="<?= $app->view->field($company, 'tipo') ?>" disabled>
                    </div>
                </div>
                <div class="adm-form-row">
                    <div class="adm-form-group">
                        <label class="adm-label" for="f-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                        <input class="adm-input" type="text" id="f-nome" name="nome" required maxlength="150" value="<?= $app->view->field($company, 'nome') ?>">
                    </div>
                    <div class="adm-form-group">
                        <label class="adm-label" for="f-nome_comercial">Nome Comercial</label>
                        <input class="adm-input" type="text" id="f-nome_comercial" name="nome_comercial" maxlength="150" value="<?= $app->view->field($company, 'nome_comercial') ?>">
                    </div>
                </div>
                <div class="adm-form-row-3">
                    <div class="adm-form-group">
                        <label class="adm-label" for="f-status">Estado</label>
                        <select class="adm-select" id="f-status" name="status">
                            <?php foreach (['ativa' => 'Ativa', 'suspensa' => 'Suspensa', 'inativa' => 'Inativa'] as $val => $label): ?>
                            <option value="<?= $val ?>" <?= ($company['status'] ?? '') === $val ? 'selected' : '' ?>><?= $label ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="adm-form-group">
                        <label class="adm-label" for="f-moeda_base">Moeda Base</label>
                        <input class="adm-input" type="text" id="f-moeda_base" name="moeda_base" maxlength="10" value="<?= $app->view->field($company, 'moeda_base') ?>">
                    </div>
                    <div class="adm-form-group">
                        <label class="adm-label" for="f-timezone">Fuso Horário</label>
                        <input class="adm-input" type="text" id="f-timezone" name="timezone" maxlength="60" value="<?= $app->view->field($company, 'timezone') ?>">
                    </div>
                </div>
            </div>
        </div>
        <div style="display:flex;gap:var(--adm-sp-3);justify-content:flex-end;padding-bottom:var(--adm-sp-8)">
            <button type="submit" class="adm-btn adm-btn-primary" id="btnSaveEmpresa">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/>
                    <polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/>
                </svg>
                Guardar alterações
            </button>
        </div>
    </form>
</div>

<!-- Tab: Fiscal -->
<div class="adm-tab-panel" id="tab-fiscal">
    <form id="fiscalForm">
        <input type="hidden" name="csrf_token" value="<?= $csrf ?>">
        <div class="adm-card adm-mb-6">
            <div class="adm-card-header"><h2 class="adm-card-title">Informação Fiscal</h2></div>
            <div class="adm-card-body">
                <?php if (! $tax): ?>
                <div class="adm-alert adm-alert--info" style="margin-bottom:var(--adm-sp-5)">
                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>
                    Ainda não existe informação fiscal registada para esta empresa.
                </div>
                <?php endif; ?>
                <div class="adm-form-row">
                    <div class="adm-form-group">
                        <label class="adm-label" for="f-nuit">NUIT <span style="color:var(--adm-red)">*</span></label>
                        <input class="adm-input" type="text" id="f-nuit" name="nuit" required maxlength="30" value="<?= $app->view->field($tax, 'nuit') ?>">
                    </div>
                    <div class="adm-form-group">
                        <label class="adm-label" for="f-regime_iva">Regime de IVA</label>
                        <input class="adm-input" type="text" id="f-regime_iva" name="regime_iva" maxlength="50" placeholder="ex: normal, isento, simplificado" value="<?= $app->view->field($tax, 'regime_iva') ?>">
                    </div>
                </div>
                <div class="adm-form-row-3">
                    <div class="adm-form-group">
                        <label class="adm-label" for="f-taxa_iva">Taxa de IVA Padrão (%)</label>
                        <input class="adm-input" type="number" id="f-taxa_iva" name="taxa_iva_padrao" min="0" step="0.01" value="<?= $app->view->field($tax, 'taxa_iva_padrao', '17.00') ?>">
                    </div>
                    <div class="adm-form-group">
                        <label class="adm-label" for="f-inicio_atividade">Início de Atividade</label>
                        <input class="adm-input" type="date" id="f-inicio_atividade" name="inicio_atividade" value="<?= $tax && ! empty($tax['inicio_atividade']) ? date('Y-m-d', strtotime($tax['inicio_atividade'])) : '' ?>">
                    </div>
                    <div class="adm-form-group">
                        <label class="adm-label" for="f-reparticao_fiscal">Repartição Fiscal</label>
                        <input class="adm-input" type="text" id="f-reparticao_fiscal" name="reparticao_fiscal" maxlength="150" value="<?= $app->view->field($tax, 'reparticao_fiscal') ?>">
                    </div>
                </div>
            </div>
        </div>
        <div style="display:flex;gap:var(--adm-sp-3);justify-content:flex-end;padding-bottom:var(--adm-sp-8)">
            <button type="submit" class="adm-btn adm-btn-primary" id="btnSaveFiscal">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/>
                    <polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/>
                </svg>
                Guardar dados fiscais
            </button>
        </div>
    </form>
</div>

<!-- Tab: Filiais -->
<div class="adm-tab-panel" id="tab-filiais">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Filiais</h2></div>
        <?php if ($branches): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Código</th><th>Nome</th><th>Estado</th><th>Principal</th><th>Criada em</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($branches as $b): ?>
                <tr>
                    <td><div class="adm-fw-600"><?= htmlspecialchars($b['codigo']) ?></div></td>
                    <td><?= htmlspecialchars($b['nome']) ?></td>
                    <td>
                        <?php if ($b['status'] === 'ativa'): ?>
                        <span class="adm-badge adm-badge--green">Ativa</span>
                        <?php else: ?>
                        <span class="adm-badge adm-badge--gray">Inativa</span>
                        <?php endif; ?>
                    </td>
                    <td><?php if (! empty($b['principal'])): ?><span class="adm-badge adm-badge--blue">Principal</span><?php endif; ?></td>
                    <td class="adm-text-muted"><?= date('d/m/Y', strtotime($b['created_at'])) ?></td>
                    <td>
                        <div class="adm-actions">
                            <?php if ($b['status'] === 'ativa'): ?>
                            <button class="adm-btn adm-btn-ghost adm-btn-sm" onclick="mudarEstadoBranch(<?= $b['id'] ?>, 'inativa')">Desativar</button>
                            <?php else: ?>
                            <button class="adm-btn adm-btn-ghost adm-btn-sm" onclick="mudarEstadoBranch(<?= $b['id'] ?>, 'ativa')">Ativar</button>
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
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M3 21h18"/><path d="M5 21V7l4-4 4 4v14"/><path d="M13 21V11l4-2 4 2v10"/></svg>
            <p class="adm-empty-title">Nenhuma filial registada</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Nova Filial</h2></div>
        <div class="adm-card-body">
            <form id="branchForm">
                <input type="hidden" name="csrf_token" value="<?= $csrf ?>">
                <div class="adm-form-row-3">
                    <div class="adm-form-group">
                        <label class="adm-label" for="f-branch-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                        <input class="adm-input" type="text" id="f-branch-codigo" name="codigo" required maxlength="30" placeholder="ex: MPT-01">
                    </div>
                    <div class="adm-form-group">
                        <label class="adm-label" for="f-branch-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                        <input class="adm-input" type="text" id="f-branch-nome" name="nome" required maxlength="150" placeholder="ex: Loja Maputo">
                    </div>
                    <div class="adm-form-group">
                        <label class="adm-label" style="margin-bottom:var(--adm-sp-3)">&nbsp;</label>
                        <label class="adm-toggle">
                            <input type="checkbox" name="principal" value="1">
                            <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                            <span class="adm-toggle-label">Filial principal</span>
                        </label>
                    </div>
                </div>
                <div style="display:flex;justify-content:flex-end">
                    <button type="submit" class="adm-btn adm-btn-primary" id="btnSaveBranch">
                        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                        Adicionar Filial
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Tab: Licenças -->
<div class="adm-tab-panel" id="tab-licencas">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Licenças</h2></div>
        <?php if ($licenses): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Plano</th><th>Limite Utilizadores</th><th>Limite Filiais</th><th>Início</th><th>Expira em</th><th>Estado</th></tr>
                </thead>
                <tbody>
                <?php foreach ($licenses as $l):
                    $licBadge = match ($l['status']) {
                        'ativa'    => ['adm-badge--green', 'Ativa'],
                        'expirada' => ['adm-badge--red', 'Expirada'],
                        default    => ['adm-badge--yellow', 'Suspensa'],
                    };
                ?>
                <tr>
                    <td><div class="adm-fw-600"><?= htmlspecialchars(ucfirst($l['plano'])) ?></div></td>
                    <td><?= $l['limite_usuarios'] ?? '—' ?></td>
                    <td><?= $l['limite_filiais'] ?? '—' ?></td>
                    <td class="adm-text-muted"><?= date('d/m/Y', strtotime($l['inicia_em'])) ?></td>
                    <td class="adm-text-muted"><?= ! empty($l['expira_em']) ? date('d/m/Y', strtotime($l['expira_em'])) : '—' ?></td>
                    <td><span class="adm-badge <?= $licBadge[0] ?>"><?= $licBadge[1] ?></span></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
            <p class="adm-empty-title">Nenhuma licença registada</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Nova Licença</h2></div>
        <div class="adm-card-body">
            <form id="licencaForm">
                <input type="hidden" name="csrf_token" value="<?= $csrf ?>">
                <div class="adm-form-row-3">
                    <div class="adm-form-group">
                        <label class="adm-label" for="f-lic-plano">Plano <span style="color:var(--adm-red)">*</span></label>
                        <select class="adm-select" id="f-lic-plano" name="plano" required>
                            <option value="starter">Starter</option>
                            <option value="professional">Professional</option>
                            <option value="enterprise">Enterprise</option>
                        </select>
                    </div>
                    <div class="adm-form-group">
                        <label class="adm-label" for="f-lic-limite_usuarios">Limite de Utilizadores</label>
                        <input class="adm-input" type="number" id="f-lic-limite_usuarios" name="limite_usuarios" min="1" placeholder="sem limite">
                    </div>
                    <div class="adm-form-group">
                        <label class="adm-label" for="f-lic-limite_filiais">Limite de Filiais</label>
                        <input class="adm-input" type="number" id="f-lic-limite_filiais" name="limite_filiais" min="1" placeholder="sem limite">
                    </div>
                </div>
                <div class="adm-form-row">
                    <div class="adm-form-group">
                        <label class="adm-label" for="f-lic-inicia_em">Início <span style="color:var(--adm-red)">*</span></label>
                        <input class="adm-input" type="date" id="f-lic-inicia_em" name="inicia_em" required value="<?= date('Y-m-d') ?>">
                    </div>
                    <div class="adm-form-group">
                        <label class="adm-label" for="f-lic-expira_em">Expira em</label>
                        <input class="adm-input" type="date" id="f-lic-expira_em" name="expira_em">
                        <p class="adm-input-hint">Deixar em branco para sem prazo de expiração.</p>
                    </div>
                </div>
                <div style="display:flex;justify-content:flex-end">
                    <button type="submit" class="adm-btn adm-btn-primary" id="btnSaveLicenca">
                        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                        Adicionar Licença
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
function switchTab(name, btn) {
    document.querySelectorAll('.adm-tab-panel').forEach(p => p.classList.remove('active'));
    document.querySelectorAll('.adm-tab').forEach(b => b.classList.remove('active'));
    document.getElementById('tab-' + name).classList.add('active');
    btn.classList.add('active');
}

const companyId = <?= $companyId ?? 'null' ?>;

document.getElementById('empresaForm').addEventListener('submit', async function(e) {
    e.preventDefault();
    const btn = e.submitter || document.getElementById('btnSaveEmpresa');
    btn.disabled = true;
    const fd = new FormData(this);
    fd.append('id', companyId);
    try {
        const res  = await fetch('/nexora/api/empresa_save', { method: 'POST', body: fd });
        const data = await res.json();
        showToast(data.ok ? (data.msg || 'Dados atualizados.') : (data.error || 'Erro'), data.ok ? 'success' : 'error');
    } catch {
        showToast('Erro de ligação', 'error');
    } finally {
        btn.disabled = false;
    }
});

document.getElementById('fiscalForm').addEventListener('submit', async function(e) {
    e.preventDefault();
    const btn = e.submitter || document.getElementById('btnSaveFiscal');
    btn.disabled = true;
    const fd = new FormData(this);
    fd.append('id', companyId);
    try {
        const res  = await fetch('/nexora/api/empresa_fiscal_save', { method: 'POST', body: fd });
        const data = await res.json();
        if (data.ok) {
            showToast(data.msg || 'Dados fiscais atualizados.');
            setTimeout(() => location.reload(), 800);
        } else {
            showToast(data.error || 'Erro', 'error');
        }
    } catch {
        showToast('Erro de ligação', 'error');
    } finally {
        btn.disabled = false;
    }
});

document.getElementById('branchForm').addEventListener('submit', async function(e) {
    e.preventDefault();
    const btn = e.submitter || document.getElementById('btnSaveBranch');
    btn.disabled = true;
    const fd = new FormData(this);
    fd.append('id', companyId);
    try {
        const res  = await fetch('/nexora/api/empresa_branch_save', { method: 'POST', body: fd });
        const data = await res.json();
        if (data.ok) {
            showToast(data.msg || 'Filial criada.');
            setTimeout(() => location.reload(), 800);
        } else {
            showToast(data.error || 'Erro', 'error');
            btn.disabled = false;
        }
    } catch {
        showToast('Erro de ligação', 'error');
        btn.disabled = false;
    }
});

async function mudarEstadoBranch(branchId, status) {
    try {
        const res  = await fetch('/nexora/api/empresa_branch_save', {
            method: 'POST',
            headers: {'Content-Type':'application/json'},
            body: JSON.stringify({id: companyId, branch_id: branchId, status, csrf: '<?= $csrf ?>'})
        });
        const data = await res.json();
        if (data.ok) {
            showToast('Estado atualizado');
            setTimeout(() => location.reload(), 800);
        } else {
            showToast(data.error || 'Erro', 'error');
        }
    } catch {
        showToast('Erro de ligação', 'error');
    }
}

document.getElementById('licencaForm').addEventListener('submit', async function(e) {
    e.preventDefault();
    const btn = e.submitter || document.getElementById('btnSaveLicenca');
    btn.disabled = true;
    const fd = new FormData(this);
    fd.append('id', companyId);
    try {
        const res  = await fetch('/nexora/api/empresa_licenca_save', { method: 'POST', body: fd });
        const data = await res.json();
        if (data.ok) {
            showToast(data.msg || 'Licença adicionada.');
            setTimeout(() => location.reload(), 800);
        } else {
            showToast(data.error || 'Erro', 'error');
            btn.disabled = false;
        }
    } catch {
        showToast('Erro de ligação', 'error');
        btn.disabled = false;
    }
});
</script>

<?php endif; ?>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
