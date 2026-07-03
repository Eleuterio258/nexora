<?php
declare(strict_types=1);

namespace E258Tech\Infrastructure\Auth;

use E258Tech\Model\Contract\Authorization;

final class PhpSessionAuthorization implements Authorization
{
    public function isAuthenticated(): bool
    {
        return !empty($_SESSION['nexora_access_token']);
    }

    public function can(string $module, string $action): bool
    {
        if (($_SESSION['nexora_tipo'] ?? '') === 'superadmin') {
            return true;
        }

        foreach ($_SESSION['nexora_modulos'] ?? [] as $permission) {
            if (($permission['modulo'] ?? '') === $module) {
                $acoes = $permission['acoes'] ?? [];
                return in_array($action, $acoes, true) || in_array('*', $acoes, true);
            }
        }

        return false;
    }
}
