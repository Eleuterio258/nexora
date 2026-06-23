<?php

    $filtroUnidade = $app->request->queryInt('unit_id', 0) ?: 0;
    $filtroEstado  = $app->request->queryEnum('estado', ['ativo', 'suspenso', 'licenca', 'desligado']);
    $filtroQ       = $app->request->queryString('q');

    $query = [];
    if ($filtroUnidade) {
        $query['unit_id'] = $filtroUnidade;
    }
    if ($filtroEstado !== '') {
        $query['estado'] = $filtroEstado;
    }
    if ($filtroQ !== '') {
        $query['q'] = $filtroQ;
    }

    $__safeList = fn(array $r) => ($r['status'] === 200 && is_array($r['body']) && array_is_list($r['body'])) ? $r['body'] : [];

    $funcionarios       = $__safeList($app->nexora->call('GET', '/api/rh/funcionarios', null, $query));
    $unidades           = $__safeList($app->nexora->call('GET', '/api/rh/unidades'));
    $periodos           = $__safeList($app->nexora->call('GET', '/api/rh/periodos'));
    $cargos             = $__safeList($app->nexora->call('GET', '/api/rh/cargos'));
    $horarios           = $__safeList($app->nexora->call('GET', '/api/rh/horarios'));
    $componentesSalariais = $__safeList($app->nexora->call('GET', '/api/rh/componentes-salariais'));
    $beneficios         = $__safeList($app->nexora->call('GET', '/api/rh/beneficios'));
    $tiposAusencia      = $__safeList($app->nexora->call('GET', '/api/rh/tipos-ausencia'));
    $criteriosAvaliacao = $__safeList($app->nexora->call('GET', '/api/rh/criterios-avaliacao'));
    $formacoes          = $__safeList($app->nexora->call('GET', '/api/rh/formacoes'));
    $folhasPagamento    = $__safeList($app->nexora->call('GET', '/api/rh/folhas-pagamento'));

    // RNF02 — confidencialidade salarial: 'processar_salarios' é a funcionalidade de acesso a dados salariais.
    $podeVerSalarios = $app->session->can('recursos-humanos', 'processar_salarios');
    function rhValorSalarial(?float $valor, bool $podeVer): string
    {
        if (!$podeVer) {
            return '<span class="adm-text-muted">Confidencial</span>';
        }
        return $valor !== null ? number_format($valor, 2, ',', '.') : '—';
    }

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

    $categoriaFormacaoLabels = [
        'tecnica'        => 'Técnica',
        'comportamental' => 'Comportamental',
        'obrigatoria'    => 'Obrigatória',
        'outra'          => 'Outra',
    ];
    $todosFuncionarios = $query
        ? ($app->nexora->call('GET', '/api/rh/funcionarios')['body'] ?? [])
        : $funcionarios;

    $estadoBadges = [
        'ativo'     => ['adm-badge--green',  'Ativo'],
        'suspenso'  => ['adm-badge--yellow', 'Suspenso'],
        'licenca'   => ['adm-badge--blue',   'Licença'],
        'desligado' => ['adm-badge--gray',   'Desligado'],
    ];

    $tipoContratoLabels = [
        'efetivo'           => 'Efetivo',
        'termo_certo'       => 'Termo Certo',
        'termo_incerto'     => 'Termo Incerto',
        'estagio'           => 'Estágio',
        'prestacao_servico' => 'Prestação de Serviço',
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

    $periodoEstadoBadges = [
        'aberto'    => ['adm-badge--green', 'Aberto'],
        'encerrado' => ['adm-badge--gray',  'Encerrado'],
    ];

    $tipoComponenteLabels = [
        'provento' => 'Provento',
        'desconto' => 'Desconto',
    ];
    $formaCalculoLabels = [
        'fixo'       => 'Valor Fixo',
        'percentual' => 'Percentual',
    ];

    $diasSemanaLabels = ['1' => 'Seg', '2' => 'Ter', '3' => 'Qua', '4' => 'Qui', '5' => 'Sex', '6' => 'Sáb', '7' => 'Dom'];
    $formatDiasSemana = function (string $diasSemana) use ($diasSemanaLabels): string {
        $partes = array_filter(array_map('trim', explode(',', $diasSemana)));
        return implode(', ', array_map(fn($d) => $diasSemanaLabels[$d] ?? $d, $partes));
    };

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Funcionários';
    $activePage = 'rh_funcionarios';
    $breadcrumb = [['Admin', '/nexora/'], ['Recursos Humanos', ''], ['Funcionários', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Recursos Humanos</h1>
</div>

<div class="adm-tabs" id="mainTabs">
    <button class="adm-tab active" onclick="switchTab('funcionarios',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
        Funcionários
        <?php if (count($funcionarios)): ?><span class="adm-tab-badge"><?php echo count($funcionarios) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('unidades',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 21h18"/><path d="M5 21V7l8-4v18"/><path d="M19 21V11l-6-4"/></svg>
        Unidades Organizacionais
        <?php if (count($unidades)): ?><span class="adm-tab-badge"><?php echo count($unidades) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('periodos',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
        Períodos de Avaliação
        <?php if (count($periodos)): ?><span class="adm-tab-badge"><?php echo count($periodos) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('cargos',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 7h-9"/><path d="M14 17H5"/><circle cx="17" cy="17" r="3"/><circle cx="7" cy="7" r="3"/></svg>
        Cargos
        <?php if (count($cargos)): ?><span class="adm-tab-badge"><?php echo count($cargos) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('horarios',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
        Horários
        <?php if (count($horarios)): ?><span class="adm-tab-badge"><?php echo count($horarios) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('componentes-salariais',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
        Componentes Salariais
        <?php if (count($componentesSalariais)): ?><span class="adm-tab-badge"><?php echo count($componentesSalariais) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('beneficios',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 12V8H6a2 2 0 0 1-2-2c0-1.1.9-2 2-2h12v4"/><path d="M4 6v12c0 1.1.9 2 2 2h14v-4"/><path d="M18 12a2 2 0 0 0 0 4h4v-4Z"/></svg>
        Benefícios
        <?php if (count($beneficios)): ?><span class="adm-tab-badge"><?php echo count($beneficios) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('tipos-ausencia',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/><path d="M9 16l2 2 4-4"/></svg>
        Tipos de Ausência
        <?php if (count($tiposAusencia)): ?><span class="adm-tab-badge"><?php echo count($tiposAusencia) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('criterios-avaliacao',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2l3 6 6 1-4.5 4.5L17.5 20 12 17l-5.5 3 1-6.5L3 9l6-1z"/></svg>
        Critérios de Avaliação
        <?php if (count($criteriosAvaliacao)): ?><span class="adm-tab-badge"><?php echo count($criteriosAvaliacao) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('formacoes',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 10v6M2 10l10-5 10 5-10 5z"/><path d="M6 12v5c3 3 9 3 12 0v-5"/></svg>
        Formações
        <?php if (count($formacoes)): ?><span class="adm-tab-badge"><?php echo count($formacoes) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('processamento-salarial',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="5" width="20" height="14" rx="2"/><line x1="2" y1="10" x2="22" y2="10"/></svg>
        Processamento Salarial
        <?php if (count($folhasPagamento)): ?><span class="adm-tab-badge"><?php echo count($folhasPagamento) ?></span><?php endif; ?>
    </button>
</div>

<!-- ── Funcionários ───────────────────────────────────────── -->
<div class="adm-tab-panel active" id="tab-funcionarios">
    <div class="adm-card adm-mb-6">
        <div class="adm-filter-bar">
            <div class="adm-search-wrap">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
                </svg>
                <input class="adm-input" type="search" id="fSearch" placeholder="Pesquisar por nome ou número…" value="<?php echo htmlspecialchars($filtroQ) ?>" onkeydown="if(event.key==='Enter') applyFiltros()">
            </div>
            <select class="adm-select" id="fUnidade" onchange="applyFiltros()" style="min-width:200px">
                <option value="">Todas as unidades</option>
                <?php foreach ($unidades as $u): ?>
                <option value="<?php echo (int) $u['id'] ?>" <?php echo $filtroUnidade === (int) $u['id'] ? 'selected' : '' ?>><?php echo htmlspecialchars($u['nome']) ?></option>
                <?php endforeach; ?>
            </select>
            <select class="adm-select" id="fEstado" onchange="applyFiltros()" style="width:160px">
                <option value="">Todos os estados</option>
                <?php foreach ($estadoBadges as $key => [, $label]): ?>
                <option value="<?php echo $key ?>" <?php echo $filtroEstado === $key ? 'selected' : '' ?>><?php echo $label ?></option>
                <?php endforeach; ?>
            </select>
            <button class="adm-btn adm-btn-outline adm-btn-sm" type="button" onclick="applyFiltros()">Filtrar</button>
            <span class="adm-filter-count"><?php echo count($funcionarios) ?> funcionário<?php echo count($funcionarios) !== 1 ? 's' : '' ?></span>
        </div>

        <?php if ($funcionarios): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr>
                        <th>Nº</th>
                        <th>Nome</th>
                        <th>Unidade</th>
                        <th>Cargo</th>
                        <th>Admissão</th>
                        <th>Estado</th>
                        <th>Ações</th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach ($funcionarios as $f):
                    $badge = $estadoBadges[$f['estado']] ?? ['adm-badge--gray', $f['estado']];
                ?>
                <tr>
                    <td class="adm-text-muted"><?php echo $f['numero_funcionario'] ? htmlspecialchars($f['numero_funcionario']) : '—' ?></td>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($f['nome_completo']) ?></td>
                    <td><?php echo $f['unidade_nome'] ? htmlspecialchars($f['unidade_nome']) : '—' ?></td>
                    <td><?php echo $f['cargo'] ? htmlspecialchars($f['cargo']) : '—' ?></td>
                    <td class="adm-text-muted"><?php echo $f['data_admissao'] ? date('d/m/Y', strtotime($f['data_admissao'])) : '—' ?></td>
                    <td><span class="adm-badge <?php echo $badge[0] ?>"><?php echo $badge[1] ?></span></td>
                    <td>
                        <div class="adm-actions">
                            <a href="<?php echo htmlspecialchars($app->routes->path('rh_funcionario', ['id' => $f['id']])) ?>" class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Ver">
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
                                </svg>
                            </a>
                        </div>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum funcionário encontrado</p>
            <p class="adm-empty-sub">Adicione o primeiro funcionário usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Novo Funcionário</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-nome">Nome Completo <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="f-nome" maxlength="150" placeholder="ex: Maria José Macamo">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-numero">Número de Funcionário</label>
                    <input class="adm-input" type="text" id="f-numero" maxlength="30" placeholder="ex: FUNC-001">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-unidade">Unidade Organizacional</label>
                    <select class="adm-select" id="f-unidade">
                        <option value="">— Nenhuma —</option>
                        <?php foreach ($unidades as $u): ?>
                        <option value="<?php echo (int) $u['id'] ?>"><?php echo htmlspecialchars($u['nome']) ?> (<?php echo htmlspecialchars($tipoUnidadeLabels[$u['tipo']] ?? $u['tipo']) ?>)</option>
                        <?php endforeach; ?>
                    </select>
                </div>
            </div>
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-cargo-id">Cargo</label>
                    <select class="adm-select" id="f-cargo-id" onchange="onCargoFuncionarioChange()">
                        <option value="">— Nenhum —</option>
                        <?php foreach ($cargos as $c): ?>
                        <option value="<?php echo (int) $c['id'] ?>"><?php echo htmlspecialchars($c['nome']) ?></option>
                        <?php endforeach; ?>
                        <option value="outro">Outro (especificar)</option>
                    </select>
                    <input class="adm-input" type="text" id="f-cargo-texto" maxlength="120" placeholder="ex: Técnico Administrativo" style="display:none;margin-top:var(--adm-sp-2)">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-tipo-contrato">Tipo de Contrato</label>
                    <select class="adm-select" id="f-tipo-contrato">
                        <?php foreach ($tipoContratoLabels as $key => $label): ?>
                        <option value="<?php echo $key ?>" <?php echo $key === 'efetivo' ? 'selected' : '' ?>><?php echo $label ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-data-admissao">Data de Admissão</label>
                    <input class="adm-input" type="date" id="f-data-admissao" value="<?php echo date('Y-m-d') ?>">
                </div>
            </div>
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-data-nascimento">Data de Nascimento</label>
                    <input class="adm-input" type="date" id="f-data-nascimento">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-genero">Género</label>
                    <select class="adm-select" id="f-genero">
                        <option value="">— Não especificado —</option>
                        <option value="M">Masculino</option>
                        <option value="F">Feminino</option>
                        <option value="outro">Outro</option>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-nuit">NUIT</label>
                    <input class="adm-input" type="text" id="f-nuit" maxlength="30" placeholder="ex: 123456789">
                </div>
            </div>
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-telefone">Telefone</label>
                    <input class="adm-input" type="text" id="f-telefone" maxlength="30" placeholder="ex: 84 123 4567">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-email">Email</label>
                    <input class="adm-input" type="email" id="f-email" maxlength="150" placeholder="ex: maria@empresa.co.mz">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-salario">Salário Base</label>
                    <?php if ($podeVerSalarios): ?>
                    <input class="adm-input" type="number" id="f-salario" step="0.01" min="0" placeholder="ex: 25000.00">
                    <?php else: ?>
                    <input class="adm-input" type="text" id="f-salario" value="" placeholder="Confidencial — sem permissão" disabled>
                    <?php endif; ?>
                </div>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="f-endereco">Endereço</label>
                <input class="adm-input" type="text" id="f-endereco" maxlength="255" placeholder="ex: Av. Eduardo Mondlane, Maputo">
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="f-horario-id">Horário de Trabalho</label>
                <select class="adm-select" id="f-horario-id">
                    <option value="">— Nenhum —</option>
                    <?php foreach ($horarios as $h): ?>
                    <option value="<?php echo (int) $h['id'] ?>"><?php echo htmlspecialchars($h['nome']) ?> (<?php echo htmlspecialchars($h['hora_entrada']) ?>–<?php echo htmlspecialchars($h['hora_saida']) ?>)</option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-primary" type="button" onclick="saveFuncionario()">Adicionar Funcionário</button>
            </div>
        </div>
    </div>
</div>

<!-- ── Unidades Organizacionais ──────────────────────────────── -->
<div class="adm-tab-panel" id="tab-unidades">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Unidades Organizacionais</h2></div>
        <?php if ($unidades): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Código</th><th>Nome</th><th>Tipo</th><th>Unidade Pai</th><th>Responsável</th><th>Nº Funcionários</th><th>Estado</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($unidades as $u): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($u['codigo']) ?></td>
                    <td><?php echo htmlspecialchars($u['nome']) ?></td>
                    <td><?php echo htmlspecialchars($tipoUnidadeLabels[$u['tipo']] ?? $u['tipo']) ?></td>
                    <td class="adm-text-muted"><?php echo $u['unidade_pai_nome'] ? htmlspecialchars($u['unidade_pai_nome']) : '—' ?></td>
                    <td class="adm-text-muted"><?php echo $u['responsavel_nome'] ? htmlspecialchars($u['responsavel_nome']) : '—' ?></td>
                    <td><?php echo (int) $u['num_funcionarios'] ?></td>
                    <td><span class="adm-badge <?php echo $u['ativo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $u['ativo'] ? 'Ativo' : 'Inativo' ?></span></td>
                    <td>
                        <div style="display:flex;gap:var(--adm-sp-2);align-items:center;flex-wrap:wrap">
                            <select class="adm-select" id="mover-<?php echo (int) $u['id'] ?>" style="min-width:140px">
                                <option value="">— Mover para —</option>
                                <option value="0" <?php echo $u['parent_id'] === null ? 'selected' : '' ?>>— Raiz —</option>
                                <?php foreach ($unidades as $outra): if ((int) $outra['id'] === (int) $u['id']) continue; ?>
                                <option value="<?php echo (int) $outra['id'] ?>" <?php echo ((int) ($u['parent_id'] ?? 0) === (int) $outra['id']) ? 'selected' : '' ?>><?php echo htmlspecialchars($outra['nome']) ?></option>
                                <?php endforeach; ?>
                            </select>
                            <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" onclick="moverUnidade(<?php echo (int) $u['id'] ?>)">Mover</button>
                            <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-red)" onclick="eliminarUnidade(<?php echo (int) $u['id'] ?>)">Eliminar</button>
                        </div>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhuma unidade organizacional registada</p>
            <p class="adm-empty-sub">Adicione a primeira unidade organizacional usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Nova Unidade Organizacional</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="u-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="u-codigo" maxlength="30" placeholder="ex: RH">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="u-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="u-nome" maxlength="150" placeholder="ex: Recursos Humanos">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="u-tipo">Tipo</label>
                    <select class="adm-select" id="u-tipo">
                        <?php foreach ($tipoUnidadeLabels as $key => $label): ?>
                        <option value="<?php echo $key ?>" <?php echo $key === 'departamento' ? 'selected' : '' ?>><?php echo $label ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="u-parent">Unidade Pai</label>
                    <select class="adm-select" id="u-parent">
                        <option value="">— Nenhuma —</option>
                        <?php foreach ($unidades as $u): ?>
                        <option value="<?php echo (int) $u['id'] ?>"><?php echo htmlspecialchars($u['nome']) ?> (<?php echo htmlspecialchars($tipoUnidadeLabels[$u['tipo']] ?? $u['tipo']) ?>)</option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="u-responsavel">Responsável</label>
                    <select class="adm-select" id="u-responsavel">
                        <option value="">— Nenhum —</option>
                        <?php foreach ($todosFuncionarios as $f): ?>
                        <option value="<?php echo (int) $f['id'] ?>"><?php echo htmlspecialchars($f['nome_completo']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="u-descricao">Descrição</label>
                <input class="adm-input" type="text" id="u-descricao" maxlength="255" placeholder="ex: Gestão de pessoas e processos administrativos">
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-primary" type="button" onclick="saveUnidade()">Adicionar Unidade Organizacional</button>
            </div>
        </div>
    </div>
</div>

<!-- ── Períodos de Avaliação ──────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-periodos">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Períodos de Avaliação</h2></div>
        <?php if ($periodos): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Nome</th><th>Início</th><th>Fim</th><th>Estado</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($periodos as $p):
                    $pBadge = $periodoEstadoBadges[$p['estado']] ?? ['adm-badge--gray', $p['estado']];
                ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($p['nome']) ?></td>
                    <td class="adm-text-muted"><?php echo date('d/m/Y', strtotime($p['data_inicio'])) ?></td>
                    <td class="adm-text-muted"><?php echo date('d/m/Y', strtotime($p['data_fim'])) ?></td>
                    <td><span class="adm-badge <?php echo $pBadge[0] ?>"><?php echo $pBadge[1] ?></span></td>
                    <td>
                        <?php if ($p['estado'] === 'aberto'): ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" style="color:var(--adm-red)" onclick="encerrarPeriodo(<?php echo (int) $p['id'] ?>)">Encerrar</button>
                        <?php else: ?>—<?php endif; ?>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum período de avaliação registado</p>
            <p class="adm-empty-sub">Adicione o primeiro período usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Novo Período de Avaliação</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="p-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="p-nome" maxlength="60" placeholder="ex: 2026-S1">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="p-data-inicio">Data de Início <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="date" id="p-data-inicio">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="p-data-fim">Data de Fim <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="date" id="p-data-fim">
                </div>
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-primary" type="button" onclick="savePeriodo()">Adicionar Período</button>
            </div>
        </div>
    </div>
</div>

<!-- ── Cargos ───────────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-cargos">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Cargos</h2></div>
        <?php if ($cargos): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Código</th><th>Nome</th><th>Descrição</th><th>Faixa Salarial</th><th>Nº Funcionários</th><th>Estado</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($cargos as $c): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($c['codigo']) ?></td>
                    <td><?php echo htmlspecialchars($c['nome']) ?></td>
                    <td class="adm-text-muted"><?php echo $c['descricao'] ? htmlspecialchars($c['descricao']) : '—' ?></td>
                    <td class="adm-text-muted">
                        <?php if ($c['salario_min'] !== null || $c['salario_max'] !== null): ?>
                            <?php echo $c['salario_min'] !== null ? number_format((float) $c['salario_min'], 2, ',', '.') : '—' ?>
                            –
                            <?php echo $c['salario_max'] !== null ? number_format((float) $c['salario_max'], 2, ',', '.') : '—' ?>
                        <?php else: ?>—<?php endif; ?>
                    </td>
                    <td><?php echo (int) $c['num_funcionarios'] ?></td>
                    <td><span class="adm-badge <?php echo $c['ativo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $c['ativo'] ? 'Ativo' : 'Inativo' ?></span></td>
                    <td>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-red)" onclick="eliminarCargo(<?php echo (int) $c['id'] ?>)">Eliminar</button>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum cargo registado</p>
            <p class="adm-empty-sub">Adicione o primeiro cargo usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Novo Cargo</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="cg-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="cg-codigo" maxlength="30" placeholder="ex: TEC-ADM">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="cg-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="cg-nome" maxlength="100" placeholder="ex: Técnico Administrativo">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="cg-descricao">Descrição</label>
                    <input class="adm-input" type="text" id="cg-descricao" maxlength="255" placeholder="ex: Suporte administrativo geral">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="cg-salario-min">Salário Mínimo</label>
                    <input class="adm-input" type="number" id="cg-salario-min" step="0.01" min="0" placeholder="ex: 15000.00">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="cg-salario-max">Salário Máximo</label>
                    <input class="adm-input" type="number" id="cg-salario-max" step="0.01" min="0" placeholder="ex: 25000.00">
                </div>
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-primary" type="button" onclick="saveCargo()">Adicionar Cargo</button>
            </div>
        </div>
    </div>
</div>

<!-- ── Horários de Trabalho ─────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-horarios">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Horários de Trabalho</h2></div>
        <?php if ($horarios): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Código</th><th>Nome</th><th>Horário</th><th>Intervalo</th><th>Dias</th><th>Carga Semanal</th><th>Nº Funcionários</th><th>Estado</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($horarios as $h): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($h['codigo']) ?></td>
                    <td><?php echo htmlspecialchars($h['nome']) ?></td>
                    <td class="adm-text-muted"><?php echo htmlspecialchars($h['hora_entrada']) ?> – <?php echo htmlspecialchars($h['hora_saida']) ?></td>
                    <td class="adm-text-muted">
                        <?php if ($h['intervalo_inicio'] && $h['intervalo_fim']): ?>
                            <?php echo htmlspecialchars($h['intervalo_inicio']) ?> – <?php echo htmlspecialchars($h['intervalo_fim']) ?>
                        <?php else: ?>—<?php endif; ?>
                    </td>
                    <td class="adm-text-muted"><?php echo htmlspecialchars($formatDiasSemana($h['dias_semana'])) ?></td>
                    <td class="adm-text-muted"><?php echo $h['carga_semanal_horas'] !== null ? number_format((float) $h['carga_semanal_horas'], 1, ',', '.') . 'h' : '—' ?></td>
                    <td><?php echo (int) $h['num_funcionarios'] ?></td>
                    <td><span class="adm-badge <?php echo $h['ativo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $h['ativo'] ? 'Ativo' : 'Inativo' ?></span></td>
                    <td>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-red)" onclick="eliminarHorario(<?php echo (int) $h['id'] ?>)">Eliminar</button>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum horário de trabalho registado</p>
            <p class="adm-empty-sub">Adicione o primeiro horário usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Novo Horário de Trabalho</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="hr-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="hr-codigo" maxlength="30" placeholder="ex: HOR-NORM">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="hr-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="hr-nome" maxlength="100" placeholder="ex: Horário Normal">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="hr-descricao">Descrição</label>
                    <input class="adm-input" type="text" id="hr-descricao" maxlength="255" placeholder="ex: Horário de expediente normal">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="hr-entrada">Hora de Entrada <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="time" id="hr-entrada" value="08:00">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="hr-saida">Hora de Saída <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="time" id="hr-saida" value="17:00">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="hr-intervalo-inicio">Início do Intervalo</label>
                    <input class="adm-input" type="time" id="hr-intervalo-inicio" value="12:00">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="hr-intervalo-fim">Fim do Intervalo</label>
                    <input class="adm-input" type="time" id="hr-intervalo-fim" value="13:00">
                </div>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="hr-carga-semanal">Carga Semanal (horas)</label>
                <input class="adm-input" type="number" id="hr-carga-semanal" step="0.5" min="0" placeholder="ex: 40">
            </div>
            <div class="adm-form-group">
                <label class="adm-label">Dias da Semana</label>
                <div style="display:flex;gap:var(--adm-sp-4);flex-wrap:wrap">
                    <?php foreach ($diasSemanaLabels as $val => $label): ?>
                    <label style="display:flex;align-items:center;gap:var(--adm-sp-1);font-size:var(--adm-text-sm);font-weight:normal">
                        <input type="checkbox" class="hr-dia" value="<?php echo $val ?>" <?php echo in_array($val, ['1','2','3','4','5'], true) ? 'checked' : '' ?>>
                        <?php echo $label ?>
                    </label>
                    <?php endforeach; ?>
                </div>
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-primary" type="button" onclick="saveHorario()">Adicionar Horário</button>
            </div>
        </div>
    </div>
</div>

<!-- ── Componentes Salariais ────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-componentes-salariais">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Componentes Salariais</h2></div>
        <?php if ($componentesSalariais): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Código</th><th>Nome</th><th>Tipo</th><th>Forma de Cálculo</th><th>Valor Padrão</th><th>Nº Atribuições</th><th>Estado</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($componentesSalariais as $cs): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($cs['codigo']) ?></td>
                    <td><?php echo htmlspecialchars($cs['nome']) ?></td>
                    <td><span class="adm-badge <?php echo $cs['tipo'] === 'provento' ? 'adm-badge--green' : 'adm-badge--red' ?>"><?php echo $tipoComponenteLabels[$cs['tipo']] ?? $cs['tipo'] ?></span></td>
                    <td class="adm-text-muted"><?php echo $formaCalculoLabels[$cs['forma_calculo']] ?? $cs['forma_calculo'] ?></td>
                    <td class="adm-text-muted">
                        <?php if ($cs['valor_padrao'] !== null): ?>
                            <?php echo number_format((float) $cs['valor_padrao'], 2, ',', '.') ?><?php echo $cs['forma_calculo'] === 'percentual' ? '%' : '' ?>
                        <?php else: ?>—<?php endif; ?>
                    </td>
                    <td><?php echo (int) $cs['num_atribuicoes'] ?></td>
                    <td><span class="adm-badge <?php echo $cs['ativo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $cs['ativo'] ? 'Ativo' : 'Inativo' ?></span></td>
                    <td>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-red)" onclick="eliminarComponenteSalarial(<?php echo (int) $cs['id'] ?>)">Eliminar</button>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum componente salarial registado</p>
            <p class="adm-empty-sub">Adicione o primeiro componente usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Novo Componente Salarial</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="cs-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="cs-codigo" maxlength="30" placeholder="ex: SUB-TRANS">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="cs-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="cs-nome" maxlength="100" placeholder="ex: Subsídio de Transporte">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="cs-tipo">Tipo <span style="color:var(--adm-red)">*</span></label>
                    <select class="adm-select" id="cs-tipo">
                        <?php foreach ($tipoComponenteLabels as $key => $label): ?>
                        <option value="<?php echo $key ?>"><?php echo $label ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="cs-forma-calculo">Forma de Cálculo</label>
                    <select class="adm-select" id="cs-forma-calculo">
                        <?php foreach ($formaCalculoLabels as $key => $label): ?>
                        <option value="<?php echo $key ?>"><?php echo $label ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="cs-valor-padrao">Valor Padrão</label>
                    <input class="adm-input" type="number" id="cs-valor-padrao" step="0.01" min="0" placeholder="ex: 2500.00">
                </div>
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-primary" type="button" onclick="saveComponenteSalarial()">Adicionar Componente</button>
            </div>
        </div>
    </div>
</div>

<!-- ── Benefícios ───────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-beneficios">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Benefícios</h2></div>
        <?php if ($beneficios): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Código</th><th>Nome</th><th>Descrição</th><th>Valor Padrão</th><th>Nº Atribuições</th><th>Estado</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($beneficios as $be): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($be['codigo']) ?></td>
                    <td><?php echo htmlspecialchars($be['nome']) ?></td>
                    <td class="adm-text-muted"><?php echo $be['descricao'] ? htmlspecialchars($be['descricao']) : '—' ?></td>
                    <td class="adm-text-muted"><?php echo $be['valor_padrao'] !== null ? number_format((float) $be['valor_padrao'], 2, ',', '.') : '—' ?></td>
                    <td><?php echo (int) $be['num_atribuicoes'] ?></td>
                    <td><span class="adm-badge <?php echo $be['ativo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $be['ativo'] ? 'Ativo' : 'Inativo' ?></span></td>
                    <td>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-red)" onclick="eliminarBeneficio(<?php echo (int) $be['id'] ?>)">Eliminar</button>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum benefício registado</p>
            <p class="adm-empty-sub">Adicione o primeiro benefício usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Novo Benefício</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="be-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="be-codigo" maxlength="30" placeholder="ex: SEG-SAUDE">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="be-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="be-nome" maxlength="100" placeholder="ex: Seguro de Saúde">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="be-valor-padrao">Valor Padrão</label>
                    <input class="adm-input" type="number" id="be-valor-padrao" step="0.01" min="0" placeholder="ex: 1500.00">
                </div>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="be-descricao">Descrição</label>
                <input class="adm-input" type="text" id="be-descricao" maxlength="200" placeholder="ex: Cobertura de saúde para o funcionário e agregado familiar">
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-primary" type="button" onclick="saveBeneficio()">Adicionar Benefício</button>
            </div>
        </div>
    </div>
</div>

<!-- ── Tipos de Ausência ─────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-tipos-ausencia">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Tipos de Ausência</h2></div>
        <?php if ($tiposAusencia): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Código</th><th>Nome</th><th>Dias Anuais</th><th>Remunerada</th><th>Afeta Saldo</th><th>Nº Pedidos</th><th>Estado</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($tiposAusencia as $ta): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($ta['codigo']) ?></td>
                    <td><?php echo htmlspecialchars($ta['nome']) ?></td>
                    <td class="adm-text-muted"><?php echo $ta['dias_anuais'] !== null ? number_format((float) $ta['dias_anuais'], 2, ',', '.') : '—' ?></td>
                    <td><span class="adm-badge <?php echo $ta['remunerada'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $ta['remunerada'] ? 'Sim' : 'Não' ?></span></td>
                    <td><span class="adm-badge <?php echo $ta['afeta_saldo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $ta['afeta_saldo'] ? 'Sim' : 'Não' ?></span></td>
                    <td><?php echo (int) $ta['num_pedidos'] ?></td>
                    <td><span class="adm-badge <?php echo $ta['ativo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $ta['ativo'] ? 'Ativo' : 'Inativo' ?></span></td>
                    <td>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-red)" onclick="eliminarTipoAusencia(<?php echo (int) $ta['id'] ?>)">Eliminar</button>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum tipo de ausência registado</p>
            <p class="adm-empty-sub">Adicione o primeiro tipo de ausência usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Novo Tipo de Ausência</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="ta-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="ta-codigo" maxlength="30" placeholder="ex: FERIAS">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="ta-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="ta-nome" maxlength="60" placeholder="ex: Férias Anuais">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="ta-dias-anuais">Dias Anuais</label>
                    <input class="adm-input" type="number" id="ta-dias-anuais" step="0.5" min="0" placeholder="ex: 30">
                </div>
            </div>
            <div style="display:flex;gap:var(--adm-sp-6);align-items:center">
                <label class="adm-toggle" style="margin-bottom:0">
                    <input type="checkbox" id="ta-remunerada" checked>
                    <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                    <span class="adm-toggle-label">Remunerada</span>
                </label>
                <label class="adm-toggle" style="margin-bottom:0">
                    <input type="checkbox" id="ta-afeta-saldo">
                    <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                    <span class="adm-toggle-label">Desconta do saldo de férias/licenças</span>
                </label>
            </div>
            <div style="display:flex;gap:var(--adm-sp-3);margin-top:var(--adm-sp-4)">
                <button class="adm-btn adm-btn-primary" type="button" onclick="saveTipoAusencia()">Adicionar Tipo de Ausência</button>
            </div>
        </div>
    </div>
</div>

<!-- ── Critérios de Avaliação ────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-criterios-avaliacao">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Critérios de Avaliação</h2></div>
        <?php if ($criteriosAvaliacao): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Código</th><th>Nome</th><th>Descrição</th><th>Peso</th><th>Nº Usos</th><th>Estado</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($criteriosAvaliacao as $ca): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($ca['codigo']) ?></td>
                    <td><?php echo htmlspecialchars($ca['nome']) ?></td>
                    <td class="adm-text-muted"><?php echo htmlspecialchars($ca['descricao'] ?? '—') ?></td>
                    <td><?php echo number_format((float) $ca['peso'], 2, ',', '.') ?></td>
                    <td><?php echo (int) $ca['num_usos'] ?></td>
                    <td><span class="adm-badge <?php echo $ca['ativo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $ca['ativo'] ? 'Ativo' : 'Inativo' ?></span></td>
                    <td>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-red)" onclick="eliminarCriterioAvaliacao(<?php echo (int) $ca['id'] ?>)">Eliminar</button>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum critério de avaliação registado</p>
            <p class="adm-empty-sub">Adicione o primeiro critério usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Novo Critério de Avaliação</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="ca-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="ca-codigo" maxlength="30" placeholder="ex: PRODUTIVIDADE">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="ca-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="ca-nome" maxlength="100" placeholder="ex: Produtividade">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="ca-peso">Peso</label>
                    <input class="adm-input" type="number" id="ca-peso" step="0.1" min="0" value="1">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="ca-descricao">Descrição</label>
                    <input class="adm-input" type="text" id="ca-descricao" maxlength="255" placeholder="Descrição opcional do critério">
                </div>
            </div>
            <div style="display:flex;gap:var(--adm-sp-3);margin-top:var(--adm-sp-4)">
                <button class="adm-btn adm-btn-primary" type="button" onclick="saveCriterioAvaliacao()">Adicionar Critério</button>
            </div>
        </div>
    </div>
</div>

<!-- ── Formações ─────────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-formacoes">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Formações</h2></div>
        <?php if ($formacoes): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Código</th><th>Nome</th><th>Categoria</th><th>Duração (h)</th><th>Entidade Formadora</th><th>Nº Participações</th><th>Estado</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($formacoes as $f): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($f['codigo']) ?></td>
                    <td><?php echo htmlspecialchars($f['nome']) ?></td>
                    <td><?php echo htmlspecialchars($categoriaFormacaoLabels[$f['categoria']] ?? $f['categoria']) ?></td>
                    <td><?php echo $f['duracao_horas'] !== null ? number_format((float) $f['duracao_horas'], 1, ',', '.') : '—' ?></td>
                    <td class="adm-text-muted"><?php echo htmlspecialchars($f['entidade_formadora'] ?? '—') ?></td>
                    <td><?php echo (int) $f['num_participacoes'] ?></td>
                    <td><span class="adm-badge <?php echo $f['ativo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $f['ativo'] ? 'Ativa' : 'Inativa' ?></span></td>
                    <td>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-red)" onclick="eliminarFormacao(<?php echo (int) $f['id'] ?>)">Eliminar</button>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhuma formação registada</p>
            <p class="adm-empty-sub">Adicione a primeira formação usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Nova Formação</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="fo-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="fo-codigo" maxlength="30" placeholder="ex: FORM-SEG-01">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="fo-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="fo-nome" maxlength="100" placeholder="ex: Segurança no Trabalho">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="fo-categoria">Categoria</label>
                    <select class="adm-select" id="fo-categoria">
                        <option value="tecnica">Técnica</option>
                        <option value="comportamental">Comportamental</option>
                        <option value="obrigatoria">Obrigatória</option>
                        <option value="outra">Outra</option>
                    </select>
                </div>
            </div>
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="fo-duracao-horas">Duração (h)</label>
                    <input class="adm-input" type="number" id="fo-duracao-horas" step="0.5" min="0" placeholder="ex: 8">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="fo-entidade-formadora">Entidade Formadora</label>
                    <input class="adm-input" type="text" id="fo-entidade-formadora" maxlength="150" placeholder="ex: Instituto XYZ">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="fo-descricao">Descrição</label>
                    <input class="adm-input" type="text" id="fo-descricao" maxlength="255" placeholder="Descrição opcional da formação">
                </div>
            </div>
            <div style="display:flex;gap:var(--adm-sp-3);margin-top:var(--adm-sp-4)">
                <button class="adm-btn adm-btn-primary" type="button" onclick="saveFormacao()">Adicionar Formação</button>
            </div>
        </div>
    </div>
</div>

<!-- ── Processamento Salarial ─────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-processamento-salarial">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Folhas de Pagamento</h2></div>
        <?php if ($folhasPagamento): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Período</th><th>Nº Funcionários</th><th>Total Proventos</th><th>Total Descontos</th><th>Total Líquido</th><th>Estado</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($folhasPagamento as $fp):
                    $fpBadge = $folhaPagamentoEstadoBadges[$fp['estado']] ?? ['adm-badge--gray', $fp['estado']];
                ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($mesesLabels[$fp['mes']] ?? (string) $fp['mes']) ?> de <?php echo (int) $fp['ano'] ?></td>
                    <td><?php echo (int) $fp['num_funcionarios'] ?></td>
                    <td class="adm-text-muted"><?php echo rhValorSalarial($fp['total_proventos'] !== null ? (float) $fp['total_proventos'] : null, $podeVerSalarios) ?></td>
                    <td class="adm-text-muted"><?php echo rhValorSalarial($fp['total_descontos'] !== null ? (float) $fp['total_descontos'] : null, $podeVerSalarios) ?></td>
                    <td class="adm-fw-600"><?php echo rhValorSalarial($fp['total_liquido'] !== null ? (float) $fp['total_liquido'] : null, $podeVerSalarios) ?></td>
                    <td><span class="adm-badge <?php echo $fpBadge[0] ?>"><?php echo $fpBadge[1] ?></span></td>
                    <td>
                        <div style="display:flex;gap:var(--adm-sp-2);flex-wrap:wrap">
                        <?php if (in_array($fp['estado'], ['processada', 'paga'], true)): ?>
                        <a class="adm-btn adm-btn-ghost adm-btn-sm" href="<?php echo htmlspecialchars($app->routes->path('rh_folha_pagamento', ['id' => $fp['id']])) ?>">Ver</a>
                        <?php endif; ?>
                        <?php if ($fp['estado'] === 'aberta'): ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-green)" onclick="processarFolhaPagamento(<?php echo (int) $fp['id'] ?>)">Processar</button>
                        <?php endif; ?>
                        <?php if ($fp['estado'] === 'processada'): ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-green)" onclick="pagarFolhaPagamento(<?php echo (int) $fp['id'] ?>)">Pagar</button>
                        <?php endif; ?>
                        <?php if (in_array($fp['estado'], ['aberta', 'processada'], true)): ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-red)" onclick="cancelarFolhaPagamento(<?php echo (int) $fp['id'] ?>)">Cancelar</button>
                        <?php endif; ?>
                        </div>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhuma folha de pagamento registada</p>
            <p class="adm-empty-sub">Crie a primeira folha de pagamento usando o formulário abaixo.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Nova Folha de Pagamento</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="fp-mes">Mês <span style="color:var(--adm-red)">*</span></label>
                    <select class="adm-select" id="fp-mes">
                        <?php foreach ($mesesLabels as $num => $nome): ?>
                        <option value="<?php echo $num ?>" <?php echo $num === (int) date('n') ? 'selected' : '' ?>><?php echo $nome ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="fp-ano">Ano <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="number" id="fp-ano" min="2000" max="2100" value="<?php echo date('Y') ?>">
                </div>
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-primary" type="button" onclick="saveFolhaPagamento()">Criar Folha de Pagamento</button>
            </div>
        </div>
    </div>
</div>

<script>
const CSRF = '<?php echo $csrf ?>';

// ── Tabs ─────────────────────────────────────────────────────
function switchTab(name, btn) {
    document.querySelectorAll('.adm-tab-panel').forEach(p => p.classList.remove('active'));
    document.querySelectorAll('.adm-tab').forEach(b => b.classList.remove('active'));
    document.getElementById('tab-' + name).classList.add('active');
    btn.classList.add('active');
}

document.addEventListener('DOMContentLoaded', () => {
    const tabs = ['funcionarios', 'unidades', 'periodos', 'cargos', 'horarios', 'componentes-salariais', 'beneficios', 'tipos-ausencia', 'criterios-avaliacao', 'formacoes', 'processamento-salarial'];
    const hash = location.hash.replace('#', '');
    const idx  = tabs.indexOf(hash);
    if (idx > 0) {
        const btn = document.querySelectorAll('#mainTabs .adm-tab')[idx];
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
            location.hash = tab;
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}

// ── Filtros ──────────────────────────────────────────────────
function applyFiltros() {
    const params = new URLSearchParams();
    const q   = document.getElementById('fSearch').value.trim();
    const uni = document.getElementById('fUnidade').value;
    const est = document.getElementById('fEstado').value;
    if (q)   params.set('q', q);
    if (uni) params.set('unit_id', uni);
    if (est) params.set('estado', est);
    location.href = '?' + params.toString() + '#funcionarios';
}

// ── Funcionários ─────────────────────────────────────────────
function onCargoFuncionarioChange() {
    const select = document.getElementById('f-cargo-id');
    document.getElementById('f-cargo-texto').style.display = select.value === 'outro' ? '' : 'none';
}

function saveFuncionario() {
    const nome = document.getElementById('f-nome').value.trim();
    if (!nome) { showToast('O nome completo é obrigatório.', 'error'); return; }

    const unidade = document.getElementById('f-unidade').value;
    const salario = document.getElementById('f-salario').value;
    const cargoSelect = document.getElementById('f-cargo-id').value;
    const cargoId   = (cargoSelect && cargoSelect !== 'outro') ? Number(cargoSelect) : null;
    const cargoTexto = cargoSelect === 'outro' ? (document.getElementById('f-cargo-texto').value.trim() || null) : null;

    const horario = document.getElementById('f-horario-id').value;

    postJSON('/nexora/api/rh_funcionario_save', {
        nome_completo: nome,
        numero_funcionario: document.getElementById('f-numero').value.trim() || null,
        unit_id: unidade ? Number(unidade) : null,
        cargo_id: cargoId,
        cargo: cargoTexto,
        horario_id: horario ? Number(horario) : null,
        tipo_contrato: document.getElementById('f-tipo-contrato').value,
        data_admissao: document.getElementById('f-data-admissao').value || null,
        data_nascimento: document.getElementById('f-data-nascimento').value || null,
        genero: document.getElementById('f-genero').value || null,
        nuit: document.getElementById('f-nuit').value.trim() || null,
        telefone: document.getElementById('f-telefone').value.trim() || null,
        email: document.getElementById('f-email').value.trim() || null,
        endereco: document.getElementById('f-endereco').value.trim() || null,
        salario_base: salario ? Number(salario) : null,
        csrf: CSRF
    }, 'funcionarios');
}

// ── Unidades Organizacionais ────────────────────────────────────
function saveUnidade() {
    const codigo = document.getElementById('u-codigo').value.trim();
    const nome   = document.getElementById('u-nome').value.trim();
    if (!codigo || !nome) { showToast('Código e nome são obrigatórios.', 'error'); return; }

    const parent      = document.getElementById('u-parent').value;
    const responsavel = document.getElementById('u-responsavel').value;
    postJSON('/nexora/api/rh_unidade_save', {
        codigo,
        nome,
        tipo: document.getElementById('u-tipo').value,
        parent_id: parent ? Number(parent) : null,
        descricao: document.getElementById('u-descricao').value.trim() || null,
        responsavel_id: responsavel ? Number(responsavel) : null,
        csrf: CSRF
    }, 'unidades');
}

function eliminarUnidade(id) {
    openConfirm('Eliminar unidade', 'Pretende eliminar esta unidade organizacional? Esta ação não pode ser revertida.', async () => {
        await postJSON('/nexora/api/rh_unidade_remover', { id, csrf: CSRF }, 'unidades');
    });
}

function moverUnidade(id) {
    const select = document.getElementById('mover-' + id);
    const valor  = select.value;
    if (valor === '') { showToast('Selecione a unidade-pai de destino.', 'error'); return; }

    postJSON('/nexora/api/rh_unidade_mover', {
        id,
        parent_id: valor === '0' ? null : Number(valor),
        csrf: CSRF
    }, 'unidades');
}

// ── Períodos de Avaliação ────────────────────────────────────
function savePeriodo() {
    const nome       = document.getElementById('p-nome').value.trim();
    const dataInicio = document.getElementById('p-data-inicio').value;
    const dataFim    = document.getElementById('p-data-fim').value;
    if (!nome || !dataInicio || !dataFim) { showToast('Nome e datas de início e fim são obrigatórios.', 'error'); return; }
    if (dataFim < dataInicio) { showToast('A data de fim deve ser igual ou posterior à data de início.', 'error'); return; }

    postJSON('/nexora/api/rh_periodo_save', {
        nome,
        data_inicio: dataInicio,
        data_fim: dataFim,
        csrf: CSRF
    }, 'periodos');
}

function encerrarPeriodo(id) {
    openConfirm('Encerrar período', 'Pretende encerrar este período de avaliação? Não será possível registar novas avaliações neste período.', async () => {
        await postJSON('/nexora/api/rh_periodo_encerrar', { id, csrf: CSRF }, 'periodos');
    });
}

// ── Cargos ───────────────────────────────────────────────────
function saveCargo() {
    const codigo = document.getElementById('cg-codigo').value.trim();
    const nome   = document.getElementById('cg-nome').value.trim();
    if (!codigo || !nome) { showToast('Código e nome são obrigatórios.', 'error'); return; }

    const salarioMin = document.getElementById('cg-salario-min').value;
    const salarioMax = document.getElementById('cg-salario-max').value;
    if (salarioMin && salarioMax && Number(salarioMax) < Number(salarioMin)) {
        showToast('O salário máximo deve ser igual ou superior ao salário mínimo.', 'error');
        return;
    }

    postJSON('/nexora/api/rh_cargo_save', {
        codigo,
        nome,
        descricao: document.getElementById('cg-descricao').value.trim() || null,
        salario_min: salarioMin ? Number(salarioMin) : null,
        salario_max: salarioMax ? Number(salarioMax) : null,
        csrf: CSRF
    }, 'cargos');
}

function eliminarCargo(id) {
    openConfirm('Eliminar cargo', 'Pretende eliminar este cargo? Esta ação não pode ser revertida.', async () => {
        await postJSON('/nexora/api/rh_cargo_remover', { id, csrf: CSRF }, 'cargos');
    });
}

// ── Horários de Trabalho ─────────────────────────────────────
function saveHorario() {
    const codigo      = document.getElementById('hr-codigo').value.trim();
    const nome        = document.getElementById('hr-nome').value.trim();
    const horaEntrada = document.getElementById('hr-entrada').value;
    const horaSaida   = document.getElementById('hr-saida').value;
    if (!codigo || !nome) { showToast('Código e nome são obrigatórios.', 'error'); return; }
    if (!horaEntrada || !horaSaida) { showToast('A hora de entrada e a hora de saída são obrigatórias.', 'error'); return; }

    const dias = Array.from(document.querySelectorAll('.hr-dia:checked')).map(c => c.value);
    if (!dias.length) { showToast('Selecione pelo menos um dia da semana.', 'error'); return; }

    const intervaloInicio = document.getElementById('hr-intervalo-inicio').value;
    const intervaloFim    = document.getElementById('hr-intervalo-fim').value;
    const cargaSemanal    = document.getElementById('hr-carga-semanal').value;

    postJSON('/nexora/api/rh_horario_save', {
        codigo,
        nome,
        descricao: document.getElementById('hr-descricao').value.trim() || null,
        hora_entrada: horaEntrada,
        hora_saida: horaSaida,
        intervalo_inicio: intervaloInicio || null,
        intervalo_fim: intervaloFim || null,
        dias_semana: dias.join(','),
        carga_semanal_horas: cargaSemanal ? Number(cargaSemanal) : null,
        csrf: CSRF
    }, 'horarios');
}

function eliminarHorario(id) {
    openConfirm('Eliminar horário', 'Pretende eliminar este horário de trabalho? Esta ação não pode ser revertida.', async () => {
        await postJSON('/nexora/api/rh_horario_remover', { id, csrf: CSRF }, 'horarios');
    });
}

// ── Componentes Salariais ─────────────────────────────────────
function saveComponenteSalarial() {
    const codigo = document.getElementById('cs-codigo').value.trim();
    const nome   = document.getElementById('cs-nome').value.trim();
    if (!codigo || !nome) { showToast('Código e nome são obrigatórios.', 'error'); return; }

    const valorPadrao = document.getElementById('cs-valor-padrao').value;

    postJSON('/nexora/api/rh_componente_salarial_save', {
        codigo,
        nome,
        tipo: document.getElementById('cs-tipo').value,
        forma_calculo: document.getElementById('cs-forma-calculo').value,
        valor_padrao: valorPadrao ? Number(valorPadrao) : null,
        csrf: CSRF
    }, 'componentes-salariais');
}

function eliminarComponenteSalarial(id) {
    openConfirm('Eliminar componente salarial', 'Pretende eliminar este componente salarial? Esta ação não pode ser revertida.', async () => {
        await postJSON('/nexora/api/rh_componente_salarial_remover', { id, csrf: CSRF }, 'componentes-salariais');
    });
}

// ── Benefícios ─────────────────────────────────────────────────
function saveBeneficio() {
    const codigo = document.getElementById('be-codigo').value.trim();
    const nome   = document.getElementById('be-nome').value.trim();
    if (!codigo || !nome) { showToast('Código e nome são obrigatórios.', 'error'); return; }

    const valorPadrao = document.getElementById('be-valor-padrao').value;

    postJSON('/nexora/api/rh_beneficio_save', {
        codigo,
        nome,
        descricao: document.getElementById('be-descricao').value.trim() || null,
        valor_padrao: valorPadrao ? Number(valorPadrao) : null,
        csrf: CSRF
    }, 'beneficios');
}

function eliminarBeneficio(id) {
    openConfirm('Eliminar benefício', 'Pretende eliminar este benefício? Esta ação não pode ser revertida.', async () => {
        await postJSON('/nexora/api/rh_beneficio_remover', { id, csrf: CSRF }, 'beneficios');
    });
}

// ── Tipos de Ausência ────────────────────────────────────────
function saveTipoAusencia() {
    const codigo = document.getElementById('ta-codigo').value.trim();
    const nome   = document.getElementById('ta-nome').value.trim();
    if (!codigo || !nome) { showToast('Código e nome são obrigatórios.', 'error'); return; }

    const diasAnuais = document.getElementById('ta-dias-anuais').value;

    postJSON('/nexora/api/rh_tipo_ausencia_save', {
        codigo,
        nome,
        dias_anuais: diasAnuais ? Number(diasAnuais) : null,
        remunerada: document.getElementById('ta-remunerada').checked,
        afeta_saldo: document.getElementById('ta-afeta-saldo').checked,
        csrf: CSRF
    }, 'tipos-ausencia');
}

function eliminarTipoAusencia(id) {
    openConfirm('Eliminar tipo de ausência', 'Pretende eliminar este tipo de ausência? Esta ação não pode ser revertida.', async () => {
        await postJSON('/nexora/api/rh_tipo_ausencia_remover', { id, csrf: CSRF }, 'tipos-ausencia');
    });
}

// ── Critérios de Avaliação ─────────────────────────────────────
function saveCriterioAvaliacao() {
    const codigo = document.getElementById('ca-codigo').value.trim();
    const nome   = document.getElementById('ca-nome').value.trim();
    if (!codigo || !nome) { showToast('Código e nome são obrigatórios.', 'error'); return; }

    const peso = document.getElementById('ca-peso').value;

    postJSON('/nexora/api/rh_criterio_avaliacao_save', {
        codigo,
        nome,
        descricao: document.getElementById('ca-descricao').value.trim() || null,
        peso: peso ? Number(peso) : 1,
        csrf: CSRF
    }, 'criterios-avaliacao');
}

function eliminarCriterioAvaliacao(id) {
    openConfirm('Eliminar critério de avaliação', 'Pretende eliminar este critério de avaliação? Esta ação não pode ser revertida.', async () => {
        await postJSON('/nexora/api/rh_criterio_avaliacao_remover', { id, csrf: CSRF }, 'criterios-avaliacao');
    });
}

// ── Formações ────────────────────────────────────────────────
function saveFormacao() {
    const codigo = document.getElementById('fo-codigo').value.trim();
    const nome   = document.getElementById('fo-nome').value.trim();
    if (!codigo || !nome) { showToast('Código e nome são obrigatórios.', 'error'); return; }

    const duracaoHoras = document.getElementById('fo-duracao-horas').value;

    postJSON('/nexora/api/rh_formacao_save', {
        codigo,
        nome,
        categoria: document.getElementById('fo-categoria').value || 'tecnica',
        duracao_horas: duracaoHoras ? Number(duracaoHoras) : null,
        entidade_formadora: document.getElementById('fo-entidade-formadora').value.trim() || null,
        descricao: document.getElementById('fo-descricao').value.trim() || null,
        csrf: CSRF
    }, 'formacoes');
}

function eliminarFormacao(id) {
    openConfirm('Eliminar formação', 'Pretende eliminar esta formação? Esta ação não pode ser revertida.', async () => {
        await postJSON('/nexora/api/rh_formacao_remover', { id, csrf: CSRF }, 'formacoes');
    });
}

// ── Processamento Salarial ─────────────────────────────────────
function saveFolhaPagamento() {
    const mes = document.getElementById('fp-mes').value;
    const ano = document.getElementById('fp-ano').value;
    if (!mes || !ano) { showToast('O mês e o ano são obrigatórios.', 'error'); return; }

    postJSON('/nexora/api/rh_folha_pagamento_save', {
        mes: Number(mes),
        ano: Number(ano),
        csrf: CSRF
    }, 'processamento-salarial');
}

function processarFolhaPagamento(id) {
    openConfirm('Processar folha de pagamento', 'Pretende processar esta folha de pagamento? Serão gerados os recibos de vencimento para todos os funcionários ativos.', async () => {
        await postJSON('/nexora/api/rh_folha_pagamento_processar', { id, csrf: CSRF }, 'processamento-salarial');
    });
}

function pagarFolhaPagamento(id) {
    openConfirm('Marcar como paga', 'Pretende marcar esta folha de pagamento e todos os seus recibos como pagos?', async () => {
        await postJSON('/nexora/api/rh_folha_pagamento_pagar', { id, csrf: CSRF }, 'processamento-salarial');
    });
}

function cancelarFolhaPagamento(id) {
    openConfirm('Cancelar folha de pagamento', 'Pretende cancelar esta folha de pagamento?', async () => {
        await postJSON('/nexora/api/rh_folha_pagamento_cancelar', { id, csrf: CSRF }, 'processamento-salarial');
    });
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
