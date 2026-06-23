<?php

    $anosFiscais = $app->nexora->call('GET', '/api/contabilidade/fiscal-years')['body'] ?? [];
    $contas      = $app->nexora->call('GET', '/api/contabilidade/accounts', null, ['aceita_lancamento' => 'true', 'ativo' => 'true'])['body'] ?? [];

    $mesesLabels = [
        1 => 'Janeiro', 2 => 'Fevereiro', 3 => 'Março', 4 => 'Abril',
        5 => 'Maio', 6 => 'Junho', 7 => 'Julho', 8 => 'Agosto',
        9 => 'Setembro', 10 => 'Outubro', 11 => 'Novembro', 12 => 'Dezembro',
    ];

    $anoFiscalId = $app->request->queryInt('ano', 0);
    if ($anoFiscalId <= 0 && $anosFiscais) {
        $aberto = null;
        foreach ($anosFiscais as $a) {
            if ($a['status'] === 'aberto') {
                $aberto = $a;
                break;
            }
        }
        $anoFiscalId = (int) ($aberto['id'] ?? $anosFiscais[0]['id']);
    }

    $mesFiltro = $app->request->queryInt('mes', 0) ?? 0;

    $orcamentos  = [];
    $vsRealizado = [];
    if ($anoFiscalId > 0) {
        $orcamentos = $app->nexora->call('GET', '/api/contabilidade/budgets', null, ['fiscal_year_id' => $anoFiscalId])['body'] ?? [];

        $vsQuery = ['fiscal_year_id' => $anoFiscalId];
        if ($mesFiltro > 0) {
            $vsQuery['mes'] = $mesFiltro;
        }
        $vsRealizado = $app->nexora->call('GET', '/api/contabilidade/budgets/vs-realizado', null, $vsQuery)['body'] ?? [];
    }

    $totalOrcado    = 0.0;
    $totalRealizado = 0.0;
    foreach ($vsRealizado as $v) {
        $totalOrcado    += (float) $v['valor_orcamentado'];
        $totalRealizado += (float) $v['valor_realizado'];
    }

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Orçamentos';
    $activePage = 'contab_orcamentos';
    $breadcrumb = [['Admin', '/nexora/'], ['Contabilidade', ''], ['Orçamentos', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Orçamentos</h1>
</div>

<div id="formMsg"></div>

<?php if (! $anosFiscais): ?>
<div class="adm-card">
    <div class="adm-empty">
        <p class="adm-empty-title">Nenhum ano fiscal registado</p>
        <p class="adm-text-muted">Crie um ano fiscal antes de definir orçamentos.</p>
        <a href="<?php echo htmlspecialchars($app->routes->path('contab_periodos')) ?>" class="adm-btn adm-btn-primary adm-mt-4">Anos e Períodos Fiscais</a>
    </div>
</div>
<?php else: ?>

<div class="adm-card adm-mb-6">
    <div class="adm-filter-bar">
        <select class="adm-select" id="fAno" onchange="aplicarFiltro()" style="width:200px">
            <?php foreach ($anosFiscais as $a): ?>
            <option value="<?php echo (int) $a['id'] ?>" <?php echo (int) $a['id'] === $anoFiscalId ? 'selected' : '' ?>>
                Ano Fiscal <?php echo (int) $a['ano'] ?> (<?php echo $a['status'] === 'aberto' ? 'Aberto' : 'Fechado' ?>)
            </option>
            <?php endforeach; ?>
        </select>
        <select class="adm-select" id="fMes" onchange="aplicarFiltro()" style="width:200px">
            <option value="0" <?php echo $mesFiltro === 0 ? 'selected' : '' ?>>Anual (todos os meses)</option>
            <?php foreach ($mesesLabels as $num => $label): ?>
            <option value="<?php echo $num ?>" <?php echo $mesFiltro === $num ? 'selected' : '' ?>><?php echo $label ?></option>
            <?php endforeach; ?>
        </select>
    </div>
</div>

<div class="adm-card adm-mb-6">
    <div class="adm-card-header">
        <h2 class="adm-card-title">
            Orçado vs Realizado — <?php echo $mesFiltro === 0 ? 'Anual' : htmlspecialchars($mesesLabels[$mesFiltro]) ?>
        </h2>
    </div>
    <div class="adm-card-body">
        <?php if ($vsRealizado): ?>
        <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:var(--adm-sp-5)" class="adm-mb-6">
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Total Orçado</span>
                <span class="adm-detail-pair-value adm-fw-600"><?php echo number_format($totalOrcado, 2, ',', '.') ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Total Realizado</span>
                <span class="adm-detail-pair-value adm-fw-600"><?php echo number_format($totalRealizado, 2, ',', '.') ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Variação Total</span>
                <span class="adm-detail-pair-value adm-fw-600" style="color:<?php echo ($totalRealizado - $totalOrcado) >= 0 ? 'var(--adm-green)' : 'var(--adm-red)' ?>">
                    <?php echo number_format($totalRealizado - $totalOrcado, 2, ',', '.') ?>
                </span>
            </div>
        </div>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr>
                        <th>Conta</th>
                        <th>Orçado</th>
                        <th>Realizado</th>
                        <th>Variação</th>
                        <th>Variação %</th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach ($vsRealizado as $v): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($v['codigo'] . ' - ' . $v['nome']) ?></td>
                    <td><?php echo number_format((float) $v['valor_orcamentado'], 2, ',', '.') ?></td>
                    <td><?php echo number_format((float) $v['valor_realizado'], 2, ',', '.') ?></td>
                    <td style="color:<?php echo (float) $v['variacao'] >= 0 ? 'var(--adm-green)' : 'var(--adm-red)' ?>">
                        <?php echo number_format((float) $v['variacao'], 2, ',', '.') ?>
                    </td>
                    <td style="color:<?php echo (float) $v['variacao'] >= 0 ? 'var(--adm-green)' : 'var(--adm-red)' ?>">
                        <?php echo $v['variacao_pct'] !== null ? number_format((float) $v['variacao_pct'], 1, ',', '.') . '%' : '—' ?>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum orçamento definido para este período</p>
        </div>
        <?php endif; ?>
    </div>
</div>

<div class="adm-card adm-mb-6">
    <div class="adm-filter-bar">
        <div class="adm-search-wrap">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
            </svg>
            <input class="adm-input" type="search" id="orcSearch" placeholder="Pesquisar contas…" oninput="filterTable()">
        </div>
        <span class="adm-filter-count" id="orcCount"><?php echo count($orcamentos) ?> orçamentos</span>
    </div>

    <?php if ($orcamentos): ?>
    <div class="adm-table-wrap">
        <table class="adm-table" id="orcTable">
            <thead>
                <tr>
                    <th>Conta</th>
                    <th>Mês</th>
                    <th>Valor Orçamentado</th>
                    <th>Ações</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($orcamentos as $o): ?>
            <tr data-id="<?php echo (int) $o['id'] ?>"
                data-chart-account-id="<?php echo (int) $o['chart_account_id'] ?>"
                data-mes="<?php echo $o['mes'] !== null ? (int) $o['mes'] : '' ?>"
                data-valor-orcamentado="<?php echo (float) $o['valor_orcamentado'] ?>">
                <td class="adm-fw-600"><?php echo htmlspecialchars($o['account_codigo'] . ' - ' . $o['account_nome']) ?></td>
                <td>
                    <?php if ($o['mes'] === null): ?>
                    <span class="adm-badge adm-badge--blue">Anual</span>
                    <?php else: ?>
                    <?php echo htmlspecialchars($mesesLabels[$o['mes']] ?? (string) $o['mes']) ?>
                    <?php endif; ?>
                </td>
                <td><?php echo number_format((float) $o['valor_orcamentado'], 2, ',', '.') ?></td>
                <td>
                    <div class="adm-actions">
                        <button class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" type="button" title="Editar" onclick="editarOrcamento(this.closest('tr'))">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                            </svg>
                        </button>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" type="button" title="Eliminar" style="color:var(--adm-red)" onclick="eliminarOrcamento(this.closest('tr'))">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
                            </svg>
                        </button>
                    </div>
                </td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="adm-empty">
        <p class="adm-empty-title">Nenhum orçamento registado para este ano fiscal</p>
    </div>
    <?php endif; ?>
</div>

<div class="adm-card">
    <div class="adm-card-header"><h2 class="adm-card-title" id="orcFormTitle">Novo Orçamento</h2></div>
    <div class="adm-card-body">
        <input type="hidden" id="orc-id" value="0">
        <div class="adm-form-row">
            <div class="adm-form-group">
                <label class="adm-label" for="orc-conta">Conta <span style="color:var(--adm-red)">*</span></label>
                <select class="adm-select" id="orc-conta">
                    <option value="">Seleciona uma conta</option>
                    <?php foreach ($contas as $c): ?>
                    <option value="<?php echo $c['id'] ?>"><?php echo htmlspecialchars($c['codigo'] . ' - ' . $c['nome']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="orc-mes">Período</label>
                <select class="adm-select" id="orc-mes">
                    <option value="0">Anual (ano completo)</option>
                    <?php foreach ($mesesLabels as $num => $label): ?>
                    <option value="<?php echo $num ?>"><?php echo $label ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="orc-valor">Valor Orçamentado <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="number" id="orc-valor" min="0" step="0.01" placeholder="0.00">
            </div>
        </div>
        <div style="display:flex;gap:var(--adm-sp-3)">
            <button class="adm-btn adm-btn-primary" id="orcBtnSave" type="button" onclick="guardarOrcamento()">Criar Orçamento</button>
            <button class="adm-btn adm-btn-outline" id="orcBtnCancel" type="button" onclick="cancelarEdicaoOrcamento()" style="display:none">Cancelar</button>
        </div>
    </div>
</div>

<script>
const CSRF = '<?php echo $csrf ?>';
const ANO_FISCAL_ID = <?php echo $anoFiscalId ?>;

function aplicarFiltro() {
    const ano = document.getElementById('fAno').value;
    const mes = document.getElementById('fMes').value;
    const params = new URLSearchParams();
    if (ano) params.set('ano', ano);
    if (mes && mes !== '0') params.set('mes', mes);
    location.href = '?' + params.toString();
}

function filterTable() {
    const q    = document.getElementById('orcSearch').value.toLowerCase();
    const rows = document.querySelectorAll('#orcTable tbody tr');
    let vis = 0;
    rows.forEach(row => {
        const show = !q || row.textContent.toLowerCase().includes(q);
        row.style.display = show ? '' : 'none';
        if (show) vis++;
    });
    const countEl = document.getElementById('orcCount');
    if (countEl) countEl.textContent = vis + ' orçamento' + (vis !== 1 ? 's' : '');
}

async function postJSON(url, payload) {
    try {
        const res  = await fetch(url, {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            showToast(data.msg || 'Guardado com sucesso.');
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}

function editarOrcamento(tr) {
    const d = tr.dataset;
    document.getElementById('orc-id').value = d.id;

    const elConta = document.getElementById('orc-conta');
    elConta.value = d.chartAccountId;
    elConta.disabled = true;

    const elMes = document.getElementById('orc-mes');
    elMes.value = d.mes === '' ? '0' : d.mes;
    elMes.disabled = true;

    document.getElementById('orc-valor').value = d.valorOrcamentado;

    document.getElementById('orcFormTitle').textContent = 'Editar Orçamento';
    document.getElementById('orcBtnSave').textContent = 'Guardar Alterações';
    document.getElementById('orcBtnCancel').style.display = '';

    document.getElementById('orcFormTitle').scrollIntoView({behavior: 'smooth', block: 'center'});
}

function cancelarEdicaoOrcamento() {
    document.getElementById('orc-id').value = '0';

    const elConta = document.getElementById('orc-conta');
    elConta.value = '';
    elConta.disabled = false;

    const elMes = document.getElementById('orc-mes');
    elMes.value = '0';
    elMes.disabled = false;

    document.getElementById('orc-valor').value = '';

    document.getElementById('orcFormTitle').textContent = 'Novo Orçamento';
    document.getElementById('orcBtnSave').textContent = 'Criar Orçamento';
    document.getElementById('orcBtnCancel').style.display = 'none';
}

function guardarOrcamento() {
    const id    = Number(document.getElementById('orc-id').value || 0);
    const valor = Number(document.getElementById('orc-valor').value);

    if (document.getElementById('orc-valor').value === '' || isNaN(valor) || valor < 0) {
        showToast('O valor orçamentado é obrigatório.', 'error');
        return;
    }

    const payload = { id, valor_orcamentado: valor, csrf: CSRF };

    if (!id) {
        const conta = document.getElementById('orc-conta').value;
        if (!conta) {
            showToast('A conta é obrigatória.', 'error');
            return;
        }
        payload.chart_account_id = Number(conta);
        payload.fiscal_year_id = ANO_FISCAL_ID;

        const mes = document.getElementById('orc-mes').value;
        if (mes && mes !== '0') payload.mes = Number(mes);
    }

    postJSON('/nexora/api/contab_orcamento_save', payload);
}

function eliminarOrcamento(tr) {
    const id   = Number(tr.dataset.id);
    const conta = tr.querySelector('td').textContent.trim();
    openConfirm(
        'Eliminar orçamento',
        'Eliminar o orçamento de "' + conta + '"? Esta ação não pode ser revertida.',
        () => postJSON('/nexora/api/contab_orcamento_remover', { id, csrf: CSRF })
    );
}
</script>

<?php endif; ?>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
