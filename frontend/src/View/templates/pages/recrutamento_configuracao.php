<?php

    $csrf = $app->security->csrfToken();

    $camposResp = $app->nexora->call('GET', '/api/recrutamento/campos-custom');
    $campos = (is_array($camposResp['body'] ?? null) && array_is_list($camposResp['body'])) ? $camposResp['body'] : [];
    usort($campos, fn($a, $b) => ($a['ordem'] ?? 0) <=> ($b['ordem'] ?? 0) ?: ($a['id'] ?? 0) <=> ($b['id'] ?? 0));

    $notifResp = $app->nexora->call('GET', '/api/recrutamento/config-notificacoes');
    $notif = is_array($notifResp['body'] ?? null) ? $notifResp['body'] : [];

    $tipos = [
        'texto'       => 'Texto curto',
        'textarea'    => 'Texto longo',
        'numero'      => 'Número',
        'data'        => 'Data',
        'select'      => 'Seleção única',
        'multiselect' => 'Múltipla escolha',
        'checkbox'    => 'Checkbox',
        'ficheiro'    => 'Ficheiro',
    ];

    $pageTitle  = 'Configuração do Recrutamento';
    $activePage = 'recrutamento_configuracao';
    $breadcrumb = [['Admin', '/nexora/'], ['Recrutamento', ''], ['Configuração', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Configuração do Recrutamento</h1>
</div>

<div id="formMsg"></div>

<div class="adm-tabs" id="configTabs">
    <button class="adm-tab active" onclick="switchTab('campos', this)">
        <i class="fa-solid fa-list-check fa-fw" style="margin-right:6px"></i> Campos Customizáveis
    </button>
    <button class="adm-tab" onclick="switchTab('notificacoes', this)">
        <i class="fa-solid fa-bell fa-fw" style="margin-right:6px"></i> Notificações
    </button>
</div>

<!-- Tab: Campos Customizáveis -->
<div class="adm-tab-panel active" id="tab-campos">
    <div class="adm-card">
        <div class="adm-card-header">
            <div>
                <h2 class="adm-card-title">Campos Customizáveis do Formulário</h2>
                <p class="adm-card-subtitle">Campos adicionais que aparecem no formulário público de candidatura.</p>
            </div>
            <button class="adm-btn adm-btn-primary adm-btn-sm" type="button" onclick="openCampoModal()">
                <i class="fa-solid fa-plus fa-fw"></i> Novo Campo
            </button>
        </div>
        <div class="adm-card-body">
            <?php if ($campos): ?>
            <div class="adm-table-wrap">
                <table class="adm-table" id="camposTable">
                    <thead>
                        <tr>
                            <th style="width:60px">Ordem</th>
                            <th>Código</th>
                            <th>Label</th>
                            <th>Tipo</th>
                            <th>Obrigatório</th>
                            <th>Ativo</th>
                            <th>Ações</th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php foreach ($campos as $c):
                        $opcoes = is_array($c['opcoes'] ?? null) ? implode("\n", $c['opcoes']) : '';
                    ?>
                        <tr data-id="<?= $c['id'] ?>"
                            data-codigo="<?= htmlspecialchars($c['codigo'] ?? '') ?>"
                            data-label="<?= htmlspecialchars($c['label'] ?? '') ?>"
                            data-tipo="<?= htmlspecialchars($c['tipo'] ?? 'texto') ?>"
                            data-opcoes="<?= htmlspecialchars($opcoes) ?>"
                            data-obrigatorio="<?= !empty($c['obrigatorio']) ? '1' : '0' ?>"
                            data-ativo="<?= !empty($c['ativo']) ? '1' : '0' ?>"
                            data-ordem="<?= (int)($c['ordem'] ?? 0) ?>">
                            <td><?= (int)($c['ordem'] ?? 0) ?></td>
                            <td><code class="adm-badge adm-badge--gray"><?= htmlspecialchars($c['codigo'] ?? '') ?></code></td>
                            <td><?= htmlspecialchars($c['label'] ?? '') ?></td>
                            <td><?= htmlspecialchars($tipos[$c['tipo'] ?? 'texto'] ?? $c['tipo']) ?></td>
                            <td><?= !empty($c['obrigatorio']) ? '<span class="adm-badge adm-badge--green">Sim</span>' : '<span class="adm-badge adm-badge--gray">Não</span>' ?></td>
                            <td>
                                <label class="adm-toggle adm-toggle-sm" style="margin:0">
                                    <input type="checkbox" <?= !empty($c['ativo']) ? 'checked' : '' ?> onchange="toggleAtivo(<?= $c['id'] ?>, this.checked)">
                                    <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                                </label>
                            </td>
                            <td>
                                <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" onclick="openCampoModal(<?= $c['id'] ?>)" title="Editar">
                                    <i class="fa-solid fa-pen"></i>
                                </button>
                                <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" onclick="eliminarCampo(<?= $c['id'] ?>)" title="Eliminar">
                                    <i class="fa-solid fa-trash" style="color:var(--adm-red)"></i>
                                </button>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
            <?php else: ?>
            <div class="adm-empty-state">
                <div class="adm-empty-state-icon"><i class="fa-solid fa-list-check"></i></div>
                <p class="adm-empty-state-title">Nenhum campo customizável</p>
                <p class="adm-empty-state-text">Adiciona campos para enriquecer o formulário de candidatura.</p>
            </div>
            <?php endif; ?>
        </div>
    </div>
</div>

<!-- Tab: Notificações -->
<div class="adm-tab-panel" id="tab-notificacoes">
    <div class="adm-card">
        <div class="adm-card-header">
            <div>
                <h2 class="adm-card-title">Notificações Automáticas</h2>
                <p class="adm-card-subtitle">Define quando os candidatos recebem notificações por email ou SMS.</p>
            </div>
        </div>
        <div class="adm-card-body">
            <form id="notifForm" style="max-width:720px">
                <input type="hidden" name="csrf_token" value="<?= $csrf ?>">

                <div class="adm-form-group adm-mb-5">
                    <label class="adm-label">Canais de notificação</label>
                    <div style="display:flex;flex-direction:column;gap:var(--adm-sp-3)">
                        <label class="adm-toggle">
                            <input type="checkbox" name="canal_email" value="1" <?= !empty($notif['canal_email']) ? 'checked' : '' ?>>
                            <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                            <span class="adm-toggle-label">Enviar notificações por email</span>
                        </label>
                        <label class="adm-toggle">
                            <input type="checkbox" name="canal_sms" value="1" <?= !empty($notif['canal_sms']) ? 'checked' : '' ?>>
                            <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                            <span class="adm-toggle-label">Enviar notificações por SMS</span>
                        </label>
                    </div>
                </div>

                <div class="adm-form-group adm-mb-5">
                    <label class="adm-label">Eventos que disparam notificação</label>
                    <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:var(--adm-sp-3)">
                        <label class="adm-toggle">
                            <input type="checkbox" name="notificar_candidatura_recebida" value="1" <?= !empty($notif['notificar_candidatura_recebida']) ? 'checked' : '' ?>>
                            <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                            <span class="adm-toggle-label">Candidatura recebida</span>
                        </label>
                        <label class="adm-toggle">
                            <input type="checkbox" name="notificar_em_analise" value="1" <?= !empty($notif['notificar_em_analise']) ? 'checked' : '' ?>>
                            <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                            <span class="adm-toggle-label">Candidatura em análise</span>
                        </label>
                        <label class="adm-toggle">
                            <input type="checkbox" name="notificar_entrevista_agendada" value="1" <?= !empty($notif['notificar_entrevista_agendada']) ? 'checked' : '' ?>>
                            <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                            <span class="adm-toggle-label">Entrevista agendada</span>
                        </label>
                        <label class="adm-toggle">
                            <input type="checkbox" name="notificar_aprovada" value="1" <?= !empty($notif['notificar_aprovada']) ? 'checked' : '' ?>>
                            <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                            <span class="adm-toggle-label">Candidatura aprovada</span>
                        </label>
                        <label class="adm-toggle">
                            <input type="checkbox" name="notificar_rejeitada" value="1" <?= !empty($notif['notificar_rejeitada']) ? 'checked' : '' ?>>
                            <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                            <span class="adm-toggle-label">Candidatura rejeitada</span>
                        </label>
                    </div>
                </div>

                <button class="adm-btn adm-btn-primary" type="submit">
                    <i class="fa-solid fa-save fa-fw" style="margin-right:6px"></i> Guardar Configuração
                </button>
            </form>
        </div>
    </div>
</div>

<!-- Modal: Campo Customizável -->
<div class="adm-modal-overlay" id="campoModal">
    <div class="adm-modal-content" style="max-width:560px">
        <div class="adm-modal-header">
            <h3 class="adm-modal-title" id="campoModalTitle">Novo Campo</h3>
            <button class="adm-modal-close" onclick="closeCampoModal()" type="button">&times;</button>
        </div>
        <form id="campoForm">
            <input type="hidden" name="csrf_token" value="<?= $csrf ?>">
            <input type="hidden" name="id" id="campoId" value="">
            <div class="adm-modal-body">
                <div class="adm-form-row">
                    <div class="adm-form-group">
                        <label class="adm-label" for="campoCodigo">Código <span style="color:var(--adm-red)">*</span></label>
                        <input class="adm-input" type="text" id="campoCodigo" name="codigo" required maxlength="50" placeholder="ex: formacao">
                    </div>
                    <div class="adm-form-group">
                        <label class="adm-label" for="campoLabel">Label <span style="color:var(--adm-red)">*</span></label>
                        <input class="adm-input" type="text" id="campoLabel" name="label" required maxlength="100" placeholder="ex: Formação Académica">
                    </div>
                </div>
                <div class="adm-form-row">
                    <div class="adm-form-group">
                        <label class="adm-label" for="campoTipo">Tipo <span style="color:var(--adm-red)">*</span></label>
                        <select class="adm-select" id="campoTipo" name="tipo" required onchange="toggleOpcoes()">
                            <?php foreach ($tipos as $k => $label): ?>
                            <option value="<?= $k ?>"><?= $label ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="adm-form-group">
                        <label class="adm-label" for="campoOrdem">Ordem</label>
                        <input class="adm-input" type="number" id="campoOrdem" name="ordem" min="0" value="0">
                    </div>
                </div>
                <div class="adm-form-group" id="grupoOpcoes" style="display:none">
                    <label class="adm-label" for="campoOpcoes">Opções</label>
                    <textarea class="adm-textarea" id="campoOpcoes" name="opcoes" rows="4" placeholder="Uma opção por linha"></textarea>
                    <p class="adm-input-hint">Uma opção por linha. Usado para select, multiselect e checkbox.</p>
                </div>
                <div style="display:flex;gap:var(--adm-sp-6);margin-top:var(--adm-sp-4)">
                    <label class="adm-toggle">
                        <input type="checkbox" name="obrigatorio" id="campoObrigatorio" value="1">
                        <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                        <span class="adm-toggle-label">Obrigatório</span>
                    </label>
                    <label class="adm-toggle">
                        <input type="checkbox" name="ativo" id="campoAtivo" value="1" checked>
                        <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                        <span class="adm-toggle-label">Ativo</span>
                    </label>
                </div>
            </div>
            <div class="adm-modal-footer">
                <button class="adm-btn adm-btn-outline" type="button" onclick="closeCampoModal()">Cancelar</button>
                <button class="adm-btn adm-btn-primary" type="submit">Guardar</button>
            </div>
        </form>
    </div>
</div>

<script>
const CSRF = '<?= $csrf ?>';

function switchTab(name, btn) {
    document.querySelectorAll('.adm-tab-panel').forEach(p => p.classList.remove('active'));
    document.querySelectorAll('.adm-tab').forEach(b => b.classList.remove('active'));
    document.getElementById('tab-' + name).classList.add('active');
    btn.classList.add('active');
}

function toggleOpcoes() {
    const tipo = document.getElementById('campoTipo').value;
    const show = ['select','multiselect','checkbox'].includes(tipo);
    document.getElementById('grupoOpcoes').style.display = show ? 'block' : 'none';
}

// Modal Campo
function openCampoModal(id) {
    const modal = document.getElementById('campoModal');
    const form = document.getElementById('campoForm');
    form.reset();
    document.getElementById('campoId').value = id || '';
    document.getElementById('campoModalTitle').textContent = id ? 'Editar Campo' : 'Novo Campo';

    if (id) {
        const row = document.querySelector('#camposTable tbody tr[data-id="' + id + '"]');
        if (row) {
            document.getElementById('campoCodigo').value = row.dataset.codigo;
            document.getElementById('campoLabel').value = row.dataset.label;
            document.getElementById('campoTipo').value = row.dataset.tipo;
            document.getElementById('campoOrdem').value = row.dataset.ordem;
            document.getElementById('campoOpcoes').value = row.dataset.opcoes.replace(/\\n/g, '\n');
            document.getElementById('campoObrigatorio').checked = row.dataset.obrigatorio === '1';
            document.getElementById('campoAtivo').checked = row.dataset.ativo === '1';
        }
    }
    toggleOpcoes();
    modal.classList.add('open');
}

function closeCampoModal() {
    document.getElementById('campoModal').classList.remove('open');
}

document.getElementById('campoModal').addEventListener('click', e => {
    if (e.target === e.currentTarget) closeCampoModal();
});

// Guardar campo
document.getElementById('campoForm').addEventListener('submit', async e => {
    e.preventDefault();
    const fd = new FormData(e.target);
    const payload = Object.fromEntries(fd.entries());
    payload.obrigatorio = fd.has('obrigatorio');
    payload.ativo = fd.has('ativo');

    try {
        const res = await fetch('/nexora/api/recrutamento_campo_custom_save', {
            method: 'POST',
            headers: {'Content-Type':'application/json'},
            body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            showToast('Campo guardado com sucesso');
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro ao guardar campo', 'error');
        }
    } catch (err) {
        showToast('Erro de rede ao guardar campo', 'error');
    }
});

// Ativar/desativar inline
async function toggleAtivo(id, ativo) {
    const row = document.querySelector('#camposTable tbody tr[data-id="' + id + '"]');
    if (!row) return;
    const payload = {
        id: id,
        codigo: row.dataset.codigo,
        label: row.dataset.label,
        tipo: row.dataset.tipo,
        opcoes: row.dataset.opcoes,
        obrigatorio: row.dataset.obrigatorio === '1',
        ordem: parseInt(row.dataset.ordem, 10),
        ativo: ativo,
        csrf_token: CSRF
    };
    try {
        const res = await fetch('/nexora/api/recrutamento_campo_custom_save', {
            method: 'POST',
            headers: {'Content-Type':'application/json'},
            body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            showToast(ativo ? 'Campo activado' : 'Campo desactivado');
            row.dataset.ativo = ativo ? '1' : '0';
        } else {
            showToast(data.erro || 'Erro ao actualizar campo', 'error');
            location.reload();
        }
    } catch (err) {
        showToast('Erro de rede', 'error');
        location.reload();
    }
}

// Eliminar campo
function eliminarCampo(id) {
    openConfirm('Eliminar campo?', 'Esta acção não pode ser desfeita.', async () => {
        try {
            const res = await fetch('/nexora/api/recrutamento_campo_custom_delete', {
                method: 'POST',
                headers: {'Content-Type':'application/json'},
                body: JSON.stringify({id: id, csrf_token: CSRF})
            });
            const data = await res.json();
            if (data.ok) {
                showToast('Campo eliminado');
                setTimeout(() => location.reload(), 700);
            } else {
                showToast(data.erro || 'Erro ao eliminar campo', 'error');
            }
        } catch (err) {
            showToast('Erro de rede', 'error');
        }
    });
}

// Guardar notificações
document.getElementById('notifForm').addEventListener('submit', async e => {
    e.preventDefault();
    const fd = new FormData(e.target);
    const payload = Object.fromEntries(fd.entries());
    ['canal_email','canal_sms','notificar_candidatura_recebida','notificar_em_analise','notificar_entrevista_agendada','notificar_aprovada','notificar_rejeitada']
        .forEach(k => payload[k] = fd.has(k));

    try {
        const res = await fetch('/nexora/api/recrutamento_notificacoes_save', {
            method: 'POST',
            headers: {'Content-Type':'application/json'},
            body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            showToast('Configuração de notificações guardada');
        } else {
            showToast(data.erro || 'Erro ao guardar notificações', 'error');
        }
    } catch (err) {
        showToast('Erro de rede', 'error');
    }
});
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
