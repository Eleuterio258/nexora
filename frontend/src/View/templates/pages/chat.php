<?php

$csrf      = $app->security->csrfToken();
$wsToken   = $_SESSION['nexora_access_token'] ?? '';
$wsUrl     = 'ws://localhost:8080/ws/chat';

$pageTitle  = 'Chat';
$activePage = 'chat';
$breadcrumb = [['Admin', '/nexora/'], ['Chat', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title"><i class="fa-solid fa-comments" style="color:var(--adm-green)"></i> Chat Interno</h1>
    <div class="adm-page-header-actions">
        <span id="wsStatus" class="adm-badge adm-badge--gray" style="gap:.4rem">
            <span id="wsDot" style="width:8px;height:8px;border-radius:50%;background:var(--adm-gray-400);display:inline-block"></span>
            A ligar…
        </span>
        <button class="adm-btn adm-btn-primary" onclick="abrirNovaConversa()">
            <i class="fa-solid fa-plus"></i> Nova Conversa
        </button>
    </div>
</div>

<div style="display:grid;grid-template-columns:300px 1fr;gap:0;height:calc(100vh - 170px);background:var(--adm-white);border:1px solid var(--adm-gray-200);border-radius:var(--adm-radius-lg);overflow:hidden">

    <!-- Lista de conversas -->
    <div style="border-right:1px solid var(--adm-gray-200);display:flex;flex-direction:column">
        <div style="padding:var(--adm-sp-3) var(--adm-sp-4);border-bottom:1px solid var(--adm-gray-100)">
            <input class="adm-input" type="search" id="searchConversas"
                placeholder="Pesquisar…" oninput="filtrarConversas(this.value)">
        </div>
        <div id="listaConversas" style="flex:1;overflow-y:auto">
            <div class="adm-empty" style="padding:var(--adm-sp-8)">
                <i class="fa-solid fa-spinner fa-spin" style="font-size:1.5rem;opacity:.3"></i>
                <p class="adm-empty-title" style="margin-top:var(--adm-sp-3)">A carregar…</p>
            </div>
        </div>
    </div>

    <!-- Área de chat — min-height:0 impede overflow em grid/flex -->
    <div style="display:flex;flex-direction:column;min-height:0;overflow:hidden">
        <!-- Ecrã vazio -->
        <div id="chatVazio" style="flex:1;display:flex;align-items:center;justify-content:center;flex-direction:column;gap:var(--adm-sp-4);color:var(--adm-gray-400)">
            <i class="fa-solid fa-comments" style="font-size:3rem;opacity:.15"></i>
            <p style="font-size:var(--adm-text-sm)">Selecione uma conversa ou inicie uma nova</p>
        </div>

        <!-- Chat aberto — flex:1 + min-height:0 para não ultrapassar o pai -->
        <div id="chatAberto" style="display:none;flex-direction:column;flex:1;min-height:0">
            <!-- Cabeçalho — altura fixa -->
            <div style="flex-shrink:0;padding:var(--adm-sp-3) var(--adm-sp-5);border-bottom:1px solid var(--adm-gray-100);display:flex;align-items:center;gap:var(--adm-sp-3)">
                <div id="chatAvatar" style="width:36px;height:36px;border-radius:50%;background:var(--adm-green-xlight);display:flex;align-items:center;justify-content:center;color:var(--adm-green-dark);font-weight:700;flex-shrink:0">?</div>
                <div style="flex:1">
                    <div class="adm-fw-600" id="chatNome">—</div>
                    <div class="adm-text-xs adm-text-muted" id="chatTyping" style="min-height:1em"></div>
                </div>
                <div id="onlineIndicator" style="display:flex;align-items:center;gap:.3rem;font-size:.7rem;color:var(--adm-gray-400)"></div>
            </div>

            <!-- Mensagens — cresce e faz scroll, nunca empurra o input -->
            <div id="listaMensagens" style="flex:1;min-height:0;overflow-y:auto;padding:var(--adm-sp-5);display:flex;flex-direction:column;gap:var(--adm-sp-3)"></div>

            <!-- Input — altura fixa, sempre visível -->
            <div style="flex-shrink:0;padding:var(--adm-sp-3) var(--adm-sp-4);border-top:1px solid var(--adm-gray-100);display:flex;gap:var(--adm-sp-3);align-items:flex-end;background:var(--adm-white)">
                <textarea id="inputMensagem" class="adm-textarea" rows="2"
                    style="flex:1;resize:none;min-height:unset;max-height:120px;padding:var(--adm-sp-2) var(--adm-sp-3)"
                    placeholder="Escreva uma mensagem… (Enter para enviar)"
                    oninput="onTyping()"
                    onkeydown="if(event.key==='Enter'&&!event.shiftKey){event.preventDefault();enviarMensagem()}"></textarea>
                <button class="adm-btn adm-btn-primary" style="flex-shrink:0" onclick="enviarMensagem()">
                    <i class="fa-solid fa-paper-plane"></i>
                </button>
            </div>
        </div>
    </div>
</div>

<!-- Modal nova conversa -->
<div class="adm-modal-overlay" id="modalNovaConversa">
    <div class="adm-modal" style="max-width:460px">
        <p class="adm-modal-title">Nova Conversa</p>
        <div class="adm-form-group">
            <label class="adm-label">Tipo</label>
            <select class="adm-select" id="novoTipo" onchange="this.value==='grupo'?document.getElementById('wrapNome').style.display='':document.getElementById('wrapNome').style.display='none'">
                <option value="individual">Individual</option>
                <option value="grupo">Grupo</option>
            </select>
        </div>
        <div class="adm-form-group" id="wrapNome" style="display:none">
            <label class="adm-label">Nome do grupo</label>
            <input class="adm-input" type="text" id="nomeGrupo" placeholder="Ex: Equipa TI">
        </div>
        <div class="adm-form-group">
            <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:var(--adm-sp-2)">
                <label class="adm-label" style="margin:0">Participantes <span id="selCount" class="adm-badge adm-badge--gray" style="font-size:.65rem"></span></label>
                <button type="button" class="adm-btn adm-btn-ghost adm-btn-sm" onclick="toggleSelectAll()" id="btnSelAll">Seleccionar todos</button>
            </div>
            <div id="listaUtilizadores" style="max-height:220px;overflow-y:auto;border:1px solid var(--adm-gray-200);border-radius:var(--adm-radius-sm);padding:var(--adm-sp-1)">
                <p class="adm-text-xs adm-text-muted" style="padding:var(--adm-sp-2)">A carregar…</p>
            </div>
        </div>
        <div class="adm-modal-footer">
            <button class="adm-btn adm-btn-outline" onclick="fecharNovaConversa()">Cancelar</button>
            <button class="adm-btn adm-btn-primary" onclick="criarConversa()">
                <i class="fa-solid fa-plus"></i> Criar
            </button>
        </div>
    </div>
</div>

<style>
.conversa-item{display:flex;align-items:center;gap:var(--adm-sp-3);padding:var(--adm-sp-3) var(--adm-sp-4);cursor:pointer;border-bottom:1px solid var(--adm-gray-100);transition:background .1s}
.conversa-item:hover{background:var(--adm-gray-50)}
.conversa-item.ativa{background:var(--adm-green-xlight)}
.cv-avatar{width:38px;height:38px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:.85rem;flex-shrink:0}
.cv-avatar.ind{background:var(--adm-blue-light);color:var(--adm-blue)}
.cv-avatar.grp{background:#ede9fe;color:#7c3aed}
.msg-bubble{max-width:70%;padding:var(--adm-sp-2) var(--adm-sp-4);border-radius:var(--adm-radius-lg);font-size:var(--adm-text-sm);line-height:1.5;word-break:break-word}
.msg-minha{background:var(--adm-green);color:#fff;align-self:flex-end;border-bottom-right-radius:4px}
.msg-outra{background:var(--adm-gray-100);color:var(--adm-gray-800);align-self:flex-start;border-bottom-left-radius:4px}
.msg-wrap{display:flex;flex-direction:column;gap:2px}
.msg-meta{font-size:.65rem;color:var(--adm-gray-400);padding:0 var(--adm-sp-2)}
.msg-meta.minha{text-align:right}
.online-dot{width:8px;height:8px;border-radius:50%;background:var(--adm-green);display:inline-block}
.offline-dot{width:8px;height:8px;border-radius:50%;background:var(--adm-gray-300);display:inline-block}
</style>

<script>
// ── Config ─────────────────────────────────────────────────────────────────
const CSRF      = <?= json_encode($csrf) ?>;
const WS_URL    = <?= json_encode($wsUrl) ?>;
const WS_TOKEN  = <?= json_encode($wsToken) ?>;
const ME_ID     = <?= json_encode($app->session->user()['id'] ?? 0) ?>;

// ── Estado ─────────────────────────────────────────────────────────────────
let socket       = null;
let conversaAtualID = null;
let conversas    = [];
let mensagens    = {};        // cache local por conversa_id
let onlineUsers  = new Set();
let typingTimers = {};

// ── WebSocket ──────────────────────────────────────────────────────────────
function conectarWS() {
    const url = WS_URL + '?token=' + encodeURIComponent(WS_TOKEN);
    socket = new WebSocket(url);

    socket.onopen = () => {
        setStatus('online', 'Ligado');
        carregarConversas();
    };

    socket.onclose = () => {
        setStatus('offline', 'Desligado');
        setTimeout(conectarWS, 3000); // reconectar
    };

    socket.onerror = () => setStatus('offline', 'Erro de ligação');

    socket.onmessage = (e) => {
        const env = JSON.parse(e.data);
        handleEvent(env.type, env.data);
    };
}

function send(type, data) {
    if (socket && socket.readyState === WebSocket.OPEN) {
        socket.send(JSON.stringify({type, ...data}));
    }
}

// ── Eventos recebidos ──────────────────────────────────────────────────────
function handleEvent(type, data) {
    switch (type) {
        case 'joined':
            onlineUsers = new Set(data.online_users || []);
            updateOnlineIndicator();
            break;

        case 'user_online':
            onlineUsers.add(data.user_id);
            updateOnlineIndicator();
            break;

        case 'user_offline':
            onlineUsers.delete(data.user_id);
            updateOnlineIndicator();
            break;

        case 'message':
            const msg = {...data, minha: data.autor_id == ME_ID};
            if (!mensagens[data.conversa_id]) mensagens[data.conversa_id] = [];
            mensagens[data.conversa_id].push(msg);
            if (data.conversa_id === conversaAtualID) {
                appendMensagem(msg);
                scrollBottom();
            } else {
                // Incrementar badge na conversa
                incrementBadge(data.conversa_id);
            }
            break;

        case 'typing':
            if (data.conversa_id === conversaAtualID && data.user_id != ME_ID) {
                document.getElementById('chatTyping').textContent = 'a escrever…';
                clearTimeout(typingTimers[data.user_id]);
                typingTimers[data.user_id] = setTimeout(() => {
                    document.getElementById('chatTyping').textContent = '';
                }, 2000);
            }
            break;

        case 'stop_typing':
            if (data.conversa_id === conversaAtualID)
                document.getElementById('chatTyping').textContent = '';
            break;
    }
}

// ── Conversas ──────────────────────────────────────────────────────────────
async function carregarConversas() {
    const resp = await fetch('/nexora/api/self_service_chat_conversas');
    const data = await resp.json();
    conversas = data.conversas || [];
    renderConversas(conversas);
}

function renderConversas(lista) {
    const el = document.getElementById('listaConversas');
    if (!lista.length) {
        el.innerHTML = '<div class="adm-empty" style="padding:var(--adm-sp-6)"><p class="adm-empty-title">Sem conversas</p><p class="adm-text-xs adm-text-muted">Clique em "Nova Conversa" para começar.</p></div>';
        return;
    }
    el.innerHTML = lista.map(c => {
        const ini = (c.nome || '?')[0].toUpperCase();
        const cls = c.tipo === 'grupo' ? 'grp' : 'ind';
        const ult = c.ultima_mensagem ? c.ultima_mensagem.substring(0,38) + (c.ultima_mensagem.length > 38 ? '…' : '') : '<em>Sem mensagens</em>';
        const badge = (c.nao_lidas > 0)
            ? `<span class="adm-nav-badge" id="badge-${c.id}">${c.nao_lidas}</span>`
            : `<span id="badge-${c.id}" style="display:none" class="adm-nav-badge"></span>`;
        // Usar data-* para evitar problemas com aspas nos nomes
        return `<div class="conversa-item${conversaAtualID===c.id?' ativa':''}"
                     id="conv-${c.id}"
                     data-id="${c.id}"
                     data-nome="${esc(c.nome||'Conversa')}"
                     data-tipo="${esc(c.tipo)}">
            <div class="cv-avatar ${cls}">${ini}</div>
            <div style="flex:1;min-width:0">
                <div class="adm-fw-600 adm-truncate">${esc(c.nome||'Conversa')}</div>
                <div class="adm-text-xs adm-text-muted adm-truncate">${ult}</div>
            </div>
            ${badge}
        </div>`;
    }).join('');

    // Delegação de eventos — click em qualquer .conversa-item
    el.querySelectorAll('.conversa-item').forEach(div => {
        div.addEventListener('click', () => {
            abrirConversa(
                parseInt(div.dataset.id),
                div.dataset.nome,
                div.dataset.tipo
            );
        });
    });
}

function filtrarConversas(q) {
    const fil = conversas.filter(c => (c.nome||'').toLowerCase().includes(q.toLowerCase()));
    renderConversas(fil);
}

function incrementBadge(convID) {
    const el = document.getElementById('badge-' + convID);
    if (!el) return;
    const n = (parseInt(el.textContent) || 0) + 1;
    el.textContent = n;
    el.style.display = '';
}

// ── Abrir conversa ─────────────────────────────────────────────────────────
async function abrirConversa(id, nome, tipo) {
    // Sair da sala anterior
    if (conversaAtualID && conversaAtualID !== id) {
        send('leave', {conversa_id: conversaAtualID});
    }

    conversaAtualID = id;
    document.getElementById('chatVazio').style.display = 'none';
    const ca = document.getElementById('chatAberto');
    ca.style.display = 'flex';
    document.getElementById('chatNome').textContent = nome;
    document.getElementById('chatAvatar').textContent = nome[0].toUpperCase();
    document.getElementById('chatTyping').textContent = '';

    // Marcar conversa activa
    document.querySelectorAll('.conversa-item').forEach(el => el.classList.remove('ativa'));
    document.getElementById('conv-' + id)?.classList.add('ativa');

    // Limpar badge
    const badge = document.getElementById('badge-' + id);
    if (badge) badge.style.display = 'none';

    // Entrar na sala WS
    send('join', {conversa_id: id});

    // Carregar mensagens do servidor (histórico)
    await carregarMensagens(id);
    updateOnlineIndicator();
}

async function carregarMensagens(id) {
    const resp = await fetch(`/nexora/api/self_service_chat_mensagens?conversa_id=${id}`);
    const data = await resp.json();
    const msgs = (data.mensagens || []).map(m => ({...m, minha: m.autor_id == ME_ID}));
    mensagens[id] = msgs;
    const el = document.getElementById('listaMensagens');
    el.innerHTML = '';
    if (!msgs.length) {
        el.innerHTML = '<div style="text-align:center;color:var(--adm-gray-400);padding:var(--adm-sp-8);font-size:var(--adm-text-sm)">Sem mensagens ainda. Seja o primeiro a escrever!</div>';
        return;
    }
    msgs.forEach(m => appendMensagem(m));
    scrollBottom();
}

function appendMensagem(m) {
    const el = document.getElementById('listaMensagens');
    const hora = m.created_at ? new Date(m.created_at).toLocaleTimeString('pt-PT', {hour:'2-digit', minute:'2-digit'}) : '';
    const wrap = document.createElement('div');
    wrap.className = 'msg-wrap';
    wrap.innerHTML = (!m.minha && m.autor_nome ? `<span class="msg-meta">${esc(m.autor_nome)}</span>` : '') +
        `<div class="msg-bubble ${m.minha?'msg-minha':'msg-outra'}">${esc(m.conteudo)}</div>` +
        `<span class="msg-meta${m.minha?' minha':''}">${hora}</span>`;
    el.appendChild(wrap);
}

function scrollBottom() {
    const el = document.getElementById('listaMensagens');
    el.scrollTop = el.scrollHeight;
}

// ── Enviar mensagem ────────────────────────────────────────────────────────
function enviarMensagem() {
    if (!conversaAtualID) return;
    const input = document.getElementById('inputMensagem');
    const txt   = input.value.trim();
    if (!txt) return;
    input.value = '';
    // Enviar via WebSocket
    send('message', {conversa_id: conversaAtualID, conteudo: txt});
    send('stop_typing', {conversa_id: conversaAtualID});
}

// ── Typing indicator ───────────────────────────────────────────────────────
let typingDebounce = null;
function onTyping() {
    if (!conversaAtualID) return;
    send('typing', {conversa_id: conversaAtualID});
    clearTimeout(typingDebounce);
    typingDebounce = setTimeout(() => send('stop_typing', {conversa_id: conversaAtualID}), 1500);
}

// ── Online indicator ───────────────────────────────────────────────────────
function updateOnlineIndicator() {
    const el = document.getElementById('onlineIndicator');
    if (!el) return;
    const n = onlineUsers.size;
    el.innerHTML = n > 0
        ? `<span class="online-dot"></span> ${n} online`
        : `<span class="offline-dot"></span> 0 online`;
}

// ── Status WS ──────────────────────────────────────────────────────────────
function setStatus(state, label) {
    const el  = document.getElementById('wsStatus');
    const dot = document.getElementById('wsDot');
    if (!el || !dot) return;
    const colors = {online:'var(--adm-green)', offline:'var(--adm-gray-400)', error:'var(--adm-red)'};
    dot.style.background = colors[state] || colors.offline;
    el.className = 'adm-badge ' + (state === 'online' ? 'adm-badge--green' : 'adm-badge--gray');
    el.innerHTML = `<span style="width:8px;height:8px;border-radius:50%;background:${colors[state]||colors.offline};display:inline-block"></span> ${label}`;
}

// ── Nova conversa ──────────────────────────────────────────────────────────
async function abrirNovaConversa() {
    document.getElementById('modalNovaConversa').classList.add('open');
    document.getElementById('selCount').textContent = '';
    const resp = await fetch('/nexora/api/self_service_utilizadores');
    const data = await resp.json();
    const lista = data.utilizadores || [];
    const el = document.getElementById('listaUtilizadores');
    el.innerHTML = lista.length
        ? lista.map(u => `
          <label class="part-item" style="display:flex;align-items:center;gap:var(--adm-sp-3);padding:var(--adm-sp-2) var(--adm-sp-3);border-radius:var(--adm-radius-sm);cursor:pointer;transition:background .1s">
            <input type="checkbox" class="part-cb" value="${u.id}" style="accent-color:var(--adm-green);width:16px;height:16px;cursor:pointer;flex-shrink:0">
            <div style="flex:1;min-width:0">
                <div class="adm-fw-600 adm-truncate">${esc(u.nome)}</div>
                <div class="adm-text-xs adm-text-muted adm-truncate">${esc(u.email)}</div>
            </div>
            ${onlineUsers.has(u.id) ? '<span class="online-dot" title="Online"></span>' : ''}
          </label>`).join('')
        : '<p class="adm-text-xs adm-text-muted" style="padding:var(--adm-sp-3)">Sem utilizadores disponíveis</p>';

    // Feedback visual ao seleccionar
    el.querySelectorAll('.part-cb').forEach(cb => {
        cb.addEventListener('change', () => {
            cb.closest('label').style.background = cb.checked ? 'var(--adm-green-xlight)' : '';
            updateSelCount();
        });
    });
}

function updateSelCount() {
    const n = document.querySelectorAll('#listaUtilizadores .part-cb:checked').length;
    const el = document.getElementById('selCount');
    el.textContent = n ? n + ' sel.' : '';
}

function toggleSelectAll() {
    const boxes = [...document.querySelectorAll('#listaUtilizadores .part-cb')];
    const allChecked = boxes.every(b => b.checked);
    boxes.forEach(b => {
        b.checked = !allChecked;
        b.closest('label').style.background = b.checked ? 'var(--adm-green-xlight)' : '';
    });
    document.getElementById('btnSelAll').textContent = allChecked ? 'Seleccionar todos' : 'Limpar selecção';
    updateSelCount();
}

function fecharNovaConversa() {
    document.getElementById('modalNovaConversa').classList.remove('open');
}

async function criarConversa() {
    const tipo  = document.getElementById('novoTipo').value;
    const nome  = document.getElementById('nomeGrupo').value.trim() || null;
    const parts = [...document.querySelectorAll('#listaUtilizadores .part-cb:checked')].map(c => parseInt(c.value));
    if (!parts.length) { showToast('Selecione pelo menos um participante', 'error'); return; }
    const resp = await fetch('/nexora/api/self_service_chat_criar', {
        method: 'POST',
        headers: {'Content-Type':'application/json'},
        body: JSON.stringify({tipo, nome, participantes: parts, csrf_token: CSRF})
    });
    const data = await resp.json();
    if (data.ok) {
        fecharNovaConversa();
        showToast('Conversa criada');
        await carregarConversas();
        if (data.id) abrirConversa(data.id, nome || 'Conversa', tipo);
    } else {
        showToast(data.error || 'Erro', 'error');
    }
}

// ── Utils ──────────────────────────────────────────────────────────────────
function esc(s) {
    return String(s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}

document.getElementById('modalNovaConversa').addEventListener('click', e => {
    if (e.target === e.currentTarget) fecharNovaConversa();
});

// Iniciar
conectarWS();
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
