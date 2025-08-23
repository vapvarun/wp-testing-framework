<?php
/**
 * Sample unit test to verify PHPUnit setup
 * 
 * @package BuddyNext\Tests\Unit
 */

namespace BuddyNext\Tests\Unit;

use PHPUnit\Framework\TestCase;

class SampleTest extends TestCase {
    
    /**
     * Test that PHPUnit is working
     */
    public function test_phpunit_is_working() {
        $this->assertTrue( true );
        $this->assertEquals( 4, 2 + 2 );
    }
    
    /**
     * Test that assertions work properly
     */
    public function test_basic_assertions() {
        $array = [ 'buddypress', 'theme', 'test' ];
        
        $this->assertCount( 3, $array );
        $this->assertContains( 'buddypress', $array );
        $this->assertIsArray( $array );
    }
    
    /**
     * Test string operations
     */
    public function test_string_operations() {
        $theme_name = 'BuddyNext';
        
        $this->assertStringStartsWith( 'Buddy', $theme_name );
        $this->assertStringEndsWith( 'Next', $theme_name );
        $this->assertEquals( 9, strlen( $theme_name ) );
    }
}