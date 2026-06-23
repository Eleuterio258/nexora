<?php
    $types = [
        'request' => ['label' => 'Requisições', 'path' => '/api/purchase-requests'],
        'order' => ['label' => 'Ordens', 'path' => '/api/purchase-orders'],
        'receipt' => ['label' => 'Recepções', 'path' => '/api/purchase-receipts'],
        'return' => ['label' => 'Devoluções', 'path' => '/api/purchase-returns'],
        'invoice' => ['label' => 'Facturas', 'path' => '/api/purchase-invoices'],
        'payment' => ['label' => 'Pagamentos', 'path' => '/api/purchase-payments'],
    ];

    $data = [];
    foreach ($types as $key => $definition) {
        $response = $app->nexora->call('GET', $definition['path']);
        $data[$key] = is_array($response['body'] ?? null) ? $response['body'] : [];
    }

    $productsResponse = $app->nexora->call('GET', '/api/produtos', null, ['limit' => 100]);
    $products = $productsResponse['body']['data'] ?? [];
    $warehousesResponse = $app->nexora->call('GET', '/api/stock/warehouses');
    $warehouses = $warehousesResponse['body'] ?? [];

    $csrf = $app->security->csrfToken();
    $pageTitle = 'Compras';
    $activePage = 'compras';
    $breadcrumb = [['Admin', '/nexora/'], ['Compras', '']];

    function purchaseStatusBadge(string $status): string
    {
        return match ($status) {
            'aprovada', 'recebida', 'confirmado', 'confirmada', 'paga', 'liquidada' => 'adm-badge--green',
            'parcial', 'emitida', 'submetida' => 'adm-badge--blue',
            'cancelada', 'cancelado', 'rejeitada' => 'adm-badge--red',
            default => 'adm-badge--gray',
        };
    }

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <div>
        <h1 class="adm-page-title">Compras</h1>
        <p class="adm-text-muted">Requisições, ordens, recepções, devoluções, facturas e pagamentos.</p>
    </div>
    <div class="adm-page-header-actions">
        <button class="adm-btn adm-btn-outline" type="button" onclick="openPurchaseModal('item')">Adicionar item</button>
        <button class="adm-btn adm-btn-primary" type="button" onclick="openPurchaseModal('document')">Novo documento</button>
    </div>
</div>

<div class="adm-tabs" id="purchaseTabs">
    <?php foreach ($types as $key => $definition): ?>
    <button class="adm-tab <?php echo $key === 'request' ? 'active' : '' ?>" type="button" onclick="switchPurchaseTab('<?php echo $key ?>',this)">
        <?php echo htmlspecialchars($definition['label']) ?>
        <span class="adm-tab-badge"><?php echo count($data[$key]) ?></span>
    </button>
    <?php endforeach; ?>
</div>

<?php foreach ($types as $key => $definition): ?>
<div class="adm-tab-panel <?php echo $key === 'request' ? 'active' : '' ?>" id="purchase-<?php echo $key ?>">
    <div class="adm-card">
        <div class="adm-card-header">
            <h2 class="adm-card-title"><?php echo htmlspecialchars($definition['label']) ?></h2>
        </div>
        <?php if ($data[$key]): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr>
                        <th>Número</th>
                        <th>Data</th>
                        <th>Fornecedor / Departamento</th>
                        <th>Estado</th>
                        <th>Total</th>
                        <th>Itens</th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach ($data[$key] as $row):
                    $date = $row['request_date'] ?? $row['order_date'] ?? $row['receipt_date']
                        ?? $row['return_date'] ?? $row['invoice_date'] ?? $row['payment_date'] ?? null;
                    $owner = $row['supplier_name'] ?? $row['department'] ?? '—';
                    $status = (string) ($row['status'] ?? '—');
                    $total = $row['total'] ?? $row['valor'] ?? $row['estimated_total'] ?? null;
                    $items = is_array($row['items'] ?? null) ? count($row['items']) : 0;
                ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars((string) ($row['numero'] ?? $row['id'])) ?></td>
                    <td><?php echo $date ? htmlspecialchars((string) $date) : '—' ?></td>
                    <td><?php echo htmlspecialchars((string) $owner) ?></td>
                    <td><span class="adm-badge <?php echo purchaseStatusBadge($status) ?>"><?php echo htmlspecialchars(ucfirst($status)) ?></span></td>
                    <td><?php echo $total !== null ? number_format((float) $total, 2, ',', '.') . ' MZN' : '—' ?></td>
                    <td><?php echo $items ?></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Nenhum registo</p>
            <p class="adm-empty-sub">Crie o primeiro documento nesta etapa do processo de compras.</p>
        </div>
        <?php endif; ?>
    </div>
</div>
<?php endforeach; ?>

<div class="adm-modal-overlay" id="purchaseModal">
    <div class="adm-modal" style="max-width:760px">
        <p class="adm-modal-title" id="purchaseModalTitle">Novo documento</p>
        <div class="adm-modal-body">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="purchaseType">Tipo</label>
                    <select class="adm-select" id="purchaseType" onchange="renderPurchaseFields()">
                        <?php foreach ($types as $key => $definition): ?>
                        <option value="<?php echo $key ?>"><?php echo htmlspecialchars($definition['label']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="purchaseNumber">Número</label>
                    <input class="adm-input" id="purchaseNumber" placeholder="Ex.: OC-2026-001">
                </div>
            </div>
            <div id="purchaseDynamicFields"></div>
        </div>
        <div class="adm-modal-footer">
            <button class="adm-btn adm-btn-outline" type="button" onclick="closePurchaseModal()">Cancelar</button>
            <button class="adm-btn adm-btn-primary" type="button" onclick="savePurchase()">Guardar</button>
        </div>
    </div>
</div>

<script>
const PURCHASE_CSRF = <?php echo json_encode($csrf) ?>;
const PURCHASE_PRODUCTS = <?php echo json_encode($products, JSON_UNESCAPED_UNICODE) ?>;
const PURCHASE_WAREHOUSES = <?php echo json_encode($warehouses, JSON_UNESCAPED_UNICODE) ?>;
let purchaseMode = 'document';

const documentFields = {
    request: [
        ['department','Departamento','text'], ['required_date','Data necessária','date'],
        ['prioridade','Prioridade','select','normal|alta|urgente|baixa'], ['justificacao','Justificação','text']
    ],
    order: [
        ['supplier_id','ID do fornecedor','number'], ['purchase_request_id','ID da requisição','number'],
        ['expected_date','Entrega prevista','date'], ['status','Estado','select','aprovada|rascunho'],
        ['payment_terms','Condições de pagamento','text']
    ],
    receipt: [
        ['purchase_order_id','ID da ordem','number'], ['warehouse_id','Armazém','warehouse'],
        ['supplier_document','Documento do fornecedor','text']
    ],
    return: [
        ['goods_receipt_id','ID da recepção','number'], ['motivo','Motivo','text']
    ],
    invoice: [
        ['supplier_id','ID do fornecedor','number'], ['purchase_order_id','ID da ordem','number'],
        ['goods_receipt_id','ID da recepção','number'], ['supplier_invoice_number','Factura do fornecedor','text'],
        ['due_date','Vencimento','date']
    ],
    payment: [
        ['supplier_id','ID do fornecedor','number'], ['metodo','Método','select','transferencia|dinheiro|mpesa|emola|cartao'],
        ['valor','Valor','number'], ['referencia','Referência','text']
    ]
};

const itemFields = {
    request: [
        ['purchase_request_id','ID da requisição','number'], ['product_id','Produto','product'],
        ['descricao','Descrição','text'], ['quantity','Quantidade','number'], ['estimated_unit_price','Preço estimado','number']
    ],
    order: [
        ['purchase_order_id','ID da ordem','number'], ['product_id','Produto','product'],
        ['descricao','Descrição','text'], ['quantity','Quantidade','number'], ['unit_price','Preço unitário','number'],
        ['desconto','Desconto','number'], ['tax_rate','IVA %','number']
    ],
    receipt: [
        ['goods_receipt_id','ID da recepção','number'], ['purchase_order_item_id','ID do item da ordem','number'],
        ['quantity_received','Quantidade recebida','number'], ['unit_cost','Custo unitário','number'],
        ['lote','Lote','text'], ['validade','Validade','date']
    ],
    return: [
        ['purchase_return_id','ID da devolução','number'], ['goods_receipt_item_id','ID do item recebido','number'],
        ['quantity','Quantidade','number'], ['unit_cost','Custo unitário','number']
    ],
    invoice: [
        ['purchase_invoice_id','ID da factura','number'], ['purchase_order_item_id','ID do item da ordem','number'],
        ['product_id','Produto','product'], ['descricao','Descrição','text'], ['quantity','Quantidade','number'],
        ['unit_price','Preço unitário','number'], ['desconto','Desconto','number'], ['tax_rate','IVA %','number']
    ],
    payment: [
        ['purchase_payment_id','ID do pagamento','number'], ['purchase_invoice_id','ID da factura','number'],
        ['valor','Valor alocado','number']
    ]
};

function options(items, label) {
    return '<option value="">— Seleccionar —</option>' + items.map(item =>
        '<option value="' + item.id + '">' + escapeHtml((item.codigo ? item.codigo + ' - ' : '') + (item.nome || item.id)) + '</option>'
    ).join('');
}

function escapeHtml(value) {
    const node = document.createElement('div');
    node.textContent = String(value ?? '');
    return node.innerHTML;
}

function renderPurchaseFields() {
    const type = document.getElementById('purchaseType').value;
    const definitions = (purchaseMode === 'document' ? documentFields : itemFields)[type] || [];
    document.getElementById('purchaseNumber').closest('.adm-form-group').style.display = purchaseMode === 'document' ? '' : 'none';
    document.getElementById('purchaseDynamicFields').innerHTML = definitions.map((field, index) => {
        const [name,label,inputType,values] = field;
        let input;
        if (inputType === 'select') {
            input = '<select class="adm-select purchase-field" data-name="' + name + '">' +
                values.split('|').map(v => '<option value="' + v + '">' + v + '</option>').join('') + '</select>';
        } else if (inputType === 'product') {
            input = '<select class="adm-select purchase-field" data-name="' + name + '">' + options(PURCHASE_PRODUCTS,'Produto') + '</select>';
        } else if (inputType === 'warehouse') {
            input = '<select class="adm-select purchase-field" data-name="' + name + '">' + options(PURCHASE_WAREHOUSES,'Armazém') + '</select>';
        } else {
            input = '<input class="adm-input purchase-field" data-name="' + name + '" type="' + inputType +
                '" ' + (inputType === 'number' ? 'step="0.01"' : '') + '>';
        }
        return (index % 2 === 0 ? '<div class="adm-form-row">' : '') +
            '<div class="adm-form-group"><label class="adm-label">' + label + '</label>' + input + '</div>' +
            (index % 2 === 1 || index === definitions.length - 1 ? '</div>' : '');
    }).join('');
}

function openPurchaseModal(mode) {
    purchaseMode = mode;
    document.getElementById('purchaseModalTitle').textContent = mode === 'document' ? 'Novo documento' : 'Adicionar item';
    document.getElementById('purchaseNumber').value = '';
    renderPurchaseFields();
    document.getElementById('purchaseModal').classList.add('open');
}

function closePurchaseModal() {
    document.getElementById('purchaseModal').classList.remove('open');
}

async function savePurchase() {
    const type = document.getElementById('purchaseType').value;
    const payload = {type, csrf: PURCHASE_CSRF};
    if (purchaseMode === 'document') payload.numero = document.getElementById('purchaseNumber').value.trim();
    document.querySelectorAll('.purchase-field').forEach(input => {
        if (input.value === '') return;
        payload[input.dataset.name] = input.type === 'number' ? Number(input.value) : input.value;
    });
    const endpoint = purchaseMode === 'document'
        ? '/nexora/api/compra_documento_save'
        : '/nexora/api/compra_item_save';
    try {
        const response = await fetch(endpoint, {
            method: 'POST',
            headers: {'Content-Type':'application/json'},
            body: JSON.stringify(payload)
        });
        const result = await response.json();
        if (!result.ok) throw new Error(result.erro || 'Erro ao guardar.');
        showToast(result.msg || 'Guardado com sucesso.');
        setTimeout(() => location.reload(), 600);
    } catch (error) {
        showToast(error.message || 'Erro de ligação.', 'error');
    }
}

function switchPurchaseTab(type, button) {
    document.querySelectorAll('#purchaseTabs .adm-tab').forEach(item => item.classList.remove('active'));
    document.querySelectorAll('[id^="purchase-"]').forEach(item => item.classList.remove('active'));
    button.classList.add('active');
    document.getElementById('purchase-' + type).classList.add('active');
    document.getElementById('purchaseType').value = type;
    location.hash = type;
}

document.addEventListener('DOMContentLoaded', () => {
    const type = location.hash.substring(1);
    const keys = <?php echo json_encode(array_keys($types)) ?>;
    if (keys.includes(type)) {
        const button = document.querySelectorAll('#purchaseTabs .adm-tab')[keys.indexOf(type)];
        switchPurchaseTab(type, button);
    }
    renderPurchaseFields();
});
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
