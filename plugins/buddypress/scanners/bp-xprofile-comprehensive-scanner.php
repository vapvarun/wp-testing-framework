<?php
/**
 * BuddyPress XProfile (Extended Profiles) Comprehensive Scanner
 * 
 * Analyzes all XProfile features based on BuddyPress's own unit tests
 * to ensure complete functionality coverage
 */

class BP_XProfile_Comprehensive_Scanner {
    
    private $xprofile_path;
    private $test_path;
    private $features = [];
    private $field_types = [];
    private $missing_coverage = [];
    
    /**
     * Complete XProfile feature list based on BuddyPress unit tests
     */
    private $xprofile_features = [
        'field_groups' => [
            'name' => 'Field Groups Management',
            'features' => [
                'create_field_group' => 'Create new field group',
                'update_field_group' => 'Update field group details',
                'delete_field_group' => 'Delete field group',
                'reorder_field_groups' => 'Reorder field groups',
                'get_field_groups' => 'Retrieve field groups',
                'duplicate_field_group' => 'Duplicate field group',
                'group_visibility' => 'Set group visibility',
                'group_description' => 'Add group description',
                'repeater_fields' => 'Support repeater fields in groups'
            ]
        ],
        'fields' => [
            'name' => 'Profile Fields Management',
            'features' => [
                'create_field' => 'Create new profile field',
                'update_field' => 'Update field properties',
                'delete_field' => 'Delete profile field',
                'reorder_fields' => 'Reorder fields within group',
                'required_fields' => 'Mark fields as required',
                'default_values' => 'Set default field values',
                'field_visibility' => 'Set field visibility levels',
                'field_autolink' => 'Enable field autolinking',
                'conditional_fields' => 'Conditional field display',
                'field_validation' => 'Custom field validation',
                'field_dependencies' => 'Field dependencies'
            ]
        ],
        'field_types' => [
            'name' => 'Field Types Support',
            'types' => [
                'textbox' => 'Single line text input',
                'textarea' => 'Multi-line text area',
                'datebox' => 'Date selector with formatting',
                'selectbox' => 'Dropdown select box',
                'multiselectbox' => 'Multiple selection box',
                'radiobutton' => 'Radio button options',
                'checkbox' => 'Checkbox options',
                'checkbox_acceptance' => 'Terms acceptance checkbox',
                'number' => 'Number input field',
                'url' => 'URL input with validation',
                'telephone' => 'Phone number input',
                'wordpress' => 'WordPress user fields',
                'wordpress_biography' => 'WordPress bio field',
                'wordpress_textbox' => 'WordPress text field',
                'placeholder' => 'Placeholder text support',
                'custom_field_type' => 'Custom field type API'
            ]
        ],
        'data_management' => [
            'name' => 'Profile Data Management',
            'features' => [
                'save_field_data' => 'Save user field data',
                'get_field_data' => 'Retrieve user field data',
                'delete_field_data' => 'Delete user field data',
                'bulk_update_data' => 'Bulk update field data',
                'data_validation' => 'Validate data before save',
                'data_sanitization' => 'Sanitize user input',
                'data_encryption' => 'Encrypt sensitive data',
                'data_export' => 'Export profile data',
                'data_import' => 'Import profile data',
                'data_migration' => 'Migrate data between fields'
            ]
        ],
        'visibility' => [
            'name' => 'Visibility Controls',
            'features' => [
                'public_visibility' => 'Public profile fields',
                'logged_in_visibility' => 'Logged-in users only',
                'friends_visibility' => 'Friends only visibility',
                'admins_only' => 'Admin only fields',
                'custom_visibility' => 'Custom visibility rules',
                'per_field_visibility' => 'Per-field visibility settings',
                'enforce_visibility' => 'Enforce visibility on frontend',
                'visibility_fallback' => 'Visibility fallback options'
            ]
        ],
        'search_filter' => [
            'name' => 'Search and Filtering',
            'features' => [
                'member_search' => 'Search members by profile fields',
                'advanced_search' => 'Advanced profile search',
                'field_search' => 'Search within specific fields',
                'range_search' => 'Range searches (dates, numbers)',
                'keyword_search' => 'Keyword matching',
                'faceted_search' => 'Faceted search filters',
                'search_operators' => 'Search operators (AND, OR, NOT)',
                'saved_searches' => 'Save search queries'
            ]
        ],
        'validation' => [
            'name' => 'Validation and Sanitization',
            'features' => [
                'required_validation' => 'Required field validation',
                'format_validation' => 'Format validation (email, URL, etc)',
                'length_validation' => 'Min/max length validation',
                'pattern_validation' => 'Regex pattern validation',
                'custom_validation' => 'Custom validation callbacks',
                'xss_prevention' => 'XSS attack prevention',
                'sql_injection_prevention' => 'SQL injection prevention',
                'html_filtering' => 'HTML content filtering'
            ]
        ],
        'admin_features' => [
            'name' => 'Admin Management',
            'features' => [
                'admin_ui' => 'Admin interface for fields',
                'drag_drop_ordering' => 'Drag and drop field ordering',
                'field_options_management' => 'Manage field options',
                'bulk_actions' => 'Bulk field operations',
                'field_stats' => 'Field usage statistics',
                'profile_completion' => 'Profile completion tracking',
                'admin_validation' => 'Admin-side validation',
                'field_migration' => 'Field type migration'
            ]
        ],
        'api_integration' => [
            'name' => 'API and Integration',
            'features' => [
                'rest_api_fields' => 'REST API for fields',
                'rest_api_groups' => 'REST API for groups',
                'rest_api_data' => 'REST API for profile data',
                'graphql_support' => 'GraphQL query support',
                'webhook_integration' => 'Webhook on profile update',
                'third_party_sync' => 'Sync with third-party services',
                'ajax_operations' => 'AJAX field operations',
                'batch_api' => 'Batch API operations'
            ]
        ],
        'templates' => [
            'name' => 'Template System',
            'features' => [
                'field_templates' => 'Custom field templates',
                'group_templates' => 'Custom group templates',
                'profile_templates' => 'Profile page templates',
                'edit_templates' => 'Edit form templates',
                'loop_templates' => 'Profile loop templates',
                'widget_templates' => 'Widget display templates',
                'email_templates' => 'Email notification templates',
                'template_overrides' => 'Theme template overrides'
            ]
        ],
        'performance' => [
            'name' => 'Performance Features',
            'features' => [
                'field_caching' => 'Field data caching',
                'query_optimization' => 'Optimized database queries',
                'lazy_loading' => 'Lazy load profile data',
                'batch_processing' => 'Batch data processing',
                'index_optimization' => 'Database index optimization',
                'cache_invalidation' => 'Smart cache invalidation',
                'cdn_support' => 'CDN support for avatars',
                'async_processing' => 'Async data processing'
            ]
        ],
        'hooks_filters' => [
            'name' => 'Hooks and Filters',
            'features' => [
                'field_display_filters' => 'Filter field display',
                'data_save_actions' => 'Actions on data save',
                'validation_filters' => 'Custom validation filters',
                'visibility_filters' => 'Visibility control filters',
                'template_filters' => 'Template output filters',
                'admin_hooks' => 'Admin interface hooks',
                'api_filters' => 'API response filters',
                'migration_hooks' => 'Data migration hooks'
            ]
        ]
    ];
    
    /**
     * Initialize scanner
     */
    public function __construct() {
        $this->xprofile_path = WP_PLUGIN_DIR . '/buddypress/src/bp-xprofile';
        $this->test_path = WP_PLUGIN_DIR . '/buddypress/tests/phpunit/testcases/xprofile';
        
        if (!is_dir($this->xprofile_path)) {
            throw new Exception("XProfile component not found at: {$this->xprofile_path}");
        }
    }
    
    /**
     * Run comprehensive scan
     */
    public function scan() {
        echo "🔍 BuddyPress XProfile Comprehensive Feature Scan\n";
        echo str_repeat("=", 70) . "\n\n";
        
        // Scan field types
        $this->scan_field_types();
        
        // Scan existing tests
        $this->scan_existing_tests();
        
        // Scan component files
        $this->scan_component_files();
        
        // Analyze features
        $this->analyze_feature_coverage();
        
        // Generate report
        $this->generate_report();
        
        return $this->features;
    }
    
    /**
     * Scan all field types
     */
    private function scan_field_types() {
        echo "📝 Scanning Field Types...\n";
        
        $field_type_files = glob($this->xprofile_path . '/classes/class-bp-xprofile-field-type-*.php');
        
        foreach ($field_type_files as $file) {
            $type_name = str_replace(
                ['class-bp-xprofile-field-type-', '.php'],
                '',
                basename($file)
            );
            
            $this->field_types[$type_name] = [
                'file' => $file,
                'class' => $this->extract_class_features($file),
                'methods' => $this->extract_methods($file)
            ];
            
            echo "  ✓ Found field type: {$type_name}\n";
        }
        
        echo "  Total field types: " . count($this->field_types) . "\n\n";
    }
    
    /**
     * Scan existing unit tests
     */
    private function scan_existing_tests() {
        echo "🧪 Scanning Existing Tests...\n";
        
        if (!is_dir($this->test_path)) {
            echo "  ⚠️ Test directory not found\n\n";
            return;
        }
        
        $test_files = glob($this->test_path . '/*.php');
        $test_coverage = [];
        
        foreach ($test_files as $file) {
            $content = file_get_contents($file);
            
            // Extract test methods
            preg_match_all('/public function (test_\w+)/', $content, $matches);
            
            $test_coverage[basename($file)] = [
                'file' => $file,
                'tests' => $matches[1] ?? [],
                'count' => count($matches[1] ?? [])
            ];
            
            echo "  ✓ " . basename($file) . ": " . count($matches[1] ?? []) . " tests\n";
        }
        
        $this->features['existing_tests'] = $test_coverage;
        
        $total_tests = array_sum(array_column($test_coverage, 'count'));
        echo "  Total existing tests: {$total_tests}\n\n";
    }
    
    /**
     * Scan component files
     */
    private function scan_component_files() {
        echo "📂 Scanning Component Structure...\n";
        
        $structure = [
            'admin' => glob($this->xprofile_path . '/admin/*.php'),
            'classes' => glob($this->xprofile_path . '/classes/*.php'),
            'screens' => glob($this->xprofile_path . '/screens/*.php'),
            'actions' => glob($this->xprofile_path . '/actions/*.php'),
            'functions' => glob($this->xprofile_path . '/*functions*.php'),
            'templates' => $this->find_templates()
        ];
        
        foreach ($structure as $type => $files) {
            echo "  • " . ucfirst($type) . ": " . count($files) . " files\n";
        }
        
        $this->features['structure'] = $structure;
        echo "\n";
    }
    
    /**
     * Find template files
     */
    private function find_templates() {
        $template_paths = [
            WP_PLUGIN_DIR . '/buddypress/bp-templates/bp-legacy/buddypress/members/single/profile',
            WP_PLUGIN_DIR . '/buddypress/bp-templates/bp-nouveau/buddypress/members/single/profile'
        ];
        
        $templates = [];
        foreach ($template_paths as $path) {
            if (is_dir($path)) {
                $templates = array_merge($templates, glob($path . '/*.php'));
            }
        }
        
        return $templates;
    }
    
    /**
     * Extract class features from file
     */
    private function extract_class_features($file) {
        $content = file_get_contents($file);
        $features = [];
        
        // Check for key features
        $feature_patterns = [
            'validation' => '/function.*validate|validation/i',
            'sanitization' => '/function.*sanitize|sanitization/i',
            'display' => '/function.*display|render/i',
            'admin' => '/function.*admin/i',
            'save' => '/function.*save|update/i',
            'format' => '/function.*format/i'
        ];
        
        foreach ($feature_patterns as $feature => $pattern) {
            if (preg_match($pattern, $content)) {
                $features[] = $feature;
            }
        }
        
        return $features;
    }
    
    /**
     * Extract methods from file
     */
    private function extract_methods($file) {
        $content = file_get_contents($file);
        preg_match_all('/public function (\w+)/', $content, $matches);
        return $matches[1] ?? [];
    }
    
    /**
     * Analyze feature coverage
     */
    private function analyze_feature_coverage() {
        echo "📊 Analyzing Feature Coverage...\n";
        
        foreach ($this->xprofile_features as $category => $data) {
            $covered = 0;
            $total = 0;
            
            if (isset($data['features'])) {
                $total = count($data['features']);
                // Check coverage based on existing tests and files
                foreach ($data['features'] as $feature => $description) {
                    if ($this->is_feature_covered($feature)) {
                        $covered++;
                    } else {
                        $this->missing_coverage[$category][] = $feature;
                    }
                }
            } elseif (isset($data['types'])) {
                $total = count($data['types']);
                foreach ($data['types'] as $type => $description) {
                    if (isset($this->field_types[$type]) || 
                        isset($this->field_types[str_replace('_', '-', $type)])) {
                        $covered++;
                    } else {
                        $this->missing_coverage[$category][] = $type;
                    }
                }
            }
            
            $percentage = $total > 0 ? round(($covered / $total) * 100, 2) : 0;
            echo "  • {$data['name']}: {$covered}/{$total} ({$percentage}%)\n";
            
            $this->features['coverage'][$category] = [
                'name' => $data['name'],
                'covered' => $covered,
                'total' => $total,
                'percentage' => $percentage
            ];
        }
        echo "\n";
    }
    
    /**
     * Check if feature is covered
     */
    private function is_feature_covered($feature) {
        // Check in existing tests
        if (isset($this->features['existing_tests'])) {
            foreach ($this->features['existing_tests'] as $test_file) {
                foreach ($test_file['tests'] as $test) {
                    if (stripos($test, $feature) !== false) {
                        return true;
                    }
                }
            }
        }
        
        // Check in field types
        foreach ($this->field_types as $type) {
            foreach ($type['methods'] as $method) {
                if (stripos($method, $feature) !== false) {
                    return true;
                }
            }
        }
        
        return false;
    }
    
    /**
     * Generate comprehensive report
     */
    private function generate_report() {
        echo str_repeat("=", 70) . "\n";
        echo "📋 XPROFILE COMPREHENSIVE REPORT\n";
        echo str_repeat("=", 70) . "\n\n";
        
        // Summary
        echo "📊 Overall Coverage Summary:\n";
        $total_features = 0;
        $total_covered = 0;
        
        foreach ($this->features['coverage'] as $category) {
            $total_features += $category['total'];
            $total_covered += $category['covered'];
        }
        
        $overall_percentage = $total_features > 0 ? 
            round(($total_covered / $total_features) * 100, 2) : 0;
        
        echo "  Total Features: {$total_features}\n";
        echo "  Covered: {$total_covered}\n";
        echo "  Coverage: {$overall_percentage}%\n\n";
        
        // Field Types
        echo "📝 Field Types Found (" . count($this->field_types) . "):\n";
        foreach ($this->field_types as $type => $data) {
            echo "  • {$type}\n";
        }
        echo "\n";
        
        // Missing Coverage
        if (!empty($this->missing_coverage)) {
            echo "⚠️ Missing Coverage:\n";
            foreach ($this->missing_coverage as $category => $features) {
                if (!empty($features)) {
                    echo "  {$category}:\n";
                    foreach ($features as $feature) {
                        echo "    - {$feature}\n";
                    }
                }
            }
            echo "\n";
        }
        
        // Recommendations
        echo "🔧 Recommendations:\n";
        echo "  1. Implement tests for custom field types\n";
        echo "  2. Add REST API integration tests\n";
        echo "  3. Test visibility controls thoroughly\n";
        echo "  4. Validate data sanitization\n";
        echo "  5. Test field migration scenarios\n";
    }
    
    /**
     * Export results
     */
    public function export_results($filename = null) {
        if (!$filename) {
            $upload_dir = wp_upload_dir();
            $filename = $upload_dir['basedir'] . '/wbcom-scan/buddypress/components/xprofile-comprehensive-scan-' . 
                       date('Y-m-d-His') . '.json';
        }
        
        $dir = dirname($filename);
        if (!is_dir($dir)) {
            wp_mkdir_p($dir);
        }
        
        $export_data = [
            'scan_date' => date('Y-m-d H:i:s'),
            'features' => $this->features,
            'field_types' => $this->field_types,
            'missing_coverage' => $this->missing_coverage,
            'feature_map' => $this->xprofile_features
        ];
        
        file_put_contents($filename, json_encode($export_data, JSON_PRETTY_PRINT));
        
        echo "\n✅ Results exported to: {$filename}\n";
        
        return $filename;
    }
}

// Run if called directly
if (php_sapi_name() === 'cli') {
    // Load WordPress
    $wp_load_paths = [
        dirname(dirname(dirname(dirname(dirname(__FILE__))))) . '/wp-load.php',
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
    $scanner = new BP_XProfile_Comprehensive_Scanner();
    $results = $scanner->scan();
    $scanner->export_results();
}