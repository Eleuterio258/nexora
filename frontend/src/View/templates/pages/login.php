<?php
// Módulos da suite Nexora mostrados no ecrã de login. Texto em vez de logótipos
// de imagem: os ficheiros em assets/images/erp-logos/*.svg são traçados a
// partir de bitmaps com uma margem transparente enorme (o desenho real ocupa
// só ~20–45% do canvas), pelo que ficam ilegíveis a qualquer tamanho pequeno.
// Uma única fonte de dados alimenta a versão desktop e a mobile, para não
// haver dois blocos de HTML escritos à mão a divergir com o tempo.
$suiteModules = [
    ['nome' => 'Pay',          'cor' => '#f5b942'],
    ['nome' => 'School',       'cor' => '#60a5fa'],
    ['nome' => 'Recrutamento', 'cor' => '#c084fc'],
];

$renderErpSuite = function (bool $mobile) use ($suiteModules): void {
    $cls = 'erp-suite' . ($mobile ? ' erp-suite--mobile' : '');
    ?>
    <div class="<?= $cls ?>" aria-label="Suite Nexora ERP">
        <div class="erp-suite-label">Suite ERP</div>
        <div class="erp-suite-primary">
            <span class="erp-suite-mark">N</span>
            <span class="erp-suite-name">Nexora <strong>ERP</strong></span>
        </div>
        <div class="erp-suite-modules">
            <?php foreach ($suiteModules as $mod): ?>
            <div class="erp-suite-module">
                <span class="erp-suite-dot" style="background:<?= htmlspecialchars($mod['cor']) ?>"></span>
                <?= htmlspecialchars($mod['nome']) ?>
            </div>
            <?php endforeach; ?>
        </div>
    </div>
    <?php
};
?>
<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin · E258Tech</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700;800&family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="/assets/css/nexora.css">
    <style>
        html, body { height: 100%; }
        body {
            display: flex;
            min-height: 100vh;
            background: var(--adm-bg);
        }

        .login-page { display: flex; width: 100%; min-height: 100vh; }

        /* ── Painel lateral (branding) ── */
        .login-aside {
            position: relative;
            flex: 1 1 46%;
            display: flex;
            flex-direction: column;
            justify-content: center;
            padding: var(--adm-sp-12);
            background: linear-gradient(135deg, #0b2e23 0%, #065f46 55%, #10b981 140%);
            color: #fff;
            overflow: hidden;
        }
        .login-aside::before,
        .login-aside::after {
            content: '';
            position: absolute;
            border-radius: 50%;
            background: rgba(255,255,255,.08);
        }
        .login-aside::before { width: 420px; height: 420px; top: -140px; right: -140px; }
        .login-aside::after  { width: 280px; height: 280px; bottom: -90px; left: -70px; background: rgba(255,255,255,.06); }

        .login-aside-content { position: relative; z-index: 1; max-width: 500px; }
        .login-aside .login-logo span { color: #fff; }
        .login-aside .login-logo-mark { filter: brightness(0) invert(1); }

        .login-aside h2 {
            font-family: var(--adm-font-h);
            font-size: 2rem;
            font-weight: 700;
            line-height: 1.25;
            margin: var(--adm-sp-10) 0 var(--adm-sp-3);
        }
        .login-aside > .login-aside-content > p {
            font-size: var(--adm-text-base);
            color: rgba(255,255,255,.78);
            line-height: 1.6;
            margin-bottom: var(--adm-sp-8);
        }

        .erp-suite {
            display: flex;
            flex-direction: column;
            gap: var(--adm-sp-4);
            padding: var(--adm-sp-5);
            margin-bottom: var(--adm-sp-10);
            background: rgba(255,255,255,.10);
            border: 1px solid rgba(255,255,255,.16);
            border-radius: var(--adm-radius-lg);
            backdrop-filter: blur(12px);
        }
        .erp-suite-label {
            font-size: .68rem;
            font-weight: 700;
            line-height: 1;
            letter-spacing: .08em;
            text-transform: uppercase;
            color: rgba(255,255,255,.64);
        }
        /* Marca + nome por extenso — sem depender de ficheiros de logótipo
           (os SVGs em erp-logos/ são traçados a partir de bitmaps com uma
           margem transparente enorme e ficam ilegíveis a este tamanho). */
        .erp-suite-primary {
            display: flex;
            align-items: center;
            gap: var(--adm-sp-3);
        }
        .erp-suite-mark {
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
            width: 34px;
            height: 34px;
            border-radius: var(--adm-radius-md);
            background: rgba(255,255,255,.16);
            border: 1px solid rgba(255,255,255,.22);
            font-family: var(--adm-font-h);
            font-weight: 700;
            font-size: 1.05rem;
            color: #fff;
        }
        .erp-suite-name {
            font-family: var(--adm-font-h);
            font-weight: 500;
            font-size: 1.15rem;
            color: rgba(255,255,255,.92);
            letter-spacing: -.01em;
        }
        .erp-suite-name strong { font-weight: 700; color: #fff; }
        .erp-suite-modules {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: var(--adm-sp-2);
        }
        .erp-suite-module {
            display: flex;
            align-items: center;
            gap: .5rem;
            min-height: 40px;
            padding: 0 var(--adm-sp-3);
            font-size: var(--adm-text-xs);
            font-weight: 600;
            color: rgba(255,255,255,.85);
            background: rgba(255,255,255,.08);
            border: 1px solid rgba(255,255,255,.14);
            border-radius: var(--adm-radius-md);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        .erp-suite-dot {
            flex-shrink: 0;
            width: 8px;
            height: 8px;
            border-radius: 50%;
        }
        .erp-suite--mobile {
            display: none;
            margin-bottom: var(--adm-sp-5);
            padding: var(--adm-sp-4);
            background: var(--adm-gray-50, #f8fafc);
            border-color: var(--adm-gray-200);
            backdrop-filter: none;
        }
        .erp-suite--mobile .erp-suite-label { color: var(--adm-gray-500); }
        .erp-suite--mobile .erp-suite-mark { background: var(--adm-green); border-color: var(--adm-green); }
        .erp-suite--mobile .erp-suite-name { color: var(--adm-gray-700); }
        .erp-suite--mobile .erp-suite-name strong { color: var(--adm-gray-900); }
        .erp-suite--mobile .erp-suite-module {
            color: var(--adm-gray-700);
            background: var(--adm-white);
            border-color: var(--adm-gray-200);
            box-shadow: var(--adm-shadow-sm);
        }

        .login-features { list-style: none; display: flex; flex-direction: column; gap: var(--adm-sp-5); }
        .login-features li { display: flex; align-items: center; gap: var(--adm-sp-4); font-size: var(--adm-text-sm); color: rgba(255,255,255,.92); }
        .login-features .icon {
            display: flex; align-items: center; justify-content: center; flex-shrink: 0;
            width: 38px; height: 38px;
            background: rgba(255,255,255,.12);
            border: 1px solid rgba(255,255,255,.16);
            border-radius: var(--adm-radius-md);
        }
        .login-features strong { display: block; font-weight: 600; }
        .login-features small { display: block; color: rgba(255,255,255,.6); font-size: var(--adm-text-xs); margin-top: 1px; }

        /* ── Painel do formulário ── */
        .login-main {
            flex: 1 1 54%;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: var(--adm-sp-6);
        }
        .login-wrap { width: 100%; max-width: 400px; }
        .login-logo { display: flex; align-items: center; gap: var(--adm-sp-3); margin-bottom: var(--adm-sp-8); }
        .login-logo span { font-family: var(--adm-font-h); font-weight: 700; font-size: 1.125rem; color: var(--adm-gray-900); }

        /* e258tech-logo.png tem uma margem transparente grande à volta do
           desenho real (bbox ~203,132 a 1537,355 num canvas 1920x544);
           recorta essa margem via background-position/-size em vez de
           depender de um ficheiro à parte. */
        .login-logo-mark {
            display: block;
            flex-shrink: 0;
            width: 191px;
            height: 32px;
            background-image: url('/assets/images/e258tech-logo.png');
            background-repeat: no-repeat;
            background-size: auto 78px;
            background-position: -29px -19px;
        }
        .login-logo--mobile { display: none; }

        .login-card {
            background: var(--adm-white);
            border: 1px solid var(--adm-gray-200);
            border-radius: var(--adm-radius-lg);
            padding: var(--adm-sp-8);
            box-shadow: var(--adm-shadow-md);
        }
        .login-title { font-family: var(--adm-font-h); font-size: 1.625rem; font-weight: 700; color: var(--adm-gray-900); margin-bottom: 0.375rem; }
        .login-sub   { font-size: var(--adm-text-sm); color: var(--adm-gray-500); margin-bottom: var(--adm-sp-8); }

        .login-erro {
            display: flex; align-items: center; gap: var(--adm-sp-2);
            background: #fef2f2; border: 1px solid #fecaca; border-radius: var(--adm-radius-sm);
            padding: var(--adm-sp-3) var(--adm-sp-4); font-size: var(--adm-text-sm); color: #dc2626;
            margin-bottom: var(--adm-sp-5);
        }
        .login-erro svg { flex-shrink: 0; }

        .login-field { position: relative; }
        .login-field .field-icon {
            position: absolute; left: var(--adm-sp-3); top: 50%; transform: translateY(-50%);
            color: var(--adm-gray-400); pointer-events: none;
        }
        .login-field .adm-input { padding-left: 2.5rem; }
        .login-field .adm-input.has-toggle { padding-right: 2.5rem; }
        .login-field .pw-toggle {
            position: absolute; right: 0.3rem; top: 50%; transform: translateY(-50%);
            display: flex; align-items: center; justify-content: center;
            width: 30px; height: 30px;
            background: transparent; border: none; cursor: pointer; color: var(--adm-gray-400);
            border-radius: var(--adm-radius-sm);
        }
        .login-field .pw-toggle:hover { color: var(--adm-gray-600); background: var(--adm-gray-100); }
        .login-field .pw-toggle svg:last-child { display: none; }
        .login-field .pw-toggle.is-visible svg:first-child { display: none; }
        .login-field .pw-toggle.is-visible svg:last-child { display: block; }

        .login-row { display: flex; align-items: center; justify-content: space-between; margin-bottom: var(--adm-sp-6); }
        .login-remember { display: flex; align-items: center; gap: var(--adm-sp-2); font-size: var(--adm-text-sm); color: var(--adm-gray-600); cursor: pointer; }
        .login-remember input { accent-color: var(--adm-green); width: 15px; height: 15px; }

        .login-submit { width: 100%; justify-content: center; padding: .7rem var(--adm-sp-4); font-size: var(--adm-text-sm); }
        .login-submit svg.spin { animation: spin .7s linear infinite; }
        @keyframes spin { to { transform: rotate(360deg); } }

        .login-footer { text-align: center; font-size: var(--adm-text-xs); color: var(--adm-gray-400); margin-top: var(--adm-sp-8); }

        @media (max-width: 900px) {
            .login-aside { display: none; }
            .login-logo--mobile { display: flex; }
            .erp-suite--mobile { display: flex; }
        }

        @media (max-width: 520px) {
            .erp-suite-modules { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
<div class="login-page">

    <!-- ── Painel de branding ── -->
    <aside class="login-aside">
        <div class="login-aside-content">
            <div class="login-logo">
                <span class="login-logo-mark" role="img" aria-label="E258Tech"></span>
                <span>E258Tech</span>
            </div>
            <h2>Painel de Administração</h2>
            <p>Recrutamento, utilizadores, permissões e auditoria — tudo num só lugar.</p>

            <?php $renderErpSuite(false); ?>

            <ul class="login-features">
                <li>
                    <span class="icon">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M20 7H4a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2z"/>
                            <path d="M16 7V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v2"/>
                        </svg>
                    </span>
                    <span>
                        <strong>Recrutamento</strong>
                        <small>Vagas, candidaturas e pipeline de seleção</small>
                    </span>
                </li>
                <li>
                    <span class="icon">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
                        </svg>
                    </span>
                    <span>
                        <strong>Utilizadores &amp; Permissões</strong>
                        <small>Cargos, acessos e níveis de autorização</small>
                    </span>
                </li>
                <li>
                    <span class="icon">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
                        </svg>
                    </span>
                    <span>
                        <strong>Auditoria</strong>
                        <small>Histórico completo de ações no sistema</small>
                    </span>
                </li>
            </ul>
        </div>
    </aside>

    <!-- ── Formulário de login ── -->
    <main class="login-main">
        <div class="login-wrap">
            <div class="login-logo login-logo--mobile">
                <span class="login-logo-mark" role="img" aria-label="E258Tech"></span>
                <span>Admin Panel</span>
            </div>

            <?php $renderErpSuite(true); ?>

            <div class="login-card">
                <h1 class="login-title">Aceder ao Nexora ERP</h1>
                <p class="login-sub">Entre para gerir os módulos da suite empresarial</p>

                <?php if ($erro): ?>
                <div class="login-erro">
                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                    <?= htmlspecialchars($erro) ?>
                </div>
                <?php endif; ?>

                <form method="POST" action="" autocomplete="on" id="loginForm">
                    <input type="hidden" name="csrf_token" value="<?= $csrf ?>">

                    <div class="adm-form-group">
                        <label class="adm-label" for="email">Email</label>
                        <div class="login-field">
                            <svg class="field-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
                                <polyline points="22,6 12,13 2,6"/>
                            </svg>
                            <input class="adm-input" type="email" id="email" name="email"
                                   autocomplete="email" required autofocus
                                   placeholder="nome@empresa.com"
                                   value="<?= htmlspecialchars($app->request->postString('email')) ?>">
                        </div>
                    </div>

                    <div class="adm-form-group">
                        <label class="adm-label" for="password">Senha</label>
                        <div class="login-field">
                            <svg class="field-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <rect x="3" y="11" width="18" height="11" rx="2"/>
                                <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                            </svg>
                            <input class="adm-input has-toggle" type="password" id="password" name="password"
                                   autocomplete="current-password" required placeholder="••••••••">
                            <button type="button" class="pw-toggle" id="pwToggle" title="Mostrar/ocultar senha" tabindex="-1">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                            </button>
                        </div>
                    </div>

                    <button type="submit" class="adm-btn adm-btn-primary login-submit" id="btnLogin">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/>
                            <polyline points="10 17 15 12 10 7"/>
                            <line x1="15" y1="12" x2="3" y2="12"/>
                        </svg>
                        Entrar
                    </button>
                </form>
            </div>

            <p class="login-footer">&copy; <?= date('Y') ?> E258Tech. Todos os direitos reservados.</p>
        </div>
    </main>
</div>

<script>
    document.getElementById('pwToggle').addEventListener('click', function () {
        const input = document.getElementById('password');
        const visible = input.type === 'text';
        input.type = visible ? 'password' : 'text';
        this.classList.toggle('is-visible', !visible);
    });

    document.getElementById('loginForm').addEventListener('submit', function () {
        const btn = document.getElementById('btnLogin');
        btn.disabled = true;
        btn.innerHTML = '<svg class="spin" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg> A entrar…';
    });
</script>
</body>
</html>
