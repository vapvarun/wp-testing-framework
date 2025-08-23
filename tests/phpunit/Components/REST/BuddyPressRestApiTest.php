<?php
/**
 * BuddyPress REST API Comprehensive Tests
 * Tests all BuddyPress REST API endpoints
 * 
 * @package BuddyNext\Tests\Components\REST
 */

namespace BuddyNext\Tests\Components\REST;

use WP_UnitTestCase;
use WP_REST_Request;
use WP_REST_Server;

class BuddyPressRestApiTest extends WP_UnitTestCase {
    
    protected $server;
    protected $test_user_id;
    protected $test_user2_id;
    protected $admin_id;
    
    protected function setUp(): void {
        parent::setUp();
        
        // Initialize REST server
        global $wp_rest_server;
        $this->server = $wp_rest_server = new WP_REST_Server;
        do_action('rest_api_init');
        
        // Create test users
        $this->test_user_id = $this->factory->user->create([
            'user_login' => 'test_user',
            'user_email' => 'test@example.com',
            'role' => 'subscriber'
        ]);
        
        $this->test_user2_id = $this->factory->user->create([
            'user_login' => 'test_user2',
            'user_email' => 'test2@example.com',
            'role' => 'subscriber'
        ]);
        
        $this->admin_id = $this->factory->user->create([
            'role' => 'administrator'
        ]);
        
        // Set current user as admin for tests
        wp_set_current_user($this->admin_id);
    }
    
    protected function tearDown(): void {
        wp_set_current_user(0);
        parent::tearDown();
    }
    
    /**
     * Test components endpoint
     */
    public function test_components_endpoint() {
        $request = new WP_REST_Request('GET', '/buddypress/v2/components');
        $response = $this->server->dispatch($request);
        
        $this->assertEquals(200, $response->get_status());
        
        $data = $response->get_data();
        $this->assertIsArray($data);
        
        // Check for core components
        $component_names = array_column($data, 'name');
        $this->assertContains('members', $component_names);
        $this->assertContains('activity', $component_names);
        $this->assertContains('groups', $component_names);
    }
    
    /**
     * Test members endpoint
     */
    public function test_members_list_endpoint() {
        $request = new WP_REST_Request('GET', '/buddypress/v2/members');
        $response = $this->server->dispatch($request);
        
        $this->assertEquals(200, $response->get_status());
        
        $data = $response->get_data();
        $this->assertIsArray($data);
        $this->assertNotEmpty($data);
        
        // Check member structure
        if (!empty($data)) {
            $member = $data[0];
            $this->assertArrayHasKey('id', $member);
            $this->assertArrayHasKey('name', $member);
            $this->assertArrayHasKey('link', $member);
            $this->assertArrayHasKey('avatar_urls', $member);
        }
    }
    
    /**
     * Test single member endpoint
     */
    public function test_single_member_endpoint() {
        $request = new WP_REST_Request('GET', '/buddypress/v2/members/' . $this->test_user_id);
        $response = $this->server->dispatch($request);
        
        $this->assertEquals(200, $response->get_status());
        
        $data = $response->get_data();
        $this->assertEquals($this->test_user_id, $data['id']);
        $this->assertArrayHasKey('name', $data);
        $this->assertArrayHasKey('registered_date', $data);
    }
    
    /**
     * Test activity creation endpoint
     */
    public function test_activity_create_endpoint() {
        if (!bp_is_active('activity')) {
            $this->markTestSkipped('Activity component not active');
        }
        
        $request = new WP_REST_Request('POST', '/buddypress/v2/activity');
        $request->set_param('content', 'Test activity from REST API');
        $request->set_param('type', 'activity_update');
        $request->set_param('user_id', $this->test_user_id);
        
        $response = $this->server->dispatch($request);
        
        $this->assertEquals(200, $response->get_status());
        
        $data = $response->get_data();
        $this->assertArrayHasKey('id', $data);
        $this->assertEquals('Test activity from REST API', $data['content']['raw']);
        $this->assertEquals($this->test_user_id, $data['user_id']);
    }
    
    /**
     * Test activity list endpoint
     */
    public function test_activity_list_endpoint() {
        if (!bp_is_active('activity')) {
            $this->markTestSkipped('Activity component not active');
        }
        
        // Create some test activities
        bp_activity_add([
            'user_id' => $this->test_user_id,
            'content' => 'Test activity 1',
            'type' => 'activity_update'
        ]);
        
        bp_activity_add([
            'user_id' => $this->test_user2_id,
            'content' => 'Test activity 2',
            'type' => 'activity_update'
        ]);
        
        $request = new WP_REST_Request('GET', '/buddypress/v2/activity');
        $response = $this->server->dispatch($request);
        
        $this->assertEquals(200, $response->get_status());
        
        $data = $response->get_data();
        $this->assertIsArray($data);
        $this->assertNotEmpty($data);
    }
    
    /**
     * Test groups endpoint
     */
    public function test_groups_endpoint() {
        if (!bp_is_active('groups')) {
            $this->markTestSkipped('Groups component not active');
        }
        
        // Create test group
        $group_id = groups_create_group([
            'creator_id' => $this->test_user_id,
            'name' => 'Test Group',
            'description' => 'Test group description',
            'status' => 'public'
        ]);
        
        $request = new WP_REST_Request('GET', '/buddypress/v2/groups');
        $response = $this->server->dispatch($request);
        
        $this->assertEquals(200, $response->get_status());
        
        $data = $response->get_data();
        $this->assertIsArray($data);
        
        // Find our test group
        $test_group = null;
        foreach ($data as $group) {
            if ($group['name'] === 'Test Group') {
                $test_group = $group;
                break;
            }
        }
        
        $this->assertNotNull($test_group);
        $this->assertEquals('Test Group', $test_group['name']);
    }
    
    /**
     * Test friends endpoint
     */
    public function test_friends_endpoint() {
        if (!bp_is_active('friends')) {
            $this->markTestSkipped('Friends component not active');
        }
        
        // Create friendship
        friends_add_friend($this->test_user_id, $this->test_user2_id, true);
        
        $request = new WP_REST_Request('GET', '/buddypress/v2/friends');
        $request->set_param('user_id', $this->test_user_id);
        
        $response = $this->server->dispatch($request);
        
        $this->assertEquals(200, $response->get_status());
        
        $data = $response->get_data();
        $this->assertIsArray($data);
    }
    
    /**
     * Test messages endpoint
     */
    public function test_messages_endpoint() {
        if (!bp_is_active('messages')) {
            $this->markTestSkipped('Messages component not active');
        }
        
        wp_set_current_user($this->test_user_id);
        
        // Create test message
        $message_id = messages_new_message([
            'sender_id' => $this->test_user_id,
            'recipients' => [$this->test_user2_id],
            'subject' => 'Test Subject',
            'content' => 'Test message content'
        ]);
        
        $request = new WP_REST_Request('GET', '/buddypress/v2/messages');
        $response = $this->server->dispatch($request);
        
        $this->assertEquals(200, $response->get_status());
        
        $data = $response->get_data();
        $this->assertIsArray($data);
    }
    
    /**
     * Test notifications endpoint
     */
    public function test_notifications_endpoint() {
        if (!bp_is_active('notifications')) {
            $this->markTestSkipped('Notifications component not active');
        }
        
        // Create test notification
        bp_notifications_add_notification([
            'user_id' => $this->test_user_id,
            'item_id' => 1,
            'secondary_item_id' => 0,
            'component_name' => 'activity',
            'component_action' => 'new_at_mention',
            'date_notified' => bp_core_current_time(),
            'is_new' => 1
        ]);
        
        wp_set_current_user($this->test_user_id);
        
        $request = new WP_REST_Request('GET', '/buddypress/v2/notifications');
        $response = $this->server->dispatch($request);
        
        $this->assertEquals(200, $response->get_status());
        
        $data = $response->get_data();
        $this->assertIsArray($data);
    }
    
    /**
     * Test xProfile fields endpoint
     */
    public function test_xprofile_fields_endpoint() {
        if (!bp_is_active('xprofile')) {
            $this->markTestSkipped('xProfile component not active');
        }
        
        $request = new WP_REST_Request('GET', '/buddypress/v2/xprofile/fields');
        $response = $this->server->dispatch($request);
        
        $this->assertEquals(200, $response->get_status());
        
        $data = $response->get_data();
        $this->assertIsArray($data);
        
        // Should have at least the Name field
        $this->assertNotEmpty($data);
    }
    
    /**
     * Test authentication requirement
     */
    public function test_authentication_required_endpoints() {
        // Log out
        wp_set_current_user(0);
        
        // Try to access protected endpoint
        $request = new WP_REST_Request('POST', '/buddypress/v2/activity');
        $request->set_param('content', 'Should fail');
        
        $response = $this->server->dispatch($request);
        
        // Should return 401 Unauthorized
        $this->assertEquals(401, $response->get_status());
    }
    
    /**
     * Test pagination
     */
    public function test_members_pagination() {
        // Create additional test users
        for ($i = 0; $i < 15; $i++) {
            $this->factory->user->create([
                'user_login' => 'paged_user_' . $i
            ]);
        }
        
        // Test first page
        $request = new WP_REST_Request('GET', '/buddypress/v2/members');
        $request->set_param('per_page', 5);
        $request->set_param('page', 1);
        
        $response = $this->server->dispatch($request);
        $this->assertEquals(200, $response->get_status());
        
        $data = $response->get_data();
        $this->assertCount(5, $data);
        
        // Test second page
        $request->set_param('page', 2);
        $response = $this->server->dispatch($request);
        
        $this->assertEquals(200, $response->get_status());
        $data = $response->get_data();
        $this->assertCount(5, $data);
    }
    
    /**
     * Test filtering
     */
    public function test_activity_filtering() {
        if (!bp_is_active('activity')) {
            $this->markTestSkipped('Activity component not active');
        }
        
        // Create activities of different types
        bp_activity_add([
            'user_id' => $this->test_user_id,
            'content' => 'Regular update',
            'type' => 'activity_update'
        ]);
        
        bp_activity_add([
            'user_id' => $this->test_user_id,
            'content' => 'New blog post',
            'type' => 'new_blog_post'
        ]);
        
        // Filter by type
        $request = new WP_REST_Request('GET', '/buddypress/v2/activity');
        $request->set_param('type', 'activity_update');
        
        $response = $this->server->dispatch($request);
        $this->assertEquals(200, $response->get_status());
        
        $data = $response->get_data();
        foreach ($data as $activity) {
            $this->assertEquals('activity_update', $activity['type']);
        }
    }
    
    /**
     * Test error handling
     */
    public function test_invalid_member_returns_404() {
        $request = new WP_REST_Request('GET', '/buddypress/v2/members/999999');
        $response = $this->server->dispatch($request);
        
        $this->assertEquals(404, $response->get_status());
    }
    
    /**
     * Test schema validation
     */
    public function test_activity_schema_validation() {
        if (!bp_is_active('activity')) {
            $this->markTestSkipped('Activity component not active');
        }
        
        // Try to create activity with invalid data
        $request = new WP_REST_Request('POST', '/buddypress/v2/activity');
        $request->set_param('content', ''); // Empty content should fail
        $request->set_param('type', 'invalid_type');
        
        $response = $this->server->dispatch($request);
        
        // Should return error
        $this->assertGreaterThanOrEqual(400, $response->get_status());
    }
}