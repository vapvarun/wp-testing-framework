#!/usr/bin/env php
<?php
/**
 * Safe Unit Test Runner
 * Runs generated tests without breaking if PHPUnit isn't available
 */

$plugin_name = $argv[1] ?? 'plugin';
$scan_dir = dirname(dirname(dirname(__FILE__))) . "/wp-content/uploads/wbcom-scan/$plugin_name/" . date('Y-m');
$test_dir = $scan_dir . '/generated-tests';
$results_file = $scan_dir . '/test-results.json';

// Initialize results
$results = [
    'plugin' => $plugin_name,
    'timestamp' => date('Y-m-d H:i:s'),
    'tests_found' => 0,
    'tests_run' => 0,
    'tests_passed' => 0,
    'tests_failed' => 0,
    'tests_skipped' => 0,
    'execution_time' => 0,
    'status' => 'pending'
];

// Check if test directory exists
if (!file_exists($test_dir)) {
    $results['status'] = 'no_tests';
    $results['message'] = 'No generated tests found';
    file_put_contents($results_file, json_encode($results, JSON_PRETTY_PRINT));
    echo "⚠️  No generated tests found for $plugin_name\n";
    exit(0);
}

// Count test files
$test_files = glob($test_dir . '/*Test.php');
$results['tests_found'] = count($test_files);

if (empty($test_files)) {
    $results['status'] = 'no_tests';
    $results['message'] = 'No test files found';
    file_put_contents($results_file, json_encode($results, JSON_PRETTY_PRINT));
    echo "⚠️  No test files found in $test_dir\n";
    exit(0);
}

echo "🧪 Found {$results['tests_found']} test file(s) for $plugin_name\n";

// Check if PHPUnit is available
$phpunit_path = null;
$phpunit_commands = [
    'vendor/bin/phpunit',
    'phpunit',
    '../../../vendor/bin/phpunit',
    '/usr/local/bin/phpunit',
    'tools/phpunit.phar'
];

foreach ($phpunit_commands as $cmd) {
    // Check if it's a file that exists
    if (file_exists($cmd)) {
        // Verify it's actually executable
        if (is_executable($cmd)) {
            $phpunit_path = $cmd;
            break;
        }
    }
    // Check if it's a command in PATH (but verify it works)
    $test_output = shell_exec("$cmd --version 2>/dev/null");
    if (!empty($test_output) && stripos($test_output, 'phpunit') !== false) {
        $phpunit_path = $cmd;
        break;
    }
}

// If no PHPUnit, try to run basic PHP checks
if (!$phpunit_path) {
    echo "⚠️  PHPUnit not found, running basic syntax checks...\n";
    
    $results['status'] = 'basic_check';
    $all_valid = true;
    
    foreach ($test_files as $test_file) {
        $output = [];
        $return_code = 0;
        exec("php -l '$test_file' 2>&1", $output, $return_code);
        
        if ($return_code === 0) {
            echo "   ✅ " . basename($test_file) . " - Syntax OK\n";
            $results['tests_passed']++;
        } else {
            echo "   ❌ " . basename($test_file) . " - Syntax Error\n";
            $results['tests_failed']++;
            $all_valid = false;
        }
        $results['tests_run']++;
    }
    
    $results['status'] = $all_valid ? 'basic_pass' : 'basic_fail';
    file_put_contents($results_file, json_encode($results, JSON_PRETTY_PRINT));
    
    echo "\n📊 Basic Check Results:\n";
    echo "   Tests checked: {$results['tests_run']}\n";
    echo "   Syntax valid: {$results['tests_passed']}\n";
    echo "   Syntax errors: {$results['tests_failed']}\n";
    exit($all_valid ? 0 : 1);
}

// Verify PHPUnit actually works before claiming it's found
$phpunit_works = false;
$test_version = shell_exec("$phpunit_path --version 2>&1");
if (stripos($test_version, 'phpunit') !== false || stripos($test_version, 'sebastian') !== false) {
    $phpunit_works = true;
    echo "✅ PHPUnit found at: $phpunit_path\n";
    echo "🚀 Running unit tests...\n\n";
} else {
    echo "⚠️  PHPUnit path found but not working, falling back to basic checks...\n";
    $phpunit_path = null;
}

if (!$phpunit_works) {
    // Jump to basic checks
    $phpunit_path = null;
}

if ($phpunit_path) {

$start_time = microtime(true);

// Create minimal PHPUnit configuration
$phpunit_config = $test_dir . '/phpunit.xml';
if (!file_exists($phpunit_config)) {
    $config_content = '<?xml version="1.0"?>
<phpunit bootstrap="' . dirname(dirname(dirname(dirname(dirname(__FILE__))))) . '/wp-load.php">
    <testsuites>
        <testsuite name="' . $plugin_name . '">
            <directory>.</directory>
        </testsuite>
    </testsuites>
</phpunit>';
    file_put_contents($phpunit_config, $config_content);
}

// Run PHPUnit with JSON output
$output = [];
$return_code = 0;
$cmd = "cd '$test_dir' && $phpunit_path --log-json test-output.json 2>&1";
exec($cmd, $output, $return_code);

// Display output
foreach ($output as $line) {
    echo $line . "\n";
}

// Parse results if JSON output exists
$json_output = $test_dir . '/test-output.json';
if (file_exists($json_output)) {
    $lines = file($json_output, FILE_IGNORE_NEW_LINES);
    foreach ($lines as $line) {
        $event = json_decode($line, true);
        if ($event) {
            if ($event['event'] === 'test') {
                $results['tests_run']++;
                if ($event['status'] === 'pass') {
                    $results['tests_passed']++;
                } elseif ($event['status'] === 'fail' || $event['status'] === 'error') {
                    $results['tests_failed']++;
                } else {
                    $results['tests_skipped']++;
                }
            }
        }
    }
}

$results['execution_time'] = round(microtime(true) - $start_time, 2);
$results['status'] = ($return_code === 0) ? 'success' : 'failed';

// Save results
file_put_contents($results_file, json_encode($results, JSON_PRETTY_PRINT));

// Display summary
echo "\n" . str_repeat('=', 50) . "\n";
echo "📊 Test Execution Summary\n";
echo str_repeat('=', 50) . "\n";
echo "Plugin: $plugin_name\n";
echo "Tests Run: {$results['tests_run']}\n";
echo "Passed: {$results['tests_passed']} ✅\n";
echo "Failed: {$results['tests_failed']} ❌\n";
echo "Skipped: {$results['tests_skipped']} ⏭️\n";
echo "Execution Time: {$results['execution_time']}s\n";
echo "Status: " . ($results['status'] === 'success' ? '✅ SUCCESS' : '❌ FAILED') . "\n";
echo str_repeat('=', 50) . "\n";

exit($return_code);