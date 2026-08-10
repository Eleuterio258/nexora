<?php

if (!$app->session->canModule('pos')) {
    header('Location: /nexora');
    exit;
}

$erro = null;
$sucesso = null;
$descontos = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $app->security->validateCsrf($_POST['csrf_token'] ?? '');

        $acao = $_POST['acao'] ?? '';
        $id = $_POST['id'] ?? '';

        if ($acao === 'eliminar' && $id !== '') {
            $app->payCoreDiscount->delete($id);
            $sucesso = 'Desconto removido com sucesso.';
        } else {
            $data = [
                'name' => $_POST['name'] ?? '',
                'description' => $_POST['description'] ?? null,
                'type' => $_POST['type'] ?? 'PERCENTAGE',
                'value' => (float) ($_POST['value'] ?? 0),
                'min_amount' => $_POST['min_amount'] !== '' ? (float) $_POST['min_amount'] : null,
                'max_amount' => $_POST['max_amount'] !== '' ? (float) $_POST['max_amount'] : null,
                'valid_from' => $_POST['valid_from'] ?? null,
                'valid_until' => $_POST['valid_until'] ?? null,
                'active' => isset($_POST['active']),
            ];

            if ($acao === 'editar' && $id !== '') {
                $app->payCoreDiscount->update($id, $data);
                $sucesso = 'Desconto actualizado com sucesso.';
            } else {
                $app->payCoreDiscount->create($data);
                $sucesso = 'Desconto criado com sucesso.';
            }
        }
    } catch (\Throwable $e) {
        $erro = $e->getMessage();
    }
}

try {
    $descontos = $app->payCoreDiscount->list();
} catch (\Throwable $e) {
    $erro = $e->getMessage();
}

$pageTitle  = 'Descontos POS';
$activePage = 'pos_descontos';
$breadcrumb = [['Admin', '/nexora/'], ['POS', '/nexora/pos'], ['Descontos', '']];
$csrf       = $app->security->csrfToken();

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Descontos POS</h1>
    <div class="adm-page-header-actions">
        <button type="button" class="adm-btn adm-btn-primary" onclick="document.getElementById('descontoModal').classList.add('open')">
            <i class="fa-solid fa-plus"></i> Novo desconto
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
        <h2 class="adm-card-title">Catálogo de descontos</h2>
    </div>
    <div class="adm-card-body" style="padding:0">
        <?php if (!empty($descontos)): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr>
                        <th>Nome</th>
                        <th>Tipo</th>
                        <th>Valor</th>
                        <th>Mínimo</th>
                        <th>Máximo</th>
                        <th>Válido de</th>
                        <th>Válido até</th>
                        <th>Estado</th>
                        <th style="width:120px"></th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach ($descontos as $d): ?>
                    <tr>
                        <td>
                            <div class="adm-fw-600"><?= htmlspecialchars($d['name'] ?? '—') ?></div>
                            <?php if (!empty($d['description'])): ?>
                            <div class="adm-text-xs adm-text-muted"><?= htmlspecialchars($d['description']) ?></div>
                            <?php endif; ?>
                        </td>
                        <td>
                            <?php if (($d['type'] ?? '') === 'PERCENTAGE'): ?>
                            <span class="adm-badge adm-badge--blue">Percentual</span>
                            <?php else: ?>
                            <span class="adm-badge adm-badge--yellow">Valor fixo</span>
                            <?php endif; ?>
                        </td>
                        <td class="adm-fw-600">
                            <?= ($d['type'] ?? '') === 'PERCENTAGE' ? number_format((float) ($d['value'] ?? 0), 2) . '%' : number_format((float) ($d['value'] ?? 0), 2) . ' MZN' ?>
                        </td>
                        <td class="adm-text-muted"><?= isset($d['min_amount']) ? number_format((float) $d['min_amount'], 2) . ' MZN' : '—' ?></td>
                        <td class="adm-text-muted"><?= isset($d['max_amount']) ? number_format((float) $d['max_amount'], 2) . ' MZN' : '—' ?></td>
                        <td class="adm-text-muted"><?= !empty($d['valid_from']) ? date('d/m/Y', strtotime($d['valid_from'])) : '—' ?></td>
                        <td class="adm-text-muted"><?= !empty($d['valid_until']) ? date('d/m/Y', strtotime($d['valid_until'])) : '—' ?></td>
                        <td>
                            <?php if (($d['active'] ?? false)): ?>
                            <span class="adm-badge adm-badge--green">Activo</span>
                            <?php else: ?>
                            <span class="adm-badge adm-badge--gray">Inactivo</span>
                            <?php endif; ?>
                        </td>
                        <td>
                            <div class="adm-actions">
                                <button type="button" class="adm-btn adm-btn-ghost adm-btn-icon adm-btn-sm" title="Editar" onclick='editarDesconto(<?= json_encode($d) ?>)'>
                                    <i class="fa-solid fa-pen"></i>
                                </button>
                                <form method="post" action="" style="display:inline" onsubmit="return confirm('Remover este desconto?')">
                                    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">
                                    <input type="hidden" name="acao" value="eliminar">
                                    <input type="hidden" name="id" value="<?= htmlspecialchars($d['id'] ?? '') ?>">
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
            <i class="fa-solid fa-tag" style="font-size:2rem;opacity:.2"></i>
            <p class="adm-empty-title">Sem descontos registados</p>
            <p class="adm-empty-sub">Crie o primeiro desconto para usar no POS.</p>
        </div>
        <?php endif; ?>
    </div>
</div>

<!-- Modal -->
<div class="adm-modal-overlay" id="descontoModal">
    <div class="adm-modal-content" style="max-width:560px;width:100%">
        <div class="adm-modal-header">
            <h3 id="modalTitle">Novo desconto</h3>
            <button type="button" class="adm-btn adm-btn-ghost adm-btn-icon adm-btn-sm" onclick="fecharModal()">
                <i class="fa-solid fa-xmark"></i>
            </button>
        </div>
        <form method="post" action="" id="descontoForm">
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

            <div class="adm-form-row" style="grid-template-columns:1fr 1fr">
                <div class="adm-form-group">
                    <label class="adm-label" for="type">Tipo</label>
                    <select id="type" name="type" class="adm-select" required>
                        <option value="PERCENTAGE">Percentual (%)</option>
                        <option value="FIXED">Valor fixo (MZN)</option>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="value">Valor</label>
                    <input type="number" id="value" name="value" class="adm-input" step="0.01" min="0" required>
                </div>
            </div>

            <div class="adm-form-row" style="grid-template-columns:1fr 1fr">
                <div class="adm-form-group">
                    <label class="adm-label" for="min_amount">Valor mínimo da transação</label>
                    <input type="number" id="min_amount" name="min_amount" class="adm-input" step="0.01" min="0">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="max_amount">Valor máximo da transação</label>
                    <input type="number" id="max_amount" name="max_amount" class="adm-input" step="0.01" min="0">
                </div>
            </div>

            <div class="adm-form-row" style="grid-template-columns:1fr 1fr">
                <div class="adm-form-group">
                    <label class="adm-label" for="valid_from">Válido de</label>
                    <input type="datetime-local" id="valid_from" name="valid_from" class="adm-input">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="valid_until">Válido até</label>
                    <input type="datetime-local" id="valid_until" name="valid_until" class="adm-input">
                </div>
            </div>

            <div class="adm-form-group">
                <label class="adm-label" style="display:flex;align-items:center;gap:var(--adm-sp-2)">
                    <input type="checkbox" name="active" id="active" checked>
                    Activo
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
function editarDesconto(d) {
    document.getElementById('modalTitle').textContent = 'Editar desconto';
    document.getElementById('formAcao').value = 'editar';
    document.getElementById('formId').value = d.id || '';
    document.getElementById('name').value = d.name || '';
    document.getElementById('description').value = d.description || '';
    document.getElementById('type').value = d.type || 'PERCENTAGE';
    document.getElementById('value').value = d.value ?? '';
    document.getElementById('min_amount').value = d.min_amount ?? '';
    document.getElementById('max_amount').value = d.max_amount ?? '';
    document.getElementById('valid_from').value = d.valid_from ? d.valid_from.slice(0,16) : '';
    document.getElementById('valid_until').value = d.valid_until ? d.valid_until.slice(0,16) : '';
    document.getElementById('active').checked = d.active === true;
    document.getElementById('descontoModal').classList.add('open');
}

function fecharModal() {
    document.getElementById('descontoModal').classList.remove('open');
    document.getElementById('descontoForm').reset();
    document.getElementById('modalTitle').textContent = 'Novo desconto';
    document.getElementById('formAcao').value = 'criar';
    document.getElementById('formId').value = '';
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
