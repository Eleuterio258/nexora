<?php

declare(strict_types=1);

namespace PHC\Presentation\View;

final class Html
{
    public static function e(string $text): string
    {
        return htmlspecialchars($text, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
    }

    public static function money(float $amount): string
    {
        return number_format($amount, 2, ',', '.') . ' MT';
    }

    public static function datePt(string $date): string
    {
        return date('d/m/Y', strtotime($date));
    }
}
