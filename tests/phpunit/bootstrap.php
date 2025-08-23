<?php
/**
 * PHPUnit bootstrap file for BuddyNext tests
 *
 * @package BuddyNext\Tests
 */

// Load composer autoloader
$composer_autoloader = dirname( __DIR__, 2 ) . '/vendor/autoload.php';
if ( file_exists( $composer_autoloader ) ) {
    require_once $composer_autoloader;
}

// Define test constants
define( 'BUDDYNEXT_TESTS_DIR', __DIR__ );
define( 'BUDDYNEXT_ROOT_DIR', dirname( __DIR__, 2 ) );

// For unit tests (not requiring WordPress)
if ( defined( 'BUDDYNEXT_UNIT_TESTS' ) && BUDDYNEXT_UNIT_TESTS ) {
    return;
}

// Integration tests - Load WordPress test environment
$wp_tests_dir = getenv( 'WP_TESTS_DIR' );

// Try common locations for WordPress test library
if ( ! $wp_tests_dir ) {
    // Local by Flywheel default location
    $wp_tests_dir = '/tmp/wordpress-tests-lib';
    
    // Check if we're in a Local environment
    if ( ! file_exists( $wp_tests_dir . '/includes/functions.php' ) ) {
        $wp_tests_dir = dirname( __DIR__, 2 ) . '/wp-tests';
    }
    
    // Try to find it relative to WordPress install
    if ( ! file_exists( $wp_tests_dir . '/includes/functions.php' ) ) {
        $wp_tests_dir = dirname( __DIR__, 4 ) . '/wp-tests';
    }
}

// Verify WordPress test library exists
if ( ! file_exists( $wp_tests_dir . '/includes/functions.php' ) ) {
    echo "WordPress test library not found at: $wp_tests_dir\n";
    echo "Please set WP_TESTS_DIR environment variable or install WordPress test library.\n";
    echo "\nTo install WordPress test library, run:\n";
    echo "bash bin/install-wp-tests.sh wordpress_test root root localhost latest\n";
    exit( 1 );
}

// Give access to tests_add_filter() function
require_once $wp_tests_dir . '/includes/functions.php';

/**
 * Manually load required plugins
 */
function _manually_load_plugins() {
    // Load BuddyPress
    $bp_path = dirname( __DIR__, 2 ) . '/wp-content/plugins/buddypress/bp-loader.php';
    if ( file_exists( $bp_path ) ) {
        require $bp_path;
    }
    
    // Load any BuddyNext specific plugins
    $plugins_dir = dirname( __DIR__, 2 ) . '/wp-content/plugins/';
    foreach ( glob( $plugins_dir . 'buddynext-*/buddynext-*.php' ) as $plugin ) {
        if ( file_exists( $plugin ) ) {
            require $plugin;
        }
    }
    
    // Load theme if needed for integration tests
    $theme_functions = dirname( __DIR__, 2 ) . '/wp-content/themes/buddynext/functions.php';
    if ( file_exists( $theme_functions ) ) {
        require $theme_functions;
    }
}

// Hook into WordPress loading
tests_add_filter( 'muplugins_loaded', '_manually_load_plugins' );

// Activate BuddyPress components for testing
tests_add_filter( 'bp_is_network_activated', '__return_false' );
tests_add_filter( 'bp_active_components', function() {
    return array(
        'members'     => 1,
        'groups'      => 1,
        'activity'    => 1,
        'xprofile'    => 1,
        'friends'     => 1,
        'messages'    => 1,
        'settings'    => 1,
        'notifications' => 1,
    );
});

// Start up the WordPress test environment
require $wp_tests_dir . '/includes/bootstrap.php';

// Load BuddyPress test case if available
$bp_tests_dir = dirname( __DIR__, 2 ) . '/wp-content/plugins/buddypress/tests/phpunit/includes/';
if ( file_exists( $bp_tests_dir . 'testcase.php' ) ) {
    require_once $bp_tests_dir . 'testcase.php';
}

echo "BuddyNext PHPUnit test environment loaded.\n";