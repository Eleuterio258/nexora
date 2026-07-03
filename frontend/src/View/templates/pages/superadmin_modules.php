<?php

$tenantsResp = $app->nexora->call('GET', '/api/superadmin/tenants', null, ['limit' => 1000]);
$tenants     = $tenantsResp['body']['data'] ?? [];

$tenantId = $app->request->queryInt('tenant_id');
$modules  = [];
$tenantModules = [];

if ($tenantId) {
    $modResp = $app->nexora->call('GET', '/api/superadmin/modules/disponiveis');
    $modules = $modResp['body'] ?? [];
    $tmResp  = $app->nexora->call('GET', '/api/superadmin/modules/tenants/' . $tenantId);
    foreach ($tmResp['body'] ?? [] as $m) {
        $tenantModules[$m['modulo']] = $m;
    }
}

$csrf = $app->security->csrfToken();
$pageTitle  = 'Módulos';
$activePage = 'superadmin_modules';
$breadcrumb = [['Nexora', '/nexora/superadmin'], ['Módulos', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Módulos por Tenant</h1>
    <div class="adm-page-header-actions">
        <form method="get" style="display:flex;align-items:center;gap:var(--adm-sp-3)">
            <select class="adm-select" name="tenant_id" onchange="this.form.submit()" style="min-width:260px">
                <option value="">Selecionar tenant…</option>
                <?php foreach ($tenants as $t): ?>
                <option value="<?= $t['id'] ?>" <?= $tenantId == $t['id'] ? 'selected' : '' ?>><?= htmlspecialchars($t['nome']) ?> (<?= htmlspecialchars($t['codigo']) ?>)</option>
                <?php endforeach; ?>
            </select>
        </form>
        <?php if ($tenantId): ?>
        <button class="adm-btn adm-btn-ghost adm-btn-sm" style="color:var(--adm-red)" onclick="resetModulos(<?= (int) $tenantId ?>)">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 1 0 .49-3.5"/></svg>
            Resetar tudo
        </button>
        <?php endif; ?>
    </div>
</div>

<?php if ($tenantId && $modules): ?>

<div style="background:var(--adm-white);border:1px solid var(--adm-gray-200);border-radius:var(--adm-radius-md);overflow:hidden;box-shadow:var(--adm-shadow-card)">
    <?php foreach ($modules as $i => $m):
        $key   = $m['key'];
        $ativo = isset($tenantModules[$key]) ? (bool) $tenantModules[$key]['ativo'] : true;
        $isLast = $i === array_key_last($modules);
    ?>
    <div style="display:flex;align-items:center;gap:var(--adm-sp-4);padding:var(--adm-sp-4) var(--adm-sp-6);<?= $isLast ? '' : 'border-bottom:1px solid var(--adm-gray-100);' ?>">
        <div style="flex:1;min-width:0">
            <div class="adm-fw-600" style="<?= $ativo ? '' : 'color:var(--adm-gray-400)' ?>"><?= htmlspecialchars($m['nome']) ?></div>
            <div class="adm-text-xs adm-text-muted" style="margin-top:.15rem"><code><?= htmlspecialchars($key) ?></code></div>
        </div>
        <label class="adm-switch" style="flex-shrink:0">
            <input type="checkbox" <?= $ativo ? 'checked' : '' ?> onchange="toggleModule(<?= $tenantId ?>, '<?= htmlspecialchars($key) ?>', this.checked)">
            <span></span>
        </label>
    </div>
    <?php endforeach; ?>
</div>

<?php elseif ($tenantId): ?>
<div class="adm-empty">Nenhum módulo disponível.</div>
<?php else: ?>
<div class="adm-empty" style="padding:var(--adm-sp-12)">
    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="margin:0 auto var(--adm-sp-3);opacity:.25"><rect x="2" y="3" width="6" height="6"/><rect x="16" y="3" width="6" height="6"/><rect x="2" y="15" width="6" height="6"/><rect x="16" y="15" width="6" height="6"/></svg>
    <p class="adm-empty-title">Selecione um tenant</p>
    <p class="adm-text-sm adm-text-muted">Escolha um tenant no selector acima para gerir os seus módulos.</p>
</div>
<?php endif; ?>

<script>
async function toggleModule(tenantId, modulo, ativo) {
    const res = await fetch('/nexora/api/superadmin_module_save', {
        method: 'POST',
        headers: {'Content-Type': 'application/json', 'X-CSRF-Token': '<?= $csrf ?>'},
        body: JSON.stringify({tenant_id: tenantId, modulo, ativo})
    }).then(r => r.json());
    if (!res.ok) showToast(res.error || 'Erro ao actualizar módulo', 'error');
    else showToast(ativo ? 'Módulo activado' : 'Módulo desactivado');
}

async function resetModulos(tenantId) {
    if (!confirm('Resetar todos os módulos deste tenant? Os toggles voltarão ao estado padrão.')) return;
    const res = await fetch('/nexora/api/superadmin_modules_reset', {
        method: 'POST',
        headers: {'Content-Type': 'application/json', 'X-CSRF-Token': '<?= $csrf ?>'},
        body: JSON.stringify({tenant_id: tenantId})
    }).then(r => r.json());
    if (res.ok) location.reload();
    else showToast(res.error || 'Erro ao resetar módulos', 'error');
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
