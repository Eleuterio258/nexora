<?php

$id = $app->request->queryInt('id');
if (!$id) {
    header('Location: ' . $app->routes->path('faturas'));
    exit;
}

$resp = $app->nexora->call('GET', "/api/faturacao/invoices/$id");
if ($resp['status'] !== 200) {
    header('Location: ' . $app->routes->path('faturas'));
    exit;
}
$fatura = $resp['body']['fatura'] ?? [];
$itens  = $resp['body']['itens'] ?? [];

if (($fatura['status'] ?? '') === 'rascunho') {
    header('Location: ' . $app->routes->path('fatura_form', ['id' => $id]));
    exit;
}

$clienteResp = $app->nexora->call('GET', '/api/clientes/' . $fatura['customer_id']);
$cliente     = $clienteResp['body'] ?? [];

$statusBadges = [
    'emitida'           => ['adm-badge--blue',   'Emitida'],
    'parcialmente_paga' => ['adm-badge--yellow', 'Parcialmente Paga'],
    'paga'              => ['adm-badge--green',  'Paga'],
    'cancelada'         => ['adm-badge--red',    'Cancelada'],
    'vencida'           => ['adm-badge--indigo', 'Vencida'],
];
$tipoLabels  = ['normal' => 'Fatura', 'FR' => 'Fatura-recibo', 'VD' => 'Venda a Dinheiro', 'proforma' => 'Pró-forma'];
$statusBadge = $statusBadges[$fatura['status']] ?? ['adm-badge--gray', $fatura['status']];

$csrf       = $app->security->csrfToken();
$pageTitle  = 'Fatura ' . $fatura['numero'];
$activePage = 'fatura_detalhe';
$breadcrumb = [['Admin', '/nexora/'], ['Faturação', ''], ['Faturas', $app->routes->path('faturas')], [$fatura['numero'], '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header" style="align-items:flex-start">
    <div style="display:flex;align-items:center;gap:var(--adm-sp-3)">
        <h1 class="adm-page-title" style="margin:0"><?= htmlspecialchars($fatura['numero']) ?></h1>
        <span class="adm-badge <?= $statusBadge[0] ?>"><?= $statusBadge[1] ?></span>
    </div>
    <div class="adm-page-header-actions">
        <a href="/nexora/api/fatura_pdf?id=<?= (int) $id ?>" class="adm-btn adm-btn-outline adm-btn-sm" target="_blank">
            <i class="fa-solid fa-file-pdf"></i> PDF
        </a>
        <a href="<?= htmlspecialchars($app->routes->path('faturas')) ?>" class="adm-btn adm-btn-outline adm-btn-sm">Voltar</a>
    </div>
</div>

<div id="formMsg"></div>

<div class="adm-detail-grid">
<div>

<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Cliente</h2></div>
    <div class="adm-card-body">
        <p class="adm-fw-600"><?= htmlspecialchars($cliente['nome'] ?? ('#' . $fatura['customer_id'])) ?></p>
        <?php if (!empty($cliente['nuit'])): ?><p class="adm-text-muted adm-text-sm">NUIT <?= htmlspecialchars($cliente['nuit']) ?></p><?php endif; ?>
        <p class="adm-text-muted adm-text-sm">Tipo: <?= htmlspecialchars($tipoLabels[$fatura['tipo']] ?? $fatura['tipo']) ?></p>
        <p class="adm-text-muted adm-text-sm">Emissão: <?= date('d/m/Y', strtotime($fatura['invoice_date'])) ?><?= !empty($fatura['due_date']) ? ' · Vencimento: ' . date('d/m/Y', strtotime($fatura['due_date'])) : '' ?></p>
        <?php if (!empty($fatura['observacoes'])): ?>
        <p class="adm-text-muted adm-text-sm"><?= nl2br(htmlspecialchars($fatura['observacoes'])) ?></p>
        <?php endif; ?>
    </div>
</div>

<div class="adm-card">
    <div class="adm-card-header"><h2 class="adm-card-title">Linhas</h2></div>
    <div class="adm-card-body" style="padding:0">
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Descrição</th><th>Qtd.</th><th>Preço Unit.</th><th>Desc. %</th><th>IVA %</th><th style="text-align:right">Total</th></tr>
                </thead>
                <tbody>
                <?php foreach ($itens as $it): ?>
                    <tr>
                        <td><?= htmlspecialchars($it['descricao'] ?? '') ?></td>
                        <td><?= number_format((float) $it['quantidade'], 2, ',', '.') ?></td>
                        <td><?= number_format((float) $it['preco_unitario'], 2, ',', '.') ?></td>
                        <td><?= number_format((float) $it['desconto_percent'], 1, ',', '.') ?></td>
                        <td><?= number_format((float) $it['imposto_percent'], 1, ',', '.') ?></td>
                        <td style="text-align:right" class="adm-fw-600"><?= number_format((float) $it['total'], 2, ',', '.') ?></td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
                <tfoot>
                    <tr><td colspan="5" style="text-align:right" class="adm-fw-600">Total</td><td style="text-align:right" class="adm-fw-600"><?= number_format((float) $fatura['total'], 2, ',', '.') ?> <?= htmlspecialchars($fatura['moeda']) ?></td></tr>
                </tfoot>
            </table>
        </div>
    </div>
</div>

</div>

<aside>
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Acções</h2></div>
        <div class="adm-card-body" style="display:flex;flex-direction:column;gap:var(--adm-sp-2)">
            <?php if (in_array($fatura['status'], ['emitida', 'parcialmente_paga', 'vencida'], true)): ?>
            <a href="<?= htmlspecialchars($app->routes->path('recibos', ['invoice_id' => $id])) ?>" class="adm-btn adm-btn-outline adm-btn-sm" style="justify-content:flex-start">
                <i class="fa-solid fa-circle-check fa-fw"></i> Registar Recibo
            </a>
            <?php endif; ?>
            <a href="<?= htmlspecialchars($app->routes->path('notas_credito', ['invoice_id' => $id, 'customer_id' => $fatura['customer_id']])) ?>" class="adm-btn adm-btn-outline adm-btn-sm" style="justify-content:flex-start">
                <i class="fa-solid fa-file-circle-minus fa-fw"></i> Emitir Nota de Crédito
            </a>
            <?php if ($fatura['status'] !== 'cancelada'): ?>
            <button class="adm-btn adm-btn-outline adm-btn-sm" style="justify-content:flex-start;color:var(--adm-red)" onclick="cancelarFatura()">
                <i class="fa-solid fa-ban fa-fw"></i> Cancelar Fatura
            </button>
            <?php endif; ?>
        </div>
    </div>
</aside>
</div>

<script>
const CSRF = '<?php echo $csrf ?>';
const FATURA_ID = <?= (int) $id ?>;

function cancelarFatura() {
    openConfirm(
        'Cancelar fatura',
        'Pretende cancelar esta fatura?',
        async () => {
            try {
                const res  = await fetch('/nexora/api/fatura_estado', {
                    method: 'POST', headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({id: FATURA_ID, action: 'cancelar', csrf: CSRF})
                });
                const data = await res.json();
                if (data.ok) { showToast('Fatura cancelada'); setTimeout(() => location.reload(), 700); }
                else showToast(data.erro || 'Erro', 'error');
            } catch { showToast('Erro de ligação', 'error'); }
        }
    );
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
