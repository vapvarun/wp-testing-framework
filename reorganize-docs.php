<?php
/**
 * Documentation Reorganization Script
 * Organizes docs into proper structure for 100+ plugin scalability
 */

class DocsReorganizer {
    private $baseDir;
    private $changes = [];
    
    public function __construct($baseDir) {
        $this->baseDir = rtrim($baseDir, '/');
    }
    
    public function reorganize() {
        echo "📚 Starting Documentation Reorganization...\n";
        echo "==========================================\n\n";
        
        // 1. Create proper structure
        $this->createProperStructure();
        
        // 2. Move framework docs
        $this->moveFrameworkDocs();
        
        // 3. Move BuddyPress-specific docs
        $this->moveBuddyPressDocs();
        
        // 4. Clean up root directory
        $this->cleanupRootDocs();
        
        // 5. Create master index
        $this->createMasterDocsIndex();
        
        // 6. Report changes
        $this->reportChanges();
    }
    
    private function createProperStructure() {
        echo "📁 Creating proper documentation structure...\n";
        
        $directories = [
            '/docs',                          // Root docs for framework
            '/docs/framework',                // Framework-specific guides
            '/docs/architecture',             // Architecture documentation
            '/docs/guides',                   // User guides
            '/docs/api',                      // API documentation
            '/plugins/buddypress/docs',       // Plugin-specific docs
            '/templates/plugin-skeleton/docs' // Template docs
        ];
        
        foreach ($directories as $dir) {
            $path = $this->baseDir . $dir;
            if (!is_dir($path)) {
                mkdir($path, 0755, true);
                echo "  ✅ Created: $dir\n";
            }
        }
        echo "\n";
    }
    
    private function moveFrameworkDocs() {
        echo "📋 Organizing framework documentation...\n";
        
        $moves = [
            // Framework guides to /docs/framework/
            '/docs/FRAMEWORK-GUIDE.md' => '/docs/framework/FRAMEWORK-GUIDE.md',
            '/docs/UNIVERSAL-TESTING-GUIDE.md' => '/docs/guides/UNIVERSAL-TESTING-GUIDE.md',
            '/docs/TESTING-GUIDE.md' => '/docs/guides/TESTING-GUIDE.md',
            '/docs/report-organization-guide.md' => '/docs/guides/REPORT-ORGANIZATION.md',
            
            // Root files that should be in docs
            '/FRAMEWORK-STRUCTURE.md' => '/docs/architecture/FRAMEWORK-STRUCTURE.md',
            '/MASTER-INDEX.md' => '/docs/MASTER-INDEX.md',
            '/QUICK-START.md' => '/docs/QUICK-START.md',
            '/README.md' => '/README.md', // Keep in root
            
            // Cleanup and archive docs
            '/FILE-INDEX.md' => '/docs/architecture/FILE-INDEX.md',
            '/RESTRUCTURE-REPORT.md' => '/docs/architecture/RESTRUCTURE-REPORT.md',
            '/SCAN-SUMMARY.md' => '/docs/architecture/SCAN-SUMMARY.md',
        ];
        
        $this->moveFiles($moves);
    }
    
    private function moveBuddyPressDocs() {
        echo "📘 Organizing BuddyPress documentation...\n";
        
        $moves = [
            // BuddyPress docs that are in wrong places
            '/docs/BUDDYPRESS-COMPONENT-TESTING.md' => '/plugins/buddypress/docs/COMPONENT-TESTING.md',
            '/docs/COMPREHENSIVE-TEST-COVERAGE.md' => '/plugins/buddypress/docs/TEST-COVERAGE.md',
            '/BUDDYPRESS-COMPLETE-TESTING-SUMMARY.md' => '/plugins/buddypress/docs/TESTING-SUMMARY.md',
            '/BUDDYPRESS-REMAINING-COMMANDS.md' => '/plugins/buddypress/docs/REMAINING-COMMANDS.md',
            
            // Remove duplicates (keep the one in plugin folder)
            '/plugins/buddypress/docs/BUDDYPRESS-COMPLETE-TESTING-SUMMARY.md' => '/plugins/buddypress/docs/TESTING-SUMMARY-OLD.md',
            
            // Plan file
            '/docs/plan.md' => '/plugins/buddypress/docs/INITIAL-PLAN.md',
        ];
        
        $this->moveFiles($moves);
    }
    
    private function cleanupRootDocs() {
        echo "🧹 Cleaning up root directory documentation...\n";
        
        // These files should not be in root
        $rootDocs = glob($this->baseDir . '/*.md');
        
        foreach ($rootDocs as $file) {
            $filename = basename($file);
            
            // Skip README.md - it should stay in root
            if ($filename === 'README.md') {
                continue;
            }
            
            // Determine destination based on content
            if (strpos($filename, 'BUDDYPRESS') !== false || strpos($filename, 'BP-') !== false) {
                $dest = '/plugins/buddypress/docs/' . $filename;
            } elseif (strpos($filename, 'FRAMEWORK') !== false || strpos($filename, 'STRUCTURE') !== false) {
                $dest = '/docs/architecture/' . $filename;
            } else {
                $dest = '/docs/guides/' . $filename;
            }
            
            if (!file_exists($this->baseDir . $dest)) {
                $this->changes[] = [
                    'action' => 'move',
                    'from' => str_replace($this->baseDir, '', $file),
                    'to' => $dest
                ];
                echo "  📄 Moving: $filename → $dest\n";
            }
        }
        echo "\n";
    }
    
    private function moveFiles($moves) {
        foreach ($moves as $from => $to) {
            $source = $this->baseDir . $from;
            $dest = $this->baseDir . $to;
            
            if (file_exists($source)) {
                // Create destination directory if needed
                $destDir = dirname($dest);
                if (!is_dir($destDir)) {
                    mkdir($destDir, 0755, true);
                }
                
                // Check if destination already exists
                if (file_exists($dest)) {
                    echo "  ⚠️  Skipping (destination exists): $from\n";
                    continue;
                }
                
                // Move the file
                if (rename($source, $dest)) {
                    $this->changes[] = [
                        'action' => 'moved',
                        'from' => $from,
                        'to' => $to
                    ];
                    echo "  ✅ Moved: $from → $to\n";
                } else {
                    echo "  ❌ Failed to move: $from\n";
                }
            }
        }
        echo "\n";
    }
    
    private function createMasterDocsIndex() {
        echo "📚 Creating master documentation index...\n";
        
        $index = "# WP Testing Framework - Documentation Index\n\n";
        $index .= "## 📁 Documentation Structure\n\n";
        $index .= "```\n";
        $index .= "docs/\n";
        $index .= "├── README.md                  # This index\n";
        $index .= "├── QUICK-START.md            # 5-minute quick start\n";
        $index .= "├── MASTER-INDEX.md           # Complete framework index\n";
        $index .= "├── framework/                # Framework documentation\n";
        $index .= "│   └── FRAMEWORK-GUIDE.md    # Core framework guide\n";
        $index .= "├── architecture/             # Architecture & design\n";
        $index .= "│   ├── FRAMEWORK-STRUCTURE.md\n";
        $index .= "│   ├── FILE-INDEX.md\n";
        $index .= "│   ├── RESTRUCTURE-REPORT.md\n";
        $index .= "│   └── SCAN-SUMMARY.md\n";
        $index .= "├── guides/                   # User guides\n";
        $index .= "│   ├── UNIVERSAL-TESTING-GUIDE.md\n";
        $index .= "│   ├── TESTING-GUIDE.md\n";
        $index .= "│   └── REPORT-ORGANIZATION.md\n";
        $index .= "└── api/                      # API documentation\n";
        $index .= "```\n\n";
        
        $index .= "## 🔌 Plugin Documentation\n\n";
        $index .= "Each plugin has its own documentation:\n\n";
        $index .= "```\n";
        $index .= "plugins/\n";
        $index .= "└── [plugin-name]/\n";
        $index .= "    └── docs/\n";
        $index .= "        ├── README.md         # Plugin test overview\n";
        $index .= "        ├── TESTING-GUIDE.md  # How to test this plugin\n";
        $index .= "        └── ...\n";
        $index .= "```\n\n";
        
        $index .= "### BuddyPress Documentation\n\n";
        $index .= "Complete example implementation:\n\n";
        $index .= "- [BuddyPress Testing Guide](/plugins/buddypress/docs/TESTING-GUIDE.md)\n";
        $index .= "- [Component Testing](/plugins/buddypress/docs/COMPONENT-TESTING.md)\n";
        $index .= "- [Test Coverage Report](/plugins/buddypress/docs/TEST-COVERAGE.md)\n";
        $index .= "- [Testing Summary](/plugins/buddypress/docs/TESTING-SUMMARY.md)\n\n";
        
        $index .= "## 📖 Quick Links\n\n";
        $index .= "### Getting Started\n";
        $index .= "1. [Quick Start Guide](QUICK-START.md) - Test any plugin in 5 minutes\n";
        $index .= "2. [Framework Guide](framework/FRAMEWORK-GUIDE.md) - Understanding the framework\n";
        $index .= "3. [Universal Testing](guides/UNIVERSAL-TESTING-GUIDE.md) - Testing methodology\n\n";
        
        $index .= "### Architecture\n";
        $index .= "1. [Framework Structure](architecture/FRAMEWORK-STRUCTURE.md) - Directory layout\n";
        $index .= "2. [File Index](architecture/FILE-INDEX.md) - Complete file listing\n";
        $index .= "3. [Master Index](MASTER-INDEX.md) - Everything about the framework\n\n";
        
        $index .= "### For Developers\n";
        $index .= "1. [Testing Guide](guides/TESTING-GUIDE.md) - How to write tests\n";
        $index .= "2. [Report Organization](guides/REPORT-ORGANIZATION.md) - Report structure\n";
        $index .= "3. [Plugin Template](/templates/plugin-skeleton/docs/README.md) - Starting template\n\n";
        
        $index .= "## 🎯 Documentation Standards\n\n";
        $index .= "### Framework Documentation\n";
        $index .= "- Location: `/docs/`\n";
        $index .= "- Purpose: Universal framework documentation\n";
        $index .= "- Audience: All users\n\n";
        
        $index .= "### Plugin Documentation\n";
        $index .= "- Location: `/plugins/[plugin-name]/docs/`\n";
        $index .= "- Purpose: Plugin-specific guides and reports\n";
        $index .= "- Audience: Plugin testers\n\n";
        
        $index .= "### Report Files\n";
        $index .= "- Location: `/reports/[plugin-name]/`\n";
        $index .= "- Purpose: Generated test reports\n";
        $index .= "- Format: Markdown and JSON\n\n";
        
        $index .= "---\n\n";
        $index .= "*Documentation organized for 100+ plugin scalability*\n";
        
        file_put_contents($this->baseDir . '/docs/README.md', $index);
        echo "  ✅ Created master documentation index\n\n";
    }
    
    private function reportChanges() {
        echo "📊 Documentation Reorganization Summary\n";
        echo "========================================\n\n";
        
        if (empty($this->changes)) {
            echo "No changes were needed - documentation is already organized!\n";
            return;
        }
        
        $moveCount = 0;
        foreach ($this->changes as $change) {
            if ($change['action'] === 'moved') {
                $moveCount++;
            }
        }
        
        echo "Total files reorganized: $moveCount\n\n";
        
        echo "Changes made:\n";
        foreach ($this->changes as $change) {
            echo "  - {$change['from']} → {$change['to']}\n";
        }
        
        echo "\n✅ Documentation reorganization complete!\n";
        echo "\nNew structure:\n";
        echo "  /docs/              - Framework documentation\n";
        echo "  /docs/framework/    - Core framework guides\n";
        echo "  /docs/architecture/ - Architecture docs\n";
        echo "  /docs/guides/       - User guides\n";
        echo "  /plugins/*/docs/    - Plugin-specific docs\n";
    }
}

// Run the reorganization
$reorganizer = new DocsReorganizer(__DIR__);
$reorganizer->reorganize();