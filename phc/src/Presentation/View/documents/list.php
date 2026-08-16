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
  <a href="/documents/new" id="newDocumentBtn" class="btn primary">＋ Novo documento</a>
</div>

<div id="documentModalRoot"></div>

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

<script>
(function () {
  var modalRoot = document.getElementById('documentModalRoot');
  var trigger = document.getElementById('newDocumentBtn');
  var escHandler = null;

  function openModal(html) {
    modalRoot.innerHTML = html;
    document.body.style.overflow = 'hidden';
    bindModalEvents();
  }

  function closeModal() {
    modalRoot.innerHTML = '';
    document.body.style.overflow = '';
    if (escHandler) { document.removeEventListener('keydown', escHandler); escHandler = null; }
  }

  function showModalError(message) {
    var toast = modalRoot.querySelector('.toast.error');
    if (!toast) {
      toast = document.createElement('div');
      toast.className = 'toast error';
      toast.style.cssText = 'position:fixed;top:20px;right:20px;z-index:200';
      modalRoot.appendChild(toast);
    }
    toast.textContent = message;
  }

  function bindModalEvents() {
    var backdrop = modalRoot.querySelector('.modal-backdrop');
    if (!backdrop) return;

    backdrop.addEventListener('click', function (e) {
      if (e.target === backdrop) closeModal();
    });

    var closeBtn = modalRoot.querySelector('.modal-head-actions .icon-btn');
    if (closeBtn) {
      closeBtn.addEventListener('click', function (e) {
        e.preventDefault();
        closeModal();
      });
    }

    escHandler = function (e) {
      if (e.key === 'Escape') closeModal();
    };
    document.addEventListener('keydown', escHandler);

    var form = modalRoot.querySelector('#documentForm');
    if (form) {
      form.addEventListener('submit', function (e) {
        e.preventDefault();
        var formData = new FormData(form);
        var submitter = e.submitter;
        var isDraft = !!(submitter && submitter.name === 'draft');
        if (submitter && submitter.name) formData.append(submitter.name, submitter.value);

        // Abrir a aba já aqui, dentro do gesto de clique — se só abrirmos
        // depois do fetch responder, o browser trata como pop-up não
        // solicitado e bloqueia-a. "Guardar rascunho" não emite, por isso
        // não abre PDF nenhum.
        var pdfWindow = isDraft ? null : window.open('', '_blank');

        fetch('/documents', {
          method: 'POST',
          headers: { 'X-Requested-With': 'XMLHttpRequest' },
          body: formData
        })
          .then(function (res) { return res.json(); })
          .then(function (data) {
            if (data.success) {
              if (pdfWindow && data.pdfUrl) {
                pdfWindow.location = data.pdfUrl;
              } else if (pdfWindow) {
                pdfWindow.close();
              }
              window.location.reload();
            } else {
              if (pdfWindow) pdfWindow.close();
              showModalError(data.error || 'Erro ao gravar o documento.');
            }
          })
          .catch(function () {
            if (pdfWindow) pdfWindow.close();
            showModalError('Erro de ligação ao gravar o documento.');
          });
      });
    }
  }

  if (trigger) {
    trigger.addEventListener('click', function (e) {
      e.preventDefault();
      fetch('/documents/new', { headers: { 'X-Requested-With': 'XMLHttpRequest' } })
        .then(function (res) {
          if (!res.ok) throw new Error('HTTP ' + res.status);
          return res.text();
        })
        .then(openModal)
        .catch(function () {
          window.location.href = '/documents/new';
        });
    });
  }
})();
</script>
