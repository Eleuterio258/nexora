<?php
declare(strict_types=1);

namespace E258Tech\Model\Contract;

interface Authorization
{
    public function isAuthenticated(): bool;

    public function can(string $module, string $action): bool;
}
