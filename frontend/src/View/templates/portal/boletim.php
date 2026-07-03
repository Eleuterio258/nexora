<?php
declare(strict_types=1);

$pageTitle  = 'Boletim';
$activePage = 'boletim';

$boletim    = $portalData['boletim']['body'] ?? [];
$alunoInfo  = $portalData['me']['body'] ?? [];

$termos     = $boletim['terms'] ?? [];
$periodoActual = $boletim['current_term'] ?? null;
$termId     = (int) ($_GET['term_id'] ?? 0);

include dirname(__FILE__) . '/layout_top.php';
?>

<!-- Acções: imprimir -->
<div style="display:flex;justify-content:flex-end;margin-bottom:.75rem">
    <a href="/portal/aluno/boletim/imprimir<?= $termId ? "?term_id=$termId" : '' ?>"
       target="_blank"
       style="display:inline-flex;align-items:center;gap:.4rem;padding:.4rem .85rem;border-radius:8px;
              background:#0369A1;color:#fff;text-decoration:none;font-size:.82rem;font-weight:600">
        <i class="fa-solid fa-print"></i> Imprimir / PDF
    </a>
</div>

<!-- Selector de período -->
<?php if (!empty($termos)): ?>
<div class="portal-card" style="padding:.75rem 1rem;display:flex;align-items:center;gap:.75rem;margin-bottom:1rem">
    <label style="font-size:.82rem;font-weight:600;color:#334155;white-space:nowrap">Período:</label>
    <form method="GET" style="display:flex;gap:.5rem;align-items:center">
        <select name="term_id" onchange="this.form.submit()"
                style="padding:.4rem .75rem;border:1.5px solid #CBD5E1;border-radius:8px;font-size:.875rem;font-family:inherit;outline:none;background:#fff;color:#1E293B">
            <option value="">Período actual</option>
            <?php foreach ($termos as $t): ?>
            <option value="<?= (int)$t['id'] ?>" <?= $termId === (int)$t['id'] ? 'selected' : '' ?>>
                <?= htmlspecialchars($t['nome'] ?? "Período {$t['id']}") ?>
            </option>
            <?php endforeach; ?>
        </select>
    </form>
    <?php if (!empty($periodoActual)): ?>
    <span style="font-size:.78rem;color:#64748B">
        Período actual: <strong><?= htmlspecialchars($periodoActual['nome'] ?? '') ?></strong>
    </span>
    <?php endif; ?>
</div>
<?php endif; ?>

<?php
$disciplinas = $boletim['subjects'] ?? $boletim['grades'] ?? [];
$media = $boletim['media'] ?? $boletim['average'] ?? null;
$totalFaltas = $boletim['total_absences'] ?? null;
?>

<!-- Média geral -->
<?php if ($media !== null): ?>
<div class="portal-stats" style="grid-template-columns:repeat(3,1fr);margin-bottom:1rem">
    <div class="portal-stat">
        <span class="portal-stat-label">Média geral</span>
        <span class="portal-stat-value" style="color:<?= (float)$media >= 10 ? '#15803D' : '#B91C1C' ?>">
            <?= number_format((float)$media, 1) ?>
        </span>
        <span class="portal-stat-sub"><?= (float)$media >= 10 ? 'Aprovado' : 'Em risco' ?></span>
    </div>
    <?php if ($totalFaltas !== null): ?>
    <div class="portal-stat">
        <span class="portal-stat-label">Total de faltas</span>
        <span class="portal-stat-value"><?= (int)$totalFaltas ?></span>
    </div>
    <?php endif; ?>
    <div class="portal-stat">
        <span class="portal-stat-label">Disciplinas</span>
        <span class="portal-stat-value"><?= count($disciplinas) ?></span>
    </div>
</div>
<?php endif; ?>

<!-- Notas por disciplina -->
<?php if (empty($disciplinas)): ?>
<div class="portal-card">
    <div class="portal-empty">
        <i class="fa-solid fa-chart-bar"></i>
        <p>Ainda não há notas lançadas para este período.</p>
    </div>
</div>
<?php else: ?>
<div class="portal-card">
    <h3 class="portal-card-title">Notas por disciplina</h3>
    <table class="portal-table">
        <thead>
            <tr>
                <th>Disciplina</th>
                <th>P1</th><th>P2</th><th>P3</th>
                <th>Exame</th>
                <th>Média</th>
                <th>Resultado</th>
                <th>Faltas</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($disciplinas as $d): ?>
        <?php
            $nota = (float) ($d['media'] ?? $d['average'] ?? $d['nota'] ?? 0);
            $aprovado = $nota >= 10;
        ?>
        <tr>
            <td style="font-weight:600"><?= htmlspecialchars($d['nome'] ?? $d['subject_name'] ?? $d['disciplina'] ?? '') ?></td>
            <td><?= $d['p1'] ?? $d['nota_p1'] ?? '—' ?></td>
            <td><?= $d['p2'] ?? $d['nota_p2'] ?? '—' ?></td>
            <td><?= $d['p3'] ?? $d['nota_p3'] ?? '—' ?></td>
            <td><?= $d['exame'] ?? $d['nota_exame'] ?? '—' ?></td>
            <td style="font-weight:700;color:<?= $aprovado ? '#15803D' : '#B91C1C' ?>"><?= number_format($nota, 1) ?></td>
            <td>
                <span class="portal-badge <?= $aprovado ? 'badge-green' : 'badge-red' ?>">
                    <?= $aprovado ? 'Aprovado' : 'Reprovado' ?>
                </span>
            </td>
            <td><?= $d['faltas'] ?? $d['absences'] ?? '—' ?></td>
        </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</div>
<?php endif; ?>

<?php include dirname(__FILE__) . '/layout_bottom.php'; ?>
