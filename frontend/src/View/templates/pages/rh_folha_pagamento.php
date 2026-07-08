<?php

    $idHash = $app->request->queryString('id');

    $resp = $app->nexora->call('GET', "/api/rh/folhas-pagamento/$idHash");
    $__safeList = fn(array $r) => ($r['status'] === 200 && is_array($r['body']) && array_is_list($r['body'])) ? $r['body'] : [];
    if ($resp['status'] !== 200) {
        header('Location: /nexora/rh/funcionarios#processamento-salarial');
        exit;
    }
    $folha   = $resp['body']['folha'] ?? [];
    $recibos = $resp['body']['recibos'] ?? [];
    $journalEntryID = $resp['body']['journal_entry_id'] ?? null;

    $contasBancarias = $__safeList($app->nexora->call('GET', '/api/tesouraria/contas-bancarias'));
    $caixas          = $__safeList($app->nexora->call('GET', '/api/tesouraria/caixas'));

    $lancamento = null;
    if ($journalEntryID) {
        $lancamentoResp = $app->nexora->call('GET', "/api/contabilidade/lancamentos/$journalEntryID");
        if ($lancamentoResp['status'] === 200) {
            $lancamento = $lancamentoResp['body'] ?? null;
        }
    }

    $mesesLabels = [
        1 => 'Janeiro', 2 => 'Fevereiro', 3 => 'Março', 4 => 'Abril', 5 => 'Maio', 6 => 'Junho',
        7 => 'Julho', 8 => 'Agosto', 9 => 'Setembro', 10 => 'Outubro', 11 => 'Novembro', 12 => 'Dezembro',
    ];
    $folhaPagamentoEstadoBadges = [
        'aberta'     => ['adm-badge--gray',   'Aberta'],
        'processada' => ['adm-badge--blue',   'Processada'],
        'paga'       => ['adm-badge--green',  'Paga'],
        'cancelada'  => ['adm-badge--red',    'Cancelada'],
    ];
    $reciboEstadoBadges = [
        'pendente' => ['adm-badge--gray',  'Pendente'],
        'pago'     => ['adm-badge--green', 'Pago'],
    ];

    $folhaBadge = $folhaPagamentoEstadoBadges[$folha['estado']] ?? ['adm-badge--gray', $folha['estado']];
    $periodo    = ($mesesLabels[$folha['mes']] ?? (string) $folha['mes']) . ' de ' . (int) $folha['ano'];

    // RNF02 — confidencialidade salarial: valores são devolvidos como null pelo
    // backend quando o utilizador não tem permissão (recursos-humanos, gerir).
    $podeVerSalarios = $app->session->can('recursos-humanos', 'processar_salarios');
    $csrf = $app->security->csrfToken();
    function rhValorSalarial(?float $valor, bool $podeVer): string
    {
        if (!$podeVer) {
            return '<span class="adm-text-muted">Confidencial</span>';
        }
        return $valor !== null ? number_format($valor, 2, ',', '.') : '—';
    }

    $pageTitle  = 'Folha de Pagamento — ' . $periodo;
    $activePage = 'rh_processamento_salarial';
    $breadcrumb = [['Admin', '/nexora/'], ['Recursos Humanos', ''], ['Processamento Salarial', '/nexora/rh/processamento-salarial'], ['Folha de Pagamento', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header" style="align-items:flex-start">
    <div style="display:flex;align-items:center;gap:var(--adm-sp-3)">
        <h1 class="adm-page-title" style="margin:0">Folha de Pagamento — <?php echo htmlspecialchars($periodo) ?></h1>
        <span class="adm-badge <?php echo $folhaBadge[0] ?>"><?php echo $folhaBadge[1] ?></span>
    </div>
    <div class="adm-page-header-actions no-print">
        <?php if ($folha['estado'] === 'processada'): ?>
        <button class="adm-btn adm-btn-primary adm-btn-sm" type="button" onclick="openPagarFolhaModal()">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:4px"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>
            Pagar Folha
        </button>
        <?php endif; ?>
        <?php if ($folha['estado'] === 'paga'): ?>
        <button class="adm-btn adm-btn-outline adm-btn-sm" type="button" onclick="cancelarFolha()" style="color:var(--adm-red)">
            Cancelar Pagamento
        </button>
        <?php endif; ?>
        <button class="adm-btn adm-btn-outline adm-btn-sm" type="button" onclick="window.print()">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:4px"><polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><rect x="6" y="14" width="12" height="8"/></svg>
            Imprimir / PDF
        </button>
        <a href="/nexora/rh/processamento-salarial" class="adm-btn adm-btn-outline adm-btn-sm">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>
            Voltar
        </a>
    </div>
</div>

<!-- Cabeçalho visível apenas na impressão -->
<div class="print-header">
    <h2 style="margin:0 0 .25rem;font-size:1.1rem">Folha de Pagamento — <?php echo htmlspecialchars($periodo) ?></h2>
    <p style="margin:0;color:#666;font-size:.85rem">
        Estado: <strong><?php echo $folhaBadge[1] ?></strong>
        &nbsp;·&nbsp; Gerada em: <?php echo date('d/m/Y H:i', strtotime($folha['created_at'])) ?>
        <?php if ($folha['processada_em']): ?>&nbsp;·&nbsp; Processada em: <?php echo date('d/m/Y H:i', strtotime($folha['processada_em'])) ?><?php endif; ?>
        <?php if ($folha['paga_em']): ?>&nbsp;·&nbsp; Paga em: <?php echo date('d/m/Y H:i', strtotime($folha['paga_em'])) ?><?php endif; ?>
    </p>
</div>

<div class="adm-stats-grid" style="grid-template-columns:repeat(4,1fr)">
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--blue">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="9" cy="7" r="4"/><path d="M1 21v-2a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v2"/></svg>
        </div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?php echo (int) $folha['num_funcionarios'] ?></div>
            <div class="adm-stat-label">Nº Funcionários</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--green">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
        </div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?php echo rhValorSalarial($folha['total_proventos'] !== null ? (float) $folha['total_proventos'] : null, $podeVerSalarios) ?></div>
            <div class="adm-stat-label">Total Proventos</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--red">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="8" y1="12" x2="16" y2="12"/></svg>
        </div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?php echo rhValorSalarial($folha['total_descontos'] !== null ? (float) $folha['total_descontos'] : null, $podeVerSalarios) ?></div>
            <div class="adm-stat-label">Total Descontos</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--blue">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
        </div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?php echo rhValorSalarial($folha['total_liquido'] !== null ? (float) $folha['total_liquido'] : null, $podeVerSalarios) ?></div>
            <div class="adm-stat-label">Total Líquido</div>
        </div>
    </div>
</div>

<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Informação</h2></div>
    <div class="adm-card-body">
        <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:var(--adm-sp-5)">
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Período</span>
                <span class="adm-detail-pair-value"><?php echo htmlspecialchars($periodo) ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Criada em</span>
                <span class="adm-detail-pair-value"><?php echo date('d/m/Y H:i', strtotime($folha['created_at'])) ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Processada em</span>
                <span class="adm-detail-pair-value"><?php echo $folha['processada_em'] ? date('d/m/Y H:i', strtotime($folha['processada_em'])) : '—' ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Paga em</span>
                <span class="adm-detail-pair-value"><?php echo $folha['paga_em'] ? date('d/m/Y H:i', strtotime($folha['paga_em'])) : '—' ?></span>
            </div>
        </div>
    </div>
</div>

<?php if ($lancamento): ?>
<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Lançamento Contabilístico</h2></div>
    <div class="adm-card-body">
        <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:var(--adm-sp-5)">
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Número</span>
                <span class="adm-detail-pair-value"><?php echo htmlspecialchars($lancamento['numero']) ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Data</span>
                <span class="adm-detail-pair-value"><?php echo date('d/m/Y', strtotime($lancamento['entry_date'])) ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Estado</span>
                <span class="adm-detail-pair-value"><span class="adm-badge adm-badge--green">Publicado</span></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Débito</span>
                <span class="adm-detail-pair-value"><?php echo number_format((float) $lancamento['total_debito'], 2, ',', '.') ?> MZN</span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Crédito</span>
                <span class="adm-detail-pair-value"><?php echo number_format((float) $lancamento['total_credito'], 2, ',', '.') ?> MZN</span>
            </div>
        </div>
        <div style="margin-top:var(--adm-sp-4)">
            <a href="/nexora/contabilidade/lancamento?id=<?php echo $app->id->encode((int)$lancamento['id']) ?>" class="adm-btn adm-btn-outline adm-btn-sm">Ver Lançamento</a>
        </div>
    </div>
</div>
<?php endif; ?>

<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Recibos de Vencimento</h2></div>
    <?php if ($recibos): ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr><th>Funcionário</th><th>Nº Funcionário</th><th>Salário Base</th><th>Total Proventos</th><th>Total Descontos</th><th>Salário Líquido</th><th>Estado</th><th></th></tr>
            </thead>
            <tbody>
            <?php foreach ($recibos as $rv):
                $rvBadge = $reciboEstadoBadges[$rv['estado']] ?? ['adm-badge--gray', $rv['estado']];
            ?>
            <tr>
                <td class="adm-fw-600"><?php echo htmlspecialchars($rv['nome_completo']) ?></td>
                <td class="adm-text-muted"><?php echo $rv['numero_funcionario'] ? htmlspecialchars($rv['numero_funcionario']) : '—' ?></td>
                <td class="adm-text-muted"><?php echo rhValorSalarial($rv['salario_base'] !== null ? (float) $rv['salario_base'] : null, $podeVerSalarios) ?></td>
                <td class="adm-text-muted"><?php echo rhValorSalarial($rv['total_proventos'] !== null ? (float) $rv['total_proventos'] : null, $podeVerSalarios) ?></td>
                <td class="adm-text-muted"><?php echo rhValorSalarial($rv['total_descontos'] !== null ? (float) $rv['total_descontos'] : null, $podeVerSalarios) ?></td>
                <td class="adm-fw-600"><?php echo rhValorSalarial($rv['salario_liquido'] !== null ? (float) $rv['salario_liquido'] : null, $podeVerSalarios) ?></td>
                <td><span class="adm-badge <?php echo $rvBadge[0] ?>"><?php echo $rvBadge[1] ?></span></td>
                <td>
                    <a class="adm-btn adm-btn-ghost adm-btn-sm" href="/nexora/rh/recibo-vencimento?id=<?php echo $app->id->encode((int)$rv['id']) ?>">
                        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                        Ver
                    </a>
                </td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="adm-empty">
        <p class="adm-empty-title">Esta folha de pagamento ainda não foi processada</p>
        <p class="adm-empty-sub">Os recibos de vencimento são gerados ao processar a folha de pagamento.</p>
    </div>
    <?php endif; ?>
</div>

<?php if ($folha['estado'] === 'processada'): ?>
<div class="adm-modal" id="pagarFolhaModal" style="display:none">
    <div class="adm-modal-content" style="max-width:520px">
        <div class="adm-modal-header">
            <h3>Pagar Folha de Pagamento</h3>
            <button class="adm-btn adm-btn-ghost adm-btn-icon" type="button" onclick="closePagarFolhaModal()">&times;</button>
        </div>
        <div style="padding:var(--adm-sp-5) var(--adm-sp-6)">
            <p class="adm-text-muted" style="margin-bottom:var(--adm-sp-4)">Selecione a conta bancária ou caixa de onde sairá o pagamento.</p>
            <div class="adm-form-group">
                <label class="adm-label">Origem do Pagamento</label>
                <select class="adm-select" id="origemPagamento">
                    <option value="">— Seleccionar —</option>
                    <optgroup label="Contas Bancárias">
                        <?php foreach ($contasBancarias as $cb): ?>
                        <option value="bank:<?php echo (int) $cb['id'] ?>"><?php echo htmlspecialchars($cb['banco']) ?> — <?php echo htmlspecialchars($cb['numero_conta']) ?> (Saldo: <?php echo number_format((float) $cb['saldo_actual'], 2, ',', '.') ?> <?php echo htmlspecialchars($cb['moeda']) ?>)</option>
                        <?php endforeach; ?>
                    </optgroup>
                    <optgroup label="Caixas">
                        <?php foreach ($caixas as $cx): ?>
                        <option value="cash:<?php echo (int) $cx['id'] ?>"><?php echo htmlspecialchars($cx['nome']) ?> (Saldo: <?php echo number_format((float) $cx['saldo_actual'], 2, ',', '.') ?> <?php echo htmlspecialchars($cx['moeda']) ?>)</option>
                        <?php endforeach; ?>
                    </optgroup>
                </select>
            </div>
        </div>
        <div class="adm-modal-footer">
            <button class="adm-btn adm-btn-ghost" type="button" onclick="closePagarFolhaModal()">Cancelar</button>
            <button class="adm-btn adm-btn-primary" type="button" onclick="pagarFolha()">Confirmar Pagamento</button>
        </div>
    </div>
</div>
<?php endif; ?>

<script>
const CSRF = <?php echo json_encode($csrf) ?>;
const FOLHA_ID = <?php echo (int) $id ?>;

<?php if ($folha['estado'] === 'processada'): ?>
function openPagarFolhaModal() { document.getElementById('pagarFolhaModal').style.display = 'flex'; }
function closePagarFolhaModal() { document.getElementById('pagarFolhaModal').style.display = 'none'; }

async function pagarFolha() {
    const origem = document.getElementById('origemPagamento').value;
    if (!origem) { showToast('Seleccione uma conta bancária ou caixa.', 'error'); return; }

    const [tipo, idStr] = origem.split(':');
    const payload = tipo === 'bank' ? {bank_account_id: parseInt(idStr)} : {cash_register_id: parseInt(idStr)};

    try {
        const res = await fetch('/nexora/api/rh_operacao', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({csrf: CSRF, operation: 'folha.pagar', id: FOLHA_ID, payload})
        });
        const data = await res.json();
        if (!res.ok || !data.ok) throw new Error(data.erro || 'Erro ao pagar folha.');
        showToast('Folha paga com sucesso.');
        setTimeout(() => location.reload(), 800);
    } catch (e) {
        showToast(e.message, 'error');
    }
}
<?php endif; ?>

<?php if ($folha['estado'] === 'paga'): ?>
async function cancelarFolha() {
    if (!confirm('Cancelar o pagamento desta folha? O movimento de tesouraria e o lançamento contabilístico serão estornados.')) return;
    try {
        const res = await fetch('/nexora/api/rh_operacao', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({csrf: CSRF, operation: 'folha.cancelar', id: FOLHA_ID})
        });
        const data = await res.json();
        if (!res.ok || !data.ok) throw new Error(data.erro || 'Erro ao cancelar folha.');
        showToast('Folha cancelada com sucesso.');
        setTimeout(() => location.reload(), 800);
    } catch (e) {
        showToast(e.message, 'error');
    }
}
<?php endif; ?>
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>


