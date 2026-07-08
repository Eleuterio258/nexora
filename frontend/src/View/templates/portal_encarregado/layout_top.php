<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= htmlspecialchars($pageTitle ?? 'Portal do Encarregado') ?> · Portal Escolar</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" crossorigin="anonymous">
    <style>
        :root {
            --enc-primary: #15803D;
            --enc-primary-dark: #14532D;
            --enc-bg: #F0FDF4;
            --enc-sidebar-w: 240px;
        }
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        html, body { height: 100%; font-family: 'Plus Jakarta Sans', sans-serif; background: var(--enc-bg); display: flex; min-height: 100vh; }

        .portal-sidebar {
            width: var(--enc-sidebar-w); background: #fff; border-right: 1px solid #DCFCE7;
            display: flex; flex-direction: column; position: fixed; top: 0; left: 0; height: 100vh; overflow-y: auto;
        }
        .portal-sidebar-header { padding: 1.25rem 1rem; border-bottom: 1px solid #DCFCE7; }
        .portal-brand { display: flex; align-items: center; gap: .6rem; text-decoration: none; margin-bottom: .75rem; }
        .portal-brand-icon { width: 34px; height: 34px; border-radius: 10px; background: #15803D; color: #fff; display: flex; align-items: center; justify-content: center; font-size: .95rem; }
        .portal-brand span { font-size: .95rem; font-weight: 700; color: #14532D; }
        .portal-enc-nome { font-size: .82rem; font-weight: 700; color: #334155; }
        .portal-enc-email { font-size: .73rem; color: #94A3B8; margin-top: .1rem; }

        .portal-nav { padding: .75rem 0; flex: 1; }
        .portal-nav-label { font-size: .68rem; font-weight: 700; color: #94A3B8; text-transform: uppercase; letter-spacing: .06em; padding: .75rem 1rem .3rem; }
        .portal-nav-item { display: flex; align-items: center; gap: .6rem; padding: .55rem 1rem; font-size: .85rem; font-weight: 500; color: #475569; text-decoration: none; border-radius: 8px; margin: .1rem .5rem; transition: all .12s; }
        .portal-nav-item:hover, .portal-nav-item.active { background: #DCFCE7; color: #14532D; font-weight: 600; }

        .portal-sidebar-footer { padding: .75rem .5rem; border-top: 1px solid #DCFCE7; margin-top: auto; }
        .portal-main { margin-left: var(--enc-sidebar-w); flex: 1; min-height: 100vh; }
        .portal-topbar { background: #fff; border-bottom: 1px solid #DCFCE7; padding: .85rem 1.5rem; display: flex; align-items: center; justify-content: space-between; position: sticky; top: 0; z-index: 40; }
        .portal-page-title { font-size: 1.1rem; font-weight: 700; color: #14532D; margin: 0; }
        .portal-content { padding: 1.5rem; flex: 1; }

        .portal-card { background: #fff; border-radius: 12px; border: 1px solid #DCFCE7; padding: 1.25rem; margin-bottom: 1rem; }
        .portal-card-title { font-size: .9rem; font-weight: 700; color: #14532D; margin: 0 0 1rem; padding-bottom: .6rem; border-bottom: 1px solid #F0FDF4; }

        .portal-stats { display: grid; grid-template-columns: repeat(auto-fill, minmax(160px,1fr)); gap: 1rem; margin-bottom: 1.5rem; }
        .portal-stat { background: #fff; border-radius: 12px; border: 1px solid #DCFCE7; padding: 1rem; display: flex; flex-direction: column; gap: .3rem; }
        .portal-stat-label { font-size: .72rem; font-weight: 600; color: #64748B; text-transform: uppercase; letter-spacing: .04em; }
        .portal-stat-value { font-size: 1.6rem; font-weight: 700; color: #14532D; }
        .portal-stat-sub   { font-size: .75rem; color: #94A3B8; }

        .portal-badge { display: inline-flex; align-items: center; gap: .3rem; font-size: .75rem; font-weight: 600; padding: .2rem .55rem; border-radius: 20px; }
        .badge-green  { background: #DCFCE7; color: #15803D; }
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

        /* Selector de educando */
        .educando-card { display: flex; align-items: center; gap: .6rem; padding: .5rem; border-radius: 8px; text-decoration: none; color: #334155; transition: background .12s; margin: .15rem 0; }
        .educando-card:hover, .educando-card.active { background: #DCFCE7; color: #14532D; }
        .educando-avatar { width: 30px; height: 30px; border-radius: 50%; background: #15803D; color: #fff; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: .8rem; flex-shrink: 0; }
        .educando-info { font-size: .8rem; }
        .educando-nome { font-weight: 600; }
        .educando-turma { font-size: .72rem; color: #94A3B8; }

        @media (max-width: 640px) { .portal-sidebar { display: none; } .portal-main { margin-left: 0; } }
    </style>
</head>
<body>

<?php
$encInfo    = $portalEncarregado ?? [];
$encNome    = htmlspecialchars($encInfo['nome'] ?? $encInfo['email'] ?? 'Encarregado');
$educandos  = $encInfo['educandos'] ?? [];
$activePage = $activePage ?? '';
// $selectedId and $selectedHash come from the index.php closure scope
?>

<aside class="portal-sidebar">
    <div class="portal-sidebar-header">
        <a href="/portal/encarregado" class="portal-brand">
            <div class="portal-brand-icon"><i class="fa-solid fa-users"></i></div>
            <span>Portal Escolar</span>
        </a>
        <div class="portal-enc-nome"><?= $encNome ?></div>
        <div class="portal-enc-email"><?= htmlspecialchars($encInfo['email'] ?? '') ?></div>
    </div>

    <?php if (!empty($educandos)): ?>
    <div style="padding:.75rem 1rem; border-bottom:1px solid #DCFCE7;">
        <p style="font-size:.68rem;font-weight:700;color:#94A3B8;text-transform:uppercase;letter-spacing:.06em;margin-bottom:.5rem">Educandos</p>
        <?php foreach ($educandos as $ed): ?>
        <a href="?educando_id=<?= htmlspecialchars($app->id->encode((int)$ed['student_id'])) ?>"
           class="educando-card <?= $selectedId === (int)$ed['student_id'] ? 'active' : '' ?>">
            <div class="educando-avatar"><?= mb_strtoupper(mb_substr($ed['aluno_nome'] ?? '?', 0, 1)) ?></div>
            <div class="educando-info">
                <div class="educando-nome"><?= htmlspecialchars($ed['aluno_nome'] ?? '') ?></div>
                <div class="educando-turma"><?= htmlspecialchars($ed['matricula_activa']['turma'] ?? $ed['aluno_codigo'] ?? '') ?></div>
            </div>
        </a>
        <?php endforeach; ?>
    </div>
    <?php endif; ?>

    <nav class="portal-nav">
        <p class="portal-nav-label">Educando seleccionado</p>
        <a href="/portal/encarregado?educando_id=<?= htmlspecialchars($selectedHash) ?>" class="portal-nav-item <?= $activePage === 'dashboard' ? 'active' : '' ?>">
            <i class="fa-solid fa-house fa-fw"></i> Resumo
        </a>
        <a href="/portal/encarregado/boletim?educando_id=<?= htmlspecialchars($selectedHash) ?>" class="portal-nav-item <?= $activePage === 'boletim' ? 'active' : '' ?>">
            <i class="fa-solid fa-chart-bar fa-fw"></i> Boletim
        </a>
        <a href="/portal/encarregado/presencas?educando_id=<?= htmlspecialchars($selectedHash) ?>" class="portal-nav-item <?= $activePage === 'presencas' ? 'active' : '' ?>">
            <i class="fa-solid fa-calendar-check fa-fw"></i> Presenças
        </a>
        <a href="/portal/encarregado/cobrancas?educando_id=<?= htmlspecialchars($selectedHash) ?>" class="portal-nav-item <?= $activePage === 'cobrancas' ? 'active' : '' ?>">
            <i class="fa-solid fa-file-invoice-dollar fa-fw"></i> Propinas
        </a>
        <a href="/portal/encarregado/ocorrencias?educando_id=<?= htmlspecialchars($selectedHash) ?>" class="portal-nav-item <?= $activePage === 'ocorrencias' ? 'active' : '' ?>">
            <i class="fa-solid fa-flag fa-fw"></i> Ocorrências
        </a>
    </nav>

    <div class="portal-sidebar-footer">
        <a href="/portal/encarregado/conta" class="portal-nav-item <?= $activePage === 'conta' ? 'active' : '' ?>">
            <i class="fa-solid fa-key fa-fw"></i> Alterar Senha
        </a>
        <a href="/portal/encarregado/logout" class="portal-nav-item" style="color:#DC2626">
            <i class="fa-solid fa-arrow-right-from-bracket fa-fw"></i> Sair
        </a>
    </div>
</aside>

<main class="portal-main">
    <div class="portal-topbar">
        <h1 class="portal-page-title"><?= htmlspecialchars($pageTitle ?? 'Portal do Encarregado') ?></h1>
        <?php if ($selectedId && !empty($educandos)): ?>
        <?php foreach ($educandos as $ed): if ((int)$ed['student_id'] === $selectedId): ?>
        <span style="font-size:.8rem;color:#64748B">
            <i class="fa-solid fa-user-graduate" style="color:var(--enc-primary)"></i>
            <?= htmlspecialchars($ed['aluno_nome'] ?? '') ?>
            · <?= htmlspecialchars($ed['matricula_activa']['turma'] ?? '') ?>
        </span>
        <?php endif; endforeach; ?>
        <?php endif; ?>
    </div>
    <div class="portal-content">
