<?php
declare(strict_types=1);

$pageTitle  = 'Minha Conta';
$activePage = 'conta';

$me        = $portalData['me']['body'] ?? [];
$alunoInfo = $me;
$erro      = null;
$ok        = false;

include dirname(__FILE__) . '/layout_top.php';
?>

<div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;align-items:start;max-width:800px">

    <!-- Dados pessoais (read-only) -->
    <div class="portal-card">
        <h3 class="portal-card-title"><i class="fa-solid fa-user" style="color:#0EA5E9"></i> Dados pessoais</h3>
        <div style="display:flex;flex-direction:column;gap:.65rem;font-size:.875rem">
            <?php
            $campos = [
                'Nome'          => $me['nome'] ?? '',
                'Código'        => $me['codigo'] ?? '',
                'Email'         => $me['email'] ?? '',
                'Telefone'      => $me['telefone'] ?? '',
                'Data nasc.'    => !empty($me['data_nascimento']) ? date('d/m/Y', strtotime($me['data_nascimento'])) : '',
                'Nº documento'  => $me['documento_numero'] ?? '',
                'NUIT'          => $me['nuit'] ?? '',
                'Endereço'      => $me['endereco'] ?? '',
            ];
            foreach ($campos as $label => $val): if (empty($val)) continue; ?>
            <div style="display:flex;gap:.5rem">
                <span style="font-weight:600;color:#334155;min-width:100px"><?= $label ?>:</span>
                <span style="color:#64748B"><?= htmlspecialchars($val) ?></span>
            </div>
            <?php endforeach; ?>
        </div>
    </div>

    <!-- Alterar senha -->
    <div class="portal-card">
        <h3 class="portal-card-title"><i class="fa-solid fa-key" style="color:#0EA5E9"></i> Alterar senha</h3>

        <div id="msgSenha" style="margin-bottom:.75rem"></div>

        <div style="display:flex;flex-direction:column;gap:.75rem">
            <div>
                <label style="display:block;font-size:.8rem;font-weight:600;color:#334155;margin-bottom:.3rem">Senha actual</label>
                <input type="password" id="senhaActual" class="adm-input"
                       style="border:1.5px solid #CBD5E1;border-radius:8px;padding:.6rem .8rem;font-size:.875rem;width:100%;font-family:inherit;outline:none"
                       placeholder="••••••••">
            </div>
            <div>
                <label style="display:block;font-size:.8rem;font-weight:600;color:#334155;margin-bottom:.3rem">Nova senha</label>
                <input type="password" id="novaSenha"
                       style="border:1.5px solid #CBD5E1;border-radius:8px;padding:.6rem .8rem;font-size:.875rem;width:100%;font-family:inherit;outline:none"
                       placeholder="Mínimo 6 caracteres">
            </div>
            <div>
                <label style="display:block;font-size:.8rem;font-weight:600;color:#334155;margin-bottom:.3rem">Confirmar nova senha</label>
                <input type="password" id="confirmarSenha"
                       style="border:1.5px solid #CBD5E1;border-radius:8px;padding:.6rem .8rem;font-size:.875rem;width:100%;font-family:inherit;outline:none"
                       placeholder="••••••••">
            </div>
            <button onclick="alterarSenha()" id="btnAlterarSenha"
                    style="padding:.65rem;border-radius:8px;background:#0369A1;color:#fff;border:none;cursor:pointer;font-weight:600;font-size:.875rem;font-family:inherit">
                <i class="fa-solid fa-check"></i> Actualizar senha
            </button>
        </div>
    </div>

</div>

<script>
async function alterarSenha() {
    const senhaActual   = document.getElementById('senhaActual').value;
    const novaSenha     = document.getElementById('novaSenha').value;
    const confirmarSenha= document.getElementById('confirmarSenha').value;
    const msg = document.getElementById('msgSenha');

    if (!senhaActual || !novaSenha || !confirmarSenha) {
        msg.innerHTML = '<div style="background:#FEE2E2;color:#B91C1C;padding:.5rem .75rem;border-radius:6px;font-size:.82rem">Preencha todos os campos.</div>';
        return;
    }
    if (novaSenha.length < 6) {
        msg.innerHTML = '<div style="background:#FEE2E2;color:#B91C1C;padding:.5rem .75rem;border-radius:6px;font-size:.82rem">A nova senha deve ter pelo menos 6 caracteres.</div>';
        return;
    }
    if (novaSenha !== confirmarSenha) {
        msg.innerHTML = '<div style="background:#FEE2E2;color:#B91C1C;padding:.5rem .75rem;border-radius:6px;font-size:.82rem">As senhas não coincidem.</div>';
        return;
    }

    const btn = document.getElementById('btnAlterarSenha');
    btn.disabled = true; btn.textContent = 'A actualizar...';

    const resp = await fetch('/portal/aluno/api/alterar-senha', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({senha_actual: senhaActual, nova_senha: novaSenha}),
    });
    const data = await resp.json();

    if (data.ok) {
        msg.innerHTML = '<div style="background:#DCFCE7;color:#15803D;padding:.5rem .75rem;border-radius:6px;font-size:.82rem">Senha actualizada com sucesso!</div>';
        document.getElementById('senhaActual').value = '';
        document.getElementById('novaSenha').value = '';
        document.getElementById('confirmarSenha').value = '';
    } else {
        msg.innerHTML = `<div style="background:#FEE2E2;color:#B91C1C;padding:.5rem .75rem;border-radius:6px;font-size:.82rem">${data.erro || data.message || 'Erro ao actualizar.'}</div>`;
    }
    btn.disabled = false; btn.innerHTML = '<i class="fa-solid fa-check"></i> Actualizar senha';
}
</script>

<?php include dirname(__FILE__) . '/layout_bottom.php'; ?>
