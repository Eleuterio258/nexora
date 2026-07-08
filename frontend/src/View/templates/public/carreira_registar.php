<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Registo de Candidato | E258Tech</title>
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
            <h1 class="vagas-hero-title" style="font-size:2rem;">Criar Conta</h1>
            <p class="vagas-hero-sub">Regista-te para gerir as tuas candidaturas.</p>

            <div style="margin-top:2rem;background:#fff;padding:1.5rem;border-radius:1rem;box-shadow:0 10px 40px rgba(0,0,0,0.1);">
                <form id="form-registar">
                    <div class="form-group">
                        <label for="f-nome">Nome completo <span class="req-star">*</span></label>
                        <input type="text" id="f-nome" name="nome" required maxlength="150" placeholder="O seu nome">
                    </div>
                    <div class="form-group">
                        <label for="f-email">Email <span class="req-star">*</span></label>
                        <input type="email" id="f-email" name="email" required maxlength="255" placeholder="email@exemplo.com">
                    </div>
                    <div class="form-group">
                        <label for="f-telefone">Telefone</label>
                        <input type="tel" id="f-telefone" name="telefone" maxlength="30" placeholder="+258 84 000 0000">
                    </div>
                    <div class="form-group">
                        <label for="f-password">Palavra-passe <span class="req-star">*</span></label>
                        <input type="password" id="f-password" name="password" required minlength="6" placeholder="Mínimo 6 caracteres">
                    </div>
                    <button type="submit" class="btn-candidatar" style="width:100%;">Criar conta</button>
                </form>

                <div class="form-msg" id="registar-msg" style="display:none;margin-top:1rem;"></div>

                <hr style="margin:1.5rem 0;border:0;border-top:1px solid #e5e7eb;">
                <p style="text-align:center;">Já tens conta? <a href="<?= htmlspecialchars($app->candidatoRoutes->loginUrl()) ?>" style="color:#2563eb;text-decoration:underline;">Entrar</a></p>
            </div>

            <div style="margin-top:1.5rem;text-align:center;">
                <a href="/vagas" class="btn-outline">← Voltar às vagas</a>
            </div>
        </div>
    </section>

    <script>
        document.getElementById('form-registar').addEventListener('submit', async function(e) {
            e.preventDefault();
            const msg = document.getElementById('registar-msg');
            msg.style.display = 'none';

            const body = {
                nome: document.getElementById('f-nome').value.trim(),
                email: document.getElementById('f-email').value.trim(),
                telefone: document.getElementById('f-telefone').value.trim(),
                password: document.getElementById('f-password').value
            };

            try {
                const res = await fetch('/api/public/recrutamento/candidatos/registar', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify(body)
                });
                const data = await res.json();

                if (data.id) {
                    msg.className = 'form-msg sucesso';
                    msg.textContent = 'Conta criada com sucesso! Redirecionando...';
                    msg.style.display = 'flex';
                    setTimeout(() => window.location.href = <?= json_encode($app->candidatoRoutes->loginUrl(), JSON_UNESCAPED_UNICODE) ?>, 1500);
                } else {
                    msg.className = 'form-msg erro';
                    msg.textContent = data.error || 'Erro ao criar conta.';
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
