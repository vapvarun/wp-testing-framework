#!/bin/bash

# Advanced Analysis Module - Manages deep code analysis during phase execution
# Generates comprehensive analysis requests for manual review

# Check AI mode and availability
check_analysis_mode() {
    # Check for Claude subscription mode (default)
    if [ "${ANALYSIS_MODE:-subscription}" = "subscription" ]; then
        return 0  # Subscription mode active
    elif [ "${ANALYSIS_MODE}" = "api" ] && [ -n "$ANTHROPIC_API_KEY" ]; then
        return 1  # API mode with key
    else
        return 2  # No AI available
    fi
}

# Generate and save analysis request during phase execution
generate_analysis_request_for_phase() {
    local phase_num=$1
    local plugin_name=$2
    local plugin_path=$3
    local scan_dir=$4
    local prompt_type=$5
    
    # Ensure analysis requests directory exists
    local analysis_dir="$scan_dir/analysis-requests"
    ensure_directory "$analysis_dir"
    
    local request_file="$analysis_dir/phase-${phase_num}-${prompt_type}.md"
    
    case $prompt_type in
        "detection")
            cat > "$request_file" << 'EOF'
# Plugin Detection & Architecture Analysis

Analyze this WordPress plugin structure and provide insights.

## Plugin Files:
EOF
            find "$plugin_path" -name "*.php" | head -20 | while read file; do
                echo "### $(basename $file)" >> "$request_file"
                echo '```php' >> "$request_file"
                head -100 "$file" >> "$request_file"
                echo '```' >> "$request_file"
            done
            
            cat >> "$request_file" << 'EOF'

## Required Analysis:
1. Identify plugin type and purpose
2. Detect design patterns used
3. Analyze architecture quality
4. Check WordPress integration patterns
5. Identify potential conflicts
6. Rate code organization (1-10)
EOF
            ;;
            
        "security")
            cat > "$request_file" << 'EOF'
# Security Vulnerability Analysis

Analyze this WordPress plugin for security vulnerabilities.

## Critical Security Files:
EOF
            # Find security-relevant files
            grep -r "\$_POST\|\$_GET\|\$wpdb\|wp_ajax" "$plugin_path" --include="*.php" -l 2>/dev/null | head -15 | while read file; do
                echo "### $(basename $file)" >> "$request_file"
                echo '```php' >> "$request_file"
                cat "$file" | head -200 >> "$request_file"
                echo '```' >> "$request_file"
            done
            
            cat >> "$request_file" << 'EOF'

## Security Analysis Required:
1. SQL Injection vulnerabilities (with line numbers)
2. XSS vulnerabilities (with examples)
3. CSRF protection status
4. Authentication/Authorization issues
5. File operation security
6. Data validation problems

For each issue provide:
- Severity: CRITICAL/HIGH/MEDIUM/LOW
- Exact location (file:line)
- Exploit example
- Fix code
EOF
            ;;
            
        "performance")
            cat > "$request_file" << 'EOF'
# Performance Optimization Analysis

Analyze this WordPress plugin for performance issues.

## Performance-Critical Files:
EOF
            # Find database and loop heavy files
            grep -r "\$wpdb\|foreach\|while\|WP_Query" "$plugin_path" --include="*.php" -l 2>/dev/null | head -15 | while read file; do
                echo "### $(basename $file)" >> "$request_file"
                echo '```php' >> "$request_file"
                grep -A5 -B5 "\$wpdb\|foreach\|while\|WP_Query" "$file" | head -150 >> "$request_file"
                echo '```' >> "$request_file"
            done
            
            cat >> "$request_file" << 'EOF'

## Performance Analysis Required:
1. Database query optimizations needed
2. Caching opportunities
3. Memory-intensive operations
4. Slow loops or algorithms
5. Missing pagination

Provide specific optimizations with code examples.
Rate performance impact: Critical/High/Medium/Low
EOF
            ;;
            
        "documentation")
            cat > "$request_file" << 'EOF'
# Documentation Generation Request

Generate comprehensive documentation for this WordPress plugin.

## Main Plugin File:
EOF
            # Include main plugin file
            local main_file=$(grep -l "Plugin Name:" "$plugin_path"/*.php 2>/dev/null | head -1)
            if [ -f "$main_file" ]; then
                cat "$main_file" >> "$request_file"
            fi
            
            cat >> "$request_file" << 'EOF'

## Documentation Needed:

### 1. User Documentation
- Installation guide
- Configuration steps
- Usage instructions
- Troubleshooting

### 2. Developer Documentation  
- Available hooks and filters
- API endpoints
- Function reference
- Extension guide

### 3. Inline Documentation
Generate PHPDoc for all functions

Provide complete, formatted documentation.
EOF
            ;;
    esac
    
    # Add footer with instructions
    cat >> "$request_file" << EOF

---
Generated: $(date)
Plugin: $plugin_name
Phase: $phase_num

Instructions:
1. Copy this entire prompt
2. Paste into claude.ai
3. Save response to: $analysis_dir/phase-${phase_num}-${prompt_type}-response.md
EOF
    
    echo "$request_file"
}

# Process AI analysis during phase (for subscription mode)
handle_deep_analysis() {
    local phase_num=$1
    local plugin_name=$2
    local analysis_type=$3
    local plugin_path="${4:-$PLUGIN_PATH}"
    local scan_dir="${5:-$SCAN_DIR}"
    
    check_analysis_mode
    local ai_mode=$?
    
    if [ $ai_mode -eq 0 ]; then
        # Subscription mode - generate prompt
        print_info "Generating Claude analysis prompt for $analysis_type..."
        
        local request_file=$(generate_analysis_request_for_phase "$phase_num" "$plugin_name" "$plugin_path" "$scan_dir" "$analysis_type")
        
        if [ -f "$request_file" ]; then
            print_success "analysis request generated: $request_file"
            
            # Create instruction file
            local instructions_file="$scan_dir/analysis-requests/INSTRUCTIONS.md"
            if [ ! -f "$instructions_file" ]; then
                cat > "$instructions_file" << 'EOF'
# AI Analysis Instructions

## Claude Subscription Workflow

1. **Open Prompts**: Find prompts in this directory
2. **Copy to Claude**: Paste entire prompt into claude.ai
3. **Save Responses**: Save as `[prompt-name]-response.md`
4. **Process Results**: Run `process-ai-responses.sh`

## Available Prompts:
EOF
                ls -1 "$scan_dir/analysis-requests/"*.md 2>/dev/null | grep -v INSTRUCTIONS | while read prompt; do
                    echo "- $(basename $prompt)" >> "$instructions_file"
                done
            fi
            
            # Show user notification
            echo ""
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${CYAN}📋 Claude Analysis Prompt Ready${NC}"
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo "Type: $analysis_type"
            echo "File: $request_file"
            echo ""
            echo "To analyze with Claude:"
            echo "1. Open: $request_file"
            echo "2. Copy entire content"
            echo "3. Paste into claude.ai"
            echo "4. Save response for processing"
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
        fi
        
    elif [ $ai_mode -eq 1 ]; then
        # API mode (legacy) - only if explicitly enabled
        print_warning "API mode is deprecated. Consider using Claude subscription mode."
        print_info "Set ANALYSIS_MODE=subscription (default) for better analysis"
        
    else
        # No AI available
        print_info "AI analysis skipped (subscription mode, prompts generated for manual use)"
    fi
}

# Check for and process any existing AI responses
process_existing_analysis_reports() {
    local scan_dir=$1
    local phase_num=$2
    
    local analysis_dir="$scan_dir/analysis-requests"
    local response_files=$(ls "$analysis_dir"/phase-${phase_num}-*-response.md 2>/dev/null)
    
    if [ -n "$response_files" ]; then
        print_info "Found AI responses to process..."
        
        for response_file in $response_files; do
            if [ -f "$response_file" ]; then
                local base_name=$(basename "$response_file" -response.md)
                local processed_dir="$scan_dir/deep-analysis"
                ensure_directory "$processed_dir"
                
                # Extract key sections from response
                print_info "Processing: $(basename $response_file)"
                
                # Extract security findings
                if grep -q "CRITICAL\|HIGH\|Security" "$response_file"; then
                    grep -A2 -B2 "CRITICAL\|HIGH" "$response_file" > "$processed_dir/${base_name}-critical-findings.txt"
                fi
                
                # Extract scores if present
                grep -E "Score:.*[0-9]+|Rating:.*[0-9]+" "$response_file" > "$processed_dir/${base_name}-scores.txt" 2>/dev/null
                
                # Extract code fixes
                sed -n '/```/,/```/p' "$response_file" > "$processed_dir/${base_name}-code-fixes.txt" 2>/dev/null
                
                print_success "Processed: $(basename $response_file)"
            fi
        done
    fi
}

# Export functions
export -f check_analysis_mode
export -f generate_analysis_request_for_phase
export -f handle_deep_analysis
export -f process_existing_analysis_reports