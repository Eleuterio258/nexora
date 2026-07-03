<?php
$pageTitle  = 'As Minhas Turmas';
$activePage = 'turmas';
$turmas     = $portalData['turmas']['body']['data'] ?? $portalData['turmas']['body'] ?? [];

require __DIR__ . '/layout_top.php';
?>

<?php if (empty($turmas)): ?>
<div class="portal-card">
    <div class="portal-empty">
        <i class="fa-solid fa-users-rectangle"></i>
        Não tem turmas atribuídas neste momento.
    </div>
</div>
<?php else: ?>
<div class="portal-card">
    <p class="portal-card-title"><i class="fa-solid fa-users-rectangle" style="color:var(--prof-primary)"></i> Turmas Atribuídas</p>
    <table class="portal-table">
        <thead>
            <tr>
                <th>Turma</th>
                <th>Disciplina</th>
                <th>Ano Lectivo</th>
                <th>Total Alunos</th>
                <th></th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($turmas as $t): ?>
        <tr>
            <td style="font-weight:600"><?= htmlspecialchars($t['nome'] ?? $t['turma'] ?? '—') ?></td>
            <td><?= htmlspecialchars($t['disciplina'] ?? '—') ?></td>
            <td><?= htmlspecialchars($t['ano_lectivo'] ?? '—') ?></td>
            <td><?= (int)($t['total_alunos'] ?? 0) ?></td>
            <td>
                <a href="/portal/professor/turma?id=<?= (int)($t['id'] ?? 0) ?>" class="btn-secondary" style="font-size:.78rem;padding:.3rem .7rem">
                    <i class="fa-solid fa-eye"></i> Ver
                </a>
            </td>
        </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</div>
<?php endif; ?>

<?php require __DIR__ . '/layout_bottom.php'; ?>
