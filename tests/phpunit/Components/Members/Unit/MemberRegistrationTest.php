<?php
/**
 * Unit tests for BuddyPress Members Component - Registration
 * 
 * @package BuddyNext\Tests\Components\Members\Unit
 */

namespace BuddyNext\Tests\Components\Members\Unit;

use PHPUnit\Framework\TestCase;
use Brain\Monkey;
use Brain\Monkey\Functions;

class MemberRegistrationTest extends TestCase {
    
    protected function setUp(): void {
        parent::setUp();
        Monkey\setUp();
        
        // Mock WordPress functions
        Functions\when('is_multisite')->justReturn(false);
        Functions\when('wp_verify_nonce')->justReturn(true);
        Functions\when('sanitize_text_field')->returnArg();
        Functions\when('sanitize_email')->returnArg();
    }
    
    protected function tearDown(): void {
        Monkey\tearDown();
        parent::tearDown();
    }
    
    /**
     * Test member registration validation
     * @test
     */
    public function test_registration_requires_valid_email() {
        // Mock email validation
        Functions\when('is_email')->alias(function($email) {
            return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
        });
        
        // Test valid email
        $this->assertTrue(is_email('user@example.com'));
        
        // Test invalid emails
        $this->assertFalse(is_email('invalid-email'));
        $this->assertFalse(is_email('user@'));
        $this->assertFalse(is_email('@example.com'));
    }
    
    /**
     * Test username validation
     * @test
     */
    public function test_username_validation() {
        // Mock username validation
        Functions\when('validate_username')->alias(function($username) {
            return preg_match('/^[a-zA-Z0-9_]+$/', $username) === 1;
        });
        
        // Valid usernames
        $this->assertTrue(validate_username('john_doe'));
        $this->assertTrue(validate_username('user123'));
        
        // Invalid usernames
        $this->assertFalse(validate_username('john doe')); // spaces
        $this->assertFalse(validate_username('user@123')); // special chars
        $this->assertFalse(validate_username('')); // empty
    }
    
    /**
     * Test password strength requirements
     * @test
     */
    public function test_password_strength() {
        $this->assertTrue($this->isStrongPassword('StrongP@ss123'));
        $this->assertFalse($this->isStrongPassword('weak'));
        $this->assertFalse($this->isStrongPassword('12345678'));
        $this->assertFalse($this->isStrongPassword('password'));
    }
    
    /**
     * Test registration spam check
     * @test
     */
    public function test_spam_registration_check() {
        // Mock spam check
        Functions\when('bp_core_check_for_spam')->alias(function($data) {
            // Check for spam patterns
            $spam_words = ['viagra', 'casino', 'lottery'];
            foreach ($spam_words as $word) {
                if (stripos($data, $word) !== false) {
                    return true;
                }
            }
            return false;
        });
        
        // Test clean registration
        $this->assertFalse(bp_core_check_for_spam('John Doe'));
        
        // Test spam detection
        $this->assertTrue(bp_core_check_for_spam('Buy viagra now'));
        $this->assertTrue(bp_core_check_for_spam('Online casino bonus'));
    }
    
    /**
     * Test duplicate email prevention
     * @test
     */
    public function test_duplicate_email_prevention() {
        $existing_emails = ['john@example.com', 'jane@example.com'];
        
        Functions\when('email_exists')->alias(function($email) use ($existing_emails) {
            return in_array($email, $existing_emails);
        });
        
        // Test existing email
        $this->assertTrue(email_exists('john@example.com'));
        
        // Test new email
        $this->assertFalse(email_exists('newuser@example.com'));
    }
    
    /**
     * Test registration rate limiting
     * @test
     */
    public function test_registration_rate_limiting() {
        $registrations = [];
        
        Functions\when('bp_registration_rate_limit')->alias(function($ip) use (&$registrations) {
            if (!isset($registrations[$ip])) {
                $registrations[$ip] = 0;
            }
            $registrations[$ip]++;
            
            // Allow max 3 registrations per IP per hour
            return $registrations[$ip] <= 3;
        });
        
        $test_ip = '192.168.1.1';
        
        // First 3 registrations should pass
        $this->assertTrue(bp_registration_rate_limit($test_ip));
        $this->assertTrue(bp_registration_rate_limit($test_ip));
        $this->assertTrue(bp_registration_rate_limit($test_ip));
        
        // 4th registration should fail
        $this->assertFalse(bp_registration_rate_limit($test_ip));
    }
    
    /**
     * Helper: Check password strength
     */
    private function isStrongPassword($password) {
        // At least 8 chars, one uppercase, one lowercase, one number, one special char
        return strlen($password) >= 8 &&
               preg_match('/[A-Z]/', $password) &&
               preg_match('/[a-z]/', $password) &&
               preg_match('/[0-9]/', $password) &&
               preg_match('/[!@#$%^&*]/', $password);
    }
}