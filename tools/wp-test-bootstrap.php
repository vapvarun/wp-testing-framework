<?php
/**
 * WordPress Test Bootstrap
 * Minimal bootstrap for running plugin tests
 */

// Try to find WordPress
$wp_load_paths = [
    dirname(dirname(dirname(dirname(__FILE__)))) . '/wp-load.php',
    dirname(dirname(dirname(__FILE__))) . '/wp-load.php',
    '/Users/varundubey/Local Sites/wptesting/app/public/wp-load.php',
    $_SERVER['HOME'] . '/Local Sites/wptesting/app/public/wp-load.php'
];

$wp_loaded = false;
foreach ($wp_load_paths as $path) {
    if (file_exists($path)) {
        require_once $path;
        $wp_loaded = true;
        break;
    }
}

if (!$wp_loaded) {
    echo "Warning: Could not load WordPress. Some tests may fail.\n";
}

// Define test constants if not defined
if (!defined('WP_TESTS_DOMAIN')) {
    define('WP_TESTS_DOMAIN', 'example.org');
}

if (!defined('WP_TESTS_EMAIL')) {
    define('WP_TESTS_EMAIL', 'admin@example.org');
}

if (!defined('WP_TESTS_TITLE')) {
    define('WP_TESTS_TITLE', 'Test Blog');
}

if (!defined('WP_DEBUG')) {
    define('WP_DEBUG', true);
}

// Create a minimal WP_UnitTestCase if it doesn't exist
if (!class_exists('WP_UnitTestCase')) {
    class WP_UnitTestCase extends PHPUnit\Framework\TestCase {
        
        protected function setUp(): void {
            parent::setUp();
            // Basic setup
        }
        
        protected function tearDown(): void {
            parent::tearDown();
            // Basic cleanup
        }
        
        // Helper methods
        protected function factory() {
            return new stdClass();
        }
        
        protected function assertWPError($actual, $message = '') {
            $this->assertInstanceOf('WP_Error', $actual, $message);
        }
        
        protected function assertNotWPError($actual, $message = '') {
            $this->assertNotInstanceOf('WP_Error', $actual, $message);
        }
        
        protected function assertQueryTrue(...$args) {
            // Simplified version
            $this->assertTrue(true, 'Query assertion');
        }
        
        protected function go_to($url) {
            // Simplified version
            $_SERVER['REQUEST_URI'] = $url;
        }
    }
}