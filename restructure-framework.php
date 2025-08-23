<?php
/**
 * WP Testing Framework Restructuring Script
 * 
 * Reorganizes the framework for scalability (100+ plugins)
 * Separates universal components from plugin-specific data
 * Creates clean structure for GitHub sync
 */

class FrameworkRestructure {
    
    private $base_path;
    private $moved_files = [];
    private $created_dirs = [];
    private $errors = [];
    
    public function __construct() {
        $this->base_path = '/Users/varundubey/Local Sites/buddynext/app/public/wp-testing-framework';
    }
    
    public function execute() {
        echo "WP Testing Framework Restructuring\n";
        echo "===================================\n\n";
        
        // Step 1: Create new directory structure
        $this->createNewStructure();
        
        // Step 2: Move universal components
        $this->moveUniversalComponents();
        
        // Step 3: Organize BuddyPress plugin
        $this->organizeBuddyPressPlugin();
        
        // Step 4: Move ephemeral data to workspace
        $this->moveEphemeralData();
        
        // Step 5: Create plugin template
        $this->createPluginTemplate();
        
        // Step 6: Update configuration files
        $this->updateConfigurations();
        
        // Step 7: Clean up old structure
        $this->cleanupOldStructure();
        
        // Step 8: Generate report
        $this->generateReport();
    }
    
    private function createNewStructure() {
        echo "Creating new directory structure...\n";
        
        $directories = [
            // Universal framework
            '/src',
            '/src/Framework',
            '/src/Generators',
            '/src/Analyzers', 
            '/src/Utilities',
            '/src/Templates',
            '/src/Bin',
            '/src/Interfaces',
            
            // Plugin-specific
            '/plugins',
            '/plugins/buddypress',
            '/plugins/buddypress/data',
            '/plugins/buddypress/data/fixtures',
            '/plugins/buddypress/data/mocks',
            '/plugins/buddypress/data/seeds',
            '/plugins/buddypress/tests',
            '/plugins/buddypress/scanners',
            '/plugins/buddypress/models',
            '/plugins/buddypress/analysis',
            '/plugins/buddypress/commands',
            '/plugins/buddypress/docs',
            
            // Workspace (ephemeral)
            '/workspace',
            '/workspace/reports',
            '/workspace/reports/buddypress',
            '/workspace/screenshots',
            '/workspace/videos',
            '/workspace/logs',
            '/workspace/cache',
            '/workspace/output',
            
            // Templates
            '/templates',
            '/templates/plugin-skeleton',
            '/templates/plugin-skeleton/data',
            '/templates/plugin-skeleton/tests',
            '/templates/plugin-skeleton/scanners',
            '/templates/plugin-skeleton/models',
            '/templates/plugin-skeleton/analysis',
            '/templates/plugin-skeleton/commands',
            '/templates/plugin-skeleton/docs'
        ];
        
        foreach ($directories as $dir) {
            $full_path = $this->base_path . $dir;
            if (!file_exists($full_path)) {
                if (mkdir($full_path, 0755, true)) {
                    $this->created_dirs[] = $dir;
                    echo "  ✅ Created: $dir\n";
                }
            }
        }
        
        echo "Created " . count($this->created_dirs) . " directories\n\n";
    }
    
    private function moveUniversalComponents() {
        echo "Moving universal framework components...\n";
        
        // Move generators
        $this->moveDirectory('/tools/generators', '/src/Generators');
        
        // Move analyzers (but not plugin-specific ones)
        $analyzers = glob($this->base_path . '/tools/analyzers/*.php');
        foreach ($analyzers as $file) {
            $filename = basename($file);
            if (!strpos($filename, 'buddypress') && !strpos($filename, 'bp-')) {
                $this->moveFile($file, $this->base_path . '/src/Analyzers/' . $filename);
            }
        }
        
        // Move universal utilities
        $utilities = [
            'file-index-generator.php',
            'report-organizer.php',
            'test-executor.php'
        ];
        
        foreach ($utilities as $utility) {
            $source = $this->base_path . '/tools/utilities/' . $utility;
            if (file_exists($source)) {
                $this->moveFile($source, $this->base_path . '/src/Utilities/' . $utility);
            }
        }
        
        // Move templates
        $this->moveDirectory('/tools/templates', '/src/Templates');
        
        // Move bin scripts
        if (file_exists($this->base_path . '/bin')) {
            $this->moveDirectory('/bin', '/src/Bin');
        }
        
        echo "\n";
    }
    
    private function organizeBuddyPressPlugin() {
        echo "Organizing BuddyPress plugin structure...\n";
        
        // Move tests
        if (file_exists($this->base_path . '/tests/plugins/buddypress')) {
            $this->moveDirectory('/tests/plugins/buddypress', '/plugins/buddypress/tests');
        }
        
        // Move BuddyPress-specific scanners
        $bp_scanners = glob($this->base_path . '/tools/scanners/*buddypress*.php');
        $bp_scanners = array_merge($bp_scanners, glob($this->base_path . '/tools/scanners/bp-*.php'));
        
        foreach ($bp_scanners as $scanner) {
            $filename = basename($scanner);
            $this->moveFile($scanner, $this->base_path . '/plugins/buddypress/scanners/' . $filename);
        }
        
        // Move WP-CLI commands
        if (file_exists($this->base_path . '/wp-cli-commands')) {
            $this->moveDirectory('/wp-cli-commands', '/plugins/buddypress/commands');
        }
        
        // Move analysis data (permanent)
        $analysis_files = glob($this->base_path . '/reports/buddypress/analysis/*');
        foreach ($analysis_files as $file) {
            if (!is_dir($file)) {
                $filename = basename($file);
                $this->moveFile($file, $this->base_path . '/plugins/buddypress/analysis/' . $filename);
            }
        }
        
        // Create models from existing data
        $this->createBuddyPressModels();
        
        echo "\n";
    }
    
    private function moveEphemeralData() {
        echo "Moving ephemeral data to workspace...\n";
        
        // Move execution reports
        $this->moveDirectory('/reports/buddypress/execution', '/workspace/reports/buddypress/execution');
        
        // Move coverage reports (regeneratable)
        $this->moveDirectory('/reports/buddypress/coverage', '/workspace/reports/buddypress/coverage');
        
        // Move integration reports (regeneratable)
        $this->moveDirectory('/reports/buddypress/integration', '/workspace/reports/buddypress/integration');
        
        // Move any screenshots, videos, logs
        $files_to_move = [
            '/*.log' => '/workspace/logs/',
            '/screenshots/*' => '/workspace/screenshots/',
            '/videos/*' => '/workspace/videos/'
        ];
        
        foreach ($files_to_move as $pattern => $destination) {
            $files = glob($this->base_path . $pattern);
            foreach ($files as $file) {
                if (!is_dir($file)) {
                    $filename = basename($file);
                    $dest = $this->base_path . $destination . $filename;
                    $this->moveFile($file, $dest);
                }
            }
        }
        
        echo "\n";
    }
    
    private function createPluginTemplate() {
        echo "Creating plugin template...\n";
        
        $template_base = $this->base_path . '/templates/plugin-skeleton';
        
        // Create .gitkeep files
        $gitkeep_dirs = [
            '/data/fixtures',
            '/data/mocks',
            '/data/seeds',
            '/tests/unit',
            '/tests/integration',
            '/tests/functional',
            '/scanners',
            '/analysis',
            '/commands'
        ];
        
        foreach ($gitkeep_dirs as $dir) {
            $full_path = $template_base . $dir;
            if (!file_exists($full_path)) {
                mkdir($full_path, 0755, true);
            }
            touch($full_path . '/.gitkeep');
        }
        
        // Create template files
        $this->createTemplateFiles($template_base);
        
        echo "  ✅ Plugin template created\n\n";
    }
    
    private function createBuddyPressModels() {
        $models_dir = $this->base_path . '/plugins/buddypress/models';
        
        // Create patterns.json
        $patterns = [
            'hooks' => [
                'actions' => ['bp_init', 'bp_setup_nav', 'bp_ready'],
                'filters' => ['bp_get_activity_content', 'bp_get_group_name']
            ],
            'components' => ['activity', 'groups', 'members', 'xprofile', 'messages', 'friends', 'notifications', 'settings', 'blogs'],
            'database_tables' => ['bp_activity', 'bp_groups', 'bp_xprofile_data']
        ];
        file_put_contents($models_dir . '/patterns.json', json_encode($patterns, JSON_PRETTY_PRINT));
        
        // Create best-practices.json
        $best_practices = [
            'security' => [
                'always_escape_output' => true,
                'validate_input' => true,
                'use_nonces' => true
            ],
            'performance' => [
                'cache_queries' => true,
                'lazy_load' => true
            ]
        ];
        file_put_contents($models_dir . '/best-practices.json', json_encode($best_practices, JSON_PRETTY_PRINT));
        
        // Create vulnerabilities.json
        $vulnerabilities = [
            'known_issues' => [],
            'security_checks' => ['sql_injection', 'xss', 'csrf']
        ];
        file_put_contents($models_dir . '/vulnerabilities.json', json_encode($vulnerabilities, JSON_PRETTY_PRINT));
        
        echo "  ✅ Created BuddyPress models\n";
    }
    
    private function createTemplateFiles($template_base) {
        // Create plugin-config.json template
        $config = [
            'name' => '{plugin-name}',
            'version' => '1.0.0',
            'components' => [],
            'test_suites' => ['unit', 'integration', 'functional'],
            'scanners' => [],
            'models' => ['patterns', 'best-practices', 'vulnerabilities']
        ];
        file_put_contents($template_base . '/plugin-config.json', json_encode($config, JSON_PRETTY_PRINT));
        
        // Create README template
        $readme = "# {Plugin Name} Testing Suite\n\n";
        $readme .= "## Overview\n\n";
        $readme .= "Testing suite for {Plugin Name} WordPress plugin.\n\n";
        $readme .= "## Structure\n\n";
        $readme .= "- `data/` - Test fixtures and mock data\n";
        $readme .= "- `tests/` - Test suites\n";
        $readme .= "- `scanners/` - Code scanners\n";
        $readme .= "- `models/` - Learning models\n";
        $readme .= "- `analysis/` - Static analysis results\n";
        $readme .= "- `commands/` - WP-CLI commands\n";
        file_put_contents($template_base . '/docs/README.md', $readme);
        
        // Create phpunit.xml template
        $phpunit = '<?xml version="1.0" encoding="UTF-8"?>
<phpunit bootstrap="../../../vendor/autoload.php">
    <testsuites>
        <testsuite name="{Plugin} Unit Tests">
            <directory>./unit</directory>
        </testsuite>
        <testsuite name="{Plugin} Integration Tests">
            <directory>./integration</directory>
        </testsuite>
    </testsuites>
</phpunit>';
        file_put_contents($template_base . '/tests/phpunit.xml', $phpunit);
    }
    
    private function updateConfigurations() {
        echo "Updating configuration files...\n";
        
        // Update .gitignore
        $gitignore = "# Ephemeral data - NOT synced\n";
        $gitignore .= "/workspace/\n";
        $gitignore .= "*.log\n";
        $gitignore .= "*.cache\n";
        $gitignore .= ".phpunit.result.cache\n\n";
        $gitignore .= "# Dependencies\n";
        $gitignore .= "/vendor/\n";
        $gitignore .= "/node_modules/\n\n";
        $gitignore .= "# IDE\n";
        $gitignore .= ".idea/\n";
        $gitignore .= ".vscode/\n\n";
        $gitignore .= "# OS\n";
        $gitignore .= ".DS_Store\n";
        $gitignore .= "Thumbs.db\n";
        
        file_put_contents($this->base_path . '/.gitignore', $gitignore);
        echo "  ✅ Updated .gitignore\n";
        
        // Create framework config
        $framework_config = [
            'version' => '2.0.0',
            'structure' => [
                'plugins_directory' => './plugins',
                'workspace_directory' => './workspace',
                'templates_directory' => './templates',
                'source_directory' => './src'
            ],
            'github_sync' => [
                'include' => ['src', 'plugins', 'templates', 'docs', 'config'],
                'exclude' => ['workspace', 'vendor', 'node_modules']
            ]
        ];
        
        file_put_contents($this->base_path . '/config/framework.json', json_encode($framework_config, JSON_PRETTY_PRINT));
        echo "  ✅ Created framework.json\n\n";
    }
    
    private function cleanupOldStructure() {
        echo "Cleaning up old structure...\n";
        
        // Remove old empty directories
        $dirs_to_check = [
            '/tools/scanners',
            '/tools/generators',
            '/tools/analyzers',
            '/reports/buddypress',
            '/tests/plugins'
        ];
        
        foreach ($dirs_to_check as $dir) {
            $full_path = $this->base_path . $dir;
            if (file_exists($full_path) && $this->isDirEmpty($full_path)) {
                rmdir($full_path);
                echo "  ✅ Removed empty: $dir\n";
            }
        }
        
        echo "\n";
    }
    
    private function generateReport() {
        echo "Generating restructure report...\n\n";
        
        $report = "RESTRUCTURE SUMMARY\n";
        $report .= "===================\n\n";
        
        $report .= "Directories Created: " . count($this->created_dirs) . "\n";
        $report .= "Files Moved: " . count($this->moved_files) . "\n";
        
        if (!empty($this->errors)) {
            $report .= "\nErrors:\n";
            foreach ($this->errors as $error) {
                $report .= "  ❌ $error\n";
            }
        }
        
        $report .= "\nNew Structure:\n";
        $report .= "- /src/          Universal framework\n";
        $report .= "- /plugins/      Plugin-specific data\n";
        $report .= "- /workspace/    Ephemeral data (not synced)\n";
        $report .= "- /templates/    Plugin templates\n";
        
        file_put_contents($this->base_path . '/RESTRUCTURE-REPORT.md', $report);
        
        echo $report;
        echo "\n✅ Restructuring complete!\n";
    }
    
    private function moveFile($source, $destination) {
        if (file_exists($source)) {
            $dest_dir = dirname($destination);
            if (!file_exists($dest_dir)) {
                mkdir($dest_dir, 0755, true);
            }
            
            if (rename($source, $destination)) {
                $this->moved_files[] = basename($source);
                return true;
            } else {
                $this->errors[] = "Failed to move: " . basename($source);
                return false;
            }
        }
        return false;
    }
    
    private function moveDirectory($source, $destination) {
        $source_path = $this->base_path . $source;
        $dest_path = $this->base_path . $destination;
        
        if (file_exists($source_path)) {
            if (!file_exists($dest_path)) {
                mkdir($dest_path, 0755, true);
            }
            
            $this->recursiveCopy($source_path, $dest_path);
            $this->recursiveRemove($source_path);
            
            echo "  ✅ Moved: $source → $destination\n";
            return true;
        }
        return false;
    }
    
    private function recursiveCopy($source, $dest) {
        $dir = opendir($source);
        if (!file_exists($dest)) {
            mkdir($dest, 0755, true);
        }
        
        while (($file = readdir($dir)) !== false) {
            if ($file != '.' && $file != '..') {
                if (is_dir($source . '/' . $file)) {
                    $this->recursiveCopy($source . '/' . $file, $dest . '/' . $file);
                } else {
                    copy($source . '/' . $file, $dest . '/' . $file);
                    $this->moved_files[] = $file;
                }
            }
        }
        
        closedir($dir);
    }
    
    private function recursiveRemove($dir) {
        if (is_dir($dir)) {
            $objects = scandir($dir);
            foreach ($objects as $object) {
                if ($object != '.' && $object != '..') {
                    if (is_dir($dir . '/' . $object)) {
                        $this->recursiveRemove($dir . '/' . $object);
                    } else {
                        unlink($dir . '/' . $object);
                    }
                }
            }
            rmdir($dir);
        }
    }
    
    private function isDirEmpty($dir) {
        $handle = opendir($dir);
        while (($entry = readdir($handle)) !== false) {
            if ($entry != '.' && $entry != '..') {
                closedir($handle);
                return false;
            }
        }
        closedir($handle);
        return true;
    }
}

// Execute restructuring
$restructure = new FrameworkRestructure();
$restructure->execute();