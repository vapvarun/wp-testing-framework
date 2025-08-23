<?php
/**
 * BuddyPress Component-Specific Code Scanner
 * 
 * Scans each BuddyPress component's code structure, functions, hooks, and dependencies
 */

class BuddyPressComponentScanner {
    
    private $buddypress_path;
    private $components = [];
    private $scan_results = [];
    
    // BuddyPress core components
    private $core_components = [
        'core' => [
            'path' => 'bp-core',
            'name' => 'Core',
            'description' => 'Core functionality and infrastructure'
        ],
        'members' => [
            'path' => 'bp-members', 
            'name' => 'Members',
            'description' => 'Member profiles and directories'
        ],
        'activity' => [
            'path' => 'bp-activity',
            'name' => 'Activity Streams',
            'description' => 'Activity updates and streams'
        ],
        'groups' => [
            'path' => 'bp-groups',
            'name' => 'Groups',
            'description' => 'User groups and communities'
        ],
        'friends' => [
            'path' => 'bp-friends',
            'name' => 'Friends',
            'description' => 'Friend connections between members'
        ],
        'messages' => [
            'path' => 'bp-messages',
            'name' => 'Private Messages',
            'description' => 'Private messaging between members'
        ],
        'notifications' => [
            'path' => 'bp-notifications',
            'name' => 'Notifications',
            'description' => 'User notifications system'
        ],
        'xprofile' => [
            'path' => 'bp-xprofile',
            'name' => 'Extended Profiles',
            'description' => 'Extended profile fields'
        ],
        'settings' => [
            'path' => 'bp-settings',
            'name' => 'Settings',
            'description' => 'User account settings'
        ],
        'blogs' => [
            'path' => 'bp-blogs',
            'name' => 'Site Tracking',
            'description' => 'Blog and site tracking (Multisite)'
        ]
    ];
    
    public function __construct($buddypress_path = null) {
        if (!$buddypress_path) {
            // Try to find BuddyPress automatically
            $possible_paths = [
                WP_PLUGIN_DIR . '/buddypress',
                WP_PLUGIN_DIR . '/buddypress-trunk',
                dirname(dirname(dirname(__DIR__))) . '/wp-content/plugins/buddypress',
                '/Users/varundubey/Local Sites/buddynext/app/public/wp-content/plugins/buddypress'
            ];
            
            foreach ($possible_paths as $path) {
                if (file_exists($path . '/bp-loader.php')) {
                    $buddypress_path = $path;
                    break;
                }
            }
        }
        
        $this->buddypress_path = $buddypress_path;
    }
    
    /**
     * Scan all BuddyPress components
     */
    public function scan_all_components() {
        if (!$this->buddypress_path || !is_dir($this->buddypress_path)) {
            return ['error' => 'BuddyPress directory not found'];
        }
        
        foreach ($this->core_components as $component_id => $component) {
            // Try both old and new BuddyPress structures
            $possible_component_paths = [
                $this->buddypress_path . '/' . $component['path'],
                $this->buddypress_path . '/src/' . $component['path']
            ];
            
            foreach ($possible_component_paths as $component_path) {
                if (is_dir($component_path)) {
                    $this->scan_results[$component_id] = $this->scan_component($component_id, $component_path);
                    break;
                }
            }
        }
        
        // Add overall summary
        $this->scan_results['summary'] = $this->generate_summary();
        
        return $this->scan_results;
    }
    
    /**
     * Scan individual component
     */
    private function scan_component($component_id, $component_path) {
        $result = [
            'id' => $component_id,
            'name' => $this->core_components[$component_id]['name'],
            'description' => $this->core_components[$component_id]['description'],
            'path' => $component_path,
            'files' => $this->scan_files($component_path),
            'classes' => $this->scan_classes($component_path),
            'functions' => $this->scan_functions($component_path),
            'hooks' => $this->scan_hooks($component_path),
            'filters' => $this->scan_filters($component_path),
            'actions' => $this->scan_actions($component_path),
            'database_tables' => $this->scan_database_tables($component_path),
            'ajax_handlers' => $this->scan_ajax_handlers($component_path),
            'rest_endpoints' => $this->scan_rest_endpoints($component_path),
            'templates' => $this->scan_templates($component_path),
            'assets' => $this->scan_assets($component_path),
            'dependencies' => $this->scan_dependencies($component_path),
            'test_scenarios' => $this->generate_test_scenarios($component_id)
        ];
        
        // Calculate metrics
        $result['metrics'] = [
            'total_files' => count($result['files']),
            'php_files' => count(array_filter($result['files'], fn($f) => is_array($f) ? str_ends_with($f['path'] ?? '', '.php') : str_ends_with($f, '.php'))),
            'total_classes' => count($result['classes']),
            'total_functions' => count($result['functions']),
            'total_hooks' => count($result['hooks']),
            'total_filters' => count($result['filters']),
            'total_actions' => count($result['actions']),
            'complexity_score' => $this->calculate_complexity($result)
        ];
        
        return $result;
    }
    
    /**
     * Scan all files in component
     */
    private function scan_files($path) {
        $files = [];
        $iterator = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator($path, RecursiveDirectoryIterator::SKIP_DOTS)
        );
        
        foreach ($iterator as $file) {
            if ($file->isFile()) {
                $relative_path = str_replace($path . '/', '', $file->getPathname());
                $files[] = [
                    'path' => $relative_path,
                    'size' => $file->getSize(),
                    'type' => pathinfo($file->getFilename(), PATHINFO_EXTENSION),
                    'lines' => $this->count_lines($file->getPathname())
                ];
            }
        }
        
        return $files;
    }
    
    /**
     * Scan PHP classes in component
     */
    private function scan_classes($path) {
        $classes = [];
        $php_files = glob($path . '/**/*.php', GLOB_BRACE);
        
        foreach ($php_files as $file) {
            $content = file_get_contents($file);
            
            // Find class declarations
            if (preg_match_all('/class\s+([A-Z][A-Za-z0-9_]+)(?:\s+extends\s+([A-Za-z0-9_]+))?/', $content, $matches)) {
                foreach ($matches[1] as $index => $class_name) {
                    $classes[] = [
                        'name' => $class_name,
                        'file' => str_replace($path . '/', '', $file),
                        'extends' => $matches[2][$index] ?? null,
                        'methods' => $this->extract_class_methods($content, $class_name)
                    ];
                }
            }
        }
        
        return $classes;
    }
    
    /**
     * Extract methods from a class
     */
    private function extract_class_methods($content, $class_name) {
        $methods = [];
        
        // Simple regex to find public methods
        if (preg_match('/class\s+' . $class_name . '.*?\{(.*?)^\}/ms', $content, $class_match)) {
            if (preg_match_all('/public\s+function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(/', $class_match[1], $method_matches)) {
                $methods = $method_matches[1];
            }
        }
        
        return $methods;
    }
    
    /**
     * Scan functions in component
     */
    private function scan_functions($path) {
        $functions = [];
        $php_files = glob($path . '/**/*.php', GLOB_BRACE);
        
        foreach ($php_files as $file) {
            $content = file_get_contents($file);
            
            // Find function declarations (not class methods)
            if (preg_match_all('/^function\s+([a-z_][a-z0-9_]*)\s*\(/mi', $content, $matches)) {
                foreach ($matches[1] as $function_name) {
                    // Filter out BuddyPress functions (usually start with bp_)
                    if (strpos($function_name, 'bp_') === 0) {
                        $functions[] = [
                            'name' => $function_name,
                            'file' => str_replace($path . '/', '', $file),
                            'type' => $this->categorize_function($function_name)
                        ];
                    }
                }
            }
        }
        
        return $functions;
    }
    
    /**
     * Categorize function by name pattern
     */
    private function categorize_function($function_name) {
        if (strpos($function_name, 'bp_get_') === 0) return 'getter';
        if (strpos($function_name, 'bp_set_') === 0) return 'setter';
        if (strpos($function_name, 'bp_is_') === 0) return 'conditional';
        if (strpos($function_name, 'bp_has_') === 0) return 'conditional';
        if (strpos($function_name, 'bp_can_') === 0) return 'capability';
        if (strpos($function_name, 'bp_core_') === 0) return 'core';
        if (strpos($function_name, 'bp_ajax_') === 0) return 'ajax';
        if (strpos($function_name, '_screen') !== false) return 'screen';
        if (strpos($function_name, '_template') !== false) return 'template';
        return 'utility';
    }
    
    /**
     * Scan hooks in component
     */
    private function scan_hooks($path) {
        $hooks = [];
        $php_files = glob($path . '/**/*.php', GLOB_BRACE);
        
        foreach ($php_files as $file) {
            $content = file_get_contents($file);
            
            // Find do_action and apply_filters calls
            if (preg_match_all('/(?:do_action|apply_filters)\s*\(\s*[\'"]([^\'"]+)[\'"]/', $content, $matches)) {
                foreach ($matches[1] as $hook_name) {
                    if (strpos($hook_name, 'bp_') === 0) {
                        $hooks[] = [
                            'name' => $hook_name,
                            'file' => str_replace($path . '/', '', $file),
                            'type' => strpos($content, "do_action.*$hook_name") !== false ? 'action' : 'filter'
                        ];
                    }
                }
            }
        }
        
        return array_unique($hooks, SORT_REGULAR);
    }
    
    /**
     * Scan filters specifically
     */
    private function scan_filters($path) {
        return array_filter($this->scan_hooks($path), fn($h) => $h['type'] === 'filter');
    }
    
    /**
     * Scan actions specifically
     */
    private function scan_actions($path) {
        return array_filter($this->scan_hooks($path), fn($h) => $h['type'] === 'action');
    }
    
    /**
     * Scan database tables used by component
     */
    private function scan_database_tables($path) {
        $tables = [];
        $php_files = glob($path . '/**/*.php', GLOB_BRACE);
        
        foreach ($php_files as $file) {
            $content = file_get_contents($file);
            
            // Look for $wpdb->prefix references
            if (preg_match_all('/\$wpdb->prefix\s*\.\s*[\'"]?bp_([a-z_]+)/', $content, $matches)) {
                foreach ($matches[1] as $table_suffix) {
                    $tables[] = 'bp_' . $table_suffix;
                }
            }
            
            // Look for $bp->table_name references
            if (preg_match_all('/\$bp->([a-z_]+)->table_name/', $content, $matches)) {
                foreach ($matches[1] as $component_table) {
                    $tables[] = $component_table;
                }
            }
        }
        
        return array_unique($tables);
    }
    
    /**
     * Scan AJAX handlers
     */
    private function scan_ajax_handlers($path) {
        $handlers = [];
        $php_files = glob($path . '/**/*.php', GLOB_BRACE);
        
        foreach ($php_files as $file) {
            $content = file_get_contents($file);
            
            // Find wp_ajax_ and wp_ajax_nopriv_ handlers
            if (preg_match_all('/add_action\s*\(\s*[\'"]wp_ajax_(?:nopriv_)?([^\'"]+)/', $content, $matches)) {
                foreach ($matches[1] as $handler) {
                    $handlers[] = [
                        'action' => $handler,
                        'file' => str_replace($path . '/', '', $file)
                    ];
                }
            }
        }
        
        return $handlers;
    }
    
    /**
     * Scan REST API endpoints
     */
    private function scan_rest_endpoints($path) {
        $endpoints = [];
        $php_files = glob($path . '/**/*.php', GLOB_BRACE);
        
        foreach ($php_files as $file) {
            $content = file_get_contents($file);
            
            // Find register_rest_route calls
            if (preg_match_all('/register_rest_route\s*\(\s*[\'"]([^\'"]+)[\'"],\s*[\'"]([^\'"]+)/', $content, $matches)) {
                for ($i = 0; $i < count($matches[0]); $i++) {
                    $endpoints[] = [
                        'namespace' => $matches[1][$i],
                        'route' => $matches[2][$i],
                        'file' => str_replace($path . '/', '', $file)
                    ];
                }
            }
        }
        
        return $endpoints;
    }
    
    /**
     * Scan template files
     */
    private function scan_templates($path) {
        $templates = [];
        
        // Look for template files
        $template_patterns = [
            $path . '/templates/*.php',
            $path . '/*-template.php',
            $path . '/*-templates.php'
        ];
        
        foreach ($template_patterns as $pattern) {
            $files = glob($pattern);
            foreach ($files as $file) {
                $templates[] = [
                    'file' => basename($file),
                    'path' => str_replace($path . '/', '', $file)
                ];
            }
        }
        
        return $templates;
    }
    
    /**
     * Scan assets (CSS, JS)
     */
    private function scan_assets($path) {
        $assets = [
            'css' => [],
            'js' => []
        ];
        
        // Scan CSS files
        $css_files = glob($path . '/**/*.css', GLOB_BRACE);
        foreach ($css_files as $file) {
            $assets['css'][] = [
                'file' => basename($file),
                'path' => str_replace($path . '/', '', $file),
                'size' => filesize($file)
            ];
        }
        
        // Scan JS files
        $js_files = glob($path . '/**/*.js', GLOB_BRACE);
        foreach ($js_files as $file) {
            $assets['js'][] = [
                'file' => basename($file),
                'path' => str_replace($path . '/', '', $file),
                'size' => filesize($file)
            ];
        }
        
        return $assets;
    }
    
    /**
     * Scan component dependencies
     */
    private function scan_dependencies($path) {
        $dependencies = [];
        $php_files = glob($path . '/**/*.php', GLOB_BRACE);
        
        foreach ($php_files as $file) {
            $content = file_get_contents($file);
            
            // Look for references to other components
            foreach ($this->core_components as $comp_id => $comp) {
                if (preg_match('/bp_is_' . $comp_id . '_component|BP_' . strtoupper($comp_id) . '_|bp_' . $comp_id . '_/', $content)) {
                    $dependencies[] = $comp_id;
                }
            }
        }
        
        return array_unique($dependencies);
    }
    
    /**
     * Generate test scenarios for component
     */
    private function generate_test_scenarios($component_id) {
        $scenarios = [];
        
        // Component-specific test scenarios
        switch ($component_id) {
            case 'members':
                $scenarios = [
                    'user_registration' => 'Test user registration flow',
                    'profile_update' => 'Test profile field updates',
                    'member_directory' => 'Test member directory listing',
                    'member_search' => 'Test member search functionality',
                    'avatar_upload' => 'Test avatar upload and display'
                ];
                break;
                
            case 'activity':
                $scenarios = [
                    'post_update' => 'Test posting activity updates',
                    'comment_activity' => 'Test commenting on activities',
                    'delete_activity' => 'Test deleting activities',
                    'filter_activity' => 'Test activity stream filters',
                    'mentions' => 'Test @mentions functionality'
                ];
                break;
                
            case 'groups':
                $scenarios = [
                    'create_group' => 'Test group creation',
                    'join_group' => 'Test joining groups',
                    'group_activity' => 'Test group activity posting',
                    'group_members' => 'Test group member management',
                    'group_settings' => 'Test group settings and privacy'
                ];
                break;
                
            case 'friends':
                $scenarios = [
                    'send_request' => 'Test sending friend requests',
                    'accept_request' => 'Test accepting friend requests',
                    'reject_request' => 'Test rejecting friend requests',
                    'remove_friend' => 'Test removing friends',
                    'friendship_status' => 'Test friendship status checks'
                ];
                break;
                
            case 'messages':
                $scenarios = [
                    'send_message' => 'Test sending private messages',
                    'reply_message' => 'Test replying to messages',
                    'delete_message' => 'Test deleting messages',
                    'mark_read' => 'Test marking messages as read',
                    'thread_management' => 'Test message thread management'
                ];
                break;
                
            case 'notifications':
                $scenarios = [
                    'create_notification' => 'Test notification creation',
                    'mark_read' => 'Test marking notifications as read',
                    'delete_notification' => 'Test deleting notifications',
                    'bulk_manage' => 'Test bulk notification management',
                    'email_notifications' => 'Test email notification sending'
                ];
                break;
                
            case 'xprofile':
                $scenarios = [
                    'create_field' => 'Test creating profile fields',
                    'field_validation' => 'Test field validation rules',
                    'field_visibility' => 'Test field visibility settings',
                    'field_groups' => 'Test field group management',
                    'data_export' => 'Test profile data export'
                ];
                break;
                
            case 'settings':
                $scenarios = [
                    'email_change' => 'Test email address change',
                    'password_change' => 'Test password change',
                    'privacy_settings' => 'Test privacy settings',
                    'notification_settings' => 'Test notification preferences',
                    'data_export' => 'Test data export request'
                ];
                break;
                
            case 'blogs':
                $scenarios = [
                    'blog_tracking' => 'Test blog post tracking',
                    'comment_tracking' => 'Test comment tracking',
                    'blog_directory' => 'Test blog directory listing',
                    'recent_posts' => 'Test recent posts widget',
                    'blog_creation' => 'Test blog creation (multisite)'
                ];
                break;
                
            case 'core':
                $scenarios = [
                    'component_activation' => 'Test component activation/deactivation',
                    'permalink_setup' => 'Test permalink configuration',
                    'theme_compatibility' => 'Test theme compatibility layer',
                    'admin_screens' => 'Test admin screen rendering',
                    'options_api' => 'Test options API functionality'
                ];
                break;
        }
        
        return $scenarios;
    }
    
    /**
     * Count lines in file
     */
    private function count_lines($file) {
        if (!is_readable($file)) return 0;
        $lines = 0;
        $handle = fopen($file, 'r');
        while (!feof($handle)) {
            fgets($handle);
            $lines++;
        }
        fclose($handle);
        return $lines;
    }
    
    /**
     * Calculate complexity score
     */
    private function calculate_complexity($component_data) {
        $score = 0;
        
        // Base complexity on various metrics
        $score += count($component_data['classes']) * 10;
        $score += count($component_data['functions']) * 2;
        $score += count($component_data['hooks']) * 3;
        $score += count($component_data['database_tables']) * 20;
        $score += count($component_data['ajax_handlers']) * 5;
        $score += count($component_data['rest_endpoints']) * 8;
        
        return $score;
    }
    
    /**
     * Generate summary of all components
     */
    private function generate_summary() {
        $summary = [
            'total_components' => count($this->scan_results),
            'total_files' => 0,
            'total_classes' => 0,
            'total_functions' => 0,
            'total_hooks' => 0,
            'total_database_tables' => [],
            'complexity_ranking' => [],
            'dependency_map' => []
        ];
        
        foreach ($this->scan_results as $component_id => $data) {
            if ($component_id === 'summary') continue;
            
            $summary['total_files'] += $data['metrics']['total_files'];
            $summary['total_classes'] += $data['metrics']['total_classes'];
            $summary['total_functions'] += $data['metrics']['total_functions'];
            $summary['total_hooks'] += $data['metrics']['total_hooks'];
            
            $summary['total_database_tables'] = array_merge(
                $summary['total_database_tables'],
                $data['database_tables']
            );
            
            $summary['complexity_ranking'][$component_id] = $data['metrics']['complexity_score'];
            $summary['dependency_map'][$component_id] = $data['dependencies'];
        }
        
        // Sort complexity ranking
        arsort($summary['complexity_ranking']);
        
        // Make database tables unique
        $summary['total_database_tables'] = array_unique($summary['total_database_tables']);
        
        return $summary;
    }
    
    /**
     * Export scan results
     */
    public function export_results($output_file = null) {
        if (!$output_file) {
            $output_file = dirname(dirname(__DIR__)) . '/wp-content/uploads/wbcom-scan/buddypress-components-scan.json';
        }
        
        // Ensure directory exists
        $dir = dirname($output_file);
        if (!is_dir($dir)) {
            mkdir($dir, 0755, true);
        }
        
        // Save results
        file_put_contents($output_file, json_encode($this->scan_results, JSON_PRETTY_PRINT));
        
        return $output_file;
    }
}

// If run directly from command line
if (php_sapi_name() === 'cli' && basename($argv[0]) === basename(__FILE__)) {
    // Bootstrap WordPress if needed
    if (!defined('ABSPATH')) {
        $wp_load = dirname(dirname(dirname(__DIR__))) . '/wp-load.php';
        if (file_exists($wp_load)) {
            require_once $wp_load;
        }
    }
    
    echo "🔍 BuddyPress Component Scanner\n";
    echo "================================\n\n";
    
    $scanner = new BuddyPressComponentScanner();
    $results = $scanner->scan_all_components();
    
    if (isset($results['error'])) {
        echo "❌ Error: " . $results['error'] . "\n";
        exit(1);
    }
    
    // Display results
    foreach ($results as $component_id => $data) {
        if ($component_id === 'summary') continue;
        
        echo "📦 Component: " . $data['name'] . "\n";
        echo "   Files: " . $data['metrics']['total_files'] . "\n";
        echo "   Classes: " . $data['metrics']['total_classes'] . "\n";
        echo "   Functions: " . $data['metrics']['total_functions'] . "\n";
        echo "   Hooks: " . $data['metrics']['total_hooks'] . "\n";
        echo "   Complexity: " . $data['metrics']['complexity_score'] . "\n";
        echo "\n";
    }
    
    // Export results
    $output_file = $scanner->export_results();
    echo "✅ Results saved to: " . $output_file . "\n";
}