<?php
/**
 * Load WP-CLI Commands for BuddyPress Testing
 * 
 * Add this to wp-config.php or load via mu-plugin:
 * require_once '/path/to/wp-testing-framework/load-wp-cli-commands.php';
 */

if (defined('WP_CLI') && WP_CLI) {
    require_once __DIR__ . '/wp-cli-commands/class-bp-component-scan-command.php';
}