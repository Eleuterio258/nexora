<?php
use PHC\Presentation\View\Html;

$reports = [
  ['▥', 'Mapa de faturação', 'Documentos emitidos por período, tipo e estado.'],
  ['◴', 'Idade de saldos', 'Valores pendentes agrupados pelo tempo em dívida.'],
  ['♙', 'Vendas por cliente', 'Ranking, volume de vendas e margem por cliente.'],
  ['◇', 'Vendas por artigo', 'Quantidade e valor vendido por artigo ou serviço.'],
  ['%', 'Resumo de IVA', 'Base tributável e imposto liquidado por taxa.'],
  ['↗', 'Evolução mensal', 'Comparativo da faturação e recebimentos mensais.'],
];
?>

<div class="page-head compact">
  <div>
    <p class="eyebrow">ANÁLISE</p>
    <h1>Relatórios</h1>
    <p>Informação comercial e fiscal pronta para análise.</p>
  </div>
  <a href="/export/documents" class="btn primary">⇩ Exportar movimentos</a>
</div>

<div class="report-grid">
  <?php foreach ($reports as [$icon, $title, $desc]): ?>
    <article class="panel report-card">
      <span class="report-icon"><?= Html::e($icon) ?></span>
      <h3><?= Html::e($title) ?></h3>
      <p><?= Html::e($desc) ?></p>
      <span class="link-btn">Abrir relatório →</span>
    </article>
  <?php endforeach; ?>
</div>
