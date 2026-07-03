<?php

$search   = $app->request->queryString('search');
$tenantId = $app->request->queryString('tenant_id');
$page     = max(1, $app->request->queryInt('page', 1) ?? 1);
$limit    = 20;

$resp  = $app->nexora->call('GET', '/api/superadmin/utilizadores', null, [
    'tenant_id' => $tenantId,
    'search'    => $search,
    'page'      => $page,
    'limit'     => $limit,
]);
$users = $resp['body']['data'] ?? [];
$meta  = $resp['body']['meta'] ?? ['total' => 0, 'page' => $page, 'limit' => $limit];
$totalPages = max(1, (int) ceil($meta['total'] / $limit));

$tenantsResp = $app->nexora->call('GET', '/api/superadmin/tenants', null, ['limit' => 1000]);
$tenants     = $tenantsResp['body']['data'] ?? [];

$csrf = $app->security->csrfToken();
$pageTitle  = 'Utilizadores Globais';
$activePage = 'superadmin_users';
$breadcrumb = [['Nexora', '/nexora/superadmin'], ['Utilizadores Globais', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Utilizadores Globais</h1>
</div>

<div class="adm-card">
    <form method="get" class="adm-filter-bar">
        <div class="adm-search-wrap">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
            </svg>
            <input class="adm-input" type="search" name="search" placeholder="Pesquisar nome ou email…" value="<?= htmlspecialchars($search) ?>">
        </div>
        <select class="adm-select" name="tenant_id" style="width:200px">
            <option value="">Todos os tenants</option>
            <?php foreach ($tenants as $t): ?>
            <option value="<?= $t['id'] ?>" <?= (string)$tenantId === (string)$t['id'] ? 'selected' : '' ?>>
                <?= htmlspecialchars($t['nome']) ?> (<?= htmlspecialchars($t['codigo']) ?>)
            </option>
            <?php endforeach; ?>
        </select>
        <button type="submit" class="adm-btn adm-btn-outline adm-btn-sm">Filtrar</button>
        <span class="adm-filter-count"><?= $meta['total'] ?> utilizador<?= $meta['total'] != 1 ? 'es' : '' ?></span>
    </form>

    <?php if ($users): ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Nome</th>
                    <th>Email</th>
                    <th>Tenant</th>
                    <th>Tipo</th>
                    <th>Estado</th>
                    <th>Último login</th>
                    <th>Ações</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($users as $u):
                $estadoBadge = match ($u['estado']) {
                    'ativo'     => ['adm-badge--green', 'Ativo'],
                    'inativo'   => ['adm-badge--gray', 'Inativo'],
                    'bloqueado' => ['adm-badge--red', 'Bloqueado'],
                    default     => ['adm-badge--gray', $u['estado']],
                };
                $tipoBadge = match ($u['tipo']) {
                    'superadmin'  => ['adm-badge--red', 'Admin Global'],
                    'funcionario' => ['adm-badge--green', 'Funcionário'],
                    default       => ['adm-badge--gray', $u['tipo']],
                };
            ?>
            <tr>
                <td><code><?= (int) $u['id'] ?></code></td>
                <td><div class="adm-fw-600"><?= htmlspecialchars($u['nome']) ?></div></td>
                <td><?= htmlspecialchars($u['email']) ?></td>
                <td><?= htmlspecialchars($u['tenant_nome'] ?? '—') ?></td>
                <td><span class="adm-badge <?= $tipoBadge[0] ?>"><?= $tipoBadge[1] ?></span></td>
                <td><span class="adm-badge <?= $estadoBadge[0] ?>"><?= $estadoBadge[1] ?></span></td>
                <td class="adm-text-muted"><?= $u['ultimo_login_em'] ? date('d/m/Y H:i', strtotime($u['ultimo_login_em'])) : '—' ?></td>
                <td>
                    <div class="adm-actions">
                        <button class="adm-btn adm-btn-ghost adm-btn-sm"
                            onclick="openResetPasswordModal(<?= (int) $u['id'] ?>, '<?= htmlspecialchars(addslashes($u['nome'])) ?>')">
                            Reset Senha
                        </button>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm"
                            onclick="openAlterarTipoModal(<?= (int) $u['id'] ?>, '<?= htmlspecialchars(addslashes($u['nome'])) ?>', '<?= htmlspecialchars($u['tipo']) ?>')">
                            Alterar Tipo
                        </button>
                    </div>
                </td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>

    <?php if ($totalPages > 1): ?>
    <div class="adm-pagination">
        <?php for ($i = 1; $i <= $totalPages; $i++): ?>
        <a href="?<?= http_build_query(array_filter(['search' => $search, 'tenant_id' => $tenantId, 'page' => $i])) ?>" class="adm-btn adm-btn-sm <?= $i === $page ? 'adm-btn-primary' : 'adm-btn-ghost' ?>"><?= $i ?></a>
        <?php endfor; ?>
    </div>
    <?php endif; ?>

    <?php else: ?>
    <div class="adm-empty">Nenhum utilizador encontrado.</div>
    <?php endif; ?>
</div>

<!-- Modal Reset Password -->
<div class="adm-modal" id="resetPasswordModal" style="display:none">
    <div class="adm-modal-content" style="max-width:420px">
        <div class="adm-modal-header">
            <h3>Reset de Senha</h3>
            <button class="adm-btn adm-btn-ghost adm-btn-icon" onclick="closeResetPasswordModal()">&times;</button>
        </div>
        <form id="resetPasswordForm" class="adm-form" onsubmit="return submitResetPassword(event)">
            <input type="hidden" name="id" id="rpUserId">
            <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">
            <p class="adm-text-muted" style="margin-bottom:1rem">
                Utilizador: <strong id="rpUserName"></strong>
            </p>
            <div class="adm-form-group">
                <label>Nova Senha</label>
                <input class="adm-input" type="password" name="password" id="rpPassword" minlength="8" required placeholder="Mínimo 8 caracteres">
            </div>
            <div class="adm-form-group">
                <label>Confirmar Senha</label>
                <input class="adm-input" type="password" id="rpPasswordConfirm" minlength="8" required placeholder="Repita a senha">
            </div>
            <div class="adm-modal-footer">
                <button type="button" class="adm-btn adm-btn-ghost" onclick="closeResetPasswordModal()">Cancelar</button>
                <button type="submit" class="adm-btn adm-btn-primary">Redefinir Senha</button>
            </div>
        </form>
    </div>
</div>

<!-- Modal Alterar Tipo -->
<div class="adm-modal" id="alterarTipoModal" style="display:none">
    <div class="adm-modal-content" style="max-width:380px">
        <div class="adm-modal-header">
            <h3>Alterar Tipo de Utilizador</h3>
            <button class="adm-btn adm-btn-ghost adm-btn-icon" onclick="closeAlterarTipoModal()">&times;</button>
        </div>
        <form id="alterarTipoForm" class="adm-form" onsubmit="return submitAlterarTipo(event)">
            <input type="hidden" name="id" id="atUserId">
            <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">
            <p class="adm-text-muted" style="margin-bottom:1rem">
                Utilizador: <strong id="atUserName"></strong>
            </p>
            <div class="adm-form-group">
                <label>Tipo</label>
                <select class="adm-select" name="tipo" id="atTipo">
                    <option value="funcionario">Funcionário</option>
                    <option value="superadmin">Admin Global</option>
                </select>
            </div>
            <div class="adm-modal-footer">
                <button type="button" class="adm-btn adm-btn-ghost" onclick="closeAlterarTipoModal()">Cancelar</button>
                <button type="submit" class="adm-btn adm-btn-primary">Guardar</button>
            </div>
        </form>
    </div>
</div>

<script>
const resetPasswordModal = document.getElementById('resetPasswordModal');
const alterarTipoModal   = document.getElementById('alterarTipoModal');

function openResetPasswordModal(id, nome) {
    document.getElementById('rpUserId').value = id;
    document.getElementById('rpUserName').textContent = nome;
    document.getElementById('rpPassword').value = '';
    document.getElementById('rpPasswordConfirm').value = '';
    resetPasswordModal.style.display = 'flex';
}
function closeResetPasswordModal() { resetPasswordModal.style.display = 'none'; }

async function submitResetPassword(e) {
    e.preventDefault();
    const pwd  = document.getElementById('rpPassword').value;
    const conf = document.getElementById('rpPasswordConfirm').value;
    if (pwd !== conf) { alert('As senhas não coincidem.'); return false; }
    const fd      = new FormData(e.target);
    const payload = { id: parseInt(fd.get('id')), password: pwd, csrf_token: fd.get('csrf_token') };
    const res = await fetch('/nexora/api/superadmin_user_reset_password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
    }).then(r => r.json());
    if (res.ok) { closeResetPasswordModal(); alert('Senha redefinida com sucesso.'); }
    else alert(res.erro || 'Erro ao redefinir senha.');
    return false;
}

function openAlterarTipoModal(id, nome, tipoAtual) {
    document.getElementById('atUserId').value = id;
    document.getElementById('atUserName').textContent = nome;
    document.getElementById('atTipo').value = tipoAtual;
    alterarTipoModal.style.display = 'flex';
}
function closeAlterarTipoModal() { alterarTipoModal.style.display = 'none'; }

async function submitAlterarTipo(e) {
    e.preventDefault();
    const fd      = new FormData(e.target);
    const payload = { id: parseInt(fd.get('id')), tipo: fd.get('tipo'), csrf_token: fd.get('csrf_token') };
    const res = await fetch('/nexora/api/superadmin_user_tipo', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
    }).then(r => r.json());
    if (res.ok) location.reload();
    else alert(res.erro || 'Erro ao alterar tipo.');
    return false;
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
