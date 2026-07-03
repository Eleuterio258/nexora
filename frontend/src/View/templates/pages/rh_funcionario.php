<?php

    $id = $app->request->queryInt('id', 0);

    $resp = $app->nexora->call('GET', "/api/rh/funcionarios/$id");
    if ($resp['status'] !== 200) {
        header('Location: /nexora/rh/funcionarios');
        exit;
    }
    $funcionario = $resp['body']['funcionario'] ?? [];
    $contratos   = $resp['body']['contratos'] ?? [];
    $ausencias   = $resp['body']['ausencias'] ?? [];
    $avaliacoes  = $resp['body']['avaliacoes'] ?? [];
    $contactosEmergencia = $resp['body']['contactos_emergencia'] ?? [];
    $documentos  = $resp['body']['documentos'] ?? [];

    $unidades = $app->nexora->call('GET', '/api/rh/unidades')['body'] ?? [];
    $centrosCustoRaw = $app->nexora->call('GET', '/api/centros-custo/cost-centers');
    $centrosCusto = (is_array($centrosCustoRaw['body'] ?? null) && array_is_list($centrosCustoRaw['body'])) ? $centrosCustoRaw['body'] : [];
    $utilizadores = $app->nexora->call('GET', '/api/auth/utilizadores', null, ['limit' => 100])['body']['data'] ?? [];
    $podeAprovar = $resp['body']['pode_aprovar'] ?? false;
    $podeVerSalarios = $app->session->can('recursos-humanos', 'processar_salarios');
    $periodosAbertos = array_values(array_filter(
        $app->nexora->call('GET', '/api/rh/periodos')['body'] ?? [],
        fn($p) => $p['estado'] === 'aberto'
    ));
    $criteriosAvaliacaoAtivos = array_values(array_filter(
        $app->nexora->call('GET', '/api/rh/criterios-avaliacao')['body'] ?? [],
        fn($c) => $c['ativo']
    ));

    $historicoSalarial = $app->nexora->call('GET', "/api/rh/funcionarios/$id/historico-salarial")['body'] ?? [];

    $componentesFuncionario = $app->nexora->call('GET', "/api/rh/funcionarios/$id/componentes-salariais")['body'] ?? [];
    $componentesSalariaisDisponiveis = array_values(array_filter(
        $app->nexora->call('GET', '/api/rh/componentes-salariais')['body'] ?? [],
        fn($c) => $c['ativo']
    ));

    $beneficiosFuncionario = $app->nexora->call('GET', "/api/rh/funcionarios/$id/beneficios")['body'] ?? [];
    $beneficiosDisponiveis = array_values(array_filter(
        $app->nexora->call('GET', '/api/rh/beneficios')['body'] ?? [],
        fn($b) => $b['ativo']
    ));

    $formacoesFuncionario = $app->nexora->call('GET', "/api/rh/funcionarios/$id/formacoes")['body'] ?? [];
    $formacoesDisponiveis = array_values(array_filter(
        $app->nexora->call('GET', '/api/rh/formacoes')['body'] ?? [],
        fn($f) => $f['ativo']
    ));

    $processosDisciplinares = $app->nexora->call('GET', "/api/rh/funcionarios/$id/processos-disciplinares")['body'] ?? [];

    $recibosVencimento = $app->nexora->call('GET', "/api/rh/funcionarios/$id/recibos-vencimento")['body'] ?? [];

    $adiantamentos = $podeVerSalarios
        ? ($app->nexora->call('GET', "/api/rh/funcionarios/$id/adiantamentos")['body'] ?? [])
        : [];
    $emprestimos = $podeVerSalarios
        ? ($app->nexora->call('GET', "/api/rh/funcionarios/$id/emprestimos")['body'] ?? [])
        : [];

    $presencas = $app->nexora->call('GET', "/api/rh/funcionarios/$id/presencas")['body'] ?? [];

    $tiposAusenciaAtivos = array_values(array_filter(
        $app->nexora->call('GET', '/api/rh/tipos-ausencia')['body'] ?? [],
        fn($t) => $t['ativo']
    ));
    $saldosAusencia = $app->nexora->call('GET', "/api/rh/funcionarios/$id/saldos-ausencia")['body'] ?? [];

    $tipoComponenteLabels = [
        'provento' => 'Provento',
        'desconto' => 'Desconto',
    ];
    $formaCalculoLabels = [
        'fixo'       => 'Valor Fixo',
        'percentual' => 'Percentual',
    ];

    $tipoUnidadeLabels = [
        'departamento' => 'Departamento',
        'equipa'       => 'Equipa',
        'divisao'      => 'Divisão',
        'seccao'       => 'Secção',
        'direccao'     => 'Direção',
        'gabinete'     => 'Gabinete',
        'projeto'      => 'Projeto',
        'outro'        => 'Outro',
    ];

    $estadoBadges = [
        'ativo'     => ['adm-badge--green',  'Ativo'],
        'suspenso'  => ['adm-badge--yellow', 'Suspenso'],
        'licenca'   => ['adm-badge--blue',   'Licença'],
        'desligado' => ['adm-badge--gray',   'Desligado'],
    ];
    $estadoBadge = $estadoBadges[$funcionario['estado']] ?? ['adm-badge--gray', $funcionario['estado']];

    $tipoContratoLabels = [
        'efetivo'           => 'Efetivo',
        'indeterminado'     => 'Indeterminado',
        'termo_certo'       => 'Termo Certo',
        'termo_incerto'     => 'Termo Incerto',
        'estagio'           => 'Estágio',
        'prestacao_servico' => 'Prestação de Serviço',
    ];

    $contratoEstadoBadges = [
        'ativo'      => ['adm-badge--green', 'Ativo'],
        'encerrado'  => ['adm-badge--gray',  'Encerrado'],
        'rescindido' => ['adm-badge--red',   'Rescindido'],
    ];

    $ausenciaEstadoBadges = [
        'pendente'  => ['adm-badge--yellow', 'Pendente'],
        'aprovado'  => ['adm-badge--green',  'Aprovado'],
        'rejeitado' => ['adm-badge--red',    'Rejeitado'],
        'gozada'    => ['adm-badge--blue',   'Gozada'],
        'cancelada' => ['adm-badge--gray',   'Cancelada'],
    ];

    $avaliacaoEstadoBadges = [
        'rascunho'  => ['adm-badge--gray',   'Rascunho'],
        'submetida' => ['adm-badge--yellow', 'Submetida'],
        'aprovada'  => ['adm-badge--green',  'Aprovada'],
    ];

    $categoriaFormacaoLabels = [
        'tecnica'        => 'Técnica',
        'comportamental' => 'Comportamental',
        'obrigatoria'    => 'Obrigatória',
        'outra'          => 'Outra',
    ];
    $formacaoEstadoBadges = [
        'planeada'  => ['adm-badge--gray',  'Planeada'],
        'em_curso'  => ['adm-badge--blue',  'Em Curso'],
        'concluida' => ['adm-badge--green', 'Concluída'],
        'cancelada' => ['adm-badge--red',   'Cancelada'],
    ];

    $tipoProcessoDisciplinarLabels = [
        'advertencia_verbal'  => 'Advertência Verbal',
        'advertencia_escrita' => 'Advertência Escrita',
        'suspensao'           => 'Suspensão',
        'despedimento'        => 'Despedimento',
        'outro'               => 'Outro',
    ];
    $processoDisciplinarEstadoBadges = [
        'aberto'     => ['adm-badge--yellow', 'Aberto'],
        'em_analise' => ['adm-badge--blue',   'Em Análise'],
        'decidido'   => ['adm-badge--green',  'Decidido'],
        'arquivado'  => ['adm-badge--gray',   'Arquivado'],
    ];

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

    $tipoDocumentoLabels = [
        'bi'                  => 'Bilhete de Identidade',
        'passaporte'          => 'Passaporte',
        'carta_conducao'      => 'Carta de Condução',
        'cartao_eleitor'      => 'Cartão de Eleitor',
        'certidao_nascimento' => 'Certidão de Nascimento',
        'outro'               => 'Outro',
    ];

    // RNF02 — confidencialidade salarial: valores são devolvidos como null pelo
    // backend quando o utilizador não tem permissão (recursos-humanos, gerir).
    function rhValorSalarial(?float $valor, bool $podeVer): string
    {
        if (!$podeVer) {
            return '<span class="adm-text-muted">Confidencial</span>';
        }
        return $valor !== null ? number_format($valor, 2, ',', '.') : '—';
    }

    $csrf       = $app->security->csrfToken();
    $pageTitle  = $funcionario['nome_completo'];
    $activePage = 'rh_funcionarios';
    $breadcrumb = [['Admin', '/nexora/'], ['Recursos Humanos', ''], ['Funcionários', '/nexora/rh/funcionarios'], [$funcionario['nome_completo'], '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header" style="align-items:flex-start">
    <div style="display:flex;align-items:center;gap:var(--adm-sp-3)">
        <h1 class="adm-page-title" style="margin:0"><?php echo htmlspecialchars($funcionario['nome_completo']) ?></h1>
        <span class="adm-badge <?php echo $estadoBadge[0] ?>"><?php echo $estadoBadge[1] ?></span>
    </div>
    <div class="adm-page-header-actions">
        <a href="/nexora/rh/funcionarios" class="adm-btn adm-btn-outline adm-btn-sm">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>
            Voltar
        </a>
    </div>
</div>

<div class="adm-detail-grid">
<div>

<div class="adm-tabs" id="mainTabs">
    <?php
    // Helper: renderiza um botão de tab com data-tab para navegação robusta
    $tab = fn(string $name, string $label, string $svgPath, int $badge = 0, bool $show = true, bool $active = false) =>
        $show ? sprintf(
            '<button class="adm-tab%s" data-tab="%s" onclick="switchTab(\'%s\',this)">%s %s%s</button>',
            $active ? ' active' : '',
            $name, $name,
            '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">'.$svgPath.'</svg>',
            $label,
            $badge > 0 ? '<span class="adm-tab-badge">'.$badge.'</span>' : ''
        ) : '';
    $aAtivos = count(array_filter($adiantamentos, fn($a) => $a['estado'] === 'ativo'));
    $eAtivos = count(array_filter($emprestimos,   fn($e) => $e['estado'] === 'ativo'));
    echo $tab('dados',                  'Dados',                   '<path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>',                                                                                              0,                               true,             true);
    echo $tab('contratos',              'Contratos',               '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/>',                                                                          count($contratos));
    echo $tab('historico-salarial',     'Hist. Salarial',          '<line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/>',                                                                               count($historicoSalarial),       $podeVerSalarios);
    echo $tab('componentes-salariais',  'Componentes Sal.',        '<rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/>',                                                                            count($componentesFuncionario),  $podeVerSalarios);
    echo $tab('adiantamentos',          'Adiantamentos',           '<line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/>',                                                                               $aAtivos,                        $podeVerSalarios);
    echo $tab('emprestimos',            'Empréstimos',             '<path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/>',                                                                               $eAtivos,                        $podeVerSalarios);
    echo $tab('recibos-vencimento',     'Recibos',                 '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/>',count($recibosVencimento),       $podeVerSalarios);
    echo $tab('beneficios',             'Benefícios',              '<path d="M20 12V8H6a2 2 0 0 1-2-2c0-1.1.9-2 2-2h12v4"/><path d="M4 6v12c0 1.1.9 2 2 2h14v-4"/><path d="M18 12a2 2 0 0 0 0 4h4v-4Z"/>',                                             count($beneficiosFuncionario));
    echo $tab('presencas',              'Presenças',               '<circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>',                                                                                                               count($presencas));
    echo $tab('ausencias',              'Ausências',               '<rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/>',                    count($ausencias));
    echo $tab('avaliacoes',             'Avaliações',              '<path d="M12 2l3 7h7l-5.5 4.5L18.5 21 12 16.5 5.5 21l2-7.5L2 9h7z"/>',                                                                                                              count($avaliacoes));
    echo $tab('formacoes',              'Formações',               '<path d="M22 10v6M2 10l10-5 10 5-10 5z"/><path d="M6 12v5c3 3 9 3 12 0v-5"/>',                                                                                                       count($formacoesFuncionario));
    echo $tab('processos-disciplinares','Proc. Disciplinares',     '<path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/>',count($processosDisciplinares));
    echo $tab('contactos',              'Contactos Emerg.',        '<path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.127.96.362 1.903.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.907.338 1.85.573 2.81.7A2 2 0 0 1 22 16.92z"/>',count($contactosEmergencia));
    echo $tab('documentos',             'Documentos',              '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/>',count($documentos));
    ?>
</div>

<!-- ── Dados ──────────────────────────────────────────────── -->
<div class="adm-tab-panel active" id="tab-dados">
    <div class="adm-card">
        <div class="adm-card-header"><h2 class="adm-card-title">Dados do Funcionário</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row-1">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-nome">Nome Completo <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="f-nome" maxlength="150" value="<?php echo htmlspecialchars($funcionario['nome_completo']) ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-numero">Número de Funcionário</label>
                    <input class="adm-input" type="text" id="f-numero" maxlength="30" value="<?php echo htmlspecialchars($funcionario['numero_funcionario'] ?? '') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-unidade">Unidade Organizacional</label>
                    <select class="adm-select" id="f-unidade">
                        <option value="">— Nenhuma —</option>
                        <?php foreach ($unidades as $u): ?>
                        <option value="<?php echo (int) $u['id'] ?>" <?php echo ((int) ($funcionario['unit_id'] ?? 0)) === (int) $u['id'] ? 'selected' : '' ?>><?php echo htmlspecialchars($u['nome']) ?> (<?php echo htmlspecialchars($tipoUnidadeLabels[$u['tipo']] ?? $u['tipo']) ?>)</option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-centro-custo">Centro de Custo</label>
                    <select class="adm-select" id="f-centro-custo">
                        <option value="">— Nenhum —</option>
                        <?php foreach ($centrosCusto as $cc): ?>
                        <option value="<?php echo (int) $cc['id'] ?>" <?php echo ((int) ($funcionario['centro_custo_id'] ?? 0)) === (int) $cc['id'] ? 'selected' : '' ?>><?php echo htmlspecialchars($cc['codigo']) ?> — <?php echo htmlspecialchars($cc['nome']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
            </div>
            <div class="adm-form-row-1">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-cargo">Cargo</label>
                    <input class="adm-input" type="text" id="f-cargo" maxlength="120" value="<?php echo htmlspecialchars($funcionario['cargo'] ?? '') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-tipo-contrato">Tipo de Contrato</label>
                    <select class="adm-select" id="f-tipo-contrato">
                        <?php foreach ($tipoContratoLabels as $key => $label): ?>
                        <option value="<?php echo $key ?>" <?php echo $funcionario['tipo_contrato'] === $key ? 'selected' : '' ?>><?php echo $label ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-estado">Estado</label>
                    <select class="adm-select" id="f-estado">
                        <?php foreach ($estadoBadges as $key => [, $label]): ?>
                        <option value="<?php echo $key ?>" <?php echo $funcionario['estado'] === $key ? 'selected' : '' ?>><?php echo $label ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
            </div>
            <div class="adm-form-row-1">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-data-admissao">Data de Admissão</label>
                    <input class="adm-input" type="date" id="f-data-admissao" value="<?php echo $funcionario['data_admissao'] ? date('Y-m-d', strtotime($funcionario['data_admissao'])) : '' ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-data-nascimento">Data de Nascimento</label>
                    <input class="adm-input" type="date" id="f-data-nascimento" value="<?php echo $funcionario['data_nascimento'] ? date('Y-m-d', strtotime($funcionario['data_nascimento'])) : '' ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-genero">Género</label>
                    <select class="adm-select" id="f-genero">
                        <option value="">— Não especificado —</option>
                        <option value="M" <?php echo $funcionario['genero'] === 'M' ? 'selected' : '' ?>>Masculino</option>
                        <option value="F" <?php echo $funcionario['genero'] === 'F' ? 'selected' : '' ?>>Feminino</option>
                        <option value="outro" <?php echo $funcionario['genero'] === 'outro' ? 'selected' : '' ?>>Outro</option>
                    </select>
                </div>
            </div>
            <div class="adm-form-row-1">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-nuit">NUIT</label>
                    <input class="adm-input" type="text" id="f-nuit" maxlength="30" value="<?php echo htmlspecialchars($funcionario['nuit'] ?? '') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-telefone">Telefone</label>
                    <input class="adm-input" type="text" id="f-telefone" maxlength="30" value="<?php echo htmlspecialchars($funcionario['telefone'] ?? '') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-email">Email</label>
                    <input class="adm-input" type="email" id="f-email" maxlength="150" value="<?php echo htmlspecialchars($funcionario['email'] ?? '') ?>">
                </div>
            </div>
            <div class="adm-form-row-1">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-endereco">Endereço</label>
                    <input class="adm-input" type="text" id="f-endereco" maxlength="255" value="<?php echo htmlspecialchars($funcionario['endereco'] ?? '') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-salario">Salário Base</label>
                    <?php if ($podeVerSalarios): ?>
                    <input class="adm-input" type="number" id="f-salario" step="0.01" min="0" value="<?php echo $funcionario['salario_base'] !== null ? (float) $funcionario['salario_base'] : '' ?>">
                    <?php else: ?>
                    <input class="adm-input" type="text" id="f-salario" value="" placeholder="Confidencial — sem permissão" disabled>
                    <?php endif; ?>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-user">Conta de Utilizador</label>
                    <select class="adm-select" id="f-user">
                        <option value="">— Nenhuma —</option>
                        <?php foreach ($utilizadores as $u): ?>
                        <option value="<?php echo (int) $u['id'] ?>" <?php echo ((int) ($funcionario['user_id'] ?? 0)) === (int) $u['id'] ? 'selected' : '' ?>><?php echo htmlspecialchars($u['nome']) ?> (<?php echo htmlspecialchars($u['email']) ?>)</option>
                        <?php endforeach; ?>
                    </select>
                </div>
            </div>
            <div class="adm-form-row-1">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-provincia">Província</label>
                    <input class="adm-input" type="text" id="f-provincia" maxlength="60" value="<?php echo htmlspecialchars($funcionario['provincia'] ?? '') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-cidade">Cidade</label>
                    <input class="adm-input" type="text" id="f-cidade" maxlength="60" value="<?php echo htmlspecialchars($funcionario['cidade'] ?? '') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-bairro">Bairro</label>
                    <input class="adm-input" type="text" id="f-bairro" maxlength="100" value="<?php echo htmlspecialchars($funcionario['bairro'] ?? '') ?>">
                </div>
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-primary" type="button" onclick="saveFuncionario()">Guardar Alterações</button>
            </div>
        </div>
    </div>
</div>

<!-- ── Contratos ──────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-contratos">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Contratos</h2></div>
        <?php if ($contratos): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Tipo</th><th>Função</th><th>Início</th><th>Fim</th><th>Salário</th><th>Estado</th><th>Ficheiro</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($contratos as $c):
                    $cBadge = $contratoEstadoBadges[$c['estado']] ?? ['adm-badge--gray', $c['estado']];
                    $cDataFim = $c['data_fim'] ? date('Y-m-d', strtotime($c['data_fim'])) : '';
                ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($tipoContratoLabels[$c['tipo']] ?? $c['tipo']) ?></td>
                    <td><?php echo $c['funcao'] ? htmlspecialchars($c['funcao']) : '—' ?></td>
                    <td class="adm-text-muted"><?php echo date('d/m/Y', strtotime($c['data_inicio'])) ?></td>
                    <td class="adm-text-muted"><?php echo $c['data_fim'] ? date('d/m/Y', strtotime($c['data_fim'])) : '—' ?></td>
                    <td><?php echo rhValorSalarial($c['salario'] !== null ? (float) $c['salario'] : null, $podeVerSalarios) ?></td>
                    <td><span class="adm-badge <?php echo $cBadge[0] ?>"><?php echo $cBadge[1] ?></span></td>
                    <td>
                        <?php if (!empty($c['ficheiro_url'])): ?>
                        <a href="/nexora/api/rh_contrato_pdf?id=<?php echo (int) $c['id'] ?>" target="_blank" class="adm-btn adm-btn-ghost adm-btn-sm">Ver PDF</a>
                        <?php else: ?>—<?php endif; ?>
                    </td>
                    <td style="white-space:nowrap">
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" onclick="editarContrato(<?php echo (int) $c['id'] ?>)">Editar</button>
                        <?php if (!empty($c['ficheiro_url'])): ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" onclick="enviarContratoAssinatura(<?php echo (int) $c['id'] ?>)" title="Criar documento de assinatura digital">Assinatura Digital</button>
                        <?php endif; ?>
                        <?php if ($c['estado'] === 'ativo'): ?>
                            <?php if ($cDataFim): ?>
                            <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" onclick="openRenovarContrato(<?php echo (int) $c['id'] ?>, '<?php echo $cDataFim ?>')">Renovar</button>
                            <?php endif; ?>
                            <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-red)" onclick="rescindirContrato(<?php echo (int) $c['id'] ?>)">Rescindir</button>
                        <?php endif; ?>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum contrato registado</p>
            <p class="adm-empty-sub">Adicione o primeiro contrato usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title" id="contrato-form-title">Novo Contrato</h2></div>
        <div class="adm-card-body">
            <input type="hidden" id="c-id" value="">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="c-tipo">Tipo <span style="color:var(--adm-red)">*</span></label>
                    <select class="adm-select" id="c-tipo">
                        <?php foreach ($tipoContratoLabels as $key => $label): ?>
                        <option value="<?php echo $key ?>"><?php echo $label ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="c-funcao">Função</label>
                    <input class="adm-input" type="text" id="c-funcao" maxlength="120" placeholder="ex: Técnico de Sistemas">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="c-salario">Salário</label>
                    <?php if ($podeVerSalarios): ?>
                    <input class="adm-input" type="number" id="c-salario" step="0.01" min="0" placeholder="ex: 30000.00">
                    <?php else: ?>
                    <input class="adm-input" type="text" id="c-salario" value="" placeholder="Confidencial — sem permissão" disabled>
                    <?php endif; ?>
                </div>
            </div>
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="c-data-inicio">Data de Início <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="date" id="c-data-inicio" value="<?php echo date('Y-m-d') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="c-data-fim">Data de Fim</label>
                    <input class="adm-input" type="date" id="c-data-fim">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="c-ficheiro">Ficheiro do Contrato</label>
                    <input class="adm-input" type="file" id="c-ficheiro" accept=".pdf,.doc,.docx,.jpg,.jpeg,.png">
                </div>
            </div>
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" style="display:flex;align-items:center;gap:8px;cursor:pointer;">
                        <input type="checkbox" id="c-participacao" value="1" style="width:auto">
                        Com participação societária (50% das quotas)
                    </label>
                </div>
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-primary" type="button" id="contrato-submit-btn" onclick="saveContrato()">Adicionar Contrato</button>
                <button class="adm-btn adm-btn-outline" type="button" id="contrato-cancel-btn" style="display:none" onclick="cancelarEdicaoContrato()">Cancelar</button>
            </div>
        </div>
    </div>
</div>

<!-- ── Histórico Salarial ─────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-historico-salarial">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Histórico Salarial</h2></div>
        <?php if ($historicoSalarial): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Data de Efeito</th><th>Salário Anterior</th><th>Salário Novo</th><th>Motivo</th></tr>
                </thead>
                <tbody>
                <?php foreach ($historicoSalarial as $hs): ?>
                <tr>
                    <td class="adm-text-muted"><?php echo date('d/m/Y', strtotime($hs['data_efectiva'])) ?></td>
                    <td><?php echo rhValorSalarial($hs['salario_anterior'] !== null ? (float) $hs['salario_anterior'] : null, $podeVerSalarios) ?></td>
                    <td class="adm-fw-600"><?php echo rhValorSalarial($hs['salario_novo'] !== null ? (float) $hs['salario_novo'] : null, $podeVerSalarios) ?></td>
                    <td><?php echo $hs['motivo'] ? htmlspecialchars($hs['motivo']) : '—' ?></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhuma alteração salarial registada</p>
            <p class="adm-empty-sub">Registe a primeira alteração usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Registar Alteração Salarial</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="hs-salario-novo">Novo Salário <span style="color:var(--adm-red)">*</span></label>
                    <?php if ($podeVerSalarios): ?>
                    <input class="adm-input" type="number" id="hs-salario-novo" step="0.01" min="0" placeholder="ex: 35000.00">
                    <?php else: ?>
                    <input class="adm-input" type="text" id="hs-salario-novo" value="" placeholder="Confidencial — sem permissão" disabled>
                    <?php endif; ?>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="hs-data-efectiva">Data de Efeito <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="date" id="hs-data-efectiva" value="<?php echo date('Y-m-d') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="hs-motivo">Motivo</label>
                    <input class="adm-input" type="text" id="hs-motivo" maxlength="200" placeholder="ex: Promoção, ajuste anual">
                </div>
            </div>
            <button class="adm-btn adm-btn-primary" type="button" onclick="saveAlteracaoSalarial()">Registar Alteração</button>
        </div>
    </div>
</div>

<!-- ── Componentes Salariais ─────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-componentes-salariais">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Componentes Salariais</h2></div>
        <?php if ($componentesFuncionario): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Componente</th><th>Tipo</th><th>Forma de Cálculo</th><th>Valor</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($componentesFuncionario as $cf): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($cf['nome']) ?></td>
                    <td><span class="adm-badge <?php echo $cf['tipo'] === 'provento' ? 'adm-badge--green' : 'adm-badge--red' ?>"><?php echo $tipoComponenteLabels[$cf['tipo']] ?? $cf['tipo'] ?></span></td>
                    <td class="adm-text-muted"><?php echo $formaCalculoLabels[$cf['forma_calculo']] ?? $cf['forma_calculo'] ?></td>
                    <td class="adm-fw-600"><?php if ($podeVerSalarios): ?><?php echo number_format((float) $cf['valor'], 2, ',', '.') ?><?php echo $cf['forma_calculo'] === 'percentual' ? '%' : '' ?><?php else: ?><span class="adm-text-muted">Confidencial</span><?php endif; ?></td>
                    <td>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-red)" onclick="removerComponenteFuncionario(<?php echo (int) $cf['componente_id'] ?>)">Remover</button>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum componente salarial atribuído</p>
            <p class="adm-empty-sub">Atribua um componente usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Atribuir Componente Salarial</h2></div>
        <div class="adm-card-body">
            <?php if ($componentesSalariaisDisponiveis): ?>
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="cf-componente-id">Componente <span style="color:var(--adm-red)">*</span></label>
                    <select class="adm-select" id="cf-componente-id">
                        <?php foreach ($componentesSalariaisDisponiveis as $cs): ?>
                        <option value="<?php echo (int) $cs['id'] ?>"><?php echo htmlspecialchars($cs['nome']) ?> (<?php echo $tipoComponenteLabels[$cs['tipo']] ?? $cs['tipo'] ?>)</option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="cf-valor">Valor <span style="color:var(--adm-red)">*</span></label>
                    <?php if ($podeVerSalarios): ?>
                    <input class="adm-input" type="number" id="cf-valor" step="0.01" min="0" placeholder="ex: 2500.00">
                    <?php else: ?>
                    <input class="adm-input" type="text" id="cf-valor" value="" placeholder="Confidencial — sem permissão" disabled>
                    <?php endif; ?>
                </div>
            </div>
            <button class="adm-btn adm-btn-primary" type="button" onclick="saveComponenteFuncionario()">Atribuir Componente</button>
            <?php else: ?>
            <p class="adm-text-muted">Não existem componentes salariais activos no catálogo. Adicione-os na página de gestão de funcionários.</p>
            <?php endif; ?>
        </div>
    </div>
</div>

<!-- ── Benefícios ─────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-beneficios">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Benefícios</h2></div>
        <?php if ($beneficiosFuncionario): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Benefício</th><th>Valor</th><th>Data de Início</th><th>Data de Fim</th><th>Observações</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($beneficiosFuncionario as $bf): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($bf['nome']) ?></td>
                    <td><?php echo $bf['valor'] !== null ? number_format((float) $bf['valor'], 2, ',', '.') : '—' ?></td>
                    <td class="adm-text-muted"><?php echo date('d/m/Y', strtotime($bf['data_inicio'])) ?></td>
                    <td class="adm-text-muted"><?php echo $bf['data_fim'] ? date('d/m/Y', strtotime($bf['data_fim'])) : '—' ?></td>
                    <td class="adm-text-muted"><?php echo $bf['observacoes'] ? htmlspecialchars($bf['observacoes']) : '—' ?></td>
                    <td>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-red)" onclick="removerBeneficioFuncionario(<?php echo (int) $bf['beneficio_id'] ?>)">Remover</button>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum benefício atribuído</p>
            <p class="adm-empty-sub">Atribua um benefício usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Atribuir Benefício</h2></div>
        <div class="adm-card-body">
            <?php if ($beneficiosDisponiveis): ?>
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="bf-beneficio-id">Benefício <span style="color:var(--adm-red)">*</span></label>
                    <select class="adm-select" id="bf-beneficio-id">
                        <?php foreach ($beneficiosDisponiveis as $be): ?>
                        <option value="<?php echo (int) $be['id'] ?>"><?php echo htmlspecialchars($be['nome']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="bf-valor">Valor</label>
                    <input class="adm-input" type="number" id="bf-valor" step="0.01" min="0" placeholder="ex: 1500.00">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="bf-data-inicio">Data de Início</label>
                    <input class="adm-input" type="date" id="bf-data-inicio" value="<?php echo date('Y-m-d') ?>">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="bf-data-fim">Data de Fim</label>
                    <input class="adm-input" type="date" id="bf-data-fim">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="bf-observacoes">Observações</label>
                    <input class="adm-input" type="text" id="bf-observacoes" maxlength="200">
                </div>
            </div>
            <button class="adm-btn adm-btn-primary" type="button" onclick="saveBeneficioFuncionario()">Atribuir Benefício</button>
            <?php else: ?>
            <p class="adm-text-muted">Não existem benefícios activos no catálogo. Adicione-os na página de gestão de funcionários.</p>
            <?php endif; ?>
        </div>
    </div>
</div>

<!-- ── Presenças ──────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-presencas">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Presenças</h2></div>
        <?php if ($presencas): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Data</th><th>Entrada</th><th>Saída</th><th>Horas Trabalhadas</th><th>Horas Extra</th><th>Observações</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($presencas as $p): ?>
                <?php
                    $horasTrabalhadas = '—';
                    if ($p['hora_entrada'] && $p['hora_saida']) {
                        $minutos = (strtotime($p['hora_saida']) - strtotime($p['hora_entrada'])) / 60;
                        if ($minutos > 0) {
                            $horasTrabalhadas = number_format($minutos / 60, 2, ',', '.');
                        }
                    }
                ?>
                <tr>
                    <td class="adm-fw-600"><?php echo date('d/m/Y', strtotime($p['data'])) ?></td>
                    <td class="adm-text-muted"><?php echo $p['hora_entrada'] ?: '—' ?></td>
                    <td class="adm-text-muted"><?php echo $p['hora_saida'] ?: '—' ?></td>
                    <td class="adm-text-muted"><?php echo $horasTrabalhadas ?></td>
                    <td class="adm-text-muted"><?php echo number_format((float) $p['horas_extra'], 2, ',', '.') ?></td>
                    <td class="adm-text-muted"><?php echo $p['observacoes'] ? htmlspecialchars($p['observacoes']) : '—' ?></td>
                    <td>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-red)" onclick="removerPresenca(<?php echo (int) $p['id'] ?>)">Remover</button>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhuma presença registada</p>
            <p class="adm-empty-sub">Registe uma presença usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Registar Presença</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="pr-data">Data <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="date" id="pr-data" value="<?php echo date('Y-m-d') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="pr-hora-entrada">Hora de Entrada</label>
                    <input class="adm-input" type="time" id="pr-hora-entrada">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="pr-hora-saida">Hora de Saída</label>
                    <input class="adm-input" type="time" id="pr-hora-saida">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="pr-horas-extra">Horas Extra</label>
                    <input class="adm-input" type="number" id="pr-horas-extra" step="0.01" min="0" placeholder="ex: 1.50">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="pr-observacoes">Observações</label>
                    <input class="adm-input" type="text" id="pr-observacoes" maxlength="200">
                </div>
            </div>
            <button class="adm-btn adm-btn-primary" type="button" onclick="savePresenca()">Registar Presença</button>
        </div>
    </div>
</div>

<!-- ── Ausências ──────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-ausencias">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Ausências</h2></div>
        <?php if ($ausencias): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Tipo</th><th>Início</th><th>Fim</th><th>Dias</th><th>Motivo</th><th>Estado</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($ausencias as $a):
                    $aBadge = $ausenciaEstadoBadges[$a['estado']] ?? ['adm-badge--gray', $a['estado']];
                ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($a['tipo_nome'] ?? '—') ?></td>
                    <td class="adm-text-muted"><?php echo date('d/m/Y', strtotime($a['data_inicio'])) ?></td>
                    <td class="adm-text-muted"><?php echo date('d/m/Y', strtotime($a['data_fim'])) ?></td>
                    <td><?php echo $a['dias'] !== null ? (int) $a['dias'] : '—' ?></td>
                    <td><?php echo $a['motivo'] ? htmlspecialchars($a['motivo']) : '—' ?></td>
                    <td><span class="adm-badge <?php echo $aBadge[0] ?>"><?php echo $aBadge[1] ?></span></td>
                    <td>
                        <?php if ($podeAprovar && $a['estado'] === 'pendente'): ?>
                        <div class="adm-actions">
                            <button class="adm-btn adm-btn-ghost adm-btn-sm" style="color:var(--adm-green)" onclick="aprovarAusencia(<?php echo (int) $a['id'] ?>)">Aprovar</button>
                            <button class="adm-btn adm-btn-ghost adm-btn-sm" style="color:var(--adm-red)" onclick="rejeitarAusencia(<?php echo (int) $a['id'] ?>)">Rejeitar</button>
                            <button class="adm-btn adm-btn-ghost adm-btn-sm" onclick="cancelarAusencia(<?php echo (int) $a['id'] ?>)">Cancelar</button>
                        </div>
                        <?php elseif ($podeAprovar && $a['estado'] === 'aprovado'): ?>
                        <div class="adm-actions">
                            <button class="adm-btn adm-btn-ghost adm-btn-sm" style="color:var(--adm-green)" onclick="gozarAusencia(<?php echo (int) $a['id'] ?>)">Marcar como Gozada</button>
                            <button class="adm-btn adm-btn-ghost adm-btn-sm" onclick="cancelarAusencia(<?php echo (int) $a['id'] ?>)">Cancelar</button>
                        </div>
                        <?php elseif ($a['estado'] === 'pendente'): ?>
                        Pendente
                        <?php else: ?>
                        —
                        <?php endif; ?>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhuma ausência registada</p>
            <p class="adm-empty-sub">Registe o primeiro pedido de ausência usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Novo Pedido de Ausência</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="a-tipo">Tipo <span style="color:var(--adm-red)">*</span></label>
                    <select class="adm-select" id="a-tipo">
                        <?php if (!$tiposAusenciaAtivos): ?>
                        <option value="">— Nenhum tipo configurado —</option>
                        <?php else: ?>
                        <?php foreach ($tiposAusenciaAtivos as $t): ?>
                        <option value="<?php echo (int) $t['id'] ?>"><?php echo htmlspecialchars($t['nome']) ?></option>
                        <?php endforeach; ?>
                        <?php endif; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="a-data-inicio">Data de Início <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="date" id="a-data-inicio" value="<?php echo date('Y-m-d') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="a-data-fim">Data de Fim <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="date" id="a-data-fim" value="<?php echo date('Y-m-d') ?>">
                </div>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="a-motivo">Motivo</label>
                <input class="adm-input" type="text" id="a-motivo" maxlength="255" placeholder="ex: Consulta médica">
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-primary" type="button" onclick="saveAusencia()">Submeter Pedido</button>
            </div>
        </div>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Saldos de Férias/Licenças (<?php echo date('Y') ?>)</h2></div>
        <?php if ($saldosAusencia): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Tipo</th><th>Dias Atribuídos</th><th>Dias Usados</th><th>Dias Restantes</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($saldosAusencia as $s): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($s['tipo_nome']) ?></td>
                    <td>
                        <input class="adm-input" type="number" step="0.5" min="0" style="width:100px" id="saldo-<?php echo (int) $s['tipo_ausencia_id'] ?>" value="<?php echo number_format((float) $s['dias_atribuidos'], 2, '.', '') ?>">
                    </td>
                    <td class="adm-text-muted"><?php echo number_format((float) $s['dias_usados'], 2, ',', '.') ?></td>
                    <td class="adm-fw-600"><?php echo number_format((float) $s['dias_atribuidos'] - (float) $s['dias_usados'], 2, ',', '.') ?></td>
                    <td>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" onclick="saveSaldoAusencia(<?php echo (int) $s['tipo_ausencia_id'] ?>)">Guardar</button>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum tipo de ausência com gestão de saldo</p>
            <p class="adm-empty-sub">Configure tipos de ausência com "Afeta Saldo" activo na página de Recursos Humanos para gerir saldos de férias/licenças.</p>
        </div>
        <?php endif; ?>
    </div>
</div>

<!-- ── Avaliações ─────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-avaliacoes">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Avaliações de Desempenho</h2></div>
        <?php if ($avaliacoes): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Período</th><th>Pontuação</th><th>Estado</th><th>Critérios</th><th>Comentários</th><th>Data</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($avaliacoes as $a):
                    $avBadge = $avaliacaoEstadoBadges[$a['estado']] ?? ['adm-badge--gray', $a['estado']];
                    $avCriterios = $a['criterios'] ?? [];
                ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($a['periodo_nome'] ?? '—') ?></td>
                    <td><?php echo $a['pontuacao'] !== null ? number_format((float) $a['pontuacao'], 2, ',', '.') : '—' ?></td>
                    <td><span class="adm-badge <?php echo $avBadge[0] ?>"><?php echo $avBadge[1] ?></span></td>
                    <td class="adm-text-sm adm-text-muted">
                        <?php if ($avCriterios): ?>
                        <?php echo htmlspecialchars(implode(', ', array_map(
                            fn($c) => $c['criterio_nome'] . ': ' . number_format((float) $c['pontuacao'], 2, ',', '.'),
                            $avCriterios
                        ))) ?>
                        <?php else: ?>—<?php endif; ?>
                    </td>
                    <td class="adm-text-sm"><?php echo $a['comentarios'] ? htmlspecialchars($a['comentarios']) : '—' ?></td>
                    <td class="adm-text-muted"><?php echo date('d/m/Y', strtotime($a['created_at'])) ?></td>
                    <td>
                        <?php if ($a['estado'] === 'rascunho' && $a['pode_submeter']): ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" onclick="submeterAvaliacao(<?php echo (int) $a['id'] ?>)">Submeter</button>
                        <?php elseif ($a['estado'] === 'submetida' && $podeAprovar): ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" style="color:var(--adm-green)" onclick="aprovarAvaliacao(<?php echo (int) $a['id'] ?>)">Aprovar</button>
                        <?php else: ?>
                        —
                        <?php endif; ?>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhuma avaliação registada</p>
            <p class="adm-empty-sub">Registe a primeira avaliação usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Nova Avaliação</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-group">
                <label class="adm-label" for="av-periodo">Período <span style="color:var(--adm-red)">*</span></label>
                <select class="adm-select" id="av-periodo">
                    <?php if (!$periodosAbertos): ?>
                    <option value="">— Nenhum período aberto —</option>
                    <?php else: ?>
                    <?php foreach ($periodosAbertos as $p): ?>
                    <option value="<?php echo (int) $p['id'] ?>"><?php echo htmlspecialchars($p['nome']) ?></option>
                    <?php endforeach; ?>
                    <?php endif; ?>
                </select>
            </div>
            <?php if (!$criteriosAvaliacaoAtivos): ?>
            <p class="adm-text-muted adm-text-sm">Nenhum critério de avaliação configurado. Configure os critérios na página de Funcionários.</p>
            <?php else: ?>
            <div class="adm-form-row-3">
                <?php foreach ($criteriosAvaliacaoAtivos as $c): ?>
                <div class="adm-form-group">
                    <label class="adm-label" for="av-criterio-<?php echo (int) $c['id'] ?>"><?php echo htmlspecialchars($c['nome']) ?> (peso <?php echo number_format((float) $c['peso'], 2, ',', '.') ?>)</label>
                    <input class="adm-input adm-av-criterio" type="number" id="av-criterio-<?php echo (int) $c['id'] ?>" data-criterio-id="<?php echo (int) $c['id'] ?>" step="0.01" min="0" max="20" placeholder="ex: 16.50">
                </div>
                <?php endforeach; ?>
            </div>
            <?php endif; ?>
            <div class="adm-form-group">
                <label class="adm-label" for="av-comentarios">Comentários</label>
                <input class="adm-input" type="text" id="av-comentarios" maxlength="500" placeholder="ex: Bom desempenho geral, cumpre prazos.">
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-primary" type="button" onclick="saveAvaliacao()">Registar Avaliação</button>
            </div>
        </div>
    </div>
</div>

<!-- ── Formações ──────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-formacoes">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Formações</h2></div>
        <?php if ($formacoesFuncionario): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Formação</th><th>Categoria</th><th>Data Início</th><th>Data Fim</th><th>Estado</th><th>Nota</th><th>Certificado</th><th>Observações</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($formacoesFuncionario as $ff):
                    $ffBadge = $formacaoEstadoBadges[$ff['estado']] ?? ['adm-badge--gray', $ff['estado']];
                ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($ff['nome']) ?></td>
                    <td><?php echo htmlspecialchars($categoriaFormacaoLabels[$ff['categoria']] ?? $ff['categoria']) ?></td>
                    <td class="adm-text-muted"><?php echo date('d/m/Y', strtotime($ff['data_inicio'])) ?></td>
                    <td class="adm-text-muted"><?php echo $ff['data_fim'] ? date('d/m/Y', strtotime($ff['data_fim'])) : '—' ?></td>
                    <td><span class="adm-badge <?php echo $ffBadge[0] ?>"><?php echo $ffBadge[1] ?></span></td>
                    <td><?php echo $ff['nota'] !== null ? number_format((float) $ff['nota'], 2, ',', '.') : '—' ?></td>
                    <td><?php if ($ff['certificado_url']): ?><a class="adm-btn adm-btn-ghost adm-btn-sm" href="<?php echo htmlspecialchars($ff['certificado_url']) ?>" target="_blank" rel="noopener">Ver</a><?php else: ?>—<?php endif; ?></td>
                    <td class="adm-text-sm adm-text-muted"><?php echo $ff['observacoes'] ? htmlspecialchars($ff['observacoes']) : '—' ?></td>
                    <td>
                        <div style="display:flex;gap:var(--adm-sp-2);flex-wrap:wrap">
                        <?php if ($ff['estado'] === 'planeada'): ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" onclick="iniciarFormacaoFuncionario(<?php echo (int) $ff['id'] ?>)">Iniciar</button>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-red)" onclick="cancelarFormacaoFuncionario(<?php echo (int) $ff['id'] ?>)">Cancelar</button>
                        <?php elseif ($ff['estado'] === 'em_curso'): ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-green)" onclick="openConcluirFormacao(<?php echo (int) $ff['id'] ?>)">Concluir</button>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-red)" onclick="cancelarFormacaoFuncionario(<?php echo (int) $ff['id'] ?>)">Cancelar</button>
                        <?php endif; ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-red)" onclick="removerFormacaoFuncionario(<?php echo (int) $ff['id'] ?>)">Remover</button>
                        </div>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhuma formação registada</p>
            <p class="adm-empty-sub">Registe uma formação usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Registar Formação</h2></div>
        <div class="adm-card-body">
            <?php if ($formacoesDisponiveis): ?>
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="ff-formacao-id">Formação <span style="color:var(--adm-red)">*</span></label>
                    <select class="adm-select" id="ff-formacao-id">
                        <?php foreach ($formacoesDisponiveis as $fd): ?>
                        <option value="<?php echo (int) $fd['id'] ?>"><?php echo htmlspecialchars($fd['nome']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="ff-data-inicio">Data de Início</label>
                    <input class="adm-input" type="date" id="ff-data-inicio" value="<?php echo date('Y-m-d') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="ff-data-fim">Data de Fim</label>
                    <input class="adm-input" type="date" id="ff-data-fim">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="ff-observacoes">Observações</label>
                    <input class="adm-input" type="text" id="ff-observacoes" maxlength="255">
                </div>
            </div>
            <button class="adm-btn adm-btn-primary" type="button" onclick="saveFormacaoFuncionario()">Registar Formação</button>
            <?php else: ?>
            <p class="adm-text-muted">Não existem formações activas no catálogo. Adicione-as na página de gestão de funcionários.</p>
            <?php endif; ?>
        </div>
    </div>
</div>

<!-- ── Processos Disciplinares ────────────────────────────── -->
<div class="adm-tab-panel" id="tab-processos-disciplinares">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Processos Disciplinares</h2></div>
        <?php if ($processosDisciplinares): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Tipo</th><th>Motivo</th><th>Data Ocorrência</th><th>Data Abertura</th><th>Estado</th><th>Decisão</th><th>Data Decisão</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($processosDisciplinares as $pd):
                    $pdBadge = $processoDisciplinarEstadoBadges[$pd['estado']] ?? ['adm-badge--gray', $pd['estado']];
                ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($tipoProcessoDisciplinarLabels[$pd['tipo']] ?? $pd['tipo']) ?></td>
                    <td class="adm-text-sm"><?php echo htmlspecialchars($pd['motivo']) ?></td>
                    <td class="adm-text-muted"><?php echo date('d/m/Y', strtotime($pd['data_ocorrencia'])) ?></td>
                    <td class="adm-text-muted"><?php echo date('d/m/Y', strtotime($pd['data_abertura'])) ?></td>
                    <td><span class="adm-badge <?php echo $pdBadge[0] ?>"><?php echo $pdBadge[1] ?></span></td>
                    <td class="adm-text-sm"><?php echo $pd['decisao'] ? htmlspecialchars($pd['decisao']) : '—' ?></td>
                    <td class="adm-text-muted"><?php echo $pd['data_decisao'] ? date('d/m/Y', strtotime($pd['data_decisao'])) : '—' ?></td>
                    <td>
                        <div style="display:flex;gap:var(--adm-sp-2);flex-wrap:wrap">
                        <?php if (in_array($pd['estado'], ['aberto', 'em_analise'], true)): ?>
                        <?php if ($pd['estado'] === 'aberto'): ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" onclick="iniciarAnaliseProcessoDisciplinar(<?php echo (int) $pd['id'] ?>)">Iniciar Análise</button>
                        <?php endif; ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-green)" onclick="openDecidirProcesso(<?php echo (int) $pd['id'] ?>)">Decidir</button>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-red)" onclick="arquivarProcessoDisciplinar(<?php echo (int) $pd['id'] ?>)">Arquivar</button>
                        <?php endif; ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-red)" onclick="removerProcessoDisciplinar(<?php echo (int) $pd['id'] ?>)">Remover</button>
                        </div>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum processo disciplinar registado</p>
            <p class="adm-empty-sub">Registe um processo disciplinar usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Novo Processo Disciplinar</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="pd-tipo">Tipo <span style="color:var(--adm-red)">*</span></label>
                    <select class="adm-select" id="pd-tipo">
                        <option value="advertencia_verbal">Advertência Verbal</option>
                        <option value="advertencia_escrita">Advertência Escrita</option>
                        <option value="suspensao">Suspensão</option>
                        <option value="despedimento">Despedimento</option>
                        <option value="outro">Outro</option>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="pd-data-ocorrencia">Data de Ocorrência <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="date" id="pd-data-ocorrencia" value="<?php echo date('Y-m-d') ?>">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="pd-motivo">Motivo <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="pd-motivo" maxlength="500" placeholder="ex: Atrasos repetidos sem justificação">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="pd-descricao">Descrição</label>
                    <input class="adm-input" type="text" id="pd-descricao" maxlength="1000" placeholder="Descrição detalhada opcional">
                </div>
            </div>
            <button class="adm-btn adm-btn-primary" type="button" onclick="saveProcessoDisciplinar()">Registar Processo</button>
        </div>
    </div>
</div>

<!-- ── Recibos de Vencimento ──────────────────────────────── -->
<div class="adm-tab-panel" id="tab-recibos-vencimento">
    <?php
    // Info: adiantamentos e empréstimos activos que serão descontados no próximo processamento
    $aAtivosInfo = array_values(array_filter($adiantamentos ?? [], fn($a) => $a['estado'] === 'ativo'));
    $eAtivosInfo = array_values(array_filter($emprestimos   ?? [], fn($e) => $e['estado'] === 'ativo'));
    if ($podeVerSalarios && ($aAtivosInfo || $eAtivosInfo)):
    ?>
    <div class="adm-card adm-mb-4" style="border-left:3px solid var(--adm-blue)">
        <div class="adm-card-body" style="padding:var(--adm-sp-4) var(--adm-sp-5)">
            <p class="adm-fw-600" style="margin-bottom:var(--adm-sp-2);font-size:.85rem">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:4px;vertical-align:middle"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                Descontos activos para o próximo processamento
            </p>
            <div style="display:flex;gap:var(--adm-sp-4);flex-wrap:wrap">
                <?php foreach ($aAtivosInfo as $a): ?>
                <span class="adm-badge adm-badge--blue">
                    <?php echo htmlspecialchars($a['descricao'] ?? 'Adiantamento') ?>:
                    <?php echo number_format((float)$a['prestacao_valor'],2,',','.') ?> MT/mês
                    (<?php echo (int)$a['prestacoes_pagas']?>/<?php echo (int)$a['num_prestacoes']?>)
                </span>
                <?php endforeach; ?>
                <?php foreach ($eAtivosInfo as $e): ?>
                <span class="adm-badge adm-badge--indigo">
                    <?php echo htmlspecialchars($e['descricao'] ?? 'Empréstimo') ?>:
                    <?php echo number_format((float)$e['prestacao_valor'],2,',','.') ?> MT/mês
                    (<?php echo (int)$e['prestacoes_pagas']?>/<?php echo (int)$e['num_prestacoes']?>)
                </span>
                <?php endforeach; ?>
            </div>
        </div>
    </div>
    <?php endif; ?>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Recibos de Vencimento</h2></div>
        <?php if ($recibosVencimento): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Período</th><th>Salário Base</th><th>Proventos</th><th>Descontos</th><th>Líquido</th><th>Estado</th><th></th></tr>
                </thead>
                <tbody>
                <?php foreach ($recibosVencimento as $rv):
                    $rvBadge  = $reciboEstadoBadges[$rv['estado']] ?? ['adm-badge--gray', $rv['estado']];
                    $periodo  = ($mesesLabels[$rv['mes']] ?? $rv['mes']) . ' ' . (int)$rv['ano'];
                ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($periodo) ?></td>
                    <td class="adm-text-muted"><?php echo rhValorSalarial($rv['salario_base'] !== null ? (float)$rv['salario_base'] : null, $podeVerSalarios) ?></td>
                    <td class="adm-text-muted"><?php echo rhValorSalarial($rv['total_proventos'] !== null ? (float)$rv['total_proventos'] : null, $podeVerSalarios) ?></td>
                    <td class="adm-text-muted"><?php echo rhValorSalarial($rv['total_descontos'] !== null ? (float)$rv['total_descontos'] : null, $podeVerSalarios) ?></td>
                    <td class="adm-fw-600"><?php echo rhValorSalarial($rv['salario_liquido'] !== null ? (float)$rv['salario_liquido'] : null, $podeVerSalarios) ?></td>
                    <td><span class="adm-badge <?php echo $rvBadge[0] ?>"><?php echo $rvBadge[1] ?></span></td>
                    <td>
                        <a class="adm-btn adm-btn-ghost adm-btn-sm" href="/nexora/rh/recibo-vencimento?id=<?php echo (int)$rv['id'] ?>">
                            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:3px"><polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><rect x="6" y="14" width="12" height="8"/></svg>
                            Ver
                        </a>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum recibo de vencimento registado</p>
            <p class="adm-empty-sub">Os recibos são gerados ao processar uma folha de pagamento em <a href="/nexora/rh/processamento-salarial" class="adm-link">Processamento Salarial</a>.</p>
        </div>
        <?php endif; ?>
    </div>
</div>

<!-- ── Adiantamentos ──────────────────────────────────────── -->
<?php if ($podeVerSalarios): ?>
<div class="adm-tab-panel" id="tab-adiantamentos">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Adiantamentos</h2></div>
        <?php if ($adiantamentos): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead><tr><th>Descrição</th><th>Valor Total</th><th>Prestação</th><th>Prestações</th><th>Estado</th><th></th></tr></thead>
                <tbody>
                <?php foreach ($adiantamentos as $a):
                    $aBadge = ['ativo'=>['adm-badge--blue','Ativo'],'quitado'=>['adm-badge--green','Quitado'],'cancelado'=>['adm-badge--gray','Cancelado']][$a['estado']] ?? ['adm-badge--gray',$a['estado']];
                ?>
                <tr>
                    <td><?php echo htmlspecialchars($a['descricao'] ?? 'Adiantamento') ?></td>
                    <td class="adm-fw-600"><?php echo number_format((float)$a['valor_total'],2,',','.') ?> MT</td>
                    <td><?php echo number_format((float)$a['prestacao_valor'],2,',','.') ?> MT</td>
                    <td><?php echo (int)$a['prestacoes_pagas'] ?> / <?php echo (int)$a['num_prestacoes'] ?></td>
                    <td><span class="adm-badge <?php echo $aBadge[0] ?>"><?php echo $aBadge[1] ?></span></td>
                    <td>
                        <?php if ($a['estado'] === 'ativo'): ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" style="color:var(--adm-red)" type="button"
                            onclick="cancelarAdiantamento(<?php echo (int)$a['id'] ?>)">Cancelar</button>
                        <?php endif; ?>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty"><p class="adm-empty-title">Nenhum adiantamento registado</p></div>
        <?php endif; ?>
    </div>
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Registar Adiantamento</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label">Valor Total (MT) *</label>
                    <input class="adm-input" type="number" id="adt-valor" step="0.01" min="0.01" placeholder="ex: 5000.00">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label">Nº de Prestações *</label>
                    <input class="adm-input" type="number" id="adt-prestacoes" min="1" max="36" value="1">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label">Data de Início</label>
                    <input class="adm-input" type="date" id="adt-data" value="<?php echo date('Y-m-d') ?>">
                </div>
            </div>
            <div class="adm-form-group adm-mb-4">
                <label class="adm-label">Descrição</label>
                <input class="adm-input" type="text" id="adt-descricao" maxlength="200" placeholder="ex: Adiantamento de salário — Agosto 2026">
            </div>
            <button class="adm-btn adm-btn-primary" type="button" onclick="saveAdiantamento()">Registar Adiantamento</button>
        </div>
    </div>
</div>

<!-- ── Empréstimos ─────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-emprestimos">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Empréstimos</h2></div>
        <?php if ($emprestimos): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead><tr><th>Descrição</th><th>Valor</th><th>Prestação</th><th>Juros</th><th>Prestações</th><th>Estado</th><th></th></tr></thead>
                <tbody>
                <?php foreach ($emprestimos as $e):
                    $eBadge = ['ativo'=>['adm-badge--blue','Ativo'],'quitado'=>['adm-badge--green','Quitado'],'cancelado'=>['adm-badge--gray','Cancelado']][$e['estado']] ?? ['adm-badge--gray',$e['estado']];
                ?>
                <tr>
                    <td><?php echo htmlspecialchars($e['descricao'] ?? 'Empréstimo') ?></td>
                    <td class="adm-fw-600"><?php echo number_format((float)$e['valor_total'],2,',','.') ?> MT</td>
                    <td><?php echo number_format((float)$e['prestacao_valor'],2,',','.') ?> MT</td>
                    <td><?php echo number_format((float)$e['taxa_juros']*100,1) ?>%</td>
                    <td><?php echo (int)$e['prestacoes_pagas'] ?> / <?php echo (int)$e['num_prestacoes'] ?></td>
                    <td><span class="adm-badge <?php echo $eBadge[0] ?>"><?php echo $eBadge[1] ?></span></td>
                    <td>
                        <?php if ($e['estado'] === 'ativo'): ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" style="color:var(--adm-red)" type="button"
                            onclick="cancelarEmprestimo(<?php echo (int)$e['id'] ?>)">Cancelar</button>
                        <?php endif; ?>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty"><p class="adm-empty-title">Nenhum empréstimo registado</p></div>
        <?php endif; ?>
    </div>
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Registar Empréstimo</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label">Valor Total (MT) *</label>
                    <input class="adm-input" type="number" id="emp-valor" step="0.01" min="0.01" placeholder="ex: 20000.00">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label">Nº de Prestações *</label>
                    <input class="adm-input" type="number" id="emp-prestacoes" min="1" max="60" value="12">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label">Taxa de Juros (%)</label>
                    <input class="adm-input" type="number" id="emp-juros" step="0.1" min="0" value="0" placeholder="0 = sem juros">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label">Descrição</label>
                    <input class="adm-input" type="text" id="emp-descricao" maxlength="200" placeholder="ex: Empréstimo pessoal">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label">Data de Início</label>
                    <input class="adm-input" type="date" id="emp-data" value="<?php echo date('Y-m-d') ?>">
                </div>
            </div>
            <button class="adm-btn adm-btn-primary" type="button" onclick="saveEmprestimo()">Registar Empréstimo</button>
        </div>
    </div>
</div>
<?php endif; ?>

<!-- ── Contactos de Emergência ────────────────────────────── -->
<div class="adm-tab-panel" id="tab-contactos">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Contactos de Emergência</h2></div>
        <?php if ($contactosEmergencia): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Nome</th><th>Parentesco</th><th>Telefone</th><th>Email</th><th></th></tr>
                </thead>
                <tbody>
                <?php foreach ($contactosEmergencia as $ce): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($ce['nome']) ?></td>
                    <td><?php echo $ce['parentesco'] ? htmlspecialchars($ce['parentesco']) : '—' ?></td>
                    <td><?php echo htmlspecialchars($ce['telefone']) ?></td>
                    <td><?php echo $ce['email'] ? htmlspecialchars($ce['email']) : '—' ?></td>
                    <td>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" style="color:var(--adm-red)" onclick="eliminarContactoEmergencia(<?php echo (int) $ce['id'] ?>)">Remover</button>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum contacto de emergência registado</p>
            <p class="adm-empty-sub">Adicione o primeiro contacto usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Novo Contacto de Emergência</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="ce-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="ce-nome" maxlength="150" placeholder="ex: Maria Joaquina">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="ce-parentesco">Parentesco</label>
                    <input class="adm-input" type="text" id="ce-parentesco" maxlength="50" placeholder="ex: Cônjuge, Mãe, Irmão">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="ce-telefone">Telefone <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="ce-telefone" maxlength="30" placeholder="ex: 84 123 4567">
                </div>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="ce-email">Email</label>
                <input class="adm-input" type="email" id="ce-email" maxlength="150" placeholder="ex: contacto@exemplo.com">
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-primary" type="button" onclick="saveContactoEmergencia()">Adicionar Contacto</button>
            </div>
        </div>
    </div>
</div>

<!-- ── Documentos ─────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-documentos">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Documentos</h2></div>
        <?php if ($documentos): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Tipo</th><th>Número</th><th>Emissão</th><th>Validade</th><th>Ficheiro</th><th></th></tr>
                </thead>
                <tbody>
                <?php foreach ($documentos as $d): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($tipoDocumentoLabels[$d['tipo']] ?? $d['tipo']) ?></td>
                    <td><?php echo $d['numero'] ? htmlspecialchars($d['numero']) : '—' ?></td>
                    <td class="adm-text-muted"><?php echo $d['data_emissao'] ? date('d/m/Y', strtotime($d['data_emissao'])) : '—' ?></td>
                    <td class="adm-text-muted"><?php echo $d['data_validade'] ? date('d/m/Y', strtotime($d['data_validade'])) : '—' ?></td>
                    <td>
                        <?php if (!empty($d['ficheiro_url'])): ?>
                        <a href="/nexora/api/rh_documento_ficheiro?path=<?php echo urlencode($d['ficheiro_url']) ?>" target="_blank" class="adm-btn adm-btn-ghost adm-btn-sm">Ver ficheiro</a>
                        <?php else: ?>—<?php endif; ?>
                    </td>
                    <td>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" style="color:var(--adm-red)" onclick="eliminarDocumento(<?php echo (int) $d['id'] ?>)">Remover</button>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum documento registado</p>
            <p class="adm-empty-sub">Adicione o primeiro documento usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Novo Documento</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="doc-tipo">Tipo <span style="color:var(--adm-red)">*</span></label>
                    <select class="adm-select" id="doc-tipo">
                        <?php foreach ($tipoDocumentoLabels as $key => $label): ?>
                        <option value="<?php echo $key ?>"><?php echo $label ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="doc-numero">Número</label>
                    <input class="adm-input" type="text" id="doc-numero" maxlength="60" placeholder="ex: 110100123456A">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="doc-ficheiro">Ficheiro</label>
                    <input class="adm-input" type="file" id="doc-ficheiro" accept=".pdf,.doc,.docx,.jpg,.jpeg,.png">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="doc-data-emissao">Data de Emissão</label>
                    <input class="adm-input" type="date" id="doc-data-emissao">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="doc-data-validade">Data de Validade</label>
                    <input class="adm-input" type="date" id="doc-data-validade">
                </div>
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-primary" type="button" onclick="saveDocumento()">Adicionar Documento</button>
            </div>
        </div>
    </div>
</div>

</div> <!-- /main col -->

<aside>
    <div class="adm-card">
        <div class="adm-card-header"><h2 class="adm-card-title">Resumo</h2></div>
        <div class="adm-card-body">
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Unidade Organizacional</span>
                <span class="adm-detail-pair-value"><?php echo $funcionario['unidade_nome'] ? htmlspecialchars($funcionario['unidade_nome']) : '—' ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Cargo</span>
                <span class="adm-detail-pair-value"><?php echo $funcionario['cargo'] ? htmlspecialchars($funcionario['cargo']) : '—' ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Tipo de Contrato</span>
                <span class="adm-detail-pair-value"><?php echo htmlspecialchars($tipoContratoLabels[$funcionario['tipo_contrato']] ?? $funcionario['tipo_contrato']) ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Data de Admissão</span>
                <span class="adm-detail-pair-value"><?php echo $funcionario['data_admissao'] ? date('d/m/Y', strtotime($funcionario['data_admissao'])) : '—' ?></span>
            </div>
            <?php if (!empty($funcionario['data_saida'])): ?>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Data de Saída</span>
                <span class="adm-detail-pair-value"><?php echo date('d/m/Y', strtotime($funcionario['data_saida'])) ?></span>
            </div>
            <?php endif; ?>

            <?php if ($funcionario['estado'] !== 'desligado'): ?>
            <button class="adm-btn adm-btn-outline adm-btn-sm" onclick="desligarFuncionario()" style="justify-content:flex-start;color:var(--adm-red);margin-top:var(--adm-sp-3)">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                Desligar Funcionário
            </button>
            <?php else: ?>
            <p class="adm-text-muted adm-text-sm" style="margin:var(--adm-sp-3) 0 0">Funcionário desligado.</p>
            <?php endif; ?>
        </div>
    </div>
</aside>
</div> <!-- /adm-detail-grid -->

<!-- Modal: Renovar Contrato -->
<div class="adm-modal-overlay" id="renovarContratoModal">
    <div class="adm-modal">
        <p class="adm-modal-title">Renovar Contrato</p>
        <div class="adm-form-group">
            <label class="adm-label" for="renovar-data-fim">Nova Data de Fim <span style="color:var(--adm-red)">*</span></label>
            <input class="adm-input" type="date" id="renovar-data-fim">
        </div>
        <div class="adm-form-group">
            <label class="adm-label" for="renovar-salario">Novo Salário (opcional)</label>
            <?php if ($podeVerSalarios): ?>
            <input class="adm-input" type="number" id="renovar-salario" step="0.01" min="0" placeholder="manter salário actual">
            <?php else: ?>
            <input class="adm-input" type="text" id="renovar-salario" value="" placeholder="Confidencial — sem permissão" disabled>
            <?php endif; ?>
        </div>
        <div class="adm-modal-footer">
            <button class="adm-btn adm-btn-outline" type="button" onclick="closeRenovarContrato()">Cancelar</button>
            <button class="adm-btn adm-btn-primary" type="button" id="renovarContratoBtn">Renovar</button>
        </div>
    </div>
</div>

<div class="adm-modal-overlay" id="concluirFormacaoModal">
    <div class="adm-modal">
        <p class="adm-modal-title">Concluir Formação</p>
        <div class="adm-form-group">
            <label class="adm-label" for="cf-nota">Nota</label>
            <input class="adm-input" type="number" id="cf-nota" step="0.01" min="0" max="20" placeholder="ex: 18.50">
        </div>
        <div class="adm-form-group">
            <label class="adm-label" for="cf-certificado-url">URL do Certificado</label>
            <input class="adm-input" type="text" id="cf-certificado-url" placeholder="https://...">
        </div>
        <div class="adm-form-group">
            <label class="adm-label" for="cf-observacoes">Observações</label>
            <input class="adm-input" type="text" id="cf-observacoes" maxlength="255">
        </div>
        <div class="adm-modal-footer">
            <button class="adm-btn adm-btn-outline" type="button" onclick="closeConcluirFormacao()">Cancelar</button>
            <button class="adm-btn adm-btn-primary" type="button" id="concluirFormacaoBtn">Concluir</button>
        </div>
    </div>
</div>

<div class="adm-modal-overlay" id="decidirProcessoModal">
    <div class="adm-modal">
        <p class="adm-modal-title">Decidir Processo Disciplinar</p>
        <div class="adm-form-group">
            <label class="adm-label" for="dp-decisao">Decisão <span style="color:var(--adm-red)">*</span></label>
            <input class="adm-input" type="text" id="dp-decisao" maxlength="1000" placeholder="ex: Aplicada advertência escrita">
        </div>
        <div class="adm-form-group">
            <label class="adm-label" for="dp-data-decisao">Data da Decisão <span style="color:var(--adm-red)">*</span></label>
            <input class="adm-input" type="date" id="dp-data-decisao">
        </div>
        <div class="adm-modal-footer">
            <button class="adm-btn adm-btn-outline" type="button" onclick="closeDecidirProcesso()">Cancelar</button>
            <button class="adm-btn adm-btn-primary" type="button" id="decidirProcessoBtn">Decidir</button>
        </div>
    </div>
</div>

<script>
const CSRF    = '<?php echo $csrf ?>';
const FUNC_ID = <?php echo (int) $funcionario['id'] ?>;

// ── Tabs ─────────────────────────────────────────────────────
function switchTab(name, btn) {
    const panel = document.getElementById('tab-' + name);
    if (!panel) return; // tab não existe no DOM (ex: sem permissão)
    document.querySelectorAll('.adm-tab-panel').forEach(p => p.classList.remove('active'));
    document.querySelectorAll('#mainTabs .adm-tab').forEach(b => b.classList.remove('active'));
    panel.classList.add('active');
    // Usa o botão passado directamente, ou encontra pelo data-tab
    const activeBtn = btn || document.querySelector(`#mainTabs .adm-tab[data-tab="${name}"]`);
    if (activeBtn) activeBtn.classList.add('active');
    history.replaceState(null, '', location.pathname + location.search + '#' + name);
}

document.addEventListener('DOMContentLoaded', () => {
    const hash = location.hash.replace('#', '');
    if (hash) {
        const btn = document.querySelector(`#mainTabs .adm-tab[data-tab="${hash}"]`);
        if (btn) switchTab(hash, btn);
    }
});

async function postJSON(url, payload, tab) {
    try {
        const res  = await fetch(url, {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            showToast(data.msg || 'Guardado com sucesso.');
            // Preserva a tab após reload usando o parâmetro passado ou a tab actualmente activa
            const targetTab = tab || location.hash.replace('#','') || 'dados';
            location.hash = targetTab;
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}

// ── Dados ────────────────────────────────────────────────────
function saveFuncionario() {
    const nome = document.getElementById('f-nome').value.trim();
    if (!nome) { showToast('O nome completo é obrigatório.', 'error'); return; }

    const unidade = document.getElementById('f-unidade').value;
    const salario = document.getElementById('f-salario').value;

    const userId = document.getElementById('f-user').value;

    postJSON('/nexora/api/rh_funcionario_save', {
        id: FUNC_ID,
        nome_completo: nome,
        numero_funcionario: document.getElementById('f-numero').value.trim() || null,
        unit_id: unidade ? Number(unidade) : null,
        centro_custo_id: document.getElementById('f-centro-custo').value ? Number(document.getElementById('f-centro-custo').value) : null,
        cargo: document.getElementById('f-cargo').value.trim() || null,
        tipo_contrato: document.getElementById('f-tipo-contrato').value,
        estado: document.getElementById('f-estado').value,
        data_admissao: document.getElementById('f-data-admissao').value || null,
        data_nascimento: document.getElementById('f-data-nascimento').value || null,
        genero: document.getElementById('f-genero').value || null,
        nuit: document.getElementById('f-nuit').value.trim() || null,
        telefone: document.getElementById('f-telefone').value.trim() || null,
        email: document.getElementById('f-email').value.trim() || null,
        endereco: document.getElementById('f-endereco').value.trim() || null,
        provincia: document.getElementById('f-provincia').value.trim() || null,
        cidade: document.getElementById('f-cidade').value.trim() || null,
        bairro: document.getElementById('f-bairro').value.trim() || null,
        salario_base: salario ? Number(salario) : null,
        user_id: userId ? Number(userId) : null,
        csrf: CSRF
    }, 'dados');
}

function desligarFuncionario() {
    openConfirm(
        'Desligar funcionário',
        'Pretende desligar "<?php echo htmlspecialchars(addslashes($funcionario['nome_completo'])) ?>"? Esta ação marca o funcionário como desligado.',
        async () => {
            try {
                const res  = await fetch('/nexora/api/rh_funcionario_desligar', {
                    method: 'POST',
                    headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({ id: FUNC_ID, csrf: CSRF })
                });
                const data = await res.json();
                if (data.ok) {
                    showToast('Funcionário desligado.');
                    setTimeout(() => location.reload(), 700);
                } else {
                    showToast(data.erro || 'Erro', 'error');
                }
            } catch { showToast('Erro de ligação', 'error'); }
        }
    );
}

// ── Contratos ────────────────────────────────────────────────
const CONTRATOS = <?php echo json_encode($contratos) ?>;

async function saveContrato() {
    const dataInicio = document.getElementById('c-data-inicio').value;
    if (!dataInicio) { showToast('A data de início é obrigatória.', 'error'); return; }

    const id = document.getElementById('c-id').value;

    const fd = new FormData();
    if (id) fd.append('id', id);
    fd.append('funcionario_id', FUNC_ID);
    fd.append('tipo', document.getElementById('c-tipo').value);
    fd.append('funcao', document.getElementById('c-funcao').value.trim());
    fd.append('data_inicio', dataInicio);
    fd.append('data_fim', document.getElementById('c-data-fim').value);
    fd.append('salario', document.getElementById('c-salario').value);
    fd.append('participacao', document.getElementById('c-participacao').checked ? '1' : '0');
    fd.append('csrf', CSRF);

    const ficheiro = document.getElementById('c-ficheiro').files[0];
    if (ficheiro) fd.append('ficheiro', ficheiro);

    try {
        const res  = await fetch('/nexora/api/rh_contrato_save', { method: 'POST', body: fd });
        const data = await res.json();
        if (data.ok) {
            showToast(data.msg || 'Guardado com sucesso.');
            location.hash = 'contratos';
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}

async function enviarContratoAssinatura(id) {
    if (!confirm('Criar documento de assinatura digital a partir deste contrato?')) return;
    const r = await postJSON('/nexora/api/rh_contrato_enviar_assinatura', { id, csrf: CSRF }, 'contratos');
    if (r.doc_id) {
        window.open('/nexora/assinatura-digital?doc_id=' + r.doc_id, '_blank');
    } else {
        alert(r.erro || 'Erro ao criar documento de assinatura.');
    }
}

function editarContrato(id) {
    const c = CONTRATOS.find(x => x.id === id);
    if (!c) return;

    document.getElementById('c-id').value = c.id;
    document.getElementById('c-tipo').value = c.tipo;
    document.getElementById('c-funcao').value = c.funcao || '';
    document.getElementById('c-salario').value = c.salario ?? '';
    document.getElementById('c-data-inicio').value = c.data_inicio ? c.data_inicio.substring(0, 10) : '';
    document.getElementById('c-data-fim').value = c.data_fim ? c.data_fim.substring(0, 10) : '';

    document.getElementById('contrato-form-title').textContent = 'Editar Contrato';
    document.getElementById('contrato-submit-btn').textContent = 'Guardar Alterações';
    document.getElementById('contrato-cancel-btn').style.display = '';

    document.getElementById('tab-contratos').scrollIntoView({ behavior: 'smooth', block: 'end' });
}

function cancelarEdicaoContrato() {
    document.getElementById('c-id').value = '';
    document.getElementById('c-tipo').selectedIndex = 0;
    document.getElementById('c-funcao').value = '';
    document.getElementById('c-salario').value = '';
    document.getElementById('c-data-inicio').value = '<?php echo date('Y-m-d') ?>';
    document.getElementById('c-data-fim').value = '';
    document.getElementById('c-ficheiro').value = '';
    document.getElementById('c-participacao').checked = false;

    document.getElementById('contrato-form-title').textContent = 'Novo Contrato';
    document.getElementById('contrato-submit-btn').textContent = 'Adicionar Contrato';
    document.getElementById('contrato-cancel-btn').style.display = 'none';
}

function rescindirContrato(id) {
    openConfirm('Rescindir contrato', 'Pretende rescindir este contrato? Esta ação marca o contrato como rescindido e não pode ser revertida.', async () => {
        await postJSON('/nexora/api/rh_contrato_rescindir', { id, csrf: CSRF }, 'contratos');
    });
}

// ── Renovar Contrato ───────────────────────────────────────────
let _renovarContratoId = null;
function openRenovarContrato(id, dataFimAtual) {
    _renovarContratoId = id;
    const dataFimInput = document.getElementById('renovar-data-fim');
    if (dataFimAtual) {
        const d = new Date(dataFimAtual + 'T00:00:00');
        d.setDate(d.getDate() + 1);
        dataFimInput.min = d.toISOString().substring(0, 10);
    } else {
        dataFimInput.removeAttribute('min');
    }
    dataFimInput.value = '';
    document.getElementById('renovar-salario').value = '';
    document.getElementById('renovarContratoModal').classList.add('open');
}
function closeRenovarContrato() {
    document.getElementById('renovarContratoModal').classList.remove('open');
    _renovarContratoId = null;
}
document.getElementById('renovarContratoBtn').addEventListener('click', async () => {
    const dataFim = document.getElementById('renovar-data-fim').value;
    if (!dataFim) { showToast('A nova data de fim é obrigatória.', 'error'); return; }

    const payload = { id: _renovarContratoId, data_fim: dataFim, csrf: CSRF };
    const salario = document.getElementById('renovar-salario').value;
    if (salario) payload.salario = Number(salario);

    closeRenovarContrato();
    await postJSON('/nexora/api/rh_contrato_renovar', payload, 'contratos');
});
document.getElementById('renovarContratoModal').addEventListener('click', e => {
    if (e.target === e.currentTarget) closeRenovarContrato();
});

// ── Histórico Salarial ─────────────────────────────────────────
async function saveAlteracaoSalarial() {
    const salarioNovo = document.getElementById('hs-salario-novo').value;
    const dataEfectiva = document.getElementById('hs-data-efectiva').value;
    if (!salarioNovo || Number(salarioNovo) <= 0) { showToast('O novo salário é obrigatório.', 'error'); return; }
    if (!dataEfectiva) { showToast('A data de efeito é obrigatória.', 'error'); return; }

    await postJSON('/nexora/api/rh_historico_salarial_save', {
        funcionario_id: FUNC_ID,
        salario_novo: Number(salarioNovo),
        data_efectiva: dataEfectiva,
        motivo: document.getElementById('hs-motivo').value.trim(),
        csrf: CSRF
    }, 'historico-salarial');
}

// ── Componentes Salariais ───────────────────────────────────────
async function saveComponenteFuncionario() {
    const componenteId = document.getElementById('cf-componente-id').value;
    const valor = document.getElementById('cf-valor').value;
    if (!componenteId) { showToast('Selecione um componente salarial.', 'error'); return; }
    if (!valor || Number(valor) < 0) { showToast('O valor é obrigatório.', 'error'); return; }

    await postJSON('/nexora/api/rh_funcionario_componente_save', {
        funcionario_id: FUNC_ID,
        componente_id: Number(componenteId),
        valor: Number(valor),
        csrf: CSRF
    }, 'componentes-salariais');
}

function removerComponenteFuncionario(componenteId) {
    openConfirm('Remover componente salarial', 'Pretende remover este componente salarial do funcionário?', async () => {
        await postJSON('/nexora/api/rh_funcionario_componente_remover', {
            funcionario_id: FUNC_ID,
            componente_id: componenteId,
            csrf: CSRF
        }, 'componentes-salariais');
    });
}

// ── Adiantamentos ─────────────────────────────────────────────
async function saveAdiantamento() {
    const valor     = document.getElementById('adt-valor').value;
    const prestacoes = document.getElementById('adt-prestacoes').value;
    if (!valor || Number(valor) <= 0) { showToast('Valor é obrigatório.', 'error'); return; }
    await postJSON('/nexora/api/rh_adiantamento_save', {
        funcionario_id: FUNC_ID,
        valor_total:    Number(valor),
        num_prestacoes: Number(prestacoes) || 1,
        descricao:      document.getElementById('adt-descricao').value || null,
        data_inicio:    document.getElementById('adt-data').value || null,
        csrf: CSRF
    }, 'adiantamentos');
}

function cancelarAdiantamento(id) {
    openConfirm('Cancelar adiantamento', 'Pretende cancelar este adiantamento? As prestações futuras não serão descontadas.', async () => {
        await postJSON('/nexora/api/rh_adiantamento_cancelar', { id, csrf: CSRF }, 'adiantamentos');
    });
}

// ── Empréstimos ───────────────────────────────────────────────
async function saveEmprestimo() {
    const valor     = document.getElementById('emp-valor').value;
    const prestacoes = document.getElementById('emp-prestacoes').value;
    if (!valor || Number(valor) <= 0) { showToast('Valor é obrigatório.', 'error'); return; }
    await postJSON('/nexora/api/rh_emprestimo_save', {
        funcionario_id: FUNC_ID,
        valor_total:    Number(valor),
        num_prestacoes: Number(prestacoes) || 1,
        taxa_juros:     Number(document.getElementById('emp-juros').value || 0) / 100,
        descricao:      document.getElementById('emp-descricao').value || null,
        data_inicio:    document.getElementById('emp-data').value || null,
        csrf: CSRF
    }, 'emprestimos');
}

function cancelarEmprestimo(id) {
    openConfirm('Cancelar empréstimo', 'Pretende cancelar este empréstimo? As prestações futuras não serão descontadas.', async () => {
        await postJSON('/nexora/api/rh_emprestimo_cancelar', { id, csrf: CSRF }, 'emprestimos');
    });
}

// ── Benefícios ───────────────────────────────────────────────
async function saveBeneficioFuncionario() {
    const beneficioId = document.getElementById('bf-beneficio-id').value;
    if (!beneficioId) { showToast('Selecione um benefício.', 'error'); return; }

    const valor      = document.getElementById('bf-valor').value;
    const dataInicio = document.getElementById('bf-data-inicio').value;
    const dataFim    = document.getElementById('bf-data-fim').value;
    if (dataFim && dataInicio && dataFim < dataInicio) {
        showToast('A data de fim deve ser igual ou posterior à data de início.', 'error');
        return;
    }

    await postJSON('/nexora/api/rh_funcionario_beneficio_save', {
        funcionario_id: FUNC_ID,
        beneficio_id: Number(beneficioId),
        valor: valor ? Number(valor) : null,
        data_inicio: dataInicio || null,
        data_fim: dataFim || null,
        observacoes: document.getElementById('bf-observacoes').value.trim() || null,
        csrf: CSRF
    }, 'beneficios');
}

function removerBeneficioFuncionario(beneficioId) {
    openConfirm('Remover benefício', 'Pretende remover este benefício do funcionário?', async () => {
        await postJSON('/nexora/api/rh_funcionario_beneficio_remover', {
            funcionario_id: FUNC_ID,
            beneficio_id: beneficioId,
            csrf: CSRF
        }, 'beneficios');
    });
}

// ── Presenças ────────────────────────────────────────────────
async function savePresenca() {
    const data = document.getElementById('pr-data').value;
    if (!data) { showToast('A data é obrigatória.', 'error'); return; }

    const horasExtra = document.getElementById('pr-horas-extra').value;

    await postJSON('/nexora/api/rh_funcionario_presenca_save', {
        funcionario_id: FUNC_ID,
        data: data,
        hora_entrada: document.getElementById('pr-hora-entrada').value || null,
        hora_saida: document.getElementById('pr-hora-saida').value || null,
        horas_extra: horasExtra ? Number(horasExtra) : 0,
        observacoes: document.getElementById('pr-observacoes').value.trim() || null,
        csrf: CSRF
    }, 'presencas');
}

function removerPresenca(presencaId) {
    openConfirm('Remover presença', 'Pretende remover este registo de presença?', async () => {
        await postJSON('/nexora/api/rh_funcionario_presenca_remover', {
            funcionario_id: FUNC_ID,
            presenca_id: presencaId,
            csrf: CSRF
        }, 'presencas');
    });
}

// ── Ausências ────────────────────────────────────────────────
function saveAusencia() {
    const tipoId = document.getElementById('a-tipo').value;
    if (!tipoId) { showToast('Selecione o tipo de ausência.', 'error'); return; }

    const dataInicio = document.getElementById('a-data-inicio').value;
    const dataFim     = document.getElementById('a-data-fim').value;
    if (!dataInicio || !dataFim) { showToast('As datas de início e fim são obrigatórias.', 'error'); return; }
    if (dataFim < dataInicio) { showToast('A data de fim deve ser igual ou posterior à data de início.', 'error'); return; }

    postJSON('/nexora/api/rh_ausencia_save', {
        funcionario_id: FUNC_ID,
        tipo_id: Number(tipoId),
        data_inicio: dataInicio,
        data_fim: dataFim,
        motivo: document.getElementById('a-motivo').value.trim() || null,
        csrf: CSRF
    }, 'ausencias');
}

function aprovarAusencia(id) {
    openConfirm('Aprovar ausência', 'Pretende aprovar este pedido de ausência?', async () => {
        await postJSON('/nexora/api/rh_ausencia_aprovar', { id, csrf: CSRF }, 'ausencias');
    });
}

function rejeitarAusencia(id) {
    openConfirm('Rejeitar ausência', 'Pretende rejeitar este pedido de ausência?', async () => {
        await postJSON('/nexora/api/rh_ausencia_rejeitar', { id, csrf: CSRF }, 'ausencias');
    });
}

function gozarAusencia(id) {
    openConfirm('Marcar como gozada', 'Confirma que esta ausência foi gozada?', async () => {
        await postJSON('/nexora/api/rh_ausencia_gozar', { id, csrf: CSRF }, 'ausencias');
    });
}

function cancelarAusencia(id) {
    openConfirm('Cancelar ausência', 'Pretende cancelar este pedido de ausência?', async () => {
        await postJSON('/nexora/api/rh_ausencia_cancelar', { id, csrf: CSRF }, 'ausencias');
    });
}

function saveSaldoAusencia(tipoAusenciaId) {
    const dias = document.getElementById('saldo-' + tipoAusenciaId).value;
    if (dias === '') { showToast('Indique os dias atribuídos.', 'error'); return; }

    postJSON('/nexora/api/rh_funcionario_saldo_ausencia_save', {
        funcionario_id: FUNC_ID,
        tipo_ausencia_id: tipoAusenciaId,
        ano: new Date().getFullYear(),
        dias_atribuidos: Number(dias),
        csrf: CSRF
    }, 'ausencias');
}

// ── Avaliações ───────────────────────────────────────────────
function saveAvaliacao() {
    const periodoId = document.getElementById('av-periodo').value;
    if (!periodoId) { showToast('Selecione um período de avaliação.', 'error'); return; }

    const criterioInputs = document.querySelectorAll('.adm-av-criterio');
    const criterios = [];
    for (const input of criterioInputs) {
        if (input.value === '') { showToast('Preencha a pontuação de todos os critérios.', 'error'); return; }
        criterios.push({ criterio_id: Number(input.dataset.criterioId), pontuacao: Number(input.value) });
    }
    if (!criterios.length) { showToast('Não há critérios de avaliação configurados.', 'error'); return; }

    postJSON('/nexora/api/rh_avaliacao_save', {
        funcionario_id: FUNC_ID,
        periodo_id: Number(periodoId),
        criterios,
        comentarios: document.getElementById('av-comentarios').value.trim() || null,
        csrf: CSRF
    }, 'avaliacoes');
}

function submeterAvaliacao(id) {
    openConfirm('Submeter avaliação', 'Pretende submeter esta avaliação para aprovação?', async () => {
        await postJSON('/nexora/api/rh_avaliacao_submeter', { id, csrf: CSRF }, 'avaliacoes');
    });
}

function aprovarAvaliacao(id) {
    openConfirm('Aprovar avaliação', 'Pretende aprovar esta avaliação de desempenho?', async () => {
        await postJSON('/nexora/api/rh_avaliacao_aprovar', { id, csrf: CSRF }, 'avaliacoes');
    });
}

// ── Formações ────────────────────────────────────────────────
function saveFormacaoFuncionario() {
    const formacaoId = document.getElementById('ff-formacao-id').value;
    const dataInicio = document.getElementById('ff-data-inicio').value;
    if (!formacaoId || !dataInicio) { showToast('Formação e data de início são obrigatórias.', 'error'); return; }

    postJSON('/nexora/api/rh_funcionario_formacao_save', {
        funcionario_id: FUNC_ID,
        formacao_id: Number(formacaoId),
        data_inicio: dataInicio,
        data_fim: document.getElementById('ff-data-fim').value || null,
        observacoes: document.getElementById('ff-observacoes').value.trim() || null,
        csrf: CSRF
    }, 'formacoes');
}

function iniciarFormacaoFuncionario(id) {
    postJSON('/nexora/api/rh_funcionario_formacao_editar', {
        funcionario_id: FUNC_ID, id, estado: 'em_curso', csrf: CSRF
    }, 'formacoes');
}

function cancelarFormacaoFuncionario(id) {
    openConfirm('Cancelar formação', 'Pretende cancelar esta formação?', async () => {
        await postJSON('/nexora/api/rh_funcionario_formacao_editar', {
            funcionario_id: FUNC_ID, id, estado: 'cancelada', csrf: CSRF
        }, 'formacoes');
    });
}

function removerFormacaoFuncionario(id) {
    openConfirm('Remover formação', 'Pretende remover este registo de formação?', async () => {
        await postJSON('/nexora/api/rh_funcionario_formacao_remover', {
            funcionario_id: FUNC_ID, id, csrf: CSRF
        }, 'formacoes');
    });
}

// ── Concluir Formação ────────────────────────────────────────
let _concluirFormacaoId = null;
function openConcluirFormacao(id) {
    _concluirFormacaoId = id;
    document.getElementById('cf-nota').value = '';
    document.getElementById('cf-certificado-url').value = '';
    document.getElementById('cf-observacoes').value = '';
    document.getElementById('concluirFormacaoModal').classList.add('open');
}
function closeConcluirFormacao() {
    document.getElementById('concluirFormacaoModal').classList.remove('open');
    _concluirFormacaoId = null;
}
document.getElementById('concluirFormacaoBtn').addEventListener('click', async () => {
    const payload = { funcionario_id: FUNC_ID, id: _concluirFormacaoId, estado: 'concluida', csrf: CSRF };
    const nota = document.getElementById('cf-nota').value;
    if (nota) payload.nota = Number(nota);
    const certificado = document.getElementById('cf-certificado-url').value.trim();
    if (certificado) payload.certificado_url = certificado;
    const observacoes = document.getElementById('cf-observacoes').value.trim();
    if (observacoes) payload.observacoes = observacoes;

    closeConcluirFormacao();
    await postJSON('/nexora/api/rh_funcionario_formacao_editar', payload, 'formacoes');
});
document.getElementById('concluirFormacaoModal').addEventListener('click', e => {
    if (e.target === e.currentTarget) closeConcluirFormacao();
});

// ── Processos Disciplinares ────────────────────────────────────
function saveProcessoDisciplinar() {
    const motivo = document.getElementById('pd-motivo').value.trim();
    const dataOcorrencia = document.getElementById('pd-data-ocorrencia').value;
    if (!motivo || !dataOcorrencia) { showToast('O motivo e a data de ocorrência são obrigatórios.', 'error'); return; }

    postJSON('/nexora/api/rh_funcionario_processo_disciplinar_save', {
        funcionario_id: FUNC_ID,
        tipo: document.getElementById('pd-tipo').value,
        data_ocorrencia: dataOcorrencia,
        motivo: motivo,
        descricao: document.getElementById('pd-descricao').value.trim() || null,
        csrf: CSRF
    }, 'processos-disciplinares');
}

function iniciarAnaliseProcessoDisciplinar(id) {
    postJSON('/nexora/api/rh_funcionario_processo_disciplinar_editar', {
        funcionario_id: FUNC_ID, id, estado: 'em_analise', csrf: CSRF
    }, 'processos-disciplinares');
}

function arquivarProcessoDisciplinar(id) {
    openConfirm('Arquivar processo', 'Pretende arquivar este processo disciplinar sem decisão registada?', async () => {
        await postJSON('/nexora/api/rh_funcionario_processo_disciplinar_editar', {
            funcionario_id: FUNC_ID, id, estado: 'arquivado', csrf: CSRF
        }, 'processos-disciplinares');
    });
}

function removerProcessoDisciplinar(id) {
    openConfirm('Remover processo', 'Pretende remover este processo disciplinar?', async () => {
        await postJSON('/nexora/api/rh_funcionario_processo_disciplinar_remover', {
            funcionario_id: FUNC_ID, id, csrf: CSRF
        }, 'processos-disciplinares');
    });
}

// ── Decidir Processo Disciplinar ────────────────────────────────
let _decidirProcessoId = null;
function openDecidirProcesso(id) {
    _decidirProcessoId = id;
    document.getElementById('dp-decisao').value = '';
    document.getElementById('dp-data-decisao').value = new Date().toISOString().slice(0, 10);
    document.getElementById('decidirProcessoModal').classList.add('open');
}
function closeDecidirProcesso() {
    document.getElementById('decidirProcessoModal').classList.remove('open');
    _decidirProcessoId = null;
}
document.getElementById('decidirProcessoBtn').addEventListener('click', async () => {
    const decisao = document.getElementById('dp-decisao').value.trim();
    const dataDecisao = document.getElementById('dp-data-decisao').value;
    if (!decisao || !dataDecisao) { showToast('A decisão e a data da decisão são obrigatórias.', 'error'); return; }

    const id = _decidirProcessoId;
    closeDecidirProcesso();
    await postJSON('/nexora/api/rh_funcionario_processo_disciplinar_editar', {
        funcionario_id: FUNC_ID, id, estado: 'decidido', decisao, data_decisao: dataDecisao, csrf: CSRF
    }, 'processos-disciplinares');
});
document.getElementById('decidirProcessoModal').addEventListener('click', e => {
    if (e.target === e.currentTarget) closeDecidirProcesso();
});

// ── Contactos de Emergência ────────────────────────────────────
function saveContactoEmergencia() {
    const nome     = document.getElementById('ce-nome').value.trim();
    const telefone = document.getElementById('ce-telefone').value.trim();
    if (!nome || !telefone) { showToast('O nome e o telefone são obrigatórios.', 'error'); return; }

    postJSON('/nexora/api/rh_contacto_emergencia_save', {
        funcionario_id: FUNC_ID,
        nome: nome,
        parentesco: document.getElementById('ce-parentesco').value.trim() || null,
        telefone: telefone,
        email: document.getElementById('ce-email').value.trim() || null,
        csrf: CSRF
    }, 'contactos');
}

function eliminarContactoEmergencia(id) {
    openConfirm('Remover contacto', 'Pretende remover este contacto de emergência?', async () => {
        await postJSON('/nexora/api/rh_contacto_emergencia_remover', { id, csrf: CSRF }, 'contactos');
    });
}

// ── Documentos ───────────────────────────────────────────────
async function saveDocumento() {
    const tipo = document.getElementById('doc-tipo').value;
    if (!tipo) { showToast('O tipo de documento é obrigatório.', 'error'); return; }

    const fd = new FormData();
    fd.append('funcionario_id', FUNC_ID);
    fd.append('tipo', tipo);
    fd.append('numero', document.getElementById('doc-numero').value.trim());
    fd.append('data_emissao', document.getElementById('doc-data-emissao').value);
    fd.append('data_validade', document.getElementById('doc-data-validade').value);
    fd.append('csrf', CSRF);

    const ficheiro = document.getElementById('doc-ficheiro').files[0];
    if (ficheiro) fd.append('ficheiro', ficheiro);

    try {
        const res  = await fetch('/nexora/api/rh_documento_save', { method: 'POST', body: fd });
        const data = await res.json();
        if (data.ok) {
            showToast(data.msg || 'Guardado com sucesso.');
            location.hash = 'documentos';
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}

function eliminarDocumento(id) {
    openConfirm('Remover documento', 'Pretende remover este documento?', async () => {
        await postJSON('/nexora/api/rh_documento_remover', { id, csrf: CSRF }, 'documentos');
    });
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
