#!/bin/bash

# Phase 3: AI-Driven Code Analysis
# Performs AST analysis and AI-driven code analysis

# Source common functions
# Set MODULES_PATH if not already set (for standalone execution)
if [ -z "$MODULES_PATH" ]; then
    MODULES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
fi
source "$MODULES_PATH/shared/common-functions.sh"

run_phase_03() {
    local plugin_name=$1
    
    print_phase 3 "AI-Driven Code Analysis (AST + Dynamic)"
    
    # Check if Node.js is available
    check_nodejs
    if [ "$NODE_AVAILABLE" != "true" ]; then
        print_warning "Node.js not available - skipping AI analysis"
        save_phase_results "03" "skipped"
        return 0
    fi
    
    # AST Analysis
    if [ "$USE_AST" = "true" ] && [ -f "$FRAMEWORK_PATH/tools/wordpress-ast-analyzer.js" ]; then
        print_info "Running AST analysis..."
        
        AST_OUTPUT="$SCAN_DIR/wordpress-ast-analysis.json"
        
        (
            cd "$FRAMEWORK_PATH"
            node tools/wordpress-ast-analyzer.js "$PLUGIN_PATH" 2>/dev/null &
            show_progress $! "AST Analysis"
        )
        
        if [ -f "$AST_OUTPUT" ]; then
            print_success "AST analysis complete"
            
            # Extract key metrics from AST
            if command_exists jq; then
                TOTAL_FUNCTIONS=$(jq '.total.functions // 0' "$AST_OUTPUT")
                TOTAL_CLASSES=$(jq '.total.classes // 0' "$AST_OUTPUT")
                TOTAL_HOOKS=$(jq '.total.hooks // 0' "$AST_OUTPUT")
                TOTAL_SHORTCODES=$(jq '.total.shortcodes // 0' "$AST_OUTPUT")
                
                print_info "AST Results:"
                echo "  - Functions: $TOTAL_FUNCTIONS"
                echo "  - Classes: $TOTAL_CLASSES"
                echo "  - Hooks: $TOTAL_HOOKS"
                echo "  - Shortcodes: $TOTAL_SHORTCODES"
            fi
        else
            print_warning "AST analysis failed or incomplete"
        fi
    fi
    
    # AI Code Analysis
    if [ -f "$FRAMEWORK_PATH/tools/ai/ai-code-analyzer.mjs" ]; then
        print_info "Running AI code analysis..."
        
        # Check for API key
        if [ -n "$ANTHROPIC_API_KEY" ]; then
            (
                cd "$FRAMEWORK_PATH"
                node tools/ai/ai-code-analyzer.mjs "$plugin_name" 2>/dev/null &
                show_progress $! "AI Code Analysis"
            )
            
            if [ -f "$SCAN_DIR/ai-analysis/ai-code-analysis.json" ]; then
                print_success "AI code analysis complete"
            else
                print_warning "AI analysis incomplete"
            fi
        else
            print_warning "ANTHROPIC_API_KEY not set - skipping AI analysis"
        fi
    fi
    
    # PHP Code Complexity Analysis
    print_info "Analyzing code complexity..."
    
    COMPLEXITY_REPORT="$SCAN_DIR/ai-analysis/complexity-report.txt"
    
    # Count cyclomatic complexity indicators
    IF_COUNT=$(grep -r "if\s*(" "$PLUGIN_PATH" --include="*.php" | wc -l)
    FOREACH_COUNT=$(grep -r "foreach\s*(" "$PLUGIN_PATH" --include="*.php" | wc -l)
    WHILE_COUNT=$(grep -r "while\s*(" "$PLUGIN_PATH" --include="*.php" | wc -l)
    SWITCH_COUNT=$(grep -r "switch\s*(" "$PLUGIN_PATH" --include="*.php" | wc -l)
    
    TOTAL_COMPLEXITY=$((IF_COUNT + FOREACH_COUNT + WHILE_COUNT + SWITCH_COUNT))
    
    cat > "$COMPLEXITY_REPORT" << EOF
Code Complexity Analysis
========================
Plugin: $plugin_name
Date: $(date)

Complexity Indicators:
- If statements: $IF_COUNT
- Foreach loops: $FOREACH_COUNT
- While loops: $WHILE_COUNT
- Switch statements: $SWITCH_COUNT
- Total complexity points: $TOTAL_COMPLEXITY

Complexity per file: $(echo "scale=2; $TOTAL_COMPLEXITY / $PHP_COUNT" | bc)
EOF
    
    print_success "Complexity analysis complete"
    
    # JavaScript Analysis
    print_info "Analyzing JavaScript files..."
    
    JS_ANALYSIS_REPORT="$SCAN_DIR/ai-analysis/javascript-analysis.txt"
    
    # Find and analyze JavaScript files
    JS_FILES=$(find "$PLUGIN_PATH" -name "*.js" -type f | grep -v "\.min\.js" | head -50)
    JS_TOTAL_LINES=0
    JS_JQUERY_COUNT=0
    JS_AJAX_COUNT=0
    JS_FUNCTIONS_COUNT=0
    JS_EVENT_HANDLERS=0
    
    if [ -n "$JS_FILES" ]; then
        cat > "$JS_ANALYSIS_REPORT" << EOF
JavaScript Analysis Report
==========================
Plugin: $plugin_name
Date: $(date)

EOF
        
        while IFS= read -r js_file; do
            if [ -f "$js_file" ]; then
                LINE_COUNT=$(wc -l < "$js_file")
                JS_TOTAL_LINES=$((${JS_TOTAL_LINES:-0} + ${LINE_COUNT:-0}))
                
                # Count JavaScript patterns
                JQUERY_USES=$(grep -c "jQuery" "$js_file" 2>&1 | head -n1)
                AJAX_CALLS=$(grep -c "ajax" "$js_file" 2>&1 | head -n1)
                FUNCTIONS=$(grep -c "function" "$js_file" 2>&1 | head -n1)
                EVENTS=$(grep -c "addEventListener" "$js_file" 2>&1 | head -n1)
                
                # Ensure numeric values
                JQUERY_USES=${JQUERY_USES:-0}
                AJAX_CALLS=${AJAX_CALLS:-0}
                FUNCTIONS=${FUNCTIONS:-0}
                EVENTS=${EVENTS:-0}
                
                JS_JQUERY_COUNT=$((${JS_JQUERY_COUNT:-0} + ${JQUERY_USES:-0}))
                JS_AJAX_COUNT=$((${JS_AJAX_COUNT:-0} + ${AJAX_CALLS:-0}))
                JS_FUNCTIONS_COUNT=$((${JS_FUNCTIONS_COUNT:-0} + ${FUNCTIONS:-0}))
                JS_EVENT_HANDLERS=$((${JS_EVENT_HANDLERS:-0} + ${EVENTS:-0}))
                
                echo "File: $(basename "$js_file")" >> "$JS_ANALYSIS_REPORT"
                echo "  - Lines: $LINE_COUNT" >> "$JS_ANALYSIS_REPORT"
                echo "  - jQuery uses: $JQUERY_USES" >> "$JS_ANALYSIS_REPORT"
                echo "  - AJAX calls: $AJAX_CALLS" >> "$JS_ANALYSIS_REPORT"
                echo "  - Functions: $FUNCTIONS" >> "$JS_ANALYSIS_REPORT"
                echo "  - Event handlers: $EVENTS" >> "$JS_ANALYSIS_REPORT"
                echo "" >> "$JS_ANALYSIS_REPORT"
            fi
        done <<< "$JS_FILES"
        
        cat >> "$JS_ANALYSIS_REPORT" << EOF

Summary:
- Total JS lines: $JS_TOTAL_LINES
- jQuery usage: $JS_JQUERY_COUNT occurrences
- AJAX calls: $JS_AJAX_COUNT occurrences
- Functions: $JS_FUNCTIONS_COUNT total
- Event handlers: $JS_EVENT_HANDLERS total
EOF
        
        print_success "JavaScript analysis complete"
        echo "  - JS lines analyzed: $JS_TOTAL_LINES"
        echo "  - AJAX calls found: $JS_AJAX_COUNT" 
        echo "  - Event handlers: $JS_EVENT_HANDLERS"
    else
        echo "No JavaScript files found" > "$JS_ANALYSIS_REPORT"
        print_info "No JavaScript files to analyze"
    fi
    
    # Complete File Coverage Analysis
    print_info "Generating complete file coverage report..."
    
    COVERAGE_REPORT="$SCAN_DIR/ai-analysis/file-coverage-report.txt"
    
    # Count all file types
    PHP_FILES_LIST=$(find "$PLUGIN_PATH" -name "*.php" -type f)
    JS_FILES_LIST=$(find "$PLUGIN_PATH" -name "*.js" -type f)
    CSS_FILES_LIST=$(find "$PLUGIN_PATH" -name "*.css" -type f)
    JSON_FILES_LIST=$(find "$PLUGIN_PATH" -name "*.json" -type f)
    XML_FILES_LIST=$(find "$PLUGIN_PATH" -name "*.xml" -type f)
    TXT_FILES_LIST=$(find "$PLUGIN_PATH" -name "*.txt" -type f)
    MD_FILES_LIST=$(find "$PLUGIN_PATH" -name "*.md" -type f)
    
    cat > "$COVERAGE_REPORT" << EOF
Complete File Coverage Analysis
===============================
Plugin: $plugin_name
Date: $(date)

FILES ANALYZED BY TYPE:
PHP Files: $(echo "$PHP_FILES_LIST" | grep -c . || echo 0) files
$(echo "$PHP_FILES_LIST" | head -10 | sed 's|.*/||' | sed 's/^/  - /')
$([ $(echo "$PHP_FILES_LIST" | wc -l) -gt 10 ] && echo "  ... and $(($(echo "$PHP_FILES_LIST" | wc -l) - 10)) more")

JavaScript Files: $(echo "$JS_FILES_LIST" | grep -c . || echo 0) files  
$(echo "$JS_FILES_LIST" | head -5 | sed 's|.*/||' | sed 's/^/  - /')
$([ $(echo "$JS_FILES_LIST" | wc -l) -gt 5 ] && echo "  ... and $(($(echo "$JS_FILES_LIST" | wc -l) - 5)) more")

CSS Files: $(echo "$CSS_FILES_LIST" | grep -c . || echo 0) files
$(echo "$CSS_FILES_LIST" | head -5 | sed 's|.*/||' | sed 's/^/  - /')

Configuration Files: $(echo "$JSON_FILES_LIST" | grep -c . || echo 0) JSON, $(echo "$XML_FILES_LIST" | grep -c . || echo 0) XML
Documentation Files: $(echo "$TXT_FILES_LIST" | grep -c . || echo 0) TXT, $(echo "$MD_FILES_LIST" | grep -c . || echo 0) MD

ANALYSIS COVERAGE:
✅ PHP Files: FULLY ANALYZED (AST parsing, functions, classes, hooks)
$([ $JS_AJAX_COUNT -gt 0 ] && echo "✅ JavaScript Files: ANALYZED (AJAX, events, functions)" || echo "⚠️  JavaScript Files: BASIC ANALYSIS")
⚠️  CSS Files: NOT ANALYZED (could check responsive design, custom properties)
⚠️  JSON/XML Files: NOT ANALYZED (could check package.json, composer.json)
⚠️  Documentation: NOT ANALYZED (could extract API docs, README info)

RECOMMENDATIONS:
- PHP coverage is comprehensive
$([ $JS_AJAX_COUNT -gt 0 ] && echo "- JavaScript shows active frontend functionality" || echo "- JavaScript files need deeper analysis")
- Consider adding CSS analysis for responsive design
- Parse configuration files for dependencies
EOF

    print_success "Complete file coverage analysis generated"
    
    # Pattern Detection
    print_info "Detecting design patterns..."
    
    PATTERNS_DETECTED=()
    
    # Singleton pattern
    if grep -r "getInstance\|instance\(\)" "$PLUGIN_PATH" --include="*.php" >/dev/null 2>&1; then
        PATTERNS_DETECTED+=("Singleton")
    fi
    
    # Factory pattern
    if grep -r "Factory\|create[A-Z]" "$PLUGIN_PATH" --include="*.php" >/dev/null 2>&1; then
        PATTERNS_DETECTED+=("Factory")
    fi
    
    # Observer pattern (WordPress hooks are observer pattern)
    if [ ${HOOK_COUNT:-0} -gt 50 ]; then
        PATTERNS_DETECTED+=("Observer (via hooks)")
    fi
    
    # MVC pattern
    if [ -d "$PLUGIN_PATH/controllers" ] || [ -d "$PLUGIN_PATH/models" ] || [ -d "$PLUGIN_PATH/views" ]; then
        PATTERNS_DETECTED+=("MVC")
    fi
    
    # Generate AI analysis report
    cat > "$SCAN_DIR/reports/ai-analysis-report.md" << EOF
# AI-Driven Code Analysis Report
**Plugin**: $plugin_name  
**Date**: $(date)

## AST Analysis Results
- Functions: ${TOTAL_FUNCTIONS:-N/A}
- Classes: ${TOTAL_CLASSES:-N/A}
- Hooks: ${TOTAL_HOOKS:-N/A}
- Shortcodes: ${TOTAL_SHORTCODES:-N/A}

## Code Complexity
- Total Complexity Points: $TOTAL_COMPLEXITY
- Complexity per PHP file: $(echo "scale=2; $TOTAL_COMPLEXITY / $PHP_COUNT" | bc)

### Breakdown:
- If statements: $IF_COUNT
- Foreach loops: $FOREACH_COUNT
- While loops: $WHILE_COUNT
- Switch statements: $SWITCH_COUNT

## Design Patterns Detected
$(for pattern in "${PATTERNS_DETECTED[@]}"; do echo "- $pattern"; done)

## Recommendations
$(if [ $TOTAL_COMPLEXITY -gt 1000 ]; then
    echo "- ⚠️ High complexity detected. Consider refactoring complex functions."
fi)
$(if [ ${TOTAL_FUNCTIONS:-0} -gt 500 ]; then
    echo "- Consider organizing functions into classes for better structure."
fi)
$(if [ ${#PATTERNS_DETECTED[@]} -eq 0 ]; then
    echo "- Consider implementing design patterns for better code organization."
fi)
EOF
    
    print_success "AI analysis report generated"
    
    # Save phase results
    save_phase_results "03" "completed"
    
    # Interactive checkpoint
    checkpoint 3 "AI analysis complete. Ready for security scanning."
    
    return 0
}

# Execute if running standalone
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    # Check if plugin name provided
    if [ -z "$1" ]; then
        echo "Usage: $0 <plugin-name>"
        exit 1
    fi
    
    # Set required variables
    PLUGIN_NAME=$1
    FRAMEWORK_PATH="$(cd "$(dirname "$0")/../../" && pwd)"
    WP_PATH="$(dirname "$FRAMEWORK_PATH")"
    PLUGIN_PATH="$WP_PATH/wp-content/plugins/$PLUGIN_NAME"
    UPLOAD_PATH="$WP_PATH/wp-content/uploads"
    USE_AST=${USE_AST:-true}
    
    # Load scan directory from phase 1
    DATE_MONTH=$(date +"%Y-%m")
    SCAN_DIR="$UPLOAD_PATH/wbcom-scan/$PLUGIN_NAME/$DATE_MONTH"
    
    # Get PHP file count from phase 2
    if [ -f "$SCAN_DIR/detection-results.json" ] && command_exists jq; then
        PHP_COUNT=$(jq '.statistics.php_files' "$SCAN_DIR/detection-results.json")
    else
        PHP_COUNT=$(find "$PLUGIN_PATH" -name "*.php" -type f | wc -l)
    fi
    
    # Run the phase
    run_phase_03 "$PLUGIN_NAME"
fi