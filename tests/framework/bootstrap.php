<?php
// Load composer autoloader
$composer_autoloader = dirname(__DIR__, 2) . '/vendor/autoload.php';
if (file_exists($composer_autoloader)) {
    require_once $composer_autoloader;
}

define('TESTS_DIR', __DIR__);
define('ROOT_DIR', dirname(__DIR__, 2));

echo "WordPress Testing Framework loaded.\n";
