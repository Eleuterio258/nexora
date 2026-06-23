<?php

    $anosFiscais = $app->nexora->call('GET', '/api/contabilidade/fiscal-years')['body'] ?? [];
    $periodos    = $app->nexora->call('GET', '/api/contabilidade/fiscal-periods')['body'] ?? [];

    $mesesLabels = [
        1 => 'Janeiro', 2 => 'Fevereiro', 3 => 'Março', 4 => 'Abril',
        5 => 'Maio', 6 => 'Junho', 7 => 'Julho', 8 => 'Agosto',
        9 => 'Setembro', 10 => 'Outubro', 11 => 'Novembro', 12 => 'Dezembro',
    ];

    $periodosPorAno = [];
    foreach ($periodos as $p) {
        $periodosPorAno[$p['fiscal_year_id'] ?? 0][] = $p;
    }

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Anos e Períodos Fiscais';
    $activePage = 'contab_periodos';
    $breadcrumb = [['Admin', '/nexora/'], ['Contabilidade', ''], ['Anos e Períodos Fiscais', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Anos e Períodos Fiscais</h1>
</div>

<div class="adm-mb-6">
    <?php if ($anosFiscais): ?>
        <?php foreach ($anosFiscais as $ano): ?>
        <details class="adm-card adm-mb-6">
            <summary class="adm-card-header" style="cursor:pointer">
                <h2 class="adm-card-title">
                    Ano Fiscal <?php echo (int) $ano['ano'] ?>
                    <span class="adm-badge <?php echo $ano['status'] === 'aberto' ? 'adm-badge--green' : 'adm-badge--gray' ?>">
                        <?php echo $ano['status'] === 'aberto' ? 'Aberto' : 'Fechado' ?>
                    </span>
                </h2>
                <span class="adm-text-muted adm-text-xs">
                    <?php echo date('d/m/Y', strtotime($ano['data_inicio'])) ?> — <?php echo date('d/m/Y', strtotime($ano['data_fim'])) ?>
                </span>
            </summary>
            <div class="adm-card-body">
                <?php $periodosAno = $periodosPorAno[$ano['id']] ?? []; ?>
                <?php if ($periodosAno): ?>
                <div class="adm-table-wrap adm-mb-6">
                    <table class="adm-table">
                        <thead>
                            <tr><th>Mês</th><th>Início</th><th>Fim</th><th>Estado</th><th>Ações</th></tr>
                        </thead>
                        <tbody>
                        <?php foreach ($periodosAno as $p): ?>
                        <tr>
                            <td class="adm-fw-600"><?php echo $mesesLabels[$p['mes']] ?? $p['mes'] ?></td>
                            <td class="adm-text-muted"><?php echo date('d/m/Y', strtotime($p['data_inicio'])) ?></td>
                            <td class="adm-text-muted"><?php echo date('d/m/Y', strtotime($p['data_fim'])) ?></td>
                            <td>
                                <span class="adm-badge <?php echo $p['status'] === 'aberto' ? 'adm-badge--green' : 'adm-badge--gray' ?>">
                                    <?php echo $p['status'] === 'aberto' ? 'Aberto' : 'Fechado' ?>
                                </span>
                            </td>
                            <td>
                                <div class="adm-actions">
                                    <?php if ($p['status'] === 'aberto'): ?>
                                    <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button"
                                            onclick="fecharPeriodo(<?php echo (int) $p['id'] ?>, '<?php echo htmlspecialchars(($mesesLabels[$p['mes']] ?? $p['mes']) . '/' . $ano['ano']) ?>')">Fechar</button>
                                    <?php else: ?>
                                    <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button"
                                            onclick="abrirPeriodo(<?php echo (int) $p['id'] ?>, '<?php echo htmlspecialchars(($mesesLabels[$p['mes']] ?? $p['mes']) . '/' . $ano['ano']) ?>')">Reabrir</button>
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
                    <p class="adm-empty-title">Nenhum período fiscal</p>
                </div>
                <?php endif; ?>

                <?php if ($ano['status'] === 'aberto'): ?>
                <div class="adm-actions">
                    <button class="adm-btn adm-btn-outline" type="button" style="color:var(--adm-red)"
                            onclick="fecharAno(<?php echo (int) $ano['id'] ?>, <?php echo (int) $ano['ano'] ?>)">Fechar Ano Fiscal</button>
                </div>
                <?php endif; ?>
            </div>
        </details>
        <?php endforeach; ?>
    <?php else: ?>
    <div class="adm-card adm-mb-6">
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum ano fiscal criado</p>
            <p class="adm-empty-sub">Crie um ano fiscal para gerar automaticamente os 12 períodos mensais.</p>
        </div>
    </div>
    <?php endif; ?>
</div>

<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Novo Ano Fiscal</h2></div>
    <div class="adm-card-body">
        <div class="adm-form-row-3">
            <div class="adm-form-group">
                <label class="adm-label" for="af-ano">Ano <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="number" id="af-ano" min="2000" max="2100" placeholder="ex: <?php echo date('Y') ?>">
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="af-inicio">Data Início <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="date" id="af-inicio">
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="af-fim">Data Fim <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="date" id="af-fim">
            </div>
        </div>
        <div style="display:flex;gap:var(--adm-sp-3)">
            <button class="adm-btn adm-btn-primary" type="button" onclick="criarAnoFiscal()">Criar Ano Fiscal</button>
        </div>
    </div>
</div>

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

function criarAnoFiscal() {
    const ano    = document.getElementById('af-ano').value;
    const inicio = document.getElementById('af-inicio').value;
    const fim    = document.getElementById('af-fim').value;

    if (!ano || !inicio || !fim) { showToast('Ano, data de início e data de fim são obrigatórios.', 'error'); return; }

    postJSON('/nexora/api/contab_ano_fiscal_save', {
        ano: Number(ano), data_inicio: inicio, data_fim: fim, csrf: CSRF
    });
}

function fecharAno(id, ano) {
    openConfirm(
        'Fechar ano fiscal',
        'Fechar o ano fiscal ' + ano + '? Todos os períodos têm de estar fechados.',
        () => postJSON('/nexora/api/contab_ano_fiscal_fechar', { id, csrf: CSRF })
    );
}

function fecharPeriodo(id, label) {
    openConfirm(
        'Fechar período fiscal',
        'Fechar o período de ' + label + '? Não será possível registar novos lançamentos neste período.',
        () => postJSON('/nexora/api/contab_periodo_fechar', { id, csrf: CSRF })
    );
}

function abrirPeriodo(id, label) {
    openConfirm(
        'Reabrir período fiscal',
        'Reabrir o período de ' + label + '? Voltará a permitir lançamentos neste período.',
        () => postJSON('/nexora/api/contab_periodo_abrir', { id, csrf: CSRF })
    );
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
