<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Boletim · <?= htmlspecialchars($alunoInfo['nome'] ?? '') ?></title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: Arial, sans-serif; font-size: 11pt; color: #000; background: #fff; padding: 1.5cm; }

        .header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 1.5rem; border-bottom: 2px solid #0369A1; padding-bottom: .75rem; }
        .header-school { font-size: 13pt; font-weight: bold; color: #0369A1; }
        .header-doc { font-size: 9pt; color: #555; text-align: right; }

        h2 { font-size: 14pt; color: #0C4A6E; margin-bottom: .25rem; }
        .aluno-info { margin: 1rem 0; display: grid; grid-template-columns: 1fr 1fr; gap: .35rem; font-size: 10pt; }
        .aluno-info span { color: #555; }
        .aluno-info strong { color: #000; }

        .stats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; margin: 1rem 0; }
        .stat { border: 1px solid #ddd; border-radius: 6px; padding: .5rem .75rem; text-align: center; }
        .stat-val { font-size: 18pt; font-weight: bold; }
        .stat-label { font-size: 8pt; color: #666; margin-top: .15rem; }

        table { width: 100%; border-collapse: collapse; margin-top: 1rem; font-size: 10pt; }
        th { background: #0369A1; color: #fff; padding: .4rem .6rem; text-align: left; font-size: 9pt; }
        td { padding: .35rem .6rem; border-bottom: 1px solid #e5e7eb; }
        tr:nth-child(even) td { background: #f8fafc; }
        .aprovado { color: #15803D; font-weight: bold; }
        .reprovado { color: #B91C1C; font-weight: bold; }

        .footer { margin-top: 2rem; font-size: 8pt; color: #666; border-top: 1px solid #ddd; padding-top: .5rem;
            display: flex; justify-content: space-between; }

        @media print {
            body { padding: 1cm; }
            @page { margin: 1.5cm; }
        }
    </style>
</head>
<body>

<div class="header">
    <div>
        <div class="header-school">Portal Escolar — Nexora ERP</div>
        <div style="font-size:9pt;color:#555;margin-top:.2rem">Boletim de Notas</div>
    </div>
    <div class="header-doc">
        Emitido em: <?= date('d/m/Y H:i') ?><br>
        Documento gerado electronicamente
    </div>
</div>

<h2><?= htmlspecialchars($alunoInfo['nome'] ?? 'Aluno') ?></h2>

<div class="aluno-info">
    <div><span>Código: </span><strong><?= htmlspecialchars($alunoInfo['codigo'] ?? '') ?></strong></div>
    <?php if (!empty($alunoInfo['matricula_activa'])): $m = $alunoInfo['matricula_activa']; ?>
    <div><span>Turma: </span><strong><?= htmlspecialchars($m['turma'] ?? '') ?></strong></div>
    <div><span>Nível: </span><strong><?= htmlspecialchars($m['nivel'] ?? '') ?></strong></div>
    <div><span>Ano lectivo: </span><strong><?= htmlspecialchars($m['ano_lectivo'] ?? '') ?></strong></div>
    <?php endif; ?>
    <?php if ($termId > 0 && !empty($termos)):
        foreach ($termos as $t) { if ((int)$t['id'] === $termId) { echo "<div><span>Período: </span><strong>" . htmlspecialchars($t['nome'] ?? '') . "</strong></div>"; break; } }
    endif; ?>
</div>

<?php if ($media !== null): ?>
<div class="stats">
    <div class="stat">
        <div class="stat-val <?= (float)$media >= 10 ? 'aprovado' : 'reprovado' ?>"><?= number_format((float)$media, 1) ?></div>
        <div class="stat-label">Média geral</div>
    </div>
    <?php if ($totalFaltas !== null): ?>
    <div class="stat">
        <div class="stat-val"><?= (int)$totalFaltas ?></div>
        <div class="stat-label">Total de faltas</div>
    </div>
    <?php endif; ?>
    <div class="stat">
        <div class="stat-val"><?= count($disciplinas) ?></div>
        <div class="stat-label">Disciplinas</div>
    </div>
</div>
<?php endif; ?>

<?php if (!empty($disciplinas)): ?>
<table>
    <thead>
        <tr>
            <th>Disciplina</th>
            <th style="text-align:center">P1</th>
            <th style="text-align:center">P2</th>
            <th style="text-align:center">P3</th>
            <th style="text-align:center">Exame</th>
            <th style="text-align:center">Média</th>
            <th style="text-align:center">Resultado</th>
            <th style="text-align:center">Faltas</th>
        </tr>
    </thead>
    <tbody>
    <?php foreach ($disciplinas as $d):
        $nota = (float)($d['media'] ?? $d['average'] ?? $d['nota'] ?? 0);
        $aprovado = $nota >= 10;
    ?>
    <tr>
        <td><?= htmlspecialchars($d['nome'] ?? $d['disciplina'] ?? '') ?></td>
        <td style="text-align:center"><?= $d['p1'] ?? '—' ?></td>
        <td style="text-align:center"><?= $d['p2'] ?? '—' ?></td>
        <td style="text-align:center"><?= $d['p3'] ?? '—' ?></td>
        <td style="text-align:center"><?= $d['exame'] ?? '—' ?></td>
        <td style="text-align:center;font-weight:bold;color:<?= $aprovado ? '#15803D' : '#B91C1C' ?>"><?= number_format($nota, 1) ?></td>
        <td style="text-align:center" class="<?= $aprovado ? 'aprovado' : 'reprovado' ?>"><?= $aprovado ? 'Aprovado' : 'Reprovado' ?></td>
        <td style="text-align:center"><?= $d['faltas'] ?? $d['avaliacoes'] ?? '—' ?></td>
    </tr>
    <?php endforeach; ?>
    </tbody>
</table>
<?php else: ?>
<p style="margin-top:1rem;color:#666;font-style:italic">Ainda não há notas lançadas para este período.</p>
<?php endif; ?>

<div class="footer">
    <span>Nexora ERP · Portal do Aluno</span>
    <span>Documento gerado em <?= date('d/m/Y \à\s H:i') ?></span>
</div>

<script>window.onload = function() { window.print(); }</script>
</body>
</html>
