<?php
declare(strict_types=1);

/**
 * Sessões de Caixa — Portal Gerente
 * Replica funcionalidade de pages/pos_sessoes.php.
 */

$erro = null;
$sucesso = null;
$sessoes = [];

try {
    $sessoes = $app->pos->listSessoes(['limit' => 100]);
} catch (\Throwable $e) {
    $erro = $e->getMessage();
}

$pageTitle  = 'Sessões de Caixa';
$activePage = 'pos_manager_sessions';
$breadcrumb = [['Admin', '/nexora/'], ['POS', '/pos/gerente/dashboard'], ['Sessões de Caixa', '']];
$csrf       = $app->security->csrfToken();

include dirname(__DIR__, 2) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Sessões de Caixa</h1>
    <div class="adm-page-header-actions">
        <a href="<?= htmlspecialchars($app->routes->path('pos_operator_session_open')) ?>" class="adm-btn adm-btn-primary">
            <i class="fa-solid fa-plus"></i> Abrir sessão
        </a>
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

<div class="adm-card">
    <div class="adm-card-header"><h2 class="adm-card-title">Histórico de sessões</h2></div>
    <div class="adm-card-body" style="padding:0">
        <?php if (!empty($sessoes)): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr>
                        <th>Operador</th>
                        <th>Terminal</th>
                        <th>Estado</th>
                        <th>Abertura</th>
                        <th>Valor inicial</th>
                        <th>Valor final</th>
                        <th>Diferença</th>
                        <th style="width:120px"></th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach ($sessoes as $s):
                    $id = $s['id'] ?? '';
                    $status = $s['status'] ?? 'UNKNOWN';
                    $diff = isset($s['difference']) ? (float) $s['difference'] : null;
                ?>
                    <tr>
                        <td><?= htmlspecialchars($s['opened_by_name'] ?? ($s['operador_nome'] ?? '—')) ?></td>
                        <td class="adm-text-muted"><?= htmlspecialchars($s['terminal_nome'] ?? ($s['terminal_id'] ? '#' . $s['terminal_id'] : '—')) ?></td>
                        <td>
                            <?php if ($status === 'aberta' || $status === 'OPEN'): ?>
                            <span class="adm-badge adm-badge--green">Aberta</span>
                            <?php else: ?>
                            <span class="adm-badge adm-badge--gray">Fechada</span>
                            <?php endif; ?>
                        </td>
                        <td class="adm-text-muted"><?= !empty($s['opened_at']) ? date('d/m/Y H:i', strtotime($s['opened_at'])) : '—' ?></td>
                        <td><?= number_format((float) ($s['opening_amount'] ?? ($s['initial_amount'] ?? 0)), 2) ?> MZN</td>
                        <td><?= isset($s['closing_amount']) && $s['closing_amount'] !== null ? number_format((float) $s['closing_amount'], 2) . ' MZN' : (isset($s['final_amount']) && $s['final_amount'] !== null ? number_format((float) $s['final_amount'], 2) . ' MZN' : '—') ?></td>
                        <td>
                            <?php if ($diff !== null): ?>
                            <span class="adm-text-sm adm-fw-600 <?= $diff < 0 ? 'adm-text-red' : ($diff > 0 ? 'adm-text-green' : '') ?>">
                                <?= ($diff > 0 ? '+' : '') . number_format($diff, 2) ?> MZN
                            </span>
                            <?php else: ?>—<?php endif; ?>
                        </td>
                        <td>
                            <div class="adm-actions">
                                <a href="<?= htmlspecialchars($app->routes->path('pos_manager_session_view', ['id' => $id])) ?>" class="adm-btn adm-btn-ghost adm-btn-icon adm-btn-sm" title="Ver detalhes">
                                    <i class="fa-solid fa-eye"></i>
                                </a>
                                <?php if ($status === 'aberta' || $status === 'OPEN'): ?>
                                <a href="<?= htmlspecialchars($app->routes->path('pos_operator_session_close', ['id' => $id])) ?>" class="adm-btn adm-btn-primary adm-btn-sm" title="Fechar caixa">
                                    <i class="fa-solid fa-lock"></i>
                                </a>
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
            <i class="fa-solid fa-cash-register" style="font-size:2rem;opacity:.2"></i>
            <p class="adm-empty-title">Sem sessões de caixa</p>
            <p class="adm-empty-sub">Abra a primeira sessão para começar a operar.</p>
            <a href="<?= htmlspecialchars($app->routes->path('pos_operator_session_open')) ?>" class="adm-btn adm-btn-primary">
                <i class="fa-solid fa-plus"></i> Abrir sessão
            </a>
        </div>
        <?php endif; ?>
    </div>
</div>

<?php include dirname(__DIR__, 2) . '/layouts/bottom.php'; ?>
