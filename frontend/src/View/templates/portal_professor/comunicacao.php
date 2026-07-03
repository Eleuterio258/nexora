<?php
$pageTitle  = 'Comunicação';
$activePage = 'comunicacao';
$msgs       = $portalData['comunicacao']['body']['data'] ?? $portalData['comunicacao']['body'] ?? [];

require __DIR__ . '/layout_top.php';
?>

<div class="portal-card">
    <p class="portal-card-title"><i class="fa-solid fa-envelope" style="color:var(--prof-primary)"></i> Mensagens Recebidas</p>

    <?php if (empty($msgs)): ?>
    <div class="portal-empty">
        <i class="fa-solid fa-envelope-open"></i>
        Não tem mensagens de momento.
    </div>
    <?php else: ?>
    <div style="display:flex;flex-direction:column;gap:.75rem">
    <?php foreach ($msgs as $msg):
        $lida    = !empty($msg['lida']);
        $data    = $msg['data'] ?? $msg['created_at'] ?? '';
        $dataTxt = $data ? date('d/m/Y H:i', strtotime($data)) : '—';
    ?>
    <div style="border:1px solid <?= $lida ? '#E2E8F0' : 'var(--prof-primary)' ?>;border-radius:10px;padding:1rem;background:<?= $lida ? '#fff' : '#F0FDF4' ?>">
        <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:.4rem">
            <span style="font-weight:700;font-size:.9rem;color:#1E293B"><?= htmlspecialchars($msg['assunto'] ?? $msg['titulo'] ?? 'Sem assunto') ?></span>
            <div style="display:flex;align-items:center;gap:.5rem">
                <?php if (!$lida): ?>
                <span class="portal-badge badge-green">Nova</span>
                <?php endif; ?>
                <span style="font-size:.75rem;color:#94A3B8"><?= htmlspecialchars($dataTxt) ?></span>
            </div>
        </div>
        <div style="font-size:.82rem;color:#64748B;margin-bottom:.4rem">
            De: <strong><?= htmlspecialchars($msg['remetente'] ?? $msg['de'] ?? '—') ?></strong>
        </div>
        <div style="font-size:.85rem;color:#334155;white-space:pre-line"><?= nl2br(htmlspecialchars($msg['corpo'] ?? $msg['mensagem'] ?? '')) ?></div>
    </div>
    <?php endforeach; ?>
    </div>
    <?php endif; ?>
</div>

<?php require __DIR__ . '/layout_bottom.php'; ?>
