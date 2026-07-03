<?php
// ── Dados da sessão e terminal ────────────────────────────────────────────
$sessResp = $app->nexora->call('GET', '/api/pos/sessoes/atual');
$sessao   = $sessResp['status'] === 200 ? $sessResp['body'] : null;

$termResp    = $app->nexora->call('GET', '/api/pos/terminais');
$terminais   = $termResp['status'] === 200 ? ($termResp['body'] ?? []) : [];
$terminalMap = [];
foreach ($terminais as $t) $terminalMap[(int) $t['id']] = $t;
$terminaisAtivos = array_filter($terminais, static fn ($t) => (bool) $t['activo']);

$terminalAtual = null;
$warehouseId   = null;
if ($sessao !== null) {
    $terminalAtual = $terminalMap[(int) $sessao['terminal_id']] ?? null;
    $warehouseId   = $terminalAtual['warehouse_id'] ?? null;
}

$csrf      = $app->security->csrfToken();
$operador  = $app->session->user()['nome'] ?? 'Operador';
$caixaNome = $terminalAtual['nome'] ?? ($terminalAtual['codigo'] ?? 'Caixa');

// Layout POS independente — não usa top.php
?>
<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>POS · E258Tech</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700;800&family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="/assets/css/nexora.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.7.2/css/all.min.css" crossorigin="anonymous" referrerpolicy="no-referrer">
<style>
/* ── Reset POS ──────────────────────────────────────────────────────────── */
* { margin:0; padding:0; box-sizing:border-box; }
html, body { height:100%; overflow:hidden; font-family:'Plus Jakarta Sans',sans-serif; font-size:13px; background:#f1f5f9; }

/* ── Layout principal ───────────────────────────────────────────────────── */
.pos-wrap    { display:flex; height:100vh; }
.pos-sidebar { width:200px; background:#0d2118; display:flex; flex-direction:column; flex-shrink:0; }
.pos-body    { flex:1; display:flex; flex-direction:column; min-width:0; overflow:hidden; }

/* ── Sidebar ────────────────────────────────────────────────────────────── */
.pos-logo {
    padding:20px 16px 16px;
    display:flex; align-items:center; gap:10px;
    border-bottom:1px solid rgba(255,255,255,.08);
}
.pos-logo img { height:24px; filter:brightness(0) invert(1); opacity:.9; }
.pos-logo-text { font-family:'Outfit',sans-serif; font-weight:700; font-size:14px; color:#fff; opacity:.9; }

.pos-nav { flex:1; padding:12px 8px; overflow-y:auto; }
.pos-nav-item {
    display:flex; align-items:center; gap:10px;
    padding:9px 12px; border-radius:8px;
    color:rgba(255,255,255,.6); font-size:13px; font-weight:500;
    cursor:pointer; text-decoration:none;
    transition:background .12s, color .12s;
    margin-bottom:2px;
}
.pos-nav-item:hover   { background:rgba(255,255,255,.08); color:#fff; }
.pos-nav-item.active  { background:rgba(16,185,129,.18); color:#34d399; }
.pos-nav-item i       { width:16px; text-align:center; font-size:13px; }

.pos-sidebar-footer {
    border-top:1px solid rgba(255,255,255,.07);
    padding:12px 16px;
}
.pos-operator { display:flex; align-items:center; gap:8px; }
.pos-operator-avatar {
    width:30px; height:30px; border-radius:50%;
    background:#10b981; display:flex; align-items:center; justify-content:center;
    color:#fff; font-weight:700; font-size:12px; flex-shrink:0;
}
.pos-operator-info { flex:1; min-width:0; }
.pos-operator-name  { font-size:12px; font-weight:600; color:#fff; opacity:.85; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.pos-operator-time  { font-size:10px; color:rgba(255,255,255,.4); }
.pos-logout { color:rgba(255,255,255,.4); background:none; border:none; cursor:pointer; padding:4px; border-radius:4px; }
.pos-logout:hover { color:#ef4444; background:rgba(239,68,68,.1); }

/* ── Top bar ─────────────────────────────────────────────────────────────── */
.pos-topbar {
    background:#fff; border-bottom:1px solid #e5e7eb;
    display:flex; align-items:center; gap:10px;
    padding:10px 16px; height:52px; flex-shrink:0;
}
.pos-search-outer { flex:1; position:relative; }
.pos-search-input {
    width:100%; height:34px; border:1px solid #d1d5db;
    border-radius:8px; padding:0 36px 0 36px;
    font-size:13px; font-family:inherit; outline:none;
    transition:border-color .15s, box-shadow .15s;
    background:#f9fafb;
}
.pos-search-input:focus { border-color:#10b981; box-shadow:0 0 0 3px rgba(16,185,129,.1); background:#fff; }
.pos-search-icon  { position:absolute; left:10px; top:50%; transform:translateY(-50%); color:#9ca3af; font-size:12px; }
.pos-filter-btn {
    display:flex; align-items:center; gap:6px; height:34px; padding:0 14px;
    background:none; border:1px solid #d1d5db; border-radius:8px;
    font-size:12px; font-weight:600; color:#374151; cursor:pointer; white-space:nowrap;
    transition:background .1s;
}
.pos-filter-btn:hover { background:#f3f4f6; }
.pos-filter-btn i { color:#10b981; }
.pos-caixa-badge {
    display:flex; align-items:center; gap:6px; padding:4px 12px;
    border:1px solid #e5e7eb; border-radius:8px;
    font-size:12px; font-weight:600; color:#374151; white-space:nowrap;
}
.pos-caixa-dot { width:7px; height:7px; border-radius:50%; background:#10b981; }

/* ── Barcode row ─────────────────────────────────────────────────────────── */
.pos-barcode-row {
    background:#fff; border-bottom:1px solid #e5e7eb;
    display:flex; align-items:center; gap:10px;
    padding:6px 16px; height:38px; flex-shrink:0;
}
.pos-barcode-input {
    flex:1; height:26px; border:none; border-bottom:1.5px solid #d1d5db;
    font-size:12px; font-family:inherit; outline:none; color:#374151;
    background:transparent; padding:0 4px;
    transition:border-color .15s;
}
.pos-barcode-input:focus { border-bottom-color:#10b981; }
.pos-barcode-icon { color:#9ca3af; font-size:16px; }

/* ── Content area ─────────────────────────────────────────────────────────── */
.pos-content { flex:1; display:flex; overflow:hidden; }

/* ── Products panel ──────────────────────────────────────────────────────── */
.pos-products { flex:1; overflow-y:auto; display:flex; flex-direction:column; }
.pos-products-table { width:100%; border-collapse:collapse; }
.pos-products-table th {
    text-align:left; padding:8px 12px;
    font-size:11px; text-transform:uppercase; letter-spacing:.05em;
    font-weight:600; color:#6b7280; background:#f9fafb;
    border-bottom:1px solid #e5e7eb; position:sticky; top:0; z-index:1;
}
.pos-products-table td { padding:10px 12px; border-bottom:1px solid #f3f4f6; vertical-align:middle; }
.pos-products-table tr:hover td { background:#f9fafb; }
.pos-prod-name { font-weight:600; font-size:13px; color:#111827; }
.pos-prod-ref  { font-size:11px; color:#9ca3af; margin-top:1px; }
.pos-prod-img  { width:32px; height:32px; border-radius:6px; object-fit:cover; background:#f3f4f6; }
.pos-add-btn {
    width:28px; height:28px; border-radius:50%;
    background:#10b981; color:#fff; border:none; cursor:pointer;
    display:flex; align-items:center; justify-content:center;
    font-size:16px; font-weight:300; transition:background .12s;
}
.pos-add-btn:hover { background:#059669; }

/* ── Payment methods bar ─────────────────────────────────────────────────── */
.pos-payment-bar {
    background:#fff; border-top:1px solid #e5e7eb;
    padding:10px 16px; display:flex; align-items:center; gap:8px;
    flex-shrink:0;
}
.pos-payment-label { font-size:12px; font-weight:600; color:#374151; margin-right:4px; white-space:nowrap; }
.pos-pay-method {
    display:flex; align-items:center; gap:6px; height:34px; padding:0 14px;
    border:1.5px solid #e5e7eb; border-radius:8px;
    font-size:12px; font-weight:600; color:#6b7280; cursor:pointer;
    transition:all .12s; background:#fff; white-space:nowrap;
}
.pos-pay-method:hover  { border-color:#10b981; color:#10b981; }
.pos-pay-method.active { border-color:#10b981; background:#ecfdf5; color:#059669; }
.pos-pay-method i { font-size:14px; }

/* ── Cart panel ──────────────────────────────────────────────────────────── */
.pos-cart { width:300px; flex-shrink:0; background:#fff; border-left:1px solid #e5e7eb; display:flex; flex-direction:column; }
.pos-cart-header {
    display:flex; align-items:center; justify-content:space-between;
    padding:14px 16px; border-bottom:1px solid #e5e7eb;
}
.pos-cart-title { font-family:'Outfit',sans-serif; font-size:15px; font-weight:700; color:#111827; }
.pos-cart-clear { background:none; border:none; cursor:pointer; color:#9ca3af; font-size:14px; }
.pos-cart-clear:hover { color:#ef4444; }

.pos-cart-items { flex:1; overflow-y:auto; padding:8px 0; }
.pos-cart-item {
    display:flex; align-items:flex-start; gap:10px;
    padding:10px 16px;
    border-bottom:1px solid #f3f4f6;
}
.pos-cart-item:last-child { border-bottom:none; }
.pos-cart-item-info { flex:1; min-width:0; }
.pos-cart-item-name  { font-size:13px; font-weight:600; color:#111827; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.pos-cart-item-ref   { font-size:11px; color:#9ca3af; margin-top:1px; }
.pos-cart-item-price { font-size:13px; font-weight:700; color:#374151; white-space:nowrap; }
.pos-cart-item-remove { background:none; border:none; cursor:pointer; color:#d1d5db; font-size:13px; padding:2px; margin-top:1px; flex-shrink:0; }
.pos-cart-item-remove:hover { color:#ef4444; }
.pos-cart-empty { display:flex; flex-direction:column; align-items:center; justify-content:center; height:100%; gap:8px; color:#9ca3af; padding:24px; text-align:center; }

.pos-cart-totals { border-top:1px solid #e5e7eb; padding:14px 16px; }
.pos-cart-total-row { display:flex; justify-content:space-between; align-items:center; margin-bottom:6px; }
.pos-cart-total-label { font-size:13px; color:#6b7280; }
.pos-cart-total-val   { font-size:13px; font-weight:600; color:#374151; }
.pos-cart-total-main  { font-size:20px; font-weight:800; color:#10b981; font-family:'Outfit',sans-serif; }

.pos-cart-actions { padding:12px 16px 14px; display:flex; flex-direction:column; gap:8px; border-top:1px solid #f3f4f6; }
.pos-btn-desconto {
    height:38px; border:1.5px solid #d1d5db; border-radius:8px;
    background:#fff; cursor:pointer; font-size:13px; font-weight:600;
    color:#374151; display:flex; align-items:center; justify-content:center; gap:6px;
    transition:border-color .12s;
}
.pos-btn-desconto:hover { border-color:#10b981; color:#10b981; }
.pos-btn-finalizar {
    height:42px; background:#10b981; border:none; border-radius:8px;
    cursor:pointer; font-size:14px; font-weight:700; color:#fff;
    display:flex; align-items:center; justify-content:center; gap:8px;
    transition:background .12s;
}
.pos-btn-finalizar:hover:not(:disabled) { background:#059669; }
.pos-btn-finalizar:disabled { opacity:.5; cursor:not-allowed; }

/* ── Search dropdown ─────────────────────────────────────────────────────── */
.pos-search-drop {
    display:none; position:absolute; top:calc(100% + 4px); left:0; right:0;
    z-index:50; background:#fff; border:1px solid #e5e7eb; border-radius:10px;
    max-height:280px; overflow-y:auto; box-shadow:0 8px 24px rgba(0,0,0,.1);
}
.pos-drop-item {
    display:flex; align-items:center; gap:10px; padding:10px 14px;
    cursor:pointer; border-bottom:1px solid #f3f4f6; transition:background .1s;
}
.pos-drop-item:last-child { border-bottom:none; }
.pos-drop-item:hover { background:#f9fafb; }
.pos-drop-name { font-size:13px; font-weight:600; color:#111827; }
.pos-drop-ref  { font-size:11px; color:#9ca3af; }
.pos-drop-price { font-size:13px; font-weight:700; color:#10b981; white-space:nowrap; }
.pos-drop-stock { font-size:11px; color:#9ca3af; }
.pos-drop-empty { padding:14px; text-align:center; color:#9ca3af; font-size:13px; }

/* ── Modal Abrir Sessão ──────────────────────────────────────────────────── */
.pos-modal-overlay {
    position:fixed; inset:0; background:rgba(0,0,0,.5); z-index:100;
    display:flex; align-items:center; justify-content:center;
}
.pos-modal {
    background:#fff; border-radius:16px; padding:28px; width:400px;
    box-shadow:0 20px 60px rgba(0,0,0,.2);
}
.pos-modal h2 { font-family:'Outfit',sans-serif; font-size:18px; font-weight:700; color:#111827; margin-bottom:20px; }
.pos-modal-footer { display:flex; justify-content:flex-end; gap:10px; margin-top:20px; }

/* ── Toast ─────────────────────────────────────────────────────────────── */
.pos-toast {
    position:fixed; bottom:20px; right:20px; z-index:9999;
    background:#111827; color:#fff; padding:10px 18px; border-radius:10px;
    font-size:13px; font-weight:500; opacity:0; transform:translateY(8px);
    transition:opacity .25s, transform .25s; pointer-events:none;
    display:flex; align-items:center; gap:8px; max-width:340px;
}
.pos-toast.show { opacity:1; transform:translateY(0); }
.pos-toast.success { background:#059669; }
.pos-toast.error   { background:#dc2626; }

/* Scrollbars finos */
::-webkit-scrollbar { width:4px; } ::-webkit-scrollbar-track { background:transparent; } ::-webkit-scrollbar-thumb { background:#d1d5db; border-radius:2px; }
</style>
</head>
<body>

<div class="pos-wrap">

<!-- ── SIDEBAR ─────────────────────────────────────────────────────────── -->
<nav class="pos-sidebar">
    <div class="pos-logo">
        <img src="/assets/images/e258tech-logo.png" alt="E258Tech">
    </div>
    <div class="pos-nav">
        <a href="/nexora/pos"             class="pos-nav-item active"><i class="fa-solid fa-cash-register"></i> Vendas</a>
        <a href="/nexora/pos/dashboard"   class="pos-nav-item"><i class="fa-solid fa-gauge"></i> Dashboard</a>
        <a href="/nexora/pos/terminais"   class="pos-nav-item"><i class="fa-solid fa-desktop"></i> Caixas</a>
        <a href="/nexora/pos/relatorios"  class="pos-nav-item"><i class="fa-solid fa-chart-bar"></i> Relatórios</a>
        <a href="/nexora/clientes"        class="pos-nav-item"><i class="fa-solid fa-users"></i> Clientes</a>
        <a href="/nexora/pos/devolucoes"  class="pos-nav-item"><i class="fa-solid fa-rotate-left"></i> Devoluções</a>
    </div>
    <div class="pos-sidebar-footer">
        <div class="pos-operator">
            <div class="pos-operator-avatar"><?= strtoupper(substr($operador, 0, 1)) ?></div>
            <div class="pos-operator-info">
                <div class="pos-operator-name"><?= htmlspecialchars(explode(' ', $operador)[0]) ?></div>
                <div class="pos-operator-time" id="posTime"><?= date('d/m/Y H:i') ?></div>
            </div>
            <a href="/nexora/logout" class="pos-logout" title="Sair">
                <i class="fa-solid fa-right-from-bracket"></i>
            </a>
        </div>
    </div>
</nav>

<!-- ── BODY ────────────────────────────────────────────────────────────── -->
<div class="pos-body">

<?php if ($sessao === null): ?>
<!-- ══ ABRIR SESSÃO ══════════════════════════════════════════════════════ -->
<div style="flex:1;display:flex;align-items:center;justify-content:center;background:#f8fafc">
    <div class="pos-modal" style="width:460px;box-shadow:var(--adm-shadow-md)">
        <h2><i class="fa-solid fa-cash-register" style="color:#10b981;margin-right:8px"></i> Abrir Sessão de Caixa</h2>
        <?php if (!$terminaisAtivos): ?>
        <p style="color:#6b7280;font-size:13px;margin-bottom:16px">
            Nenhum terminal activo.
            <a href="/nexora/pos/terminais" style="color:#10b981">Criar terminal →</a>
        </p>
        <?php else: ?>
        <div style="margin-bottom:14px">
            <label style="display:block;font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.04em;color:#6b7280;margin-bottom:6px">Terminal</label>
            <select id="o-terminal" style="width:100%;height:38px;border:1px solid #d1d5db;border-radius:8px;padding:0 10px;font-size:13px;font-family:inherit;outline:none">
                <option value="">— Seleccionar —</option>
                <?php foreach ($terminaisAtivos as $t): ?>
                <option value="<?= (int)$t['id'] ?>"><?= htmlspecialchars($t['codigo'] . ' — ' . $t['nome']) ?></option>
                <?php endforeach; ?>
            </select>
        </div>
        <div style="margin-bottom:14px">
            <label style="display:block;font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.04em;color:#6b7280;margin-bottom:6px">Valor de Abertura (MT)</label>
            <input id="o-abertura" type="number" min="0" step="0.01" value="0"
                   style="width:100%;height:38px;border:1px solid #d1d5db;border-radius:8px;padding:0 10px;font-size:13px;font-family:inherit;outline:none">
        </div>
        <div class="pos-modal-footer">
            <a href="/nexora/" style="height:38px;padding:0 16px;display:flex;align-items:center;border:1px solid #d1d5db;border-radius:8px;font-size:13px;font-weight:600;color:#374151;text-decoration:none">Cancelar</a>
            <button onclick="abrirSessao()" style="height:38px;padding:0 20px;background:#10b981;border:none;border-radius:8px;font-size:13px;font-weight:700;color:#fff;cursor:pointer">
                <i class="fa-solid fa-lock-open"></i> Abrir Caixa
            </button>
        </div>
        <?php endif; ?>
    </div>
</div>

<?php else: ?>
<!-- ══ PDV PRINCIPAL ═════════════════════════════════════════════════════ -->

<!-- Top bar -->
<div class="pos-topbar">
    <div class="pos-search-outer">
        <i class="fa-solid fa-magnifying-glass pos-search-icon"></i>
        <input id="searchInput" class="pos-search-input" type="text"
               placeholder="Pesquisar produto por nome, código ou referência..."
               autocomplete="off">
        <div id="searchDrop" class="pos-search-drop"></div>
    </div>
    <button class="pos-filter-btn"><i class="fa-solid fa-sliders"></i> Filtrar</button>
    <div class="pos-caixa-badge">
        <span class="pos-caixa-dot"></span>
        <?= htmlspecialchars($caixaNome) ?>
        <i class="fa-solid fa-ellipsis-vertical" style="color:#9ca3af;margin-left:4px"></i>
    </div>
</div>

<!-- Barcode row -->
<div class="pos-barcode-row">
    <i class="fa-solid fa-barcode pos-barcode-icon"></i>
    <input id="barcodeInput" class="pos-barcode-input" type="text" placeholder="Digite ou escaneie o código de barras">
    <i class="fa-solid fa-qrcode" style="color:#9ca3af;font-size:18px;cursor:pointer" onclick="document.getElementById('barcodeInput').focus()"></i>
</div>

<!-- Content: products + cart -->
<div class="pos-content">

    <!-- Products list -->
    <div class="pos-products">
        <table class="pos-products-table">
            <thead>
                <tr>
                    <th style="width:40px"></th>
                    <th>Produto</th>
                    <th style="width:90px">Quantidade</th>
                    <th style="width:110px">Preço Unitário</th>
                    <th style="width:110px">Preço Total</th>
                    <th style="width:50px"></th>
                </tr>
            </thead>
            <tbody id="cartTableBody">
                <tr id="emptyRow">
                    <td colspan="6" style="text-align:center;padding:40px;color:#9ca3af">
                        <i class="fa-solid fa-bag-shopping" style="font-size:2rem;opacity:.3;display:block;margin-bottom:10px"></i>
                        Pesquise ou escaneie um produto para adicionar à venda
                    </td>
                </tr>
            </tbody>
        </table>
    </div>

    <!-- Cart panel -->
    <div class="pos-cart">
        <div class="pos-cart-header">
            <span class="pos-cart-title">
                <i class="fa-solid fa-shopping-cart" style="color:#10b981;margin-right:6px"></i>
                Carrinho
            </span>
            <button class="pos-cart-clear" onclick="limparCarrinho()" title="Limpar carrinho">
                <i class="fa-solid fa-trash"></i>
            </button>
        </div>

        <div class="pos-cart-items" id="cartItems">
            <div class="pos-cart-empty">
                <i class="fa-solid fa-cart-shopping" style="font-size:2rem;opacity:.2"></i>
                <p style="font-size:13px">Carrinho vazio</p>
            </div>
        </div>

        <div class="pos-cart-totals">
            <div class="pos-cart-total-row">
                <span class="pos-cart-total-label">SubTotal</span>
                <span class="pos-cart-total-val" id="subtotalVal">0,00 MT</span>
            </div>
            <div class="pos-cart-total-row">
                <span class="pos-cart-total-label" id="impostoLabel">Imposto (IVA 17%)</span>
                <span class="pos-cart-total-val" id="impostoVal">0,00 MT</span>
            </div>
            <div class="pos-cart-total-row" style="margin-top:8px;padding-top:8px;border-top:1px solid #e5e7eb">
                <span style="font-size:15px;font-weight:700;color:#111827">Total</span>
                <span class="pos-cart-total-main" id="totalVal">0,00 MT</span>
            </div>
        </div>

        <div class="pos-cart-actions">
            <button class="pos-btn-desconto" onclick="aplicarDesconto()">
                <i class="fa-solid fa-tag"></i> Aplicar Desconto
            </button>
            <button class="pos-btn-finalizar" id="btnFinalizar" onclick="finalizarVenda()" disabled>
                <i class="fa-solid fa-circle-check"></i> Finalizar Venda
            </button>
        </div>
    </div>
</div>

<!-- Payment methods bar -->
<div class="pos-payment-bar">
    <span class="pos-payment-label">Forma de Pagamento</span>
    <button class="pos-pay-method active" data-method="Dinheiro"       onclick="selectMetodo(this)"><i class="fa-solid fa-money-bill-wave"></i> Dinheiro</button>
    <button class="pos-pay-method"        data-method="Cartão"         onclick="selectMetodo(this)"><i class="fa-solid fa-credit-card"></i> Cartão</button>
    <button class="pos-pay-method"        data-method="M-Pesa"         onclick="selectMetodo(this)"><i class="fa-solid fa-mobile-screen"></i> M-Pesa</button>
    <button class="pos-pay-method"        data-method="E-Mola"         onclick="selectMetodo(this)"><i class="fa-solid fa-mobile-alt"></i> E-Mola</button>
    <button class="pos-pay-method"        data-method="Transferência"  onclick="selectMetodo(this)"><i class="fa-solid fa-building-columns"></i> Transferência</button>
</div>

<?php endif; ?>

</div> <!-- /pos-body -->
</div> <!-- /pos-wrap -->

<div id="posToast" class="pos-toast"></div>

<script>
const CSRF = <?= json_encode($csrf) ?>;
<?php if ($sessao !== null): ?>
const SESSAO_ID    = <?= (int)$sessao['id'] ?>;
const WAREHOUSE_ID = <?= $warehouseId !== null ? (int)$warehouseId : 'null' ?>;
const IVA_DEFAULT  = 17;

let cart        = [];    // { product_id, product_variant_id, codigo, nome, quantidade, preco_unitario, imposto_percent }
let metodoAtual = 'Dinheiro';
let lastResults = [];

// ── Utils ────────────────────────────────────────────────────────────────────
function esc(s) { return String(s??'').replace(/[&<>"']/g, c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }
function fmt(v) { return (+(v)||0).toFixed(2).replace('.',','); }

function showToast(msg, type='success') {
    const el = document.getElementById('posToast');
    el.className = 'pos-toast ' + type;
    el.innerHTML = `<i class="fa-solid fa-${type==='error'?'circle-xmark':'circle-check'}"></i> ${msg}`;
    el.classList.add('show');
    setTimeout(() => el.classList.remove('show'), 3500);
}

// ── Clock ─────────────────────────────────────────────────────────────────────
setInterval(() => {
    const t = document.getElementById('posTime');
    if (t) t.textContent = new Date().toLocaleString('pt-PT',{day:'2-digit',month:'2-digit',year:'numeric',hour:'2-digit',minute:'2-digit'});
}, 10000);

// ── Payment method ────────────────────────────────────────────────────────────
function selectMetodo(btn) {
    document.querySelectorAll('.pos-pay-method').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    metodoAtual = btn.dataset.method;
}

// ── Product search ────────────────────────────────────────────────────────────
let searchTimer;
document.getElementById('searchInput').addEventListener('input', () => {
    clearTimeout(searchTimer);
    const q = document.getElementById('searchInput').value.trim();
    if (!q) { hideDrop(); return; }
    searchTimer = setTimeout(() => buscarProdutos(q), 280);
});
document.getElementById('searchInput').addEventListener('keydown', e => {
    if (e.key === 'Escape') hideDrop();
});
document.addEventListener('click', e => {
    if (!document.getElementById('searchInput').contains(e.target)) hideDrop();
});

// Barcode scanner
document.getElementById('barcodeInput').addEventListener('keydown', e => {
    if (e.key === 'Enter') {
        const q = e.target.value.trim();
        if (q) { buscarProdutos(q, true); e.target.value = ''; }
    }
});

async function buscarProdutos(q, autoAdd=false) {
    const params = new URLSearchParams({ q });
    if (WAREHOUSE_ID) params.set('warehouse_id', WAREHOUSE_ID);
    try {
        const res  = await fetch('/nexora/api/pos_produtos_buscar?' + params);
        const data = await res.json();
        const items = Array.isArray(data) ? data : [];
        lastResults = items;
        if (autoAdd && items.length === 1) { adicionarAoCarrinho(0); return; }
        renderDrop(items);
    } catch {}
}

function renderDrop(items) {
    const drop = document.getElementById('searchDrop');
    if (!items.length) {
        drop.innerHTML = '<div class="pos-drop-empty">Sem resultados</div>';
        drop.style.display = 'block'; return;
    }
    drop.innerHTML = items.map((p,i) => `
        <div class="pos-drop-item" onclick="adicionarAoCarrinho(${i})">
            <div style="width:32px;height:32px;background:#f3f4f6;border-radius:6px;flex-shrink:0;overflow:hidden">
                ${p.imagem_url ? `<img src="${esc(p.imagem_url)}" style="width:100%;height:100%;object-fit:cover">` : '<div style="width:100%;height:100%;display:flex;align-items:center;justify-content:center;color:#9ca3af;font-size:14px"><i class="fa-solid fa-box"></i></div>'}
            </div>
            <div style="flex:1;min-width:0">
                <div class="pos-drop-name">${esc(p.nome)}</div>
                <div class="pos-drop-ref">${esc(p.codigo)}</div>
            </div>
            <div style="text-align:right;flex-shrink:0">
                <div class="pos-drop-price">${fmt(p.preco_venda)} MT</div>
                <div class="pos-drop-stock">Stock: ${p.available_quantity ?? '—'}</div>
            </div>
        </div>`).join('');
    drop.style.display = 'block';
}
function hideDrop() { document.getElementById('searchDrop').style.display = 'none'; }

// ── Add to cart ────────────────────────────────────────────────────────────
function adicionarAoCarrinho(i) {
    const p = lastResults[i];
    if (!p) return;
    const ex = cart.find(c => c.product_id === p.product_id && c.product_variant_id === p.product_variant_id);
    if (ex) { ex.quantidade += 1; }
    else {
        cart.push({
            product_id: p.product_id,
            product_variant_id: p.product_variant_id ?? null,
            codigo: p.codigo, nome: p.nome,
            quantidade: 1,
            preco_unitario: +p.preco_venda,
            imposto_percent: +(p.iva_percentual ?? IVA_DEFAULT),
            imagem: p.imagem_url ?? null,
        });
    }
    document.getElementById('searchInput').value = '';
    hideDrop();
    renderAll();
}

function limparCarrinho() {
    if (!cart.length) return;
    if (!confirm('Limpar o carrinho?')) return;
    cart = []; renderAll();
}

// ── Render cart ────────────────────────────────────────────────────────────
function renderAll() {
    renderTable();
    renderCartPanel();
    recalcular();
}

function renderTable() {
    const tbody = document.getElementById('cartTableBody');
    if (!cart.length) {
        tbody.innerHTML = `<tr id="emptyRow"><td colspan="6" style="text-align:center;padding:40px;color:#9ca3af">
            <i class="fa-solid fa-bag-shopping" style="font-size:2rem;opacity:.3;display:block;margin-bottom:10px"></i>
            Pesquise ou escaneie um produto</td></tr>`;
        return;
    }
    tbody.innerHTML = cart.map((item,i) => {
        const sub = item.quantidade * item.preco_unitario;
        return `<tr>
            <td style="width:40px">
                <div style="width:32px;height:32px;background:#f3f4f6;border-radius:6px;overflow:hidden">
                    ${item.imagem ? `<img src="${esc(item.imagem)}" style="width:100%;height:100%;object-fit:cover">` : '<div style="width:100%;height:100%;display:flex;align-items:center;justify-content:center;color:#9ca3af;font-size:12px"><i class="fa-solid fa-box"></i></div>'}
                </div>
            </td>
            <td><div class="pos-prod-name">${esc(item.nome)}</div><div class="pos-prod-ref">${esc(item.codigo)}</div></td>
            <td><input type="number" min="1" step="1" value="${item.quantidade}"
                style="width:70px;height:28px;border:1px solid #d1d5db;border-radius:6px;padding:0 8px;font-size:13px;font-family:inherit;outline:none;text-align:center"
                onchange="mudarQtd(${i},this.value)" onfocus="this.select()"></td>
            <td style="color:#374151;font-weight:600">${fmt(item.preco_unitario)} MT</td>
            <td style="font-weight:700;color:#111827">${fmt(sub)} MT</td>
            <td><button class="pos-add-btn" onclick="adicionarMais(${i})" style="background:#ecfdf5;color:#10b981">+</button></td>
        </tr>`;
    }).join('');
}

function renderCartPanel() {
    const el = document.getElementById('cartItems');
    if (!cart.length) {
        el.innerHTML = `<div class="pos-cart-empty"><i class="fa-solid fa-cart-shopping" style="font-size:2rem;opacity:.2"></i><p>Carrinho vazio</p></div>`;
        return;
    }
    el.innerHTML = cart.map((item,i) => {
        const sub = item.quantidade * item.preco_unitario;
        return `<div class="pos-cart-item">
            <div class="pos-cart-item-info">
                <div class="pos-cart-item-name">${esc(item.nome)}</div>
                <div class="pos-cart-item-ref">${item.quantidade} × ${fmt(item.preco_unitario)}</div>
            </div>
            <span class="pos-cart-item-price">${fmt(sub)} MT</span>
            <button class="pos-cart-item-remove" onclick="removerItem(${i})"><i class="fa-solid fa-xmark"></i></button>
        </div>`;
    }).join('');
}

function mudarQtd(i, val) {
    const q = +val;
    cart[i].quantidade = q > 0 ? q : 1;
    renderAll();
}
function adicionarMais(i) { cart[i].quantidade++; renderAll(); }
function removerItem(i)   { cart.splice(i,1); renderAll(); }

// ── Totals ─────────────────────────────────────────────────────────────────
function recalcular() {
    let subtotal = 0, imposto = 0;
    cart.forEach(item => {
        const s = item.quantidade * item.preco_unitario;
        subtotal += s;
        imposto  += s * item.imposto_percent / 100;
    });
    document.getElementById('subtotalVal').textContent = fmt(subtotal) + ' MT';
    document.getElementById('impostoVal').textContent  = fmt(imposto)  + ' MT';
    document.getElementById('totalVal').textContent    = fmt(subtotal + imposto) + ' MT';
    document.getElementById('btnFinalizar').disabled   = !cart.length;
}

// ── Desconto ───────────────────────────────────────────────────────────────
function aplicarDesconto() {
    const pct = prompt('Desconto em %:');
    if (pct === null) return;
    const d = parseFloat(pct);
    if (isNaN(d) || d < 0 || d > 100) { showToast('Valor inválido', 'error'); return; }
    cart.forEach(item => item.preco_unitario = item.preco_unitario * (1 - d/100));
    renderAll();
    showToast('Desconto de ' + d + '% aplicado');
}

// ── Finalizar venda ────────────────────────────────────────────────────────
async function finalizarVenda() {
    if (!cart.length) { showToast('Carrinho vazio', 'error'); return; }

    let subtotal = 0;
    cart.forEach(item => subtotal += item.quantidade * item.preco_unitario * (1 + item.imposto_percent/100));

    const itens = cart.map(item => ({
        product_id: item.product_id,
        product_variant_id: item.product_variant_id,
        quantidade: item.quantidade,
        preco_unitario: item.preco_unitario,
        desconto_percent: 0,
        imposto_percent: item.imposto_percent,
    }));

    const btn = document.getElementById('btnFinalizar');
    btn.disabled = true;
    btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> A processar…';

    try {
        const res = await fetch('/nexora/api/pos_venda_save', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                pos_session_id: SESSAO_ID,
                itens,
                pagamentos: [{ tipo: metodoAtual.toLowerCase().replace(' ','_').replace('ão','ao'), valor: subtotal, referencia: null }],
                csrf: CSRF
            })
        });
        const data = await res.json();
        if (data.ok) {
            showToast('✓ Venda ' + (data.numero || '') + ' registada — Troco: ' + fmt(data.troco ?? 0) + ' MT');
            cart = [];
            renderAll();
        } else {
            showToast(data.erro || data.error || 'Erro ao registar venda', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }

    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-circle-check"></i> Finalizar Venda';
}

renderAll();

<?php else: ?>
// ── Abrir sessão ──────────────────────────────────────────────────────────
async function abrirSessao() {
    const terminalId = document.getElementById('o-terminal').value;
    if (!terminalId) { alert('Seleccione um terminal.'); return; }
    try {
        const res = await fetch('/nexora/api/pos_sessao_abrir', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                terminal_id: +terminalId,
                opening_amount: +(document.getElementById('o-abertura').value || 0),
                csrf: CSRF
            })
        });
        const data = await res.json();
        if (data.ok) location.reload();
        else alert(data.erro || data.error || 'Erro ao abrir sessão');
    } catch { alert('Erro de ligação'); }
}
<?php endif; ?>
</script>
</body>
</html>
