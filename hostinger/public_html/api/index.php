<?php

declare(strict_types=1);

// Backend root is the sibling "backend" directory
$backendRoot = __DIR__ . '/../backend/';

// Load environment variables
$envFile = $backendRoot . '.env';
if (file_exists($envFile)) {
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (str_starts_with(trim($line), '#')) continue;
        if (str_contains($line, '=')) {
            [$key, $value] = explode('=', $line, 2);
            $_ENV[trim($key)] = trim($value);
        }
    }
}

// Autoloader
spl_autoload_register(function (string $class) use ($backendRoot): void {
    $dirs = [
        $backendRoot . 'app/controllers/',
        $backendRoot . 'app/models/',
        $backendRoot . 'app/middleware/',
        $backendRoot . 'app/services/',
        $backendRoot . 'app/helpers/',
        $backendRoot . 'app/routes/',
        $backendRoot . 'config/',
    ];

    foreach ($dirs as $dir) {
        $file = $dir . $class . '.php';
        if (file_exists($file)) {
            require_once $file;
            return;
        }
    }
});

// CORS Headers
$config = require $backendRoot . 'config/app.php';
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';

if (in_array($origin, $config['cors_origins'], true)) {
    header('Access-Control-Allow-Origin: ' . $origin);
}

header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Max-Age: 86400');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

// Security headers
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');
header('X-XSS-Protection: 1; mode=block');
header('Referrer-Policy: strict-origin-when-cross-origin');

// Parse request body
if (in_array($_SERVER['REQUEST_METHOD'], ['POST', 'PUT', 'PATCH'], true)) {
    $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
    if (str_contains($contentType, 'application/json')) {
        $body = file_get_contents('php://input');
        if ($body) {
            $parsed = json_decode($body, true);
            if (json_last_error() === JSON_ERROR_NONE) {
                $_POST = array_merge($_POST, $parsed ?? []);
            }
        }
    }
}

// DEBUG: dump server vars when ?_debug=1 is present — REMOVE after diagnosis
if (isset($_GET['_debug'])) {
    header('Content-Type: application/json');
    echo json_encode([
        'REQUEST_URI'    => $_SERVER['REQUEST_URI']    ?? 'NOT SET',
        'REDIRECT_URL'   => $_SERVER['REDIRECT_URL']   ?? 'NOT SET',
        'PATH_INFO'      => $_SERVER['PATH_INFO']      ?? 'NOT SET',
        'ORIG_PATH_INFO' => $_SERVER['ORIG_PATH_INFO'] ?? 'NOT SET',
        'SCRIPT_NAME'    => $_SERVER['SCRIPT_NAME']    ?? 'NOT SET',
        'HTTP_HOST'      => $_SERVER['HTTP_HOST']      ?? 'NOT SET',
        'REQUEST_METHOD' => $_SERVER['REQUEST_METHOD'] ?? 'NOT SET',
    ], JSON_PRETTY_PRINT);
    exit;
}

// Get URI — LiteSpeed may update REQUEST_URI during rewrites; fall back to REDIRECT_URL
$uri = parse_url(
    $_SERVER['REDIRECT_URL'] ?? $_SERVER['REQUEST_URI'] ?? '/',
    PHP_URL_PATH
);
$uri = rtrim($uri, '/') ?: '/';

// Strip base path if set (not needed for Hostinger root installs, set APP_BASE_PATH=none)
$basePath = $_ENV['APP_BASE_PATH'] ?? 'none';
if ($basePath && $basePath !== 'none' && str_starts_with($uri, $basePath)) {
    $uri = substr($uri, strlen($basePath)) ?: '/';
}

// Global exception handler
set_exception_handler(function (Throwable $e): void {
    if (!headers_sent()) {
        header('Content-Type: application/json');
        http_response_code(500);
    }
    $debug = ($_ENV['APP_DEBUG'] ?? 'false') === 'true';
    echo json_encode([
        'ok'      => false,
        'message' => $debug ? $e->getMessage() : 'Internal server error',
        'file'    => $debug ? $e->getFile() . ':' . $e->getLine() : null,
    ]);
});

// Load and dispatch routes
$router = require $backendRoot . 'app/routes/api.php';
$router->dispatch($_SERVER['REQUEST_METHOD'], $uri);
