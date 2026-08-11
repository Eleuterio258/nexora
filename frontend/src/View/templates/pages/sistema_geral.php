<?php

declare(strict_types=1);

if (!$app->session->canModule('sistema-configuracao')) {
    header('Location: /nexora');
    exit;
}

$csrf       = $app->security->csrfToken();
$pageTitle  = 'Configuração do Sistema';
$activePage = 'sistema_geral';
$breadcrumb = [['Admin', '/nexora/'], ['Configuração', '']];

$brandingResp = $app->nexora->call('GET', '/api/system/branding');
$branding     = ($brandingResp['status'] ?? 0) === 200
    ? ($brandingResp['body'] ?? [])
    : [];

$defaults = [
    'logo_url'         => '',
    'primary_color'    => '#10B981',
    'on_primary_color' => '#FFFFFF',
    'slogan'           => '',
    'contact_email'    => '',
    'contact_phone'    => '',
    'contact_address'  => '',
];

foreach ($defaults as $key => $default) {
    $branding[$key] = $branding[$key] ?? $default;
}

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Configuração do Sistema</h1>
    <p class="adm-text-sm adm-text-muted">Personalize a identidade visual e os contactos da instituição.</p>
</div>

<div id="formMsg"></div>

<form id="brandingForm">
    <input type="hidden" name="csrf_token" value="<?= $csrf ?>">

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Identidade Visual</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-logo_url">URL do Logotipo</label>
                    <input class="adm-input" type="url" id="f-logo_url" name="logo_url"
                           placeholder="https://..." maxlength="500"
                           value="<?= htmlspecialchars($branding['logo_url']) ?>">
                    <p class="adm-input-hint">URL pública da imagem (PNG/SVG recomendado).</p>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-slogan">Slogan</label>
                    <input class="adm-input" type="text" id="f-slogan" name="slogan"
                           maxlength="200" placeholder="Ex.: Educação que transforma"
                           value="<?= htmlspecialchars($branding['slogan']) ?>">
                </div>
            </div>

            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-primary_color">Cor Primária</label>
                    <div style="display:flex;gap:var(--adm-sp-2);align-items:center">
                        <input class="adm-input" type="color" id="f-primary_color_picker"
                               value="<?= htmlspecialchars($branding['primary_color']) ?>"
                               style="width:48px;height:40px;padding:2px;cursor:pointer">
                        <input class="adm-input" type="text" id="f-primary_color" name="primary_color"
                               maxlength="7" placeholder="#10B981"
                               value="<?= htmlspecialchars($branding['primary_color']) ?>">
                    </div>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-on_primary_color">Cor sobre Primária</label>
                    <div style="display:flex;gap:var(--adm-sp-2);align-items:center">
                        <input class="adm-input" type="color" id="f-on_primary_color_picker"
                               value="<?= htmlspecialchars($branding['on_primary_color']) ?>"
                               style="width:48px;height:40px;padding:2px;cursor:pointer">
                        <input class="adm-input" type="text" id="f-on_primary_color" name="on_primary_color"
                               maxlength="7" placeholder="#FFFFFF"
                               value="<?= htmlspecialchars($branding['on_primary_color']) ?>">
                    </div>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label">Pré-visualização</label>
                    <div id="brandPreview" style="display:flex;align-items:center;gap:var(--adm-sp-3);padding:var(--adm-sp-3);border:1px solid var(--adm-gray-200);border-radius:var(--adm-radius)">
                        <img id="previewLogo" src="<?= htmlspecialchars($branding['logo_url'] ?: '/assets/images/logo-192x192.png') ?>"
                             alt="Logo" style="height:40px;max-width:120px;object-fit:contain">
                        <div>
                            <div id="previewSlogan" style="font-weight:600;color:<?= htmlspecialchars($branding['primary_color']) ?>">
                                <?= htmlspecialchars($branding['slogan'] ?: 'Slogan da instituição') ?>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Contactos da Instituição</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-contact_email">Email</label>
                    <input class="adm-input" type="email" id="f-contact_email" name="contact_email"
                           maxlength="150" placeholder="geral@escola.mz"
                           value="<?= htmlspecialchars($branding['contact_email']) ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-contact_phone">Telefone</label>
                    <input class="adm-input" type="tel" id="f-contact_phone" name="contact_phone"
                           maxlength="50" placeholder="+258 84 000 0000"
                           value="<?= htmlspecialchars($branding['contact_phone']) ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-contact_address">Endereço</label>
                    <input class="adm-input" type="text" id="f-contact_address" name="contact_address"
                           maxlength="250" placeholder="Maputo, Moçambique"
                           value="<?= htmlspecialchars($branding['contact_address']) ?>">
                </div>
            </div>
        </div>
    </div>

    <div style="display:flex;gap:var(--adm-sp-3);justify-content:flex-end;padding-bottom:var(--adm-sp-8)">
        <button type="submit" class="adm-btn adm-btn-primary" id="btnSaveBranding">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/>
                <polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/>
            </svg>
            Guardar alterações
        </button>
    </div>
</form>

<script>
(function () {
    const primaryInput   = document.getElementById('f-primary_color');
    const primaryPicker  = document.getElementById('f-primary_color_picker');
    const onPrimaryInput = document.getElementById('f-on_primary_color');
    const onPrimaryPicker= document.getElementById('f-on_primary_color_picker');
    const logoInput      = document.getElementById('f-logo_url');
    const sloganInput    = document.getElementById('f-slogan');
    const previewLogo    = document.getElementById('previewLogo');
    const previewSlogan  = document.getElementById('previewSlogan');

    function syncText(picker, input) {
        picker.addEventListener('input', () => input.value = picker.value);
        input.addEventListener('input', () => {
            if (/^#[0-9A-Fa-f]{6}$/.test(input.value)) picker.value = input.value;
        });
    }

    syncText(primaryPicker, primaryInput);
    syncText(onPrimaryPicker, onPrimaryInput);

    function updatePreview() {
        previewLogo.src = logoInput.value.trim() || '/assets/images/logo-192x192.png';
        previewSlogan.textContent = sloganInput.value.trim() || 'Slogan da instituição';
        previewSlogan.style.color = primaryInput.value;
    }

    logoInput.addEventListener('input', updatePreview);
    sloganInput.addEventListener('input', updatePreview);
    primaryInput.addEventListener('input', updatePreview);

    document.getElementById('brandingForm').addEventListener('submit', async function (e) {
        e.preventDefault();
        const btn = e.submitter || document.getElementById('btnSaveBranding');
        btn.disabled = true;

        const fd = new FormData(this);
        try {
            const res  = await fetch('/nexora/api/sistema_branding_save', { method: 'POST', body: fd });
            const data = await res.json();
            showToast(data.ok ? (data.msg || 'Branding guardado.') : (data.erro || 'Erro'), data.ok ? 'success' : 'error');
        } catch {
            showToast('Erro de ligação', 'error');
        } finally {
            btn.disabled = false;
        }
    });
})();
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
