<?php
/**
 * Create Auto-Login URL for WordPress
 * This script creates a temporary auto-login URL that expires after use
 */

// Load WordPress
require_once(dirname(__FILE__) . '/../../wp-load.php');

// Get username from command line or default to admin
$username = $argv[1] ?? 'admin';
$expiry_minutes = $argv[2] ?? 15;

// Check if user exists
$user = get_user_by('login', $username);

if (!$user) {
    // Create admin user if doesn't exist
    $user_id = wp_create_user($username, wp_generate_password(), $username . '@example.com');
    $user = new WP_User($user_id);
    $user->set_role('administrator');
    $user = get_user_by('id', $user_id);
    echo "Created user: $username\n";
}

// Generate a unique token
$token = wp_generate_password(32, false);
$expiry = time() + ($expiry_minutes * 60);

// Store token as transient
set_transient('auto_login_' . $token, $user->ID, $expiry_minutes * 60);

// Generate the auto-login URL
$auto_login_url = add_query_arg(array(
    'auto_login' => $token,
    'redirect_to' => admin_url()
), home_url());

echo "Auto-login URL (expires in {$expiry_minutes} minutes):\n";
echo $auto_login_url . "\n";

// Also add the auto-login handler if not exists
if (!has_action('init', 'handle_auto_login')) {
    // Add to functions.php or mu-plugins
    $mu_plugin = ABSPATH . 'wp-content/mu-plugins/auto-login.php';
    if (!file_exists(dirname($mu_plugin))) {
        mkdir(dirname($mu_plugin), 0755, true);
    }
    
    $handler_code = '<?php
// Auto-login handler
add_action("init", function() {
    if (isset($_GET["auto_login"]) && !is_user_logged_in()) {
        $token = sanitize_text_field($_GET["auto_login"]);
        $user_id = get_transient("auto_login_" . $token);
        
        if ($user_id) {
            // Delete token after use
            delete_transient("auto_login_" . $token);
            
            // Log in the user
            wp_set_current_user($user_id);
            wp_set_auth_cookie($user_id);
            
            // Redirect to intended page
            $redirect = isset($_GET["redirect_to"]) ? $_GET["redirect_to"] : admin_url();
            wp_safe_redirect($redirect);
            exit;
        }
    }
});';
    
    if (!file_exists($mu_plugin)) {
        file_put_contents($mu_plugin, $handler_code);
        echo "Auto-login handler installed\n";
    }
}
?>