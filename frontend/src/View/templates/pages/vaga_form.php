<?php

    $id     = $app->request->queryInt('id', 0);
    $isEdit = $id > 0;
    $vaga   = null;

    if ($isEdit) {
    $resp = $app->nexora->call('GET', "/api/recrutamento/vagas/$id");
    if ($resp['status'] !== 200) {
        header('Location: /nexora/recrutamento/vagas');
        exit;
    }
    $vaga = $resp['body'];
    }

    $csrf       = $app->security->csrfToken();
    $pageTitle  = $isEdit ? 'Editar Vaga' : 'Nova Vaga';
    $activePage = $isEdit ? 'vagas' : 'vaga_nova';
    $breadcrumb = [['Admin', '/nexora/'], ['Vagas', '/nexora/recrutamento/vagas'], [$pageTitle, '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title"><?php echo $isEdit ? 'Editar Vaga' : 'Nova Vaga' ?></h1>
    <?php if ($isEdit): ?>
    <div class="adm-page-header-actions">
        <a href="/vagas" target="_blank" class="adm-btn adm-btn-outline adm-btn-sm">Ver no site</a>
    </div>
    <?php endif; ?>
</div>

<div id="formMsg"></div>

<form id="vagaForm">
    <input type="hidden" name="csrf_token" value="<?php echo $csrf ?>">
    <?php if ($isEdit): ?><input type="hidden" name="id" value="<?php echo $id ?>"><?php endif; ?>

    <!-- Bloco: Identificação -->
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Identificação</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-titulo">Título da Vaga <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="f-titulo" name="titulo" required maxlength="200"
                           placeholder="ex: Desenvolvedor Full-Stack"
                           value="<?php echo $app->view->field($vaga, 'titulo') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-area">Área <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="f-area" name="area" required maxlength="100"
                           placeholder="ex: Tecnologia Web"
                           value="<?php echo $app->view->field($vaga, 'area') ?>">
                    <p class="adm-input-hint">Usado como identificador do separador na página pública.</p>
                </div>
            </div>

            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-tipo">Tipo</label>
                    <select class="adm-select" id="f-tipo" name="tipo">
                        <?php foreach (['Estágio', 'Full-time', 'Part-time', 'Freelance', 'Consultoria'] as $t): ?>
                        <option value="<?php echo $t ?>" <?php echo $app->view->field($vaga,'tipo') === $t ? 'selected' : '' ?>><?php echo $t ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-regime">Regime</label>
                    <select class="adm-select" id="f-regime" name="regime">
                        <?php foreach (['Presencial', 'Remoto', 'Híbrido'] as $r): ?>
                        <option value="<?php echo $r ?>" <?php echo $app->view->field($vaga,'regime') === $r ? 'selected' : '' ?>><?php echo $r ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-local">Localização</label>
                    <input class="adm-input" type="text" id="f-local" name="local" maxlength="100"
                           placeholder="ex: Maputo, Moçambique"
                           value="<?php echo $app->view->field($vaga, 'local') ?>">
                </div>
            </div>

            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-num_vagas">Nº de Posições</label>
                    <input class="adm-input" type="number" id="f-num_vagas" name="num_vagas" min="1" max="99"
                           value="<?php echo $app->view->field($vaga, 'num_vagas', '1') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-prazo">Prazo de Candidatura</label>
                    <input class="adm-input" type="date" id="f-prazo" name="prazo"
                           value="<?php echo $app->view->field($vaga, 'prazo') ?>">
                    <p class="adm-input-hint">Deixar em branco para sem prazo definido.</p>
                </div>
            </div>

            <div class="adm-form-group">
                <label class="adm-toggle">
                    <input type="checkbox" name="ativa" value="1" <?php echo ($vaga['ativa'] ?? 1) ? 'checked' : '' ?>>
                    <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                    <span class="adm-toggle-label">Vaga ativa (visível no site)</span>
                </label>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" style="margin-bottom:var(--adm-sp-3)">Tipos de Candidatura Permitidos</label>
                <div style="display:flex;flex-direction:column;gap:var(--adm-sp-2)">
                    <label class="adm-toggle">
                        <input type="checkbox" name="permite_publica" value="1" <?php echo ($vaga['permite_publica'] ?? 1) ? 'checked' : '' ?>>
                        <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                        <span class="adm-toggle-label">Candidatura pública (sem conta)</span>
                    </label>
                    <label class="adm-toggle">
                        <input type="checkbox" name="permite_conta" value="1" <?php echo ($vaga['permite_conta'] ?? 1) ? 'checked' : '' ?>>
                        <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                        <span class="adm-toggle-label">Candidatura via conta de candidato</span>
                    </label>
                </div>
            </div>
        </div>
    </div>

    <!-- Bloco: Descrições -->
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Descrição</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-group">
                <label class="adm-label" for="f-descricao">Sobre a empresa</label>
                <textarea class="adm-textarea" id="f-descricao" name="descricao" maxlength="1000" rows="3"
                          placeholder="Breve descrição da e258tech..."><?php echo $app->view->field($vaga, 'descricao') ?></textarea>
            </div>
            <div class="adm-form-group" style="margin-bottom:0">
                <label class="adm-label" for="f-sobre_funcao">Sobre a Função</label>
                <textarea class="adm-textarea" id="f-sobre_funcao" name="sobre_funcao" maxlength="1500" rows="4"
                          placeholder="Descreve o papel e o que o candidato irá fazer..."><?php echo $app->view->field($vaga, 'sobre_funcao') ?></textarea>
            </div>
        </div>
    </div>

    <!-- Bloco: Responsabilidades -->
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Responsabilidades</h2></div>
        <div class="adm-card-body">
            <div class="adm-list-field" id="resp-list">
                <?php foreach ($vaga['responsabilidades'] ?? [''] as $r): ?>
                <?php if ($r !== '' || count($vaga['responsabilidades'] ?? []) === 0): ?>
                <div class="adm-list-item">
                    <input class="adm-input" type="text" name="responsabilidades[]" maxlength="300"
                           placeholder="ex: Desenvolver funcionalidades..."
                           value="<?php echo htmlspecialchars($r) ?>">
                    <button type="button" class="adm-list-remove" onclick="removeItem(this)" title="Remover">
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                    </button>
                </div>
                <?php endif; ?>
                <?php endforeach; ?>
                <?php if (empty($vaga['responsabilidades'])): ?>
                <div class="adm-list-item">
                    <input class="adm-input" type="text" name="responsabilidades[]" maxlength="300" placeholder="ex: Desenvolver funcionalidades...">
                    <button type="button" class="adm-list-remove" onclick="removeItem(this)"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button>
                </div>
                <?php endif; ?>
            </div>
            <button type="button" class="adm-list-add" onclick="addItem('resp-list','responsabilidades[]')">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                Adicionar responsabilidade
            </button>
        </div>
    </div>

    <!-- Bloco: Requisitos -->
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Requisitos</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row" style="align-items:start">
                <div>
                    <label class="adm-label" style="margin-bottom:var(--adm-sp-3)">Obrigatórios</label>
                    <div class="adm-list-field" id="req-obrig-list">
                        <?php foreach ($vaga['req_obrigatorios'] ?? [''] as $r): ?>
                        <div class="adm-list-item">
                            <input class="adm-input" type="text" name="req_obrigatorios[]" maxlength="300"
                                   placeholder="ex: PHP, MySQL"
                                   value="<?php echo htmlspecialchars($r) ?>">
                            <button type="button" class="adm-list-remove" onclick="removeItem(this)"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button>
                        </div>
                        <?php endforeach; ?>
                        <?php if (empty($vaga['req_obrigatorios'])): ?>
                        <div class="adm-list-item">
                            <input class="adm-input" type="text" name="req_obrigatorios[]" maxlength="300" placeholder="ex: PHP, MySQL">
                            <button type="button" class="adm-list-remove" onclick="removeItem(this)"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button>
                        </div>
                        <?php endif; ?>
                    </div>
                    <button type="button" class="adm-list-add" onclick="addItem('req-obrig-list','req_obrigatorios[]')">
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                        Adicionar
                    </button>
                </div>
                <div>
                    <label class="adm-label" style="margin-bottom:var(--adm-sp-3)">Preferenciais</label>
                    <div class="adm-list-field" id="req-pref-list">
                        <?php foreach ($vaga['req_preferenciais'] ?? [''] as $r): ?>
                        <div class="adm-list-item">
                            <input class="adm-input" type="text" name="req_preferenciais[]" maxlength="300"
                                   placeholder="ex: Experiência com Docker"
                                   value="<?php echo htmlspecialchars($r) ?>">
                            <button type="button" class="adm-list-remove" onclick="removeItem(this)"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button>
                        </div>
                        <?php endforeach; ?>
                        <?php if (empty($vaga['req_preferenciais'])): ?>
                        <div class="adm-list-item">
                            <input class="adm-input" type="text" name="req_preferenciais[]" maxlength="300" placeholder="ex: Experiência com Docker">
                            <button type="button" class="adm-list-remove" onclick="removeItem(this)"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button>
                        </div>
                        <?php endif; ?>
                    </div>
                    <button type="button" class="adm-list-add" onclick="addItem('req-pref-list','req_preferenciais[]')">
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                        Adicionar
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Bloco: O que oferecemos -->
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">O que Oferecemos</h2></div>
        <div class="adm-card-body">
            <div class="adm-list-field" id="oferece-list">
                <?php foreach ($vaga['oferece'] ?? [''] as $o): ?>
                <div class="adm-list-item">
                    <input class="adm-input" type="text" name="oferece[]" maxlength="200"
                           placeholder="ex: Subsídio de alimentação"
                           value="<?php echo htmlspecialchars($o) ?>">
                    <button type="button" class="adm-list-remove" onclick="removeItem(this)"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button>
                </div>
                <?php endforeach; ?>
                <?php if (empty($vaga['oferece'])): ?>
                <div class="adm-list-item">
                    <input class="adm-input" type="text" name="oferece[]" maxlength="200" placeholder="ex: Subsídio de alimentação">
                    <button type="button" class="adm-list-remove" onclick="removeItem(this)"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button>
                </div>
                <?php endif; ?>
            </div>
            <button type="button" class="adm-list-add" onclick="addItem('oferece-list','oferece[]')">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                Adicionar benefício
            </button>
        </div>
    </div>

    <?php if ($isEdit): ?>
    <!-- Bloco: Form Builder (campos do formulário por vaga) -->
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header" style="display:flex;align-items:center;justify-content:space-between">
            <h2 class="adm-card-title">Campos do Formulário de Candidatura</h2>
            <button type="button" class="adm-btn adm-btn-primary adm-btn-sm" onclick="openAddCampo()">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                Adicionar campo
            </button>
        </div>
        <div class="adm-card-body">
            <p class="adm-text-muted adm-text-sm" style="margin-bottom:var(--adm-sp-4)">Campos adicionais específicos desta vaga. Aparecem no formulário público abaixo dos campos padrão.</p>
            <div id="campos-vaga-list">
                <p class="adm-text-muted adm-text-sm" id="campos-vaga-empty">A carregar...</p>
            </div>
        </div>
    </div>

    <!-- Modal: Adicionar/Editar Campo -->
    <div id="modal-campo" style="display:none;position:fixed;inset:0;background:rgba(0,0,0,.45);z-index:9999;align-items:center;justify-content:center">
        <div style="background:#fff;border-radius:1rem;padding:2rem;width:100%;max-width:480px;box-shadow:0 20px 60px rgba(0,0,0,.2)">
            <h3 style="margin:0 0 1.5rem;font-family:'Outfit',sans-serif;font-size:1.1rem" id="modal-campo-title">Adicionar Campo</h3>
            <div class="adm-form-group">
                <label class="adm-label">Código <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="text" id="mc-codigo" placeholder="ex: carta_motivacao" maxlength="50">
                <p class="adm-input-hint">Identificador único, sem espaços. Usado internamente.</p>
            </div>
            <div class="adm-form-group">
                <label class="adm-label">Label <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="text" id="mc-label" placeholder="ex: Carta de Motivação" maxlength="150">
            </div>
            <div class="adm-form-group">
                <label class="adm-label">Tipo</label>
                <select class="adm-select" id="mc-tipo" onchange="toggleOpcoes()">
                    <option value="texto">Texto curto</option>
                    <option value="textarea">Texto longo</option>
                    <option value="numero">Número</option>
                    <option value="data">Data</option>
                    <option value="select">Dropdown (select)</option>
                    <option value="multiselect">Multi-seleção</option>
                    <option value="checkbox">Checkbox</option>
                    <option value="ficheiro">Ficheiro</option>
                </select>
            </div>
            <div class="adm-form-group" id="mc-opcoes-group" style="display:none">
                <label class="adm-label">Opções (uma por linha)</label>
                <textarea class="adm-textarea" id="mc-opcoes" rows="4" placeholder="Opção 1&#10;Opção 2&#10;Opção 3"></textarea>
            </div>
            <div class="adm-form-group" style="margin-bottom:1.5rem">
                <label class="adm-toggle">
                    <input type="checkbox" id="mc-obrigatorio">
                    <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                    <span class="adm-toggle-label">Campo obrigatório</span>
                </label>
            </div>
            <div style="display:flex;gap:.75rem;justify-content:flex-end">
                <button type="button" class="adm-btn adm-btn-outline" onclick="closeCampoModal()">Cancelar</button>
                <button type="button" class="adm-btn adm-btn-primary" id="mc-save-btn" onclick="saveCampo()">Guardar</button>
            </div>
        </div>
    </div>
    <?php endif; ?>

    <!-- Actions -->
    <div style="display:flex;gap:var(--adm-sp-3);justify-content:flex-end;padding-bottom:var(--adm-sp-8)">
        <a href="/nexora/recrutamento/vagas" class="adm-btn adm-btn-outline">Cancelar</a>
        <button type="submit" class="adm-btn adm-btn-primary" id="btnSave">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/>
                <polyline points="17 21 17 13 7 13 7 21"/>
                <polyline points="7 3 7 8 15 8"/>
            </svg>
            <?php echo $isEdit ? 'Guardar alterações' : 'Criar Vaga' ?>
        </button>
    </div>
</form>

<script>
function addItem(listId, fieldName) {
    const list = document.getElementById(listId);
    const div  = document.createElement('div');
    div.className = 'adm-list-item';
    div.innerHTML = `
        <input class="adm-input" type="text" name="${fieldName}" maxlength="300" placeholder="…">
        <button type="button" class="adm-list-remove" onclick="removeItem(this)">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
        </button>`;
    list.appendChild(div);
    div.querySelector('input').focus();
}

function removeItem(btn) {
    const list = btn.closest('.adm-list-field');
    if (list.children.length > 1) {
        btn.closest('.adm-list-item').remove();
    } else {
        btn.closest('.adm-list-item').querySelector('input').value = '';
    }
}

document.getElementById('vagaForm').addEventListener('submit', async function(e) {
    e.preventDefault();
    const btn = document.getElementById('btnSave');
    btn.disabled = true;
    btn.innerHTML = '<svg class="spin" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg> A guardar…';

    const msgEl = document.getElementById('formMsg');
    msgEl.innerHTML = '';

    const fd = new FormData(this);

    try {
        const res  = await fetch('/nexora/api/vaga_save', { method:'POST', body: fd });
        const data = await res.json();

        if (data.ok) {
            window.location.href = '/nexora/recrutamento/vagas?msg=' + encodeURIComponent(data.msg || 'Vaga guardada com sucesso.');
        } else {
            msgEl.innerHTML = `<div class="adm-alert adm-alert--error">${data.erro || 'Erro ao guardar.'}</div>`;
            btn.disabled = false;
            btn.innerHTML = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg> <?php echo $isEdit ? 'Guardar alterações' : 'Criar Vaga' ?>`;
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

<?php if ($isEdit): ?>
// ── Form Builder ──────────────────────────────────────────────
const VAGA_ID = <?php echo $id ?>;
const FB_CSRF = '<?php echo $csrf ?>';
let editingCampoId = null;

const TIPO_LABELS = {
    texto:'Texto curto', textarea:'Texto longo', numero:'Número',
    data:'Data', select:'Dropdown', multiselect:'Multi-seleção',
    checkbox:'Checkbox', ficheiro:'Ficheiro'
};

async function carregarCamposVaga() {
    const res  = await fetch(`/nexora/api/recrutamento/vagas/${VAGA_ID}/campos`);
    const data = await res.json();
    const list = document.getElementById('campos-vaga-list');
    const empty = document.getElementById('campos-vaga-empty');
    if (!data.length) {
        list.innerHTML = '<p class="adm-text-muted adm-text-sm" id="campos-vaga-empty">Nenhum campo configurado. Adiciona o primeiro acima.</p>';
        return;
    }
    list.innerHTML = data.map(c => `
        <div class="adm-list-item" style="align-items:center;padding:.6rem .75rem;border:1px solid var(--adm-gray-200);border-radius:.5rem;margin-bottom:.5rem;background:#fff">
            <div style="flex:1;min-width:0">
                <span style="font-weight:600;font-size:.875rem">${escHtml(c.label)}</span>
                <span class="adm-text-muted adm-text-xs" style="margin-left:.5rem">${TIPO_LABELS[c.tipo] || c.tipo}</span>
                ${c.obrigatorio ? '<span style="margin-left:.5rem;font-size:.7rem;font-weight:700;color:var(--adm-red)">OBRIG.</span>' : ''}
            </div>
            <div style="display:flex;gap:.5rem">
                <button type="button" class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Editar" onclick="openEditCampo(${JSON.stringify(c).replace(/"/g,'&quot;')})">
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                </button>
                <button type="button" class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Eliminar" style="color:var(--adm-red)" onclick="deleteCampo(${c.id}, '${escHtml(c.label)}')">
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/></svg>
                </button>
            </div>
        </div>`).join('');
}

function escHtml(s) { return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }

function openAddCampo() {
    editingCampoId = null;
    document.getElementById('modal-campo-title').textContent = 'Adicionar Campo';
    document.getElementById('mc-codigo').value = '';
    document.getElementById('mc-label').value = '';
    document.getElementById('mc-tipo').value = 'texto';
    document.getElementById('mc-opcoes').value = '';
    document.getElementById('mc-obrigatorio').checked = false;
    toggleOpcoes();
    document.getElementById('mc-codigo').removeAttribute('disabled');
    document.getElementById('modal-campo').style.display = 'flex';
}

function openEditCampo(c) {
    editingCampoId = c.id;
    document.getElementById('modal-campo-title').textContent = 'Editar Campo';
    document.getElementById('mc-codigo').value = c.codigo;
    document.getElementById('mc-label').value = c.label;
    document.getElementById('mc-tipo').value = c.tipo;
    document.getElementById('mc-opcoes').value = (c.opcoes || []).join('\n');
    document.getElementById('mc-obrigatorio').checked = c.obrigatorio;
    document.getElementById('mc-codigo').setAttribute('disabled', 'disabled');
    toggleOpcoes();
    document.getElementById('modal-campo').style.display = 'flex';
}

function closeCampoModal() {
    document.getElementById('modal-campo').style.display = 'none';
}

function toggleOpcoes() {
    const tipo = document.getElementById('mc-tipo').value;
    document.getElementById('mc-opcoes-group').style.display =
        ['select','multiselect'].includes(tipo) ? '' : 'none';
}

async function saveCampo() {
    const codigo = document.getElementById('mc-codigo').value.trim().replace(/\s+/g,'_');
    const label  = document.getElementById('mc-label').value.trim();
    const tipo   = document.getElementById('mc-tipo').value;
    const opcoes = document.getElementById('mc-opcoes').value.split('\n').map(s=>s.trim()).filter(Boolean);
    const obrigatorio = document.getElementById('mc-obrigatorio').checked;

    if (!label) { showToast('Label é obrigatório.','error'); return; }
    if (!editingCampoId && !codigo) { showToast('Código é obrigatório.','error'); return; }

    const btn = document.getElementById('mc-save-btn');
    btn.disabled = true;

    const url    = editingCampoId
        ? `/nexora/api/recrutamento/vagas/${VAGA_ID}/campos/${editingCampoId}`
        : `/nexora/api/recrutamento/vagas/${VAGA_ID}/campos`;
    const method = editingCampoId ? 'PUT' : 'POST';

    const body = editingCampoId
        ? { label, tipo, opcoes, obrigatorio }
        : { codigo, label, tipo, opcoes, obrigatorio };

    try {
        const res  = await fetch(url, { method, headers:{'Content-Type':'application/json'}, body: JSON.stringify(body) });
        if (res.ok || res.status === 201 || res.status === 204) {
            closeCampoModal();
            carregarCamposVaga();
            showToast(editingCampoId ? 'Campo actualizado.' : 'Campo criado.');
        } else {
            const d = await res.json();
            showToast(d.error || 'Erro ao guardar.','error');
        }
    } catch { showToast('Erro de ligação.','error'); }
    btn.disabled = false;
}

async function deleteCampo(id, label) {
    openConfirm('Eliminar campo', `Eliminar o campo "${label}"? Os dados já submetidos não serão afectados.`, async () => {
        const res = await fetch(`/nexora/api/recrutamento/vagas/${VAGA_ID}/campos/${id}`, { method:'DELETE' });
        if (res.ok) { carregarCamposVaga(); showToast('Campo eliminado.'); }
        else showToast('Erro ao eliminar.','error');
    });
}

// Fechar modal ao clicar fora
document.getElementById('modal-campo').addEventListener('click', function(e) {
    if (e.target === this) closeCampoModal();
});

// Carregar campos ao abrir a página (só edit)
carregarCamposVaga();
<?php endif; ?>
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
