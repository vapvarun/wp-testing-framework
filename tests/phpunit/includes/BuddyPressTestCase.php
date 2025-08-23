<?php
/**
 * BuddyPress Test Case Base Class
 */

class BuddyPressTestCase extends WP_UnitTestCase
{
    /**
     * Set up test environment before each test
     */
    public function setUp(): void
    {
        parent::setUp();
        
        // Create a test user
        $this->user_id = $this->factory->user->create([
            'role' => 'subscriber'
        ]);
        
        // Create an admin user
        $this->admin_user_id = $this->factory->user->create([
            'role' => 'administrator'
        ]);
        
        // Set current user
        wp_set_current_user($this->user_id);
    }

    /**
     * Clean up after each test
     */
    public function tearDown(): void
    {
        parent::tearDown();
        
        // Clean up any BuddyPress data created during tests
        $this->cleanup_buddypress_data();
    }

    /**
     * Clean up BuddyPress test data
     */
    protected function cleanup_buddypress_data()
    {
        global $wpdb;
        
        if (!function_exists('bp_is_active')) {
            return;
        }
        
        // Clean up activity data
        if (bp_is_active('activity')) {
            $wpdb->query("DELETE FROM {$wpdb->prefix}bp_activity");
            $wpdb->query("DELETE FROM {$wpdb->prefix}bp_activity_meta");
        }
        
        // Clean up groups data
        if (bp_is_active('groups')) {
            $wpdb->query("DELETE FROM {$wpdb->prefix}bp_groups");
            $wpdb->query("DELETE FROM {$wpdb->prefix}bp_groups_members");
            $wpdb->query("DELETE FROM {$wpdb->prefix}bp_groups_groupmeta");
        }
        
        // Clean up messages data
        if (bp_is_active('messages')) {
            $wpdb->query("DELETE FROM {$wpdb->prefix}bp_messages_messages");
            $wpdb->query("DELETE FROM {$wpdb->prefix}bp_messages_recipients");
        }
        
        // Clean up friends data
        if (bp_is_active('friends')) {
            $wpdb->query("DELETE FROM {$wpdb->prefix}bp_friends");
        }
        
        // Clean up notifications data
        if (bp_is_active('notifications')) {
            $wpdb->query("DELETE FROM {$wpdb->prefix}bp_notifications");
        }
        
        // Clean up xprofile data
        if (bp_is_active('xprofile')) {
            $wpdb->query("DELETE FROM {$wpdb->prefix}bp_xprofile_data WHERE field_id > 1"); // Keep default field
            $wpdb->query("DELETE FROM {$wpdb->prefix}bp_xprofile_fields WHERE id > 1"); // Keep default field
            $wpdb->query("DELETE FROM {$wpdb->prefix}bp_xprofile_groups WHERE id > 1"); // Keep default group
        }
    }

    /**
     * Create a test activity
     */
    protected function create_test_activity($args = [])
    {
        if (!bp_is_active('activity')) {
            $this->markTestSkipped('Activity component not active');
        }
        
        $defaults = [
            'user_id' => $this->user_id,
            'component' => 'activity',
            'type' => 'activity_update',
            'action' => 'Test activity action',
            'content' => 'Test activity content',
            'recorded_time' => bp_core_current_time(),
        ];
        
        $args = wp_parse_args($args, $defaults);
        
        return bp_activity_add($args);
    }

    /**
     * Create a test group
     */
    protected function create_test_group($args = [])
    {
        if (!bp_is_active('groups')) {
            $this->markTestSkipped('Groups component not active');
        }
        
        $defaults = [
            'creator_id' => $this->user_id,
            'name' => 'Test Group',
            'description' => 'Test group description',
            'slug' => 'test-group-' . wp_rand(),
            'status' => 'public',
            'enable_forum' => 0,
        ];
        
        $args = wp_parse_args($args, $defaults);
        
        return groups_create_group($args);
    }

    /**
     * Create a test friendship
     */
    protected function create_test_friendship($initiator_id = null, $friend_id = null)
    {
        if (!bp_is_active('friends')) {
            $this->markTestSkipped('Friends component not active');
        }
        
        if (!$initiator_id) {
            $initiator_id = $this->user_id;
        }
        
        if (!$friend_id) {
            $friend_id = $this->factory->user->create();
        }
        
        return friends_add_friend($initiator_id, $friend_id, true);
    }

    /**
     * Create a test private message
     */
    protected function create_test_message($args = [])
    {
        if (!bp_is_active('messages')) {
            $this->markTestSkipped('Messages component not active');
        }
        
        $defaults = [
            'sender_id' => $this->user_id,
            'recipients' => [$this->admin_user_id],
            'subject' => 'Test Message Subject',
            'content' => 'Test message content',
        ];
        
        $args = wp_parse_args($args, $defaults);
        
        return messages_new_message($args);
    }

    /**
     * Create a test notification
     */
    protected function create_test_notification($args = [])
    {
        if (!bp_is_active('notifications')) {
            $this->markTestSkipped('Notifications component not active');
        }
        
        $defaults = [
            'user_id' => $this->user_id,
            'item_id' => 1,
            'secondary_item_id' => 0,
            'component_name' => 'activity',
            'component_action' => 'new_activity_comment',
            'date_notified' => bp_core_current_time(),
            'is_new' => 1,
        ];
        
        $args = wp_parse_args($args, $defaults);
        
        return bp_notifications_add_notification($args);
    }

    /**
     * Create test xProfile field
     */
    protected function create_test_xprofile_field($args = [])
    {
        if (!bp_is_active('xprofile')) {
            $this->markTestSkipped('XProfile component not active');
        }
        
        $defaults = [
            'field_group_id' => 1, // Default group
            'name' => 'Test Field',
            'description' => 'Test field description',
            'type' => 'textbox',
            'is_required' => false,
        ];
        
        $args = wp_parse_args($args, $defaults);
        
        return xprofile_insert_field($args);
    }

    /**
     * Assert that BuddyPress component is active
     */
    protected function assertBuddyPressComponentActive($component)
    {
        $this->assertTrue(bp_is_active($component), "BuddyPress {$component} component should be active");
    }

    /**
     * Assert that user has specific capability
     */
    protected function assertUserCan($capability, $user_id = null)
    {
        if (!$user_id) {
            $user_id = $this->user_id;
        }
        
        $user = new WP_User($user_id);
        $this->assertTrue($user->has_cap($capability), "User should have {$capability} capability");
    }

    /**
     * Assert that activity exists
     */
    protected function assertActivityExists($activity_id)
    {
        if (!bp_is_active('activity')) {
            $this->markTestSkipped('Activity component not active');
        }
        
        $activity = new BP_Activity_Activity($activity_id);
        $this->assertNotEmpty($activity->id, 'Activity should exist');
    }

    /**
     * Assert that group exists
     */
    protected function assertGroupExists($group_id)
    {
        if (!bp_is_active('groups')) {
            $this->markTestSkipped('Groups component not active');
        }
        
        $group = groups_get_group($group_id);
        $this->assertNotEmpty($group->id, 'Group should exist');
    }

    /**
     * Get BuddyPress table names
     */
    protected function get_bp_tables()
    {
        global $wpdb;
        
        return [
            'activity' => $wpdb->prefix . 'bp_activity',
            'activity_meta' => $wpdb->prefix . 'bp_activity_meta',
            'groups' => $wpdb->prefix . 'bp_groups',
            'groups_members' => $wpdb->prefix . 'bp_groups_members',
            'groups_groupmeta' => $wpdb->prefix . 'bp_groups_groupmeta',
            'messages_messages' => $wpdb->prefix . 'bp_messages_messages',
            'messages_recipients' => $wpdb->prefix . 'bp_messages_recipients',
            'friends' => $wpdb->prefix . 'bp_friends',
            'notifications' => $wpdb->prefix . 'bp_notifications',
            'xprofile_groups' => $wpdb->prefix . 'bp_xprofile_groups',
            'xprofile_fields' => $wpdb->prefix . 'bp_xprofile_fields',
            'xprofile_data' => $wpdb->prefix . 'bp_xprofile_data',
        ];
    }
}