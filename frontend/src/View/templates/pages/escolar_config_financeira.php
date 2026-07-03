<?php
declare(strict_types=1);

$csrf = $app->security->csrfToken();

// Configuração actual
$cfgResp = $app->nexora->call('GET', '/api/escolar/config/financial');
$cfg = is_array($cfgResp['body'] ?? null) ? $cfgResp['body'] : [];

// Contas bancárias (tesouraria)
$bancosResp = $app->nexora->call('GET', '/api/tesouraria/contas-bancarias');
$bancos = is_array($bancosResp['body'] ?? null) ? (array_is_list($bancosResp['body']) ? $bancosResp['body'] : []) : [];

// Centros de custo
$ccResp = $app->nexora->call('GET', '/api/centros-custo/cost-centers');
$centros = is_array($ccResp['body']['data'] ?? null) ? $ccResp['body']['data'] : (is_array($ccResp['body'] ?? null) && array_is_list($ccResp['body']) ? $ccResp['body'] : []);

// Plano de contas (contabilidade)
$contasResp = $app->nexora->call('GET', '/api/contabilidade/contas');
$contasContab = is_array($contasResp['body']['data'] ?? null) ? $contasResp['body']['data'] : (is_array($contasResp['body'] ?? null) && array_is_list($contasResp['body']) ? $contasResp['body'] : []);
// Filtrar apenas contas de movimento (folha)
$contasMovimento = array_filter($contasContab, fn($c) => !empty($c['tipo_conta']) || !empty($c['codigo']));

$pageTitle  = 'Configuração Financeira Escolar';
$activePage = 'escolar_config_financeira';
$breadcrumb = $app->routes->escolarBreadcrumb([['Configuração Financeira', '']]);

include dirname(__DIR__) . '/layouts/' . (!empty($GLOBALS['_escolarPanel']) ? 'escola_top' : 'top') . '.php';
?>

<div class="adm-page-header">
    <div>
        <h1 class="adm-page-title">Configuração Financeira Escolar</h1>
        <p class="adm-page-subtitle">Define como os pagamentos escolares se integram com os restantes módulos do ERP.</p>
    </div>
    <div class="adm-page-header-actions">
        <a href="<?= htmlspecialchars($app->routes->path('escolar_dashboard')) ?>" class="adm-btn adm-btn-outline adm-btn-sm">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>
            Voltar ao Dashboard
        </a>
    </div>
</div>

<div id="formMsg"></div>

<form id="cfgForm" onsubmit="return false">

    <!-- Tesouraria -->
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header">
            <div>
                <h2 class="adm-card-title">
                    <i class="fa-solid fa-building-columns fa-fw" style="color:#2563eb;margin-right:.4rem"></i>
                    Tesouraria
                </h2>
                <p class="adm-card-subtitle">Registo automático de movimentos bancários quando uma propina é paga.</p>
            </div>
            <label class="adm-toggle">
                <input type="checkbox" id="criar_mov_tesouraria" name="criar_movimento_tesouraria"
                       <?= !empty($cfg['criar_movimento_tesouraria']) ? 'checked' : '' ?>
                       onchange="toggleSection('sec_tesouraria', this.checked)">
                <span class="adm-toggle-slider"></span>
            </label>
        </div>
        <div class="adm-card-body" id="sec_tesouraria" <?= empty($cfg['criar_movimento_tesouraria']) ? 'style="display:none"' : '' ?>>
            <div class="adm-form-group">
                <label class="adm-label" for="conta_bancaria_id">Conta Bancária</label>
                <select class="adm-select" id="conta_bancaria_id" name="conta_bancaria_id">
                    <option value="">— Seleccionar conta —</option>
                    <?php foreach ($bancos as $b): ?>
                    <option value="<?= (int)$b['id'] ?>"
                        <?= ((int)($cfg['conta_bancaria_id'] ?? 0)) === (int)$b['id'] ? 'selected' : '' ?>>
                        <?= htmlspecialchars($b['nome'] ?? $b['descricao'] ?? 'Conta '.$b['id']) ?>
                        <?php if (!empty($b['numero'])): ?> — <?= htmlspecialchars($b['numero']) ?><?php endif; ?>
                    </option>
                    <?php endforeach; ?>
                    <?php if (empty($bancos)): ?>
                    <option disabled>Nenhuma conta bancária configurada</option>
                    <?php endif; ?>
                </select>
                <p class="adm-form-hint">Os recebimentos de propinas serão registados nesta conta.</p>
            </div>
        </div>
    </div>

    <!-- Financeiro (Contas a Receber) -->
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header">
            <div>
                <h2 class="adm-card-title">
                    <i class="fa-solid fa-file-invoice-dollar fa-fw" style="color:#16a34a;margin-right:.4rem"></i>
                    Financeiro — Contas a Receber
                </h2>
                <p class="adm-card-subtitle">Cria automaticamente um registo de conta a receber no módulo Financeiro.</p>
            </div>
            <label class="adm-toggle">
                <input type="checkbox" id="criar_mov_financeiro" name="criar_movimento_financeiro"
                       <?= !empty($cfg['criar_movimento_financeiro']) ? 'checked' : '' ?>
                       onchange="toggleSection('sec_financeiro', this.checked)">
                <span class="adm-toggle-slider"></span>
            </label>
        </div>
        <div class="adm-card-body" id="sec_financeiro" <?= empty($cfg['criar_movimento_financeiro']) ? 'style="display:none"' : '' ?>>
            <div class="adm-card-body" style="padding:0">
                <div class="adm-form-group">
                    <label class="adm-label">Centro de Custo</label>
                    <select class="adm-select" id="centro_custo_id" name="centro_custo_id">
                        <option value="">— Sem centro de custo —</option>
                        <?php foreach ($centros as $cc): ?>
                        <option value="<?= (int)$cc['id'] ?>"
                            <?= ((int)($cfg['centro_custo_id'] ?? 0)) === (int)$cc['id'] ? 'selected' : '' ?>>
                            <?= htmlspecialchars($cc['codigo'] ?? '') ?> — <?= htmlspecialchars($cc['nome'] ?? '') ?>
                        </option>
                        <?php endforeach; ?>
                        <?php if (empty($centros)): ?>
                        <option disabled>Nenhum centro de custo configurado</option>
                        <?php endif; ?>
                    </select>
                </div>
            </div>
        </div>
    </div>

    <!-- Contabilidade (Journal Entries) -->
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header">
            <div>
                <h2 class="adm-card-title">
                    <i class="fa-solid fa-book fa-fw" style="color:#7c3aed;margin-right:.4rem"></i>
                    Contabilidade — Lançamentos
                </h2>
                <p class="adm-card-subtitle">Cria lançamentos contabilísticos automáticos (débito/crédito) para cada pagamento.</p>
            </div>
            <label class="adm-toggle">
                <input type="checkbox" id="criar_lanc_contab" name="criar_lancamento_contabilidade"
                       <?= !empty($cfg['criar_lancamento_contabilidade']) ? 'checked' : '' ?>
                       onchange="toggleSection('sec_contab', this.checked)">
                <span class="adm-toggle-slider"></span>
            </label>
        </div>
        <div class="adm-card-body" id="sec_contab" <?= empty($cfg['criar_lancamento_contabilidade']) ? 'style="display:none"' : '' ?>>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:var(--adm-sp-5)">
                <div class="adm-form-group">
                    <label class="adm-label" for="conta_debito_id">Conta de Débito</label>
                    <select class="adm-select" id="conta_debito_id" name="conta_debito_id">
                        <option value="">— Seleccionar conta —</option>
                        <?php foreach ($contasMovimento as $ct): ?>
                        <option value="<?= (int)$ct['id'] ?>"
                            <?= ((int)($cfg['conta_debito_id'] ?? 0)) === (int)$ct['id'] ? 'selected' : '' ?>>
                            <?= htmlspecialchars($ct['codigo'] ?? '') ?> — <?= htmlspecialchars($ct['nome'] ?? '') ?>
                        </option>
                        <?php endforeach; ?>
                        <?php if (empty($contasMovimento)): ?>
                        <option disabled>Nenhuma conta no plano de contas</option>
                        <?php endif; ?>
                    </select>
                    <p class="adm-form-hint">Normalmente a conta de caixa ou depósitos bancários.</p>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="conta_credito_id">Conta de Crédito</label>
                    <select class="adm-select" id="conta_credito_id" name="conta_credito_id">
                        <option value="">— Seleccionar conta —</option>
                        <?php foreach ($contasMovimento as $ct): ?>
                        <option value="<?= (int)$ct['id'] ?>"
                            <?= ((int)($cfg['conta_credito_id'] ?? 0)) === (int)$ct['id'] ? 'selected' : '' ?>>
                            <?= htmlspecialchars($ct['codigo'] ?? '') ?> — <?= htmlspecialchars($ct['nome'] ?? '') ?>
                        </option>
                        <?php endforeach; ?>
                        <?php if (empty($contasMovimento)): ?>
                        <option disabled>Nenhuma conta no plano de contas</option>
                        <?php endif; ?>
                    </select>
                    <p class="adm-form-hint">Normalmente a conta de receitas de propinas.</p>
                </div>
            </div>
        </div>
    </div>

    <!-- Faturação (Recibos) -->
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header">
            <div>
                <h2 class="adm-card-title">
                    <i class="fa-solid fa-receipt fa-fw" style="color:#d97706;margin-right:.4rem"></i>
                    Faturação — Recibos
                </h2>
                <p class="adm-card-subtitle">Emite automaticamente um recibo no módulo de Faturação para cada pagamento.</p>
            </div>
            <label class="adm-toggle">
                <input type="checkbox" id="criar_recibo_fat" name="criar_recibo_faturacao"
                       <?= !empty($cfg['criar_recibo_faturacao']) ? 'checked' : '' ?>
                       onchange="toggleSection('sec_faturacao', this.checked)">
                <span class="adm-toggle-slider"></span>
            </label>
        </div>
        <div class="adm-card-body" id="sec_faturacao" <?= empty($cfg['criar_recibo_faturacao']) ? 'style="display:none"' : '' ?>>
            <p class="adm-text-sm" style="color:var(--adm-gray-600)">
                Os encarregados registados como clientes no módulo <strong>Gestão de Clientes</strong> receberão recibo na série
                <strong>RB</strong> (Recibo Escolar). O recibo só é emitido se o aluno tiver um <code>client_id</code> ligado
                (<a href="<?= htmlspecialchars($app->routes->path('escolar_alunos')) ?>" style="color:var(--adm-green)">Alunos → Ligação Cliente</a>).
            </p>
        </div>
    </div>

    <!-- Botão guardar -->
    <div style="display:flex;justify-content:flex-end;gap:var(--adm-sp-3)">
        <a href="<?= htmlspecialchars($app->routes->path('escolar_dashboard')) ?>" class="adm-btn adm-btn-outline">Cancelar</a>
        <button type="button" class="adm-btn adm-btn-primary" onclick="guardarConfig()" id="btnGuardar">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/></svg>
            Guardar Configuração
        </button>
    </div>

</form>

<style>
.adm-toggle { position:relative; display:inline-flex; align-items:center; cursor:pointer; }
.adm-toggle input { opacity:0; width:0; height:0; }
.adm-toggle-slider {
    display:block; width:40px; height:22px; background:var(--adm-gray-300);
    border-radius:11px; transition:.2s;
}
.adm-toggle input:checked + .adm-toggle-slider { background:var(--adm-green); }
.adm-toggle-slider::before {
    content:''; position:absolute; width:16px; height:16px;
    border-radius:50%; background:#fff; top:3px; left:3px; transition:.2s;
}
.adm-toggle input:checked + .adm-toggle-slider::before { transform:translateX(18px); }
.adm-form-hint { font-size:var(--adm-text-xs); color:var(--adm-gray-500); margin-top:.25rem; }
</style>

<script>
const CSRF = '<?= $csrf ?>';

function toggleSection(id, show) {
    const el = document.getElementById(id);
    if (el) el.style.display = show ? '' : 'none';
}

function getVal(id) {
    const el = document.getElementById(id);
    if (!el) return undefined;
    if (el.type === 'checkbox') return el.checked;
    return el.value === '' ? null : el.value;
}

async function guardarConfig() {
    const btn = document.getElementById('btnGuardar');
    btn.disabled = true;
    btn.textContent = 'A guardar...';

    const payload = {
        csrf: CSRF,
        criar_movimento_tesouraria:     document.getElementById('criar_mov_tesouraria').checked,
        conta_bancaria_id:              getVal('conta_bancaria_id'),
        criar_movimento_financeiro:     document.getElementById('criar_mov_financeiro').checked,
        centro_custo_id:                getVal('centro_custo_id'),
        criar_lancamento_contabilidade: document.getElementById('criar_lanc_contab').checked,
        conta_debito_id:                getVal('conta_debito_id'),
        conta_credito_id:               getVal('conta_credito_id'),
        criar_recibo_faturacao:         document.getElementById('criar_recibo_fat').checked,
    };

    try {
        const res  = await fetch('/nexora/api/escolar_config_save', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload),
        });
        const data = await res.json();
        const msg  = document.getElementById('formMsg');
        if (data.ok) {
            msg.innerHTML = '<div class="adm-alert adm-alert--success" style="margin-bottom:1.5rem">Configuração guardada com sucesso.</div>';
            showToast('Configuração guardada');
        } else {
            msg.innerHTML = '<div class="adm-alert adm-alert--error" style="margin-bottom:1.5rem">' + (data.erro || 'Erro ao guardar.') + '</div>';
            showToast(data.erro || 'Erro ao guardar', 'error');
        }
    } catch {
        showToast('Erro de ligação', 'error');
    } finally {
        btn.disabled = false;
        btn.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/></svg> Guardar Configuração';
    }
}
</script>

<?php include dirname(__DIR__) . '/layouts/' . (!empty($GLOBALS['_escolarPanel']) ? 'escola_bottom' : 'bottom') . '.php'; ?>

