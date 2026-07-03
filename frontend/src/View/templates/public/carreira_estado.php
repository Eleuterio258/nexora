<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Estado da Candidatura | E258Tech</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700;800&family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="/assets/css/styles.css">
    <link rel="stylesheet" href="/assets/css/vagas.css">
    <style>
        .estado-timeline { display:flex; justify-content:space-between; position:relative; margin:2rem 0 1.5rem; padding:0; list-style:none; }
        .estado-timeline::before { content:''; position:absolute; top:14px; left:0; right:0; height:4px; background:#e5e7eb; border-radius:2px; z-index:0; }
        .estado-timeline li { position:relative; z-index:1; flex:1; text-align:center; }
        .estado-timeline .dot { width:32px; height:32px; border-radius:50%; background:#fff; border:4px solid #e5e7eb; margin:0 auto 0.5rem; display:flex; align-items:center; justify-content:center; font-size:0.75rem; font-weight:700; color:#9ca3af; transition:all .3s ease; }
        .estado-timeline .label { font-size:0.8rem; color:#6b7280; font-weight:500; }
        .estado-timeline li.done .dot { background:#10b981; border-color:#10b981; color:#fff; }
        .estado-timeline li.done .label { color:#047857; }
        .estado-timeline li.active .dot { background:#fff; border-color:#10b981; color:#10b981; box-shadow:0 0 0 4px rgba(16,185,129,.15); }
        .estado-timeline li.active .label { color:#047857; font-weight:700; }
        .estado-timeline li.rejected .dot { background:#ef4444; border-color:#ef4444; color:#fff; }
        .estado-timeline li.rejected .label { color:#b91c1c; }
        .estado-card { background:#fff; padding:1.5rem; border-radius:1rem; box-shadow:0 10px 40px rgba(0,0,0,0.08); margin-top:1.5rem; }
        .estado-card h2 { font-size:1.25rem; margin-bottom:1rem; color:#111827; }
        .estado-info { display:grid; gap:0.75rem; }
        .estado-info-row { display:flex; justify-content:space-between; padding-bottom:0.75rem; border-bottom:1px solid #f3f4f6; }
        .estado-info-row:last-child { border-bottom:none; padding-bottom:0; }
        .estado-info-label { color:#6b7280; font-size:0.9rem; }
        .estado-info-value { color:#111827; font-weight:600; text-align:right; }
        .estado-badge { display:inline-block; padding:0.35rem 0.85rem; border-radius:999px; font-size:0.85rem; font-weight:700; }
        .estado-badge--recebida { background:#fef3c7; color:#92400e; }
        .estado-badge--em_analise { background:#dbeafe; color:#1e40af; }
        .estado-badge--entrevista { background:#e0e7ff; color:#3730a3; }
        .estado-badge--aprovada { background:#d1fae5; color:#065f46; }
        .estado-badge--rejeitada { background:#fee2e2; color:#991b1b; }
        .estado-historico { margin-top:1.5rem; }
        .estado-historico h3 { font-size:1rem; margin-bottom:0.75rem; color:#111827; }
        .estado-historico ul { list-style:none; padding:0; }
        .estado-historico li { padding:0.75rem 0; border-bottom:1px solid #f3f4f6; }
        .estado-historico li:last-child { border-bottom:none; }
        .estado-historico time { display:block; font-size:0.75rem; color:#6b7280; margin-bottom:0.25rem; }
        .estado-entrevista { background:#f0fdf4; border-left:4px solid #10b981; padding:1rem; border-radius:0.5rem; margin-top:1rem; }
        .estado-entrevista h3 { font-size:1rem; margin-bottom:0.5rem; color:#065f46; }
        @media (max-width:640px) {
            .estado-timeline .label { font-size:0.7rem; }
            .estado-timeline .dot { width:28px; height:28px; }
            .estado-info-row { flex-direction:column; gap:0.25rem; }
            .estado-info-value { text-align:left; }
        }
    </style>
</head>
<body>
    <?php include 'src/View/templates/partials/nav.php'; ?>

    <section class="vagas-hero" style="min-height:40vh;">
        <div class="container" style="max-width:720px;">
            <h1 class="vagas-hero-title" style="font-size:2rem;">Estado da Candidatura</h1>
            <p class="vagas-hero-sub">Introduz o código de acompanhamento para consultar o estado.</p>

            <form id="form-estado" style="margin-top:2rem;background:#fff;padding:1.5rem;border-radius:1rem;box-shadow:0 10px 40px rgba(0,0,0,0.1);">
                <div class="form-group">
                    <label for="f-codigo">Código de acompanhamento</label>
                    <input type="text" id="f-codigo" name="codigo" maxlength="20" placeholder="Ex: ABC123XYZ" style="text-transform:uppercase;" required value="<?php echo htmlspecialchars($_GET['codigo'] ?? '') ?>">
                </div>
                <button type="submit" class="btn-candidatar" style="width:100%;">Consultar</button>
            </form>

            <div class="form-msg" id="estado-msg" style="display:none;margin-top:1rem;"></div>
            <div id="estado-resultado" style="display:none;"></div>

            <div style="margin-top:2rem;text-align:center;">
                <a href="/vagas" class="btn-outline">← Voltar às vagas</a>
            </div>
        </div>
    </section>

    <script>
        const estadoLabels = {
            'recebida': 'Recebida',
            'em_analise': 'Em análise',
            'entrevista': 'Entrevista',
            'aprovada': 'Aprovada',
            'rejeitada': 'Não selecionada'
        };
        const estadoClasses = {
            'recebida': 'estado-badge--recebida',
            'em_analise': 'estado-badge--em_analise',
            'entrevista': 'estado-badge--entrevista',
            'aprovada': 'estado-badge--aprovada',
            'rejeitada': 'estado-badge--rejeitada'
        };
        const fases = ['recebida', 'em_analise', 'entrevista'];
        const fasesFinais = ['aprovada', 'rejeitada'];

        function renderTimeline(estado) {
            const isFinal = fasesFinais.includes(estado);
            const activeFinal = isFinal ? estado : null;
            const currentIndex = fases.indexOf(estado);

            let html = '<ul class="estado-timeline">';

            fases.forEach((f, i) => {
                const done = isFinal || i < currentIndex;
                const active = !isFinal && i === currentIndex;
                html += `<li class="${done ? 'done' : ''} ${active ? 'active' : ''}">`;
                html += `<div class="dot">${done ? '✓' : i + 1}</div>`;
                html += `<div class="label">${estadoLabels[f]}</div>`;
                html += '</li>';
            });

            html += `<li class="${activeFinal === 'aprovada' ? 'active' : ''} ${activeFinal === 'rejeitada' ? 'rejected' : ''}">`;
            html += `<div class="dot">${activeFinal === 'aprovada' ? '✓' : activeFinal === 'rejeitada' ? '×' : '4'}</div>`;
            html += `<div class="label">${activeFinal ? estadoLabels[activeFinal] : 'Decisão final'}</div>`;
            html += '</li>';

            html += '</ul>';
            return html;
        }

        function renderResultado(data) {
            const c = data.candidatura;
            const estado = c.estado;

            let html = renderTimeline(estado);
            html += '<div class="estado-card">';
            html += `<h2>${c.vaga_titulo || 'Candidatura'}</h2>`;
            html += '<div class="estado-info">';
            html += `<div class="estado-info-row"><span class="estado-info-label">Estado</span><span class="estado-info-value"><span class="estado-badge ${estadoClasses[estado] || ''}">${estadoLabels[estado] || estado}</span></span></div>`;
            html += `<div class="estado-info-row"><span class="estado-info-label">Candidato</span><span class="estado-info-value">${c.nome || '—'}</span></div>`;
            html += `<div class="estado-info-row"><span class="estado-info-label">Código</span><span class="estado-info-value" style="font-family:monospace">${c.codigo_acompanhamento || '—'}</span></div>`;
            html += `<div class="estado-info-row"><span class="estado-info-label">Submetido em</span><span class="estado-info-value">${new Date(c.created_at).toLocaleString('pt-PT')}</span></div>`;
            html += '</div>';

            if (c.entrevista_data) {
                html += '<div class="estado-entrevista">';
                html += '<h3>Entrevista agendada</h3>';
                html += `<p><strong>Data e hora:</strong> ${new Date(c.entrevista_data).toLocaleString('pt-PT')}</p>`;
                if (c.entrevista_local) html += `<p><strong>Local:</strong> ${c.entrevista_local}</p>`;
                if (c.entrevista_link) html += `<p><a href="${c.entrevista_link}" target="_blank" rel="noopener" style="color:#047857;font-weight:600;">Aceder ao link da entrevista →</a></p>`;
                html += '</div>';
            }

            html += '</div>';

            if (data.historico && data.historico.length > 0) {
                html += '<div class="estado-card estado-historico">';
                html += '<h3>Histórico</h3>';
                html += '<ul>';
                data.historico.forEach(h => {
                    html += `<li><time>${new Date(h.created_at).toLocaleString('pt-PT')}</time><div>${h.conteudo}</div></li>`;
                });
                html += '</ul>';
                html += '</div>';
            }

            return html;
        }

        document.getElementById('form-estado').addEventListener('submit', async function(e) {
            e.preventDefault();
            const codigo = document.getElementById('f-codigo').value.trim().toUpperCase();
            const msg = document.getElementById('estado-msg');
            const resultado = document.getElementById('estado-resultado');
            msg.style.display = 'none';
            resultado.style.display = 'none';
            resultado.innerHTML = '';

            if (!codigo) return;

            try {
                const res = await fetch('/api/public/recrutamento/candidaturas/' + encodeURIComponent(codigo));
                const data = await res.json();

                if (data.candidatura) {
                    resultado.innerHTML = renderResultado(data);
                    resultado.style.display = 'block';
                } else {
                    msg.className = 'form-msg erro';
                    msg.textContent = data.error || 'Candidatura não encontrada.';
                    msg.style.display = 'flex';
                }
            } catch {
                msg.className = 'form-msg erro';
                msg.textContent = 'Erro de ligação. Tente novamente.';
                msg.style.display = 'flex';
            }
        });

        const codigoInicial = document.getElementById('f-codigo').value;
        if (codigoInicial) {
            document.getElementById('form-estado').dispatchEvent(new Event('submit'));
        }
    </script>
</body>
</html>
