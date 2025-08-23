<?php
/**
 * BuddyPress Code Flow Scanner
 * 
 * Analyzes user interaction flows through templates and frontend functionality
 * Maps user actions to code execution paths
 */

class BP_Code_Flow_Scanner {
    
    private $buddypress_path;
    private $flows = [];
    private $template_usage = [];
    private $user_interactions = [];
    
    /**
     * User interaction flows to analyze
     */
    private $interaction_flows = [
        'user_registration' => [
            'name' => 'User Registration Flow',
            'steps' => [
                'visit_registration_page' => 'User visits registration page',
                'fill_registration_form' => 'User fills out registration form',
                'submit_registration' => 'User submits registration',
                'email_verification' => 'User verifies email',
                'profile_completion' => 'User completes profile',
                'first_login' => 'User logs in first time'
            ],
            'templates' => [
                'register.php',
                'activation.php',
                'members/single/profile/edit.php'
            ],
            'hooks' => [
                'bp_core_signup_user',
                'bp_core_activate_signup',
                'bp_complete_signup'
            ],
            'functions' => [
                'bp_core_signup_user()',
                'bp_core_validate_user_signup()',
                'bp_core_activate_signup()'
            ]
        ],
        'profile_management' => [
            'name' => 'Profile Management Flow',
            'steps' => [
                'view_profile' => 'User views their profile',
                'edit_profile' => 'User edits profile fields',
                'upload_avatar' => 'User uploads avatar',
                'upload_cover' => 'User uploads cover image',
                'change_visibility' => 'User changes field visibility',
                'save_changes' => 'User saves profile changes'
            ],
            'templates' => [
                'members/single/profile.php',
                'members/single/profile/edit.php',
                'members/single/profile/change-avatar.php',
                'members/single/profile/change-cover-image.php'
            ],
            'hooks' => [
                'xprofile_updated_profile',
                'xprofile_avatar_uploaded',
                'xprofile_cover_image_uploaded'
            ],
            'functions' => [
                'xprofile_set_field_data()',
                'bp_core_avatar_handle_upload()',
                'bp_attachments_cover_image_ajax_upload()'
            ]
        ],
        'activity_posting' => [
            'name' => 'Activity Posting Flow',
            'steps' => [
                'view_activity_stream' => 'User views activity stream',
                'compose_update' => 'User composes activity update',
                'add_media' => 'User adds media/links',
                'mention_users' => 'User mentions other users',
                'post_activity' => 'User posts activity',
                'view_confirmation' => 'User sees posted activity'
            ],
            'templates' => [
                'activity/index.php',
                'activity/post-form.php',
                'activity/entry.php'
            ],
            'hooks' => [
                'bp_activity_before_save',
                'bp_activity_after_save',
                'bp_activity_posted_update'
            ],
            'functions' => [
                'bp_activity_add()',
                'bp_activity_post_update()',
                'bp_activity_at_name_filter()'
            ]
        ],
        'group_creation' => [
            'name' => 'Group Creation Flow',
            'steps' => [
                'initiate_creation' => 'User starts group creation',
                'enter_details' => 'User enters group details',
                'configure_settings' => 'User configures privacy settings',
                'upload_avatar' => 'User uploads group avatar',
                'invite_members' => 'User invites members',
                'finalize_group' => 'User creates group'
            ],
            'templates' => [
                'groups/create.php',
                'groups/single/admin.php',
                'groups/single/invite.php'
            ],
            'hooks' => [
                'groups_group_create_complete',
                'groups_create_group_step_save',
                'groups_group_after_save'
            ],
            'functions' => [
                'groups_create_group()',
                'groups_edit_group_settings()',
                'groups_send_invites()'
            ]
        ],
        'messaging' => [
            'name' => 'Messaging Flow',
            'steps' => [
                'access_messages' => 'User accesses messages',
                'compose_message' => 'User composes new message',
                'select_recipients' => 'User selects recipients',
                'write_content' => 'User writes message content',
                'send_message' => 'User sends message',
                'read_reply' => 'User reads and replies'
            ],
            'templates' => [
                'members/single/messages.php',
                'members/single/messages/compose.php',
                'members/single/messages/single.php'
            ],
            'hooks' => [
                'messages_message_before_save',
                'messages_message_after_save',
                'messages_message_sent'
            ],
            'functions' => [
                'messages_new_message()',
                'messages_check_thread_access()',
                'messages_mark_thread_read()'
            ]
        ],
        'friend_connection' => [
            'name' => 'Friend Connection Flow',
            'steps' => [
                'browse_members' => 'User browses members',
                'view_member_profile' => 'User views member profile',
                'send_friend_request' => 'User sends friend request',
                'receive_notification' => 'User receives notification',
                'accept_request' => 'User accepts friend request',
                'view_friends_list' => 'User views friends list'
            ],
            'templates' => [
                'members/index.php',
                'members/single/profile.php',
                'members/single/friends.php',
                'members/single/friends/requests.php'
            ],
            'hooks' => [
                'friends_friendship_requested',
                'friends_friendship_accepted',
                'friends_friendship_post_delete'
            ],
            'functions' => [
                'friends_add_friend()',
                'friends_accept_friendship()',
                'friends_check_friendship()'
            ]
        ],
        'search_discovery' => [
            'name' => 'Search & Discovery Flow',
            'steps' => [
                'enter_search' => 'User enters search query',
                'filter_results' => 'User applies filters',
                'sort_results' => 'User sorts results',
                'paginate_results' => 'User navigates pages',
                'view_result' => 'User views search result',
                'interact_result' => 'User interacts with result'
            ],
            'templates' => [
                'common/search/search-form.php',
                'members/members-loop.php',
                'groups/groups-loop.php',
                'activity/activity-loop.php'
            ],
            'hooks' => [
                'bp_ajax_querystring',
                'bp_before_directory_members_page',
                'bp_after_directory_members_page'
            ],
            'functions' => [
                'bp_has_members()',
                'bp_has_groups()',
                'bp_has_activities()'
            ]
        ],
        'notification_handling' => [
            'name' => 'Notification Handling Flow',
            'steps' => [
                'receive_notification' => 'User receives notification',
                'view_notification' => 'User views notification',
                'click_notification' => 'User clicks notification',
                'mark_as_read' => 'User marks as read',
                'manage_preferences' => 'User manages preferences',
                'bulk_actions' => 'User performs bulk actions'
            ],
            'templates' => [
                'members/single/notifications.php',
                'members/single/settings/notifications.php'
            ],
            'hooks' => [
                'bp_notification_after_save',
                'bp_notification_before_delete',
                'bp_notification_mark_read'
            ],
            'functions' => [
                'bp_notifications_add_notification()',
                'bp_notifications_mark_notification()',
                'bp_notifications_delete_notification()'
            ]
        ]
    ];
    
    /**
     * Initialize scanner
     */
    public function __construct() {
        $this->buddypress_path = WP_PLUGIN_DIR . '/buddypress';
        
        if (!is_dir($this->buddypress_path)) {
            throw new Exception("BuddyPress not found at: {$this->buddypress_path}");
        }
    }
    
    /**
     * Run code flow analysis
     */
    public function analyze_code_flows() {
        echo "🔍 BuddyPress Code Flow Analysis\n";
        echo str_repeat("=", 70) . "\n\n";
        
        foreach ($this->interaction_flows as $flow_id => $flow_config) {
            $this->analyze_single_flow($flow_id, $flow_config);
        }
        
        $this->analyze_template_usage();
        $this->map_user_actions_to_code();
        $this->generate_flow_report();
        
        return $this->flows;
    }
    
    /**
     * Analyze a single user interaction flow
     */
    private function analyze_single_flow($flow_id, $config) {
        echo "📋 Analyzing: {$config['name']}\n";
        echo str_repeat("-", 50) . "\n";
        
        $flow_data = [
            'id' => $flow_id,
            'name' => $config['name'],
            'steps' => $config['steps'],
            'templates' => [],
            'hooks' => [],
            'functions' => [],
            'files' => [],
            'ajax_handlers' => [],
            'form_handlers' => [],
            'validation' => [],
            'database_operations' => []
        ];
        
        // Check templates
        foreach ($config['templates'] as $template) {
            $template_path = $this->find_template($template);
            if ($template_path) {
                $flow_data['templates'][] = [
                    'file' => $template,
                    'path' => $template_path,
                    'exists' => file_exists($template_path),
                    'hooks_used' => $this->extract_hooks_from_template($template_path)
                ];
            }
        }
        
        // Check hooks
        foreach ($config['hooks'] as $hook) {
            $hook_usage = $this->find_hook_usage($hook);
            $flow_data['hooks'][] = [
                'name' => $hook,
                'type' => strpos($hook, 'filter') !== false ? 'filter' : 'action',
                'found' => !empty($hook_usage),
                'usage_count' => count($hook_usage),
                'files' => $hook_usage
            ];
        }
        
        // Check functions
        foreach ($config['functions'] as $function) {
            $func_name = str_replace('()', '', $function);
            $function_info = $this->find_function_definition($func_name);
            $flow_data['functions'][] = [
                'name' => $function,
                'found' => !empty($function_info),
                'file' => $function_info['file'] ?? null,
                'line' => $function_info['line'] ?? null,
                'parameters' => $function_info['parameters'] ?? [],
                'return_type' => $function_info['return_type'] ?? null
            ];
        }
        
        // Find AJAX handlers
        $flow_data['ajax_handlers'] = $this->find_ajax_handlers($flow_id);
        
        // Find form handlers
        $flow_data['form_handlers'] = $this->find_form_handlers($flow_id);
        
        // Find validation functions
        $flow_data['validation'] = $this->find_validation_functions($flow_id);
        
        // Find database operations
        $flow_data['database_operations'] = $this->find_database_operations($flow_id);
        
        // Calculate completeness
        $template_count = count($flow_data['templates']);
        $template_found = count(array_filter($flow_data['templates'], function($t) { return $t['exists']; }));
        
        $hook_count = count($flow_data['hooks']);
        $hook_found = count(array_filter($flow_data['hooks'], function($h) { return $h['found']; }));
        
        $function_count = count($flow_data['functions']);
        $function_found = count(array_filter($flow_data['functions'], function($f) { return $f['found']; }));
        
        $flow_data['completeness'] = [
            'templates' => $template_count > 0 ? round(($template_found / $template_count) * 100, 2) : 0,
            'hooks' => $hook_count > 0 ? round(($hook_found / $hook_count) * 100, 2) : 0,
            'functions' => $function_count > 0 ? round(($function_found / $function_count) * 100, 2) : 0,
            'overall' => $this->calculate_overall_completeness($flow_data)
        ];
        
        // Display results
        echo "  ✅ Templates: {$template_found}/{$template_count} found\n";
        echo "  ✅ Hooks: {$hook_found}/{$hook_count} found\n";
        echo "  ✅ Functions: {$function_found}/{$function_count} found\n";
        echo "  📊 Completeness: {$flow_data['completeness']['overall']}%\n\n";
        
        $this->flows[$flow_id] = $flow_data;
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
     * Extract hooks from template
     */
    private function extract_hooks_from_template($template_path) {
        if (!file_exists($template_path)) {
            return [];
        }
        
        $content = file_get_contents($template_path);
        $hooks = [];
        
        // Find do_action calls
        if (preg_match_all('/do_action\s*\(\s*[\'"]([^\'"]+)[\'"]/i', $content, $matches)) {
            foreach ($matches[1] as $hook) {
                $hooks[] = ['type' => 'action', 'name' => $hook];
            }
        }
        
        // Find apply_filters calls
        if (preg_match_all('/apply_filters\s*\(\s*[\'"]([^\'"]+)[\'"]/i', $content, $matches)) {
            foreach ($matches[1] as $hook) {
                $hooks[] = ['type' => 'filter', 'name' => $hook];
            }
        }
        
        return $hooks;
    }
    
    /**
     * Find hook usage in codebase
     */
    private function find_hook_usage($hook) {
        $files = [];
        $iterator = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator($this->buddypress_path)
        );
        
        foreach ($iterator as $file) {
            if ($file->isFile() && $file->getExtension() === 'php') {
                $content = file_get_contents($file->getPathname());
                if (strpos($content, $hook) !== false) {
                    $files[] = str_replace($this->buddypress_path . '/', '', $file->getPathname());
                }
            }
        }
        
        return $files;
    }
    
    /**
     * Find function definition
     */
    private function find_function_definition($function_name) {
        $iterator = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator($this->buddypress_path)
        );
        
        foreach ($iterator as $file) {
            if ($file->isFile() && $file->getExtension() === 'php') {
                $content = file_get_contents($file->getPathname());
                
                if (preg_match('/function\s+' . preg_quote($function_name) . '\s*\(/i', $content)) {
                    $lines = explode("\n", $content);
                    foreach ($lines as $line_num => $line) {
                        if (preg_match('/function\s+' . preg_quote($function_name) . '\s*\(([^)]*)\)/i', $line, $matches)) {
                            return [
                                'file' => str_replace($this->buddypress_path . '/', '', $file->getPathname()),
                                'line' => $line_num + 1,
                                'parameters' => $this->parse_parameters($matches[1] ?? ''),
                                'return_type' => $this->extract_return_type($content, $line_num)
                            ];
                        }
                    }
                }
            }
        }
        
        return null;
    }
    
    /**
     * Parse function parameters
     */
    private function parse_parameters($param_string) {
        if (empty(trim($param_string))) {
            return [];
        }
        
        $params = [];
        $parts = explode(',', $param_string);
        
        foreach ($parts as $part) {
            $part = trim($part);
            if (!empty($part)) {
                $params[] = $part;
            }
        }
        
        return $params;
    }
    
    /**
     * Extract return type from function
     */
    private function extract_return_type($content, $start_line) {
        $lines = explode("\n", $content);
        
        // Look for @return in docblock above function
        for ($i = $start_line - 1; $i >= max(0, $start_line - 20); $i--) {
            if (preg_match('/@return\s+(\S+)/i', $lines[$i], $matches)) {
                return $matches[1];
            }
        }
        
        return 'mixed';
    }
    
    /**
     * Find AJAX handlers for flow
     */
    private function find_ajax_handlers($flow_id) {
        $handlers = [];
        
        $ajax_patterns = [
            'user_registration' => ['bp_ajax_register', 'bp_ajax_validate_signup'],
            'profile_management' => ['xprofile_ajax_save', 'bp_avatar_ajax_upload'],
            'activity_posting' => ['bp_ajax_post_update', 'bp_ajax_delete_activity'],
            'group_creation' => ['bp_ajax_create_group', 'bp_ajax_invite_user'],
            'messaging' => ['bp_ajax_messages_send', 'bp_ajax_messages_autocomplete'],
            'friend_connection' => ['bp_ajax_add_friend', 'bp_ajax_remove_friend'],
            'search_discovery' => ['bp_ajax_members_filter', 'bp_ajax_object_filter'],
            'notification_handling' => ['bp_ajax_mark_notification_read', 'bp_ajax_delete_notification']
        ];
        
        if (isset($ajax_patterns[$flow_id])) {
            foreach ($ajax_patterns[$flow_id] as $pattern) {
                $found = $this->find_ajax_handler($pattern);
                if ($found) {
                    $handlers[] = $found;
                }
            }
        }
        
        return $handlers;
    }
    
    /**
     * Find specific AJAX handler
     */
    private function find_ajax_handler($handler_name) {
        $ajax_hooks = [
            "wp_ajax_{$handler_name}",
            "wp_ajax_nopriv_{$handler_name}"
        ];
        
        foreach ($ajax_hooks as $hook) {
            $usage = $this->find_hook_usage($hook);
            if (!empty($usage)) {
                return [
                    'name' => $handler_name,
                    'hook' => $hook,
                    'files' => $usage
                ];
            }
        }
        
        return null;
    }
    
    /**
     * Find form handlers
     */
    private function find_form_handlers($flow_id) {
        $handlers = [];
        
        $form_patterns = [
            'user_registration' => ['bp_core_screen_signup', 'bp_core_validate_user_signup'],
            'profile_management' => ['xprofile_screen_edit_profile', 'xprofile_action_edit_profile'],
            'activity_posting' => ['bp_activity_action_post_update', 'bp_activity_action_delete_activity'],
            'group_creation' => ['groups_action_create_group', 'groups_screen_group_admin'],
            'messaging' => ['messages_action_compose', 'messages_action_send'],
            'friend_connection' => ['friends_action_add_friend', 'friends_action_remove_friend'],
            'search_discovery' => ['bp_core_action_search_site', 'bp_directory_members_search'],
            'notification_handling' => ['bp_notifications_action_mark_read', 'bp_notifications_action_delete']
        ];
        
        if (isset($form_patterns[$flow_id])) {
            foreach ($form_patterns[$flow_id] as $handler) {
                $info = $this->find_function_definition($handler);
                if ($info) {
                    $handlers[] = [
                        'name' => $handler,
                        'file' => $info['file'],
                        'line' => $info['line']
                    ];
                }
            }
        }
        
        return $handlers;
    }
    
    /**
     * Find validation functions
     */
    private function find_validation_functions($flow_id) {
        $validators = [];
        
        $validation_patterns = [
            'user_registration' => ['bp_core_validate_user_signup', 'bp_core_validate_blog_signup'],
            'profile_management' => ['xprofile_check_is_required_field', 'bp_core_check_avatar_upload'],
            'activity_posting' => ['bp_activity_check_moderation', 'bp_activity_check_blacklist_keys'],
            'group_creation' => ['groups_check_group_name', 'groups_check_slug'],
            'messaging' => ['messages_check_thread_access', 'bp_messages_check_content'],
            'friend_connection' => ['friends_check_friendship', 'friends_check_friendship_status'],
            'search_discovery' => ['bp_core_validate_search_terms', 'bp_sanitize_search_terms'],
            'notification_handling' => ['bp_notifications_check_notification_access', 'bp_verify_nonce_request']
        ];
        
        if (isset($validation_patterns[$flow_id])) {
            foreach ($validation_patterns[$flow_id] as $validator) {
                $info = $this->find_function_definition($validator);
                if ($info) {
                    $validators[] = [
                        'name' => $validator,
                        'file' => $info['file'],
                        'parameters' => $info['parameters'],
                        'return_type' => $info['return_type']
                    ];
                }
            }
        }
        
        return $validators;
    }
    
    /**
     * Find database operations
     */
    private function find_database_operations($flow_id) {
        $operations = [];
        
        $db_patterns = [
            'user_registration' => ['INSERT INTO', 'bp_core_signup', 'usermeta'],
            'profile_management' => ['UPDATE', 'xprofile_data', 'xprofile_fields'],
            'activity_posting' => ['INSERT INTO', 'bp_activity', 'bp_activity_meta'],
            'group_creation' => ['INSERT INTO', 'bp_groups', 'bp_groups_members'],
            'messaging' => ['INSERT INTO', 'bp_messages', 'bp_messages_recipients'],
            'friend_connection' => ['INSERT INTO', 'bp_friends', 'DELETE FROM'],
            'search_discovery' => ['SELECT', 'JOIN', 'WHERE', 'LIKE'],
            'notification_handling' => ['UPDATE', 'bp_notifications', 'is_new']
        ];
        
        if (isset($db_patterns[$flow_id])) {
            foreach ($db_patterns[$flow_id] as $pattern) {
                $operations[] = [
                    'operation' => $pattern,
                    'found' => $this->search_for_database_pattern($pattern)
                ];
            }
        }
        
        return $operations;
    }
    
    /**
     * Search for database pattern
     */
    private function search_for_database_pattern($pattern) {
        $found_count = 0;
        $iterator = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator($this->buddypress_path)
        );
        
        foreach ($iterator as $file) {
            if ($file->isFile() && $file->getExtension() === 'php') {
                $content = file_get_contents($file->getPathname());
                if (stripos($content, $pattern) !== false) {
                    $found_count++;
                }
            }
        }
        
        return $found_count > 0;
    }
    
    /**
     * Calculate overall completeness
     */
    private function calculate_overall_completeness($flow_data) {
        $scores = [];
        
        if (!empty($flow_data['templates'])) {
            $scores[] = $flow_data['completeness']['templates'];
        }
        
        if (!empty($flow_data['hooks'])) {
            $scores[] = $flow_data['completeness']['hooks'];
        }
        
        if (!empty($flow_data['functions'])) {
            $scores[] = $flow_data['completeness']['functions'];
        }
        
        if (!empty($flow_data['ajax_handlers'])) {
            $ajax_found = count(array_filter($flow_data['ajax_handlers']));
            $ajax_total = count($flow_data['ajax_handlers']);
            $scores[] = $ajax_total > 0 ? ($ajax_found / $ajax_total) * 100 : 0;
        }
        
        if (!empty($flow_data['form_handlers'])) {
            $form_found = count(array_filter($flow_data['form_handlers']));
            $form_total = count($flow_data['form_handlers']);
            $scores[] = $form_total > 0 ? ($form_found / $form_total) * 100 : 0;
        }
        
        return !empty($scores) ? round(array_sum($scores) / count($scores), 2) : 0;
    }
    
    /**
     * Analyze template usage across flows
     */
    private function analyze_template_usage() {
        echo str_repeat("=", 70) . "\n";
        echo "📄 TEMPLATE USAGE ANALYSIS\n";
        echo str_repeat("=", 70) . "\n\n";
        
        $all_templates = [];
        
        foreach ($this->flows as $flow_id => $flow_data) {
            foreach ($flow_data['templates'] as $template) {
                if (!isset($all_templates[$template['file']])) {
                    $all_templates[$template['file']] = [
                        'file' => $template['file'],
                        'exists' => $template['exists'],
                        'used_in_flows' => [],
                        'hooks' => []
                    ];
                }
                
                $all_templates[$template['file']]['used_in_flows'][] = $flow_id;
                $all_templates[$template['file']]['hooks'] = array_merge(
                    $all_templates[$template['file']]['hooks'],
                    $template['hooks_used']
                );
            }
        }
        
        // Remove duplicate hooks
        foreach ($all_templates as &$template) {
            $template['hooks'] = array_unique($template['hooks'], SORT_REGULAR);
        }
        
        $this->template_usage = $all_templates;
        
        // Display summary
        $total_templates = count($all_templates);
        $existing_templates = count(array_filter($all_templates, function($t) { return $t['exists']; }));
        
        echo "  📊 Total Templates: {$total_templates}\n";
        echo "  ✅ Existing: {$existing_templates}\n";
        echo "  ❌ Missing: " . ($total_templates - $existing_templates) . "\n\n";
        
        // Show most used templates
        echo "  🔝 Most Used Templates:\n";
        $sorted = $all_templates;
        usort($sorted, function($a, $b) {
            return count($b['used_in_flows']) - count($a['used_in_flows']);
        });
        
        foreach (array_slice($sorted, 0, 5) as $template) {
            echo "     • {$template['file']} (used in " . count($template['used_in_flows']) . " flows)\n";
        }
        
        echo "\n";
    }
    
    /**
     * Map user actions to code execution
     */
    private function map_user_actions_to_code() {
        echo str_repeat("=", 70) . "\n";
        echo "🔗 USER ACTION TO CODE MAPPING\n";
        echo str_repeat("=", 70) . "\n\n";
        
        foreach ($this->flows as $flow_id => $flow_data) {
            echo "📋 {$flow_data['name']}\n";
            
            foreach ($flow_data['steps'] as $step_id => $step_description) {
                echo "  → {$step_description}\n";
                
                // Map to specific code elements
                $this->user_interactions[$flow_id][$step_id] = [
                    'description' => $step_description,
                    'templates' => $this->get_templates_for_step($flow_id, $step_id),
                    'hooks' => $this->get_hooks_for_step($flow_id, $step_id),
                    'functions' => $this->get_functions_for_step($flow_id, $step_id)
                ];
                
                // Show code mapping
                $mapping = $this->user_interactions[$flow_id][$step_id];
                if (!empty($mapping['functions'])) {
                    echo "      Code: " . implode(', ', array_column($mapping['functions'], 'name')) . "\n";
                }
            }
            
            echo "\n";
        }
    }
    
    /**
     * Get templates for specific step
     */
    private function get_templates_for_step($flow_id, $step_id) {
        // Map steps to templates based on flow
        $step_template_map = [
            'user_registration' => [
                'visit_registration_page' => ['register.php'],
                'email_verification' => ['activation.php'],
                'profile_completion' => ['members/single/profile/edit.php']
            ],
            'profile_management' => [
                'view_profile' => ['members/single/profile.php'],
                'edit_profile' => ['members/single/profile/edit.php'],
                'upload_avatar' => ['members/single/profile/change-avatar.php']
            ],
            'activity_posting' => [
                'view_activity_stream' => ['activity/index.php'],
                'compose_update' => ['activity/post-form.php'],
                'view_confirmation' => ['activity/entry.php']
            ]
        ];
        
        if (isset($step_template_map[$flow_id][$step_id])) {
            $templates = [];
            foreach ($step_template_map[$flow_id][$step_id] as $template_name) {
                foreach ($this->flows[$flow_id]['templates'] as $template) {
                    if ($template['file'] === $template_name) {
                        $templates[] = $template;
                    }
                }
            }
            return $templates;
        }
        
        return [];
    }
    
    /**
     * Get hooks for specific step
     */
    private function get_hooks_for_step($flow_id, $step_id) {
        // Map steps to hooks based on flow
        $step_hook_map = [
            'user_registration' => [
                'submit_registration' => ['bp_core_signup_user'],
                'email_verification' => ['bp_core_activate_signup']
            ],
            'profile_management' => [
                'save_changes' => ['xprofile_updated_profile'],
                'upload_avatar' => ['xprofile_avatar_uploaded']
            ],
            'activity_posting' => [
                'post_activity' => ['bp_activity_posted_update']
            ]
        ];
        
        if (isset($step_hook_map[$flow_id][$step_id])) {
            $hooks = [];
            foreach ($step_hook_map[$flow_id][$step_id] as $hook_name) {
                foreach ($this->flows[$flow_id]['hooks'] as $hook) {
                    if ($hook['name'] === $hook_name) {
                        $hooks[] = $hook;
                    }
                }
            }
            return $hooks;
        }
        
        return [];
    }
    
    /**
     * Get functions for specific step
     */
    private function get_functions_for_step($flow_id, $step_id) {
        // Map steps to functions based on flow
        $step_function_map = [
            'user_registration' => [
                'submit_registration' => ['bp_core_signup_user()'],
                'email_verification' => ['bp_core_activate_signup()']
            ],
            'profile_management' => [
                'save_changes' => ['xprofile_set_field_data()'],
                'upload_avatar' => ['bp_core_avatar_handle_upload()']
            ],
            'activity_posting' => [
                'post_activity' => ['bp_activity_post_update()']
            ]
        ];
        
        if (isset($step_function_map[$flow_id][$step_id])) {
            $functions = [];
            foreach ($step_function_map[$flow_id][$step_id] as $func_name) {
                foreach ($this->flows[$flow_id]['functions'] as $function) {
                    if ($function['name'] === $func_name) {
                        $functions[] = $function;
                    }
                }
            }
            return $functions;
        }
        
        return [];
    }
    
    /**
     * Generate comprehensive flow report
     */
    private function generate_flow_report() {
        echo str_repeat("=", 70) . "\n";
        echo "📊 CODE FLOW ANALYSIS SUMMARY\n";
        echo str_repeat("=", 70) . "\n\n";
        
        $total_flows = count($this->flows);
        $total_steps = 0;
        $total_templates = 0;
        $total_hooks = 0;
        $total_functions = 0;
        $avg_completeness = 0;
        
        foreach ($this->flows as $flow) {
            $total_steps += count($flow['steps']);
            $total_templates += count($flow['templates']);
            $total_hooks += count($flow['hooks']);
            $total_functions += count($flow['functions']);
            $avg_completeness += $flow['completeness']['overall'];
        }
        
        $avg_completeness = round($avg_completeness / $total_flows, 2);
        
        echo "  📈 Analysis Metrics:\n";
        echo "     • User Flows Analyzed: {$total_flows}\n";
        echo "     • Total Steps: {$total_steps}\n";
        echo "     • Templates Mapped: {$total_templates}\n";
        echo "     • Hooks Identified: {$total_hooks}\n";
        echo "     • Functions Tracked: {$total_functions}\n";
        echo "     • Average Completeness: {$avg_completeness}%\n\n";
        
        // Flow completeness ranking
        echo "  🏆 Flow Completeness Ranking:\n";
        $flow_scores = [];
        foreach ($this->flows as $flow_id => $flow) {
            $flow_scores[$flow['name']] = $flow['completeness']['overall'];
        }
        arsort($flow_scores);
        
        foreach ($flow_scores as $name => $score) {
            $status = $score >= 80 ? '✅' : ($score >= 60 ? '⚠️' : '❌');
            echo "     {$status} {$name}: {$score}%\n";
        }
        
        echo "\n";
    }
    
    /**
     * Export results
     */
    public function export_results($filename = null) {
        if (!$filename) {
            $upload_dir = wp_upload_dir();
            $filename = $upload_dir['basedir'] . '/wbcom-scan/buddypress-code-flow-' . date('Y-m-d-His') . '.json';
        }
        
        // Ensure directory exists
        $dir = dirname($filename);
        if (!is_dir($dir)) {
            wp_mkdir_p($dir);
        }
        
        $export_data = [
            'scan_date' => date('Y-m-d H:i:s'),
            'buddypress_version' => defined('BP_VERSION') ? BP_VERSION : 'unknown',
            'flows' => $this->flows,
            'template_usage' => $this->template_usage,
            'user_interactions' => $this->user_interactions,
            'summary' => [
                'total_flows' => count($this->flows),
                'total_templates' => count($this->template_usage),
                'average_completeness' => $this->calculate_average_completeness()
            ]
        ];
        
        file_put_contents($filename, json_encode($export_data, JSON_PRETTY_PRINT));
        
        echo "✅ Results exported to: {$filename}\n";
        
        return $filename;
    }
    
    /**
     * Calculate average completeness
     */
    private function calculate_average_completeness() {
        if (empty($this->flows)) {
            return 0;
        }
        
        $total = 0;
        foreach ($this->flows as $flow) {
            $total += $flow['completeness']['overall'];
        }
        
        return round($total / count($this->flows), 2);
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
    $scanner = new BP_Code_Flow_Scanner();
    $results = $scanner->analyze_code_flows();
    $scanner->export_results();
}