<?php
declare(strict_types=1);

namespace E258Tech\Controller\PublicSite;

use E258Tech\Infrastructure\Nexora\NexoraClient;

final class OpenVacanciesCounter
{
    public function __construct(private readonly NexoraClient $nexora)
    {
    }

    public function count(): int
    {
        $cacheFile = sys_get_temp_dir() . '/e258tech_vagas_abertas.cache';

        if (is_file($cacheFile) && (time() - filemtime($cacheFile)) < 60) {
            return (int) file_get_contents($cacheFile);
        }

        try {
            $resp = $this->nexora->callPublic('GET', '/api/public/recrutamento/vagas/abertas', null, [], [
                CURLOPT_TIMEOUT => 2,
                CURLOPT_CONNECTTIMEOUT => 1,
            ]);
            $count = (int) ($resp['body']['abertas'] ?? 0);
            file_put_contents($cacheFile, (string) $count, LOCK_EX);

            return $count;
        } catch (\Throwable) {
            return is_file($cacheFile) ? (int) file_get_contents($cacheFile) : 0;
        }
    }
}
