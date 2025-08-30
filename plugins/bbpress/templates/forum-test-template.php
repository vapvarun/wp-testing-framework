<?php
/**
 * BBPress Forum Test Template
 * Reusable test template for forum functionality
 */

namespace BBPress\Tests\Templates;

use WP_UnitTestCase;

/**
 * Forum Test Template Class
 * 
 * Use this template as a starting point for forum-related tests
 */
class ForumTestTemplate extends WP_UnitTestCase {
    
    protected $test_forum_id;
    protected $test_user_id;
    
    /**
     * Set up test environment
     */
    public function setUp(): void {
        parent::setUp();
        
        // Create test user with forum capabilities
        $this->test_user_id = $this->factory->user->create([
            'role' => 'administrator'
        ]);
        
        // Set current user
        wp_set_current_user($this->test_user_id);
        
        // Create test forum
        $this->test_forum_id = bbp_insert_forum([
            'post_title' => 'Test Forum',
            'post_content' => 'Test forum description',
            'post_status' => 'publish'
        ]);
    }
    
    /**
     * Clean up after tests
     */
    public function tearDown(): void {
        // Clean up test data
        if ($this->test_forum_id) {
            wp_delete_post($this->test_forum_id, true);
        }
        
        if ($this->test_user_id) {
            wp_delete_user($this->test_user_id);
        }
        
        parent::tearDown();
    }
    
    /**
     * Helper: Create a test topic in the forum
     */
    protected function create_test_topic($args = []) {
        $defaults = [
            'post_parent' => $this->test_forum_id,
            'post_title' => 'Test Topic',
            'post_content' => 'Test topic content',
            'post_status' => 'publish',
            'post_author' => $this->test_user_id
        ];
        
        $args = wp_parse_args($args, $defaults);
        return bbp_insert_topic($args);
    }
    
    /**
     * Helper: Create a test reply
     */
    protected function create_test_reply($topic_id, $args = []) {
        $defaults = [
            'post_parent' => $topic_id,
            'post_content' => 'Test reply content',
            'post_status' => 'publish',
            'post_author' => $this->test_user_id
        ];
        
        $args = wp_parse_args($args, $defaults);
        return bbp_insert_reply($args);
    }
    
    /**
     * Helper: Assert forum has expected structure
     */
    protected function assertForumStructure($forum_id) {
        $forum = bbp_get_forum($forum_id);
        
        $this->assertNotNull($forum);
        $this->assertEquals(bbp_get_forum_post_type(), $forum->post_type);
        $this->assertContains($forum->post_status, ['publish', 'private', 'hidden']);
    }
    
    /**
     * Helper: Assert user has capability
     */
    protected function assertUserCanModerate($user_id, $forum_id) {
        $user = get_user_by('id', $user_id);
        $this->assertTrue(
            user_can($user, 'moderate', $forum_id),
            "User {$user_id} should be able to moderate forum {$forum_id}"
        );
    }
    
    /**
     * Example test: Forum creation
     */
    public function test_forum_creation() {
        $this->assertNotNull($this->test_forum_id);
        $this->assertForumStructure($this->test_forum_id);
    }
    
    /**
     * Example test: Topic creation in forum
     */
    public function test_topic_creation_in_forum() {
        $topic_id = $this->create_test_topic();
        
        $this->assertNotNull($topic_id);
        $this->assertEquals($this->test_forum_id, wp_get_post_parent_id($topic_id));
    }
}