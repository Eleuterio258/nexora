<?php

declare(strict_types=1);

if (!$app->session->canModule('clientes')) {
    header('Location: /nexora');
    exit;
}

$email = $_GET['email'] ?? '';
if ($email === '') {
    header('Location: ' . $app->routes->path('clientes'));
    exit;
}

$erro = null;
$transacoes = [];
$cliente = null;

try {
    $clientes = $app->payCoreCustomer->list();
    foreach ($clientes as $c) {
        if (strtolower((string) ($c['email'] ?? '')) === strtolower($email)) {
            $cliente = $c;
            break;
        }
    }
    $transacoes = $app->payCoreCustomer->transactions($email);
} catch (\Throwable $e) {
    $erro = $e->getMessage();
}

if ($cliente === null) {
    header('Location: ' . $app->routes->path('clientes'));
    exit;
}

$pageTitle  = 'Detalhe do Cliente';
$activePage = 'clientes';
$breadcrumb = [['Admin', '/nexora/'], ['Clientes', '/nexora/clientes'], ['Detalhe', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title"><?= htmlspecialchars($cliente['name'] ?? 'Cliente') ?></h1>
    <div class="adm-page-header-actions">
        <a href="<?= htmlspecialchars($app->routes->path('clientes')) ?>" class="adm-btn adm-btn-outline">
            <i class="fa-solid fa-arrow-left"></i> Voltar
        </a>
    </div>
</div>

<?php if ($erro): ?>
<div class="adm-alert adm-alert--error" style="margin-bottom:var(--adm-sp-5)">
    <i class="fa-solid fa-circle-exclamation"></i>
    <span><?= htmlspecialchars($erro) ?></span>
</div>
<?php endif; ?>

<div style="display:grid;grid-template-columns:320px 1fr;gap:var(--adm-sp-6);align-items:start;margin-bottom:var(--adm-sp-6)">
    <div class="adm-card">
        <div class="adm-card-header">
            <h2 class="adm-card-title">Informações</h2>
        </div>
        <div class="adm-card-body">
            <div class="adm-detail-pair" style="margin-bottom:var(--adm-sp-3)">
                <span class="adm-detail-pair-label">Email</span>
                <span class="adm-detail-pair-value"><?= htmlspecialchars($cliente['email'] ?? '—') ?></span>
            </div>
            <div class="adm-detail-pair" style="margin-bottom:var(--adm-sp-3)">
                <span class="adm-detail-pair-label">Telefone</span>
                <span class="adm-detail-pair-value"><?= htmlspecialchars($cliente['phone'] ?? '—') ?></span>
            </div>
            <div class="adm-detail-pair" style="margin-bottom:var(--adm-sp-3)">
                <span class="adm-detail-pair-label">NIF</span>
                <span class="adm-detail-pair-value"><?= htmlspecialchars($cliente['nif'] ?? '—') ?></span>
            </div>
            <div class="adm-detail-pair" style="margin-bottom:0">
                <span class="adm-detail-pair-label">Total gasto</span>
                <span class="adm-detail-pair-value" style="font-size:1.15rem;font-weight:800"><?= number_format((float) ($cliente['total_spent'] ?? 0), 2) ?> MZN</span>
            </div>
        </div>
    </div>

    <div class="adm-card">
        <div class="adm-card-header">
            <h2 class="adm-card-title">Histórico de transacções</h2>
        </div>
        <div class="adm-card-body" style="padding:0">
            <?php if (!empty($transacoes)): ?>
            <div class="adm-table-wrap">
                <table class="adm-table">
                    <thead>
                        <tr>
                            <th>Referência</th>
                            <th>Data</th>
                            <th>Método</th>
                            <th>Total</th>
                            <th>Estado</th>
                            <th></th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php foreach ($transacoes as $t):
                        $status = $t['status'] ?? 'UNKNOWN';
                    ?>
                        <tr>
                            <td class="adm-fw-600"><?= htmlspecialchars($t['reference'] ?? '—') ?></td>
                            <td class="adm-text-muted"><?= !empty($t['timestamp']) ? date('d/m/Y H:i', (int) ($t['timestamp'] / 1000)) : '—' ?></td>
                            <td class="adm-text-muted"><?= htmlspecialchars($t['payment_method'] ?? '—') ?></td>
                            <td class="adm-fw-600"><?= number_format((float) ($t['total'] ?? 0), 2) ?> MZN</td>
                            <td>
                                <span class="adm-badge <?= match($status) { 'APPROVED' => 'adm-badge--green', 'PENDING' => 'adm-badge--yellow', 'CANCELLED' => 'adm-badge--red', 'REVERSED' => 'adm-badge--indigo', default => 'adm-badge--gray' } ?>">
                                    <?= match($status) { 'APPROVED' => 'Aprovado', 'PENDING' => 'Pendente', 'CANCELLED' => 'Cancelado', 'REVERSED' => 'Estornado', default => $status } ?>
                                </span>
                            </td>
                            <td>
                                <a href="<?= htmlspecialchars($app->routes->path('fatura_detalhe', ['id' => $t['id'] ?? ''])) ?>" class="adm-btn adm-btn-ghost adm-btn-icon adm-btn-sm">
                                    <i class="fa-solid fa-eye"></i>
                                </a>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
            <?php else: ?>
            <div class="adm-empty" style="padding:var(--adm-sp-8)">
                <p class="adm-empty-title">Sem transacções para este cliente</p>
            </div>
            <?php endif; ?>
        </div>
    </div>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
