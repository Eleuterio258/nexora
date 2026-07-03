<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Área do Candidato | E258Tech</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700;800&family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="/assets/css/styles.css">
    <link rel="stylesheet" href="/assets/css/vagas.css">
</head>
<body>
    <?php include 'src/View/templates/partials/nav.php'; ?>

    <section class="vagas-hero" style="min-height:60vh;">
        <div class="container" style="max-width:600px;">
            <h1 class="vagas-hero-title" style="font-size:2rem;">Área do Candidato</h1>
            <p class="vagas-hero-sub">Entra na tua conta para consultar as tuas candidaturas.</p>

            <div style="margin-top:2rem;background:#fff;padding:1.5rem;border-radius:1rem;box-shadow:0 10px 40px rgba(0,0,0,0.1);">
                <form id="form-login">
                    <div class="form-group">
                        <label for="f-email">Email</label>
                        <input type="email" id="f-email" name="email" required maxlength="255" placeholder="email@exemplo.com">
                    </div>
                    <div class="form-group">
                        <label for="f-password">Palavra-passe</label>
                        <input type="password" id="f-password" name="password" required minlength="6" placeholder="••••••">
                    </div>
                    <button type="submit" class="btn-candidatar" style="width:100%;">Entrar</button>
                </form>

                <div class="form-msg" id="login-msg" style="display:none;margin-top:1rem;"></div>

                <hr style="margin:1.5rem 0;border:0;border-top:1px solid #e5e7eb;">
                <p style="text-align:center;">Ainda não tens conta? <a href="/carreira/candidato/registar" style="color:#2563eb;text-decoration:underline;">Regista-te</a></p>
            </div>

            <div style="margin-top:1.5rem;text-align:center;">
                <a href="/vagas" class="btn-outline">← Voltar às vagas</a>
            </div>
        </div>
    </section>

    <script>
        document.getElementById('form-login').addEventListener('submit', async function(e) {
            e.preventDefault();
            const msg = document.getElementById('login-msg');
            msg.style.display = 'none';

            const body = {
                email: document.getElementById('f-email').value.trim(),
                password: document.getElementById('f-password').value
            };

            try {
                const res = await fetch('/api/public/recrutamento/candidatos/login', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify(body)
                });
                const data = await res.json();

                if (data.id) {
                    localStorage.setItem('candidato_id', data.id);
                    localStorage.setItem('candidato_nome', data.nome);
                    localStorage.setItem('candidato_email', data.email);
                    if (data.telefone) localStorage.setItem('candidato_telefone', data.telefone);

                    // Se veio de uma vaga, voltar para candidatar via conta
                    const params = new URLSearchParams(window.location.search);
                    const returnTo = params.get('returnTo');
                    if (returnTo) {
                        window.location.href = returnTo + '&tipo=conta';
                    } else {
                        window.location.href = '/carreira/candidato/area';
                    }
                } else {
                    msg.className = 'form-msg erro';
                    msg.textContent = data.error || 'Email ou palavra-passe inválidos.';
                    msg.style.display = 'flex';
                }
            } catch {
                msg.className = 'form-msg erro';
                msg.textContent = 'Erro de ligação. Tente novamente.';
                msg.style.display = 'flex';
            }
        });
    </script>
</body>
</html>
