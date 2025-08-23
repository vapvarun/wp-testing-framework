<?php
/**
 * BuddyPress Deep Component Scanner with REST API Analysis
 * 
 * Performs detailed component-by-component scanning including REST API endpoints
 */

class BP_Deep_Component_Scanner {
    
    private $bp_path;
    private $rest_routes = [];
    private $component_results = [];
    
    // Components to scan
    private $components = [
        'core' => 'Core Infrastructure',
        'members' => 'Members',
        'activity' => 'Activity Streams',
        'groups' => 'Groups',
        'friends' => 'Friends',
        'messages' => 'Private Messages',
        'notifications' => 'Notifications',
        'xprofile' => 'Extended Profiles',
        'settings' => 'Settings',
        'blogs' => 'Site Tracking'
    ];
    
    public function __construct() {
        $this->bp_path = WP_PLUGIN_DIR . '/buddypress/src';
        $this->load_rest_routes();
    }
    
    /**
     * Load all REST routes from WordPress
     */
    private function load_rest_routes() {
        if (function_exists('rest_get_server')) {
            $server = rest_get_server();
            $routes = $server->get_routes();
            
            // Filter BuddyPress routes
            foreach ($routes as $route => $handlers) {
                if (strpos($route, '/buddypress/') !== false) {
                    $this->rest_routes[$route] = $this->analyze_route($route, $handlers);
                }
            }
        }
    }
    
    /**
     * Analyze a REST route
     */
    private function analyze_route($route, $handlers) {
        $analysis = [
            'route' => $route,
            'methods' => [],
            'component' => $this->identify_component_from_route($route),
            'namespace' => $this->extract_namespace($route),
            'endpoints' => []
        ];
        
        foreach ($handlers as $handler) {
            if (isset($handler['methods'])) {
                $analysis['methods'] = array_merge($analysis['methods'], array_keys($handler['methods']));
            }
            
            if (isset($handler['callback'])) {
                $callback_info = $this->analyze_callback($handler['callback']);
                $analysis['endpoints'][] = [
                    'methods' => array_keys($handler['methods'] ?? []),
                    'callback' => $callback_info,
                    'permission_callback' => isset($handler['permission_callback']) ? 
                        $this->analyze_callback($handler['permission_callback']) : null,
                    'args' => $handler['args'] ?? []
                ];
            }
        }
        
        $analysis['methods'] = array_unique($analysis['methods']);
        return $analysis;
    }
    
    /**
     * Identify component from REST route
     */
    private function identify_component_from_route($route) {
        if (strpos($route, '/members') !== false) return 'members';
        if (strpos($route, '/activity') !== false) return 'activity';
        if (strpos($route, '/groups') !== false) return 'groups';
        if (strpos($route, '/messages') !== false) return 'messages';
        if (strpos($route, '/notifications') !== false) return 'notifications';
        if (strpos($route, '/xprofile') !== false) return 'xprofile';
        if (strpos($route, '/friends') !== false) return 'friends';
        if (strpos($route, '/settings') !== false) return 'settings';
        if (strpos($route, '/blogs') !== false) return 'blogs';
        return 'core';
    }
    
    /**
     * Extract namespace from route
     */
    private function extract_namespace($route) {
        $parts = explode('/', trim($route, '/'));
        if (count($parts) >= 2) {
            return $parts[0] . '/' . $parts[1];
        }
        return '';
    }
    
    /**
     * Analyze callback function
     */
    private function analyze_callback($callback) {
        if (is_string($callback)) {
            return ['type' => 'function', 'name' => $callback];
        } elseif (is_array($callback)) {
            if (is_object($callback[0])) {
                return [
                    'type' => 'method',
                    'class' => get_class($callback[0]),
                    'method' => $callback[1]
                ];
            } else {
                return [
                    'type' => 'static_method',
                    'class' => $callback[0],
                    'method' => $callback[1]
                ];
            }
        } elseif (is_object($callback) && $callback instanceof Closure) {
            return ['type' => 'closure'];
        }
        return ['type' => 'unknown'];
    }
    
    /**
     * Scan all components one by one
     */
    public function scan_all_components() {
        echo "🔍 Starting Deep Component Scan with REST API Analysis\n";
        echo "=" . str_repeat("=", 70) . "\n\n";
        
        foreach ($this->components as $component_id => $component_name) {
            echo "📦 Scanning Component: {$component_name}\n";
            echo str_repeat("-", 50) . "\n";
            
            $this->component_results[$component_id] = $this->scan_single_component($component_id);
            
            // Display summary
            $this->display_component_summary($component_id);
            echo "\n";
        }
        
        // Overall summary
        $this->display_overall_summary();
        
        return $this->component_results;
    }
    
    /**
     * Scan a single component in detail
     */
    private function scan_single_component($component_id) {
        $component_path = $this->bp_path . '/bp-' . $component_id;
        
        $result = [
            'id' => $component_id,
            'name' => $this->components[$component_id],
            'path' => $component_path,
            'exists' => is_dir($component_path),
            'files' => [],
            'classes' => [],
            'functions' => [],
            'hooks' => [],
            'rest_api' => [],
            'ajax' => [],
            'database' => [],
            'templates' => [],
            'admin_pages' => [],
            'shortcodes' => [],
            'widgets' => [],
            'blocks' => [],
            'assets' => [],
            'dependencies' => []
        ];
        
        if (!$result['exists']) {
            return $result;
        }
        
        // Scan files
        $result['files'] = $this->scan_component_files($component_path);
        
        // Scan PHP structure
        $result['classes'] = $this->scan_component_classes($component_path);
        $result['functions'] = $this->scan_component_functions($component_path);
        $result['hooks'] = $this->scan_component_hooks($component_path);
        
        // Scan REST API endpoints for this component
        $result['rest_api'] = $this->get_component_rest_endpoints($component_id);
        
        // Scan AJAX handlers
        $result['ajax'] = $this->scan_ajax_handlers($component_path);
        
        // Scan database usage
        $result['database'] = $this->scan_database_usage($component_path);
        
        // Scan templates
        $result['templates'] = $this->scan_templates($component_path);
        
        // Scan admin pages
        $result['admin_pages'] = $this->scan_admin_pages($component_path);
        
        // Scan shortcodes
        $result['shortcodes'] = $this->scan_shortcodes($component_path);
        
        // Scan blocks
        $result['blocks'] = $this->scan_blocks($component_path);
        
        // Scan assets
        $result['assets'] = $this->scan_assets($component_path);
        
        // Analyze dependencies
        $result['dependencies'] = $this->analyze_dependencies($component_path);
        
        // Calculate metrics
        $result['metrics'] = $this->calculate_metrics($result);
        
        return $result;
    }
    
    /**
     * Scan component files
     */
    private function scan_component_files($path) {
        $files = [];
        if (!is_dir($path)) return $files;
        
        $iterator = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator($path, RecursiveDirectoryIterator::SKIP_DOTS),
            RecursiveIteratorIterator::SELF_FIRST
        );
        
        foreach ($iterator as $file) {
            if ($file->isFile()) {
                $relative_path = str_replace($path . '/', '', $file->getPathname());
                $extension = pathinfo($file->getFilename(), PATHINFO_EXTENSION);
                
                $files[] = [
                    'path' => $relative_path,
                    'name' => $file->getFilename(),
                    'size' => $file->getSize(),
                    'type' => $extension,
                    'category' => $this->categorize_file($relative_path, $extension)
                ];
            }
        }
        
        return $files;
    }
    
    /**
     * Categorize file based on path and extension
     */
    private function categorize_file($path, $extension) {
        if (strpos($path, 'admin/') !== false) return 'admin';
        if (strpos($path, 'classes/') !== false) return 'class';
        if (strpos($path, 'templates/') !== false) return 'template';
        if (strpos($path, 'blocks/') !== false) return 'block';
        if (strpos($path, 'screens/') !== false) return 'screen';
        if (strpos($path, 'actions/') !== false) return 'action';
        if (strpos($path, 'filters/') !== false) return 'filter';
        if ($extension === 'js') return 'javascript';
        if ($extension === 'css') return 'stylesheet';
        if ($extension === 'php') return 'php';
        return 'other';
    }
    
    /**
     * Scan classes in component
     */
    private function scan_component_classes($path) {
        $classes = [];
        $php_files = glob($path . '/**/*.php', GLOB_BRACE);
        
        foreach ($php_files as $file) {
            $content = file_get_contents($file);
            
            // Find class declarations
            if (preg_match_all('/^\s*(?:abstract\s+)?(?:final\s+)?class\s+([A-Z][A-Za-z0-9_]+)/m', $content, $matches)) {
                foreach ($matches[1] as $class_name) {
                    $classes[] = [
                        'name' => $class_name,
                        'file' => str_replace($path . '/', '', $file),
                        'type' => $this->determine_class_type($class_name, $content),
                        'methods' => $this->count_class_methods($content, $class_name)
                    ];
                }
            }
        }
        
        return $classes;
    }
    
    /**
     * Determine class type
     */
    private function determine_class_type($class_name, $content) {
        if (strpos($content, "class {$class_name} extends BP_Component") !== false) {
            return 'component';
        }
        if (strpos($class_name, 'Admin') !== false) return 'admin';
        if (strpos($class_name, 'REST') !== false) return 'rest';
        if (strpos($class_name, 'Widget') !== false) return 'widget';
        if (strpos($class_name, 'Block') !== false) return 'block';
        if (strpos($class_name, 'Screen') !== false) return 'screen';
        return 'utility';
    }
    
    /**
     * Count methods in a class
     */
    private function count_class_methods($content, $class_name) {
        $count = 0;
        if (preg_match('/class\s+' . $class_name . '.*?\{(.*?)^\}/ms', $content, $class_match)) {
            preg_match_all('/(?:public|protected|private|static)\s+function\s+/', $class_match[1], $methods);
            $count = count($methods[0]);
        }
        return $count;
    }
    
    /**
     * Scan functions in component
     */
    private function scan_component_functions($path) {
        $functions = [];
        $php_files = glob($path . '/**/*.php', GLOB_BRACE);
        
        foreach ($php_files as $file) {
            $content = file_get_contents($file);
            
            // Find function declarations (not in classes)
            $lines = explode("\n", $content);
            $in_class = false;
            
            foreach ($lines as $line) {
                if (preg_match('/^\s*(?:abstract\s+)?(?:final\s+)?class\s+/', $line)) {
                    $in_class = true;
                } elseif (preg_match('/^}/', $line) && $in_class) {
                    $in_class = false;
                } elseif (!$in_class && preg_match('/^function\s+([a-z_][a-z0-9_]*)\s*\(/i', $line, $match)) {
                    $functions[] = [
                        'name' => $match[1],
                        'file' => str_replace($path . '/', '', $file),
                        'prefix' => $this->get_function_prefix($match[1])
                    ];
                }
            }
        }
        
        return $functions;
    }
    
    /**
     * Get function prefix
     */
    private function get_function_prefix($function_name) {
        if (strpos($function_name, 'bp_') === 0) return 'bp';
        if (strpos($function_name, '_bp_') !== false) return 'internal';
        return 'other';
    }
    
    /**
     * Scan hooks (actions and filters)
     */
    private function scan_component_hooks($path) {
        $hooks = [];
        $php_files = glob($path . '/**/*.php', GLOB_BRACE);
        
        foreach ($php_files as $file) {
            $content = file_get_contents($file);
            
            // Find do_action calls
            if (preg_match_all('/do_action(?:_ref_array)?\s*\(\s*[\'"]([^\'"]+)/', $content, $matches)) {
                foreach ($matches[1] as $hook) {
                    $hooks[] = [
                        'name' => $hook,
                        'type' => 'action',
                        'file' => str_replace($path . '/', '', $file)
                    ];
                }
            }
            
            // Find apply_filters calls
            if (preg_match_all('/apply_filters(?:_ref_array)?\s*\(\s*[\'"]([^\'"]+)/', $content, $matches)) {
                foreach ($matches[1] as $hook) {
                    $hooks[] = [
                        'name' => $hook,
                        'type' => 'filter',
                        'file' => str_replace($path . '/', '', $file)
                    ];
                }
            }
        }
        
        return $hooks;
    }
    
    /**
     * Get REST endpoints for specific component
     */
    private function get_component_rest_endpoints($component_id) {
        $endpoints = [];
        
        foreach ($this->rest_routes as $route => $data) {
            if ($data['component'] === $component_id) {
                $endpoints[] = [
                    'route' => $route,
                    'methods' => $data['methods'],
                    'namespace' => $data['namespace'],
                    'endpoints' => $data['endpoints']
                ];
            }
        }
        
        return $endpoints;
    }
    
    /**
     * Scan AJAX handlers
     */
    private function scan_ajax_handlers($path) {
        $handlers = [];
        $php_files = glob($path . '/**/*.php', GLOB_BRACE);
        
        foreach ($php_files as $file) {
            $content = file_get_contents($file);
            
            // Find add_action for wp_ajax_
            if (preg_match_all('/add_action\s*\(\s*[\'"]wp_ajax_(?:nopriv_)?([^\'"]+)/', $content, $matches)) {
                foreach ($matches[1] as $action) {
                    $handlers[] = [
                        'action' => $action,
                        'file' => str_replace($path . '/', '', $file),
                        'public' => strpos($content, "wp_ajax_nopriv_{$action}") !== false
                    ];
                }
            }
        }
        
        return $handlers;
    }
    
    /**
     * Scan database usage
     */
    private function scan_database_usage($path) {
        $database = [
            'tables' => [],
            'queries' => []
        ];
        
        $php_files = glob($path . '/**/*.php', GLOB_BRACE);
        
        foreach ($php_files as $file) {
            $content = file_get_contents($file);
            
            // Find table references
            if (preg_match_all('/\$wpdb->prefix\s*\.\s*[\'"]?bp_([a-z_]+)/', $content, $matches)) {
                foreach ($matches[1] as $table) {
                    if (!in_array('bp_' . $table, $database['tables'])) {
                        $database['tables'][] = 'bp_' . $table;
                    }
                }
            }
            
            // Count query types
            $query_types = ['get_results', 'get_var', 'get_row', 'query', 'prepare'];
            foreach ($query_types as $type) {
                if (substr_count($content, '$wpdb->' . $type) > 0) {
                    if (!isset($database['queries'][$type])) {
                        $database['queries'][$type] = 0;
                    }
                    $database['queries'][$type] += substr_count($content, '$wpdb->' . $type);
                }
            }
        }
        
        return $database;
    }
    
    /**
     * Scan templates
     */
    private function scan_templates($path) {
        $templates = [];
        
        // Look for template files
        $template_files = glob($path . '/**/templates/**/*.php', GLOB_BRACE);
        
        foreach ($template_files as $file) {
            $templates[] = [
                'file' => basename($file),
                'path' => str_replace($path . '/', '', $file),
                'type' => $this->determine_template_type(basename($file))
            ];
        }
        
        return $templates;
    }
    
    /**
     * Determine template type
     */
    private function determine_template_type($filename) {
        if (strpos($filename, 'single') !== false) return 'single';
        if (strpos($filename, 'loop') !== false) return 'loop';
        if (strpos($filename, 'form') !== false) return 'form';
        if (strpos($filename, 'index') !== false) return 'index';
        if (strpos($filename, 'widget') !== false) return 'widget';
        return 'partial';
    }
    
    /**
     * Scan admin pages
     */
    private function scan_admin_pages($path) {
        $admin_pages = [];
        $php_files = glob($path . '/**/admin/**/*.php', GLOB_BRACE);
        
        foreach ($php_files as $file) {
            $content = file_get_contents($file);
            
            // Find add_menu_page or add_submenu_page calls
            if (preg_match_all('/add_(?:menu|submenu)_page\s*\([^,]+,\s*[\'"]([^\'"]+)/', $content, $matches)) {
                foreach ($matches[1] as $page_title) {
                    $admin_pages[] = [
                        'title' => $page_title,
                        'file' => str_replace($path . '/', '', $file)
                    ];
                }
            }
        }
        
        return $admin_pages;
    }
    
    /**
     * Scan shortcodes
     */
    private function scan_shortcodes($path) {
        $shortcodes = [];
        $php_files = glob($path . '/**/*.php', GLOB_BRACE);
        
        foreach ($php_files as $file) {
            $content = file_get_contents($file);
            
            // Find add_shortcode calls
            if (preg_match_all('/add_shortcode\s*\(\s*[\'"]([^\'"]+)/', $content, $matches)) {
                foreach ($matches[1] as $shortcode) {
                    $shortcodes[] = [
                        'tag' => $shortcode,
                        'file' => str_replace($path . '/', '', $file)
                    ];
                }
            }
        }
        
        return $shortcodes;
    }
    
    /**
     * Scan blocks
     */
    private function scan_blocks($path) {
        $blocks = [];
        
        // Look for block.json files
        $block_files = glob($path . '/**/block.json', GLOB_BRACE);
        
        foreach ($block_files as $file) {
            $block_data = json_decode(file_get_contents($file), true);
            if ($block_data) {
                $blocks[] = [
                    'name' => $block_data['name'] ?? 'unknown',
                    'title' => $block_data['title'] ?? 'Unknown Block',
                    'category' => $block_data['category'] ?? 'buddypress',
                    'file' => str_replace($path . '/', '', $file)
                ];
            }
        }
        
        return $blocks;
    }
    
    /**
     * Scan assets
     */
    private function scan_assets($path) {
        $assets = [
            'css' => [],
            'js' => [],
            'images' => []
        ];
        
        // CSS files
        $css_files = glob($path . '/**/*.css', GLOB_BRACE);
        foreach ($css_files as $file) {
            $assets['css'][] = [
                'file' => basename($file),
                'size' => filesize($file),
                'minified' => strpos(basename($file), '.min.css') !== false
            ];
        }
        
        // JS files
        $js_files = glob($path . '/**/*.js', GLOB_BRACE);
        foreach ($js_files as $file) {
            $assets['js'][] = [
                'file' => basename($file),
                'size' => filesize($file),
                'minified' => strpos(basename($file), '.min.js') !== false
            ];
        }
        
        // Image files
        $image_extensions = ['png', 'jpg', 'jpeg', 'gif', 'svg'];
        foreach ($image_extensions as $ext) {
            $image_files = glob($path . '/**/*.' . $ext, GLOB_BRACE);
            foreach ($image_files as $file) {
                $assets['images'][] = [
                    'file' => basename($file),
                    'type' => $ext,
                    'size' => filesize($file)
                ];
            }
        }
        
        return $assets;
    }
    
    /**
     * Analyze dependencies
     */
    private function analyze_dependencies($path) {
        $dependencies = [];
        $php_files = glob($path . '/**/*.php', GLOB_BRACE);
        
        foreach ($php_files as $file) {
            $content = file_get_contents($file);
            
            // Check for component dependencies
            foreach ($this->components as $comp_id => $comp_name) {
                if ($comp_id === basename($path, 'bp-')) continue;
                
                if (preg_match('/bp_is_' . $comp_id . '_component|buddypress\(\)->' . $comp_id . '/', $content)) {
                    if (!in_array($comp_id, $dependencies)) {
                        $dependencies[] = $comp_id;
                    }
                }
            }
        }
        
        return $dependencies;
    }
    
    /**
     * Calculate metrics for component
     */
    private function calculate_metrics($data) {
        $metrics = [
            'total_files' => count($data['files']),
            'php_files' => count(array_filter($data['files'], fn($f) => $f['type'] === 'php')),
            'total_classes' => count($data['classes']),
            'total_functions' => count($data['functions']),
            'total_hooks' => count($data['hooks']),
            'action_hooks' => count(array_filter($data['hooks'], fn($h) => $h['type'] === 'action')),
            'filter_hooks' => count(array_filter($data['hooks'], fn($h) => $h['type'] === 'filter')),
            'rest_endpoints' => count($data['rest_api']),
            'ajax_handlers' => count($data['ajax']),
            'database_tables' => count($data['database']['tables']),
            'templates' => count($data['templates']),
            'admin_pages' => count($data['admin_pages']),
            'shortcodes' => count($data['shortcodes']),
            'blocks' => count($data['blocks']),
            'css_files' => count($data['assets']['css']),
            'js_files' => count($data['assets']['js']),
            'dependencies' => count($data['dependencies'])
        ];
        
        // Calculate complexity score
        $metrics['complexity_score'] = 
            ($metrics['total_classes'] * 10) +
            ($metrics['total_functions'] * 3) +
            ($metrics['total_hooks'] * 2) +
            ($metrics['rest_endpoints'] * 15) +
            ($metrics['ajax_handlers'] * 8) +
            ($metrics['database_tables'] * 20) +
            ($metrics['blocks'] * 12);
        
        return $metrics;
    }
    
    /**
     * Display component summary
     */
    private function display_component_summary($component_id) {
        $data = $this->component_results[$component_id];
        
        if (!$data['exists']) {
            echo "  ❌ Component directory not found\n";
            return;
        }
        
        $metrics = $data['metrics'];
        
        echo "  📊 Files: {$metrics['total_files']} ({$metrics['php_files']} PHP)\n";
        echo "  🏗️  Classes: {$metrics['total_classes']}\n";
        echo "  🔧 Functions: {$metrics['total_functions']}\n";
        echo "  🪝 Hooks: {$metrics['total_hooks']} ({$metrics['action_hooks']} actions, {$metrics['filter_hooks']} filters)\n";
        echo "  🌐 REST API: {$metrics['rest_endpoints']} endpoints\n";
        echo "  ⚡ AJAX: {$metrics['ajax_handlers']} handlers\n";
        echo "  💾 Database: {$metrics['database_tables']} tables\n";
        echo "  📄 Templates: {$metrics['templates']}\n";
        echo "  🎨 Assets: {$metrics['css_files']} CSS, {$metrics['js_files']} JS\n";
        echo "  🔗 Dependencies: " . implode(', ', $data['dependencies'] ?: ['none']) . "\n";
        echo "  📈 Complexity Score: {$metrics['complexity_score']}\n";
        
        // Show REST endpoints if any
        if (!empty($data['rest_api'])) {
            echo "\n  🌐 REST Endpoints:\n";
            foreach ($data['rest_api'] as $endpoint) {
                echo "     • {$endpoint['route']} [" . implode(', ', $endpoint['methods']) . "]\n";
            }
        }
    }
    
    /**
     * Display overall summary
     */
    private function display_overall_summary() {
        echo str_repeat("=", 70) . "\n";
        echo "📊 OVERALL SUMMARY\n";
        echo str_repeat("=", 70) . "\n\n";
        
        $totals = [
            'files' => 0,
            'classes' => 0,
            'functions' => 0,
            'hooks' => 0,
            'rest' => 0,
            'ajax' => 0,
            'complexity' => 0
        ];
        
        foreach ($this->component_results as $comp_id => $data) {
            if ($data['exists']) {
                $totals['files'] += $data['metrics']['total_files'];
                $totals['classes'] += $data['metrics']['total_classes'];
                $totals['functions'] += $data['metrics']['total_functions'];
                $totals['hooks'] += $data['metrics']['total_hooks'];
                $totals['rest'] += $data['metrics']['rest_endpoints'];
                $totals['ajax'] += $data['metrics']['ajax_handlers'];
                $totals['complexity'] += $data['metrics']['complexity_score'];
            }
        }
        
        echo "  Total Files: {$totals['files']}\n";
        echo "  Total Classes: {$totals['classes']}\n";
        echo "  Total Functions: {$totals['functions']}\n";
        echo "  Total Hooks: {$totals['hooks']}\n";
        echo "  Total REST Endpoints: {$totals['rest']}\n";
        echo "  Total AJAX Handlers: {$totals['ajax']}\n";
        echo "  Total Complexity: {$totals['complexity']}\n";
        
        // Component ranking by complexity
        echo "\n📈 Components by Complexity:\n";
        $ranked = [];
        foreach ($this->component_results as $comp_id => $data) {
            if ($data['exists']) {
                $ranked[$comp_id] = $data['metrics']['complexity_score'];
            }
        }
        arsort($ranked);
        
        $rank = 1;
        foreach ($ranked as $comp_id => $score) {
            echo "  {$rank}. {$this->components[$comp_id]}: {$score}\n";
            $rank++;
        }
    }
    
    /**
     * Export results to JSON
     */
    public function export_results($filename = null) {
        if (!$filename) {
            $upload_dir = wp_upload_dir();
            $filename = $upload_dir['basedir'] . '/wbcom-scan/buddypress-deep-scan-' . date('Y-m-d-His') . '.json';
        }
        
        // Ensure directory exists
        $dir = dirname($filename);
        if (!is_dir($dir)) {
            wp_mkdir_p($dir);
        }
        
        // Add metadata
        $export_data = [
            'scan_date' => date('Y-m-d H:i:s'),
            'buddypress_version' => defined('BP_VERSION') ? BP_VERSION : 'unknown',
            'wordpress_version' => get_bloginfo('version'),
            'php_version' => PHP_VERSION,
            'total_rest_routes' => count($this->rest_routes),
            'components' => $this->component_results,
            'rest_routes' => $this->rest_routes
        ];
        
        file_put_contents($filename, json_encode($export_data, JSON_PRETTY_PRINT));
        
        echo "\n✅ Results exported to: {$filename}\n";
        
        return $filename;
    }
}

// If run from command line
if (php_sapi_name() === 'cli') {
    // Load WordPress
    $wp_load_paths = [
        dirname(dirname(dirname(dirname(dirname(__FILE__))))) . '/wp-load.php',
        dirname(dirname(dirname(dirname(__FILE__)))) . '/wp-load.php',
        dirname(dirname(dirname(__FILE__))) . '/wp-load.php',
        '/Users/varundubey/Local Sites/buddynext/app/public/wp-load.php'
    ];
    
    foreach ($wp_load_paths as $path) {
        if (file_exists($path)) {
            require_once $path;
            break;
        }
    }
    
    if (!defined('ABSPATH')) {
        die("WordPress not loaded. Please run from WordPress root.\n");
    }
    
    // Run scanner
    $scanner = new BP_Deep_Component_Scanner();
    $results = $scanner->scan_all_components();
    $scanner->export_results();
}