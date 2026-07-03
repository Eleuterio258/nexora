<?php
$pageTitle    = 'Notas';
$activePage   = 'notas';
$turmas       = $portalData['turmas']['body']['data'] ?? $portalData['turmas']['body'] ?? [];
$notasRaw     = $portalData['notas']['body']['data']  ?? $portalData['notas']['body']  ?? [];
$alunos       = $notasRaw['alunos'] ?? $notasRaw ?? [];
$periodos     = $notasRaw['periodos'] ?? [];
$turmaId      = (int)($_GET['turma_id'] ?? 0);
$disciplinaId = (int)($_GET['disciplina_id'] ?? 0);

require __DIR__ . '/layout_top.php';
?>

<div class="portal-card" style="margin-bottom:1rem">
    <form method="get" style="display:flex;gap:.75rem;align-items:flex-end;flex-wrap:wrap">
        <div>
            <label style="display:block;font-size:.78rem;font-weight:600;color:#64748B;margin-bottom:.25rem">Turma</label>
            <select name="turma_id" style="padding:.45rem .75rem;border:1px solid #E2E8F0;border-radius:8px;font-size:.85rem;min-width:160px" id="sel-turma">
                <option value="">Seleccionar turma</option>
                <?php foreach ($turmas as $t): ?>
                <option value="<?= (int)($t['id'] ?? 0) ?>"
                    data-disc-id="<?= (int)($t['disciplina_id'] ?? 0) ?>"
                    <?= $turmaId === (int)($t['id'] ?? 0) ? 'selected' : '' ?>>
                    <?= htmlspecialchars($t['nome'] ?? $t['turma'] ?? '') ?> – <?= htmlspecialchars($t['disciplina'] ?? '') ?>
                </option>
                <?php endforeach; ?>
            </select>
        </div>
        <button type="submit" class="btn-primary"><i class="fa-solid fa-search"></i> Carregar</button>
    </form>
</div>

<?php if ($turmaId && !empty($alunos)): ?>
<div class="portal-card">
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:1rem">
        <p class="portal-card-title" style="margin:0;border:none">
            <i class="fa-solid fa-star-half-stroke" style="color:var(--prof-primary)"></i>
            Lançamento de Notas
        </p>
        <button class="btn-primary" id="btn-gravar-notas" style="font-size:.82rem">
            <i class="fa-solid fa-floppy-disk"></i> Gravar
        </button>
    </div>

    <form id="form-notas">
    <div style="overflow-x:auto">
    <table class="portal-table">
        <thead>
            <tr>
                <th>Aluno</th>
                <?php foreach ($periodos as $p): ?>
                <th><?= htmlspecialchars($p['nome'] ?? $p) ?></th>
                <?php endforeach; ?>
                <?php if (empty($periodos)): ?>
                <th>Nota</th>
                <?php endif; ?>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($alunos as $a):
            $aid = (int)($a['aluno_id'] ?? $a['id'] ?? 0);
            $notas = $a['notas'] ?? [];
        ?>
        <tr>
            <td style="font-weight:600"><?= htmlspecialchars($a['nome'] ?? $a['aluno_nome'] ?? '—') ?></td>
            <?php if (!empty($periodos)): ?>
            <?php foreach ($periodos as $p):
                $pid = (int)($p['id'] ?? 0);
                $nota = '';
                foreach ($notas as $n) { if ((int)($n['periodo_id'] ?? 0) === $pid) { $nota = $n['valor'] ?? ''; break; } }
            ?>
            <td>
                <input type="number" name="nota[<?= $aid ?>][<?= $pid ?>]" value="<?= htmlspecialchars((string)$nota) ?>"
                    min="0" max="20" step="0.5"
                    style="width:70px;padding:.3rem .4rem;border:1px solid #E2E8F0;border-radius:6px;font-size:.85rem;text-align:center">
            </td>
            <?php endforeach; ?>
            <?php else: ?>
            <td>
                <input type="number" name="nota[<?= $aid ?>][0]" value="<?= htmlspecialchars((string)($notas[0]['valor'] ?? '')) ?>"
                    min="0" max="20" step="0.5"
                    style="width:70px;padding:.3rem .4rem;border:1px solid #E2E8F0;border-radius:6px;font-size:.85rem;text-align:center">
            </td>
            <?php endif; ?>
        </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
    </div>
    </form>
</div>

<script>
document.getElementById('btn-gravar-notas')?.addEventListener('click', async () => {
    const form = document.getElementById('form-notas');
    const entries = [];
    new FormData(form).forEach((v, k) => {
        const m = k.match(/nota\[(\d+)\]\[(\d+)\]/);
        if (m && v !== '') entries.push({ aluno_id: +m[1], periodo_id: +m[2], valor: parseFloat(v) });
    });
    const payload = { turma_id: <?= $turmaId ?>, notas: entries };
    const resp = await fetch('/portal/professor/api/notas', { method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify(payload) });
    const json = await resp.json();
    showToast(resp.ok ? 'Notas gravadas com sucesso.' : (json.erro ?? json.message ?? 'Erro ao gravar.'), resp.ok ? 'success' : 'error');
});
</script>
<?php elseif ($turmaId): ?>
<div class="portal-card">
    <div class="portal-empty"><i class="fa-solid fa-users"></i>Sem alunos encontrados.</div>
</div>
<?php else: ?>
<div class="portal-card">
    <div class="portal-empty"><i class="fa-solid fa-star-half-stroke"></i>Seleccione uma turma para lançar notas.</div>
</div>
<?php endif; ?>

<?php require __DIR__ . '/layout_bottom.php'; ?>
