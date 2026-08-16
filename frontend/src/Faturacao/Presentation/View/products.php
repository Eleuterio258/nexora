<?php
use E258Tech\Faturacao\Presentation\View\Html;

/** @var \E258Tech\Faturacao\Application\DTO\ProductDTO[] $products */
?>

<div class="page-head compact">
  <div>
    <p class="eyebrow">CATÁLOGO</p>
    <h1>Artigos e serviços</h1>
    <p>Preços, impostos e disponibilidade do catálogo.</p>
  </div>
</div>

<article class="panel data-panel">
  <div class="table-wrap">
    <table>
      <thead>
        <tr><th>Código</th><th>Descrição</th><th>Unidade</th><th>Preço</th><th>IVA</th><th>Existência</th><th>Estado</th></tr>
      </thead>
      <tbody>
        <?php foreach ($products as $p): ?>
          <tr>
            <td><b><?= Html::e($p->code) ?></b></td>
            <td><?= Html::e($p->name) ?></td>
            <td><?= Html::e($p->unit) ?></td>
            <td><b><?= Html::money($p->price) ?></b></td>
            <td><?= $p->tax ?>%</td>
            <td><?= $p->stock === null ? 'N/A' : $p->stock ?></td>
            <td><span class="badge active">Ativo</span></td>
          </tr>
        <?php endforeach; ?>
      </tbody>
    </table>
  </div>
  <div class="table-footer"><span><?= count($products) ?> registos</span></div>
</article>
