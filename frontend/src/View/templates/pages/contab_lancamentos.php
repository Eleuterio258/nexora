<?php

    $diarios = $app->nexora->call('GET', '/api/contabilidade/journals')['body'] ?? [];
    $periodos = $app->nexora->call('GET', '/api/contabilidade/fiscal-periods')['body'] ?? [];
    $contas = $app->nexora->call('GET', '/api/contabilidade/accounts', null, ['aceita_lancamento' => 'true', 'ativo' => 'true'])['body'] ?? [];
    $lancamentos = $app->nexora->call('GET', '/api/contabilidade/journal-entries', null, ['limit' => 100])['body'] ?? [];

    $mesesLabels = [
        1 => 'Janeiro', 2 => 'Fevereiro', 3 => 'Março', 4 => 'Abril',
        5 => 'Maio', 6 => 'Junho', 7 => 'Julho', 8 => 'Agosto',
        9 => 'Setembro', 10 => 'Outubro', 11 => 'Novembro', 12 => 'Dezembro',
    ];

    $diarioNomes = array_column($diarios, 'codigo', 'id');

    $periodosAbertos = array_values(array_filter($periodos, static fn($p) => $p['status'] === 'aberto'));
    $periodoLabels = [];
    foreach ($periodos as $p) {
        $periodoLabels[$p['id']] = ($mesesLabels[$p['mes']] ?? $p['mes']) . '/' . $p['ano'];
    }

    $estadoBadges = [
        'publicado' => ['adm-badge--green', 'Publicado'],
        'anulado'   => ['adm-badge--gray', 'Anulado'],
    ];

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Lançamentos Contabilísticos';
    $activePage = 'contab_lancamentos';
    $breadcrumb = [['Admin', '/nexora/'], ['Contabilidade', ''], ['Lançamentos', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Lançamentos Contabilísticos</h1>
</div>

<div id="formMsg"></div>

<div class="adm-card adm-mb-6">
    <div class="adm-filter-bar">
        <div class="adm-search-wrap">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
            </svg>
            <input class="adm-input" type="search" id="lancSearch" placeholder="Pesquisar lançamentos…" oninput="filterTable()">
        </div>
        <select class="adm-select" id="lancEstado" onchange="filterTable()" style="width:160px">
            <option value="">Todos os estados</option>
            <?php foreach ($estadoBadges as $key => [$cls, $label]): ?>
            <option value="<?php echo $key ?>"><?php echo $label ?></option>
            <?php endforeach; ?>
        </select>
        <select class="adm-select" id="lancDiario" onchange="filterTable()" style="width:180px">
            <option value="">Todos os diários</option>
            <?php foreach ($diarios as $d): ?>
            <option value="<?php echo $d['id'] ?>"><?php echo htmlspecialchars($d['codigo'] . ' - ' . $d['nome']) ?></option>
            <?php endforeach; ?>
        </select>
        <span class="adm-filter-count" id="lancCount"><?php echo count($lancamentos) ?> lançamentos</span>
    </div>

    <?php if ($lancamentos): ?>
    <div class="adm-table-wrap">
        <table class="adm-table" id="lancTable">
            <thead>
                <tr>
                    <th>Número</th>
                    <th>Diário</th>
                    <th>Período</th>
                    <th>Data</th>
                    <th>Descrição</th>
                    <th>Débito</th>
                    <th>Crédito</th>
                    <th>Estado</th>
                    <th>Ações</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($lancamentos as $l):
                    $estadoBadge = $estadoBadges[$l['status']] ?? ['adm-badge--gray', $l['status']];
            ?>
            <tr data-estado="<?php echo htmlspecialchars($l['status']) ?>" data-diario="<?php echo (int) $l['accounting_journal_id'] ?>">
                <td class="adm-fw-600"><?php echo htmlspecialchars($l['numero']) ?></td>
                <td><?php echo htmlspecialchars($diarioNomes[$l['accounting_journal_id']] ?? ('#' . $l['accounting_journal_id'])) ?></td>
                <td class="adm-text-muted"><?php echo htmlspecialchars($periodoLabels[$l['fiscal_period_id']] ?? ('#' . $l['fiscal_period_id'])) ?></td>
                <td class="adm-text-muted"><?php echo date('d/m/Y', strtotime($l['entry_date'])) ?></td>
                <td><?php echo htmlspecialchars($l['descricao']) ?></td>
                <td class="adm-fw-600"><?php echo number_format((float) $l['total_debito'], 2, ',', '.') ?></td>
                <td class="adm-fw-600"><?php echo number_format((float) $l['total_credito'], 2, ',', '.') ?></td>
                <td><span class="adm-badge <?php echo $estadoBadge[0] ?>"><?php echo $estadoBadge[1] ?></span></td>
                <td>
                    <div class="adm-actions">
                        <a href="<?php echo htmlspecialchars($app->routes->path('contab_lancamento', ['id' => $l['id']])) ?>" class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Ver">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
                            </svg>
                        </a>
                    </div>
                </td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="adm-empty">
        <p class="adm-empty-title">Nenhum lançamento registado</p>
    </div>
    <?php endif; ?>
</div>

<div class="adm-card">
    <div class="adm-card-header"><h2 class="adm-card-title">Novo Lançamento</h2></div>
    <div class="adm-card-body">
        <div class="adm-form-row-3">
            <div class="adm-form-group">
                <label class="adm-label" for="f-diario">Diário <span style="color:var(--adm-red)">*</span></label>
                <select class="adm-select" id="f-diario">
                    <option value="">Seleciona um diário</option>
                    <?php foreach ($diarios as $d): ?>
                    <option value="<?php echo $d['id'] ?>"><?php echo htmlspecialchars($d['codigo'] . ' - ' . $d['nome']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="f-periodo">Período Fiscal <span style="color:var(--adm-red)">*</span></label>
                <select class="adm-select" id="f-periodo">
                    <option value="">Seleciona um período</option>
                    <?php foreach ($periodosAbertos as $p): ?>
                    <option value="<?php echo $p['id'] ?>"><?php echo htmlspecialchars(($mesesLabels[$p['mes']] ?? $p['mes']) . '/' . $p['ano']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="f-data">Data <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="date" id="f-data" value="<?php echo date('Y-m-d') ?>">
            </div>
        </div>
        <div class="adm-form-row">
            <div class="adm-form-group">
                <label class="adm-label" for="f-descricao">Descrição <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="text" id="f-descricao" maxlength="255">
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="f-moeda">Moeda</label>
                <select class="adm-select" id="f-moeda">
                    <?php foreach (['MZN', 'USD', 'EUR', 'ZAR'] as $m): ?>
                    <option value="<?php echo $m ?>" <?php echo $m === 'MZN' ? 'selected' : '' ?>><?php echo $m ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
        </div>

        <h3 class="adm-fw-600 adm-mb-2" style="margin-top:var(--adm-sp-5)">Linhas</h3>
        <div class="adm-table-wrap adm-mb-2">
            <table class="adm-table">
                <thead>
                    <tr>
                        <th>Conta</th>
                        <th>Descrição</th>
                        <th style="width:140px">Débito</th>
                        <th style="width:140px">Crédito</th>
                        <th style="width:50px"></th>
                    </tr>
                </thead>
                <tbody id="linhasBody"></tbody>
            </table>
        </div>
        <button class="adm-btn adm-btn-outline adm-btn-sm" type="button" onclick="addLinha()">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            Adicionar Linha
        </button>

        <div class="adm-mb-6" style="margin-top:var(--adm-sp-4);display:flex;gap:var(--adm-sp-5)">
            <span>Débito: <strong id="totalDebito">0.00</strong></span>
            <span>Crédito: <strong id="totalCredito">0.00</strong></span>
            <span>Diferença: <strong id="totalDiferenca">0.00</strong></span>
        </div>

        <button class="adm-btn adm-btn-primary" id="btnSave" type="button" onclick="criarLancamento()">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/>
                <polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/>
            </svg>
            Criar Lançamento
        </button>
    </div>
</div>

<template id="contaOptionsTpl">
    <option value="">Selecione...</option>
    <?php foreach ($contas as $c): ?>
    <option value="<?php echo $c['id'] ?>"><?php echo htmlspecialchars($c['codigo'] . ' - ' . $c['nome']) ?></option>
    <?php endforeach; ?>
</template>

<script>
const CSRF = '<?php echo $csrf ?>';

function filterTable() {
    const q      = document.getElementById('lancSearch').value.toLowerCase();
    const estado = document.getElementById('lancEstado').value;
    const diario = document.getElementById('lancDiario').value;
    const rows   = document.querySelectorAll('#lancTable tbody tr');
    let vis = 0;
    rows.forEach(row => {
        const txt   = row.textContent.toLowerCase();
        const est   = row.dataset.estado;
        const dia   = row.dataset.diario;
        const show  = (!q || txt.includes(q)) && (!estado || est === estado) && (!diario || dia === diario);
        row.style.display = show ? '' : 'none';
        if (show) vis++;
    });
    const countEl = document.getElementById('lancCount');
    if (countEl) countEl.textContent = vis + ' lançamento' + (vis !== 1 ? 's' : '');
}

function addLinha() {
    const tbody = document.getElementById('linhasBody');
    const tr = document.createElement('tr');

    const tdConta = document.createElement('td');
    const select = document.createElement('select');
    select.className = 'adm-select linha-conta';
    select.innerHTML = document.getElementById('contaOptionsTpl').innerHTML;
    tdConta.appendChild(select);

    const tdDescricao = document.createElement('td');
    const inputDescricao = document.createElement('input');
    inputDescricao.className = 'adm-input linha-descricao';
    inputDescricao.type = 'text';
    inputDescricao.maxLength = 255;
    tdDescricao.appendChild(inputDescricao);

    const tdDebit = document.createElement('td');
    const inputDebit = document.createElement('input');
    inputDebit.className = 'adm-input linha-debit';
    inputDebit.type = 'number';
    inputDebit.min = '0';
    inputDebit.step = '0.01';
    inputDebit.placeholder = '0.00';
    inputDebit.addEventListener('input', updateBalance);
    tdDebit.appendChild(inputDebit);

    const tdCredit = document.createElement('td');
    const inputCredit = document.createElement('input');
    inputCredit.className = 'adm-input linha-credit';
    inputCredit.type = 'number';
    inputCredit.min = '0';
    inputCredit.step = '0.01';
    inputCredit.placeholder = '0.00';
    inputCredit.addEventListener('input', updateBalance);
    tdCredit.appendChild(inputCredit);

    const tdRemove = document.createElement('td');
    const btnRemove = document.createElement('button');
    btnRemove.className = 'adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon';
    btnRemove.type = 'button';
    btnRemove.title = 'Remover';
    btnRemove.textContent = '✕';
    btnRemove.addEventListener('click', () => removeLinha(tr));
    tdRemove.appendChild(btnRemove);

    tr.append(tdConta, tdDescricao, tdDebit, tdCredit, tdRemove);
    tbody.appendChild(tr);
}

function removeLinha(tr) {
    const tbody = document.getElementById('linhasBody');
    if (tbody.rows.length <= 2) { showToast('O lançamento deve ter pelo menos duas linhas.', 'error'); return; }
    tr.remove();
    updateBalance();
}

function updateBalance() {
    let totalDebit = 0, totalCredit = 0;
    document.querySelectorAll('#linhasBody tr').forEach(tr => {
        totalDebit  += Number(tr.querySelector('.linha-debit').value || 0);
        totalCredit += Number(tr.querySelector('.linha-credit').value || 0);
    });
    document.getElementById('totalDebito').textContent  = totalDebit.toFixed(2);
    document.getElementById('totalCredito').textContent = totalCredit.toFixed(2);
    const diff = totalDebit - totalCredit;
    const diffEl = document.getElementById('totalDiferenca');
    diffEl.textContent = diff.toFixed(2);
    diffEl.style.color = Math.abs(diff) < 0.005 ? 'var(--adm-green-dark)' : 'var(--adm-red)';
}

async function criarLancamento() {
    const diarioId  = document.getElementById('f-diario').value;
    const periodoId = document.getElementById('f-periodo').value;
    const data      = document.getElementById('f-data').value;
    const descricao = document.getElementById('f-descricao').value.trim();

    if (!diarioId || !periodoId || !data || !descricao) {
        showToast('Diário, período, data e descrição são obrigatórios.', 'error');
        return;
    }

    const linhas = [];
    document.querySelectorAll('#linhasBody tr').forEach(tr => {
        const accountId = tr.querySelector('.linha-conta').value;
        const debit     = Number(tr.querySelector('.linha-debit').value || 0);
        const credit    = Number(tr.querySelector('.linha-credit').value || 0);
        if (!accountId && debit === 0 && credit === 0) return;
        linhas.push({
            account_id: Number(accountId),
            descricao: tr.querySelector('.linha-descricao').value.trim() || null,
            debit, credit
        });
    });

    if (linhas.length < 2) { showToast('O lançamento deve ter pelo menos duas linhas.', 'error'); return; }
    if (linhas.some(l => !l.account_id)) { showToast('Todas as linhas devem ter uma conta.', 'error'); return; }

    const totalDebit  = linhas.reduce((s, l) => s + l.debit, 0);
    const totalCredit = linhas.reduce((s, l) => s + l.credit, 0);
    if (Math.abs(totalDebit - totalCredit) > 0.005) { showToast('O lançamento não está balanceado.', 'error'); return; }

    const payload = {
        accounting_journal_id: Number(diarioId),
        fiscal_period_id: Number(periodoId),
        entry_date: data,
        descricao,
        moeda: document.getElementById('f-moeda').value,
        linhas,
        csrf: CSRF
    };

    const btn = document.getElementById('btnSave');
    btn.disabled = true;

    try {
        const res  = await fetch('/nexora/api/contab_lancamento_save', {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data2 = await res.json();
        if (data2.ok) {
            showToast(data2.msg || 'Lançamento criado com sucesso.');
            setTimeout(() => window.location.href = '/nexora/contabilidade/lancamento?id=' + data2.id, 700);
        } else {
            document.getElementById('formMsg').innerHTML = `<div class="adm-alert adm-alert--error">${data2.erro || 'Erro ao guardar.'}</div>`;
            btn.disabled = false;
        }
    } catch {
        document.getElementById('formMsg').innerHTML = '<div class="adm-alert adm-alert--error">Erro de ligação.</div>';
        btn.disabled = false;
    }
}

addLinha();
addLinha();
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
