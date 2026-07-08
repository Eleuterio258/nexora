<?php
declare(strict_types=1);

$pageTitle  = 'Resumo';
$activePage = 'dashboard';

$encInfo   = $portalEncarregado ?? [];
$educandos = $encInfo['educandos'] ?? [];
// $selectedId and $selectedHash come from the index.php closure scope

// Dados do educando seleccionado
$cobrancas  = $portalData['cobrancas']['body']  ?? [];
$boletim    = $portalData['boletim']['body']    ?? [];
$presencas  = $portalData['presencas']['body']  ?? [];

if (!is_array($cobrancas))  $cobrancas  = [];
if (!is_array($presencas))  $presencas  = [];

// Calcular métricas
$pendente   = 0;
$vencido    = 0;
foreach ($cobrancas as $c) {
    $saldo = (float)($c['saldo'] ?? max(0, ($c['valor_total'] ?? 0) - ($c['desconto'] ?? 0) - ($c['valor_pago'] ?? 0)));
    if (($c['status'] ?? '') === 'emitida') $pendente += $saldo;
    if (($c['status'] ?? '') === 'parcial')  $pendente += $saldo;
    if (in_array($c['status'] ?? '', ['vencida']) || (!empty($c['data_vencimento']) && strtotime($c['data_vencimento']) < time() && $saldo > 0)) $vencido += $saldo;
}
$grades  = $boletim['disciplinas'] ?? [];
$media   = $boletim['media'] ?? null;
$records = $presencas['records'] ?? $presencas;
$totalPresencas = is_array($records) ? count($records) : ($presencas['total'] ?? 0);

include dirname(__FILE__) . '/layout_top.php';
?>

<?php if (empty($educandos)): ?>
<div class="portal-card">
    <div class="portal-empty">
        <i class="fa-solid fa-child"></i>
        <p>Não foram encontrados educandos associados à sua conta.</p>
        <p style="font-size:.82rem;margin-top:.5rem">Contacte a secretaria da escola.</p>
    </div>
</div>
<?php else: ?>

<!-- Stats financeiras -->
<div class="portal-stats">
    <div class="portal-stat">
        <span class="portal-stat-label">Propinas pendentes</span>
        <span class="portal-stat-value" style="color:<?= $pendente > 0 ? '#B45309' : '#15803D' ?>">
            <?= number_format($pendente, 2, ',', '.') ?> MT
        </span>
    </div>
    <?php if ($vencido > 0): ?>
    <div class="portal-stat">
        <span class="portal-stat-label">Em atraso</span>
        <span class="portal-stat-value" style="color:#B91C1C"><?= number_format($vencido, 2, ',', '.') ?> MT</span>
    </div>
    <?php endif; ?>
    <?php if ($media !== null): ?>
    <div class="portal-stat">
        <span class="portal-stat-label">Média geral</span>
        <span class="portal-stat-value" style="color:<?= (float)$media >= 10 ? '#15803D' : '#B91C1C' ?>"><?= number_format((float)$media, 1) ?></span>
        <span class="portal-stat-sub"><?= (float)$media >= 10 ? 'Aprovado' : 'Em risco' ?></span>
    </div>
    <?php endif; ?>
    <div class="portal-stat">
        <span class="portal-stat-label">Educandos</span>
        <span class="portal-stat-value"><?= count($educandos) ?></span>
    </div>
</div>

<!-- Boletim resumo -->
<?php if (!empty($grades)): ?>
<div class="portal-card">
    <h3 class="portal-card-title"><i class="fa-solid fa-chart-bar" style="color:var(--enc-primary)"></i> Notas por disciplina</h3>
    <table class="portal-table">
        <thead><tr><th>Disciplina</th><th>Média</th><th>Resultado</th></tr></thead>
        <tbody>
        <?php foreach (array_slice($grades, 0, 8) as $g):
            $nota = (float)($g['media'] ?? 0); $ok = $nota >= 10;
        ?>
        <tr>
            <td style="font-weight:600"><?= htmlspecialchars($g['nome'] ?? $g['disciplina'] ?? '') ?></td>
            <td style="font-weight:700;color:<?= $ok ? '#15803D' : '#B91C1C' ?>"><?= number_format($nota, 1) ?></td>
            <td><span class="portal-badge <?= $ok ? 'badge-green' : 'badge-red' ?>"><?= $ok ? 'Aprovado' : 'Reprovado' ?></span></td>
        </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
    <div style="text-align:right;margin-top:.5rem">
        <a href="/portal/encarregado/boletim?educando_id=<?= htmlspecialchars($selectedHash) ?>" style="font-size:.82rem;color:var(--enc-primary);font-weight:600;text-decoration:none">
            Ver boletim completo →
        </a>
    </div>
</div>
<?php endif; ?>

<!-- Cobranças pendentes -->
<?php $cobPend = array_filter($cobrancas, fn($c) => in_array($c['status'] ?? '', ['emitida','parcial','vencida'])); ?>
<?php if (!empty($cobPend)): ?>
<div class="portal-card">
    <h3 class="portal-card-title"><i class="fa-solid fa-file-invoice-dollar" style="color:var(--enc-primary)"></i> Propinas por regularizar</h3>
    <table class="portal-table">
        <thead><tr><th>Descrição</th><th>Vencimento</th><th>Saldo</th><th>Estado</th></tr></thead>
        <tbody>
        <?php foreach (array_slice(array_values($cobPend), 0, 5) as $c):
            $saldo = (float)($c['saldo'] ?? 0);
            $venc  = !empty($c['data_vencimento']) && strtotime($c['data_vencimento']) < time();
        ?>
        <tr>
            <td><?= htmlspecialchars($c['descricao'] ?? '') ?></td>
            <td style="font-size:.82rem;color:<?= $venc ? '#B91C1C' : '#64748B' ?>">
                <?= !empty($c['data_vencimento']) ? date('d/m/Y', strtotime($c['data_vencimento'])) : '—' ?>
            </td>
            <td style="font-weight:700"><?= number_format($saldo, 2, ',', '.') ?> MT</td>
            <td><span class="portal-badge <?= $venc ? 'badge-red' : 'badge-yellow' ?>"><?= $venc ? 'Vencida' : 'Pendente' ?></span></td>
        </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</div>
<?php endif; ?>
<?php endif; ?>

<?php include dirname(__FILE__) . '/layout_bottom.php'; ?>
