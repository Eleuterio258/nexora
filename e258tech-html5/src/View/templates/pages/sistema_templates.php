<?php

    $emailTemplates = $app->nexora->call('GET', '/api/system/email-templates')['body'] ?? [];
    $smsTemplates   = $app->nexora->call('GET', '/api/system/sms-templates')['body'] ?? [];
    $integrations   = $app->nexora->call('GET', '/api/system/integrations')['body'] ?? [];

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Modelos & Integrações';
    $activePage = 'sistema_templates';
    $breadcrumb = [['Admin', '/nexora/'], ['Sistema', ''], ['Modelos & Integrações', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Modelos &amp; Integrações</h1>
</div>

<div class="adm-tabs" id="mainTabs">
    <button class="adm-tab active" onclick="switchTab('email',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
        Email
        <?php if (count($emailTemplates)): ?><span class="adm-tab-badge"><?php echo count($emailTemplates) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('sms',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"/></svg>
        SMS
        <?php if (count($smsTemplates)): ?><span class="adm-tab-badge"><?php echo count($smsTemplates) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('integracoes',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 16.98h-5.99c-1.1 0-1.95.94-2.48 1.9A4 4 0 0 1 2 17a4 4 0 0 1 4-4h12.5"/><path d="M6 7a4 4 0 0 1 7.96-.46"/><path d="M21 7l-4 4-2-2"/></svg>
        Integrações
        <?php if (count($integrations)): ?><span class="adm-tab-badge"><?php echo count($integrations) ?></span><?php endif; ?>
    </button>
</div>

<!-- ── Email ──────────────────────────────────────────────── -->
<div class="adm-tab-panel active" id="tab-email">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Modelos de Email</h2></div>
        <?php if ($emailTemplates): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Código</th><th>Assunto</th></tr>
                </thead>
                <tbody>
                <?php foreach ($emailTemplates as $t): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($t['codigo']) ?></td>
                    <td><?php echo htmlspecialchars($t['assunto']) ?></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum modelo de email registado</p>
            <p class="adm-empty-sub">Adicione o primeiro modelo usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Novo Modelo de Email</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="em-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="em-codigo" maxlength="60" placeholder="ex: candidatura.recebida">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="em-assunto">Assunto <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="em-assunto" maxlength="200" placeholder="ex: Recebemos a sua candidatura">
                </div>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="em-corpo">Corpo <span style="color:var(--adm-red)">*</span></label>
                <textarea class="adm-textarea" id="em-corpo" rows="6" placeholder="Conteúdo do email…"></textarea>
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-primary" type="button" onclick="saveEmailTemplate()">Adicionar Modelo</button>
            </div>
        </div>
    </div>
</div>

<!-- ── SMS ────────────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-sms">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Modelos de SMS</h2></div>
        <?php if ($smsTemplates): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Código</th><th>Corpo</th></tr>
                </thead>
                <tbody>
                <?php foreach ($smsTemplates as $t):
                    $corpo = $t['corpo'];
                    $resumo = mb_strlen($corpo) > 80 ? mb_substr($corpo, 0, 80) . '…' : $corpo;
                ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($t['codigo']) ?></td>
                    <td class="adm-text-sm adm-text-muted"><?php echo htmlspecialchars($resumo) ?></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum modelo de SMS registado</p>
            <p class="adm-empty-sub">Adicione o primeiro modelo usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Novo Modelo de SMS</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-group">
                <label class="adm-label" for="sm-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="text" id="sm-codigo" maxlength="60" placeholder="ex: entrevista.lembrete">
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="sm-corpo">Corpo <span style="color:var(--adm-red)">*</span></label>
                <textarea class="adm-textarea" id="sm-corpo" rows="4" maxlength="320" placeholder="Conteúdo do SMS…"></textarea>
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-primary" type="button" onclick="saveSmsTemplate()">Adicionar Modelo</button>
            </div>
        </div>
    </div>
</div>

<!-- ── Integrações ────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-integracoes">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Integrações</h2></div>
        <?php if ($integrations): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Código</th><th>Nome</th><th>Estado</th></tr>
                </thead>
                <tbody>
                <?php foreach ($integrations as $i): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($i['codigo']) ?></td>
                    <td><?php echo htmlspecialchars($i['nome']) ?></td>
                    <td><span class="adm-badge <?php echo $i['ativa'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $i['ativa'] ? 'Ativa' : 'Inativa' ?></span></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhuma integração registada</p>
            <p class="adm-empty-sub">Adicione a primeira integração usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Nova Integração</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="in-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="in-codigo" maxlength="60" placeholder="ex: whatsapp">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="in-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="in-nome" maxlength="120" placeholder="ex: WhatsApp Business">
                </div>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="in-config">Configuração (JSON)</label>
                <textarea class="adm-textarea" id="in-config" rows="4" placeholder='ex: {"api_key": "..."}'></textarea>
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-primary" type="button" onclick="saveIntegracao()">Adicionar Integração</button>
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
    const tabs = ['email', 'sms', 'integracoes'];
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

// ── Email ────────────────────────────────────────────────────
function saveEmailTemplate() {
    const codigo  = document.getElementById('em-codigo').value.trim();
    const assunto = document.getElementById('em-assunto').value.trim();
    const corpo   = document.getElementById('em-corpo').value.trim();
    if (!codigo || !assunto || !corpo) { showToast('Código, assunto e corpo são obrigatórios.', 'error'); return; }

    postJSON('/nexora/api/sistema_email_template_save', { codigo, assunto, corpo, csrf: CSRF }, 'email');
}

// ── SMS ──────────────────────────────────────────────────────
function saveSmsTemplate() {
    const codigo = document.getElementById('sm-codigo').value.trim();
    const corpo  = document.getElementById('sm-corpo').value.trim();
    if (!codigo || !corpo) { showToast('Código e corpo são obrigatórios.', 'error'); return; }

    postJSON('/nexora/api/sistema_sms_template_save', { codigo, corpo, csrf: CSRF }, 'sms');
}

// ── Integrações ──────────────────────────────────────────────
function saveIntegracao() {
    const codigo = document.getElementById('in-codigo').value.trim();
    const nome   = document.getElementById('in-nome').value.trim();
    if (!codigo || !nome) { showToast('Código e nome são obrigatórios.', 'error'); return; }

    const config = document.getElementById('in-config').value.trim();
    if (config) {
        try { JSON.parse(config); } catch { showToast('A configuração deve ser um JSON válido.', 'error'); return; }
    }

    postJSON('/nexora/api/sistema_integracao_save', {
        codigo, nome, configuracao: config || null, csrf: CSRF
    }, 'integracoes');
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
