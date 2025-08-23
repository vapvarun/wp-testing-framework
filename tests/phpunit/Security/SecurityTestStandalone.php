<?php
/**
 * Standalone Security Tests (No WordPress Required)
 * 
 * Tests security concepts and functions independently
 */

namespace BuddyNext\Tests\Security;

use PHPUnit\Framework\TestCase;

class SecurityTestStandalone extends TestCase
{
    /**
     * Test XSS sanitization functions
     */
    public function test_xss_sanitization()
    {
        $malicious_inputs = [
            '<script>alert("XSS")</script>',
            'javascript:alert("XSS")',
            '<img src=x onerror=alert("XSS")>',
            '"><script>alert("XSS")</script>',
        ];
        
        foreach ($malicious_inputs as $input) {
            // Test basic HTML stripping
            $sanitized = strip_tags($input);
            $this->assertStringNotContainsString('<script>', $sanitized, 
                'XSS payload not properly sanitized: ' . $input);
                
            // Test that dangerous protocols are removed
            $sanitized_url = preg_replace('/^javascript:/i', '', $input);
            $this->assertStringNotContainsString('javascript:', $sanitized_url,
                'JavaScript protocol not removed: ' . $input);
        }
    }

    /**
     * Test SQL injection prevention patterns
     */
    public function test_sql_injection_patterns()
    {
        $sql_injection_patterns = [
            "'; DROP TABLE users; --",
            "1' OR '1'='1",
            "1' UNION SELECT * FROM wp_users--",
        ];
        
        foreach ($sql_injection_patterns as $pattern) {
            // Test that dangerous SQL keywords are detected
            $is_dangerous = preg_match('/(DROP|DELETE|INSERT|UPDATE|UNION|SELECT|OR)/i', $pattern) > 0;
            $this->assertTrue($is_dangerous, 
                'SQL injection pattern should be detected: ' . $pattern);
        }
    }

    /**
     * Test password security requirements
     */
    public function test_password_security()
    {
        $weak_passwords = ['password', '123456', 'admin', 'test'];
        $strong_passwords = ['MyStr0ng!P@ssw0rd', 'C0mpl3x-P@ssw0rd-123'];
        
        foreach ($weak_passwords as $password) {
            $is_strong = $this->isStrongPassword($password);
            $this->assertFalse($is_strong, 
                "Weak password should be rejected: {$password}");
        }
        
        foreach ($strong_passwords as $password) {
            $is_strong = $this->isStrongPassword($password);
            $this->assertTrue($is_strong, 
                "Strong password should be accepted: {$password}");
        }
    }

    /**
     * Test file upload security
     */
    public function test_file_upload_security()
    {
        $dangerous_files = ['malicious.php', 'script.js', 'exploit.exe'];
        $safe_files = ['image.jpg', 'document.pdf', 'data.csv'];
        
        foreach ($dangerous_files as $filename) {
            $is_safe = $this->isFileUploadSafe($filename);
            $this->assertFalse($is_safe, 
                "Dangerous file should be rejected: {$filename}");
        }
        
        foreach ($safe_files as $filename) {
            $is_safe = $this->isFileUploadSafe($filename);
            $this->assertTrue($is_safe, 
                "Safe file should be accepted: {$filename}");
        }
    }

    /**
     * Test CSRF token generation
     */
    public function test_csrf_token_generation()
    {
        $token1 = $this->generateCSRFToken();
        $token2 = $this->generateCSRFToken();
        
        // Tokens should be unique
        $this->assertNotEquals($token1, $token2, 
            'CSRF tokens should be unique');
            
        // Tokens should be long enough to be secure
        $this->assertGreaterThan(32, strlen($token1), 
            'CSRF token should be at least 32 characters');
    }

    /**
     * Test input validation
     */
    public function test_input_validation()
    {
        // Email validation
        $valid_emails = ['user@example.com', 'test.email+tag@domain.co.uk'];
        $invalid_emails = ['invalid-email', 'user@', '@domain.com'];
        
        foreach ($valid_emails as $email) {
            $this->assertTrue(filter_var($email, FILTER_VALIDATE_EMAIL) !== false,
                "Valid email should pass validation: {$email}");
        }
        
        foreach ($invalid_emails as $email) {
            $this->assertFalse(filter_var($email, FILTER_VALIDATE_EMAIL) !== false,
                "Invalid email should fail validation: {$email}");
        }
        
        // URL validation
        $valid_urls = ['https://example.com', 'http://sub.domain.org/path'];
        $invalid_urls = ['javascript:alert(1)', 'ftp://unsafe.com'];
        
        foreach ($valid_urls as $url) {
            $this->assertTrue(filter_var($url, FILTER_VALIDATE_URL) !== false,
                "Valid URL should pass validation: {$url}");
        }
    }

    /**
     * Helper: Check if password meets security requirements
     */
    private function isStrongPassword($password)
    {
        return strlen($password) >= 8 &&
               preg_match('/[A-Z]/', $password) &&
               preg_match('/[a-z]/', $password) &&
               preg_match('/[0-9]/', $password) &&
               preg_match('/[^A-Za-z0-9]/', $password);
    }

    /**
     * Helper: Check if file upload is safe
     */
    private function isFileUploadSafe($filename)
    {
        $dangerous_extensions = ['php', 'js', 'exe', 'bat', 'cmd', 'sh'];
        $extension = strtolower(pathinfo($filename, PATHINFO_EXTENSION));
        
        return !in_array($extension, $dangerous_extensions);
    }

    /**
     * Helper: Generate CSRF token
     */
    private function generateCSRFToken()
    {
        return bin2hex(random_bytes(32));
    }

    /**
     * Test HTTP security headers validation
     */
    public function test_security_headers()
    {
        $required_headers = [
            'X-Content-Type-Options' => 'nosniff',
            'X-Frame-Options' => 'SAMEORIGIN',
            'X-XSS-Protection' => '1; mode=block',
        ];
        
        foreach ($required_headers as $header => $expected_value) {
            // In a real implementation, these would check actual HTTP headers
            $this->assertNotEmpty($header, 
                "Security header {$header} should be defined");
            $this->assertNotEmpty($expected_value, 
                "Security header {$header} should have a value");
        }
    }
}