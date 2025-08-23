<?php
/**
 * BuddyPress Performance Profiler
 * 
 * Profiles WordPress and BuddyPress performance metrics
 */

class BuddyPressPerformanceProfiler
{
    private $start_time;
    private $queries = [];
    private $memory_usage = [];
    private $results = [];
    
    public function __construct()
    {
        $this->start_time = microtime(true);
        $this->memory_usage['start'] = memory_get_usage();
        
        // Hook into query logging
        add_filter('query', [$this, 'log_query']);
        
        // Hook into WordPress shutdown to generate report
        add_action('shutdown', [$this, 'generate_report']);
    }

    /**
     * Start profiling a specific operation
     */
    public function startProfiling($operation_name)
    {
        $this->results[$operation_name] = [
            'start_time' => microtime(true),
            'start_memory' => memory_get_usage(),
            'queries_before' => count($this->queries),
        ];
    }

    /**
     * End profiling a specific operation
     */
    public function endProfiling($operation_name)
    {
        if (!isset($this->results[$operation_name])) {
            return false;
        }
        
        $this->results[$operation_name]['end_time'] = microtime(true);
        $this->results[$operation_name]['end_memory'] = memory_get_usage();
        $this->results[$operation_name]['queries_after'] = count($this->queries);
        
        // Calculate metrics
        $result = &$this->results[$operation_name];
        $result['duration'] = $result['end_time'] - $result['start_time'];
        $result['memory_used'] = $result['end_memory'] - $result['start_memory'];
        $result['queries_count'] = $result['queries_after'] - $result['queries_before'];
        
        return $result;
    }

    /**
     * Log database queries
     */
    public function log_query($query)
    {
        $backtrace = debug_backtrace(DEBUG_BACKTRACE_IGNORE_ARGS, 5);
        
        $this->queries[] = [
            'query' => $query,
            'time' => microtime(true),
            'backtrace' => $backtrace,
        ];
        
        return $query;
    }

    /**
     * Profile BuddyPress component performance
     */
    public function profileBuddyPressComponents()
    {
        if (!function_exists('bp_is_active')) {
            return;
        }
        
        $components = [
            'members' => 'BP_Members_Component',
            'xprofile' => 'BP_XProfile_Component', 
            'activity' => 'BP_Activity_Component',
            'groups' => 'BP_Groups_Component',
            'friends' => 'BP_Friends_Component',
            'messages' => 'BP_Messages_Component',
            'notifications' => 'BP_Notifications_Component',
        ];
        
        foreach ($components as $component => $class) {
            if (bp_is_active($component)) {
                $this->startProfiling("component_{$component}");
                
                // Simulate component operations
                switch ($component) {
                    case 'members':
                        $this->profileMembersComponent();
                        break;
                    case 'activity':
                        $this->profileActivityComponent();
                        break;
                    case 'groups':
                        $this->profileGroupsComponent();
                        break;
                }
                
                $this->endProfiling("component_{$component}");
            }
        }
    }

    /**
     * Profile Members component
     */
    private function profileMembersComponent()
    {
        // Test member queries
        $members = bp_core_get_users([
            'type' => 'active',
            'per_page' => 20,
        ]);
        
        // Test member meta queries
        if (!empty($members['users'])) {
            foreach (array_slice($members['users'], 0, 5) as $member) {
                bp_get_member_last_active($member->ID);
            }
        }
    }

    /**
     * Profile Activity component
     */
    private function profileActivityComponent()
    {
        // Test activity queries
        $activities = bp_activity_get([
            'per_page' => 20,
            'show_hidden' => false,
        ]);
        
        // Test activity meta queries
        if (!empty($activities['activities'])) {
            foreach (array_slice($activities['activities'], 0, 5) as $activity) {
                bp_activity_get_meta($activity->id, 'test_meta');
            }
        }
    }

    /**
     * Profile Groups component
     */
    private function profileGroupsComponent()
    {
        // Test group queries
        $groups = groups_get_groups([
            'per_page' => 20,
            'show_hidden' => false,
        ]);
        
        // Test group member queries
        if (!empty($groups['groups'])) {
            foreach (array_slice($groups['groups'], 0, 3) as $group) {
                groups_get_group_members($group->id, 10);
            }
        }
    }

    /**
     * Analyze slow queries
     */
    private function analyzeSlowQueries()
    {
        $slow_queries = [];
        $query_times = [];
        
        for ($i = 1; $i < count($this->queries); $i++) {
            $duration = $this->queries[$i]['time'] - $this->queries[$i-1]['time'];
            $query_times[] = $duration;
            
            // Queries taking more than 0.01 seconds are considered slow
            if ($duration > 0.01) {
                $slow_queries[] = [
                    'query' => $this->queries[$i]['query'],
                    'duration' => $duration,
                    'backtrace' => $this->queries[$i]['backtrace'],
                ];
            }
        }
        
        return [
            'slow_queries' => $slow_queries,
            'total_queries' => count($this->queries),
            'average_query_time' => count($query_times) > 0 ? array_sum($query_times) / count($query_times) : 0,
            'max_query_time' => count($query_times) > 0 ? max($query_times) : 0,
        ];
    }

    /**
     * Check for performance issues
     */
    private function checkPerformanceIssues()
    {
        $issues = [];
        
        // Check total queries
        if (count($this->queries) > 100) {
            $issues[] = [
                'type' => 'high_query_count',
                'severity' => 'warning',
                'message' => 'High database query count: ' . count($this->queries),
                'recommendation' => 'Consider query optimization or caching',
            ];
        }
        
        // Check memory usage
        $total_memory = memory_get_usage() - $this->memory_usage['start'];
        if ($total_memory > 32 * 1024 * 1024) { // 32MB
            $issues[] = [
                'type' => 'high_memory_usage',
                'severity' => 'warning', 
                'message' => 'High memory usage: ' . $this->formatBytes($total_memory),
                'recommendation' => 'Optimize memory-intensive operations',
            ];
        }
        
        // Check execution time
        $execution_time = microtime(true) - $this->start_time;
        if ($execution_time > 2.0) { // 2 seconds
            $issues[] = [
                'type' => 'slow_execution',
                'severity' => 'warning',
                'message' => 'Slow page execution: ' . number_format($execution_time, 3) . 's',
                'recommendation' => 'Profile and optimize slow operations',
            ];
        }
        
        return $issues;
    }

    /**
     * Generate performance report
     */
    public function generate_report()
    {
        if (defined('DOING_AJAX') && DOING_AJAX) {
            return; // Skip for AJAX requests
        }
        
        $total_time = microtime(true) - $this->start_time;
        $total_memory = memory_get_usage() - $this->memory_usage['start'];
        $peak_memory = memory_get_peak_usage();
        
        $query_analysis = $this->analyzeSlowQueries();
        $issues = $this->checkPerformanceIssues();
        
        $report = [
            'timestamp' => current_time('mysql'),
            'url' => $_SERVER['REQUEST_URI'] ?? '',
            'execution_time' => $total_time,
            'memory_usage' => $total_memory,
            'peak_memory' => $peak_memory,
            'query_count' => count($this->queries),
            'query_analysis' => $query_analysis,
            'component_performance' => $this->results,
            'issues' => $issues,
        ];
        
        // Output report if in debug mode
        if (defined('WP_DEBUG') && WP_DEBUG && !defined('DOING_CRON')) {
            $this->outputReport($report);
        }
        
        // Save to log file
        $this->saveReport($report);
    }

    /**
     * Output performance report to screen
     */
    private function outputReport($report)
    {
        if (headers_sent()) {
            return;
        }
        
        echo "\n\n<!-- BuddyPress Performance Report -->\n";
        echo "<!-- \n";
        echo "Execution Time: " . number_format($report['execution_time'], 3) . "s\n";
        echo "Memory Usage: " . $this->formatBytes($report['memory_usage']) . "\n";
        echo "Peak Memory: " . $this->formatBytes($report['peak_memory']) . "\n";
        echo "Database Queries: " . $report['query_count'] . "\n";
        
        if (!empty($report['query_analysis']['slow_queries'])) {
            echo "\nSlow Queries (" . count($report['query_analysis']['slow_queries']) . "):\n";
            foreach (array_slice($report['query_analysis']['slow_queries'], 0, 5) as $query) {
                echo "- " . number_format($query['duration'], 4) . "s: " . substr($query['query'], 0, 100) . "...\n";
            }
        }
        
        if (!empty($report['issues'])) {
            echo "\nPerformance Issues:\n";
            foreach ($report['issues'] as $issue) {
                echo "- [{$issue['severity']}] {$issue['message']}\n";
                echo "  Recommendation: {$issue['recommendation']}\n";
            }
        }
        
        echo "-->\n";
    }

    /**
     * Save performance report to log file
     */
    private function saveReport($report)
    {
        $log_dir = WP_CONTENT_DIR . '/uploads/performance-logs';
        if (!file_exists($log_dir)) {
            wp_mkdir_p($log_dir);
        }
        
        $log_file = $log_dir . '/performance-' . date('Y-m-d') . '.json';
        $log_entry = json_encode($report) . "\n";
        
        file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
    }

    /**
     * Format bytes to human readable format
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
}

// Initialize profiler if debug mode is enabled
if (defined('WP_DEBUG') && WP_DEBUG) {
    new BuddyPressPerformanceProfiler();
}

// WP-CLI command for performance testing
if (defined('WP_CLI') && WP_CLI) {
    WP_CLI::add_command('bp performance-test', function($args, $assoc_args) {
        $profiler = new BuddyPressPerformanceProfiler();
        
        WP_CLI::line('Running BuddyPress performance tests...');
        
        // Profile components
        $profiler->profileBuddyPressComponents();
        
        // Generate report
        $profiler->generate_report();
        
        WP_CLI::success('Performance test completed. Check /wp-content/uploads/performance-logs/ for detailed results.');
    });
}