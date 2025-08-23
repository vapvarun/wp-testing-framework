<?php
/**
 * Cleanup Organizer for WordPress Testing Framework
 * 
 * Identifies and helps clean up unwanted, duplicate, or temporary files
 * Maintains framework organization for optimal AI learning
 */

class CleanupOrganizer {
    
    private $framework_path;
    private $issues_found = [];
    private $cleanup_actions = [];
    
    private $patterns_to_clean = [
        'temp_files' => [
            'pattern' => '/\.(tmp|temp|bak|backup|old|orig|swp)$/i',
            'action' => 'delete',
            'reason' => 'Temporary/backup file'
        ],
        'error_dumps' => [
            'pattern' => '/error-context\.md$/i',
            'action' => 'consolidate',
            'reason' => 'Multiple error context files'
        ],
        'hash_files' => [
            'pattern' => '/^[a-f0-9]{40}\.(json|md)$/i',
            'action' => 'archive',
            'reason' => 'Hash-named file (likely temporary)'
        ],
        'duplicate_json' => [
            'pattern' => '/2d53b86fd532fac5d34ed762b2e15882be06461e\.json/',
            'action' => 'deduplicate',
            'reason' => 'Duplicate JSON file'
        ],
        'empty_files' => [
            'min_size' => 10,
            'action' => 'review',
            'reason' => 'Empty or nearly empty file'
        ],
        'node_artifacts' => [
            'pattern' => '/\.(map|d\.ts|min\.js|min\.css)$/i',
            'action' => 'skip',
            'reason' => 'Build artifact'
        ]
    ];
    
    private $important_paths = [
        '/tools/',
        '/tests/',
        '/reports/',
        '/wp-cli-commands/',
        '/bin/',
        '/examples/'
    ];
    
    public function __construct($framework_path = null) {
        $this->framework_path = $framework_path ?: dirname(dirname(dirname(__FILE__)));
    }
    
    /**
     * Run cleanup analysis
     */
    public function analyze() {
        echo "🔍 Analyzing WordPress Testing Framework for cleanup...\n";
        echo str_repeat("=", 70) . "\n\n";
        
        $this->scan_for_issues();
        $this->identify_duplicates();
        $this->check_organization();
        $this->generate_cleanup_plan();
        
        return $this->cleanup_actions;
    }
    
    /**
     * Scan for issues
     */
    private function scan_for_issues() {
        $iterator = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator($this->framework_path)
        );
        
        foreach ($iterator as $file) {
            if (!$file->isFile()) continue;
            
            $path = $file->getPathname();
            $relative_path = str_replace($this->framework_path . '/', '', $path);
            
            // Skip vendor and node_modules
            if (strpos($relative_path, 'vendor/') !== false ||
                strpos($relative_path, 'node_modules/') !== false ||
                strpos($relative_path, '.git/') !== false) {
                continue;
            }
            
            // Check patterns
            foreach ($this->patterns_to_clean as $type => $config) {
                if (isset($config['pattern'])) {
                    if (preg_match($config['pattern'], basename($path))) {
                        $this->issues_found[] = [
                            'type' => $type,
                            'file' => $relative_path,
                            'reason' => $config['reason'],
                            'action' => $config['action'],
                            'size' => filesize($path)
                        ];
                    }
                }
            }
            
            // Check for empty files
            if (filesize($path) < 10) {
                $this->issues_found[] = [
                    'type' => 'empty_file',
                    'file' => $relative_path,
                    'reason' => 'Empty or nearly empty file',
                    'action' => 'review',
                    'size' => filesize($path)
                ];
            }
        }
    }
    
    /**
     * Identify duplicate files
     */
    private function identify_duplicates() {
        $file_hashes = [];
        $duplicates = [];
        
        $iterator = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator($this->framework_path)
        );
        
        foreach ($iterator as $file) {
            if (!$file->isFile()) continue;
            
            $path = $file->getPathname();
            $relative_path = str_replace($this->framework_path . '/', '', $path);
            
            // Skip large files and dependencies
            if (filesize($path) > 1000000 ||
                strpos($relative_path, 'vendor/') !== false ||
                strpos($relative_path, 'node_modules/') !== false) {
                continue;
            }
            
            // Calculate file hash
            $hash = md5_file($path);
            
            if (isset($file_hashes[$hash])) {
                $duplicates[] = [
                    'original' => $file_hashes[$hash],
                    'duplicate' => $relative_path,
                    'hash' => $hash
                ];
            } else {
                $file_hashes[$hash] = $relative_path;
            }
        }
        
        foreach ($duplicates as $dup) {
            $this->issues_found[] = [
                'type' => 'duplicate',
                'file' => $dup['duplicate'],
                'reason' => "Duplicate of {$dup['original']}",
                'action' => 'delete',
                'size' => filesize($this->framework_path . '/' . $dup['duplicate'])
            ];
        }
    }
    
    /**
     * Check organization structure
     */
    private function check_organization() {
        // Check for files in root that should be organized
        $root_files = scandir($this->framework_path);
        
        foreach ($root_files as $file) {
            if ($file === '.' || $file === '..' || is_dir($this->framework_path . '/' . $file)) {
                continue;
            }
            
            $ext = pathinfo($file, PATHINFO_EXTENSION);
            
            // Identify misplaced files
            if (in_array($ext, ['php', 'mjs', 'js']) && 
                !in_array($file, ['composer.json', 'package.json', 'package-lock.json'])) {
                
                $suggested_location = $this->suggest_location($file);
                if ($suggested_location) {
                    $this->issues_found[] = [
                        'type' => 'misplaced',
                        'file' => $file,
                        'reason' => "Should be in {$suggested_location}",
                        'action' => 'move',
                        'size' => filesize($this->framework_path . '/' . $file)
                    ];
                }
            }
        }
    }
    
    /**
     * Suggest better location for file
     */
    private function suggest_location($filename) {
        if (strpos($filename, 'test') !== false) return '/tests/';
        if (strpos($filename, 'scan') !== false) return '/tools/scanners/';
        if (strpos($filename, 'generate') !== false) return '/tools/generators/';
        if (strpos($filename, 'command') !== false) return '/wp-cli-commands/';
        if (strpos($filename, 'report') !== false) return '/reports/';
        return null;
    }
    
    /**
     * Generate cleanup plan
     */
    private function generate_cleanup_plan() {
        // Group issues by action
        $by_action = [];
        foreach ($this->issues_found as $issue) {
            $by_action[$issue['action']][] = $issue;
        }
        
        // Generate actions
        foreach ($by_action as $action => $files) {
            $this->cleanup_actions[$action] = [
                'action' => $action,
                'files' => $files,
                'count' => count($files),
                'total_size' => array_sum(array_column($files, 'size'))
            ];
        }
    }
    
    /**
     * Display cleanup report
     */
    public function display_report() {
        echo "📋 CLEANUP REPORT\n";
        echo str_repeat("=", 70) . "\n\n";
        
        if (empty($this->issues_found)) {
            echo "✅ No cleanup issues found! Framework is well organized.\n";
            return;
        }
        
        echo "Found " . count($this->issues_found) . " issues to address:\n\n";
        
        // Display by action type
        foreach ($this->cleanup_actions as $action => $data) {
            $size_kb = round($data['total_size'] / 1024, 2);
            echo "### " . ucfirst($action) . " ({$data['count']} files, {$size_kb} KB)\n";
            
            foreach (array_slice($data['files'], 0, 5) as $file) {
                echo "  - {$file['file']}\n";
                echo "    Reason: {$file['reason']}\n";
            }
            
            if ($data['count'] > 5) {
                echo "  ... and " . ($data['count'] - 5) . " more\n";
            }
            echo "\n";
        }
    }
    
    /**
     * Generate cleanup script
     */
    public function generate_cleanup_script($output_file = null) {
        if (!$output_file) {
            $output_file = $this->framework_path . '/cleanup-script.sh';
        }
        
        $script = "#!/bin/bash\n";
        $script .= "# WordPress Testing Framework Cleanup Script\n";
        $script .= "# Generated: " . date('Y-m-d H:i:s') . "\n\n";
        
        $script .= "echo '🧹 Starting WordPress Testing Framework cleanup...'\n\n";
        
        // Create archive directory
        $script .= "# Create archive directory\n";
        $script .= "mkdir -p archive/cleanup-" . date('Y-m-d') . "\n\n";
        
        // Generate commands by action
        if (isset($this->cleanup_actions['delete'])) {
            $script .= "# Delete temporary/unwanted files\n";
            foreach ($this->cleanup_actions['delete']['files'] as $file) {
                $script .= "rm -f \"{$file['file']}\"\n";
            }
            $script .= "\n";
        }
        
        if (isset($this->cleanup_actions['archive'])) {
            $script .= "# Archive hash-named files\n";
            foreach ($this->cleanup_actions['archive']['files'] as $file) {
                $script .= "mv \"{$file['file']}\" archive/cleanup-" . date('Y-m-d') . "/\n";
            }
            $script .= "\n";
        }
        
        if (isset($this->cleanup_actions['move'])) {
            $script .= "# Move misplaced files\n";
            foreach ($this->cleanup_actions['move']['files'] as $file) {
                $suggested = $this->suggest_location($file['file']);
                $script .= "# mv \"{$file['file']}\" \"{$suggested}\"\n";
            }
            $script .= "\n";
        }
        
        $script .= "echo '✅ Cleanup complete!'\n";
        
        file_put_contents($output_file, $script);
        chmod($output_file, 0755);
        
        echo "📝 Cleanup script generated: {$output_file}\n";
        
        return $output_file;
    }
    
    /**
     * Export cleanup report as JSON
     */
    public function export_json($filename = null) {
        if (!$filename) {
            $filename = $this->framework_path . '/cleanup-report.json';
        }
        
        $report = [
            'generated' => date('Y-m-d H:i:s'),
            'issues_found' => count($this->issues_found),
            'cleanup_actions' => $this->cleanup_actions,
            'detailed_issues' => $this->issues_found
        ];
        
        file_put_contents($filename, json_encode($report, JSON_PRETTY_PRINT));
        
        echo "📄 Cleanup report exported: {$filename}\n";
        
        return $filename;
    }
}

// Run if called directly
if (php_sapi_name() === 'cli') {
    $cleaner = new CleanupOrganizer();
    $cleaner->analyze();
    $cleaner->display_report();
    $cleaner->generate_cleanup_script();
    $cleaner->export_json();
}