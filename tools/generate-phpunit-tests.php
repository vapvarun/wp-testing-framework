<?php
/**
 * Simple PHPUnit Test Generator
 * Generates basic test cases based on detected functions
 */

// Get plugin name from command line
$plugin_name = $argv[1] ?? 'plugin';
$scan_dir = dirname(dirname(dirname(__FILE__))) . "/wp-content/uploads/wbcom-scan/$plugin_name/" . date('Y-m');

// Load AST analysis
$ast_file = $scan_dir . '/wordpress-ast-analysis.json';
if (!file_exists($ast_file)) {
    echo "AST analysis not found\n";
    exit(1);
}

$ast_data = json_decode(file_get_contents($ast_file), true);

// Generate test class
$test_content = "<?php
/**
 * Generated PHPUnit Tests for $plugin_name
 * Generated: " . date('Y-m-d H:i:s') . "
 */

class " . ucfirst(str_replace('-', '', $plugin_name)) . "Test extends WP_UnitTestCase {
    
    public function setUp(): void {
        parent::setUp();
        // Setup code here
    }
    
    public function tearDown(): void {
        parent::tearDown();
        // Cleanup code here
    }
";

// Generate tests for top 10 functions
$functions = array_slice($ast_data['details']['functions'] ?? [], 0, 10);
foreach ($functions as $func) {
    $func_name = $func['name'] ?? 'unknown';
    $test_method = str_replace('_', '', ucwords($func_name, '_'));
    
    $test_content .= "
    /**
     * Test for function: $func_name
     */
    public function test$test_method() {
        // Arrange
        \$this->markTestIncomplete('Test for $func_name needs implementation');
        
        // Act
        // \$result = $func_name();
        
        // Assert
        // \$this->assertNotNull(\$result);
    }
";
}

// Add tests for shortcodes
$shortcodes = $ast_data['details']['shortcodes'] ?? [];
foreach ($shortcodes as $shortcode) {
    $shortcode_name = is_array($shortcode) ? ($shortcode['name'] ?? 'unknown') : $shortcode;
    $test_method = 'Shortcode' . str_replace(['-', '_'], '', ucwords($shortcode_name, '-_'));
    
    $test_content .= "
    /**
     * Test shortcode: [$shortcode_name]
     */
    public function test$test_method() {
        // Test shortcode output
        \$output = do_shortcode('[$shortcode_name]');
        \$this->assertNotEmpty(\$output, 'Shortcode [$shortcode_name] should produce output');
    }
";
}

// Add tests for AJAX handlers (top 5 unique)
$ajax_handlers = array_slice($ast_data['details']['ajax_handlers'] ?? [], 0, 20);
$used_methods = [];
$ajax_count = 0;
foreach ($ajax_handlers as $handler) {
    if ($ajax_count >= 5) break;
    
    $handler_name = is_array($handler) ? ($handler['name'] ?? 'unknown') : $handler;
    $test_method = 'Ajax' . str_replace(['wp_ajax_', 'wp_ajax_nopriv_', '_', '-'], '', ucwords($handler_name, '_-'));
    
    // Skip if we already have this method
    if (in_array($test_method, $used_methods)) continue;
    $used_methods[] = $test_method;
    $ajax_count++;
    
    $test_content .= "
    /**
     * Test AJAX handler: $handler_name
     */
    public function test$test_method() {
        // Setup AJAX request
        \$this->markTestIncomplete('AJAX test for $handler_name needs implementation');
        
        // \$_POST['action'] = '$handler_name';
        // \$response = \$this->handleAjax('$handler_name');
        // \$this->assertTrue(\$response);
    }
";
}

$test_content .= "
}
";

// Save test file
$output_dir = $scan_dir . '/generated-tests';
if (!file_exists($output_dir)) {
    mkdir($output_dir, 0755, true);
}

$output_file = $output_dir . '/' . ucfirst(str_replace('-', '', $plugin_name)) . 'Test.php';
file_put_contents($output_file, $test_content);

echo "✅ Generated PHPUnit test file: $output_file\n";
echo "   - " . count($functions) . " function tests\n";
echo "   - " . count($shortcodes) . " shortcode tests\n";
echo "   - " . count($ajax_handlers) . " AJAX handler tests\n";