<?php
$pageTitle   = 'Presenças';
$activePage  = 'presencas';
$turmas      = $portalData['turmas']['body']['data']    ?? $portalData['turmas']['body']    ?? [];
$presencaRaw = $portalData['presencas']['body']['data'] ?? $portalData['presencas']['body'] ?? [];
$alunos      = $presencaRaw['alunos'] ?? $presencaRaw ?? [];
$turmaId     = $turmaId ?? 0; // decoded by index.php from hash
$turmaIdHash = $_GET['turma_id'] ?? '';
$dataHoje    = $_GET['data'] ?? date('Y-m-d');

require __DIR__ . '/layout_top.php';
?>

<div class="portal-card" style="margin-bottom:1rem">
    <form method="get" style="display:flex;gap:.75rem;align-items:flex-end;flex-wrap:wrap">
        <div>
            <label style="display:block;font-size:.78rem;font-weight:600;color:#64748B;margin-bottom:.25rem">Turma</label>
            <select name="turma_id" style="padding:.45rem .75rem;border:1px solid #E2E8F0;border-radius:8px;font-size:.85rem;min-width:160px">
                <option value="">Seleccionar turma</option>
                <?php foreach ($turmas as $t): ?>
                <option value="<?= $app->id->encode((int)($t['id'] ?? 0)) ?>" <?= $turmaId === (int)($t['id'] ?? 0) ? 'selected' : '' ?>>
                    <?= htmlspecialchars($t['nome'] ?? $t['turma'] ?? '') ?> – <?= htmlspecialchars($t['disciplina'] ?? '') ?>
                </option>
                <?php endforeach; ?>
            </select>
        </div>
        <div>
            <label style="display:block;font-size:.78rem;font-weight:600;color:#64748B;margin-bottom:.25rem">Data</label>
            <input type="date" name="data" value="<?= htmlspecialchars($dataHoje) ?>" style="padding:.45rem .75rem;border:1px solid #E2E8F0;border-radius:8px;font-size:.85rem">
        </div>
        <button type="submit" class="btn-primary"><i class="fa-solid fa-search"></i> Carregar</button>
    </form>
</div>

<?php if ($turmaId && !empty($alunos)): ?>
<div class="portal-card">
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:1rem">
        <p class="portal-card-title" style="margin:0;border:none">
            <i class="fa-solid fa-calendar-check" style="color:var(--prof-primary)"></i>
            Registo de Presenças — <?= htmlspecialchars($dataHoje) ?>
        </p>
        <button class="btn-primary" id="btn-gravar" style="font-size:.82rem">
            <i class="fa-solid fa-floppy-disk"></i> Gravar
        </button>
    </div>

    <form id="form-presencas">
    <table class="portal-table">
        <thead>
            <tr>
                <th>#</th>
                <th>Aluno</th>
                <th>Presente</th>
                <th>Justificado</th>
                <th>Observação</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($alunos as $i => $a):
            $aid     = (int)($a['aluno_id'] ?? $a['id'] ?? 0);
            $estado  = $a['estado_presenca'] ?? 'presente';
        ?>
        <tr>
            <td style="color:#94A3B8;font-size:.8rem"><?= $i + 1 ?></td>
            <td style="font-weight:600"><?= htmlspecialchars($a['nome'] ?? $a['aluno_nome'] ?? '—') ?></td>
            <td>
                <select name="presenca[<?= $aid ?>][estado]" style="padding:.3rem .5rem;border:1px solid #E2E8F0;border-radius:6px;font-size:.82rem">
                    <option value="presente"  <?= $estado === 'presente'  ? 'selected' : '' ?>>Presente</option>
                    <option value="ausente"   <?= $estado === 'ausente'   ? 'selected' : '' ?>>Ausente</option>
                    <option value="atrasado"  <?= $estado === 'atrasado'  ? 'selected' : '' ?>>Atrasado</option>
                </select>
            </td>
            <td>
                <input type="checkbox" name="presenca[<?= $aid ?>][justificado]" value="1" <?= !empty($a['justificado']) ? 'checked' : '' ?>>
            </td>
            <td>
                <input type="text" name="presenca[<?= $aid ?>][observacao]" value="<?= htmlspecialchars($a['observacao'] ?? '') ?>"
                    style="padding:.3rem .5rem;border:1px solid #E2E8F0;border-radius:6px;font-size:.82rem;width:100%;max-width:220px">
            </td>
        </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
    </form>
</div>

<script>
document.getElementById('btn-gravar')?.addEventListener('click', async () => {
    const form = document.getElementById('form-presencas');
    const data = {};
    new FormData(form).forEach((v, k) => {
        const m = k.match(/presenca\[(\d+)\]\[(\w+)\]/);
        if (m) { data[m[1]] ??= {}; data[m[1]][m[2]] = v; }
    });
    // Checkboxes desmarcadas não aparecem no FormData
    document.querySelectorAll('[name^="presenca"][name$="[justificado]"]').forEach(el => {
        const m = el.name.match(/presenca\[(\d+)\]/);
        if (m && !data[m[1]]?.justificado) { data[m[1]] ??= {}; data[m[1]].justificado = '0'; }
    });
    const payload = { turma_id: <?= $turmaId ?>, data: '<?= $dataHoje ?>', presencas: Object.entries(data).map(([id,v]) => ({aluno_id:+id,...v})) };
    const resp = await fetch('/portal/professor/api/presencas', { method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify(payload) });
    const json = await resp.json();
    showToast(resp.ok ? 'Presenças gravadas com sucesso.' : (json.erro ?? json.message ?? 'Erro ao gravar.'), resp.ok ? 'success' : 'error');
});
</script>
<?php elseif ($turmaId): ?>
<div class="portal-card">
    <div class="portal-empty"><i class="fa-solid fa-users"></i>Sem alunos encontrados para esta turma.</div>
</div>
<?php else: ?>
<div class="portal-card">
    <div class="portal-empty"><i class="fa-solid fa-calendar-check"></i>Seleccione uma turma para registar presenças.</div>
</div>
<?php endif; ?>

<?php require __DIR__ . '/layout_bottom.php'; ?>
