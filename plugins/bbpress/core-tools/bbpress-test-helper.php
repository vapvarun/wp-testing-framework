<?php
/**
 * BBPress Test Helper
 * Core testing utilities specific to BBPress
 */

namespace BBPress\TestHelpers;

/**
 * BBPress Test Helper Class
 * Provides utilities for testing BBPress functionality
 */
class BBPressTestHelper {
    
    /**
     * Create a complete forum hierarchy
     */
    public static function create_forum_hierarchy() {
        $structure = [];
        
        // Create parent forum
        $structure['parent'] = bbp_insert_forum([
            'post_title' => 'Parent Forum',
            'post_content' => 'Parent forum description',
            'post_status' => 'publish'
        ]);
        
        // Create child forums
        $structure['children'] = [];
        for ($i = 1; $i <= 3; $i++) {
            $structure['children'][] = bbp_insert_forum([
                'post_title' => "Child Forum {$i}",
                'post_content' => "Child forum {$i} description",
                'post_parent' => $structure['parent'],
                'post_status' => 'publish'
            ]);
        }
        
        return $structure;
    }
    
    /**
     * Create test users with different roles
     */
    public static function create_test_users() {
        $users = [];
        
        $roles = [
            'bbp_keymaster' => 'Keymaster User',
            'bbp_moderator' => 'Moderator User',
            'bbp_participant' => 'Participant User',
            'bbp_spectator' => 'Spectator User',
            'bbp_blocked' => 'Blocked User'
        ];
        
        foreach ($roles as $role => $display_name) {
            $users[$role] = wp_insert_user([
                'user_login' => strtolower(str_replace(' ', '_', $display_name)),
                'user_pass' => 'test_password',
                'display_name' => $display_name,
                'role' => $role
            ]);
        }
        
        return $users;
    }
    
    /**
     * Create sample content for a forum
     */
    public static function populate_forum($forum_id, $options = []) {
        $defaults = [
            'topics' => 5,
            'replies_per_topic' => 3,
            'users' => 3
        ];
        
        $options = wp_parse_args($options, $defaults);
        $content = [];
        
        // Create users
        $users = [];
        for ($i = 1; $i <= $options['users']; $i++) {
            $users[] = wp_insert_user([
                'user_login' => "test_user_{$i}_" . time(),
                'user_pass' => 'password',
                'display_name' => "Test User {$i}"
            ]);
        }
        
        // Create topics
        for ($t = 1; $t <= $options['topics']; $t++) {
            $author = $users[array_rand($users)];
            
            $topic_id = bbp_insert_topic([
                'post_parent' => $forum_id,
                'post_title' => "Test Topic {$t}",
                'post_content' => "This is test topic {$t} content with some discussion points.",
                'post_status' => 'publish',
                'post_author' => $author
            ]);
            
            $content['topics'][] = $topic_id;
            
            // Create replies for each topic
            for ($r = 1; $r <= $options['replies_per_topic']; $r++) {
                $reply_author = $users[array_rand($users)];
                
                $reply_id = bbp_insert_reply([
                    'post_parent' => $topic_id,
                    'post_content' => "This is reply {$r} to topic {$t}.",
                    'post_status' => 'publish',
                    'post_author' => $reply_author
                ]);
                
                $content['replies'][] = $reply_id;
            }
        }
        
        $content['users'] = $users;
        return $content;
    }
    
    /**
     * Clean up all BBPress data
     */
    public static function cleanup_all_forums() {
        // Get all forums
        $forums = get_posts([
            'post_type' => bbp_get_forum_post_type(),
            'posts_per_page' => -1,
            'post_status' => 'any'
        ]);
        
        foreach ($forums as $forum) {
            wp_delete_post($forum->ID, true);
        }
        
        // Get all topics
        $topics = get_posts([
            'post_type' => bbp_get_topic_post_type(),
            'posts_per_page' => -1,
            'post_status' => 'any'
        ]);
        
        foreach ($topics as $topic) {
            wp_delete_post($topic->ID, true);
        }
        
        // Get all replies
        $replies = get_posts([
            'post_type' => bbp_get_reply_post_type(),
            'posts_per_page' => -1,
            'post_status' => 'any'
        ]);
        
        foreach ($replies as $reply) {
            wp_delete_post($reply->ID, true);
        }
    }
    
    /**
     * Assert forum statistics are correct
     */
    public static function assert_forum_counts($forum_id, $expected_topics, $expected_replies) {
        $topic_count = bbp_get_forum_topic_count($forum_id);
        $reply_count = bbp_get_forum_reply_count($forum_id);
        
        assert($topic_count == $expected_topics, "Forum should have {$expected_topics} topics, has {$topic_count}");
        assert($reply_count == $expected_replies, "Forum should have {$expected_replies} replies, has {$reply_count}");
        
        return true;
    }
    
    /**
     * Simulate user actions
     */
    public static function simulate_user_action($user_id, $action, $args = []) {
        $old_user = wp_get_current_user();
        wp_set_current_user($user_id);
        
        $result = false;
        
        switch ($action) {
            case 'create_topic':
                $result = bbp_insert_topic($args);
                break;
                
            case 'create_reply':
                $result = bbp_insert_reply($args);
                break;
                
            case 'subscribe_topic':
                $result = bbp_add_user_subscription($user_id, $args['topic_id']);
                break;
                
            case 'favorite_topic':
                $result = bbp_add_user_favorite($user_id, $args['topic_id']);
                break;
                
            case 'moderate_topic':
                if (current_user_can('moderate')) {
                    $result = wp_update_post([
                        'ID' => $args['topic_id'],
                        'post_status' => $args['status'] ?? 'closed'
                    ]);
                }
                break;
        }
        
        wp_set_current_user($old_user->ID);
        return $result;
    }
    
    /**
     * Generate performance test data
     */
    public static function generate_performance_data($scale = 'small') {
        $configs = [
            'small' => [
                'forums' => 5,
                'topics_per_forum' => 10,
                'replies_per_topic' => 5
            ],
            'medium' => [
                'forums' => 20,
                'topics_per_forum' => 50,
                'replies_per_topic' => 20
            ],
            'large' => [
                'forums' => 100,
                'topics_per_forum' => 200,
                'replies_per_topic' => 50
            ]
        ];
        
        $config = $configs[$scale] ?? $configs['small'];
        $data = [];
        
        for ($f = 1; $f <= $config['forums']; $f++) {
            $forum_id = bbp_insert_forum([
                'post_title' => "Performance Test Forum {$f}",
                'post_status' => 'publish'
            ]);
            
            $data['forums'][] = $forum_id;
            
            for ($t = 1; $t <= $config['topics_per_forum']; $t++) {
                $topic_id = bbp_insert_topic([
                    'post_parent' => $forum_id,
                    'post_title' => "Topic {$t} in Forum {$f}",
                    'post_content' => "Performance test content",
                    'post_status' => 'publish'
                ]);
                
                $data['topics'][] = $topic_id;
                
                for ($r = 1; $r <= $config['replies_per_topic']; $r++) {
                    $reply_id = bbp_insert_reply([
                        'post_parent' => $topic_id,
                        'post_content' => "Reply {$r}",
                        'post_status' => 'publish'
                    ]);
                    
                    $data['replies'][] = $reply_id;
                }
            }
        }
        
        return $data;
    }
    
    /**
     * Validate BBPress installation
     */
    public static function validate_installation() {
        $checks = [
            'post_types' => [
                bbp_get_forum_post_type(),
                bbp_get_topic_post_type(),
                bbp_get_reply_post_type()
            ],
            'taxonomies' => [
                bbp_get_topic_tag_tax_id()
            ],
            'capabilities' => [
                'spectate',
                'participate',
                'moderate',
                'throttle',
                'view_trash'
            ],
            'options' => [
                '_bbp_db_version',
                '_bbp_enable_favorites',
                '_bbp_enable_subscriptions'
            ]
        ];
        
        $results = [];
        
        // Check post types
        foreach ($checks['post_types'] as $post_type) {
            $results['post_types'][$post_type] = post_type_exists($post_type);
        }
        
        // Check taxonomies
        foreach ($checks['taxonomies'] as $taxonomy) {
            $results['taxonomies'][$taxonomy] = taxonomy_exists($taxonomy);
        }
        
        // Check options
        foreach ($checks['options'] as $option) {
            $results['options'][$option] = get_option($option) !== false;
        }
        
        return $results;
    }
}