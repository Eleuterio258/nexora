<?php
use PHC\Presentation\View\Html;
use PHC\Application\DTO\DocumentDTO;

/** @var \PHC\Application\DTO\DashboardDTO $dashboard */
?>

<div class="page-head">
  <div>
    <p class="eyebrow"><?= Html::e(strtoupper($dashboard->todayFormatted)) ?></p>
    <h1>Bom dia, António</h1>
    <p>Acompanhe a faturação da sua empresa num só lugar.</p>
  </div>
  <a href="/documents/new" class="btn primary">＋ Novo documento</a>
</div>

<div class="period-bar"><div><button class="period active">Este mês</button><button class="period">Últimos 30 dias</button><button class="period">Este ano</button></div><span>Atualizado agora</span></div>

<div class="stat-grid">
  <article class="stat-card" style="--accent:#008b83">
    <span class="stat-label">Faturação emitida</span>
    <strong class="stat-value"><?= Html::e($dashboard->emitted) ?></strong>
    <span class="stat-foot up">Indicador do período atual</span>
  </article>
  <article class="stat-card" style="--accent:#2e6ddf">
    <span class="stat-label">Total recebido</span>
    <strong class="stat-value"><?= Html::e($dashboard->received) ?></strong>
    <span class="stat-foot"><?= $dashboard->emitted !== '0,00 MT' ? 'percentagem do emitido' : 'sem faturação' ?></span>
  </article>
  <article class="stat-card" style="--accent:#d88a16">
    <span class="stat-label">Por receber</span>
    <strong class="stat-value"><?= Html::e($dashboard->outstanding) ?></strong>
    <span class="stat-foot"><?= $dashboard->pendingCount ?> documentos pendentes</span>
  </article>
  <article class="stat-card" style="--accent:#d94b4b">
    <span class="stat-label">Vencido</span>
    <strong class="stat-value"><?= Html::e($dashboard->overdue) ?></strong>
    <span class="stat-foot"><?= $dashboard->overdueCount ? 'Requer acompanhamento' : 'Sem valores vencidos' ?></span>
  </article>
</div>

<div class="dashboard-grid">
  <article class="panel chart-panel">
    <div class="panel-head">
      <div><h2>Faturação</h2><p>Valores emitidos e recebidos</p></div>
      <span class="legend"><i></i>Emitido <i></i>Recebido</span>
    </div>
    <div class="bar-chart">
      <?php
      $months = ['Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago'];
      $sales = [44, 55, 48, 70, 59, 88];
      $paid = [36, 46, 42, 58, 52, 65];
      ?>
      <?php foreach ($months as $i => $month): ?>
        <div class="bar-group" data-label="<?= Html::e($month) ?>">
          <i class="bar" style="height:<?= $sales[$i] ?>%" title="Emitido"></i>
          <i class="bar received" style="height:<?= $paid[$i] ?>%" title="Recebido"></i>
        </div>
      <?php endforeach; ?>
    </div>
  </article>

  <article class="panel">
    <div class="panel-head"><div><h2>A receber</h2><p>Faturas pendentes</p></div><a href="/documents?filter=pending" class="link-btn">Ver todas →</a></div>
    <div class="receivables">
      <?php if (empty($dashboard->pendingDocuments)): ?>
        <div class="empty-state">Sem valores pendentes.</div>
      <?php else: ?>
        <?php foreach ($dashboard->pendingDocuments as $doc): ?>
          <div class="receivable">
            <div>
              <b><?= Html::e($doc->customerName) ?></b>
              <small><?= Html::e($doc->number) ?> · vence <?= Html::datePt($doc->dueDate) ?></small>
            </div>
            <strong class="<?= $doc->status === 'overdue' ? 'overdue' : '' ?>"><?= Html::e($doc->total) ?></strong>
          </div>
        <?php endforeach; ?>
      <?php endif; ?>
    </div>
  </article>

  <article class="panel span-2">
    <div class="panel-head"><div><h2>Atividade recente</h2><p>Últimos documentos emitidos</p></div><a href="/documents" class="link-btn">Todos os documentos →</a></div>
    <div class="table-wrap">
      <table>
        <thead>
          <tr><th>Documento</th><th>Cliente</th><th>Emissão</th><th>Estado</th><th style="text-align:right">Total</th></tr>
        </thead>
        <tbody>
          <?php foreach ($dashboard->recentDocuments as $doc): ?>
            <tr>
              <td>
                <div class="doc-cell">
                  <span class="doc-icon"><?= Html::e($doc->type) ?></span>
                  <span><b><?= Html::e($doc->number) ?></b><small>Documento de venda</small></span>
                </div>
              </td>
              <td><?= Html::e($doc->customerName) ?></td>
              <td><?= Html::datePt($doc->date) ?></td>
              <td><span class="badge <?= Html::e($doc->status) ?>"><?= Html::e($doc->statusLabel) ?></span></td>
              <td style="text-align:right"><b><?= Html::e($doc->total) ?></b></td>
            </tr>
          <?php endforeach; ?>
        </tbody>
      </table>
    </div>
  </article>
</div>
