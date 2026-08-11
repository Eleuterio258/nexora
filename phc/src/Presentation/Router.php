<?php

declare(strict_types=1);

namespace PHC\Presentation;

final class Router
{
    /**
     * @var array<string, callable>
     */
    private array $routes = [];

    public function get(string $path, callable $handler): self
    {
        $this->register('GET', $path, $handler);
        return $this;
    }

    public function post(string $path, callable $handler): self
    {
        $this->register('POST', $path, $handler);
        return $this;
    }

    private function register(string $method, string $path, callable $handler): void
    {
        $this->routes[$method . ':' . $path] = $handler;
    }

    public function dispatch(string $method, string $uri): void
    {
        $path = parse_url($uri, PHP_URL_PATH) ?: $uri;
        $path = rtrim($path, '/') ?: '/';

        $key = $method . ':' . $path;

        if (!isset($this->routes[$key])) {
            http_response_code(404);
            echo 'Página não encontrada.';
            return;
        }

        $handler = $this->routes[$key];
        $handler();
    }
}
