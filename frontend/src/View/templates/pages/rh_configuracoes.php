<?php

    $rhConfigResp  = $app->nexora->call('GET', '/api/rh/configuracoes');
    $rhConfig      = is_array($rhConfigResp['body'] ?? null) ? $rhConfigResp['body'] : [];

    $prefixo  = $rhConfig['rh.prefixo_funcionario']              ?? 'FUNC';
    $sep      = $rhConfig['rh.separador_funcionario']             ?? '-';
    $digitos  = (int) ($rhConfig['rh.digitos_funcionario']        ?? 3);
    $inicio   = (int) ($rhConfig['rh.numero_inicial_funcionario'] ?? 1);

    // Escalões IRPS
    $anoAtual   = (int) date('Y');
    $anoFiltro  = $app->request->queryInt('ano_irps', $anoAtual);
    $irpsResp   = $app->nexora->call('GET', '/api/rh/irps-escaloes', null, ['ano' => $anoFiltro]);
    $escaloes   = is_array($irpsResp['body'] ?? null) && array_is_list($irpsResp['body']) ? $irpsResp['body'] : [];

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Configurações de RH';
    $activePage = 'rh_configuracoes';
    $breadcrumb = [['Admin', '/nexora/'], ['Recursos Humanos', ''], ['Configurações', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Configurações de RH</h1>
</div>

<!-- ── Numeração de Funcionários ─────────────────────────────── -->
<div class="adm-card adm-mb-6">
    <div class="adm-card-header">
        <h2 class="adm-card-title">Numeração de Funcionários</h2>
        <p class="adm-card-subtitle">Formato gerado automaticamente ao criar um novo funcionário.</p>
    </div>
    <div class="adm-card-body">
        <div style="max-width:560px">

            <div class="adm-form-row-3 adm-mb-4">
                <div class="adm-form-group">
                    <label class="adm-label" for="cfg-prefixo">Prefixo</label>
                    <input class="adm-input" type="text" id="cfg-prefixo" maxlength="20"
                           value="<?php echo htmlspecialchars($prefixo) ?>" placeholder="ex: FUNC">
                    <span class="adm-text-muted" style="font-size:var(--adm-text-xs)">ex: FUNC, EMP, COL</span>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="cfg-sep">Separador</label>
                    <select class="adm-select" id="cfg-sep">
                        <option value="-"  <?php echo $sep === '-'  ? 'selected' : '' ?>>Hífen ( - )</option>
                        <option value="/"  <?php echo $sep === '/'  ? 'selected' : '' ?>>Barra ( / )</option>
                        <option value="."  <?php echo $sep === '.'  ? 'selected' : '' ?>>Ponto ( . )</option>
                        <option value=""   <?php echo $sep === ''   ? 'selected' : '' ?>>Nenhum</option>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="cfg-digitos">Dígitos</label>
                    <select class="adm-select" id="cfg-digitos">
                        <option value="3" <?php echo $digitos === 3 ? 'selected' : '' ?>>3 → 001</option>
                        <option value="4" <?php echo $digitos === 4 ? 'selected' : '' ?>>4 → 0001</option>
                        <option value="5" <?php echo $digitos === 5 ? 'selected' : '' ?>>5 → 00001</option>
                        <option value="6" <?php echo $digitos === 6 ? 'selected' : '' ?>>6 → 000001</option>
                    </select>
                </div>
            </div>

            <div class="adm-form-row adm-mb-5" style="max-width:200px">
                <div class="adm-form-group">
                    <label class="adm-label" for="cfg-inicio">Número inicial</label>
                    <input class="adm-input" type="number" id="cfg-inicio" min="1" max="99999"
                           value="<?php echo $inicio ?>">
                    <span class="adm-text-muted" style="font-size:var(--adm-text-xs)">Sequência começa neste número</span>
                </div>
            </div>

            <!-- Pré-visualização -->
            <div class="adm-form-group adm-mb-5">
                <label class="adm-label">Pré-visualização</label>
                <div style="display:flex;align-items:center;gap:var(--adm-sp-3);flex-wrap:wrap">
                    <code class="adm-badge adm-badge--blue" id="cfg-prev1" style="font-size:.9rem;padding:var(--adm-sp-2) var(--adm-sp-4);font-family:monospace"></code>
                    <span class="adm-text-muted">→</span>
                    <code class="adm-badge adm-badge--blue" id="cfg-prev2" style="font-size:.9rem;padding:var(--adm-sp-2) var(--adm-sp-4);opacity:.65;font-family:monospace"></code>
                    <span class="adm-text-muted">→</span>
                    <code class="adm-badge adm-badge--blue" id="cfg-prev3" style="font-size:.9rem;padding:var(--adm-sp-2) var(--adm-sp-4);opacity:.4;font-family:monospace"></code>
                </div>
                <p class="adm-text-muted" style="font-size:var(--adm-text-xs);margin-top:var(--adm-sp-2)">
                    Alterar estas configurações não afecta funcionários já registados.
                </p>
            </div>

            <button class="adm-btn adm-btn-primary" type="button" onclick="saveConfig()">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:6px"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg>
                Guardar Configurações
            </button>
        </div>
    </div>
</div>

<!-- ── Escalões IRPS ──────────────────────────────────────────── -->
<div class="adm-card adm-mb-6">
    <div class="adm-card-header">
        <div>
            <h2 class="adm-card-title">Escalões IRPS</h2>
            <p class="adm-card-subtitle">Tabela de imposto sobre rendimento de pessoas singulares (trabalhadores assalariados).</p>
        </div>
        <div style="display:flex;gap:var(--adm-sp-2);align-items:center">
            <form method="get" style="display:flex;gap:var(--adm-sp-2);align-items:center">
                <select class="adm-select" name="ano_irps" style="width:100px" onchange="this.form.submit()">
                    <?php for ($y = $anoAtual + 1; $y >= 2024; $y--): ?>
                    <option value="<?php echo $y ?>" <?php echo $y === $anoFiltro ? 'selected' : '' ?>><?php echo $y ?></option>
                    <?php endfor; ?>
                </select>
            </form>
            <?php if (!$escaloes): ?>
            <button class="adm-btn adm-btn-outline adm-btn-sm" type="button" onclick="seedMozambique2024()">
                Carregar Moçambique <?php echo $anoFiltro ?>
            </button>
            <?php endif; ?>
            <button class="adm-btn adm-btn-primary adm-btn-sm" type="button" onclick="openNovoEscalao()">+ Escalão</button>
        </div>
    </div>
    <?php if ($escaloes): ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr><th>Limite Inf. (MT)</th><th>Limite Sup. (MT)</th><th>Taxa (%)</th><th>Parcela a Abater (MT)</th><th>Activo</th><th></th></tr>
            </thead>
            <tbody>
            <?php foreach ($escaloes as $e): ?>
            <tr>
                <td><?php echo number_format((float)$e['limite_inf'],2,',','.') ?></td>
                <td><?php echo $e['limite_sup'] !== null ? number_format((float)$e['limite_sup'],2,',','.') : '∞' ?></td>
                <td class="adm-fw-600"><?php echo number_format((float)$e['taxa']*100,1) ?>%</td>
                <td><?php echo number_format((float)$e['parcela_ded'],2,',','.') ?></td>
                <td>
                    <span class="adm-badge <?php echo $e['ativo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>">
                        <?php echo $e['ativo'] ? 'Activo' : 'Inactivo' ?>
                    </span>
                </td>
                <td>
                    <div style="display:flex;gap:var(--adm-sp-2)">
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button"
                            onclick='editarEscalao(<?php echo (int)$e["id"] ?>,<?php echo (float)$e["taxa"]*100 ?>,<?php echo (float)$e["parcela_ded"] ?>,<?php echo $e["limite_sup"] !== null ? (float)$e["limite_sup"] : "null" ?>,<?php echo $e["ativo"] ? "true" : "false" ?>)'>Editar</button>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-red)"
                            onclick="eliminarEscalao(<?php echo (int)$e['id'] ?>)">Eliminar</button>
                    </div>
                </td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="adm-empty">
        <p class="adm-empty-title">Sem escalões configurados para <?php echo $anoFiltro ?></p>
        <p class="adm-empty-sub">Clique em "Carregar Moçambique <?php echo $anoFiltro ?>" para importar os valores padrão ou adicione manualmente.</p>
    </div>
    <?php endif; ?>
</div>

<!-- Modal Escalão IRPS -->
<div class="adm-modal" id="escalaoModal" style="display:none">
    <div class="adm-modal-content" style="max-width:480px">
        <div class="adm-modal-header">
            <h3 id="escalaoModalTitle">Novo Escalão IRPS</h3>
            <button class="adm-btn adm-btn-ghost adm-btn-icon" type="button" onclick="closeEscalaoModal()">&times;</button>
        </div>
        <div style="padding:var(--adm-sp-5) var(--adm-sp-6);max-height:65vh;overflow-y:auto">
            <input type="hidden" id="esc-id">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label">Ano Fiscal *</label>
                    <input class="adm-input" type="number" id="esc-ano" min="2024" max="2035" value="<?php echo $anoFiltro ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label">Limite Inferior (MT) *</label>
                    <input class="adm-input" type="number" id="esc-inf" step="0.01" min="0" placeholder="ex: 10000.01">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label">Limite Superior (MT)</label>
                    <input class="adm-input" type="number" id="esc-sup" step="0.01" min="0" placeholder="Vazio = sem limite">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label">Taxa (%)</label>
                    <input class="adm-input" type="number" id="esc-taxa" step="0.1" min="0" max="100" placeholder="ex: 10">
                </div>
            </div>
            <div class="adm-form-group">
                <label class="adm-label">Parcela a Abater (MT)</label>
                <input class="adm-input" type="number" id="esc-parc" step="0.01" min="0" value="0">
            </div>
        </div>
        <div class="adm-modal-footer">
            <button class="adm-btn adm-btn-ghost" type="button" onclick="closeEscalaoModal()">Cancelar</button>
            <button class="adm-btn adm-btn-primary" type="button" onclick="saveEscalao()">Guardar</button>
        </div>
    </div>
</div>

<script>
const CSRF = '<?php echo $csrf ?>';

function formatNum(n, digitos) {
    return String(n).padStart(digitos, '0');
}

function updatePreview() {
    const p = document.getElementById('cfg-prefixo').value.trim() || 'FUNC';
    const s = document.getElementById('cfg-sep').value;
    const d = parseInt(document.getElementById('cfg-digitos').value) || 3;
    const i = parseInt(document.getElementById('cfg-inicio').value) || 1;
    document.getElementById('cfg-prev1').textContent = p + s + formatNum(i,     d);
    document.getElementById('cfg-prev2').textContent = p + s + formatNum(i + 1, d);
    document.getElementById('cfg-prev3').textContent = p + s + formatNum(i + 2, d);
}

['cfg-prefixo','cfg-sep','cfg-digitos','cfg-inicio'].forEach(id =>
    document.getElementById(id).addEventListener('input', updatePreview)
);
updatePreview();

async function saveSetting(chave, valor) {
    const res = await fetch('/nexora/api/rh_config_save', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ chave, valor, csrf: CSRF })
    });
    return res.json();
}

async function saveConfig() {
    const prefixo = document.getElementById('cfg-prefixo').value.trim();
    if (!prefixo) { showToast('O prefixo é obrigatório.', 'error'); return; }
    try {
        await Promise.all([
            saveSetting('rh.prefixo_funcionario',          prefixo),
            saveSetting('rh.separador_funcionario',        document.getElementById('cfg-sep').value),
            saveSetting('rh.digitos_funcionario',          document.getElementById('cfg-digitos').value),
            saveSetting('rh.numero_inicial_funcionario',   document.getElementById('cfg-inicio').value),
        ]);
        showToast('Configurações guardadas com sucesso.');
    } catch { showToast('Erro ao guardar.', 'error'); }
}

// ── Escalões IRPS ─────────────────────────────────────────────────────────
const _escalaoModal = document.getElementById('escalaoModal');
function openNovoEscalao() {
    document.getElementById('esc-id').value = '';
    document.getElementById('esc-ano').disabled = false;
    document.getElementById('esc-inf').disabled = false;
    ['esc-inf','esc-sup','esc-taxa','esc-parc'].forEach(id => document.getElementById(id).value = '');
    document.getElementById('esc-parc').value = '0';
    document.getElementById('escalaoModalTitle').textContent = 'Novo Escalão IRPS';
    _escalaoModal.style.display = 'flex';
}
function editarEscalao(id, taxa, parc, sup, ativo) {
    document.getElementById('esc-id').value = id;
    document.getElementById('esc-ano').disabled = true;
    document.getElementById('esc-inf').disabled = true;
    document.getElementById('esc-sup').value  = sup !== null ? sup : '';
    document.getElementById('esc-taxa').value  = taxa;
    document.getElementById('esc-parc').value  = parc;
    document.getElementById('escalaoModalTitle').textContent = 'Editar Escalão IRPS';
    _escalaoModal.style.display = 'flex';
}
function closeEscalaoModal() { _escalaoModal.style.display = 'none'; }
_escalaoModal.addEventListener('click', e => { if (e.target === _escalaoModal) closeEscalaoModal(); });

async function postRH(url, payload) {
    const res = await fetch(url, {
        method: 'POST', headers: {'Content-Type':'application/json'},
        body: JSON.stringify({ ...payload, csrf: CSRF })
    });
    const data = await res.json();
    if (!res.ok || (!data.ok && data.erro)) throw new Error(data.erro || 'Erro');
    return data;
}

async function saveEscalao() {
    const id   = document.getElementById('esc-id').value;
    const taxa = parseFloat(document.getElementById('esc-taxa').value) / 100;
    const parc = parseFloat(document.getElementById('esc-parc').value) || 0;
    const sup  = document.getElementById('esc-sup').value ? parseFloat(document.getElementById('esc-sup').value) : null;
    try {
        if (id) {
            await postRH('/nexora/api/rh_irps_escalao_update', { id: Number(id), taxa, parcela_ded: parc, limite_sup: sup });
        } else {
            const ano = parseInt(document.getElementById('esc-ano').value);
            const inf = parseFloat(document.getElementById('esc-inf').value) || 0;
            await postRH('/nexora/api/rh_irps_escalao_save', { ano_fiscal: ano, limite_inf: inf, limite_sup: sup, taxa, parcela_ded: parc });
        }
        showToast('Escalão guardado com sucesso.');
        closeEscalaoModal();
        setTimeout(() => location.reload(), 500);
    } catch (e) { showToast(e.message || 'Erro', 'error'); }
}

async function eliminarEscalao(id) {
    if (!confirm('Eliminar este escalão IRPS?')) return;
    try {
        await postRH('/nexora/api/rh_irps_escalao_delete', { id });
        showToast('Escalão eliminado.');
        setTimeout(() => location.reload(), 500);
    } catch (e) { showToast(e.message || 'Erro ao eliminar', 'error'); }
}

async function seedMozambique2024() {
    try {
        const data = await postRH('/nexora/api/rh_irps_seed_mozambique', {});
        showToast(data.msg || 'Escalões carregados.');
        setTimeout(() => location.reload(), 700);
    } catch (e) { showToast(e.message || 'Erro', 'error'); }
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
