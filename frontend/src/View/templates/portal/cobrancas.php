<?php
declare(strict_types=1);

$pageTitle  = 'Propinas & Pagamentos';
$activePage = 'cobrancas';

$cobrancas  = $portalData['cobrancas']['body'] ?? [];
$alunoInfo  = $portalData['me']['body'] ?? [];

$filtroStatus = $_GET['status'] ?? '';

$statusLabels = [
    ''         => 'Todas',
    'emitida'  => 'Pendentes',
    'vencida'  => 'Vencidas',
    'pago'     => 'Pagas',
    'cancelada'=> 'Canceladas',
];

$totalPendente = 0;
$totalVencido  = 0;
foreach ($cobrancas as $c) {
    $v = (float)($c['valor'] ?? 0);
    if (($c['status'] ?? '') === 'emitida') $totalPendente += $v;
    if (($c['status'] ?? '') === 'vencida')  $totalVencido  += $v;
}

include dirname(__FILE__) . '/layout_top.php';
?>

<!-- Stats -->
<div class="portal-stats" style="margin-bottom:1rem">
    <div class="portal-stat">
        <span class="portal-stat-label">Pendente</span>
        <span class="portal-stat-value" style="font-size:1.2rem"><?= number_format($totalPendente, 2, ',', '.') ?> MT</span>
    </div>
    <div class="portal-stat">
        <span class="portal-stat-label">Vencido</span>
        <span class="portal-stat-value" style="font-size:1.2rem;color:#B91C1C"><?= number_format($totalVencido, 2, ',', '.') ?> MT</span>
    </div>
    <div class="portal-stat">
        <span class="portal-stat-label">Total cobranças</span>
        <span class="portal-stat-value"><?= count($cobrancas) ?></span>
    </div>
</div>

<!-- Filtro de estado -->
<div style="display:flex;gap:.4rem;flex-wrap:wrap;margin-bottom:.75rem">
    <?php foreach ($statusLabels as $val => $label): ?>
    <a href="/portal/aluno/cobrancas<?= $val ? "?status=$val" : '' ?>"
       style="padding:.35rem .85rem;border-radius:20px;font-size:.8rem;font-weight:600;text-decoration:none;
              background:<?= $filtroStatus === $val ? '#0EA5E9' : '#fff' ?>;
              color:<?= $filtroStatus === $val ? '#fff' : '#334155' ?>;
              border:1.5px solid <?= $filtroStatus === $val ? '#0EA5E9' : '#CBD5E1' ?>">
        <?= $label ?>
    </a>
    <?php endforeach; ?>
</div>

<div class="portal-card">
    <?php if (empty($cobrancas)): ?>
    <div class="portal-empty">
        <i class="fa-solid fa-check-circle"></i>
        <p>Nenhuma cobrança encontrada.</p>
    </div>
    <?php else: ?>
    <table class="portal-table">
        <thead>
            <tr>
                <th>Descrição</th>
                <th>Valor</th>
                <th>Vencimento</th>
                <th>Estado</th>
                <th>Pago em</th>
                <th></th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($cobrancas as $c): ?>
        <?php
            $status = $c['status'] ?? 'emitida';
            $badgeClass = match($status) {
                'pago'      => 'badge-green',
                'vencida'   => 'badge-red',
                'emitida'   => 'badge-yellow',
                'cancelada' => 'badge-gray',
                default     => 'badge-gray',
            };
            $statusLabel = match($status) {
                'pago'      => 'Pago',
                'vencida'   => 'Vencida',
                'emitida'   => 'Pendente',
                'cancelada' => 'Cancelada',
                default     => ucfirst($status),
            };
        ?>
        <tr>
            <td>
                <div style="font-weight:600;font-size:.875rem"><?= htmlspecialchars($c['descricao'] ?? 'Propina') ?></div>
                <?php if (!empty($c['numero'])): ?>
                <div style="font-size:.73rem;color:#94A3B8"><?= htmlspecialchars($c['numero']) ?></div>
                <?php endif; ?>
            </td>
            <td style="font-weight:700;font-size:.95rem">
                <?= number_format((float)($c['valor'] ?? 0), 2, ',', '.') ?> MT
                <?php if (!empty($c['desconto']) && (float)$c['desconto'] > 0): ?>
                <div style="font-size:.73rem;color:#22C55E">-<?= number_format((float)$c['desconto'], 2, ',', '.') ?> MT desconto</div>
                <?php endif; ?>
            </td>
            <td><?= !empty($c['due_date']) ? date('d/m/Y', strtotime($c['due_date'])) : '—' ?></td>
            <td><span class="portal-badge <?= $badgeClass ?>"><?= $statusLabel ?></span></td>
            <td style="font-size:.82rem;color:#64748B">
                <?= !empty($c['paid_at']) ? date('d/m/Y', strtotime($c['paid_at'])) : '—' ?>
            </td>
            <td style="white-space:nowrap">
                <?php if (!empty($c['id']) && in_array($c['status'] ?? '', ['pago','parcial'], true) && !empty($c['paid_at'])): ?>
                <a href="/portal/aluno/cobrancas/<?= (int)$c['id'] ?>/recibo"
                   target="_blank"
                   style="display:inline-flex;align-items:center;gap:.3rem;font-size:.78rem;color:#0369A1;text-decoration:none;font-weight:600">
                    <i class="fa-solid fa-receipt"></i> Recibo
                </a>
                <?php elseif (!empty($c['id']) && in_array($c['status'] ?? '', ['emitida','parcial'], true)): ?>
                <button onclick="abrirModalPagar(<?= (int)$c['id'] ?>, '<?= htmlspecialchars(addslashes($c['descricao'] ?? 'Propina'), ENT_QUOTES) ?>', <?= number_format((float)($c['saldo'] ?? max(0, ($c['valor_total'] ?? $c['valor'] ?? 0) - ($c['valor_pago'] ?? 0))), 2, '.', '') ?>)"
                        style="display:inline-flex;align-items:center;gap:.3rem;font-size:.78rem;
                               background:#15803D;color:#fff;border:none;border-radius:6px;
                               padding:.3rem .65rem;cursor:pointer;font-weight:600;font-family:inherit">
                    <i class="fa-brands fa-mobile-screen-button"></i> Pagar
                </button>
                <?php endif; ?>
            </td>
        </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
    <?php endif; ?>
</div>

<!-- Modal: Pagar via M-Pesa/eMola/mKesh ─────────────────────────────────── -->
<div id="modalPagar" style="display:none;position:fixed;inset:0;background:rgba(0,0,0,.45);
    z-index:9999;align-items:center;justify-content:center">
    <div style="background:#fff;border-radius:14px;padding:1.75rem;max-width:420px;width:90%;box-shadow:0 8px 32px rgba(0,0,0,.2)">
        <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:1rem">
            <h3 style="font-size:1rem;font-weight:700;color:#0C4A6E;margin:0">Pagamento Mobile Money</h3>
            <button onclick="fecharModal()" style="border:none;background:none;cursor:pointer;font-size:1.2rem;color:#94A3B8">&times;</button>
        </div>

        <p id="payDesc" style="font-size:.875rem;color:#64748B;margin-bottom:1rem"></p>

        <div style="margin-bottom:.85rem">
            <label style="display:block;font-size:.8rem;font-weight:600;color:#334155;margin-bottom:.3rem">Operador</label>
            <div style="display:flex;gap:.5rem">
                <?php foreach (['mpesa' => 'M-Pesa', 'emola' => 'eMola', 'mkesh' => 'mKesh'] as $prov => $label): ?>
                <label style="flex:1;text-align:center">
                    <input type="radio" name="payProvider" value="<?= $prov ?>" <?= $prov === 'mpesa' ? 'checked' : '' ?> style="display:none">
                    <span id="lbl_<?= $prov ?>"
                          onclick="selectProvider('<?= $prov ?>')"
                          style="display:block;padding:.5rem;border-radius:8px;border:1.5px solid #CBD5E1;
                                 font-size:.82rem;font-weight:600;cursor:pointer;color:#334155;
                                 transition:all .12s"><?= $label ?></span>
                </label>
                <?php endforeach; ?>
            </div>
        </div>

        <div style="margin-bottom:1rem">
            <label style="display:block;font-size:.8rem;font-weight:600;color:#334155;margin-bottom:.3rem">
                Número de telemóvel
            </label>
            <input type="tel" id="payMSISDN" placeholder="258841234567"
                   style="width:100%;padding:.65rem .85rem;border:1.5px solid #CBD5E1;border-radius:8px;
                          font-size:.9rem;font-family:inherit;outline:none">
            <p style="font-size:.73rem;color:#94A3B8;margin-top:.3rem">Formato: 258 + número (ex: 258841234567)</p>
        </div>

        <div id="payStatus" style="margin-bottom:.75rem"></div>

        <button id="btnPagar" onclick="iniciarPagamento()"
                style="width:100%;padding:.75rem;border-radius:10px;border:none;cursor:pointer;
                       background:linear-gradient(135deg,#15803D,#4ADE80);color:#fff;
                       font-size:.95rem;font-weight:700;font-family:inherit">
            <i class="fa-solid fa-mobile-screen-button"></i> Confirmar pagamento
        </button>
        <p style="font-size:.73rem;color:#94A3B8;margin-top:.6rem;text-align:center">
            Receberá um pedido de confirmação no seu telemóvel.
        </p>
    </div>
</div>

<script>
let _payFeeId = null;
let _pollInterval = null;
let _gatewayTxnId = null;
let _selectedProvider = 'mpesa';

function selectProvider(p) {
    _selectedProvider = p;
    ['mpesa','emola','mkesh'].forEach(x => {
        const el = document.getElementById('lbl_' + x);
        if (el) el.style.cssText = el.style.cssText.replace(/border:[^;]+;/, '')
            + (x === p ? 'border:1.5px solid #15803D;color:#15803D;background:#F0FDF4;'
                       : 'border:1.5px solid #CBD5E1;color:#334155;background:#fff;');
    });
}

function abrirModalPagar(feeId, descricao, saldo) {
    _payFeeId = feeId;
    _gatewayTxnId = null;
    document.getElementById('payDesc').textContent = descricao + ' — ' + saldo.toFixed(2).replace('.', ',') + ' MT';
    document.getElementById('payMSISDN').value = '';
    document.getElementById('payStatus').innerHTML = '';
    document.getElementById('btnPagar').disabled = false;
    document.getElementById('btnPagar').innerHTML = '<i class="fa-solid fa-mobile-screen-button"></i> Confirmar pagamento';
    selectProvider('mpesa');
    document.getElementById('modalPagar').style.display = 'flex';
}
function fecharModal() {
    clearInterval(_pollInterval);
    document.getElementById('modalPagar').style.display = 'none';
}

function payMsg(tipo, texto) {
    const bg  = tipo === 'ok' ? '#DCFCE7' : tipo === 'err' ? '#FEE2E2' : '#EFF6FF';
    const cor = tipo === 'ok' ? '#15803D' : tipo === 'err' ? '#B91C1C' : '#1D4ED8';
    document.getElementById('payStatus').innerHTML =
        `<div style="background:${bg};color:${cor};padding:.5rem .75rem;border-radius:7px;font-size:.82rem">${texto}</div>`;
}

async function iniciarPagamento() {
    const msisdn = document.getElementById('payMSISDN').value.trim().replace(/\s+/g,'');
    if (!/^258[27]\d{7}$/.test(msisdn)) {
        payMsg('err', 'Número inválido. Use o formato 258XXXXXXXXX (ex: 258841234567)');
        return;
    }
    const btn = document.getElementById('btnPagar');
    btn.disabled = true;
    btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> A enviar pedido...';
    payMsg('info', 'A processar. Por favor aguarde...');

    const resp = await fetch(`/nexora/api/proxy?path=/api/portal/aluno/me/cobrancas/${_payFeeId}/pagar`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ msisdn, provider: _selectedProvider }),
    });
    const data = await resp.json().catch(() => ({}));

    if (!resp.ok || data.error) {
        payMsg('err', data.error || data.message || data.erro || 'Erro ao iniciar pagamento.');
        btn.disabled = false;
        btn.innerHTML = '<i class="fa-solid fa-mobile-screen-button"></i> Tentar novamente';
        return;
    }

    _gatewayTxnId = data.gateway_txn_id;
    btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Aguardar confirmação no telemóvel...';
    payMsg('info', `✅ Pedido enviado! Confirme o pagamento no seu telemóvel (${msisdn}).`);

    // Polling a cada 8 segundos, máximo 15 tentativas (~2 minutos)
    let tentativas = 0;
    _pollInterval = setInterval(async () => {
        tentativas++;
        if (tentativas > 15) {
            clearInterval(_pollInterval);
            payMsg('err', 'Tempo esgotado. Verifique o estado do pagamento mais tarde.');
            btn.disabled = false;
            btn.innerHTML = '<i class="fa-solid fa-rotate-right"></i> Verificar novamente';
            return;
        }

        const sr = await fetch(`/nexora/api/proxy?path=/api/portal/aluno/me/cobrancas/${_payFeeId}/pagamento/${_gatewayTxnId}`);
        const sd = await sr.json().catch(() => ({}));

        if (sd.completed) {
            clearInterval(_pollInterval);
            payMsg('ok', '🎉 Pagamento confirmado com sucesso!');
            btn.innerHTML = '<i class="fa-solid fa-check-circle"></i> Pago!';
            setTimeout(() => { fecharModal(); location.reload(); }, 2000);
        } else if (sd.cancelled) {
            clearInterval(_pollInterval);
            payMsg('err', '❌ Pagamento cancelado ou expirado. Tente novamente.');
            btn.disabled = false;
            btn.innerHTML = '<i class="fa-solid fa-mobile-screen-button"></i> Tentar novamente';
        }
        // else: ainda processing — continuar a polling
    }, 8000);
}
</script>

<?php include dirname(__FILE__) . '/layout_bottom.php'; ?>
