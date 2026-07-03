<?php
$pageTitle  = 'Horário';
$activePage = 'horario';
$horario    = $portalData['horario']['body']['data'] ?? $portalData['horario']['body'] ?? [];

$dias = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta'];
$porDia = [];
foreach ($horario as $aula) {
    $dia = $aula['dia'] ?? '';
    $porDia[$dia][] = $aula;
}
foreach ($porDia as &$aulas) {
    usort($aulas, fn($a, $b) => strcmp($a['hora_inicio'] ?? '', $b['hora_inicio'] ?? ''));
}

require __DIR__ . '/layout_top.php';
?>

<?php if (empty($horario)): ?>
<div class="portal-card">
    <div class="portal-empty">
        <i class="fa-solid fa-calendar-days"></i>
        Não tem aulas atribuídas neste momento.
    </div>
</div>
<?php else: ?>
<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:1rem">
<?php foreach ($dias as $dia): ?>
<?php $aulas = $porDia[$dia] ?? []; ?>
<div class="portal-card" style="margin-bottom:0">
    <p class="portal-card-title"><?= $dia ?>-feira</p>
    <?php if (empty($aulas)): ?>
    <p style="font-size:.82rem;color:#94A3B8;text-align:center;padding:.75rem 0">Sem aulas</p>
    <?php else: ?>
    <?php foreach ($aulas as $aula): ?>
    <div style="border-left:3px solid var(--prof-primary);padding:.5rem .75rem;margin-bottom:.5rem;border-radius:0 6px 6px 0;background:var(--prof-bg)">
        <div style="font-size:.72rem;color:#64748B;font-weight:600"><?= htmlspecialchars($aula['hora_inicio'] ?? '') ?>–<?= htmlspecialchars($aula['hora_fim'] ?? '') ?></div>
        <div style="font-size:.85rem;font-weight:700;color:#1E293B"><?= htmlspecialchars($aula['disciplina'] ?? '—') ?></div>
        <div style="font-size:.78rem;color:#64748B"><?= htmlspecialchars($aula['turma'] ?? '') ?> <?= !empty($aula['sala']) ? '· Sala ' . htmlspecialchars($aula['sala']) : '' ?></div>
    </div>
    <?php endforeach; ?>
    <?php endif; ?>
</div>
<?php endforeach; ?>
</div>
<?php endif; ?>

<?php require __DIR__ . '/layout_bottom.php'; ?>
