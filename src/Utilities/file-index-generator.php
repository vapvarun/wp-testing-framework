<?php
/**
 * File Index Generator for WordPress Testing Framework
 * 
 * Automatically generates and updates the FILE-INDEX.md with all framework files
 * Helps maintain organization and provides AI-readable documentation
 */

class FileIndexGenerator {
    
    private $framework_path;
    private $exclude_paths = [
        'node_modules',
        'vendor',
        '.git',
        '.cache',
        'coverage',
        'dist',
        'build'
    ];
    
    private $file_categories = [
        'tools' => [
            'path' => '/tools/',
            'extensions' => ['php', 'mjs', 'js'],
            'priority' => 'Critical'
        ],
        'tests' => [
            'path' => '/tests/',
            'extensions' => ['php', 'js', 'json'],
            'priority' => 'High'
        ],
        'reports' => [
            'path' => '/reports/',
            'extensions' => ['md', 'json'],
            'priority' => 'High'
        ],
        'commands' => [
            'path' => '/wp-cli-commands/',
            'extensions' => ['php'],
            'priority' => 'High'
        ],
        'config' => [
            'path' => '/',
            'extensions' => ['json', 'xml', 'yml', 'yaml'],
            'priority' => 'Medium'
        ],
        'documentation' => [
            'path' => '/',
            'extensions' => ['md'],
            'priority' => 'Medium'
        ]
    ];
    
    private $files_index = [];
    private $statistics = [
        'total_files' => 0,
        'by_extension' => [],
        'by_category' => [],
        'ai_ready' => 0,
        'active' => 0,
        'needs_update' => 0,
        'deprecated' => 0
    ];
    
    public function __construct($framework_path = null) {
        $this->framework_path = $framework_path ?: dirname(dirname(dirname(__FILE__)));
    }
    
    /**
     * Generate the file index
     */
    public function generate() {
        echo "🔍 Scanning WordPress Testing Framework files...\n";
        
        // Scan all files
        $this->scan_directory($this->framework_path);
        
        // Analyze files
        $this->analyze_files();
        
        // Generate index markdown
        $index_content = $this->generate_markdown();
        
        // Save index
        $index_file = $this->framework_path . '/FILE-INDEX.md';
        file_put_contents($index_file, $index_content);
        
        echo "✅ File index generated: {$index_file}\n";
        echo "📊 Total files indexed: {$this->statistics['total_files']}\n";
        
        return $this->files_index;
    }
    
    /**
     * Scan directory recursively
     */
    private function scan_directory($path, $relative_path = '') {
        if (!is_dir($path)) {
            return;
        }
        
        $items = scandir($path);
        
        foreach ($items as $item) {
            if ($item === '.' || $item === '..') {
                continue;
            }
            
            $full_path = $path . '/' . $item;
            $rel_path = $relative_path ? $relative_path . '/' . $item : $item;
            
            // Skip excluded paths
            foreach ($this->exclude_paths as $exclude) {
                if (strpos($rel_path, $exclude) !== false) {
                    continue 2;
                }
            }
            
            if (is_dir($full_path)) {
                $this->scan_directory($full_path, $rel_path);
            } else {
                $this->index_file($full_path, $rel_path);
            }
        }
    }
    
    /**
     * Index a single file
     */
    private function index_file($full_path, $relative_path) {
        $info = pathinfo($relative_path);
        $extension = isset($info['extension']) ? strtolower($info['extension']) : '';
        
        // Skip non-relevant files
        $relevant_extensions = ['php', 'js', 'mjs', 'json', 'md', 'xml', 'yml', 'yaml', 'sh'];
        if (!in_array($extension, $relevant_extensions)) {
            return;
        }
        
        $file_data = [
            'path' => $relative_path,
            'name' => $info['basename'],
            'extension' => $extension,
            'size' => filesize($full_path),
            'modified' => filemtime($full_path),
            'category' => $this->categorize_file($relative_path, $extension),
            'purpose' => $this->determine_purpose($relative_path, $full_path),
            'status' => $this->determine_status($relative_path, $full_path),
            'priority' => $this->determine_priority($relative_path),
            'ai_ready' => $this->is_ai_ready($extension)
        ];
        
        $this->files_index[] = $file_data;
        $this->statistics['total_files']++;
        
        // Update statistics
        if (!isset($this->statistics['by_extension'][$extension])) {
            $this->statistics['by_extension'][$extension] = 0;
        }
        $this->statistics['by_extension'][$extension]++;
        
        if ($file_data['ai_ready']) {
            $this->statistics['ai_ready']++;
        }
    }
    
    /**
     * Categorize file based on path and extension
     */
    private function categorize_file($path, $extension) {
        foreach ($this->file_categories as $category => $config) {
            if (strpos($path, $config['path']) !== false) {
                if (in_array($extension, $config['extensions'])) {
                    return $category;
                }
            }
        }
        
        // Default categorization by extension
        if ($extension === 'md') return 'documentation';
        if ($extension === 'json' || $extension === 'xml') return 'config';
        if ($extension === 'php') return 'tools';
        if ($extension === 'js' || $extension === 'mjs') return 'tests';
        
        return 'other';
    }
    
    /**
     * Determine file purpose from name and content
     */
    private function determine_purpose($path, $full_path) {
        $name = basename($path);
        
        // Common patterns
        if (strpos($name, 'scanner') !== false) return 'Code scanner';
        if (strpos($name, 'generator') !== false) return 'Test generator';
        if (strpos($name, 'executor') !== false) return 'Test executor';
        if (strpos($name, 'reporter') !== false) return 'Report generator';
        if (strpos($name, 'test') !== false) return 'Test file';
        if (strpos($name, 'spec') !== false) return 'Test specification';
        if (strpos($name, 'config') !== false) return 'Configuration';
        if (strpos($name, 'command') !== false) return 'WP-CLI command';
        if (strpos($name, 'README') !== false) return 'Documentation';
        if (strpos($name, 'index') !== false) return 'Index file';
        
        // Check first few lines of file for description
        if (file_exists($full_path)) {
            $content = file_get_contents($full_path, false, null, 0, 500);
            
            if (preg_match('/\* ([A-Z][^*\n]+)/', $content, $matches)) {
                return trim($matches[1]);
            }
            
            if (preg_match('/\/\/ ([A-Z][^\n]+)/', $content, $matches)) {
                return trim($matches[1]);
            }
        }
        
        return 'Framework file';
    }
    
    /**
     * Determine file status
     */
    private function determine_status($path, $full_path) {
        $name = basename($path);
        
        // Check if file is new (created in last 24 hours)
        if (filemtime($full_path) > (time() - 86400)) {
            return '🆕 New';
        }
        
        // Check for common deprecated patterns
        if (strpos($name, 'old') !== false || 
            strpos($name, 'deprecated') !== false ||
            strpos($name, 'backup') !== false) {
            return '❌ Deprecated';
        }
        
        // Check if file is empty
        if (filesize($full_path) < 10) {
            return '⚠️ Empty';
        }
        
        // Check for TODO comments
        if (file_exists($full_path)) {
            $content = file_get_contents($full_path, false, null, 0, 1000);
            if (stripos($content, 'TODO') !== false || 
                stripos($content, 'FIXME') !== false) {
                return '⚠️ Needs Update';
            }
        }
        
        return '✅ Active';
    }
    
    /**
     * Determine file priority
     */
    private function determine_priority($path) {
        $name = basename($path);
        
        // Critical files
        if (strpos($name, 'index') !== false ||
            strpos($name, 'scanner') !== false ||
            strpos($name, 'package.json') !== false ||
            strpos($name, 'composer.json') !== false) {
            return 'Critical';
        }
        
        // High priority
        if (strpos($path, '/tools/') !== false ||
            strpos($path, '/tests/') !== false ||
            strpos($name, 'command') !== false) {
            return 'High';
        }
        
        // Medium priority
        if (strpos($path, '/reports/') !== false ||
            strpos($name, 'config') !== false) {
            return 'Medium';
        }
        
        return 'Low';
    }
    
    /**
     * Check if file is AI-ready
     */
    private function is_ai_ready($extension) {
        $ai_ready_extensions = ['json', 'md', 'php', 'js', 'mjs', 'xml', 'yml', 'yaml'];
        return in_array($extension, $ai_ready_extensions);
    }
    
    /**
     * Analyze collected files
     */
    private function analyze_files() {
        foreach ($this->files_index as $file) {
            // Count by category
            if (!isset($this->statistics['by_category'][$file['category']])) {
                $this->statistics['by_category'][$file['category']] = 0;
            }
            $this->statistics['by_category'][$file['category']]++;
            
            // Count by status
            if (strpos($file['status'], '✅') !== false) {
                $this->statistics['active']++;
            } elseif (strpos($file['status'], '⚠️') !== false) {
                $this->statistics['needs_update']++;
            } elseif (strpos($file['status'], '❌') !== false) {
                $this->statistics['deprecated']++;
            }
        }
    }
    
    /**
     * Generate markdown index
     */
    private function generate_markdown() {
        $date = date('Y-m-d');
        $total = $this->statistics['total_files'];
        $ai_ready_pct = $total > 0 ? round(($this->statistics['ai_ready'] / $total) * 100, 1) : 0;
        
        $md = "# WordPress Testing Framework - Complete File Index\n\n";
        $md .= "**Generated**: {$date}\n";
        $md .= "**Total Files**: {$total} core files\n";
        $md .= "**AI-Ready**: {$this->statistics['ai_ready']} files ({$ai_ready_pct}%)\n\n";
        
        // Add statistics
        $md .= "## 📊 Statistics\n\n";
        $md .= "### File Status\n";
        $md .= "- ✅ Active: {$this->statistics['active']}\n";
        $md .= "- ⚠️ Needs Update: {$this->statistics['needs_update']}\n";
        $md .= "- ❌ Deprecated: {$this->statistics['deprecated']}\n\n";
        
        $md .= "### By Extension\n";
        arsort($this->statistics['by_extension']);
        foreach ($this->statistics['by_extension'] as $ext => $count) {
            $pct = round(($count / $total) * 100, 1);
            $md .= "- `.{$ext}`: {$count} ({$pct}%)\n";
        }
        $md .= "\n";
        
        // Group files by category
        $by_category = [];
        foreach ($this->files_index as $file) {
            $by_category[$file['category']][] = $file;
        }
        
        // Add files by category
        foreach ($by_category as $category => $files) {
            $md .= "## " . ucfirst($category) . " Files\n\n";
            $md .= "| File | Purpose | Status | Priority | AI-Ready |\n";
            $md .= "|------|---------|--------|----------|----------|\n";
            
            // Sort files by path
            usort($files, function($a, $b) {
                return strcmp($a['path'], $b['path']);
            });
            
            foreach ($files as $file) {
                $ai = $file['ai_ready'] ? 'Yes' : 'No';
                $md .= "| `{$file['name']}` | {$file['purpose']} | {$file['status']} | {$file['priority']} | {$ai} |\n";
            }
            $md .= "\n";
        }
        
        // Add maintenance notes
        $md .= "## 🔧 Maintenance Notes\n\n";
        $md .= "### Files Needing Attention\n";
        foreach ($this->files_index as $file) {
            if (strpos($file['status'], '⚠️') !== false || strpos($file['status'], '❌') !== false) {
                $md .= "- `{$file['path']}` - {$file['status']}\n";
            }
        }
        $md .= "\n";
        
        $md .= "### Recommended Actions\n";
        if ($this->statistics['deprecated'] > 0) {
            $md .= "1. Remove or archive {$this->statistics['deprecated']} deprecated files\n";
        }
        if ($this->statistics['needs_update'] > 0) {
            $md .= "2. Update {$this->statistics['needs_update']} files that need attention\n";
        }
        $md .= "3. Keep this index updated with new files\n\n";
        
        $md .= "---\n";
        $md .= "*This index was automatically generated by `tools/utilities/file-index-generator.php`*\n";
        
        return $md;
    }
    
    /**
     * Export index as JSON for AI consumption
     */
    public function export_json($filename = null) {
        if (!$filename) {
            $filename = $this->framework_path . '/FILE-INDEX.json';
        }
        
        $export_data = [
            'generated' => date('Y-m-d H:i:s'),
            'statistics' => $this->statistics,
            'files' => $this->files_index
        ];
        
        file_put_contents($filename, json_encode($export_data, JSON_PRETTY_PRINT));
        
        echo "📄 JSON index exported: {$filename}\n";
        
        return $filename;
    }
}

// Run if called directly
if (php_sapi_name() === 'cli') {
    $generator = new FileIndexGenerator();
    $generator->generate();
    $generator->export_json();
}