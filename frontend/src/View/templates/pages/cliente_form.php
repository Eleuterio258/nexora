<?php

    $idHash = $app->request->queryString('id');
    $isEdit = $idHash !== '';

    $cliente    = null;
    $contactos  = [];
    $enderecos  = [];
    $pagamentos = [];
    $historico  = [];
    $saldo      = [];

    if ($isEdit) {
        $resp = $app->nexora->call('GET', "/api/clientes/$idHash");
        if ($resp['status'] !== 200) {
            header('Location: /nexora/clientes');
            exit;
        }
        $cliente = $resp['body'];

        $contactos  = $app->nexora->call('GET', "/api/clientes/$id/contactos")['body'] ?? [];
        $enderecos  = $app->nexora->call('GET', "/api/clientes/$id/enderecos")['body'] ?? [];
        $pagamentos = $app->nexora->call('GET', "/api/clientes/$id/pagamentos", null, ['limit' => 50])['body'] ?? [];
        $historico  = $app->nexora->call('GET', "/api/clientes/$id/historico", null, ['limit' => 50])['body'] ?? [];
        $saldo      = $app->nexora->call('GET', "/api/clientes/$id/saldo")['body'] ?? [];
    }

    $gruposResp = $app->nexora->call('GET', '/api/clientes/grupos');
    $grupos     = $gruposResp['body'] ?? [];

    $estadoBadges = [
        'ativo'     => ['adm-badge--green', 'Ativo'],
        'inativo'   => ['adm-badge--gray',  'Inativo'],
        'bloqueado' => ['adm-badge--red',   'Bloqueado'],
    ];
    $estadoBadge = $estadoBadges[$cliente['estado'] ?? 'ativo'] ?? ['adm-badge--gray', $cliente['estado'] ?? ''];

    $tipoEnderecoLabels = [
        'principal' => 'Principal',
        'entrega'   => 'Entrega',
        'cobranca'  => 'Cobrança',
        'fiscal'    => 'Fiscal',
    ];

    $metodoPagamentoLabels = [
        'dinheiro'      => 'Dinheiro',
        'transferencia' => 'Transferência',
        'mpesa'         => 'M-Pesa',
        'emola'         => 'e-Mola',
        'cartao'        => 'Cartão',
    ];

    $csrf       = $app->security->csrfToken();
    $pageTitle  = $isEdit ? 'Editar Cliente' : 'Novo Cliente';
    $activePage = 'clientes';
    $breadcrumb = [['Admin', '/nexora/'], ['Clientes', '/nexora/clientes'], [$pageTitle, '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header" style="align-items:flex-start">
    <div style="display:flex;align-items:center;gap:var(--adm-sp-3)">
        <h1 class="adm-page-title" style="margin:0"><?php echo $pageTitle ?></h1>
        <?php if ($isEdit): ?>
        <span class="adm-badge <?php echo $estadoBadge[0] ?>"><?php echo $estadoBadge[1] ?></span>
        <?php endif; ?>
    </div>
    <div class="adm-page-header-actions">
        <a href="/nexora/clientes" class="adm-btn adm-btn-outline adm-btn-sm">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>
            Voltar
        </a>
    </div>
</div>

<div id="formMsg"></div>

<?php if ($isEdit): ?>
<div class="adm-detail-grid">
<div>
<div class="adm-tabs" id="mainTabs">
    <button class="adm-tab active" onclick="switchTab('info',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="8" r="4"/><path d="M20 21a8 8 0 1 0-16 0"/></svg>
        Informação
    </button>
    <button class="adm-tab" onclick="switchTab('contactos',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.13.96.36 1.9.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.91.34 1.85.57 2.81.7A2 2 0 0 1 22 16.92z"/></svg>
        Contactos
        <?php if (count($contactos)): ?><span class="adm-tab-badge"><?php echo count($contactos) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('enderecos',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
        Endereços
        <?php if (count($enderecos)): ?><span class="adm-tab-badge"><?php echo count($enderecos) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('credito',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>
        Crédito &amp; Saldo
    </button>
    <button class="adm-tab" onclick="switchTab('pagamentos',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
        Pagamentos
        <?php if (count($pagamentos)): ?><span class="adm-tab-badge"><?php echo count($pagamentos) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('historico',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
        Histórico
        <?php if (count($historico)): ?><span class="adm-tab-badge"><?php echo count($historico) ?></span><?php endif; ?>
    </button>
</div>

<div class="adm-tab-panel active" id="tab-info">
<?php endif; ?>

<form id="clienteForm">
    <input type="hidden" name="csrf_token" value="<?php echo $csrf ?>">
    <?php if ($isEdit): ?><input type="hidden" name="id" value="<?= (int)($cliente['id'] ?? 0) ?>"><?php endif; ?>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Identificação</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-codigo">Código</label>
                    <input class="adm-input" type="text" id="f-codigo" name="codigo" maxlength="50"
                           placeholder="ex: CLI-0001"
                           value="<?php echo $app->view->field($cliente, 'codigo') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="f-nome" name="nome" required maxlength="150"
                           placeholder="ex: ACME Lda"
                           value="<?php echo $app->view->field($cliente, 'nome') ?>">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-nuit">NUIT</label>
                    <input class="adm-input" type="text" id="f-nuit" name="nuit" maxlength="30"
                           placeholder="ex: 400123456"
                           value="<?php echo $app->view->field($cliente, 'nuit') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-grupo">Grupo</label>
                    <select class="adm-select" id="f-grupo" name="customer_group_id">
                        <option value="">Sem grupo</option>
                        <?php foreach ($grupos as $g): ?>
                        <option value="<?php echo $g['id'] ?>" <?php echo (int) ($cliente['customer_group_id'] ?? 0) === (int) $g['id'] ? 'selected' : '' ?>><?php echo htmlspecialchars($g['nome']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
            </div>
        </div>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Contacto</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-email">Email</label>
                    <input class="adm-input" type="email" id="f-email" name="email" maxlength="120"
                           placeholder="ex: geral@acme.co.mz"
                           value="<?php echo $app->view->field($cliente, 'email') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-telefone">Telefone</label>
                    <input class="adm-input" type="text" id="f-telefone" name="telefone" maxlength="30"
                           placeholder="ex: +258 84 000 0000"
                           value="<?php echo $app->view->field($cliente, 'telefone') ?>">
                </div>
            </div>
        </div>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Observações</h2></div>
        <div class="adm-card-body">
            <textarea class="adm-textarea" id="f-observacao" name="observacao" rows="4" maxlength="2000"
                      placeholder="Notas internas sobre este cliente..."><?php echo $app->view->field($cliente, 'observacao') ?></textarea>
        </div>
    </div>

    <div style="display:flex;gap:var(--adm-sp-3);justify-content:flex-end;padding-bottom:var(--adm-sp-8)">
        <a href="/nexora/clientes" class="adm-btn adm-btn-outline">Cancelar</a>
        <button type="submit" class="adm-btn adm-btn-primary" id="btnSave">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/>
                <polyline points="17 21 17 13 7 13 7 21"/>
                <polyline points="7 3 7 8 15 8"/>
            </svg>
            <?php echo $isEdit ? 'Guardar alterações' : 'Criar Cliente' ?>
        </button>
    </div>
</form>

<?php if ($isEdit): ?>
</div> <!-- /tab-info -->

<!-- ── Contactos ──────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-contactos">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Contactos</h2></div>
        <?php if ($contactos): ?>
        <div class="adm-table-wrap">
            <table class="adm-table" id="contactosTable">
                <thead>
                    <tr><th>Nome</th><th>Cargo</th><th>Telefone</th><th>Email</th><th>Principal</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($contactos as $c): ?>
                <tr data-id="<?php echo (int) $c['id'] ?>"
                    data-nome="<?php echo htmlspecialchars($c['nome']) ?>"
                    data-cargo="<?php echo htmlspecialchars((string) ($c['cargo'] ?? '')) ?>"
                    data-telefone="<?php echo htmlspecialchars((string) ($c['telefone'] ?? '')) ?>"
                    data-email="<?php echo htmlspecialchars((string) ($c['email'] ?? '')) ?>"
                    data-principal="<?php echo $c['principal'] ? '1' : '0' ?>">
                    <td class="adm-fw-600"><?php echo htmlspecialchars($c['nome']) ?></td>
                    <td><?php echo $app->view->field($c, 'cargo', '—') ?></td>
                    <td><?php echo $app->view->field($c, 'telefone', '—') ?></td>
                    <td><?php echo $app->view->field($c, 'email', '—') ?></td>
                    <td><span class="adm-badge <?php echo $c['principal'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $c['principal'] ? 'Sim' : 'Não' ?></span></td>
                    <td>
                        <div class="adm-actions">
                            <button class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Editar" onclick="editContacto(this)">
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                                </svg>
                            </button>
                            <button class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Eliminar" style="color:var(--adm-red)"
                                    onclick="deleteContacto(<?php echo (int) $c['id'] ?>, '<?php echo htmlspecialchars(addslashes($c['nome'])) ?>')">
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/>
                                    <path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/>
                                </svg>
                            </button>
                        </div>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-card-body">
            <p class="adm-text-muted adm-text-sm" style="margin:0">Sem contactos registados.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title" id="contactoFormTitle">Adicionar Contacto</h2></div>
        <div class="adm-card-body">
            <input type="hidden" id="ct-id" value="">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="ct-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="ct-nome" maxlength="150" placeholder="ex: Maria Sitoe">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="ct-cargo">Cargo</label>
                    <input class="adm-input" type="text" id="ct-cargo" maxlength="100" placeholder="ex: Gestora de Compras">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="ct-telefone">Telefone</label>
                    <input class="adm-input" type="text" id="ct-telefone" maxlength="30" placeholder="ex: +258 84 000 0000">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="ct-email">Email</label>
                    <input class="adm-input" type="email" id="ct-email" maxlength="120" placeholder="ex: maria@acme.co.mz">
                </div>
            </div>
            <label class="adm-toggle" style="margin-bottom:var(--adm-sp-4)">
                <input type="checkbox" id="ct-principal">
                <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                <span class="adm-toggle-label">Contacto principal</span>
            </label>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-outline" type="button" onclick="resetContactoForm()">Limpar</button>
                <button class="adm-btn adm-btn-primary" type="button" id="btnContactoSave" onclick="saveContacto()">Adicionar Contacto</button>
            </div>
        </div>
    </div>
</div>

<!-- ── Endereços ──────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-enderecos">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Endereços</h2></div>
        <?php if ($enderecos): ?>
        <div class="adm-table-wrap">
            <table class="adm-table" id="enderecosTable">
                <thead>
                    <tr><th>Tipo</th><th>Endereço</th><th>Cidade</th><th>Província</th><th>País</th><th>Cód. Postal</th><th>Principal</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($enderecos as $e): ?>
                <tr data-id="<?php echo (int) $e['id'] ?>"
                    data-tipo="<?php echo htmlspecialchars($e['tipo']) ?>"
                    data-endereco="<?php echo htmlspecialchars($e['endereco']) ?>"
                    data-cidade="<?php echo htmlspecialchars((string) ($e['cidade'] ?? '')) ?>"
                    data-provincia="<?php echo htmlspecialchars((string) ($e['provincia'] ?? '')) ?>"
                    data-pais="<?php echo htmlspecialchars((string) ($e['pais'] ?? '')) ?>"
                    data-codigo-postal="<?php echo htmlspecialchars((string) ($e['codigo_postal'] ?? '')) ?>"
                    data-principal="<?php echo $e['principal'] ? '1' : '0' ?>">
                    <td><?php echo $tipoEnderecoLabels[$e['tipo']] ?? htmlspecialchars($e['tipo']) ?></td>
                    <td><?php echo htmlspecialchars($e['endereco']) ?></td>
                    <td><?php echo $app->view->field($e, 'cidade', '—') ?></td>
                    <td><?php echo $app->view->field($e, 'provincia', '—') ?></td>
                    <td><?php echo $app->view->field($e, 'pais', '—') ?></td>
                    <td><?php echo $app->view->field($e, 'codigo_postal', '—') ?></td>
                    <td><span class="adm-badge <?php echo $e['principal'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $e['principal'] ? 'Sim' : 'Não' ?></span></td>
                    <td>
                        <div class="adm-actions">
                            <button class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Editar" onclick="editEndereco(this)">
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                                </svg>
                            </button>
                            <button class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Eliminar" style="color:var(--adm-red)"
                                    onclick="deleteEndereco(<?php echo (int) $e['id'] ?>, '<?php echo htmlspecialchars(addslashes($e['endereco'])) ?>')">
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/>
                                    <path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/>
                                </svg>
                            </button>
                        </div>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-card-body">
            <p class="adm-text-muted adm-text-sm" style="margin:0">Sem endereços registados.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title" id="enderecoFormTitle">Adicionar Endereço</h2></div>
        <div class="adm-card-body">
            <input type="hidden" id="en-id" value="">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="en-tipo">Tipo</label>
                    <select class="adm-select" id="en-tipo">
                        <?php foreach ($tipoEnderecoLabels as $key => $label): ?>
                        <option value="<?php echo $key ?>"><?php echo $label ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="en-endereco">Endereço <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="en-endereco" maxlength="255" placeholder="ex: Av. 25 de Setembro, 1234">
                </div>
            </div>
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="en-cidade">Cidade</label>
                    <input class="adm-input" type="text" id="en-cidade" maxlength="100" placeholder="ex: Maputo">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="en-provincia">Província</label>
                    <input class="adm-input" type="text" id="en-provincia" maxlength="100" placeholder="ex: Maputo Cidade">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="en-codigo-postal">Código Postal</label>
                    <input class="adm-input" type="text" id="en-codigo-postal" maxlength="30">
                </div>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="en-pais">País</label>
                <input class="adm-input" type="text" id="en-pais" maxlength="100" placeholder="Moçambique" value="Moçambique">
            </div>
            <label class="adm-toggle" style="margin-bottom:var(--adm-sp-4)">
                <input type="checkbox" id="en-principal">
                <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                <span class="adm-toggle-label">Endereço principal</span>
            </label>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-outline" type="button" onclick="resetEnderecoForm()">Limpar</button>
                <button class="adm-btn adm-btn-primary" type="button" id="btnEnderecoSave" onclick="saveEndereco()">Adicionar Endereço</button>
            </div>
        </div>
    </div>
</div>

<!-- ── Crédito & Saldo ────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-credito">
    <div class="adm-stats-grid" style="grid-template-columns:repeat(2,1fr)">
        <div class="adm-stat-card">
            <div class="adm-stat-icon adm-stat-icon--red">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
            </div>
            <div class="adm-stat-info">
                <div class="adm-stat-num"><?php echo number_format((float) ($saldo['saldo_devedor'] ?? 0), 2, ',', '.') ?></div>
                <div class="adm-stat-label">Saldo Devedor (MZN)</div>
            </div>
        </div>
        <div class="adm-stat-card">
            <div class="adm-stat-icon adm-stat-icon--blue">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 9h18"/></svg>
            </div>
            <div class="adm-stat-info">
                <div class="adm-stat-num"><?php echo number_format((float) ($saldo['total_compras'] ?? 0), 2, ',', '.') ?></div>
                <div class="adm-stat-label">Total de Compras (MZN)</div>
            </div>
        </div>
        <div class="adm-stat-card">
            <div class="adm-stat-icon adm-stat-icon--green">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>
            </div>
            <div class="adm-stat-info">
                <div class="adm-stat-num"><?php echo number_format((float) ($saldo['total_pago'] ?? 0), 2, ',', '.') ?></div>
                <div class="adm-stat-label">Total Pago (MZN)</div>
            </div>
        </div>
        <div class="adm-stat-card">
            <div class="adm-stat-icon adm-stat-icon--yellow">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
            </div>
            <div class="adm-stat-info">
                <div class="adm-stat-num" style="font-size:1rem">
                    <?php echo ! empty($saldo['ultima_compra_em']) ? date('d/m/Y', strtotime($saldo['ultima_compra_em'])) : '—' ?>
                </div>
                <div class="adm-stat-label">Última Compra</div>
            </div>
        </div>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Limite de Crédito</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="cr-limite">Limite de Crédito (MZN) <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="number" id="cr-limite" min="0" step="0.01" placeholder="0.00">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="cr-motivo">Motivo <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="cr-motivo" maxlength="200" placeholder="ex: Histórico de pagamentos pontuais">
                </div>
            </div>
            <button class="adm-btn adm-btn-primary" type="button" onclick="saveCredito()">Actualizar Limite</button>
        </div>
    </div>
</div>

<!-- ── Pagamentos ─────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-pagamentos">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Pagamentos</h2></div>
        <?php if ($pagamentos): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Método</th><th>Valor</th><th>Referência</th><th>Pago em</th></tr>
                </thead>
                <tbody>
                <?php foreach ($pagamentos as $p): ?>
                <tr>
                    <td><?php echo $metodoPagamentoLabels[$p['metodo']] ?? htmlspecialchars($p['metodo']) ?></td>
                    <td class="adm-fw-600"><?php echo number_format((float) $p['valor'], 2, ',', '.') ?> MZN</td>
                    <td><?php echo $app->view->field($p, 'referencia', '—') ?></td>
                    <td class="adm-text-muted"><?php echo $p['pago_em'] ? date('d/m/Y H:i', strtotime($p['pago_em'])) : '—' ?></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-card-body">
            <p class="adm-text-muted adm-text-sm" style="margin:0">Sem pagamentos registados.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Registar Pagamento</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="pg-metodo">Método <span style="color:var(--adm-red)">*</span></label>
                    <select class="adm-select" id="pg-metodo">
                        <?php foreach ($metodoPagamentoLabels as $key => $label): ?>
                        <option value="<?php echo $key ?>"><?php echo $label ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="pg-valor">Valor (MZN) <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="number" id="pg-valor" min="0" step="0.01" placeholder="0.00">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="pg-referencia">Referência</label>
                    <input class="adm-input" type="text" id="pg-referencia" maxlength="100" placeholder="ex: REF-00123">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="pg-observacao">Observação</label>
                    <input class="adm-input" type="text" id="pg-observacao" maxlength="255">
                </div>
            </div>
            <button class="adm-btn adm-btn-primary" type="button" onclick="savePagamento()">Registar Pagamento</button>
        </div>
    </div>
</div>

<!-- ── Histórico ──────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-historico">
    <div class="adm-card">
        <div class="adm-card-header"><h2 class="adm-card-title">Histórico</h2></div>
        <div class="adm-card-body">
            <div class="timeline">
                <?php foreach ($historico as $h): ?>
                <div class="timeline-item">
                    <div class="timeline-dot timeline-dot--gray">
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                    </div>
                    <div class="timeline-body">
                        <div class="timeline-header">
                            <span class="timeline-author"><?php echo htmlspecialchars(str_replace('_', ' ', $h['evento'])) ?></span>
                            <span class="timeline-time"><?php echo $h['created_at'] ? date('d/m/Y H:i', strtotime($h['created_at'])) : '' ?></span>
                        </div>
                        <?php if (! empty($h['descricao'])): ?>
                        <div class="timeline-content"><p><?php echo nl2br(htmlspecialchars($h['descricao'])) ?></p></div>
                        <?php endif; ?>
                    </div>
                </div>
                <?php endforeach; ?>
                <?php if (empty($historico)): ?>
                <p class="adm-text-muted adm-text-sm" style="padding-left:2.5rem">Sem registos de histórico.</p>
                <?php endif; ?>
            </div>
        </div>
    </div>
</div>

</div> <!-- /main col -->

<aside>
    <div class="adm-card">
        <div class="adm-card-header"><h2 class="adm-card-title">Estado do Cliente</h2></div>
        <div class="adm-card-body">
            <div style="margin-bottom:var(--adm-sp-3)">
                <span class="adm-badge <?php echo $estadoBadge[0] ?>" style="font-size:var(--adm-text-sm)"><?php echo $estadoBadge[1] ?></span>
            </div>
            <div style="display:flex;flex-direction:column;gap:var(--adm-sp-2)">
                <?php if ($cliente['estado'] === 'ativo'): ?>
                <button class="adm-btn adm-btn-outline adm-btn-sm" onclick="changeEstado('bloquear')" style="justify-content:flex-start;color:var(--adm-red)">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                    Bloquear Cliente
                </button>
                <?php elseif ($cliente['estado'] === 'bloqueado'): ?>
                <button class="adm-btn adm-btn-outline adm-btn-sm" onclick="changeEstado('desbloquear')" style="justify-content:flex-start;color:var(--adm-green-dark)">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 9.9-1"/></svg>
                    Desbloquear Cliente
                </button>
                <?php else: ?>
                <button class="adm-btn adm-btn-outline adm-btn-sm" onclick="changeEstado('activar')" style="justify-content:flex-start;color:var(--adm-green-dark)">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>
                    Activar Cliente
                </button>
                <?php endif; ?>
            </div>
        </div>
    </div>
</aside>
</div> <!-- /adm-detail-grid -->
<?php endif; ?>

<script>
const CLIENTE_ID = <?= $isEdit ? (int)($cliente['id'] ?? 0) : 'null' ?>;
const CSRF       = '<?php echo $csrf ?>';

// ── Tabs ─────────────────────────────────────────────────────
function switchTab(name, btn) {
    document.querySelectorAll('.adm-tab-panel').forEach(p => p.classList.remove('active'));
    document.querySelectorAll('.adm-tab').forEach(b => b.classList.remove('active'));
    document.getElementById('tab-' + name).classList.add('active');
    btn.classList.add('active');
}

document.addEventListener('DOMContentLoaded', () => {
    const tabs = ['info', 'contactos', 'enderecos', 'credito', 'pagamentos', 'historico'];
    const hash = location.hash.replace('#', '');
    const idx  = tabs.indexOf(hash);
    if (idx > 0) {
        const btn = document.querySelectorAll('#mainTabs .adm-tab')[idx];
        if (btn) switchTab(hash, btn);
    }
});

// ── Guardar cliente ──────────────────────────────────────────
document.getElementById('clienteForm').addEventListener('submit', async function(e) {
    e.preventDefault();
    const btn = document.getElementById('btnSave');
    btn.disabled = true;
    btn.innerHTML = '<svg class="spin" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg> A guardar…';

    const msgEl = document.getElementById('formMsg');
    msgEl.innerHTML = '';

    const fd = new FormData(this);

    try {
        const res  = await fetch('/nexora/api/cliente_save', { method: 'POST', body: fd });
        const data = await res.json();

        if (data.ok) {
            if (CLIENTE_ID) {
                msgEl.innerHTML = `<div class="adm-alert adm-alert--success">${data.msg || 'Cliente actualizado com sucesso.'}</div>`;
                btn.disabled = false;
                btn.innerHTML = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg> Guardar alterações`;
            } else {
                window.location.href = '/nexora/clientes/form?id=' + nexoraEncodeId(data.id) + '&msg=' + encodeURIComponent(data.msg || 'Cliente criado com sucesso.');
            }
        } else {
            msgEl.innerHTML = `<div class="adm-alert adm-alert--error">${data.erro || 'Erro ao guardar.'}</div>`;
            btn.disabled = false;
            btn.innerHTML = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg> <?php echo $isEdit ? 'Guardar alterações' : 'Criar Cliente' ?>`;
        }
    } catch {
        msgEl.innerHTML = '<div class="adm-alert adm-alert--error">Erro de ligação.</div>';
        btn.disabled = false;
    }
});

<?php if ($isEdit): ?>
// ── Estado do cliente ────────────────────────────────────────
const ESTADO_VERBOS = { activar: 'activar', bloquear: 'bloquear', desbloquear: 'desbloquear' };

function changeEstado(action) {
    openConfirm(
        'Alterar estado',
        'Pretende ' + ESTADO_VERBOS[action] + ' este cliente?',
        async () => {
            try {
                const res  = await fetch('/nexora/api/cliente_estado', {
                    method: 'POST',
                    headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({id: CLIENTE_ID, action, csrf: CSRF})
                });
                const data = await res.json();
                if (data.ok) { showToast('Estado actualizado'); setTimeout(() => location.reload(), 700); }
                else showToast(data.erro || 'Erro', 'error');
            } catch { showToast('Erro de ligação', 'error'); }
        }
    );
}

// ── Contactos ────────────────────────────────────────────────
function resetContactoForm() {
    document.getElementById('ct-id').value = '';
    document.getElementById('ct-nome').value = '';
    document.getElementById('ct-cargo').value = '';
    document.getElementById('ct-telefone').value = '';
    document.getElementById('ct-email').value = '';
    document.getElementById('ct-principal').checked = false;
    document.getElementById('contactoFormTitle').textContent = 'Adicionar Contacto';
    document.getElementById('btnContactoSave').textContent = 'Adicionar Contacto';
}

function editContacto(btn) {
    const row = btn.closest('tr');
    document.getElementById('ct-id').value = row.dataset.id;
    document.getElementById('ct-nome').value = row.dataset.nome;
    document.getElementById('ct-cargo').value = row.dataset.cargo;
    document.getElementById('ct-telefone').value = row.dataset.telefone;
    document.getElementById('ct-email').value = row.dataset.email;
    document.getElementById('ct-principal').checked = row.dataset.principal === '1';
    document.getElementById('contactoFormTitle').textContent = 'Editar Contacto';
    document.getElementById('btnContactoSave').textContent = 'Guardar Contacto';
    document.getElementById('tab-contactos').scrollIntoView({behavior: 'smooth', block: 'end'});
}

async function saveContacto() {
    const id   = document.getElementById('ct-id').value;
    const nome = document.getElementById('ct-nome').value.trim();
    if (!nome) { showToast('O nome do contacto é obrigatório.', 'error'); return; }

    const payload = {
        cliente_id: CLIENTE_ID,
        id: id ? Number(id) : null,
        nome,
        cargo: document.getElementById('ct-cargo').value.trim() || null,
        telefone: document.getElementById('ct-telefone').value.trim() || null,
        email: document.getElementById('ct-email').value.trim() || null,
        principal: document.getElementById('ct-principal').checked,
        csrf: CSRF
    };

    try {
        const res  = await fetch('/nexora/api/cliente_contacto_save', {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            showToast(data.msg || 'Contacto guardado com sucesso.');
            location.hash = 'contactos';
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}

function deleteContacto(id, nome) {
    openConfirm(
        'Eliminar contacto',
        'Eliminar o contacto "' + nome + '"?',
        async () => {
            try {
                const res  = await fetch('/nexora/api/cliente_contacto_delete', {
                    method: 'POST', headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({cliente_id: CLIENTE_ID, id, csrf: CSRF})
                });
                const data = await res.json();
                if (data.ok) {
                    showToast('Contacto eliminado');
                    location.hash = 'contactos';
                    setTimeout(() => location.reload(), 700);
                } else {
                    showToast(data.erro || 'Erro', 'error');
                }
            } catch { showToast('Erro de ligação', 'error'); }
        }
    );
}

// ── Endereços ────────────────────────────────────────────────
function resetEnderecoForm() {
    document.getElementById('en-id').value = '';
    document.getElementById('en-tipo').value = 'principal';
    document.getElementById('en-endereco').value = '';
    document.getElementById('en-cidade').value = '';
    document.getElementById('en-provincia').value = '';
    document.getElementById('en-pais').value = 'Moçambique';
    document.getElementById('en-codigo-postal').value = '';
    document.getElementById('en-principal').checked = false;
    document.getElementById('enderecoFormTitle').textContent = 'Adicionar Endereço';
    document.getElementById('btnEnderecoSave').textContent = 'Adicionar Endereço';
}

function editEndereco(btn) {
    const row = btn.closest('tr');
    document.getElementById('en-id').value = row.dataset.id;
    document.getElementById('en-tipo').value = row.dataset.tipo;
    document.getElementById('en-endereco').value = row.dataset.endereco;
    document.getElementById('en-cidade').value = row.dataset.cidade;
    document.getElementById('en-provincia').value = row.dataset.provincia;
    document.getElementById('en-pais').value = row.dataset.pais;
    document.getElementById('en-codigo-postal').value = row.dataset.codigoPostal;
    document.getElementById('en-principal').checked = row.dataset.principal === '1';
    document.getElementById('enderecoFormTitle').textContent = 'Editar Endereço';
    document.getElementById('btnEnderecoSave').textContent = 'Guardar Endereço';
    document.getElementById('tab-enderecos').scrollIntoView({behavior: 'smooth', block: 'end'});
}

async function saveEndereco() {
    const id       = document.getElementById('en-id').value;
    const endereco = document.getElementById('en-endereco').value.trim();
    if (!endereco) { showToast('O endereço é obrigatório.', 'error'); return; }

    const payload = {
        cliente_id: CLIENTE_ID,
        id: id ? Number(id) : null,
        tipo: document.getElementById('en-tipo').value,
        endereco,
        cidade: document.getElementById('en-cidade').value.trim() || null,
        provincia: document.getElementById('en-provincia').value.trim() || null,
        pais: document.getElementById('en-pais').value.trim() || null,
        codigo_postal: document.getElementById('en-codigo-postal').value.trim() || null,
        principal: document.getElementById('en-principal').checked,
        csrf: CSRF
    };

    try {
        const res  = await fetch('/nexora/api/cliente_endereco_save', {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            showToast(data.msg || 'Endereço guardado com sucesso.');
            location.hash = 'enderecos';
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}

function deleteEndereco(id, endereco) {
    openConfirm(
        'Eliminar endereço',
        'Eliminar o endereço "' + endereco + '"?',
        async () => {
            try {
                const res  = await fetch('/nexora/api/cliente_endereco_delete', {
                    method: 'POST', headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({cliente_id: CLIENTE_ID, id, csrf: CSRF})
                });
                const data = await res.json();
                if (data.ok) {
                    showToast('Endereço eliminado');
                    location.hash = 'enderecos';
                    setTimeout(() => location.reload(), 700);
                } else {
                    showToast(data.erro || 'Erro', 'error');
                }
            } catch { showToast('Erro de ligação', 'error'); }
        }
    );
}

// ── Crédito ──────────────────────────────────────────────────
async function saveCredito() {
    const limite = document.getElementById('cr-limite').value;
    const motivo = document.getElementById('cr-motivo').value.trim();
    if (limite === '' || Number(limite) < 0) { showToast('O limite deve ser um valor positivo.', 'error'); return; }
    if (!motivo) { showToast('O motivo é obrigatório.', 'error'); return; }

    try {
        const res  = await fetch('/nexora/api/cliente_credito_save', {
            method: 'POST', headers: {'Content-Type':'application/json'},
            body: JSON.stringify({cliente_id: CLIENTE_ID, limite: Number(limite), motivo, csrf: CSRF})
        });
        const data = await res.json();
        if (data.ok) showToast(data.msg || 'Limite de crédito actualizado.');
        else showToast(data.erro || 'Erro', 'error');
    } catch { showToast('Erro de ligação', 'error'); }
}

// ── Pagamentos ───────────────────────────────────────────────
async function savePagamento() {
    const valor = document.getElementById('pg-valor').value;
    if (valor === '' || Number(valor) <= 0) { showToast('O valor deve ser superior a zero.', 'error'); return; }

    const payload = {
        cliente_id: CLIENTE_ID,
        metodo: document.getElementById('pg-metodo').value,
        valor: Number(valor),
        referencia: document.getElementById('pg-referencia').value.trim() || null,
        observacao: document.getElementById('pg-observacao').value.trim() || null,
        csrf: CSRF
    };

    try {
        const res  = await fetch('/nexora/api/cliente_pagamento_save', {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            showToast(data.msg || 'Pagamento registado com sucesso.');
            location.hash = 'pagamentos';
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}
<?php endif; ?>

// Spin animation
const style = document.createElement('style');
style.textContent = '.spin{animation:spin .7s linear infinite}@keyframes spin{to{transform:rotate(360deg)}}';
document.head.appendChild(style);
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
