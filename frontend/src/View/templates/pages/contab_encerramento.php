<?php

    $anosFiscais = $app->nexora->call('GET', '/api/contabilidade/fiscal-years')['body'] ?? [];

    $anoFiscalId = $app->request->queryInt('ano', 0);
    if ($anoFiscalId <= 0 && $anosFiscais) {
        $anoFiscalId = (int) $anosFiscais[0]['id'];
        foreach ($anosFiscais as $a) {
            if (($a['status'] ?? '') === 'aberto') {
                $anoFiscalId = (int) $a['id'];
                break;
            }
        }
    }

    $periodos = [];
    if ($anoFiscalId > 0) {
        $periodos = $app->nexora->call('GET', '/api/contabilidade/fiscal-periods', null, ['fiscal_year_id' => $anoFiscalId])['body'] ?? [];
    }

    $mesesLabels = [
        1 => 'Janeiro', 2 => 'Fevereiro', 3 => 'Março', 4 => 'Abril',
        5 => 'Maio', 6 => 'Junho', 7 => 'Julho', 8 => 'Agosto',
        9 => 'Setembro', 10 => 'Outubro', 11 => 'Novembro', 12 => 'Dezembro',
    ];

    $checkLabels = [
        'lancamentos_balanceados' => 'Lançamentos balanceados (débito = crédito)',
        'sem_rascunhos_pendentes' => 'Sem lançamentos em rascunho',
        'amortizacoes_processadas' => 'Amortizações do período processadas',
    ];

    $statusLabels = [
        'em_curso'  => ['Em Curso', 'yellow'],
        'verificado' => ['Verificado', 'blue'],
        'encerrado' => ['Encerrado', 'green'],
        'reaberto'  => ['Reaberto', 'red'],
    ];

    $encerramentos = $app->nexora->call('GET', '/api/contabilidade/period-closings')['body'] ?? [];
    $encerramentoPorPeriodo = [];
    foreach ($encerramentos as $pc) {
        $fpid = (int) $pc['fiscal_period_id'];
        if (! isset($encerramentoPorPeriodo[$fpid]) || (int) $pc['id'] > (int) $encerramentoPorPeriodo[$fpid]['id']) {
            $encerramentoPorPeriodo[$fpid] = $pc;
        }
    }

    $checksPorEncerramento = [];
    foreach ($periodos as $p) {
        $fpid = (int) $p['id'];
        if (isset($encerramentoPorPeriodo[$fpid])) {
            $closingId = (int) $encerramentoPorPeriodo[$fpid]['id'];
            $detail = $app->nexora->call('GET', "/api/contabilidade/period-closings/{$closingId}")['body'] ?? [];
            $checksPorEncerramento[$closingId] = $detail['checks'] ?? [];
        }
    }

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Encerramento de Período';
    $activePage = 'contab_encerramento';
    $breadcrumb = [['Admin', '/nexora/'], ['Contabilidade', ''], ['Encerramento de Período', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Encerramento de Período</h1>
</div>

<?php if (! $anosFiscais): ?>
<div class="adm-card adm-mb-6">
    <div class="adm-empty">
        <p class="adm-empty-title">Nenhum ano fiscal criado</p>
        <p class="adm-empty-sub">Crie um ano fiscal e os respectivos períodos antes de iniciar um encerramento.</p>
        <a class="adm-btn adm-btn-primary adm-mt-4" href="<?php echo htmlspecialchars($app->routes->path('contab_periodos')) ?>">Anos e Períodos Fiscais</a>
    </div>
</div>
<?php else: ?>

<div class="adm-card adm-mb-6">
    <div class="adm-card-body">
        <div class="adm-filter-bar">
            <div class="adm-form-group">
                <label class="adm-label" for="fAno">Ano Fiscal</label>
                <select class="adm-select" id="fAno" onchange="aplicarFiltro()">
                    <?php foreach ($anosFiscais as $a): ?>
                    <option value="<?php echo (int) $a['id'] ?>" <?php echo $anoFiscalId === (int) $a['id'] ? 'selected' : '' ?>>
                        Ano Fiscal <?php echo (int) $a['ano'] ?> (<?php echo $a['status'] === 'aberto' ? 'Aberto' : 'Fechado' ?>)
                    </option>
                    <?php endforeach; ?>
                </select>
            </div>
        </div>
    </div>
</div>

<div class="adm-mb-6">
    <?php if ($periodos): ?>
        <?php foreach ($periodos as $p): ?>
        <?php
            $fpid     = (int) $p['id'];
            $mesLabel = $mesesLabels[$p['mes']] ?? (string) $p['mes'];
            $pc       = $encerramentoPorPeriodo[$fpid] ?? null;
            $checks   = $pc ? ($checksPorEncerramento[(int) $pc['id']] ?? []) : [];
            $allPassed = $checks && array_reduce($checks, fn($carry, $c) => $carry && (bool) $c['passou'], true);
        ?>
        <details class="adm-card adm-mb-6">
            <summary class="adm-card-header" style="cursor:pointer">
                <h2 class="adm-card-title">
                    <?php echo htmlspecialchars($mesLabel) ?> / <?php echo (int) $p['ano'] ?>
                    <span class="adm-badge <?php echo $p['status'] === 'aberto' ? 'adm-badge--green' : 'adm-badge--gray' ?>">
                        <?php echo $p['status'] === 'aberto' ? 'Período Aberto' : 'Período Fechado' ?>
                    </span>
                    <?php if ($pc): ?>
                    <?php [$label, $color] = $statusLabels[$pc['status']] ?? [$pc['status'], 'gray']; ?>
                    <span class="adm-badge adm-badge--<?php echo $color ?>">Encerramento: <?php echo htmlspecialchars($label) ?></span>
                    <?php else: ?>
                    <span class="adm-badge adm-badge--gray">Sem processo de encerramento</span>
                    <?php endif; ?>
                </h2>
            </summary>
            <div class="adm-card-body">
                <?php if (! $pc): ?>
                    <?php if ($p['status'] === 'aberto'): ?>
                    <p class="adm-text-muted adm-mb-4">Nenhum processo de encerramento foi iniciado para este período.</p>
                    <div class="adm-actions">
                        <button class="adm-btn adm-btn-primary" type="button"
                                onclick="iniciarEncerramento(<?php echo $fpid ?>, '<?php echo htmlspecialchars($mesLabel . '/' . $p['ano']) ?>')">Iniciar Processo de Encerramento</button>
                    </div>
                    <?php else: ?>
                    <p class="adm-text-muted">Este período foi fechado directamente, sem um processo de encerramento.</p>
                    <?php endif; ?>
                <?php else: ?>
                    <div class="adm-form-row-3 adm-mb-4">
                        <div class="adm-detail-pair">
                            <span class="adm-detail-pair-label">Iniciado em</span>
                            <span class="adm-detail-pair-value"><?php echo $pc['iniciado_em'] ? date('d/m/Y H:i', strtotime($pc['iniciado_em'])) : '—' ?></span>
                        </div>
                        <div class="adm-detail-pair">
                            <span class="adm-detail-pair-label">Encerrado em</span>
                            <span class="adm-detail-pair-value"><?php echo $pc['encerrado_em'] ? date('d/m/Y H:i', strtotime($pc['encerrado_em'])) : '—' ?></span>
                        </div>
                        <?php if (! empty($pc['justificacao_reabertura'])): ?>
                        <div class="adm-detail-pair">
                            <span class="adm-detail-pair-label">Justificação de Reabertura</span>
                            <span class="adm-detail-pair-value"><?php echo htmlspecialchars($pc['justificacao_reabertura']) ?></span>
                        </div>
                        <?php endif; ?>
                    </div>

                    <?php if ($checks): ?>
                    <div class="adm-table-wrap adm-mb-4">
                        <table class="adm-table">
                            <thead>
                                <tr><th>Verificação</th><th>Resultado</th><th>Detalhe</th></tr>
                            </thead>
                            <tbody>
                            <?php foreach ($checks as $c): ?>
                            <tr>
                                <td class="adm-fw-600"><?php echo htmlspecialchars($checkLabels[$c['verificacao']] ?? $c['verificacao']) ?></td>
                                <td>
                                    <span class="adm-badge <?php echo $c['passou'] ? 'adm-badge--green' : 'adm-badge--red' ?>">
                                        <?php echo $c['passou'] ? 'Passou' : 'Falhou' ?>
                                    </span>
                                </td>
                                <td class="adm-text-muted"><?php echo htmlspecialchars($c['detalhe'] ?? '') ?></td>
                            </tr>
                            <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                    <?php elseif ($pc['status'] !== 'encerrado' && $pc['status'] !== 'reaberto'): ?>
                    <div class="adm-empty adm-mb-4">
                        <p class="adm-empty-title">Ainda sem verificações</p>
                        <p class="adm-empty-sub">Execute as verificações automáticas para validar este período.</p>
                    </div>
                    <?php endif; ?>

                    <div class="adm-actions">
                        <?php if ($pc['status'] === 'em_curso' || $pc['status'] === 'verificado'): ?>
                        <button class="adm-btn adm-btn-outline" type="button"
                                onclick="executarVerificacoes(<?php echo (int) $pc['id'] ?>)">Executar Verificações</button>
                        <?php endif; ?>

                        <?php if ($pc['status'] === 'verificado' && $allPassed): ?>
                        <button class="adm-btn adm-btn-primary" type="button"
                                onclick="confirmarEncerramento(<?php echo (int) $pc['id'] ?>, '<?php echo htmlspecialchars($mesLabel . '/' . $p['ano']) ?>')">Confirmar Encerramento</button>
                        <?php endif; ?>

                        <?php if ($pc['status'] === 'encerrado'): ?>
                        <button class="adm-btn adm-btn-outline" type="button" style="color:var(--adm-red)"
                                onclick="abrirReabrir(<?php echo (int) $pc['id'] ?>, '<?php echo htmlspecialchars($mesLabel . '/' . $p['ano']) ?>')">Reabrir Encerramento</button>
                        <?php endif; ?>

                        <?php if ($pc['status'] === 'reaberto' && $p['status'] === 'aberto'): ?>
                        <button class="adm-btn adm-btn-primary" type="button"
                                onclick="iniciarEncerramento(<?php echo $fpid ?>, '<?php echo htmlspecialchars($mesLabel . '/' . $p['ano']) ?>')">Iniciar Novo Processo de Encerramento</button>
                        <?php endif; ?>
                    </div>
                <?php endif; ?>
            </div>
        </details>
        <?php endforeach; ?>
    <?php else: ?>
    <div class="adm-card adm-mb-6">
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum período fiscal encontrado</p>
            <p class="adm-empty-sub">O ano fiscal seleccionado não tem períodos mensais.</p>
        </div>
    </div>
    <?php endif; ?>
</div>

<div class="adm-card adm-mb-6" id="reabrirCard" style="display:none">
    <div class="adm-card-header"><h2 class="adm-card-title">Reabrir Encerramento — <span id="rbLabel"></span></h2></div>
    <div class="adm-card-body">
        <input type="hidden" id="rb-id" value="0">
        <div class="adm-form-group">
            <label class="adm-label" for="rb-justificacao">Justificação <span style="color:var(--adm-red)">*</span></label>
            <textarea class="adm-input" id="rb-justificacao" rows="3" placeholder="Indique o motivo da reabertura deste período"></textarea>
        </div>
        <div style="display:flex;gap:var(--adm-sp-3)">
            <button class="adm-btn adm-btn-primary" type="button" onclick="confirmarReabrir()">Confirmar Reabertura</button>
            <button class="adm-btn adm-btn-outline" type="button" onclick="cancelarReabrir()">Cancelar</button>
        </div>
    </div>
</div>

<?php endif; ?>

<script>
const CSRF = '<?php echo $csrf ?>';

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

function aplicarFiltro() {
    const params = new URLSearchParams();
    params.set('ano', document.getElementById('fAno').value);
    location.href = '?' + params.toString();
}

function iniciarEncerramento(fiscalPeriodId, label) {
    openConfirm(
        'Iniciar encerramento',
        'Iniciar o processo de encerramento do período ' + label + '?',
        () => postJSON('/nexora/api/contab_encerramento_iniciar', { fiscal_period_id: fiscalPeriodId, csrf: CSRF })
    );
}

function executarVerificacoes(id) {
    postJSON('/nexora/api/contab_encerramento_verificar', { id, csrf: CSRF });
}

function confirmarEncerramento(id, label) {
    openConfirm(
        'Confirmar encerramento',
        'Confirmar o encerramento do período ' + label + '? O período será fechado e deixará de aceitar novos lançamentos.',
        () => postJSON('/nexora/api/contab_encerramento_confirmar', { id, csrf: CSRF })
    );
}

function abrirReabrir(id, label) {
    document.getElementById('rb-id').value = id;
    document.getElementById('rbLabel').textContent = label;
    document.getElementById('rb-justificacao').value = '';
    const card = document.getElementById('reabrirCard');
    card.style.display = '';
    card.scrollIntoView({behavior: 'smooth', block: 'center'});
}

function cancelarReabrir() {
    document.getElementById('reabrirCard').style.display = 'none';
}

function confirmarReabrir() {
    const id = Number(document.getElementById('rb-id').value);
    const justificacao = document.getElementById('rb-justificacao').value.trim();
    if (! justificacao) { showToast('A justificação é obrigatória.', 'error'); return; }

    postJSON('/nexora/api/contab_encerramento_reabrir', { id, justificacao, csrf: CSRF });
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
