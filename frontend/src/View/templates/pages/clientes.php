<?php

declare(strict_types=1);

if (!$app->session->canModule('clientes')) {
    header('Location: /nexora');
    exit;
}

$erro = null;
$clientes = [];

try {
    $clientes = $app->payCoreCustomer->list();
} catch (\Throwable $e) {
    $erro = $e->getMessage();
}

$pageTitle  = 'Clientes';
$activePage = 'clientes';
$breadcrumb = [['Admin', '/nexora/'], ['Clientes', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Clientes</h1>
    <div class="adm-page-header-actions">
        <span class="adm-text-sm adm-text-muted" style="max-width:340px">
            O backend PayCore ainda nao tem um modulo de clientes. A lista e construida a partir dos dados disponiveis nas transaccoes.
        </span>
    </div>
</div>

<?php if ($erro): ?>
<div class="adm-alert adm-alert--error" style="margin-bottom:var(--adm-sp-5)">
    <i class="fa-solid fa-circle-exclamation"></i>
    <span><?= htmlspecialchars($erro) ?></span>
</div>
<?php endif; ?>

<div class="adm-card">
    <div class="adm-card-header">
        <h2 class="adm-card-title">Lista de clientes</h2>
    </div>
    <div class="adm-card-body" style="padding:0">
        <?php if (!empty($clientes)): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr>
                        <th>Nome</th>
                        <th>Email</th>
                        <th>Telefone</th>
                        <th>NIF</th>
                        <th>Transaccoes</th>
                        <th>Total gasto</th>
                        <th></th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach ($clientes as $c): ?>
                    <tr>
                        <td class="adm-fw-600"><?= htmlspecialchars($c['name'] ?? '—') ?></td>
                        <td class="adm-text-muted"><?= htmlspecialchars($c['email'] ?? '—') ?></td>
                        <td class="adm-text-muted"><?= htmlspecialchars($c['phone'] ?? '—') ?></td>
                        <td class="adm-text-muted"><?= htmlspecialchars($c['nif'] ?? '—') ?></td>
                        <td><?= count($c['transactions'] ?? []) ?></td>
                        <td class="adm-fw-600"><?= number_format((float) ($c['total_spent'] ?? 0), 2) ?> MZN</td>
                        <td>
                            <?php if (!empty($c['email'])): ?>
                            <a href="<?= htmlspecialchars($app->routes->path('cliente_detalhe', ['email' => $c['email']])) ?>" class="adm-btn adm-btn-ghost adm-btn-icon adm-btn-sm" title="Ver detalhes">
                                <i class="fa-solid fa-eye"></i>
                            </a>
                            <?php endif; ?>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty" style="padding:var(--adm-sp-12)">
            <i class="fa-solid fa-users" style="font-size:2rem;opacity:.2"></i>
            <p class="adm-empty-title">Sem clientes identificados</p>
            <p class="adm-empty-sub">O modulo de clientes ainda nao esta disponivel no backend PayCore.</p>
            <a href="<?= htmlspecialchars($app->routes->path('faturas')) ?>" class="adm-btn adm-btn-outline">
                Ver vendas
            </a>
        </div>
        <?php endif; ?>
    </div>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
