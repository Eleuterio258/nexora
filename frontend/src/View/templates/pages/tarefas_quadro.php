<?php
declare(strict_types=1);

$idHash   = $app->request->queryString('id');
$quadroId = $idHash ? $app->id->decode($idHash) : 0;
if ($quadroId <= 0) {
    header('Location: ' . $app->routes->path('tarefas'));
    exit;
}

$pageTitle  = 'Quadro';
$activePage = 'tarefas_quadro';
$csrf       = $app->security->csrfToken();

try {
    $resp    = $app->nexora->call('GET', "/api/tarefas/quadros/$quadroId");
    $quadro  = (array) ($resp['body']['quadro'] ?? []);
    $listas  = (array) ($resp['body']['listas'] ?? []);
} catch (\Throwable) {
    $quadro = [];
    $listas = [];
}

if (empty($quadro)) {
    header('Location: ' . $app->routes->path('tarefas'));
    exit;
}

$pageTitle  = htmlspecialchars($quadro['titulo'] ?? 'Quadro');
$breadcrumb = [
    ['Admin', '/nexora/'],
    ['Tarefas', $app->routes->path('tarefas')],
    [$pageTitle, ''],
];

$prioridades = ['baixa' => '#64748B', 'media' => '#F59E0B', 'alta' => '#EF4444', 'urgente' => '#7C3AED'];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <div>
        <h1 class="adm-page-title" style="display:flex;align-items:center;gap:.5rem">
            <span style="display:inline-block;width:14px;height:14px;border-radius:50%;background:<?= htmlspecialchars($quadro['cor'] ?? '#F59E0B') ?>"></span>
            <?= htmlspecialchars($quadro['titulo'] ?? '') ?>
        </h1>
        <?php if (!empty($quadro['descricao'])): ?>
        <p class="adm-page-subtitle"><?= htmlspecialchars($quadro['descricao']) ?></p>
        <?php endif; ?>
    </div>
    <div class="adm-page-header-actions">
        <a href="<?= htmlspecialchars($app->routes->path('tarefas')) ?>" class="adm-btn adm-btn-outline adm-btn-sm">
            <i class="fa-solid fa-arrow-left fa-fw"></i> Quadros
        </a>
        <button class="adm-btn adm-btn-primary adm-btn-sm" onclick="abrirModalLista()">
            <i class="fa-solid fa-plus fa-fw"></i> Nova Lista
        </button>
    </div>
</div>

<!-- Kanban Board -->
<div id="kanbanBoard" style="display:flex;gap:1rem;overflow-x:auto;padding-bottom:2rem;align-items:flex-start;min-height:60vh">
<?php foreach ($listas as $lista): ?>
<?php
    $listaId = (int)$lista['id'];
    $cartoes  = json_decode(json_encode($lista['cartoes']), true) ?: [];
?>
<div class="kanban-col" id="col-<?= $listaId ?>" data-lista-id="<?= $listaId ?>">
    <div class="kanban-col-header">
        <span class="kanban-col-titulo" ondblclick="editarLista(<?= $listaId ?>, this)"><?= htmlspecialchars($lista['titulo']) ?></span>
        <div style="display:flex;gap:.25rem">
            <button class="kanban-col-btn" title="Novo cartão" onclick="abrirModalCartao(<?= $listaId ?>)">
                <i class="fa-solid fa-plus"></i>
            </button>
            <button class="kanban-col-btn kanban-col-btn--danger" title="Eliminar lista" onclick="eliminarLista(<?= $listaId ?>)">
                <i class="fa-solid fa-trash"></i>
            </button>
        </div>
    </div>
    <div class="kanban-col-body" id="body-<?= $listaId ?>"
         ondragover="event.preventDefault()" ondrop="soltar(event, <?= $listaId ?>)">
        <?php foreach ($cartoes as $c): ?>
        <?php $cId = (int)$c['id']; $cor = $prioridades[$c['prioridade'] ?? 'media'] ?? '#F59E0B'; ?>
        <div class="kanban-card" id="card-<?= $cId ?>" draggable="true"
             ondragstart="arrastar(event, <?= $cId ?>, <?= $listaId ?>)"
             onclick="verCartao(<?= $cId ?>)">
            <?php if ($c['concluido'] ?? false): ?>
            <span class="kanban-card-badge kanban-card-badge--done">Concluído</span>
            <?php endif; ?>
            <p class="kanban-card-titulo <?= ($c['concluido'] ?? false) ? 'kanban-card-done' : '' ?>">
                <?= htmlspecialchars($c['titulo']) ?>
            </p>
            <div class="kanban-card-meta">
                <span class="kanban-prioridade" style="background:<?= $cor ?>20;color:<?= $cor ?>">
                    <?= htmlspecialchars($c['prioridade'] ?? 'media') ?>
                </span>
                <?php if (!empty($c['data_fim'])): ?>
                <span class="kanban-data"><i class="fa-regular fa-clock fa-fw"></i><?= htmlspecialchars($c['data_fim']) ?></span>
                <?php endif; ?>
            </div>
        </div>
        <?php endforeach; ?>
        <button class="kanban-add-card-btn" onclick="abrirModalCartao(<?= $listaId ?>)">
            <i class="fa-solid fa-plus fa-fw"></i> Cartão
        </button>
    </div>
</div>
<?php endforeach; ?>

<div class="kanban-col kanban-col--new" onclick="abrirModalLista()" style="cursor:pointer;border:2px dashed var(--adm-gray-200);background:transparent;justify-content:center;align-items:center;display:flex;min-height:80px">
    <span style="color:var(--adm-gray-400);font-size:.875rem"><i class="fa-solid fa-plus fa-fw"></i> Nova Lista</span>
</div>
</div>

<!-- Modal Nova Lista -->
<div id="modalLista" class="adm-modal-backdrop" style="display:none" onclick="if(event.target===this)fecharModalLista()">
    <div class="adm-modal" style="max-width:380px">
        <div class="adm-modal-header">
            <h3 class="adm-modal-title">Nova Lista</h3>
            <button class="adm-modal-close" onclick="fecharModalLista()">×</button>
        </div>
        <div class="adm-modal-body">
            <input type="hidden" id="listaId" value="">
            <div class="adm-form-group">
                <label class="adm-label">Título *</label>
                <input class="adm-input" type="text" id="listaTitulo" placeholder="Ex: A Fazer" maxlength="200">
            </div>
        </div>
        <div class="adm-modal-footer">
            <button class="adm-btn adm-btn-outline" onclick="fecharModalLista()">Cancelar</button>
            <button class="adm-btn adm-btn-primary" id="btnSalvarLista" onclick="salvarLista()">Guardar</button>
        </div>
    </div>
</div>

<!-- Modal Novo Cartão -->
<div id="modalCartao" class="adm-modal-backdrop" style="display:none" onclick="if(event.target===this)fecharModalCartao()">
    <div class="adm-modal" style="max-width:440px">
        <div class="adm-modal-header">
            <h3 id="modalCartaoTitulo" class="adm-modal-title">Novo Cartão</h3>
            <button class="adm-modal-close" onclick="fecharModalCartao()">×</button>
        </div>
        <div class="adm-modal-body">
            <input type="hidden" id="cartaoId" value="">
            <input type="hidden" id="cartaoListaId" value="">
            <div class="adm-form-group">
                <label class="adm-label">Título *</label>
                <input class="adm-input" type="text" id="cartaoTitulo" placeholder="O que precisa ser feito?" maxlength="255">
            </div>
            <div class="adm-form-group">
                <label class="adm-label">Descrição</label>
                <textarea class="adm-input" id="cartaoDesc" rows="3" placeholder="Detalhes opcionais"></textarea>
            </div>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem">
                <div class="adm-form-group">
                    <label class="adm-label">Prazo</label>
                    <input class="adm-input" type="date" id="cartaoDataFim">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label">Prioridade</label>
                    <select class="adm-select" id="cartaoPrioridade">
                        <option value="baixa">Baixa</option>
                        <option value="media" selected>Média</option>
                        <option value="alta">Alta</option>
                        <option value="urgente">Urgente</option>
                    </select>
                </div>
            </div>
        </div>
        <div class="adm-modal-footer">
            <button class="adm-btn adm-btn-outline" onclick="fecharModalCartao()">Cancelar</button>
            <button class="adm-btn adm-btn-primary" id="btnSalvarCartao" onclick="salvarCartao()">Guardar</button>
        </div>
    </div>
</div>

<style>
.kanban-col {
    min-width:270px; max-width:270px; border-radius:10px; background:var(--adm-gray-50);
    border:1px solid var(--adm-gray-200); display:flex; flex-direction:column;
}
.kanban-col-header {
    padding:.65rem .85rem; display:flex; align-items:center; justify-content:space-between;
    border-bottom:1px solid var(--adm-gray-200); gap:.5rem;
}
.kanban-col-titulo { font-weight:600; font-size:.875rem; flex:1; cursor:default; }
.kanban-col-btn {
    background:none; border:none; border-radius:5px; color:var(--adm-gray-400);
    width:26px; height:26px; cursor:pointer; display:flex; align-items:center; justify-content:center;
}
.kanban-col-btn:hover { background:var(--adm-gray-200); color:var(--adm-gray-700); }
.kanban-col-btn--danger:hover { background:#fee2e2; color:#dc2626; }
.kanban-col-body { padding:.5rem; display:flex; flex-direction:column; gap:.5rem; flex:1; min-height:80px; }
.kanban-card {
    background:#fff; border:1px solid var(--adm-gray-200); border-radius:8px;
    padding:.65rem .75rem; cursor:pointer; transition:.15s;
}
.kanban-card:hover { box-shadow:0 2px 8px rgba(0,0,0,.1); border-color:var(--adm-gray-300); }
.kanban-card.drag-over { border:2px dashed var(--adm-green); background:var(--adm-gray-50); }
.kanban-card-titulo { margin:0; font-size:.8rem; font-weight:500; color:var(--adm-gray-800); }
.kanban-card-done { text-decoration:line-through; color:var(--adm-gray-400); }
.kanban-card-badge { font-size:.7rem; font-weight:600; padding:.1rem .4rem; border-radius:4px; display:inline-block; margin-bottom:.3rem; }
.kanban-card-badge--done { background:#d1fae5; color:#065f46; }
.kanban-card-meta { display:flex; align-items:center; gap:.4rem; margin-top:.4rem; flex-wrap:wrap; }
.kanban-prioridade { font-size:.7rem; font-weight:600; padding:.1rem .45rem; border-radius:4px; }
.kanban-data { font-size:.7rem; color:var(--adm-gray-500); }
.kanban-add-card-btn {
    background:none; border:1px dashed var(--adm-gray-300); border-radius:7px;
    color:var(--adm-gray-400); padding:.45rem; cursor:pointer; font-size:.78rem;
    width:100%; text-align:left;
}
.kanban-add-card-btn:hover { border-color:var(--adm-green); color:var(--adm-green); }
</style>

<script>
const CSRF       = '<?= $csrf ?>';
const QUADRO_ID  = <?= $quadroId ?>;
const CARTAO_URL = '<?= htmlspecialchars($app->routes->path('tarefas_cartao')) ?>';

let arrastando = null, listaOrigem = null;

function arrastar(e, cartaoId, listaId) {
    arrastando   = cartaoId;
    listaOrigem  = listaId;
    e.dataTransfer.effectAllowed = 'move';
}

async function soltar(e, listaDestinoId) {
    e.preventDefault();
    if (!arrastando || listaDestinoId === listaOrigem) { arrastando = null; return; }

    const col    = document.getElementById('body-' + listaDestinoId);
    const cards  = col.querySelectorAll('.kanban-card');
    const novaPos = cards.length;

    const res  = await fetch('/nexora/api/cartao_mover', {
        method:'POST', headers:{'Content-Type':'application/json'},
        body: JSON.stringify({csrf:CSRF, id:arrastando, lista_id:listaDestinoId, posicao:novaPos}),
    });
    const data = await res.json();
    if (data.ok) location.reload();
    else showToast(data.erro || 'Erro ao mover', 'error');
    arrastando = null;
}

function verCartao(id) {
    window.location.href = CARTAO_URL + '?id=' + nexoraEncodeId(id) + '&back=' + encodeURIComponent(location.href);
}

function abrirModalLista() {
    document.getElementById('listaId').value = '';
    document.getElementById('listaTitulo').value = '';
    document.getElementById('modalLista').style.display = 'flex';
    setTimeout(() => document.getElementById('listaTitulo').focus(), 50);
}
function fecharModalLista() { document.getElementById('modalLista').style.display = 'none'; }

async function editarLista(id, el) {
    const novo = prompt('Novo título:', el.textContent.trim());
    if (!novo || novo === el.textContent.trim()) return;
    const res  = await fetch('/nexora/api/lista_save', {
        method:'POST', headers:{'Content-Type':'application/json'},
        body: JSON.stringify({csrf:CSRF, id, titulo:novo}),
    });
    const data = await res.json();
    if (data.ok) el.textContent = novo;
    else showToast(data.erro || 'Erro', 'error');
}

async function salvarLista() {
    const titulo = document.getElementById('listaTitulo').value.trim();
    if (!titulo) { showToast('O título é obrigatório','error'); return; }
    const btn = document.getElementById('btnSalvarLista');
    btn.disabled = true;
    try {
        const res  = await fetch('/nexora/api/lista_save', {
            method:'POST', headers:{'Content-Type':'application/json'},
            body: JSON.stringify({csrf:CSRF, titulo, quadro_id:QUADRO_ID}),
        });
        const data = await res.json();
        if (data.id || data.ok) { showToast('Lista criada'); setTimeout(() => location.reload(), 400); }
        else showToast(data.erro || 'Erro','error');
    } catch { showToast('Erro de ligação','error'); }
    finally { btn.disabled = false; }
}

async function eliminarLista(id) {
    if (!confirm('Eliminar esta lista e todos os seus cartões?')) return;
    const res  = await fetch('/nexora/api/lista_delete', {
        method:'POST', headers:{'Content-Type':'application/json'},
        body: JSON.stringify({csrf:CSRF, id}),
    });
    const data = await res.json();
    if (data.ok) { showToast('Lista eliminada'); setTimeout(() => location.reload(), 400); }
    else showToast(data.erro || 'Erro','error');
}

function abrirModalCartao(listaId) {
    document.getElementById('cartaoId').value = '';
    document.getElementById('cartaoListaId').value = listaId;
    document.getElementById('cartaoTitulo').value = '';
    document.getElementById('cartaoDesc').value = '';
    document.getElementById('cartaoDataFim').value = '';
    document.getElementById('cartaoPrioridade').value = 'media';
    document.getElementById('modalCartaoTitulo').textContent = 'Novo Cartão';
    document.getElementById('modalCartao').style.display = 'flex';
    setTimeout(() => document.getElementById('cartaoTitulo').focus(), 50);
}
function fecharModalCartao() { document.getElementById('modalCartao').style.display = 'none'; }

async function salvarCartao() {
    const titulo = document.getElementById('cartaoTitulo').value.trim();
    if (!titulo) { showToast('O título é obrigatório','error'); return; }
    const btn = document.getElementById('btnSalvarCartao');
    btn.disabled = true;
    try {
        const res  = await fetch('/nexora/api/cartao_save', {
            method:'POST', headers:{'Content-Type':'application/json'},
            body: JSON.stringify({
                csrf:CSRF,
                id: document.getElementById('cartaoId').value || null,
                lista_id: parseInt(document.getElementById('cartaoListaId').value),
                titulo,
                descricao: document.getElementById('cartaoDesc').value || null,
                data_fim: document.getElementById('cartaoDataFim').value || null,
                prioridade: document.getElementById('cartaoPrioridade').value,
            }),
        });
        const data = await res.json();
        if (data.id || data.ok) { showToast('Cartão guardado'); setTimeout(() => location.reload(), 400); }
        else showToast(data.erro || 'Erro','error');
    } catch { showToast('Erro de ligação','error'); }
    finally { btn.disabled = false; }
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
