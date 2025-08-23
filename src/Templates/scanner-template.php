<?php
/**
 * Universal Scanner Template for WP Testing Framework
 * 
 * Template for creating plugin-specific scanners with proper report organization
 */

namespace WPTestingFramework\Scanners;

require_once __DIR__ . '/../utilities/report-organizer.php';
use WPTestingFramework\Utilities\ReportOrganizer;

abstract class UniversalPluginScanner {
    
    protected $plugin_name;
    protected $plugin_path;
    protected $results = [];
    protected $report_organizer;
    
    public function __construct($plugin_name, $plugin_path) {
        $this->plugin_name = $plugin_name;
        $this->plugin_path = $plugin_path;
        $this->report_organizer = new ReportOrganizer($plugin_name);
    }
    
    /**
     * Main scan method - must be implemented by child classes
     */
    abstract public function scan();
    
    /**
     * Save scan results with proper organization
     */
    protected function save_results($report_type = 'analysis') {
        $timestamp = date('Y-m-d_H-i-s');
        $plugin_folder = strtolower(str_replace(' ', '-', $this->plugin_name));
        
        // Determine subdirectory based on report type
        $subdirs = [
            'component' => 'analysis',
            'api' => 'api',
            'security' => 'security',
            'performance' => 'performance',
            'coverage' => 'coverage',
            'integration' => 'integration',
            'execution' => 'execution'
        ];
        
        $subdir = $subdirs[$report_type] ?? 'analysis';
        
        // Get proper report path
        $report_path = $this->report_organizer->get_report_path() . '/' . $subdir;
        
        // Create subdirectory if needed
        if (!file_exists($report_path)) {
            mkdir($report_path, 0755, true);
        }
        
        // Save JSON report
        $json_filename = "{$plugin_folder}-{$report_type}-{$timestamp}.json";
        $json_path = $report_path . '/' . $json_filename;
        file_put_contents($json_path, json_encode($this->results, JSON_PRETTY_PRINT));
        echo "✅ JSON report saved: $json_path\n";
        
        // Save Markdown report
        $md_content = $this->generate_markdown_report();
        $md_filename = "{$plugin_folder}-{$report_type}-{$timestamp}.md";
        $md_path = $report_path . '/' . $md_filename;
        file_put_contents($md_path, $md_content);
        echo "✅ Markdown report saved: $md_path\n";
        
        // Update plugin index
        $this->update_plugin_index();
        
        return [
            'json' => $json_path,
            'markdown' => $md_path
        ];
    }
    
    /**
     * Generate markdown report - can be overridden by child classes
     */
    protected function generate_markdown_report() {
        $md = "# {$this->plugin_name} Scan Report\n\n";
        $md .= "Generated: " . date('Y-m-d H:i:s') . "\n\n";
        
        // Add results summary
        if (!empty($this->results)) {
            $md .= "## Results Summary\n\n";
            $md .= "```json\n";
            $md .= json_encode($this->results, JSON_PRETTY_PRINT);
            $md .= "\n```\n";
        }
        
        return $md;
    }
    
    /**
     * Update the plugin's report index
     */
    protected function update_plugin_index() {
        $plugin_path = $this->report_organizer->get_report_path();
        $index_path = $plugin_path . '/README.md';
        
        $content = "# {$this->plugin_name} Test Reports\n\n";
        $content .= "Last Updated: " . date('Y-m-d H:i:s') . "\n\n";
        
        // Get report statistics
        $stats = $this->report_organizer->get_plugin_report_stats($this->plugin_name);
        
        $content .= "## Statistics\n\n";
        $content .= "- **Total Reports**: {$stats['total_reports']}\n";
        $content .= "- **Total Size**: {$stats['total_size_readable']}\n";
        
        if ($stats['latest_report']) {
            $content .= "- **Latest Report**: {$stats['latest_report']['file']} ({$stats['latest_report']['date']})\n";
        }
        
        $content .= "\n## Report Categories\n\n";
        
        // List reports by category
        $categories = ['analysis', 'api', 'coverage', 'execution', 'integration', 'performance', 'security'];
        
        foreach ($categories as $category) {
            $cat_path = $plugin_path . '/' . $category;
            if (file_exists($cat_path)) {
                $reports = glob($cat_path . '/*.{json,md,html,xml}', GLOB_BRACE);
                if (!empty($reports)) {
                    $content .= "\n### " . ucfirst($category) . " (" . count($reports) . " reports)\n";
                    foreach ($reports as $report) {
                        $filename = basename($report);
                        $size = $this->format_bytes(filesize($report));
                        $date = date('Y-m-d H:i', filemtime($report));
                        $content .= "- `$filename` ($size, $date)\n";
                    }
                }
            }
        }
        
        file_put_contents($index_path, $content);
    }
    
    /**
     * Format bytes to human readable
     */
    protected function format_bytes($bytes, $precision = 2) {
        $units = ['B', 'KB', 'MB', 'GB'];
        
        for ($i = 0; $bytes > 1024 && $i < count($units) - 1; $i++) {
            $bytes /= 1024;
        }
        
        return round($bytes, $precision) . ' ' . $units[$i];
    }
    
    /**
     * Common scanning utilities
     */
    protected function scan_directory($path, $pattern = '*.php') {
        $files = [];
        $iterator = new \RecursiveIteratorIterator(
            new \RecursiveDirectoryIterator($path, \RecursiveDirectoryIterator::SKIP_DOTS)
        );
        
        foreach ($iterator as $file) {
            if ($file->isFile() && fnmatch($pattern, $file->getFilename())) {
                $files[] = $file->getPathname();
            }
        }
        
        return $files;
    }
    
    /**
     * Extract classes from file
     */
    protected function extract_classes($file_path) {
        $classes = [];
        $content = file_get_contents($file_path);
        
        if (preg_match_all('/class\s+(\w+)/', $content, $matches)) {
            $classes = $matches[1];
        }
        
        return $classes;
    }
    
    /**
     * Extract functions from file
     */
    protected function extract_functions($file_path) {
        $functions = [];
        $content = file_get_contents($file_path);
        
        if (preg_match_all('/function\s+(\w+)\s*\(/', $content, $matches)) {
            $functions = $matches[1];
        }
        
        return $functions;
    }
    
    /**
     * Extract hooks from file
     */
    protected function extract_hooks($file_path) {
        $hooks = [];
        $content = file_get_contents($file_path);
        
        // WordPress hooks
        $hook_patterns = [
            'actions' => '/(?:do_action|add_action)\s*\(\s*[\'"]([^\'"]+)[\'"]/i',
            'filters' => '/(?:apply_filters|add_filter)\s*\(\s*[\'"]([^\'"]+)[\'"]/i'
        ];
        
        foreach ($hook_patterns as $type => $pattern) {
            if (preg_match_all($pattern, $content, $matches)) {
                $hooks[$type] = array_unique($matches[1]);
            }
        }
        
        return $hooks;
    }
}

/**
 * Example implementation for a specific plugin
 */
class ExamplePluginScanner extends UniversalPluginScanner {
    
    public function __construct() {
        $plugin_name = 'Example Plugin';
        $plugin_path = '/path/to/plugin';
        parent::__construct($plugin_name, $plugin_path);
    }
    
    public function scan() {
        echo "Scanning {$this->plugin_name}...\n";
        
        // Implement scanning logic
        $this->results['files'] = $this->scan_directory($this->plugin_path);
        $this->results['total_files'] = count($this->results['files']);
        
        // Save results with proper organization
        $this->save_results('component');
        
        return $this->results;
    }
    
    protected function generate_markdown_report() {
        $md = "# {$this->plugin_name} Component Analysis\n\n";
        $md .= "Generated: " . date('Y-m-d H:i:s') . "\n\n";
        
        $md .= "## Summary\n\n";
        $md .= "- Total Files: {$this->results['total_files']}\n";
        
        return $md;
    }
}