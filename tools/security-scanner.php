<?php
/**
 * BuddyPress Security Scanner
 * 
 * Automated security vulnerability scanner for BuddyPress installations
 */

class BuddyPressSecurityScanner
{
    private $results = [];
    private $severity_levels = ['low', 'medium', 'high', 'critical'];
    
    public function __construct()
    {
        $this->results = [
            'vulnerabilities' => [],
            'recommendations' => [],
            'summary' => []
        ];
    }

    /**
     * Run complete security scan
     */
    public function runScan()
    {
        echo "🔍 Starting BuddyPress Security Scan...\n\n";
        
        $this->checkWordPressVersion();
        $this->checkBuddyPressVersion();
        $this->checkFilePermissions();
        $this->checkDatabaseSecurity();
        $this->checkPluginSecurity();
        $this->checkUserSecurity();
        $this->checkConfigurationSecurity();
        $this->checkAPIEndpointSecurity();
        
        $this->generateReport();
    }

    /**
     * Check WordPress version for known vulnerabilities
     */
    private function checkWordPressVersion()
    {
        echo "📋 Checking WordPress version...\n";
        
        $wp_version = get_bloginfo('version');
        $latest_version = $this->getLatestWordPressVersion();
        
        if (version_compare($wp_version, $latest_version, '<')) {
            $this->addVulnerability(
                'Outdated WordPress Version',
                "WordPress {$wp_version} is outdated. Latest version: {$latest_version}",
                'high',
                'Update WordPress to the latest version'
            );
        } else {
            echo "✅ WordPress version {$wp_version} is up to date\n";
        }
    }

    /**
     * Check BuddyPress version
     */
    private function checkBuddyPressVersion()
    {
        echo "📋 Checking BuddyPress version...\n";
        
        if (!function_exists('bp_get_version')) {
            $this->addVulnerability(
                'BuddyPress Not Found',
                'BuddyPress plugin is not active or installed',
                'critical',
                'Install and activate BuddyPress plugin'
            );
            return;
        }
        
        $bp_version = bp_get_version();
        echo "✅ BuddyPress version {$bp_version} detected\n";
        
        // Check for known vulnerable versions
        $vulnerable_versions = ['11.0.0', '10.6.0']; // Example vulnerable versions
        if (in_array($bp_version, $vulnerable_versions)) {
            $this->addVulnerability(
                'Vulnerable BuddyPress Version',
                "BuddyPress {$bp_version} has known security vulnerabilities",
                'critical',
                'Update BuddyPress to the latest secure version'
            );
        }
    }

    /**
     * Check file and directory permissions
     */
    private function checkFilePermissions()
    {
        echo "📋 Checking file permissions...\n";
        
        $critical_files = [
            ABSPATH . 'wp-config.php' => 0644,
            ABSPATH . '.htaccess' => 0644,
            WP_CONTENT_DIR => 0755,
            WP_PLUGIN_DIR => 0755,
        ];
        
        foreach ($critical_files as $file => $recommended_perm) {
            if (file_exists($file)) {
                $current_perm = fileperms($file) & 0777;
                
                if ($current_perm > $recommended_perm) {
                    $this->addVulnerability(
                        'Insecure File Permissions',
                        "File {$file} has permissions " . decoct($current_perm) . 
                        " (recommended: " . decoct($recommended_perm) . ")",
                        'medium',
                        "Change file permissions to " . decoct($recommended_perm)
                    );
                }
            }
        }
        
        echo "✅ File permissions checked\n";
    }

    /**
     * Check database security
     */
    private function checkDatabaseSecurity()
    {
        echo "📋 Checking database security...\n";
        
        global $wpdb;
        
        // Check for default table prefix
        if ($wpdb->prefix === 'wp_') {
            $this->addVulnerability(
                'Default Database Prefix',
                'Using default "wp_" table prefix makes database more vulnerable to attacks',
                'medium',
                'Change database table prefix to something unique'
            );
        }
        
        // Check for admin user with ID 1
        $admin_user = get_user_by('id', 1);
        if ($admin_user && in_array('administrator', $admin_user->roles)) {
            if ($admin_user->user_login === 'admin') {
                $this->addVulnerability(
                    'Default Admin Username',
                    'Admin user has default username "admin"',
                    'medium',
                    'Change admin username to something less predictable'
                );
            }
        }
        
        echo "✅ Database security checked\n";
    }

    /**
     * Check plugin security
     */
    private function checkPluginSecurity()
    {
        echo "📋 Checking plugin security...\n";
        
        $active_plugins = get_option('active_plugins');
        $outdated_plugins = [];
        $vulnerable_plugins = $this->getKnownVulnerablePlugins();
        
        foreach ($active_plugins as $plugin) {
            $plugin_data = get_plugin_data(WP_PLUGIN_DIR . '/' . $plugin);
            $plugin_name = $plugin_data['Name'];
            
            // Check for known vulnerable plugins
            if (isset($vulnerable_plugins[$plugin_name])) {
                $this->addVulnerability(
                    'Vulnerable Plugin',
                    "Plugin {$plugin_name} has known security vulnerabilities",
                    'high',
                    'Update or replace the vulnerable plugin'
                );
            }
        }
        
        echo "✅ Plugin security checked\n";
    }

    /**
     * Check user security
     */
    private function checkUserSecurity()
    {
        echo "📋 Checking user security...\n";
        
        // Check for weak admin passwords (simplified check)
        $admin_users = get_users(['role' => 'administrator']);
        
        foreach ($admin_users as $admin) {
            // Check for common weak usernames
            $weak_usernames = ['admin', 'administrator', 'root', 'test'];
            if (in_array($admin->user_login, $weak_usernames)) {
                $this->addVulnerability(
                    'Weak Admin Username',
                    "Admin user '{$admin->user_login}' uses a predictable username",
                    'medium',
                    'Use a unique, non-predictable admin username'
                );
            }
            
            // Check for users without strong password enforcement
            if (!get_user_meta($admin->ID, 'force_strong_password', true)) {
                $this->addRecommendation(
                    'Enable strong password enforcement for admin users'
                );
            }
        }
        
        echo "✅ User security checked\n";
    }

    /**
     * Check configuration security
     */
    private function checkConfigurationSecurity()
    {
        echo "📋 Checking configuration security...\n";
        
        // Check debug settings
        if (defined('WP_DEBUG') && WP_DEBUG) {
            $this->addVulnerability(
                'Debug Mode Enabled',
                'WP_DEBUG is enabled in production',
                'low',
                'Disable WP_DEBUG in production environment'
            );
        }
        
        // Check file editing
        if (!defined('DISALLOW_FILE_EDIT') || !DISALLOW_FILE_EDIT) {
            $this->addVulnerability(
                'File Editing Enabled',
                'WordPress file editing is not disabled',
                'medium',
                'Add define("DISALLOW_FILE_EDIT", true); to wp-config.php'
            );
        }
        
        // Check automatic updates
        if (defined('AUTOMATIC_UPDATER_DISABLED') && AUTOMATIC_UPDATER_DISABLED) {
            $this->addRecommendation(
                'Consider enabling automatic security updates'
            );
        }
        
        echo "✅ Configuration security checked\n";
    }

    /**
     * Check API endpoint security
     */
    private function checkAPIEndpointSecurity()
    {
        echo "📋 Checking API endpoint security...\n";
        
        // Check if REST API is properly secured
        $rest_endpoints = [
            '/wp-json/wp/v2/users',
            '/wp-json/buddypress/v1/members',
            '/wp-json/buddypress/v1/groups',
        ];
        
        foreach ($rest_endpoints as $endpoint) {
            // Simulate unauthorized request
            $response = wp_remote_get(home_url($endpoint));
            
            if (!is_wp_error($response)) {
                $status_code = wp_remote_retrieve_response_code($response);
                
                if ($status_code === 200) {
                    $this->addVulnerability(
                        'Unsecured API Endpoint',
                        "Endpoint {$endpoint} is accessible without authentication",
                        'medium',
                        'Implement proper authentication for sensitive API endpoints'
                    );
                }
            }
        }
        
        echo "✅ API endpoint security checked\n";
    }

    /**
     * Add vulnerability to results
     */
    private function addVulnerability($title, $description, $severity, $recommendation)
    {
        $this->results['vulnerabilities'][] = [
            'title' => $title,
            'description' => $description,
            'severity' => $severity,
            'recommendation' => $recommendation,
            'timestamp' => current_time('mysql')
        ];
    }

    /**
     * Add recommendation to results
     */
    private function addRecommendation($recommendation)
    {
        $this->results['recommendations'][] = $recommendation;
    }

    /**
     * Generate security report
     */
    private function generateReport()
    {
        echo "\n🔍 SECURITY SCAN COMPLETE\n";
        echo str_repeat("=", 50) . "\n\n";
        
        $vulnerabilities = $this->results['vulnerabilities'];
        $total_vulns = count($vulnerabilities);
        
        // Count by severity
        $severity_counts = array_fill_keys($this->severity_levels, 0);
        foreach ($vulnerabilities as $vuln) {
            $severity_counts[$vuln['severity']]++;
        }
        
        // Summary
        echo "📊 SUMMARY:\n";
        echo "Total vulnerabilities found: {$total_vulns}\n";
        foreach ($this->severity_levels as $level) {
            $count = $severity_counts[$level];
            if ($count > 0) {
                $icon = $this->getSeverityIcon($level);
                echo "{$icon} {$level}: {$count}\n";
            }
        }
        echo "\n";
        
        // Detailed vulnerabilities
        if ($total_vulns > 0) {
            echo "🚨 VULNERABILITIES:\n";
            echo str_repeat("-", 30) . "\n";
            
            foreach ($vulnerabilities as $i => $vuln) {
                $icon = $this->getSeverityIcon($vuln['severity']);
                echo ($i + 1) . ". {$icon} {$vuln['title']} [{$vuln['severity']}]\n";
                echo "   Description: {$vuln['description']}\n";
                echo "   Recommendation: {$vuln['recommendation']}\n\n";
            }
        }
        
        // Recommendations
        if (!empty($this->results['recommendations'])) {
            echo "💡 RECOMMENDATIONS:\n";
            echo str_repeat("-", 30) . "\n";
            foreach ($this->results['recommendations'] as $i => $rec) {
                echo ($i + 1) . ". {$rec}\n";
            }
            echo "\n";
        }
        
        // Save report to file
        $report_data = [
            'scan_date' => current_time('mysql'),
            'wordpress_version' => get_bloginfo('version'),
            'buddypress_version' => function_exists('bp_get_version') ? bp_get_version() : 'Not installed',
            'results' => $this->results
        ];
        
        $report_file = WP_CONTENT_DIR . '/uploads/security-scan-' . date('Y-m-d-H-i-s') . '.json';
        file_put_contents($report_file, json_encode($report_data, JSON_PRETTY_PRINT));
        
        echo "📄 Report saved to: {$report_file}\n";
    }

    /**
     * Get severity icon
     */
    private function getSeverityIcon($severity)
    {
        $icons = [
            'low' => '🟡',
            'medium' => '🟠', 
            'high' => '🔴',
            'critical' => '💀'
        ];
        
        return $icons[$severity] ?? '⚪';
    }

    /**
     * Get latest WordPress version (simplified)
     */
    private function getLatestWordPressVersion()
    {
        // In real implementation, this would check WordPress.org API
        return '6.4.2'; // Example latest version
    }

    /**
     * Get known vulnerable plugins (simplified)
     */
    private function getKnownVulnerablePlugins()
    {
        return [
            'old-plugin' => ['version' => '1.0', 'vulnerability' => 'XSS'],
            // In real implementation, this would be updated from vulnerability database
        ];
    }
}

// Run scanner if called directly
if (defined('WP_CLI') && WP_CLI) {
    WP_CLI::add_command('bp security-scan', function() {
        $scanner = new BuddyPressSecurityScanner();
        $scanner->runScan();
    });
} elseif (php_sapi_name() === 'cli') {
    // Load WordPress if running from command line
    if (file_exists('wp-config.php')) {
        require_once 'wp-config.php';
        $scanner = new BuddyPressSecurityScanner();
        $scanner->runScan();
    } else {
        echo "Error: WordPress installation not found\n";
        exit(1);
    }
}