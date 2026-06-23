<?php

    $id = $app->request->queryInt('id', 0);

    $resp = $app->nexora->call('GET', "/api/rh/folhas-pagamento/$id");
    if ($resp['status'] !== 200) {
        header('Location: /nexora/rh/funcionarios#processamento-salarial');
        exit;
    }
    $folha   = $resp['body']['folha'] ?? [];
    $recibos = $resp['body']['recibos'] ?? [];

    $mesesLabels = [
        1 => 'Janeiro', 2 => 'Fevereiro', 3 => 'Março', 4 => 'Abril', 5 => 'Maio', 6 => 'Junho',
        7 => 'Julho', 8 => 'Agosto', 9 => 'Setembro', 10 => 'Outubro', 11 => 'Novembro', 12 => 'Dezembro',
    ];
    $folhaPagamentoEstadoBadges = [
        'aberta'     => ['adm-badge--gray',   'Aberta'],
        'processada' => ['adm-badge--blue',   'Processada'],
        'paga'       => ['adm-badge--green',  'Paga'],
        'cancelada'  => ['adm-badge--red',    'Cancelada'],
    ];
    $reciboEstadoBadges = [
        'pendente' => ['adm-badge--gray',  'Pendente'],
        'pago'     => ['adm-badge--green', 'Pago'],
    ];

    $folhaBadge = $folhaPagamentoEstadoBadges[$folha['estado']] ?? ['adm-badge--gray', $folha['estado']];
    $periodo    = ($mesesLabels[$folha['mes']] ?? (string) $folha['mes']) . ' de ' . (int) $folha['ano'];

    // RNF02 — confidencialidade salarial: valores são devolvidos como null pelo
    // backend quando o utilizador não tem permissão (recursos-humanos, gerir).
    $podeVerSalarios = $app->session->can('recursos-humanos', 'processar_salarios');
    function rhValorSalarial(?float $valor, bool $podeVer): string
    {
        if (!$podeVer) {
            return '<span class="adm-text-muted">Confidencial</span>';
        }
        return $valor !== null ? number_format($valor, 2, ',', '.') : '—';
    }

    $pageTitle  = 'Folha de Pagamento — ' . $periodo;
    $activePage = 'rh_funcionarios';
    $breadcrumb = [['Admin', '/nexora/'], ['Recursos Humanos', ''], ['Funcionários', '/nexora/rh/funcionarios'], ['Folha de Pagamento', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header" style="align-items:flex-start">
    <div style="display:flex;align-items:center;gap:var(--adm-sp-3)">
        <h1 class="adm-page-title" style="margin:0">Folha de Pagamento — <?php echo htmlspecialchars($periodo) ?></h1>
        <span class="adm-badge <?php echo $folhaBadge[0] ?>"><?php echo $folhaBadge[1] ?></span>
    </div>
    <div class="adm-page-header-actions">
        <a href="/nexora/rh/funcionarios#processamento-salarial" class="adm-btn adm-btn-outline adm-btn-sm">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>
            Voltar
        </a>
    </div>
</div>

<div class="adm-stats-grid" style="grid-template-columns:repeat(4,1fr)">
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--blue">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="9" cy="7" r="4"/><path d="M1 21v-2a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v2"/></svg>
        </div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?php echo (int) $folha['num_funcionarios'] ?></div>
            <div class="adm-stat-label">Nº Funcionários</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--green">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
        </div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?php echo rhValorSalarial($folha['total_proventos'] !== null ? (float) $folha['total_proventos'] : null, $podeVerSalarios) ?></div>
            <div class="adm-stat-label">Total Proventos</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--red">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="8" y1="12" x2="16" y2="12"/></svg>
        </div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?php echo rhValorSalarial($folha['total_descontos'] !== null ? (float) $folha['total_descontos'] : null, $podeVerSalarios) ?></div>
            <div class="adm-stat-label">Total Descontos</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--blue">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
        </div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?php echo rhValorSalarial($folha['total_liquido'] !== null ? (float) $folha['total_liquido'] : null, $podeVerSalarios) ?></div>
            <div class="adm-stat-label">Total Líquido</div>
        </div>
    </div>
</div>

<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Informação</h2></div>
    <div class="adm-card-body">
        <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:var(--adm-sp-5)">
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Período</span>
                <span class="adm-detail-pair-value"><?php echo htmlspecialchars($periodo) ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Criada em</span>
                <span class="adm-detail-pair-value"><?php echo date('d/m/Y H:i', strtotime($folha['created_at'])) ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Processada em</span>
                <span class="adm-detail-pair-value"><?php echo $folha['processada_em'] ? date('d/m/Y H:i', strtotime($folha['processada_em'])) : '—' ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Paga em</span>
                <span class="adm-detail-pair-value"><?php echo $folha['paga_em'] ? date('d/m/Y H:i', strtotime($folha['paga_em'])) : '—' ?></span>
            </div>
        </div>
    </div>
</div>

<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Recibos de Vencimento</h2></div>
    <?php if ($recibos): ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr><th>Funcionário</th><th>Nº Funcionário</th><th>Salário Base</th><th>Total Proventos</th><th>Total Descontos</th><th>Salário Líquido</th><th>Estado</th></tr>
            </thead>
            <tbody>
            <?php foreach ($recibos as $rv):
                $rvBadge = $reciboEstadoBadges[$rv['estado']] ?? ['adm-badge--gray', $rv['estado']];
            ?>
            <tr>
                <td class="adm-fw-600"><?php echo htmlspecialchars($rv['nome_completo']) ?></td>
                <td class="adm-text-muted"><?php echo $rv['numero_funcionario'] ? htmlspecialchars($rv['numero_funcionario']) : '—' ?></td>
                <td class="adm-text-muted"><?php echo rhValorSalarial($rv['salario_base'] !== null ? (float) $rv['salario_base'] : null, $podeVerSalarios) ?></td>
                <td class="adm-text-muted"><?php echo rhValorSalarial($rv['total_proventos'] !== null ? (float) $rv['total_proventos'] : null, $podeVerSalarios) ?></td>
                <td class="adm-text-muted"><?php echo rhValorSalarial($rv['total_descontos'] !== null ? (float) $rv['total_descontos'] : null, $podeVerSalarios) ?></td>
                <td class="adm-fw-600"><?php echo rhValorSalarial($rv['salario_liquido'] !== null ? (float) $rv['salario_liquido'] : null, $podeVerSalarios) ?></td>
                <td><span class="adm-badge <?php echo $rvBadge[0] ?>"><?php echo $rvBadge[1] ?></span></td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="adm-empty">
        <p class="adm-empty-title">Esta folha de pagamento ainda não foi processada</p>
        <p class="adm-empty-sub">Os recibos de vencimento são gerados ao processar a folha de pagamento.</p>
    </div>
    <?php endif; ?>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
