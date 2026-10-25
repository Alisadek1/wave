<?php
declare(strict_types=1);

$uri = rtrim(parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH), '/') ?: '/';

if (str_starts_with($uri, '/api')) {
    require __DIR__ . '/api/index.php';
    exit;
}

// Serve the React SPA
header('Content-Type: text/html; charset=UTF-8');
readfile(__DIR__ . '/index.html');
