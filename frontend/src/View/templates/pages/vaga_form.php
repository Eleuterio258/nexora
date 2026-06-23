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

            <div class="adm-form-group" style="margin-bottom:0">
                <label class="adm-toggle">
                    <input type="checkbox" name="ativa" value="1" <?php echo ($vaga['ativa'] ?? 1) ? 'checked' : '' ?>>
                    <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                    <span class="adm-toggle-label">Vaga ativa (visível no site)</span>
                </label>
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
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
