<?php

$idHash = $app->request->queryString('id');
$isEdit = $idHash !== '';
$cargo  = null;
$permsCurrent = [];

if ($isEdit) {
    $resp = $app->nexora->call('GET', "/api/auth/cargos/$idHash");
    if ($resp['status'] !== 200) {
        header('Location: /nexora/admin/cargos');
        exit;
    }
    $cargo = $resp['body'];

    $permsResp    = $app->nexora->call('GET', "/api/auth/cargos/$id/permissoes");
    $permsCurrent = $permsResp['body'] ?? [];
}

$csrf       = $app->security->csrfToken();
$pageTitle  = $isEdit ? 'Editar Cargo' : 'Novo Cargo';
$activePage = 'cargos';
$breadcrumb = [['Admin', '/nexora/'], ['Administração', ''], ['Cargos & Permissões', '/nexora/admin/cargos'], [$pageTitle, '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title"><?= $isEdit ? 'Editar Cargo' : 'Novo Cargo' ?></h1>
</div>

<?php if ($app->request->queryString('msg') !== ''): ?>
<div class="adm-alert adm-alert--success">
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
    <?= htmlspecialchars($app->request->queryString('msg')) ?>
</div>
<?php endif; ?>

<div id="formMsg"></div>

<form id="cargoForm">
    <input type="hidden" name="csrf_token" value="<?= $csrf ?>">
    <?php if ($isEdit): ?><input type="hidden" name="id" value="<?= (int)($cargo['id'] ?? 0) ?>"><?php endif; ?>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header">
            <h2 class="adm-card-title">Dados do Cargo</h2>
            <?php if ($isEdit): ?>
            <div class="adm-card-actions">
                <?php if (! empty($cargo['ativo'])): ?>
                <span class="adm-badge adm-badge--green">Ativo</span>
                <?php else: ?>
                <span class="adm-badge adm-badge--gray">Inativo</span>
                <?php endif; ?>
            </div>
            <?php endif; ?>
        </div>
        <div class="adm-card-body">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="f-nome" name="nome" required maxlength="100"
                           placeholder="ex: Gestor de Vendas" value="<?= $app->view->field($cargo, 'nome') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-descricao">Descrição</label>
                    <input class="adm-input" type="text" id="f-descricao" name="descricao" maxlength="255"
                           placeholder="Descrição opcional" value="<?= $app->view->field($cargo, 'descricao') ?>">
                </div>
            </div>

            <?php if ($isEdit): ?>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <?php if (! empty($cargo['ativo'])): ?>
                <button type="button" class="adm-btn adm-btn-outline" onclick="mudarEstadoCargo(false)">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/></svg>
                    Desativar cargo
                </button>
                <?php else: ?>
                <button type="button" class="adm-btn adm-btn-outline" onclick="mudarEstadoCargo(true)">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18.36 6.64a9 9 0 1 1-12.73 0"/><line x1="12" y1="2" x2="12" y2="12"/></svg>
                    Ativar cargo
                </button>
                <?php endif; ?>
            </div>
            <?php endif; ?>
        </div>
    </div>

    <div style="display:flex;gap:var(--adm-sp-3);justify-content:flex-end;padding-bottom:var(--adm-sp-8)">
        <a href="/nexora/admin/cargos" class="adm-btn adm-btn-outline">Cancelar</a>
        <button type="submit" class="adm-btn adm-btn-primary" id="btnSave">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/>
                <polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/>
            </svg>
            <?= $isEdit ? 'Guardar alterações' : 'Criar Cargo' ?>
        </button>
    </div>
</form>

<?php if ($isEdit): ?>
<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Permissões do Cargo</h2></div>
    <div class="adm-card-body">
        <p class="adm-text-sm adm-text-muted" style="margin-bottom:var(--adm-sp-4)">Permissões aplicadas a todos os utilizadores com este cargo. Clique no cabeçalho de uma coluna/linha para marcar ou desmarcar tudo.</p>
        <?php $permGridId = 'cargoPermsGrid'; include dirname(__DIR__) . '/partials/permission_grid.php'; ?>

    

        <div style="margin-top:var(--adm-sp-5)">
            <button type="button" class="adm-btn adm-btn-primary" id="btnSavePerms" onclick="savePerms()">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/>
                    <polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/>
                </svg>
                Guardar permissões
            </button>
        </div>
    </div>
</div>
<?php endif; ?>

<script>
<?php if ($isEdit): ?>
function mudarEstadoCargo(ativar) {
    const acao = ativar ? 'Ativar' : 'Desativar';
    openConfirm(
        acao + ' cargo',
        acao + ' este cargo?',
        async () => {
            try {
                const res  = await fetch('/nexora/api/cargo_estado', {
                    method: 'POST',
                    headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({id: <?= (int)($cargo['id'] ?? 0) ?>, ativo: ativar, csrf: '<?= $csrf ?>'})
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
    );
}

async function savePerms() {
    const btn = document.getElementById('btnSavePerms');
    btn.disabled = true;
    try {
        const permissoes = collectGridPerms('cargoPermsGrid');
        const res  = await fetch('/nexora/api/cargo_permissoes', {
            method: 'POST',
            headers: {'Content-Type':'application/json'},
            body: JSON.stringify({id: <?= (int)($cargo['id'] ?? 0) ?>, permissoes, csrf: '<?= $csrf ?>'})
        });
        const data = await res.json();
        showToast(data.ok ? 'Permissões atualizadas' : (data.error || 'Erro'), data.ok ? 'success' : 'error');
    } catch {
        showToast('Erro de ligação', 'error');
    } finally {
        btn.disabled = false;
    }
}
<?php endif; ?>

document.getElementById('cargoForm').addEventListener('submit', async function(e) {
    e.preventDefault();
    const btn = document.getElementById('btnSave');
    btn.disabled = true;
    const originalHtml = btn.innerHTML;
    btn.innerHTML = '<svg class="spin" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg> A guardar…';

    const msgEl = document.getElementById('formMsg');
    msgEl.innerHTML = '';

    const fd = new FormData(this);

    try {
        const res  = await fetch('/nexora/api/cargo_save', { method: 'POST', body: fd });
        const data = await res.json();

        if (data.ok) {
            <?php if ($isEdit): ?>
            showToast(data.msg || 'Cargo atualizado.');
            btn.disabled = false;
            btn.innerHTML = originalHtml;
            <?php else: ?>
            window.location.href = '/nexora/admin/cargos/form?id=' + nexoraEncodeId(data.id) + '&msg=' + encodeURIComponent(data.msg || 'Cargo criado com sucesso.');
            <?php endif; ?>
        } else {
            msgEl.innerHTML = `<div class="adm-alert adm-alert--error">${data.error || 'Erro ao guardar.'}</div>`;
            btn.disabled = false;
            btn.innerHTML = originalHtml;
        }
    } catch {
        msgEl.innerHTML = '<div class="adm-alert adm-alert--error">Erro de ligação.</div>';
        btn.disabled = false;
        btn.innerHTML = originalHtml;
    }
});

const style = document.createElement('style');
style.textContent = '.spin{animation:spin .7s linear infinite}@keyframes spin{to{transform:rotate(360deg)}}';
document.head.appendChild(style);
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
