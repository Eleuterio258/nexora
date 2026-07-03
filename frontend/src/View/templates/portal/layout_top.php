<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= htmlspecialchars($pageTitle ?? 'Portal do Aluno') ?> · Portal Escolar</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="/assets/css/nexora.css">
    <style>
        :root {
            --portal-primary: #0EA5E9;
            --portal-primary-dark: #0284C7;
            --portal-bg: #F0F9FF;
            --portal-sidebar-w: 240px;
        }
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
            border-right: 1px solid #E0F2FE;
            display: flex;
            flex-direction: column;
            position: fixed;
            top: 0; left: 0; bottom: 0;
            z-index: 50;
            padding: 0;
        }
        .portal-sidebar-header {
            padding: 1.25rem 1rem 1rem;
            border-bottom: 1px solid #E0F2FE;
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
        .portal-aluno-info {
            margin-top: .75rem;
            padding: .6rem .75rem;
            background: #F0F9FF;
            border-radius: 8px;
        }
        .portal-aluno-nome {
            font-weight: 600; font-size: .85rem; color: #0C4A6E;
            white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
        }
        .portal-aluno-cod {
            font-size: .73rem; color: #38BDF8; margin-top: .1rem;
        }
        .portal-nav { flex: 1; padding: .75rem .5rem; overflow-y: auto; }
        .portal-nav-item {
            display: flex; align-items: center; gap: .6rem;
            padding: .55rem .75rem; border-radius: 8px;
            color: #334155; text-decoration: none; font-size: .875rem; font-weight: 500;
            transition: background .15s, color .15s;
            margin-bottom: .1rem;
        }
        .portal-nav-item:hover { background: #F0F9FF; color: var(--portal-primary-dark); }
        .portal-nav-item.active {
            background: #E0F2FE; color: var(--portal-primary-dark); font-weight: 600;
        }
        .portal-nav-item i { width: 18px; text-align: center; font-size: .85rem; }
        .portal-nav-label {
            font-size: .7rem; font-weight: 700; text-transform: uppercase;
            letter-spacing: .06em; color: #94A3B8; padding: .5rem .75rem .2rem;
        }
        .portal-sidebar-footer {
            padding: .75rem .5rem;
            border-top: 1px solid #E0F2FE;
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
            border-bottom: 1px solid #E0F2FE;
            padding: .875rem 1.5rem;
            display: flex; align-items: center; justify-content: space-between;
            position: sticky; top: 0; z-index: 40;
        }
        .portal-page-title {
            font-size: 1.1rem; font-weight: 700; color: #0C4A6E; margin: 0;
        }
        .portal-content {
            padding: 1.5rem;
            flex: 1;
        }

        /* ── Cards ── */
        .portal-card {
            background: #fff; border-radius: 12px;
            border: 1px solid #E0F2FE; padding: 1.25rem;
            margin-bottom: 1rem;
        }
        .portal-card-title {
            font-size: .9rem; font-weight: 700; color: #0C4A6E;
            margin: 0 0 1rem; padding-bottom: .6rem;
            border-bottom: 1px solid #F0F9FF;
        }

        /* ── Stats ── */
        .portal-stats { display: grid; grid-template-columns: repeat(auto-fill, minmax(160px,1fr)); gap: 1rem; margin-bottom: 1.5rem; }
        .portal-stat {
            background: #fff; border-radius: 12px; border: 1px solid #E0F2FE;
            padding: 1rem; display: flex; flex-direction: column; gap: .3rem;
        }
        .portal-stat-label { font-size: .72rem; font-weight: 600; color: #64748B; text-transform: uppercase; letter-spacing: .04em; }
        .portal-stat-value { font-size: 1.6rem; font-weight: 700; color: #0C4A6E; }
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

        @media (max-width: 640px) {
            .portal-sidebar { display: none; }
            .portal-main { margin-left: 0; }
        }
    </style>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" crossorigin="anonymous">
</head>
<body>

<?php
$portalAluno  = $alunoInfo ?? [];
$alunoNome    = htmlspecialchars($portalAluno['nome'] ?? 'Aluno');
$alunoCodigo  = htmlspecialchars($portalAluno['codigo'] ?? '');
$activePage   = $activePage ?? '';
?>

<aside class="portal-sidebar">
    <div class="portal-sidebar-header">
        <a href="/portal/aluno" class="portal-brand">
            <div class="portal-brand-icon"><i class="fa-solid fa-graduation-cap"></i></div>
            Portal Escolar
        </a>
        <div class="portal-aluno-info">
            <div class="portal-aluno-nome"><?= $alunoNome ?></div>
            <?php if ($alunoCodigo): ?>
            <div class="portal-aluno-cod"><?= $alunoCodigo ?></div>
            <?php endif; ?>
        </div>
    </div>

    <nav class="portal-nav">
        <p class="portal-nav-label">Principal</p>
        <a href="/portal/aluno" class="portal-nav-item <?= $activePage === 'dashboard' ? 'active' : '' ?>">
            <i class="fa-solid fa-house fa-fw"></i> Início
        </a>
        <a href="/portal/aluno/perfil" class="portal-nav-item <?= $activePage === 'perfil' ? 'active' : '' ?>">
            <i class="fa-solid fa-id-card fa-fw"></i> Meu Perfil
        </a>

        <p class="portal-nav-label">Académico</p>
        <a href="/portal/aluno/boletim" class="portal-nav-item <?= $activePage === 'boletim' ? 'active' : '' ?>">
            <i class="fa-solid fa-chart-bar fa-fw"></i> Boletim & Notas
        </a>
        <a href="/portal/aluno/presencas" class="portal-nav-item <?= $activePage === 'presencas' ? 'active' : '' ?>">
            <i class="fa-solid fa-calendar-check fa-fw"></i> Presenças
        </a>
        <a href="/portal/aluno/horario" class="portal-nav-item <?= $activePage === 'horario' ? 'active' : '' ?>">
            <i class="fa-solid fa-clock fa-fw"></i> Horário
        </a>
        <a href="/portal/aluno/ocorrencias" class="portal-nav-item <?= $activePage === 'ocorrencias' ? 'active' : '' ?>">
            <i class="fa-solid fa-flag fa-fw"></i> Ocorrências
        </a>
        <a href="/portal/aluno/biblioteca" class="portal-nav-item <?= $activePage === 'biblioteca' ? 'active' : '' ?>">
            <i class="fa-solid fa-book fa-fw"></i> Biblioteca
        </a>

        <p class="portal-nav-label">Financeiro</p>
        <a href="/portal/aluno/cobrancas" class="portal-nav-item <?= $activePage === 'cobrancas' ? 'active' : '' ?>">
            <i class="fa-solid fa-file-invoice-dollar fa-fw"></i> Propinas
        </a>

        <p class="portal-nav-label">Comunicação</p>
        <a href="/portal/aluno/mensagens" class="portal-nav-item <?= $activePage === 'mensagens' ? 'active' : '' ?>">
            <i class="fa-solid fa-bell fa-fw"></i> Avisos
        </a>
        <a href="/portal/aluno/eventos" class="portal-nav-item <?= $activePage === 'eventos' ? 'active' : '' ?>">
            <i class="fa-solid fa-calendar-days fa-fw"></i> Eventos
        </a>
    </nav>

    <div class="portal-sidebar-footer">
        <a href="/portal/aluno/conta" class="portal-nav-item <?= $activePage === 'conta' ? 'active' : '' ?>">
            <i class="fa-solid fa-key fa-fw"></i> Alterar Senha
        </a>
        <a href="/portal/aluno/logout" class="portal-nav-item" style="color:#DC2626">
            <i class="fa-solid fa-arrow-right-from-bracket fa-fw"></i> Sair
        </a>
    </div>
</aside>

<main class="portal-main">
    <div class="portal-topbar">
        <h1 class="portal-page-title"><?= htmlspecialchars($pageTitle ?? 'Portal do Aluno') ?></h1>
        <?php if (!empty($portalAluno['matricula_activa'])): ?>
        <span style="font-size:.8rem;color:#64748B">
            <i class="fa-solid fa-school" style="color:var(--portal-primary)"></i>
            <?= htmlspecialchars($portalAluno['matricula_activa']['turma'] ?? '') ?>
            <?php if (!empty($portalAluno['matricula_activa']['ano_lectivo'])): ?>
            · <?= htmlspecialchars($portalAluno['matricula_activa']['ano_lectivo']) ?>
            <?php endif; ?>
        </span>
        <?php endif; ?>
    </div>
    <div class="portal-content">
<?php if (empty($portalAluno['portal_email_verificado'])): ?>
<div style="background:#FEF3C7;border:1px solid #FDE68A;border-radius:8px;padding:.6rem 1rem;
            margin-bottom:1rem;display:flex;align-items:center;gap:.6rem;font-size:.82rem;color:#92400E">
    <i class="fa-solid fa-envelope-circle-check"></i>
    <span>O seu email ainda não foi verificado. Para maior segurança, contacte a secretaria para enviar um link de convite.</span>
</div>
<?php endif; ?>
