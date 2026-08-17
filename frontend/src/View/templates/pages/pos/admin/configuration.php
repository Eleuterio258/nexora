<?php
declare(strict_types=1);

use E258Tech\Exception\OperationException;

$erro   = null;
$sucesso = null;
$config = [];

try {
    $config = $app->pos->getConfiguracao();
} catch (\Throwable $e) {
    $erro = $e->getMessage();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && $app->auth->userCan('pos', 'configurar')) {
    try {
        $payload = [
            'iva_padrao'         => (float) ($_POST['iva_padrao'] ?? 17),
            'serie_venda'        => ($_POST['serie_venda'] ?? '') !== '' ? trim($_POST['serie_venda']) : null,
            'serie_nota_credito' => ($_POST['serie_nota_credito'] ?? '') !== '' ? trim($_POST['serie_nota_credito']) : null,
            'recibo_auto'        => isset($_POST['recibo_auto']),
        ];
        $app->pos->saveConfiguracao($payload);
        $config = $app->pos->getConfiguracao();
        $sucesso = 'Configuração guardada com sucesso.';
    } catch (OperationException $e) {
        $erro = $e->getMessage();
    } catch (\Throwable $e) {
        $erro = 'Erro ao guardar configuração: ' . $e->getMessage();
    }
}

$pageTitle  = 'Configuração POS';
$activePage = 'pos_admin_configuration';
$breadcrumb = [['Admin', '/nexora/'], ['POS', '/pos/gerente/dashboard'], ['Configuração', '']];

include dirname(__DIR__, 2) . '/layouts/top.php';
?>
<div class="container-fluid">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h1 class="h3 mb-0"><i class="bi bi-gear"></i> Configuração POS</h1>
        <span class="badge bg-secondary">Portal Admin</span>
    </div>

    <?php if ($sucesso): ?>
    <div class="alert alert-success"><?= htmlspecialchars($sucesso) ?></div>
    <?php endif; ?>
    <?php if ($erro): ?>
    <div class="alert alert-danger"><?= htmlspecialchars($erro) ?></div>
    <?php endif; ?>

    <div class="card">
        <div class="card-body">
            <form method="POST" action="">
                <div class="row">
                    <div class="col-md-4 mb-3">
                        <label for="iva_padrao" class="form-label">IVA Padrão (%)</label>
                        <input type="number" step="0.01" min="0" max="100" class="form-control" id="iva_padrao" name="iva_padrao"
                               value="<?= htmlspecialchars((string) ($config['iva_padrao'] ?? 17)) ?>" required>
                    </div>
                    <div class="col-md-4 mb-3">
                        <label for="serie_venda" class="form-label">Série de Venda</label>
                        <input type="text" class="form-control" id="serie_venda" name="serie_venda"
                               value="<?= htmlspecialchars($config['serie_venda'] ?? '') ?>">
                    </div>
                    <div class="col-md-4 mb-3">
                        <label for="serie_nota_credito" class="form-label">Série de Nota de Crédito</label>
                        <input type="text" class="form-control" id="serie_nota_credito" name="serie_nota_credito"
                               value="<?= htmlspecialchars($config['serie_nota_credito'] ?? '') ?>">
                    </div>
                </div>
                <div class="form-check mb-3">
                    <input class="form-check-input" type="checkbox" id="recibo_auto" name="recibo_auto"
                           <?= ($config['recibo_auto'] ?? true) ? 'checked' : '' ?>>
                    <label class="form-check-label" for="recibo_auto">
                        Emitir recibo automaticamente após venda
                    </label>
                </div>
                <?php if ($app->auth->userCan('pos', 'configurar')): ?>
                <button type="submit" class="btn btn-primary">
                    <i class="bi bi-save"></i> Guardar
                </button>
                <?php endif; ?>
            </form>
        </div>
    </div>
</div>
<?php include dirname(__DIR__, 2) . '/layouts/bottom.php'; ?>
