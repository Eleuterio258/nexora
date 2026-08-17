<?php
declare(strict_types=1);

/**
 * Redirecionamento temporário das rotas antigas /nexora/pos/* para os novos
 * portais /pos/*.
 *
 * Esta view é usada pelas rotas legadas em ComercialPageRoutes enquanto durar
 * a transição. Quando todos os utilizadores estiverem habituados aos novos
 * URLs, estas rotas devem ser removidas.
 */

$uri = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
$uri = rtrim($uri, '/');

$map = [
    '/nexora/pos'                       => '/pos/operador/terminal',
    '/nexora/pos/dashboard'             => '/pos/gerente/dashboard',
    '/nexora/pos/vendas'                => '/pos/gerente/vendas',
    '/nexora/pos/vendas/ver'            => '/pos/gerente/vendas/ver',
    '/nexora/pos/terminais'             => '/pos/admin/terminais',
    '/nexora/pos/catalogo'              => '/pos/admin/catalogo',
    '/nexora/pos/relatorios'            => '/pos/gerente/relatorios',
    '/nexora/pos/devolucoes'            => '/pos/operador/devolucoes',
    '/nexora/pos/sessoes'               => '/pos/gerente/sessoes',
    '/nexora/pos/sessoes/abrir'         => '/pos/operador/sessao/abrir',
    '/nexora/pos/sessoes/ver'           => '/pos/gerente/sessoes/ver',
    '/nexora/pos/sessoes/fechar'        => '/pos/operador/sessao/fechar',
    '/nexora/pos/relatorios/fecho'      => '/pos/gerente/relatorios/fecho',
    '/nexora/pos/descontos'             => '/pos/admin/descontos',
];

$target = $map[$uri] ?? '/pos/gerente/dashboard';

$query = $_SERVER['QUERY_STRING'] ?? '';
if ($query !== '') {
    $target .= '?' . $query;
}

header('Location: ' . $target, true, 302);
exit;
