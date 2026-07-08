<?php

    $idHash = $app->request->queryString('id');

    $resp = $app->nexora->call('GET', "/api/pos/sales/$idHash");
    if ($resp['status'] !== 200) {
        header('Location: /nexora/pos/vendas');
        exit;
    }
    $venda      = $resp['body']['venda'] ?? [];
    $itens      = $resp['body']['itens'] ?? [];
    $pagamentos = $resp['body']['pagamentos'] ?? [];

    $catResp  = $app->nexora->call('GET', '/api/pos/catalogo');
    $catalogo = $catResp['body'] ?? [];
    $produtoMap = [];
    foreach ($catalogo as $c) {
        $produtoMap[(int) $c['product_id']] = $c;
    }

    $termResp  = $app->nexora->call('GET', '/api/pos/terminais');
    $terminais = $termResp['body'] ?? [];
    $terminalMap = [];
    foreach ($terminais as $t) {
        $terminalMap[(int) $t['id']] = $t;
    }
    $terminal = $terminalMap[(int) $venda['terminal_id']] ?? null;

    $estadoBadges = [
        'concluida' => ['adm-badge--green', 'Concluída'],
        'cancelada' => ['adm-badge--red',   'Cancelada'],
        'rascunho'  => ['adm-badge--gray',  'Rascunho'],
    ];
    $estadoBadge = $estadoBadges[$venda['status']] ?? ['adm-badge--gray', $venda['status']];

    $pagamentoLabels = [
        'numerario'     => 'Numerário',
        'transferencia' => 'Transferência',
        'tpa'           => 'TPA',
        'mpesa'         => 'M-Pesa',
        'emola'         => 'E-Mola',
        'outro'         => 'Outro',
    ];

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Venda ' . $venda['numero'];
    $activePage = 'pos_vendas';
    $breadcrumb = [['Admin', '/nexora/'], ['POS', ''], ['Vendas', '/nexora/pos/vendas'], [$venda['numero'], '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header" style="align-items:flex-start">
    <div style="display:flex;align-items:center;gap:var(--adm-sp-3)">
        <h1 class="adm-page-title" style="margin:0"><?php echo htmlspecialchars($venda['numero']) ?></h1>
        <span class="adm-badge <?php echo $estadoBadge[0] ?>"><?php echo $estadoBadge[1] ?></span>
    </div>
    <div class="adm-page-header-actions">
        <a href="/nexora/pos/vendas" class="adm-btn adm-btn-outline adm-btn-sm">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>
            Voltar
        </a>
    </div>
</div>

<div class="adm-stats-grid" style="grid-template-columns:repeat(2,1fr)">
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--green">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
        </div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?php echo number_format((float) $venda['total'], 2, ',', '.') ?> <?php echo htmlspecialchars($venda['moeda']) ?></div>
            <div class="adm-stat-label">Total</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--blue">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="1" y="4" width="22" height="16" rx="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>
        </div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?php echo number_format((float) $venda['troco'], 2, ',', '.') ?></div>
            <div class="adm-stat-label">Troco</div>
        </div>
    </div>
</div>

<div class="adm-detail-grid">
<div>

<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Informação</h2></div>
    <div class="adm-card-body">
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:var(--adm-sp-5)">
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Terminal</span>
                <span class="adm-detail-pair-value"><?php echo htmlspecialchars($terminal ? ($terminal['codigo'] . ' - ' . $terminal['nome']) : ('#' . $venda['terminal_id'])) ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Sessão</span>
                <span class="adm-detail-pair-value">#<?php echo (int) $venda['pos_session_id'] ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Data</span>
                <span class="adm-detail-pair-value"><?php echo $venda['sold_at'] ? date('d/m/Y H:i', strtotime($venda['sold_at'])) : date('d/m/Y H:i', strtotime($venda['created_at'])) ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Moeda</span>
                <span class="adm-detail-pair-value"><?php echo htmlspecialchars($venda['moeda']) ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Subtotal</span>
                <span class="adm-detail-pair-value"><?php echo number_format((float) $venda['subtotal'], 2, ',', '.') ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Desconto</span>
                <span class="adm-detail-pair-value"><?php echo number_format((float) $venda['desconto_total'], 2, ',', '.') ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Imposto</span>
                <span class="adm-detail-pair-value"><?php echo number_format((float) $venda['imposto_total'], 2, ',', '.') ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Valor Recebido</span>
                <span class="adm-detail-pair-value"><?php echo number_format((float) $venda['valor_recebido'], 2, ',', '.') ?></span>
            </div>
        </div>
    </div>
</div>

<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Itens</h2></div>
    <?php if ($itens): ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr>
                    <th>Produto</th>
                    <th>Quantidade</th>
                    <th>Preço Unit.</th>
                    <th>Desconto</th>
                    <th>Imposto</th>
                    <th>Total</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($itens as $item):
                    $produto = $produtoMap[(int) $item['product_id']] ?? null;
                    $nome    = $item['descricao'] ?? ($produto['nome'] ?? ('#' . $item['product_id']));
            ?>
            <tr>
                <td><?php echo htmlspecialchars($nome) ?></td>
                <td><?php echo number_format((float) $item['quantidade'], 2, ',', '.') ?></td>
                <td><?php echo number_format((float) $item['preco_unitario'], 2, ',', '.') ?></td>
                <td><?php echo number_format((float) $item['desconto_valor'], 2, ',', '.') ?></td>
                <td><?php echo number_format((float) $item['imposto_valor'], 2, ',', '.') ?></td>
                <td class="adm-fw-600"><?php echo number_format((float) $item['total'], 2, ',', '.') ?></td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="adm-card-body">
        <p class="adm-text-muted adm-text-sm" style="margin:0">Sem itens registados.</p>
    </div>
    <?php endif; ?>
</div>

<div class="adm-card">
    <div class="adm-card-header"><h2 class="adm-card-title">Pagamentos</h2></div>
    <?php if ($pagamentos): ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr>
                    <th>Tipo</th>
                    <th>Valor</th>
                    <th>Referência</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($pagamentos as $p): ?>
            <tr>
                <td><?php echo htmlspecialchars($pagamentoLabels[$p['tipo']] ?? $p['tipo']) ?></td>
                <td class="adm-fw-600"><?php echo number_format((float) $p['valor'], 2, ',', '.') ?></td>
                <td><?php echo $p['referencia'] ? htmlspecialchars($p['referencia']) : '—' ?></td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="adm-card-body">
        <p class="adm-text-muted adm-text-sm" style="margin:0">Sem pagamentos registados.</p>
    </div>
    <?php endif; ?>
</div>

</div> <!-- /main col -->

<aside>
    <div class="adm-card">
        <div class="adm-card-header"><h2 class="adm-card-title">Estado da Venda</h2></div>
        <div class="adm-card-body">
            <div style="margin-bottom:var(--adm-sp-3)">
                <span class="adm-badge <?php echo $estadoBadge[0] ?>" style="font-size:var(--adm-text-sm)"><?php echo $estadoBadge[1] ?></span>
            </div>
            <?php if ($venda['status'] === 'concluida'): ?>
            <button class="adm-btn adm-btn-outline adm-btn-sm" onclick="cancelarVenda()" style="justify-content:flex-start;color:var(--adm-red)">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                Cancelar Venda
            </button>
            <?php else: ?>
            <p class="adm-text-muted adm-text-sm" style="margin:0">Sem ações disponíveis para este estado.</p>
            <?php endif; ?>
        </div>
    </div>
</aside>
</div> <!-- /adm-detail-grid -->

<script>
const CSRF    = '<?php echo $csrf ?>';
const VENDA_ID = <?php echo (int) $venda['id'] ?>;

function cancelarVenda() {
    openConfirm(
        'Cancelar venda',
        'Pretende cancelar a venda "<?php echo htmlspecialchars(addslashes($venda['numero'])) ?>"? O stock será reposto.',
        async () => {
            try {
                const res  = await fetch('/nexora/api/pos_venda_cancelar', {
                    method: 'POST',
                    headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({ id: VENDA_ID, csrf: CSRF })
                });
                const data = await res.json();
                if (data.ok) {
                    showToast('Venda cancelada');
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


