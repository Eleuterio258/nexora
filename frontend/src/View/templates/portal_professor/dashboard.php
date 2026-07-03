<?php
$pageTitle  = 'Início';
$activePage = 'dashboard';
$turmas     = $portalData['turmas']['body']['data']    ?? $portalData['turmas']['body']    ?? [];
$horario    = $portalData['horario']['body']['data']   ?? $portalData['horario']['body']   ?? [];
$msgs       = $portalData['comunicacao']['body']['data'] ?? $portalData['comunicacao']['body'] ?? [];

require __DIR__ . '/layout_top.php';
?>

<div class="portal-stats">
    <div class="portal-stat">
        <span class="portal-stat-label">Turmas</span>
        <span class="portal-stat-value"><?= count($turmas) ?></span>
        <span class="portal-stat-sub">atribuídas</span>
    </div>
    <div class="portal-stat">
        <span class="portal-stat-label">Aulas hoje</span>
        <span class="portal-stat-value">
            <?php
            $hoje = date('l');
            $diasMap = ['Monday'=>'Segunda','Tuesday'=>'Terça','Wednesday'=>'Quarta','Thursday'=>'Quinta','Friday'=>'Sexta','Saturday'=>'Sábado','Sunday'=>'Domingo'];
            $diaHoje = $diasMap[$hoje] ?? $hoje;
            $aulasHoje = array_filter($horario, fn($a) => strcasecmp($a['dia'] ?? '', $diaHoje) === 0);
            echo count($aulasHoje);
            ?>
        </span>
        <span class="portal-stat-sub"><?= $diaHoje ?></span>
    </div>
    <div class="portal-stat">
        <span class="portal-stat-label">Mensagens</span>
        <span class="portal-stat-value"><?= count($msgs) ?></span>
        <span class="portal-stat-sub">recebidas</span>
    </div>
</div>

<div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;flex-wrap:wrap">

<div class="portal-card">
    <p class="portal-card-title"><i class="fa-solid fa-users-rectangle" style="color:var(--prof-primary)"></i> As Minhas Turmas</p>
    <?php if (empty($turmas)): ?>
    <div class="portal-empty"><i class="fa-solid fa-users-rectangle"></i>Sem turmas atribuídas</div>
    <?php else: ?>
    <table class="portal-table">
        <thead><tr><th>Turma</th><th>Disciplina</th><th>Alunos</th></tr></thead>
        <tbody>
        <?php foreach (array_slice($turmas, 0, 5) as $t): ?>
        <tr>
            <td><a href="/portal/professor/turma?id=<?= (int)($t['id'] ?? 0) ?>" style="color:var(--prof-primary);text-decoration:none;font-weight:600"><?= htmlspecialchars($t['nome'] ?? $t['turma'] ?? '—') ?></a></td>
            <td><?= htmlspecialchars($t['disciplina'] ?? '—') ?></td>
            <td><?= (int)($t['total_alunos'] ?? 0) ?></td>
        </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
    <?php if (count($turmas) > 5): ?>
    <div style="text-align:right;margin-top:.75rem"><a href="/portal/professor/turmas" style="font-size:.8rem;color:var(--prof-primary)">Ver todas →</a></div>
    <?php endif; ?>
    <?php endif; ?>
</div>

<div class="portal-card">
    <p class="portal-card-title"><i class="fa-solid fa-calendar-days" style="color:var(--prof-primary)"></i> Aulas Hoje</p>
    <?php if (empty($aulasHoje)): ?>
    <div class="portal-empty"><i class="fa-solid fa-calendar-days"></i>Sem aulas hoje</div>
    <?php else: ?>
    <table class="portal-table">
        <thead><tr><th>Hora</th><th>Turma</th><th>Disciplina</th></tr></thead>
        <tbody>
        <?php foreach ($aulasHoje as $aula): ?>
        <tr>
            <td><?= htmlspecialchars($aula['hora_inicio'] ?? '') ?>–<?= htmlspecialchars($aula['hora_fim'] ?? '') ?></td>
            <td><?= htmlspecialchars($aula['turma'] ?? '—') ?></td>
            <td><?= htmlspecialchars($aula['disciplina'] ?? '—') ?></td>
        </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
    <?php endif; ?>
</div>

</div>

<?php require __DIR__ . '/layout_bottom.php'; ?>
