<?php

    $centros = $app->nexora->call('GET', '/api/centros-custo/cost-centers')['body'] ?? [];

    $tipoLabels = [
        'centro'      => 'Centro',
        'departamento' => 'Departamento',
        'projecto'    => 'Projecto',
    ];

    $mesesLabels = [
        1 => 'Janeiro', 2 => 'Fevereiro', 3 => 'Março', 4 => 'Abril',
        5 => 'Maio', 6 => 'Junho', 7 => 'Julho', 8 => 'Agosto',
        9 => 'Setembro', 10 => 'Outubro', 11 => 'Novembro', 12 => 'Dezembro',
    ];

    $centrosById = [];
    foreach ($centros as $c) {
        $centrosById[$c['id']] = $c;
    }

    $byParent = [];
    foreach ($centros as $c) {
        $byParent[$c['parent_id'] ?? 0][] = $c;
    }

    function renderCentroNode(array $c, array $byParent, array $tipoLabels): void
    {
        $children = $byParent[$c['id']] ?? [];
        ?>
        <li class="adm-tree-node">
            <div class="adm-tree-card"
                 data-id="<?php echo (int) $c['id'] ?>"
                 data-parent-id="<?php echo $c['parent_id'] !== null ? (int) $c['parent_id'] : '' ?>"
                 data-codigo="<?php echo htmlspecialchars($c['codigo']) ?>"
                 data-nome="<?php echo htmlspecialchars($c['nome']) ?>"
                 data-tipo="<?php echo htmlspecialchars($c['tipo']) ?>"
                 data-gestor-user-id="<?php echo $c['gestor_user_id'] !== null ? (int) $c['gestor_user_id'] : '' ?>"
                 data-activo="<?php echo $c['activo'] ? '1' : '0' ?>">
                <div class="adm-tree-card-title"><?php echo htmlspecialchars($c['codigo'] . ' - ' . $c['nome']) ?></div>
                <div class="adm-tree-card-meta">
                    <span class="adm-badge adm-badge--blue"><?php echo htmlspecialchars($tipoLabels[$c['tipo']] ?? $c['tipo']) ?></span>
                    <?php if (! $c['activo']): ?>
                    <span class="adm-badge adm-badge--gray">Inativo</span>
                    <?php endif; ?>
                </div>
                <div class="adm-actions" style="margin-top:var(--adm-sp-2)">
                    <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" onclick="editCentro(this)">Editar</button>
                    <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-red)" onclick="deleteCentro(this)">Eliminar</button>
                </div>
            </div>
            <?php if ($children): ?>
            <ul class="adm-tree-children">
                <?php foreach ($children as $ch) renderCentroNode($ch, $byParent, $tipoLabels); ?>
            </ul>
            <?php endif; ?>
        </li>
        <?php
    }

    function renderCentroOptions(array $byParent, int $parentKey = 0, int $depth = 0): void
    {
        foreach ($byParent[$parentKey] ?? [] as $c) {
            $prefix = str_repeat('— ', $depth);
            ?>
            <option value="<?php echo (int) $c['id'] ?>"><?php echo htmlspecialchars($prefix . $c['codigo'] . ' - ' . $c['nome']) ?></option>
            <?php
            renderCentroOptions($byParent, (int) $c['id'], $depth + 1);
        }
    }

    $anoFiltro = $app->request->queryInt('ano', 0) ?: (int) date('Y');
    $mesFiltro = $app->request->queryInt('mes', 0) ?? 0;

    $orcamentos  = [];
    $vsRealizado = ['linhas' => [], 'totais' => ['valor_orcamentado' => 0, 'valor_realizado' => 0, 'variacao' => 0]];
    if ($centros) {
        $orcamentos = $app->nexora->call('GET', '/api/centros-custo/budgets', null, ['ano' => $anoFiltro])['body'] ?? [];

        $vsQuery = ['ano' => $anoFiltro];
        if ($mesFiltro > 0) {
            $vsQuery['mes'] = $mesFiltro;
        }
        $vsRealizado = $app->nexora->call('GET', '/api/centros-custo/budgets/vs-realizado', null, $vsQuery)['body'] ?? $vsRealizado;
    }

    $alocFiltro = $app->request->queryInt('cc', 0) ?: 0;
    $alocQuery  = ['limit' => 100];
    if ($alocFiltro > 0) {
        $alocQuery['cost_center_id'] = $alocFiltro;
    }
    $alocacoes = $app->nexora->call('GET', '/api/centros-custo/allocations', null, $alocQuery)['body'] ?? [];

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Centros de Custo';
    $activePage = 'centros_custo';
    $breadcrumb = [['Admin', '/nexora/'], ['Centros de Custo', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Centros de Custo</h1>
</div>

<div class="adm-tabs" id="mainTabs">
    <button class="adm-tab active" onclick="switchTab('centros',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><path d="M9 22V12h6v10"/></svg>
        Centros de Custo
        <?php if (count($centros)): ?><span class="adm-tab-badge"><?php echo count($centros) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('orcamentos',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="18" rx="2"/><line x1="2" y1="9" x2="22" y2="9"/><line x1="9" y1="9" x2="9" y2="21"/></svg>
        Orçamentos
        <?php if (count($orcamentos)): ?><span class="adm-tab-badge"><?php echo count($orcamentos) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('alocacoes',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12a9 9 0 1 1-9-9c2.52 0 4.93 1 6.74 2.74L21 8"/><path d="M21 3v5h-5"/></svg>
        Alocações
        <?php if (count($alocacoes)): ?><span class="adm-tab-badge"><?php echo count($alocacoes) ?></span><?php endif; ?>
    </button>
</div>

<!-- ── Centros de Custo ───────────────────────────────────────── -->
<div class="adm-tab-panel active" id="tab-centros">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Centros de Custo</h2></div>
        <?php if ($centros): ?>
        <div class="adm-tree-wrap">
            <ul class="adm-tree adm-tree-root">
                <?php foreach ($byParent[0] ?? [] as $raiz) renderCentroNode($raiz, $byParent, $tipoLabels); ?>
            </ul>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum centro de custo criado</p>
            <p class="adm-empty-sub">Adicione centros de custo para organizar orçamentos e alocações.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6" id="centroFormCard">
        <div class="adm-card-header"><h2 class="adm-card-title" id="centroFormTitle">Adicionar Centro de Custo</h2></div>
        <div class="adm-card-body">
            <input type="hidden" id="c-id" value="">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="c-parent">Centro Pai</label>
                    <select class="adm-select" id="c-parent">
                        <option value="">— Raiz —</option>
                        <?php renderCentroOptions($byParent); ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="c-tipo">Tipo</label>
                    <select class="adm-select" id="c-tipo">
                        <?php foreach ($tipoLabels as $key => $label): ?>
                        <option value="<?php echo $key ?>"><?php echo $label ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="c-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="c-codigo" maxlength="30" placeholder="ex: CC-001">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="c-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="c-nome" maxlength="150" placeholder="ex: Direção Comercial">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="c-gestor">ID do Gestor (utilizador)</label>
                    <input class="adm-input" type="number" id="c-gestor" min="1" placeholder="opcional">
                </div>
            </div>
            <label class="adm-toggle" id="c-ativo-wrap" style="margin-bottom:var(--adm-sp-4);display:none">
                <input type="checkbox" id="c-ativo" checked>
                <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                <span class="adm-toggle-label">Ativo</span>
            </label>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-outline" type="button" onclick="resetCentroForm()">Limpar</button>
                <button class="adm-btn adm-btn-primary" type="button" id="btnCentroSave" onclick="saveCentro()">Adicionar Centro de Custo</button>
            </div>
        </div>
    </div>
</div>

<!-- ── Orçamentos ─────────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-orcamentos">
    <?php if (! $centros): ?>
    <div class="adm-card">
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum centro de custo registado</p>
            <p class="adm-text-muted">Crie centros de custo antes de definir orçamentos.</p>
        </div>
    </div>
    <?php else: ?>

    <div class="adm-card adm-mb-6">
        <div class="adm-filter-bar">
            <div class="adm-form-group" style="margin-bottom:0">
                <label class="adm-label" for="fAno">Ano</label>
                <input class="adm-input" type="number" id="fAno" value="<?php echo (int) $anoFiltro ?>" style="width:120px" onchange="aplicarFiltroOrcamento()">
            </div>
            <div class="adm-form-group" style="margin-bottom:0">
                <label class="adm-label" for="fMes">Período</label>
                <select class="adm-select" id="fMes" onchange="aplicarFiltroOrcamento()" style="width:200px">
                    <option value="0" <?php echo $mesFiltro === 0 ? 'selected' : '' ?>>Anual (todos os meses)</option>
                    <?php foreach ($mesesLabels as $num => $label): ?>
                    <option value="<?php echo $num ?>" <?php echo $mesFiltro === $num ? 'selected' : '' ?>><?php echo $label ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
        </div>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header">
            <h2 class="adm-card-title">
                Orçado vs Realizado — <?php echo $anoFiltro ?><?php echo $mesFiltro === 0 ? ' (Anual)' : ' / ' . htmlspecialchars($mesesLabels[$mesFiltro]) ?>
            </h2>
        </div>
        <div class="adm-card-body">
            <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:var(--adm-sp-5)" class="adm-mb-6">
                <div class="adm-detail-pair">
                    <span class="adm-detail-pair-label">Total Orçado</span>
                    <span class="adm-detail-pair-value adm-fw-600"><?php echo number_format((float) $vsRealizado['totais']['valor_orcamentado'], 2, ',', '.') ?></span>
                </div>
                <div class="adm-detail-pair">
                    <span class="adm-detail-pair-label">Total Realizado</span>
                    <span class="adm-detail-pair-value adm-fw-600"><?php echo number_format((float) $vsRealizado['totais']['valor_realizado'], 2, ',', '.') ?></span>
                </div>
                <div class="adm-detail-pair">
                    <span class="adm-detail-pair-label">Variação Total</span>
                    <span class="adm-detail-pair-value adm-fw-600" style="color:<?php echo (float) $vsRealizado['totais']['variacao'] >= 0 ? 'var(--adm-green)' : 'var(--adm-red)' ?>">
                        <?php echo number_format((float) $vsRealizado['totais']['variacao'], 2, ',', '.') ?>
                    </span>
                </div>
            </div>
            <?php if ($vsRealizado['linhas']): ?>
            <div class="adm-table-wrap">
                <table class="adm-table">
                    <thead>
                        <tr>
                            <th>Centro de Custo</th>
                            <th>Orçado</th>
                            <th>Realizado</th>
                            <th>Variação</th>
                            <th>Variação %</th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php foreach ($vsRealizado['linhas'] as $v): ?>
                    <tr>
                        <td class="adm-fw-600"><?php echo htmlspecialchars($v['codigo'] . ' - ' . $v['nome']) ?></td>
                        <td><?php echo number_format((float) $v['valor_orcamentado'], 2, ',', '.') ?></td>
                        <td><?php echo number_format((float) $v['valor_realizado'], 2, ',', '.') ?></td>
                        <td style="color:<?php echo (float) $v['variacao'] >= 0 ? 'var(--adm-green)' : 'var(--adm-red)' ?>">
                            <?php echo number_format((float) $v['variacao'], 2, ',', '.') ?>
                        </td>
                        <td style="color:<?php echo (float) $v['variacao'] >= 0 ? 'var(--adm-green)' : 'var(--adm-red)' ?>">
                            <?php echo $v['variacao_pct'] !== null ? number_format((float) $v['variacao_pct'], 1, ',', '.') . '%' : '—' ?>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
            <?php else: ?>
            <div class="adm-empty">
                <p class="adm-empty-title">Nenhum dado disponível para este período</p>
            </div>
            <?php endif; ?>
        </div>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Orçamentos de <?php echo $anoFiltro ?></h2></div>
        <?php if ($orcamentos): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr>
                        <th>Centro de Custo</th>
                        <th>Período</th>
                        <th>Valor Orçamentado</th>
                        <th>Moeda</th>
                        <th>Ações</th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach ($orcamentos as $o): ?>
                <tr data-id="<?php echo (int) $o['id'] ?>"
                    data-cost-center-id="<?php echo (int) $o['cost_center_id'] ?>"
                    data-mes="<?php echo $o['mes'] !== null ? (int) $o['mes'] : '' ?>"
                    data-valor-orcamentado="<?php echo (float) $o['valor_orcamentado'] ?>"
                    data-moeda="<?php echo htmlspecialchars($o['moeda']) ?>">
                    <td class="adm-fw-600"><?php
                        $cc = $centrosById[$o['cost_center_id']] ?? null;
                        echo $cc ? htmlspecialchars($cc['codigo'] . ' - ' . $cc['nome']) : '#' . (int) $o['cost_center_id'];
                    ?></td>
                    <td>
                        <?php if ($o['mes'] === null): ?>
                        <span class="adm-badge adm-badge--blue">Anual</span>
                        <?php else: ?>
                        <?php echo htmlspecialchars($mesesLabels[$o['mes']] ?? (string) $o['mes']) ?>
                        <?php endif; ?>
                    </td>
                    <td><?php echo number_format((float) $o['valor_orcamentado'], 2, ',', '.') ?></td>
                    <td><?php echo htmlspecialchars($o['moeda']) ?></td>
                    <td>
                        <div class="adm-actions">
                            <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" onclick="editOrcamento(this)">Editar</button>
                            <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" style="color:var(--adm-red)" onclick="deleteOrcamento(this)">Eliminar</button>
                        </div>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum orçamento registado para <?php echo $anoFiltro ?></p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card">
        <div class="adm-card-header"><h2 class="adm-card-title" id="orcFormTitle">Novo Orçamento</h2></div>
        <div class="adm-card-body">
            <input type="hidden" id="o-id" value="0">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="o-centro">Centro de Custo <span style="color:var(--adm-red)">*</span></label>
                    <select class="adm-select" id="o-centro">
                        <option value="">Seleciona um centro de custo</option>
                        <?php foreach ($centros as $c): ?>
                        <option value="<?php echo (int) $c['id'] ?>"><?php echo htmlspecialchars($c['codigo'] . ' - ' . $c['nome']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="o-mes">Período</label>
                    <select class="adm-select" id="o-mes">
                        <option value="0">Anual (ano completo)</option>
                        <?php foreach ($mesesLabels as $num => $label): ?>
                        <option value="<?php echo $num ?>"><?php echo $label ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="o-valor">Valor Orçamentado <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="number" id="o-valor" min="0" step="0.01" placeholder="0.00">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="o-moeda">Moeda</label>
                    <input class="adm-input" type="text" id="o-moeda" maxlength="10" value="MZN">
                </div>
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-primary" id="btnOrcSave" type="button" onclick="saveOrcamento()">Criar Orçamento</button>
                <button class="adm-btn adm-btn-outline" id="btnOrcCancel" type="button" onclick="resetOrcamentoForm()" style="display:none">Cancelar</button>
            </div>
        </div>
    </div>
    <?php endif; ?>
</div>

<!-- ── Alocações ──────────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-alocacoes">
    <?php if (! $centros): ?>
    <div class="adm-card">
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum centro de custo registado</p>
            <p class="adm-text-muted">Crie centros de custo antes de registar alocações.</p>
        </div>
    </div>
    <?php else: ?>

    <div class="adm-card adm-mb-6">
        <div class="adm-filter-bar">
            <div class="adm-form-group" style="margin-bottom:0">
                <label class="adm-label" for="fAlocCentro">Centro de Custo</label>
                <select class="adm-select" id="fAlocCentro" onchange="filtrarAlocacoes()" style="width:280px">
                    <option value="">Todos os centros de custo</option>
                    <?php foreach ($centros as $c): ?>
                    <option value="<?php echo (int) $c['id'] ?>" <?php echo $alocFiltro === (int) $c['id'] ? 'selected' : '' ?>><?php echo htmlspecialchars($c['codigo'] . ' - ' . $c['nome']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <span class="adm-filter-count"><?php echo count($alocacoes) ?> alocações</span>
        </div>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Alocações</h2></div>
        <?php if ($alocacoes): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr>
                        <th>Centro de Custo</th>
                        <th>Origem</th>
                        <th>Descrição</th>
                        <th>Valor</th>
                        <th>%</th>
                        <th>Referência</th>
                        <th>Data</th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach ($alocacoes as $a): ?>
                <tr>
                    <td class="adm-fw-600"><?php
                        $cc = $centrosById[$a['cost_center_id']] ?? null;
                        echo $cc ? htmlspecialchars($cc['codigo'] . ' - ' . $cc['nome']) : '#' . (int) $a['cost_center_id'];
                    ?></td>
                    <td>
                        <span class="adm-badge adm-badge--blue"><?php echo htmlspecialchars($a['source_service']) ?></span>
                        <span class="adm-text-muted adm-text-xs"><?php echo htmlspecialchars($a['source_type']) ?> #<?php echo (int) $a['source_id'] ?></span>
                    </td>
                    <td><?php echo htmlspecialchars($a['descricao'] ?? '—') ?></td>
                    <td><?php echo number_format((float) $a['valor'], 2, ',', '.') . ' ' . htmlspecialchars($a['moeda']) ?></td>
                    <td><?php echo number_format((float) $a['allocation_percent'], 1, ',', '.') ?>%</td>
                    <td><?php echo $a['referencia_tipo'] !== null ? htmlspecialchars($a['referencia_tipo']) . ' #' . (int) $a['referencia_id'] : '—' ?></td>
                    <td class="adm-text-muted adm-text-xs"><?php echo htmlspecialchars(substr((string) $a['created_at'], 0, 10)) ?></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhuma alocação registada</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card">
        <div class="adm-card-header"><h2 class="adm-card-title">Nova Alocação</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="al-centro">Centro de Custo <span style="color:var(--adm-red)">*</span></label>
                    <select class="adm-select" id="al-centro">
                        <option value="">Seleciona um centro de custo</option>
                        <?php foreach ($centros as $c): ?>
                        <option value="<?php echo (int) $c['id'] ?>"><?php echo htmlspecialchars($c['codigo'] . ' - ' . $c['nome']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="al-source-service">Serviço de Origem <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="al-source-service" maxlength="100" placeholder="ex: faturacao">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="al-source-type">Tipo de Origem <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="al-source-type" maxlength="100" placeholder="ex: fatura">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="al-source-id">ID de Origem <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="number" id="al-source-id" min="1" placeholder="ex: 123">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="al-source-line-id">ID da Linha de Origem</label>
                    <input class="adm-input" type="number" id="al-source-line-id" min="1" placeholder="opcional">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="al-descricao">Descrição</label>
                    <input class="adm-input" type="text" id="al-descricao" maxlength="255" placeholder="opcional">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="al-valor">Valor <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="number" id="al-valor" min="0" step="0.01" placeholder="0.00">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="al-moeda">Moeda</label>
                    <input class="adm-input" type="text" id="al-moeda" maxlength="10" value="MZN">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="al-percent">Alocação (%)</label>
                    <input class="adm-input" type="number" id="al-percent" min="0.01" max="100" step="0.01" value="100">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="al-referencia-tipo">Tipo de Referência</label>
                    <input class="adm-input" type="text" id="al-referencia-tipo" maxlength="50" placeholder="opcional">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="al-referencia-id">ID de Referência</label>
                    <input class="adm-input" type="number" id="al-referencia-id" min="1" placeholder="opcional">
                </div>
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-outline" type="button" onclick="resetAlocacaoForm()">Limpar</button>
                <button class="adm-btn adm-btn-primary" type="button" onclick="saveAlocacao()">Registar Alocação</button>
            </div>
        </div>
    </div>
    <?php endif; ?>
</div>

<script>
const CSRF = '<?php echo $csrf ?>';
const ANO_FILTRO = <?php echo (int) $anoFiltro ?>;

// ── Tabs ─────────────────────────────────────────────────────
function switchTab(name, btn) {
    document.querySelectorAll('.adm-tab-panel').forEach(p => p.classList.remove('active'));
    document.querySelectorAll('.adm-tab').forEach(b => b.classList.remove('active'));
    document.getElementById('tab-' + name).classList.add('active');
    btn.classList.add('active');
}

document.addEventListener('DOMContentLoaded', () => {
    const tabs = ['centros', 'orcamentos', 'alocacoes'];
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

// ── Centros de Custo ───────────────────────────────────────────
function resetCentroForm() {
    document.getElementById('c-id').value = '';
    document.getElementById('c-parent').value = '';
    document.getElementById('c-codigo').value = '';
    document.getElementById('c-codigo').disabled = false;
    document.getElementById('c-nome').value = '';
    document.getElementById('c-tipo').value = 'centro';
    document.getElementById('c-gestor').value = '';
    document.getElementById('c-ativo-wrap').style.display = 'none';
    document.getElementById('c-ativo').checked = true;
    document.getElementById('centroFormTitle').textContent = 'Adicionar Centro de Custo';
    document.getElementById('btnCentroSave').textContent = 'Adicionar Centro de Custo';
}

function editCentro(btn) {
    const el = btn.closest('.adm-tree-card');
    document.getElementById('c-id').value = el.dataset.id;
    document.getElementById('c-parent').value = el.dataset.parentId || '';
    document.getElementById('c-codigo').value = el.dataset.codigo;
    document.getElementById('c-codigo').disabled = true;
    document.getElementById('c-nome').value = el.dataset.nome;
    document.getElementById('c-tipo').value = el.dataset.tipo;
    document.getElementById('c-gestor').value = el.dataset.gestorUserId || '';
    document.getElementById('c-ativo-wrap').style.display = '';
    document.getElementById('c-ativo').checked = el.dataset.activo === '1';
    document.getElementById('centroFormTitle').textContent = 'Editar Centro de Custo';
    document.getElementById('btnCentroSave').textContent = 'Guardar';
    document.getElementById('centroFormCard').scrollIntoView({behavior: 'smooth', block: 'end'});
}

function saveCentro() {
    const id     = document.getElementById('c-id').value;
    const codigo = document.getElementById('c-codigo').value.trim();
    const nome   = document.getElementById('c-nome').value.trim();

    if (!id && (!codigo || !nome)) { showToast('Código e nome são obrigatórios.', 'error'); return; }
    if (id && !nome) { showToast('O nome é obrigatório.', 'error'); return; }

    const parent = document.getElementById('c-parent').value;
    const gestor = document.getElementById('c-gestor').value;

    const payload = {
        id: id ? Number(id) : null,
        nome,
        parent_id: parent ? Number(parent) : null,
        tipo: document.getElementById('c-tipo').value,
        gestor_user_id: gestor ? Number(gestor) : null,
        csrf: CSRF
    };
    if (!id) {
        payload.codigo = codigo;
    } else {
        payload.activo = document.getElementById('c-ativo').checked;
    }

    postJSON('/nexora/api/centros_custo_centro_save', payload, 'centros');
}

function deleteCentro(btn) {
    const el   = btn.closest('.adm-tree-card');
    const id   = Number(el.dataset.id);
    const nome = el.dataset.nome;
    openConfirm(
        'Eliminar centro de custo',
        'Eliminar o centro de custo "' + nome + '"? Esta ação não pode ser revertida.',
        () => postJSON('/nexora/api/centros_custo_centro_remover', { id, csrf: CSRF }, 'centros')
    );
}

// ── Orçamentos ───────────────────────────────────────────────
function aplicarFiltroOrcamento() {
    const ano = document.getElementById('fAno').value;
    const mes = document.getElementById('fMes').value;
    const params = new URLSearchParams();
    if (ano) params.set('ano', ano);
    if (mes && mes !== '0') params.set('mes', mes);
    location.href = '?' + params.toString() + '#orcamentos';
}

function resetOrcamentoForm() {
    document.getElementById('o-id').value = '0';

    const elCentro = document.getElementById('o-centro');
    elCentro.value = '';
    elCentro.disabled = false;

    const elMes = document.getElementById('o-mes');
    elMes.value = '0';
    elMes.disabled = false;

    document.getElementById('o-valor').value = '';
    document.getElementById('o-moeda').value = 'MZN';

    document.getElementById('orcFormTitle').textContent = 'Novo Orçamento';
    document.getElementById('btnOrcSave').textContent = 'Criar Orçamento';
    document.getElementById('btnOrcCancel').style.display = 'none';
}

function editOrcamento(btn) {
    const tr = btn.closest('tr');
    const d  = tr.dataset;
    document.getElementById('o-id').value = d.id;

    const elCentro = document.getElementById('o-centro');
    elCentro.value = d.costCenterId;
    elCentro.disabled = true;

    const elMes = document.getElementById('o-mes');
    elMes.value = d.mes === '' ? '0' : d.mes;
    elMes.disabled = true;

    document.getElementById('o-valor').value = d.valorOrcamentado;
    document.getElementById('o-moeda').value = d.moeda;

    document.getElementById('orcFormTitle').textContent = 'Editar Orçamento';
    document.getElementById('btnOrcSave').textContent = 'Guardar Alterações';
    document.getElementById('btnOrcCancel').style.display = '';

    document.getElementById('orcFormTitle').scrollIntoView({behavior: 'smooth', block: 'center'});
}

function saveOrcamento() {
    const id    = Number(document.getElementById('o-id').value || 0);
    const valor = Number(document.getElementById('o-valor').value);

    if (document.getElementById('o-valor').value === '' || isNaN(valor) || valor < 0) {
        showToast('O valor orçamentado é obrigatório.', 'error');
        return;
    }

    const payload = { id, valor_orcamentado: valor, moeda: document.getElementById('o-moeda').value.trim() || 'MZN', csrf: CSRF };

    if (!id) {
        const centro = document.getElementById('o-centro').value;
        if (!centro) { showToast('O centro de custo é obrigatório.', 'error'); return; }
        payload.cost_center_id = Number(centro);
        payload.ano = ANO_FILTRO;

        const mes = document.getElementById('o-mes').value;
        if (mes && mes !== '0') payload.mes = Number(mes);
    }

    postJSON('/nexora/api/centros_custo_orcamento_save', payload, 'orcamentos');
}

function deleteOrcamento(btn) {
    const tr     = btn.closest('tr');
    const id     = Number(tr.dataset.id);
    const centro = tr.querySelector('td').textContent.trim();
    openConfirm(
        'Eliminar orçamento',
        'Eliminar o orçamento de "' + centro + '"? Esta ação não pode ser revertida.',
        () => postJSON('/nexora/api/centros_custo_orcamento_remover', { id, csrf: CSRF }, 'orcamentos')
    );
}

// ── Alocações ──────────────────────────────────────────────────
function filtrarAlocacoes() {
    const cc = document.getElementById('fAlocCentro').value;
    const params = new URLSearchParams();
    if (cc) params.set('cc', cc);
    location.href = '?' + params.toString() + '#alocacoes';
}

function resetAlocacaoForm() {
    document.getElementById('al-centro').value = '';
    document.getElementById('al-source-service').value = '';
    document.getElementById('al-source-type').value = '';
    document.getElementById('al-source-id').value = '';
    document.getElementById('al-source-line-id').value = '';
    document.getElementById('al-descricao').value = '';
    document.getElementById('al-valor').value = '';
    document.getElementById('al-moeda').value = 'MZN';
    document.getElementById('al-percent').value = '100';
    document.getElementById('al-referencia-tipo').value = '';
    document.getElementById('al-referencia-id').value = '';
}

function saveAlocacao() {
    const centro    = document.getElementById('al-centro').value;
    const service   = document.getElementById('al-source-service').value.trim();
    const type      = document.getElementById('al-source-type').value.trim();
    const sourceId  = document.getElementById('al-source-id').value;
    const valor     = document.getElementById('al-valor').value;

    if (!centro || !service || !type || !sourceId || valor === '') {
        showToast('Centro de custo, origem (serviço/tipo/ID) e valor são obrigatórios.', 'error');
        return;
    }

    const payload = {
        cost_center_id: Number(centro),
        source_service: service,
        source_type: type,
        source_id: Number(sourceId),
        valor: Number(valor),
        csrf: CSRF
    };

    const sourceLineId = document.getElementById('al-source-line-id').value;
    if (sourceLineId) payload.source_line_id = Number(sourceLineId);

    const descricao = document.getElementById('al-descricao').value.trim();
    if (descricao) payload.descricao = descricao;

    const moeda = document.getElementById('al-moeda').value.trim();
    if (moeda) payload.moeda = moeda;

    const percent = document.getElementById('al-percent').value;
    if (percent) payload.allocation_percent = Number(percent);

    const refTipo = document.getElementById('al-referencia-tipo').value.trim();
    if (refTipo) payload.referencia_tipo = refTipo;

    const refId = document.getElementById('al-referencia-id').value;
    if (refId) payload.referencia_id = Number(refId);

    postJSON('/nexora/api/centros_custo_alocacao_save', payload, 'alocacoes');
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
