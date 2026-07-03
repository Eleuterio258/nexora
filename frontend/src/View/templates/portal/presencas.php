<?php
declare(strict_types=1);

$pageTitle  = 'Presenças e Faltas';
$activePage = 'presencas';

$_presBody  = $portalData['presencas']['body'] ?? [];
$alunoInfo  = $portalData['me']['body'] ?? [];

// Suporta resposta paginada {records,total,...} e array plano (retrocompatibilidade)
$presencas  = isset($_presBody['records']) ? ($_presBody['records'] ?? []) : $_presBody;
$totalPages = $_presBody['paginas'] ?? 1;
$currentPage= (int)($_GET['page'] ?? 1);

$mes = $_GET['mes'] ?? date('Y-m');
$aba = $_GET['aba'] ?? 'resumo';

// Calcular estatísticas globais
$total      = count($presencas);
$presentes  = 0;
$faltasInj  = 0;
$faltasJust = 0;
$atrasos    = 0;

// Agrupar por disciplina
$porDisciplina = [];
foreach ($presencas as $p) {
    $disc   = $p['disciplina'] ?? 'Sem disciplina';
    $status = $p['status'] ?? $p['presenca'] ?? 'falta';
    $porDisciplina[$disc][] = $p;

    match($status) {
        'presente'             => $presentes++,
        'falta','ausente'      => $faltasInj++,
        'justificada','autorizada' => $faltasJust++,
        'atraso'               => $atrasos++,
        default                => null,
    };
}
ksort($porDisciplina);

$faltas = $faltasInj + $faltasJust;
$pct    = $total > 0 ? round($presentes / $total * 100) : 0;

include dirname(__FILE__) . '/layout_top.php';
?>

<!-- Filtro mês -->
<div class="portal-card" style="padding:.65rem 1rem;display:flex;align-items:center;gap:.75rem;margin-bottom:1rem">
    <label style="font-size:.82rem;font-weight:600;color:#334155;white-space:nowrap">Mês:</label>
    <form method="GET" style="display:flex;align-items:center;gap:.5rem">
        <input type="hidden" name="aba" value="<?= htmlspecialchars($aba) ?>">
        <input type="month" name="mes" value="<?= htmlspecialchars($mes) ?>"
               onchange="this.form.submit()"
               style="padding:.35rem .75rem;border:1.5px solid #CBD5E1;border-radius:8px;font-size:.875rem;font-family:inherit;outline:none">
    </form>
</div>

<!-- Stats -->
<div class="portal-stats" style="margin-bottom:1rem">
    <div class="portal-stat">
        <span class="portal-stat-label">Aulas registadas</span>
        <span class="portal-stat-value"><?= $total ?></span>
    </div>
    <div class="portal-stat">
        <span class="portal-stat-label">Presentes</span>
        <span class="portal-stat-value" style="color:#15803D"><?= $presentes ?></span>
    </div>
    <div class="portal-stat">
        <span class="portal-stat-label">Faltas injustificadas</span>
        <span class="portal-stat-value" style="color:<?= $faltasInj > 3 ? '#B91C1C' : '#0C4A6E' ?>"><?= $faltasInj ?></span>
    </div>
    <div class="portal-stat">
        <span class="portal-stat-label">Faltas justificadas</span>
        <span class="portal-stat-value" style="color:#F59E0B"><?= $faltasJust ?></span>
    </div>
    <div class="portal-stat">
        <span class="portal-stat-label">Assiduidade</span>
        <span class="portal-stat-value" style="color:<?= $pct >= 75 ? '#15803D' : '#B91C1C' ?>"><?= $pct ?>%</span>
    </div>
</div>

<!-- Barra assiduidade -->
<div class="portal-card" style="padding:.85rem 1.25rem;margin-bottom:1rem">
    <div style="display:flex;justify-content:space-between;font-size:.78rem;color:#64748B;margin-bottom:.4rem">
        <span>Taxa de assiduidade</span>
        <span style="font-weight:700;color:<?= $pct >= 75 ? '#15803D' : '#B91C1C' ?>"><?= $pct ?>%</span>
    </div>
    <div style="height:10px;background:#E2E8F0;border-radius:6px;overflow:hidden">
        <div style="height:100%;width:<?= $pct ?>%;background:<?= $pct >= 75 ? '#22C55E' : '#EF4444' ?>;border-radius:6px"></div>
    </div>
    <div style="display:flex;gap:1rem;margin-top:.5rem;font-size:.75rem;color:#64748B;flex-wrap:wrap">
        <span><span style="display:inline-block;width:10px;height:10px;border-radius:50%;background:#22C55E;margin-right:.25rem"></span>Presente: <?= $presentes ?></span>
        <span><span style="display:inline-block;width:10px;height:10px;border-radius:50%;background:#EF4444;margin-right:.25rem"></span>Injustificada: <?= $faltasInj ?></span>
        <span><span style="display:inline-block;width:10px;height:10px;border-radius:50%;background:#F59E0B;margin-right:.25rem"></span>Justificada: <?= $faltasJust ?></span>
        <?php if ($atrasos > 0): ?>
        <span><span style="display:inline-block;width:10px;height:10px;border-radius:50%;background:#0EA5E9;margin-right:.25rem"></span>Atraso: <?= $atrasos ?></span>
        <?php endif; ?>
    </div>
    <?php if ($pct < 75): ?>
    <div style="margin-top:.5rem;font-size:.77rem;color:#B91C1C;font-weight:600">
        ⚠ Assiduidade abaixo do mínimo requerido (75%)
    </div>
    <?php endif; ?>
</div>

<!-- Tabs -->
<div style="display:flex;gap:.35rem;margin-bottom:1rem;border-bottom:2px solid #E0F2FE">
    <?php foreach (['resumo' => 'Por disciplina', 'historico' => 'Histórico completo'] as $key => $label): ?>
    <a href="?mes=<?= urlencode($mes) ?>&aba=<?= $key ?>"
       style="padding:.5rem 1rem;font-size:.875rem;font-weight:600;text-decoration:none;border-bottom:2px solid <?= $aba === $key ? '#0EA5E9' : 'transparent' ?>;margin-bottom:-2px;color:<?= $aba === $key ? '#0EA5E9' : '#64748B' ?>">
        <?= $label ?>
    </a>
    <?php endforeach; ?>
</div>

<?php if ($aba === 'resumo'): ?>

<!-- Resumo por disciplina -->
<?php if (empty($porDisciplina)): ?>
<div class="portal-card">
    <div class="portal-empty">
        <i class="fa-solid fa-calendar-check"></i>
        <p>Nenhum registo para este mês.</p>
    </div>
</div>
<?php else: ?>
<div class="portal-card" style="padding:0;overflow:hidden">
    <table class="portal-table">
        <thead><tr><th>Disciplina</th><th>Aulas</th><th>Presentes</th><th>Injustificadas</th><th>Justificadas</th><th>Assiduidade</th></tr></thead>
        <tbody>
        <?php foreach ($porDisciplina as $disc => $aulas): ?>
        <?php
        $tot  = count($aulas);
        $pres = count(array_filter($aulas, fn($a) => ($a['status'] ?? $a['presenca'] ?? '') === 'presente'));
        $inj  = count(array_filter($aulas, fn($a) => in_array($a['status'] ?? $a['presenca'] ?? '', ['falta','ausente'], true)));
        $just = count(array_filter($aulas, fn($a) => in_array($a['status'] ?? $a['presenca'] ?? '', ['justificada','autorizada'], true)));
        $pctD = $tot > 0 ? round($pres / $tot * 100) : 0;
        ?>
        <tr>
            <td style="font-weight:600"><?= htmlspecialchars($disc) ?></td>
            <td><?= $tot ?></td>
            <td style="color:#15803D;font-weight:600"><?= $pres ?></td>
            <td style="color:<?= $inj > 0 ? '#B91C1C' : '#64748B' ?>;font-weight:<?= $inj > 0 ? 600 : 400 ?>"><?= $inj ?></td>
            <td style="color:<?= $just > 0 ? '#F59E0B' : '#64748B' ?>"><?= $just ?></td>
            <td>
                <div style="display:flex;align-items:center;gap:.4rem">
                    <div style="flex:1;height:6px;background:#E2E8F0;border-radius:4px;min-width:50px;overflow:hidden">
                        <div style="height:100%;width:<?= $pctD ?>%;background:<?= $pctD >= 75 ? '#22C55E' : '#EF4444' ?>;border-radius:4px"></div>
                    </div>
                    <span style="font-size:.78rem;font-weight:600;color:<?= $pctD >= 75 ? '#15803D' : '#B91C1C' ?>"><?= $pctD ?>%</span>
                </div>
            </td>
        </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</div>
<?php endif; ?>

<?php else: ?>

<!-- Histórico completo -->
<?php if (empty($presencas)): ?>
<div class="portal-card">
    <div class="portal-empty">
        <i class="fa-solid fa-calendar-check"></i>
        <p>Nenhum registo para este mês.</p>
    </div>
</div>
<?php else: ?>
<div class="portal-card" style="padding:0;overflow:hidden">
    <table class="portal-table">
        <thead><tr><th>Data</th><th>Disciplina</th><th>Estado</th><th>Justificação</th></tr></thead>
        <tbody>
        <?php foreach ($presencas as $p): ?>
        <?php
        $statusVal = $p['status'] ?? $p['presenca'] ?? 'falta';
        $badgeClass = match($statusVal) {
            'presente'              => 'badge-green',
            'falta','ausente'       => 'badge-red',
            'justificada','autorizada' => 'badge-yellow',
            'atraso'                => 'badge-blue',
            default                 => 'badge-gray',
        };
        $statusLabel = match($statusVal) {
            'presente'   => 'Presente',
            'falta'      => 'Falta',
            'ausente'    => 'Ausente',
            'justificada'=> 'Justificada',
            'autorizada' => 'Autorizada',
            'atraso'     => 'Atraso',
            default      => ucfirst($statusVal),
        };
        ?>
        <tr>
            <td style="white-space:nowrap"><?= $p['data'] ? date('d/m/Y', strtotime($p['data'])) : '—' ?></td>
            <td><?= htmlspecialchars($p['disciplina'] ?? '—') ?></td>
            <td><span class="portal-badge <?= $badgeClass ?>"><?= $statusLabel ?></span></td>
            <td style="font-size:.8rem;color:#64748B"><?= htmlspecialchars($p['justificacao'] ?? '') ?></td>
        </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</div>
<?php endif; ?>
<?php endif; ?>

<?php if ($totalPages > 1): ?>
<div style="display:flex;justify-content:center;gap:.4rem;margin-top:1rem">
    <?php for ($i = 1; $i <= $totalPages; $i++): ?>
    <a href="?mes=<?= htmlspecialchars($mes) ?>&page=<?= $i ?>&aba=<?= htmlspecialchars($aba) ?>"
       style="padding:.35rem .75rem;border-radius:8px;font-size:.82rem;font-weight:600;text-decoration:none;
              background:<?= $i === $currentPage ? '#0EA5E9' : '#fff' ?>;
              color:<?= $i === $currentPage ? '#fff' : '#334155' ?>;
              border:1.5px solid <?= $i === $currentPage ? '#0EA5E9' : '#CBD5E1' ?>">
        <?= $i ?>
    </a>
    <?php endfor; ?>
</div>
<?php endif; ?>

<?php include dirname(__FILE__) . '/layout_bottom.php'; ?>
