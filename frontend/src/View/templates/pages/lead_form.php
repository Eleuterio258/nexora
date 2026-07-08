<?php

    $idHash = $app->request->queryString('id');
    $isEdit = $idHash !== '';
    $lead       = null;
    $atividades = [];

    if ($isEdit) {
    $resp = $app->nexora->call('GET', "/api/crm/leads/$idHash");
    if ($resp['status'] !== 200) {
        header('Location: /nexora/crm/leads');
        exit;
    }
    $lead = $resp['body'];

    $atvResp    = $app->nexora->call('GET', '/api/crm/atividades', null, ['lead_id' => $id, 'limit' => 50]);
    $atividades = $atvResp['body']['data'] ?? [];
    }

    $origemLabels = [
    'site'          => 'Site',
    'referencia'    => 'Referência',
    'redes_sociais' => 'Redes Sociais',
    'evento'        => 'Evento',
    'chamada_fria'  => 'Chamada Fria',
    'email'         => 'Email',
    'anuncio'       => 'Anúncio',
    'outro'         => 'Outro',
    ];

    $estadoBadges = [
    'novo'           => ['adm-badge--gray',   'Novo'],
    'contactado'     => ['adm-badge--blue',   'Contactado'],
    'qualificado'    => ['adm-badge--indigo', 'Qualificado'],
    'desqualificado' => ['adm-badge--red',    'Desqualificado'],
    'convertido'     => ['adm-badge--green',  'Convertido'],
    ];

    $tipoAtividade = [
    'nota'    => ['Nota',    'timeline-dot--blue',   '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>'],
    'tarefa'  => ['Tarefa',  'timeline-dot--yellow', '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 11 12 14 22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>'],
    'chamada' => ['Chamada', 'timeline-dot--indigo', '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.13.96.36 1.9.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.91.34 1.85.57 2.81.7A2 2 0 0 1 22 16.92z"/></svg>'],
    'reuniao' => ['Reunião', 'timeline-dot--green',  '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>'],
    'email'   => ['Email',   'timeline-dot--gray',   '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>'],
    ];

    $estadoBadge = $estadoBadges[$lead['estado'] ?? 'novo'] ?? ['adm-badge--gray', $lead['estado'] ?? ''];

    $csrf       = $app->security->csrfToken();
    $pageTitle  = $isEdit ? 'Editar Lead' : 'Novo Lead';
    $activePage = 'crm_leads';
    $breadcrumb = [['Admin', '/nexora/'], ['CRM', ''], ['Leads', '/nexora/crm/leads'], [$pageTitle, '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header" style="align-items:flex-start">
    <div style="display:flex;align-items:center;gap:var(--adm-sp-3)">
        <h1 class="adm-page-title" style="margin:0"><?php echo $isEdit ? 'Editar Lead' : 'Novo Lead' ?></h1>
        <?php if ($isEdit): ?>
        <span class="adm-badge <?php echo $estadoBadge[0] ?>"><?php echo $estadoBadge[1] ?></span>
        <?php endif; ?>
    </div>
    <div class="adm-page-header-actions">
        <a href="/nexora/crm/leads" class="adm-btn adm-btn-outline adm-btn-sm">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>
            Voltar
        </a>
    </div>
</div>

<div id="formMsg"></div>

<?php if ($isEdit): ?>
<div class="adm-detail-grid">
<div>
<div class="adm-tabs" id="mainTabs">
    <button class="adm-tab active" onclick="switchTab('info',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="8" r="4"/><path d="M20 21a8 8 0 1 0-16 0"/></svg>
        Informação
    </button>
    <button class="adm-tab" onclick="switchTab('atividades',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
        Atividades
        <?php if (count($atividades)): ?>
        <span class="adm-tab-badge"><?php echo count($atividades) ?></span>
        <?php endif; ?>
    </button>
</div>

<div class="adm-tab-panel active" id="tab-info">
<?php endif; ?>

<form id="leadForm">
    <input type="hidden" name="csrf_token" value="<?php echo $csrf ?>">
    <?php if ($isEdit): ?><input type="hidden" name="id" value="<?php echo $id ?>"><?php endif; ?>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Identificação</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="f-nome" name="nome" required maxlength="150"
                           placeholder="ex: João Macamo"
                           value="<?php echo $app->view->field($lead, 'nome') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-empresa">Empresa</label>
                    <input class="adm-input" type="text" id="f-empresa" name="empresa" maxlength="150"
                           placeholder="ex: ACME Lda"
                           value="<?php echo $app->view->field($lead, 'empresa') ?>">
                </div>
            </div>
        </div>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Contacto</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-email">Email</label>
                    <input class="adm-input" type="email" id="f-email" name="email" maxlength="255"
                           placeholder="ex: joao@acme.co.mz"
                           value="<?php echo $app->view->field($lead, 'email') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-telefone">Telefone</label>
                    <input class="adm-input" type="text" id="f-telefone" name="telefone" maxlength="30"
                           placeholder="ex: +258 84 000 0000"
                           value="<?php echo $app->view->field($lead, 'telefone') ?>">
                </div>
            </div>
        </div>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Classificação</h2></div>
        <div class="adm-card-body">
            <div class="<?php echo $isEdit ? 'adm-form-row-3' : 'adm-form-row' ?>">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-origem">Origem</label>
                    <select class="adm-select" id="f-origem" name="origem">
                        <?php foreach ($origemLabels as $key => $label): ?>
                        <option value="<?php echo $key ?>" <?php echo ($lead['origem'] ?? 'outro') === $key ? 'selected' : '' ?>><?php echo $label ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-responsavel">Responsável</label>
                    <input class="adm-input" type="text" id="f-responsavel" name="responsavel" maxlength="100"
                           placeholder="ex: Maria Sitoe"
                           value="<?php echo $app->view->field($lead, 'responsavel') ?>">
                </div>
                <?php if ($isEdit): ?>
                <div class="adm-form-group">
                    <label class="adm-label">Estado</label>
                    <input class="adm-input" type="text" value="<?php echo $estadoBadge[1] ?>" disabled>
                    <p class="adm-input-hint">Altera-se na barra lateral.</p>
                </div>
                <?php endif; ?>
            </div>
        </div>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Notas</h2></div>
        <div class="adm-card-body">
            <textarea class="adm-textarea" id="f-notas" name="notas" rows="4" maxlength="2000"
                      placeholder="Notas internas sobre este lead..."><?php echo $app->view->field($lead, 'notas') ?></textarea>
        </div>
    </div>

    <div style="display:flex;gap:var(--adm-sp-3);justify-content:flex-end;padding-bottom:var(--adm-sp-8)">
        <a href="/nexora/crm/leads" class="adm-btn adm-btn-outline">Cancelar</a>
        <button type="submit" class="adm-btn adm-btn-primary" id="btnSave">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/>
                <polyline points="17 21 17 13 7 13 7 21"/>
                <polyline points="7 3 7 8 15 8"/>
            </svg>
            <?php echo $isEdit ? 'Guardar alterações' : 'Criar Lead' ?>
        </button>
    </div>
</form>

<?php if ($isEdit): ?>
</div> <!-- /tab-info -->

<div class="adm-tab-panel" id="tab-atividades">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Nova Atividade</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="at-tipo">Tipo</label>
                    <select class="adm-select" id="at-tipo">
                        <?php foreach ($tipoAtividade as $key => [$label, , ]): ?>
                        <option value="<?php echo $key ?>"><?php echo $label ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="at-data">Data / Hora</label>
                    <input class="adm-input" type="datetime-local" id="at-data">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="at-responsavel">Responsável</label>
                    <input class="adm-input" type="text" id="at-responsavel" maxlength="100" value="<?php echo htmlspecialchars($lead['responsavel'] ?? '') ?>">
                </div>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="at-titulo">Título <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="text" id="at-titulo" maxlength="200" placeholder="ex: Ligar para apresentar proposta">
            </div>
            <div class="adm-form-group" style="margin-bottom:0">
                <label class="adm-label" for="at-descricao">Descrição</label>
                <textarea class="adm-textarea" id="at-descricao" rows="3" placeholder="Detalhes da atividade..."></textarea>
            </div>
            <div style="margin-top:var(--adm-sp-4)">
                <button class="adm-btn adm-btn-primary" onclick="addAtividade()">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                    Adicionar Atividade
                </button>
            </div>
        </div>
    </div>

    <div class="timeline" id="timeline">
        <?php foreach ($atividades as $a):
                [$tipoLabel, $dotClass, $dotIcon] = $tipoAtividade[$a['tipo']] ?? $tipoAtividade['nota'];
                $quando = $a['data_atividade'] ?? $a['created_at'];
        ?>
        <div class="timeline-item">
            <div class="timeline-dot <?php echo $dotClass ?>"><?php echo $dotIcon ?></div>
            <div class="timeline-body">
                <div class="timeline-header">
                    <span class="timeline-author"><?php echo $tipoLabel ?><?php echo $a['responsavel'] ? ' · ' . htmlspecialchars($a['responsavel']) : '' ?></span>
                    <span class="timeline-time"><?php echo $quando ? date('d/m/Y H:i', strtotime($quando)) : '' ?></span>
                </div>
                <div class="timeline-content">
                    <p class="adm-fw-600" style="margin-bottom:.2rem"><?php echo htmlspecialchars($a['titulo']) ?></p>
                    <?php if ($a['descricao']): ?><p><?php echo nl2br(htmlspecialchars($a['descricao'])) ?></p><?php endif; ?>
                </div>
                <div style="margin-top:var(--adm-sp-2)">
                    <?php if ($a['concluida']): ?>
                    <span class="adm-badge adm-badge--green">Concluída</span>
                    <?php else: ?>
                    <button class="adm-btn adm-btn-ghost adm-btn-sm" onclick="concluirAtividade(<?php echo $a['id'] ?>, this)">Marcar concluída</button>
                    <?php endif; ?>
                </div>
            </div>
        </div>
        <?php endforeach; ?>
        <?php if (empty($atividades)): ?>
        <p class="adm-text-muted adm-text-sm" style="padding-left:2.5rem">Sem atividades ainda. Adiciona a primeira acima.</p>
        <?php endif; ?>
    </div>
</div>

</div> <!-- /main col -->

<aside>
    <!-- Estado do Lead -->
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Estado do Lead</h2></div>
        <div class="adm-card-body">
            <div style="margin-bottom:var(--adm-sp-3)">
                <span class="adm-badge <?php echo $estadoBadge[0] ?>" style="font-size:var(--adm-text-sm)"><?php echo $estadoBadge[1] ?></span>
            </div>
            <?php if ($lead['estado'] !== 'convertido'): ?>
            <div style="display:flex;flex-direction:column;gap:var(--adm-sp-2)">
                <?php foreach (['novo' => 'Novo', 'contactado' => 'Contactado', 'qualificado' => 'Qualificado', 'desqualificado' => 'Desqualificado'] as $key => $label): ?>
                <?php if ($key !== $lead['estado']): ?>
                <button class="adm-btn adm-btn-outline adm-btn-sm" onclick="moverEstado('<?php echo $key ?>')" style="justify-content:flex-start">
                    Mover para "<?php echo $label ?>"
                </button>
                <?php endif; ?>
                <?php endforeach; ?>
            </div>
            <?php else: ?>
            <p class="adm-text-muted adm-text-sm" style="margin:0">Este lead já foi convertido — o estado está bloqueado.</p>
            <?php endif; ?>
        </div>
    </div>

    <?php if ($lead['estado'] !== 'convertido'): ?>
    <!-- Converter Lead -->
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Converter Lead</h2></div>
        <div class="adm-card-body" id="convertCardBody">
            <p class="adm-text-sm adm-text-muted" style="margin-bottom:var(--adm-sp-3)">
                Cria um cliente a partir deste lead. Opcionalmente, cria também uma oportunidade de venda associada.
            </p>
            <label class="adm-toggle" style="margin-bottom:var(--adm-sp-3)">
                <input type="checkbox" id="conv-criar-oportunidade" checked onchange="toggleOportunidadeFields()">
                <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                <span class="adm-toggle-label">Criar oportunidade automaticamente</span>
            </label>
            <div id="conv-oportunidade-fields">
                <div class="adm-form-group">
                    <label class="adm-label" for="conv-titulo">Título da Oportunidade</label>
                    <input class="adm-input" type="text" id="conv-titulo" maxlength="200" placeholder="Oportunidade — <?php echo $app->view->field($lead, 'nome') ?>">
                </div>
                <div class="adm-form-row">
                    <div class="adm-form-group">
                        <label class="adm-label" for="conv-valor">Valor Estimado</label>
                        <input class="adm-input" type="number" id="conv-valor" min="0" step="0.01" placeholder="0.00">
                    </div>
                    <div class="adm-form-group">
                        <label class="adm-label" for="conv-moeda">Moeda</label>
                        <select class="adm-select" id="conv-moeda">
                            <?php foreach (['MZN', 'USD', 'EUR', 'ZAR'] as $m): ?>
                            <option value="<?php echo $m ?>"><?php echo $m ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                </div>
            </div>
            <button class="adm-btn adm-btn-primary" style="width:100%;justify-content:center" onclick="converterLead()">
                Converter Lead
            </button>
        </div>
    </div>
    <?php endif; ?>

    <?php if (! empty($lead['cliente_id'])): ?>
    <!-- Cliente associado -->
    <div class="adm-card">
        <div class="adm-card-header"><h2 class="adm-card-title">Cliente Associado</h2></div>
        <div class="adm-card-body">
            <p class="adm-text-sm" style="margin:0">Cliente #<?php echo (int) $lead['cliente_id'] ?></p>
            <?php if (! empty($lead['convertido_em'])): ?>
            <p class="adm-text-xs adm-text-muted" style="margin:.3rem 0 0">Convertido em <?php echo date('d/m/Y H:i', strtotime($lead['convertido_em'])) ?></p>
            <?php endif; ?>
        </div>
    </div>
    <?php endif; ?>
</aside>
</div> <!-- /adm-detail-grid -->
<?php endif; ?>

<script>
const LEAD_ID = <?php echo $isEdit ? $id : 'null' ?>;
const CSRF    = '<?php echo $csrf ?>';

// ── Tabs ─────────────────────────────────────────────────────
function switchTab(name, btn) {
    document.querySelectorAll('.adm-tab-panel').forEach(p => p.classList.remove('active'));
    document.querySelectorAll('.adm-tab').forEach(b => b.classList.remove('active'));
    document.getElementById('tab-' + name).classList.add('active');
    btn.classList.add('active');
}

document.addEventListener('DOMContentLoaded', () => {
    if (location.hash === '#atividades') {
        const btn = document.querySelectorAll('#mainTabs .adm-tab')[1];
        if (btn) switchTab('atividades', btn);
    }
});

// ── Estado do lead ───────────────────────────────────────────
async function moverEstado(estado) {
    try {
        const res  = await fetch('/nexora/api/lead_mover', {
            method: 'POST', headers: {'Content-Type':'application/json'},
            body: JSON.stringify({id: LEAD_ID, estado, csrf: CSRF})
        });
        const data = await res.json();
        if (data.ok) { showToast('Estado actualizado'); setTimeout(() => location.reload(), 700); }
        else showToast(data.erro || 'Erro', 'error');
    } catch { showToast('Erro de ligação', 'error'); }
}

// ── Converter lead ───────────────────────────────────────────
function toggleOportunidadeFields() {
    document.getElementById('conv-oportunidade-fields').style.display =
        document.getElementById('conv-criar-oportunidade').checked ? '' : 'none';
}

async function converterLead() {
    const criarOp = document.getElementById('conv-criar-oportunidade').checked;
    const payload = { id: LEAD_ID, criar_oportunidade: criarOp, csrf: CSRF };
    if (criarOp) {
        const titulo = document.getElementById('conv-titulo').value.trim();
        const valor  = document.getElementById('conv-valor').value;
        if (titulo) payload.oportunidade_titulo = titulo;
        if (valor !== '') payload.valor_estimado = parseFloat(valor);
        payload.moeda = document.getElementById('conv-moeda').value;
    }
    try {
        const res  = await fetch('/nexora/api/lead_converter', {
            method: 'POST', headers: {'Content-Type':'application/json'},
            body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            let html = '<div class="adm-alert adm-alert--success" style="margin-bottom:var(--adm-sp-3)">Lead convertido com sucesso. Cliente #' + data.cliente_id + ' criado.</div>';
            if (data.oportunidade_id) {
                html += '<a href="/nexora/crm/oportunidades/form?id=' + nexoraEncodeId(data.oportunidade_id) + '" class="adm-btn adm-btn-outline" style="width:100%;justify-content:center">Ver oportunidade criada</a>';
            }
            document.getElementById('convertCardBody').innerHTML = html;
            showToast('Lead convertido');
            setTimeout(() => location.reload(), 1500);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}

// ── Atividades ───────────────────────────────────────────────
async function addAtividade() {
    const titulo = document.getElementById('at-titulo').value.trim();
    if (!titulo) { showToast('O título é obrigatório.', 'error'); return; }
    const payload = {
        lead_id: LEAD_ID,
        tipo: document.getElementById('at-tipo').value,
        titulo,
        descricao: document.getElementById('at-descricao').value.trim() || null,
        data_atividade: document.getElementById('at-data').value || null,
        responsavel: document.getElementById('at-responsavel').value.trim() || null,
        csrf: CSRF
    };
    try {
        const res  = await fetch('/nexora/api/atividade_save', {
            method: 'POST', headers: {'Content-Type':'application/json'},
            body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            location.hash = 'atividades';
            location.reload();
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}

async function concluirAtividade(id, btn) {
    try {
        const res  = await fetch('/nexora/api/atividade_concluir', {
            method: 'POST', headers: {'Content-Type':'application/json'},
            body: JSON.stringify({id, csrf: CSRF})
        });
        const data = await res.json();
        if (data.ok) {
            btn.outerHTML = '<span class="adm-badge adm-badge--green">Concluída</span>';
            showToast('Atividade concluída');
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}

// ── Guardar lead ─────────────────────────────────────────────
document.getElementById('leadForm').addEventListener('submit', async function(e) {
    e.preventDefault();
    const btn = document.getElementById('btnSave');
    btn.disabled = true;
    btn.innerHTML = '<svg class="spin" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg> A guardar…';

    const msgEl = document.getElementById('formMsg');
    msgEl.innerHTML = '';

    const fd = new FormData(this);

    try {
        const res  = await fetch('/nexora/api/lead_save', { method:'POST', body: fd });
        const data = await res.json();

        if (data.ok) {
            window.location.href = '/nexora/crm/leads?msg=' + encodeURIComponent(data.msg || 'Lead guardado com sucesso.');
        } else {
            msgEl.innerHTML = `<div class="adm-alert adm-alert--error">${data.erro || 'Erro ao guardar.'}</div>`;
            btn.disabled = false;
            btn.innerHTML = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg> <?php echo $isEdit ? 'Guardar alterações' : 'Criar Lead' ?>`;
        }
    } catch {
        msgEl.innerHTML = '<div class="adm-alert adm-alert--error">Erro de ligação.</div>';
        btn.disabled = false;
    }
});

// Spin animation
const style = document.createElement('style');
style.textContent = '.spin{animation:spin .7s linear infinite}@keyframes spin{to{transform:rotate(360deg)}}';
document.head.appendChild(style);
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>


