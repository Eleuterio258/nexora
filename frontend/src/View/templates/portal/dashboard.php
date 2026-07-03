<?php
declare(strict_types=1);

$pageTitle  = 'Início';
$activePage = 'dashboard';

$me         = $portalData['me']['body'] ?? [];
$cobrancas  = $portalData['cobrancas']['body'] ?? [];
$mensagens  = $portalData['mensagens']['body'] ?? [];
$eventos    = $portalData['eventos']['body'] ?? [];

$alunoInfo  = $me;
$matricula  = $me['matricula_activa'] ?? null;

$pendentes  = array_filter($cobrancas, fn($c) => in_array($c['status'] ?? '', ['emitida', 'vencida'], true));
$vencidas   = array_filter($cobrancas, fn($c) => ($c['status'] ?? '') === 'vencida');

include dirname(__FILE__) . '/layout_top.php';
?>

<!-- Stats rápidas -->
<div class="portal-stats">
    <div class="portal-stat">
        <span class="portal-stat-label">Turma</span>
        <span class="portal-stat-value" style="font-size:1.1rem"><?= htmlspecialchars($matricula['turma'] ?? '—') ?></span>
        <span class="portal-stat-sub"><?= htmlspecialchars($matricula['ano_lectivo'] ?? '') ?></span>
    </div>
    <div class="portal-stat">
        <span class="portal-stat-label">Propinas em aberto</span>
        <span class="portal-stat-value"><?= count($pendentes) ?></span>
        <?php if (count($vencidas) > 0): ?>
        <span class="portal-stat-sub" style="color:#DC2626"><?= count($vencidas) ?> vencida(s)</span>
        <?php endif; ?>
    </div>
    <div class="portal-stat">
        <span class="portal-stat-label">Avisos novos</span>
        <span class="portal-stat-value"><?= count($mensagens) ?></span>
    </div>
    <div class="portal-stat">
        <span class="portal-stat-label">Próximos eventos</span>
        <span class="portal-stat-value"><?= count($eventos) ?></span>
    </div>
</div>

<div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;align-items:start">

    <!-- Propinas em aberto -->
    <div class="portal-card">
        <h3 class="portal-card-title"><i class="fa-solid fa-file-invoice-dollar" style="color:#0EA5E9"></i> Propinas pendentes</h3>
        <?php if (empty($pendentes)): ?>
        <div class="portal-empty" style="padding:1.5rem">
            <i class="fa-solid fa-circle-check" style="color:#22C55E;font-size:1.75rem;margin-bottom:.5rem"></i>
            <p style="font-size:.85rem">Sem propinas em aberto</p>
        </div>
        <?php else: ?>
        <table class="portal-table">
            <thead><tr><th>Descrição</th><th>Valor</th><th>Vencimento</th><th>Estado</th></tr></thead>
            <tbody>
            <?php foreach (array_slice($pendentes, 0, 5) as $c): ?>
            <tr>
                <td><?= htmlspecialchars($c['descricao'] ?? 'Propina') ?></td>
                <td style="font-weight:600"><?= number_format((float)($c['valor'] ?? 0), 2, ',', '.') ?> MT</td>
                <td><?= $c['due_date'] ? date('d/m/Y', strtotime($c['due_date'])) : '—' ?></td>
                <td>
                    <?php if (($c['status'] ?? '') === 'vencida'): ?>
                    <span class="portal-badge badge-red">Vencida</span>
                    <?php else: ?>
                    <span class="portal-badge badge-yellow">Pendente</span>
                    <?php endif; ?>
                </td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
        <div style="margin-top:.75rem;text-align:right">
            <a href="/portal/aluno/cobrancas" style="font-size:.8rem;color:#0EA5E9;text-decoration:none;font-weight:600">Ver todas →</a>
        </div>
        <?php endif; ?>
    </div>

    <!-- Avisos recentes -->
    <div class="portal-card">
        <h3 class="portal-card-title"><i class="fa-solid fa-bell" style="color:#0EA5E9"></i> Últimos avisos</h3>
        <?php if (empty($mensagens)): ?>
        <div class="portal-empty" style="padding:1.5rem">
            <i class="fa-solid fa-inbox" style="font-size:1.75rem;margin-bottom:.5rem"></i>
            <p style="font-size:.85rem">Sem avisos de momento</p>
        </div>
        <?php else: ?>
        <div style="display:flex;flex-direction:column;gap:.6rem">
        <?php foreach (array_slice($mensagens, 0, 4) as $m): ?>
            <div style="padding:.65rem .75rem;background:#F8FAFC;border-radius:8px;border-left:3px solid #0EA5E9">
                <div style="font-weight:600;font-size:.85rem;color:#0C4A6E"><?= htmlspecialchars($m['titulo'] ?? '') ?></div>
                <div style="font-size:.77rem;color:#64748B;margin-top:.2rem">
                    <?= $m['publicado_em'] ? date('d/m/Y', strtotime($m['publicado_em'])) : '' ?>
                    <?php if (!empty($m['audience_type']) && $m['audience_type'] !== 'todos'): ?>
                    · <span style="color:#0EA5E9">Para a sua turma</span>
                    <?php endif; ?>
                </div>
            </div>
        <?php endforeach; ?>
        </div>
        <div style="margin-top:.75rem;text-align:right">
            <a href="/portal/aluno/mensagens" style="font-size:.8rem;color:#0EA5E9;text-decoration:none;font-weight:600">Ver todos →</a>
        </div>
        <?php endif; ?>
    </div>

    <!-- Próximos eventos -->
    <?php if (!empty($eventos)): ?>
    <div class="portal-card" style="grid-column:1/-1">
        <h3 class="portal-card-title"><i class="fa-solid fa-calendar-days" style="color:#0EA5E9"></i> Próximos eventos</h3>
        <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:.75rem">
        <?php foreach (array_slice($eventos, 0, 6) as $ev): ?>
            <div style="padding:.75rem;border-radius:10px;border:1px solid #E0F2FE;background:#F8FAFC">
                <div style="font-size:.75rem;font-weight:700;color:<?= htmlspecialchars($ev['cor'] ?? '#0EA5E9') ?>;margin-bottom:.25rem">
                    <?= htmlspecialchars($ev['tipo'] ?? '') ?>
                </div>
                <div style="font-weight:600;font-size:.875rem;color:#0C4A6E"><?= htmlspecialchars($ev['titulo'] ?? '') ?></div>
                <div style="font-size:.77rem;color:#64748B;margin-top:.25rem">
                    <?= $ev['data_inicio'] ? date('d/m/Y', strtotime($ev['data_inicio'])) : '' ?>
                </div>
            </div>
        <?php endforeach; ?>
        </div>
    </div>
    <?php endif; ?>

</div>

<?php include dirname(__FILE__) . '/layout_bottom.php'; ?>
