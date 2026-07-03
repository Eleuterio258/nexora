    </div><!-- /.portal-content -->
</main><!-- /.portal-main -->

<script>
function showToast(msg, type = 'success') {
    const t = document.createElement('div');
    t.style.cssText = `position:fixed;bottom:1.25rem;right:1.25rem;padding:.65rem 1.1rem;border-radius:8px;
        font-size:.85rem;font-weight:600;z-index:9999;color:#fff;box-shadow:0 4px 12px rgba(0,0,0,.15);
        background:${type === 'error' ? '#DC2626' : '#10B981'};animation:fadeIn .2s`;
    t.textContent = msg;
    document.body.appendChild(t);
    setTimeout(() => t.remove(), 3000);
}
</script>
<style>
@keyframes fadeIn { from { opacity:0; transform:translateY(6px); } to { opacity:1; transform:translateY(0); } }
</style>
</body>
</html>
