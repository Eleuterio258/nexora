<?php

$resp     = $app->nexora->call('GET', '/api/auth/sessoes');
$sessoes  = $resp['body'] ?? [];

$csrf       = $app->security->csrfToken();
$pageTitle  = 'Sessões';
$activePage = 'sessoes';
$breadcrumb = [['Admin', '/nexora/'], ['Administração', ''], ['Sessões', '']];

$temOutras = (bool) array_filter($sessoes, fn($s) => empty($s['atual']));

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Sessões</h1>
    <?php if ($temOutras): ?>
    <div class="adm-page-header-actions">
        <button type="button" class="adm-btn adm-btn-outline" onclick="revogarTodas()">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/></svg>
            Revogar todas as outras
        </button>
    </div>
    <?php endif; ?>
</div>

<div class="adm-alert adm-alert--info">
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>
    Estas são as sessões da conta de serviço usada por este painel de administração, não de todos os utilizadores do Nexora.
</div>

<div class="adm-card">
    <?php if ($sessoes): ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr>
                    <th>IP</th>
                    <th>User-Agent</th>
                    <th>Iniciada em</th>
                    <th>Expira em</th>
                    <th>Estado</th>
                    <th>Ações</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($sessoes as $s):
                $ua = $s['user_agent'] ?? '';
                $uaShort = strlen($ua) > 60 ? substr($ua, 0, 60) . '…' : $ua;
            ?>
            <tr>
                <td><?= htmlspecialchars($s['ip_address'] ?? '—') ?></td>
                <td class="adm-text-muted" title="<?= htmlspecialchars($ua) ?>"><?= htmlspecialchars($uaShort ?: '—') ?></td>
                <td class="adm-text-muted"><?= date('d/m/Y H:i', strtotime($s['iniciado_em'])) ?></td>
                <td class="adm-text-muted"><?= date('d/m/Y H:i', strtotime($s['expira_em'])) ?></td>
                <td>
                    <?php if (! empty($s['atual'])): ?>
                    <span class="adm-badge adm-badge--blue">Atual</span>
                    <?php else: ?>
                    <span class="adm-badge adm-badge--gray">—</span>
                    <?php endif; ?>
                </td>
                <td>
                    <?php if (empty($s['atual'])): ?>
                    <button class="adm-btn adm-btn-ghost adm-btn-sm" onclick="revogar(<?= $s['id'] ?>)">Revogar</button>
                    <?php endif; ?>
                </td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="adm-empty">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/>
        </svg>
        <p class="adm-empty-title">Nenhuma sessão ativa</p>
    </div>
    <?php endif; ?>
</div>

<script>
async function revogar(id) {
    openConfirm('Revogar sessão', 'Tem a certeza que pretende revogar esta sessão?', async () => {
        try {
            const res  = await fetch('/nexora/api/sessao_revogar', {
                method: 'POST',
                headers: {'Content-Type':'application/json'},
                body: JSON.stringify({id, csrf: '<?= $csrf ?>'})
            });
            const data = await res.json();
            if (data.ok) {
                showToast('Sessão revogada');
                setTimeout(() => location.reload(), 800);
            } else {
                showToast(data.error || 'Erro', 'error');
            }
        } catch {
            showToast('Erro de ligação', 'error');
        }
    });
}

async function revogarTodas() {
    openConfirm('Revogar todas as outras sessões', 'Tem a certeza? Esta ação termina todas as sessões exceto a atual.', async () => {
        try {
            const res  = await fetch('/nexora/api/sessao_revogar', {
                method: 'POST',
                headers: {'Content-Type':'application/json'},
                body: JSON.stringify({all: true, csrf: '<?= $csrf ?>'})
            });
            const data = await res.json();
            if (data.ok) {
                showToast('Sessões revogadas');
                setTimeout(() => location.reload(), 800);
            } else {
                showToast(data.error || 'Erro', 'error');
            }
        } catch {
            showToast('Erro de ligação', 'error');
        }
    });
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
