<?php
declare(strict_types=1);

$pageTitle  = 'Ocorrências';
$activePage = 'ocorrencias';

$dados      = $portalData['ocorrencias']['body'] ?? [];
$alunoInfo  = $portalData['me']['body'] ?? [];

$incidentes = $dados['incidentes'] ?? [];
$sancoes    = $dados['sancoes']    ?? [];
$meritos    = $dados['meritos']    ?? [];

$aba = $_GET['aba'] ?? 'incidentes';

include dirname(__FILE__) . '/layout_top.php';
?>

<!-- Tabs -->
<div style="display:flex;gap:.35rem;margin-bottom:1rem;border-bottom:2px solid #E0F2FE;padding-bottom:0">
    <?php
    $tabs = [
        'incidentes' => ['Incidentes', count($incidentes), 'fa-triangle-exclamation', '#EF4444'],
        'sancoes'    => ['Sanções',    count($sancoes),    'fa-ban',                   '#F59E0B'],
        'meritos'    => ['Méritos',    count($meritos),    'fa-star',                  '#22C55E'],
    ];
    foreach ($tabs as $key => [$label, $count, $icon, $cor]):
        $active = $aba === $key;
    ?>
    <a href="?aba=<?= $key ?>"
       style="display:flex;align-items:center;gap:.4rem;padding:.55rem 1rem;font-size:.875rem;font-weight:600;
              text-decoration:none;border-bottom:2px solid <?= $active ? $cor : 'transparent' ?>;
              margin-bottom:-2px;color:<?= $active ? $cor : '#64748B' ?>">
        <i class="fa-solid <?= $icon ?>" style="font-size:.8rem"></i>
        <?= $label ?>
        <span style="background:<?= $active ? $cor.'22' : '#F1F5F9' ?>;color:<?= $active ? $cor : '#64748B' ?>;
                     font-size:.7rem;padding:.1rem .45rem;border-radius:10px"><?= $count ?></span>
    </a>
    <?php endforeach; ?>
</div>

<?php if ($aba === 'incidentes'): ?>
<!-- ── Incidentes disciplinares ── -->
<?php if (empty($incidentes)): ?>
<div class="portal-card">
    <div class="portal-empty">
        <i class="fa-solid fa-shield-check" style="color:#22C55E"></i>
        <p>Sem ocorrências disciplinares registadas.</p>
    </div>
</div>
<?php else: ?>
<div style="display:flex;flex-direction:column;gap:.75rem">
<?php foreach ($incidentes as $inc): ?>
<?php
$gravidade = $inc['gravidade'] ?? 'leve';
$gravCorMap = ['leve' => ['#F59E0B','badge-yellow'], 'moderada' => ['#EF4444','badge-red'], 'grave' => ['#7C3AED','badge-red']];
[$gravCor, $gravBadge] = $gravCorMap[$gravidade] ?? ['#64748B','badge-gray'];
$statusMap = ['registada'=>'badge-gray','em_analise'=>'badge-yellow','resolvida'=>'badge-green','arquivada'=>'badge-gray'];
?>
<div class="portal-card" style="margin:0;border-left:4px solid <?= $gravCor ?>">
    <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:.5rem;margin-bottom:.6rem">
        <div>
            <div style="font-weight:700;font-size:.9rem;color:#0C4A6E">
                <?= htmlspecialchars($inc['tipo'] ?? 'Ocorrência') ?>
            </div>
            <div style="font-size:.77rem;color:#64748B;margin-top:.1rem">
                <i class="fa-regular fa-calendar" style="font-size:.7rem"></i>
                <?= $inc['data_ocorrencia'] ? date('d/m/Y', strtotime($inc['data_ocorrencia'])) : '' ?>
                <?php if (!empty($inc['local'])): ?>
                · <i class="fa-solid fa-location-dot" style="font-size:.7rem"></i> <?= htmlspecialchars($inc['local']) ?>
                <?php endif; ?>
            </div>
        </div>
        <div style="display:flex;flex-direction:column;gap:.3rem;align-items:flex-end">
            <span class="portal-badge <?= $gravBadge ?>">
                <?= ucfirst($gravidade) ?>
            </span>
            <span class="portal-badge <?= $statusMap[$inc['status'] ?? 'registada'] ?? 'badge-gray' ?>">
                <?= str_replace('_', ' ', ucfirst($inc['status'] ?? 'registada')) ?>
            </span>
        </div>
    </div>
    <p style="font-size:.85rem;color:#334155;line-height:1.6;margin:0">
        <?= htmlspecialchars($inc['descricao'] ?? '') ?>
    </p>
</div>
<?php endforeach; ?>
</div>
<?php endif; ?>

<?php elseif ($aba === 'sancoes'): ?>
<!-- ── Sanções ── -->
<?php if (empty($sancoes)): ?>
<div class="portal-card">
    <div class="portal-empty">
        <i class="fa-solid fa-circle-check" style="color:#22C55E"></i>
        <p>Sem sanções registadas.</p>
    </div>
</div>
<?php else: ?>
<table class="portal-table" style="background:#fff;border-radius:12px;overflow:hidden;border:1px solid #E0F2FE">
    <thead><tr><th>Tipo</th><th>Início</th><th>Fim</th><th>Estado</th><th>Motivo</th></tr></thead>
    <tbody>
    <?php foreach ($sancoes as $s): ?>
    <tr>
        <td style="font-weight:600"><?= htmlspecialchars($s['tipo'] ?? 'Sanção') ?></td>
        <td><?= $s['data_inicio'] ? date('d/m/Y', strtotime($s['data_inicio'])) : '—' ?></td>
        <td><?= $s['data_fim'] ? date('d/m/Y', strtotime($s['data_fim'])) : '—' ?></td>
        <td>
            <?php $activa = empty($s['data_fim']) || strtotime($s['data_fim']) >= time(); ?>
            <span class="portal-badge <?= $activa ? 'badge-red' : 'badge-gray' ?>">
                <?= $activa ? 'Activa' : 'Concluída' ?>
            </span>
        </td>
        <td style="font-size:.82rem;color:#64748B;max-width:200px">
            <?= htmlspecialchars(\mb_strimwidth($s['motivo'] ?? '', 0, 80, '…')) ?>
        </td>
    </tr>
    <?php endforeach; ?>
    </tbody>
</table>
<?php endif; ?>

<?php else: ?>
<!-- ── Méritos ── -->
<?php if (empty($meritos)): ?>
<div class="portal-card">
    <div class="portal-empty">
        <i class="fa-solid fa-star" style="color:#94A3B8"></i>
        <p>Sem méritos registados ainda. Continue a trabalhar!</p>
    </div>
</div>
<?php else: ?>
<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:.85rem">
<?php foreach ($meritos as $m): ?>
<div style="background:#fff;border-radius:12px;border:1px solid #E0F2FE;padding:1rem;
            border-top:4px solid #F59E0B">
    <div style="display:flex;align-items:center;gap:.5rem;margin-bottom:.5rem">
        <div style="width:36px;height:36px;border-radius:50%;background:#FEF9C3;display:flex;align-items:center;justify-content:center">
            <i class="fa-solid fa-star" style="color:#F59E0B;font-size:.9rem"></i>
        </div>
        <div>
            <div style="font-weight:700;font-size:.875rem;color:#0C4A6E"><?= htmlspecialchars($m['titulo'] ?? '') ?></div>
            <div style="font-size:.73rem;color:#64748B"><?= $m['data_merito'] ? date('d/m/Y', strtotime($m['data_merito'])) : '' ?></div>
        </div>
    </div>
    <?php if (!empty($m['descricao'])): ?>
    <p style="font-size:.82rem;color:#334155;line-height:1.55;margin:0"><?= htmlspecialchars($m['descricao']) ?></p>
    <?php endif; ?>
</div>
<?php endforeach; ?>
</div>
<?php endif; ?>
<?php endif; ?>

<?php include dirname(__FILE__) . '/layout_bottom.php'; ?>
