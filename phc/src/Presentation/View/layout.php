<!doctype html>
<html lang="pt-PT">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><?= \PHC\Presentation\View\Html::e($title ?? 'PHC Faturação') ?></title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/assets/styles.css">
</head>
<body>
  <div class="app-shell">
    <aside class="sidebar">
      <a class="brand" href="/" aria-label="PHC Faturação">
        <span class="brand-mark">P</span>
        <span><b>PHC</b><small>Faturação</small></span>
      </a>
      <nav id="mainNav" aria-label="Navegação principal">
        <a href="/" class="nav-item <?= ($active ?? '') === 'dashboard' ? 'active' : '' ?>"><span>⌂</span>Visão geral</a>
        <p class="nav-label">Vendas</p>
        <a href="/documents" class="nav-item <?= ($active ?? '') === 'documents' ? 'active' : '' ?>"><span>▤</span>Documentos</a>
        <a href="/customers" class="nav-item <?= ($active ?? '') === 'customers' ? 'active' : '' ?>"><span>♙</span>Clientes</a>
        <a href="/products" class="nav-item <?= ($active ?? '') === 'products' ? 'active' : '' ?>"><span>◇</span>Artigos e serviços</a>
        <p class="nav-label">Configuração</p>
        <a href="/series" class="nav-item <?= ($active ?? '') === 'series' ? 'active' : '' ?>"><span>≡</span>Séries documentais</a>
        <a href="/settings/invoice-layout" class="nav-item <?= ($active ?? '') === 'settings-invoice-layout' ? 'active' : '' ?>"><span>▧</span>Layout da fatura</a>
        <a href="/reports" class="nav-item <?= ($active ?? '') === 'reports' ? 'active' : '' ?>"><span>↗</span>Relatórios</a>
      </nav>
      <?php $authSession = new \PHC\Infrastructure\Auth\AuthSession(); ?>
      <div class="sidebar-foot">
        <span class="avatar"><?= \PHC\Presentation\View\Html::e(mb_strtoupper(mb_substr($authSession->userName() ?? '?', 0, 1))) ?></span>
        <span><b><?= \PHC\Presentation\View\Html::e($authSession->userName() ?? 'Sessão local') ?></b><small>Nexora</small></span>
        <form method="post" action="/logout" style="display:contents">
          <button type="submit" title="Sair">⏻</button>
        </form>
      </div>
    </aside>

    <main class="main">
      <header class="topbar">
        <div class="company-switcher">
          <span class="company-icon">N</span>
          <span><small>Empresa ativa</small><b>Nexora, Lda.</b></span>
          <button>⌄</button>
        </div>
        <form action="/documents" method="get" class="global-search">
          <span>⌕</span>
          <input id="globalSearch" name="search" type="search" placeholder="Pesquisar documentos, clientes ou artigos…" value="<?= \PHC\Presentation\View\Html::e($search ?? '') ?>">
          <kbd>Ctrl K</kbd>
        </form>
        <div class="top-actions"><button title="Ajuda">?</button><button title="Notificações">♢<i></i></button></div>
      </header>

      <section id="viewRoot" class="content" aria-live="polite">
        <?= $content ?? '' ?>
      </section>
    </main>
  </div>
</body>
</html>
