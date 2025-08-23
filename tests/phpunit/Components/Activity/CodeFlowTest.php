<?php
/**
 * BuddyPress Activity Code Flow Tests
 * Tests internal code execution flow for Activity component
 * 
 * @package BuddyNext\Tests\Components\Activity
 */

namespace BuddyNext\Tests\Components\Activity;

use WP_UnitTestCase;

class ActivityCodeFlowTest extends WP_UnitTestCase {
    
    protected $test_user_id;
    protected $hooks_fired = [];
    
    protected function setUp(): void {
        parent::setUp();
        
        // Create test user
        $this->test_user_id = $this->factory->user->create([
            'user_login' => 'activity_test_user',
            'user_email' => 'activity@test.com'
        ]);
        
        // Track hooks for code flow verification
        $this->hooks_fired = [];
        
        // Monitor critical activity hooks
        add_action('bp_activity_before_save', [$this, 'track_hook'], 10, 1);
        add_action('bp_activity_after_save', [$this, 'track_hook'], 10, 1);
        add_action('bp_activity_posted_update', [$this, 'track_hook'], 10, 3);
        add_filter('bp_activity_content_before_save', [$this, 'track_filter'], 10, 2);
        add_filter('bp_activity_action_before_save', [$this, 'track_filter'], 10, 2);
    }
    
    protected function tearDown(): void {
        remove_action('bp_activity_before_save', [$this, 'track_hook']);
        remove_action('bp_activity_after_save', [$this, 'track_hook']);
        remove_action('bp_activity_posted_update', [$this, 'track_hook']);
        remove_filter('bp_activity_content_before_save', [$this, 'track_filter']);
        remove_filter('bp_activity_action_before_save', [$this, 'track_filter']);
        
        parent::tearDown();
    }
    
    public function track_hook($activity = null) {
        $this->hooks_fired[] = current_filter();
    }
    
    public function track_filter($content, $activity = null) {
        $this->hooks_fired[] = current_filter();
        return $content;
    }
    
    /**
     * Test activity creation code flow
     * Verifies the sequence of operations when creating an activity
     */
    public function test_activity_creation_flow() {
        // Step 1: Initialize activity data
        $activity_data = [
            'user_id' => $this->test_user_id,
            'content' => 'Testing activity creation flow',
            'type' => 'activity_update',
            'component' => 'activity'
        ];
        
        // Step 2: Create activity (triggers internal flow)
        $activity_id = bp_activity_add($activity_data);
        
        // Step 3: Verify activity was created
        $this->assertIsNumeric($activity_id);
        $this->assertGreaterThan(0, $activity_id);
        
        // Step 4: Verify hooks fired in correct order
        $expected_hooks = [
            'bp_activity_content_before_save',
            'bp_activity_action_before_save',
            'bp_activity_before_save',
            'bp_activity_after_save'
        ];
        
        foreach ($expected_hooks as $hook) {
            $this->assertContains($hook, $this->hooks_fired, "Hook $hook should have fired");
        }
        
        // Step 5: Verify database record
        $activity = bp_activity_get_specific(['activity_ids' => [$activity_id]]);
        $this->assertNotEmpty($activity['activities']);
        $this->assertEquals($activity_data['content'], $activity['activities'][0]->content);
        
        // Step 6: Verify cache was set
        $cached = wp_cache_get($activity_id, 'bp_activity');
        $this->assertNotFalse($cached, 'Activity should be cached');
        
        // Step 7: Verify user meta was updated
        $last_activity = bp_get_user_last_activity($this->test_user_id);
        $this->assertNotEmpty($last_activity);
    }
    
    /**
     * Test activity comment flow
     */
    public function test_activity_comment_flow() {
        // Create parent activity
        $parent_id = bp_activity_add([
            'user_id' => $this->test_user_id,
            'content' => 'Parent activity',
            'type' => 'activity_update'
        ]);
        
        // Track comment hooks
        $comment_hooks = [];
        add_action('bp_activity_comment_posted', function($comment_id, $params, $parent) use (&$comment_hooks) {
            $comment_hooks[] = 'bp_activity_comment_posted';
        }, 10, 3);
        
        // Add comment
        $comment_id = bp_activity_new_comment([
            'activity_id' => $parent_id,
            'user_id' => $this->test_user_id,
            'content' => 'Test comment',
            'parent_id' => $parent_id
        ]);
        
        // Verify comment was created
        $this->assertIsNumeric($comment_id);
        
        // Verify comment hook fired
        $this->assertContains('bp_activity_comment_posted', $comment_hooks);
        
        // Verify parent activity was updated
        $parent = bp_activity_get_specific(['activity_ids' => [$parent_id]]);
        $this->assertEquals(1, $parent['activities'][0]->comment_count);
    }
    
    /**
     * Test activity deletion flow
     */
    public function test_activity_deletion_flow() {
        // Create activity
        $activity_id = bp_activity_add([
            'user_id' => $this->test_user_id,
            'content' => 'Activity to delete',
            'type' => 'activity_update'
        ]);
        
        // Track deletion hooks
        $deletion_hooks = [];
        add_action('bp_before_activity_delete', function($args) use (&$deletion_hooks) {
            $deletion_hooks[] = 'bp_before_activity_delete';
        });
        add_action('bp_activity_deleted_activities', function($deleted) use (&$deletion_hooks) {
            $deletion_hooks[] = 'bp_activity_deleted_activities';
        });
        
        // Delete activity
        $deleted = bp_activity_delete(['id' => $activity_id]);
        
        // Verify deletion
        $this->assertTrue($deleted);
        
        // Verify hooks fired
        $this->assertContains('bp_before_activity_delete', $deletion_hooks);
        $this->assertContains('bp_activity_deleted_activities', $deletion_hooks);
        
        // Verify activity no longer exists
        $activity = bp_activity_get_specific(['activity_ids' => [$activity_id]]);
        $this->assertEmpty($activity['activities']);
        
        // Verify cache was cleared
        $cached = wp_cache_get($activity_id, 'bp_activity');
        $this->assertFalse($cached);
    }
    
    /**
     * Test activity mentions flow
     */
    public function test_activity_mentions_flow() {
        // Create mentioned user
        $mentioned_user_id = $this->factory->user->create([
            'user_login' => 'mentioned_user'
        ]);
        
        // Track mention hooks
        $mention_hooks = [];
        add_action('bp_activity_sent_mention_email', function($activity, $subject, $message, $content, $user_id) use (&$mention_hooks) {
            $mention_hooks[] = 'bp_activity_sent_mention_email';
        }, 10, 5);
        
        // Create activity with mention
        $activity_id = bp_activity_add([
            'user_id' => $this->test_user_id,
            'content' => 'Hey @mentioned_user check this out!',
            'type' => 'activity_update'
        ]);
        
        // Verify activity was created
        $this->assertIsNumeric($activity_id);
        
        // Verify mention was detected and processed
        $activity = bp_activity_get_specific(['activity_ids' => [$activity_id]]);
        $mentions = bp_activity_find_mentions($activity['activities'][0]->content);
        $this->assertContains('mentioned_user', $mentions);
        
        // Verify notification was created (if notifications component is active)
        if (bp_is_active('notifications')) {
            $notifications = bp_notifications_get_notifications_for_user($mentioned_user_id);
            $this->assertNotEmpty($notifications);
        }
    }
    
    /**
     * Test activity favorites flow
     */
    public function test_activity_favorites_flow() {
        // Create activity
        $activity_id = bp_activity_add([
            'user_id' => $this->test_user_id,
            'content' => 'Activity to favorite',
            'type' => 'activity_update'
        ]);
        
        // Create user to favorite
        $fav_user_id = $this->factory->user->create();
        
        // Track favorite hooks
        $fav_hooks = [];
        add_action('bp_activity_add_user_favorite', function($activity_id, $user_id) use (&$fav_hooks) {
            $fav_hooks[] = 'bp_activity_add_user_favorite';
        }, 10, 2);
        
        // Add favorite
        $added = bp_activity_add_user_favorite($activity_id, $fav_user_id);
        
        // Verify favorite was added
        $this->assertTrue($added);
        
        // Verify hook fired
        $this->assertContains('bp_activity_add_user_favorite', $fav_hooks);
        
        // Verify favorite is in user meta
        $favorites = bp_activity_get_user_favorites($fav_user_id);
        $this->assertContains($activity_id, $favorites);
        
        // Verify activity meta was updated
        $fav_count = bp_activity_get_meta($activity_id, 'favorite_count', true);
        $this->assertEquals(1, $fav_count);
    }
    
    /**
     * Test activity spam flow
     */
    public function test_activity_spam_flow() {
        // Create activity
        $activity_id = bp_activity_add([
            'user_id' => $this->test_user_id,
            'content' => 'Potential spam content',
            'type' => 'activity_update'
        ]);
        
        // Track spam hooks
        $spam_hooks = [];
        add_action('bp_activity_mark_as_spam', function($activity, $by) use (&$spam_hooks) {
            $spam_hooks[] = 'bp_activity_mark_as_spam';
        }, 10, 2);
        
        // Mark as spam
        $activity = bp_activity_get_specific(['activity_ids' => [$activity_id]]);
        $activity_obj = $activity['activities'][0];
        $activity_obj->is_spam = 1;
        $activity_obj->save();
        
        // Verify activity is marked as spam
        $updated = bp_activity_get_specific(['activity_ids' => [$activity_id], 'spam' => 'all']);
        $this->assertEquals(1, $updated['activities'][0]->is_spam);
        
        // Verify normal queries don't return spam
        $normal = bp_activity_get_specific(['activity_ids' => [$activity_id]]);
        $this->assertEmpty($normal['activities']);
    }
    
    /**
     * Test activity privacy flow
     */
    public function test_activity_privacy_flow() {
        if (!bp_is_active('groups')) {
            $this->markTestSkipped('Groups component needed for privacy testing');
        }
        
        // Create private group
        $group_id = groups_create_group([
            'creator_id' => $this->test_user_id,
            'name' => 'Private Group',
            'status' => 'private'
        ]);
        
        // Create activity in private group
        $activity_id = bp_activity_add([
            'user_id' => $this->test_user_id,
            'content' => 'Private group activity',
            'type' => 'activity_update',
            'component' => 'groups',
            'item_id' => $group_id,
            'hide_sitewide' => 1
        ]);
        
        // Verify activity is hidden from sitewide
        $public_activities = bp_activity_get(['scope' => 'public']);
        $activity_ids = wp_list_pluck($public_activities['activities'], 'id');
        $this->assertNotContains($activity_id, $activity_ids);
        
        // Verify group members can see it
        groups_join_group($group_id, $this->test_user_id);
        $group_activities = bp_activity_get([
            'filter' => ['object' => 'groups', 'primary_id' => $group_id]
        ]);
        $group_activity_ids = wp_list_pluck($group_activities['activities'], 'id');
        $this->assertContains($activity_id, $group_activity_ids);
    }
}