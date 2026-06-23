<?php

$perfilResp = $app->nexora->call('GET', '/api/self-service/perfil/');
$perfil = ($perfilResp['status'] === 200 && is_array($perfilResp['body'])) ? $perfilResp['body'] : [];

$docsResp = $app->nexora->call('GET', '/api/self-service/perfil/documentos');
$docs = ($docsResp['status'] === 200 && is_array($docsResp['body']) && array_is_list($docsResp['body'])) ? $docsResp['body'] : [];

$csrf       = $app->security->csrfToken();
$pageTitle  = 'Meu Perfil';
$activePage = 'meu_perfil';
$breadcrumb = [['Admin', '/nexora/'], ['Meu Perfil', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title"><i class="fa-solid fa-user-circle" style="color:var(--adm-green)"></i> Meu Perfil</h1>
</div>

<div class="adm-tabs" id="mainTabs">
    <button class="adm-tab active" onclick="switchTab('dados',this)">
        <i class="fa-solid fa-user"></i> Dados Pessoais
    </button>
    <button class="adm-tab" onclick="switchTab('contrato',this)">
        <i class="fa-solid fa-file-contract"></i> Contrato
    </button>
    <button class="adm-tab" onclick="switchTab('documentos',this)">
        <i class="fa-solid fa-folder"></i> Documentos
    </button>
    <button class="adm-tab" onclick="switchTab('seguranca',this)">
        <i class="fa-solid fa-lock"></i> Segurança
    </button>
</div>

<!-- Tab: Dados Pessoais -->
<div class="adm-tab-panel active" id="tab-dados">
    <div id="perfilMsg"></div>
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header">
            <h2 class="adm-card-title">Dados Pessoais</h2>
        </div>
        <div class="adm-card-body">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label">Nome</label>
                    <input class="adm-input" type="text" id="pNome" value="<?= htmlspecialchars($perfil['nome'] ?? '') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label">Email</label>
                    <input class="adm-input" type="email" value="<?= htmlspecialchars($perfil['email'] ?? '') ?>" disabled>
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label">Telefone</label>
                    <input class="adm-input" type="text" id="pTelefone" value="<?= htmlspecialchars($perfil['telefone'] ?? '') ?>" placeholder="+258 84 000 0000">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label">Último login</label>
                    <input class="adm-input" type="text" value="<?= !empty($perfil['ultimo_login_em']) ? date('d/m/Y H:i', strtotime($perfil['ultimo_login_em'])) : 'Nunca' ?>" disabled>
                </div>
            </div>
            <button class="adm-btn adm-btn-primary" id="btnSavePerfil" onclick="guardarPerfil()">
                <i class="fa-solid fa-floppy-disk"></i> Guardar alterações
            </button>
        </div>
    </div>
</div>

<!-- Tab: Contrato -->
<div class="adm-tab-panel" id="tab-contrato">
    <div class="adm-card">
        <div class="adm-card-header"><h2 class="adm-card-title">Informações do Contrato</h2></div>
        <div class="adm-card-body">
            <?php if (!empty($perfil['funcionario_id'])): ?>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:var(--adm-sp-6)">
                <div>
                    <div class="adm-detail-pair">
                        <div class="adm-detail-pair-label">Nome Completo</div>
                        <div class="adm-detail-pair-value"><?= htmlspecialchars($perfil['nome_completo'] ?? '—') ?></div>
                    </div>
                    <div class="adm-detail-pair">
                        <div class="adm-detail-pair-label">Cargo</div>
                        <div class="adm-detail-pair-value"><?= htmlspecialchars($perfil['cargo'] ?? '—') ?></div>
                    </div>
                    <div class="adm-detail-pair">
                        <div class="adm-detail-pair-label">Departamento</div>
                        <div class="adm-detail-pair-value"><?= htmlspecialchars($perfil['departamento'] ?? '—') ?></div>
                    </div>
                </div>
                <div>
                    <div class="adm-detail-pair">
                        <div class="adm-detail-pair-label">Data de Admissão</div>
                        <div class="adm-detail-pair-value"><?= !empty($perfil['data_admissao']) ? date('d/m/Y', strtotime($perfil['data_admissao'])) : '—' ?></div>
                    </div>
                    <div class="adm-detail-pair">
                        <div class="adm-detail-pair-label">Tipo de Contrato</div>
                        <div class="adm-detail-pair-value"><?= htmlspecialchars(ucfirst($perfil['tipo_contrato'] ?? '—')) ?></div>
                    </div>
                </div>
            </div>
            <?php else: ?>
            <div class="adm-empty">
                <i class="fa-solid fa-file-contract" style="font-size:2rem;opacity:.3"></i>
                <p class="adm-empty-title">Sem registo de funcionário associado</p>
                <p class="adm-text-sm adm-text-muted">Contacte o departamento de RH.</p>
            </div>
            <?php endif; ?>
        </div>
    </div>
</div>

<!-- Tab: Documentos -->
<div class="adm-tab-panel" id="tab-documentos">
    <div class="adm-card">
        <div class="adm-card-header"><h2 class="adm-card-title">Documentos Pessoais</h2></div>
        <?php if ($docs): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead><tr><th>Tipo</th><th>Nome</th><th>Data</th><th></th></tr></thead>
                <tbody>
                <?php foreach ($docs as $d): ?>
                <tr>
                    <td><span class="adm-badge adm-badge--gray"><?= htmlspecialchars($d['tipo'] ?? '—') ?></span></td>
                    <td class="adm-fw-600"><?= htmlspecialchars($d['nome'] ?? '—') ?></td>
                    <td class="adm-text-muted"><?= !empty($d['created_at']) ? date('d/m/Y', strtotime($d['created_at'])) : '—' ?></td>
                    <td>
                        <?php if (!empty($d['url'])): ?>
                        <a href="<?= htmlspecialchars($d['url']) ?>" target="_blank" class="adm-btn adm-btn-ghost adm-btn-sm">
                            <i class="fa-solid fa-download"></i>
                        </a>
                        <?php endif; ?>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <i class="fa-solid fa-folder-open" style="font-size:2rem;opacity:.3"></i>
            <p class="adm-empty-title">Sem documentos</p>
        </div>
        <?php endif; ?>
    </div>
</div>

<!-- Tab: Segurança -->
<div class="adm-tab-panel" id="tab-seguranca">
    <div class="adm-card" style="max-width:480px">
        <div class="adm-card-header"><h2 class="adm-card-title">Alterar Senha</h2></div>
        <div class="adm-card-body">
            <div id="senhaMsg"></div>
            <div class="adm-form-group">
                <label class="adm-label">Senha actual</label>
                <input class="adm-input" type="password" id="senhaActual" placeholder="••••••••">
            </div>
            <div class="adm-form-group">
                <label class="adm-label">Nova senha</label>
                <input class="adm-input" type="password" id="senhaNova" placeholder="Mínimo 8 caracteres">
            </div>
            <div class="adm-form-group">
                <label class="adm-label">Confirmar nova senha</label>
                <input class="adm-input" type="password" id="senhaConfirmar" placeholder="Repita a nova senha">
            </div>
            <button class="adm-btn adm-btn-primary" id="btnSenha" onclick="alterarSenha()">
                <i class="fa-solid fa-lock"></i> Alterar Senha
            </button>
        </div>
    </div>
</div>

<script>
const CSRF = <?= json_encode($csrf) ?>;

function switchTab(name, btn) {
    document.querySelectorAll('.adm-tab-panel').forEach(p => p.classList.remove('active'));
    document.querySelectorAll('.adm-tab').forEach(b => b.classList.remove('active'));
    document.getElementById('tab-' + name).classList.add('active');
    btn.classList.add('active');
}

async function guardarPerfil() {
    const btn = document.getElementById('btnSavePerfil');
    btn.disabled = true;
    const resp = await fetch('/nexora/api/self_service_perfil_update', {
        method: 'POST',
        headers: {'Content-Type':'application/json'},
        body: JSON.stringify({
            nome: document.getElementById('pNome').value.trim() || null,
            telefone: document.getElementById('pTelefone').value.trim() || null,
            csrf_token: CSRF
        })
    });
    const data = await resp.json();
    btn.disabled = false;
    if (data.ok) showToast('Perfil actualizado');
    else showToast(data.error || 'Erro', 'error');
}

async function alterarSenha() {
    const actual = document.getElementById('senhaActual').value;
    const nova   = document.getElementById('senhaNova').value;
    const conf   = document.getElementById('senhaConfirmar').value;
    const msg    = document.getElementById('senhaMsg');
    msg.innerHTML = '';
    if (!actual) { msg.innerHTML='<div class="adm-alert adm-alert--error">Introduza a senha actual.</div>'; return; }
    if (nova.length < 8) { msg.innerHTML='<div class="adm-alert adm-alert--error">A nova senha deve ter pelo menos 8 caracteres.</div>'; return; }
    if (nova !== conf) { msg.innerHTML='<div class="adm-alert adm-alert--error">As senhas não coincidem.</div>'; return; }
    const btn = document.getElementById('btnSenha');
    btn.disabled = true;
    const resp = await fetch('/nexora/api/self_service_senha', {
        method: 'POST',
        headers: {'Content-Type':'application/json'},
        body: JSON.stringify({senha_actual: actual, senha_nova: nova, csrf_token: CSRF})
    });
    const data = await resp.json();
    btn.disabled = false;
    if (data.ok) {
        showToast('Senha alterada. Será redireccionado para o login…');
        setTimeout(() => window.location.href = '/nexora/logout', 2000);
    } else {
        msg.innerHTML = `<div class="adm-alert adm-alert--error">${data.error||'Erro'}</div>`;
    }
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
