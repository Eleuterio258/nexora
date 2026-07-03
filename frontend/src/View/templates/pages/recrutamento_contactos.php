<?php

    $page = max(1, $app->request->queryInt('page', 1));
    $limit = 20;

    $resp = $app->nexora->call('GET', '/api/recrutamento/contactos', null, [
        'page'  => $page,
        'limit' => $limit,
    ]);

    $contactos = [];
    $meta = [];
    if (is_array($resp['body'] ?? null)) {
        $contactos = $resp['body']['data'] ?? $resp['body'] ?? [];
        $meta = $resp['body']['meta'] ?? [];
    }

    $csrf = $app->security->csrfToken();
    $pageTitle  = 'Contactos / Candidaturas Espontâneas';
    $activePage = 'recrutamento_contactos';
    $breadcrumb = [['Admin', '/nexora/'], ['Recrutamento', ''], ['Contactos', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Contactos</h1>
</div>

<div class="adm-card">
    <div class="adm-card-header">
        <div>
            <h2 class="adm-card-title">Mensagens de Contacto</h2>
            <p class="adm-card-subtitle">Candidaturas espontâneas e mensagens enviadas pelo site.</p>
        </div>
    </div>
    <div class="adm-card-body">
        <?php if ($contactos): ?>
        <div class="adm-table-wrap">
            <table class="adm-table" id="contactosTable">
                <thead>
                    <tr>
                        <th style="width:40px"></th>
                        <th>Nome / Email</th>
                        <th>Assunto</th>
                        <th>Data</th>
                        <th>Ações</th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach ($contactos as $c):
                    $lido = !empty($c['lido']);
                ?>
                    <tr data-id="<?= $c['id'] ?>" class="<?= $lido ? '' : 'adm-row-highlight' ?>">
                        <td>
                            <?php if (!$lido): ?>
                            <span class="adm-dot" style="background:var(--adm-green);width:8px;height:8px;border-radius:50%;display:inline-block" title="Não lido"></span>
                            <?php endif; ?>
                        </td>
                        <td>
                            <div class="adm-fw-600"><?= htmlspecialchars($c['nome'] ?? '') ?></div>
                            <div class="adm-text-xs adm-text-muted"><?= htmlspecialchars($c['email'] ?? '') ?></div>
                        </td>
                        <td>
                            <div class="adm-fw-500"><?= htmlspecialchars($c['assunto'] ?? '') ?></div>
                            <div class="adm-text-xs adm-text-muted" style="max-width:320px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">
                                <?= htmlspecialchars(strip_tags($c['mensagem'] ?? '')) ?>
                            </div>
                        </td>
                        <td class="adm-text-sm adm-text-muted">
                            <?= !empty($c['created_at']) ? date('d/m/Y H:i', strtotime($c['created_at'])) : '—' ?>
                        </td>
                        <td>
                            <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" onclick="verContacto(<?= $c['id'] ?>)" title="Ver">
                                <i class="fa-solid fa-eye"></i>
                            </button>
                            <?php if (!$lido): ?>
                            <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" onclick="marcarLido(<?= $c['id'] ?>)" title="Marcar como lido">
                                <i class="fa-solid fa-envelope-open" style="color:var(--adm-green)"></i>
                            </button>
                            <?php endif; ?>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>

        <?php if (!empty($meta['total']) && $meta['total'] > $limit): ?>
        <div class="adm-pagination">
            <?php if ($page > 1): ?>
            <a href="?page=<?= $page - 1 ?>" class="adm-btn adm-btn-outline adm-btn-sm">Anterior</a>
            <?php endif; ?>
            <span class="adm-text-sm adm-text-muted">Página <?= $page ?> de <?= (int) ceil($meta['total'] / $limit) ?></span>
            <?php if ($page * $limit < $meta['total']): ?>
            <a href="?page=<?= $page + 1 ?>" class="adm-btn adm-btn-outline adm-btn-sm">Próxima</a>
            <?php endif; ?>
        </div>
        <?php endif; ?>

        <?php else: ?>
        <div class="adm-empty-state">
            <div class="adm-empty-state-icon"><i class="fa-solid fa-envelope-open"></i></div>
            <p class="adm-empty-state-title">Nenhuma mensagem</p>
            <p class="adm-empty-state-text">As mensagens enviadas pelo formulário de contacto aparecerão aqui.</p>
        </div>
        <?php endif; ?>
    </div>
</div>

<!-- Modal: Ver contacto -->
<div class="adm-modal-overlay" id="contactoModal">
    <div class="adm-modal-content" style="max-width:560px">
        <div class="adm-modal-header">
            <h3 class="adm-modal-title" id="contactoModalTitle">Mensagem</h3>
            <button class="adm-modal-close" onclick="closeContactoModal()" type="button">&times;</button>
        </div>
        <div class="adm-modal-body">
            <div class="adm-detail-grid" style="grid-template-columns:1fr;gap:var(--adm-sp-4)">
                <div class="adm-detail-pair">
                    <span class="adm-detail-pair-label">De</span>
                    <span class="adm-detail-pair-value" id="modalNome"></span>
                </div>
                <div class="adm-detail-pair">
                    <span class="adm-detail-pair-label">Email</span>
                    <span class="adm-detail-pair-value" id="modalEmail"></span>
                </div>
                <div class="adm-detail-pair">
                    <span class="adm-detail-pair-label">Assunto</span>
                    <span class="adm-detail-pair-value" id="modalAssunto"></span>
                </div>
                <div class="adm-detail-pair">
                    <span class="adm-detail-pair-label">Mensagem</span>
                    <span class="adm-detail-pair-value" id="modalMensagem" style="white-space:pre-wrap"></span>
                </div>
                <div class="adm-detail-pair">
                    <span class="adm-detail-pair-label">Recebido em</span>
                    <span class="adm-detail-pair-value" id="modalData"></span>
                </div>
            </div>
        </div>
        <div class="adm-modal-footer">
            <button class="adm-btn adm-btn-outline" type="button" onclick="closeContactoModal()">Fechar</button>
            <button class="adm-btn adm-btn-primary" type="button" id="modalBtnLido" onclick="marcarLidoModal()">Marcar como lido</button>
        </div>
    </div>
</div>

<script>
const CSRF = '<?= $csrf ?>';
const CONTACTOS = <?= json_encode($contactos, JSON_UNESCAPED_UNICODE) ?>;
let contactoAtual = null;

function verContacto(id) {
    const c = CONTACTOS.find(x => x.id == id);
    if (!c) return;
    contactoAtual = c;

    document.getElementById('modalNome').textContent = c.nome || '';
    document.getElementById('modalEmail').textContent = c.email || '';
    document.getElementById('modalAssunto').textContent = c.assunto || '';
    document.getElementById('modalMensagem').textContent = c.mensagem || '';
    document.getElementById('modalData').textContent = c.created_at
        ? new Date(c.created_at).toLocaleString('pt-PT')
        : '—';

    const btn = document.getElementById('modalBtnLido');
    if (c.lido) {
        btn.style.display = 'none';
    } else {
        btn.style.display = '';
    }

    document.getElementById('contactoModal').classList.add('open');
}

function closeContactoModal() {
    document.getElementById('contactoModal').classList.remove('open');
    contactoAtual = null;
}

document.getElementById('contactoModal').addEventListener('click', e => {
    if (e.target === e.currentTarget) closeContactoModal();
});

async function marcarLido(id) {
    await enviarLido(id);
}

async function marcarLidoModal() {
    if (!contactoAtual) return;
    await enviarLido(contactoAtual.id);
}

async function enviarLido(id) {
    try {
        const res = await fetch('/nexora/api/recrutamento_contacto_lido.php', {
            method: 'POST',
            headers: {'Content-Type':'application/json'},
            body: JSON.stringify({id: id, csrf_token: CSRF})
        });
        const data = await res.json();
        if (data.ok) {
            showToast('Mensagem marcada como lida');
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro ao marcar como lido', 'error');
        }
    } catch (err) {
        showToast('Erro de rede', 'error');
    }
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
