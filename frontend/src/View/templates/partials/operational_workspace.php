<?php
declare(strict_types=1);

$resources = $workspace['resources'] ?? [];
$resourceData   = [];
$paginationMeta = [];
$normaliseRows = static function (mixed $body): array {
    if (!is_array($body)) {
        return [];
    }
    if (is_array($body['data'] ?? null)) {
        return array_is_list($body['data']) ? $body['data'] : [];
    }
    if (array_is_list($body)) {
        return $body;
    }
    foreach ($body as $value) {
        if (is_array($value) && array_is_list($value)) {
            return $value;
        }
    }
    $rows = [];
    foreach ($body as $label => $value) {
        if (is_scalar($value) || $value === null) {
            $rows[] = ['nome' => str_replace('_', ' ', (string) $label), 'valor' => $value];
        }
    }
    return $rows;
};
foreach ($resources as $key => $resource) {
    $resourceData[$key] = [];
    if (!empty($resource['path'])) {
        $response = $app->nexora->call('GET', $resource['path']);
        $body = $response['body'] ?? [];
        $resourceData[$key] = $normaliseRows($body);
        if (isset($body['total'], $body['pagina'], $body['paginas'])) {
            $paginationMeta[$key] = [
                'total'      => (int) $body['total'],
                'pagina'     => (int) $body['pagina'],
                'paginas'    => (int) $body['paginas'],
                'por_pagina' => (int) ($body['por_pagina'] ?? 25),
            ];
        }
    }
}

$firstResource = (string) array_key_first($resources);
$csrf = $app->security->csrfToken();
$valueFor = static function (array $row, string $keys): mixed {
    foreach (explode('|', $keys) as $key) {
        if (array_key_exists($key, $row) && $row[$key] !== null && $row[$key] !== '') {
            return $row[$key];
        }
    }
    return null;
};

include dirname(__DIR__) . '/layouts/' . (!empty($GLOBALS['_escolarPanel']) ? 'escola_top' : 'top') . '.php';
?>

<div class="adm-page-header">
    <div>
        <h1 class="adm-page-title"><?php echo htmlspecialchars($workspace['title']) ?></h1>
        <p class="adm-text-muted"><?php echo htmlspecialchars($workspace['subtitle']) ?></p>
    </div>
    <button class="adm-btn adm-btn-primary" type="button" id="workspaceCreateButton" onclick="workspaceOpenCreate()">
        Novo registo
    </button>
</div>

<div class="adm-tabs" id="workspaceTabs">
    <?php foreach ($resources as $key => $resource): ?>
    <button class="adm-tab <?php echo $key === $firstResource ? 'active' : '' ?>" type="button"
            onclick="workspaceSwitch('<?php echo htmlspecialchars($key) ?>',this)">
        <?php echo htmlspecialchars($resource['label']) ?>
        <?php if (!empty($resource['path'])): ?>
        <span class="adm-tab-badge"><?php echo isset($paginationMeta[$key]) ? $paginationMeta[$key]['total'] : count($resourceData[$key]) ?></span>
        <?php endif; ?>
    </button>
    <?php endforeach; ?>
</div>

<?php foreach ($resources as $key => $resource): ?>
<?php $pparam = $resource['pagina_param'] ?? 'pagina'; $baseUrl = strtok($_SERVER['REQUEST_URI'] ?? '', '?'); ?>
<div class="adm-tab-panel <?php echo $key === $firstResource ? 'active' : '' ?>" id="workspace-<?php echo htmlspecialchars($key) ?>">
    <div class="adm-card">
        <div class="adm-card-header">
            <div>
                <h2 class="adm-card-title"><?php echo htmlspecialchars($resource['label']) ?></h2>
                <?php if (!empty($resource['description'])): ?>
                <p class="adm-text-muted"><?php echo htmlspecialchars($resource['description']) ?></p>
                <?php endif; ?>
            </div>
            <?php if (!empty($resource['tools'])): ?>
            <div class="adm-row-actions">
                <?php foreach ($resource['tools'] as $tool): ?>
                <button class="adm-btn adm-btn-outline adm-btn-sm" type="button"
                    onclick='workspaceRunAction(<?php echo json_encode($tool, JSON_UNESCAPED_UNICODE) ?>, null)'>
                    <?php echo htmlspecialchars($tool['label']) ?>
                </button>
                <?php endforeach; ?>
            </div>
            <?php endif; ?>
        </div>
        <?php if ($resourceData[$key]): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr>
                        <th style="color:var(--adm-gray-300);font-weight:500;width:2rem">#</th>
                        <?php foreach ($resource['columns'] ?? [] as $column): ?>
                        <th><?php echo htmlspecialchars($column[1]) ?></th>
                        <?php endforeach; ?>
                        <?php if (!empty($resource['actions'])): ?><th>Ações</th><?php endif; ?>
                    </tr>
                </thead>
                <tbody>
                <?php foreach ($resourceData[$key] as $row): ?>
                    <tr>
                        <td>
                            <span class="adm-badge adm-badge--gray" style="font-family:monospace;font-size:.7rem;cursor:pointer;user-select:all"
                                  title="Copiar ID" onclick="navigator.clipboard.writeText('<?= (int)($row['id'] ?? 0) ?>')">
                                <?= (int)($row['id'] ?? 0) ?>
                            </span>
                        </td>
                        <?php foreach ($resource['columns'] ?? [] as $column):
                            $value = $valueFor((array) $row, $column[0]);
                            if (is_bool($value)) {
                                $value = $value ? 'Sim' : 'Não';
                            } elseif (is_array($value)) {
                                $value = count($value);
                            }
                        ?>
                        <td><?php echo $value !== null ? htmlspecialchars((string) $value) : '—' ?></td>
                        <?php endforeach; ?>
                        <?php if (!empty($resource['actions'])): ?>
                        <td>
                            <div class="adm-row-actions">
                            <?php foreach ($resource['actions'] as $action):
                                if (isset($action['only_when'])) {
                                    $show = true;
                                    foreach ($action['only_when'] as $field => $allowed) {
                                        $rowVal = (string) ($row[$field] ?? '');
                                        $allowed = is_array($allowed) ? $allowed : [$allowed];
                                        if (!in_array($rowVal, $allowed, true)) { $show = false; break; }
                                    }
                                    if (!$show) continue;
                                }
                                if (isset($action['link'])):
                                    $href = str_replace('{id}', (string)(int)($row['id'] ?? 0), $action['link']);
                            ?>
                                <a class="adm-btn adm-btn-ghost adm-btn-sm" href="<?php echo htmlspecialchars($href) ?>">
                                    <?php echo htmlspecialchars($action['label']) ?>
                                </a>
                            <?php else: ?>
                                <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button"
                                    onclick='workspaceRunAction(
                                        <?php echo json_encode($action, JSON_UNESCAPED_UNICODE) ?>,
                                        <?php echo (int) ($row["id"] ?? 0) ?>
                                    )'>
                                    <?php echo htmlspecialchars($action['label']) ?>
                                </button>
                            <?php endif; ?>
                            <?php endforeach; ?>
                            </div>
                        </td>
                        <?php endif; ?>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php if (!empty($paginationMeta[$key])): ?>
        <?php $pm = $paginationMeta[$key]; ?>
        <div style="display:flex;align-items:center;justify-content:space-between;padding:var(--adm-sp-3) var(--adm-sp-4);border-top:1px solid var(--adm-border);gap:var(--adm-sp-3);flex-wrap:wrap">
            <span class="adm-text-muted" style="font-size:.82rem">
                <?php echo $pm['total'] ?> registos · Página <?php echo $pm['pagina'] ?> de <?php echo $pm['paginas'] ?>
            </span>
            <div style="display:flex;gap:var(--adm-sp-2);align-items:center">
                <?php if ($pm['pagina'] > 1): ?>
                <a href="<?php echo htmlspecialchars($baseUrl . '?' . http_build_query(array_merge($_GET, [$pparam => $pm['pagina'] - 1]))) ?>"
                   class="adm-btn adm-btn-ghost adm-btn-sm">&#8592; Anterior</a>
                <?php else: ?>
                <button class="adm-btn adm-btn-ghost adm-btn-sm" disabled>&#8592; Anterior</button>
                <?php endif; ?>
                <?php for ($p = max(1, $pm['pagina'] - 2); $p <= min($pm['paginas'], $pm['pagina'] + 2); $p++): ?>
                <a href="<?php echo htmlspecialchars($baseUrl . '?' . http_build_query(array_merge($_GET, [$pparam => $p]))) ?>"
                   class="adm-btn adm-btn-sm <?php echo $p === $pm['pagina'] ? 'adm-btn-primary' : 'adm-btn-ghost' ?>"
                   style="min-width:2rem;padding:0 .5rem"><?php echo $p ?></a>
                <?php endfor; ?>
                <?php if ($pm['pagina'] < $pm['paginas']): ?>
                <a href="<?php echo htmlspecialchars($baseUrl . '?' . http_build_query(array_merge($_GET, [$pparam => $pm['pagina'] + 1]))) ?>"
                   class="adm-btn adm-btn-ghost adm-btn-sm">Seguinte &#8594;</a>
                <?php else: ?>
                <button class="adm-btn adm-btn-ghost adm-btn-sm" disabled>Seguinte &#8594;</button>
                <?php endif; ?>
            </div>
        </div>
        <?php endif; ?>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title"><?php echo empty($resource['path']) ? 'Operação disponível' : 'Nenhum registo encontrado' ?></p>
            <p class="adm-empty-sub"><?php echo htmlspecialchars($resource['empty'] ?? 'Use o botão acima para criar o primeiro registo.') ?></p>
        </div>
        <?php endif; ?>
        <?php if (!empty($resource['filters'])): ?>
        <div style="display:flex;gap:var(--adm-sp-3);padding:var(--adm-sp-3) var(--adm-sp-4);background:var(--adm-bg);border-top:1px solid var(--adm-border);flex-wrap:wrap;align-items:center">
            <span class="adm-text-muted" style="font-size:.82rem;font-weight:500">Filtrar:</span>
            <?php foreach ($resource['filters'] as $filter): ?>
            <div style="display:flex;gap:var(--adm-sp-1);align-items:center">
                <label class="adm-label" style="margin:0;font-size:.8rem"><?php echo htmlspecialchars($filter['label']) ?></label>
                <select class="adm-select adm-select-sm" style="font-size:.82rem;padding:.25rem .5rem"
                        onchange="location.href='<?php echo htmlspecialchars($baseUrl) ?>?'+new URLSearchParams({...Object.fromEntries(new URLSearchParams('<?php echo htmlspecialchars(http_build_query(array_diff_key($_GET, [$pparam=>1, $filter['name']=>1]))) ?>')),<?php echo json_encode($filter['name']) ?>:this.value,<?php echo json_encode($pparam) ?>:1})">
                    <?php foreach ($filter['options'] as $val => $lbl): ?>
                    <option value="<?php echo htmlspecialchars((string)$val) ?>" <?php echo (string)($filter['current'] ?? '') === (string)$val ? 'selected' : '' ?>>
                        <?php echo htmlspecialchars($lbl) ?>
                    </option>
                    <?php endforeach; ?>
                </select>
            </div>
            <?php endforeach; ?>
        </div>
        <?php endif; ?>
    </div>
</div>
<?php endforeach; ?>

<div class="adm-modal-overlay" id="workspaceModal">
    <div class="adm-modal-content" style="max-width:760px">
        <div class="adm-modal-header">
            <p class="adm-modal-title" id="workspaceModalTitle">Novo registo</p>
            <button class="adm-btn adm-btn-ghost adm-btn-icon" type="button" onclick="workspaceClose()">&times;</button>
        </div>
        <div class="adm-modal-body" id="workspaceFields" style="max-height:70vh;overflow-y:auto;padding:var(--adm-sp-5) var(--adm-sp-6)"></div>
        <div class="adm-modal-footer" style="padding:var(--adm-sp-4) var(--adm-sp-6)">
            <button class="adm-btn adm-btn-ghost" type="button" onclick="workspaceClose()">Cancelar</button>
            <button class="adm-btn adm-btn-primary" type="button" onclick="workspaceSave()">Guardar</button>
        </div>
    </div>
</div>

<div class="adm-modal-overlay" id="workspaceResultModal">
    <div class="adm-modal-content" style="max-width:900px">
        <div class="adm-modal-header">
            <p class="adm-modal-title" id="workspaceResultTitle">Resultado</p>
            <button class="adm-btn adm-btn-ghost adm-btn-icon" type="button" onclick="document.getElementById('workspaceResultModal').classList.remove('open')">&times;</button>
        </div>
        <div class="adm-modal-body" style="padding:var(--adm-sp-5) var(--adm-sp-6)">
            <pre id="workspaceResult" style="white-space:pre-wrap;max-height:60vh;overflow:auto;background:var(--adm-bg);padding:16px;border-radius:8px"></pre>
        </div>
        <div class="adm-modal-footer" style="padding:var(--adm-sp-4) var(--adm-sp-6)">
            <button class="adm-btn adm-btn-primary" type="button" onclick="document.getElementById('workspaceResultModal').classList.remove('open')">Fechar</button>
        </div>
    </div>
</div>

<script>
const WORKSPACE_RESOURCES = <?php echo json_encode($resources, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?>;
const WORKSPACE_CSRF = <?php echo json_encode($csrf) ?>;
const WORKSPACE_ENDPOINT = <?php echo json_encode($workspace['endpoint']) ?>;
let workspaceCurrent = <?php echo json_encode($firstResource) ?>;
let workspaceOperation = null;
let workspaceRecordId = null;
let workspaceShowResult = false;

function workspaceEscape(value) {
    const node = document.createElement('div');
    node.textContent = String(value ?? '');
    return node.innerHTML;
}

function workspaceRenderFields(fields) {
    document.getElementById('workspaceFields').innerHTML = (fields || []).map((field, index) => {
        const name = field.name;
        const label = field.label;
        const type = field.type || 'text';
        const required = field.required ? ' required' : '';
        let input;
        if (type === 'select') {
            const defVal = String(field.default ?? '');
            input = '<select class="adm-select workspace-field" data-name="' + name + '"' + required + '>' +
                (field.required ? '' : '<option value="">— Seleccionar —</option>') +
                (field.options || []).map(option => {
                    const value = typeof option === 'object' ? option.value : option;
                    const text  = typeof option === 'object' ? option.label : option;
                    const sel   = defVal && String(value) === defVal ? ' selected' : '';
                    return '<option value="' + workspaceEscape(value) + '"' + sel + '>' + workspaceEscape(text) + '</option>';
                }).join('') + '</select>';
        } else if (type === 'textarea') {
            input = '<textarea class="adm-textarea workspace-field" data-name="' + name + '"' + required + '></textarea>';
        } else {
            const step = type === 'number' ? ' step="0.01"' : '';
            input = '<input class="adm-input workspace-field" data-name="' + name + '" type="' + type + '"' + step + required + '>';
        }
        return (index % 2 === 0 ? '<div class="adm-form-row">' : '') +
            '<div class="adm-form-group"><label class="adm-label">' + workspaceEscape(label) + '</label>' + input + '</div>' +
            (index % 2 === 1 || index === fields.length - 1 ? '</div>' : '');
    }).join('');
}

function workspaceOpen(operation, title, fields, id, showResult) {
    workspaceOperation = operation;
    workspaceRecordId = id || null;
    workspaceShowResult = Boolean(showResult);
    document.getElementById('workspaceModalTitle').textContent = title;
    workspaceRenderFields(fields || []);
    document.getElementById('workspaceModal').classList.add('open');
}

function workspaceOpenCreate() {
    const resource = WORKSPACE_RESOURCES[workspaceCurrent];
    if (!resource || !resource.create) return;
    workspaceOpen(resource.create.operation, resource.create.label || 'Novo registo', resource.create.fields || [], null, resource.create.result);
}

function workspaceClose() {
    document.getElementById('workspaceModal').classList.remove('open');
}

async function workspaceRunAction(action, id) {
    if (action.fields && action.fields.length) {
        workspaceOpen(action.operation, action.label, action.fields, id, action.result);
        return;
    }
    if (action.confirm && !confirm(action.confirm)) return;
    await workspaceSubmit(action.operation, id, {}, action.result);
}

async function workspaceSave() {
    const payload = {};
    for (const input of document.querySelectorAll('.workspace-field')) {
        if (input.required && !input.value) {
            showToast('Preencha todos os campos obrigatórios.', 'error');
            input.focus();
            return;
        }
        if (input.value === '') continue;
        payload[input.dataset.name] = input.type === 'number' ? Number(input.value) : input.value;
    }
    let recordId = workspaceRecordId;
    if (payload._id) {
        recordId = payload._id;
        delete payload._id;
    }
    await workspaceSubmit(workspaceOperation, recordId, payload, workspaceShowResult);
}

async function workspaceSubmit(operation, id, payload, showResult) {
    try {
        const response = await fetch(WORKSPACE_ENDPOINT, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({csrf: WORKSPACE_CSRF, operation, id, payload})
        });
        const result = await response.json();
        if (!response.ok || !result.ok) throw new Error(result.erro || 'Erro ao executar a operação.');
        if (showResult) {
            workspaceClose();
            document.getElementById('workspaceResultTitle').textContent = result.msg || 'Resultado';
            document.getElementById('workspaceResult').textContent = JSON.stringify(result.data ?? {}, null, 2);
            document.getElementById('workspaceResultModal').classList.add('open');
            return;
        }
        showToast(result.msg || 'Operação concluída com sucesso.');
        setTimeout(() => location.reload(), 500);
    } catch (error) {
        showToast(error.message || 'Erro de ligação.', 'error');
    }
}

function workspaceSwitch(resource, button) {
    workspaceCurrent = resource;
    document.querySelectorAll('#workspaceTabs .adm-tab').forEach(item => item.classList.remove('active'));
    document.querySelectorAll('[id^="workspace-"]').forEach(item => item.classList.remove('active'));
    button.classList.add('active');
    document.getElementById('workspace-' + resource).classList.add('active');
    const create = WORKSPACE_RESOURCES[resource].create;
    const createButton = document.getElementById('workspaceCreateButton');
    createButton.style.display = create ? '' : 'none';
    createButton.textContent = create ? (create.label || 'Novo registo') : '';
    if (Object.keys(WORKSPACE_RESOURCES).length > 1) {
        location.hash = resource;
    } else {
        history.replaceState(null, '', location.pathname + location.search);
    }
}

document.addEventListener('DOMContentLoaded', () => {
    const resource = location.hash.substring(1);
    const keys = Object.keys(WORKSPACE_RESOURCES);
    const selected = keys.includes(resource) ? resource : keys[0];
    const button = document.querySelectorAll('#workspaceTabs .adm-tab')[keys.indexOf(selected)];
    workspaceSwitch(selected, button);
});
</script>

<?php include dirname(__DIR__) . '/layouts/' . (!empty($GLOBALS['_escolarPanel']) ? 'escola_bottom' : 'bottom') . '.php'; ?>
