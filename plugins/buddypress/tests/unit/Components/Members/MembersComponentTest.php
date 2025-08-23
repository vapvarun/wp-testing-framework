<?php
/**
 * BuddyPress Members Component Tests
 * 
 * Tests based on component scan data without requiring WordPress
 */

namespace Tests\Components\Members\Unit;

use PHPUnit\Framework\TestCase;

class MembersComponentTest extends TestCase {
    
    private $componentScanData;
    
    protected function setUp(): void {
        parent::setUp();
        
        // Load component scan data if available
        $scanPath = dirname(dirname(dirname(dirname(dirname(__DIR__))))) . '/wp-content/uploads/wbcom-scan/buddypress-components-scan.json';
        if (file_exists($scanPath)) {
            $scanData = json_decode(file_get_contents($scanPath), true);
            $this->componentScanData = $scanData['members'] ?? null;
        }
    }
    
    /**
     * Test that Members component scan data exists
     */
    public function testMembersComponentScanExists() {
        $this->assertNotNull($this->componentScanData, 'Members component scan data should exist');
    }
    
    /**
     * Test Members component has expected structure
     */
    public function testMembersComponentStructure() {
        if (!$this->componentScanData) {
            $this->markTestSkipped('Component scan data not available');
        }
        
        $this->assertArrayHasKey('name', $this->componentScanData);
        $this->assertEquals('Members', $this->componentScanData['name']);
        
        $this->assertArrayHasKey('files', $this->componentScanData);
        $this->assertArrayHasKey('classes', $this->componentScanData);
        $this->assertArrayHasKey('functions', $this->componentScanData);
        $this->assertArrayHasKey('hooks', $this->componentScanData);
    }
    
    /**
     * Test Members component file count
     */
    public function testMembersComponentFileCount() {
        if (!$this->componentScanData) {
            $this->markTestSkipped('Component scan data not available');
        }
        
        $fileCount = $this->componentScanData['metrics']['total_files'] ?? 0;
        
        // Members component should have significant number of files
        $this->assertGreaterThan(50, $fileCount, 'Members component should have more than 50 files');
        $this->assertLessThan(200, $fileCount, 'Members component should have less than 200 files');
        
        // Based on scan: 74 files
        $this->assertEquals(74, $fileCount, 'Members component should have exactly 74 files');
    }
    
    /**
     * Test Members component classes
     */
    public function testMembersComponentClasses() {
        if (!$this->componentScanData) {
            $this->markTestSkipped('Component scan data not available');
        }
        
        $classCount = $this->componentScanData['metrics']['total_classes'] ?? 0;
        
        // Members should have multiple classes
        $this->assertGreaterThan(10, $classCount, 'Members component should have more than 10 classes');
        
        // Based on scan: 20 classes
        $this->assertEquals(20, $classCount, 'Members component should have exactly 20 classes');
    }
    
    /**
     * Test Members component complexity
     */
    public function testMembersComponentComplexity() {
        if (!$this->componentScanData) {
            $this->markTestSkipped('Component scan data not available');
        }
        
        $complexity = $this->componentScanData['metrics']['complexity_score'] ?? 0;
        
        // Members is a complex component
        $this->assertGreaterThan(500, $complexity, 'Members component should have complexity > 500');
        
        // Based on scan: 627
        $this->assertEquals(627, $complexity, 'Members component complexity should be 627');
    }
    
    /**
     * Test Members component hooks
     */
    public function testMembersComponentHooks() {
        if (!$this->componentScanData) {
            $this->markTestSkipped('Component scan data not available');
        }
        
        $hookCount = $this->componentScanData['metrics']['total_hooks'] ?? 0;
        
        // Members should have many hooks for extensibility
        $this->assertGreaterThan(100, $hookCount, 'Members component should have more than 100 hooks');
        
        // Based on scan: 129 hooks
        $this->assertEquals(129, $hookCount, 'Members component should have exactly 129 hooks');
    }
    
    /**
     * Test Members component test scenarios exist
     */
    public function testMembersComponentTestScenarios() {
        if (!$this->componentScanData) {
            $this->markTestSkipped('Component scan data not available');
        }
        
        $this->assertArrayHasKey('test_scenarios', $this->componentScanData);
        $scenarios = $this->componentScanData['test_scenarios'];
        
        // Members should have key test scenarios
        $this->assertArrayHasKey('user_registration', $scenarios);
        $this->assertArrayHasKey('profile_update', $scenarios);
        $this->assertArrayHasKey('member_directory', $scenarios);
        $this->assertArrayHasKey('member_search', $scenarios);
        $this->assertArrayHasKey('avatar_upload', $scenarios);
    }
    
    /**
     * Test Members component dependencies
     */
    public function testMembersComponentDependencies() {
        if (!$this->componentScanData) {
            $this->markTestSkipped('Component scan data not available');
        }
        
        $this->assertArrayHasKey('dependencies', $this->componentScanData);
        $dependencies = $this->componentScanData['dependencies'];
        
        // Members should depend on core
        $this->assertContains('core', $dependencies, 'Members should depend on Core component');
    }
    
    /**
     * Test Members component database tables
     */
    public function testMembersComponentDatabaseTables() {
        if (!$this->componentScanData) {
            $this->markTestSkipped('Component scan data not available');
        }
        
        $this->assertArrayHasKey('database_tables', $this->componentScanData);
        $tables = $this->componentScanData['database_tables'];
        
        // Members might use signup table
        $this->assertIsArray($tables);
    }
    
    /**
     * Test Members component REST endpoints
     */
    public function testMembersComponentRestEndpoints() {
        if (!$this->componentScanData) {
            $this->markTestSkipped('Component scan data not available');
        }
        
        $this->assertArrayHasKey('rest_endpoints', $this->componentScanData);
        $endpoints = $this->componentScanData['rest_endpoints'];
        
        // Members should have REST endpoints
        $this->assertIsArray($endpoints);
        
        // Check for members namespace
        foreach ($endpoints as $endpoint) {
            if (isset($endpoint['namespace'])) {
                $this->assertStringContainsString('buddypress', $endpoint['namespace']);
            }
        }
    }
    
    /**
     * Test Members component AJAX handlers
     */
    public function testMembersComponentAjaxHandlers() {
        if (!$this->componentScanData) {
            $this->markTestSkipped('Component scan data not available');
        }
        
        $this->assertArrayHasKey('ajax_handlers', $this->componentScanData);
        $handlers = $this->componentScanData['ajax_handlers'];
        
        $this->assertIsArray($handlers);
    }
    
    /**
     * Test Members component functions categorization
     */
    public function testMembersComponentFunctions() {
        if (!$this->componentScanData) {
            $this->markTestSkipped('Component scan data not available');
        }
        
        $functions = $this->componentScanData['functions'] ?? [];
        
        // Count function types
        $functionTypes = [];
        foreach ($functions as $func) {
            $type = $func['type'] ?? 'unknown';
            if (!isset($functionTypes[$type])) {
                $functionTypes[$type] = 0;
            }
            $functionTypes[$type]++;
        }
        
        // Members should have various function types
        $this->assertNotEmpty($functionTypes, 'Members should have categorized functions');
    }
    
    /**
     * Test Members component file types
     */
    public function testMembersComponentFileTypes() {
        if (!$this->componentScanData) {
            $this->markTestSkipped('Component scan data not available');
        }
        
        $files = $this->componentScanData['files'] ?? [];
        
        // Count file types
        $fileTypes = [];
        foreach ($files as $file) {
            $type = $file['type'] ?? 'unknown';
            if (!isset($fileTypes[$type])) {
                $fileTypes[$type] = 0;
            }
            $fileTypes[$type]++;
        }
        
        // Should have PHP files primarily
        $this->assertArrayHasKey('php', $fileTypes, 'Members should have PHP files');
        $this->assertGreaterThan(50, $fileTypes['php'] ?? 0, 'Members should have many PHP files');
    }
}