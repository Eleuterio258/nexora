<?php
use E258Tech\Faturacao\Presentation\View\Html;

/** @var \E258Tech\Faturacao\Application\DTO\SeriesDTO[] $series */
?>

<div class="page-head compact">
  <div>
    <p class="eyebrow">CONFIGURAÇÃO</p>
    <h1>Séries documentais</h1>
    <p>Numeração e sequências por tipo de documento.</p>
  </div>
</div>

<article class="panel data-panel">
  <div class="table-wrap">
    <table>
      <thead>
        <tr><th>Série</th><th>Tipo</th><th>Descrição</th><th>Ano</th><th>Próximo número</th><th>Estado</th></tr>
      </thead>
      <tbody>
        <?php foreach ($series as $s): ?>
          <tr>
            <td>
              <div class="doc-cell">
                <span class="doc-icon"><?= Html::e($s->code) ?></span>
                <b><?= Html::e($s->type . ' ' . $s->code . '/' . $s->year) ?></b>
              </div>
            </td>
            <td><?= Html::e($s->type) ?></td>
            <td><?= Html::e($s->description) ?></td>
            <td><?= $s->year ?></td>
            <td><b><?= str_pad((string) $s->next, 6, '0', STR_PAD_LEFT) ?></b></td>
            <td><span class="badge active">Ativa</span></td>
          </tr>
        <?php endforeach; ?>
      </tbody>
    </table>
  </div>
  <div class="table-footer"><span><?= count($series) ?> registos</span></div>
</article>
