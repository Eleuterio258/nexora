<?php

if (!$app->session->canModule('pos')) {
    header('Location: /nexora');
    exit;
}

$erro = null;
$relatorio = [];
$sessoesFechadas = [];

$from = $_GET['from'] ?? date('Y-m-01');
$to   = $_GET['to'] ?? date('Y-m-d');

try {
    $relatorio = $app->payCoreTransactionReport->byPeriod($from, $to);
    $todasSessoes = $app->payCoreCashDrawer->list();
    $sessoesFechadas = array_filter($todasSessoes, static fn(array $s): bool => ($s['status'] ?? '') !== 'OPEN');
} catch (\Throwable $e) {
    $erro = $e->getMessage();
}

$pageTitle  = 'Relatório de Fecho de Caixa';
$activePage = 'pos_relatorio_fecho';
$breadcrumb = [['Admin', '/nexora/'], ['POS', '/nexora/pos'], ['Relatório de Fecho', '']];
$csrf       = $app->security->csrfToken();

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Relatório de Fecho de Caixa</h1>
    <div class="adm-page-header-actions">
        <a href="<?= htmlspecialchars($app->routes->path('pos_sessoes')) ?>" class="adm-btn adm-btn-outline">
            <i class="fa-solid fa-arrow-left"></i> Sessões
        </a>
    </div>
</div>

<?php if ($erro): ?>
<div class="adm-alert adm-alert--error" style="margin-bottom:var(--adm-sp-5)">
    <i class="fa-solid fa-circle-exclamation"></i>
    <span><?= htmlspecialchars($erro) ?></span>
</div>
<?php endif; ?>

<div class="adm-card" style="margin-bottom:var(--adm-sp-6)">
    <div class="adm-card-body">
        <form method="get" action="" class="adm-filter-bar" style="padding:0;background:none;border:none">
            <div class="adm-form-row" style="gap:var(--adm-sp-3);margin:0;align-items:end">
                <div class="adm-form-group" style="margin-bottom:0">
                    <label class="adm-label" for="from">De</label>
                    <input type="date" id="from" name="from" class="adm-input" value="<?= htmlspecialchars($from) ?>">
                </div>
                <div class="adm-form-group" style="margin-bottom:0">
                    <label class="adm-label" for="to">Até</label>
                    <input type="date" id="to" name="to" class="adm-input" value="<?= htmlspecialchars($to) ?>">
                </div>
                <button type="submit" class="adm-btn adm-btn-primary">
                    <i class="fa-solid fa-filter"></i> Filtrar
                </button>
            </div>
        </form>
    </div>
</div>

<?php if (!empty($relatorio)): ?>
<div class="adm-stats-grid" style="margin-bottom:var(--adm-sp-6)">
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--green"><i class="fa-solid fa-cash-register" style="font-size:1rem"></i></div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= number_format((float) ($relatorio['summary']['netTotal'] ?? 0), 2) ?> MZN</div>
            <div class="adm-stat-label">Total líquido</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--blue"><i class="fa-solid fa-receipt" style="font-size:1rem"></i></div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= (int) ($relatorio['summary']['totalTransactions'] ?? 0) ?></div>
            <div class="adm-stat-label">Transações</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--yellow"><i class="fa-solid fa-circle-check" style="font-size:1rem"></i></div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= number_format((float) ($relatorio['summary']['totalApproved'] ?? 0), 2) ?> MZN</div>
            <div class="adm-stat-label">Aprovado</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--red"><i class="fa-solid fa-ban" style="font-size:1rem"></i></div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= number_format((float) (($relatorio['summary']['totalCancelled'] ?? 0) + ($relatorio['summary']['totalReversed'] ?? 0)), 2) ?> MZN</div>
            <div class="adm-stat-label">Cancelado / Estornado</div>
        </div>
    </div>
</div>
<?php endif; ?>

<div class="adm-card" style="margin-bottom:var(--adm-sp-6)">
    <div class="adm-card-header">
        <h2 class="adm-card-title">Sessões fechadas no período</h2>
    </div>
    <div class="adm-card-body" style="padding:0">
        <?php if (!empty($sessoesFechadas)): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr>
                        <th>Operador</th>
                        <th>Abertura</th>
                        <th>Fecho</th>
                        <th>Valor esperado</th>
                        <th>Valor final</th>
                        <th>Diferença</th>
                        <th></th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach ($sessoesFechadas as $s):
                    $diff = isset($s['difference']) ? (float) $s['difference'] : null;
                ?>
                    <tr>
                        <td><?= htmlspecialchars($s['opened_by_name'] ?? '—') ?></td>
                        <td class="adm-text-muted"><?= !empty($s['opened_at']) ? date('d/m/Y H:i', strtotime($s['opened_at'])) : '—' ?></td>
                        <td class="adm-text-muted"><?= !empty($s['closed_at']) ? date('d/m/Y H:i', strtotime($s['closed_at'])) : '—' ?></td>
                        <td><?= number_format((float) ($s['expected_amount'] ?? ($s['final_amount'] ?? 0) - ($diff ?? 0)), 2) ?> MZN</td>
                        <td><?= $s['final_amount'] !== null ? number_format((float) $s['final_amount'], 2) . ' MZN' : '—' ?></td>
                        <td>
                            <?php if ($diff !== null): ?>
                            <span class="adm-text-sm adm-fw-600 <?= $diff < 0 ? 'adm-text-red' : ($diff > 0 ? 'adm-text-green' : '') ?>">
                                <?= ($diff > 0 ? '+' : '') . number_format($diff, 2) ?> MZN
                            </span>
                            <?php else: ?>
                            —
                            <?php endif; ?>
                        </td>
                        <td>
                            <a href="<?= htmlspecialchars($app->routes->path('pos_sessa_detalhe', ['id' => $s['id'] ?? ''])) ?>" class="adm-btn adm-btn-ghost adm-btn-icon adm-btn-sm" title="Ver detalhes">
                                <i class="fa-solid fa-eye"></i>
                            </a>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty" style="padding:var(--adm-sp-12)">
            <p class="adm-empty-title">Sem sessões fechadas no período</p>
        </div>
        <?php endif; ?>
    </div>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
