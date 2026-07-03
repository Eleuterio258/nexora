<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Definir Senha · Portal do Aluno</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" crossorigin="anonymous">
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        html, body { height: 100%; font-family: 'Plus Jakarta Sans', sans-serif; background: #F0F9FF; display: flex; align-items: center; justify-content: center; }
        .card { background: #fff; border-radius: 16px; padding: 2.5rem; width: 100%; max-width: 420px; box-shadow: 0 4px 24px rgba(0,0,0,.08); }
        .card-icon { width: 52px; height: 52px; border-radius: 14px; background: #0EA5E9; display: flex; align-items: center; justify-content: center; color: #fff; font-size: 1.4rem; margin-bottom: 1.25rem; }
        h1 { font-size: 1.4rem; font-weight: 800; color: #0C4A6E; margin-bottom: .25rem; }
        p.sub { font-size: .875rem; color: #64748B; margin-bottom: 1.5rem; }
        .form-group { margin-bottom: 1rem; }
        .form-label { display: block; font-size: .82rem; font-weight: 600; color: #334155; margin-bottom: .3rem; }
        .form-input { width: 100%; padding: .7rem .9rem; border: 1.5px solid #CBD5E1; border-radius: 10px; font-size: .9rem; font-family: inherit; outline: none; }
        .form-input:focus { border-color: #0EA5E9; box-shadow: 0 0 0 3px rgba(14,165,233,.12); }
        .btn { width: 100%; padding: .8rem; border-radius: 10px; border: none; cursor: pointer; background: linear-gradient(135deg,#0369A1,#0EA5E9); color: #fff; font-size: .95rem; font-weight: 700; font-family: inherit; margin-top: .5rem; }
        .alert { padding: .65rem .9rem; border-radius: 8px; font-size: .85rem; margin-bottom: 1rem; display: flex; align-items: center; gap: .5rem; }
        .alert-error   { background: #FEE2E2; color: #B91C1C; }
        .alert-success { background: #DCFCE7; color: #15803D; }
    </style>
</head>
<body>
<div class="card">
    <div class="card-icon"><i class="fa-solid fa-key"></i></div>
    <h1>Definir senha</h1>
    <p class="sub">Escolha uma senha segura para aceder ao portal.</p>

    <?php if ($ok): ?>
    <div class="alert alert-success">
        <i class="fa-solid fa-circle-check"></i>
        Senha definida com sucesso! <a href="/nexora/login?next=/portal/aluno" style="color:#15803D;font-weight:700">Fazer login</a>
    </div>
    <?php else: ?>
        <?php if ($erro): ?>
        <div class="alert alert-error">
            <i class="fa-solid fa-circle-exclamation"></i>
            <?= htmlspecialchars($erro) ?>
        </div>
        <?php endif; ?>
        <form method="POST">
            <input type="hidden" name="_csrf" value="<?= htmlspecialchars($csrfToken ?? '') ?>">
            <input type="hidden" name="token" value="<?= htmlspecialchars($token) ?>">
            <div class="form-group">
                <label class="form-label">Nova senha (mínimo 6 caracteres)</label>
                <input class="form-input" type="password" name="password" required minlength="6" placeholder="••••••••">
            </div>
            <div class="form-group">
                <label class="form-label">Confirmar senha</label>
                <input class="form-input" type="password" name="password2" required placeholder="••••••••">
            </div>
            <button type="submit" class="btn">
                <i class="fa-solid fa-check"></i> Definir senha e entrar
            </button>
        </form>
    <?php endif; ?>
</div>
</body>
</html>
