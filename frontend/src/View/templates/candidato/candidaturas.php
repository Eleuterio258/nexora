<?php
declare(strict_types=1);

$pageTitle = 'Minhas Candidaturas';

$estadoLabels = [
    'recebida'   => 'Recebida',
    'em_analise' => 'Em análise',
    'entrevista' => 'Entrevista agendada',
    'aprovada'   => 'Aprovada',
    'rejeitada'  => 'Não seleccionada',
];
$estadoBadge = [
    'recebida'   => 'badge-gray',
    'em_analise' => 'badge-blue',
    'entrevista' => 'badge-purple',
    'aprovada'   => 'badge-green',
    'rejeitada'  => 'badge-red',
];

include dirname(__FILE__) . '/layout_top.php';
?>

<div class="portal-card">
    <?php if (empty($candidaturas)): ?>
    <div class="portal-empty">
        <i class="fa-solid fa-inbox"></i>
        <p>Ainda não submeteste nenhuma candidatura.</p>
        <a href="/vagas" class="portal-btn-outline" style="margin-top:.5rem">Ver vagas abertas</a>
    </div>
    <?php else: ?>
    <div style="display:grid;gap:1rem">
    <?php foreach ($candidaturas as $c): ?>
        <div style="border:1px solid #E5E7EB;border-radius:10px;padding:1rem">
            <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:.5rem">
                <strong style="color:#064E3B"><?= htmlspecialchars($c['vaga_titulo'] ?? '') ?></strong>
                <span class="portal-badge <?= $estadoBadge[$c['estado']] ?? 'badge-gray' ?>">
                    <?= htmlspecialchars($c['estado_label'] ?: ($estadoLabels[$c['estado']] ?? $c['estado'])) ?>
                </span>
            </div>
            <p style="margin:.5rem 0 0;color:#64748B;font-size:.85rem">
                Código: <?= htmlspecialchars($c['codigo_acompanhamento'] ?? '—') ?>
                · Submetida em <?= !empty($c['criado_em']) ? date('d/m/Y', strtotime($c['criado_em'])) : '—' ?>
            </p>
            <?php if (!empty($c['entrevista_data'])): ?>
            <div style="margin-top:.65rem;padding:.65rem .85rem;background:#F0FDF4;border-left:3px solid #059669;border-radius:6px;font-size:.85rem">
                <i class="fa-solid fa-calendar-check" style="color:#059669"></i>
                Entrevista: <?= date('d/m/Y H:i', strtotime($c['entrevista_data'])) ?>
                <?php if (!empty($c['entrevista_local'])): ?> · <?= htmlspecialchars($c['entrevista_local']) ?><?php endif; ?>
                <?php if (!empty($c['entrevista_link'])): ?>
                · <a href="<?= htmlspecialchars($c['entrevista_link']) ?>" target="_blank" rel="noopener" style="color:#047857;font-weight:600">Aceder ao link →</a>
                <?php endif; ?>
            </div>
            <?php endif; ?>
            <div style="margin-top:.65rem">
                <a href="/carreira/candidato/mensagens?id=<?= (int) $c['id'] ?>" style="font-size:.8rem;color:#059669;text-decoration:none;font-weight:600">
                    <i class="fa-solid fa-comments"></i> Ver conversa
                </a>
            </div>
        </div>
    <?php endforeach; ?>
    </div>
    <?php endif; ?>
</div>

<?php include dirname(__FILE__) . '/layout_bottom.php'; ?>
