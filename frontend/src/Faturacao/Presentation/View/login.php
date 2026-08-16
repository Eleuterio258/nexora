<?php
use E258Tech\Faturacao\Presentation\View\Html;

/** @var string|null $error */
?>
<!doctype html>
<html lang="pt-PT">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Entrar — PHC Faturação</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/assets/styles.css">
</head>
<body>
  <div style="min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px">
    <article class="panel data-panel" style="max-width:380px;width:100%">
      <div class="panel-head">
        <h2>PHC Faturação</h2>
        <p>Inicie sessão com a sua conta Nexora para aceder aos dados reais da sua empresa.</p>
      </div>
      <?php if ($error !== null): ?>
        <div class="toast error" style="position:static;margin-bottom:16px"><?= Html::e($error) ?></div>
      <?php endif; ?>
      <form method="post" action="/login" class="form-section">
        <label>
          <span>E-mail</span>
          <input type="email" name="email" required autofocus autocomplete="username">
        </label>
        <label>
          <span>Palavra-passe</span>
          <input type="password" name="password" required autocomplete="current-password">
        </label>
        <button type="submit" class="btn primary wide">Entrar</button>
      </form>
    </article>
  </div>
</body>
</html>
