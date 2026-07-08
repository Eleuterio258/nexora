<?php

    $idHash = $app->request->queryString('id');
    if (!$idHash) { header('Location: /nexora/rh/processamento-salarial'); exit; }

    $resp = $app->nexora->call('GET', "/api/rh/recibos-vencimento/$idHash");
    if ($resp['status'] !== 200) { header('Location: /nexora/rh/processamento-salarial'); exit; }

    $recibo = $resp['body']['recibo']  ?? [];
    $itens  = $resp['body']['itens']   ?? [];
    $podeVerSalarios = (bool) ($resp['body']['pode_ver_salarios'] ?? false);

    // Dados do funcionário (cargo, NUIT)
    $funcResp = $app->nexora->call('GET', '/api/rh/funcionarios/' . (int) ($recibo['funcionario_id'] ?? 0));
    $func = ($funcResp['status'] === 200) ? $funcResp['body'] : [];

    // Dados da empresa
    $companiesResp = $app->nexora->call('GET', '/api/companies');
    $company = ($companiesResp['body'] ?? [])[0] ?? [];
    $taxResp = !empty($company['id']) ? $app->nexora->call('GET', "/api/companies/{$company['id']}/tax-info") : [];
    $tax = ($taxResp['status'] ?? 0) === 200 ? ($taxResp['body'] ?? []) : [];

    $mesesLabels = [1=>'Janeiro',2=>'Fevereiro',3=>'Março',4=>'Abril',5=>'Maio',6=>'Junho',
                    7=>'Julho',8=>'Agosto',9=>'Setembro',10=>'Outubro',11=>'Novembro',12=>'Dezembro'];
    $periodo = ($mesesLabels[$recibo['mes']] ?? $recibo['mes']) . ' de ' . (int) $recibo['ano'];

    $proventos = array_filter($itens, fn($i) => $i['tipo'] === 'provento');
    $descontos = array_filter($itens, fn($i) => $i['tipo'] === 'desconto');

    $fmt = fn(?float $v) => $podeVerSalarios && $v !== null ? number_format($v, 2, ',', '.') . ' MT' : '—';

    if (($_GET['formato'] ?? '') === 'pdf') {
        $reciboId = $recibo['id'] ?? 0;
        $filename = 'recibo-vencimento-' . $reciboId . '.pdf';

        $cache = $app->nexora->download("/api/rh/recibos-vencimento/$id/pdf");
        if ($cache->status === 200) {
            header('Content-Type: application/pdf');
            header('Content-Disposition: attachment; filename="' . $filename . '"');
            echo $cache->body;
            exit;
        }

        $tipoLabels = ['efetivo'=>'Efetivo','indeterminado'=>'Indeterminado','termo_certo'=>'Termo Certo','termo_incerto'=>'Termo Incerto','estagio'=>'Estágio','prestacao_servico'=>'Prestação de Serviço'];

        $pdf = (new \E258Tech\Infrastructure\Pdf\ReciboPdfBuilder())->build([
            'empresaNome'   => $company['nome'] ?? 'Empresa',
            'empresaNuit'   => $tax['nuit'] ?? null,
            'empresaMorada' => $company['morada'] ?? null,
            'periodo'       => $periodo,
            'reciboId'      => $reciboId,
            'estado'        => $recibo['estado'] ?? '',
            'funcionario'   => [
                'nomeCompleto'      => $recibo['nome_completo'] ?? null,
                'numeroFuncionario' => $recibo['numero_funcionario'] ?? null,
                'nuit'              => $func['nuit'] ?? null,
                'cargo'             => $func['cargo'] ?? null,
                'unidadeNome'       => $func['unidade_nome'] ?? null,
                'tipoContratoLabel' => $tipoLabels[$func['tipo_contrato'] ?? ''] ?? ($func['tipo_contrato'] ?? null),
            ],
            'salarioBase'     => (float) ($recibo['salario_base'] ?? 0),
            'proventos'       => array_values($proventos),
            'descontos'       => array_values($descontos),
            'totalProventos'  => (float) ($recibo['total_proventos'] ?? 0),
            'totalDescontos'  => (float) ($recibo['total_descontos'] ?? 0),
            'salarioLiquido'  => (float) ($recibo['salario_liquido'] ?? 0),
            'podeVerSalarios' => $podeVerSalarios,
            'geradoEm'        => date('d/m/Y H:i'),
        ]);

        $app->nexora->uploadBinary("/api/rh/recibos-vencimento/$id/pdf", $pdf, 'application/pdf');

        header('Content-Type: application/pdf');
        header('Content-Disposition: attachment; filename="' . $filename . '"');
        echo $pdf;
        exit;
    }

    $pageTitle  = 'Recibo de Vencimento — ' . $periodo;
    $activePage = 'rh_processamento_salarial';
    $breadcrumb = [['Admin','/nexora/'],['Recursos Humanos',''],['Processamento Salarial','/nexora/rh/processamento-salarial'],['Recibo de Vencimento','']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header no-print">
    <h1 class="adm-page-title">Recibo de Vencimento — <?php echo htmlspecialchars($periodo) ?></h1>
    <div class="adm-page-header-actions">
        <a class="adm-btn adm-btn-primary" href="?id=<?= htmlspecialchars($idHash) ?>&formato=pdf">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:5px"><path d="M12 15V3M12 15l-4-4M12 15l4-4M2 17l.6 3A2 2 0 0 0 4.6 22h14.8a2 2 0 0 0 2-1.7l.6-3.3"/></svg>
            Descarregar PDF
        </a>
        <button class="adm-btn adm-btn-outline adm-btn-sm" type="button" onclick="window.print()">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:5px"><polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><rect x="6" y="14" width="12" height="8"/></svg>
            Imprimir
        </button>
        <a href="/nexora/rh/folha-pagamento?id=<?php echo $app->id->encode((int)($recibo['folha_id'] ?? 0)) ?>" class="adm-btn adm-btn-outline adm-btn-sm">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>
            Voltar
        </a>
    </div>
</div>

<div class="recibo-card">
    <!-- Cabeçalho -->
    <div class="recibo-header">
        <div class="recibo-empresa">
            <img class="recibo-logo" src="/assets/images/e258tech-logo.png" alt="E258Tech">
            <h2><?php echo htmlspecialchars($company['nome'] ?? 'Empresa') ?></h2>
            <?php if (!empty($tax['nuit'])): ?>
            <p>NUIT: <?php echo htmlspecialchars($tax['nuit']) ?></p>
            <?php endif; ?>
            <?php if (!empty($company['morada'])): ?>
            <p><?php echo htmlspecialchars($company['morada']) ?></p>
            <?php endif; ?>
        </div>
        <div class="recibo-titulo">
            <h3>Recibo de Vencimento</h3>
            <p><strong>Período:</strong> <?php echo htmlspecialchars($periodo) ?></p>
            <p><strong>Nº Recibo:</strong> RV-<?php echo str_pad($recibo['id'] ?? 0, 6, '0', STR_PAD_LEFT) ?></p>
            <p style="margin-top:.4rem">
                <span class="adm-badge <?php echo $recibo['estado'] === 'pago' ? 'adm-badge--green' : 'adm-badge--gray' ?>">
                    <?php echo $recibo['estado'] === 'pago' ? 'Pago' : 'Pendente' ?>
                </span>
            </p>
        </div>
    </div>

    <!-- Dados do Funcionário -->
    <div class="recibo-section-title">Dados do Funcionário</div>
    <div class="recibo-info-grid">
        <div class="recibo-info-pair">
            <span class="recibo-info-label">Nome Completo</span>
            <span class="recibo-info-value"><?php echo htmlspecialchars($recibo['nome_completo'] ?? '—') ?></span>
        </div>
        <div class="recibo-info-pair">
            <span class="recibo-info-label">Nº Funcionário</span>
            <span class="recibo-info-value"><?php echo htmlspecialchars($recibo['numero_funcionario'] ?? '—') ?></span>
        </div>
        <div class="recibo-info-pair">
            <span class="recibo-info-label">NUIT</span>
            <span class="recibo-info-value"><?php echo htmlspecialchars($func['nuit'] ?? '—') ?></span>
        </div>
        <div class="recibo-info-pair">
            <span class="recibo-info-label">Cargo</span>
            <span class="recibo-info-value"><?php echo htmlspecialchars($func['cargo'] ?? '—') ?></span>
        </div>
        <div class="recibo-info-pair">
            <span class="recibo-info-label">Departamento / Unidade</span>
            <span class="recibo-info-value"><?php echo htmlspecialchars($func['unidade_nome'] ?? '—') ?></span>
        </div>
        <div class="recibo-info-pair">
            <span class="recibo-info-label">Tipo de Contrato</span>
            <span class="recibo-info-value"><?php
                $tipoLabels = ['efetivo'=>'Efetivo','indeterminado'=>'Indeterminado','termo_certo'=>'Termo Certo','termo_incerto'=>'Termo Incerto','estagio'=>'Estágio','prestacao_servico'=>'Prestação de Serviço'];
                echo htmlspecialchars($tipoLabels[$func['tipo_contrato'] ?? ''] ?? ($func['tipo_contrato'] ?? '—'));
            ?></span>
        </div>
    </div>

    <!-- Rendimentos -->
    <?php if ($podeVerSalarios): ?>
    <div class="recibo-section-title">Rendimentos</div>
    <table class="recibo-table">
        <thead><tr><th>Descrição</th><th style="text-align:right">Valor (MT)</th></tr></thead>
        <tbody>
            <tr>
                <td>Salário Base</td>
                <td class="val"><?php echo $fmt((float)($recibo['salario_base'] ?? 0)) ?></td>
            </tr>
            <?php foreach ($proventos as $p): ?>
            <tr>
                <td><?php echo htmlspecialchars($p['nome']) ?></td>
                <td class="val"><?php echo $fmt($p['valor'] !== null ? (float)$p['valor'] : null) ?></td>
            </tr>
            <?php endforeach; ?>
            <tr class="total-row">
                <td>Total Proventos</td>
                <td class="val"><?php
                    $bruto = (float)($recibo['salario_base'] ?? 0) + (float)($recibo['total_proventos'] ?? 0);
                    echo $fmt($bruto);
                ?></td>
            </tr>
        </tbody>
    </table>

    <!-- Descontos -->
    <div class="recibo-section-title">Descontos</div>
    <table class="recibo-table">
        <thead><tr><th>Descrição</th><th style="text-align:right">Valor (MT)</th></tr></thead>
        <tbody>
            <?php if ($descontos): ?>
            <?php foreach ($descontos as $d): ?>
            <tr>
                <td><?php echo htmlspecialchars($d['nome']) ?></td>
                <td class="val"><?php echo $fmt($d['valor'] !== null ? (float)$d['valor'] : null) ?></td>
            </tr>
            <?php endforeach; ?>
            <?php else: ?>
            <tr><td colspan="2" style="color:#888;font-style:italic">Sem descontos registados</td></tr>
            <?php endif; ?>
            <tr class="total-row">
                <td>Total Descontos</td>
                <td class="val"><?php echo $fmt((float)($recibo['total_descontos'] ?? 0)) ?></td>
            </tr>
        </tbody>
    </table>

    <!-- Totais -->
    <div class="recibo-totais">
        <div class="recibo-totais-item">
            <div class="label">Salário Bruto</div>
            <div class="value"><?php echo $fmt((float)($recibo['salario_base'] ?? 0) + (float)($recibo['total_proventos'] ?? 0)) ?></div>
        </div>
        <div class="recibo-totais-item">
            <div class="label">Total Descontos</div>
            <div class="value"><?php echo $fmt((float)($recibo['total_descontos'] ?? 0)) ?></div>
        </div>
        <div class="recibo-totais-item liquido">
            <div class="label">Salário Líquido</div>
            <div class="value"><?php echo $fmt((float)($recibo['salario_liquido'] ?? 0)) ?></div>
        </div>
    </div>
    <?php else: ?>
    <div class="adm-empty" style="margin:2rem 0">
        <p class="adm-empty-title">Valores confidenciais</p>
        <p class="adm-empty-sub">Não tem permissão para visualizar os valores salariais.</p>
    </div>
    <?php endif; ?>

    <!-- Rodapé -->
    <div class="recibo-footer">
        <div>
            <p>Gerado em: <?php echo date('d/m/Y H:i') ?></p>
            <p>Este documento é meramente informativo.</p>
        </div>
        <div class="recibo-assinatura">
            <div class="linha"></div>
            <p>Assinatura do Funcionário</p>
        </div>
        <div class="recibo-assinatura">
            <div class="linha"></div>
            <p>Recursos Humanos</p>
        </div>
    </div>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>

