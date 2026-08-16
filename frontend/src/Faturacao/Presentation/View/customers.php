<?php
use E258Tech\Faturacao\Presentation\View\Html;

/** @var \E258Tech\Faturacao\Application\DTO\CustomerDTO[] $customers */
?>

<div class="page-head compact">
  <div>
    <p class="eyebrow">ENTIDADES</p>
    <h1>Clientes</h1>
    <p>Fichas de clientes e respetiva posição financeira.</p>
  </div>
</div>

<article class="panel data-panel">
  <div class="table-wrap">
    <table>
      <thead>
        <tr><th>Código</th><th>Cliente</th><th>NUIT</th><th>Contacto</th><th>Localidade</th><th>Saldo</th><th>Estado</th></tr>
      </thead>
      <tbody>
        <?php foreach ($customers as $c): ?>
          <tr>
            <td><b><?= Html::e($c->code) ?></b></td>
            <td>
              <div class="doc-cell">
                <span class="doc-icon"><?= Html::e(mb_substr($c->name, 0, 1)) ?></span>
                <span><b><?= Html::e($c->name) ?></b><small><?= Html::e($c->email) ?></small></span>
              </div>
            </td>
            <td><?= Html::e($c->nuit) ?></td>
            <td><?= Html::e($c->phone) ?></td>
            <td><?= Html::e($c->city) ?></td>
            <td><b><?= Html::money($c->balance) ?></b></td>
            <td><span class="badge active">Ativo</span></td>
          </tr>
        <?php endforeach; ?>
      </tbody>
    </table>
  </div>
  <div class="table-footer"><span><?= count($customers) ?> registos</span></div>
</article>
