<?php
require_once __DIR__ . '/../src/autoload.php';

use E258Tech\Core\Application;

$app = Application::bootstrap('http://127.0.0.1:8080');
$resp = $app->session->login('olimpia.chitlhango@e258tech.mz', 'E258tech@2026');

echo "HTTP Status: " . $resp['status'] . "\n";
echo "User:\n";
print_r($resp['body']['user'] ?? []);
echo "Modulos count: " . count($resp['body']['modulos'] ?? []) . "\n";
echo "Features count: " . count($resp['body']['features'] ?? []) . "\n";

$app->session->store($resp['body']);
echo "Stored user in session:\n";
print_r($app->session->user());
