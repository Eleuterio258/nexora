<?php
declare(strict_types=1);

require_once __DIR__ . '/../src/autoload.php';

$src = realpath(__DIR__ . '/../src');
$forbiddenModelDependencies = [
    'E258Tech\\Controller\\',
    'E258Tech\\Core\\',
    'E258Tech\\Infrastructure\\',
    'E258Tech\\Routing\\',
    'E258Tech\\View\\',
];
$errors = [];

$iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($src));
foreach ($iterator as $file) {
    if (!$file->isFile() || $file->getExtension() !== 'php') {
        continue;
    }

    $contents = (string) file_get_contents($file->getPathname());
    $relative = str_replace('\\', '/', substr($file->getPathname(), strlen($src) + 1));

    if (str_starts_with($relative, 'Model/')) {
        foreach ($forbiddenModelDependencies as $dependency) {
            if (str_contains($contents, $dependency)) {
                $errors[] = "$relative depende de $dependency";
            }
        }
    }

    if ($relative !== 'autoload.php' && !str_starts_with($relative, 'View/templates/')) {
        $class = 'E258Tech\\' . str_replace(['/', '.php'], ['\\', ''], $relative);
        try {
            if (!class_exists($class) && !interface_exists($class) && !trait_exists($class)) {
                $errors[] = "$relative nao corresponde a $class";
            }
        } catch (Throwable $exception) {
            $errors[] = "$relative: {$exception->getMessage()}";
        }
    }
}

if ($errors) {
    throw new RuntimeException(implode(PHP_EOL, $errors));
}

echo "Architecture tests passed.\n";
