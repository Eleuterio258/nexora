<?php

declare(strict_types=1);

namespace PHC\Infrastructure\Persistence;

use RuntimeException;

final class JsonDataStore
{
    public function __construct(private string $dataDirectory)
    {
        if (!is_dir($this->dataDirectory)) {
            mkdir($this->dataDirectory, 0755, true);
        }
    }

    public function read(string $name): array
    {
        $path = $this->path($name);
        if (!file_exists($path)) {
            return [];
        }

        $content = file_get_contents($path);
        if ($content === false) {
            throw new RuntimeException('Não foi possível ler ' . $name);
        }

        $data = json_decode($content, true);
        if (!is_array($data)) {
            throw new RuntimeException('Ficheiro JSON inválido: ' . $name);
        }

        return $data;
    }

    public function write(string $name, array $data): void
    {
        $path = $this->path($name);
        $json = json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
        if ($json === false) {
            throw new RuntimeException('Erro ao codificar JSON: ' . $name);
        }

        file_put_contents($path, $json, LOCK_EX);
    }

    private function path(string $name): string
    {
        return $this->dataDirectory . DIRECTORY_SEPARATOR . $name . '.json';
    }
}
