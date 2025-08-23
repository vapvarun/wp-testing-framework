<?php
/**
 * Integration Tests for Buddypress
 * 
 * Tests plugin functionality with WordPress environment
 */

namespace Tests\Integration;

use WP_UnitTestCase;

class buddypressIntegrationTest extends WP_UnitTestCase
{
    public function setUp(): void
    {
        parent::setUp();
        
        // Activate plugin for testing
        if (!is_plugin_active('buddypress/buddypress.php')) {
            activate_plugin('buddypress/buddypress.php');
        }
    }
    
    public function test_plugin_is_active()
    {
        $this->assertTrue(is_plugin_active('buddypress/buddypress.php'));
    }
    
    
    
    
    
    
}