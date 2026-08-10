<?php

declare(strict_types=1);

if (!$app->session->canModule('faturacao')) {
    header('Location: /nexora');
    exit;
}

$erro = null;
$sucesso = null;
$transacoes = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['acao'])) {
    try {
        $app->security->validateCsrf($_POST['csrf_token'] ?? '');

        $acao = $_POST['acao'];
        $id = $_POST['id'] ?? '';
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

$filtroStatus = $_GET['status'] ?? '';
$filtroData = $_GET['data'] ?? '';
$filtroRef = trim($_GET['ref'] ?? '');

try {
    $query = [];
    if ($filtroStatus !== '') {
        $query['status'] = $filtroStatus;
    }
    if ($filtroData !== '') {
        $query['date'] = $filtroData;
    }

    $transacoes = $app->payCoreInvoicing->list($query);

    if ($filtroRef !== '') {
        $transacoes = array_filter($transacoes, static fn(array $t): bool =>
            str_contains((string) ($t['reference'] ?? ''), $filtroRef) ||
            str_contains((string) ($t['id'] ?? ''), $filtroRef)
        );
    }
} catch (\Throwable $e) {
    $erro = $e->getMessage();
}

$pageTitle  = 'Documentos de Venda';
$activePage = 'faturas';
$breadcrumb = [['Admin', '/nexora/'], ['Faturação', ''], ['Documentos de Venda', '']];
$csrf       = $app->security->csrfToken();

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Documentos de Venda</h1>
    <div class="adm-page-header-actions">
        <span class="adm-text-sm adm-text-muted" style="max-width:320px">
            O backend PayCore ainda nao tem documentos fiscais. As vendas POS sao apresentadas como documentos de venda.
        </span>
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

<div class="adm-card" style="margin-bottom:var(--adm-sp-6)">
    <div class="adm-card-body">
        <form method="get" action="" class="adm-filter-bar" style="padding:0;background:none;border:none">
            <div class="adm-form-row" style="gap:var(--adm-sp-3);margin:0;align-items:end">
                <div class="adm-form-group" style="margin-bottom:0">
                    <label class="adm-label" for="ref">Referência</label>
                    <input type="text" id="ref" name="ref" class="adm-input" value="<?= htmlspecialchars($filtroRef) ?>" placeholder="Ex.: TXN-123">
                </div>
                <div class="adm-form-group" style="margin-bottom:0">
                    <label class="adm-label" for="status">Estado</label>
                    <select id="status" name="status" class="adm-select">
                        <option value="">Todos</option>
                        <option value="APPROVED" <?= $filtroStatus === 'APPROVED' ? 'selected' : '' ?>>Aprovado</option>
                        <option value="PENDING" <?= $filtroStatus === 'PENDING' ? 'selected' : '' ?>>Pendente</option>
                        <option value="CANCELLED" <?= $filtroStatus === 'CANCELLED' ? 'selected' : '' ?>>Cancelado</option>
                        <option value="REVERSED" <?= $filtroStatus === 'REVERSED' ? 'selected' : '' ?>>Estornado</option>
                    </select>
                </div>
                <div class="adm-form-group" style="margin-bottom:0">
                    <label class="adm-label" for="data">Data</label>
                    <input type="date" id="data" name="data" class="adm-input" value="<?= htmlspecialchars($filtroData) ?>">
                </div>
                <button type="submit" class="adm-btn adm-btn-primary">
                    <i class="fa-solid fa-filter"></i> Filtrar
                </button>
                <a href="<?= htmlspecialchars($app->routes->path('faturas')) ?>" class="adm-btn adm-btn-outline">
                    <i class="fa-solid fa-rotate-right"></i>
                </a>
            </div>
        </form>
    </div>
</div>

<div class="adm-card">
    <div class="adm-card-header">
        <h2 class="adm-card-title">Transacções</h2>
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
                        <th>Itens</th>
                        <th>Total</th>
                        <th>Estado</th>
                        <th style="width:140px"></th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach ($transacoes as $t):
                    $status = $t['status'] ?? 'UNKNOWN';
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
                ?>
                    <tr>
                        <td class="adm-fw-600"><?= htmlspecialchars($t['reference'] ?? '—') ?></td>
                        <td class="adm-text-muted"><?= !empty($t['timestamp']) ? date('d/m/Y H:i', (int) ($t['timestamp'] / 1000)) : '—' ?></td>
                        <td class="adm-text-muted"><?= htmlspecialchars($t['payment_method'] ?? '—') ?></td>
                        <td class="adm-text-muted"><?= count($t['items'] ?? []) ?></td>
                        <td class="adm-fw-600"><?= number_format((float) ($t['total'] ?? 0), 2) ?> MZN</td>
                        <td><span class="adm-badge <?= $statusClass ?>"><?= $statusLabel ?></span></td>
                        <td>
                            <div class="adm-actions">
                                <a href="<?= htmlspecialchars($app->routes->path('fatura_detalhe', ['id' => $t['id'] ?? ''])) ?>" class="adm-btn adm-btn-ghost adm-btn-icon adm-btn-sm" title="Ver detalhes">
                                    <i class="fa-solid fa-eye"></i>
                                </a>
                                <?php if ($status === 'APPROVED' || $status === 'PENDING'): ?>
                                <button type="button" class="adm-btn adm-btn-ghost adm-btn-icon adm-btn-sm" title="Cancelar" onclick="cancelarTransaccao('<?= htmlspecialchars($t['id'] ?? '') ?>')">
                                    <i class="fa-solid fa-ban"></i>
                                </button>
                                <?php endif; ?>
                            </div>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty" style="padding:var(--adm-sp-12)">
            <i class="fa-solid fa-file-invoice" style="font-size:2rem;opacity:.2"></i>
            <p class="adm-empty-title">Sem documentos de venda</p>
            <p class="adm-empty-sub">As vendas registadas no POS serao apresentadas aqui.</p>
        </div>
        <?php endif; ?>
    </div>
</div>

<form method="post" action="" id="cancelForm" style="display:none">
    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">
    <input type="hidden" name="acao" value="cancelar">
    <input type="hidden" name="id" id="cancelId" value="">
    <input type="hidden" name="reason" id="cancelReason" value="">
</form>

<script>
function cancelarTransaccao(id) {
    const reason = prompt('Motivo do cancelamento:');
    if (!reason) return;
    document.getElementById('cancelId').value = id;
    document.getElementById('cancelReason').value = reason;
    document.getElementById('cancelForm').submit();
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
