<?php

$idHash = $app->request->queryString('id');
$isEdit = $idHash !== '';
$user   = null;
$cargos = [];
$permsCurrent = [];

if ($isEdit) {
    $resp = $app->nexora->call('GET', "/api/auth/utilizadores/$idHash");
    if ($resp['status'] !== 200) {
        header('Location: /nexora/admin/utilizadores');
        exit;
    }
    $user = $resp['body'];

    $cargosResp = $app->nexora->call('GET', '/api/auth/cargos');
    $cargos = array_values(array_filter($cargosResp['body'] ?? [], fn($c) => ! empty($c['ativo'])));

    $permsResp    = $app->nexora->call('GET', "/api/auth/utilizadores/$idHash/permissoes");
    $permsCurrent = $permsResp['body'] ?? [];

    $tipoUtilizador = $user['tipo'] ?? 'funcionario';
    $isSuperAdmin   = $app->session->isSuperAdmin();

    // Superadmin tem acesso implícito a tudo — preencher a grelha manualmente
    if (($user['tipo'] ?? '') === 'superadmin') {
        $allModules = array_keys(array_filter(require dirname(__DIR__) . '/partials/modules.php', fn($m) => empty($m['sem_atribuicao'])));
        $allAcoes   = ['ver', 'criar', 'editar', 'eliminar', 'gerir'];
        $permsCurrent = [];
        foreach ($allModules as $mod) {
            foreach ($allAcoes as $acao) {
                $permsCurrent[] = ['modulo' => $mod, 'acao' => $acao];
            }
        }
    }
}

$csrf       = $app->security->csrfToken();
$pageTitle  = $isEdit ? 'Editar Utilizador' : 'Novo Utilizador';
$activePage = 'utilizadores';
$breadcrumb = [['Admin', '/nexora/'], ['Administração', ''], ['Utilizadores', '/nexora/admin/utilizadores'], [$pageTitle, '']];

if ($isEdit) {
    $estadoBadge = match ($user['estado']) {
        'ativo'     => ['adm-badge--green',  'Ativo'],
        'bloqueado' => ['adm-badge--red',    'Bloqueado'],
        'pendente'  => ['adm-badge--yellow', 'Pendente'],
        default     => ['adm-badge--gray',   'Inativo'],
    };
}

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title"><?= $isEdit ? 'Editar Utilizador' : 'Novo Utilizador' ?></h1>
</div>

<div id="formMsg"></div>

<?php if (! $isEdit): ?>

<form id="userForm">
    <input type="hidden" name="csrf_token" value="<?= $csrf ?>">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Dados do Utilizador</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="f-nome" name="nome" required maxlength="150" placeholder="Nome completo">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-email">Email <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="email" id="f-email" name="email" required maxlength="150" placeholder="email@exemplo.com">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-password">Palavra-passe <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="password" id="f-password" name="password" required minlength="8" placeholder="Mínimo 8 caracteres">
                    <p class="adm-input-hint">O utilizador pode alterar depois do primeiro acesso.</p>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-telefone">Telefone</label>
                    <input class="adm-input" type="text" id="f-telefone" name="telefone" maxlength="30" placeholder="ex: +258 84 000 0000">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-escopo">Escopo de acesso <span style="color:var(--adm-red)">*</span></label>
                    <select class="adm-select" id="f-escopo" name="escopo" required>
                        <option value="erp" selected>ERP Geral</option>
                        <option value="escola">Painel da Escola</option>
                    </select>
                    <p class="adm-input-hint">Define quais painéis o utilizador pode aceder.</p>
                </div>
            </div>
        </div>
    </div>
    <div style="display:flex;gap:var(--adm-sp-3);justify-content:flex-end;padding-bottom:var(--adm-sp-8)">
        <a href="/nexora/admin/utilizadores" class="adm-btn adm-btn-outline">Cancelar</a>
        <button type="submit" class="adm-btn adm-btn-primary" id="btnSave">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
            Criar Utilizador
        </button>
    </div>
</form>

<?php else: ?>

<div class="adm-tabs" id="mainTabs">
    <button class="adm-tab active" onclick="switchTab('dados',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="8" r="4"/><path d="M20 21a8 8 0 1 0-16 0"/></svg>
        Dados
    </button>
    <button class="adm-tab" onclick="switchTab('cargo',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"/><line x1="7" y1="7" x2="7.01" y2="7"/></svg>
        Cargo &amp; Permissões
    </button>
</div>

<!-- Tab: Dados -->
<div class="adm-tab-panel active" id="tab-dados">
    <form id="userForm">
        <input type="hidden" name="csrf_token" value="<?= $csrf ?>">
        <input type="hidden" name="id" value="<?= (int)($utilizador['id'] ?? 0) ?>">

        <div class="adm-card adm-mb-6">
            <div class="adm-card-header">
                <h2 class="adm-card-title">Dados do Utilizador</h2>
                <div class="adm-card-actions">
                    <span class="adm-badge <?= $estadoBadge[0] ?>"><?= $estadoBadge[1] ?></span>
                    <?php if (! empty($user['email_verificado'])): ?>
                    <span class="adm-badge adm-badge--blue">Email verificado</span>
                    <?php endif; ?>
                </div>
            </div>
            <div class="adm-card-body">
                <div class="adm-form-row">
                    <div class="adm-form-group">
                        <label class="adm-label" for="f-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                        <input class="adm-input" type="text" id="f-nome" name="nome" required maxlength="150" value="<?= $app->view->field($user, 'nome') ?>">
                    </div>
                    <div class="adm-form-group">
                        <label class="adm-label">Email</label>
                        <input class="adm-input" type="email" value="<?= $app->view->field($user, 'email') ?>" disabled>
                    </div>
                </div>
                <div class="adm-form-row">
                    <div class="adm-form-group">
                        <label class="adm-label" for="f-telefone">Telefone</label>
                        <input class="adm-input" type="text" id="f-telefone" name="telefone" maxlength="30" value="<?= $app->view->field($user, 'telefone') ?>">
                    </div>
                    <div class="adm-form-group">
                        <label class="adm-label">Criado em</label>
                        <input class="adm-input" type="text" value="<?= date('d/m/Y H:i', strtotime($user['created_at'])) ?>" disabled>
                    </div>
                </div>
                <div class="adm-form-row">
                    <div class="adm-form-group">
                        <label class="adm-label" for="f-escopo">Escopo de acesso <span style="color:var(--adm-red)">*</span></label>
                        <select class="adm-select" id="f-escopo" name="escopo" required>
                            <?php $currentEscopo = $user['escopo'] ?? 'erp'; ?>
                            <option value="erp" <?= $currentEscopo === 'erp' ? 'selected' : '' ?>>ERP Geral</option>
                            <option value="escola" <?= $currentEscopo === 'escola' ? 'selected' : '' ?>>Painel da Escola</option>
                        </select>
                        <p class="adm-input-hint">Define quais painéis o utilizador pode aceder.</p>
                    </div>
                </div>
                <div class="adm-form-group" style="margin-bottom:0;max-width:280px">
                    <label class="adm-label">Último login</label>
                    <input class="adm-input" type="text" value="<?= $user['ultimo_login_em'] ? date('d/m/Y H:i', strtotime($user['ultimo_login_em'])) : 'Nunca' ?>" disabled>
                </div>
            </div>
        </div>

        <!-- Tipo de utilizador -->
        <?php if ($isSuperAdmin): ?>
        <div class="adm-card adm-mb-6">
            <div class="adm-card-header">
                <h2 class="adm-card-title">Tipo de Utilizador</h2>
                <div class="adm-card-actions">
                    <span class="adm-badge <?= $tipoUtilizador === 'superadmin' ? 'adm-badge--indigo' : 'adm-badge--gray' ?>">
                        <?= $tipoUtilizador === 'superadmin' ? 'Superadmin' : 'Funcionário' ?>
                    </span>
                </div>
            </div>
            <div class="adm-card-body">
                <div class="adm-form-row" style="align-items:flex-end;max-width:480px">
                    <div class="adm-form-group" style="margin-bottom:0">
                        <label class="adm-label" for="f-tipo">Tipo</label>
                        <select class="adm-select" id="f-tipo">
                            <option value="funcionario" <?= $tipoUtilizador === 'funcionario' ? 'selected' : '' ?>>Funcionário</option>
                            <option value="superadmin"  <?= $tipoUtilizador === 'superadmin'  ? 'selected' : '' ?>>Superadmin</option>
                        </select>
                        <p class="adm-input-hint">Alterar o tipo termina as sessões activas do utilizador.</p>
                    </div>
                    <button type="button" class="adm-btn adm-btn-primary" id="btnSaveTipo" onclick="saveTipo()" style="margin-bottom:var(--adm-sp-5)">
                        <i class="fa-solid fa-shield"></i> Guardar tipo
                    </button>
                </div>
            </div>
        </div>
        <?php endif; ?>

        <!-- Estado da conta -->
        <div class="adm-card adm-mb-6">
            <div class="adm-card-header"><h2 class="adm-card-title">Estado da Conta</h2></div>
            <div class="adm-card-body">
                <div style="display:flex;gap:var(--adm-sp-3);flex-wrap:wrap">
                    <button type="button" class="adm-btn adm-btn-outline" onclick="mudarEstado('activar')" <?= $user['estado'] === 'ativo' ? 'disabled' : '' ?>>
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18.36 6.64a9 9 0 1 1-12.73 0"/><line x1="12" y1="2" x2="12" y2="12"/></svg>
                        Ativar
                    </button>
                    <button type="button" class="adm-btn adm-btn-outline" onclick="mudarEstado('bloquear')" <?= $user['estado'] === 'bloqueado' ? 'disabled' : '' ?>>
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                        Bloquear
                    </button>
                    <button type="button" class="adm-btn adm-btn-outline" onclick="mudarEstado('desactivar')" <?= $user['estado'] === 'inativo' ? 'disabled' : '' ?>>
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/></svg>
                        Desativar
                    </button>
                </div>
                <p class="adm-input-hint" style="margin-top:var(--adm-sp-3)">Bloquear um utilizador termina também todas as suas sessões ativas.</p>
            </div>
        </div>

        <!-- Redefinir senha (só superadmins) -->
        <?php if ($isSuperAdmin): ?>
        <div class="adm-card adm-mb-6">
            <div class="adm-card-header"><h2 class="adm-card-title">Redefinir Senha</h2></div>
            <div class="adm-card-body">
                <div class="adm-form-row" style="align-items:flex-end;max-width:480px">
                    <div class="adm-form-group" style="margin-bottom:0">
                        <label class="adm-label" for="f-new-password">Nova senha</label>
                        <input class="adm-input" type="password" id="f-new-password" minlength="8" placeholder="Mínimo 8 caracteres">
                        <p class="adm-input-hint">O utilizador deverá alterar a senha no próximo acesso.</p>
                    </div>
                    <button type="button" class="adm-btn adm-btn-outline" id="btnResetPw" onclick="resetPassword()" style="margin-bottom:var(--adm-sp-5)">
                        <i class="fa-solid fa-key"></i> Redefinir
                    </button>
                </div>
            </div>
        </div>
        <?php endif; ?>

        <div style="display:flex;gap:var(--adm-sp-3);justify-content:flex-end;padding-bottom:var(--adm-sp-8)">
            <a href="/nexora/admin/utilizadores" class="adm-btn adm-btn-outline">Voltar</a>
            <button type="submit" class="adm-btn adm-btn-primary" id="btnSave">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/>
                    <polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/>
                </svg>
                Guardar alterações
            </button>
        </div>
    </form>
</div>

<!-- Tab: Cargo & Permissões -->
<div class="adm-tab-panel" id="tab-cargo">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Cargo</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-group" style="max-width:360px">
                <label class="adm-label" for="f-cargo">Cargo</label>
                <select class="adm-select" id="f-cargo" name="cargo_id">
                    <option value="">Sem cargo</option>
                    <?php foreach ($cargos as $c): ?>
                    <option value="<?= $c['id'] ?>" <?= ((int) ($user['cargo_id'] ?? 0) === (int) $c['id']) ? 'selected' : '' ?>><?= htmlspecialchars($c['nome']) ?></option>
                    <?php endforeach; ?>
                </select>
                <p class="adm-input-hint">Ao selecionar um cargo, as permissões já incluídas nesse cargo ficam marcadas e bloqueadas na grelha "Permissões diretas" abaixo, para evitar duplicação.</p>
            </div>
            <button type="button" class="adm-btn adm-btn-primary" id="btnSaveCargo" onclick="saveCargo()">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/>
                    <polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/>
                </svg>
                Guardar cargo
            </button>
        </div>
    </div>

    <!-- Permissões automáticas por tipo -->
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header">
            <h2 class="adm-card-title">Permissões automáticas por tipo</h2>
            <div class="adm-card-actions">
                <span class="adm-badge adm-badge--gray"><?= htmlspecialchars($tipoUtilizador) ?></span>
            </div>
        </div>
        <div class="adm-card-body">
            <?php if ($tipoUtilizador === 'superadmin'): ?>
            <div class="adm-alert adm-alert--info" style="margin-bottom:0">
                <i class="fa-solid fa-shield-halved"></i>
                <span>Superadmins têm acesso total a todos os módulos e acções — as permissões diretas e de cargo são ignoradas.</span>
            </div>
            <?php else: ?>
            <p class="adm-text-sm adm-text-muted" style="margin-bottom:var(--adm-sp-3)">
                Permissões atribuídas automaticamente a todos os utilizadores do tipo <strong><?= htmlspecialchars($tipoUtilizador) ?></strong>, sem necessidade de configuração manual.
            </p>
            <div style="display:flex;flex-wrap:wrap;gap:var(--adm-sp-2)">
                <span class="adm-badge adm-badge--green"><i class="fa-solid fa-umbrella-beach"></i> pedido-ferias · ver_pedidos</span>
                <span class="adm-badge adm-badge--green"><i class="fa-solid fa-umbrella-beach"></i> pedido-ferias · submeter_pedido</span>
            </div>
            <p class="adm-input-hint" style="margin-top:var(--adm-sp-3)">
                Para adicionar mais permissões automáticas ao tipo, edite a tabela <code>auth.permissoes_tipo</code>.
            </p>
            <?php endif; ?>
        </div>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Permissões diretas</h2></div>
        <div class="adm-card-body">
            <p class="adm-text-sm adm-text-muted" style="margin-bottom:var(--adm-sp-4)">
                Permissões atribuídas diretamente a este utilizador, além das herdadas do seu cargo.
                Se o utilizador não tiver cargo, estas são as únicas permissões que terá — defina aqui a quais módulos tem acesso e o que pode fazer em cada um.
                Clique no cabeçalho de uma coluna/linha para marcar ou desmarcar tudo.
            </p>
            <p class="adm-perm-from-cargo-hint"><span class="adm-perm-from-cargo-dot"></span> Permissões já garantidas pelo cargo selecionado (bloqueadas aqui)</p>
            <?php $permGridId = 'userPermsGrid'; include dirname(__DIR__) . '/partials/permission_grid.php'; ?>

        

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
</div>

<?php endif; ?>

<script>
<?php if ($isEdit): ?>
function switchTab(name, btn) {
    document.querySelectorAll('.adm-tab-panel').forEach(p => p.classList.remove('active'));
    document.querySelectorAll('.adm-tab').forEach(b => b.classList.remove('active'));
    document.getElementById('tab-' + name).classList.add('active');
    btn.classList.add('active');
}

function mudarEstado(acao) {
    const labels = {activar: 'Ativar', bloquear: 'Bloquear', desactivar: 'Desativar'};
    openConfirm(
        labels[acao] + ' utilizador',
        labels[acao] + ' este utilizador?' + (acao === 'bloquear' ? ' Isto também termina todas as sessões activas.' : ''),
        async () => {
            try {
                const res  = await fetch('/nexora/api/utilizador_estado', {
                    method: 'POST',
                    headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({id: <?= (int)($utilizador['id'] ?? 0) ?>, acao, csrf: '<?= $csrf ?>'})
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

async function saveTipo() {
    const btn = document.getElementById('btnSaveTipo');
    const tipo = document.getElementById('f-tipo').value;
    btn.disabled = true;
    try {
        const res  = await fetch('/nexora/api/utilizador_tipo', {
            method: 'POST',
            headers: {'Content-Type':'application/json'},
            body: JSON.stringify({id: <?= (int)($utilizador['id'] ?? 0) ?>, tipo, csrf: '<?= $csrf ?>'})
        });
        const data = await res.json();
        if (data.ok) {
            showToast(data.msg || 'Tipo actualizado');
            setTimeout(() => location.reload(), 1200);
        } else {
            showToast(data.error || data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
    finally { btn.disabled = false; }
}

async function resetPassword() {
    const pw  = document.getElementById('f-new-password').value.trim();
    if (pw.length < 8) { showToast('A senha deve ter pelo menos 8 caracteres', 'error'); return; }
    const btn = document.getElementById('btnResetPw');
    btn.disabled = true;
    try {
        const res  = await fetch('/nexora/api/utilizador_reset_password', {
            method: 'POST',
            headers: {'Content-Type':'application/json'},
            body: JSON.stringify({id: <?= (int)($utilizador['id'] ?? 0) ?>, password: pw, csrf: '<?= $csrf ?>'})
        });
        const data = await res.json();
        if (data.ok) {
            document.getElementById('f-new-password').value = '';
            showToast(data.msg || 'Senha redefinida');
        } else {
            showToast(data.error || data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
    finally { btn.disabled = false; }
}

async function saveCargo() {
    const btn = document.getElementById('btnSaveCargo');
    btn.disabled = true;
    const cargoVal = document.getElementById('f-cargo').value;
    try {
        const res  = await fetch('/nexora/api/utilizador_cargo', {
            method: 'POST',
            headers: {'Content-Type':'application/json'},
            body: JSON.stringify({id: <?= (int)($utilizador['id'] ?? 0) ?>, cargo_id: cargoVal ? parseInt(cargoVal, 10) : null, csrf: '<?= $csrf ?>'})
        });
        const data = await res.json();
        showToast(data.ok ? 'Cargo atualizado' : (data.error || 'Erro'), data.ok ? 'success' : 'error');
    } catch {
        showToast('Erro de ligação', 'error');
    } finally {
        btn.disabled = false;
    }
}

async function savePerms() {
    const btn = document.getElementById('btnSavePerms');
    btn.disabled = true;
    try {
        const permissoes = collectGridPerms('userPermsGrid');
        const res  = await fetch('/nexora/api/utilizador_permissoes', {
            method: 'POST',
            headers: {'Content-Type':'application/json'},
            body: JSON.stringify({id: <?= (int)($utilizador['id'] ?? 0) ?>, permissoes, csrf: '<?= $csrf ?>'})
        });
        const data = await res.json();
        showToast(data.ok ? 'Permissões atualizadas' : (data.error || 'Erro'), data.ok ? 'success' : 'error');
    } catch {
        showToast('Erro de ligação', 'error');
    } finally {
        btn.disabled = false;
    }
}

// Permissões herdadas do cargo selecionado: marcar e bloquear na grelha de permissões diretas.
(function() {
    const cargoSelect = document.getElementById('f-cargo');
    const grid        = document.getElementById('userPermsGrid');
    const baseline    = new Map();
    const cache       = {};

    grid.querySelectorAll('input[type="checkbox"]').forEach(cb => baseline.set(cb.name, cb.checked));

    async function applyCargoPerms(cargoId) {
        grid.querySelectorAll('input[type="checkbox"]').forEach(cb => {
            cb.disabled = false;
            cb.checked  = baseline.get(cb.name);
            cb.closest('td').classList.remove('adm-perm-from-cargo');
        });

        if (!cargoId) return;

        if (! (cargoId in cache)) {
            try {
                const res  = await fetch('/nexora/api/cargo_permissoes_get?id=' + encodeURIComponent(cargoId));
                const data = await res.json();
                cache[cargoId] = data.ok ? (data.permissoes || []) : [];
            } catch {
                cache[cargoId] = [];
            }
        }

        cache[cargoId].forEach(p => {
            const cb = grid.querySelector(`input[name="perm[${p.modulo}][${p.acao}]"]`);
            if (cb) {
                cb.checked  = true;
                cb.disabled = true;
                cb.closest('td').classList.add('adm-perm-from-cargo');
            }
        });
    }

    cargoSelect.addEventListener('change', () => applyCargoPerms(cargoSelect.value));
    applyCargoPerms(cargoSelect.value);
})();
<?php endif; ?>

document.getElementById('userForm').addEventListener('submit', async function(e) {
    e.preventDefault();
    const btn = document.getElementById('btnSave');
    btn.disabled = true;
    const originalHtml = btn.innerHTML;
    btn.innerHTML = '<svg class="spin" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg> A guardar…';

    const msgEl = document.getElementById('formMsg');
    msgEl.innerHTML = '';

    const fd = new FormData(this);

    try {
        const res  = await fetch('/nexora/api/utilizador_save', { method: 'POST', body: fd });
        const data = await res.json();

        if (data.ok) {
            <?php if ($isEdit): ?>
            showToast(data.msg || 'Utilizador atualizado.');
            btn.disabled = false;
            btn.innerHTML = originalHtml;
            <?php else: ?>
            window.location.href = '/nexora/admin/utilizadores?msg=' + encodeURIComponent(data.msg || 'Utilizador criado com sucesso.');
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


