<?php

declare(strict_types=1);

if (!$app->session->canModule('recursos-humanos')) {
    header('Location: /nexora');
    exit;
}

$filtroUnidade = $app->request->queryInt('unit_id', 0) ?: 0;
$filtroEstado  = $app->request->queryEnum('estado', ['ativo', 'suspenso', 'licenca', 'desligado']);
$filtroQ       = $app->request->queryString('q');
$page          = max(1, $app->request->queryInt('page', 1) ?: 1);
$limit         = 20;

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

$safeList  = fn(array $r) => ($r['status'] === 200 && is_array($r['body']) && array_is_list($r['body'])) ? $r['body'] : [];
$safePaged = fn(array $r) => ($r['status'] === 200 && is_array($r['body']) && isset($r['body']['data']))
    ? $r['body']
    : ['data' => [], 'meta' => ['total' => 0, 'page' => 1, 'limit' => $limit]];

// A listagem só devolve {data, meta} quando `page` é enviado; sem `page` devolve a lista completa.
$resp         = $safePaged($app->nexora->call('GET', '/api/rh/funcionarios', null, array_merge($query, ['page' => $page, 'limit' => $limit])));
$funcionarios = $resp['data'];
$meta         = $resp['meta'] ?? ['total' => 0, 'page' => $page, 'limit' => $limit];
$totalPages   = max(1, (int) ceil(((int) $meta['total']) / $limit));

// Segunda chamada sem filtros para os contadores por estado — a `meta` acima só
// conhece o total do filtro activo.
$todos = $safeList($app->nexora->call('GET', '/api/rh/funcionarios'));

$unidades = $safeList($app->nexora->call('GET', '/api/rh/unidades'));

$podeGerir       = $app->session->can('recursos-humanos', 'gerir_funcionarios');
$podeVerSalarios = $app->session->can('recursos-humanos', 'processar_salarios');

// Recursos só necessários para o formulário de criação.
$cargos   = $podeGerir ? $safeList($app->nexora->call('GET', '/api/rh/cargos')) : [];
$horarios = $podeGerir ? $safeList($app->nexora->call('GET', '/api/rh/horarios')) : [];

$estadoBadges = [
    'ativo'     => ['adm-badge--green',  'Activo'],
    'suspenso'  => ['adm-badge--yellow', 'Suspenso'],
    'licenca'   => ['adm-badge--blue',   'Licença'],
    'desligado' => ['adm-badge--gray',   'Desligado'],
];

$tipoContratoLabels = [
    'efetivo'           => 'Efetivo',
    'indeterminado'     => 'Indeterminado',
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

$contaEstado = fn(string $estado) => count(array_filter($todos, fn($f) => ($f['estado'] ?? '') === $estado));

$csrf       = $app->security->csrfToken();
$pageTitle  = 'Funcionários';
$activePage = 'rh_funcionarios';
$breadcrumb = [['Admin', '/nexora/'], ['Recursos Humanos', ''], ['Funcionários', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Funcionários</h1>
    <?php if ($podeGerir): ?>
    <div class="adm-page-header-actions">
        <button class="adm-btn adm-btn-primary" type="button" onclick="openFuncionarioModal()">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:5px"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            Novo Funcionário
        </button>
    </div>
    <?php endif; ?>
</div>

<!-- Stats -->
<div class="adm-stats-grid" style="grid-template-columns:repeat(4,1fr);margin-bottom:var(--adm-sp-6)">
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--blue">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
        </div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?php echo count($todos) ?></div>
            <div class="adm-stat-label">Total</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--green">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
        </div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?php echo $contaEstado('ativo') ?></div>
            <div class="adm-stat-label">Activos</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--blue">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
        </div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?php echo $contaEstado('licenca') + $contaEstado('suspenso') ?></div>
            <div class="adm-stat-label">Em licença / suspensos</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--blue">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 21h18"/><path d="M5 21V7l7-4 7 4v14"/><path d="M9 21v-6h6v6"/></svg>
        </div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?php echo count($unidades) ?></div>
            <div class="adm-stat-label">Unidades</div>
        </div>
    </div>
</div>

<!-- Lista -->
<div class="adm-card">
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
        <?php if ($query): ?>
        <a class="adm-btn adm-btn-ghost adm-btn-sm" href="/nexora/rh/funcionarios">Limpar</a>
        <?php endif; ?>
        <span class="adm-filter-count"><?php echo (int) $meta['total'] ?> funcionário<?php echo (int) $meta['total'] !== 1 ? 's' : '' ?></span>
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
                    <th>Contrato</th>
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
                <td>
                    <?php if ($f['numero_funcionario']): ?>
                    <code style="font-size:.78rem;background:var(--adm-gray-100);padding:2px 6px;border-radius:4px;color:var(--adm-gray-700)">
                        <?php echo htmlspecialchars($f['numero_funcionario']) ?>
                    </code>
                    <?php else: ?>
                    <span class="adm-text-muted">—</span>
                    <?php endif; ?>
                </td>
                <td class="adm-fw-600"><?php echo htmlspecialchars($f['nome_completo']) ?></td>
                <td><?php echo $f['unidade_nome'] ? htmlspecialchars($f['unidade_nome']) : '<span class="adm-text-muted">—</span>' ?></td>
                <td><?php echo $f['cargo'] ? htmlspecialchars($f['cargo']) : '<span class="adm-text-muted">—</span>' ?></td>
                <td class="adm-text-muted" style="font-size:var(--adm-text-sm)">
                    <?php echo htmlspecialchars($tipoContratoLabels[$f['tipo_contrato']] ?? ($f['tipo_contrato'] ?: '—')) ?>
                </td>
                <td class="adm-text-muted"><?php echo $f['data_admissao'] ? date('d/m/Y', strtotime($f['data_admissao'])) : '—' ?></td>
                <td><span class="adm-badge <?php echo $badge[0] ?>"><?php echo htmlspecialchars($badge[1]) ?></span></td>
                <td>
                    <div class="adm-actions">
                        <a href="<?php echo htmlspecialchars($app->routes->path('rh_funcionario', ['id' => $app->id->encode((int) $f['id'])])) ?>"
                           class="adm-btn adm-btn-ghost adm-btn-sm" title="Ver ficha do funcionário">Ver ficha</a>
                    </div>
                </td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>

    <?php if ($totalPages > 1): ?>
    <div style="display:flex;justify-content:center;gap:var(--adm-sp-3);padding:var(--adm-sp-5)">
        <?php if ($page > 1): ?>
        <a href="<?php echo htmlspecialchars($app->view->queryLink('/nexora/rh/funcionarios', $app->request->query(), ['page' => $page - 1])) ?>" class="adm-btn adm-btn-outline adm-btn-sm">« Anterior</a>
        <?php endif; ?>
        <span class="adm-text-sm adm-text-muted" style="align-self:center">Página <?php echo $page ?> de <?php echo $totalPages ?></span>
        <?php if ($page < $totalPages): ?>
        <a href="<?php echo htmlspecialchars($app->view->queryLink('/nexora/rh/funcionarios', $app->request->query(), ['page' => $page + 1])) ?>" class="adm-btn adm-btn-outline adm-btn-sm">Seguinte »</a>
        <?php endif; ?>
    </div>
    <?php endif; ?>

    <?php else: ?>
    <div class="adm-empty">
        <p class="adm-empty-title">Nenhum funcionário encontrado</p>
        <p class="adm-empty-sub">
            <?php if ($query): ?>
            Nenhum resultado para os filtros aplicados.
            <?php elseif ($podeGerir): ?>
            Clique em "Novo Funcionário" para adicionar o primeiro.
            <?php else: ?>
            Ainda não há funcionários registados.
            <?php endif; ?>
        </p>
    </div>
    <?php endif; ?>
</div>

<?php if ($podeGerir): ?>
<!-- Modal: Novo Funcionário -->
<div class="adm-modal" id="funcionarioModal" style="display:none">
    <div class="adm-modal-content" style="max-width:720px">
        <div class="adm-modal-header">
            <h3>Novo Funcionário</h3>
            <button class="adm-btn adm-btn-ghost adm-btn-icon" type="button" onclick="closeFuncionarioModal()">&times;</button>
        </div>
        <div style="padding:var(--adm-sp-5) var(--adm-sp-6);max-height:72vh;overflow-y:auto">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-nome">Nome Completo <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="f-nome" maxlength="150" placeholder="ex: Maria José Macamo">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-numero">Número de Funcionário</label>
                    <input class="adm-input" type="text" id="f-numero" maxlength="30" placeholder="A gerar…" disabled style="background:var(--adm-gray-50);color:var(--adm-gray-500)">
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
                    <select class="adm-select" id="f-cargo-id" onchange="onCargoChange()">
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
                    <label class="adm-label" for="f-salario">Salário Base (MZN)</label>
                    <?php if ($podeVerSalarios): ?>
                    <input class="adm-input" type="number" id="f-salario" step="0.01" min="0" placeholder="ex: 25000.00">
                    <?php else: ?>
                    <input class="adm-input" type="text" id="f-salario" placeholder="Confidencial — sem permissão" disabled>
                    <?php endif; ?>
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-horario-id">Horário de Trabalho</label>
                    <select class="adm-select" id="f-horario-id">
                        <option value="">— Nenhum —</option>
                        <?php foreach ($horarios as $h): ?>
                        <option value="<?php echo (int) $h['id'] ?>"><?php echo htmlspecialchars($h['nome']) ?> (<?php echo htmlspecialchars($h['hora_entrada']) ?>–<?php echo htmlspecialchars($h['hora_saida']) ?>)</option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-endereco">Endereço</label>
                    <input class="adm-input" type="text" id="f-endereco" maxlength="255" placeholder="ex: Av. Eduardo Mondlane, Maputo">
                </div>
            </div>
        </div>
        <div class="adm-modal-footer">
            <button class="adm-btn adm-btn-ghost" type="button" onclick="closeFuncionarioModal()">Cancelar</button>
            <button class="adm-btn adm-btn-primary" type="button" onclick="saveFuncionario()">Adicionar Funcionário</button>
        </div>
    </div>
</div>
<?php endif; ?>

<script>
const CSRF = '<?php echo $csrf ?>';

function applyFiltros() {
    const params = new URLSearchParams();
    const q   = document.getElementById('fSearch').value.trim();
    const uni = document.getElementById('fUnidade').value;
    const est = document.getElementById('fEstado').value;
    if (q)   params.set('q', q);
    if (uni) params.set('unit_id', uni);
    if (est) params.set('estado', est);
    const qs = params.toString();
    location.href = '/nexora/rh/funcionarios' + (qs ? '?' + qs : '');
}

<?php if ($podeGerir): ?>
const _funcModal = document.getElementById('funcionarioModal');

async function openFuncionarioModal() {
    _funcModal.style.display = 'flex';
    const el = document.getElementById('f-numero');
    el.value = '';
    el.placeholder = 'A gerar…';
    try {
        const r = await fetch('/nexora/api/rh_proximo_numero_funcionario');
        if (r.ok) { const d = await r.json(); el.value = d.numero ?? ''; }
    } catch (_) {}
}

function closeFuncionarioModal() {
    _funcModal.style.display = 'none';
    document.getElementById('f-numero').value = '';
}
_funcModal.addEventListener('click', e => { if (e.target === _funcModal) closeFuncionarioModal(); });

function onCargoChange() {
    const select = document.getElementById('f-cargo-id');
    document.getElementById('f-cargo-texto').style.display = select.value === 'outro' ? '' : 'none';
}

async function saveFuncionario() {
    const nome = document.getElementById('f-nome').value.trim();
    if (!nome) { showToast('O nome completo é obrigatório.', 'error'); return; }

    const unidade     = document.getElementById('f-unidade').value;
    const salario     = document.getElementById('f-salario').value;
    const cargoSelect = document.getElementById('f-cargo-id').value;
    const cargoId     = (cargoSelect && cargoSelect !== 'outro') ? Number(cargoSelect) : null;
    const cargoTexto  = cargoSelect === 'outro' ? (document.getElementById('f-cargo-texto').value.trim() || null) : null;
    const horario     = document.getElementById('f-horario-id').value;

    try {
        const res = await fetch('/nexora/api/rh_funcionario_save', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                nome_completo:      nome,
                numero_funcionario: document.getElementById('f-numero').value.trim() || null,
                unit_id:            unidade ? Number(unidade) : null,
                cargo_id:           cargoId,
                cargo:              cargoTexto,
                horario_id:         horario ? Number(horario) : null,
                tipo_contrato:      document.getElementById('f-tipo-contrato').value,
                data_admissao:      document.getElementById('f-data-admissao').value || null,
                data_nascimento:    document.getElementById('f-data-nascimento').value || null,
                genero:             document.getElementById('f-genero').value || null,
                nuit:               document.getElementById('f-nuit').value.trim() || null,
                telefone:           document.getElementById('f-telefone').value.trim() || null,
                email:              document.getElementById('f-email').value.trim() || null,
                endereco:           document.getElementById('f-endereco').value.trim() || null,
                salario_base:       salario ? Number(salario) : null,
                csrf: CSRF
            })
        }).then(r => r.json());

        if (res.ok) {
            showToast(res.msg || 'Funcionário adicionado com sucesso.');
            closeFuncionarioModal();
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(res.erro || 'Erro ao adicionar funcionário.', 'error');
        }
    } catch { showToast('Erro de ligação.', 'error'); }
}
<?php endif; ?>
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
