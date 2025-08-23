<?php
/**
 * Base class for BuddyPress Security Tests
 * 
 * Tests various security aspects of BuddyPress components including:
 * - SQL injection prevention
 * - XSS prevention
 * - CSRF protection
 * - Permission checks
 * - Data sanitization
 */

namespace BuddyNext\Tests\Security;

use PHPUnit\Framework\TestCase;

abstract class SecurityTestBase extends TestCase
{
    /**
     * Common XSS payloads for testing
     */
    protected $xss_payloads = [
        '<script>alert("XSS")</script>',
        'javascript:alert("XSS")',
        '<img src=x onerror=alert("XSS")>',
        '"><script>alert("XSS")</script>',
        '\';alert("XSS");//',
        '<svg onload=alert("XSS")>',
        '<iframe src=javascript:alert("XSS")></iframe>',
    ];

    /**
     * Common SQL injection payloads for testing
     */
    protected $sql_injection_payloads = [
        "' OR '1'='1",
        "'; DROP TABLE wp_users; --",
        "1' UNION SELECT null,user_pass FROM wp_users--",
        "' OR 1=1 --",
        "'; SELECT * FROM wp_users WHERE 'x'='x",
        "1' AND (SELECT COUNT(*) FROM wp_users) > 0 --",
    ];

    /**
     * Test XSS protection in form fields
     */
    protected function assertXSSProtected($field_value, $expected_safe_output, $message = '')
    {
        foreach ($this->xss_payloads as $payload) {
            $test_value = $field_value . $payload;
            
            // Test that XSS payload is properly escaped/sanitized
            $sanitized = wp_kses($test_value, []);
            $this->assertNotContains('<script>', $sanitized, 
                "XSS payload not properly sanitized in field: {$field_value}. " . $message);
            $this->assertNotContains('javascript:', $sanitized, 
                "JavaScript protocol not blocked in field: {$field_value}. " . $message);
        }
    }

    /**
     * Test SQL injection protection
     */
    protected function assertSQLInjectionProtected($query_method, $test_params, $message = '')
    {
        foreach ($this->sql_injection_payloads as $payload) {
            $malicious_params = array_map(function($param) use ($payload) {
                return is_string($param) ? $param . $payload : $param;
            }, $test_params);

            // This should not cause any SQL errors or return unexpected data
            try {
                $result = call_user_func_array($query_method, $malicious_params);
                
                // Verify result doesn't contain sensitive data that shouldn't be accessible
                if (is_array($result) && !empty($result)) {
                    $this->assertNotContains('wp_users', json_encode($result), 
                        "SQL injection may have exposed sensitive table data. " . $message);
                }
            } catch (\Exception $e) {
                // SQL errors might indicate injection vulnerability
                $this->assertNotContains('SQL syntax', $e->getMessage(), 
                    "SQL injection payload caused database error. " . $message);
            }
        }
    }

    /**
     * Test CSRF protection
     */
    protected function assertCSRFProtected($action_name, $message = '')
    {
        // Test without nonce
        $_POST['action'] = $action_name;
        unset($_POST['_wpnonce']);
        
        $this->assertFalse(wp_verify_nonce('', $action_name), 
            "Action {$action_name} should require valid nonce. " . $message);
    }

    /**
     * Test user permission checks
     */
    protected function assertPermissionRequired($callback, $required_capability, $message = '')
    {
        // Test with user that doesn't have required capability
        $user_id = $this->factory->user->create(['role' => 'subscriber']);
        wp_set_current_user($user_id);
        
        $this->assertFalse(current_user_can($required_capability), 
            "Test user should not have {$required_capability} capability");
        
        // Callback should fail or return unauthorized result
        $result = call_user_func($callback);
        
        $this->assertFalse($result, 
            "Action should be denied for users without {$required_capability}. " . $message);
    }

    /**
     * Test data sanitization
     */
    protected function assertDataSanitized($input_data, $sanitization_function, $message = '')
    {
        $malicious_inputs = array_merge($this->xss_payloads, [
            '<script>malicious()</script>',
            'DROP TABLE wp_posts',
            '../../../etc/passwd',
            '<?php evil_code(); ?>',
        ]);

        foreach ($malicious_inputs as $malicious_input) {
            $test_data = is_array($input_data) ? 
                array_merge($input_data, ['malicious' => $malicious_input]) : 
                $input_data . $malicious_input;
                
            $sanitized = call_user_func($sanitization_function, $test_data);
            
            $this->assertNotContains('<script>', $sanitized, 
                "Malicious script not sanitized. " . $message);
            $this->assertNotContains('<?php', $sanitized, 
                "PHP code not sanitized. " . $message);
        }
    }
}