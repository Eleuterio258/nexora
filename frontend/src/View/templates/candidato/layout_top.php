<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= htmlspecialchars($pageTitle ?? 'Área do Candidato') ?> · E258Tech</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" crossorigin="anonymous">
    <style>
        :root {
            --portal-primary: #059669;
            --portal-primary-dark: #047857;
            --portal-bg: #F0FDF4;
            --portal-sidebar-w: 240px;
        }
        * { box-sizing: border-box; }
        html, body { height: 100%; margin: 0; }
        body {
            font-family: 'Plus Jakarta Sans', sans-serif;
            background: var(--portal-bg);
            display: flex;
            min-height: 100vh;
        }

        /* ── Sidebar ── */
        .portal-sidebar {
            width: var(--portal-sidebar-w);
            background: #fff;
            border-right: 1px solid #D1FAE5;
            display: flex;
            flex-direction: column;
            position: fixed;
            top: 0; left: 0; bottom: 0;
            z-index: 50;
            padding: 0;
        }
        .portal-sidebar-header {
            padding: 1.25rem 1rem 1rem;
            border-bottom: 1px solid #D1FAE5;
        }
        .portal-brand {
            display: flex; align-items: center; gap: .5rem;
            font-weight: 700; font-size: 1rem; color: var(--portal-primary-dark);
            text-decoration: none;
        }
        .portal-brand-icon {
            width: 32px; height: 32px; border-radius: 8px;
            background: var(--portal-primary);
            display: flex; align-items: center; justify-content: center;
            color: #fff; font-size: .9rem;
        }
        .portal-candidato-info {
            margin-top: .75rem;
            padding: .6rem .75rem;
            background: #F0FDF4;
            border-radius: 8px;
        }
        .portal-candidato-nome {
            font-weight: 600; font-size: .85rem; color: #064E3B;
            white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
        }
        .portal-candidato-email {
            font-size: .73rem; color: #34D399; margin-top: .1rem;
            white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
        }
        .portal-nav { flex: 1; padding: .75rem .5rem; overflow-y: auto; }
        .portal-nav-item {
            display: flex; align-items: center; justify-content: space-between; gap: .6rem;
            padding: .55rem .75rem; border-radius: 8px;
            color: #334155; text-decoration: none; font-size: .875rem; font-weight: 500;
            transition: background .15s, color .15s;
            margin-bottom: .1rem;
        }
        .portal-nav-item:hover { background: #F0FDF4; color: var(--portal-primary-dark); }
        .portal-nav-item.active {
            background: #D1FAE5; color: var(--portal-primary-dark); font-weight: 600;
        }
        .portal-nav-item-label { display: flex; align-items: center; gap: .6rem; }
        .portal-nav-item i { width: 18px; text-align: center; font-size: .85rem; }
        .portal-nav-badge {
            background: #DC2626; color: #fff; font-size: .68rem; font-weight: 700;
            padding: .05rem .4rem; border-radius: 999px; min-width: 1.1rem; text-align: center;
        }
        .portal-sidebar-footer {
            padding: .75rem .5rem;
            border-top: 1px solid #D1FAE5;
        }

        /* ── Main ── */
        .portal-main {
            margin-left: var(--portal-sidebar-w);
            flex: 1;
            display: flex;
            flex-direction: column;
            min-height: 100vh;
        }
        .portal-topbar {
            background: #fff;
            border-bottom: 1px solid #D1FAE5;
            padding: .875rem 1.5rem;
            display: flex; align-items: center; justify-content: space-between;
            position: sticky; top: 0; z-index: 40;
        }
        .portal-page-title {
            font-size: 1.1rem; font-weight: 700; color: #064E3B; margin: 0;
        }
        .portal-content {
            padding: 1.5rem;
            flex: 1;
        }

        /* ── Cards ── */
        .portal-card {
            background: #fff; border-radius: 12px;
            border: 1px solid #D1FAE5; padding: 1.25rem;
            margin-bottom: 1rem;
        }
        .portal-card-title {
            font-size: .9rem; font-weight: 700; color: #064E3B;
            margin: 0 0 1rem; padding-bottom: .6rem;
            border-bottom: 1px solid #F0FDF4;
        }

        /* ── Stats ── */
        .portal-stats { display: grid; grid-template-columns: repeat(auto-fill, minmax(160px,1fr)); gap: 1rem; margin-bottom: 1.5rem; }
        .portal-stat {
            background: #fff; border-radius: 12px; border: 1px solid #D1FAE5;
            padding: 1rem; display: flex; flex-direction: column; gap: .3rem;
        }
        .portal-stat-label { font-size: .72rem; font-weight: 600; color: #64748B; text-transform: uppercase; letter-spacing: .04em; }
        .portal-stat-value { font-size: 1.6rem; font-weight: 700; color: #064E3B; }
        .portal-stat-sub   { font-size: .75rem; color: #94A3B8; }

        /* ── Badge ── */
        .portal-badge {
            display: inline-flex; align-items: center; gap: .3rem;
            font-size: .75rem; font-weight: 600; padding: .2rem .55rem; border-radius: 20px;
        }
        .badge-green  { background: #DCFCE7; color: #15803D; }
        .badge-red    { background: #FEE2E2; color: #B91C1C; }
        .badge-yellow { background: #FEF9C3; color: #854D0E; }
        .badge-blue   { background: #DBEAFE; color: #1D4ED8; }
        .badge-purple { background: #EDE9FE; color: #6D28D9; }
        .badge-gray   { background: #F1F5F9; color: #475569; }

        /* ── Table ── */
        .portal-table { width: 100%; border-collapse: collapse; font-size: .85rem; }
        .portal-table th { background: #F8FAFC; color: #64748B; font-weight: 600; font-size: .75rem; text-transform: uppercase; letter-spacing: .04em; padding: .6rem .75rem; text-align: left; border-bottom: 1px solid #E2E8F0; }
        .portal-table td { padding: .65rem .75rem; border-bottom: 1px solid #F1F5F9; color: #334155; vertical-align: middle; }
        .portal-table tr:hover td { background: #F8FAFC; }
        .portal-table tr:last-child td { border-bottom: none; }

        /* ── Empty state ── */
        .portal-empty { text-align: center; padding: 3rem 1rem; color: #94A3B8; }
        .portal-empty i { font-size: 2.5rem; display: block; margin-bottom: .75rem; }

        /* ── Forms ── */
        .portal-form-group { margin-bottom: 1rem; }
        .portal-form-group label { display: block; font-size: .8rem; font-weight: 600; color: #334155; margin-bottom: .35rem; }
        .portal-form-group input {
            width: 100%; padding: .6rem .75rem; border: 1px solid #D1D5DB; border-radius: 8px;
            font-size: .875rem; font-family: inherit;
        }
        .portal-form-group input:focus { outline: none; border-color: var(--portal-primary); box-shadow: 0 0 0 3px rgba(5,150,105,.12); }
        .portal-btn {
            background: var(--portal-primary); color: #fff; border: none; border-radius: 8px;
            padding: .6rem 1.1rem; font-size: .85rem; font-weight: 600; cursor: pointer;
            transition: background .15s;
        }
        .portal-btn:hover { background: var(--portal-primary-dark); }
        .portal-btn:disabled { opacity: .6; cursor: not-allowed; }
        .portal-btn-outline {
            background: #fff; color: var(--portal-primary-dark); border: 1px solid #A7F3D0; border-radius: 8px;
            padding: .6rem 1.1rem; font-size: .85rem; font-weight: 600; cursor: pointer; text-decoration: none;
            display: inline-block;
        }
        .portal-btn-outline:hover { background: #F0FDF4; }

        @media (max-width: 640px) {
            .portal-sidebar { display: none; }
            .portal-main { margin-left: 0; }
        }
    </style>
</head>
<body>

<?php
$candidatoInfo  = $candidato ?? [];
$candidatoNome  = htmlspecialchars($candidatoInfo['nome'] ?? 'Candidato');
$candidatoEmail = htmlspecialchars($candidatoInfo['email'] ?? '');
$activePage     = $activePage ?? '';
$naoLidasTotal  = array_sum(array_column($conversas ?? [], 'nao_lidas'));
?>

<aside class="portal-sidebar">
    <div class="portal-sidebar-header">
        <a href="/carreira/candidato/area" class="portal-brand">
            <div class="portal-brand-icon"><i class="fa-solid fa-briefcase"></i></div>
            Área do Candidato
        </a>
        <div class="portal-candidato-info">
            <div class="portal-candidato-nome"><?= $candidatoNome ?></div>
            <?php if ($candidatoEmail): ?>
            <div class="portal-candidato-email"><?= $candidatoEmail ?></div>
            <?php endif; ?>
        </div>
    </div>

    <nav class="portal-nav">
        <a href="/carreira/candidato/area" class="portal-nav-item <?= $activePage === 'painel_dashboard' ? 'active' : '' ?>">
            <span class="portal-nav-item-label"><i class="fa-solid fa-house fa-fw"></i> Início</span>
        </a>
        <a href="/carreira/candidato/candidaturas" class="portal-nav-item <?= $activePage === 'painel_candidaturas' ? 'active' : '' ?>">
            <span class="portal-nav-item-label"><i class="fa-solid fa-file-lines fa-fw"></i> Minhas Candidaturas</span>
        </a>
        <a href="/carreira/candidato/mensagens" class="portal-nav-item <?= $activePage === 'painel_mensagens' ? 'active' : '' ?>">
            <span class="portal-nav-item-label"><i class="fa-solid fa-comments fa-fw"></i> Mensagens</span>
            <?php if ($naoLidasTotal > 0): ?>
            <span class="portal-nav-badge"><?= $naoLidasTotal ?></span>
            <?php endif; ?>
        </a>
        <a href="/carreira/candidato/perfil" class="portal-nav-item <?= $activePage === 'painel_perfil' ? 'active' : '' ?>">
            <span class="portal-nav-item-label"><i class="fa-solid fa-id-card fa-fw"></i> Meu Perfil</span>
        </a>
    </nav>

    <div class="portal-sidebar-footer">
        <a href="/vagas" class="portal-nav-item">
            <span class="portal-nav-item-label"><i class="fa-solid fa-arrow-left fa-fw"></i> Ver vagas</span>
        </a>
        <a href="/carreira/candidato/logout" class="portal-nav-item" style="color:#DC2626">
            <span class="portal-nav-item-label"><i class="fa-solid fa-arrow-right-from-bracket fa-fw"></i> Sair</span>
        </a>
    </div>
</aside>

<main class="portal-main">
    <div class="portal-topbar">
        <h1 class="portal-page-title"><?= htmlspecialchars($pageTitle ?? 'Área do Candidato') ?></h1>
    </div>
    <div class="portal-content">
