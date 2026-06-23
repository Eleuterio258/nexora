<?php
declare(strict_types=1);

use E258Tech\Http\ServerRequest;
use E258Tech\Routing\AdminRoutes;
use E258Tech\View\ViewHelper;

require_once __DIR__ . '/../src/autoload.php';

function presentationExpect(mixed $expected, mixed $actual, string $message): void
{
    if ($expected !== $actual) {
        throw new RuntimeException(
            $message . PHP_EOL
            . 'Esperado: ' . var_export($expected, true) . PHP_EOL
            . 'Recebido: ' . var_export($actual, true)
        );
    }
}

$request = new ServerRequest(
    ['page' => '3', 'estado' => 'ativo', 'invalid' => 'x'],
    ['nome' => '  Maria  ', 'vaga_id' => '12'],
    ['cv' => ['name' => 'cv.pdf']],
    ['REQUEST_METHOD' => 'POST', 'REQUEST_URI' => '/nexora/teste.php?page=3']
);

presentationExpect(true, $request->isPost(), 'Deve identificar pedidos POST.');
presentationExpect(3, $request->queryInt('page'), 'Deve converter inteiros da query.');
presentationExpect('ativo', $request->queryEnum('estado', ['ativo']), 'Deve validar enums.');
presentationExpect('', $request->queryEnum('invalid', ['ativo']), 'Deve rejeitar enums invalidos.');
presentationExpect('Maria', $request->postString('nome'), 'Deve normalizar strings POST.');
presentationExpect(12, $request->postInt('vaga_id'), 'Deve converter inteiros POST.');
presentationExpect('cv.pdf', $request->file('cv')['name'], 'Deve devolver ficheiros.');

$view = new ViewHelper();
presentationExpect(
    '&lt;script&gt;',
    $view->field(['name' => '<script>'], 'name'),
    'Deve escapar valores de formulario.'
);
presentationExpect(
    '/nexora/lista.php?estado=ativo&page=2',
    $view->queryLink('/nexora/lista.php', ['estado' => 'ativo', 'page' => 1], ['page' => 2]),
    'Deve construir links preservando filtros.'
);
presentationExpect(
    'desenvolvimento_web',
    $view->vacancySlug('Desenvolvimento Web'),
    'Deve criar slugs de vagas.'
);

$routes = new AdminRoutes();
presentationExpect(71, count($routes->names()), 'Deve registrar todas as paginas administrativas.');
foreach ($routes->names() as $routeName) {
    $definition = $routes->definition($routeName);
    presentationExpect(
        true,
        is_file(__DIR__ . '/../src/View/templates/pages/' . $definition['view']),
        "A rota $routeName deve apontar para uma view existente."
    );
}
presentationExpect('/nexora/', $routes->path('dashboard'), 'Deve resolver o dashboard.');
presentationExpect(
    '/nexora/vaga_form.php?id=12',
    $routes->path('vaga_form', ['id' => 12]),
    'Deve construir URLs administrativas com query.'
);
presentationExpect(
    '/nexora/api/vaga_save.php',
    $routes->api('vaga_save'),
    'Deve construir URLs da API administrativa.'
);

$apiFiles = array_map(
    static fn(string $path): string => basename($path, '.php'),
    (array) glob(__DIR__ . '/../nexora/api/*.php')
);
sort($apiFiles);
$apiNames = $routes->apiNames();
sort($apiNames);
presentationExpect(
    $apiFiles,
    $apiNames,
    'O catalogo de rotas de API deve corresponder aos ficheiros em nexora/api.'
);

echo "Presentation service tests passed.\n";
