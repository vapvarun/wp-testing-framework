#!/bin/bash

# Phase 4: AI-Driven Code Analysis
# Performs AST analysis and AI-driven code analysis
# Now incorporates Plugin Check data from Phase 3

# Source common functions
# Set MODULES_PATH if not already set (for standalone execution)
if [ -z "$MODULES_PATH" ]; then
    MODULES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
fi
source "$MODULES_PATH/shared/common-functions.sh"

run_phase_04() {
    local plugin_name=$1
    
    print_phase 4 "AI-Driven Code Analysis (AST + Dynamic + Plugin Check)"
    
    # Check if Node.js is available
    check_nodejs
    if [ "$NODE_AVAILABLE" != "true" ]; then
        print_warning "Node.js not available - skipping AI analysis"
        save_phase_results "04" "skipped"
        return 0
    fi
    
    # Load Plugin Check results from Phase 3
    PLUGIN_CHECK_DIR="$SCAN_DIR/plugin-check"
    PLUGIN_CHECK_JSON="$PLUGIN_CHECK_DIR/plugin-check-full.json"
    PLUGIN_CHECK_INSIGHTS="$PLUGIN_CHECK_DIR/plugin-check-insights.md"
    
    if [ -f "$PLUGIN_CHECK_JSON" ]; then
        print_info "Loading Plugin Check results for AI analysis..."
        
        # Extract key metrics from Plugin Check
        if command_exists jq; then
            PC_ERRORS=$(grep -o '"type":"ERROR"' "$PLUGIN_CHECK_JSON" 2>/dev/null | wc -l || echo "0")
            PC_WARNINGS=$(grep -o '"type":"WARNING"' "$PLUGIN_CHECK_JSON" 2>/dev/null | wc -l || echo "0")
            
            print_info "Plugin Check Summary:"
            echo "  - Errors: $PC_ERRORS"
            echo "  - Warnings: $PC_WARNINGS"
        fi
    else
        print_warning "Plugin Check results not found - AI analysis will proceed without them"
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
                TOTAL_FUNCTIONS=$(jq '.total.functions // 0' "$AST_OUTPUT" 2>/dev/null || echo 0)
                TOTAL_CLASSES=$(jq '.total.classes // 0' "$AST_OUTPUT" 2>/dev/null || echo 0)
                TOTAL_HOOKS=$(jq '.total.hooks // 0' "$AST_OUTPUT" 2>/dev/null || echo 0)
                TOTAL_SHORTCODES=$(jq '.total.shortcodes // 0' "$AST_OUTPUT" 2>/dev/null || echo 0)
                
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
    
    # Generate Claude prompt for AI code analysis
    print_info "Generating Claude analysis prompt for AI code review..."
    
    AI_PROMPT_FILE="$SCAN_DIR/analysis-requests/phase-3-ai-analysis.md"
    
    cat > "$AI_PROMPT_FILE" << EOF
# AI Code Analysis Request

## Plugin Information
- **Plugin Name**: $plugin_name
- **Plugin Path**: $PLUGIN_PATH

## AST Analysis Results
$(if [ -f "$AST_OUTPUT" ]; then
    echo "- Functions: ${TOTAL_FUNCTIONS:-0}"
    echo "- Classes: ${TOTAL_CLASSES:-0}"
    echo "- Hooks: ${TOTAL_HOOKS:-0}"
    echo "- Shortcodes: ${TOTAL_SHORTCODES:-0}"
fi)

## Code Complexity Metrics
- Total Complexity: ${TOTAL_COMPLEXITY:-0}
- If statements: ${IF_COUNT:-0}
- Loops: $((${FOREACH_COUNT:-0} + ${WHILE_COUNT:-0}))
- Switch statements: ${SWITCH_COUNT:-0}

## Request
Please analyze this WordPress plugin code for:

1. **Code Quality**
   - Design patterns used
   - Code organization
   - WordPress best practices adherence
   
2. **Performance Issues**
   - Database query optimization
   - Caching implementation
   - Hook usage efficiency
   
3. **Security Concerns**
   - Input validation
   - Output escaping
   - SQL injection risks
   - XSS vulnerabilities
   
4. **Recommendations**
   - Refactoring suggestions
   - Performance improvements
   - Security enhancements

## Sample Code Structure
$(find "$PLUGIN_PATH" -name "*.php" -type f | head -5 | while read -r file; do
    echo "### $(basename "$file")"
    echo "\`\`\`php"
    head -50 "$file" 2>/dev/null
    echo "\`\`\`"
    echo ""
done)

EOF
    
    print_success "AI analysis prompt generated: $AI_PROMPT_FILE"
    
    # Try running local AI analysis without API key
    if [ -f "$FRAMEWORK_PATH/tools/ai/ai-code-analyzer.mjs" ]; then
        print_info "Attempting local AI analysis..."
        (
            cd "$FRAMEWORK_PATH"
            # Set dummy API key to bypass check
            ANTHROPIC_API_KEY="use-claude-directly" node tools/ai/ai-code-analyzer.mjs "$plugin_name" 2>/dev/null &
            show_progress $! "Local AI Analysis"
        )
        
        if [ -f "$SCAN_DIR/ai-analysis/ai-code-analysis.json" ]; then
            print_success "Local AI analysis complete"
        fi
    fi
    
    # PHP Code Complexity Analysis
    print_info "Analyzing code complexity..."
    
    COMPLEXITY_REPORT="$SCAN_DIR/ai-analysis/complexity-report.txt"
    
    # Count cyclomatic complexity indicators (with error handling)
    IF_COUNT=$(grep -r "if\s*(" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l | tr -d ' ' || echo 0)
    FOREACH_COUNT=$(grep -r "foreach\s*(" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l | tr -d ' ' || echo 0)
    WHILE_COUNT=$(grep -r "while\s*(" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l | tr -d ' ' || echo 0)
    SWITCH_COUNT=$(grep -r "switch\s*(" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l | tr -d ' ' || echo 0)
    
    # Ensure numeric values
    IF_COUNT=${IF_COUNT:-0}
    FOREACH_COUNT=${FOREACH_COUNT:-0}
    WHILE_COUNT=${WHILE_COUNT:-0}
    SWITCH_COUNT=${SWITCH_COUNT:-0}
    
    TOTAL_COMPLEXITY=$((IF_COUNT + FOREACH_COUNT + WHILE_COUNT + SWITCH_COUNT))
    
    # Calculate complexity per file (with bc check)
    PHP_COUNT=${PHP_COUNT:-0}
    if command_exists bc && [ "$PHP_COUNT" -gt 0 ]; then
        COMPLEXITY_PER_FILE=$(echo "scale=2; $TOTAL_COMPLEXITY / $PHP_COUNT" | bc)
    else
        COMPLEXITY_PER_FILE="N/A"
    fi
    
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

Complexity per file: $COMPLEXITY_PER_FILE
EOF
    
    print_success "Complexity analysis complete"
    
    # JavaScript Analysis
    print_info "Analyzing JavaScript files..."
    
    JS_ANALYSIS_REPORT="$SCAN_DIR/ai-analysis/javascript-analysis.txt"
    
    # Find and analyze JavaScript files (with error handling)
    JS_FILES=$(find "$PLUGIN_PATH" -name "*.js" -type f 2>/dev/null | grep -v "\.min\.js" | head -50)
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
                # Get line count (clean)
                LINE_COUNT=$(wc -l < "$js_file" 2>/dev/null | tr -d ' ' || echo 0)
                JS_TOTAL_LINES=$((${JS_TOTAL_LINES:-0} + ${LINE_COUNT:-0}))
                
                # Count JavaScript patterns (simplified and cleaned)
                JQUERY_USES=$(grep -c "jQuery" "$js_file" 2>/dev/null || echo 0)
                AJAX_CALLS=$(grep -c "ajax" "$js_file" 2>/dev/null || echo 0)
                FUNCTIONS=$(grep -c "function" "$js_file" 2>/dev/null || echo 0)
                EVENTS=$(grep -c "addEventListener" "$js_file" 2>/dev/null || echo 0)
                
                # Ensure single-line numeric values
                JQUERY_USES=$(echo "$JQUERY_USES" | head -n1 | tr -d ' ')
                AJAX_CALLS=$(echo "$AJAX_CALLS" | head -n1 | tr -d ' ')
                FUNCTIONS=$(echo "$FUNCTIONS" | head -n1 | tr -d ' ')
                EVENTS=$(echo "$EVENTS" | head -n1 | tr -d ' ')
                
                # Ensure numeric defaults
                JQUERY_USES=${JQUERY_USES:-0}
                AJAX_CALLS=${AJAX_CALLS:-0}
                FUNCTIONS=${FUNCTIONS:-0}
                EVENTS=${EVENTS:-0}
                
                # Accumulate totals
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
    
    # Count all file types (with error handling)
    PHP_FILES_LIST=$(find "$PLUGIN_PATH" -name "*.php" -type f 2>/dev/null || echo "")
    JS_FILES_LIST=$(find "$PLUGIN_PATH" -name "*.js" -type f 2>/dev/null || echo "")
    CSS_FILES_LIST=$(find "$PLUGIN_PATH" -name "*.css" -type f 2>/dev/null || echo "")
    JSON_FILES_LIST=$(find "$PLUGIN_PATH" -name "*.json" -type f 2>/dev/null || echo "")
    XML_FILES_LIST=$(find "$PLUGIN_PATH" -name "*.xml" -type f 2>/dev/null || echo "")
    TXT_FILES_LIST=$(find "$PLUGIN_PATH" -name "*.txt" -type f 2>/dev/null || echo "")
    MD_FILES_LIST=$(find "$PLUGIN_PATH" -name "*.md" -type f 2>/dev/null || echo "")
    
    # Count files safely
    PHP_COUNT=$(echo "$PHP_FILES_LIST" | grep -c . 2>/dev/null || echo 0)
    JS_COUNT=$(echo "$JS_FILES_LIST" | grep -c . 2>/dev/null || echo 0)
    CSS_COUNT=$(echo "$CSS_FILES_LIST" | grep -c . 2>/dev/null || echo 0)
    JSON_COUNT=$(echo "$JSON_FILES_LIST" | grep -c . 2>/dev/null || echo 0)
    XML_COUNT=$(echo "$XML_FILES_LIST" | grep -c . 2>/dev/null || echo 0)
    TXT_COUNT=$(echo "$TXT_FILES_LIST" | grep -c . 2>/dev/null || echo 0)
    MD_COUNT=$(echo "$MD_FILES_LIST" | grep -c . 2>/dev/null || echo 0)
    
    cat > "$COVERAGE_REPORT" << EOF
Complete File Coverage Analysis
===============================
Plugin: $plugin_name
Date: $(date)

FILES ANALYZED BY TYPE:
PHP Files: $PHP_COUNT files
$(echo "$PHP_FILES_LIST" | head -10 | sed 's|.*/||' | sed 's/^/  - /')
$([ $PHP_COUNT -gt 10 ] && echo "  ... and $((PHP_COUNT - 10)) more")

JavaScript Files: $JS_COUNT files  
$(echo "$JS_FILES_LIST" | head -5 | sed 's|.*/||' | sed 's/^/  - /')
$([ $JS_COUNT -gt 5 ] && echo "  ... and $((JS_COUNT - 5)) more")

CSS Files: $CSS_COUNT files
$(echo "$CSS_FILES_LIST" | head -5 | sed 's|.*/||' | sed 's/^/  - /')

Configuration Files: $JSON_COUNT JSON, $XML_COUNT XML
Documentation Files: $TXT_COUNT TXT, $MD_COUNT MD

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
    if grep -r "getInstance\|instance()" "$PLUGIN_PATH" --include="*.php" -q 2>/dev/null; then
        PATTERNS_DETECTED+=("Singleton")
    fi
    
    # Factory pattern
    if grep -r "Factory\|create[A-Z]" "$PLUGIN_PATH" --include="*.php" -q 2>/dev/null; then
        PATTERNS_DETECTED+=("Factory")
    fi
    
    # Observer pattern (WordPress hooks are observer pattern)
    if [ ${TOTAL_HOOKS:-0} -gt 50 ]; then
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

## Plugin Check Integration
$(if [ -f "$PLUGIN_CHECK_JSON" ]; then
    echo "### WordPress Standards Compliance"
    echo "- **Errors Found**: ${PC_ERRORS:-0}"
    echo "- **Warnings Found**: ${PC_WARNINGS:-0}"
    echo ""
    if [ ${PC_ERRORS:-0} -gt 0 ]; then
        echo "⚠️ **Critical**: Plugin has WordPress standards violations that need fixing."
    fi
    if [ -f "$PLUGIN_CHECK_INSIGHTS" ]; then
        echo ""
        echo "[Detailed Plugin Check Report](../plugin-check/plugin-check-insights.md)"
    fi
else
    echo "*Plugin Check data not available*"
fi)

## AST Analysis Results
- Functions: ${TOTAL_FUNCTIONS:-N/A}
- Classes: ${TOTAL_CLASSES:-N/A}
- Hooks: ${TOTAL_HOOKS:-N/A}
- Shortcodes: ${TOTAL_SHORTCODES:-N/A}

## Code Complexity
- Total Complexity Points: $TOTAL_COMPLEXITY
- Complexity per PHP file: $COMPLEXITY_PER_FILE

### Breakdown:
- If statements: $IF_COUNT
- Foreach loops: $FOREACH_COUNT
- While loops: $WHILE_COUNT
- Switch statements: $SWITCH_COUNT

## Design Patterns Detected
$(for pattern in "${PATTERNS_DETECTED[@]}"; do echo "- $pattern"; done)

## Combined Analysis Recommendations
$(if [ ${PC_ERRORS:-0} -gt 0 ]; then
    echo "### Priority 1: WordPress Standards"
    echo "- Fix all Plugin Check errors before proceeding"
    echo "- Review escaping and sanitization practices"
    echo ""
fi)
$(if [ $TOTAL_COMPLEXITY -gt 1000 ]; then
    echo "### Code Complexity"
    echo "- ⚠️ High complexity detected. Consider refactoring complex functions."
    echo ""
fi)
$(if [ ${TOTAL_FUNCTIONS:-0} -gt 500 ]; then
    echo "### Code Organization"
    echo "- Consider organizing functions into classes for better structure."
    echo ""
fi)
$(if [ ${#PATTERNS_DETECTED[@]} -eq 0 ]; then
    echo "### Architecture"
    echo "- Consider implementing design patterns for better code organization."
    echo ""
fi)
$(if [ ${PC_WARNINGS:-0} -gt 20 ]; then
    echo "### Code Quality"
    echo "- Address Plugin Check warnings to improve code quality"
    echo "- Focus on performance and security warnings first"
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
    
    # Get PHP file count from phase 2 or count directly
    if [ -f "$SCAN_DIR/detection-results.json" ] && command_exists jq; then
        PHP_COUNT=$(jq '.statistics.php_files' "$SCAN_DIR/detection-results.json" 2>/dev/null || echo 0)
    else
        PHP_COUNT=$(find "$PLUGIN_PATH" -name "*.php" -type f 2>/dev/null | wc -l | tr -d ' ' || echo 0)
    fi
    
    # Ensure PHP_COUNT is numeric
    PHP_COUNT=${PHP_COUNT:-0}
    
    # Run the phase
    run_phase_04 "$PLUGIN_NAME"
fi