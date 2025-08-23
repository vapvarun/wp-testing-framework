<?php
/**
 * Universal UX Compliance Scanner
 * 
 * Scans ANY WordPress plugin for responsive and accessibility compliance
 * Generates reports for AI analysis and manual review
 */

namespace WPTestingFramework\Scanners;

class UXComplianceScanner {
    
    private $pluginSlug;
    private $pluginPath;
    private $results = [];
    
    /**
     * Scan any WordPress plugin for UX compliance
     */
    public function scanPlugin($pluginSlug) {
        $this->pluginSlug = $pluginSlug;
        $this->pluginPath = WP_PLUGIN_DIR . '/' . $pluginSlug;
        
        if (!is_dir($this->pluginPath)) {
            return [
                'error' => "Plugin not found: {$pluginSlug}",
                'path' => $this->pluginPath
            ];
        }
        
        echo "🔍 Scanning {$pluginSlug} for UX compliance...\n";
        
        // Run all scans
        $this->results = [
            'plugin' => $pluginSlug,
            'timestamp' => date('Y-m-d H:i:s'),
            'responsive' => $this->scanResponsive(),
            'accessibility' => $this->scanAccessibility(),
            'files' => $this->analyzeFileStructure(),
            'score' => 0,
            'issues' => [],
            'recommendations' => []
        ];
        
        // Calculate overall score
        $this->calculateScore();
        
        // Generate recommendations
        $this->generateRecommendations();
        
        // Save results
        $this->saveResults();
        
        return $this->results;
    }
    
    /**
     * Scan for responsive design patterns
     */
    private function scanResponsive() {
        $responsive = [
            'breakpoints' => $this->findBreakpoints(),
            'viewport' => $this->findViewportMeta(),
            'flexible_images' => $this->findFlexibleImages(),
            'responsive_tables' => $this->findResponsiveTables(),
            'touch_friendly' => $this->findTouchElements(),
            'mobile_menus' => $this->findMobileMenus()
        ];
        
        $responsive['score'] = $this->calculateCategoryScore($responsive);
        return $responsive;
    }
    
    /**
     * Scan for accessibility compliance
     */
    private function scanAccessibility() {
        $accessibility = [
            'alt_text' => $this->analyzeAltText(),
            'aria_labels' => $this->findAriaLabels(),
            'semantic_html' => $this->analyzeSemanticHTML(),
            'focus_management' => $this->analyzeFocusManagement(),
            'keyboard_support' => $this->analyzeKeyboardSupport(),
            'screen_reader' => $this->analyzeScreenReaderSupport(),
            'color_contrast' => $this->analyzeColorContrast(),
            'form_labels' => $this->analyzeFormLabels()
        ];
        
        $accessibility['score'] = $this->calculateCategoryScore($accessibility);
        return $accessibility;
    }
    
    /**
     * Find responsive breakpoints in CSS
     */
    private function findBreakpoints() {
        $cssFiles = $this->findFiles('*.css');
        $breakpoints = [];
        $count = 0;
        
        foreach ($cssFiles as $file) {
            $content = file_get_contents($file);
            
            // Common breakpoint patterns
            preg_match_all('/@media[^{]+\(([^)]+)\)/i', $content, $matches);
            
            foreach ($matches[1] as $media) {
                if (preg_match('/\d+px/', $media)) {
                    $breakpoints[] = $media;
                    $count++;
                }
            }
        }
        
        return [
            'found' => $count,
            'breakpoints' => array_unique($breakpoints),
            'score' => min(100, $count * 20), // 5+ breakpoints = 100%
            'status' => $count >= 3 ? 'pass' : ($count > 0 ? 'warning' : 'fail')
        ];
    }
    
    /**
     * Find viewport meta tags
     */
    private function findViewportMeta() {
        $templates = $this->findFiles('*.php');
        $found = false;
        
        foreach ($templates as $template) {
            $content = file_get_contents($template);
            
            if (stripos($content, 'viewport') !== false && 
                stripos($content, 'width=device-width') !== false) {
                $found = true;
                break;
            }
            
            // Also check if using wp_head properly
            if (stripos($content, 'wp_head()') !== false) {
                $found = true;
                break;
            }
        }
        
        return [
            'found' => $found,
            'score' => $found ? 100 : 0,
            'status' => $found ? 'pass' : 'fail'
        ];
    }
    
    /**
     * Find flexible/responsive images
     */
    private function findFlexibleImages() {
        $templates = $this->findFiles('*.php');
        $total = 0;
        $responsive = 0;
        
        foreach ($templates as $template) {
            $content = file_get_contents($template);
            preg_match_all('/<img[^>]+>/i', $content, $images);
            
            foreach ($images[0] as $img) {
                $total++;
                
                if (stripos($img, 'srcset') !== false ||
                    stripos($img, 'sizes') !== false ||
                    stripos($img, 'wp-image') !== false ||
                    stripos($img, 'width="100%"') !== false) {
                    $responsive++;
                }
            }
        }
        
        $percentage = $total > 0 ? ($responsive / $total) * 100 : 100;
        
        return [
            'total' => $total,
            'responsive' => $responsive,
            'percentage' => round($percentage),
            'score' => round($percentage),
            'status' => $percentage >= 70 ? 'pass' : ($percentage >= 40 ? 'warning' : 'fail')
        ];
    }
    
    /**
     * Find responsive table implementations
     */
    private function findResponsiveTables() {
        $templates = $this->findFiles('*.php');
        $tables = 0;
        $responsive = 0;
        
        foreach ($templates as $template) {
            $content = file_get_contents($template);
            
            if (stripos($content, '<table') !== false) {
                $tables++;
                
                if (stripos($content, 'table-responsive') !== false ||
                    stripos($content, 'responsive-table') !== false ||
                    stripos($content, 'overflow-x') !== false) {
                    $responsive++;
                }
            }
        }
        
        if ($tables === 0) {
            return ['found' => 0, 'score' => 100, 'status' => 'pass'];
        }
        
        $percentage = ($responsive / $tables) * 100;
        
        return [
            'total' => $tables,
            'responsive' => $responsive,
            'percentage' => round($percentage),
            'score' => round($percentage),
            'status' => $percentage >= 70 ? 'pass' : 'warning'
        ];
    }
    
    /**
     * Find touch-friendly elements
     */
    private function findTouchElements() {
        $cssFiles = $this->findFiles('*.css');
        $touchFriendly = 0;
        
        foreach ($cssFiles as $file) {
            $content = file_get_contents($file);
            
            // Look for touch-friendly sizes
            if (preg_match('/min-height:\s*4[4-9]px/i', $content) ||
                preg_match('/min-width:\s*4[4-9]px/i', $content) ||
                preg_match('/padding:\s*1[5-9]px/i', $content) ||
                stripos($content, 'touch-action') !== false) {
                $touchFriendly++;
            }
        }
        
        return [
            'found' => $touchFriendly,
            'score' => min(100, $touchFriendly * 25),
            'status' => $touchFriendly > 0 ? 'pass' : 'warning'
        ];
    }
    
    /**
     * Find mobile menu implementations
     */
    private function findMobileMenus() {
        $files = array_merge($this->findFiles('*.js'), $this->findFiles('*.php'));
        $mobileMenu = false;
        
        $patterns = ['mobile-menu', 'hamburger', 'toggle-menu', 'nav-toggle', 'menu-toggle'];
        
        foreach ($files as $file) {
            $content = file_get_contents($file);
            
            foreach ($patterns as $pattern) {
                if (stripos($content, $pattern) !== false) {
                    $mobileMenu = true;
                    break 2;
                }
            }
        }
        
        return [
            'found' => $mobileMenu,
            'score' => $mobileMenu ? 100 : 50,
            'status' => $mobileMenu ? 'pass' : 'warning'
        ];
    }
    
    /**
     * Analyze alt text usage
     */
    private function analyzeAltText() {
        $templates = $this->findFiles('*.php');
        $total = 0;
        $withAlt = 0;
        
        foreach ($templates as $template) {
            $content = file_get_contents($template);
            preg_match_all('/<img[^>]+>/i', $content, $images);
            
            foreach ($images[0] as $img) {
                $total++;
                if (stripos($img, 'alt=') !== false) {
                    $withAlt++;
                }
            }
        }
        
        $percentage = $total > 0 ? ($withAlt / $total) * 100 : 100;
        
        return [
            'total' => $total,
            'with_alt' => $withAlt,
            'percentage' => round($percentage),
            'score' => round($percentage),
            'status' => $percentage >= 90 ? 'pass' : ($percentage >= 70 ? 'warning' : 'fail')
        ];
    }
    
    /**
     * Find ARIA labels and attributes
     */
    private function findAriaLabels() {
        $files = $this->findFiles('*.php');
        $ariaCount = 0;
        
        $ariaAttributes = [
            'aria-label', 'aria-labelledby', 'aria-describedby',
            'aria-live', 'aria-hidden', 'role='
        ];
        
        foreach ($files as $file) {
            $content = file_get_contents($file);
            
            foreach ($ariaAttributes as $attr) {
                $ariaCount += substr_count($content, $attr);
            }
        }
        
        return [
            'found' => $ariaCount,
            'score' => min(100, $ariaCount * 5),
            'status' => $ariaCount > 10 ? 'pass' : ($ariaCount > 0 ? 'warning' : 'fail')
        ];
    }
    
    /**
     * Analyze semantic HTML usage
     */
    private function analyzeSemanticHTML() {
        $templates = $this->findFiles('*.php');
        $semanticCount = 0;
        
        $semanticTags = [
            '<nav', '<main', '<header', '<footer', '<aside',
            '<article', '<section', '<figure', '<figcaption'
        ];
        
        foreach ($templates as $template) {
            $content = file_get_contents($template);
            
            foreach ($semanticTags as $tag) {
                if (stripos($content, $tag) !== false) {
                    $semanticCount++;
                }
            }
        }
        
        return [
            'found' => $semanticCount,
            'score' => min(100, $semanticCount * 10),
            'status' => $semanticCount > 5 ? 'pass' : ($semanticCount > 0 ? 'warning' : 'fail')
        ];
    }
    
    /**
     * Analyze focus management
     */
    private function analyzeFocusManagement() {
        $cssFiles = $this->findFiles('*.css');
        $focusRules = 0;
        
        foreach ($cssFiles as $file) {
            $content = file_get_contents($file);
            $focusRules += substr_count($content, ':focus');
            $focusRules += substr_count($content, ':focus-visible');
            $focusRules += substr_count($content, ':focus-within');
        }
        
        return [
            'found' => $focusRules,
            'score' => min(100, $focusRules * 10),
            'status' => $focusRules > 5 ? 'pass' : ($focusRules > 0 ? 'warning' : 'fail')
        ];
    }
    
    /**
     * Analyze keyboard support
     */
    private function analyzeKeyboardSupport() {
        $jsFiles = $this->findFiles('*.js');
        $keyboardSupport = 0;
        
        $patterns = ['keydown', 'keyup', 'keypress', 'tabindex', 'event.key'];
        
        foreach ($jsFiles as $file) {
            $content = file_get_contents($file);
            
            foreach ($patterns as $pattern) {
                if (stripos($content, $pattern) !== false) {
                    $keyboardSupport++;
                }
            }
        }
        
        return [
            'found' => $keyboardSupport,
            'score' => min(100, $keyboardSupport * 20),
            'status' => $keyboardSupport > 3 ? 'pass' : ($keyboardSupport > 0 ? 'warning' : 'fail')
        ];
    }
    
    /**
     * Analyze screen reader support
     */
    private function analyzeScreenReaderSupport() {
        $files = array_merge($this->findFiles('*.php'), $this->findFiles('*.css'));
        $srSupport = 0;
        
        $patterns = [
            'screen-reader-text', 'sr-only', 'visually-hidden',
            'aria-live', 'role="alert"', 'role="status"'
        ];
        
        foreach ($files as $file) {
            $content = file_get_contents($file);
            
            foreach ($patterns as $pattern) {
                if (stripos($content, $pattern) !== false) {
                    $srSupport++;
                    break;
                }
            }
        }
        
        return [
            'found' => $srSupport,
            'score' => min(100, $srSupport * 15),
            'status' => $srSupport > 3 ? 'pass' : ($srSupport > 0 ? 'warning' : 'fail')
        ];
    }
    
    /**
     * Analyze color contrast (basic check)
     */
    private function analyzeColorContrast() {
        $cssFiles = $this->findFiles('*.css');
        $potentialIssues = 0;
        
        // Common low-contrast color combinations
        $lowContrastColors = ['#ccc', '#ddd', '#eee', '#999', '#aaa', '#bbb'];
        
        foreach ($cssFiles as $file) {
            $content = file_get_contents($file);
            
            foreach ($lowContrastColors as $color) {
                if (stripos($content, $color) !== false) {
                    $potentialIssues++;
                }
            }
        }
        
        $score = max(0, 100 - ($potentialIssues * 10));
        
        return [
            'potential_issues' => $potentialIssues,
            'score' => $score,
            'status' => $potentialIssues < 3 ? 'pass' : ($potentialIssues < 6 ? 'warning' : 'fail')
        ];
    }
    
    /**
     * Analyze form labels
     */
    private function analyzeFormLabels() {
        $templates = $this->findFiles('*.php');
        $inputs = 0;
        $labeled = 0;
        
        foreach ($templates as $template) {
            $content = file_get_contents($template);
            
            // Find inputs
            preg_match_all('/<input[^>]+type=["\'](?!hidden|submit)[^"\']+/i', $content, $matches);
            $inputs += count($matches[0]);
            
            // Find labels
            $labeled += substr_count($content, '<label');
            $labeled += substr_count($content, 'aria-label');
        }
        
        $percentage = $inputs > 0 ? min(100, ($labeled / $inputs) * 100) : 100;
        
        return [
            'inputs' => $inputs,
            'labeled' => $labeled,
            'percentage' => round($percentage),
            'score' => round($percentage),
            'status' => $percentage >= 80 ? 'pass' : ($percentage >= 60 ? 'warning' : 'fail')
        ];
    }
    
    /**
     * Analyze file structure
     */
    private function analyzeFileStructure() {
        return [
            'php_files' => count($this->findFiles('*.php')),
            'css_files' => count($this->findFiles('*.css')),
            'js_files' => count($this->findFiles('*.js')),
            'template_files' => count($this->findFiles('*template*.php')),
            'total_size' => $this->getDirectorySize($this->pluginPath)
        ];
    }
    
    /**
     * Calculate overall score
     */
    private function calculateScore() {
        $responsiveScore = $this->results['responsive']['score'] ?? 0;
        $accessibilityScore = $this->results['accessibility']['score'] ?? 0;
        
        $this->results['score'] = round(($responsiveScore + $accessibilityScore) / 2);
        
        // Determine compliance level
        if ($this->results['score'] >= 90) {
            $this->results['compliance_level'] = 'AAA - Excellent';
        } elseif ($this->results['score'] >= 75) {
            $this->results['compliance_level'] = 'AA - Good (WCAG Compliant)';
        } elseif ($this->results['score'] >= 60) {
            $this->results['compliance_level'] = 'A - Basic';
        } else {
            $this->results['compliance_level'] = 'Needs Improvement';
        }
        
        // Collect issues
        $this->collectIssues();
    }
    
    /**
     * Calculate category score
     */
    private function calculateCategoryScore($category) {
        $scores = [];
        
        foreach ($category as $key => $test) {
            if (isset($test['score'])) {
                $scores[] = $test['score'];
            }
        }
        
        return !empty($scores) ? round(array_sum($scores) / count($scores)) : 0;
    }
    
    /**
     * Collect issues from test results
     */
    private function collectIssues() {
        $this->results['issues'] = [];
        
        // Check responsive issues
        foreach ($this->results['responsive'] as $key => $test) {
            if (isset($test['status']) && $test['status'] === 'fail') {
                $this->results['issues'][] = [
                    'type' => 'responsive',
                    'area' => $key,
                    'severity' => 'high',
                    'message' => "Failed responsive check: {$key}"
                ];
            }
        }
        
        // Check accessibility issues
        foreach ($this->results['accessibility'] as $key => $test) {
            if (isset($test['status']) && $test['status'] === 'fail') {
                $this->results['issues'][] = [
                    'type' => 'accessibility',
                    'area' => $key,
                    'severity' => 'high',
                    'message' => "Failed accessibility check: {$key}"
                ];
            }
        }
    }
    
    /**
     * Generate recommendations
     */
    private function generateRecommendations() {
        $recommendations = [];
        
        // Responsive recommendations
        if ($this->results['responsive']['breakpoints']['found'] < 3) {
            $recommendations[] = [
                'priority' => 'high',
                'category' => 'responsive',
                'action' => 'Add responsive breakpoints for mobile (480px) and tablet (768px)'
            ];
        }
        
        if (!$this->results['responsive']['viewport']['found']) {
            $recommendations[] = [
                'priority' => 'critical',
                'category' => 'responsive',
                'action' => 'Add viewport meta tag for mobile compatibility'
            ];
        }
        
        // Accessibility recommendations
        if ($this->results['accessibility']['alt_text']['percentage'] < 90) {
            $recommendations[] = [
                'priority' => 'high',
                'category' => 'accessibility',
                'action' => 'Add alt text to all images for screen readers'
            ];
        }
        
        if ($this->results['accessibility']['focus_management']['found'] < 5) {
            $recommendations[] = [
                'priority' => 'medium',
                'category' => 'accessibility',
                'action' => 'Add :focus styles for keyboard navigation'
            ];
        }
        
        $this->results['recommendations'] = $recommendations;
    }
    
    /**
     * Save scan results
     */
    private function saveResults() {
        $outputDir = WP_CONTENT_DIR . "/uploads/wbcom-scan/{$this->pluginSlug}";
        
        if (!is_dir($outputDir)) {
            mkdir($outputDir, 0755, true);
        }
        
        $filename = $outputDir . '/ux-compliance-' . date('Y-m-d-His') . '.json';
        file_put_contents($filename, json_encode($this->results, JSON_PRETTY_PRINT));
        
        echo "✅ UX Compliance report saved: {$filename}\n";
        echo "📊 Overall Score: {$this->results['score']}% ({$this->results['compliance_level']})\n";
    }
    
    /**
     * Find files by pattern
     */
    private function findFiles($pattern) {
        $files = [];
        $iterator = new \RecursiveIteratorIterator(
            new \RecursiveDirectoryIterator($this->pluginPath, \RecursiveDirectoryIterator::SKIP_DOTS)
        );
        
        foreach ($iterator as $file) {
            if ($file->isFile() && fnmatch($pattern, $file->getFilename())) {
                $files[] = $file->getPathname();
            }
        }
        
        return $files;
    }
    
    /**
     * Get directory size
     */
    private function getDirectorySize($dir) {
        $size = 0;
        $iterator = new \RecursiveIteratorIterator(
            new \RecursiveDirectoryIterator($dir, \RecursiveDirectoryIterator::SKIP_DOTS)
        );
        
        foreach ($iterator as $file) {
            $size += $file->getSize();
        }
        
        return $this->formatBytes($size);
    }
    
    /**
     * Format bytes to human readable
     */
    private function formatBytes($bytes, $precision = 2) {
        $units = ['B', 'KB', 'MB', 'GB'];
        
        for ($i = 0; $bytes > 1024 && $i < count($units) - 1; $i++) {
            $bytes /= 1024;
        }
        
        return round($bytes, $precision) . ' ' . $units[$i];
    }
}