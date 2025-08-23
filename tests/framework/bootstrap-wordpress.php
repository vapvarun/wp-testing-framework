<?php
/**
 * Bootstrap for WordPress integration tests
 */

// Determine paths
$_tests_dir = getenv('WP_TESTS_DIR');
if (!$_tests_dir) {
    $_tests_dir = rtrim(sys_get_temp_dir(), '/\\') . '/wordpress-tests-lib';
}

if (!file_exists($_tests_dir . '/includes/functions.php')) {
    echo "Could not find $_tests_dir/includes/functions.php, have you run bin/install-wp-tests.sh ?" . PHP_EOL; // phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped
    exit(1);
}

// Give access to tests_add_filter() function
require_once $_tests_dir . '/includes/functions.php';

/**
 * Manually load BuddyPress for testing
 */
function _manually_load_buddypress() {
    // Load BuddyPress if available
    $buddypress_plugin = dirname(dirname(__DIR__)) . '/wp-content/plugins/buddypress/bp-loader.php';
    
    // Try common BuddyPress locations
    $possible_locations = [
        $buddypress_plugin,
        WP_PLUGIN_DIR . '/buddypress/bp-loader.php',
        ABSPATH . 'wp-content/plugins/buddypress/bp-loader.php',
    ];
    
    foreach ($possible_locations as $location) {
        if (file_exists($location)) {
            require_once $location;
            break;
        }
    }
    
    // Activate BuddyPress components for testing
    if (function_exists('bp_core_install')) {
        // Set up default BuddyPress components
        $active_components = [
            'xprofile' => 1,
            'settings' => 1,
            'friends' => 1,
            'messages' => 1,
            'activity' => 1,
            'notifications' => 1,
            'groups' => 1,
            'members' => 1,
        ];
        
        bp_update_option('bp-active-components', $active_components);
    }
}

/**
 * Set up test user and environment
 */
function _setup_test_environment() {
    // Create test admin user
    $user_id = wp_create_user('testadmin', 'testpass', 'admin@test.local');
    if (!is_wp_error($user_id)) {
        wp_update_user([
            'ID' => $user_id,
            'role' => 'administrator'
        ]);
    }
    
    // Set current user for tests
    wp_set_current_user($user_id);
    
    // Install BuddyPress tables if needed
    if (function_exists('bp_core_install')) {
        bp_core_install();
    }
}

// Load BuddyPress before WordPress test suite
tests_add_filter('muplugins_loaded', '_manually_load_buddypress');
tests_add_filter('wp_install', '_setup_test_environment');

// Start up the WP testing environment
require $_tests_dir . '/includes/bootstrap.php';

// Include our test utilities
require_once __DIR__ . '/includes/BuddyPressTestCase.php';