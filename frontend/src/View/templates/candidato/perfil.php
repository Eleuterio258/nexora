<?php
declare(strict_types=1);

$pageTitle = 'Meu Perfil';

include dirname(__FILE__) . '/layout_top.php';
?>

<div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;align-items:start">

    <div class="portal-card">
        <h3 class="portal-card-title"><i class="fa-solid fa-id-card" style="color:#059669"></i> Dados pessoais</h3>
        <form id="form-dados">
            <div class="portal-form-group">
                <label for="f-nome">Nome</label>
                <input type="text" id="f-nome" value="<?= htmlspecialchars($perfil['nome'] ?? '') ?>" required minlength="2">
            </div>
            <div class="portal-form-group">
                <label>Email</label>
                <input type="email" value="<?= htmlspecialchars($perfil['email'] ?? '') ?>" disabled style="background:#F8FAFC;color:#94A3B8">
            </div>
            <div class="portal-form-group">
                <label for="f-telefone">Telefone</label>
                <input type="text" id="f-telefone" value="<?= htmlspecialchars($perfil['telefone'] ?? '') ?>">
            </div>
            <button type="submit" class="portal-btn">Guardar alterações</button>
        </form>
    </div>

    <div class="portal-card">
        <h3 class="portal-card-title"><i class="fa-solid fa-lock" style="color:#059669"></i> Alterar palavra-passe</h3>
        <form id="form-password">
            <div class="portal-form-group">
                <label for="f-pass-actual">Palavra-passe actual</label>
                <input type="password" id="f-pass-actual" required>
            </div>
            <div class="portal-form-group">
                <label for="f-pass-nova">Nova palavra-passe</label>
                <input type="password" id="f-pass-nova" required minlength="6">
            </div>
            <div class="portal-form-group">
                <label for="f-pass-confirmar">Confirmar nova palavra-passe</label>
                <input type="password" id="f-pass-confirmar" required minlength="6">
            </div>
            <button type="submit" class="portal-btn">Alterar palavra-passe</button>
        </form>
    </div>

</div>

<?php include dirname(__FILE__) . '/layout_bottom.php'; ?>

<script>
async function actualizarPerfil(payload) {
    const res = await fetch('/carreira/candidato/api/perfil', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
    });
    if (!res.ok) {
        let erro = 'Erro ao actualizar.';
        try { const data = await res.json(); erro = data.erro || data.error || erro; } catch {}
        throw new Error(erro);
    }
}

document.getElementById('form-dados').addEventListener('submit', async function (e) {
    e.preventDefault();
    const btn = e.target.querySelector('button');
    btn.disabled = true;
    try {
        await actualizarPerfil({
            nome: document.getElementById('f-nome').value.trim(),
            telefone: document.getElementById('f-telefone').value.trim() || null,
        });
        showToast('Dados actualizados com sucesso.');
    } catch (err) {
        showToast(err.message, 'error');
    } finally {
        btn.disabled = false;
    }
});

document.getElementById('form-password').addEventListener('submit', async function (e) {
    e.preventDefault();
    const nova = document.getElementById('f-pass-nova').value;
    const confirmar = document.getElementById('f-pass-confirmar').value;
    if (nova !== confirmar) {
        showToast('As palavras-passe não coincidem.', 'error');
        return;
    }
    const btn = e.target.querySelector('button');
    btn.disabled = true;
    try {
        await actualizarPerfil({
            password_atual: document.getElementById('f-pass-actual').value,
            password_nova: nova,
        });
        showToast('Palavra-passe alterada com sucesso.');
        e.target.reset();
    } catch (err) {
        showToast(err.message, 'error');
    } finally {
        btn.disabled = false;
    }
});
</script>
