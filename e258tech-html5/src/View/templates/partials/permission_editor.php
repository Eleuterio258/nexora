<?php
// Editor de permissões reutilizável (lista de {modulo, acao}).
// Requer no scope: $permsCurrent (array de ['modulo'=>string,'acao'=>string])
//                  $permListId   (string, id único do contentor na página)
$__modulosPerm = array_filter(require __DIR__ . '/modules.php', fn($m) => empty($m['sem_atribuicao']));
if (empty($permsCurrent)) {
    $permsCurrent = [['modulo' => '', 'acao' => '']];
}
?>
<div class="adm-list-field" id="<?= htmlspecialchars($permListId) ?>">
    <?php foreach ($permsCurrent as $p): ?>
    <div class="adm-list-item">
        <select class="adm-select" name="perm_modulo[]" style="max-width:220px">
            <?php foreach ($__modulosPerm as $key => $info): ?>
            <option value="<?= $key ?>" <?= ($p['modulo'] ?? '') === $key ? 'selected' : '' ?>><?= htmlspecialchars($info['nome']) ?></option>
            <?php endforeach; ?>
        </select>
        <input class="adm-input" type="text" name="perm_acao[]" maxlength="60" placeholder="ação (ex: ler, criar, editar, eliminar)" value="<?= htmlspecialchars($p['acao'] ?? '') ?>">
        <button type="button" class="adm-list-remove" onclick="removeItem(this)" title="Remover">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
        </button>
    </div>
    <?php endforeach; ?>
</div>
<button type="button" class="adm-list-add" onclick="addPermRow('<?= htmlspecialchars($permListId) ?>')">
    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
    Adicionar permissão
</button>

<script>
const PERM_MODULOS = <?= json_encode(array_map(fn($k, $v) => ['key' => $k, 'nome' => $v['nome']], array_keys($__modulosPerm), $__modulosPerm), JSON_UNESCAPED_UNICODE) ?>;

function addPermRow(listId) {
    const list = document.getElementById(listId);
    const div  = document.createElement('div');
    div.className = 'adm-list-item';
    let opts = '';
    PERM_MODULOS.forEach(m => opts += `<option value="${m.key}">${m.nome}</option>`);
    div.innerHTML = `
        <select class="adm-select" name="perm_modulo[]" style="max-width:220px">${opts}</select>
        <input class="adm-input" type="text" name="perm_acao[]" maxlength="60" placeholder="ação (ex: ler, criar, editar, eliminar)">
        <button type="button" class="adm-list-remove" onclick="removeItem(this)" title="Remover">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
        </button>`;
    list.appendChild(div);
    div.querySelector('input').focus();
}

function removeItem(btn) {
    btn.closest('.adm-list-item').remove();
}

function collectPerms(listId) {
    const perms = [];
    document.querySelectorAll('#' + listId + ' .adm-list-item').forEach(item => {
        const modulo = item.querySelector('select[name="perm_modulo[]"]').value;
        const acao   = item.querySelector('input[name="perm_acao[]"]').value.trim();
        if (acao) perms.push({ modulo, acao });
    });
    return perms;
}
</script>
