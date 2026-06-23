<?php

    $id = $app->request->queryInt('id', 0);
    if ($id <= 0) {
        header('Location: ' . $app->routes->path('contab_lancamentos'));
        exit;
    }

    $resp = $app->nexora->call('GET', "/api/contabilidade/journal-entries/$id");
    if ($resp['status'] !== 200) {
        header('Location: ' . $app->routes->path('contab_lancamentos'));
        exit;
    }
    $lancamento = $resp['body'] ?? [];
    $linhas     = $lancamento['linhas'] ?? [];

    $diarios = $app->nexora->call('GET', '/api/contabilidade/journals')['body'] ?? [];
    $periodos = $app->nexora->call('GET', '/api/contabilidade/fiscal-periods')['body'] ?? [];
    $utilizadores = $app->nexora->call('GET', '/api/auth/utilizadores', null, ['limit' => 200])['body']['data'] ?? [];

    $mesesLabels = [
        1 => 'Janeiro', 2 => 'Fevereiro', 3 => 'Março', 4 => 'Abril',
        5 => 'Maio', 6 => 'Junho', 7 => 'Julho', 8 => 'Agosto',
        9 => 'Setembro', 10 => 'Outubro', 11 => 'Novembro', 12 => 'Dezembro',
    ];

    $diarioCodigos = [];
    foreach ($diarios as $d) {
        $diarioCodigos[$d['id']] = $d['codigo'] . ' - ' . $d['nome'];
    }

    $periodoLabels = [];
    foreach ($periodos as $p) {
        $periodoLabels[$p['id']] = ($mesesLabels[$p['mes']] ?? $p['mes']) . '/' . $p['ano'];
    }

    $userNomes = array_column($utilizadores, 'nome', 'id');

    $estadoBadges = [
        'publicado' => ['adm-badge--green', 'Publicado'],
        'anulado'   => ['adm-badge--gray', 'Anulado'],
    ];
    $estadoBadge = $estadoBadges[$lancamento['status']] ?? ['adm-badge--gray', $lancamento['status']];

    $contas = [];
    if ($lancamento['status'] === 'publicado') {
        $contas = $app->nexora->call('GET', '/api/contabilidade/accounts', null, ['aceita_lancamento' => 'true', 'ativo' => 'true'])['body'] ?? [];
    }

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Lançamento ' . $lancamento['numero'];
    $activePage = 'contab_lancamentos';
    $breadcrumb = [['Admin', '/nexora/'], ['Contabilidade', ''], ['Lançamentos', $app->routes->path('contab_lancamentos')], [$lancamento['numero'], '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <div style="display:flex;align-items:center;gap:var(--adm-sp-3)">
        <h1 class="adm-page-title" style="margin:0">Lançamento <?php echo htmlspecialchars($lancamento['numero']) ?></h1>
        <span class="adm-badge <?php echo $estadoBadge[0] ?>"><?php echo $estadoBadge[1] ?></span>
    </div>
    <div class="adm-page-header-actions">
        <a href="<?php echo htmlspecialchars($app->routes->path('contab_lancamentos')) ?>" class="adm-btn adm-btn-outline adm-btn-sm">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>
            Voltar
        </a>
    </div>
</div>

<div id="formMsg"></div>

<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Informação</h2></div>
    <div class="adm-card-body">
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:var(--adm-sp-5)">
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Diário</span>
                <span class="adm-detail-pair-value"><?php echo htmlspecialchars($diarioCodigos[$lancamento['accounting_journal_id']] ?? ('#' . $lancamento['accounting_journal_id'])) ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Período</span>
                <span class="adm-detail-pair-value"><?php echo htmlspecialchars($periodoLabels[$lancamento['fiscal_period_id']] ?? ('#' . $lancamento['fiscal_period_id'])) ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Data</span>
                <span class="adm-detail-pair-value"><?php echo date('d/m/Y', strtotime($lancamento['entry_date'])) ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Moeda</span>
                <span class="adm-detail-pair-value"><?php echo htmlspecialchars($lancamento['moeda']) ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Total Débito</span>
                <span class="adm-detail-pair-value adm-fw-600"><?php echo number_format((float) $lancamento['total_debito'], 2, ',', '.') ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Total Crédito</span>
                <span class="adm-detail-pair-value adm-fw-600"><?php echo number_format((float) $lancamento['total_credito'], 2, ',', '.') ?></span>
            </div>
            <?php if (! empty($lancamento['referencia_tipo'])): ?>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Referência Tipo</span>
                <span class="adm-detail-pair-value"><?php echo htmlspecialchars($lancamento['referencia_tipo']) ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Referência ID</span>
                <span class="adm-detail-pair-value">
                    <?php if ($lancamento['referencia_tipo'] === 'estorno' && $lancamento['referencia_id']): ?>
                    <a href="<?php echo htmlspecialchars($app->routes->path('contab_lancamento', ['id' => $lancamento['referencia_id']])) ?>"><?php echo (int) $lancamento['referencia_id'] ?></a>
                    <?php else: ?>
                    <?php echo (int) $lancamento['referencia_id'] ?>
                    <?php endif; ?>
                </span>
            </div>
            <?php endif; ?>
            <?php if (! empty($lancamento['criado_por'])): ?>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Criado por</span>
                <span class="adm-detail-pair-value"><?php echo htmlspecialchars($userNomes[$lancamento['criado_por']] ?? ('#' . $lancamento['criado_por'])) ?></span>
            </div>
            <?php endif; ?>
            <?php if (! empty($lancamento['publicado_por'])): ?>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Publicado por</span>
                <span class="adm-detail-pair-value"><?php echo htmlspecialchars($userNomes[$lancamento['publicado_por']] ?? ('#' . $lancamento['publicado_por'])) ?></span>
            </div>
            <?php endif; ?>
            <?php if (! empty($lancamento['publicado_em'])): ?>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Publicado em</span>
                <span class="adm-detail-pair-value"><?php echo date('d/m/Y H:i', strtotime($lancamento['publicado_em'])) ?></span>
            </div>
            <?php endif; ?>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Criado em</span>
                <span class="adm-detail-pair-value"><?php echo date('d/m/Y H:i', strtotime($lancamento['created_at'])) ?></span>
            </div>
        </div>
    </div>
</div>

<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Linhas</h2></div>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr>
                    <th>Conta</th>
                    <th>Descrição</th>
                    <th>Débito</th>
                    <th>Crédito</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($linhas as $linha): ?>
            <tr>
                <td><?php echo htmlspecialchars($linha['account_codigo'] . ' - ' . $linha['account_nome']) ?></td>
                <td><?php echo htmlspecialchars((string) ($linha['descricao'] ?? '—')) ?></td>
                <td class="adm-fw-600"><?php echo $linha['debit'] > 0 ? number_format((float) $linha['debit'], 2, ',', '.') : '—' ?></td>
                <td class="adm-fw-600"><?php echo $linha['credit'] > 0 ? number_format((float) $linha['credit'], 2, ',', '.') : '—' ?></td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>

<?php if ($lancamento['status'] === 'publicado'): ?>
<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Adicionar Linha</h2></div>
    <div class="adm-card-body">
        <div class="adm-form-row">
            <div class="adm-form-group">
                <label class="adm-label" for="al-conta">Conta <span style="color:var(--adm-red)">*</span></label>
                <select class="adm-select" id="al-conta">
                    <option value="">Selecione...</option>
                    <?php foreach ($contas as $c): ?>
                    <option value="<?php echo $c['id'] ?>"><?php echo htmlspecialchars($c['codigo'] . ' - ' . $c['nome']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="al-descricao">Descrição</label>
                <input class="adm-input" type="text" id="al-descricao" maxlength="255">
            </div>
        </div>
        <div class="adm-form-row">
            <div class="adm-form-group">
                <label class="adm-label" for="al-debit">Débito</label>
                <input class="adm-input" type="number" id="al-debit" min="0" step="0.01" placeholder="0.00">
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="al-credit">Crédito</label>
                <input class="adm-input" type="number" id="al-credit" min="0" step="0.01" placeholder="0.00">
            </div>
        </div>
        <button class="adm-btn adm-btn-primary" onclick="adicionarLinha()">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            Adicionar Linha
        </button>
    </div>
</div>

<button class="adm-btn adm-btn-outline" style="color:var(--adm-red)" onclick="estornarLancamento()">
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 1 0 2.13-9.36L1 10"/></svg>
    Estornar Lançamento
</button>
<?php endif; ?>

<script>
const LANCAMENTO_ID = <?php echo $id ?>;
const CSRF          = '<?php echo $csrf ?>';

async function adicionarLinha() {
    const accountId = document.getElementById('al-conta').value;
    const debit     = Number(document.getElementById('al-debit').value || 0);
    const credit    = Number(document.getElementById('al-credit').value || 0);

    if (!accountId) { showToast('A conta é obrigatória.', 'error'); return; }
    if (debit === 0 && credit === 0) { showToast('Indique um valor de débito ou crédito.', 'error'); return; }

    try {
        const res  = await fetch('/nexora/api/contab_lancamento_linha_save', {
            method: 'POST', headers: {'Content-Type':'application/json'},
            body: JSON.stringify({
                id: LANCAMENTO_ID,
                account_id: Number(accountId),
                descricao: document.getElementById('al-descricao').value.trim() || null,
                debit, credit,
                csrf: CSRF
            })
        });
        const data = await res.json();
        if (data.ok) {
            showToast('Linha adicionada com sucesso.');
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}

function estornarLancamento() {
    openConfirm(
        'Estornar lançamento',
        'Estornar o lançamento <?php echo htmlspecialchars($lancamento['numero']) ?>? Será criado um lançamento de reversão e este será marcado como anulado.',
        async () => {
            try {
                const res  = await fetch('/nexora/api/contab_lancamento_estornar', {
                    method: 'POST', headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({id: LANCAMENTO_ID, csrf: CSRF})
                });
                const data = await res.json();
                if (data.ok) {
                    showToast('Lançamento estornado com sucesso.');
                    setTimeout(() => window.location.href = '/nexora/contabilidade/lancamento?id=' + data.id, 700);
                } else {
                    showToast(data.erro || 'Erro', 'error');
                }
            } catch { showToast('Erro de ligação', 'error'); }
        }
    );
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
