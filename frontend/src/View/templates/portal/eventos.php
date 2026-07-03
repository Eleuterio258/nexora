<?php
declare(strict_types=1);

$pageTitle  = 'Eventos';
$activePage = 'eventos';

$eventos    = $portalData['eventos']['body'] ?? [];
$alunoInfo  = $portalData['me']['body'] ?? [];

include dirname(__FILE__) . '/layout_top.php';
?>

<?php if (empty($eventos)): ?>
<div class="portal-card">
    <div class="portal-empty">
        <i class="fa-solid fa-calendar-days"></i>
        <p>Nenhum evento programado.</p>
    </div>
</div>
<?php else: ?>
<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:1rem">
<?php foreach ($eventos as $ev): ?>
<?php
    $cor = htmlspecialchars($ev['cor'] ?? '#0EA5E9');
    $dataInicio = $ev['data_inicio'] ? date('d/m/Y', strtotime($ev['data_inicio'])) : '';
    $dataFim    = !empty($ev['data_fim']) && $ev['data_fim'] !== $ev['data_inicio']
                    ? date('d/m/Y', strtotime($ev['data_fim'])) : '';
?>
<div style="background:#fff;border-radius:12px;border:1px solid #E0F2FE;overflow:hidden">
    <div style="height:5px;background:<?= $cor ?>"></div>
    <div style="padding:1rem">
        <div style="font-size:.72rem;font-weight:700;color:<?= $cor ?>;text-transform:uppercase;letter-spacing:.05em;margin-bottom:.3rem">
            <?= htmlspecialchars($ev['tipo'] ?? 'Evento') ?>
        </div>
        <h3 style="font-size:.925rem;font-weight:700;color:#0C4A6E;margin:0 0 .5rem">
            <?= htmlspecialchars($ev['titulo'] ?? '') ?>
        </h3>
        <?php if (!empty($ev['descricao'])): ?>
        <p style="font-size:.82rem;color:#64748B;margin:0 0 .65rem;line-height:1.5">
            <?= htmlspecialchars($ev['descricao']) ?>
        </p>
        <?php endif; ?>
        <div style="font-size:.78rem;color:#64748B;display:flex;align-items:center;gap:.4rem">
            <i class="fa-regular fa-calendar" style="color:<?= $cor ?>"></i>
            <?= $dataInicio ?><?= $dataFim ? " → $dataFim" : '' ?>
        </div>
        <?php if (!empty($ev['local'])): ?>
        <div style="font-size:.78rem;color:#94A3B8;margin-top:.3rem">
            <i class="fa-solid fa-location-dot" style="font-size:.73rem"></i> <?= htmlspecialchars($ev['local']) ?>
        </div>
        <?php endif; ?>
    </div>
</div>
<?php endforeach; ?>
</div>
<?php endif; ?>

<?php include dirname(__FILE__) . '/layout_bottom.php'; ?>
