<?php
// ── Layout partilhado do módulo POS ─────────────────────────────────────────
// Requer: $pageTitle, $activePage (pos, pos_dashboard, pos_vendas, etc.)
// Não usa top.php — layout independente com sidebar própria do POS.

$posOperador = $app->session->user()['nome'] ?? 'Operador';
$posNavPages = [
    'pos'            => ['label' => 'Ponto de Venda', 'icon' => 'fa-cash-register',   'href' => '/nexora/pos'],
    'pos_dashboard'  => ['label' => 'Dashboard',      'icon' => 'fa-gauge',            'href' => '/nexora/pos/dashboard'],
    'pos_vendas'     => ['label' => 'Vendas',          'icon' => 'fa-bag-shopping',     'href' => '/nexora/pos/vendas'],
    'pos_relatorios' => ['label' => 'Relatórios',      'icon' => 'fa-chart-bar',        'href' => '/nexora/pos/relatorios'],
    'pos_catalogo'   => ['label' => 'Catálogo',        'icon' => 'fa-list',             'href' => '/nexora/pos/catalogo'],
    'pos_terminais'  => ['label' => 'Caixas',          'icon' => 'fa-desktop',          'href' => '/nexora/pos/terminais'],
    'clientes'       => ['label' => 'Clientes',        'icon' => 'fa-users',            'href' => '/nexora/clientes'],
    'pos_devolucoes' => ['label' => 'Devoluções',      'icon' => 'fa-rotate-left',      'href' => '/nexora/pos/devolucoes'],
];
$ap = $activePage ?? '';
?>
<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= htmlspecialchars($pageTitle ?? 'POS') ?> · E258Tech</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700;800&family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="/assets/css/nexora.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.7.2/css/all.min.css" crossorigin="anonymous" referrerpolicy="no-referrer">
<style>
*,*::before,*::after{margin:0;padding:0;box-sizing:border-box}
html,body{height:100%;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;background:#f1f5f9;overflow:hidden}
.pos-wrap{display:flex;height:100vh}
/* Sidebar */
.pos-sidebar{width:210px;background:#0d2118;display:flex;flex-direction:column;flex-shrink:0}
.pos-logo{padding:18px 16px 14px;display:flex;align-items:center;gap:10px;border-bottom:1px solid rgba(255,255,255,.08)}
.pos-logo img{height:22px;filter:brightness(0) invert(1);opacity:.9}
.pos-logo-txt{font-family:'Outfit',sans-serif;font-weight:700;font-size:13px;color:#fff;opacity:.9}
.pos-nav{flex:1;padding:10px 8px;overflow-y:auto}
.pos-nav-item{display:flex;align-items:center;gap:10px;padding:8px 12px;border-radius:8px;color:rgba(255,255,255,.58);font-size:13px;font-weight:500;cursor:pointer;text-decoration:none;transition:background .12s,color .12s;margin-bottom:2px}
.pos-nav-item:hover{background:rgba(255,255,255,.08);color:#fff}
.pos-nav-item.active{background:rgba(16,185,129,.18);color:#34d399}
.pos-nav-item i{width:15px;text-align:center;font-size:12px}
.pos-sidebar-footer{border-top:1px solid rgba(255,255,255,.07);padding:11px 14px}
.pos-op-wrap{display:flex;align-items:center;gap:8px}
.pos-op-av{width:28px;height:28px;border-radius:50%;background:#10b981;display:flex;align-items:center;justify-content:center;color:#fff;font-weight:700;font-size:11px;flex-shrink:0}
.pos-op-info{flex:1;min-width:0}
.pos-op-name{font-size:12px;font-weight:600;color:#fff;opacity:.85;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.pos-op-time{font-size:10px;color:rgba(255,255,255,.35)}
.pos-logout{color:rgba(255,255,255,.35);background:none;border:none;cursor:pointer;padding:3px;border-radius:4px;font-size:13px}
.pos-logout:hover{color:#ef4444;background:rgba(239,68,68,.1)}
/* Body */
.pos-body{flex:1;display:flex;flex-direction:column;min-width:0;overflow:hidden}
.pos-module-header{background:#fff;border-bottom:1px solid #e5e7eb;padding:0 20px;height:52px;display:flex;align-items:center;justify-content:space-between;flex-shrink:0}
.pos-module-title{font-family:'Outfit',sans-serif;font-size:17px;font-weight:700;color:#111827}
.pos-module-breadcrumb{font-size:12px;color:#9ca3af}
.pos-module-breadcrumb a{color:#9ca3af;text-decoration:none}
.pos-module-breadcrumb a:hover{color:#10b981}
.pos-module-actions{display:flex;align-items:center;gap:8px}
.pos-module-content{flex:1;overflow-y:auto;padding:20px}
/* Scrollbars */
::-webkit-scrollbar{width:4px}::-webkit-scrollbar-track{background:transparent}::-webkit-scrollbar-thumb{background:#d1d5db;border-radius:2px}
</style>
</head>
<body>
<div class="pos-wrap">

<!-- ── POS Sidebar ──────────────────────────────────────────────────── -->
<nav class="pos-sidebar">
    <div class="pos-logo">
        <img src="/assets/images/e258tech-logo.png" alt="E258Tech">
        <span class="pos-logo-txt">Nexora</span>
    </div>
    <div class="pos-nav">
        <?php foreach ($posNavPages as $key => $nav): ?>
        <a href="<?= htmlspecialchars($nav['href']) ?>"
           class="pos-nav-item <?= ($ap === $key || ($key === 'pos_vendas' && in_array($ap, ['pos_venda_ver'], true))) ? 'active' : '' ?>">
            <i class="fa-solid <?= $nav['icon'] ?> fa-fw"></i>
            <?= htmlspecialchars($nav['label']) ?>
        </a>
        <?php endforeach; ?>
    </div>
    <div class="pos-sidebar-footer">
        <div class="pos-op-wrap">
            <div class="pos-op-av"><?= strtoupper(substr($posOperador, 0, 1)) ?></div>
            <div class="pos-op-info">
                <div class="pos-op-name"><?= htmlspecialchars(explode(' ', $posOperador)[0]) ?></div>
                <div class="pos-op-time" id="posClk"><?= date('d/m/Y H:i') ?></div>
            </div>
            <a href="/nexora/logout" class="pos-logout" title="Sair">
                <i class="fa-solid fa-right-from-bracket"></i>
            </a>
        </div>
    </div>
</nav>

<!-- ── POS Body ─────────────────────────────────────────────────────── -->
<div class="pos-body">
    <div class="pos-module-header">
        <div>
            <div class="pos-module-title"><?= htmlspecialchars($pageTitle ?? '') ?></div>
            <div class="pos-module-breadcrumb">
                <a href="/nexora/pos">POS</a> / <?= htmlspecialchars($pageTitle ?? '') ?>
            </div>
        </div>
        <div class="pos-module-actions">
