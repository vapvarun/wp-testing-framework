<?php
/**
 * PHPUnit bootstrap file for WordPress Testing Framework
 */

// Load composer autoloader
$composer_autoloader = dirname(__DIR__) . '/vendor/autoload.php';
if (file_exists($composer_autoloader)) {
    require_once $composer_autoloader;
}

// Define test constants
define('TESTS_DIR', __DIR__);
define('ROOT_DIR', dirname(__DIR__));
define('WP_ROOT_DIR', dirname(__DIR__, 2));

// Load environment variables
if (file_exists(dirname(__DIR__) . '/.env')) {
    $lines = file(dirname(__DIR__) . '/.env', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (strpos(trim($line), '#') === 0) {
            continue;
        }
        list($name, $value) = explode('=', $line, 2);
        $name = trim($name);
        $value = trim($value);
        if (!empty($name)) {
            putenv(sprintf('%s=%s', $name, $value));
            $_ENV[$name] = $value;
            $_SERVER[$name] = $value;
        }
    }
}

// Set up WordPress test environment if available
$wp_tests_dir = getenv('WP_TESTS_DIR') ?: '/tmp/wordpress-tests-lib';

// Check if we're running WordPress integration tests
if (file_exists($wp_tests_dir . '/includes/functions.php')) {
    // Give access to tests_add_filter() function
    require_once $wp_tests_dir . '/includes/functions.php';

    // Manually load any plugins we want to test
    function _manually_load_environment() {
        // Load WordPress
        $wp_root = getenv('WP_ROOT_DIR') ?: dirname(__DIR__, 2);
        
        // Load any specific plugins for testing
        // Example: require $wp_root . '/wp-content/plugins/my-plugin/my-plugin.php';
    }
    tests_add_filter('muplugins_loaded', '_manually_load_environment');

    // Start up the WP testing environment
    require $wp_tests_dir . '/includes/bootstrap.php';
    
    echo "WordPress Testing Framework loaded with WordPress test suite.\n";
} else {
    // Fallback for unit tests that don't need WordPress
    echo "WordPress Testing Framework loaded (Unit test mode - no WordPress).\n";
    
    // Define WP_UnitTestCase as a simple PHPUnit TestCase if not available
    if (!class_exists('WP_UnitTestCase')) {
        abstract class WP_UnitTestCase extends \PHPUnit\Framework\TestCase {
            protected function setUp(): void {
                parent::setUp();
                // Add any setup needed for non-WordPress tests
            }
            
            protected function tearDown(): void {
                parent::tearDown();
                // Add any teardown needed for non-WordPress tests
            }
        }
    }
}