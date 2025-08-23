<?php
/**
 * BuddyPress Advanced Features Scanner
 * 
 * Scans for additional features: Invitations, Moderation, Media/Attachments, Search
 */

namespace WPTestingFramework\Scanners;

class BPAdvancedFeaturesScanner {
    
    private $bp_path;
    private $results = [];
    
    // Advanced features to analyze
    private $advanced_features = [
        'invitations' => [
            'name' => 'Community Invitations',
            'files' => [],
            'classes' => [],
            'functions' => [],
            'capabilities' => []
        ],
        'moderation' => [
            'name' => 'Content Moderation',
            'files' => [],
            'classes' => [],
            'functions' => [],
            'capabilities' => []
        ],
        'attachments' => [
            'name' => 'Media & Attachments',
            'files' => [],
            'classes' => [],
            'functions' => [],
            'capabilities' => []
        ],
        'search' => [
            'name' => 'Advanced Search',
            'files' => [],
            'classes' => [],
            'functions' => [],
            'capabilities' => []
        ],
        'privacy' => [
            'name' => 'Privacy & Visibility',
            'files' => [],
            'classes' => [],
            'functions' => [],
            'capabilities' => []
        ]
    ];
    
    public function __construct() {
        $this->bp_path = '/Users/varundubey/Local Sites/buddynext/app/public/wp-content/plugins/buddypress/src';
    }
    
    public function scan() {
        echo "BuddyPress Advanced Features Scanner\n";
        echo "=====================================\n\n";
        
        // Scan each advanced feature
        $this->scan_invitations();
        $this->scan_moderation();
        $this->scan_attachments();
        $this->scan_search();
        $this->scan_privacy();
        
        // Generate report
        $this->generate_report();
        
        return $this->results;
    }
    
    private function scan_invitations() {
        echo "Scanning Invitations System...\n";
        
        // Core invitation files
        $invitation_files = [
            'bp-core/classes/class-bp-invitation.php',
            'bp-core/classes/class-bp-invitation-manager.php',
            'bp-members/classes/class-bp-members-invitations-list-table.php',
            'bp-members/classes/class-bp-members-invitation-manager.php',
            'bp-members/classes/class-bp-members-invitations-rest-controller.php',
            'bp-groups/classes/class-bp-groups-invitation-manager.php'
        ];
        
        foreach ($invitation_files as $file) {
            $full_path = $this->bp_path . '/' . $file;
            if (file_exists($full_path)) {
                $this->advanced_features['invitations']['files'][] = $file;
                $this->analyze_file($full_path, 'invitations');
            }
        }
        
        // Invitation functions
        $this->scan_functions_by_pattern('bp_.*invit', 'invitations');
        
        // Invitation capabilities
        $this->advanced_features['invitations']['capabilities'] = [
            'bp_members_send_invitation',
            'bp_members_delete_invitation',
            'bp_groups_send_invitation',
            'bp_groups_receive_invitation'
        ];
    }
    
    private function scan_moderation() {
        echo "Scanning Moderation System...\n";
        
        // Core moderation file
        $moderation_files = [
            'bp-core/bp-core-moderation.php',
            'bp-activity/bp-activity-moderation.php',
            'bp-groups/bp-groups-moderation.php'
        ];
        
        foreach ($moderation_files as $file) {
            $full_path = $this->bp_path . '/' . $file;
            if (file_exists($full_path)) {
                $this->advanced_features['moderation']['files'][] = $file;
                $this->analyze_file($full_path, 'moderation');
            }
        }
        
        // Moderation functions
        $this->scan_functions_by_pattern('bp_.*moderat', 'moderation');
        $this->scan_functions_by_pattern('bp_.*spam', 'moderation');
        $this->scan_functions_by_pattern('bp_.*suspend', 'moderation');
        
        // Moderation capabilities
        $this->advanced_features['moderation']['capabilities'] = [
            'bp_moderate',
            'bp_moderate_activity',
            'bp_moderate_groups',
            'bp_moderate_members',
            'bp_spam_user',
            'bp_delete_user'
        ];
    }
    
    private function scan_attachments() {
        echo "Scanning Attachments & Media System...\n";
        
        // Core attachment files
        $attachment_files = [
            'bp-core/bp-core-attachments.php',
            'bp-core/bp-core-avatars.php',
            'bp-core/bp-core-cover-images.php',
            'bp-core/classes/class-bp-attachment.php',
            'bp-core/classes/class-bp-attachment-avatar.php',
            'bp-core/classes/class-bp-attachment-cover-image.php',
            'bp-messages/classes/class-bp-messages-attachment.php'
        ];
        
        foreach ($attachment_files as $file) {
            $full_path = $this->bp_path . '/' . $file;
            if (file_exists($full_path)) {
                $this->advanced_features['attachments']['files'][] = $file;
                $this->analyze_file($full_path, 'attachments');
            }
        }
        
        // Attachment functions
        $this->scan_functions_by_pattern('bp_.*attachment', 'attachments');
        $this->scan_functions_by_pattern('bp_.*avatar', 'attachments');
        $this->scan_functions_by_pattern('bp_.*cover', 'attachments');
        $this->scan_functions_by_pattern('bp_.*upload', 'attachments');
        
        // Attachment capabilities
        $this->advanced_features['attachments']['capabilities'] = [
            'bp_upload_avatar',
            'bp_upload_cover_image',
            'bp_messages_upload_attachment',
            'bp_activity_upload_media'
        ];
    }
    
    private function scan_search() {
        echo "Scanning Search System...\n";
        
        // Search related files
        $search_files = [
            'bp-core/bp-core-search.php',
            'bp-core/classes/class-bp-core-search.php',
            'bp-activity/bp-activity-search.php',
            'bp-groups/bp-groups-search.php',
            'bp-members/bp-members-search.php',
            'bp-blogs/bp-blogs-search.php'
        ];
        
        foreach ($search_files as $file) {
            $full_path = $this->bp_path . '/' . $file;
            if (file_exists($full_path)) {
                $this->advanced_features['search']['files'][] = $file;
                $this->analyze_file($full_path, 'search');
            }
        }
        
        // Search functions
        $this->scan_functions_by_pattern('bp_.*search', 'search');
        $this->scan_functions_by_pattern('bp_.*query', 'search');
        
        // Search types
        $this->advanced_features['search']['search_types'] = [
            'members' => 'Member search',
            'groups' => 'Group search',
            'activity' => 'Activity search',
            'messages' => 'Message search',
            'xprofile' => 'Profile field search',
            'blogs' => 'Blog/Site search',
            'global' => 'Global unified search'
        ];
    }
    
    private function scan_privacy() {
        echo "Scanning Privacy & Visibility System...\n";
        
        // Privacy related files
        $privacy_files = [
            'bp-xprofile/classes/class-bp-xprofile-visibility.php',
            'bp-core/bp-core-privacy.php',
            'bp-activity/bp-activity-privacy.php',
            'bp-members/bp-members-privacy.php'
        ];
        
        foreach ($privacy_files as $file) {
            $full_path = $this->bp_path . '/' . $file;
            if (file_exists($full_path)) {
                $this->advanced_features['privacy']['files'][] = $file;
                $this->analyze_file($full_path, 'privacy');
            }
        }
        
        // Privacy functions
        $this->scan_functions_by_pattern('bp_.*privacy', 'privacy');
        $this->scan_functions_by_pattern('bp_.*visibility', 'privacy');
        $this->scan_functions_by_pattern('bp_.*block', 'privacy');
        
        // Privacy levels
        $this->advanced_features['privacy']['visibility_levels'] = [
            'public' => 'Anyone can view',
            'loggedin' => 'Logged-in users only',
            'friends' => 'Friends/connections only',
            'onlyme' => 'Only the user',
            'adminsonly' => 'Administrators only'
        ];
        
        // Privacy capabilities
        $this->advanced_features['privacy']['capabilities'] = [
            'bp_xprofile_change_field_visibility',
            'bp_moderate_private_messages',
            'bp_block_users',
            'bp_view_private_profiles'
        ];
    }
    
    private function analyze_file($file_path, $feature) {
        if (!file_exists($file_path)) {
            return;
        }
        
        $content = file_get_contents($file_path);
        
        // Extract classes
        if (preg_match_all('/class\s+(\w+)/', $content, $matches)) {
            foreach ($matches[1] as $class) {
                if (!in_array($class, $this->advanced_features[$feature]['classes'])) {
                    $this->advanced_features[$feature]['classes'][] = $class;
                }
            }
        }
        
        // Extract functions
        if (preg_match_all('/function\s+(\w+)\s*\(/', $content, $matches)) {
            foreach ($matches[1] as $function) {
                if (!in_array($function, $this->advanced_features[$feature]['functions'])) {
                    $this->advanced_features[$feature]['functions'][] = $function;
                }
            }
        }
    }
    
    private function scan_functions_by_pattern($pattern, $feature) {
        $command = "grep -r 'function $pattern' " . escapeshellarg($this->bp_path) . " 2>/dev/null | grep -o 'function [a-zA-Z0-9_]*' | cut -d' ' -f2 | sort | uniq";
        $output = shell_exec($command);
        
        if ($output) {
            $functions = array_filter(explode("\n", $output));
            foreach ($functions as $function) {
                if (!in_array($function, $this->advanced_features[$feature]['functions'])) {
                    $this->advanced_features[$feature]['functions'][] = $function;
                }
            }
        }
    }
    
    private function generate_report() {
        echo "\n\n";
        echo "=========================================\n";
        echo "BUDDYPRESS ADVANCED FEATURES ANALYSIS\n";
        echo "=========================================\n\n";
        
        foreach ($this->advanced_features as $feature_id => $feature) {
            echo "## " . $feature['name'] . "\n";
            echo str_repeat("-", strlen($feature['name']) + 3) . "\n";
            
            echo "Files: " . count($feature['files']) . "\n";
            echo "Classes: " . count($feature['classes']) . "\n";
            echo "Functions: " . count($feature['functions']) . "\n";
            
            if (!empty($feature['capabilities'])) {
                echo "Capabilities: " . count($feature['capabilities']) . "\n";
            }
            
            if (!empty($feature['search_types'])) {
                echo "Search Types: " . count($feature['search_types']) . "\n";
            }
            
            if (!empty($feature['visibility_levels'])) {
                echo "Visibility Levels: " . count($feature['visibility_levels']) . "\n";
            }
            
            // Check if feature is well-implemented
            $implementation_score = $this->calculate_implementation_score($feature);
            echo "Implementation Score: " . $implementation_score . "%\n";
            
            if ($implementation_score < 50) {
                echo "⚠️  WARNING: This feature appears to be minimally implemented\n";
            }
            
            echo "\n";
        }
        
        // Summary
        echo "\n## SUMMARY\n";
        echo "----------\n";
        
        $total_files = 0;
        $total_classes = 0;
        $total_functions = 0;
        
        foreach ($this->advanced_features as $feature) {
            $total_files += count($feature['files']);
            $total_classes += count($feature['classes']);
            $total_functions += count($feature['functions']);
        }
        
        echo "Total Advanced Feature Files: $total_files\n";
        echo "Total Advanced Feature Classes: $total_classes\n";
        echo "Total Advanced Feature Functions: $total_functions\n";
        
        // Testing recommendations
        echo "\n## TESTING RECOMMENDATIONS\n";
        echo "-------------------------\n";
        
        foreach ($this->advanced_features as $feature_id => $feature) {
            $score = $this->calculate_implementation_score($feature);
            if ($score > 0) {
                echo "\n### " . $feature['name'] . "\n";
                $this->generate_test_recommendations($feature_id, $feature);
            }
        }
        
        // Save results
        $this->results = $this->advanced_features;
        $this->save_results();
    }
    
    private function calculate_implementation_score($feature) {
        $score = 0;
        $factors = 0;
        
        if (count($feature['files']) > 0) {
            $score += min(count($feature['files']) * 10, 30);
            $factors++;
        }
        
        if (count($feature['classes']) > 0) {
            $score += min(count($feature['classes']) * 5, 35);
            $factors++;
        }
        
        if (count($feature['functions']) > 0) {
            $score += min(count($feature['functions']) * 2, 35);
            $factors++;
        }
        
        return $factors > 0 ? round($score) : 0;
    }
    
    private function generate_test_recommendations($feature_id, $feature) {
        $recommendations = [];
        
        switch ($feature_id) {
            case 'invitations':
                $recommendations = [
                    'Test sending member invitations',
                    'Test accepting/rejecting invitations',
                    'Test invitation expiry',
                    'Test bulk invitation sending',
                    'Test invitation tracking and analytics',
                    'Test email invitation delivery',
                    'Test invitation rate limiting'
                ];
                break;
                
            case 'moderation':
                $recommendations = [
                    'Test content flagging',
                    'Test spam detection',
                    'Test user suspension',
                    'Test moderation queue',
                    'Test auto-moderation rules',
                    'Test moderation notifications',
                    'Test bulk moderation actions'
                ];
                break;
                
            case 'attachments':
                $recommendations = [
                    'Test file upload validation',
                    'Test file size limits',
                    'Test file type restrictions',
                    'Test avatar cropping',
                    'Test cover image positioning',
                    'Test attachment security',
                    'Test attachment deletion'
                ];
                break;
                
            case 'search':
                $recommendations = [
                    'Test search relevance',
                    'Test search filters',
                    'Test search pagination',
                    'Test search performance',
                    'Test fuzzy search',
                    'Test search suggestions',
                    'Test search analytics'
                ];
                break;
                
            case 'privacy':
                $recommendations = [
                    'Test visibility settings',
                    'Test user blocking',
                    'Test data export',
                    'Test data deletion',
                    'Test privacy settings inheritance',
                    'Test third-party data sharing',
                    'Test GDPR compliance'
                ];
                break;
        }
        
        foreach ($recommendations as $rec) {
            echo "- $rec\n";
        }
    }
    
    private function save_results() {
        $report_path = '/Users/varundubey/Local Sites/buddynext/app/public/wp-testing-framework/reports';
        
        // Save JSON report
        $json_file = $report_path . '/buddypress-advanced-features-analysis.json';
        file_put_contents($json_file, json_encode($this->results, JSON_PRETTY_PRINT));
        echo "\n✅ JSON report saved to: $json_file\n";
        
        // Save Markdown report
        $md_content = $this->generate_markdown_report();
        $md_file = $report_path . '/buddypress-advanced-features-analysis.md';
        file_put_contents($md_file, $md_content);
        echo "✅ Markdown report saved to: $md_file\n";
    }
    
    private function generate_markdown_report() {
        $md = "# BuddyPress Advanced Features Analysis\n\n";
        $md .= "Generated: " . date('Y-m-d H:i:s') . "\n\n";
        
        foreach ($this->advanced_features as $feature_id => $feature) {
            $md .= "## " . $feature['name'] . "\n\n";
            
            $md .= "### Statistics\n";
            $md .= "- Files: " . count($feature['files']) . "\n";
            $md .= "- Classes: " . count($feature['classes']) . "\n";
            $md .= "- Functions: " . count($feature['functions']) . "\n";
            
            if (!empty($feature['capabilities'])) {
                $md .= "\n### Capabilities\n";
                foreach ($feature['capabilities'] as $cap) {
                    $md .= "- `$cap`\n";
                }
            }
            
            if (!empty($feature['classes']) && count($feature['classes']) <= 10) {
                $md .= "\n### Key Classes\n";
                foreach ($feature['classes'] as $class) {
                    $md .= "- `$class`\n";
                }
            }
            
            $md .= "\n";
        }
        
        return $md;
    }
}

// Execute scanner
$scanner = new BPAdvancedFeaturesScanner();
$scanner->scan();