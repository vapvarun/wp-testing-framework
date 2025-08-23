<?php
/**
 * WP-CLI Command for BuddyPress Component Scanning
 * 
 * Usage: wp bp component-scan [--output=<format>] [--save=<path>]
 */

if (!class_exists('WP_CLI')) {
    return;
}

class BP_Component_Scan_Command {
    
    /**
     * Scan BuddyPress components and generate detailed code analysis
     *
     * ## OPTIONS
     *
     * [--output=<format>]
     * : Output format (json, table, summary)
     * ---
     * default: summary
     * options:
     *   - json
     *   - table
     *   - summary
     * ---
     *
     * [--save=<path>]
     * : Save JSON output to file
     *
     * [--component=<name>]
     * : Scan specific component only
     *
     * ## EXAMPLES
     *
     *     # Scan all components with summary output
     *     wp bp component-scan
     *
     *     # Scan and save as JSON
     *     wp bp component-scan --output=json --save=buddypress-scan.json
     *
     *     # Scan specific component
     *     wp bp component-scan --component=members
     *
     * @when after_wp_load
     */
    public function __invoke($args, $assoc_args) {
        
        WP_CLI::log('🔍 BuddyPress Component Scanner');
        WP_CLI::log('================================');
        
        // Check if BuddyPress is active
        if (!class_exists('BuddyPress')) {
            WP_CLI::error('BuddyPress is not active');
        }
        
        $output_format = $assoc_args['output'] ?? 'summary';
        $save_path = $assoc_args['save'] ?? null;
        $specific_component = $assoc_args['component'] ?? null;
        
        // Get BuddyPress path
        $bp_path = WP_PLUGIN_DIR . '/buddypress';
        if (!is_dir($bp_path)) {
            WP_CLI::error('BuddyPress directory not found');
        }
        
        // Include the scanner class
        $scanner_path = dirname(__DIR__) . '/tools/scanners/buddypress-component-scanner.php';
        if (file_exists($scanner_path)) {
            require_once $scanner_path;
        }
        
        // Run scan
        $scanner = new BuddyPressComponentScanner($bp_path);
        
        WP_CLI::log('Scanning BuddyPress components...');
        
        $results = $scanner->scan_all_components();
        
        if (isset($results['error'])) {
            WP_CLI::error($results['error']);
        }
        
        // Filter for specific component if requested
        if ($specific_component) {
            if (!isset($results[$specific_component])) {
                WP_CLI::error("Component '{$specific_component}' not found");
            }
            $results = [$specific_component => $results[$specific_component]];
        }
        
        // Output based on format
        switch ($output_format) {
            case 'json':
                $this->output_json($results);
                break;
                
            case 'table':
                $this->output_table($results);
                break;
                
            case 'summary':
            default:
                $this->output_summary($results);
                break;
        }
        
        // Save if requested
        if ($save_path) {
            $this->save_results($results, $save_path);
        }
        
        WP_CLI::success('Component scan completed');
    }
    
    /**
     * Output results as JSON
     */
    private function output_json($results) {
        echo json_encode($results, JSON_PRETTY_PRINT);
    }
    
    /**
     * Output results as table
     */
    private function output_table($results) {
        $table_data = [];
        
        foreach ($results as $component_id => $data) {
            if ($component_id === 'summary') continue;
            
            $table_data[] = [
                'Component' => $data['name'],
                'Files' => $data['metrics']['total_files'],
                'Classes' => $data['metrics']['total_classes'],
                'Functions' => $data['metrics']['total_functions'],
                'Hooks' => $data['metrics']['total_hooks'],
                'Complexity' => $data['metrics']['complexity_score']
            ];
        }
        
        WP_CLI\Utils\format_items('table', $table_data, array_keys($table_data[0]));
    }
    
    /**
     * Output summary
     */
    private function output_summary($results) {
        foreach ($results as $component_id => $data) {
            if ($component_id === 'summary') continue;
            
            WP_CLI::log(sprintf(
                '📦 %s: %d files, %d classes, %d functions, %d hooks (Complexity: %d)',
                $data['name'],
                $data['metrics']['total_files'],
                $data['metrics']['total_classes'],
                $data['metrics']['total_functions'],
                $data['metrics']['total_hooks'],
                $data['metrics']['complexity_score']
            ));
        }
        
        if (isset($results['summary'])) {
            WP_CLI::log('');
            WP_CLI::log('📊 Overall Summary:');
            WP_CLI::log(sprintf('   Total Files: %d', $results['summary']['total_files']));
            WP_CLI::log(sprintf('   Total Classes: %d', $results['summary']['total_classes']));
            WP_CLI::log(sprintf('   Total Functions: %d', $results['summary']['total_functions']));
            WP_CLI::log(sprintf('   Total Hooks: %d', $results['summary']['total_hooks']));
        }
    }
    
    /**
     * Save results to file
     */
    private function save_results($results, $path) {
        // Default to wbcom-scan directory if just filename given
        if (!str_contains($path, '/')) {
            $upload_dir = wp_upload_dir();
            $scan_dir = $upload_dir['basedir'] . '/wbcom-scan';
            
            if (!is_dir($scan_dir)) {
                wp_mkdir_p($scan_dir);
            }
            
            $path = $scan_dir . '/' . $path;
        }
        
        file_put_contents($path, json_encode($results, JSON_PRETTY_PRINT));
        WP_CLI::log("Results saved to: {$path}");
    }
}

// Register command
WP_CLI::add_command('bp component-scan', 'BP_Component_Scan_Command');

/**
 * Additional BuddyPress testing commands
 */
class BP_Test_Commands {
    
    /**
     * Run functionality tests for BuddyPress
     *
     * ## OPTIONS
     *
     * [--component=<name>]
     * : Test specific component
     *
     * ## EXAMPLES
     *
     *     wp bp test functionality
     *     wp bp test functionality --component=members
     */
    public function functionality($args, $assoc_args) {
        WP_CLI::log('🧪 Running BuddyPress functionality tests...');
        
        $component = $assoc_args['component'] ?? 'all';
        
        // Run functionality analyzer
        $analyzer_path = dirname(__DIR__) . '/tools/ai/functionality-analyzer.mjs';
        $scan_path = wp_upload_dir()['basedir'] . '/wbcom-scan/buddypress-complete.json';
        
        if (!file_exists($scan_path)) {
            WP_CLI::error('No scan data found. Run: wp bp scan first');
        }
        
        $command = sprintf(
            'node %s --plugin buddypress --scan %s',
            escapeshellarg($analyzer_path),
            escapeshellarg($scan_path)
        );
        
        $output = shell_exec($command);
        WP_CLI::log($output);
        
        WP_CLI::success('Functionality tests completed');
    }
    
    /**
     * Generate test scenarios for BuddyPress
     *
     * ## EXAMPLES
     *
     *     wp bp test generate
     */
    public function generate($args, $assoc_args) {
        WP_CLI::log('📝 Generating BuddyPress test scenarios...');
        
        // Ensure scan exists
        $scan_path = wp_upload_dir()['basedir'] . '/wbcom-scan/buddypress-components-scan.json';
        
        if (!file_exists($scan_path)) {
            WP_CLI::log('Component scan not found. Running scan first...');
            WP_CLI::runcommand('bp component-scan --save=buddypress-components-scan.json');
        }
        
        // Run test generator
        $generator_path = dirname(__DIR__) . '/tools/ai/component-test-generator.mjs';
        
        $command = sprintf('node %s', escapeshellarg($generator_path));
        $output = shell_exec($command);
        
        WP_CLI::log($output);
        WP_CLI::success('Test scenarios generated');
    }
    
    /**
     * Execute BuddyPress tests
     *
     * ## OPTIONS
     *
     * [--type=<type>]
     * : Test type (unit, e2e, functional, all)
     * ---
     * default: all
     * ---
     *
     * ## EXAMPLES
     *
     *     wp bp test execute
     *     wp bp test execute --type=unit
     */
    public function execute($args, $assoc_args) {
        $type = $assoc_args['type'] ?? 'all';
        
        WP_CLI::log("🚀 Executing BuddyPress {$type} tests...");
        
        switch ($type) {
            case 'unit':
                WP_CLI::runcommand('eval-file vendor/bin/phpunit -c phpunit-components.xml');
                break;
                
            case 'e2e':
                $command = 'npx playwright test --config=tools/e2e/playwright.config.ts';
                shell_exec($command);
                break;
                
            case 'functional':
                $executor_path = dirname(__DIR__) . '/tools/ai/scenario-test-executor.mjs';
                $scan_path = wp_upload_dir()['basedir'] . '/wbcom-scan/buddypress-complete.json';
                
                $command = sprintf(
                    'node %s --plugin buddypress --scan %s',
                    escapeshellarg($executor_path),
                    escapeshellarg($scan_path)
                );
                
                shell_exec($command);
                break;
                
            case 'all':
                WP_CLI::runcommand('bp test execute --type=unit');
                WP_CLI::runcommand('bp test execute --type=functional');
                WP_CLI::runcommand('bp test execute --type=e2e');
                break;
        }
        
        WP_CLI::success("BuddyPress {$type} tests completed");
    }
    
    /**
     * Generate coverage report
     *
     * ## EXAMPLES
     *
     *     wp bp test coverage
     */
    public function coverage($args, $assoc_args) {
        WP_CLI::log('📊 Generating coverage report...');
        
        // Get scan data
        $scan_path = wp_upload_dir()['basedir'] . '/wbcom-scan/buddypress-components-scan.json';
        
        if (!file_exists($scan_path)) {
            WP_CLI::error('Component scan not found. Run: wp bp component-scan first');
        }
        
        $scan_data = json_decode(file_get_contents($scan_path), true);
        
        // Calculate coverage
        $coverage = [
            'components_scanned' => count($scan_data) - 1, // Exclude summary
            'total_files' => $scan_data['summary']['total_files'] ?? 0,
            'total_classes' => $scan_data['summary']['total_classes'] ?? 0,
            'total_functions' => $scan_data['summary']['total_functions'] ?? 0,
            'total_hooks' => $scan_data['summary']['total_hooks'] ?? 0
        ];
        
        WP_CLI::log('Coverage Summary:');
        foreach ($coverage as $key => $value) {
            WP_CLI::log(sprintf('  %s: %d', str_replace('_', ' ', ucfirst($key)), $value));
        }
        
        WP_CLI::success('Coverage report generated');
    }
}

// Register test commands
WP_CLI::add_command('bp test', 'BP_Test_Commands');

/**
 * Main BuddyPress testing command
 */
class BP_Testing_Command {
    
    /**
     * Complete BuddyPress testing workflow
     *
     * ## EXAMPLES
     *
     *     wp bp scan
     *     wp bp analyze
     *     wp bp test all
     */
    public function scan($args, $assoc_args) {
        WP_CLI::log('🔍 Scanning BuddyPress...');
        
        // Use existing wbcom scanner
        WP_CLI::runcommand('scan buddypress --output=json > ' . wp_upload_dir()['basedir'] . '/wbcom-scan/buddypress-complete.json');
        
        // Also run component scan
        WP_CLI::runcommand('bp component-scan --save=buddypress-components-scan.json');
        
        WP_CLI::success('BuddyPress scan completed');
    }
    
    public function analyze($args, $assoc_args) {
        WP_CLI::log('🎯 Analyzing BuddyPress functionality...');
        
        WP_CLI::runcommand('bp test functionality');
        
        // Run customer value analysis
        $analyzer_path = dirname(__DIR__) . '/tools/ai/customer-value-analyzer.mjs';
        $scan_path = wp_upload_dir()['basedir'] . '/wbcom-scan/buddypress-complete.json';
        
        $command = sprintf(
            'node %s --plugin buddypress --scan %s',
            escapeshellarg($analyzer_path),
            escapeshellarg($scan_path)
        );
        
        shell_exec($command);
        
        WP_CLI::success('BuddyPress analysis completed');
    }
    
    public function test($args, $assoc_args) {
        $subcommand = $args[0] ?? 'all';
        
        if ($subcommand === 'all') {
            WP_CLI::log('🧪 Running complete BuddyPress test suite...');
            
            // Run all test types
            WP_CLI::runcommand('bp scan');
            WP_CLI::runcommand('bp analyze');
            WP_CLI::runcommand('bp test execute --type=all');
            WP_CLI::runcommand('bp test coverage');
            
            WP_CLI::success('All BuddyPress tests completed');
        }
    }
}

// Register main commands
WP_CLI::add_command('bp scan', ['BP_Testing_Command', 'scan']);
WP_CLI::add_command('bp analyze', ['BP_Testing_Command', 'analyze']);
WP_CLI::add_command('bp test all', ['BP_Testing_Command', 'test']);