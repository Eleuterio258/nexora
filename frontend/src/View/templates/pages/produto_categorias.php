<?php

declare(strict_types=1);

if (!$app->session->canModule('stock')) {
    header('Location: /nexora');
    exit;
}

$erro = null;
$sucesso = null;
$categorias = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $app->security->validateCsrf($_POST['csrf_token'] ?? '');

        $acao = $_POST['acao'] ?? '';
        $id = $_POST['id'] ?? '';

        if ($acao === 'eliminar' && $id !== '') {
            $app->payCoreStockCategory->delete($id);
            $sucesso = 'Categoria removida com sucesso.';
        } else {
            $data = [
                'name' => $_POST['name'] ?? '',
                'description' => $_POST['description'] ?? null,
                'icon' => $_POST['icon'] ?? null,
                'color' => $_POST['color'] ?? null,
                'order' => $_POST['order'] !== '' ? (int) $_POST['order'] : 0,
                'active' => isset($_POST['active']),
            ];

            if ($acao === 'editar' && $id !== '') {
                $app->payCoreStockCategory->update($id, $data);
                $sucesso = 'Categoria actualizada com sucesso.';
            } else {
                $app->payCoreStockCategory->create($data);
                $sucesso = 'Categoria criada com sucesso.';
            }
        }
    } catch (\Throwable $e) {
        $erro = $e->getMessage();
    }
}

try {
    $categorias = $app->payCoreStockCategory->list();
} catch (\Throwable $e) {
    $erro = $e->getMessage();
}

$pageTitle  = 'Categorias de Produtos';
$activePage = 'produtos';
$breadcrumb = [['Admin', '/nexora/'], ['Produtos', '/nexora/produtos'], ['Categorias', '']];
$csrf       = $app->security->csrfToken();

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Categorias de Produtos</h1>
    <div class="adm-page-header-actions">
        <a href="<?= htmlspecialchars($app->routes->path('produtos')) ?>" class="adm-btn adm-btn-outline">
            <i class="fa-solid fa-arrow-left"></i> Voltar
        </a>
        <button type="button" class="adm-btn adm-btn-primary" onclick="document.getElementById('categoriaModal').classList.add('open')">
            <i class="fa-solid fa-plus"></i> Nova categoria
        </button>
    </div>
</div>

<?php if ($erro): ?>
<div class="adm-alert adm-alert--error" style="margin-bottom:var(--adm-sp-5)">
    <i class="fa-solid fa-circle-exclamation"></i>
    <span><?= htmlspecialchars($erro) ?></span>
</div>
<?php endif; ?>

<?php if ($sucesso): ?>
<div class="adm-alert adm-alert--success" style="margin-bottom:var(--adm-sp-5)">
    <i class="fa-solid fa-check-circle"></i>
    <span><?= htmlspecialchars($sucesso) ?></span>
</div>
<?php endif; ?>

<div class="adm-card">
    <div class="adm-card-header">
        <h2 class="adm-card-title">Catálogo de categorias</h2>
    </div>
    <div class="adm-card-body" style="padding:0">
        <?php if (!empty($categorias)): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr>
                        <th style="width:40px"></th>
                        <th>Nome</th>
                        <th>Descrição</th>
                        <th>Ordem</th>
                        <th>Estado</th>
                        <th style="width:120px"></th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach ($categorias as $c): ?>
                    <tr>
                        <td>
                            <?php if (!empty($c['color'])): ?>
                            <span style="display:inline-block;width:18px;height:18px;border-radius:4px;background:<?= htmlspecialchars($c['color']) ?>;border:1px solid rgba(0,0,0,.1)"></span>
                            <?php else: ?>
                            <span class="adm-text-muted">—</span>
                            <?php endif; ?>
                        </td>
                        <td>
                            <div class="adm-fw-600"><?= htmlspecialchars($c['name'] ?? '—') ?></div>
                            <?php if (!empty($c['icon'])): ?>
                            <div class="adm-text-xs adm-text-muted">Icon: <?= htmlspecialchars($c['icon']) ?></div>
                            <?php endif; ?>
                        </td>
                        <td class="adm-text-muted"><?= htmlspecialchars($c['description'] ?? '—') ?></td>
                        <td class="adm-text-muted"><?= (int) ($c['order_index'] ?? 0) ?></td>
                        <td>
                            <?php if (($c['active'] ?? false)): ?>
                            <span class="adm-badge adm-badge--green">Activa</span>
                            <?php else: ?>
                            <span class="adm-badge adm-badge--gray">Inactiva</span>
                            <?php endif; ?>
                        </td>
                        <td>
                            <div class="adm-actions">
                                <button type="button" class="adm-btn adm-btn-ghost adm-btn-icon adm-btn-sm" title="Editar" onclick='editarCategoria(<?= json_encode($c) ?>)'>
                                    <i class="fa-solid fa-pen"></i>
                                </button>
                                <form method="post" action="" style="display:inline" onsubmit="return confirm('Remover esta categoria?')">
                                    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">
                                    <input type="hidden" name="acao" value="eliminar">
                                    <input type="hidden" name="id" value="<?= htmlspecialchars($c['id'] ?? '') ?>">
                                    <button type="submit" class="adm-btn adm-btn-ghost adm-btn-icon adm-btn-sm" title="Remover">
                                        <i class="fa-solid fa-trash"></i>
                                    </button>
                                </form>
                            </div>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty" style="padding:var(--adm-sp-12)">
            <i class="fa-solid fa-tags" style="font-size:2rem;opacity:.2"></i>
            <p class="adm-empty-title">Sem categorias registadas</p>
            <p class="adm-empty-sub">Crie a primeira categoria para organizar os produtos.</p>
        </div>
        <?php endif; ?>
    </div>
</div>

<!-- Modal -->
<div class="adm-modal-overlay" id="categoriaModal">
    <div class="adm-modal-content" style="max-width:520px;width:100%">
        <div class="adm-modal-header">
            <h3 id="modalTitle">Nova categoria</h3>
            <button type="button" class="adm-btn adm-btn-ghost adm-btn-icon adm-btn-sm" onclick="fecharModal()">
                <i class="fa-solid fa-xmark"></i>
            </button>
        </div>
        <form method="post" action="" id="categoriaForm">
            <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">
            <input type="hidden" name="acao" id="formAcao" value="criar">
            <input type="hidden" name="id" id="formId" value="">

            <div class="adm-form-group">
                <label class="adm-label" for="name">Nome</label>
                <input type="text" id="name" name="name" class="adm-input" required>
            </div>

            <div class="adm-form-group">
                <label class="adm-label" for="description">Descrição</label>
                <textarea id="description" name="description" class="adm-textarea" rows="2"></textarea>
            </div>

            <div class="adm-form-row" style="grid-template-columns:1fr 1fr 1fr">
                <div class="adm-form-group">
                    <label class="adm-label" for="icon">Icone</label>
                    <input type="text" id="icon" name="icon" class="adm-input" placeholder="drink.svg">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="color">Cor</label>
                    <input type="color" id="color" name="color" class="adm-input" style="padding:2px;height:38px">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="order">Ordem</label>
                    <input type="number" id="order" name="order" class="adm-input" value="0" min="0">
                </div>
            </div>

            <div class="adm-form-group">
                <label class="adm-label" style="display:flex;align-items:center;gap:var(--adm-sp-2)">
                    <input type="checkbox" name="active" id="active" checked>
                    Activa
                </label>
            </div>

            <div class="adm-modal-footer">
                <button type="button" class="adm-btn adm-btn-outline" onclick="fecharModal()">Cancelar</button>
                <button type="submit" class="adm-btn adm-btn-primary">Guardar</button>
            </div>
        </form>
    </div>
</div>

<script>
function editarCategoria(c) {
    document.getElementById('modalTitle').textContent = 'Editar categoria';
    document.getElementById('formAcao').value = 'editar';
    document.getElementById('formId').value = c.id || '';
    document.getElementById('name').value = c.name || '';
    document.getElementById('description').value = c.description || '';
    document.getElementById('icon').value = c.icon || '';
    document.getElementById('color').value = c.color || '#10b981';
    document.getElementById('order').value = c.order_index ?? 0;
    document.getElementById('active').checked = c.active === true;
    document.getElementById('categoriaModal').classList.add('open');
}

function fecharModal() {
    document.getElementById('categoriaModal').classList.remove('open');
    document.getElementById('categoriaForm').reset();
    document.getElementById('modalTitle').textContent = 'Nova categoria';
    document.getElementById('formAcao').value = 'criar';
    document.getElementById('formId').value = '';
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
