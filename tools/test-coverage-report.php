<?php
/**
 * Test Coverage Report Generator
 * 
 * Generates comprehensive test coverage reports for the WordPress Testing Framework
 */

class TestCoverageReporter
{
    private $coverage_data = [];
    private $test_results = [];
    private $framework_root;
    
    public function __construct()
    {
        $this->framework_root = dirname(__DIR__);
    }

    /**
     * Generate comprehensive coverage report
     */
    public function generateReport()
    {
        echo "🔍 Generating Test Coverage Report...\n\n";
        
        $this->collectPHPUnitCoverage();
        $this->collectPlaywrightResults();
        $this->collectSecurityTestResults();
        $this->collectPerformanceResults();
        $this->analyzeComponentCoverage();
        
        $this->generateHTMLReport();
        $this->generateSummaryReport();
        
        echo "✅ Coverage report generated successfully!\n";
    }

    /**
     * Collect PHPUnit coverage data
     */
    private function collectPHPUnitCoverage()
    {
        echo "📊 Collecting PHPUnit coverage data...\n";
        
        $coverage_dirs = [
            'unit' => $this->framework_root . '/coverage/unit',
            'integration' => $this->framework_root . '/coverage/integration',
            'security' => $this->framework_root . '/coverage/security',
        ];
        
        foreach ($coverage_dirs as $type => $dir) {
            if (file_exists($dir . '/index.html')) {
                $this->coverage_data[$type] = $this->parsePHPUnitCoverage($dir);
            } else {
                echo "⚠️  No {$type} coverage data found. Run tests with --coverage-html flag.\n";
            }
        }
    }

    /**
     * Parse PHPUnit coverage data
     */
    private function parsePHPUnitCoverage($coverage_dir)
    {
        $coverage_data = [
            'lines_covered' => 0,
            'lines_total' => 0,
            'percentage' => 0,
            'files' => [],
        ];
        
        // Parse coverage XML if available
        $clover_file = dirname($coverage_dir) . '/clover.xml';
        if (file_exists($clover_file)) {
            $xml = simplexml_load_file($clover_file);
            if ($xml) {
                $metrics = $xml->project->metrics ?? null;
                if ($metrics) {
                    $coverage_data['lines_total'] = (int) $metrics['statements'];
                    $coverage_data['lines_covered'] = (int) $metrics['coveredstatements'];
                    $coverage_data['percentage'] = $coverage_data['lines_total'] > 0 
                        ? round(($coverage_data['lines_covered'] / $coverage_data['lines_total']) * 100, 2)
                        : 0;
                }
            }
        }
        
        return $coverage_data;
    }

    /**
     * Collect Playwright test results
     */
    private function collectPlaywrightResults()
    {
        echo "🎭 Collecting Playwright test results...\n";
        
        $playwright_report = $this->framework_root . '/tools/e2e/playwright-report/results.json';
        if (file_exists($playwright_report)) {
            $results = json_decode(file_get_contents($playwright_report), true);
            $this->test_results['e2e'] = $this->parsePlaywrightResults($results);
        } else {
            // Look for test results in alternative location
            $test_results_dir = $this->framework_root . '/tools/e2e/test-results';
            if (is_dir($test_results_dir)) {
                $this->test_results['e2e'] = $this->parsePlaywrightResultsDir($test_results_dir);
            }
        }
    }

    /**
     * Parse Playwright results
     */
    private function parsePlaywrightResults($results)
    {
        $summary = [
            'total' => 0,
            'passed' => 0,
            'failed' => 0,
            'skipped' => 0,
            'duration' => 0,
            'categories' => [
                'sanity' => ['total' => 0, 'passed' => 0],
                'interactions' => ['total' => 0, 'passed' => 0],
                'pages' => ['total' => 0, 'passed' => 0],
                'security' => ['total' => 0, 'passed' => 0],
                'performance' => ['total' => 0, 'passed' => 0],
                'accessibility' => ['total' => 0, 'passed' => 0],
            ]
        ];
        
        if (isset($results['suites'])) {
            foreach ($results['suites'] as $suite) {
                foreach ($suite['specs'] ?? [] as $spec) {
                    foreach ($spec['tests'] ?? [] as $test) {
                        $summary['total']++;
                        
                        if ($test['status'] === 'passed') {
                            $summary['passed']++;
                        } elseif ($test['status'] === 'failed') {
                            $summary['failed']++;
                        } else {
                            $summary['skipped']++;
                        }
                        
                        // Categorize tests
                        $file_name = basename($spec['fileName'] ?? '');
                        $category = $this->categorizeTest($file_name);
                        if (isset($summary['categories'][$category])) {
                            $summary['categories'][$category]['total']++;
                            if ($test['status'] === 'passed') {
                                $summary['categories'][$category]['passed']++;
                            }
                        }
                    }
                }
            }
        }
        
        return $summary;
    }

    /**
     * Parse Playwright results from directory
     */
    private function parsePlaywrightResultsDir($dir)
    {
        $summary = [
            'total' => 0,
            'passed' => 0,
            'failed' => 0,
            'skipped' => 0,
            'categories' => [
                'sanity' => ['total' => 0, 'passed' => 0],
                'interactions' => ['total' => 0, 'passed' => 0],
                'pages' => ['total' => 0, 'passed' => 0],
                'security' => ['total' => 0, 'passed' => 0],
                'performance' => ['total' => 0, 'passed' => 0],
                'accessibility' => ['total' => 0, 'passed' => 0],
            ]
        ];
        
        // Scan test result files
        $result_files = glob($dir . '/**/test-results.xml');
        foreach ($result_files as $file) {
            // Parse JUnit XML if available
            $xml = simplexml_load_file($file);
            if ($xml) {
                $testsuites = $xml->testsuite ?? [$xml];
                foreach ($testsuites as $testsuite) {
                    $summary['total'] += (int) ($testsuite['tests'] ?? 0);
                    $summary['failed'] += (int) ($testsuite['failures'] ?? 0);
                    $summary['skipped'] += (int) ($testsuite['skipped'] ?? 0);
                }
            }
        }
        
        $summary['passed'] = $summary['total'] - $summary['failed'] - $summary['skipped'];
        
        return $summary;
    }

    /**
     * Categorize test by filename
     */
    private function categorizeTest($filename)
    {
        if (strpos($filename, 'sanity') !== false) return 'sanity';
        if (strpos($filename, 'interaction') !== false) return 'interactions';
        if (strpos($filename, 'pages') !== false) return 'pages';
        if (strpos($filename, 'security') !== false) return 'security';
        if (strpos($filename, 'performance') !== false) return 'performance';
        if (strpos($filename, 'accessibility') !== false) return 'accessibility';
        
        return 'other';
    }

    /**
     * Collect security test results
     */
    private function collectSecurityTestResults()
    {
        echo "🔒 Collecting security test results...\n";
        
        $security_dir = WP_CONTENT_DIR . '/uploads';
        if (defined('WP_CONTENT_DIR') && is_dir($security_dir)) {
            $security_files = glob($security_dir . '/security-scan-*.json');
            
            if (!empty($security_files)) {
                $latest_scan = max($security_files);
                $scan_data = json_decode(file_get_contents($latest_scan), true);
                
                $this->test_results['security'] = [
                    'scan_date' => $scan_data['scan_date'] ?? 'Unknown',
                    'vulnerabilities' => count($scan_data['results']['vulnerabilities'] ?? []),
                    'recommendations' => count($scan_data['results']['recommendations'] ?? []),
                    'severity_breakdown' => $this->analyzeSeverity($scan_data['results']['vulnerabilities'] ?? []),
                ];
            }
        }
    }

    /**
     * Analyze vulnerability severity
     */
    private function analyzeSeverity($vulnerabilities)
    {
        $breakdown = ['low' => 0, 'medium' => 0, 'high' => 0, 'critical' => 0];
        
        foreach ($vulnerabilities as $vuln) {
            $severity = $vuln['severity'] ?? 'unknown';
            if (isset($breakdown[$severity])) {
                $breakdown[$severity]++;
            }
        }
        
        return $breakdown;
    }

    /**
     * Collect performance results
     */
    private function collectPerformanceResults()
    {
        echo "⚡ Collecting performance test results...\n";
        
        $perf_dir = WP_CONTENT_DIR . '/uploads/performance-logs';
        if (defined('WP_CONTENT_DIR') && is_dir($perf_dir)) {
            $perf_files = glob($perf_dir . '/performance-*.json');
            
            if (!empty($perf_files)) {
                $latest_perf = max($perf_files);
                $perf_data = json_decode(file_get_contents($latest_perf), true);
                
                $this->test_results['performance'] = [
                    'execution_time' => $perf_data['execution_time'] ?? 0,
                    'memory_usage' => $perf_data['memory_usage'] ?? 0,
                    'query_count' => $perf_data['query_count'] ?? 0,
                    'component_performance' => $perf_data['component_performance'] ?? [],
                    'issues_count' => count($perf_data['issues'] ?? []),
                ];
            }
        }
    }

    /**
     * Analyze component coverage
     */
    private function analyzeComponentCoverage()
    {
        echo "🧩 Analyzing BuddyPress component coverage...\n";
        
        $components = [
            'core' => 'Core functionality',
            'members' => 'Member management',
            'xprofile' => 'Extended profiles',
            'activity' => 'Activity streams',
            'groups' => 'Group functionality',
            'friends' => 'Friend connections',
            'messages' => 'Private messaging',
            'notifications' => 'Notifications',
            'settings' => 'Settings management',
            'blogs' => 'Site tracking',
        ];
        
        $component_coverage = [];
        
        foreach ($components as $component => $description) {
            $test_files = glob($this->framework_root . "/tests/phpunit/Components/{$component}/*.php");
            $test_files = array_merge($test_files, 
                glob($this->framework_root . "/tests/phpunit/Components/{$component}/**/*.php"));
                
            $component_coverage[$component] = [
                'description' => $description,
                'test_files' => count($test_files),
                'has_unit_tests' => file_exists($this->framework_root . "/tests/phpunit/Components/{$component}/Unit"),
                'has_integration_tests' => file_exists($this->framework_root . "/tests/phpunit/Components/{$component}/Integration"),
                'has_functional_tests' => file_exists($this->framework_root . "/tests/phpunit/Components/{$component}/Functional"),
            ];
        }
        
        $this->coverage_data['components'] = $component_coverage;
    }

    /**
     * Generate HTML coverage report
     */
    private function generateHTMLReport()
    {
        echo "📄 Generating HTML coverage report...\n";
        
        $html_template = $this->getHTMLTemplate();
        $report_data = $this->compileReportData();
        
        $html_content = str_replace('{{REPORT_DATA}}', json_encode($report_data), $html_template);
        
        $report_dir = $this->framework_root . '/coverage';
        if (!is_dir($report_dir)) {
            mkdir($report_dir, 0755, true);
        }
        
        file_put_contents($report_dir . '/coverage-report.html', $html_content);
        
        echo "📄 HTML report saved to: coverage/coverage-report.html\n";
    }

    /**
     * Compile all report data
     */
    private function compileReportData()
    {
        return [
            'timestamp' => date('Y-m-d H:i:s'),
            'framework_version' => '3.0.0',
            'php_coverage' => $this->coverage_data,
            'test_results' => $this->test_results,
            'summary' => $this->calculateSummary(),
        ];
    }

    /**
     * Calculate overall summary
     */
    private function calculateSummary()
    {
        $summary = [
            'overall_coverage' => 0,
            'test_categories' => [],
            'recommendations' => [],
        ];
        
        // Calculate overall coverage percentage
        $total_lines = 0;
        $covered_lines = 0;
        
        foreach ($this->coverage_data as $type => $data) {
            if (isset($data['lines_total']) && isset($data['lines_covered'])) {
                $total_lines += $data['lines_total'];
                $covered_lines += $data['lines_covered'];
            }
        }
        
        if ($total_lines > 0) {
            $summary['overall_coverage'] = round(($covered_lines / $total_lines) * 100, 2);
        }
        
        // Analyze test categories
        if (isset($this->test_results['e2e']['categories'])) {
            foreach ($this->test_results['e2e']['categories'] as $category => $data) {
                if ($data['total'] > 0) {
                    $success_rate = round(($data['passed'] / $data['total']) * 100, 2);
                    $summary['test_categories'][$category] = $success_rate;
                }
            }
        }
        
        // Generate recommendations
        if ($summary['overall_coverage'] < 80) {
            $summary['recommendations'][] = 'Increase code coverage to at least 80%';
        }
        
        if (isset($this->test_results['security']['vulnerabilities']) && 
            $this->test_results['security']['vulnerabilities'] > 0) {
            $summary['recommendations'][] = 'Address security vulnerabilities';
        }
        
        return $summary;
    }

    /**
     * Generate summary report
     */
    private function generateSummaryReport()
    {
        echo "\n" . str_repeat("=", 60) . "\n";
        echo "📊 TEST COVERAGE SUMMARY REPORT\n";
        echo str_repeat("=", 60) . "\n";
        
        $summary = $this->calculateSummary();
        
        // Overall metrics
        echo "\n🎯 OVERALL METRICS:\n";
        echo "Overall Coverage: {$summary['overall_coverage']}%\n";
        
        // PHP Unit coverage
        if (!empty($this->coverage_data)) {
            echo "\n🔧 PHP UNIT COVERAGE:\n";
            foreach ($this->coverage_data as $type => $data) {
                if (isset($data['percentage'])) {
                    echo "- " . ucfirst($type) . ": {$data['percentage']}%\n";
                }
            }
        }
        
        // E2E test results
        if (isset($this->test_results['e2e'])) {
            $e2e = $this->test_results['e2e'];
            echo "\n🎭 END-TO-END TESTS:\n";
            echo "- Total Tests: {$e2e['total']}\n";
            echo "- Passed: {$e2e['passed']}\n";
            echo "- Failed: {$e2e['failed']}\n";
            echo "- Skipped: {$e2e['skipped']}\n";
            
            if (!empty($e2e['categories'])) {
                echo "\nCategory Breakdown:\n";
                foreach ($e2e['categories'] as $category => $data) {
                    if ($data['total'] > 0) {
                        $rate = round(($data['passed'] / $data['total']) * 100);
                        echo "- " . ucfirst($category) . ": {$data['passed']}/{$data['total']} ({$rate}%)\n";
                    }
                }
            }
        }
        
        // Security results
        if (isset($this->test_results['security'])) {
            $security = $this->test_results['security'];
            echo "\n🔒 SECURITY ASSESSMENT:\n";
            echo "- Vulnerabilities Found: {$security['vulnerabilities']}\n";
            echo "- Recommendations: {$security['recommendations']}\n";
            
            if (!empty($security['severity_breakdown'])) {
                echo "Severity Breakdown:\n";
                foreach ($security['severity_breakdown'] as $severity => $count) {
                    if ($count > 0) {
                        echo "- " . ucfirst($severity) . ": {$count}\n";
                    }
                }
            }
        }
        
        // Performance results
        if (isset($this->test_results['performance'])) {
            $perf = $this->test_results['performance'];
            echo "\n⚡ PERFORMANCE METRICS:\n";
            echo "- Execution Time: " . number_format($perf['execution_time'], 3) . "s\n";
            echo "- Memory Usage: " . $this->formatBytes($perf['memory_usage']) . "\n";
            echo "- Database Queries: {$perf['query_count']}\n";
            echo "- Performance Issues: {$perf['issues_count']}\n";
        }
        
        // Component coverage
        if (isset($this->coverage_data['components'])) {
            echo "\n🧩 COMPONENT COVERAGE:\n";
            foreach ($this->coverage_data['components'] as $component => $data) {
                $coverage_indicators = [];
                if ($data['has_unit_tests']) $coverage_indicators[] = 'Unit';
                if ($data['has_integration_tests']) $coverage_indicators[] = 'Integration';
                if ($data['has_functional_tests']) $coverage_indicators[] = 'Functional';
                
                $coverage_status = empty($coverage_indicators) ? 'No tests' : implode(', ', $coverage_indicators);
                echo "- " . ucfirst($component) . ": {$data['test_files']} files ({$coverage_status})\n";
            }
        }
        
        // Recommendations
        if (!empty($summary['recommendations'])) {
            echo "\n💡 RECOMMENDATIONS:\n";
            foreach ($summary['recommendations'] as $i => $recommendation) {
                echo ($i + 1) . ". {$recommendation}\n";
            }
        }
        
        echo "\n" . str_repeat("=", 60) . "\n";
        echo "Report generated at: " . date('Y-m-d H:i:s') . "\n";
        echo str_repeat("=", 60) . "\n\n";
    }

    /**
     * Format bytes to human readable
     */
    private function formatBytes($bytes)
    {
        $units = ['B', 'KB', 'MB', 'GB'];
        $bytes = max($bytes, 0);
        $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
        $pow = min($pow, count($units) - 1);
        
        $bytes /= pow(1024, $pow);
        
        return round($bytes, 2) . ' ' . $units[$pow];
    }

    /**
     * Get HTML template for report
     */
    private function getHTMLTemplate()
    {
        return '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WordPress Testing Framework - Coverage Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1, h2, h3 { color: #333; }
        .metric { display: inline-block; margin: 10px 20px 10px 0; padding: 15px 20px; background: #f8f9fa; border-left: 4px solid #007cba; border-radius: 4px; }
        .metric-value { font-size: 24px; font-weight: bold; color: #007cba; }
        .metric-label { font-size: 14px; color: #666; margin-top: 5px; }
        .coverage-bar { width: 100%; height: 20px; background: #eee; border-radius: 10px; overflow: hidden; margin: 10px 0; }
        .coverage-fill { height: 100%; background: linear-gradient(90deg, #ff4444 0%, #ffaa00 50%, #44ff44 100%); transition: width 0.3s; }
        .test-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 20px 0; }
        .test-card { padding: 20px; background: #f8f9fa; border-radius: 8px; border: 1px solid #ddd; }
        .severity-high { color: #dc3545; }
        .severity-medium { color: #fd7e14; }
        .severity-low { color: #28a745; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #f8f9fa; font-weight: bold; }
        .timestamp { color: #666; font-style: italic; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🧪 WordPress Testing Framework - Coverage Report</h1>
        <p class="timestamp">Generated: <span id="timestamp"></span></p>
        
        <div id="report-content">
            <div class="metric">
                <div class="metric-value" id="overall-coverage">--</div>
                <div class="metric-label">Overall Coverage</div>
            </div>
            
            <div id="detailed-metrics"></div>
            <div id="test-results"></div>
            <div id="component-coverage"></div>
        </div>
    </div>
    
    <script>
        const reportData = {{REPORT_DATA}};
        
        // Update timestamp
        document.getElementById("timestamp").textContent = reportData.timestamp;
        
        // Update overall coverage
        document.getElementById("overall-coverage").textContent = reportData.summary.overall_coverage + "%";
        
        // Render detailed metrics and results
        console.log("Coverage Report Data:", reportData);
    </script>
</body>
</html>';
    }
}

// Run coverage report if called directly
if (php_sapi_name() === 'cli') {
    $reporter = new TestCoverageReporter();
    $reporter->generateReport();
} elseif (defined('WP_CLI') && WP_CLI) {
    WP_CLI::add_command('bp coverage-report', function() {
        $reporter = new TestCoverageReporter();
        $reporter->generateReport();
    });
}