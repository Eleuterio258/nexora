<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Minhas Candidaturas | E258Tech</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700;800&family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="/assets/css/styles.css">
    <link rel="stylesheet" href="/assets/css/vagas.css">
</head>
<body>
    <?php include 'src/View/templates/partials/nav.php'; ?>

    <?php
    $estadoLabels = [
        'recebida'    => 'Recebida',
        'em_analise'  => 'Em análise',
        'entrevista'  => 'Entrevista agendada',
        'aprovada'    => 'Aprovada',
        'rejeitada'   => 'Não seleccionada',
    ];
    ?>

    <section class="vagas-hero" style="min-height:60vh;">
        <div class="container" style="max-width:800px;">
            <h1 class="vagas-hero-title" style="font-size:2rem;">Minhas Candidaturas</h1>
            <p class="vagas-hero-sub">Bem-vindo, <?= htmlspecialchars($candidato['nome'] ?? 'candidato') ?>.</p>

            <div style="margin-top:2rem;background:#fff;padding:1.5rem;border-radius:1rem;box-shadow:0 10px 40px rgba(0,0,0,0.1);">
                <?php if (empty($candidaturas)): ?>
                    <p>Ainda não submeteste nenhuma candidatura. <a href="/vagas" style="color:#2563eb;text-decoration:underline;">Ver vagas</a></p>
                <?php else: ?>
                    <div style="display:grid;gap:1rem;">
                        <?php foreach ($candidaturas as $c): ?>
                        <div style="border:1px solid #e5e7eb;border-radius:0.75rem;padding:1rem;">
                            <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:0.5rem;">
                                <strong><?= htmlspecialchars($c['vaga_titulo'] ?? '') ?></strong>
                                <span style="display:inline-block;padding:0.3rem 0.7rem;border-radius:999px;background:#f0fdf4;color:#166534;font-size:0.875rem;font-weight:600;">
                                    <?= htmlspecialchars($c['estado_label'] ?? $estadoLabels[$c['estado'] ?? ''] ?? ($c['estado'] ?? '')) ?>
                                </span>
                            </div>
                            <p style="margin:0.5rem 0 0;color:#6b7280;font-size:0.875rem;">
                                Código: <?= htmlspecialchars($c['codigo_acompanhamento'] ?? '—') ?>
                                · Submetida em <?= !empty($c['criado_em']) ? htmlspecialchars((new DateTime($c['criado_em']))->format('d/m/Y')) : '—' ?>
                            </p>
                            <?php if (!empty($c['entrevista_data'])): ?>
                            <p style="margin-top:0.5rem;color:#2563eb;font-size:0.875rem;">
                                Entrevista: <?= htmlspecialchars((new DateTime($c['entrevista_data']))->format('d/m/Y H:i')) ?>
                            </p>
                            <?php endif; ?>
                        </div>
                        <?php endforeach; ?>
                    </div>
                <?php endif; ?>
            </div>

            <div style="margin-top:1.5rem;text-align:center;">
                <a href="/vagas" class="btn-outline">← Voltar às vagas</a>
                <a href="/carreira/candidato/logout" class="btn-outline" style="margin-left:0.5rem;">Sair</a>
            </div>
        </div>
    </section>
</body>
</html>
