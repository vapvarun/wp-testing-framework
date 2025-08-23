<?php
/**
 * BuddyPress Template to REST API Mapper
 * 
 * Maps template files and their functionality to corresponding REST API endpoints
 * Identifies gaps and provides recommendations for API completeness
 */

class BP_Template_API_Mapper {
    
    private $buddypress_path;
    private $template_mappings = [];
    private $api_endpoints = [];
    private $coverage_report = [];
    
    /**
     * Template to API endpoint mappings
     */
    private $template_api_map = [
        // Members templates
        'members/index.php' => [
            'description' => 'Members directory page',
            'api_endpoints' => [
                'GET /buddypress/v2/members' => 'List members',
                'GET /buddypress/v2/members?search=' => 'Search members',
                'GET /buddypress/v2/members?type=' => 'Filter members by type'
            ],
            'ajax_actions' => [
                'bp_members_filter' => 'Filter members via AJAX'
            ]
        ],
        'members/single/profile.php' => [
            'description' => 'Single member profile view',
            'api_endpoints' => [
                'GET /buddypress/v2/members/{id}' => 'Get member details',
                'GET /buddypress/v2/xprofile/fields' => 'Get profile fields',
                'GET /buddypress/v2/members/{id}/avatar' => 'Get member avatar'
            ]
        ],
        'members/single/profile/edit.php' => [
            'description' => 'Edit member profile',
            'api_endpoints' => [
                'PUT /buddypress/v2/members/{id}' => 'Update member details',
                'PUT /buddypress/v2/xprofile/fields/{field_id}' => 'Update profile field'
            ],
            'form_actions' => [
                'xprofile_screen_edit_profile' => 'Handle profile edit form'
            ]
        ],
        'members/single/profile/change-avatar.php' => [
            'description' => 'Change member avatar',
            'api_endpoints' => [
                'POST /buddypress/v2/members/{id}/avatar' => 'Upload new avatar',
                'DELETE /buddypress/v2/members/{id}/avatar' => 'Delete avatar'
            ]
        ],
        'members/single/profile/change-cover-image.php' => [
            'description' => 'Change member cover image',
            'api_endpoints' => [
                'POST /buddypress/v2/members/{id}/cover' => 'Upload cover image',
                'DELETE /buddypress/v2/members/{id}/cover' => 'Delete cover image'
            ]
        ],
        
        // Activity templates
        'activity/index.php' => [
            'description' => 'Activity stream page',
            'api_endpoints' => [
                'GET /buddypress/v2/activity' => 'Get activity stream',
                'GET /buddypress/v2/activity?filter=' => 'Filter activities',
                'GET /buddypress/v2/activity?page=' => 'Paginate activities'
            ]
        ],
        'activity/post-form.php' => [
            'description' => 'Activity post form',
            'api_endpoints' => [
                'POST /buddypress/v2/activity' => 'Post new activity'
            ],
            'ajax_actions' => [
                'bp_post_update' => 'Post activity via AJAX'
            ]
        ],
        'activity/entry.php' => [
            'description' => 'Single activity entry',
            'api_endpoints' => [
                'GET /buddypress/v2/activity/{id}' => 'Get single activity',
                'POST /buddypress/v2/activity/{id}/favorite' => 'Favorite activity',
                'DELETE /buddypress/v2/activity/{id}' => 'Delete activity'
            ]
        ],
        'activity/comment.php' => [
            'description' => 'Activity comment',
            'api_endpoints' => [
                'POST /buddypress/v2/activity/{id}/comment' => 'Add comment',
                'DELETE /buddypress/v2/activity/comment/{id}' => 'Delete comment'
            ]
        ],
        
        // Groups templates
        'groups/index.php' => [
            'description' => 'Groups directory',
            'api_endpoints' => [
                'GET /buddypress/v2/groups' => 'List groups',
                'GET /buddypress/v2/groups?search=' => 'Search groups'
            ]
        ],
        'groups/single/home.php' => [
            'description' => 'Single group home',
            'api_endpoints' => [
                'GET /buddypress/v2/groups/{id}' => 'Get group details'
            ]
        ],
        'groups/single/members.php' => [
            'description' => 'Group members list',
            'api_endpoints' => [
                'GET /buddypress/v2/groups/{id}/members' => 'Get group members',
                'POST /buddypress/v2/groups/{id}/members' => 'Add member to group',
                'DELETE /buddypress/v2/groups/{id}/members/{user_id}' => 'Remove member'
            ]
        ],
        'groups/single/admin.php' => [
            'description' => 'Group admin settings',
            'api_endpoints' => [
                'PUT /buddypress/v2/groups/{id}' => 'Update group settings',
                'PUT /buddypress/v2/groups/{id}/members/{user_id}' => 'Update member role'
            ]
        ],
        'groups/single/invite.php' => [
            'description' => 'Group invitations',
            'api_endpoints' => [
                'POST /buddypress/v2/groups/invites' => 'Send group invitation',
                'GET /buddypress/v2/groups/{id}/invites' => 'Get pending invites'
            ]
        ],
        'groups/create.php' => [
            'description' => 'Create new group',
            'api_endpoints' => [
                'POST /buddypress/v2/groups' => 'Create group'
            ],
            'form_actions' => [
                'groups_action_create_group' => 'Handle group creation'
            ]
        ],
        
        // Messages templates
        'members/single/messages.php' => [
            'description' => 'Messages inbox',
            'api_endpoints' => [
                'GET /buddypress/v2/messages' => 'Get messages',
                'GET /buddypress/v2/messages?box=' => 'Get inbox/sent messages'
            ]
        ],
        'members/single/messages/compose.php' => [
            'description' => 'Compose message',
            'api_endpoints' => [
                'POST /buddypress/v2/messages' => 'Send new message'
            ],
            'ajax_actions' => [
                'messages_send_message' => 'Send message via AJAX'
            ]
        ],
        'members/single/messages/single.php' => [
            'description' => 'Single message thread',
            'api_endpoints' => [
                'GET /buddypress/v2/messages/{id}' => 'Get message thread',
                'POST /buddypress/v2/messages/{id}/reply' => 'Reply to message',
                'DELETE /buddypress/v2/messages/{id}' => 'Delete message'
            ]
        ],
        
        // Friends templates
        'members/single/friends.php' => [
            'description' => 'Friends list',
            'api_endpoints' => [
                'GET /buddypress/v2/friends' => 'Get friends list',
                'GET /buddypress/v2/friends/{user_id}' => 'Get user friends'
            ]
        ],
        'members/single/friends/requests.php' => [
            'description' => 'Friend requests',
            'api_endpoints' => [
                'GET /buddypress/v2/friends?status=pending' => 'Get pending requests',
                'POST /buddypress/v2/friends' => 'Send friend request',
                'PUT /buddypress/v2/friends/{id}/accept' => 'Accept request',
                'DELETE /buddypress/v2/friends/{id}' => 'Reject/Remove friend'
            ]
        ],
        
        // Notifications templates
        'members/single/notifications.php' => [
            'description' => 'Notifications list',
            'api_endpoints' => [
                'GET /buddypress/v2/notifications' => 'Get notifications',
                'PUT /buddypress/v2/notifications/{id}/read' => 'Mark as read',
                'DELETE /buddypress/v2/notifications/{id}' => 'Delete notification'
            ]
        ],
        'members/single/settings/notifications.php' => [
            'description' => 'Notification settings',
            'api_endpoints' => [
                'GET /buddypress/v2/notifications/settings' => 'Get settings',
                'PUT /buddypress/v2/notifications/settings' => 'Update settings'
            ]
        ],
        
        // Settings templates
        'members/single/settings/general.php' => [
            'description' => 'General settings',
            'api_endpoints' => [
                'GET /buddypress/v2/settings' => 'Get user settings',
                'PUT /buddypress/v2/settings' => 'Update settings'
            ]
        ],
        'members/single/settings/profile.php' => [
            'description' => 'Profile visibility settings',
            'api_endpoints' => [
                'PUT /buddypress/v2/xprofile/fields/{id}/visibility' => 'Update field visibility'
            ]
        ],
        
        // Registration/Login templates
        'members/register.php' => [
            'description' => 'Registration page',
            'api_endpoints' => [
                'POST /buddypress/v2/signup' => 'Register new user'
            ],
            'form_actions' => [
                'bp_core_signup_user' => 'Handle registration'
            ]
        ],
        'members/activate.php' => [
            'description' => 'Account activation',
            'api_endpoints' => [
                'POST /buddypress/v2/signup/activate' => 'Activate account'
            ]
        ]
    ];
    
    /**
     * Initialize mapper
     */
    public function __construct() {
        $this->buddypress_path = WP_PLUGIN_DIR . '/buddypress';
        
        if (!is_dir($this->buddypress_path)) {
            throw new Exception("BuddyPress not found at: {$this->buddypress_path}");
        }
        
        // Get actual REST API endpoints
        $this->load_rest_endpoints();
    }
    
    /**
     * Load registered REST API endpoints
     */
    private function load_rest_endpoints() {
        if (!function_exists('rest_get_server')) {
            return;
        }
        
        $server = rest_get_server();
        $routes = $server->get_routes();
        
        foreach ($routes as $route => $handlers) {
            if (strpos($route, '/buddypress/') !== false) {
                $this->api_endpoints[] = $route;
            }
        }
    }
    
    /**
     * Run template to API mapping analysis
     */
    public function analyze_mappings() {
        echo "🔍 BuddyPress Template to REST API Mapping Analysis\n";
        echo str_repeat("=", 70) . "\n\n";
        
        $this->analyze_template_coverage();
        $this->analyze_api_coverage();
        $this->identify_gaps();
        $this->generate_recommendations();
        $this->display_summary();
        
        return $this->coverage_report;
    }
    
    /**
     * Analyze template coverage
     */
    private function analyze_template_coverage() {
        echo "📄 TEMPLATE COVERAGE ANALYSIS\n";
        echo str_repeat("-", 50) . "\n\n";
        
        $templates_found = 0;
        $templates_with_api = 0;
        $templates_without_api = 0;
        
        foreach ($this->template_api_map as $template => $mapping) {
            $template_path = $this->find_template($template);
            $exists = !empty($template_path) && file_exists($template_path);
            
            $api_coverage = $this->check_api_endpoints($mapping['api_endpoints'] ?? []);
            
            $this->template_mappings[$template] = [
                'exists' => $exists,
                'path' => $template_path,
                'description' => $mapping['description'],
                'api_endpoints' => $mapping['api_endpoints'] ?? [],
                'api_coverage' => $api_coverage,
                'ajax_actions' => $mapping['ajax_actions'] ?? [],
                'form_actions' => $mapping['form_actions'] ?? []
            ];
            
            if ($exists) {
                $templates_found++;
                
                if ($api_coverage['covered'] > 0) {
                    $templates_with_api++;
                } else {
                    $templates_without_api++;
                }
            }
        }
        
        echo "  📊 Templates Analyzed: " . count($this->template_api_map) . "\n";
        echo "  ✅ Templates Found: {$templates_found}\n";
        echo "  🌐 Templates with API: {$templates_with_api}\n";
        echo "  ⚠️ Templates without API: {$templates_without_api}\n\n";
        
        // Show templates without API coverage
        if ($templates_without_api > 0) {
            echo "  Templates Missing API Coverage:\n";
            foreach ($this->template_mappings as $template => $data) {
                if ($data['exists'] && $data['api_coverage']['covered'] === 0) {
                    echo "    • {$template}\n";
                }
            }
            echo "\n";
        }
    }
    
    /**
     * Find template file
     */
    private function find_template($template) {
        $possible_paths = [
            $this->buddypress_path . '/bp-templates/bp-legacy/buddypress/' . $template,
            $this->buddypress_path . '/bp-templates/bp-nouveau/buddypress/' . $template,
            get_stylesheet_directory() . '/buddypress/' . $template,
            get_template_directory() . '/buddypress/' . $template
        ];
        
        foreach ($possible_paths as $path) {
            if (file_exists($path)) {
                return $path;
            }
        }
        
        return null;
    }
    
    /**
     * Check API endpoints
     */
    private function check_api_endpoints($endpoints) {
        $total = count($endpoints);
        $covered = 0;
        $missing = [];
        
        foreach ($endpoints as $endpoint => $description) {
            // Remove parameters for comparison
            $endpoint_pattern = preg_replace('/\{[^}]+\}/', '[^/]+', $endpoint);
            $endpoint_pattern = str_replace('/', '\/', $endpoint_pattern);
            
            $found = false;
            foreach ($this->api_endpoints as $registered) {
                if (preg_match('/^' . $endpoint_pattern . '/', $registered)) {
                    $found = true;
                    $covered++;
                    break;
                }
            }
            
            if (!$found) {
                $missing[] = $endpoint;
            }
        }
        
        return [
            'total' => $total,
            'covered' => $covered,
            'missing' => $missing,
            'percentage' => $total > 0 ? round(($covered / $total) * 100, 2) : 0
        ];
    }
    
    /**
     * Analyze API coverage
     */
    private function analyze_api_coverage() {
        echo "🌐 API ENDPOINT COVERAGE ANALYSIS\n";
        echo str_repeat("-", 50) . "\n\n";
        
        $component_coverage = [];
        
        foreach ($this->template_mappings as $template => $data) {
            // Extract component from template path
            $component = explode('/', $template)[0];
            if ($component === 'members' && strpos($template, 'members/single/') === 0) {
                // Extract sub-component
                $parts = explode('/', $template);
                if (isset($parts[2])) {
                    $component = 'members-' . $parts[2];
                }
            }
            
            if (!isset($component_coverage[$component])) {
                $component_coverage[$component] = [
                    'templates' => 0,
                    'api_endpoints' => 0,
                    'covered' => 0,
                    'missing' => []
                ];
            }
            
            $component_coverage[$component]['templates']++;
            $component_coverage[$component]['api_endpoints'] += $data['api_coverage']['total'];
            $component_coverage[$component]['covered'] += $data['api_coverage']['covered'];
            $component_coverage[$component]['missing'] = array_merge(
                $component_coverage[$component]['missing'],
                $data['api_coverage']['missing']
            );
        }
        
        // Display component coverage
        foreach ($component_coverage as $component => $coverage) {
            $percentage = $coverage['api_endpoints'] > 0 
                ? round(($coverage['covered'] / $coverage['api_endpoints']) * 100, 2)
                : 0;
            
            $status = $percentage >= 80 ? '✅' : ($percentage >= 60 ? '⚠️' : '❌');
            
            echo "  {$status} " . ucfirst($component) . ": {$percentage}% API coverage\n";
            echo "     Templates: {$coverage['templates']}, ";
            echo "Endpoints: {$coverage['covered']}/{$coverage['api_endpoints']}\n";
            
            if (!empty($coverage['missing'])) {
                echo "     Missing: " . implode(', ', array_slice($coverage['missing'], 0, 3));
                if (count($coverage['missing']) > 3) {
                    echo " +" . (count($coverage['missing']) - 3) . " more";
                }
                echo "\n";
            }
            echo "\n";
        }
        
        $this->coverage_report['component_coverage'] = $component_coverage;
    }
    
    /**
     * Identify gaps between templates and API
     */
    private function identify_gaps() {
        echo "⚠️ GAP ANALYSIS\n";
        echo str_repeat("-", 50) . "\n\n";
        
        $gaps = [
            'templates_without_api' => [],
            'api_without_templates' => [],
            'partial_coverage' => [],
            'missing_functionality' => []
        ];
        
        // Templates without API
        foreach ($this->template_mappings as $template => $data) {
            if ($data['exists'] && $data['api_coverage']['covered'] === 0) {
                $gaps['templates_without_api'][] = $template;
            } elseif ($data['exists'] && $data['api_coverage']['percentage'] < 100) {
                $gaps['partial_coverage'][] = [
                    'template' => $template,
                    'coverage' => $data['api_coverage']['percentage'],
                    'missing' => $data['api_coverage']['missing']
                ];
            }
        }
        
        // Check for API endpoints without template mapping
        foreach ($this->api_endpoints as $endpoint) {
            $found = false;
            foreach ($this->template_mappings as $data) {
                foreach ($data['api_endpoints'] as $mapped_endpoint => $desc) {
                    if (strpos($endpoint, str_replace(['{id}', '{user_id}', '{field_id}'], '', $mapped_endpoint)) !== false) {
                        $found = true;
                        break 2;
                    }
                }
            }
            
            if (!$found && strpos($endpoint, '/buddypress/v2/') !== false) {
                $gaps['api_without_templates'][] = $endpoint;
            }
        }
        
        // Identify missing functionality
        $critical_functions = [
            'bulk_operations' => 'Bulk delete/update operations',
            'batch_processing' => 'Batch API for multiple operations',
            'webhooks' => 'Webhook endpoints for real-time updates',
            'export_import' => 'Data export/import endpoints',
            'analytics' => 'Analytics and reporting endpoints'
        ];
        
        foreach ($critical_functions as $function => $description) {
            $found = false;
            foreach ($this->api_endpoints as $endpoint) {
                if (strpos($endpoint, $function) !== false) {
                    $found = true;
                    break;
                }
            }
            
            if (!$found) {
                $gaps['missing_functionality'][] = $description;
            }
        }
        
        // Display gaps
        if (!empty($gaps['templates_without_api'])) {
            echo "  📄 Templates without API endpoints:\n";
            foreach ($gaps['templates_without_api'] as $template) {
                echo "     • {$template}\n";
            }
            echo "\n";
        }
        
        if (!empty($gaps['partial_coverage'])) {
            echo "  ⚠️ Templates with partial API coverage:\n";
            foreach (array_slice($gaps['partial_coverage'], 0, 5) as $item) {
                echo "     • {$item['template']} ({$item['coverage']}%)\n";
            }
            echo "\n";
        }
        
        if (!empty($gaps['api_without_templates'])) {
            echo "  🌐 API endpoints without template mapping:\n";
            foreach (array_slice($gaps['api_without_templates'], 0, 5) as $endpoint) {
                echo "     • {$endpoint}\n";
            }
            echo "\n";
        }
        
        if (!empty($gaps['missing_functionality'])) {
            echo "  ❌ Missing API functionality:\n";
            foreach ($gaps['missing_functionality'] as $func) {
                echo "     • {$func}\n";
            }
            echo "\n";
        }
        
        $this->coverage_report['gaps'] = $gaps;
    }
    
    /**
     * Generate recommendations
     */
    private function generate_recommendations() {
        echo "🔧 RECOMMENDATIONS\n";
        echo str_repeat("-", 50) . "\n\n";
        
        $recommendations = [];
        
        // Priority 1: Templates without any API
        if (!empty($this->coverage_report['gaps']['templates_without_api'])) {
            $recommendations['high'][] = [
                'issue' => 'Templates without API endpoints',
                'action' => 'Create REST API endpoints for templates that currently have no API coverage',
                'templates' => array_slice($this->coverage_report['gaps']['templates_without_api'], 0, 3)
            ];
        }
        
        // Priority 2: Partial coverage
        if (!empty($this->coverage_report['gaps']['partial_coverage'])) {
            $low_coverage = array_filter($this->coverage_report['gaps']['partial_coverage'], function($item) {
                return $item['coverage'] < 50;
            });
            
            if (!empty($low_coverage)) {
                $recommendations['high'][] = [
                    'issue' => 'Templates with low API coverage (< 50%)',
                    'action' => 'Complete API implementation for partially covered templates',
                    'count' => count($low_coverage)
                ];
            }
        }
        
        // Priority 3: Missing functionality
        if (!empty($this->coverage_report['gaps']['missing_functionality'])) {
            $recommendations['medium'][] = [
                'issue' => 'Missing API functionality',
                'action' => 'Implement missing API features for better parity',
                'features' => $this->coverage_report['gaps']['missing_functionality']
            ];
        }
        
        // Priority 4: AJAX to REST migration
        $ajax_count = 0;
        foreach ($this->template_mappings as $data) {
            $ajax_count += count($data['ajax_actions'] ?? []);
        }
        
        if ($ajax_count > 0) {
            $recommendations['medium'][] = [
                'issue' => "Legacy AJAX handlers ({$ajax_count} found)",
                'action' => 'Migrate AJAX handlers to REST API endpoints for consistency'
            ];
        }
        
        // Display recommendations
        foreach (['high' => '🔴 HIGH PRIORITY', 'medium' => '🟡 MEDIUM PRIORITY', 'low' => '🟢 LOW PRIORITY'] as $priority => $label) {
            if (!empty($recommendations[$priority])) {
                echo "  {$label}:\n";
                foreach ($recommendations[$priority] as $rec) {
                    echo "    • {$rec['issue']}\n";
                    echo "      Action: {$rec['action']}\n";
                    if (isset($rec['templates'])) {
                        echo "      Templates: " . implode(', ', $rec['templates']) . "\n";
                    }
                    if (isset($rec['features'])) {
                        echo "      Features: " . implode(', ', array_slice($rec['features'], 0, 3)) . "\n";
                    }
                    echo "\n";
                }
            }
        }
        
        $this->coverage_report['recommendations'] = $recommendations;
    }
    
    /**
     * Display summary
     */
    private function display_summary() {
        echo str_repeat("=", 70) . "\n";
        echo "📊 MAPPING SUMMARY\n";
        echo str_repeat("=", 70) . "\n\n";
        
        $total_templates = count($this->template_api_map);
        $templates_found = count(array_filter($this->template_mappings, function($t) { return $t['exists']; }));
        $templates_with_full_api = count(array_filter($this->template_mappings, function($t) {
            return $t['exists'] && $t['api_coverage']['percentage'] === 100;
        }));
        
        $total_endpoints = 0;
        $covered_endpoints = 0;
        foreach ($this->template_mappings as $data) {
            $total_endpoints += $data['api_coverage']['total'];
            $covered_endpoints += $data['api_coverage']['covered'];
        }
        
        $overall_coverage = $total_endpoints > 0 
            ? round(($covered_endpoints / $total_endpoints) * 100, 2)
            : 0;
        
        echo "  📄 Templates: {$templates_found}/{$total_templates} found\n";
        echo "  🌐 API Endpoints: {$covered_endpoints}/{$total_endpoints} implemented\n";
        echo "  ✅ Full API Coverage: {$templates_with_full_api} templates\n";
        echo "  📈 Overall Coverage: {$overall_coverage}%\n\n";
        
        // Status indicator
        if ($overall_coverage >= 80) {
            echo "  ✅ EXCELLENT: API coverage is comprehensive\n";
        } elseif ($overall_coverage >= 60) {
            echo "  ⚠️ GOOD: API coverage needs some improvements\n";
        } else {
            echo "  ❌ NEEDS WORK: Significant API gaps exist\n";
        }
    }
    
    /**
     * Export mapping results
     */
    public function export_results($filename = null) {
        if (!$filename) {
            $upload_dir = wp_upload_dir();
            $filename = $upload_dir['basedir'] . '/wbcom-scan/buddypress/templates/template-api-mapping-' . date('Y-m-d-His') . '.json';
        }
        
        // Ensure directory exists
        $dir = dirname($filename);
        if (!is_dir($dir)) {
            wp_mkdir_p($dir);
        }
        
        $export_data = [
            'scan_date' => date('Y-m-d H:i:s'),
            'buddypress_version' => defined('BP_VERSION') ? BP_VERSION : 'unknown',
            'template_mappings' => $this->template_mappings,
            'registered_endpoints' => $this->api_endpoints,
            'coverage_report' => $this->coverage_report,
            'summary' => [
                'total_templates' => count($this->template_api_map),
                'templates_found' => count(array_filter($this->template_mappings, function($t) { return $t['exists']; })),
                'total_endpoints_mapped' => count($this->api_endpoints),
                'overall_coverage' => $this->calculate_overall_coverage()
            ]
        ];
        
        file_put_contents($filename, json_encode($export_data, JSON_PRETTY_PRINT));
        
        echo "\n✅ Results exported to: {$filename}\n";
        
        return $filename;
    }
    
    /**
     * Calculate overall coverage
     */
    private function calculate_overall_coverage() {
        $total = 0;
        $covered = 0;
        
        foreach ($this->template_mappings as $data) {
            $total += $data['api_coverage']['total'];
            $covered += $data['api_coverage']['covered'];
        }
        
        return $total > 0 ? round(($covered / $total) * 100, 2) : 0;
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
    
    // Run mapper
    $mapper = new BP_Template_API_Mapper();
    $results = $mapper->analyze_mappings();
    $mapper->export_results();
}