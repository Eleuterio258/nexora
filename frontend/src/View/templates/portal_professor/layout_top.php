<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= htmlspecialchars($pageTitle ?? 'Portal do Professor') ?> · Nexora</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" crossorigin="anonymous">
    <style>
        :root {
            --prof-primary:      #10B981;
            --prof-primary-dark: #059669;
            --prof-bg:           #ECFDF5;
            --prof-border:       #D1FAE5;
            --prof-sidebar-w:    240px;
        }
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        html, body { height: 100%; font-family: 'Plus Jakarta Sans', sans-serif; background: var(--prof-bg); display: flex; min-height: 100vh; }

        .portal-sidebar {
            width: var(--prof-sidebar-w); background: #fff; border-right: 1px solid var(--prof-border);
            display: flex; flex-direction: column; position: fixed; top: 0; left: 0; height: 100vh; overflow-y: auto;
        }
        .portal-sidebar-header { padding: 1.25rem 1rem; border-bottom: 1px solid var(--prof-border); }
        .portal-brand { display: flex; align-items: center; gap: .6rem; text-decoration: none; margin-bottom: .75rem; }
        .portal-brand-icon { width: 34px; height: 34px; border-radius: 10px; background: var(--prof-primary); color: #fff; display: flex; align-items: center; justify-content: center; font-size: .95rem; }
        .portal-brand span { font-size: .95rem; font-weight: 700; color: var(--prof-primary-dark); }
        .portal-prof-nome  { font-size: .82rem; font-weight: 700; color: #334155; }
        .portal-prof-cargo { font-size: .73rem; color: #94A3B8; margin-top: .1rem; }

        .portal-nav { padding: .75rem 0; flex: 1; }
        .portal-nav-label { font-size: .68rem; font-weight: 700; color: #94A3B8; text-transform: uppercase; letter-spacing: .06em; padding: .75rem 1rem .3rem; }
        .portal-nav-item { display: flex; align-items: center; gap: .6rem; padding: .55rem 1rem; font-size: .85rem; font-weight: 500; color: #475569; text-decoration: none; border-radius: 8px; margin: .1rem .5rem; transition: all .12s; }
        .portal-nav-item:hover, .portal-nav-item.active { background: var(--prof-border); color: var(--prof-primary-dark); font-weight: 600; }

        .portal-sidebar-footer { padding: .75rem .5rem; border-top: 1px solid var(--prof-border); margin-top: auto; }
        .portal-main { margin-left: var(--prof-sidebar-w); flex: 1; min-height: 100vh; }
        .portal-topbar { background: #fff; border-bottom: 1px solid var(--prof-border); padding: .85rem 1.5rem; display: flex; align-items: center; justify-content: space-between; position: sticky; top: 0; z-index: 40; }
        .portal-page-title { font-size: 1.1rem; font-weight: 700; color: var(--prof-primary-dark); margin: 0; }
        .portal-content { padding: 1.5rem; }

        .portal-card { background: #fff; border-radius: 12px; border: 1px solid var(--prof-border); padding: 1.25rem; margin-bottom: 1rem; }
        .portal-card-title { font-size: .9rem; font-weight: 700; color: var(--prof-primary-dark); margin: 0 0 1rem; padding-bottom: .6rem; border-bottom: 1px solid var(--prof-bg); }

        .portal-stats { display: grid; grid-template-columns: repeat(auto-fill, minmax(160px,1fr)); gap: 1rem; margin-bottom: 1.5rem; }
        .portal-stat { background: #fff; border-radius: 12px; border: 1px solid var(--prof-border); padding: 1rem; display: flex; flex-direction: column; gap: .3rem; }
        .portal-stat-label { font-size: .72rem; font-weight: 600; color: #64748B; text-transform: uppercase; letter-spacing: .04em; }
        .portal-stat-value { font-size: 1.6rem; font-weight: 700; color: var(--prof-primary-dark); }
        .portal-stat-sub   { font-size: .75rem; color: #94A3B8; }

        .portal-badge { display: inline-flex; align-items: center; gap: .3rem; font-size: .75rem; font-weight: 600; padding: .2rem .55rem; border-radius: 20px; }
        .badge-green  { background: #D1FAE5; color: #059669; }
        .badge-red    { background: #FEE2E2; color: #B91C1C; }
        .badge-yellow { background: #FEF9C3; color: #854D0E; }
        .badge-blue   { background: #DBEAFE; color: #1D4ED8; }
        .badge-gray   { background: #F1F5F9; color: #475569; }

        .portal-table { width: 100%; border-collapse: collapse; font-size: .85rem; }
        .portal-table th { background: #F8FAFC; color: #64748B; font-weight: 600; font-size: .75rem; text-transform: uppercase; padding: .6rem .75rem; text-align: left; border-bottom: 1px solid #E2E8F0; }
        .portal-table td { padding: .65rem .75rem; border-bottom: 1px solid #F1F5F9; color: #334155; vertical-align: middle; }
        .portal-table tr:hover td { background: #F8FAFC; }
        .portal-table tr:last-child td { border-bottom: none; }
        .portal-empty { text-align: center; padding: 3rem 1rem; color: #94A3B8; }
        .portal-empty i { font-size: 2.5rem; display: block; margin-bottom: .75rem; }

        .btn-primary { display: inline-flex; align-items: center; gap: .4rem; padding: .5rem 1rem; background: var(--prof-primary); color: #fff; font-size: .85rem; font-weight: 600; border: none; border-radius: 8px; cursor: pointer; text-decoration: none; transition: background .12s; }
        .btn-primary:hover { background: var(--prof-primary-dark); }
        .btn-secondary { display: inline-flex; align-items: center; gap: .4rem; padding: .5rem 1rem; background: #F1F5F9; color: #475569; font-size: .85rem; font-weight: 600; border: none; border-radius: 8px; cursor: pointer; text-decoration: none; transition: background .12s; }
        .btn-secondary:hover { background: #E2E8F0; }

        @media (max-width: 640px) { .portal-sidebar { display: none; } .portal-main { margin-left: 0; } }
    </style>
</head>
<body>

<?php
$profInfo   = $profInfo ?? [];
$profNome   = htmlspecialchars($profInfo['nome'] ?? $profInfo['email'] ?? 'Professor');
$profCargo  = htmlspecialchars($profInfo['cargo'] ?? $profInfo['disciplinas'][0] ?? '');
$activePage = $activePage ?? '';
?>

<aside class="portal-sidebar">
    <div class="portal-sidebar-header">
        <a href="/portal/professor" class="portal-brand">
            <div class="portal-brand-icon"><i class="fa-solid fa-chalkboard-user"></i></div>
            <span>Portal Professor</span>
        </a>
        <div class="portal-prof-nome"><?= $profNome ?></div>
        <?php if ($profCargo !== ''): ?>
        <div class="portal-prof-cargo"><?= $profCargo ?></div>
        <?php endif; ?>
    </div>

    <nav class="portal-nav">
        <p class="portal-nav-label">Navegação</p>
        <a href="/portal/professor" class="portal-nav-item <?= $activePage === 'dashboard' ? 'active' : '' ?>">
            <i class="fa-solid fa-house fa-fw"></i> Início
        </a>
        <a href="/portal/professor/turmas" class="portal-nav-item <?= $activePage === 'turmas' ? 'active' : '' ?>">
            <i class="fa-solid fa-users-rectangle fa-fw"></i> As Minhas Turmas
        </a>
        <a href="/portal/professor/horario" class="portal-nav-item <?= $activePage === 'horario' ? 'active' : '' ?>">
            <i class="fa-solid fa-calendar-days fa-fw"></i> Horário
        </a>
        <a href="/portal/professor/presencas" class="portal-nav-item <?= $activePage === 'presencas' ? 'active' : '' ?>">
            <i class="fa-solid fa-calendar-check fa-fw"></i> Presenças
        </a>
        <a href="/portal/professor/notas" class="portal-nav-item <?= $activePage === 'notas' ? 'active' : '' ?>">
            <i class="fa-solid fa-star-half-stroke fa-fw"></i> Notas
        </a>
        <a href="/portal/professor/comunicacao" class="portal-nav-item <?= $activePage === 'comunicacao' ? 'active' : '' ?>">
            <i class="fa-solid fa-envelope fa-fw"></i> Comunicação
        </a>
    </nav>

    <div class="portal-sidebar-footer">
        <a href="/portal/professor/conta" class="portal-nav-item <?= $activePage === 'conta' ? 'active' : '' ?>">
            <i class="fa-solid fa-key fa-fw"></i> Alterar Senha
        </a>
        <a href="/portal/professor/logout" class="portal-nav-item" style="color:#DC2626">
            <i class="fa-solid fa-arrow-right-from-bracket fa-fw"></i> Sair
        </a>
    </div>
</aside>

<main class="portal-main">
    <div class="portal-topbar">
        <h1 class="portal-page-title"><?= htmlspecialchars($pageTitle ?? 'Portal do Professor') ?></h1>
        <span style="font-size:.8rem;color:#64748B">
            <i class="fa-solid fa-chalkboard-user" style="color:var(--prof-primary)"></i>
            <?= $profNome ?>
        </span>
    </div>
    <div class="portal-content">
