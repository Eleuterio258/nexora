<?php
use PHC\Presentation\View\Html;

/** @var \PHC\Application\DTO\CustomerDTO[] $customers */
/** @var \PHC\Application\DTO\ProductDTO[] $products */
/** @var \PHC\Application\DTO\SeriesDTO[] $series */
/** @var string|null $error */

$today = date('Y-m-d');
$dueDate = date('Y-m-d', strtotime('+30 days'));
$types = [
  'FT' => 'Fatura',
  'FR' => 'Fatura-recibo',
  'VD' => 'Venda a dinheiro',
  'ORC' => 'Orçamento',
  'NC' => 'Nota de crédito',
  'PP' => 'Fatura pro forma',
];
?>

<?php if ($error !== null): ?>
  <div class="toast error" style="position:fixed;top:20px;right:20px;z-index:100"><?= Html::e($error) ?></div>
<?php endif; ?>

<div class="modal-backdrop">
  <section class="document-modal" role="dialog" aria-modal="true" aria-labelledby="documentTitle">
    <header class="modal-head">
      <div>
        <p class="eyebrow">DOCUMENTO DE VENDA</p>
        <h2 id="documentTitle">Novo documento</h2>
      </div>
      <div class="modal-head-actions">
        <button type="submit" name="draft" value="1" class="btn subtle" form="documentForm">Guardar rascunho</button>
        <a href="/documents" class="icon-btn">×</a>
      </div>
    </header>

<form id="documentForm" method="post" action="/documents" class="document-body">
    <div class="document-main">
      <div class="form-section document-meta">
        <label>
          <span>Tipo de documento</span>
          <select name="type" id="docType">
            <?php foreach ($types as $key => $label): ?>
              <option value="<?= Html::e($key) ?>"><?= Html::e($label) ?></option>
            <?php endforeach; ?>
          </select>
        </label>
        <label>
          <span>Série</span>
          <select name="series_id" id="docSeries">
            <?php foreach ($series as $s): ?>
              <option value="<?= $s->id ?>" data-type="<?= Html::e($s->type) ?>"><?= Html::e($s->code . '/' . $s->year . ' — ' . $s->description) ?></option>
            <?php endforeach; ?>
          </select>
        </label>
        <label>
          <span>Data</span>
          <input type="date" name="date" value="<?= $today ?>">
        </label>
        <label>
          <span>Vencimento</span>
          <input type="date" name="due_date" id="docDueDate" value="<?= $dueDate ?>">
        </label>
      </div>

      <div class="form-section client-picker">
        <label>
          <span>Cliente</span>
          <select name="customer_id" id="docCustomer">
            <option value="">Selecionar cliente…</option>
            <?php foreach ($customers as $c): ?>
              <option value="<?= $c->id ?>"><?= Html::e($c->code . ' — ' . $c->name) ?></option>
            <?php endforeach; ?>
          </select>
        </label>
      </div>

      <div class="lines-toolbar">
        <div><h3>Linhas do documento</h3><p>Adicione artigos, serviços ou linhas livres</p></div>
        <button type="button" class="btn secondary" id="addLine">＋ Adicionar linha</button>
      </div>

      <div class="invoice-lines">
        <table>
          <thead>
            <tr>
              <th>Artigo / descrição</th>
              <th>Qtd.</th>
              <th>Preço unit.</th>
              <th>Desc.</th>
              <th>IVA</th>
              <th>Total</th>
              <th></th>
            </tr>
          </thead>
          <tbody id="invoiceLines"></tbody>
        </table>
      </div>

      <div class="form-section notes">
        <label><span>Observações</span><textarea name="notes" rows="3" placeholder="Informação adicional visível no documento…"></textarea></label>
        <label><span>Referência</span><input name="reference" placeholder="Opcional"></label>
      </div>
    </div>

    <aside class="document-summary">
      <div class="summary-company">
        <span class="company-icon">N</span>
        <div><b>Nexora, Lda.</b><small>NUIT 400123456</small></div>
      </div>
      <dl>
        <div><dt>Subtotal</dt><dd id="subtotalValue">0,00 MT</dd></div>
        <div><dt>Descontos</dt><dd id="discountValue">0,00 MT</dd></div>
        <div><dt>IVA</dt><dd id="taxValue">0,00 MT</dd></div>
      </dl>
      <div class="grand-total"><span>Total</span><strong id="totalValue">0,00 MT</strong></div>
      <button type="submit" class="btn primary wide">Emitir documento</button>
    </aside>
  </div>
</form>
  </section>
</div>

<script>
const products = <?= json_encode(array_map(fn($p) => ['id' => $p->id, 'code' => $p->code, 'name' => $p->name, 'price' => $p->price, 'tax' => $p->tax], $products)) ?>;

function formatMoney(v) {
  return new Intl.NumberFormat('pt-PT', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(Number(v || 0)) + ' MT';
}

function lineRow() {
  const tr = document.createElement('tr');
  tr.innerHTML = `<td><select name="lines[product_id][]" class="line-product"><option value="">Selecionar artigo…</option>${products.map(p => `<option value="${p.id}">${p.code} — ${p.name}</option>`).join('')}</select><input type="hidden" name="lines[description][]" class="line-desc"></td>
    <td><input name="lines[quantity][]" class="line-number line-qty" type="number" min="0.01" step="0.01" value="1"></td>
    <td><input name="lines[price][]" class="line-number line-price" type="number" min="0" step="0.01" value="0"></td>
    <td><input name="lines[discount][]" class="line-number line-discount" type="number" min="0" max="100" step="0.1" value="0"></td>
    <td><select name="lines[tax][]" class="line-tax"><option value="16">16%</option><option value="5">5%</option><option value="0">0%</option></select></td>
    <td class="line-total">0,00 MT</td>
    <td><button type="button" class="remove-line" title="Remover linha">×</button></td>`;
  tr.querySelector('.line-product').addEventListener('change', e => {
    const p = products.find(x => x.id == e.target.value);
    if (p) { tr.querySelector('.line-price').value = p.price; tr.querySelector('.line-tax').value = p.tax; tr.querySelector('.line-desc').value = p.name; recalc(); }
  });
  tr.querySelector('.remove-line').onclick = () => { tr.remove(); if (!document.querySelectorAll('#invoiceLines tr').length) addLine(); recalc(); };
  tr.querySelectorAll('input, select').forEach(el => el.addEventListener('input', recalc));
  return tr;
}

function addLine() { document.querySelector('#invoiceLines').append(lineRow()); recalc(); }

function recalc() {
  let subtotal = 0, discount = 0, tax = 0, total = 0;
  document.querySelectorAll('#invoiceLines tr').forEach(row => {
    const qty = Number(row.querySelector('.line-qty').value) || 0;
    const price = Number(row.querySelector('.line-price').value) || 0;
    const disc = Number(row.querySelector('.line-discount').value) || 0;
    const taxRate = Number(row.querySelector('.line-tax').value) || 0;
    const gross = qty * price;
    const lineDisc = gross * disc / 100;
    const base = gross - lineDisc;
    const lineTax = base * taxRate / 100;
    subtotal += gross; discount += lineDisc; tax += lineTax; total += base + lineTax;
    row.querySelector('.line-total').textContent = formatMoney(base + lineTax);
  });
  document.querySelector('#subtotalValue').textContent = formatMoney(subtotal);
  document.querySelector('#discountValue').textContent = formatMoney(discount);
  document.querySelector('#taxValue').textContent = formatMoney(tax);
  document.querySelector('#totalValue').textContent = formatMoney(total);
}

document.querySelector('#addLine').onclick = addLine;
document.querySelector('#docType').addEventListener('change', () => {
  const type = document.querySelector('#docType').value;
  document.querySelectorAll('#docSeries option').forEach(opt => opt.style.display = opt.dataset.type === type ? '' : 'none');
  const visible = document.querySelector('#docSeries option:not([style*="none"])');
  if (visible) document.querySelector('#docSeries').value = visible.value;
  if (['FR','VD'].includes(type)) document.querySelector('#docDueDate').value = document.querySelector('input[name=date]').value;
});

addLine();
document.querySelector('#docType').dispatchEvent(new Event('change'));
</script>
