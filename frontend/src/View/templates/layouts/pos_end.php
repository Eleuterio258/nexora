    </div><!-- /pos-module-content -->
</div><!-- /pos-body -->
</div><!-- /pos-wrap -->

<script>
setInterval(() => {
    const el = document.getElementById('posClk');
    if (el) el.textContent = new Date().toLocaleString('pt-PT',{day:'2-digit',month:'2-digit',year:'numeric',hour:'2-digit',minute:'2-digit'});
}, 30000);

function showToast(msg, type='success') {
    let t = document.getElementById('_posToast');
    if (!t) {
        t = document.createElement('div');
        t.id = '_posToast';
        t.style.cssText='position:fixed;bottom:20px;right:20px;z-index:9999;background:#111827;color:#fff;padding:10px 18px;border-radius:10px;font-size:13px;font-weight:500;opacity:0;transform:translateY(8px);transition:opacity .25s,transform .25s;pointer-events:none;display:flex;align-items:center;gap:8px;max-width:340px';
        document.body.appendChild(t);
    }
    t.style.background = type==='error' ? '#dc2626' : (type==='warning' ? '#d97706' : '#059669');
    t.innerHTML = `<i class="fa-solid fa-${type==='error'?'circle-xmark':'circle-check'}"></i> ${msg}`;
    t.style.opacity = '1'; t.style.transform = 'translateY(0)';
    clearTimeout(t._tm);
    t._tm = setTimeout(() => { t.style.opacity='0'; t.style.transform='translateY(8px)'; }, 3500);
}

function openConfirm(title, msg, onConfirm) {
    if (confirm(msg)) onConfirm();
}
</script>
</body>
</html>
