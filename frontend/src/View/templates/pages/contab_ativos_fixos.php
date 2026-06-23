<?php

    $ativos = $app->nexora->call('GET', '/api/contabilidade/fixed-assets')['body'] ?? [];
    $contas = $app->nexora->call('GET', '/api/contabilidade/accounts', null, ['aceita_lancamento' => 'true', 'ativo' => 'true'])['body'] ?? [];

    $contaLabels = [];
    foreach ($contas as $c) {
        $contaLabels[$c['id']] = $c['codigo'] . ' - ' . $c['nome'];
    }

    $estadoBadges = [
        'ativo'    => ['adm-badge--green', 'Ativo'],
        'alienado' => ['adm-badge--gray', 'Alienado'],
    ];

    $depStatusBadges = [
        'pendente'   => ['adm-badge--yellow', 'Pendente'],
        'processado' => ['adm-badge--green', 'Processado'],
        'cancelado'  => ['adm-badge--gray', 'Cancelado'],
    ];

    $verId    = $app->request->queryInt('ver', 0);
    $plano    = null;
    $ativoVer = null;
    if ($verId > 0) {
        $resp = $app->nexora->call('GET', "/api/contabilidade/fixed-assets/$verId/schedule");
        if ($resp['status'] === 200) {
            $plano = $resp['body'] ?? null;
            foreach ($ativos as $a) {
                if ((int) $a['id'] === $verId) {
                    $ativoVer = $a;
                    break;
                }
            }
        }
    }

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Ativos Fixos';
    $activePage = 'contab_ativos_fixos';
    $breadcrumb = [['Admin', '/nexora/'], ['Contabilidade', ''], ['Ativos Fixos', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Ativos Fixos</h1>
</div>

<div id="formMsg"></div>

<?php if ($plano && $ativoVer): ?>
<div class="adm-card adm-mb-6">
    <div class="adm-card-header">
        <h2 class="adm-card-title">Plano de Amortização — <?php echo htmlspecialchars($ativoVer['codigo'] . ' - ' . $ativoVer['nome']) ?></h2>
        <a href="<?php echo htmlspecialchars($app->routes->path('contab_ativos_fixos')) ?>" class="adm-btn adm-btn-outline adm-btn-sm">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>
            Voltar à lista
        </a>
    </div>
    <div class="adm-card-body">
        <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:var(--adm-sp-5)" class="adm-mb-6">
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Valor de Aquisição</span>
                <span class="adm-detail-pair-value adm-fw-600"><?php echo number_format((float) $plano['valor_aquisicao'], 2, ',', '.') ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Valor Residual</span>
                <span class="adm-detail-pair-value adm-fw-600"><?php echo number_format((float) $plano['valor_residual'], 2, ',', '.') ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Vida Útil</span>
                <span class="adm-detail-pair-value adm-fw-600"><?php echo (int) $plano['vida_util_meses'] ?> meses</span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Parcela Mensal</span>
                <span class="adm-detail-pair-value adm-fw-600"><?php echo number_format((float) $plano['valor_parcela'], 2, ',', '.') ?></span>
            </div>
        </div>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Parcela</th><th>Valor</th><th>Estado</th><th>Lançamento</th></tr>
                </thead>
                <tbody>
                <?php foreach ($plano['plano'] ?? [] as $p):
                        $status = $depStatusBadges[$p['status']] ?? ['adm-badge--gray', $p['status']];
                ?>
                <tr>
                    <td class="adm-fw-600">#<?php echo (int) $p['numero_parcela'] ?></td>
                    <td><?php echo number_format((float) $p['valor_amortizacao'], 2, ',', '.') ?></td>
                    <td><span class="adm-badge <?php echo $status[0] ?>"><?php echo $status[1] ?></span></td>
                    <td>
                        <?php if (! empty($p['journal_entry_id'])): ?>
                        <a href="<?php echo htmlspecialchars($app->routes->path('contab_lancamento', ['id' => $p['journal_entry_id']])) ?>">Ver lançamento</a>
                        <?php else: ?>
                        <span class="adm-text-muted">—</span>
                        <?php endif; ?>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>
<?php endif; ?>

<div class="adm-card adm-mb-6">
    <div class="adm-filter-bar">
        <div class="adm-search-wrap">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
            </svg>
            <input class="adm-input" type="search" id="afSearch" placeholder="Pesquisar ativos…" oninput="filterTable()">
        </div>
        <select class="adm-select" id="afEstado" onchange="filterTable()" style="width:160px">
            <option value="">Todos os estados</option>
            <?php foreach ($estadoBadges as $key => [$cls, $label]): ?>
            <option value="<?php echo $key ?>"><?php echo $label ?></option>
            <?php endforeach; ?>
        </select>
        <span class="adm-filter-count" id="afCount"><?php echo count($ativos) ?> ativos</span>
    </div>

    <?php if ($ativos): ?>
    <div class="adm-table-wrap">
        <table class="adm-table" id="afTable">
            <thead>
                <tr>
                    <th>Código</th>
                    <th>Nome</th>
                    <th>Conta</th>
                    <th>Aquisição</th>
                    <th>Valor Residual</th>
                    <th>Vida Útil</th>
                    <th>Estado</th>
                    <th>Ações</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($ativos as $a):
                    $estado = $estadoBadges[$a['estado']] ?? ['adm-badge--gray', $a['estado']];
            ?>
            <tr data-estado="<?php echo htmlspecialchars($a['estado']) ?>"
                data-id="<?php echo (int) $a['id'] ?>"
                data-codigo="<?php echo htmlspecialchars($a['codigo']) ?>"
                data-nome="<?php echo htmlspecialchars($a['nome']) ?>"
                data-chart-account-id="<?php echo (int) $a['chart_account_id'] ?>"
                data-depreciation-account-id="<?php echo (int) $a['depreciation_account_id'] ?>"
                data-accumulated-depreciation-account-id="<?php echo (int) $a['accumulated_depreciation_account_id'] ?>"
                data-data-aquisicao="<?php echo htmlspecialchars(date('Y-m-d', strtotime($a['data_aquisicao']))) ?>"
                data-valor-aquisicao="<?php echo (float) $a['valor_aquisicao'] ?>"
                data-valor-residual="<?php echo (float) $a['valor_residual'] ?>"
                data-vida-util-meses="<?php echo (int) $a['vida_util_meses'] ?>">
                <td class="adm-fw-600"><?php echo htmlspecialchars($a['codigo']) ?></td>
                <td><?php echo htmlspecialchars($a['nome']) ?></td>
                <td class="adm-text-muted"><?php echo htmlspecialchars($contaLabels[$a['chart_account_id']] ?? ('#' . $a['chart_account_id'])) ?></td>
                <td class="adm-text-muted">
                    <?php echo date('d/m/Y', strtotime($a['data_aquisicao'])) ?><br>
                    <span class="adm-fw-600"><?php echo number_format((float) $a['valor_aquisicao'], 2, ',', '.') ?></span>
                </td>
                <td><?php echo number_format((float) $a['valor_residual'], 2, ',', '.') ?></td>
                <td><?php echo (int) $a['vida_util_meses'] ?> meses</td>
                <td><span class="adm-badge <?php echo $estado[0] ?>"><?php echo $estado[1] ?></span></td>
                <td>
                    <div class="adm-actions">
                        <a href="?ver=<?php echo (int) $a['id'] ?>" class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Ver Plano de Amortização">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/>
                            </svg>
                        </a>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" type="button" title="Editar" onclick="editarAtivo(this.closest('tr'))">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                            </svg>
                        </button>
                        <?php if ($a['estado'] === 'ativo'): ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" type="button" title="Alienar" onclick="abrirAlienar(this.closest('tr'))">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M3 6h18"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
                            </svg>
                        </button>
                        <?php endif; ?>
                    </div>
                </td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="adm-empty">
        <p class="adm-empty-title">Nenhum ativo fixo registado</p>
    </div>
    <?php endif; ?>
</div>

<div class="adm-card adm-mb-6" id="alienarCard" style="display:none">
    <div class="adm-card-header"><h2 class="adm-card-title">Alienar Ativo Fixo — <span id="alAtivoNome"></span></h2></div>
    <div class="adm-card-body">
        <input type="hidden" id="al-id" value="0">
        <div class="adm-form-row">
            <div class="adm-form-group">
                <label class="adm-label" for="al-data">Data de Alienação <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="date" id="al-data">
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="al-valor">Valor de Alienação</label>
                <input class="adm-input" type="number" id="al-valor" min="0" step="0.01" placeholder="0.00">
            </div>
        </div>
        <div style="display:flex;gap:var(--adm-sp-3)">
            <button class="adm-btn adm-btn-primary" type="button" onclick="confirmarAlienar()">Confirmar Alienação</button>
            <button class="adm-btn adm-btn-outline" type="button" onclick="cancelarAlienar()">Cancelar</button>
        </div>
    </div>
</div>

<div class="adm-card">
    <div class="adm-card-header"><h2 class="adm-card-title" id="afFormTitle">Novo Ativo Fixo</h2></div>
    <div class="adm-card-body">
        <input type="hidden" id="af-id" value="0">
        <div class="adm-form-row-3">
            <div class="adm-form-group">
                <label class="adm-label" for="af-conta">Conta do Ativo <span style="color:var(--adm-red)">*</span></label>
                <select class="adm-select" id="af-conta">
                    <option value="">Seleciona uma conta</option>
                    <?php foreach ($contas as $c): ?>
                    <option value="<?php echo $c['id'] ?>"><?php echo htmlspecialchars($c['codigo'] . ' - ' . $c['nome']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="af-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="text" id="af-codigo" maxlength="50">
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="af-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="text" id="af-nome" maxlength="255">
            </div>
        </div>
        <div class="adm-form-row-3">
            <div class="adm-form-group">
                <label class="adm-label" for="af-conta-amortizacao">Conta de Amortização <span style="color:var(--adm-red)">*</span></label>
                <select class="adm-select" id="af-conta-amortizacao">
                    <option value="">Seleciona uma conta</option>
                    <?php foreach ($contas as $c): ?>
                    <option value="<?php echo $c['id'] ?>"><?php echo htmlspecialchars($c['codigo'] . ' - ' . $c['nome']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="af-conta-acumulada">Conta de Amortização Acumulada <span style="color:var(--adm-red)">*</span></label>
                <select class="adm-select" id="af-conta-acumulada">
                    <option value="">Seleciona uma conta</option>
                    <?php foreach ($contas as $c): ?>
                    <option value="<?php echo $c['id'] ?>"><?php echo htmlspecialchars($c['codigo'] . ' - ' . $c['nome']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
        </div>
        <div class="adm-form-row-3">
            <div class="adm-form-group">
                <label class="adm-label" for="af-data-aquisicao">Data de Aquisição <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="date" id="af-data-aquisicao" value="<?php echo date('Y-m-d') ?>">
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="af-valor-aquisicao">Valor de Aquisição <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="number" id="af-valor-aquisicao" min="0" step="0.01" placeholder="0.00">
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="af-valor-residual">Valor Residual</label>
                <input class="adm-input" type="number" id="af-valor-residual" min="0" step="0.01" placeholder="0.00" value="0">
            </div>
        </div>
        <div class="adm-form-row-3">
            <div class="adm-form-group">
                <label class="adm-label" for="af-vida-util">Vida Útil (meses) <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="number" id="af-vida-util" min="1" step="1" placeholder="ex: 60">
            </div>
        </div>
        <div style="display:flex;gap:var(--adm-sp-3)">
            <button class="adm-btn adm-btn-primary" id="afBtnSave" type="button" onclick="guardarAtivo()">Criar Ativo Fixo</button>
            <button class="adm-btn adm-btn-outline" id="afBtnCancel" type="button" onclick="cancelarEdicaoAtivo()" style="display:none">Cancelar</button>
        </div>
    </div>
</div>

<script>
const CSRF = '<?php echo $csrf ?>';

function filterTable() {
    const q      = document.getElementById('afSearch').value.toLowerCase();
    const estado = document.getElementById('afEstado').value;
    const rows   = document.querySelectorAll('#afTable tbody tr');
    let vis = 0;
    rows.forEach(row => {
        const txt  = row.textContent.toLowerCase();
        const est  = row.dataset.estado;
        const show = (!q || txt.includes(q)) && (!estado || est === estado);
        row.style.display = show ? '' : 'none';
        if (show) vis++;
    });
    const countEl = document.getElementById('afCount');
    if (countEl) countEl.textContent = vis + ' ativo' + (vis !== 1 ? 's' : '');
}

async function postJSON(url, payload) {
    try {
        const res  = await fetch(url, {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            showToast(data.msg || 'Guardado com sucesso.');
            setTimeout(() => window.location.href = '/nexora/contabilidade/ativos-fixos', 700);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}

function editarAtivo(tr) {
    const d = tr.dataset;
    document.getElementById('af-id').value = d.id;

    const elConta = document.getElementById('af-conta');
    elConta.value = d.chartAccountId;
    elConta.disabled = true;

    document.getElementById('af-conta-amortizacao').value = d.depreciationAccountId;
    document.getElementById('af-conta-acumulada').value = d.accumulatedDepreciationAccountId;

    const elCodigo = document.getElementById('af-codigo');
    elCodigo.value = d.codigo;
    elCodigo.disabled = true;

    document.getElementById('af-nome').value = d.nome;

    const elDataAquisicao = document.getElementById('af-data-aquisicao');
    elDataAquisicao.value = d.dataAquisicao;
    elDataAquisicao.disabled = true;

    const elValorAquisicao = document.getElementById('af-valor-aquisicao');
    elValorAquisicao.value = d.valorAquisicao;
    elValorAquisicao.disabled = true;

    document.getElementById('af-valor-residual').value = d.valorResidual;
    document.getElementById('af-vida-util').value = d.vidaUtilMeses;

    document.getElementById('afFormTitle').textContent = 'Editar Ativo Fixo — ' + d.codigo;
    document.getElementById('afBtnSave').textContent = 'Guardar Alterações';
    document.getElementById('afBtnCancel').style.display = '';

    document.getElementById('afFormTitle').scrollIntoView({behavior: 'smooth', block: 'center'});
}

function cancelarEdicaoAtivo() {
    document.getElementById('af-id').value = '0';

    const elConta = document.getElementById('af-conta');
    elConta.value = '';
    elConta.disabled = false;

    document.getElementById('af-conta-amortizacao').value = '';
    document.getElementById('af-conta-acumulada').value = '';

    const elCodigo = document.getElementById('af-codigo');
    elCodigo.value = '';
    elCodigo.disabled = false;

    document.getElementById('af-nome').value = '';

    const elDataAquisicao = document.getElementById('af-data-aquisicao');
    elDataAquisicao.value = '<?php echo date('Y-m-d') ?>';
    elDataAquisicao.disabled = false;

    const elValorAquisicao = document.getElementById('af-valor-aquisicao');
    elValorAquisicao.value = '';
    elValorAquisicao.disabled = false;

    document.getElementById('af-valor-residual').value = '0';
    document.getElementById('af-vida-util').value = '';

    document.getElementById('afFormTitle').textContent = 'Novo Ativo Fixo';
    document.getElementById('afBtnSave').textContent = 'Criar Ativo Fixo';
    document.getElementById('afBtnCancel').style.display = 'none';
}

async function guardarAtivo() {
    const id = Number(document.getElementById('af-id').value || 0);
    const nome           = document.getElementById('af-nome').value.trim();
    const contaAmort     = document.getElementById('af-conta-amortizacao').value;
    const contaAcumulada = document.getElementById('af-conta-acumulada').value;
    const valorResidual  = Number(document.getElementById('af-valor-residual').value || 0);
    const vidaUtil       = Number(document.getElementById('af-vida-util').value || 0);

    if (!nome || !contaAmort || !contaAcumulada || vidaUtil <= 0) {
        showToast('Nome, contas de amortização e vida útil são obrigatórios.', 'error');
        return;
    }

    const payload = {
        id,
        nome,
        depreciation_account_id: Number(contaAmort),
        accumulated_depreciation_account_id: Number(contaAcumulada),
        valor_residual: valorResidual,
        vida_util_meses: vidaUtil,
        csrf: CSRF
    };

    if (!id) {
        const conta          = document.getElementById('af-conta').value;
        const codigo         = document.getElementById('af-codigo').value.trim();
        const dataAquisicao  = document.getElementById('af-data-aquisicao').value;
        const valorAquisicao = Number(document.getElementById('af-valor-aquisicao').value || 0);

        if (!conta || !codigo || !dataAquisicao || valorAquisicao <= 0) {
            showToast('Conta, código, data e valor de aquisição são obrigatórios.', 'error');
            return;
        }

        payload.chart_account_id = Number(conta);
        payload.codigo = codigo;
        payload.data_aquisicao = dataAquisicao;
        payload.valor_aquisicao = valorAquisicao;
        payload.metodo = 'linha_recta';
    }

    postJSON('/nexora/api/contab_ativo_fixo_save', payload);
}

function abrirAlienar(tr) {
    const d = tr.dataset;
    document.getElementById('al-id').value = d.id;
    document.getElementById('alAtivoNome').textContent = d.codigo + ' - ' + d.nome;
    document.getElementById('al-data').value = new Date().toISOString().slice(0, 10);
    document.getElementById('al-valor').value = '';
    const card = document.getElementById('alienarCard');
    card.style.display = '';
    card.scrollIntoView({behavior: 'smooth', block: 'center'});
}

function cancelarAlienar() {
    document.getElementById('alienarCard').style.display = 'none';
}

function confirmarAlienar() {
    const id    = Number(document.getElementById('al-id').value || 0);
    const data  = document.getElementById('al-data').value;
    const valor = Number(document.getElementById('al-valor').value || 0);
    const nome  = document.getElementById('alAtivoNome').textContent;

    if (!id || !data) { showToast('A data de alienação é obrigatória.', 'error'); return; }

    openConfirm(
        'Alienar ativo fixo',
        'Marcar o ativo ' + nome + ' como alienado? Esta ação altera o estado do ativo e não pode ser revertida pela interface.',
        () => postJSON('/nexora/api/contab_ativo_fixo_alienar', { id, data_alienacao: data, valor_alienacao: valor, csrf: CSRF })
    );
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
