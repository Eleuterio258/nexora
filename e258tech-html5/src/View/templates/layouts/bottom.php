        </main>
    </div><!-- /adm-main -->
</div><!-- /adm-wrapper -->

<!-- Toast -->
<div class="adm-toast" id="admToast"></div>

<!-- Confirm Modal -->
<div class="adm-modal-overlay" id="confirmModal">
    <div class="adm-modal">
        <p class="adm-modal-title" id="confirmTitle">Confirmar acção</p>
        <p class="adm-modal-body"  id="confirmBody">Tem a certeza?</p>
        <div class="adm-modal-footer">
            <button class="adm-btn adm-btn-outline" onclick="closeConfirm()">Cancelar</button>
            <button class="adm-btn adm-btn-danger"  id="confirmBtn">Confirmar</button>
        </div>
    </div>
</div>

<script>
// ── Sidebar toggle (mobile) ───────────────────────────────────
(function(){
    const toggle = document.getElementById('sidebarToggle');
    const sidebar = document.getElementById('admSidebar');
    if (toggle && sidebar) {
        toggle.addEventListener('click', () => sidebar.classList.toggle('open'));
        document.addEventListener('click', e => {
            if (!sidebar.contains(e.target) && !toggle.contains(e.target))
                sidebar.classList.remove('open');
        });
    }
    function checkMobile() {
        if (toggle) toggle.style.display = window.innerWidth <= 768 ? 'flex' : 'none';
    }
    checkMobile();
    window.addEventListener('resize', checkMobile);
})();

// ── Toast ─────────────────────────────────────────────────────
function showToast(msg, type = 'success') {
    const el = document.getElementById('admToast');
    el.className = 'adm-toast adm-toast--' + type;
    el.innerHTML = (type === 'success'
        ? '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>'
        : '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>'
    ) + ' ' + msg;
    el.classList.add('show');
    clearTimeout(el._t);
    el._t = setTimeout(() => el.classList.remove('show'), 3500);
}

// ── Confirm modal ─────────────────────────────────────────────
let _confirmCb = null;
function openConfirm(title, body, cb) {
    document.getElementById('confirmTitle').textContent = title;
    document.getElementById('confirmBody').textContent  = body;
    _confirmCb = cb;
    document.getElementById('confirmModal').classList.add('open');
}
function closeConfirm() {
    document.getElementById('confirmModal').classList.remove('open');
    _confirmCb = null;
}
document.getElementById('confirmBtn').addEventListener('click', () => {
    if (_confirmCb) _confirmCb();
    closeConfirm();
});
document.getElementById('confirmModal').addEventListener('click', e => {
    if (e.target === e.currentTarget) closeConfirm();
});
</script>
</body>
</html>
