<?php
/**
 * Report Organizer for WP Testing Framework
 * 
 * Ensures all reports are saved in plugin-specific folders
 */

namespace WPTestingFramework\Utilities;

class ReportOrganizer {
    
    private $reports_base_path;
    private $plugin_name;
    
    public function __construct($plugin_name = null) {
        $this->reports_base_path = '/Users/varundubey/Local Sites/buddynext/app/public/wp-testing-framework/reports';
        $this->plugin_name = $plugin_name;
    }
    
    /**
     * Get the appropriate report path for a plugin
     */
    public function get_report_path($plugin_name = null) {
        $plugin = $plugin_name ?: $this->plugin_name;
        
        if (!$plugin) {
            throw new \Exception('Plugin name must be specified');
        }
        
        // Standardize plugin name (remove spaces, lowercase)
        $plugin_folder = strtolower(str_replace(' ', '-', $plugin));
        
        $plugin_path = $this->reports_base_path . '/' . $plugin_folder;
        
        // Create directory if it doesn't exist
        if (!file_exists($plugin_path)) {
            mkdir($plugin_path, 0755, true);
            echo "Created report directory: $plugin_path\n";
        }
        
        return $plugin_path;
    }
    
    /**
     * Save report with proper organization
     */
    public function save_report($content, $filename, $plugin_name = null) {
        $report_path = $this->get_report_path($plugin_name);
        $full_path = $report_path . '/' . $filename;
        
        if (file_put_contents($full_path, $content)) {
            echo "✅ Report saved: $full_path\n";
            return $full_path;
        }
        
        return false;
    }
    
    /**
     * Organize existing reports
     */
    public function organize_existing_reports() {
        $files = glob($this->reports_base_path . '/*.*');
        $organized = [];
        
        foreach ($files as $file) {
            $filename = basename($file);
            
            // Skip if already in a subdirectory
            if (strpos($file, $this->reports_base_path . '/') !== false && 
                count(explode('/', str_replace($this->reports_base_path . '/', '', $file))) > 1) {
                continue;
            }
            
            // Detect plugin from filename
            $plugin = $this->detect_plugin_from_filename($filename);
            
            if ($plugin) {
                $new_path = $this->get_report_path($plugin) . '/' . $filename;
                
                if (rename($file, $new_path)) {
                    $organized[$plugin][] = $filename;
                    echo "Moved: $filename -> $plugin/$filename\n";
                }
            }
        }
        
        return $organized;
    }
    
    /**
     * Detect plugin name from filename
     */
    private function detect_plugin_from_filename($filename) {
        $patterns = [
            'buddypress' => '/^(buddypress|bp-)/i',
            'woocommerce' => '/^(woocommerce|wc-)/i',
            'elementor' => '/^elementor/i',
            'yoast' => '/^(yoast|seo)/i',
            'jetpack' => '/^jetpack/i',
            'acf' => '/^(acf|advanced-custom)/i',
            'wpforms' => '/^wpforms/i',
            'contact-form-7' => '/^(cf7|contact-form)/i'
        ];
        
        foreach ($patterns as $plugin => $pattern) {
            if (preg_match($pattern, $filename)) {
                return $plugin;
            }
        }
        
        return null;
    }
    
    /**
     * Create standard report structure for a plugin
     */
    public function create_plugin_report_structure($plugin_name) {
        $plugin_path = $this->get_report_path($plugin_name);
        
        $subdirs = [
            'analysis',      // Code analysis reports
            'coverage',      // Test coverage reports
            'execution',     // Test execution results
            'api',          // API testing reports
            'security',     // Security scan reports
            'performance',  // Performance test reports
            'integration'   // Integration test reports
        ];
        
        foreach ($subdirs as $subdir) {
            $full_path = $plugin_path . '/' . $subdir;
            if (!file_exists($full_path)) {
                mkdir($full_path, 0755, true);
                echo "Created: $full_path\n";
            }
        }
        
        // Create index file
        $this->create_plugin_index($plugin_name);
        
        return $plugin_path;
    }
    
    /**
     * Create index file for plugin reports
     */
    private function create_plugin_index($plugin_name) {
        $plugin_path = $this->get_report_path($plugin_name);
        $index_content = $this->generate_index_content($plugin_name, $plugin_path);
        
        file_put_contents($plugin_path . '/README.md', $index_content);
        echo "Created index: $plugin_path/README.md\n";
    }
    
    /**
     * Generate index content for plugin
     */
    private function generate_index_content($plugin_name, $plugin_path) {
        $content = "# $plugin_name Test Reports\n\n";
        $content .= "Generated: " . date('Y-m-d H:i:s') . "\n\n";
        
        $content .= "## Report Categories\n\n";
        $content .= "- **analysis/** - Code analysis and scanning reports\n";
        $content .= "- **coverage/** - Test coverage reports\n";
        $content .= "- **execution/** - Test execution results\n";
        $content .= "- **api/** - REST API testing reports\n";
        $content .= "- **security/** - Security vulnerability reports\n";
        $content .= "- **performance/** - Performance testing reports\n";
        $content .= "- **integration/** - Integration test reports\n\n";
        
        // List existing reports
        $content .= "## Available Reports\n\n";
        
        $reports = glob($plugin_path . '/**/*.{json,md,html,xml}', GLOB_BRACE);
        foreach ($reports as $report) {
            $relative = str_replace($plugin_path . '/', '', $report);
            $content .= "- `$relative`\n";
        }
        
        return $content;
    }
    
    /**
     * Get report statistics for a plugin
     */
    public function get_plugin_report_stats($plugin_name) {
        $plugin_path = $this->get_report_path($plugin_name);
        
        $stats = [
            'total_reports' => 0,
            'by_type' => [],
            'by_category' => [],
            'latest_report' => null,
            'total_size' => 0
        ];
        
        $reports = glob($plugin_path . '/**/*.{json,md,html,xml}', GLOB_BRACE);
        
        foreach ($reports as $report) {
            $stats['total_reports']++;
            
            // Get file extension
            $ext = pathinfo($report, PATHINFO_EXTENSION);
            $stats['by_type'][$ext] = ($stats['by_type'][$ext] ?? 0) + 1;
            
            // Get category (subdirectory)
            $relative = str_replace($plugin_path . '/', '', $report);
            $parts = explode('/', $relative);
            if (count($parts) > 1) {
                $category = $parts[0];
                $stats['by_category'][$category] = ($stats['by_category'][$category] ?? 0) + 1;
            }
            
            // Track latest report
            $mtime = filemtime($report);
            if (!$stats['latest_report'] || $mtime > $stats['latest_report']['time']) {
                $stats['latest_report'] = [
                    'file' => basename($report),
                    'time' => $mtime,
                    'date' => date('Y-m-d H:i:s', $mtime)
                ];
            }
            
            // Add to total size
            $stats['total_size'] += filesize($report);
        }
        
        // Convert size to human readable
        $stats['total_size_readable'] = $this->format_bytes($stats['total_size']);
        
        return $stats;
    }
    
    /**
     * Format bytes to human readable
     */
    private function format_bytes($bytes, $precision = 2) {
        $units = ['B', 'KB', 'MB', 'GB'];
        
        for ($i = 0; $bytes > 1024 && $i < count($units) - 1; $i++) {
            $bytes /= 1024;
        }
        
        return round($bytes, $precision) . ' ' . $units[$i];
    }
}

// Execute organization if run directly
if (php_sapi_name() === 'cli' && basename(__FILE__) === basename($argv[0] ?? '')) {
    echo "Report Organizer for WP Testing Framework\n";
    echo "=========================================\n\n";
    
    $organizer = new ReportOrganizer();
    
    // Organize existing reports
    echo "Organizing existing reports...\n";
    $organized = $organizer->organize_existing_reports();
    
    if (!empty($organized)) {
        echo "\nOrganized reports by plugin:\n";
        foreach ($organized as $plugin => $files) {
            echo "- $plugin: " . count($files) . " files\n";
        }
    }
    
    // Create structure for BuddyPress
    echo "\nCreating report structure for BuddyPress...\n";
    $organizer->create_plugin_report_structure('buddypress');
    
    // Get stats
    echo "\nBuddyPress Report Statistics:\n";
    $stats = $organizer->get_plugin_report_stats('buddypress');
    echo "- Total Reports: " . $stats['total_reports'] . "\n";
    echo "- Total Size: " . $stats['total_size_readable'] . "\n";
    if ($stats['latest_report']) {
        echo "- Latest Report: " . $stats['latest_report']['file'] . " (" . $stats['latest_report']['date'] . ")\n";
    }
}