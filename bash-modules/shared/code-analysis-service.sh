#!/bin/bash

# AI Service Module - Centralized AI capabilities for all phases
# Provides unified AI analysis functions for the testing framework

# Check if AI is available
check_ai_availability() {
    if [ -z "$ANTHROPIC_API_KEY" ]; then
        return 1
    fi
    
    # Check if Node.js and AI tools are available
    if ! command -v node &> /dev/null; then
        return 1
    fi
    
    return 0
}

# AI-powered code analysis
ai_analyze_code() {
    local code_path=$1
    local analysis_type=$2
    local output_file=$3
    
    if ! check_ai_availability; then
        return 1
    fi
    
    # Create AI prompt based on analysis type
    case $analysis_type in
        "security")
            local prompt="Analyze this WordPress plugin code for security vulnerabilities. Focus on: SQL injection, XSS, CSRF, file uploads, authentication bypass, privilege escalation. Provide specific line numbers and severity ratings."
            ;;
        "performance")
            local prompt="Analyze this code for performance issues. Identify: database query optimization opportunities, memory leaks, inefficient loops, caching opportunities, slow operations. Rate impact as high/medium/low."
            ;;
        "quality")
            local prompt="Analyze code quality. Check for: code smells, anti-patterns, WordPress coding standards violations, documentation gaps, maintainability issues. Suggest specific improvements."
            ;;
        "architecture")
            local prompt="Analyze the architecture and design patterns. Identify: design patterns used, architectural issues, coupling problems, SOLID principle violations, suggested refactoring."
            ;;
        *)
            local prompt="Perform comprehensive code analysis including security, performance, and quality aspects."
            ;;
    esac
    
    # Call AI API (using Claude via API)
    call_ai_api "$code_path" "$prompt" "$output_file"
}

# AI-powered vulnerability detection
ai_detect_vulnerabilities() {
    local plugin_path=$1
    local output_file=$2
    
    if ! check_ai_availability; then
        return 1
    fi
    
    # Gather code context
    local code_context=""
    
    # Find potentially vulnerable code patterns
    local sql_files=$(grep -r "\$wpdb->" "$plugin_path" --include="*.php" -l 2>/dev/null | head -5)
    local input_files=$(grep -r "\$_POST\|\$_GET\|\$_REQUEST" "$plugin_path" --include="*.php" -l 2>/dev/null | head -5)
    local file_ops=$(grep -r "file_get_contents\|fopen\|include\|require" "$plugin_path" --include="*.php" -l 2>/dev/null | head -5)
    
    # Build context for AI
    for file in $sql_files $input_files $file_ops; do
        if [ -f "$file" ]; then
            code_context+="File: $file\n"
            code_context+=$(head -100 "$file")
            code_context+="\n---\n"
        fi
    done
    
    local prompt="Analyze this WordPress plugin code for critical security vulnerabilities:
    
1. SQL Injection vulnerabilities
2. Cross-Site Scripting (XSS)
3. Cross-Site Request Forgery (CSRF)
4. Authentication/Authorization issues
5. File inclusion vulnerabilities
6. Insecure file operations

Provide:
- Specific vulnerability locations (file and line number)
- Severity rating (Critical/High/Medium/Low)
- Exploit scenario
- Remediation code

Code to analyze:
$code_context"
    
    # Call AI for analysis
    echo "$prompt" | call_ai_direct > "$output_file"
}

# AI-powered performance optimization suggestions
ai_suggest_optimizations() {
    local plugin_path=$1
    local metrics_file=$2
    local output_file=$3
    
    if ! check_ai_availability; then
        return 1
    fi
    
    # Read existing metrics
    local metrics=""
    if [ -f "$metrics_file" ]; then
        metrics=$(cat "$metrics_file")
    fi
    
    # Find performance-critical code
    local db_queries=$(grep -r "\$wpdb->" "$plugin_path" --include="*.php" -c | sort -t: -k2 -nr | head -10)
    local loops=$(grep -r "foreach\|while\|for\s*(" "$plugin_path" --include="*.php" -c | sort -t: -k2 -nr | head -10)
    
    local prompt="Based on these performance metrics and code analysis, provide specific optimization recommendations:

Metrics:
$metrics

High database usage files:
$db_queries

High loop complexity files:
$loops

Provide:
1. Top 5 performance bottlenecks
2. Specific optimization techniques
3. Caching strategies
4. Database query optimizations
5. Code refactoring suggestions

Format as actionable tasks with expected performance improvement percentages."
    
    echo "$prompt" | call_ai_direct > "$output_file"
}

# AI-powered test generation
ai_generate_tests() {
    local function_code=$1
    local test_type=$2
    local output_file=$3
    
    if ! check_ai_availability; then
        return 1
    fi
    
    local prompt="Generate PHPUnit tests for this WordPress function:

$function_code

Test Type: $test_type

Requirements:
1. Follow WordPress testing best practices
2. Include edge cases and error conditions
3. Mock WordPress functions appropriately
4. Add clear test descriptions
5. Include assertions for all code paths

Generate complete, runnable test code."
    
    echo "$prompt" | call_ai_direct > "$output_file"
}

# AI-powered documentation generation
ai_generate_documentation() {
    local code_file=$1
    local doc_type=$2
    local output_file=$3
    
    if ! check_ai_availability; then
        return 1
    fi
    
    local code_content=$(cat "$code_file" 2>/dev/null | head -500)
    
    case $doc_type in
        "user")
            local prompt="Generate user documentation for this WordPress plugin code. Include: features, usage examples, configuration options, FAQ section."
            ;;
        "developer")
            local prompt="Generate developer documentation for this code. Include: architecture overview, API reference, hooks/filters, extension points, code examples."
            ;;
        "inline")
            local prompt="Add comprehensive PHPDoc comments to this code. Include: function descriptions, parameter types, return values, throws declarations, usage examples."
            ;;
        *)
            local prompt="Generate comprehensive documentation for this WordPress plugin code."
            ;;
    esac
    
    prompt="$prompt\n\nCode to document:\n$code_content"
    
    echo "$prompt" | call_ai_direct > "$output_file"
}

# AI-powered code review
ai_review_code() {
    local plugin_path=$1
    local focus_area=$2
    local output_file=$3
    
    if ! check_ai_availability; then
        return 1
    fi
    
    # Select files for review based on focus area
    case $focus_area in
        "security")
            local files=$(find "$plugin_path" -name "*.php" -exec grep -l "\$_POST\|\$_GET\|\$wpdb\|wp_ajax" {} \; | head -10)
            ;;
        "hooks")
            local files=$(find "$plugin_path" -name "*.php" -exec grep -l "add_action\|add_filter\|do_action\|apply_filters" {} \; | head -10)
            ;;
        "database")
            local files=$(find "$plugin_path" -name "*.php" -exec grep -l "\$wpdb" {} \; | head -10)
            ;;
        *)
            local files=$(find "$plugin_path" -name "*.php" | head -10)
            ;;
    esac
    
    local code_samples=""
    for file in $files; do
        code_samples+="=== $file ===\n"
        code_samples+=$(head -100 "$file")
        code_samples+="\n\n"
    done
    
    local prompt="Perform a detailed code review of this WordPress plugin focusing on $focus_area:

$code_samples

Provide:
1. Critical issues that must be fixed
2. Important suggestions for improvement  
3. WordPress best practices violations
4. Security concerns
5. Performance optimizations
6. Code quality scores (1-10) for: Security, Performance, Maintainability, WordPress Standards"
    
    echo "$prompt" | call_ai_direct > "$output_file"
}

# Direct AI API call
call_ai_direct() {
    if [ -z "$ANTHROPIC_API_KEY" ]; then
        echo "Error: ANTHROPIC_API_KEY not set"
        return 1
    fi
    
    # Read input from stdin
    local prompt=$(cat)
    
    # Create API request
    local request='{
        "model": "claude-3-haiku-20240307",
        "max_tokens": 4000,
        "messages": [
            {
                "role": "user",
                "content": "'"$(echo "$prompt" | sed 's/"/\\"/g' | tr '\n' ' ')"'"
            }
        ]
    }'
    
    # Call Claude API
    local response=$(curl -s -X POST https://api.anthropic.com/v1/messages \
        -H "Content-Type: application/json" \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -d "$request")
    
    # Extract content from response
    echo "$response" | grep -oP '"text":"\K[^"]*' | sed 's/\\n/\n/g' | sed 's/\\"/"/g'
}

# AI-powered pattern recognition
ai_detect_patterns() {
    local plugin_path=$1
    local output_file=$2
    
    if ! check_ai_availability; then
        return 1
    fi
    
    # Gather plugin structure
    local structure=$(find "$plugin_path" -type f -name "*.php" | head -20)
    local main_file=$(grep -l "Plugin Name:" "$plugin_path"/*.php 2>/dev/null | head -1)
    local sample_code=""
    
    if [ -f "$main_file" ]; then
        sample_code=$(head -200 "$main_file")
    fi
    
    local prompt="Analyze this WordPress plugin structure and code to identify:

1. Design patterns used (Singleton, Factory, Observer, MVC, etc.)
2. WordPress patterns (hooks, filters, shortcodes, widgets)
3. Code organization pattern
4. Dependency injection usage
5. Anti-patterns present

Plugin structure:
$structure

Sample code:
$sample_code

Provide specific examples and locations of each pattern found."
    
    echo "$prompt" | call_ai_direct > "$output_file"
}

# AI-powered compatibility check
ai_check_compatibility() {
    local plugin_path=$1
    local wp_version=$2
    local php_version=$3
    local output_file=$4
    
    if ! check_ai_availability; then
        return 1
    fi
    
    # Find version-specific code
    local php_features=$(grep -r "match\|str_contains\|str_starts_with\|str_ends_with\|array_key_first\|array_key_last" "$plugin_path" --include="*.php" | head -20)
    local wp_functions=$(grep -r "wp_[a-z_]*(" "$plugin_path" --include="*.php" | head -20)
    
    local prompt="Check WordPress plugin compatibility:

Target WordPress: $wp_version
Target PHP: $php_version

PHP features used:
$php_features

WordPress functions used:
$wp_functions

Identify:
1. PHP version requirements
2. WordPress version requirements  
3. Deprecated functions used
4. Compatibility issues
5. Polyfills needed

Provide specific compatibility fixes."
    
    echo "$prompt" | call_ai_direct > "$output_file"
}

# Export functions for use in other modules
export -f check_ai_availability
export -f ai_analyze_code
export -f ai_detect_vulnerabilities
export -f ai_suggest_optimizations
export -f ai_generate_tests
export -f ai_generate_documentation
export -f ai_review_code
export -f call_ai_direct
export -f ai_detect_patterns
export -f ai_check_compatibility