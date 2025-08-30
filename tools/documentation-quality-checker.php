<?php
/**
 * Documentation Quality Checker
 * Ensures generated documentation meets quality standards
 */

class DocumentationQualityChecker {
    
    private $minLineCount = [
        'USER-GUIDE.md' => 500,
        'ISSUES-AND-FIXES.md' => 400,
        'DEVELOPMENT-PLAN.md' => 600
    ];
    
    private $requiredSections = [
        'USER-GUIDE.md' => [
            'Installation',
            'Configuration',
            'Troubleshooting',
            'Performance',
            'Examples'
        ],
        'ISSUES-AND-FIXES.md' => [
            'Critical',
            'Security',
            'Performance',
            'Fix',
            'Time'
        ],
        'DEVELOPMENT-PLAN.md' => [
            'Phase',
            'Timeline',
            'Cost',
            'Resources',
            'Metrics'
        ]
    ];
    
    private $qualityMetrics = [];
    
    /**
     * Check documentation quality
     */
    public function checkQuality($filepath) {
        if (!file_exists($filepath)) {
            return ['error' => 'File not found'];
        }
        
        $filename = basename($filepath);
        $content = file_get_contents($filepath);
        $lines = explode("\n", $content);
        
        $score = 0;
        $maxScore = 100;
        $issues = [];
        $strengths = [];
        
        // Check line count
        $lineCount = count($lines);
        $minLines = $this->minLineCount[$filename] ?? 300;
        
        if ($lineCount >= $minLines) {
            $score += 20;
            $strengths[] = "Comprehensive content ($lineCount lines)";
        } else {
            $issues[] = "Too short: $lineCount lines (minimum: $minLines)";
        }
        
        // Check code examples
        $codeBlocks = substr_count($content, '```');
        $codeBlockPairs = floor($codeBlocks / 2);
        
        if ($codeBlockPairs >= 10) {
            $score += 25;
            $strengths[] = "Rich code examples ($codeBlockPairs blocks)";
        } elseif ($codeBlockPairs >= 5) {
            $score += 15;
            $strengths[] = "Good code examples ($codeBlockPairs blocks)";
        } else {
            $issues[] = "Insufficient code examples ($codeBlockPairs blocks, need 10+)";
        }
        
        // Check for required sections
        $requiredSections = $this->requiredSections[$filename] ?? [];
        $foundSections = 0;
        
        foreach ($requiredSections as $section) {
            if (stripos($content, $section) !== false) {
                $foundSections++;
            } else {
                $issues[] = "Missing section: $section";
            }
        }
        
        if ($foundSections == count($requiredSections)) {
            $score += 20;
            $strengths[] = "All required sections present";
        } else {
            $score += ($foundSections / count($requiredSections)) * 20;
        }
        
        // Check for specific, actionable content
        $specificityMarkers = [
            'line \d+',           // Line numbers
            'file:',              // File references
            '\$[\d,]+',          // Cost estimates
            '\d+ hours?',        // Time estimates
            '\d+%',              // Percentages
            '\d+ms',             // Performance metrics
            'Location:',         // Specific locations
            'Fix:',              // Solutions
            'Example:',          // Examples
            'Step \d+'           // Step-by-step guides
        ];
        
        $specificityCount = 0;
        foreach ($specificityMarkers as $marker) {
            if (preg_match_all("/$marker/i", $content, $matches)) {
                $specificityCount += count($matches[0]);
            }
        }
        
        if ($specificityCount >= 20) {
            $score += 25;
            $strengths[] = "Highly specific content ($specificityCount specific references)";
        } elseif ($specificityCount >= 10) {
            $score += 15;
            $strengths[] = "Good specificity ($specificityCount specific references)";
        } else {
            $issues[] = "Too generic ($specificityCount specific references, need 20+)";
        }
        
        // Check for real metrics
        $hasMetrics = false;
        if (preg_match_all('/\d+\.\d+[ms|s|MB|KB|%]/', $content, $matches)) {
            $hasMetrics = true;
            $score += 10;
            $strengths[] = "Contains real metrics";
        } else {
            $issues[] = "No performance metrics found";
        }
        
        // Calculate final grade
        $grade = $this->calculateGrade($score);
        
        return [
            'filename' => $filename,
            'score' => $score,
            'maxScore' => $maxScore,
            'grade' => $grade,
            'lineCount' => $lineCount,
            'codeBlocks' => $codeBlockPairs,
            'specificityCount' => $specificityCount,
            'strengths' => $strengths,
            'issues' => $issues,
            'recommendation' => $this->getRecommendation($score)
        ];
    }
    
    /**
     * Calculate letter grade
     */
    private function calculateGrade($score) {
        if ($score >= 90) return 'A';
        if ($score >= 80) return 'B';
        if ($score >= 70) return 'C';
        if ($score >= 60) return 'D';
        return 'F';
    }
    
    /**
     * Get recommendation based on score
     */
    private function getRecommendation($score) {
        if ($score >= 85) {
            return "Excellent documentation! Production ready.";
        } elseif ($score >= 70) {
            return "Good documentation with minor improvements needed.";
        } elseif ($score >= 55) {
            return "Acceptable but needs significant enhancement.";
        } else {
            return "Poor quality - requires major rewrite with specific examples.";
        }
    }
    
    /**
     * Enhance documentation automatically
     */
    public function enhanceDocumentation($filepath, $scanData) {
        $content = file_get_contents($filepath);
        $enhanced = $content;
        
        // Add real examples from scan data
        if (!empty($scanData['hooks'])) {
            $hookExamples = "## Real Hook Examples\n```php\n";
            foreach (array_slice($scanData['hooks'], 0, 5) as $hook) {
                $hookExamples .= $hook . "\n";
            }
            $hookExamples .= "```\n";
            $enhanced = str_replace('## Examples', "## Examples\n\n$hookExamples", $enhanced);
        }
        
        // Add performance metrics
        if (!empty($scanData['metrics'])) {
            $metricsTable = "\n## Performance Metrics\n";
            $metricsTable .= "| Metric | Value | Impact |\n";
            $metricsTable .= "|--------|-------|--------|\n";
            foreach ($scanData['metrics'] as $metric => $value) {
                $metricsTable .= "| $metric | $value | Measured |\n";
            }
            $enhanced .= $metricsTable;
        }
        
        // Add specific file references
        if (!empty($scanData['issues'])) {
            $issuesSection = "\n## Specific Issues Found\n";
            foreach ($scanData['issues'] as $issue) {
                $issuesSection .= "- **{$issue['type']}**: {$issue['file']}:{$issue['line']}\n";
                $issuesSection .= "  - Fix: {$issue['fix']}\n";
                $issuesSection .= "  - Time: {$issue['time']} hours\n";
            }
            $enhanced .= $issuesSection;
        }
        
        return $enhanced;
    }
    
    /**
     * Generate quality report
     */
    public function generateReport($results) {
        $report = "# Documentation Quality Report\n\n";
        $report .= "Generated: " . date('Y-m-d H:i:s') . "\n\n";
        
        $totalScore = 0;
        $totalMax = 0;
        
        foreach ($results as $result) {
            $report .= "## {$result['filename']}\n";
            $report .= "- **Score**: {$result['score']}/{$result['maxScore']} ({$result['grade']})\n";
            $report .= "- **Lines**: {$result['lineCount']}\n";
            $report .= "- **Code Blocks**: {$result['codeBlocks']}\n";
            $report .= "- **Specificity**: {$result['specificityCount']} references\n\n";
            
            if (!empty($result['strengths'])) {
                $report .= "### Strengths\n";
                foreach ($result['strengths'] as $strength) {
                    $report .= "- ✅ $strength\n";
                }
                $report .= "\n";
            }
            
            if (!empty($result['issues'])) {
                $report .= "### Issues\n";
                foreach ($result['issues'] as $issue) {
                    $report .= "- ⚠️ $issue\n";
                }
                $report .= "\n";
            }
            
            $report .= "**Recommendation**: {$result['recommendation']}\n\n";
            $report .= "---\n\n";
            
            $totalScore += $result['score'];
            $totalMax += $result['maxScore'];
        }
        
        // Overall summary
        $overallScore = round(($totalScore / $totalMax) * 100);
        $overallGrade = $this->calculateGrade($overallScore);
        
        $report .= "## Overall Summary\n";
        $report .= "- **Total Score**: $overallScore/100 ($overallGrade)\n";
        $report .= "- **Verdict**: " . $this->getRecommendation($overallScore) . "\n";
        
        return $report;
    }
}

// Usage
if (php_sapi_name() === 'cli' && isset($argv[1])) {
    $checker = new DocumentationQualityChecker();
    $docPath = $argv[1];
    
    if (is_dir($docPath)) {
        $results = [];
        foreach (glob("$docPath/*.md") as $file) {
            $results[] = $checker->checkQuality($file);
        }
        
        $report = $checker->generateReport($results);
        echo $report;
        
        // Save report
        file_put_contents("$docPath/QUALITY-REPORT.md", $report);
        
        // Exit code based on overall quality
        $avgScore = array_sum(array_column($results, 'score')) / count($results);
        exit($avgScore >= 70 ? 0 : 1);
    } else {
        $result = $checker->checkQuality($docPath);
        print_r($result);
        exit($result['score'] >= 70 ? 0 : 1);
    }
}