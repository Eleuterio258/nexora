<?php
/**
 * Login de terminal POS. Um terminal não tem pessoa nem email: identifica-se
 * pelo código e prova-o com o código de activação, definidos quando o terminal
 * foi criado no ERP.
 *
 * O ecrã é deliberadamente maior e mais espaçado que o login normal — quem o
 * usa está de pé, muitas vezes num tablet ou num monitor táctil de caixa.
 *
 * @var string $csrf
 * @var string $erro
 * @var E258Tech\Core\Application $app
 */
?>
<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Activar Terminal · Nexora POS</title>
    <link rel="stylesheet" href="/assets/css/admin.css">
    <style>
        :root {
            --t-fundo: #0f172a;
            --t-cartao: #ffffff;
            --t-texto: #0f172a;
            --t-suave: #64748b;
            --t-borda: #e2e8f0;
            --t-destaque: #10b981;
            --t-erro: #dc2626;
            --t-erro-fundo: #fef2f2;
            --t-erro-borda: #fecaca;
        }

        body {
            margin: 0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 1.5rem;
            background: var(--t-fundo);
            background-image: radial-gradient(circle at 20% 10%, #1e293b 0%, #0f172a 55%);
            font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
            color: var(--t-texto);
        }

        .t-cartao {
            width: 100%;
            max-width: 30rem;
            background: var(--t-cartao);
            padding: 2.5rem 2.25rem;
            box-shadow: 0 20px 50px rgba(0, 0, 0, .35);
        }

        .t-marca {
            display: flex;
            align-items: center;
            gap: .6rem;
            margin-bottom: 1.75rem;
        }
        .t-marca-icone {
            width: 2.5rem;
            height: 2.5rem;
            display: grid;
            place-items: center;
            background: var(--t-destaque);
            color: #fff;
            flex: none;
        }
        .t-marca-nome { font-size: 1.05rem; font-weight: 700; letter-spacing: -.01em; }
        .t-marca-sub { font-size: .8rem; color: var(--t-suave); }

        .t-titulo { font-size: 1.4rem; font-weight: 700; margin: 0 0 .35rem; letter-spacing: -.02em; }
        .t-sub { font-size: .9rem; color: var(--t-suave); margin: 0 0 1.75rem; line-height: 1.5; }

        .t-erro {
            display: flex;
            align-items: center;
            gap: .5rem;
            background: var(--t-erro-fundo);
            border: 1px solid var(--t-erro-borda);
            color: var(--t-erro);
            padding: .7rem .9rem;
            font-size: .85rem;
            margin-bottom: 1.25rem;
        }

        .t-grupo { margin-bottom: 1.1rem; }
        .t-label {
            display: block;
            font-size: .78rem;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: .06em;
            color: var(--t-suave);
            margin-bottom: .4rem;
        }
        .t-input {
            width: 100%;
            box-sizing: border-box;
            padding: .85rem .95rem;
            font-size: 1.05rem;
            font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
            letter-spacing: .06em;
            border: 1px solid var(--t-borda);
            background: #fff;
            color: var(--t-texto);
        }
        .t-input:focus {
            outline: 2px solid var(--t-destaque);
            outline-offset: 1px;
            border-color: var(--t-destaque);
        }
        .t-dica { font-size: .78rem; color: var(--t-suave); margin: .35rem 0 0; }

        .t-submeter {
            width: 100%;
            margin-top: .5rem;
            padding: .95rem;
            font-size: .95rem;
            font-weight: 600;
            border: 0;
            background: var(--t-destaque);
            color: #fff;
            cursor: pointer;
        }
        .t-submeter:hover { filter: brightness(.94); }
        .t-submeter:focus-visible { outline: 2px solid #fff; outline-offset: 2px; }

        .t-rodape {
            margin-top: 1.5rem;
            padding-top: 1.1rem;
            border-top: 1px solid var(--t-borda);
            font-size: .82rem;
            color: var(--t-suave);
            text-align: center;
        }
        .t-rodape a { color: var(--t-destaque); text-decoration: none; }
        .t-rodape a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <main class="t-cartao">
        <div class="t-marca">
            <span class="t-marca-icone">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="3" y="4" width="18" height="13" rx="1"/>
                    <path d="M7 21h10M12 17v4"/>
                </svg>
            </span>
            <span>
                <div class="t-marca-nome">Nexora <strong>POS</strong></div>
                <div class="t-marca-sub">Ponto de venda</div>
            </span>
        </div>

        <h1 class="t-titulo">Activar terminal</h1>
        <p class="t-sub">
            Introduza os códigos entregues com este terminal. Ficam guardados nesta
            sessão — não é preciso repetir a cada venda.
        </p>

        <?php if ($erro): ?>
        <div class="t-erro" role="alert">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true">
                <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
            </svg>
            <?= htmlspecialchars($erro) ?>
        </div>
        <?php endif; ?>

        <form method="POST" action="" autocomplete="off">
            <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">

            <div class="t-grupo">
                <label class="t-label" for="codigo_terminal">Código do terminal</label>
                <input class="t-input" type="text" id="codigo_terminal" name="codigo_terminal"
                       required autofocus placeholder="QBS-CAIXA1" maxlength="60"
                       value="<?= htmlspecialchars($app->request->postString('codigo_terminal')) ?>">
            </div>

            <div class="t-grupo">
                <label class="t-label" for="activation_code">Código de activação</label>
                <input class="t-input" type="password" id="activation_code" name="activation_code"
                       required placeholder="••••-••••-••••">
            </div>

            <div class="t-grupo">
                <label class="t-label" for="tenant_slug">Empresa <span style="text-transform:none;font-weight:400">(opcional)</span></label>
                <input class="t-input" type="text" id="tenant_slug" name="tenant_slug"
                       placeholder="quick-buystore" maxlength="60"
                       value="<?= htmlspecialchars($app->request->postString('tenant_slug')) ?>">
                <p class="t-dica">Só necessário se o mesmo código de terminal existir em mais do que uma empresa.</p>
            </div>

            <button type="submit" class="t-submeter">Activar e abrir o POS</button>
        </form>

        <div class="t-rodape">
            É um operador com conta própria? <a href="/nexora/login">Entrar com email</a>
        </div>
    </main>
</body>
</html>
