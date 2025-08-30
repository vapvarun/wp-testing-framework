#!/usr/bin/env python3
"""
Enhanced PHP Code Analyzer for WP Testing Framework
Provides accurate AST-based analysis of PHP code structure
"""

import os
import re
import json
import sys
from pathlib import Path
from typing import Dict, List, Tuple
from dataclasses import dataclass, asdict
import subprocess

@dataclass
class PHPFunction:
    name: str
    file: str
    line: int
    visibility: str = 'public'
    is_static: bool = False
    parameters: List[str] = None
    return_type: str = None
    docblock: str = None
    complexity: int = 0

@dataclass
class PHPClass:
    name: str
    file: str
    line: int
    type: str  # class, interface, trait, abstract
    extends: str = None
    implements: List[str] = None
    methods_count: int = 0
    properties_count: int = 0

@dataclass
class CodeMetrics:
    functions: List[PHPFunction]
    classes: List[PHPClass]
    hooks: Dict[str, List]
    database_ops: List[Dict]
    ajax_handlers: List[str]
    rest_endpoints: List[str]
    security_issues: List[Dict]

class PHPAnalyzer:
    def __init__(self, plugin_path: str):
        self.plugin_path = Path(plugin_path)
        self.metrics = CodeMetrics([], [], {}, [], [], [], [])
        
    def analyze(self) -> CodeMetrics:
        """Main analysis entry point"""
        php_files = list(self.plugin_path.rglob('*.php'))
        
        for file_path in php_files:
            self._analyze_file(file_path)
            
        return self.metrics
    
    def _analyze_file(self, file_path: Path):
        """Analyze a single PHP file"""
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                
            rel_path = file_path.relative_to(self.plugin_path)
            
            # Extract functions with better accuracy
            self._extract_functions(content, str(rel_path))
            
            # Extract classes, interfaces, traits
            self._extract_classes(content, str(rel_path))
            
            # Extract WordPress specific patterns
            self._extract_wordpress_patterns(content, str(rel_path))
            
            # Security analysis
            self._analyze_security(content, str(rel_path))
            
        except Exception as e:
            print(f"Error analyzing {file_path}: {e}", file=sys.stderr)
    
    def _extract_functions(self, content: str, file_path: str):
        """Extract functions with detailed information"""
        # Pattern for function declarations (handles multiple formats)
        patterns = [
            # Regular functions
            r'(?:(?P<visibility>public|private|protected|static)\s+)?function\s+(?P<name>[a-zA-Z_\x7f-\xff][a-zA-Z0-9_\x7f-\xff]*)\s*\((?P<params>[^)]*)\)(?:\s*:\s*(?P<return>\S+))?',
            # Anonymous functions
            r'\$\w+\s*=\s*function\s*\((?P<params>[^)]*)\)',
            # Arrow functions (PHP 7.4+)
            r'fn\s*\((?P<params>[^)]*)\)\s*=>'
        ]
        
        for pattern in patterns:
            for match in re.finditer(pattern, content, re.MULTILINE):
                line_num = content[:match.start()].count('\n') + 1
                
                if 'name' in match.groupdict() and match.group('name'):
                    func = PHPFunction(
                        name=match.group('name'),
                        file=file_path,
                        line=line_num,
                        visibility=match.group('visibility') or 'public',
                        parameters=self._parse_params(match.group('params')) if 'params' in match.groupdict() else [],
                        return_type=match.group('return') if 'return' in match.groupdict() else None
                    )
                    
                    # Calculate cyclomatic complexity
                    func.complexity = self._calculate_complexity(content, match.start())
                    
                    self.metrics.functions.append(func)
    
    def _extract_classes(self, content: str, file_path: str):
        """Extract classes, interfaces, and traits"""
        pattern = r'(?P<type>class|interface|trait|abstract\s+class|final\s+class)\s+(?P<name>[a-zA-Z_\x7f-\xff][a-zA-Z0-9_\x7f-\xff]*)(?:\s+extends\s+(?P<extends>\S+))?(?:\s+implements\s+(?P<implements>[^{]+))?'
        
        for match in re.finditer(pattern, content, re.MULTILINE):
            line_num = content[:match.start()].count('\n') + 1
            
            cls = PHPClass(
                name=match.group('name'),
                file=file_path,
                line=line_num,
                type=match.group('type').replace(' ', '_'),
                extends=match.group('extends'),
                implements=match.group('implements').split(',') if match.group('implements') else None
            )
            
            # Count methods and properties in class
            cls.methods_count = self._count_class_methods(content, match.start())
            cls.properties_count = self._count_class_properties(content, match.start())
            
            self.metrics.classes.append(cls)
    
    def _extract_wordpress_patterns(self, content: str, file_path: str):
        """Extract WordPress-specific patterns"""
        
        # WordPress Hooks
        hook_patterns = {
            'actions': r'add_action\s*\(\s*[\'"]([^\'"]+)[\'"]',
            'filters': r'add_filter\s*\(\s*[\'"]([^\'"]+)[\'"]',
            'do_actions': r'do_action\s*\(\s*[\'"]([^\'"]+)[\'"]',
            'apply_filters': r'apply_filters\s*\(\s*[\'"]([^\'"]+)[\'"]'
        }
        
        for hook_type, pattern in hook_patterns.items():
            if hook_type not in self.metrics.hooks:
                self.metrics.hooks[hook_type] = []
                
            for match in re.finditer(pattern, content):
                hook_name = match.group(1)
                line_num = content[:match.start()].count('\n') + 1
                
                self.metrics.hooks[hook_type].append({
                    'name': hook_name,
                    'file': file_path,
                    'line': line_num
                })
        
        # Database operations
        db_pattern = r'\$wpdb->(?P<method>get_results|get_var|get_row|query|prepare|insert|update|delete)\s*\('
        for match in re.finditer(db_pattern, content):
            line_num = content[:match.start()].count('\n') + 1
            self.metrics.database_ops.append({
                'method': match.group('method'),
                'file': file_path,
                'line': line_num
            })
        
        # AJAX handlers
        ajax_pattern = r'add_action\s*\(\s*[\'"]wp_ajax_(?:nopriv_)?([^\'"]+)[\'"]'
        for match in re.finditer(ajax_pattern, content):
            self.metrics.ajax_handlers.append(match.group(1))
        
        # REST endpoints
        rest_pattern = r'register_rest_route\s*\(\s*[\'"]([^\'"]+)[\'"]'
        for match in re.finditer(rest_pattern, content):
            self.metrics.rest_endpoints.append(match.group(1))
    
    def _analyze_security(self, content: str, file_path: str):
        """Perform security analysis"""
        security_patterns = {
            'eval': (r'eval\s*\(', 'critical', 'Dangerous eval() usage'),
            'exec': (r'exec\s*\(', 'critical', 'Command execution vulnerability'),
            'system': (r'system\s*\(', 'critical', 'System command execution'),
            'unserialize': (r'unserialize\s*\(', 'high', 'Unsafe unserialization'),
            'direct_input': (r'echo\s+\$_(?:GET|POST|REQUEST)', 'high', 'Potential XSS vulnerability'),
            'sql_injection': (r'\$wpdb->.*\$_(?:GET|POST|REQUEST)', 'critical', 'Potential SQL injection'),
            'file_inclusion': (r'(?:include|require)(?:_once)?\s*\(\s*\$_', 'critical', 'File inclusion vulnerability'),
            'weak_comparison': (r'==\s*[\'"](?:admin|true|1)[\'"]', 'low', 'Weak comparison')
        }
        
        for issue_type, (pattern, severity, description) in security_patterns.items():
            for match in re.finditer(pattern, content):
                line_num = content[:match.start()].count('\n') + 1
                self.metrics.security_issues.append({
                    'type': issue_type,
                    'severity': severity,
                    'description': description,
                    'file': file_path,
                    'line': line_num,
                    'code_snippet': content[match.start():match.end()]
                })
    
    def _parse_params(self, params_str: str) -> List[str]:
        """Parse function parameters"""
        if not params_str or params_str.strip() == '':
            return []
        
        params = []
        for param in params_str.split(','):
            param = param.strip()
            if param:
                # Extract parameter name (handles type hints)
                match = re.search(r'\$\w+', param)
                if match:
                    params.append(match.group())
        
        return params
    
    def _calculate_complexity(self, content: str, start_pos: int) -> int:
        """Calculate cyclomatic complexity of a function"""
        # Find function body
        brace_count = 0
        in_function = False
        end_pos = start_pos
        
        for i in range(start_pos, len(content)):
            if content[i] == '{':
                brace_count += 1
                in_function = True
            elif content[i] == '}':
                brace_count -= 1
                if in_function and brace_count == 0:
                    end_pos = i
                    break
        
        if end_pos > start_pos:
            function_body = content[start_pos:end_pos]
            
            # Count decision points
            complexity = 1  # Base complexity
            decision_patterns = [
                r'\bif\b', r'\belseif\b', r'\bfor\b', r'\bforeach\b',
                r'\bwhile\b', r'\bcase\b', r'\bcatch\b', r'\?\s*:'
            ]
            
            for pattern in decision_patterns:
                complexity += len(re.findall(pattern, function_body))
            
            return complexity
        
        return 1
    
    def _count_class_methods(self, content: str, class_start: int) -> int:
        """Count methods in a class"""
        # Simple approximation - find next class or end of file
        next_class = re.search(r'\b(?:class|interface|trait)\b', content[class_start+10:])
        if next_class:
            class_content = content[class_start:class_start+10+next_class.start()]
        else:
            class_content = content[class_start:]
        
        return len(re.findall(r'\bfunction\s+\w+\s*\(', class_content))
    
    def _count_class_properties(self, content: str, class_start: int) -> int:
        """Count properties in a class"""
        next_class = re.search(r'\b(?:class|interface|trait)\b', content[class_start+10:])
        if next_class:
            class_content = content[class_start:class_start+10+next_class.start()]
        else:
            class_content = content[class_start:]
        
        return len(re.findall(r'(?:public|private|protected|static)\s+\$\w+', class_content))
    
    def generate_report(self) -> Dict:
        """Generate comprehensive report"""
        return {
            'summary': {
                'total_functions': len(self.metrics.functions),
                'total_classes': len(self.metrics.classes),
                'total_hooks': sum(len(hooks) for hooks in self.metrics.hooks.values()),
                'database_operations': len(self.metrics.database_ops),
                'ajax_handlers': len(self.metrics.ajax_handlers),
                'rest_endpoints': len(self.metrics.rest_endpoints),
                'security_issues': len(self.metrics.security_issues),
                'critical_issues': len([i for i in self.metrics.security_issues if i['severity'] == 'critical'])
            },
            'functions': [asdict(f) for f in self.metrics.functions],
            'classes': [asdict(c) for c in self.metrics.classes],
            'hooks': self.metrics.hooks,
            'database_operations': self.metrics.database_ops,
            'ajax_handlers': self.metrics.ajax_handlers,
            'rest_endpoints': self.metrics.rest_endpoints,
            'security_issues': self.metrics.security_issues,
            'complexity_analysis': self._analyze_complexity()
        }
    
    def _analyze_complexity(self) -> Dict:
        """Analyze code complexity metrics"""
        if not self.metrics.functions:
            return {}
        
        complexities = [f.complexity for f in self.metrics.functions]
        
        return {
            'average_complexity': sum(complexities) / len(complexities) if complexities else 0,
            'max_complexity': max(complexities) if complexities else 0,
            'high_complexity_functions': [
                {'name': f.name, 'file': f.file, 'complexity': f.complexity}
                for f in self.metrics.functions if f.complexity > 10
            ]
        }

def main():
    if len(sys.argv) < 2:
        print("Usage: python php-analyzer.py <plugin-path>")
        sys.exit(1)
    
    plugin_path = sys.argv[1]
    
    if not os.path.exists(plugin_path):
        print(f"Error: Plugin path '{plugin_path}' does not exist")
        sys.exit(1)
    
    analyzer = PHPAnalyzer(plugin_path)
    metrics = analyzer.analyze()
    report = analyzer.generate_report()
    
    # Output JSON report
    print(json.dumps(report, indent=2))
    
    # Print summary to stderr for human reading
    print(f"\n=== Analysis Summary ===", file=sys.stderr)
    print(f"Functions: {report['summary']['total_functions']}", file=sys.stderr)
    print(f"Classes: {report['summary']['total_classes']}", file=sys.stderr)
    print(f"Hooks: {report['summary']['total_hooks']}", file=sys.stderr)
    print(f"Security Issues: {report['summary']['security_issues']} ({report['summary']['critical_issues']} critical)", file=sys.stderr)

if __name__ == "__main__":
    main()