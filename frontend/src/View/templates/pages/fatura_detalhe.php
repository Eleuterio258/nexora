<?php

declare(strict_types=1);

if (!$app->session->canModule('faturacao')) {
    header('Location: /nexora');
    exit;
}

$id = $_GET['id'] ?? '';
if ($id === '') {
    header('Location: ' . $app->routes->path('faturas'));
    exit;
}

$erro = null;
$sucesso = null;
$transacao = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['acao'])) {
    try {
        $app->security->validateCsrf($_POST['csrf_token'] ?? '');

        $acao = $_POST['acao'];
        $reason = $_POST['reason'] ?? '';

        if ($acao === 'cancelar') {
            $app->payCoreInvoicing->cancel($id, $reason);
            $sucesso = 'Transaccao cancelada com sucesso.';
        } elseif ($acao === 'estornar') {
            $app->payCoreInvoicing->reverse($id, $reason);
            $sucesso = 'Transaccao estornada com sucesso.';
        }
    } catch (\Throwable $e) {
        $erro = $e->getMessage();
    }
}

try {
    $transacao = $app->payCoreInvoicing->get($id);
} catch (\Throwable $e) {
    $erro = $e->getMessage();
}

if ($transacao === null) {
    header('Location: ' . $app->routes->path('faturas'));
    exit;
}

$status = $transacao['status'] ?? 'UNKNOWN';
$statusClass = match ($status) {
    'APPROVED' => 'adm-badge--green',
    'PENDING' => 'adm-badge--yellow',
    'CANCELLED' => 'adm-badge--red',
    'REVERSED' => 'adm-badge--indigo',
    default => 'adm-badge--gray',
};
$statusLabel = match ($status) {
    'APPROVED' => 'Aprovado',
    'PENDING' => 'Pendente',
    'CANCELLED' => 'Cancelado',
    'REVERSED' => 'Estornado',
    default => $status,
};

$pageTitle  = 'Detalhe do Documento';
$activePage = 'faturas';
$breadcrumb = [['Admin', '/nexora/'], ['Faturação', '/nexora/faturacao/faturas'], ['Detalhe', '']];
$csrf       = $app->security->csrfToken();

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Documento <?= htmlspecialchars($transacao['reference'] ?? '—') ?></h1>
    <div class="adm-page-header-actions">
        <a href="<?= htmlspecialchars($app->routes->path('faturas')) ?>" class="adm-btn adm-btn-outline">
            <i class="fa-solid fa-arrow-left"></i> Voltar
        </a>
        <?php if ($status === 'APPROVED' || $status === 'PENDING'): ?>
        <button type="button" class="adm-btn adm-btn-danger" onclick="cancelarTransaccao()">
            <i class="fa-solid fa-ban"></i> Cancelar
        </button>
        <?php endif; ?>
    </div>
</div>

<?php if ($erro): ?>
<div class="adm-alert adm-alert--error" style="margin-bottom:var(--adm-sp-5)">
    <i class="fa-solid fa-circle-exclamation"></i>
    <span><?= htmlspecialchars($erro) ?></span>
</div>
<?php endif; ?>

<?php if ($sucesso): ?>
<div class="adm-alert adm-alert--success" style="margin-bottom:var(--adm-sp-5)">
    <i class="fa-solid fa-check-circle"></i>
    <span><?= htmlspecialchars($sucesso) ?></span>
</div>
<?php endif; ?>

<div style="display:grid;grid-template-columns:1fr 320px;gap:var(--adm-sp-6);align-items:start;margin-bottom:var(--adm-sp-6)">
    <div class="adm-card">
        <div class="adm-card-header">
            <h2 class="adm-card-title">Itens</h2>
        </div>
        <div class="adm-card-body" style="padding:0">
            <?php if (!empty($transacao['items'])): ?>
            <div class="adm-table-wrap">
                <table class="adm-table">
                    <thead>
                        <tr>
                            <th>Produto</th>
                            <th>Qtd.</th>
                            <th>Preço unit.</th>
                            <th>Desconto</th>
                            <th>Total</th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php foreach ($transacao['items'] as $item):
                        $qtd = (int) ($item['quantity'] ?? 1);
                        $preco = (float) ($item['price'] ?? 0);
                        $desconto = (float) ($item['discount'] ?? 0);
                        $total = ($qtd * $preco) - $desconto;
                    ?>
                        <tr>
                            <td><?= htmlspecialchars($item['name'] ?? '—') ?></td>
                            <td class="adm-text-muted"><?= $qtd ?></td>
                            <td class="adm-text-muted"><?= number_format($preco, 2) ?> MZN</td>
                            <td class="adm-text-muted"><?= number_format($desconto, 2) ?> MZN</td>
                            <td class="adm-fw-600"><?= number_format($total, 2) ?> MZN</td>
                        </tr>
                    <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
            <?php else: ?>
            <div class="adm-empty" style="padding:var(--adm-sp-8)">
                <p class="adm-empty-title">Sem itens</p>
            </div>
            <?php endif; ?>
        </div>
    </div>

    <div>
        <div class="adm-card" style="margin-bottom:var(--adm-sp-6)">
            <div class="adm-card-header">
                <h2 class="adm-card-title">Resumo</h2>
            </div>
            <div class="adm-card-body">
                <div class="adm-detail-pair" style="margin-bottom:var(--adm-sp-3)">
                    <span class="adm-detail-pair-label">Estado</span>
                    <span class="adm-detail-pair-value"><span class="adm-badge <?= $statusClass ?>"><?= $statusLabel ?></span></span>
                </div>
                <div class="adm-detail-pair" style="margin-bottom:var(--adm-sp-3)">
                    <span class="adm-detail-pair-label">Data</span>
                    <span class="adm-detail-pair-value"><?= !empty($transacao['timestamp']) ? date('d/m/Y H:i', (int) ($transacao['timestamp'] / 1000)) : '—' ?></span>
                </div>
                <div class="adm-detail-pair" style="margin-bottom:var(--adm-sp-3)">
                    <span class="adm-detail-pair-label">Método de pagamento</span>
                    <span class="adm-detail-pair-value"><?= htmlspecialchars($transacao['payment_method'] ?? '—') ?></span>
                </div>
                <div class="adm-detail-pair" style="margin-bottom:var(--adm-sp-3)">
                    <span class="adm-detail-pair-label">Subtotal</span>
                    <span class="adm-detail-pair-value"><?= number_format((float) ($transacao['subtotal'] ?? 0), 2) ?> MZN</span>
                </div>
                <div class="adm-detail-pair" style="margin-bottom:var(--adm-sp-3)">
                    <span class="adm-detail-pair-label">Desconto</span>
                    <span class="adm-detail-pair-value"><?= number_format((float) ($transacao['discount'] ?? 0), 2) ?> MZN</span>
                </div>
                <div class="adm-detail-pair" style="margin-bottom:0">
                    <span class="adm-detail-pair-label">Total</span>
                    <span class="adm-detail-pair-value" style="font-size:1.15rem;font-weight:800"><?= number_format((float) ($transacao['total'] ?? 0), 2) ?> MZN</span>
                </div>
            </div>
        </div>

        <div class="adm-card">
            <div class="adm-card-header">
                <h2 class="adm-card-title">Observações</h2>
            </div>
            <div class="adm-card-body">
                <p class="adm-text-sm adm-text-muted">
                    O backend PayCore ainda nao emite documentos fiscais. Esta transaccao representa uma venda registada no POS.
                </p>
            </div>
        </div>
    </div>
</div>

<form method="post" action="" id="actionForm" style="display:none">
    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">
    <input type="hidden" name="acao" id="actionName" value="">
    <input type="hidden" name="reason" id="actionReason" value="">
</form>

<script>
function cancelarTransaccao() {
    const reason = prompt('Motivo do cancelamento:');
    if (!reason) return;
    document.getElementById('actionName').value = 'cancelar';
    document.getElementById('actionReason').value = reason;
    document.getElementById('actionForm').submit();
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
