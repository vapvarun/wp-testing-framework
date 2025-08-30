#!/usr/bin/env php
<?php
/**
 * Enhanced PHP Analyzer using Industry-Standard Tools
 * Leverages nikic/php-parser for accurate AST analysis
 */

require_once __DIR__ . '/../vendor/autoload.php';

use PhpParser\Node;
use PhpParser\NodeTraverser;
use PhpParser\NodeVisitor\FindingVisitor;
use PhpParser\ParserFactory;
use PhpParser\PrettyPrinter;
use PhpParser\NodeFinder;
use PhpParser\Comment;

class WordPressPluginAnalyzer {
    private $parser;
    private $traverser;
    private $metrics = [
        'functions' => [],
        'classes' => [],
        'hooks' => [],
        'database_operations' => [],
        'ajax_handlers' => [],
        'rest_endpoints' => [],
        'shortcodes' => [],
        'security_issues' => [],
        'nonces' => [],
        'capabilities' => [],
        'sanitization' => []
    ];
    
    public function __construct() {
        $this->parser = (new ParserFactory)->create(ParserFactory::PREFER_PHP7);
        $this->traverser = new NodeTraverser();
    }
    
    public function analyzePlugin($pluginPath) {
        $files = $this->getPhpFiles($pluginPath);
        
        foreach ($files as $file) {
            $this->analyzeFile($file, $pluginPath);
        }
        
        return $this->generateReport();
    }
    
    private function analyzeFile($filePath, $basePath) {
        try {
            $code = file_get_contents($filePath);
            $ast = $this->parser->parse($code);
            
            if ($ast === null) {
                return;
            }
            
            $relativePath = str_replace($basePath . '/', '', $filePath);
            
            // Custom visitor for WordPress patterns
            $visitor = new WordPressPatternVisitor($relativePath, $code);
            $this->traverser->addVisitor($visitor);
            $this->traverser->traverse($ast);
            $this->traverser->removeVisitor($visitor);
            
            // Merge results
            $this->mergeMetrics($visitor->getMetrics());
            
        } catch (Exception $e) {
            error_log("Error parsing $filePath: " . $e->getMessage());
        }
    }
    
    private function getPhpFiles($path) {
        $iterator = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator($path, RecursiveDirectoryIterator::SKIP_DOTS)
        );
        
        $files = [];
        foreach ($iterator as $file) {
            if ($file->isFile() && $file->getExtension() === 'php') {
                $files[] = $file->getPathname();
            }
        }
        
        return $files;
    }
    
    private function mergeMetrics($newMetrics) {
        foreach ($newMetrics as $key => $value) {
            if (isset($this->metrics[$key])) {
                if (is_array($value)) {
                    $this->metrics[$key] = array_merge($this->metrics[$key], $value);
                } else {
                    $this->metrics[$key] += $value;
                }
            }
        }
    }
    
    private function generateReport() {
        return [
            'summary' => [
                'total_functions' => count($this->metrics['functions']),
                'total_classes' => count($this->metrics['classes']),
                'total_hooks' => count($this->metrics['hooks']),
                'database_operations' => count($this->metrics['database_operations']),
                'ajax_handlers' => count($this->metrics['ajax_handlers']),
                'rest_endpoints' => count($this->metrics['rest_endpoints']),
                'shortcodes' => count($this->metrics['shortcodes']),
                'security_issues' => count($this->metrics['security_issues']),
                'nonce_checks' => count($this->metrics['nonces']),
                'capability_checks' => count($this->metrics['capabilities']),
                'sanitization_uses' => count($this->metrics['sanitization'])
            ],
            'details' => $this->metrics,
            'recommendations' => $this->generateRecommendations()
        ];
    }
    
    private function generateRecommendations() {
        $recommendations = [];
        
        // Security recommendations
        if (empty($this->metrics['nonces'])) {
            $recommendations[] = [
                'type' => 'security',
                'severity' => 'high',
                'message' => 'No nonce verification found. Add wp_verify_nonce() for form submissions.'
            ];
        }
        
        if (empty($this->metrics['capabilities'])) {
            $recommendations[] = [
                'type' => 'security',
                'severity' => 'high',
                'message' => 'No capability checks found. Use current_user_can() for access control.'
            ];
        }
        
        if (count($this->metrics['database_operations']) > 0 && 
            count($this->metrics['sanitization']) < count($this->metrics['database_operations'])) {
            $recommendations[] = [
                'type' => 'security',
                'severity' => 'critical',
                'message' => 'Database operations without proper sanitization detected.'
            ];
        }
        
        // Performance recommendations
        if (count($this->metrics['hooks']) > 100) {
            $recommendations[] = [
                'type' => 'performance',
                'severity' => 'medium',
                'message' => 'High number of hooks may impact performance. Consider lazy loading.'
            ];
        }
        
        return $recommendations;
    }
}

class WordPressPatternVisitor extends NodeVisitor\AbstractVisitor {
    private $metrics = [
        'functions' => [],
        'classes' => [],
        'hooks' => [],
        'database_operations' => [],
        'ajax_handlers' => [],
        'rest_endpoints' => [],
        'shortcodes' => [],
        'security_issues' => [],
        'nonces' => [],
        'capabilities' => [],
        'sanitization' => []
    ];
    
    private $currentFile;
    private $sourceCode;
    
    public function __construct($file, $sourceCode) {
        $this->currentFile = $file;
        $this->sourceCode = $sourceCode;
    }
    
    public function enterNode(Node $node) {
        // Analyze functions
        if ($node instanceof Node\Stmt\Function_) {
            $this->analyzeFunction($node);
        }
        
        // Analyze classes
        if ($node instanceof Node\Stmt\Class_) {
            $this->analyzeClass($node);
        }
        
        // Analyze method calls for WordPress patterns
        if ($node instanceof Node\Expr\FuncCall) {
            $this->analyzeFunctionCall($node);
        }
        
        // Analyze method calls
        if ($node instanceof Node\Expr\MethodCall) {
            $this->analyzeMethodCall($node);
        }
        
        return null;
    }
    
    private function analyzeFunction($node) {
        $this->metrics['functions'][] = [
            'name' => $node->name->toString(),
            'file' => $this->currentFile,
            'line' => $node->getLine(),
            'params' => count($node->params),
            'return_type' => $node->returnType ? $node->returnType->toString() : null,
            'complexity' => $this->calculateComplexity($node)
        ];
    }
    
    private function analyzeClass($node) {
        $this->metrics['classes'][] = [
            'name' => $node->name->toString(),
            'file' => $this->currentFile,
            'line' => $node->getLine(),
            'methods' => count(array_filter($node->stmts, function($stmt) {
                return $stmt instanceof Node\Stmt\ClassMethod;
            })),
            'properties' => count(array_filter($node->stmts, function($stmt) {
                return $stmt instanceof Node\Stmt\Property;
            })),
            'extends' => $node->extends ? $node->extends->toString() : null,
            'implements' => array_map(function($i) { return $i->toString(); }, $node->implements)
        ];
    }
    
    private function analyzeFunctionCall($node) {
        if (!$node->name instanceof Node\Name) {
            return;
        }
        
        $functionName = $node->name->toString();
        
        // WordPress hooks
        if (in_array($functionName, ['add_action', 'add_filter', 'do_action', 'apply_filters'])) {
            if (isset($node->args[0]) && $node->args[0]->value instanceof Node\Scalar\String_) {
                $this->metrics['hooks'][] = [
                    'type' => $functionName,
                    'name' => $node->args[0]->value->value,
                    'file' => $this->currentFile,
                    'line' => $node->getLine()
                ];
                
                // Check for AJAX handlers
                if ($functionName === 'add_action' && 
                    strpos($node->args[0]->value->value, 'wp_ajax_') === 0) {
                    $this->metrics['ajax_handlers'][] = [
                        'action' => $node->args[0]->value->value,
                        'file' => $this->currentFile,
                        'line' => $node->getLine()
                    ];
                }
            }
        }
        
        // REST API registration
        if ($functionName === 'register_rest_route') {
            if (isset($node->args[0]) && $node->args[0]->value instanceof Node\Scalar\String_) {
                $this->metrics['rest_endpoints'][] = [
                    'namespace' => $node->args[0]->value->value,
                    'file' => $this->currentFile,
                    'line' => $node->getLine()
                ];
            }
        }
        
        // Shortcodes
        if ($functionName === 'add_shortcode') {
            if (isset($node->args[0]) && $node->args[0]->value instanceof Node\Scalar\String_) {
                $this->metrics['shortcodes'][] = [
                    'tag' => $node->args[0]->value->value,
                    'file' => $this->currentFile,
                    'line' => $node->getLine()
                ];
            }
        }
        
        // Security functions
        if (in_array($functionName, ['wp_verify_nonce', 'check_admin_referer'])) {
            $this->metrics['nonces'][] = [
                'function' => $functionName,
                'file' => $this->currentFile,
                'line' => $node->getLine()
            ];
        }
        
        if (in_array($functionName, ['current_user_can', 'user_can'])) {
            $this->metrics['capabilities'][] = [
                'function' => $functionName,
                'file' => $this->currentFile,
                'line' => $node->getLine()
            ];
        }
        
        if (strpos($functionName, 'sanitize_') === 0 || 
            strpos($functionName, 'esc_') === 0 || 
            $functionName === 'wp_kses') {
            $this->metrics['sanitization'][] = [
                'function' => $functionName,
                'file' => $this->currentFile,
                'line' => $node->getLine()
            ];
        }
        
        // Dangerous functions
        if (in_array($functionName, ['eval', 'exec', 'system', 'shell_exec', 'passthru'])) {
            $this->metrics['security_issues'][] = [
                'type' => 'dangerous_function',
                'function' => $functionName,
                'severity' => 'critical',
                'file' => $this->currentFile,
                'line' => $node->getLine(),
                'message' => "Use of dangerous function: $functionName"
            ];
        }
    }
    
    private function analyzeMethodCall($node) {
        // Check for $wpdb methods
        if ($node->var instanceof Node\Expr\Variable && 
            $node->var->name === 'wpdb' && 
            $node->name instanceof Node\Identifier) {
            
            $method = $node->name->toString();
            $this->metrics['database_operations'][] = [
                'method' => $method,
                'file' => $this->currentFile,
                'line' => $node->getLine(),
                'needs_prepare' => in_array($method, ['query', 'get_results', 'get_var', 'get_row'])
            ];
            
            // Check if prepare is used
            $isPrepared = false;
            if (isset($node->args[0]) && 
                $node->args[0]->value instanceof Node\Expr\MethodCall &&
                $node->args[0]->value->name->toString() === 'prepare') {
                $isPrepared = true;
            }
            
            if (!$isPrepared && in_array($method, ['query', 'get_results'])) {
                $this->metrics['security_issues'][] = [
                    'type' => 'sql_injection_risk',
                    'severity' => 'high',
                    'file' => $this->currentFile,
                    'line' => $node->getLine(),
                    'message' => "Direct database query without prepare() method"
                ];
            }
        }
    }
    
    private function calculateComplexity($node) {
        $complexity = 1;
        
        $finder = new NodeFinder();
        $conditions = $finder->find($node, function(Node $node) {
            return $node instanceof Node\Stmt\If_ ||
                   $node instanceof Node\Stmt\ElseIf_ ||
                   $node instanceof Node\Stmt\For_ ||
                   $node instanceof Node\Stmt\Foreach_ ||
                   $node instanceof Node\Stmt\While_ ||
                   $node instanceof Node\Stmt\Do_ ||
                   $node instanceof Node\Stmt\Case_ ||
                   $node instanceof Node\Stmt\Catch_ ||
                   $node instanceof Node\Expr\Ternary ||
                   $node instanceof Node\Expr\BooleanAnd ||
                   $node instanceof Node\Expr\BooleanOr;
        });
        
        $complexity += count($conditions);
        
        return $complexity;
    }
    
    public function getMetrics() {
        return $this->metrics;
    }
}

// Main execution
if (php_sapi_name() === 'cli') {
    if ($argc < 2) {
        echo "Usage: php enhanced-php-analyzer.php <plugin-path>\n";
        exit(1);
    }
    
    $pluginPath = $argv[1];
    
    if (!is_dir($pluginPath)) {
        echo "Error: Plugin path '$pluginPath' does not exist\n";
        exit(1);
    }
    
    $analyzer = new WordPressPluginAnalyzer();
    $report = $analyzer->analyzePlugin($pluginPath);
    
    echo json_encode($report, JSON_PRETTY_PRINT) . "\n";
}