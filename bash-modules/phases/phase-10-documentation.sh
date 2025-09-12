#!/bin/bash

# Phase 9: AI-Driven Documentation Generation
# Creates comprehensive documentation prompt for AI with all collected data

# Set MODULES_PATH if not already set (for standalone execution)
if [ -z "$MODULES_PATH" ]; then
    MODULES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
fi
source "$MODULES_PATH/shared/common-functions.sh"

run_phase_10() {
    local plugin_name=$1
    
    print_phase 10 "AI-Driven Documentation Generation"
    
    # Create documentation directory
    DOC_DIR="$SCAN_DIR/documentation"
    mkdir -p "$DOC_DIR"
    
    print_info "Gathering all analysis data for AI documentation..."
    
    # Check for existing documentation files
    EXISTING_DOCS=()
    DOC_FILES=("README.md" "readme.txt" "README.txt" "CHANGELOG.md" "CONTRIBUTING.md" "LICENSE" "LICENSE.txt")
    
    for doc in "${DOC_FILES[@]}"; do
        if [ -f "$PLUGIN_PATH/$doc" ]; then
            EXISTING_DOCS+=("$doc")
        fi
    done
    
    # Generate comprehensive AI prompt with ALL collected data
    print_info "Creating comprehensive AI documentation prompt..."
    
    AI_DOC_PROMPT="$SCAN_DIR/analysis-requests/phase-9-ai-documentation.md"
    
    cat > "$AI_DOC_PROMPT" << 'EOF'
# Complete AI Documentation Generation Request

You are tasked with creating comprehensive documentation for a WordPress plugin based on the complete analysis data provided below. Generate:

1. **USER-GUIDE.md** - Practical guide for end users
2. **DEVELOPER-GUIDE.md** - Technical documentation for developers  
3. **API-REFERENCE.md** - Complete API documentation
4. **ISSUES-AND-FIXES.md** - Current issues and solutions
5. **FUTURE-ROADMAP.md** - Potential improvements and features

Use ALL the data provided below to create accurate, detailed, and useful documentation.

EOF
    
    # Add plugin information
    echo "## Plugin Information" >> "$AI_DOC_PROMPT"
    echo "- **Plugin Name**: $plugin_name" >> "$AI_DOC_PROMPT"
    echo "- **Plugin Path**: $PLUGIN_PATH" >> "$AI_DOC_PROMPT"
    echo "- **Analysis Date**: $(date)" >> "$AI_DOC_PROMPT"
    echo "" >> "$AI_DOC_PROMPT"
    
    # Add existing documentation
    echo "## Existing Documentation Files" >> "$AI_DOC_PROMPT"
    if [ ${#EXISTING_DOCS[@]} -gt 0 ]; then
        for doc in "${EXISTING_DOCS[@]}"; do
            echo "- $doc" >> "$AI_DOC_PROMPT"
        done
    else
        echo "- No existing documentation found" >> "$AI_DOC_PROMPT"
    fi
    echo "" >> "$AI_DOC_PROMPT"
    
    # Add AST analysis data if available
    if [ -f "$SCAN_DIR/wordpress-ast-analysis.json" ] && command_exists jq; then
        echo "## Complete Code Analysis (AST)" >> "$AI_DOC_PROMPT"
        echo "\`\`\`json" >> "$AI_DOC_PROMPT"
        cat "$SCAN_DIR/wordpress-ast-analysis.json" >> "$AI_DOC_PROMPT"
        echo "\`\`\`" >> "$AI_DOC_PROMPT"
        echo "" >> "$AI_DOC_PROMPT"
    fi
    
    # Add all function signatures (handle indented functions)
    echo "## All Functions Index" >> "$AI_DOC_PROMPT"
    echo "\`\`\`php" >> "$AI_DOC_PROMPT"
    find "$PLUGIN_PATH" -name "*.php" -type f -exec grep -h "function [a-zA-Z_]" {} \; 2>/dev/null | sed 's/^[[:space:]]*//' | sort -u | head -200 >> "$AI_DOC_PROMPT"
    echo "\`\`\`" >> "$AI_DOC_PROMPT"
    echo "" >> "$AI_DOC_PROMPT"
    
    # Add all class definitions (handle indented classes)
    echo "## All Classes Index" >> "$AI_DOC_PROMPT"
    echo "\`\`\`php" >> "$AI_DOC_PROMPT"
    find "$PLUGIN_PATH" -name "*.php" -type f -exec grep -h "^\s*class \|^\s*abstract class \|^\s*final class " {} \; 2>/dev/null | sed 's/^[[:space:]]*//' | sort -u >> "$AI_DOC_PROMPT"
    echo "\`\`\`" >> "$AI_DOC_PROMPT"
    echo "" >> "$AI_DOC_PROMPT"
    
    # Add all hooks
    echo "## All Hooks (Actions and Filters)" >> "$AI_DOC_PROMPT"
    echo "### Actions (do_action)" >> "$AI_DOC_PROMPT"
    echo "\`\`\`php" >> "$AI_DOC_PROMPT"
    find "$PLUGIN_PATH" -name "*.php" -type f -exec grep -h "do_action(" {} \; 2>/dev/null | sed 's/^[[:space:]]*//' | sort -u | head -100 >> "$AI_DOC_PROMPT"
    echo "\`\`\`" >> "$AI_DOC_PROMPT"
    echo "" >> "$AI_DOC_PROMPT"
    
    echo "### Filters (apply_filters)" >> "$AI_DOC_PROMPT"
    echo "\`\`\`php" >> "$AI_DOC_PROMPT"
    find "$PLUGIN_PATH" -name "*.php" -type f -exec grep -h "apply_filters(" {} \; 2>/dev/null | sed 's/^[[:space:]]*//' | sort -u | head -100 >> "$AI_DOC_PROMPT"
    echo "\`\`\`" >> "$AI_DOC_PROMPT"
    echo "" >> "$AI_DOC_PROMPT"
    
    echo "### Hook Registrations (add_action/add_filter)" >> "$AI_DOC_PROMPT"
    echo "\`\`\`php" >> "$AI_DOC_PROMPT"
    find "$PLUGIN_PATH" -name "*.php" -type f -exec grep -h "add_action\|add_filter" {} \; 2>/dev/null | sed 's/^[[:space:]]*//' | sort -u | head -100 >> "$AI_DOC_PROMPT"
    echo "\`\`\`" >> "$AI_DOC_PROMPT"
    echo "" >> "$AI_DOC_PROMPT"
    
    # Add shortcodes
    echo "## All Shortcodes" >> "$AI_DOC_PROMPT"
    echo "\`\`\`php" >> "$AI_DOC_PROMPT"
    find "$PLUGIN_PATH" -name "*.php" -type f -exec grep -h "add_shortcode(" {} \; 2>/dev/null | sed 's/^[[:space:]]*//' | sort -u >> "$AI_DOC_PROMPT"
    echo "\`\`\`" >> "$AI_DOC_PROMPT"
    echo "" >> "$AI_DOC_PROMPT"
    
    # Add AJAX handlers
    echo "## AJAX Handlers" >> "$AI_DOC_PROMPT"
    echo "\`\`\`php" >> "$AI_DOC_PROMPT"
    find "$PLUGIN_PATH" -name "*.php" -type f -exec grep -h "wp_ajax_\|admin-ajax.php" {} \; 2>/dev/null | sed 's/^[[:space:]]*//' | sort -u | head -50 >> "$AI_DOC_PROMPT"
    echo "\`\`\`" >> "$AI_DOC_PROMPT"
    echo "" >> "$AI_DOC_PROMPT"
    
    # Add custom post types
    echo "## Custom Post Types" >> "$AI_DOC_PROMPT"
    echo "\`\`\`php" >> "$AI_DOC_PROMPT"
    find "$PLUGIN_PATH" -name "*.php" -type f -exec grep -h "register_post_type(" {} \; 2>/dev/null | sed 's/^[[:space:]]*//' >> "$AI_DOC_PROMPT"
    echo "\`\`\`" >> "$AI_DOC_PROMPT"
    echo "" >> "$AI_DOC_PROMPT"
    
    # Add database operations
    echo "## Database Operations" >> "$AI_DOC_PROMPT"
    echo "\`\`\`php" >> "$AI_DOC_PROMPT"
    find "$PLUGIN_PATH" -name "*.php" -type f -exec grep -h "\$wpdb->" {} \; 2>/dev/null | sed 's/^[[:space:]]*//' | head -50 >> "$AI_DOC_PROMPT"
    echo "\`\`\`" >> "$AI_DOC_PROMPT"
    echo "" >> "$AI_DOC_PROMPT"
    
    # Add security report if available
    if [ -f "$SCAN_DIR/reports/security-report.md" ]; then
        echo "## Security Analysis Results" >> "$AI_DOC_PROMPT"
        echo "\`\`\`markdown" >> "$AI_DOC_PROMPT"
        cat "$SCAN_DIR/reports/security-report.md" >> "$AI_DOC_PROMPT"
        echo "\`\`\`" >> "$AI_DOC_PROMPT"
        echo "" >> "$AI_DOC_PROMPT"
    fi
    
    # Add performance report if available
    if [ -f "$SCAN_DIR/reports/performance-report.md" ]; then
        echo "## Performance Analysis Results" >> "$AI_DOC_PROMPT"
        echo "\`\`\`markdown" >> "$AI_DOC_PROMPT"
        cat "$SCAN_DIR/reports/performance-report.md" >> "$AI_DOC_PROMPT"
        echo "\`\`\`" >> "$AI_DOC_PROMPT"
        echo "" >> "$AI_DOC_PROMPT"
    fi
    
    # Add functionality report if available
    if [ -f "$SCAN_DIR/reports/functionality-report.md" ]; then
        echo "## Functionality Detection Results" >> "$AI_DOC_PROMPT"
        echo "\`\`\`markdown" >> "$AI_DOC_PROMPT"
        cat "$SCAN_DIR/reports/functionality-report.md" >> "$AI_DOC_PROMPT"
        echo "\`\`\`" >> "$AI_DOC_PROMPT"
        echo "" >> "$AI_DOC_PROMPT"
    fi
    
    # Add main plugin file header
    MAIN_FILE=$(find "$PLUGIN_PATH" -maxdepth 1 -name "$plugin_name.php" -o -name "*.php" | head -1)
    if [ -f "$MAIN_FILE" ]; then
        echo "## Main Plugin File Header" >> "$AI_DOC_PROMPT"
        echo "\`\`\`php" >> "$AI_DOC_PROMPT"
        head -100 "$MAIN_FILE" >> "$AI_DOC_PROMPT"
        echo "\`\`\`" >> "$AI_DOC_PROMPT"
        echo "" >> "$AI_DOC_PROMPT"
    fi
    
    # Add file structure
    echo "## Plugin File Structure" >> "$AI_DOC_PROMPT"
    echo "\`\`\`" >> "$AI_DOC_PROMPT"
    find "$PLUGIN_PATH" -type f -name "*.php" -o -name "*.js" -o -name "*.css" | \
        sed "s|$PLUGIN_PATH|.|g" | \
        sort | \
        head -100 >> "$AI_DOC_PROMPT"
    echo "\`\`\`" >> "$AI_DOC_PROMPT"
    echo "" >> "$AI_DOC_PROMPT"
    
    # Add configuration options
    echo "## Configuration Options (wp_options usage)" >> "$AI_DOC_PROMPT"
    echo "\`\`\`php" >> "$AI_DOC_PROMPT"
    grep -h "get_option\|update_option\|add_option\|delete_option" "$PLUGIN_PATH"/**/*.php 2>/dev/null | \
        sed 's/^[[:space:]]*//' | \
        sort -u | \
        head -50 >> "$AI_DOC_PROMPT"
    echo "\`\`\`" >> "$AI_DOC_PROMPT"
    echo "" >> "$AI_DOC_PROMPT"
    
    # Add user capabilities
    echo "## User Capabilities and Permissions" >> "$AI_DOC_PROMPT"
    echo "\`\`\`php" >> "$AI_DOC_PROMPT"
    grep -h "current_user_can\|add_cap\|remove_cap\|capability" "$PLUGIN_PATH"/**/*.php 2>/dev/null | \
        sed 's/^[[:space:]]*//' | \
        sort -u | \
        head -50 >> "$AI_DOC_PROMPT"
    echo "\`\`\`" >> "$AI_DOC_PROMPT"
    echo "" >> "$AI_DOC_PROMPT"
    
    # Add JavaScript functionality
    echo "## JavaScript Files and Functionality" >> "$AI_DOC_PROMPT"
    if [ -d "$PLUGIN_PATH" ]; then
        JS_FILES=$(find "$PLUGIN_PATH" -name "*.js" -not -name "*.min.js" 2>/dev/null)
        if [ -n "$JS_FILES" ]; then
            for js_file in $JS_FILES; do
                echo "### $(basename "$js_file")" >> "$AI_DOC_PROMPT"
                echo "\`\`\`javascript" >> "$AI_DOC_PROMPT"
                head -50 "$js_file" 2>/dev/null >> "$AI_DOC_PROMPT"
                echo "\`\`\`" >> "$AI_DOC_PROMPT"
                echo "" >> "$AI_DOC_PROMPT"
            done
        fi
    fi
    
    # Add documentation generation instructions
    cat >> "$AI_DOC_PROMPT" << 'EOF'

## Documentation Generation Instructions

Based on ALL the above data, generate the following documentation files:

### 1. USER-GUIDE.md
Create a comprehensive user guide that includes:
- Clear installation instructions
- Step-by-step configuration guide
- How to use each feature (based on detected functionality)
- Common use cases and workflows
- Troubleshooting section for common issues
- FAQ based on the plugin's complexity

### 2. DEVELOPER-GUIDE.md
Create technical documentation including:
- Architecture overview based on the code structure
- Complete hooks reference (all actions and filters)
- How to extend the plugin
- Database schema and operations
- AJAX endpoints and how to use them
- Custom post types and taxonomies
- Code examples for common integrations
- Performance considerations

### 3. API-REFERENCE.md
Create complete API documentation:
- All public functions with parameters and return types
- All classes and their methods
- All hooks with parameters and usage examples
- All shortcodes with attributes
- REST API endpoints (if any)
- JavaScript APIs and events

### 4. ISSUES-AND-FIXES.md
Based on the security and performance analysis:
- List all identified security issues with severity
- Provide specific code fixes for each issue
- Performance bottlenecks identified
- Optimization recommendations with code examples
- Code quality issues that need refactoring
- Missing features or incomplete implementations

### 5. FUTURE-ROADMAP.md
Suggest future improvements:
- Features that could be added based on current architecture
- Performance optimizations possible
- Security enhancements needed
- Code refactoring opportunities
- Modern WordPress features that could be adopted
- Integration possibilities with other plugins/services

## Important Notes:
- Use the actual function names, class names, and hooks from the data provided
- Include real code examples from the plugin
- Be specific about file locations and line numbers where relevant
- Prioritize practical, actionable content
- Consider the plugin's actual purpose (forum, e-commerce, etc.) based on the code

Generate comprehensive, production-ready documentation that would be genuinely useful for both users and developers.
EOF
    
    print_success "AI documentation prompt generated: $AI_DOC_PROMPT"
    
    # Get file size of prompt
    PROMPT_SIZE=$(du -h "$AI_DOC_PROMPT" | cut -f1)
    
    # Show Claude prompt
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📋 AI Documentation Generation Prompt Ready${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "Type: Complete Documentation Generation"
    echo "File: $AI_DOC_PROMPT"
    echo "Size: $PROMPT_SIZE"
    echo ""
    echo "This prompt contains:"
    echo "✓ Complete AST analysis data"
    echo "✓ All function signatures"
    echo "✓ All class definitions"
    echo "✓ All hooks and filters"
    echo "✓ All shortcodes"
    echo "✓ Security analysis results"
    echo "✓ Performance analysis results"
    echo "✓ File structure and organization"
    echo ""
    echo "To generate documentation with Claude:"
    echo "1. Open: $AI_DOC_PROMPT"
    echo "2. Copy entire content"
    echo "3. Paste into Claude"
    echo "4. Save each generated document to: $DOC_DIR/"
    echo ""
    echo "Expected output:"
    echo "- USER-GUIDE.md"
    echo "- DEVELOPER-GUIDE.md"
    echo "- API-REFERENCE.md"
    echo "- ISSUES-AND-FIXES.md"
    echo "- FUTURE-ROADMAP.md"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Create placeholder files with instructions
    for doc_file in "USER-GUIDE.md" "DEVELOPER-GUIDE.md" "API-REFERENCE.md" "ISSUES-AND-FIXES.md" "FUTURE-ROADMAP.md"; do
        cat > "$DOC_DIR/$doc_file" << EOF
# $doc_file - Awaiting AI Generation

This documentation file should be generated by AI using the comprehensive prompt at:
$AI_DOC_PROMPT

To generate this documentation:
1. Copy the entire prompt file content
2. Submit to Claude or another AI
3. Replace this file with the AI-generated content

The AI has access to:
- Complete code analysis (AST)
- All functions, classes, and methods
- All hooks, filters, and actions
- Security and performance analysis
- Complete file structure
- All detected issues and patterns

Expected content for this file is detailed in the prompt.
EOF
    done
    
    # Generate documentation report
    DOC_REPORT="$SCAN_DIR/reports/documentation-report.md"
    cat > "$DOC_REPORT" << EOF
# Documentation Generation Report
**Plugin**: $plugin_name  
**Date**: $(date)  
**Status**: AI Prompt Generated

## AI Documentation Prompt
- **Location**: $AI_DOC_PROMPT
- **Size**: $PROMPT_SIZE
- **Type**: Comprehensive documentation generation

## Data Included in Prompt
- AST Analysis: $([ -f "$SCAN_DIR/wordpress-ast-analysis.json" ] && echo "✅ Included" || echo "❌ Not available")
- Function Index: ✅ Complete
- Class Index: ✅ Complete  
- Hooks Index: ✅ Complete
- Shortcodes: ✅ Complete
- Security Analysis: $([ -f "$SCAN_DIR/reports/security-report.md" ] && echo "✅ Included" || echo "❌ Not available")
- Performance Analysis: $([ -f "$SCAN_DIR/reports/performance-report.md" ] && echo "✅ Included" || echo "❌ Not available")

## Expected Documentation Files
The AI should generate:
1. **USER-GUIDE.md** - End-user documentation
2. **DEVELOPER-GUIDE.md** - Technical documentation
3. **API-REFERENCE.md** - Complete API reference
4. **ISSUES-AND-FIXES.md** - Issues and solutions
5. **FUTURE-ROADMAP.md** - Future improvements

## Next Steps
1. Copy the prompt from: $AI_DOC_PROMPT
2. Submit to Claude or preferred AI
3. Save generated documentation to: $DOC_DIR/
4. Review and refine as needed

## Why AI Documentation?
- Comprehensive analysis of ALL code aspects
- Intelligent understanding of plugin purpose
- Contextual documentation based on actual functionality
- Identification of issues and improvements
- Future roadmap based on code analysis
EOF
    
    print_success "Documentation report generated"
    
    # Calculate a score based on available data
    DOC_SCORE=0
    [ -f "$SCAN_DIR/wordpress-ast-analysis.json" ] && DOC_SCORE=$((DOC_SCORE + 30))
    [ -f "$SCAN_DIR/reports/security-report.md" ] && DOC_SCORE=$((DOC_SCORE + 20))
    [ -f "$SCAN_DIR/reports/performance-report.md" ] && DOC_SCORE=$((DOC_SCORE + 20))
    [ ${#EXISTING_DOCS[@]} -gt 0 ] && DOC_SCORE=$((DOC_SCORE + 20))
    [ -f "$AI_DOC_PROMPT" ] && DOC_SCORE=$((DOC_SCORE + 10))
    
    print_success "Documentation generation complete - Score: $DOC_SCORE/100"
    
    # Save phase results
    save_phase_results "10" "completed"
    
    # Copy to wbcom-plans for reusable documentation templates
    PLAN_DIR="$UPLOAD_PATH/wbcom-plan/$PLUGIN_NAME/$DATE_MONTH"
    ensure_directory "$PLAN_DIR/ai-prompts"
    
    if [ -f "$AI_DOC_PROMPT" ]; then
        cp "$AI_DOC_PROMPT" "$PLAN_DIR/ai-prompts/documentation-generation.md"
        print_info "Copied AI documentation prompt to wbcom-plans for future reuse"
    fi
    
    # Save documentation pattern for this plugin type
    if [ -f "$SCAN_DIR/extracted-features.json" ] && command_exists jq; then
        TEMPLATES_DIR="$UPLOAD_PATH/wbcom-plan/templates/documentation"
        ensure_directory "$TEMPLATES_DIR"
        
        # Extract key metrics for template (with fallbacks)
        FUNC_COUNT=$(jq '.statistics.functions // 0' "$SCAN_DIR/extracted-features.json" 2>/dev/null || echo "0")
        CLASS_COUNT=$(jq '.statistics.classes // 0' "$SCAN_DIR/extracted-features.json" 2>/dev/null || echo "0")
        HOOK_COUNT=$(jq '.statistics.hooks // 0' "$SCAN_DIR/extracted-features.json" 2>/dev/null || echo "0")
        
        # Ensure we have valid numbers
        FUNC_COUNT=${FUNC_COUNT:-0}
        CLASS_COUNT=${CLASS_COUNT:-0}
        HOOK_COUNT=${HOOK_COUNT:-0}
        
        cat > "$TEMPLATES_DIR/${PLUGIN_NAME}-metrics.json" << EOF
{
    "plugin": "$PLUGIN_NAME",
    "documentation_metrics": {
        "functions": $FUNC_COUNT,
        "classes": $CLASS_COUNT,
        "hooks": $HOOK_COUNT,
        "prompt_size": "${PROMPT_SIZE:-N/A}",
        "generated_date": "$(date -Iseconds)"
    }
}
EOF
        print_info "Saved documentation metrics to wbcom-plans templates"
    fi
    
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
    
    # Load scan directory
    DATE_MONTH=$(date +"%Y-%m")
    SCAN_DIR="$UPLOAD_PATH/wbcom-scan/$PLUGIN_NAME/$DATE_MONTH"
    
    # Run the phase
    run_phase_10 "$PLUGIN_NAME"
fi