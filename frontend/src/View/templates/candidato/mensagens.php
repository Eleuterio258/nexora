<?php
declare(strict_types=1);

$pageTitle = 'Mensagens';

include dirname(__FILE__) . '/layout_top.php';
?>

<div style="display:grid;grid-template-columns:<?= $conversaActiva ? '300px 1fr' : '1fr' ?>;gap:1rem;align-items:start">

    <div class="portal-card" style="padding:.75rem">
        <h3 class="portal-card-title" style="padding:0 .5rem .6rem">Conversas</h3>
        <?php if (empty($conversas)): ?>
        <div class="portal-empty" style="padding:1.5rem">
            <i class="fa-solid fa-comment-slash"></i>
            <p style="font-size:.85rem">Sem conversas de momento</p>
        </div>
        <?php else: ?>
        <div style="display:flex;flex-direction:column">
        <?php foreach ($conversas as $conv):
            $activa = $conversaActiva && (int) $conversaActiva['candidatura_id'] === (int) $conv['candidatura_id']; ?>
            <a href="/carreira/candidato/mensagens?id=<?= (int) $conv['candidatura_id'] ?>"
               style="text-decoration:none;color:inherit;display:block;padding:.65rem .5rem;border-radius:8px;<?= $activa ? 'background:#D1FAE5' : '' ?>">
                <div style="display:flex;justify-content:space-between;align-items:center;gap:.5rem">
                    <div style="font-weight:600;font-size:.83rem;color:#064E3B;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">
                        <?= htmlspecialchars($conv['vaga_titulo'] ?? '') ?>
                    </div>
                    <?php if (($conv['nao_lidas'] ?? 0) > 0): ?>
                    <span class="portal-nav-badge"><?= (int) $conv['nao_lidas'] ?></span>
                    <?php endif; ?>
                </div>
                <div style="font-size:.75rem;color:#64748B;margin-top:.15rem;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">
                    <?= htmlspecialchars($conv['ultima_mensagem'] ?? 'Sem mensagens') ?>
                </div>
            </a>
        <?php endforeach; ?>
        </div>
        <?php endif; ?>
    </div>

    <?php if ($conversaActiva): ?>
    <div class="portal-card" style="display:flex;flex-direction:column;height:70vh">
        <h3 class="portal-card-title"><?= htmlspecialchars($conversaActiva['vaga_titulo'] ?? '') ?></h3>
        <div id="thread-mensagens" style="flex:1;overflow-y:auto;display:flex;flex-direction:column;gap:.6rem;padding-right:.25rem">
            <?php if (empty($mensagens)): ?>
            <div class="portal-empty" style="padding:1.5rem">
                <i class="fa-solid fa-comments"></i>
                <p style="font-size:.85rem">Ainda não há mensagens nesta candidatura.</p>
            </div>
            <?php else: ?>
            <?php foreach ($mensagens as $m):
                $ehCandidato = ($m['autor'] ?? '') === 'candidato'; ?>
                <div style="align-self:<?= $ehCandidato ? 'flex-end' : 'flex-start' ?>;max-width:75%">
                    <div style="background:<?= $ehCandidato ? '#059669' : '#F1F5F9' ?>;color:<?= $ehCandidato ? '#fff' : '#334155' ?>;
                                padding:.55rem .8rem;border-radius:12px;font-size:.85rem;white-space:pre-wrap">
                        <?= htmlspecialchars($m['conteudo'] ?? '') ?>
                    </div>
                    <div style="font-size:.7rem;color:#94A3B8;margin-top:.2rem;text-align:<?= $ehCandidato ? 'right' : 'left' ?>">
                        <?= date('d/m/Y H:i', strtotime($m['created_at'])) ?>
                    </div>
                </div>
            <?php endforeach; ?>
            <?php endif; ?>
        </div>
        <form id="form-resposta" style="display:flex;gap:.5rem;margin-top:1rem;border-top:1px solid #E5E7EB;padding-top:1rem">
            <input type="hidden" id="f-candidatura-id" value="<?= (int) $conversaActiva['candidatura_id'] ?>">
            <textarea id="f-conteudo" rows="1" placeholder="Escreve uma mensagem..." required
                      style="flex:1;padding:.6rem .75rem;border:1px solid #D1D5DB;border-radius:8px;font-family:inherit;font-size:.85rem;resize:none"></textarea>
            <button type="submit" class="portal-btn"><i class="fa-solid fa-paper-plane"></i></button>
        </form>
    </div>
    <?php endif; ?>

</div>

<?php include dirname(__FILE__) . '/layout_bottom.php'; ?>

<?php if ($conversaActiva): ?>
<script>
(function () {
    const thread = document.getElementById('thread-mensagens');
    thread.scrollTop = thread.scrollHeight;

    document.getElementById('form-resposta').addEventListener('submit', async function (e) {
        e.preventDefault();
        const conteudoEl = document.getElementById('f-conteudo');
        const candidaturaId = document.getElementById('f-candidatura-id').value;
        const conteudo = conteudoEl.value.trim();
        if (!conteudo) return;

        const btn = e.target.querySelector('button');
        btn.disabled = true;
        try {
            const res = await fetch('/carreira/candidato/api/mensagens/' + candidaturaId, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ conteudo }),
            });
            if (!res.ok) throw new Error('Falha ao enviar');
            const nota = await res.json();

            const bubble = document.createElement('div');
            bubble.style.cssText = 'align-self:flex-end;max-width:75%';
            bubble.innerHTML = `
                <div style="background:#059669;color:#fff;padding:.55rem .8rem;border-radius:12px;font-size:.85rem;white-space:pre-wrap"></div>
                <div style="font-size:.7rem;color:#94A3B8;margin-top:.2rem;text-align:right"></div>`;
            bubble.querySelector('div').textContent = nota.conteudo || conteudo;
            bubble.querySelectorAll('div')[1].textContent = new Date(nota.created_at || Date.now()).toLocaleString('pt-PT');
            thread.appendChild(bubble);
            thread.scrollTop = thread.scrollHeight;

            conteudoEl.value = '';
            showToast('Mensagem enviada.');
        } catch {
            showToast('Não foi possível enviar a mensagem.', 'error');
        } finally {
            btn.disabled = false;
        }
    });
})();
</script>
<?php endif; ?>
