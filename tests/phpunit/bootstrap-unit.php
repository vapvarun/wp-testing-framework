<?php
/**
 * PHPUnit bootstrap file for BuddyNext unit tests (no WordPress required)
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
define( 'BUDDYNEXT_UNIT_TESTS', true );

echo "BuddyNext Unit Test environment loaded (no WordPress).\n";