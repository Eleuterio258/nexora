<?php
// Grelha de permissões por funcionalidade real de cada módulo.
// Requer: $permsCurrent (array de ['modulo'=>string,'acao'=>string])
//          $permGridId  (string, id único — opcional)

$__allModulos  = require __DIR__ . '/modules.php';
$__modulosGrid = array_filter($__allModulos, fn($m) => empty($m['sem_atribuicao']));
$permGridId    = $permGridId ?? 'permGrid';

// Permissões actuais indexadas por "modulo:acao"
$__granted = [];
foreach (($permsCurrent ?? []) as $p) {
    $mod = $p['modulo'] ?? '';
    $ac  = $p['acao']   ?? '';
    if ($mod !== '' && $ac !== '') {
        $__granted[$mod . ':' . $ac] = true;
    }
}
?>
<style>
.pg-wrap { display:grid; grid-template-columns:repeat(auto-fill,minmax(340px,1fr)); gap:var(--adm-sp-4); }
.pg-card { background:var(--adm-white); border:1px solid var(--adm-gray-200); border-radius:var(--adm-radius-lg); overflow:hidden; }
.pg-card-head {
    display:flex; align-items:center; gap:var(--adm-sp-3);
    padding:var(--adm-sp-3) var(--adm-sp-4);
    background:var(--adm-gray-50); border-bottom:1px solid var(--adm-gray-100);
    cursor:pointer; user-select:none;
}
.pg-card-dot { width:10px; height:10px; border-radius:50%; flex-shrink:0; }
.pg-card-title { font-size:var(--adm-text-sm); font-weight:700; color:var(--adm-gray-800); flex:1; }
.pg-card-toggle-all {
    font-size:.65rem; font-weight:600; text-transform:uppercase; letter-spacing:.05em;
    color:var(--adm-gray-400); background:none; border:none; cursor:pointer; padding:0;
}
.pg-card-toggle-all:hover { color:var(--adm-green); }
.pg-features { padding:var(--adm-sp-2) var(--adm-sp-4) var(--adm-sp-3); display:flex; flex-direction:column; gap:1px; }
.pg-feature {
    display:flex; align-items:center; gap:var(--adm-sp-3);
    padding:var(--adm-sp-2) var(--adm-sp-2);
    border-radius:var(--adm-radius-sm);
    cursor:pointer; transition:background .1s;
}
.pg-feature:hover { background:var(--adm-gray-50); }
.pg-feature input[type="checkbox"] { accent-color:var(--adm-green); width:15px; height:15px; cursor:pointer; flex-shrink:0; }
.pg-feature input:disabled { accent-color:var(--adm-gray-400); cursor:not-allowed; opacity:.7; }
.pg-feature-label { font-size:var(--adm-text-sm); color:var(--adm-gray-700); line-height:1.4; }
.pg-feature.from-cargo { background:var(--adm-gray-50); }
.pg-feature.from-cargo .pg-feature-label { color:var(--adm-gray-400); }
</style>

<div class="pg-wrap" id="<?= htmlspecialchars($permGridId) ?>">
<?php foreach ($__modulosGrid as $modKey => $modInfo):
    $acoesMod = $modInfo['acoes'] ?? [];
    if (empty($acoesMod)) continue;
?>
<div class="pg-card" data-modulo="<?= htmlspecialchars($modKey) ?>">
    <div class="pg-card-head" onclick="pgToggleModule('<?= htmlspecialchars($permGridId) ?>', '<?= htmlspecialchars($modKey) ?>')">
        <span class="pg-card-dot" style="background:<?= htmlspecialchars($modInfo['cor']) ?>"></span>
        <span class="pg-card-title"><?= htmlspecialchars($modInfo['nome']) ?></span>
        <button type="button" class="pg-card-toggle-all"
                onclick="event.stopPropagation();pgToggleModule('<?= htmlspecialchars($permGridId) ?>', '<?= htmlspecialchars($modKey) ?>')">
            selec. tudo
        </button>
    </div>
    <div class="pg-features">
        <?php foreach ($acoesMod as $acKey => $acLabel):
            $checked  = isset($__granted[$modKey . ':' . $acKey]);
            $fromCargo = isset($__fromCargo[$modKey . ':' . $acKey]);
        ?>
        <label class="pg-feature<?= $fromCargo ? ' from-cargo adm-perm-from-cargo' : '' ?>">
            <input type="checkbox"
                   class="adm-checkbox"
                   name="perm[<?= htmlspecialchars($modKey) ?>][<?= htmlspecialchars($acKey) ?>]"
                   <?= $checked || $fromCargo ? 'checked' : '' ?>
                   <?= $fromCargo ? 'disabled' : '' ?>>
            <span class="pg-feature-label"><?= htmlspecialchars($acLabel) ?></span>
        </label>
        <?php endforeach; ?>
    </div>
</div>
<?php endforeach; ?>
</div>

<script>
function pgToggleModule(gridId, modulo) {
    const boxes = document.querySelectorAll(
        '#' + gridId + ' [data-modulo="' + modulo + '"] input[type="checkbox"]:not(:disabled)'
    );
    const allChecked = Array.from(boxes).every(b => b.checked);
    boxes.forEach(b => b.checked = !allChecked);
}

function collectGridPerms(gridId) {
    const perms = [];
    document.querySelectorAll('#' + gridId + ' input[type="checkbox"]:checked:not(:disabled)').forEach(cb => {
        const m = cb.name.match(/^perm\[([^\]]+)\]\[([^\]]+)\]$/);
        if (m) perms.push({ modulo: m[1], acao: m[2] });
    });
    return perms;
}
</script>
