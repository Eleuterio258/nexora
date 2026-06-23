<?php

    $id         = $app->request->queryInt('id', 0);
    $isEdit     = $id > 0;
    $o          = null;
    $atividades = [];

    if ($isEdit) {
    $resp = $app->nexora->call('GET', "/api/crm/oportunidades/$id");
    if ($resp['status'] !== 200) {
        header('Location: /nexora/crm/oportunidades');
        exit;
    }
    $o = $resp['body'];

    $atvResp    = $app->nexora->call('GET', '/api/crm/atividades', null, ['oportunidade_id' => $id, 'limit' => 50]);
    $atividades = $atvResp['body']['data'] ?? [];
    }

    $leadIdPrefill = $app->request->queryInt('lead_id', 0) ?: null;
    $selectedLeadId = (int) ($o['lead_id'] ?? $leadIdPrefill ?? 0);
    $leadsResponse = $app->nexora->call('GET', '/api/crm/leads', null, ['limit' => 100]);
    $leads = $leadsResponse['body']['data'] ?? [];

    $loadedLeadIds = array_map('intval', array_column($leads, 'id'));
    if ($selectedLeadId > 0 && !in_array($selectedLeadId, $loadedLeadIds, true)) {
        $selectedLeadResponse = $app->nexora->call('GET', "/api/crm/leads/$selectedLeadId");
        if ($selectedLeadResponse['status'] === 200 && is_array($selectedLeadResponse['body'])) {
            $leads[] = $selectedLeadResponse['body'];
        }
    }

    usort(
        $leads,
        static fn(array $left, array $right): int =>
            strcasecmp((string) ($left['nome'] ?? ''), (string) ($right['nome'] ?? ''))
    );

    $selectedCustomerId = (int) ($o['cliente_id'] ?? 0);
    $customersResponse = $app->nexora->call('GET', '/api/clientes/', null, ['limit' => 100]);
    $customers = $customersResponse['body']['data'] ?? [];

    $loadedCustomerIds = array_map('intval', array_column($customers, 'id'));
    if ($selectedCustomerId > 0 && !in_array($selectedCustomerId, $loadedCustomerIds, true)) {
        $selectedCustomerResponse = $app->nexora->call(
            'GET',
            "/api/clientes/$selectedCustomerId"
        );
        if (
            $selectedCustomerResponse['status'] === 200
            && is_array($selectedCustomerResponse['body'])
        ) {
            $customers[] = $selectedCustomerResponse['body'];
        }
    }

    usort(
        $customers,
        static fn(array $left, array $right): int =>
            strcasecmp((string) ($left['nome'] ?? ''), (string) ($right['nome'] ?? ''))
    );

    $estagioBadges = [
    'novo'        => ['adm-badge--gray',   'Novo'],
    'qualificado' => ['adm-badge--blue',   'Qualificado'],
    'proposta'    => ['adm-badge--indigo', 'Proposta'],
    'negociacao'  => ['adm-badge--yellow', 'Negociação'],
    'ganho'       => ['adm-badge--green',  'Ganho'],
    'perdido'     => ['adm-badge--red',    'Perdido'],
    ];

    $tipoAtividade = [
    'nota'    => ['Nota',    'timeline-dot--blue',   '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>'],
    'tarefa'  => ['Tarefa',  'timeline-dot--yellow', '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 11 12 14 22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>'],
    'chamada' => ['Chamada', 'timeline-dot--indigo', '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.13.96.36 1.9.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.91.34 1.85.57 2.81.7A2 2 0 0 1 22 16.92z"/></svg>'],
    'reuniao' => ['Reunião', 'timeline-dot--green',  '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>'],
    'email'   => ['Email',   'timeline-dot--gray',   '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>'],
    ];

    $estagioBadge = $estagioBadges[$o['estagio'] ?? 'novo'] ?? ['adm-badge--gray', $o['estagio'] ?? ''];
    $isClosed     = $isEdit && in_array($o['estagio'], ['ganho', 'perdido'], true);

    $stageOrder  = ['novo', 'qualificado', 'proposta', 'negociacao', 'ganho'];
    $stageLabels = ['Novo', 'Qualificado', 'Proposta', 'Negociação', 'Ganho'];
    $currentIdx  = $isEdit ? array_search($o['estagio'], $stageOrder, true) : 0;
    if ($currentIdx === false) {
    $currentIdx = -1;
    }

    $csrf       = $app->security->csrfToken();
    $pageTitle  = $isEdit ? 'Editar Oportunidade' : 'Nova Oportunidade';
    $activePage = 'crm_oportunidades';
    $breadcrumb = [['Admin', '/nexora/'], ['CRM', ''], ['Oportunidades', '/nexora/crm/oportunidades'], [$pageTitle, '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header" style="align-items:flex-start">
    <div style="display:flex;align-items:center;gap:var(--adm-sp-3)">
        <h1 class="adm-page-title" style="margin:0"><?php echo $isEdit ? 'Editar Oportunidade' : 'Nova Oportunidade' ?></h1>
        <?php if ($isEdit): ?>
        <span class="adm-badge <?php echo $estagioBadge[0] ?>"><?php echo $estagioBadge[1] ?></span>
        <?php endif; ?>
    </div>
    <div class="adm-page-header-actions">
        <a href="/nexora/crm/oportunidades" class="adm-btn adm-btn-outline adm-btn-sm">
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

<form id="opForm">
    <input type="hidden" name="csrf_token" value="<?php echo $csrf ?>">
    <?php if ($isEdit): ?><input type="hidden" name="id" value="<?php echo $id ?>"><?php endif; ?>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Identificação</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-group">
                <label class="adm-label" for="f-titulo">Título <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="text" id="f-titulo" name="titulo" required maxlength="200"
                       placeholder="ex: Implementação ERP — ACME Lda"
                       value="<?php echo $app->view->field($o, 'titulo') ?>">
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-lead_id">Lead de Origem (ID)</label>
                    <select class="adm-select" id="f-lead_id" name="lead_id">
                        <option value="">Sem lead de origem</option>
                        <?php foreach ($leads as $lead): ?>
                        <?php
                            $leadId = (int) ($lead['id'] ?? 0);
                            $leadName = trim((string) ($lead['nome'] ?? ''));
                            $leadCompany = trim((string) ($lead['empresa'] ?? ''));
                            $leadLabel = '#' . $leadId . ' - ' . ($leadName ?: 'Lead');
                            if ($leadCompany !== '') {
                                $leadLabel .= ' (' . $leadCompany . ')';
                            }
                        ?>
                        <option value="<?php echo $leadId ?>"
                                <?php echo $selectedLeadId === $leadId ? 'selected' : '' ?>>
                            <?php echo htmlspecialchars($leadLabel) ?>
                        </option>
                        <?php endforeach; ?>
                    </select>
                    <p class="adm-help">Leads carregados diretamente do backend Nexora.</p>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-cliente_id">Cliente (ID)</label>
                    <select class="adm-select" id="f-cliente_id" name="cliente_id">
                        <option value="">Sem cliente associado</option>
                        <?php foreach ($customers as $customer): ?>
                        <?php
                            $customerId = (int) ($customer['id'] ?? 0);
                            $customerName = trim((string) ($customer['nome'] ?? ''));
                            $customerCode = trim((string) ($customer['codigo'] ?? ''));
                            $customerNuit = trim((string) ($customer['nuit'] ?? ''));
                            $customerLabel = '#' . $customerId . ' - ' . ($customerName ?: 'Cliente');
                            if ($customerCode !== '') {
                                $customerLabel .= ' [' . $customerCode . ']';
                            }
                            if ($customerNuit !== '') {
                                $customerLabel .= ' - NUIT ' . $customerNuit;
                            }
                        ?>
                        <option value="<?php echo $customerId ?>"
                                <?php echo $selectedCustomerId === $customerId ? 'selected' : '' ?>>
                            <?php echo htmlspecialchars($customerLabel) ?>
                        </option>
                        <?php endforeach; ?>
                    </select>
                    <p class="adm-help">Clientes carregados diretamente do backend Nexora.</p>
                </div>
            </div>
        </div>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Valor &amp; Previsão</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-valor_estimado">Valor Estimado</label>
                    <input class="adm-input" type="number" id="f-valor_estimado" name="valor_estimado" min="0" step="0.01"
                           value="<?php echo $o ? number_format((float) $o['valor_estimado'], 2, '.', '') : '0' ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-moeda">Moeda</label>
                    <select class="adm-select" id="f-moeda" name="moeda">
                        <?php foreach (['MZN', 'USD', 'EUR', 'ZAR'] as $m): ?>
                        <option value="<?php echo $m ?>" <?php echo ($o['moeda'] ?? 'MZN') === $m ? 'selected' : '' ?>><?php echo $m ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-probabilidade">Probabilidade (%)</label>
                    <input class="adm-input" type="number" id="f-probabilidade" name="probabilidade" min="0" max="100"
                           value="<?php echo $o ? (int) $o['probabilidade'] : '0' ?>">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-data_fecho_prevista">Data de Fecho Prevista</label>
                    <input class="adm-input" type="date" id="f-data_fecho_prevista" name="data_fecho_prevista"
                           value="<?php echo $app->view->field($o, 'data_fecho_prevista') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-responsavel">Responsável</label>
                    <input class="adm-input" type="text" id="f-responsavel" name="responsavel" maxlength="100"
                           placeholder="ex: Maria Sitoe"
                           value="<?php echo $app->view->field($o, 'responsavel') ?>">
                </div>
            </div>
            <?php if ($isEdit && ! empty($o['data_fecho_real'])): ?>
            <div class="adm-form-group" style="margin-bottom:0">
                <label class="adm-label">Data de Fecho Real</label>
                <input class="adm-input" type="text" value="<?php echo date('d/m/Y', strtotime($o['data_fecho_real'])) ?>" disabled>
            </div>
            <?php endif; ?>
        </div>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Descrição</h2></div>
        <div class="adm-card-body">
            <textarea class="adm-textarea" id="f-descricao" name="descricao" rows="4" maxlength="2000"
                      placeholder="Detalhes sobre a oportunidade..."><?php echo $app->view->field($o, 'descricao') ?></textarea>
        </div>
    </div>

    <div style="display:flex;gap:var(--adm-sp-3);justify-content:flex-end;padding-bottom:var(--adm-sp-8)">
        <a href="/nexora/crm/oportunidades" class="adm-btn adm-btn-outline">Cancelar</a>
        <button type="submit" class="adm-btn adm-btn-primary" id="btnSave">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/>
                <polyline points="17 21 17 13 7 13 7 21"/>
                <polyline points="7 3 7 8 15 8"/>
            </svg>
            <?php echo $isEdit ? 'Guardar alterações' : 'Criar Oportunidade' ?>
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
                    <input class="adm-input" type="text" id="at-responsavel" maxlength="100" value="<?php echo htmlspecialchars($o['responsavel'] ?? '') ?>">
                </div>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="at-titulo">Título <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="text" id="at-titulo" maxlength="200" placeholder="ex: Enviar proposta comercial">
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
    <!-- Estágio -->
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Estágio</h2></div>
        <div class="adm-card-body" style="padding:var(--adm-sp-2) var(--adm-sp-3)">
            <?php if ($o['estagio'] === 'perdido'): ?>
            <div class="adm-alert adm-alert--error" style="margin:var(--adm-sp-2)">
                Oportunidade perdida.
                <?php if (! empty($o['motivo_perda'])): ?>
                <div class="adm-text-xs" style="margin-top:.3rem"><?php echo nl2br(htmlspecialchars($o['motivo_perda'])) ?></div>
                <?php endif; ?>
            </div>
            <?php endif; ?>
            <div class="stage-progress" id="stageProgress">
                <?php foreach ($stageOrder as $i => $sk):
                        $cls = $i < $currentIdx ? 'done' : ($i === $currentIdx ? 'current' : '');
                ?>
                <div class="stage-step <?php echo $cls ?>"
                     <?php echo $isClosed ? '' : 'onclick="moverEstagio(\'' . $sk . '\')"' ?>
                     title="<?php echo $isClosed ? 'Oportunidade fechada' : 'Mover para ' . $stageLabels[$i] ?>">
                    <div class="stage-dot">
                        <?php if ($i < $currentIdx): ?>
                        <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
                        <?php elseif ($i === $currentIdx): ?>
                        <svg width="8" height="8" viewBox="0 0 24 24" fill="currentColor"><circle cx="12" cy="12" r="6"/></svg>
                        <?php else: ?>
                        <span style="font-size:.6rem;color:var(--adm-gray-400)"><?php echo $i + 1 ?></span>
                        <?php endif; ?>
                    </div>
                    <?php echo $stageLabels[$i] ?>
                </div>
                <?php endforeach; ?>
            </div>
        </div>
    </div>

    <?php if (! $isClosed): ?>
    <!-- Marcar como perdida -->
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Marcar como Perdida</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-group" style="margin-bottom:var(--adm-sp-3)">
                <label class="adm-label" for="motivoPerda">Motivo</label>
                <textarea class="adm-textarea" id="motivoPerda" rows="3" placeholder="ex: Optaram por outro fornecedor..."></textarea>
            </div>
            <button class="adm-btn adm-btn-outline" style="width:100%;justify-content:center;color:var(--adm-red);border-color:var(--adm-red)" onclick="marcarPerdida()">
                Marcar como Perdida
            </button>
        </div>
    </div>
    <?php endif; ?>

    <?php if (! empty($o['lead_id'])): ?>
    <!-- Lead de origem -->
    <div class="adm-card">
        <div class="adm-card-header"><h2 class="adm-card-title">Lead de Origem</h2></div>
        <div class="adm-card-body">
            <a href="/nexora/crm/leads/form?id=<?php echo (int) $o['lead_id'] ?>" class="adm-btn adm-btn-outline" style="width:100%;justify-content:center">
                Ver Lead #<?php echo (int) $o['lead_id'] ?>
            </a>
        </div>
    </div>
    <?php endif; ?>
</aside>
</div> <!-- /adm-detail-grid -->
<?php endif; ?>

<script>
const OP_ID = <?php echo $isEdit ? $id : 'null' ?>;
const CSRF  = '<?php echo $csrf ?>';

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

// ── Estágio ──────────────────────────────────────────────────
async function moverEstagio(estagio) {
    try {
        const res  = await fetch('/nexora/api/oportunidade_mover', {
            method: 'POST', headers: {'Content-Type':'application/json'},
            body: JSON.stringify({id: OP_ID, estagio, csrf: CSRF})
        });
        const data = await res.json();
        if (data.ok) { showToast('Estágio actualizado'); setTimeout(() => location.reload(), 700); }
        else showToast(data.erro || 'Erro', 'error');
    } catch { showToast('Erro de ligação', 'error'); }
}

async function marcarPerdida() {
    const motivo = document.getElementById('motivoPerda').value.trim();
    try {
        const res  = await fetch('/nexora/api/oportunidade_perder', {
            method: 'POST', headers: {'Content-Type':'application/json'},
            body: JSON.stringify({id: OP_ID, motivo_perda: motivo, csrf: CSRF})
        });
        const data = await res.json();
        if (data.ok) { showToast('Oportunidade marcada como perdida'); setTimeout(() => location.reload(), 700); }
        else showToast(data.erro || 'Erro', 'error');
    } catch { showToast('Erro de ligação', 'error'); }
}

// ── Atividades ───────────────────────────────────────────────
async function addAtividade() {
    const titulo = document.getElementById('at-titulo').value.trim();
    if (!titulo) { showToast('O título é obrigatório.', 'error'); return; }
    const payload = {
        oportunidade_id: OP_ID,
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

// ── Guardar oportunidade ─────────────────────────────────────
document.getElementById('opForm').addEventListener('submit', async function(e) {
    e.preventDefault();
    const btn = document.getElementById('btnSave');
    btn.disabled = true;
    btn.innerHTML = '<svg class="spin" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg> A guardar…';

    const msgEl = document.getElementById('formMsg');
    msgEl.innerHTML = '';

    const fd = new FormData(this);

    try {
        const res  = await fetch('/nexora/api/oportunidade_save', { method:'POST', body: fd });
        const data = await res.json();

        if (data.ok) {
            window.location.href = '/nexora/crm/oportunidades?msg=' + encodeURIComponent(data.msg || 'Oportunidade guardada com sucesso.');
        } else {
            msgEl.innerHTML = `<div class="adm-alert adm-alert--error">${data.erro || 'Erro ao guardar.'}</div>`;
            btn.disabled = false;
            btn.innerHTML = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg> <?php echo $isEdit ? 'Guardar alterações' : 'Criar Oportunidade' ?>`;
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
