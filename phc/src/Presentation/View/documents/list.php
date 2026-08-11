<?php
use PHC\Presentation\View\Html;

/** @var \PHC\Application\DTO\DocumentDTO[] $documents */
/** @var string $filter */
/** @var string $search */

$filters = [
  ['all', 'Todos'],
  ['FT', 'Faturas'],
  ['FR', 'Fatura-recibo'],
  ['VD', 'Vendas a dinheiro'],
  ['ORC', 'Orçamentos'],
  ['PP', 'Faturas pro forma'],
  ['pending', 'Pendentes'],
  ['overdue', 'Vencidos'],
];
?>

<div class="page-head compact">
  <div>
    <p class="eyebrow">VENDAS</p>
    <h1>Documentos</h1>
    <p>Consulte e gira todos os documentos de venda.</p>
  </div>
  <a href="/documents/new" class="btn primary">＋ Novo documento</a>
</div>

<article class="panel data-panel">
  <div class="table-tools">
    <form action="/documents" method="get" class="table-search">
      <span>⌕</span>
      <input name="search" type="search" placeholder="Pesquisar…" value="<?= Html::e($search) ?>">
    </form>
    <div class="filters">
      <?php foreach ($filters as [$key, $label]): ?>
        <a href="/documents?filter=<?= Html::e($key) ?>&search=<?= Html::e($search) ?>" class="filter <?= $filter === $key ? 'active' : '' ?>"><?= Html::e($label) ?></a>
      <?php endforeach; ?>
    </div>
    <a href="/export/documents?filter=<?= Html::e($filter) ?>&search=<?= Html::e($search) ?>" class="btn subtle">⇩ Exportar</a>
  </div>

  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>Documento</th>
          <th>Cliente</th>
          <th>Emissão</th>
          <th>Vencimento</th>
          <th>Estado</th>
          <th style="text-align:right">Total</th>
          <th></th>
        </tr>
      </thead>
      <tbody>
        <?php if (empty($documents)): ?>
          <tr><td colspan="7"><div class="empty-state"><b>Nenhum documento encontrado</b>Altere os filtros ou crie um novo documento.</div></td></tr>
        <?php else: ?>
          <?php foreach ($documents as $doc): ?>
            <tr>
              <td>
                <div class="doc-cell">
                  <span class="doc-icon"><?= Html::e($doc->type) ?></span>
                  <span><b><?= Html::e($doc->number) ?></b><small>Documento de venda</small></span>
                </div>
              </td>
              <td><?= Html::e($doc->customerName) ?></td>
              <td><?= Html::datePt($doc->date) ?></td>
              <td><?= Html::datePt($doc->dueDate) ?></td>
              <td><span class="badge <?= Html::e($doc->status) ?>"><?= Html::e($doc->statusLabel) ?></span></td>
              <td style="text-align:right"><b><?= Html::e($doc->total) ?></b></td>
              <td>
                <a href="/documents/preview?id=<?= $doc->id ?>" class="row-action" title="Pré-visualizar">👁</a>
                <a href="/documents/pdf?id=<?= $doc->id ?>" class="row-action" title="Descarregar PDF">⇩</a>
              </td>
            </tr>
          <?php endforeach; ?>
        <?php endif; ?>
      </tbody>
    </table>
  </div>
  <div class="table-footer"><span><?= count($documents) ?> registos</span><span>1 página</span></div>
</article>
