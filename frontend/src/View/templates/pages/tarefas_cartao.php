<?php
declare(strict_types=1);

$idHash   = $app->request->queryString('id');
$cartaoId = $idHash ? $app->id->decode($idHash) : 0;
$backUrl  = filter_var($_GET['back'] ?? '', FILTER_SANITIZE_URL);
if ($cartaoId <= 0) {
    header('Location: ' . $app->routes->path('tarefas'));
    exit;
}

$pageTitle  = 'Cartão';
$activePage = 'tarefas_cartao';
$csrf       = $app->security->csrfToken();

try {
    $resp   = $app->nexora->call('GET', "/api/tarefas/cartoes/$cartaoId");
    $cartao = (array) ($resp['body'] ?? []);
} catch (\Throwable) {
    $cartao = [];
}

if (empty($cartao)) {
    header('Location: ' . $app->routes->path('tarefas'));
    exit;
}

$pageTitle  = htmlspecialchars($cartao['titulo'] ?? 'Cartão');
$breadcrumb = [
    ['Admin', '/nexora/'],
    ['Tarefas', $app->routes->path('tarefas')],
    [$pageTitle, ''],
];

$prioridades = [
    'baixa'   => ['cor' => '#64748B', 'label' => 'Baixa'],
    'media'   => ['cor' => '#F59E0B', 'label' => 'Média'],
    'alta'    => ['cor' => '#EF4444', 'label' => 'Alta'],
    'urgente' => ['cor' => '#7C3AED', 'label' => 'Urgente'],
];

$prio = $cartao['prioridade'] ?? 'media';
$prioCor = $prioridades[$prio]['cor'] ?? '#F59E0B';

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <div>
        <h1 class="adm-page-title" id="tituloDisplay"><?= htmlspecialchars($cartao['titulo']) ?></h1>
        <div style="display:flex;align-items:center;gap:.75rem;margin-top:.25rem">
            <span id="prioBadge" style="font-size:.78rem;font-weight:600;padding:.15rem .55rem;border-radius:5px;background:<?= $prioCor ?>20;color:<?= $prioCor ?>">
                <?= htmlspecialchars($prioridades[$prio]['label'] ?? $prio) ?>
            </span>
            <?php if ($cartao['concluido'] ?? false): ?>
            <span style="font-size:.78rem;font-weight:600;padding:.15rem .55rem;border-radius:5px;background:#d1fae5;color:#065f46">Concluído</span>
            <?php endif; ?>
        </div>
    </div>
    <div class="adm-page-header-actions">
        <?php if ($backUrl): ?>
        <a href="<?= htmlspecialchars($backUrl) ?>" class="adm-btn adm-btn-outline adm-btn-sm">
            <i class="fa-solid fa-arrow-left fa-fw"></i> Voltar
        </a>
        <?php else: ?>
        <a href="<?= htmlspecialchars($app->routes->path('tarefas')) ?>" class="adm-btn adm-btn-outline adm-btn-sm">
            <i class="fa-solid fa-arrow-left fa-fw"></i> Quadros
        </a>
        <?php endif; ?>
    </div>
</div>

<div id="formMsg"></div>

<div style="display:grid;grid-template-columns:1fr 280px;gap:1.5rem;align-items:start">

    <!-- Coluna principal -->
    <div>
        <div class="adm-card adm-mb-4">
            <div class="adm-card-body">
                <div class="adm-form-group">
                    <label class="adm-label">Título</label>
                    <input class="adm-input" type="text" id="cartaoTitulo" value="<?= htmlspecialchars($cartao['titulo']) ?>" maxlength="255">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label">Descrição</label>
                    <textarea class="adm-input" id="cartaoDesc" rows="5" placeholder="Descrição detalhada da tarefa..."><?= htmlspecialchars($cartao['descricao'] ?? '') ?></textarea>
                </div>
                <div style="display:flex;justify-content:flex-end;gap:.75rem">
                    <button class="adm-btn adm-btn-primary adm-btn-sm" onclick="guardarCartao()">
                        <i class="fa-solid fa-floppy-disk fa-fw"></i> Guardar
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Sidebar -->
    <div style="display:flex;flex-direction:column;gap:1rem">

        <!-- Acções -->
        <div class="adm-card">
            <div class="adm-card-header"><h4 class="adm-card-title">Acções</h4></div>
            <div class="adm-card-body" style="display:flex;flex-direction:column;gap:.5rem">
                <button class="adm-btn adm-btn-outline adm-btn-sm" style="justify-content:flex-start;width:100%"
                        onclick="toggleConcluido()" id="btnConcluir">
                    <?php if ($cartao['concluido'] ?? false): ?>
                    <i class="fa-solid fa-rotate-left fa-fw"></i> Reabrir
                    <?php else: ?>
                    <i class="fa-solid fa-check fa-fw" style="color:var(--adm-green)"></i> Marcar concluído
                    <?php endif; ?>
                </button>
                <button class="adm-btn adm-btn-outline adm-btn-sm" style="justify-content:flex-start;width:100%;color:#dc2626"
                        onclick="eliminarCartao()">
                    <i class="fa-solid fa-trash fa-fw"></i> Eliminar cartão
                </button>
            </div>
        </div>

        <!-- Detalhes -->
        <div class="adm-card">
            <div class="adm-card-header"><h4 class="adm-card-title">Detalhes</h4></div>
            <div class="adm-card-body" style="display:flex;flex-direction:column;gap:.85rem">
                <div class="adm-form-group" style="margin:0">
                    <label class="adm-label">Prioridade</label>
                    <select class="adm-select adm-select--sm" id="cartaoPrioridade" onchange="guardarCartao()">
                        <?php foreach ($prioridades as $key => $p): ?>
                        <option value="<?= $key ?>" <?= $prio === $key ? 'selected' : '' ?>><?= $p['label'] ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group" style="margin:0">
                    <label class="adm-label">Data de início</label>
                    <input class="adm-input adm-input--sm" type="date" id="cartaoDataInicio"
                           value="<?= htmlspecialchars($cartao['data_inicio'] ?? '') ?>"
                           onchange="guardarCartao()">
                </div>
                <div class="adm-form-group" style="margin:0">
                    <label class="adm-label">Prazo</label>
                    <input class="adm-input adm-input--sm" type="date" id="cartaoDataFim"
                           value="<?= htmlspecialchars($cartao['data_fim'] ?? '') ?>"
                           onchange="guardarCartao()">
                </div>
            </div>
        </div>

    </div>
</div>

<script>
const CSRF      = '<?= $csrf ?>';
const CARTAO_ID = <?= $cartaoId ?>;
const BACK_URL  = '<?= addslashes($backUrl ?: $app->routes->path('tarefas')) ?>';

async function guardarCartao() {
    const titulo = document.getElementById('cartaoTitulo').value.trim();
    if (!titulo) { showToast('O título é obrigatório','error'); return; }

    const res  = await fetch('/nexora/api/cartao_save', {
        method:'POST', headers:{'Content-Type':'application/json'},
        body: JSON.stringify({
            csrf: CSRF, id: CARTAO_ID, titulo,
            descricao:   document.getElementById('cartaoDesc').value || null,
            data_inicio: document.getElementById('cartaoDataInicio').value || null,
            data_fim:    document.getElementById('cartaoDataFim').value || null,
            prioridade:  document.getElementById('cartaoPrioridade').value,
        }),
    });
    const data = await res.json();
    if (data.ok) showToast('Guardado');
    else showToast(data.erro || 'Erro ao guardar','error');
}

async function toggleConcluido() {
    const res  = await fetch('/nexora/api/cartao_concluir', {
        method:'POST', headers:{'Content-Type':'application/json'},
        body: JSON.stringify({csrf:CSRF, id:CARTAO_ID}),
    });
    const data = await res.json();
    if (data.ok) { showToast('Estado actualizado'); setTimeout(() => location.reload(), 500); }
    else showToast(data.erro || 'Erro','error');
}

async function eliminarCartao() {
    if (!confirm('Eliminar este cartão? Esta acção é irreversível.')) return;
    const res  = await fetch('/nexora/api/cartao_delete', {
        method:'POST', headers:{'Content-Type':'application/json'},
        body: JSON.stringify({csrf:CSRF, id:CARTAO_ID}),
    });
    const data = await res.json();
    if (data.ok) { showToast('Cartão eliminado'); setTimeout(() => window.location.href = BACK_URL, 600); }
    else showToast(data.erro || 'Erro','error');
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
