<?php
declare(strict_types=1);

$pageTitle  = 'Horário';
$activePage = 'horario';

$slots      = $portalData['horario']['body'] ?? [];
$alunoInfo  = $portalData['me']['body'] ?? [];

$diasSemana = [1=>'Segunda',2=>'Terça',3=>'Quarta',4=>'Quinta',5=>'Sexta',6=>'Sábado'];

$porDia = [];
foreach ($slots as $s) {
    $dia = (int)($s['dia_semana'] ?? 0);
    $porDia[$dia][] = $s;
}
ksort($porDia);

include dirname(__FILE__) . '/layout_top.php';
?>

<?php if (empty($slots)): ?>
<div class="portal-card">
    <div class="portal-empty">
        <i class="fa-solid fa-clock"></i>
        <p>O horário ainda não foi configurado para a sua turma.</p>
    </div>
</div>
<?php else: ?>
<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:1rem">
<?php foreach ($porDia as $dia => $aulas): ?>
<div class="portal-card" style="padding:0;overflow:hidden">
    <div style="background:#0369A1;color:#fff;padding:.65rem 1rem;font-weight:700;font-size:.875rem">
        <?= $diasSemana[$dia] ?? "Dia $dia" ?>
    </div>
    <div style="padding:.5rem">
    <?php foreach ($aulas as $a): ?>
    <div style="padding:.6rem .75rem;border-radius:8px;background:#F0F9FF;margin-bottom:.35rem">
        <div style="display:flex;align-items:center;justify-content:space-between;gap:.75rem">
            <span style="font-size:.73rem;color:#0EA5E9;font-weight:700;white-space:nowrap">
            <?= htmlspecialchars($a['hora_inicio'] ?? '') ?> – <?= htmlspecialchars($a['hora_fim'] ?? '') ?>
            </span>
            <span style="font-weight:600;font-size:.875rem;color:#0C4A6E;text-align:right">
            <?= htmlspecialchars($a['disciplina'] ?? '') ?>
            </span>
        </div>
        <?php if (!empty($a['professor'])): ?>
        <div style="font-size:.77rem;color:#64748B;margin-top:.1rem">
            <i class="fa-solid fa-chalkboard-teacher" style="font-size:.7rem"></i>
            <?= htmlspecialchars($a['professor']) ?>
        </div>
        <?php endif; ?>
        <?php if (!empty($a['sala'])): ?>
        <div style="font-size:.75rem;color:#94A3B8">
            <i class="fa-solid fa-door-open" style="font-size:.7rem"></i> <?= htmlspecialchars($a['sala']) ?>
        </div>
        <?php endif; ?>
    </div>
    <?php endforeach; ?>
    </div>
</div>
<?php endforeach; ?>
</div>
<?php endif; ?>

<?php include dirname(__FILE__) . '/layout_bottom.php'; ?>
