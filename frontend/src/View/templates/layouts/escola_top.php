<?php
// Layout dedicado do Painel Escolar — sidebar exclusiva, sem módulos ERP gerais.
// Activado via $GLOBALS['_escolarPanel'] = true antes do dispatch.

$loggedUser = $app->session->user();
$adminUser  = $loggedUser['nome'] ?? $loggedUser['email'] ?? 'Admin';
$userRole   = $loggedUser['cargo'] ?? 'Secretaria';
$initials   = mb_strtoupper(mb_substr($adminUser, 0, 1));
$ap         = $activePage ?? '';

// Grupos de páginas para activar a secção
$apAcademico  = in_array($ap, ['escolar_anos_lectivos','escolar_periodos','escolar_turmas','escolar_disciplinas','escolar_professores','escolar_atribuicoes','escolar_horarios','escolar_calendario','escolar_niveis','escolar_series','escolar_cursos'], true);
$apAlunos     = in_array($ap, ['escolar_alunos','escolar_matriculas','escolar_cargos_alunos','escolar_cargos_professores','escolar_ocorrencias'], true);
$apAvaliacao  = in_array($ap, ['escolar_frequencia','escolar_avaliacoes','escolar_notas','escolar_boletins'], true);
$apFinanceiro = in_array($ap, ['escolar_planos_cobranca','escolar_cobrancas','escolar_pagamentos','escolar_inadimplencia','escolar_config_financeira'], true);
$apBiblioteca = in_array($ap, ['escolar_biblioteca','escolar_emprestimos'], true);
$apComuncacao = in_array($ap, ['escolar_comunicacao','escolar_resumo_academico','escolar_resumo_financeiro'], true);
$apPortal     = in_array($ap, ['aluno_portal'], true);
?>
<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= htmlspecialchars($pageTitle ?? 'Escola') ?> · Nexora Escola</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700;800&family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="/assets/css/nexora.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.7.2/css/all.min.css" crossorigin="anonymous">
    <style>
        /* ── Sidebar da Escola (tema teal) ────────────────────────────────────── */
        .adm-sidebar {
            --adm-sidebar-bg:     #0F172A;
            --adm-sidebar-accent: #0D9488;
            background: var(--adm-sidebar-bg) !important;
        }
        .adm-sidebar-logo { border-bottom-color: rgba(255,255,255,.08) !important; }
        .adm-sidebar-logo span { color: #5EEAD4 !important; }
        .adm-nav-group-title,
        .adm-nav-item { color: #94A3B8 !important; }
        .adm-nav-item:hover,
        .adm-nav-item.active { background: rgba(13,148,136,.18) !important; color: #5EEAD4 !important; }
        .adm-nav-label { color: #475569 !important; }
        .escola-brand-icon {
            width: 28px; height: 28px; border-radius: 8px;
            background: #0D9488; display: inline-flex; align-items: center;
            justify-content: center; color: #fff; font-size: .8rem; flex-shrink: 0;
        }
        .escola-user-block {
            padding: var(--adm-sp-3) var(--adm-sp-4);
            border-top: 1px solid rgba(255,255,255,.08);
            margin-top: auto;
        }
        .escola-user-avatar {
            width: 30px; height: 30px; border-radius: 50%;
            background: #0D9488; color: #fff; font-weight: 700;
            display: flex; align-items: center; justify-content: center;
            font-size: .8rem; flex-shrink: 0;
        }
        /* Botão de voltar ao ERP */
        .escola-back-btn {
            display: flex; align-items: center; gap: .5rem;
            padding: .45rem var(--adm-sp-4); font-size: .78rem;
            color: #64748B !important; text-decoration: none;
            border-top: 1px solid rgba(255,255,255,.05);
            transition: color .12s;
        }
        .escola-back-btn:hover { color: #94A3B8 !important; }
        /* Override header accent */
        .adm-header { border-bottom-color: rgba(13,148,136,.2) !important; }
    </style>
</head>
<body>
<div class="adm-wrapper">

    <!-- ── Sidebar Escola ── -->
    <aside class="adm-sidebar" id="admSidebar">

        <!-- Logo/Brand -->
        <div class="adm-sidebar-logo" style="padding:var(--adm-sp-4)">
            <div style="display:flex;align-items:center;gap:.6rem">
                <div class="escola-brand-icon"><i class="fa-solid fa-graduation-cap"></i></div>
                <div>
                    <div style="font-weight:700;font-size:.9rem;color:#E2E8F0;line-height:1.1">Nexora Escola</div>
                    <div style="font-size:.68rem;color:#475569;line-height:1">Painel de Gestão</div>
                </div>
            </div>
        </div>

        <nav class="adm-nav" style="flex:1;overflow-y:auto">

            <!-- Dashboard -->
            <a href="/escola" class="adm-nav-item <?= $ap === 'escolar_dashboard' ? 'active' : '' ?>">
                <i class="fa-solid fa-house-chimney fa-fw"></i> Dashboard
            </a>

            <!-- ACADÉMICO -->
            <p class="adm-nav-label">Académico</p>
            <details class="adm-nav-group" <?= $apAcademico ? 'open' : '' ?>>
                <summary class="adm-nav-group-title">
                    <i class="fa-solid fa-book-open fa-fw"></i> Académico
                    <svg class="adm-nav-chevron" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 6 15 12 9 18"/></svg>
                </summary>
                <div class="adm-nav-submenu">
                    <a href="/escola/anos-lectivos"  class="adm-nav-item <?= $ap === 'escolar_anos_lectivos' ? 'active' : '' ?>"><i class="fa-solid fa-calendar-days fa-fw"></i> Anos Lectivos</a>
                    <a href="/escola/periodos"       class="adm-nav-item <?= $ap === 'escolar_periodos' ? 'active' : '' ?>"><i class="fa-solid fa-calendar-week fa-fw"></i> Períodos / Módulos</a>
                    <a href="/escola/niveis"         class="adm-nav-item <?= $ap === 'escolar_niveis' ? 'active' : '' ?>"><i class="fa-solid fa-layer-group fa-fw"></i> Níveis</a>
                    <a href="/escola/series"         class="adm-nav-item <?= $ap === 'escolar_series' ? 'active' : '' ?>"><i class="fa-solid fa-list-ol fa-fw"></i> Séries</a>
                    <a href="/escola/cursos"         class="adm-nav-item <?= $ap === 'escolar_cursos' ? 'active' : '' ?>"><i class="fa-solid fa-graduation-cap fa-fw"></i> Cursos</a>
                    <a href="/escola/turmas"         class="adm-nav-item <?= $ap === 'escolar_turmas' ? 'active' : '' ?>"><i class="fa-solid fa-people-group fa-fw"></i> Turmas</a>
                    <a href="/escola/disciplinas"    class="adm-nav-item <?= $ap === 'escolar_disciplinas' ? 'active' : '' ?>"><i class="fa-solid fa-chalkboard fa-fw"></i> Disciplinas</a>
                    <a href="/escola/professores"    class="adm-nav-item <?= $ap === 'escolar_professores' ? 'active' : '' ?>"><i class="fa-solid fa-chalkboard-user fa-fw"></i> Professores</a>
                    <a href="/escola/atribuicoes"    class="adm-nav-item <?= $ap === 'escolar_atribuicoes' ? 'active' : '' ?>"><i class="fa-solid fa-link fa-fw"></i> Atribuições</a>
                    <a href="/escola/horarios"       class="adm-nav-item <?= $ap === 'escolar_horarios' ? 'active' : '' ?>"><i class="fa-solid fa-clock fa-fw"></i> Horários</a>
                    <a href="/escola/calendario"     class="adm-nav-item <?= $ap === 'escolar_calendario' ? 'active' : '' ?>"><i class="fa-solid fa-calendar fa-fw"></i> Calendário</a>
                </div>
            </details>

            <!-- ALUNOS -->
            <p class="adm-nav-label">Alunos</p>
            <details class="adm-nav-group" <?= $apAlunos ? 'open' : '' ?>>
                <summary class="adm-nav-group-title">
                    <i class="fa-solid fa-user-graduate fa-fw"></i> Alunos
                    <svg class="adm-nav-chevron" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 6 15 12 9 18"/></svg>
                </summary>
                <div class="adm-nav-submenu">
                    <a href="/escola/alunos"             class="adm-nav-item <?= $ap === 'escolar_alunos' ? 'active' : '' ?>"><i class="fa-solid fa-users fa-fw"></i> Alunos</a>
                    <a href="/escola/matriculas"          class="adm-nav-item <?= $ap === 'escolar_matriculas' ? 'active' : '' ?>"><i class="fa-solid fa-file-signature fa-fw"></i> Matrículas</a>
                    <a href="/escola/cargos-alunos"      class="adm-nav-item <?= $ap === 'escolar_cargos_alunos' ? 'active' : '' ?>"><i class="fa-solid fa-id-badge fa-fw"></i> Cargos de Alunos</a>
                    <a href="/escola/cargos-professores" class="adm-nav-item <?= $ap === 'escolar_cargos_professores' ? 'active' : '' ?>"><i class="fa-solid fa-user-tie fa-fw"></i> Cargos Professores</a>
                    <a href="/escola/ocorrencias"        class="adm-nav-item <?= $ap === 'escolar_ocorrencias' ? 'active' : '' ?>"><i class="fa-solid fa-triangle-exclamation fa-fw"></i> Ocorrências</a>
                </div>
            </details>

            <!-- AVALIAÇÃO -->
            <p class="adm-nav-label">Avaliação</p>
            <details class="adm-nav-group" <?= $apAvaliacao ? 'open' : '' ?>>
                <summary class="adm-nav-group-title">
                    <i class="fa-solid fa-chart-bar fa-fw"></i> Avaliação
                    <svg class="adm-nav-chevron" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 6 15 12 9 18"/></svg>
                </summary>
                <div class="adm-nav-submenu">
                    <a href="/escola/frequencia"  class="adm-nav-item <?= $ap === 'escolar_frequencia' ? 'active' : '' ?>"><i class="fa-solid fa-calendar-check fa-fw"></i> Frequência</a>
                    <a href="/escola/avaliacoes"  class="adm-nav-item <?= $ap === 'escolar_avaliacoes' ? 'active' : '' ?>"><i class="fa-solid fa-pencil fa-fw"></i> Avaliações</a>
                    <a href="/escola/notas"       class="adm-nav-item <?= $ap === 'escolar_notas' ? 'active' : '' ?>"><i class="fa-solid fa-star fa-fw"></i> Notas</a>
                    <a href="/escola/boletins"    class="adm-nav-item <?= $ap === 'escolar_boletins' ? 'active' : '' ?>"><i class="fa-solid fa-file-lines fa-fw"></i> Boletins</a>
                </div>
            </details>

            <!-- FINANCEIRO -->
            <p class="adm-nav-label">Financeiro</p>
            <details class="adm-nav-group" <?= $apFinanceiro ? 'open' : '' ?>>
                <summary class="adm-nav-group-title">
                    <i class="fa-solid fa-coins fa-fw"></i> Financeiro
                    <svg class="adm-nav-chevron" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 6 15 12 9 18"/></svg>
                </summary>
                <div class="adm-nav-submenu">
                    <a href="/escola/planos-propinas" class="adm-nav-item <?= $ap === 'escolar_planos_cobranca' ? 'active' : '' ?>"><i class="fa-solid fa-list-check fa-fw"></i> Planos de Propinas</a>
                    <a href="/escola/cobrancas"       class="adm-nav-item <?= $ap === 'escolar_cobrancas' ? 'active' : '' ?>"><i class="fa-solid fa-file-invoice fa-fw"></i> Cobranças</a>
                    <a href="/escola/pagamentos"      class="adm-nav-item <?= $ap === 'escolar_pagamentos' ? 'active' : '' ?>"><i class="fa-solid fa-credit-card fa-fw"></i> Pagamentos</a>
                    <a href="/escola/aging"           class="adm-nav-item <?= $ap === 'escolar_inadimplencia' ? 'active' : '' ?>"><i class="fa-solid fa-clock-rotate-left fa-fw"></i> Inadimplência</a>
                    <a href="/escola/config-financeira" class="adm-nav-item <?= $ap === 'escolar_config_financeira' ? 'active' : '' ?>"><i class="fa-solid fa-sliders fa-fw"></i> Config. Financeira</a>
                </div>
            </details>

            <!-- BIBLIOTECA -->
            <p class="adm-nav-label">Biblioteca</p>
            <details class="adm-nav-group" <?= $apBiblioteca ? 'open' : '' ?>>
                <summary class="adm-nav-group-title">
                    <i class="fa-solid fa-book fa-fw"></i> Biblioteca
                    <svg class="adm-nav-chevron" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 6 15 12 9 18"/></svg>
                </summary>
                <div class="adm-nav-submenu">
                    <a href="/escola/biblioteca"  class="adm-nav-item <?= $ap === 'escolar_biblioteca' ? 'active' : '' ?>"><i class="fa-solid fa-books fa-fw"></i> Livros</a>
                    <a href="/escola/emprestimos" class="adm-nav-item <?= $ap === 'escolar_emprestimos' ? 'active' : '' ?>"><i class="fa-solid fa-arrow-right-arrow-left fa-fw"></i> Empréstimos</a>
                </div>
            </details>

            <!-- COMUNICAÇÃO -->
            <p class="adm-nav-label">Comunicação</p>
            <details class="adm-nav-group" <?= $apComuncacao ? 'open' : '' ?>>
                <summary class="adm-nav-group-title">
                    <i class="fa-solid fa-bullhorn fa-fw"></i> Comunicação
                    <svg class="adm-nav-chevron" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 6 15 12 9 18"/></svg>
                </summary>
                <div class="adm-nav-submenu">
                    <a href="/escola/comunicacao"        class="adm-nav-item <?= $ap === 'escolar_comunicacao' ? 'active' : '' ?>"><i class="fa-solid fa-envelope fa-fw"></i> Mensagens</a>
                    <a href="/escola/resumo-academico"   class="adm-nav-item <?= $ap === 'escolar_resumo_academico' ? 'active' : '' ?>"><i class="fa-solid fa-chart-column fa-fw"></i> Resumo Académico</a>
                    <a href="/escola/resumo-financeiro"  class="adm-nav-item <?= $ap === 'escolar_resumo_financeiro' ? 'active' : '' ?>"><i class="fa-solid fa-chart-pie fa-fw"></i> Resumo Financeiro</a>
                    <a href="/escola/bolsas"             class="adm-nav-item"><i class="fa-solid fa-hand-holding-heart fa-fw"></i> Bolsas & Isenções</a>
                </div>
            </details>

            <!-- PORTAL -->
            <p class="adm-nav-label">Portal</p>
            <a href="/escola/portal-alunos" class="adm-nav-item <?= $apPortal ? 'active' : '' ?>">
                <i class="fa-solid fa-display fa-fw"></i> Portal do Aluno
            </a>

        </nav>

        <!-- Utilizador + Logout -->
        <div class="escola-user-block">
            <div style="display:flex;align-items:center;gap:.6rem;margin-bottom:.6rem">
                <div class="escola-user-avatar"><?= $initials ?></div>
                <div style="flex:1;min-width:0">
                    <div style="font-size:.8rem;font-weight:600;color:#CBD5E1;white-space:nowrap;overflow:hidden;text-overflow:ellipsis"><?= htmlspecialchars($adminUser) ?></div>
                    <div style="font-size:.68rem;color:#475569"><?= htmlspecialchars($userRole) ?></div>
                </div>
            </div>
            <a href="/nexora/logout" style="display:flex;align-items:center;gap:.5rem;font-size:.78rem;color:#64748B;text-decoration:none;padding:.35rem .5rem;border-radius:6px;transition:color .12s" onmouseover="this.style.color='#94A3B8'" onmouseout="this.style.color='#64748B'">
                <i class="fa-solid fa-arrow-right-from-bracket fa-fw"></i> Sair
            </a>
            <?php if ($app->session->isSuperAdmin() || $app->session->isBoth()): ?>
            <a href="/nexora/" class="escola-back-btn">
                <i class="fa-solid fa-grid-2 fa-fw"></i> Painel ERP Geral
            </a>
            <?php endif; ?>
        </div>

    </aside>

    <!-- ── Main ── -->
    <div class="adm-main">
        <header class="adm-header">
            <button class="adm-btn adm-btn-ghost adm-btn-icon" id="sidebarToggle" title="Menu" style="display:none">
                <i class="fa-solid fa-bars"></i>
            </button>
            <nav class="adm-header-breadcrumb">
                <a href="/escola"><i class="fa-solid fa-graduation-cap" style="color:#0D9488;margin-right:.3rem"></i> Escola</a>
                <?php foreach ($breadcrumb ?? [] as $i => [$label, $href]): ?>
                    <span class="sep">/</span>
                    <?php if ($href && $i < count($breadcrumb) - 1): ?>
                        <a href="<?= htmlspecialchars($href) ?>"><?= htmlspecialchars($label) ?></a>
                    <?php else: ?>
                        <span class="current"><?= htmlspecialchars($label) ?></span>
                    <?php endif; ?>
                <?php endforeach; ?>
            </nav>
        </header>

        <main class="adm-content">
