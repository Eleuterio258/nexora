<?php
$pageTitle  = 'Alterar Senha';
$activePage = 'conta';

require __DIR__ . '/layout_top.php';
?>

<div class="portal-card" style="max-width:500px">
    <p class="portal-card-title"><i class="fa-solid fa-key" style="color:var(--prof-primary)"></i> Alterar Senha</p>

    <div id="msg-resultado" style="display:none;margin-bottom:1rem;padding:.75rem 1rem;border-radius:8px;font-size:.88rem;font-weight:600"></div>

    <form id="form-senha" style="display:flex;flex-direction:column;gap:1rem">
        <div>
            <label style="display:block;font-size:.8rem;font-weight:600;color:#475569;margin-bottom:.3rem">Senha Actual</label>
            <input type="password" id="senha-actual" required
                style="width:100%;padding:.55rem .75rem;border:1px solid #E2E8F0;border-radius:8px;font-size:.9rem">
        </div>
        <div>
            <label style="display:block;font-size:.8rem;font-weight:600;color:#475569;margin-bottom:.3rem">Nova Senha</label>
            <input type="password" id="senha-nova" required minlength="6"
                style="width:100%;padding:.55rem .75rem;border:1px solid #E2E8F0;border-radius:8px;font-size:.9rem">
        </div>
        <div>
            <label style="display:block;font-size:.8rem;font-weight:600;color:#475569;margin-bottom:.3rem">Confirmar Nova Senha</label>
            <input type="password" id="senha-confirmar" required
                style="width:100%;padding:.55rem .75rem;border:1px solid #E2E8F0;border-radius:8px;font-size:.9rem">
        </div>
        <div>
            <button type="submit" class="btn-primary" id="btn-alterar">
                <i class="fa-solid fa-floppy-disk"></i> Alterar Senha
            </button>
        </div>
    </form>
</div>

<script>
document.getElementById('form-senha').addEventListener('submit', async e => {
    e.preventDefault();
    const actual    = document.getElementById('senha-actual').value;
    const nova      = document.getElementById('senha-nova').value;
    const confirmar = document.getElementById('senha-confirmar').value;
    const msg       = document.getElementById('msg-resultado');

    if (nova !== confirmar) {
        msg.style.display = 'block';
        msg.style.background = '#FEE2E2'; msg.style.color = '#B91C1C';
        msg.textContent = 'As novas senhas não coincidem.';
        return;
    }
    if (nova.length < 6) {
        msg.style.display = 'block';
        msg.style.background = '#FEE2E2'; msg.style.color = '#B91C1C';
        msg.textContent = 'A nova senha deve ter pelo menos 6 caracteres.';
        return;
    }

    const btn = document.getElementById('btn-alterar');
    btn.disabled = true;
    btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> A processar…';

    const resp = await fetch('/portal/professor/api/alterar-senha', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ password_actual: actual, password: nova })
    });
    const json = await resp.json();

    msg.style.display = 'block';
    if (resp.ok) {
        msg.style.background = '#D1FAE5'; msg.style.color = '#065F46';
        msg.textContent = 'Senha alterada com sucesso.';
        document.getElementById('form-senha').reset();
    } else {
        msg.style.background = '#FEE2E2'; msg.style.color = '#B91C1C';
        msg.textContent = json.erro ?? json.message ?? 'Não foi possível alterar a senha.';
    }
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Alterar Senha';
});
</script>

<?php require __DIR__ . '/layout_bottom.php'; ?>
