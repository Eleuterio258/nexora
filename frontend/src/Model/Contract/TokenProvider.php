<?php
declare(strict_types=1);

namespace E258Tech\Model\Contract;

interface TokenProvider
{
    public function accessToken(bool $forceRefresh = false): string;
}
