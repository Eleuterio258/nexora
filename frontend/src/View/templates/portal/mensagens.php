<?php
declare(strict_types=1);

$pageTitle  = 'Avisos & Comunicados';
$activePage = 'mensagens';

$mensagens  = $portalData['mensagens']['body'] ?? [];
$alunoInfo  = $portalData['me']['body'] ?? [];

include dirname(__FILE__) . '/layout_top.php';
?>

<?php if (empty($mensagens)): ?>
<div class="portal-card">
    <div class="portal-empty">
        <i class="fa-solid fa-inbox"></i>
        <p>Nenhum comunicado de momento.</p>
    </div>
</div>
<?php else: ?>
<div style="display:flex;flex-direction:column;gap:.75rem">
<?php foreach ($mensagens as $m): ?>
<?php
    $audienceType = $m['audience_type'] ?? 'todos';
    $tipo = $m['tipo'] ?? 'comunicado';
    $badgeClass = match($tipo) {
        'urgente' => 'badge-red',
        'aviso'   => 'badge-yellow',
        default   => 'badge-blue',
    };
?>
<div class="portal-card" style="margin-bottom:0">
    <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:.75rem;margin-bottom:.75rem">
        <div>
            <h3 style="font-size:.95rem;font-weight:700;color:#0C4A6E;margin:0 0 .2rem">
                <?= htmlspecialchars($m['titulo'] ?? '') ?>
            </h3>
            <div style="display:flex;align-items:center;gap:.5rem;font-size:.77rem;color:#64748B">
                <?php if (!empty($m['publicado_em'])): ?>
                <span><i class="fa-regular fa-calendar"></i> <?= date('d/m/Y', strtotime($m['publicado_em'])) ?></span>
                <?php endif; ?>
                <?php if ($audienceType === 'turma'): ?>
                <span class="portal-badge badge-blue"><i class="fa-solid fa-users" style="font-size:.65rem"></i> Para a sua turma</span>
                <?php elseif ($audienceType === 'aluno'): ?>
                <span class="portal-badge badge-green"><i class="fa-solid fa-user" style="font-size:.65rem"></i> Para si</span>
                <?php endif; ?>
            </div>
        </div>
        <span class="portal-badge <?= $badgeClass ?>"><?= ucfirst($tipo) ?></span>
    </div>
    <div style="font-size:.875rem;color:#334155;line-height:1.65;white-space:pre-line">
        <?= htmlspecialchars($m['conteudo'] ?? '') ?>
    </div>
</div>
<?php endforeach; ?>
</div>
<?php endif; ?>

<?php include dirname(__FILE__) . '/layout_bottom.php'; ?>
