<?php
/**
 * Componente de flash messages.
 *
 * Uso: include 'src/View/templates/partials/components/flash-messages.php';
 * O componente consome automaticamente as mensagens registadas via ApiResponse::flash().
 */

declare(strict_types=1);

use E258Tech\Infrastructure\Nexora\ApiResponse;

$messages = ApiResponse::consumeFlashMessages();
if ($messages === []) {
    return;
}
?>

<div class="flash-messages" role="alert" aria-live="polite">
    <?php foreach ($messages as $msg): ?>
        <div class="flash-message flash-message--<?= htmlspecialchars($msg['type']) ?>" data-auto-dismiss="5000">
            <span class="flash-message__text"><?= htmlspecialchars($msg['message']) ?></span>
            <button type="button" class="flash-message__close" aria-label="Fechar">&times;</button>
        </div>
    <?php endforeach; ?>
</div>
