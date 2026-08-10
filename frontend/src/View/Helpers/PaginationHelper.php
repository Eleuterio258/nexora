<?php

declare(strict_types=1);

namespace E258Tech\View\Helpers;

/**
 * Helper para construir metadados e links de paginação.
 */
final class PaginationHelper
{
    /**
     * @param array<string, mixed> $items
     * @param array<string, mixed> $meta
     */
    public function __construct(
        public array $items,
        public array $meta
    ) {
    }

    /**
     * Cria um helper a partir de uma resposta paginada do backend.
     *
     * O backend pode devolver vários formatos; este método tenta os mais comuns.
     *
     * @param array<string, mixed> $responseBody
     */
    public static function fromResponse(array $responseBody, string $itemsKey = 'data'): self
    {
        $items = $responseBody[$itemsKey] ?? $responseBody['items'] ?? $responseBody['rows'] ?? [];
        $meta = $responseBody['meta'] ?? $responseBody['pagination'] ?? [
            'current_page' => $responseBody['current_page'] ?? 1,
            'last_page'    => $responseBody['last_page'] ?? 1,
            'per_page'     => $responseBody['per_page'] ?? count($items),
            'total'        => $responseBody['total'] ?? count($items),
            'from'         => $responseBody['from'] ?? 1,
            'to'           => $responseBody['to'] ?? count($items),
        ];

        return new self(is_array($items) ? $items : [], $meta);
    }

    public function currentPage(): int
    {
        return (int) ($this->meta['current_page'] ?? 1);
    }

    public function lastPage(): int
    {
        return (int) ($this->meta['last_page'] ?? 1);
    }

    public function perPage(): int
    {
        return (int) ($this->meta['per_page'] ?? 20);
    }

    public function total(): int
    {
        return (int) ($this->meta['total'] ?? count($this->items));
    }

    public function hasPages(): bool
    {
        return $this->lastPage() > 1;
    }

    public function hasPrevious(): bool
    {
        return $this->currentPage() > 1;
    }

    public function hasNext(): bool
    {
        return $this->currentPage() < $this->lastPage();
    }

    /**
     * Gera o URL para uma página específica, preservando outros query params.
     *
     * @param array<string, mixed> $currentParams
     */
    public function urlForPage(int $page, string $baseUrl, array $currentParams, string $pageParam = 'pagina'): string
    {
        $params = array_merge($currentParams, [$pageParam => $page]);
        $query = http_build_query($params);
        return $baseUrl . (str_contains($baseUrl, '?') ? '&' : '?') . $query;
    }

    /**
     * Devolve um array de páginas visíveis (para renderizar elipses).
     *
     * @return list<int|string>
     */
    public function visiblePages(int $delta = 2): array
    {
        $current = $this->currentPage();
        $last = $this->lastPage();

        if ($last <= 1) {
            return [];
        }

        $pages = [];
        $start = max(1, $current - $delta);
        $end = min($last, $current + $delta);

        if ($start > 1) {
            $pages[] = 1;
            if ($start > 2) {
                $pages[] = '...';
            }
        }

        for ($i = $start; $i <= $end; $i++) {
            $pages[] = $i;
        }

        if ($end < $last) {
            if ($end < $last - 1) {
                $pages[] = '...';
            }
            $pages[] = $last;
        }

        return $pages;
    }
}
