<?php
namespace WPTestingFramework\Plugins\bbpress\Tests\Unit;

use PHPUnit\Framework\TestCase;

class BasicTest extends TestCase {
    public function testPluginExists() {
        $plugin_file = dirname(__DIR__, 5) . '/wp-content/plugins/bbpress/bbpress.php';
        $this->assertTrue(file_exists($plugin_file), 'Plugin main file should exist');
    }
    
    public function testPluginStructure() {
        $plugin_dir = dirname(__DIR__, 5) . '/wp-content/plugins/bbpress';
        $this->assertDirectoryExists($plugin_dir, 'Plugin directory should exist');
    }
}
