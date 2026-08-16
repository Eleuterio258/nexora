<?php
use E258Tech\Faturacao\Presentation\View\Html;
use E258Tech\Faturacao\Application\DTO\InvoiceLayoutSettingsDTO;

/** @var \E258Tech\Faturacao\Application\DTO\DocumentDTO $doc */
/** @var InvoiceLayoutSettingsDTO|null $settings */

$settings ??= InvoiceLayoutSettingsDTO::fromEntity(\E258Tech\Faturacao\Domain\Entity\InvoiceLayoutSettings::defaults());

$typeAccent = match ($doc->type) {
    'NC' => '#c0392b',
    'ORC', 'PP' => '#8a6d3b',
    default => $settings->accentColor,
};

$template = in_array($settings->template, \E258Tech\Faturacao\Domain\Entity\InvoiceLayoutSettings::VALID_TEMPLATES, true)
    ? $settings->template
    : 'classic';

$columnCount = 4 + ($settings->showDiscountColumn ? 1 : 0) + ($settings->showTaxColumn ? 1 : 0);
?>
<!doctype html>
<html lang="pt-PT">
<head>
  <meta charset="utf-8">
  <title><?= Html::e($doc->number) ?></title>
  <style>
    :root { --accent: <?= $typeAccent ?>; }
    * { box-sizing: border-box; }
    body { font-family: "DejaVu Sans", Arial, sans-serif; color: #182733; margin: 0; padding: 40px; font-size: 12px; }
    .header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 40px; }
    .company { display: flex; align-items: center; gap: 12px; }
    .company-icon { width: 42px; height: 42px; background: var(--accent); color: #fff; border-radius: 8px; display: grid; place-items: center; font-size: 20px; font-weight: 700; overflow: hidden; }
    .company-icon img { max-width: 100%; max-height: 100%; object-fit: contain; }
    .company h1 { margin: 0; font-size: 18px; }
    .company small { color: #6f7e89; display: block; }
    .doc-title { text-align: right; }
    .doc-title h2 { margin: 0; font-size: 24px; color: var(--accent); }
    .doc-title small { color: #6f7e89; }
    .type-badge { display: inline-block; margin-top: 6px; padding: 4px 12px; border: 1.5px solid var(--accent); border-radius: 999px; color: var(--accent); font-size: 11px; font-weight: 700; letter-spacing: 0.8px; text-transform: uppercase; }
    .boxes { display: flex; gap: 20px; margin-bottom: 30px; }
    .box { flex: 1; border: 1px solid #dce4e8; border-radius: 8px; padding: 14px; }
    .box h3 { margin: 0 0 8px; font-size: 11px; text-transform: uppercase; color: #6f7e89; letter-spacing: 0.5px; }
    .box p { margin: 0; line-height: 1.5; }
    table { width: 100%; border-collapse: collapse; margin-top: 20px; }
    th, td { padding: 10px; text-align: left; border-bottom: 1px solid #dce4e8; }
    th { background: #f4f7f8; font-weight: 600; }
    td.number, th.number { text-align: right; }
    .totals { width: 320px; margin-left: auto; margin-top: 20px; }
    .totals td { padding: 8px 10px; border: none; }
    .totals tr.total td { font-size: 14px; font-weight: 700; border-top: 2px solid #182733; }
    .notes { margin-top: 30px; color: #6f7e89; }
    .footer { margin-top: 50px; text-align: center; color: #6f7e89; font-size: 10px; }

    <?php if ($template === 'modern'): ?>
    .header { background: var(--accent); border-radius: 12px; padding: 26px 30px; margin-bottom: 30px; }
    .header .company h1, .header .doc-title h2 { color: #fff; }
    .header .company small, .header .doc-title small { color: rgba(255,255,255,0.8); }
    .header .company-icon { background: rgba(255,255,255,0.2); }
    .header .type-badge { border-color: #fff; color: #fff; }
    th { background: #fff; border-bottom: 2px solid var(--accent); }
    .box { border: none; background: #f7f9fa; }
    <?php elseif ($template === 'compact'): ?>
    body { padding: 26px; font-size: 10.5px; }
    .header { margin-bottom: 20px; }
    .company-icon { width: 32px; height: 32px; font-size: 15px; }
    .company h1 { font-size: 15px; }
    .doc-title h2 { font-size: 18px; }
    .boxes { gap: 10px; margin-bottom: 16px; }
    .box { padding: 8px 10px; }
    .box h3 { margin-bottom: 4px; }
    th, td { padding: 6px 8px; }
    .totals { margin-top: 10px; }
    .notes { margin-top: 16px; }
    .footer { margin-top: 26px; }
    <?php endif; ?>
  </style>
</head>
<body>
  <div class="header">
    <div class="company">
      <div class="company-icon">
        <?php if ($settings->logoDataUri): ?>
          <img src="<?= Html::e($settings->logoDataUri) ?>" alt="">
        <?php else: ?>
          <?= Html::e(mb_substr($settings->companyName, 0, 1)) ?>
        <?php endif; ?>
      </div>
      <div>
        <h1><?= Html::e($settings->companyName) ?></h1>
        <small><?= Html::e(trim($settings->companyTaxId . ' · ' . $settings->companyAddress, ' ·')) ?></small>
        <small><?= Html::e(trim($settings->companyEmail . ' · ' . $settings->companyPhone, ' ·')) ?></small>
      </div>
    </div>
    <div class="doc-title">
      <h2><?= Html::e($doc->typeLabel) ?></h2>
      <small><?= Html::e($doc->number) ?></small>
      <div><span class="type-badge"><?= Html::e($doc->type) ?></span></div>
    </div>
  </div>

  <div class="boxes">
    <div class="box">
      <h3>Cliente</h3>
      <p><strong><?= Html::e($doc->customerName) ?></strong><br>
      <?= Html::e($doc->typeLabel) ?></p>
    </div>
    <div class="box">
      <h3>Data de emissão</h3>
      <p><?= Html::datePt($doc->date) ?></p>
    </div>
    <div class="box">
      <h3>Data de vencimento</h3>
      <p><?= Html::datePt($doc->dueDate) ?></p>
    </div>
    <div class="box">
      <h3>Estado</h3>
      <p><?= Html::e($doc->statusLabel) ?></p>
    </div>
  </div>

  <table>
    <thead>
      <tr>
        <th>Descrição</th>
        <th class="number">Qtd.</th>
        <th class="number">Preço unit.</th>
        <?php if ($settings->showDiscountColumn): ?><th class="number">Desc.</th><?php endif; ?>
        <?php if ($settings->showTaxColumn): ?><th class="number">IVA</th><?php endif; ?>
        <th class="number">Total</th>
      </tr>
    </thead>
    <tbody>
      <?php if (empty($doc->lines)): ?>
        <tr><td colspan="<?= $columnCount ?>" style="text-align:center;color:#6f7e89">Documento sem linhas detalhadas.</td></tr>
      <?php else: ?>
        <?php foreach ($doc->lines as $line): ?>
          <tr>
            <td><?= Html::e($line->description) ?></td>
            <td class="number"><?= Html::e(number_format($line->quantity, 2, ',', '.')) ?></td>
            <td class="number"><?= Html::e(number_format($line->price, 2, ',', '.')) ?> MT</td>
            <?php if ($settings->showDiscountColumn): ?><td class="number"><?= Html::e(number_format($line->discount, 1, ',', '.')) ?>%</td><?php endif; ?>
            <?php if ($settings->showTaxColumn): ?><td class="number"><?= $line->tax ?>%</td><?php endif; ?>
            <td class="number"><?= Html::e($line->total) ?></td>
          </tr>
        <?php endforeach; ?>
      <?php endif; ?>
    </tbody>
  </table>

  <table class="totals">
    <tr><td>Subtotal</td><td class="number"><?= Html::e($doc->subtotal) ?></td></tr>
    <tr><td>Descontos</td><td class="number"><?= Html::e($doc->discount) ?></td></tr>
    <tr><td>IVA</td><td class="number"><?= Html::e($doc->tax) ?></td></tr>
    <tr class="total"><td>Total</td><td class="number"><?= Html::e($doc->total) ?></td></tr>
  </table>

  <?php if ($settings->showReference && $doc->reference): ?>
    <div class="notes">
      <strong>Referência:</strong> <?= Html::e($doc->reference) ?>
    </div>
  <?php endif; ?>

  <?php if ($doc->notes): ?>
    <div class="notes">
      <strong>Observações:</strong><br>
      <?= nl2br(Html::e($doc->notes)) ?>
    </div>
  <?php endif; ?>

  <div class="footer">
    <?= Html::e($settings->footerText) ?>
  </div>
</body>
</html>
