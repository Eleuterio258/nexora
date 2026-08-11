<?php
use PHC\Presentation\View\Html;

/** @var \PHC\Application\DTO\InvoiceLayoutSettingsDTO $settings */
/** @var string|null $error */
/** @var bool $saved */

$templates = [
  'classic' => 'Clássico',
  'modern' => 'Moderno',
  'compact' => 'Compacto',
];
?>

<?php if ($error !== null): ?>
  <div class="toast error" style="position:fixed;top:20px;right:20px;z-index:100"><?= Html::e($error) ?></div>
<?php elseif ($saved): ?>
  <div class="toast success" style="position:fixed;top:20px;right:20px;z-index:100">Layout da fatura atualizado.</div>
<?php endif; ?>

<div class="page-head compact">
  <div>
    <p class="eyebrow">CONFIGURAÇÃO</p>
    <h1>Layout da fatura</h1>
    <p>Personalize os dados da empresa, o logótipo, o modelo e os campos visíveis nos documentos PDF. A pré-visualização à direita atualiza-se automaticamente.</p>
  </div>
</div>

<div class="layout-editor">
  <article class="panel data-panel">
    <form method="post" action="/settings/invoice-layout" id="layoutForm">
      <div class="form-section">
        <label><span>Modelo do documento</span></label>
        <div class="template-picker">
          <?php foreach ($templates as $key => $label): ?>
            <label class="template-option">
              <input type="radio" name="template" value="<?= Html::e($key) ?>" <?= $settings->template === $key ? 'checked' : '' ?>>
              <div class="template-option-swatch" <?= $key === 'modern' ? 'id="modernSwatch"' : '' ?> style="background:<?= $key === 'modern' ? Html::e($settings->accentColor) : '#f4f7f8' ?>"></div>
              <span><?= Html::e($label) ?></span>
            </label>
          <?php endforeach; ?>
        </div>
      </div>

      <div class="form-section">
        <label><span>Logótipo</span></label>
        <div class="logo-picker">
          <div class="logo-preview" id="logoPreview">
            <?php if ($settings->logoDataUri): ?>
              <img src="<?= Html::e($settings->logoDataUri) ?>" alt="Logótipo">
            <?php else: ?>
              <span>Sem logótipo</span>
            <?php endif; ?>
          </div>
          <div class="logo-actions">
            <input type="file" id="logoFile" accept="image/png,image/jpeg,image/gif,image/webp,image/svg+xml">
            <small>PNG, JPG, GIF, WEBP ou SVG · máx. ~300 KB</small>
            <button type="button" class="btn subtle" id="removeLogo">Remover logótipo</button>
          </div>
        </div>
        <input type="hidden" name="logo_data_uri" id="logoDataUri" value="<?= Html::e($settings->logoDataUri) ?>">
      </div>

      <div class="form-section document-meta">
        <label>
          <span>Nome da empresa</span>
          <input name="company_name" value="<?= Html::e($settings->companyName) ?>" required>
        </label>
        <label>
          <span>NUIT</span>
          <input name="company_tax_id" value="<?= Html::e($settings->companyTaxId) ?>">
        </label>
        <label>
          <span>Morada</span>
          <input name="company_address" value="<?= Html::e($settings->companyAddress) ?>">
        </label>
        <label>
          <span>Cor de destaque</span>
          <input type="color" name="accent_color" id="accentColor" value="<?= Html::e($settings->accentColor) ?>" style="padding:2px;height:36px">
        </label>
        <label>
          <span>Email</span>
          <input type="email" name="company_email" value="<?= Html::e($settings->companyEmail) ?>">
        </label>
        <label>
          <span>Telefone</span>
          <input name="company_phone" value="<?= Html::e($settings->companyPhone) ?>">
        </label>
      </div>

      <div class="form-section notes">
        <label>
          <span>Texto de rodapé</span>
          <textarea name="footer_text" rows="2"><?= Html::e($settings->footerText) ?></textarea>
        </label>
        <label class="checkbox-row">
          <input type="checkbox" name="show_reference" value="1" <?= $settings->showReference ? 'checked' : '' ?>>
          <span>Mostrar referência do documento no PDF</span>
        </label>
        <label class="checkbox-row">
          <input type="checkbox" name="show_discount_column" value="1" <?= $settings->showDiscountColumn ? 'checked' : '' ?>>
          <span>Mostrar coluna de desconto na tabela de linhas</span>
        </label>
        <label class="checkbox-row">
          <input type="checkbox" name="show_tax_column" value="1" <?= $settings->showTaxColumn ? 'checked' : '' ?>>
          <span>Mostrar coluna de IVA na tabela de linhas</span>
        </label>
      </div>

      <button type="submit" class="btn primary">Guardar layout</button>
    </form>
  </article>

  <div class="layout-preview" id="layoutPreview">
    <div class="layout-preview-head">
      <span>Pré-visualização</span>
      <button type="button" id="layoutPreviewToggle" title="Ver em ecrã inteiro">⤢</button>
    </div>
    <iframe id="layoutPreviewFrame" src="/settings/invoice-layout/preview" title="Pré-visualização do documento"></iframe>
  </div>
  <div class="layout-preview-backdrop" id="layoutPreviewBackdrop"></div>
</div>

<script>
(function () {
  var form = document.getElementById('layoutForm');
  var frame = document.getElementById('layoutPreviewFrame');
  var timer = null;

  function updatePreview() {
    fetch('/settings/invoice-layout/preview', { method: 'POST', body: new FormData(form) })
      .then(function (res) { return res.text(); })
      .then(function (html) { frame.srcdoc = html; })
      .catch(function () {});
  }

  form.addEventListener('input', function () {
    clearTimeout(timer);
    timer = setTimeout(updatePreview, 300);
  });
  form.addEventListener('change', function () {
    clearTimeout(timer);
    timer = setTimeout(updatePreview, 50);
  });

  var accentColor = document.getElementById('accentColor');
  var modernSwatch = document.getElementById('modernSwatch');
  accentColor.addEventListener('input', function () {
    if (modernSwatch) modernSwatch.style.background = accentColor.value;
  });

  var logoFile = document.getElementById('logoFile');
  var logoDataUri = document.getElementById('logoDataUri');
  var logoPreview = document.getElementById('logoPreview');
  var removeLogo = document.getElementById('removeLogo');
  var MAX_LOGO_BYTES = 300 * 1024;

  logoFile.addEventListener('change', function () {
    var file = logoFile.files[0];
    if (!file) return;
    if (file.size > MAX_LOGO_BYTES) {
      alert('O logótipo é demasiado grande. Escolha uma imagem até 300 KB.');
      logoFile.value = '';
      return;
    }
    var reader = new FileReader();
    reader.onload = function () {
      logoDataUri.value = reader.result;
      logoPreview.innerHTML = '<img src="' + reader.result + '" alt="Logótipo">';
      updatePreview();
    };
    reader.readAsDataURL(file);
  });

  removeLogo.addEventListener('click', function () {
    logoDataUri.value = '';
    logoFile.value = '';
    logoPreview.innerHTML = '<span>Sem logótipo</span>';
    updatePreview();
  });

  var preview = document.getElementById('layoutPreview');
  var backdrop = document.getElementById('layoutPreviewBackdrop');
  var toggle = document.getElementById('layoutPreviewToggle');

  function setFullscreen(on) {
    preview.classList.toggle('is-fullscreen', on);
    backdrop.classList.toggle('visible', on);
    toggle.textContent = on ? '✕' : '⤢';
    toggle.title = on ? 'Sair do ecrã inteiro' : 'Ver em ecrã inteiro';
  }

  toggle.addEventListener('click', function () {
    setFullscreen(!preview.classList.contains('is-fullscreen'));
  });
  backdrop.addEventListener('click', function () {
    setFullscreen(false);
  });
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') setFullscreen(false);
  });
})();
</script>
