<?php
declare(strict_types=1);

namespace E258Tech\Core;

use LogicException;

final class Application
{
    private static ?ApplicationContainer $container = null;

    public static function bootstrap(): ApplicationContainer
    {
        define('APP_ENV', getenv('APP_ENV') ?: 'development');

        if (APP_ENV === 'production') {
            ini_set('display_errors', '0');
            ini_set('log_errors', '1');
            error_reporting(E_ALL & ~E_DEPRECATED & ~E_NOTICE);
        } else {
            ini_set('display_errors', '1');
            error_reporting(E_ALL);
        }

        return self::boot(
            rtrim((string) (getenv('NEXORA_API_URL') ?: 'http://127.0.0.1:8080'), '/')
        );
    }

    public static function boot(string $baseUrl): ApplicationContainer
    {
        return self::$container ??= new ApplicationContainer($baseUrl);
    }

    public static function instance(): ApplicationContainer
    {
        return self::$container
            ?? throw new LogicException('A aplicacao ainda nao foi inicializada.');
    }

    private function __construct()
    {
    }
}
