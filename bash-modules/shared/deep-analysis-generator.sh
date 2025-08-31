#!/bin/bash

# AI Claude Subscription Module - Optimized for Claude.ai subscription usage
# Generates consolidated prompts and analysis batches for manual Claude interaction

# Generate comprehensive analysis prompt for Claude
generate_claude_analysis_prompt() {
    local plugin_path=$1
    local plugin_name=$2
    local analysis_type=${3:-"comprehensive"}
    local output_file=$4
    
    print_info "Generating Claude analysis prompt for $analysis_type..."
    
    # Collect all relevant code in one batch
    local code_batch=""
    local file_count=0
    local max_files=20  # Optimize for Claude's context window
    
    # Prioritize files based on analysis type
    case $analysis_type in
        "security")
            # Focus on security-critical files
            local files=$(find "$plugin_path" -name "*.php" -exec grep -l "\$_POST\|\$_GET\|\$wpdb\|wp_ajax\|wp_nonce\|current_user_can" {} \; 2>/dev/null | head -$max_files)
            ;;
        "performance")
            # Focus on performance-critical files
            local files=$(find "$plugin_path" -name "*.php" -exec grep -l "\$wpdb\|wp_query\|get_posts\|WP_Query\|wp_cache" {} \; 2>/dev/null | head -$max_files)
            ;;
        "comprehensive")
            # Get main files and important includes
            local files=$(find "$plugin_path" -maxdepth 2 -name "*.php" | head -$max_files)
            ;;
        *)
            local files=$(find "$plugin_path" -name "*.php" | head -$max_files)
            ;;
    esac
    
    # Build code batch
    for file in $files; do
        if [ -f "$file" ]; then
            file_count=$((file_count + 1))
            local relative_path=${file#$plugin_path/}
            code_batch+="=== FILE: $relative_path ===\n"
            code_batch+=$(cat "$file" | head -500)  # Limit lines per file
            code_batch+="\n\n"
        fi
    done
    
    # Generate the master prompt
    cat > "$output_file" << 'PROMPT'
# WordPress Plugin Analysis Request

Please analyze this WordPress plugin comprehensively and provide detailed insights.

## Analysis Type: ANALYSIS_TYPE
## Plugin Name: PLUGIN_NAME
## Files Analyzed: FILE_COUNT

## Code to Analyze:

CODE_BATCH

## Required Analysis Output:

Please provide a comprehensive analysis in the following structured format:

### 1. SECURITY ANALYSIS
#### Critical Vulnerabilities
- List each vulnerability with:
  - File and line number
  - Vulnerability type (SQL Injection, XSS, CSRF, etc.)
  - Severity: CRITICAL/HIGH/MEDIUM/LOW
  - Exploit scenario
  - Specific fix with code example

#### Security Best Practices
- Nonce verification status
- Capability checks
- Data sanitization
- SQL prepared statements usage

### 2. PERFORMANCE ANALYSIS
#### Performance Issues
- Database query optimization opportunities
- Caching implementation status
- Memory-intensive operations
- Slow operations or loops
- Each with specific optimization code

#### Performance Metrics
- Estimated database queries per page load
- Memory usage patterns
- Optimization priority list

### 3. CODE QUALITY ANALYSIS
#### Architecture & Patterns
- Design patterns identified
- Anti-patterns found
- SOLID principle adherence
- WordPress coding standards compliance

#### Maintainability
- Code complexity score (1-10)
- Refactoring recommendations
- Documentation coverage

### 4. WORDPRESS INTEGRATION
#### Hooks & Filters
- Custom hooks provided
- Core hooks used correctly
- Missing hook implementations

#### Compatibility
- Minimum PHP version required
- Minimum WordPress version
- Deprecated functions used
- Modern PHP features requiring polyfills

### 5. TESTING RECOMMENDATIONS
#### Critical Test Cases
Generate 5 PHPUnit test examples for the most critical functions:
```php
// Provide actual test code
```

### 6. DOCUMENTATION NEEDS
#### Missing Documentation
- Functions lacking PHPDoc
- Unclear code sections
- API documentation needs

### 7. ACTIONABLE IMPROVEMENTS
Provide a prioritized list of exactly 10 specific improvements:
1. [CRITICAL] Specific issue and fix
2. [HIGH] Specific issue and fix
... through 10

### 8. AUTOMATED FIX SUGGESTIONS
For the top 3 issues, provide exact code patches:
```diff
// Show exact changes needed
```

### 9. SUMMARY SCORES
- Security Score: X/100
- Performance Score: X/100
- Code Quality Score: X/100
- WordPress Standards Score: X/100
- Overall Health Score: X/100

### 10. EXECUTIVE SUMMARY
One paragraph summary of the plugin's overall state and most important recommendations.

---
Please be specific with file names, line numbers, and provide actual code examples for all recommendations.
PROMPT
    
    # Replace placeholders
    sed -i "s/ANALYSIS_TYPE/$analysis_type/g" "$output_file"
    sed -i "s/PLUGIN_NAME/$plugin_name/g" "$output_file"
    sed -i "s/FILE_COUNT/$file_count/g" "$output_file"
    
    # Add code batch (handle special characters)
    echo "$code_batch" > "${output_file}.code"
    awk '/CODE_BATCH/{system("cat '"${output_file}.code"'");next}1' "$output_file" > "${output_file}.tmp"
    mv "${output_file}.tmp" "$output_file"
    rm "${output_file}.code"
    
    print_success "Claude prompt generated: $output_file"
    echo "File contains $file_count files for analysis"
    echo "Copy the contents of $output_file and paste into Claude for analysis"
}

# Generate batch analysis for multiple plugins
generate_batch_analysis() {
    local plugins_dir="/Users/varundubey/Local Sites/wptesting/app/public/wp-content/plugins"
    local output_dir="$FRAMEWORK_PATH/ai-batch-analysis"
    
    ensure_directory "$output_dir"
    
    local batch_file="$output_dir/batch-analysis-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$batch_file" << 'HEADER'
# WordPress Plugins Batch Analysis Request

Please analyze these WordPress plugins and provide a comparative analysis.

## Plugins to Analyze:

HEADER
    
    local plugin_count=0
    for plugin_path in "$plugins_dir"/*; do
        if [ -d "$plugin_path" ] && [ $plugin_count -lt 5 ]; then
            plugin_count=$((plugin_count + 1))
            local plugin_name=$(basename "$plugin_path")
            
            echo "### Plugin $plugin_count: $plugin_name" >> "$batch_file"
            
            # Get plugin header
            local main_file=$(grep -l "Plugin Name:" "$plugin_path"/*.php 2>/dev/null | head -1)
            if [ -f "$main_file" ]; then
                echo '```php' >> "$batch_file"
                head -50 "$main_file" >> "$batch_file"
                echo '```' >> "$batch_file"
            fi
            echo "" >> "$batch_file"
        fi
    done
    
    cat >> "$batch_file" << 'FOOTER'

## Required Analysis:

For each plugin, provide:

1. **Security Risk Level**: CRITICAL/HIGH/MEDIUM/LOW
2. **Performance Impact**: Heavy/Moderate/Light
3. **Code Quality Grade**: A/B/C/D/F
4. **Top 3 Issues**
5. **Recommended Action**: Keep/Review/Replace/Remove

## Comparative Analysis:

1. Which plugin poses the highest security risk?
2. Which plugin has the worst performance impact?
3. Which plugins have conflicting functionality?
4. Priority order for addressing issues

## Summary Table:

| Plugin | Security | Performance | Quality | Action |
|--------|----------|-------------|---------|--------|
| ...    | ...      | ...         | ...     | ...    |

FOOTER
    
    print_success "Batch analysis prompt generated: $batch_file"
}

# Create Claude Project structure
setup_claude_project() {
    local plugin_name=$1
    local project_dir="$FRAMEWORK_PATH/claude-projects/$plugin_name"
    
    ensure_directory "$project_dir"
    ensure_directory "$project_dir/prompts"
    ensure_directory "$project_dir/responses"
    ensure_directory "$project_dir/artifacts"
    
    # Create project knowledge base
    cat > "$project_dir/PROJECT_KNOWLEDGE.md" << EOF
# $plugin_name Analysis Project

## Context
This is a WordPress plugin analysis project using the WP Testing Framework v12.0.

## Plugin Information
- Name: $plugin_name
- Path: $WP_PATH/wp-content/plugins/$plugin_name
- Analysis Date: $(date)

## Analysis Phases
1. Detection & Basic Analysis
2. Security Vulnerability Scanning
3. Performance Analysis
4. Code Quality Review
5. Documentation Generation
6. Test Generation

## Key Files to Analyze
$(find "$PLUGIN_PATH" -name "*.php" -type f | head -10)

## Previous Analysis Results
$(if [ -d "$SCAN_DIR" ]; then
    echo "- Scan Directory: $SCAN_DIR"
    ls "$SCAN_DIR/reports/" 2>/dev/null | sed 's/^/- /'
else
    echo "- No previous analysis found"
fi)

## Custom Instructions for Claude
- Always provide specific file names and line numbers
- Include code examples for all suggestions
- Rate severity as CRITICAL/HIGH/MEDIUM/LOW
- Provide exact fixes, not general suggestions
- Focus on WordPress-specific security issues
- Consider WordPress coding standards
EOF
    
    print_success "Claude Project structure created: $project_dir"
}

# Generate test generation prompt
generate_test_prompt() {
    local plugin_path=$1
    local output_file=$2
    
    # Find testable functions
    local functions=$(grep -h "function [a-zA-Z_]" "$plugin_path"/*.php 2>/dev/null | head -20)
    
    cat > "$output_file" << 'TEST_PROMPT'
# WordPress Plugin Test Generation

Generate comprehensive PHPUnit tests for these WordPress plugin functions:

## Functions to Test:

FUNCTIONS_LIST

## Test Requirements:

For each function, create:

1. **Basic Functionality Test**
   - Happy path test
   - Expected output validation

2. **Edge Cases**
   - Empty inputs
   - Invalid inputs
   - Boundary conditions

3. **Error Handling**
   - Exception scenarios
   - Error conditions

4. **WordPress Integration**
   - Mock WordPress functions
   - Test hooks and filters
   - Database interactions

5. **Security Tests**
   - Input sanitization
   - Authorization checks
   - Nonce verification

## Test Template:

```php
<?php
class PluginTest extends WP_UnitTestCase {
    
    public function setUp(): void {
        parent::setUp();
        // Setup code
    }
    
    public function test_function_name_happy_path() {
        // Arrange
        
        // Act
        
        // Assert
    }
    
    public function test_function_name_handles_invalid_input() {
        // Test implementation
    }
    
    // More tests...
}
```

Please provide complete, runnable test code with proper WordPress test utilities.
TEST_PROMPT
    
    echo "$functions" | sed 's/^/- /' > "${output_file}.funcs"
    sed -i '/FUNCTIONS_LIST/r '"${output_file}.funcs" "$output_file"
    sed -i '/FUNCTIONS_LIST/d' "$output_file"
    rm "${output_file}.funcs"
    
    print_success "Test generation prompt created: $output_file"
}

# Generate documentation prompt
generate_doc_prompt() {
    local plugin_path=$1
    local plugin_name=$2
    local output_file=$3
    
    # Get plugin structure
    local structure=$(find "$plugin_path" -type f -name "*.php" | head -20 | sed "s|$plugin_path/||")
    
    cat > "$output_file" << 'DOC_PROMPT'
# WordPress Plugin Documentation Generation

## Plugin: PLUGIN_NAME

## Plugin Structure:
STRUCTURE_LIST

## Documentation Needed:

### 1. USER DOCUMENTATION
Create a comprehensive user guide including:

#### Installation Guide
- Prerequisites
- Step-by-step installation
- Initial configuration
- Verification steps

#### Usage Guide
- Feature overview
- How to use each feature
- Screenshots descriptions
- Common workflows

#### Troubleshooting
- Common issues and solutions
- FAQ section
- Support resources

### 2. DEVELOPER DOCUMENTATION
Create technical documentation including:

#### Architecture Overview
- Plugin structure
- Design patterns used
- Data flow diagrams
- Database schema

#### API Reference
- All public functions
- Available hooks and filters
- REST API endpoints
- AJAX handlers

#### Extension Guide
- How to extend the plugin
- Custom hooks available
- Code examples
- Best practices

### 3. INLINE DOCUMENTATION
Generate PHPDoc blocks for all functions:

```php
/**
 * Function description
 *
 * @since 1.0.0
 * @param type $param Description
 * @return type Description
 * @throws Exception When...
 */
```

### 4. README.MD
Create a professional README with:
- Badges
- Features list
- Installation
- Usage examples
- Contributing guidelines
- License

Please provide complete, well-formatted documentation following WordPress standards.
DOC_PROMPT
    
    sed -i "s/PLUGIN_NAME/$plugin_name/g" "$output_file"
    echo "$structure" | sed 's/^/- /' > "${output_file}.struct"
    sed -i '/STRUCTURE_LIST/r '"${output_file}.struct" "$output_file"
    sed -i '/STRUCTURE_LIST/d' "$output_file"
    rm "${output_file}.struct"
    
    print_success "Documentation prompt created: $output_file"
}

# Interactive Claude session manager
start_claude_session() {
    local plugin_name=$1
    local session_dir="$FRAMEWORK_PATH/claude-sessions/$(date +%Y%m%d-%H%M%S)-$plugin_name"
    
    ensure_directory "$session_dir"
    
    # Create session file
    cat > "$session_dir/session.md" << EOF
# Claude Analysis Session: $plugin_name
Started: $(date)

## Session Commands:
- Type 'security' for security analysis
- Type 'performance' for performance analysis  
- Type 'test' for test generation
- Type 'doc' for documentation generation
- Type 'comprehensive' for full analysis
- Type 'quit' to exit

## Session Log:
EOF
    
    echo "Claude session started for $plugin_name"
    echo "Session directory: $session_dir"
    
    while true; do
        read -p "Claude command (security/performance/test/doc/comprehensive/quit): " cmd
        
        case $cmd in
            security|performance|comprehensive)
                generate_claude_analysis_prompt "$PLUGIN_PATH" "$plugin_name" "$cmd" "$session_dir/prompt-$cmd.md"
                echo "[$cmd] Prompt generated at $(date)" >> "$session_dir/session.md"
                ;;
            test)
                generate_test_prompt "$PLUGIN_PATH" "$session_dir/prompt-test.md"
                echo "[test] Test prompt generated at $(date)" >> "$session_dir/session.md"
                ;;
            doc)
                generate_doc_prompt "$PLUGIN_PATH" "$plugin_name" "$session_dir/prompt-doc.md"
                echo "[doc] Documentation prompt generated at $(date)" >> "$session_dir/session.md"
                ;;
            quit)
                echo "Session ended: $(date)" >> "$session_dir/session.md"
                break
                ;;
            *)
                echo "Unknown command: $cmd"
                ;;
        esac
        
        echo "Prompt saved to: $session_dir/prompt-$cmd.md"
        echo "Copy the prompt content and paste into Claude"
        echo "Save Claude's response to: $session_dir/response-$cmd.md"
    done
    
    print_success "Claude session ended. Results in: $session_dir"
}

# Process Claude response
process_claude_response() {
    local response_file=$1
    local output_dir=$2
    
    if [ ! -f "$response_file" ]; then
        print_error "Response file not found: $response_file"
        return 1
    fi
    
    ensure_directory "$output_dir"
    
    # Extract different sections from Claude's response
    print_info "Processing Claude response..."
    
    # Extract security findings
    sed -n '/### 1\. SECURITY ANALYSIS/,/### 2\. PERFORMANCE ANALYSIS/p' "$response_file" > "$output_dir/security-findings.md"
    
    # Extract performance findings
    sed -n '/### 2\. PERFORMANCE ANALYSIS/,/### 3\. CODE QUALITY/p' "$response_file" > "$output_dir/performance-findings.md"
    
    # Extract test code
    sed -n '/```php/,/```/p' "$response_file" | grep -v '```' > "$output_dir/generated-tests.php"
    
    # Extract scores
    grep -E "Score: [0-9]+/100" "$response_file" > "$output_dir/scores.txt"
    
    print_success "Response processed. Results in: $output_dir"
}

# Export functions
export -f generate_claude_analysis_prompt
export -f generate_batch_analysis
export -f setup_claude_project
export -f generate_test_prompt
export -f generate_doc_prompt
export -f start_claude_session
export -f process_claude_response