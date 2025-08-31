#!/usr/bin/env php
<?php
/**
 * Unit Test Runner with Coverage Support
 * Runs tests and captures code coverage metrics
 */

$plugin_name = $argv[1] ?? 'plugin';
$scan_dir = dirname(dirname(dirname(__FILE__))) . "/wp-content/uploads/wbcom-scan/$plugin_name/" . date('Y-m');
$test_dir = $scan_dir . '/generated-tests';
$results_file = $scan_dir . '/test-results.json';
$coverage_dir = $scan_dir . '/raw-outputs/coverage';

// Create coverage directory if needed
if (!file_exists($coverage_dir)) {
    mkdir($coverage_dir, 0755, true);
}

// Initialize results
$results = [
    'plugin' => $plugin_name,
    'timestamp' => date('Y-m-d H:i:s'),
    'tests_found' => 0,
    'tests_run' => 0,
    'tests_passed' => 0,
    'tests_failed' => 0,
    'tests_skipped' => 0,
    'coverage_percent' => 0,
    'execution_time' => 0,
    'status' => 'pending'
];

// Check for test files - prefer AI-generated tests, then executable tests, then regular tests
$smart_test_file = $test_dir . '/' . ucfirst(str_replace('-', '', $plugin_name)) . 'SmartExecutableTest.php';
$executable_test_file = $test_dir . '/' . ucfirst(str_replace('-', '', $plugin_name)) . 'ExecutableTest.php';
$regular_test_file = $test_dir . '/' . ucfirst(str_replace('-', '', $plugin_name)) . 'Test.php';

$test_to_run = null;
if (file_exists($smart_test_file)) {
    $test_to_run = $smart_test_file;
    echo "🤖 Found AI-enhanced smart test file for comprehensive coverage\n";
} elseif (file_exists($executable_test_file)) {
    $test_to_run = $executable_test_file;
    echo "✅ Found executable test file for better coverage\n";
} elseif (file_exists($regular_test_file)) {
    $test_to_run = $regular_test_file;
    echo "📝 Found regular test file\n";
} else {
    echo "⚠️  No test files found for $plugin_name\n";
    $results['status'] = 'no_tests';
    file_put_contents($results_file, json_encode($results, JSON_PRETTY_PRINT));
    exit(0);
}

// Find PHPUnit
$phpunit_path = dirname(dirname(__FILE__)) . '/vendor/bin/phpunit';
if (!file_exists($phpunit_path)) {
    // Try other common locations
    $phpunit_locations = [
        'vendor/bin/phpunit',
        '/usr/local/bin/phpunit',
        dirname(dirname(dirname(__FILE__))) . '/vendor/bin/phpunit'
    ];
    
    foreach ($phpunit_locations as $loc) {
        if (file_exists($loc)) {
            $phpunit_path = $loc;
            break;
        }
    }
}

// Verify PHPUnit works
if (!file_exists($phpunit_path)) {
    echo "❌ PHPUnit not found, cannot run tests\n";
    exit(1);
}

$phpunit_version = shell_exec("'$phpunit_path' --version 2>&1");
if (!$phpunit_version || (stripos($phpunit_version, 'phpunit') === false && stripos($phpunit_version, 'PHPUnit') === false)) {
    echo "❌ PHPUnit not working properly\n";
    echo "   Path: $phpunit_path\n";
    echo "   Output: $phpunit_version\n";
    exit(1);
}

echo "🚀 Running tests with PHPUnit...\n";
echo "   PHPUnit: $phpunit_path\n";
echo "   Test file: " . basename($test_to_run) . "\n";

$start_time = microtime(true);

// Create bootstrap file
$bootstrap_file = dirname(__FILE__) . '/wp-test-bootstrap.php';
if (!file_exists($bootstrap_file)) {
    file_put_contents($bootstrap_file, '<?php
// WordPress test bootstrap
if (!class_exists("WP_UnitTestCase")) {
    class WP_UnitTestCase extends PHPUnit\Framework\TestCase {
        public function setUp(): void { parent::setUp(); }
        public function tearDown(): void { parent::tearDown(); }
    }
}

// Load WordPress if available
$wp_load = dirname(dirname(dirname(dirname(dirname(__FILE__))))) . "/wp-load.php";
if (file_exists($wp_load)) {
    require_once $wp_load;
}

// Mock functions if WordPress not loaded
if (!function_exists("do_shortcode")) {
    function do_shortcode($content) { return "[shortcode processed]"; }
}
if (!function_exists("get_option")) {
    function get_option($option, $default = false) { return $default; }
}
if (!function_exists("plugin_basename")) {
    function plugin_basename($file) { return basename($file); }
}
if (!function_exists("shortcode_exists")) {
    function shortcode_exists($tag) { global $shortcode_tags; return isset($shortcode_tags[$tag]); }
}
');
}

// Prepare coverage options
$plugin_path = dirname(dirname(dirname(__FILE__))) . "/wp-content/plugins/$plugin_name";
$coverage_file = $coverage_dir . '/coverage-' . date('Ymd-His') . '.txt';

// Check if Xdebug is available for coverage
$has_coverage = extension_loaded('xdebug') || extension_loaded('pcov');

// Build command - properly escape paths with spaces
if ($has_coverage && file_exists($plugin_path)) {
    echo "📊 Coverage enabled (Xdebug/PCOV detected)\n\n";
    // Set XDEBUG_MODE environment variable for coverage
    putenv('XDEBUG_MODE=coverage');
    $cmd = "XDEBUG_MODE=coverage '$phpunit_path' --bootstrap '$bootstrap_file' '$test_to_run' --coverage-text --coverage-filter='$plugin_path' --colors=always 2>&1";
} else {
    if (!$has_coverage) {
        echo "ℹ️  Coverage disabled (install Xdebug or PCOV for coverage)\n\n";
    }
    $cmd = "'$phpunit_path' --bootstrap '$bootstrap_file' '$test_to_run' --colors=always 2>&1";
}

// Run tests
$output = shell_exec($cmd);
echo $output;

// Parse output for results - strip color codes first
$output_clean = preg_replace('/\x1b\[[0-9;]*m/', '', $output);
if (preg_match('/Tests: (\d+), Assertions: (\d+)(?:, Errors: (\d+))?(?:, Failures: (\d+))?(?:, Warnings: (\d+))?(?:, Skipped: (\d+))?/', $output_clean, $matches)) {
    $results['tests_run'] = intval($matches[1]);
    $results['tests_failed'] = intval($matches[3] ?? 0) + intval($matches[4] ?? 0);
    $results['tests_skipped'] = intval($matches[6] ?? 0);
    $results['tests_passed'] = $results['tests_run'] - $results['tests_failed'] - $results['tests_skipped'];
}

// Extract coverage if available
if (strpos($output_clean, 'Code Coverage Report') !== false || strpos($output_clean, 'Lines:') !== false) {
    if (preg_match('/Lines:\s+(\d+\.\d+)%/', $output_clean, $matches)) {
        $results['coverage_percent'] = floatval($matches[1]);
        echo "\n📊 Code Coverage: {$results['coverage_percent']}%\n";
        
        // Save coverage for main script
        file_put_contents($coverage_file, "Total Coverage: {$results['coverage_percent']}%\n\n" . $output_clean);
    }
}

$results['execution_time'] = round(microtime(true) - $start_time, 2);
$results['status'] = ($results['tests_failed'] === 0) ? 'success' : 'failed';

// Save results
file_put_contents($results_file, json_encode($results, JSON_PRETTY_PRINT));

// Display summary
echo "\n" . str_repeat('=', 60) . "\n";
echo "📊 Test Summary for $plugin_name\n";
echo str_repeat('=', 60) . "\n";
echo "Tests Run: {$results['tests_run']}\n";
echo "Passed: {$results['tests_passed']} ✅\n";
echo "Failed: {$results['tests_failed']} ❌\n";
echo "Skipped: {$results['tests_skipped']} ⏭️\n";
if ($results['coverage_percent'] > 0) {
    echo "Code Coverage: {$results['coverage_percent']}% 📈\n";
}
echo "Execution Time: {$results['execution_time']}s\n";
echo "Status: " . strtoupper($results['status']) . "\n";
echo str_repeat('=', 60) . "\n";

exit($results['tests_failed'] > 0 ? 1 : 0);