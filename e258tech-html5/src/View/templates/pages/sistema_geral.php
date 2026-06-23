<?php

    $settings      = $app->nexora->call('GET', '/api/system/settings')['body'] ?? [];
    $currencies    = $app->nexora->call('GET', '/api/system/currencies')['body'] ?? [];
    $exchangeRates = $app->nexora->call('GET', '/api/system/exchange-rates')['body'] ?? [];
    $countries     = $app->nexora->call('GET', '/api/system/countries')['body'] ?? [];
    $cities        = $app->nexora->call('GET', '/api/system/cities')['body'] ?? [];
    $languages     = $app->nexora->call('GET', '/api/system/languages')['body'] ?? [];

    $countryMap = [];
    foreach ($countries as $c) {
        $countryMap[(int) $c['id']] = $c['nome'];
    }

    $escopoBadges = [
        'global' => ['adm-badge--indigo', 'Global'],
        'tenant' => ['adm-badge--blue', 'Empresa'],
        'user'   => ['adm-badge--gray', 'Utilizador'],
    ];

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Configurações Gerais';
    $activePage = 'sistema_geral';
    $breadcrumb = [['Admin', '/nexora/'], ['Sistema', ''], ['Configurações Gerais', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Configurações Gerais</h1>
</div>

<div class="adm-tabs" id="mainTabs">
    <button class="adm-tab active" onclick="switchTab('definicoes',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>
        Definições
        <?php if (count($settings)): ?><span class="adm-tab-badge"><?php echo count($settings) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('moedas',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="6" x2="12" y2="18"/><path d="M15 9.5a3 3 0 0 0-3-1.5 3 3 0 0 0 0 6 3 3 0 0 1 0 6 3 3 0 0 1-3-1.5"/></svg>
        Moedas &amp; Câmbio
        <?php if (count($currencies)): ?><span class="adm-tab-badge"><?php echo count($currencies) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('localizacao',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
        Localização
    </button>
</div>

<!-- ── Definições ─────────────────────────────────────────── -->
<div class="adm-tab-panel active" id="tab-definicoes">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Definições</h2></div>
        <?php if ($settings): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Chave</th><th>Valor</th><th>Âmbito</th></tr>
                </thead>
                <tbody>
                <?php foreach ($settings as $s):
                    $badge = $escopoBadges[$s['escopo']] ?? ['adm-badge--gray', $s['escopo']];
                ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($s['chave']) ?></td>
                    <td class="adm-text-sm adm-text-muted"><?php echo $s['valor'] !== null && $s['valor'] !== '' ? htmlspecialchars($s['valor']) : '—' ?></td>
                    <td><span class="adm-badge <?php echo $badge[0] ?>"><?php echo $badge[1] ?></span></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhuma definição configurada</p>
            <p class="adm-empty-sub">Adicione a primeira definição usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Nova Definição</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="s-chave">Chave <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="s-chave" maxlength="120" placeholder="ex: empresa.nome">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="s-valor">Valor</label>
                    <input class="adm-input" type="text" id="s-valor" maxlength="500" placeholder="ex: E258Tech">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="s-escopo">Âmbito</label>
                    <select class="adm-select" id="s-escopo">
                        <option value="tenant" selected>Empresa</option>
                        <option value="global">Global</option>
                        <option value="user">Utilizador</option>
                    </select>
                </div>
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-primary" type="button" onclick="saveSetting()">Adicionar Definição</button>
            </div>
        </div>
    </div>
</div>

<!-- ── Moedas & Câmbio ────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-moedas">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Moedas</h2></div>
        <?php if ($currencies): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Código</th><th>Nome</th><th>Símbolo</th><th>Estado</th></tr>
                </thead>
                <tbody>
                <?php foreach ($currencies as $c): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($c['codigo']) ?></td>
                    <td><?php echo htmlspecialchars($c['nome']) ?></td>
                    <td class="adm-text-muted"><?php echo $c['simbolo'] ? htmlspecialchars($c['simbolo']) : '—' ?></td>
                    <td><span class="adm-badge <?php echo $c['ativa'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $c['ativa'] ? 'Ativa' : 'Inativa' ?></span></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhuma moeda registada</p>
            <p class="adm-empty-sub">Adicione a primeira moeda usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Nova Moeda</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="mo-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="mo-codigo" maxlength="10" placeholder="ex: MZN">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="mo-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="mo-nome" maxlength="120" placeholder="ex: Metical">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="mo-simbolo">Símbolo</label>
                    <input class="adm-input" type="text" id="mo-simbolo" maxlength="10" placeholder="ex: MT">
                </div>
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-primary" type="button" onclick="saveMoeda()">Adicionar Moeda</button>
            </div>
        </div>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Taxas de Câmbio</h2></div>
        <?php if ($exchangeRates): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>De</th><th>Para</th><th>Taxa</th><th>Data</th></tr>
                </thead>
                <tbody>
                <?php foreach ($exchangeRates as $e): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($e['de']) ?></td>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($e['para']) ?></td>
                    <td><?php echo number_format((float) $e['rate'], 6, ',', '.') ?></td>
                    <td class="adm-text-muted"><?php echo date('d/m/Y', strtotime($e['rate_date'])) ?></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhuma taxa de câmbio registada</p>
            <p class="adm-empty-sub">Adicione a primeira taxa usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Nova Taxa de Câmbio</h2></div>
        <div class="adm-card-body">
            <?php if (count($currencies) < 2): ?>
            <p class="adm-text-muted adm-text-sm">É necessário ter pelo menos duas moedas registadas para criar uma taxa de câmbio.</p>
            <?php else: ?>
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="tc-de">De <span style="color:var(--adm-red)">*</span></label>
                    <select class="adm-select" id="tc-de">
                        <?php foreach ($currencies as $c): ?>
                        <option value="<?php echo (int) $c['id'] ?>"><?php echo htmlspecialchars($c['codigo']) ?> — <?php echo htmlspecialchars($c['nome']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="tc-para">Para <span style="color:var(--adm-red)">*</span></label>
                    <select class="adm-select" id="tc-para">
                        <?php foreach ($currencies as $c): ?>
                        <option value="<?php echo (int) $c['id'] ?>"><?php echo htmlspecialchars($c['codigo']) ?> — <?php echo htmlspecialchars($c['nome']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="tc-rate">Taxa <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="number" id="tc-rate" step="0.000001" min="0" placeholder="ex: 64.25">
                </div>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="tc-data">Data</label>
                <input class="adm-input" type="date" id="tc-data" value="<?php echo date('Y-m-d') ?>" style="max-width:200px">
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-primary" type="button" onclick="saveTaxaCambio()">Adicionar Taxa</button>
            </div>
            <?php endif; ?>
        </div>
    </div>
</div>

<!-- ── Localização ────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-localizacao">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Países</h2></div>
        <?php if ($countries): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Código</th><th>Nome</th></tr>
                </thead>
                <tbody>
                <?php foreach ($countries as $c): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($c['codigo']) ?></td>
                    <td><?php echo htmlspecialchars($c['nome']) ?></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum país registado</p>
            <p class="adm-empty-sub">Adicione o primeiro país usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Novo País</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="p-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="p-codigo" maxlength="5" placeholder="ex: MZ">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="p-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="p-nome" maxlength="120" placeholder="ex: Moçambique">
                </div>
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-primary" type="button" onclick="savePais()">Adicionar País</button>
            </div>
        </div>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Cidades</h2></div>
        <?php if ($cities): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Nome</th><th>País</th></tr>
                </thead>
                <tbody>
                <?php foreach ($cities as $c): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($c['nome']) ?></td>
                    <td class="adm-text-muted"><?php echo $c['country_id'] !== null ? htmlspecialchars($countryMap[(int) $c['country_id']] ?? '—') : '—' ?></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhuma cidade registada</p>
            <p class="adm-empty-sub">Adicione a primeira cidade usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Nova Cidade</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="ci-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="ci-nome" maxlength="120" placeholder="ex: Maputo">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="ci-pais">País</label>
                    <select class="adm-select" id="ci-pais">
                        <option value="">— Nenhum —</option>
                        <?php foreach ($countries as $c): ?>
                        <option value="<?php echo (int) $c['id'] ?>"><?php echo htmlspecialchars($c['nome']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-primary" type="button" onclick="saveCidade()">Adicionar Cidade</button>
            </div>
        </div>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Idiomas</h2></div>
        <?php if ($languages): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Código</th><th>Nome</th></tr>
                </thead>
                <tbody>
                <?php foreach ($languages as $l): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($l['codigo']) ?></td>
                    <td><?php echo htmlspecialchars($l['nome']) ?></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum idioma registado</p>
            <p class="adm-empty-sub">Adicione o primeiro idioma usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Novo Idioma</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="id-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="id-codigo" maxlength="5" placeholder="ex: pt">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="id-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="id-nome" maxlength="120" placeholder="ex: Português">
                </div>
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-primary" type="button" onclick="saveIdioma()">Adicionar Idioma</button>
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
    const tabs = ['definicoes', 'moedas', 'localizacao'];
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

// ── Definições ───────────────────────────────────────────────
function saveSetting() {
    const chave = document.getElementById('s-chave').value.trim();
    if (!chave) { showToast('A chave é obrigatória.', 'error'); return; }

    postJSON('/nexora/api/sistema_setting_save', {
        chave,
        valor: document.getElementById('s-valor').value.trim() || null,
        escopo: document.getElementById('s-escopo').value,
        csrf: CSRF
    }, 'definicoes');
}

// ── Moedas ───────────────────────────────────────────────────
function saveMoeda() {
    const codigo = document.getElementById('mo-codigo').value.trim();
    const nome   = document.getElementById('mo-nome').value.trim();
    if (!codigo || !nome) { showToast('Código e nome são obrigatórios.', 'error'); return; }

    postJSON('/nexora/api/sistema_moeda_save', {
        codigo,
        nome,
        simbolo: document.getElementById('mo-simbolo').value.trim() || null,
        csrf: CSRF
    }, 'moedas');
}

// ── Taxas de Câmbio ──────────────────────────────────────────
function saveTaxaCambio() {
    const de   = document.getElementById('tc-de').value;
    const para = document.getElementById('tc-para').value;
    const rate = document.getElementById('tc-rate').value;

    if (!de || !para) { showToast('Selecione as moedas de origem e destino.', 'error'); return; }
    if (de === para) { showToast('As moedas de origem e destino devem ser diferentes.', 'error'); return; }
    if (!rate || Number(rate) <= 0) { showToast('A taxa deve ser superior a zero.', 'error'); return; }

    postJSON('/nexora/api/sistema_taxa_cambio_save', {
        from_currency_id: Number(de),
        to_currency_id: Number(para),
        rate: Number(rate),
        rate_date: document.getElementById('tc-data').value || null,
        csrf: CSRF
    }, 'moedas');
}

// ── Países ───────────────────────────────────────────────────
function savePais() {
    const codigo = document.getElementById('p-codigo').value.trim();
    const nome   = document.getElementById('p-nome').value.trim();
    if (!codigo || !nome) { showToast('Código e nome são obrigatórios.', 'error'); return; }

    postJSON('/nexora/api/sistema_pais_save', { codigo, nome, csrf: CSRF }, 'localizacao');
}

// ── Cidades ──────────────────────────────────────────────────
function saveCidade() {
    const nome = document.getElementById('ci-nome').value.trim();
    if (!nome) { showToast('O nome é obrigatório.', 'error'); return; }

    const pais = document.getElementById('ci-pais').value;
    postJSON('/nexora/api/sistema_cidade_save', {
        nome,
        country_id: pais ? Number(pais) : null,
        csrf: CSRF
    }, 'localizacao');
}

// ── Idiomas ──────────────────────────────────────────────────
function saveIdioma() {
    const codigo = document.getElementById('id-codigo').value.trim();
    const nome   = document.getElementById('id-nome').value.trim();
    if (!codigo || !nome) { showToast('Código e nome são obrigatórios.', 'error'); return; }

    postJSON('/nexora/api/sistema_idioma_save', { codigo, nome, csrf: CSRF }, 'localizacao');
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
