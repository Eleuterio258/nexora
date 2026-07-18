<?php
declare(strict_types=1);

$pageTitle = 'Início';

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

$emProgresso = array_filter($candidaturas, fn($c) => in_array($c['estado'] ?? '', ['em_analise', 'entrevista'], true));
$aprovadas   = array_filter($candidaturas, fn($c) => ($c['estado'] ?? '') === 'aprovada');
$naoLidas    = array_sum(array_column($conversas, 'nao_lidas'));

include dirname(__FILE__) . '/layout_top.php';
?>

<div class="portal-stats">
    <div class="portal-stat">
        <span class="portal-stat-label">Candidaturas</span>
        <span class="portal-stat-value"><?= count($candidaturas) ?></span>
    </div>
    <div class="portal-stat">
        <span class="portal-stat-label">Em progresso</span>
        <span class="portal-stat-value"><?= count($emProgresso) ?></span>
    </div>
    <div class="portal-stat">
        <span class="portal-stat-label">Aprovadas</span>
        <span class="portal-stat-value"><?= count($aprovadas) ?></span>
    </div>
    <div class="portal-stat">
        <span class="portal-stat-label">Mensagens novas</span>
        <span class="portal-stat-value"><?= $naoLidas ?></span>
    </div>
</div>

<div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;align-items:start">

    <div class="portal-card">
        <h3 class="portal-card-title"><i class="fa-solid fa-file-lines" style="color:#059669"></i> Candidaturas recentes</h3>
        <?php if (empty($candidaturas)): ?>
        <div class="portal-empty" style="padding:1.5rem">
            <i class="fa-solid fa-inbox"></i>
            <p style="font-size:.85rem">Ainda não submeteste nenhuma candidatura. <a href="/vagas" style="color:#059669;font-weight:600;">Ver vagas</a></p>
        </div>
        <?php else: ?>
        <div style="display:flex;flex-direction:column">
        <?php foreach (array_slice($candidaturas, 0, 5) as $c): ?>
            <div style="padding:.65rem 0;border-bottom:1px solid #E5E7EB;display:flex;justify-content:space-between;align-items:center;gap:.5rem">
                <div>
                    <div style="font-weight:600;font-size:.85rem;color:#064E3B"><?= htmlspecialchars($c['vaga_titulo'] ?? '') ?></div>
                    <div style="font-size:.75rem;color:#94A3B8;margin-top:.15rem">Submetida em <?= date('d/m/Y', strtotime($c['criado_em'])) ?></div>
                </div>
                <span class="portal-badge <?= $estadoBadge[$c['estado']] ?? 'badge-gray' ?>"><?= htmlspecialchars($c['estado_label'] ?: ($estadoLabels[$c['estado']] ?? $c['estado'])) ?></span>
            </div>
        <?php endforeach; ?>
        </div>
        <div style="margin-top:.75rem;text-align:right">
            <a href="/carreira/candidato/candidaturas" style="font-size:.8rem;color:#059669;text-decoration:none;font-weight:600">Ver todas →</a>
        </div>
        <?php endif; ?>
    </div>

    <div class="portal-card">
        <h3 class="portal-card-title"><i class="fa-solid fa-comments" style="color:#059669"></i> Mensagens recentes</h3>
        <?php if (empty($conversas)): ?>
        <div class="portal-empty" style="padding:1.5rem">
            <i class="fa-solid fa-comment-slash"></i>
            <p style="font-size:.85rem">Sem conversas de momento</p>
        </div>
        <?php else: ?>
        <div style="display:flex;flex-direction:column">
        <?php foreach (array_slice($conversas, 0, 5) as $conv): ?>
            <a href="/carreira/candidato/mensagens?id=<?= (int) $conv['candidatura_id'] ?>" style="text-decoration:none;color:inherit">
            <div style="padding:.65rem 0;border-bottom:1px solid #E5E7EB;display:flex;justify-content:space-between;align-items:center;gap:.5rem">
                <div style="min-width:0">
                    <div style="font-weight:600;font-size:.85rem;color:#064E3B"><?= htmlspecialchars($conv['vaga_titulo'] ?? '') ?></div>
                    <div style="font-size:.77rem;color:#64748B;margin-top:.15rem;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">
                        <?= htmlspecialchars($conv['ultima_mensagem'] ?? 'Sem mensagens') ?>
                    </div>
                </div>
                <?php if (($conv['nao_lidas'] ?? 0) > 0): ?>
                <span class="portal-nav-badge"><?= (int) $conv['nao_lidas'] ?></span>
                <?php endif; ?>
            </div>
            </a>
        <?php endforeach; ?>
        </div>
        <div style="margin-top:.75rem;text-align:right">
            <a href="/carreira/candidato/mensagens" style="font-size:.8rem;color:#059669;text-decoration:none;font-weight:600">Ver todas →</a>
        </div>
        <?php endif; ?>
    </div>

</div>

<?php include dirname(__FILE__) . '/layout_bottom.php'; ?>
