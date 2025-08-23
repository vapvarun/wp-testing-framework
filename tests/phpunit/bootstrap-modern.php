<?php
/**
 * Modern WordPress Test Bootstrap
 * Uses wp-phpunit package instead of SVN
 */

// Load Composer autoloader
require_once dirname(dirname(__DIR__)) . "/vendor/autoload.php";

// Set up WordPress test environment variables
if (!defined("WP_TESTS_DB_NAME")) {
    define("WP_TESTS_DB_NAME", getenv("WP_TESTS_DB_NAME") ?: "wordpress_test");
}
if (!defined("WP_TESTS_DB_USER")) {
    define("WP_TESTS_DB_USER", getenv("WP_TESTS_DB_USER") ?: "root");
}
if (!defined("WP_TESTS_DB_PASSWORD")) {
    define("WP_TESTS_DB_PASSWORD", getenv("WP_TESTS_DB_PASSWORD") ?: "root");
}
if (!defined("WP_TESTS_DB_HOST")) {
    define("WP_TESTS_DB_HOST", getenv("WP_TESTS_DB_HOST") ?: "localhost");
}

// Set up WordPress paths
$wp_core_dir = sys_get_temp_dir() . "/wordpress/";
if (!defined("ABSPATH")) {
    define("ABSPATH", $wp_core_dir);
}

// Download WordPress if not exists
if (!file_exists($wp_core_dir . "wp-config-sample.php")) {
    echo "Downloading WordPress...\n";
    
    $wp_zip = sys_get_temp_dir() . "/wordpress.zip";
    if (copy("https://wordpress.org/latest.zip", $wp_zip)) {
        $zip = new ZipArchive();
        if ($zip->open($wp_zip) === TRUE) {
            $zip->extractTo(sys_get_temp_dir());
            $zip->close();
            echo "✅ WordPress downloaded successfully\n";
        }
        unlink($wp_zip);
    }
}

// Use wp-phpunit for WordPress test framework
if (class_exists("WP_UnitTestCase")) {
    echo "✅ WordPress test framework loaded via wp-phpunit package\n";
} else {
    // Fallback: Try to load WordPress manually
    if (file_exists($wp_core_dir . "wp-config-sample.php")) {
        require_once $wp_core_dir . "wp-load.php";
    }
}

// Load BuddyPress if available
$possible_bp_locations = [
    $wp_core_dir . "wp-content/plugins/buddypress/bp-loader.php",
    dirname(__DIR__) . "/wp-content/plugins/buddypress/bp-loader.php",
];

foreach ($possible_bp_locations as $bp_file) {
    if (file_exists($bp_file)) {
        require_once $bp_file;
        echo "✅ BuddyPress loaded from: " . basename(dirname($bp_file)) . "\n";
        break;
    }
}

// Load our test utilities
require_once __DIR__ . "/includes/BuddyPressTestCase.php";

echo "✅ Modern WordPress test environment ready!\n";
