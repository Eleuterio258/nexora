<?php

    $periodos = $app->nexora->call('GET', '/api/contabilidade/fiscal-periods')['body'] ?? [];
    $diarios  = $app->nexora->call('GET', '/api/contabilidade/journals')['body'] ?? [];
    $ativos   = $app->nexora->call('GET', '/api/contabilidade/fixed-assets', null, ['estado' => 'ativo'])['body'] ?? [];
    $amortizacoes = $app->nexora->call('GET', '/api/contabilidade/depreciation')['body'] ?? [];

    $mesesLabels = [
        1 => 'Janeiro', 2 => 'Fevereiro', 3 => 'Março', 4 => 'Abril',
        5 => 'Maio', 6 => 'Junho', 7 => 'Julho', 8 => 'Agosto',
        9 => 'Setembro', 10 => 'Outubro', 11 => 'Novembro', 12 => 'Dezembro',
    ];

    $periodosAbertos = array_values(array_filter($periodos, static fn($p) => $p['status'] === 'aberto'));
    $periodoLabels = [];
    foreach ($periodos as $p) {
        $periodoLabels[$p['id']] = ($mesesLabels[$p['mes']] ?? $p['mes']) . '/' . $p['ano'];
    }

    $ativoLabels = [];
    foreach ($ativos as $a) {
        $ativoLabels[$a['id']] = $a['codigo'] . ' - ' . $a['nome'];
    }

    $statusBadges = [
        'pendente'   => ['adm-badge--yellow', 'Pendente'],
        'processado' => ['adm-badge--green', 'Processado'],
        'cancelado'  => ['adm-badge--gray', 'Cancelado'],
    ];

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Amortizações';
    $activePage = 'contab_amortizacoes';
    $breadcrumb = [['Admin', '/nexora/'], ['Contabilidade', ''], ['Amortizações', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Amortizações</h1>
</div>

<div id="formMsg"></div>

<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Processar Amortizações</h2></div>
    <div class="adm-card-body">
        <p class="adm-text-muted adm-mb-2">
            Gera um lançamento consolidado de amortização para todos os ativos fixos ativos que ainda não têm uma
            amortização processada no período selecionado.
        </p>
        <div class="adm-form-row">
            <div class="adm-form-group">
                <label class="adm-label" for="pa-periodo">Período Fiscal <span style="color:var(--adm-red)">*</span></label>
                <select class="adm-select" id="pa-periodo">
                    <option value="">Seleciona um período</option>
                    <?php foreach ($periodosAbertos as $p): ?>
                    <option value="<?php echo $p['id'] ?>"><?php echo htmlspecialchars(($mesesLabels[$p['mes']] ?? $p['mes']) . '/' . $p['ano']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="pa-diario">Diário <span style="color:var(--adm-red)">*</span></label>
                <select class="adm-select" id="pa-diario">
                    <option value="">Seleciona um diário</option>
                    <?php foreach ($diarios as $d): ?>
                    <option value="<?php echo $d['id'] ?>"><?php echo htmlspecialchars($d['codigo'] . ' - ' . $d['nome']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
        </div>
        <button class="adm-btn adm-btn-primary" id="btnProcessar" type="button" onclick="processarAmortizacoes()">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polygon points="5 3 19 12 5 21 5 3"/>
            </svg>
            Processar Amortizações
        </button>
    </div>
</div>

<div class="adm-card">
    <div class="adm-filter-bar">
        <select class="adm-select" id="amPeriodo" onchange="filterTable()" style="width:160px">
            <option value="">Todos os períodos</option>
            <?php foreach ($periodos as $p): ?>
            <option value="<?php echo $p['id'] ?>"><?php echo htmlspecialchars(($mesesLabels[$p['mes']] ?? $p['mes']) . '/' . $p['ano']) ?></option>
            <?php endforeach; ?>
        </select>
        <select class="adm-select" id="amStatus" onchange="filterTable()" style="width:160px">
            <option value="">Todos os estados</option>
            <?php foreach ($statusBadges as $key => [$cls, $label]): ?>
            <option value="<?php echo $key ?>"><?php echo $label ?></option>
            <?php endforeach; ?>
        </select>
        <span class="adm-filter-count" id="amCount"><?php echo count($amortizacoes) ?> amortizações</span>
    </div>

    <?php if ($amortizacoes): ?>
    <div class="adm-table-wrap">
        <table class="adm-table" id="amTable">
            <thead>
                <tr>
                    <th>Ativo Fixo</th>
                    <th>Período</th>
                    <th>Parcela</th>
                    <th>Valor</th>
                    <th>Estado</th>
                    <th>Lançamento</th>
                    <th>Ações</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($amortizacoes as $am):
                    $status = $statusBadges[$am['status']] ?? ['adm-badge--gray', $am['status']];
            ?>
            <tr data-periodo="<?php echo (int) $am['fiscal_period_id'] ?>" data-status="<?php echo htmlspecialchars($am['status']) ?>">
                <td class="adm-fw-600"><?php echo htmlspecialchars($ativoLabels[$am['fixed_asset_id']] ?? ('#' . $am['fixed_asset_id'])) ?></td>
                <td class="adm-text-muted"><?php echo htmlspecialchars($periodoLabels[$am['fiscal_period_id']] ?? ('#' . $am['fiscal_period_id'])) ?></td>
                <td>#<?php echo (int) $am['numero_parcela'] ?></td>
                <td class="adm-fw-600"><?php echo number_format((float) $am['valor_amortizacao'], 2, ',', '.') ?></td>
                <td><span class="adm-badge <?php echo $status[0] ?>"><?php echo $status[1] ?></span></td>
                <td>
                    <?php if (! empty($am['journal_entry_id'])): ?>
                    <a href="<?php echo htmlspecialchars($app->routes->path('contab_lancamento', ['id' => $am['journal_entry_id']])) ?>">Ver lançamento</a>
                    <?php else: ?>
                    <span class="adm-text-muted">—</span>
                    <?php endif; ?>
                </td>
                <td>
                    <?php if ($am['status'] === 'processado'): ?>
                    <div class="adm-actions">
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-red)" onclick="cancelarAmortizacao(<?php echo (int) $am['id'] ?>)">Cancelar</button>
                    </div>
                    <?php else: ?>
                    <span class="adm-text-muted">—</span>
                    <?php endif; ?>
                </td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="adm-empty">
        <p class="adm-empty-title">Nenhuma amortização registada</p>
    </div>
    <?php endif; ?>
</div>

<script>
const CSRF = '<?php echo $csrf ?>';

function filterTable() {
    const periodo = document.getElementById('amPeriodo').value;
    const status  = document.getElementById('amStatus').value;
    const rows    = document.querySelectorAll('#amTable tbody tr');
    let vis = 0;
    rows.forEach(row => {
        const per  = row.dataset.periodo;
        const st   = row.dataset.status;
        const show = (!periodo || per === periodo) && (!status || st === status);
        row.style.display = show ? '' : 'none';
        if (show) vis++;
    });
    const countEl = document.getElementById('amCount');
    if (countEl) countEl.textContent = vis + ' amortizaç' + (vis !== 1 ? 'ões' : 'ão');
}

async function processarAmortizacoes() {
    const periodoId = document.getElementById('pa-periodo').value;
    const diarioId  = document.getElementById('pa-diario').value;

    if (!periodoId || !diarioId) {
        showToast('O período fiscal e o diário são obrigatórios.', 'error');
        return;
    }

    const btn = document.getElementById('btnProcessar');
    btn.disabled = true;

    try {
        const res  = await fetch('/nexora/api/contab_amortizacao_processar', {
            method: 'POST', headers: {'Content-Type':'application/json'},
            body: JSON.stringify({ fiscal_period_id: Number(periodoId), accounting_journal_id: Number(diarioId), csrf: CSRF })
        });
        const data = await res.json();
        if (data.ok) {
            showToast(data.msg || ('Amortizações processadas: ' + (data.ativos_processados ?? 0)));
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro', 'error');
            btn.disabled = false;
        }
    } catch {
        showToast('Erro de ligação', 'error');
        btn.disabled = false;
    }
}

function cancelarAmortizacao(id) {
    openConfirm(
        'Cancelar amortização',
        'Cancelar esta amortização? O lançamento de amortização associado será estornado e todas as parcelas do mesmo lote serão marcadas como canceladas.',
        async () => {
            try {
                const res  = await fetch('/nexora/api/contab_amortizacao_cancelar', {
                    method: 'POST', headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({ id, csrf: CSRF })
                });
                const data = await res.json();
                if (data.ok) {
                    showToast(data.msg || 'Amortização cancelada com sucesso.');
                    setTimeout(() => location.reload(), 700);
                } else {
                    showToast(data.erro || 'Erro', 'error');
                }
            } catch { showToast('Erro de ligação', 'error'); }
        }
    );
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
