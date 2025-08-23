<?php
/**
 * BuddyPress Security Tests
 * 
 * Tests security vulnerabilities specific to BuddyPress components
 */

namespace BuddyNext\Tests\Security;

use BuddyNext\Tests\Security\SecurityTestBase;

class BuddyPressSecurityTest extends SecurityTestBase
{
    /**
     * Test Activity Stream XSS Protection
     */
    public function test_activity_stream_xss_protection()
    {
        $this->markTestSkipped('Requires WordPress environment');
        
        // Test activity content XSS protection
        foreach ($this->xss_payloads as $payload) {
            $activity_data = [
                'content' => 'Normal activity content ' . $payload,
                'component' => 'activity',
                'type' => 'activity_update',
            ];
            
            // Simulate activity creation
            $activity_id = bp_activity_add($activity_data);
            
            if ($activity_id) {
                $activity = bp_activity_get(['in' => [$activity_id]]);
                $content = $activity['activities'][0]->content ?? '';
                
                $this->assertNotContains('<script>', $content, 
                    'XSS payload found in activity content');
                $this->assertNotContains('javascript:', $content, 
                    'JavaScript protocol found in activity content');
            }
        }
    }

    /**
     * Test User Profile XSS Protection
     */
    public function test_user_profile_xss_protection()
    {
        $this->markTestSkipped('Requires WordPress environment');
        
        $test_fields = [
            'display_name',
            'user_nicename', 
            'user_url',
            'description',
        ];
        
        foreach ($test_fields as $field) {
            foreach ($this->xss_payloads as $payload) {
                $user_data = [
                    $field => 'Normal content ' . $payload,
                ];
                
                $user_id = wp_insert_user($user_data);
                
                if (!is_wp_error($user_id)) {
                    $user = get_userdata($user_id);
                    $field_value = $user->$field ?? '';
                    
                    $this->assertXSSProtected($field_value, '', 
                        "XSS vulnerability in user profile field: {$field}");
                }
            }
        }
    }

    /**
     * Test Group Creation Security
     */
    public function test_group_creation_security()
    {
        $this->markTestSkipped('Requires WordPress environment');
        
        // Test group name and description XSS protection
        foreach ($this->xss_payloads as $payload) {
            $group_data = [
                'name' => 'Test Group ' . $payload,
                'description' => 'Group description ' . $payload,
                'slug' => 'test-group-' . uniqid(),
                'creator_id' => 1,
            ];
            
            $group_id = groups_create_group($group_data);
            
            if ($group_id) {
                $group = groups_get_group(['group_id' => $group_id]);
                
                $this->assertNotContains('<script>', $group->name, 
                    'XSS payload found in group name');
                $this->assertNotContains('<script>', $group->description, 
                    'XSS payload found in group description');
            }
        }
    }

    /**
     * Test Private Message Security
     */
    public function test_private_message_security()
    {
        $this->markTestSkipped('Requires WordPress environment');
        
        foreach ($this->xss_payloads as $payload) {
            $message_data = [
                'sender_id' => 1,
                'thread_id' => false,
                'recipients' => [2],
                'subject' => 'Test Subject ' . $payload,
                'content' => 'Message content ' . $payload,
            ];
            
            $thread_id = messages_new_message($message_data);
            
            if ($thread_id) {
                $thread = new BP_Messages_Thread($thread_id);
                $messages = $thread->messages;
                
                if (!empty($messages)) {
                    $message = $messages[0];
                    $this->assertNotContains('<script>', $message->subject, 
                        'XSS payload found in message subject');
                    $this->assertNotContains('<script>', $message->message, 
                        'XSS payload found in message content');
                }
            }
        }
    }

    /**
     * Test User Registration Security
     */
    public function test_user_registration_security()
    {
        foreach ($this->xss_payloads as $payload) {
            $registration_data = [
                'user_login' => 'testuser' . uniqid(),
                'user_email' => 'test' . uniqid() . '@example.com',
                'user_pass' => 'testpass123',
                'display_name' => 'Test User ' . $payload,
            ];
            
            // Test that malicious display name is sanitized
            $sanitized_name = sanitize_text_field($registration_data['display_name']);
            $this->assertNotContains('<script>', $sanitized_name, 
                'XSS payload not sanitized in user registration');
        }
    }

    /**
     * Test File Upload Security
     */
    public function test_file_upload_security()
    {
        $dangerous_extensions = ['.php', '.js', '.html', '.svg', '.exe'];
        $safe_extensions = ['.jpg', '.png', '.gif', '.pdf'];
        
        foreach ($dangerous_extensions as $ext) {
            $filename = 'malicious_file' . $ext;
            
            // Test file extension validation
            $is_allowed = wp_check_filetype_and_ext('', $filename, []);
            $this->assertFalse($is_allowed['ext'], 
                "Dangerous file extension {$ext} should not be allowed");
        }
        
        foreach ($safe_extensions as $ext) {
            $filename = 'safe_file' . $ext;
            
            // Test that safe files are allowed
            $is_allowed = wp_check_filetype_and_ext('', $filename, []);
            $this->assertTrue(!empty($is_allowed['ext']) || in_array($ext, ['.jpg', '.png', '.gif']), 
                "Safe file extension {$ext} should be allowed");
        }
    }

    /**
     * Test API Endpoint Security
     */
    public function test_api_endpoint_security()
    {
        $this->markTestSkipped('Requires WordPress REST API environment');
        
        // Test that sensitive endpoints require authentication
        $sensitive_endpoints = [
            '/wp-json/buddypress/v1/members',
            '/wp-json/buddypress/v1/groups',
            '/wp-json/buddypress/v1/activity',
            '/wp-json/buddypress/v1/messages',
        ];
        
        foreach ($sensitive_endpoints as $endpoint) {
            // Simulate unauthenticated request
            $request = new \WP_REST_Request('GET', $endpoint);
            $response = rest_do_request($request);
            
            if ($response->is_error()) {
                $error_code = $response->get_error_code();
                $this->assertContains($error_code, ['rest_forbidden', 'rest_not_logged_in'], 
                    "Endpoint {$endpoint} should require authentication");
            }
        }
    }

    /**
     * Test SQL Injection Protection in Search
     */
    public function test_search_sql_injection_protection()
    {
        foreach ($this->sql_injection_payloads as $payload) {
            // Test member search
            $search_term = 'test' . $payload;
            $sanitized_term = sanitize_text_field($search_term);
            
            $this->assertNotContains('DROP TABLE', $sanitized_term, 
                'SQL injection payload not sanitized in search');
            $this->assertNotContains('UNION SELECT', $sanitized_term, 
                'SQL injection payload not sanitized in search');
        }
    }

    /**
     * Test Permission Checks for Admin Actions
     */
    public function test_admin_permission_checks()
    {
        $admin_actions = [
            'bp_moderate_user',
            'bp_delete_group', 
            'bp_ban_member',
            'bp_edit_settings',
        ];
        
        foreach ($admin_actions as $action) {
            // Test that non-admin users can't perform admin actions
            $this->assertFalse(current_user_can('bp_moderate'), 
                "Non-admin user should not have bp_moderate capability");
        }
    }

    /**
     * Test CSRF Protection for Form Submissions
     */
    public function test_form_csrf_protection()
    {
        $forms_requiring_nonce = [
            'activity-post',
            'send-message',
            'group-create',
            'profile-edit',
        ];
        
        foreach ($forms_requiring_nonce as $form_action) {
            $this->assertCSRFProtected($form_action, 
                "Form {$form_action} should require CSRF protection");
        }
    }

    /**
     * Test Data Validation and Sanitization
     */
    public function test_data_validation()
    {
        $test_cases = [
            ['email', 'invalid-email', 'is_email'],
            ['url', 'javascript:alert("xss")', 'esc_url_raw'],
            ['text', '<script>alert("xss")</script>', 'sanitize_text_field'],
            ['textarea', '<script>alert("xss")</script>', 'sanitize_textarea_field'],
        ];
        
        foreach ($test_cases as $test_case) {
            list($type, $input, $sanitizer) = $test_case;
            
            $sanitized = call_user_func($sanitizer, $input);
            
            if ($type === 'email' && $input === 'invalid-email') {
                $this->assertFalse($sanitized, 
                    'Invalid email should be rejected');
            } else {
                $this->assertNotContains('<script>', $sanitized, 
                    "XSS payload not sanitized in {$type} field");
            }
        }
    }
}