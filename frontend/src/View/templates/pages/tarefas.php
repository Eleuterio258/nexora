<?php
declare(strict_types=1);

$pageTitle  = 'Tarefas';
$activePage = 'tarefas';
$breadcrumb = [['Admin', '/nexora/'], ['Tarefas', '']];
$csrf       = $app->security->csrfToken();

$arquivados = isset($_GET['arquivados']);

try {
    $resp    = $app->nexora->call('GET', '/api/tarefas/quadros', null, ['arquivado' => $arquivados ? '1' : '0']);
    $quadros = is_array($resp['body'] ?? null) ? $resp['body'] : [];
} catch (\Throwable) {
    $quadros = [];
}

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <div>
        <h1 class="adm-page-title">Tarefas</h1>
        <p class="adm-page-subtitle"><?= $arquivados ? 'Quadros arquivados' : 'Os seus quadros Kanban' ?></p>
    </div>
    <div class="adm-page-header-actions">
        <?php if (!$arquivados): ?>
        <a href="?arquivados=1" class="adm-btn adm-btn-ghost adm-btn-sm">
            <i class="fa-solid fa-box-archive fa-fw"></i> Arquivados
        </a>
        <?php else: ?>
        <a href="<?= htmlspecialchars($app->routes->path('tarefas')) ?>" class="adm-btn adm-btn-ghost adm-btn-sm">
            <i class="fa-solid fa-arrow-left fa-fw"></i> Activos
        </a>
        <?php endif; ?>
        <button class="adm-btn adm-btn-primary" onclick="abrirModalQuadro()">
            <i class="fa-solid fa-plus fa-fw"></i> Novo Quadro
        </button>
    </div>
</div>

<?php if (empty($quadros)): ?>
<div class="adm-empty-state" style="margin-top:3rem">
    <i class="fa-solid fa-table-columns" style="font-size:2.5rem;color:var(--adm-gray-300);margin-bottom:1rem"></i>
    <p><?= $arquivados ? 'Nenhum quadro arquivado.' : 'Ainda não tem quadros. Crie o primeiro!' ?></p>
    <?php if (!$arquivados): ?>
    <button class="adm-btn adm-btn-primary adm-btn-sm" onclick="abrirModalQuadro()" style="margin-top:.75rem">
        Criar quadro
    </button>
    <?php endif; ?>
</div>
<?php else: ?>
<div id="quadrosGrid" style="display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:1.25rem;margin-top:1.5rem">
<?php foreach ($quadros as $q): ?>
    <div class="quadro-card" data-id="<?= (int)$q['id'] ?>">
        <div class="quadro-card-header" style="background:<?= htmlspecialchars($q['cor'] ?? '#F59E0B') ?>">
            <span class="quadro-card-titulo"><?= htmlspecialchars($q['titulo']) ?></span>
            <div class="quadro-card-actions">
                <button class="quadro-btn-action" title="Editar" onclick="abrirModalQuadro(<?= (int)$q['id'] ?>, '<?= addslashes(htmlspecialchars($q['titulo'])) ?>', '<?= htmlspecialchars($q['cor'] ?? '#F59E0B') ?>', '<?= addslashes(htmlspecialchars($q['descricao'] ?? '')) ?>')">
                    <i class="fa-solid fa-pen"></i>
                </button>
                <?php if (!($q['arquivado'] ?? false)): ?>
                <button class="quadro-btn-action" title="Arquivar" onclick="arquivarQuadro(<?= (int)$q['id'] ?>)">
                    <i class="fa-solid fa-box-archive"></i>
                </button>
                <?php endif; ?>
                <button class="quadro-btn-action" title="Eliminar" onclick="eliminarQuadro(<?= (int)$q['id'] ?>)">
                    <i class="fa-solid fa-trash"></i>
                </button>
            </div>
        </div>
        <a href="<?= htmlspecialchars($app->routes->path('tarefas_quadro')) ?>?id=<?= $app->id->encode((int)$q['id']) ?>" class="quadro-card-body">
            <?php if (!empty($q['descricao'])): ?>
            <p class="quadro-card-desc"><?= htmlspecialchars($q['descricao']) ?></p>
            <?php endif; ?>
            <span class="quadro-card-count"><?= (int)($q['total_cartoes'] ?? 0) ?> cartões</span>
        </a>
    </div>
<?php endforeach; ?>
</div>
<?php endif; ?>

<!-- Modal Quadro -->
<div id="modalQuadro" class="adm-modal-backdrop" style="display:none" onclick="if(event.target===this)fecharModal()">
    <div class="adm-modal" style="max-width:440px">
        <div class="adm-modal-header">
            <h3 id="modalQuadroTitulo" class="adm-modal-title">Novo Quadro</h3>
            <button class="adm-modal-close" onclick="fecharModal()">×</button>
        </div>
        <div class="adm-modal-body">
            <input type="hidden" id="quadroId" value="">
            <div class="adm-form-group">
                <label class="adm-label">Título *</label>
                <input class="adm-input" type="text" id="quadroTitulo" placeholder="Ex: Projecto Website" maxlength="200">
            </div>
            <div class="adm-form-group">
                <label class="adm-label">Descrição</label>
                <textarea class="adm-input" id="quadroDescricao" rows="2" placeholder="Opcional"></textarea>
            </div>
            <div class="adm-form-group">
                <label class="adm-label">Cor</label>
                <div style="display:flex;gap:.75rem;flex-wrap:wrap" id="coresPicker">
                    <?php foreach (['#F59E0B','#EF4444','#10B981','#3B82F6','#8B5CF6','#EC4899','#06B6D4','#64748B'] as $cor): ?>
                    <button type="button" class="cor-btn" data-cor="<?= $cor ?>"
                            style="width:32px;height:32px;border-radius:50%;background:<?= $cor ?>;border:3px solid transparent;cursor:pointer"
                            onclick="selecionarCor('<?= $cor ?>')"></button>
                    <?php endforeach; ?>
                </div>
                <input type="hidden" id="quadroCor" value="#F59E0B">
            </div>
        </div>
        <div class="adm-modal-footer">
            <button class="adm-btn adm-btn-outline" onclick="fecharModal()">Cancelar</button>
            <button class="adm-btn adm-btn-primary" id="btnSalvarQuadro" onclick="salvarQuadro()">Guardar</button>
        </div>
    </div>
</div>

<style>
.quadro-card { border-radius:10px; overflow:hidden; box-shadow:0 1px 4px rgba(0,0,0,.12); background:#fff; display:flex; flex-direction:column; }
.quadro-card-header { padding:.85rem 1rem; display:flex; align-items:center; justify-content:space-between; color:#fff; min-height:64px; }
.quadro-card-titulo { font-weight:600; font-size:.95rem; flex:1; text-shadow:0 1px 2px rgba(0,0,0,.2); }
.quadro-card-actions { display:flex; gap:.35rem; opacity:0; transition:.15s; }
.quadro-card:hover .quadro-card-actions { opacity:1; }
.quadro-btn-action { background:rgba(255,255,255,.25); border:none; border-radius:6px; color:#fff; width:28px; height:28px; cursor:pointer; display:flex; align-items:center; justify-content:center; font-size:.75rem; }
.quadro-btn-action:hover { background:rgba(255,255,255,.4); }
.quadro-card-body { display:block; padding:.85rem 1rem; color:inherit; text-decoration:none; flex:1; }
.quadro-card-body:hover { background:var(--adm-gray-50); }
.quadro-card-desc { font-size:.8rem; color:var(--adm-gray-500); margin:0 0 .5rem; }
.quadro-card-count { font-size:.78rem; color:var(--adm-gray-400); }
</style>

<script>
const CSRF = '<?= $csrf ?>';

function abrirModalQuadro(id = '', titulo = '', cor = '#F59E0B', desc = '') {
    document.getElementById('quadroId').value = id;
    document.getElementById('quadroTitulo').value = titulo;
    document.getElementById('quadroDescricao').value = desc;
    document.getElementById('quadroCor').value = cor;
    document.getElementById('modalQuadroTitulo').textContent = id ? 'Editar Quadro' : 'Novo Quadro';
    selecionarCor(cor);
    document.getElementById('modalQuadro').style.display = 'flex';
    setTimeout(() => document.getElementById('quadroTitulo').focus(), 50);
}
function fecharModal() {
    document.getElementById('modalQuadro').style.display = 'none';
}
function selecionarCor(cor) {
    document.getElementById('quadroCor').value = cor;
    document.querySelectorAll('.cor-btn').forEach(b => {
        b.style.border = b.dataset.cor === cor ? '3px solid #000' : '3px solid transparent';
    });
}

async function salvarQuadro() {
    const titulo = document.getElementById('quadroTitulo').value.trim();
    if (!titulo) { showToast('O título é obrigatório', 'error'); return; }
    const id  = document.getElementById('quadroId').value;
    const btn = document.getElementById('btnSalvarQuadro');
    btn.disabled = true;
    try {
        const res  = await fetch('/nexora/api/quadro_save', {
            method: 'POST',
            headers: {'Content-Type':'application/json'},
            body: JSON.stringify({
                csrf: CSRF, id: id ? parseInt(id) : null,
                titulo, descricao: document.getElementById('quadroDescricao').value || null,
                cor: document.getElementById('quadroCor').value,
            }),
        });
        const data = await res.json();
        if (data.ok || data.id) { showToast('Quadro guardado'); setTimeout(() => location.reload(), 600); }
        else showToast(data.erro || 'Erro ao guardar', 'error');
    } catch { showToast('Erro de ligação', 'error'); }
    finally { btn.disabled = false; }
}

async function arquivarQuadro(id) {
    if (!confirm('Arquivar este quadro?')) return;
    const res  = await fetch('/nexora/api/quadro_arquivar', {
        method:'POST', headers:{'Content-Type':'application/json'},
        body: JSON.stringify({csrf:CSRF, id}),
    });
    const data = await res.json();
    if (data.ok) { showToast('Quadro arquivado'); setTimeout(() => location.reload(), 600); }
    else showToast(data.erro || 'Erro', 'error');
}

async function eliminarQuadro(id) {
    if (!confirm('Eliminar este quadro e todos os seus dados? Esta acção é irreversível.')) return;
    const res  = await fetch('/nexora/api/quadro_delete', {
        method:'POST', headers:{'Content-Type':'application/json'},
        body: JSON.stringify({csrf:CSRF, id}),
    });
    const data = await res.json();
    if (data.ok) { showToast('Quadro eliminado'); setTimeout(() => location.reload(), 600); }
    else showToast(data.erro || 'Erro', 'error');
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
