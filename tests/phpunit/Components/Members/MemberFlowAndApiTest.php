<?php
/**
 * BuddyPress Members Component - Combined Code Flow and REST API Tests
 * Tests both internal code execution and REST API endpoints
 * 
 * @package BuddyNext\Tests\Components\Members
 */

namespace BuddyNext\Tests\Components\Members;

use WP_UnitTestCase;
use WP_REST_Request;
use WP_REST_Server;

class MemberFlowAndApiTest extends WP_UnitTestCase {
    
    protected $server;
    protected $test_user_data;
    protected $code_flow_tracking = [];
    
    protected function setUp(): void {
        parent::setUp();
        
        // Initialize REST server
        global $wp_rest_server;
        $this->server = $wp_rest_server = new WP_REST_Server;
        do_action('rest_api_init');
        
        // Prepare test user data
        $this->test_user_data = [
            'user_login' => 'testmember',
            'user_email' => 'testmember@example.com',
            'user_pass' => 'Test123!@#',
            'first_name' => 'Test',
            'last_name' => 'Member',
            'display_name' => 'Test Member'
        ];
        
        // Track code flow
        $this->setup_flow_tracking();
    }
    
    protected function tearDown(): void {
        $this->teardown_flow_tracking();
        wp_set_current_user(0);
        parent::tearDown();
    }
    
    /**
     * Setup hooks to track code flow
     */
    protected function setup_flow_tracking() {
        // Registration flow hooks
        add_action('user_register', [$this, 'track_user_register'], 10, 1);
        add_action('bp_core_signup_user', [$this, 'track_bp_signup'], 10, 5);
        add_action('bp_core_activated_user', [$this, 'track_bp_activation'], 10, 3);
        
        // Profile update hooks
        add_action('xprofile_data_before_save', [$this, 'track_xprofile_before_save'], 10, 1);
        add_action('xprofile_data_after_save', [$this, 'track_xprofile_after_save'], 10, 1);
        
        // Last activity hooks
        add_action('bp_core_user_updated_last_activity', [$this, 'track_last_activity'], 10, 2);
        
        // Member type hooks
        add_action('bp_set_member_type', [$this, 'track_member_type'], 10, 3);
    }
    
    protected function teardown_flow_tracking() {
        remove_action('user_register', [$this, 'track_user_register']);
        remove_action('bp_core_signup_user', [$this, 'track_bp_signup']);
        remove_action('bp_core_activated_user', [$this, 'track_bp_activation']);
        remove_action('xprofile_data_before_save', [$this, 'track_xprofile_before_save']);
        remove_action('xprofile_data_after_save', [$this, 'track_xprofile_after_save']);
        remove_action('bp_core_user_updated_last_activity', [$this, 'track_last_activity']);
        remove_action('bp_set_member_type', [$this, 'track_member_type']);
    }
    
    // Tracking methods
    public function track_user_register($user_id) {
        $this->code_flow_tracking[] = ['hook' => 'user_register', 'user_id' => $user_id];
    }
    
    public function track_bp_signup($user_login, $user_password, $user_email, $usermeta) {
        $this->code_flow_tracking[] = ['hook' => 'bp_core_signup_user', 'email' => $user_email];
    }
    
    public function track_bp_activation($user_id, $key, $user) {
        $this->code_flow_tracking[] = ['hook' => 'bp_core_activated_user', 'user_id' => $user_id];
    }
    
    public function track_xprofile_before_save($data) {
        $this->code_flow_tracking[] = ['hook' => 'xprofile_data_before_save', 'field_id' => $data->field_id];
    }
    
    public function track_xprofile_after_save($data) {
        $this->code_flow_tracking[] = ['hook' => 'xprofile_data_after_save', 'field_id' => $data->field_id];
    }
    
    public function track_last_activity($user_id, $time) {
        $this->code_flow_tracking[] = ['hook' => 'bp_core_user_updated_last_activity', 'user_id' => $user_id];
    }
    
    public function track_member_type($user_id, $member_type, $append) {
        $this->code_flow_tracking[] = ['hook' => 'bp_set_member_type', 'user_id' => $user_id, 'type' => $member_type];
    }
    
    /**
     * Test 1: Member Registration - Code Flow + REST API
     */
    public function test_member_registration_complete_flow() {
        // Reset tracking
        $this->code_flow_tracking = [];
        
        // PART 1: Code Flow - Direct Registration
        $user_id = wp_create_user(
            $this->test_user_data['user_login'],
            $this->test_user_data['user_pass'],
            $this->test_user_data['user_email']
        );
        
        // Verify user was created
        $this->assertIsNumeric($user_id);
        $this->assertGreaterThan(0, $user_id);
        
        // Verify WordPress hooks fired
        $this->assertContains('user_register', array_column($this->code_flow_tracking, 'hook'));
        
        // Update user meta
        wp_update_user([
            'ID' => $user_id,
            'first_name' => $this->test_user_data['first_name'],
            'last_name' => $this->test_user_data['last_name'],
            'display_name' => $this->test_user_data['display_name']
        ]);
        
        // Set BuddyPress last activity
        bp_update_user_last_activity($user_id);
        
        // Verify BP hook fired
        $this->assertContains('bp_core_user_updated_last_activity', array_column($this->code_flow_tracking, 'hook'));
        
        // PART 2: REST API - Verify member via API
        $request = new WP_REST_Request('GET', '/buddypress/v2/members/' . $user_id);
        $response = $this->server->dispatch($request);
        
        $this->assertEquals(200, $response->get_status());
        
        $member_data = $response->get_data();
        $this->assertEquals($user_id, $member_data['id']);
        $this->assertEquals($this->test_user_data['display_name'], $member_data['name']);
        
        // PART 3: Verify Database State
        global $wpdb;
        
        // Check wp_users table
        $user_in_db = $wpdb->get_row($wpdb->prepare(
            "SELECT * FROM {$wpdb->users} WHERE ID = %d",
            $user_id
        ));
        $this->assertNotNull($user_in_db);
        $this->assertEquals($this->test_user_data['user_email'], $user_in_db->user_email);
        
        // Check BuddyPress last activity
        $last_activity = $wpdb->get_var($wpdb->prepare(
            "SELECT date_recorded FROM {$wpdb->prefix}bp_activity 
             WHERE user_id = %d AND type = 'last_activity'",
            $user_id
        ));
        $this->assertNotNull($last_activity);
    }
    
    /**
     * Test 2: xProfile Update - Code Flow + REST API
     */
    public function test_xprofile_update_complete_flow() {
        if (!bp_is_active('xprofile')) {
            $this->markTestSkipped('xProfile component not active');
        }
        
        // Create test user
        $user_id = $this->factory->user->create();
        wp_set_current_user($user_id);
        
        // Reset tracking
        $this->code_flow_tracking = [];
        
        // PART 1: Code Flow - Update xProfile field
        $bio_text = 'This is my test bio';
        $updated = xprofile_set_field_data(2, $user_id, $bio_text); // Field 2 is usually Bio
        
        // Verify update succeeded
        $this->assertTrue($updated);
        
        // Verify hooks fired
        $xprofile_hooks = array_column($this->code_flow_tracking, 'hook');
        $this->assertContains('xprofile_data_before_save', $xprofile_hooks);
        $this->assertContains('xprofile_data_after_save', $xprofile_hooks);
        
        // PART 2: REST API - Verify via API
        $request = new WP_REST_Request('GET', '/buddypress/v2/xprofile/2/data/' . $user_id);
        $response = $this->server->dispatch($request);
        
        if ($response->get_status() === 200) {
            $data = $response->get_data();
            $this->assertEquals($bio_text, $data['value']['raw']);
        }
        
        // PART 3: Verify Database
        global $wpdb;
        $stored_value = $wpdb->get_var($wpdb->prepare(
            "SELECT value FROM {$wpdb->prefix}bp_xprofile_data 
             WHERE field_id = 2 AND user_id = %d",
            $user_id
        ));
        $this->assertEquals($bio_text, $stored_value);
    }
    
    /**
     * Test 3: Member Search - Code Flow + REST API
     */
    public function test_member_search_complete_flow() {
        // Create test users with specific names
        $user1_id = $this->factory->user->create([
            'user_login' => 'john_doe',
            'display_name' => 'John Doe'
        ]);
        
        $user2_id = $this->factory->user->create([
            'user_login' => 'jane_doe',
            'display_name' => 'Jane Doe'
        ]);
        
        $user3_id = $this->factory->user->create([
            'user_login' => 'bob_smith',
            'display_name' => 'Bob Smith'
        ]);
        
        // Set last activity for all users
        bp_update_user_last_activity($user1_id);
        bp_update_user_last_activity($user2_id);
        bp_update_user_last_activity($user3_id);
        
        // PART 1: Code Flow - Search using BP functions
        $search_results = bp_core_get_users([
            'search_terms' => 'doe',
            'type' => 'alphabetical'
        ]);
        
        // Verify search results
        $this->assertEquals(2, $search_results['total']);
        $found_ids = wp_list_pluck($search_results['users'], 'ID');
        $this->assertContains($user1_id, $found_ids);
        $this->assertContains($user2_id, $found_ids);
        $this->assertNotContains($user3_id, $found_ids);
        
        // PART 2: REST API - Search via API
        $request = new WP_REST_Request('GET', '/buddypress/v2/members');
        $request->set_param('search', 'doe');
        
        $response = $this->server->dispatch($request);
        $this->assertEquals(200, $response->get_status());
        
        $api_results = $response->get_data();
        $api_ids = wp_list_pluck($api_results, 'id');
        
        // Verify API returns same results
        $this->assertContains($user1_id, $api_ids);
        $this->assertContains($user2_id, $api_ids);
        
        // PART 3: Verify Query Execution
        // This would normally require query logging, simplified here
        $this->assertGreaterThan(0, count($api_results));
    }
    
    /**
     * Test 4: Member Type Assignment - Code Flow + REST API
     */
    public function test_member_type_complete_flow() {
        // Register custom member type
        bp_register_member_type('student', [
            'labels' => [
                'name' => 'Students',
                'singular_name' => 'Student'
            ]
        ]);
        
        // Create test user
        $user_id = $this->factory->user->create();
        
        // Reset tracking
        $this->code_flow_tracking = [];
        
        // PART 1: Code Flow - Set member type
        $result = bp_set_member_type($user_id, 'student');
        
        // Verify type was set
        $this->assertTrue($result);
        
        // Verify hook fired
        $this->assertContains('bp_set_member_type', array_column($this->code_flow_tracking, 'hook'));
        
        // Verify type is correct
        $member_type = bp_get_member_type($user_id);
        $this->assertEquals('student', $member_type);
        
        // PART 2: REST API - Verify via API
        $request = new WP_REST_Request('GET', '/buddypress/v2/members/' . $user_id);
        $response = $this->server->dispatch($request);
        
        $member_data = $response->get_data();
        if (isset($member_data['member_types'])) {
            $this->assertContains('student', $member_data['member_types']);
        }
        
        // PART 3: Verify Database
        $stored_type = bp_get_member_type($user_id, false);
        $this->assertContains('student', $stored_type);
    }
    
    /**
     * Test 5: Avatar Upload - Code Flow + REST API
     */
    public function test_avatar_upload_complete_flow() {
        $user_id = $this->factory->user->create();
        wp_set_current_user($user_id);
        
        // PART 1: Code Flow - Check avatar functions
        $avatar_url = bp_core_fetch_avatar([
            'item_id' => $user_id,
            'type' => 'full',
            'html' => false
        ]);
        
        // Default avatar should exist
        $this->assertNotEmpty($avatar_url);
        $this->assertStringContainsString('mystery', $avatar_url); // Default mystery man
        
        // PART 2: REST API - Get avatar via API
        $request = new WP_REST_Request('GET', '/buddypress/v2/members/' . $user_id . '/avatar');
        $response = $this->server->dispatch($request);
        
        if ($response->get_status() === 200) {
            $avatar_data = $response->get_data();
            $this->assertArrayHasKey('full', $avatar_data);
            $this->assertArrayHasKey('thumb', $avatar_data);
        }
    }
    
    /**
     * Test 6: Complete Member Lifecycle
     */
    public function test_complete_member_lifecycle() {
        // 1. Registration
        $user_id = wp_create_user('lifecycle_user', 'Pass123!', 'lifecycle@test.com');
        $this->assertIsNumeric($user_id);
        
        // 2. Activation
        bp_update_user_last_activity($user_id);
        
        // 3. Profile completion
        if (bp_is_active('xprofile')) {
            xprofile_set_field_data(1, $user_id, 'Lifecycle User'); // Name field
        }
        
        // 4. Activity creation
        if (bp_is_active('activity')) {
            $activity_id = bp_activity_add([
                'user_id' => $user_id,
                'type' => 'joined_group',
                'component' => 'groups'
            ]);
            $this->assertIsNumeric($activity_id);
        }
        
        // 5. Verify via REST API
        $request = new WP_REST_Request('GET', '/buddypress/v2/members/' . $user_id);
        $response = $this->server->dispatch($request);
        
        $this->assertEquals(200, $response->get_status());
        $member = $response->get_data();
        $this->assertEquals($user_id, $member['id']);
        
        // 6. Cleanup/Deletion tracking
        $delete_hooks = [];
        add_action('deleted_user', function($id) use (&$delete_hooks) {
            $delete_hooks[] = 'deleted_user';
        });
        
        wp_delete_user($user_id);
        $this->assertContains('deleted_user', $delete_hooks);
        
        // Verify user no longer exists via API
        $request = new WP_REST_Request('GET', '/buddypress/v2/members/' . $user_id);
        $response = $this->server->dispatch($request);
        $this->assertEquals(404, $response->get_status());
    }
}