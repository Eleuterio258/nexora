<?php
$icon = static function (string $name): string {
    return match ($name) {
        'briefcase' => '<svg viewBox="0 0 24 24"><rect x="3" y="7" width="18" height="13" rx="2"/><path d="M8 7V5a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><path d="M3 13h18"/><path d="M10 12h4v3h-4z"/></svg>',
        'school' => '<svg viewBox="0 0 24 24"><path d="M4 21V9l8-5 8 5v12"/><path d="M9 21v-6h6v6"/><path d="M8 11h.01M16 11h.01"/><path d="M12 8v4"/><path d="M3 21h18"/></svg>',
        'graduation' => '<svg viewBox="0 0 24 24"><path d="m2 8 10-5 10 5-10 5z"/><path d="M6 10v5c2 2 10 2 12 0v-5"/><path d="M22 8v6"/></svg>',
        'users' => '<svg viewBox="0 0 24 24"><path d="M16 21v-2a4 4 0 0 0-8 0v2"/><circle cx="12" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/><path d="M2 21v-2a4 4 0 0 1 3-3.87"/><path d="M8 3.13a4 4 0 0 0 0 7.75"/></svg>',
        'shield' => '<svg viewBox="0 0 24 24"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><circle cx="12" cy="10" r="3"/><path d="M8 17a4 4 0 0 1 8 0"/></svg>',
        default => '',
    };
};
?>
<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Selecione o seu destino</title>
    <style>
        :root {
            --green: #10b981;
            --green-dark: #059669;
            --ink: #111827;
            --muted: #6b7280;
            --line: #e5e7eb;
            --bg: #f8fafc;
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            min-height: 100vh;
            font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            color: var(--ink);
            background:
                radial-gradient(circle at 5% 100%, rgba(16,185,129,.18), transparent 24%),
                linear-gradient(180deg, #ffffff 0%, var(--bg) 100%);
        }
        .page {
            min-height: 100vh;
            padding: 38px clamp(18px, 4vw, 64px) 56px;
            display: flex;
            flex-direction: column;
            align-items: center;
        }
        .brand {
            display: flex;
            align-items: center;
            gap: 12px;
            font-weight: 800;
            font-size: 28px;
            margin-bottom: 42px;
        }
        .brand-mark {
            width: 42px;
            height: 42px;
            border-radius: 50%;
            background: conic-gradient(from 20deg, #10b981, #34d399, #047857, #10b981);
            position: relative;
        }
        .brand-mark::after {
            content: "";
            position: absolute;
            inset: 9px;
            border-radius: 50%;
            background: #fff;
            box-shadow: inset 8px 0 0 rgba(16,185,129,.25);
        }
        .brand span span { color: var(--green); }
        h1 {
            margin: 0;
            font-size: clamp(36px, 5vw, 68px);
            line-height: 1.05;
            text-align: center;
            letter-spacing: 0;
        }
        .subtitle {
            margin: 22px 0 40px;
            color: var(--muted);
            font-size: clamp(16px, 2vw, 22px);
            text-align: center;
        }
        .grid {
            width: min(100%, 1320px);
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 28px;
            justify-content: center;
        }
        .card {
            min-height: 238px;
            border: 1px solid var(--line);
            border-radius: 8px;
            background: rgba(255,255,255,.92);
            box-shadow: 0 18px 42px rgba(15,23,42,.09);
            text-decoration: none;
            color: inherit;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 34px 24px 28px;
            transition: transform .16s ease, border-color .16s ease, box-shadow .16s ease;
        }
        .card:hover {
            transform: translateY(-3px);
            border-color: rgba(16,185,129,.42);
            box-shadow: 0 24px 54px rgba(15,23,42,.13);
        }
        .icon {
            width: 108px;
            height: 108px;
            border-radius: 50%;
            background: #e8f7f1;
            display: grid;
            place-items: center;
            margin-bottom: 22px;
        }
        .icon svg {
            width: 58px;
            height: 58px;
            fill: none;
            stroke: var(--green);
            stroke-width: 1.8;
            stroke-linecap: round;
            stroke-linejoin: round;
        }
        .card h2 {
            margin: 0;
            font-size: clamp(24px, 3vw, 32px);
            line-height: 1.15;
            text-align: center;
            letter-spacing: 0;
        }
        .card p {
            min-height: 24px;
            margin: 12px 0 24px;
            color: var(--muted);
            font-size: 17px;
            text-align: center;
        }
        .arrow {
            color: var(--green);
            font-size: 34px;
            line-height: 1;
        }
        .logout {
            margin-top: 34px;
            color: var(--muted);
            text-decoration: none;
            font-size: 14px;
        }
        .logout:hover { color: var(--green-dark); }
        @media (max-width: 720px) {
            .page { padding-top: 28px; }
            .brand { margin-bottom: 30px; font-size: 22px; }
            .brand-mark { width: 34px; height: 34px; }
            .grid { grid-template-columns: 1fr; gap: 18px; }
            .card { min-height: 210px; }
        }
    </style>
</head>
<body>
    <main class="page">
        <div class="brand">
            <span class="brand-mark" aria-hidden="true"></span>
            <span>Nexora<span>ERP</span></span>
        </div>
        <h1>Selecione o seu destino</h1>
        <p class="subtitle">Escolha o sistema que deseja aceder para continuar.</p>

        <section class="grid" aria-label="Destinos disponiveis">
            <?php foreach ($destinos as $destino): ?>
                <a class="card" href="<?= htmlspecialchars($destino['url']) ?>">
                    <span class="icon" aria-hidden="true"><?= $icon($destino['icone']) ?></span>
                    <h2><?= htmlspecialchars($destino['titulo']) ?></h2>
                    <p><?= htmlspecialchars($destino['descricao']) ?></p>
                    <span class="arrow" aria-hidden="true">&rsaquo;</span>
                </a>
            <?php endforeach; ?>
        </section>
        <a class="logout" href="/nexora/logout">Terminar sessao</a>
    </main>
</body>
</html>
