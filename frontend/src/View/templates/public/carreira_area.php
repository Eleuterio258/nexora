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

    <section class="vagas-hero" style="min-height:60vh;">
        <div class="container" style="max-width:800px;">
            <h1 class="vagas-hero-title" style="font-size:2rem;">Minhas Candidaturas</h1>
            <p class="vagas-hero-sub">Bem-vindo, <span id="area-nome">candidato</span>.</p>

            <div style="margin-top:2rem;background:#fff;padding:1.5rem;border-radius:1rem;box-shadow:0 10px 40px rgba(0,0,0,0.1);">
                <div id="area-conteudo">
                    <p>A carregar...</p>
                </div>
            </div>

            <div style="margin-top:1.5rem;text-align:center;">
                <a href="/vagas" class="btn-outline">← Voltar às vagas</a>
                <button onclick="sair()" class="btn-outline" style="margin-left:0.5rem;">Sair</button>
            </div>
        </div>
    </section>

    <script>
        const estadoLabels = {
            'recebida': 'Recebida',
            'em_analise': 'Em análise',
            'entrevista': 'Entrevista agendada',
            'aprovada': 'Aprovada',
            'rejeitada': 'Não selecionada'
        };

        const nome = localStorage.getItem('candidato_nome');
        if (nome) document.getElementById('area-nome').textContent = nome;

        async function carregarCandidaturas() {
            const conteudo = document.getElementById('area-conteudo');
            // Nota: o endpoint de histórico por candidato ainda não existe no backend.
            // Esta página usa o código de acompanhamento armazenado localmente como prova de conceito.
            const codigos = JSON.parse(localStorage.getItem('codigos_acompanhamento') || '[]');

            if (codigos.length === 0) {
                conteudo.innerHTML = '<p>Ainda não submeteste nenhuma candidatura. <a href="/vagas" style="color:#2563eb;text-decoration:underline;">Ver vagas</a></p>';
                return;
            }

            let html = '<div style="display:grid;gap:1rem;">';
            for (const codigo of codigos) {
                try {
                    const res = await fetch('/api/public/recrutamento/candidaturas/' + encodeURIComponent(codigo));
                    const data = await res.json();
                    if (data.candidatura) {
                        const c = data.candidatura;
                        html += `<div style="border:1px solid #e5e7eb;border-radius:0.75rem;padding:1rem;">`;
                        html += `<div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:0.5rem;">`;
                        html += `<strong>${c.vaga_titulo}</strong>`;
                        html += `<span style="display:inline-block;padding:0.3rem 0.7rem;border-radius:999px;background:#f0fdf4;color:#166534;font-size:0.875rem;font-weight:600;">${estadoLabels[c.estado] || c.estado}</span>`;
                        html += `</div>`;
                        html += `<p style="margin:0.5rem 0 0;color:#6b7280;font-size:0.875rem;">Código: ${c.codigo_acompanhamento} · Submetida em ${new Date(c.created_at).toLocaleDateString('pt-PT')}</p>`;
                        if (c.entrevista_data) {
                            html += `<p style="margin-top:0.5rem;color:#2563eb;font-size:0.875rem;">Entrevista: ${new Date(c.entrevista_data).toLocaleString('pt-PT')}</p>`;
                        }
                        html += `</div>`;
                    }
                } catch (e) {
                    console.error(e);
                }
            }
            html += '</div>';
            conteudo.innerHTML = html;
        }

        function sair() {
            localStorage.removeItem('candidato_id');
            localStorage.removeItem('candidato_nome');
            localStorage.removeItem('candidato_email');
            window.location.href = '/carreira/candidato/login';
        }

        carregarCandidaturas();
    </script>
</body>
</html>
