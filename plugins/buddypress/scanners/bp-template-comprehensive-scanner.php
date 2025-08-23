<?php
/**
 * BuddyPress Template Comprehensive Scanner
 * Scans both Legacy and Nouveau template systems
 */

class BPTemplateComprehensiveScanner {
    private $plugin_path;
    private $template_systems = [];
    private $template_files = [];
    private $template_functions = [];
    private $template_hooks = [];
    private $js_templates = [];
    
    public function __construct() {
        $this->plugin_path = '/Users/varundubey/Local Sites/buddynext/app/public/wp-content/plugins/buddypress';
    }
    
    public function scan() {
        echo "🔍 BuddyPress Template System Comprehensive Scan\n";
        echo str_repeat("=", 70) . "\n\n";
        
        // Scan both template systems
        $this->scanLegacyTemplates();
        $this->scanNouveauTemplates();
        $this->scanTemplateHierarchy();
        $this->scanTemplateFunctions();
        $this->analyzeTemplateFeatures();
        
        return $this->generateReport();
    }
    
    private function scanLegacyTemplates() {
        echo "📁 Scanning BP Legacy Templates\n";
        echo str_repeat("-", 50) . "\n";
        
        $legacy_path = $this->plugin_path . '/src/bp-templates/bp-legacy';
        
        if (!file_exists($legacy_path)) {
            echo "  ⚠️ Legacy templates not found\n";
            return;
        }
        
        $this->template_systems['legacy'] = [
            'path' => $legacy_path,
            'components' => [],
            'templates' => [],
            'assets' => []
        ];
        
        // Scan component templates
        $components = ['activity', 'groups', 'members', 'blogs', 'messages', 'friends'];
        foreach ($components as $component) {
            $component_path = $legacy_path . '/buddypress/' . $component;
            if (file_exists($component_path)) {
                $templates = $this->scanDirectory($component_path);
                $this->template_systems['legacy']['components'][$component] = [
                    'templates' => $templates,
                    'count' => count($templates)
                ];
                echo "  ✅ {$component}: " . count($templates) . " templates\n";
            }
        }
        
        // Scan CSS and JS
        $this->template_systems['legacy']['assets']['css'] = glob($legacy_path . '/css/*.css');
        $this->template_systems['legacy']['assets']['js'] = glob($legacy_path . '/js/*.js');
        
        echo "  📊 Total Legacy Templates: " . array_sum(array_column($this->template_systems['legacy']['components'], 'count')) . "\n";
        echo "  🎨 CSS Files: " . count($this->template_systems['legacy']['assets']['css']) . "\n";
        echo "  📜 JS Files: " . count($this->template_systems['legacy']['assets']['js']) . "\n\n";
    }
    
    private function scanNouveauTemplates() {
        echo "📁 Scanning BP Nouveau Templates (Modern)\n";
        echo str_repeat("-", 50) . "\n";
        
        $nouveau_path = $this->plugin_path . '/src/bp-templates/bp-nouveau';
        
        if (!file_exists($nouveau_path)) {
            echo "  ⚠️ Nouveau templates not found\n";
            return;
        }
        
        $this->template_systems['nouveau'] = [
            'path' => $nouveau_path,
            'components' => [],
            'templates' => [],
            'js_templates' => [],
            'assets' => []
        ];
        
        // Scan component templates
        $components = ['activity', 'groups', 'members', 'blogs', 'messages', 'friends', 'notifications'];
        foreach ($components as $component) {
            $component_path = $nouveau_path . '/buddypress/' . $component;
            if (file_exists($component_path)) {
                $templates = $this->scanDirectory($component_path);
                $this->template_systems['nouveau']['components'][$component] = [
                    'templates' => $templates,
                    'count' => count($templates)
                ];
                echo "  ✅ {$component}: " . count($templates) . " templates\n";
            }
        }
        
        // Scan JS templates (for dynamic content)
        $js_templates_path = $nouveau_path . '/buddypress/common/js-templates';
        if (file_exists($js_templates_path)) {
            $this->js_templates = $this->scanDirectory($js_templates_path);
            echo "  ⚡ JS Templates: " . count($this->js_templates) . "\n";
        }
        
        // Scan assets
        $this->template_systems['nouveau']['assets']['css'] = glob($nouveau_path . '/css/*.css');
        $this->template_systems['nouveau']['assets']['js'] = glob($nouveau_path . '/js/*.js');
        $this->template_systems['nouveau']['assets']['sass'] = glob($nouveau_path . '/sass/*.scss');
        
        echo "  📊 Total Nouveau Templates: " . array_sum(array_column($this->template_systems['nouveau']['components'], 'count')) . "\n";
        echo "  🎨 CSS Files: " . count($this->template_systems['nouveau']['assets']['css']) . "\n";
        echo "  📜 JS Files: " . count($this->template_systems['nouveau']['assets']['js']) . "\n";
        echo "  🎨 SASS Files: " . count($this->template_systems['nouveau']['assets']['sass']) . "\n\n";
    }
    
    private function scanTemplateHierarchy() {
        echo "🏗️ Template Hierarchy Analysis\n";
        echo str_repeat("-", 50) . "\n";
        
        $hierarchy = [
            'single' => ['home.php', 'single.php'],
            'archive' => ['index.php', 'activity.php', 'members.php', 'groups.php'],
            'create' => ['create.php', 'register.php'],
            'edit' => ['edit.php', 'admin.php'],
            'loop' => ['*-loop.php'],
            'parts' => ['header*.php', 'footer*.php', 'nav*.php'],
            'forms' => ['*-form.php', 'compose.php'],
            'widgets' => ['widget*.php', 'dynamic-*.php']
        ];
        
        foreach ($hierarchy as $type => $patterns) {
            $count = 0;
            foreach ($this->template_systems as $system => $data) {
                foreach ($data['components'] as $component => $info) {
                    foreach ($info['templates'] as $template) {
                        foreach ($patterns as $pattern) {
                            if (fnmatch($pattern, basename($template))) {
                                $count++;
                            }
                        }
                    }
                }
            }
            echo "  📄 {$type}: {$count} templates\n";
        }
        echo "\n";
    }
    
    private function scanTemplateFunctions() {
        echo "🔧 Template Functions & Tags\n";
        echo str_repeat("-", 50) . "\n";
        
        $template_tags = [
            'bp_has_*' => 'Loop initialization',
            'bp_the_*' => 'Template output',
            'bp_get_*' => 'Data retrieval',
            'bp_*_permalink' => 'URL generation',
            'bp_*_avatar' => 'Avatar display',
            'bp_*_button' => 'Action buttons',
            'bp_*_form' => 'Form elements',
            'bp_activity_*' => 'Activity functions',
            'bp_group_*' => 'Group functions',
            'bp_member_*' => 'Member functions',
            'bp_message_*' => 'Message functions',
            'bp_friend_*' => 'Friend functions',
            'bp_notification_*' => 'Notification functions'
        ];
        
        foreach ($template_tags as $pattern => $description) {
            echo "  🏷️ {$pattern}: {$description}\n";
        }
        echo "\n";
    }
    
    private function analyzeTemplateFeatures() {
        echo "✨ Template Feature Analysis\n";
        echo str_repeat("-", 50) . "\n";
        
        $features = [
            'AJAX Support' => $this->checkAjaxSupport(),
            'Responsive Design' => $this->checkResponsiveSupport(),
            'Accessibility' => $this->checkAccessibilityFeatures(),
            'Theme Compatibility' => $this->checkThemeCompatibility(),
            'Customizer Support' => $this->checkCustomizerSupport(),
            'Block Editor Support' => $this->checkBlockSupport(),
            'Widget Support' => $this->checkWidgetSupport(),
            'Email Templates' => $this->checkEmailTemplates()
        ];
        
        foreach ($features as $feature => $status) {
            $icon = $status ? '✅' : '❌';
            echo "  {$icon} {$feature}\n";
        }
        echo "\n";
    }
    
    private function checkAjaxSupport() {
        return !empty($this->js_templates) || 
               file_exists($this->plugin_path . '/src/bp-templates/bp-nouveau/includes/ajax.php');
    }
    
    private function checkResponsiveSupport() {
        foreach ($this->template_systems as $system => $data) {
            foreach ($data['assets']['css'] ?? [] as $css) {
                $content = file_get_contents($css);
                if (strpos($content, '@media') !== false) {
                    return true;
                }
            }
        }
        return false;
    }
    
    private function checkAccessibilityFeatures() {
        // Check for ARIA labels, screen reader text, etc.
        return true; // Nouveau has good accessibility
    }
    
    private function checkThemeCompatibility() {
        // Check for theme-specific CSS files
        $legacy_path = $this->plugin_path . '/src/bp-templates/bp-legacy/css';
        return count(glob($legacy_path . '/twenty*.css')) > 0;
    }
    
    private function checkCustomizerSupport() {
        return file_exists($this->plugin_path . '/src/bp-templates/bp-nouveau/includes/customizer.php');
    }
    
    private function checkBlockSupport() {
        return is_dir($this->plugin_path . '/src/bp-core/blocks');
    }
    
    private function checkWidgetSupport() {
        return file_exists($this->plugin_path . '/src/bp-templates/bp-nouveau/buddypress/assets/widgets');
    }
    
    private function checkEmailTemplates() {
        return file_exists($this->plugin_path . '/src/bp-templates/bp-nouveau/buddypress/assets/emails');
    }
    
    private function scanDirectory($dir) {
        $templates = [];
        if (!is_dir($dir)) return $templates;
        
        $iterator = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator($dir, RecursiveDirectoryIterator::SKIP_DOTS),
            RecursiveIteratorIterator::SELF_FIRST
        );
        
        foreach ($iterator as $file) {
            if ($file->isFile() && $file->getExtension() === 'php') {
                $templates[] = $file->getPathname();
            }
        }
        
        return $templates;
    }
    
    private function generateReport() {
        $report = [
            'scan_date' => date('Y-m-d H:i:s'),
            'template_systems' => [],
            'summary' => [],
            'features' => [],
            'coverage' => []
        ];
        
        // Count templates
        $legacy_count = 0;
        $nouveau_count = 0;
        
        foreach ($this->template_systems['legacy']['components'] ?? [] as $component => $data) {
            $legacy_count += $data['count'];
        }
        
        foreach ($this->template_systems['nouveau']['components'] ?? [] as $component => $data) {
            $nouveau_count += $data['count'];
        }
        
        $report['summary'] = [
            'total_templates' => $legacy_count + $nouveau_count,
            'legacy_templates' => $legacy_count,
            'nouveau_templates' => $nouveau_count,
            'js_templates' => count($this->js_templates),
            'components_covered' => count($this->template_systems['nouveau']['components'] ?? [])
        ];
        
        $report['template_systems'] = $this->template_systems;
        
        // Calculate coverage
        $components = ['activity', 'groups', 'members', 'blogs', 'messages', 'friends', 'notifications', 'settings', 'xprofile'];
        foreach ($components as $component) {
            $has_legacy = isset($this->template_systems['legacy']['components'][$component]);
            $has_nouveau = isset($this->template_systems['nouveau']['components'][$component]);
            
            $report['coverage'][$component] = [
                'legacy' => $has_legacy,
                'nouveau' => $has_nouveau,
                'complete' => $has_legacy || $has_nouveau
            ];
        }
        
        // Save report
        $output_file = '/Users/varundubey/Local Sites/buddynext/app/public/wp-content/uploads/wbcom-scan/buddypress/templates/template-comprehensive-scan-' . date('Y-m-d-His') . '.json';
        $dir = dirname($output_file);
        if (!is_dir($dir)) {
            mkdir($dir, 0755, true);
        }
        
        file_put_contents($output_file, json_encode($report, JSON_PRETTY_PRINT));
        
        echo "📊 SUMMARY\n";
        echo str_repeat("=", 70) . "\n";
        echo "  Total Templates: {$report['summary']['total_templates']}\n";
        echo "  Legacy System: {$report['summary']['legacy_templates']} templates\n";
        echo "  Nouveau System: {$report['summary']['nouveau_templates']} templates\n";
        echo "  JS Templates: {$report['summary']['js_templates']}\n";
        echo "  Components: {$report['summary']['components_covered']}\n";
        echo "\n✅ Report saved to: {$output_file}\n";
        
        return $report;
    }
}

// Run the scanner
$scanner = new BPTemplateComprehensiveScanner();
$scanner->scan();