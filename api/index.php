<?php
if (function_exists('opcache_reset')) {
    @opcache_reset();
}
ini_set('opcache.enable', '0');

// vercel-php sets SCRIPT_NAME to "/api/index.php", which makes Symfony's
// Request auto-detect "/api" as the app's base path and strip it from
// PATH_INFO. Since our Laravel routes already include "api/" as part of
// their registered URI (Laravel's own api-routing prefix), that double
// counts "/api" and every API route 404s. Neutralize it by pretending
// the script lives at the domain root.
$_SERVER['SCRIPT_NAME'] = '/index.php';
$_SERVER['PHP_SELF'] = '/index.php';
unset($_SERVER['PATH_INFO']);

$tmp = '/tmp/storage';
foreach (['/framework/views', '/framework/cache', '/framework/sessions', '/logs'] as $dir) {
    @mkdir($tmp . $dir, 0775, true);
}
$bootstrapCache = '/tmp/bootstrap/cache';
@mkdir($bootstrapCache, 0775, true);
foreach (['routes-v7.php', 'services.php', 'packages.php', 'config.php'] as $cacheFile) {
    @unlink($bootstrapCache . '/' . $cacheFile);
}

define('LARAVEL_START', microtime(true));
require __DIR__ . '/../vendor/autoload.php';

/** @var \Illuminate\Foundation\Application $app */
$app = require_once __DIR__ . '/../bootstrap/app.php';
$app->useStoragePath($tmp);
$app->useBootstrapPath('/tmp/bootstrap');

$kernel = $app->make(\Illuminate\Contracts\Http\Kernel::class);
$request = \Illuminate\Http\Request::capture();
$response = $kernel->handle($request);
$response->send();
$kernel->terminate($request, $response);