<?php

$resp     = $app->nexora->call('GET', '/api/superadmin/settings');
$settings = $resp['body'] ?? [];

$csrf = $app->security->csrfToken();
$pageTitle  = 'Configurações Globais';
$activePage = 'superadmin_settings';
$breadcrumb = [['Nexora', '/nexora/superadmin'], ['Configurações Globais', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Configurações Globais</h1>
    <div class="adm-page-header-actions">
        <button class="adm-btn adm-btn-primary" onclick="openSettingModal()">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
            Nova Configuração
        </button>
    </div>
</div>

<div class="adm-card">
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr>
                    <th>Chave</th>
                    <th>Valor</th>
                    <th>Descrição</th>
                    <th>Actualizado em</th>
                    <th>Ações</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($settings as $s): ?>
            <tr>
                <td><code><?= htmlspecialchars($s['chave']) ?></code></td>
                <td>
                    <input class="adm-input adm-input-sm" type="text" id="val-<?= htmlspecialchars($s['chave']) ?>" value="<?= htmlspecialchars($s['valor'] ?? '') ?>">
                </td>
                <td><?= htmlspecialchars($s['descricao'] ?? '—') ?></td>
                <td class="adm-text-muted"><?= $s['updated_at'] ? date('d/m/Y H:i', strtotime($s['updated_at'])) : '—' ?></td>
                <td>
                    <button class="adm-btn adm-btn-primary adm-btn-sm" onclick="saveSetting('<?= htmlspecialchars(addslashes($s['chave'])) ?>')">Guardar</button>
                </td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>

<!-- Modal Nova Configuração -->
<div class="adm-modal" id="settingModal" style="display:none">
    <div class="adm-modal-content" style="max-width:460px">
        <div class="adm-modal-header">
            <h3>Nova Configuração</h3>
            <button class="adm-btn adm-btn-ghost adm-btn-icon" onclick="closeSettingModal()">&times;</button>
        </div>
        <form id="settingForm" class="adm-form" onsubmit="return submitSetting(event)">
            <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">
            <div class="adm-form-group">
                <label>Chave</label>
                <input class="adm-input" type="text" name="chave" id="newChave" required placeholder="ex: max_tenants">
            </div>
            <div class="adm-form-group">
                <label>Valor</label>
                <input class="adm-input" type="text" name="valor" id="newValor" placeholder="ex: 100">
            </div>
            <div class="adm-form-group">
                <label>Descrição</label>
                <input class="adm-input" type="text" name="descricao" id="newDescricao" placeholder="Descrição opcional">
            </div>
            <div class="adm-modal-footer">
                <button type="button" class="adm-btn adm-btn-ghost" onclick="closeSettingModal()">Cancelar</button>
                <button type="submit" class="adm-btn adm-btn-primary">Guardar</button>
            </div>
        </form>
    </div>
</div>

<script>
const settingModal = document.getElementById('settingModal');
function openSettingModal() {
    document.getElementById('settingForm').reset();
    settingModal.style.display = 'flex';
}
function closeSettingModal() { settingModal.style.display = 'none'; }

async function submitSetting(e) {
    e.preventDefault();
    const fd = new FormData(e.target);
    const payload = { chave: fd.get('chave'), valor: fd.get('valor') || null, descricao: fd.get('descricao') || null };
    const res = await fetch('/nexora/api/superadmin_setting_save', {
        method: 'POST',
        headers: {'Content-Type': 'application/json', 'X-CSRF-Token': fd.get('csrf_token')},
        body: JSON.stringify(payload)
    }).then(r => r.json());
    if (res.ok) location.reload();
    else alert(res.error || 'Erro ao guardar configuração');
    return false;
}

async function saveSetting(chave) {
    const valor = document.getElementById('val-' + chave).value;
    const res = await fetch('/nexora/api/superadmin_setting_save', {
        method: 'POST',
        headers: {'Content-Type': 'application/json', 'X-CSRF-Token': '<?= $csrf ?>'},
        body: JSON.stringify({chave, valor})
    }).then(r => r.json());
    if (res.ok) location.reload();
    else alert(res.error || 'Erro ao guardar configuracao');
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
