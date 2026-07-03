<?php
$turmaData  = $portalData['turma']['body'] ?? [];
$alunos     = $portalData['alunos']['body']['data'] ?? $portalData['alunos']['body'] ?? [];
$turmaNome  = $turmaData['nome'] ?? $turmaData['turma'] ?? 'Turma';
$pageTitle  = $turmaNome;
$activePage = 'turmas';

require __DIR__ . '/layout_top.php';
?>

<div style="margin-bottom:1rem">
    <a href="/portal/professor/turmas" style="font-size:.85rem;color:var(--prof-primary);text-decoration:none">
        <i class="fa-solid fa-arrow-left"></i> Voltar às turmas
    </a>
</div>

<div class="portal-stats">
    <div class="portal-stat">
        <span class="portal-stat-label">Disciplina</span>
        <span class="portal-stat-value" style="font-size:1.1rem"><?= htmlspecialchars($turmaData['disciplina'] ?? '—') ?></span>
    </div>
    <div class="portal-stat">
        <span class="portal-stat-label">Total Alunos</span>
        <span class="portal-stat-value"><?= count($alunos) ?></span>
    </div>
    <div class="portal-stat">
        <span class="portal-stat-label">Ano Lectivo</span>
        <span class="portal-stat-value" style="font-size:1rem"><?= htmlspecialchars($turmaData['ano_lectivo'] ?? '—') ?></span>
    </div>
</div>

<div class="portal-card">
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:1rem">
        <p class="portal-card-title" style="margin:0;border:none"><i class="fa-solid fa-users" style="color:var(--prof-primary)"></i> Lista de Alunos</p>
        <div style="display:flex;gap:.5rem">
            <a href="/portal/professor/presencas?turma_id=<?= (int)($_GET['id'] ?? 0) ?>" class="btn-primary" style="font-size:.8rem">
                <i class="fa-solid fa-calendar-check"></i> Registar Presenças
            </a>
            <a href="/portal/professor/notas?turma_id=<?= (int)($_GET['id'] ?? 0) ?>" class="btn-secondary" style="font-size:.8rem">
                <i class="fa-solid fa-star-half-stroke"></i> Lançar Notas
            </a>
        </div>
    </div>

    <?php if (empty($alunos)): ?>
    <div class="portal-empty"><i class="fa-solid fa-users"></i>Sem alunos nesta turma.</div>
    <?php else: ?>
    <table class="portal-table">
        <thead>
            <tr>
                <th>#</th>
                <th>Nome</th>
                <th>Código</th>
                <th>Estado</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($alunos as $i => $a): ?>
        <tr>
            <td style="color:#94A3B8;font-size:.8rem"><?= $i + 1 ?></td>
            <td style="font-weight:600"><?= htmlspecialchars($a['nome'] ?? $a['aluno_nome'] ?? '—') ?></td>
            <td style="font-family:monospace;font-size:.82rem"><?= htmlspecialchars($a['codigo'] ?? $a['numero'] ?? '—') ?></td>
            <td>
                <?php $estado = $a['estado'] ?? 'activo'; ?>
                <span class="portal-badge <?= $estado === 'activo' ? 'badge-green' : 'badge-gray' ?>">
                    <?= htmlspecialchars(ucfirst($estado)) ?>
                </span>
            </td>
        </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
    <?php endif; ?>
</div>

<?php require __DIR__ . '/layout_bottom.php'; ?>
