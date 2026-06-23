<?php
declare(strict_types=1);

namespace E258Tech\View;

final class ViewHelper
{
    public function field(?array $data, string $key, mixed $default = ''): string
    {
        return htmlspecialchars((string) ($data[$key] ?? $default), ENT_QUOTES, 'UTF-8');
    }

    public function queryLink(string $path, array $query, array $overrides = []): string
    {
        $params = array_filter(
            array_merge($query, $overrides),
            static fn(mixed $value): bool => $value !== '' && $value !== null
        );

        return $path . ($params ? '?' . http_build_query($params) : '');
    }

    public function timeAgo(string $dateTime): string
    {
        $difference = time() - strtotime($dateTime);
        if ($difference < 3600) {
            return (int) ($difference / 60) . ' min';
        }
        if ($difference < 86400) {
            return (int) ($difference / 3600) . 'h';
        }
        if ($difference < 604800) {
            return (int) ($difference / 86400) . 'd';
        }

        return date('d/m/y', strtotime($dateTime));
    }

    public function daysUntil(?string $date): ?int
    {
        return $date
            ? (int) floor((strtotime($date) - strtotime(date('Y-m-d'))) / 86400)
            : null;
    }

    public function vacancySlug(string $area): string
    {
        return strtolower((string) preg_replace(
            '/\s+/',
            '_',
            (string) iconv('UTF-8', 'ASCII//TRANSLIT', $area)
        ));
    }

    public function vacancyDeadline(?string $date): string
    {
        if (!$date) {
            return 'Em aberto';
        }

        $timestamp = strtotime($date);
        $months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
        return date('d', $timestamp)
            . ' ' . $months[(int) date('m', $timestamp) - 1]
            . '. ' . date('Y', $timestamp);
    }

    public function vacancyDeadlineLabel(?string $formatted, ?int $days): string
    {
        if ($days === null || $days > 7) {
            return (string) $formatted;
        }
        if ($days === 0) {
            return $formatted . ' · Último dia!';
        }
        if ($days <= 3) {
            return $formatted . ' · ⚠ ' . $days . ' dia' . ($days > 1 ? 's' : '') . ' restantes!';
        }

        return $formatted . ' · ' . $days . ' dias restantes';
    }

    public function vacancyDeadlineClass(?int $days): string
    {
        if ($days === null) {
            return '';
        }
        if ($days <= 3) {
            return ' vaga-prazo-badge--urgente';
        }
        if ($days <= 7) {
            return ' vaga-prazo-badge--aviso';
        }

        return '';
    }
}
