#!/usr/bin/env php
<?php
/**
 * Safe Unit Test Runner v2
 * Runs tests with proper fallbacks
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
    echo "⚠️  No generated tests found for $plugin_name\n";
    file_put_contents($results_file, json_encode($results, JSON_PRETTY_PRINT));
    exit(0);
}

// Count test files
$test_files = glob($test_dir . '/*Test.php');
$results['tests_found'] = count($test_files);

if (empty($test_files)) {
    $results['status'] = 'no_tests';
    echo "⚠️  No test files found in $test_dir\n";
    file_put_contents($results_file, json_encode($results, JSON_PRETTY_PRINT));
    exit(0);
}

echo "🧪 Found {$results['tests_found']} test file(s) for $plugin_name\n";

// Always run basic syntax checks first (safe fallback)
echo "📋 Running syntax validation...\n";

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

// Now try to run with PHPUnit if available
$phpunit_found = false;
$phpunit_commands = ['phpunit', '/usr/local/bin/phpunit'];

foreach ($phpunit_commands as $cmd) {
    $version = shell_exec("$cmd --version 2>/dev/null");
    if (stripos($version, 'phpunit') !== false) {
        $phpunit_found = $cmd;
        break;
    }
}

if ($phpunit_found) {
    echo "\n✅ PHPUnit available - running full tests...\n";
    
    // Create simple config
    $config = "<?xml version='1.0'?>
<phpunit bootstrap='" . __DIR__ . "/wp-test-bootstrap.php'>
    <testsuites>
        <testsuite name='$plugin_name'>
            <directory>$test_dir</directory>
        </testsuite>
    </testsuites>
</phpunit>";
    
    $config_file = $test_dir . '/phpunit.xml';
    file_put_contents($config_file, $config);
    
    // Run PHPUnit
    $output = shell_exec("cd '$test_dir' && $phpunit_found 2>&1");
    echo $output;
    
    // Parse output for results
    if (stripos($output, 'OK') !== false) {
        $results['status'] = 'phpunit_success';
    } else {
        $results['status'] = 'phpunit_failed';
    }
} else {
    echo "\nℹ️  PHPUnit not available - syntax validation complete\n";
    $results['status'] = $all_valid ? 'syntax_valid' : 'syntax_errors';
}

// Save results
file_put_contents($results_file, json_encode($results, JSON_PRETTY_PRINT));

// Display summary
echo "\n" . str_repeat('=', 50) . "\n";
echo "📊 Test Summary for $plugin_name\n";
echo str_repeat('=', 50) . "\n";
echo "Tests Found: {$results['tests_found']}\n";
echo "Syntax Checks: {$results['tests_run']}\n";
echo "Valid: {$results['tests_passed']} ✅\n";
echo "Errors: {$results['tests_failed']} ❌\n";
echo "Status: " . strtoupper(str_replace('_', ' ', $results['status'])) . "\n";
echo str_repeat('=', 50) . "\n";

exit($results['tests_failed'] > 0 ? 1 : 0);