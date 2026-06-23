<?php
declare (strict_types = 1);

require_once __DIR__ . '/src/autoload.php';

use E258Tech\Controller\Admin\AdminApiRuntime;
use E258Tech\Core\Application;

$uri = (string) parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

if (str_starts_with($uri, '/admin')) {
    $target = '/nexora' . substr($uri, strlen('/admin'));
    header('Location: ' . $target, true, 301);
    exit;
} elseif (str_starts_with($uri, '/nexora/api/')) {
    (new AdminApiRuntime(Application::bootstrap()))->dispatch(basename($uri, '.php'));
} elseif (str_starts_with($uri, '/nexora')) {
    $app  = Application::bootstrap();
    $path = rtrim($uri, '/') ?: '/nexora';
    if ($path === '/nexora/login') {
        $app->adminAuth->login();
    } elseif ($path === '/nexora/logout') {
        $app->adminAuth->logout();
    } elseif ($path === '/nexora/download') {
        $app->adminDownload->download();
    } elseif ($path === '/nexora' || $path === '/nexora/index') {
        $app->adminPages->dispatch('dashboard');
    } else {
        $route = $app->routes->resolveByPath($path);
        if ($route === null) {
            http_response_code(404);
            echo 'Página não encontrada.';
        } else {
            $app->adminPages->dispatch($route);
        }
    }
} elseif (str_starts_with($uri, '/api/')) {
    $app = Application::bootstrap();
    match (basename($uri, '.php')) {
        'contacto'    => $app->publicApi->submitContact(),
        'candidatura' => $app->publicApi->submitApplication(),
        default       => http_response_code(404),
    };
} else {
    $page = basename(rtrim($uri, '/'), '.php');
    $app  = Application::bootstrap();
    match ($page) {
        'vagas' => $app->carreira->render(),
        default                 => $app->home->render(),
    };
}
