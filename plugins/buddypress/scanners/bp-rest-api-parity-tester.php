<?php
/**
 * BuddyPress REST API Feature Parity Tester
 * 
 * Tests that REST API endpoints provide 1:1 feature parity with frontend functionality
 */

class BP_REST_API_Parity_Tester {
    
    private $test_results = [];
    private $frontend_features = [];
    private $api_features = [];
    
    /**
     * Feature mapping between frontend and API
     */
    private $feature_map = [
        'members' => [
            'frontend' => [
                'view_profile' => 'View member profile page',
                'edit_profile' => 'Edit profile fields',
                'upload_avatar' => 'Upload profile avatar',
                'upload_cover' => 'Upload cover image',
                'view_directory' => 'Browse members directory',
                'search_members' => 'Search for members',
                'filter_members' => 'Filter members by type',
                'send_message' => 'Send private message to member',
                'add_friend' => 'Send friend request',
                'view_activity' => 'View member activity'
            ],
            'api' => [
                'GET /members/{id}' => 'view_profile',
                'PUT /members/{id}' => 'edit_profile',
                'POST /members/{id}/avatar' => 'upload_avatar',
                'POST /members/{id}/cover' => 'upload_cover',
                'GET /members' => 'view_directory',
                'GET /members?search=' => 'search_members',
                'GET /members?type=' => 'filter_members',
                'POST /messages' => 'send_message',
                'POST /friends' => 'add_friend',
                'GET /activity?user_id=' => 'view_activity'
            ]
        ],
        'activity' => [
            'frontend' => [
                'post_update' => 'Post activity update',
                'comment_activity' => 'Comment on activity',
                'favorite_activity' => 'Favorite/like activity',
                'delete_activity' => 'Delete own activity',
                'filter_activity' => 'Filter activity stream',
                'load_more' => 'Load more activities',
                'mention_user' => '@mention users',
                'add_media' => 'Attach media to activity',
                'share_activity' => 'Share activity'
            ],
            'api' => [
                'POST /activity' => 'post_update',
                'POST /activity/{id}/comment' => 'comment_activity',
                'POST /activity/{id}/favorite' => 'favorite_activity',
                'DELETE /activity/{id}' => 'delete_activity',
                'GET /activity?filter=' => 'filter_activity',
                'GET /activity?page=' => 'load_more',
                'POST /activity' => 'mention_user',
                'POST /activity' => 'add_media',
                'POST /activity' => 'share_activity'
            ]
        ],
        'groups' => [
            'frontend' => [
                'create_group' => 'Create new group',
                'edit_group' => 'Edit group settings',
                'join_group' => 'Join public group',
                'leave_group' => 'Leave group',
                'invite_members' => 'Invite members to group',
                'post_to_group' => 'Post in group activity',
                'manage_members' => 'Manage group members',
                'upload_avatar' => 'Upload group avatar',
                'upload_cover' => 'Upload group cover',
                'delete_group' => 'Delete group'
            ],
            'api' => [
                'POST /groups' => 'create_group',
                'PUT /groups/{id}' => 'edit_group',
                'POST /groups/{id}/members' => 'join_group',
                'DELETE /groups/{id}/members/{user_id}' => 'leave_group',
                'POST /groups/invites' => 'invite_members',
                'POST /activity?group_id=' => 'post_to_group',
                'PUT /groups/{id}/members/{user_id}' => 'manage_members',
                'POST /groups/{id}/avatar' => 'upload_avatar',
                'POST /groups/{id}/cover' => 'upload_cover',
                'DELETE /groups/{id}' => 'delete_group'
            ]
        ],
        'messages' => [
            'frontend' => [
                'compose_message' => 'Compose new message',
                'reply_message' => 'Reply to message',
                'delete_message' => 'Delete message',
                'mark_read' => 'Mark as read',
                'mark_unread' => 'Mark as unread',
                'star_message' => 'Star message',
                'search_messages' => 'Search messages',
                'bulk_delete' => 'Bulk delete messages'
            ],
            'api' => [
                'POST /messages' => 'compose_message',
                'POST /messages/{id}/reply' => 'reply_message',
                'DELETE /messages/{id}' => 'delete_message',
                'PUT /messages/{id}/read' => 'mark_read',
                'PUT /messages/{id}/unread' => 'mark_unread',
                'PUT /messages/{id}/star' => 'star_message',
                'GET /messages?search=' => 'search_messages',
                'DELETE /messages' => 'bulk_delete'
            ]
        ],
        'friends' => [
            'frontend' => [
                'send_request' => 'Send friend request',
                'accept_request' => 'Accept friend request',
                'reject_request' => 'Reject friend request',
                'remove_friend' => 'Remove friend',
                'view_friends' => 'View friends list',
                'view_requests' => 'View pending requests'
            ],
            'api' => [
                'POST /friends' => 'send_request',
                'PUT /friends/{id}/accept' => 'accept_request',
                'DELETE /friends/{id}' => 'reject_request',
                'DELETE /friends/{id}' => 'remove_friend',
                'GET /friends' => 'view_friends',
                'GET /friends?status=pending' => 'view_requests'
            ]
        ],
        'notifications' => [
            'frontend' => [
                'view_notifications' => 'View notifications',
                'mark_read' => 'Mark as read',
                'mark_unread' => 'Mark as unread',
                'delete_notification' => 'Delete notification',
                'bulk_actions' => 'Bulk actions on notifications'
            ],
            'api' => [
                'GET /notifications' => 'view_notifications',
                'PUT /notifications/{id}/read' => 'mark_read',
                'PUT /notifications/{id}/unread' => 'mark_unread',
                'DELETE /notifications/{id}' => 'delete_notification',
                'PUT /notifications' => 'bulk_actions'
            ]
        ],
        'xprofile' => [
            'frontend' => [
                'view_fields' => 'View profile fields',
                'edit_fields' => 'Edit profile fields',
                'field_visibility' => 'Set field visibility',
                'create_field_group' => 'Create field group',
                'reorder_fields' => 'Reorder fields'
            ],
            'api' => [
                'GET /xprofile/fields' => 'view_fields',
                'PUT /xprofile/fields/{id}' => 'edit_fields',
                'PUT /xprofile/fields/{id}/visibility' => 'field_visibility',
                'POST /xprofile/groups' => 'create_field_group',
                'PUT /xprofile/fields/order' => 'reorder_fields'
            ]
        ]
    ];
    
    /**
     * Run parity tests for all components
     */
    public function run_parity_tests() {
        echo "🔍 BuddyPress REST API Feature Parity Testing\n";
        echo str_repeat("=", 70) . "\n\n";
        
        foreach ($this->feature_map as $component => $features) {
            $this->test_component_parity($component, $features);
        }
        
        $this->display_overall_results();
        
        return $this->test_results;
    }
    
    /**
     * Test parity for a single component
     */
    private function test_component_parity($component, $features) {
        echo "📦 Testing Component: " . ucfirst($component) . "\n";
        echo str_repeat("-", 50) . "\n";
        
        $results = [
            'component' => $component,
            'frontend_features' => count($features['frontend']),
            'api_endpoints' => count($features['api']),
            'coverage' => [],
            'missing_in_api' => [],
            'missing_in_frontend' => [],
            'parity_score' => 0
        ];
        
        // Check each frontend feature for API equivalent
        foreach ($features['frontend'] as $feature_key => $feature_name) {
            $has_api = false;
            $api_endpoint = '';
            
            foreach ($features['api'] as $endpoint => $maps_to) {
                if ($maps_to === $feature_key) {
                    $has_api = true;
                    $api_endpoint = $endpoint;
                    break;
                }
            }
            
            $results['coverage'][$feature_key] = [
                'name' => $feature_name,
                'has_api' => $has_api,
                'endpoint' => $api_endpoint,
                'tested' => false,
                'works' => false
            ];
            
            if (!$has_api) {
                $results['missing_in_api'][] = $feature_name;
            }
        }
        
        // Check for API endpoints without frontend equivalent
        $mapped_features = array_values($features['api']);
        $frontend_keys = array_keys($features['frontend']);
        
        foreach ($features['api'] as $endpoint => $maps_to) {
            if (!in_array($maps_to, $frontend_keys)) {
                $results['missing_in_frontend'][] = $endpoint;
            }
        }
        
        // Test actual API endpoints
        $this->test_api_endpoints($component, $results);
        
        // Calculate parity score
        $covered = count($results['coverage']) - count($results['missing_in_api']);
        $results['parity_score'] = round(($covered / count($results['coverage'])) * 100, 2);
        
        // Display results
        $this->display_component_results($results);
        
        $this->test_results[$component] = $results;
    }
    
    /**
     * Test actual API endpoints
     */
    private function test_api_endpoints($component, &$results) {
        // Get REST API base URL
        $rest_url = rest_url('buddypress/v2/');
        
        foreach ($results['coverage'] as $feature_key => &$feature) {
            if ($feature['has_api'] && $feature['endpoint']) {
                // Parse endpoint
                $endpoint_parts = explode(' ', $feature['endpoint']);
                $method = $endpoint_parts[0];
                $path = $endpoint_parts[1];
                
                // Build full URL
                $url = $rest_url . ltrim(str_replace('/buddypress/v2/', '', $path), '/');
                
                // Test endpoint availability
                $feature['tested'] = true;
                $feature['works'] = $this->test_endpoint($url, $method);
            }
        }
    }
    
    /**
     * Test a single endpoint
     */
    private function test_endpoint($url, $method) {
        // For testing, we'll check if the endpoint responds
        // In production, you'd want to test with actual data
        
        $args = [
            'method' => $method,
            'timeout' => 5,
            'headers' => [
                'Content-Type' => 'application/json',
            ]
        ];
        
        // For GET requests, just check if endpoint exists
        if ($method === 'GET') {
            $response = wp_remote_get($url, $args);
        } else {
            // For other methods, we'd need proper test data
            // For now, just check if endpoint accepts the method
            $response = wp_remote_request($url, $args);
        }
        
        if (is_wp_error($response)) {
            return false;
        }
        
        $status_code = wp_remote_retrieve_response_code($response);
        
        // Consider 200-299 and 400-403 as "working" (400-403 means endpoint exists but needs auth)
        return ($status_code >= 200 && $status_code < 300) || ($status_code >= 400 && $status_code <= 403);
    }
    
    /**
     * Display component results
     */
    private function display_component_results($results) {
        echo "  📊 Frontend Features: {$results['frontend_features']}\n";
        echo "  🌐 API Endpoints: {$results['api_endpoints']}\n";
        echo "  📈 Parity Score: {$results['parity_score']}%\n";
        
        if (!empty($results['missing_in_api'])) {
            echo "\n  ⚠️  Missing API endpoints for:\n";
            foreach ($results['missing_in_api'] as $missing) {
                echo "     • {$missing}\n";
            }
        }
        
        if (!empty($results['missing_in_frontend'])) {
            echo "\n  ℹ️  API endpoints without frontend:\n";
            foreach ($results['missing_in_frontend'] as $endpoint) {
                echo "     • {$endpoint}\n";
            }
        }
        
        // Show test results
        $tested = 0;
        $working = 0;
        
        foreach ($results['coverage'] as $feature) {
            if ($feature['tested']) {
                $tested++;
                if ($feature['works']) {
                    $working++;
                }
            }
        }
        
        if ($tested > 0) {
            echo "\n  🧪 API Tests: {$working}/{$tested} endpoints working\n";
        }
        
        echo "\n";
    }
    
    /**
     * Display overall results
     */
    private function display_overall_results() {
        echo str_repeat("=", 70) . "\n";
        echo "📊 OVERALL PARITY RESULTS\n";
        echo str_repeat("=", 70) . "\n\n";
        
        $total_frontend = 0;
        $total_api = 0;
        $total_missing_api = 0;
        $total_parity = 0;
        
        foreach ($this->test_results as $component => $results) {
            $total_frontend += $results['frontend_features'];
            $total_api += $results['api_endpoints'];
            $total_missing_api += count($results['missing_in_api']);
            $total_parity += $results['parity_score'];
        }
        
        $avg_parity = round($total_parity / count($this->test_results), 2);
        
        echo "  Total Frontend Features: {$total_frontend}\n";
        echo "  Total API Endpoints: {$total_api}\n";
        echo "  Missing API Coverage: {$total_missing_api} features\n";
        echo "  Average Parity Score: {$avg_parity}%\n\n";
        
        // Component ranking
        echo "📈 Component Parity Scores:\n";
        $scores = [];
        foreach ($this->test_results as $component => $results) {
            $scores[$component] = $results['parity_score'];
        }
        arsort($scores);
        
        foreach ($scores as $component => $score) {
            $status = $score >= 80 ? '✅' : ($score >= 60 ? '⚠️' : '❌');
            echo "  {$status} " . ucfirst($component) . ": {$score}%\n";
        }
        
        // Recommendations
        echo "\n🔧 Recommendations:\n";
        foreach ($this->test_results as $component => $results) {
            if (!empty($results['missing_in_api'])) {
                echo "\n  " . ucfirst($component) . " needs API endpoints for:\n";
                foreach (array_slice($results['missing_in_api'], 0, 3) as $missing) {
                    echo "    • {$missing}\n";
                }
                if (count($results['missing_in_api']) > 3) {
                    echo "    ... and " . (count($results['missing_in_api']) - 3) . " more\n";
                }
            }
        }
    }
    
    /**
     * Export results
     */
    public function export_results($filename = null) {
        if (!$filename) {
            $upload_dir = wp_upload_dir();
            $filename = $upload_dir['basedir'] . '/wbcom-scan/buddypress/api/api-parity-' . date('Y-m-d-His') . '.json';
        }
        
        // Ensure directory exists
        $dir = dirname($filename);
        if (!is_dir($dir)) {
            wp_mkdir_p($dir);
        }
        
        $export_data = [
            'test_date' => date('Y-m-d H:i:s'),
            'buddypress_version' => defined('BP_VERSION') ? BP_VERSION : 'unknown',
            'components' => $this->test_results,
            'summary' => [
                'total_frontend_features' => array_sum(array_column($this->test_results, 'frontend_features')),
                'total_api_endpoints' => array_sum(array_column($this->test_results, 'api_endpoints')),
                'average_parity' => round(array_sum(array_column($this->test_results, 'parity_score')) / count($this->test_results), 2)
            ]
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
    
    // Run tester
    $tester = new BP_REST_API_Parity_Tester();
    $results = $tester->run_parity_tests();
    $tester->export_results();
}