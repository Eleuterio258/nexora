<?php
    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Assinatura Digital';
    $activePage = 'assinatura_digital';
    $breadcrumb = [['Admin', '/nexora/'], ['Assinatura Digital', '']];

    $apiDocs = $app->nexora->call('GET', '/api/assinatura-digital/documentos');
    $docs = ($apiDocs['status'] === 200 && is_array($apiDocs['body'])) ? $apiDocs['body'] : [];

    $statusLabels = [
        'rascunho'  => ['adm-badge--gray',   'Rascunho'],
        'pendente'  => ['adm-badge--yellow', 'Pendente'],
        'assinado'  => ['adm-badge--green',  'Assinado'],
        'cancelado' => ['adm-badge--red',    'Cancelado'],
        'expirado'  => ['adm-badge--orange', 'Expirado'],
    ];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Assinatura Digital</h1>
    <button class="adm-btn adm-btn-primary adm-btn-sm" type="button" onclick="openUploadModal()">
        + Novo Documento
    </button>
</div>

<div class="adm-card">
    <div class="adm-table-wrap">
        <table class="adm-table" id="docsTable">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Título</th>
                    <th>Estado</th>
                    <th>Signatários</th>
                    <th>Envio</th>
                    <th>Ações</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($docs as $d): 
                    $badge = $statusLabels[$d['status']] ?? ['adm-badge--gray', $d['status']];
                ?>
                <tr data-id="<?php echo (int)$d['id'] ?>">
                    <td><?php echo (int)$d['id'] ?></td>
                    <td><?php echo htmlspecialchars($d['titulo']) ?></td>
                    <td><span class="adm-badge <?php echo $badge[0] ?>"><?php echo $badge[1] ?></span></td>
                    <td><?php echo (int)$d['assinados'] ?> / <?php echo (int)$d['total_signatarios'] ?></td>
                    <td class="adm-text-muted"><?php echo $d['data_envio'] ? date('d/m/Y H:i', strtotime($d['data_envio'])) : '—' ?></td>
                    <td style="white-space:nowrap">
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" onclick="verDocumento(<?php echo (int)$d['id'] ?>, '<?php echo htmlspecialchars($d['titulo'], ENT_QUOTES) ?>')">Gerir</button>
                        <?php if ($d['status'] === 'rascunho'): ?>
                        <button class="adm-btn adm-btn-primary adm-btn-sm" type="button" onclick="enviarDocumentoInline(<?php echo (int)$d['id'] ?>)">Enviar</button>
                        <?php elseif ($d['status'] === 'pendente'): ?>
                        <button class="adm-btn adm-btn-outline adm-btn-sm" type="button" onclick="cancelarDocumentoInline(<?php echo (int)$d['id'] ?>)">Cancelar</button>
                        <?php endif; ?>
                    </td>
                </tr>
                <?php endforeach; ?>
                <?php if (empty($docs)): ?>
                <tr><td colspan="6" class="adm-text-center adm-text-muted">Nenhum documento encontrado.</td></tr>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<!-- Upload Modal -->
<div class="adm-modal" id="uploadModal" style="display:none">
    <div class="adm-modal-content" style="max-width:520px">
        <div class="adm-modal-header"><h3>Enviar documento para assinatura</h3><button type="button" class="adm-btn adm-btn-ghost adm-btn-icon" onclick="closeUploadModal()">&times;</button></div>
        <form id="uploadForm" style="padding:var(--adm-sp-5) var(--adm-sp-6)" enctype="multipart/form-data">
            <input type="hidden" name="csrf" value="<?php echo htmlspecialchars($csrf) ?>">
            <div class="adm-form-group">
                <label class="adm-label">Título</label>
                <input class="adm-input" type="text" name="titulo" id="up-titulo" required>
            </div>
            <div class="adm-form-group">
                <label class="adm-label">Descrição</label>
                <textarea class="adm-input" name="descricao" id="up-descricao" rows="2"></textarea>
            </div>
            <div class="adm-form-group">
                <label class="adm-label">PDF</label>
                <input class="adm-input" type="file" name="ficheiro" id="up-ficheiro" accept="application/pdf" required>
            </div>
            <div style="display:flex;justify-content:flex-end;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-outline" type="button" onclick="closeUploadModal()">Cancelar</button>
                <button class="adm-btn adm-btn-primary" type="submit">Guardar</button>
            </div>
        </form>
    </div>
</div>

<!-- Documento Modal -->
<div class="adm-modal" id="docModal" style="display:none">
    <div class="adm-modal-content" style="max-width:760px">
        <div class="adm-modal-header"><h3 id="docModalTitle">Documento</h3><button type="button" class="adm-btn adm-btn-ghost adm-btn-icon" onclick="closeDocModal()">&times;</button></div>
        <div style="padding:var(--adm-sp-5) var(--adm-sp-6);max-height:72vh;overflow-y:auto">
            <div id="docModalBody"></div>
            <div id="pdfPreview" style="margin-top:var(--adm-sp-4)">
                <h4 style="margin-bottom:var(--adm-sp-3)">Pré-visualização</h4>
                <iframe id="pdfPreviewFrame" src="" width="100%" height="400" style="border:1px solid var(--adm-border);border-radius:8px"></iframe>
            </div>
            <div id="signatariosSection" style="margin-top:var(--adm-sp-5)">
                <h4 style="margin-bottom:var(--adm-sp-3)">Signatários</h4>
                <div id="signatariosList"></div>
                <form id="signatarioForm" style="margin-top:var(--adm-sp-4);padding:var(--adm-sp-4);background:var(--adm-gray-50);border-radius:8px">
                    <input type="hidden" name="csrf" value="<?php echo htmlspecialchars($csrf) ?>">
                    <div class="adm-form-row-2">
                        <div class="adm-form-group"><label class="adm-label">Nome *</label><input class="adm-input" type="text" name="nome" required></div>
                        <div class="adm-form-group"><label class="adm-label">Email</label><input class="adm-input" type="email" name="email"></div>
                    </div>
                    <div class="adm-form-row-3">
                        <div class="adm-form-group"><label class="adm-label">Ordem</label><input class="adm-input" type="number" name="ordem" value="1" min="1"></div>
                        <div class="adm-form-group"><label class="adm-label">Página</label><input class="adm-input" type="number" name="pagina" value="1" min="1"></div>
                        <div class="adm-form-group"><label class="adm-label">Tipo</label>
                            <select class="adm-select" name="tipo">
                                <option value="assinatura">Assinatura</option>
                                <option value="rubrica">Rubrica</option>
                                <option value="testemunha">Testemunha</option>
                            </select>
                        </div>
                    </div>
                    <div class="adm-form-row-4">
                        <div class="adm-form-group"><label class="adm-label">X (pt)</label><input class="adm-input" type="number" step="0.1" name="x" value="100"></div>
                        <div class="adm-form-group"><label class="adm-label">Y (pt)</label><input class="adm-input" type="number" step="0.1" name="y" value="100"></div>
                        <div class="adm-form-group"><label class="adm-label">Largura (pt)</label><input class="adm-input" type="number" step="0.1" name="largura" value="150"></div>
                        <div class="adm-form-group"><label class="adm-label">Altura (pt)</label><input class="adm-input" type="number" step="0.1" name="altura" value="50"></div>
                    </div>
                    <div style="display:flex;justify-content:flex-end;gap:var(--adm-sp-3);margin-top:var(--adm-sp-3)">
                        <button class="adm-btn adm-btn-primary adm-btn-sm" type="submit">Adicionar signatário</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<script>
const apiBase = '/nexora/api/';
let currentDocId = null;

function api(name, payload = {}, method = 'POST') {
    const url = apiBase + name + '.php';
    const options = { method };
    if (method === 'GET' && payload) {
        const q = new URLSearchParams(payload).toString();
        return fetch(url + '?' + q).then(r => r.json());
    }
    const body = new FormData();
    for (const [k, v] of Object.entries(payload)) body.append(k, v);
    options.body = body;
    return fetch(url, options).then(r => r.json());
}

function openUploadModal() { document.getElementById('uploadModal').style.display = 'flex'; }
function closeUploadModal() { document.getElementById('uploadModal').style.display = 'none'; }
function closeDocModal() { document.getElementById('docModal').style.display = 'none'; currentDocId = null; }

document.getElementById('uploadForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const f = document.getElementById('up-ficheiro').files[0];
    const body = new FormData();
    body.append('csrf', document.querySelector('#uploadForm input[name=csrf]').value);
    body.append('titulo', document.getElementById('up-titulo').value);
    body.append('descricao', document.getElementById('up-descricao').value);
    body.append('ficheiro', f);
    const r = await fetch(apiBase + 'assinatura_digital_documento_upload.php', { method: 'POST', body });
    const data = await r.json();
    if (data.id) { closeUploadModal(); location.reload(); }
    else { alert(data.erro || 'Erro ao enviar documento.'); }
});

async function verDocumento(id, titulo) {
    currentDocId = id;
    document.getElementById('docModalTitle').textContent = titulo;
    const data = await api('assinatura_digital_documento_obter', { id }, 'GET');
    const doc = data.documento || {};
    const sigs = data.signatarios || [];
    const statusBadge = {
        'rascunho': '<span class="adm-badge adm-badge--gray">Rascunho</span>',
        'pendente': '<span class="adm-badge adm-badge--yellow">Pendente</span>',
        'assinado': '<span class="adm-badge adm-badge--green">Assinado</span>',
        'cancelado': '<span class="adm-badge adm-badge--red">Cancelado</span>',
    }[doc.status] || doc.status;

    document.getElementById('docModalBody').innerHTML = `
        <div class="adm-form-row-3" style="margin:0">
            <div><strong>Estado</strong><div style="margin-top:4px">${statusBadge}</div></div>
            <div><strong>Envio</strong><div style="margin-top:4px" class="adm-text-muted">${doc.data_envio ? new Date(doc.data_envio).toLocaleString('pt-PT') : '—'}</div></div>
            <div><strong>Conclusão</strong><div style="margin-top:4px" class="adm-text-muted">${doc.data_conclusao ? new Date(doc.data_conclusao).toLocaleString('pt-PT') : '—'}</div></div>
        </div>
        <p style="margin-top:12px"><strong>Descrição:</strong> ${doc.descricao || '—'}</p>
        <p><strong>Hash SHA-256:</strong> <code style="font-size:12px">${doc.hash_sha256 || '—'}</code></p>
        <div style="display:flex;gap:8px;margin-top:12px">
            <button class="adm-btn adm-btn-ghost adm-btn-sm" onclick="abrirPdf(${id})">Abrir PDF</button>
            ${doc.status === 'rascunho' ? `<button class="adm-btn adm-btn-primary adm-btn-sm" onclick="enviarDocumento(${id})">Enviar para assinatura</button>` : ''}
            ${doc.status === 'pendente' ? `<button class="adm-btn adm-btn-outline adm-btn-sm" onclick="cancelarDocumento(${id})">Cancelar</button>` : ''}
        </div>
    `;
    renderSignatarios(sigs);
    document.getElementById('signatarioForm').style.display = (doc.status === 'rascunho') ? 'block' : 'none';
    document.getElementById('pdfPreviewFrame').src = '';
    document.getElementById('pdfPreviewFrame').dataset.docId = id;
    document.getElementById('docModal').style.display = 'flex';
    carregarPdfPreview(id);
}

async function carregarPdfPreview(id) {
    const iframe = document.getElementById('pdfPreviewFrame');
    iframe.src = 'about:blank';
    try {
        const data = await api('assinatura_digital_documento_download', { id }, 'GET');
        if (data.pdf) {
            const ct = data.content_type || 'application/pdf';
            iframe.src = `data:${ct};base64,${data.pdf}`;
        }
    } catch (e) {
        console.error('Erro ao carregar PDF', e);
    }
}

async function abrirPdf(id) {
    try {
        const data = await api('assinatura_digital_documento_download', { id }, 'GET');
        if (data.pdf) {
            const ct = data.content_type || 'application/pdf';
            const blob = b64toBlob(data.pdf, ct);
            const url = URL.createObjectURL(blob);
            window.open(url, '_blank');
        } else {
            alert('PDF não disponível.');
        }
    } catch (e) {
        alert('Erro ao abrir PDF.');
    }
}

function b64toBlob(b64, contentType = '', sliceSize = 512) {
    const byteCharacters = atob(b64);
    const byteArrays = [];
    for (let offset = 0; offset < byteCharacters.length; offset += sliceSize) {
        const slice = byteCharacters.slice(offset, offset + sliceSize);
        const byteNumbers = new Array(slice.length);
        for (let i = 0; i < slice.length; i++) byteNumbers[i] = slice.charCodeAt(i);
        byteArrays.push(new Uint8Array(byteNumbers));
    }
    return new Blob(byteArrays, { type: contentType });
}

function renderSignatarios(sigs) {
    const html = sigs.length ? `<table class="adm-table"><thead><tr><th>Nome</th><th>Email</th><th>Estado</th><th>Assinado em</th><th>Ações</th></tr></thead><tbody>` +
        sigs.map(s => `
            <tr>
                <td>${s.nome}</td>
                <td>${s.email || '—'}</td>
                <td><span class="adm-badge ${s.status === 'assinado' ? 'adm-badge--green' : 'adm-badge--yellow'}">${s.status}</span></td>
                <td>${s.assinado_em ? new Date(s.assinado_em).toLocaleString('pt-PT') : '—'}</td>
                <td>
                    ${s.status !== 'assinado' ? `<button class="adm-btn adm-btn-primary adm-btn-sm" onclick="assinar(${currentDocId}, ${s.id}, '${s.nome.replace(/'/g, "\\'")}')">Assinar</button>` : ''}
                    <button class="adm-btn adm-btn-ghost adm-btn-sm" onclick="removerSignatario(${currentDocId}, ${s.id})">Remover</button>
                </td>
            </tr>
        `).join('') + '</tbody></table>'
        : '<p class="adm-text-muted">Sem signatários.</p>';
    document.getElementById('signatariosList').innerHTML = html;
}

document.getElementById('signatarioForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const fd = new FormData(e.target);
    const payload = Object.fromEntries(fd.entries());
    payload.id = currentDocId;
    const data = await api('assinatura_digital_signatario_adicionar', payload);
    if (data.id) { e.target.reset(); verDocumento(currentDocId, document.getElementById('docModalTitle').textContent); }
    else { alert(data.erro || 'Erro ao adicionar signatário.'); }
});

async function enviarDocumento(id) {
    const data = await api('assinatura_digital_documento_enviar', { id });
    if (data.ok) { verDocumento(id, document.getElementById('docModalTitle').textContent); location.reload(); }
    else alert(data.erro || 'Erro ao enviar documento.');
}

async function cancelarDocumento(id) {
    const data = await api('assinatura_digital_documento_cancelar', { id });
    if (data.ok) { closeDocModal(); location.reload(); }
    else alert(data.erro || 'Erro ao cancelar documento.');
}

async function removerSignatario(docId, sigId) {
    if (!confirm('Remover signatário?')) return;
    const data = await api('assinatura_digital_signatario_remover', { id: docId, sig_id: sigId }, 'POST');
    if (data.ok !== false) verDocumento(docId, document.getElementById('docModalTitle').textContent);
    else alert(data.erro || 'Erro ao remover signatário.');
}

async function assinar(docId, sigId, nome) {
    const email = prompt('Email do signatário:', '');
    if (email === null) return;
    const data = await api('assinatura_digital_documento_assinar', { id: docId, signatario_id: sigId, nome, email });
    if (data.ok) { alert('Assinado com sucesso. Hash: ' + data.assinatura_hash); verDocumento(docId, document.getElementById('docModalTitle').textContent); location.reload(); }
    else alert(data.erro || 'Erro ao assinar.');
}

async function enviarDocumentoInline(id) {
    if (!confirm('Enviar documento para assinatura?')) return;
    const data = await api('assinatura_digital_documento_enviar', { id });
    if (data.ok) location.reload();
    else alert(data.erro || 'Erro ao enviar documento.');
}

async function cancelarDocumentoInline(id) {
    if (!confirm('Cancelar envio deste documento?')) return;
    const data = await api('assinatura_digital_documento_cancelar', { id });
    if (data.ok) location.reload();
    else alert(data.erro || 'Erro ao cancelar documento.');
}

// Abrir documento automaticamente se vier com ?doc_id=...
const urlParams = new URLSearchParams(window.location.search);
const openDocId = urlParams.get('doc_id');
if (openDocId) {
    const row = document.querySelector('#docsTable tr[data-id="' + openDocId + '"]');
    const titulo = row ? row.querySelector('td:nth-child(2)')?.textContent : 'Documento';
    verDocumento(parseInt(openDocId, 10), titulo || 'Documento');
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
