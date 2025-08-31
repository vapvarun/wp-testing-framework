#!/bin/bash

# Phase 9: Documentation Generation & Quality Validation
# Generates comprehensive documentation and validates existing docs

# Source common functions
# Set MODULES_PATH if not already set (for standalone execution)
if [ -z "$MODULES_PATH" ]; then
    MODULES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
fi
source "$MODULES_PATH/shared/common-functions.sh"

run_phase_09() {
    local plugin_name=$1
    
    print_phase 9 "Documentation Generation & Quality Validation"
    
    print_info "Analyzing plugin documentation..."
    
    # Documentation report
    DOC_REPORT="$SCAN_DIR/reports/documentation-report.md"
    
    # Check for existing documentation files
    print_info "Checking for existing documentation..."
    
    DOC_FILES=(
        "README.md"
        "readme.txt"
        "CHANGELOG.md"
        "changelog.txt"
        "LICENSE"
        "LICENSE.txt"
        "CONTRIBUTING.md"
    )
    
    EXISTING_DOCS=()
    
    for doc in "${DOC_FILES[@]}"; do
        if [ -f "$PLUGIN_PATH/$doc" ]; then
            EXISTING_DOCS+=("$doc")
            print_success "Found: $doc"
        fi
    done
    
    # Analyze code documentation
    print_info "Analyzing code documentation quality..."
    
    # Count DocBlocks
    DOCBLOCKS=$(grep -r '/\*\*' "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    
    # Count inline comments
    INLINE_COMMENTS=$(grep -r '//' "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    
    # Count total PHP lines
    TOTAL_LINES=$(find "$PLUGIN_PATH" -name "*.php" -exec wc -l {} \; 2>/dev/null | awk '{sum+=$1} END {print sum}')
    TOTAL_LINES=${TOTAL_LINES:-1}
    
    # Calculate documentation ratio
    COMMENT_RATIO=$(echo "scale=2; ($DOCBLOCKS + $INLINE_COMMENTS) / $TOTAL_LINES * 100" | bc)
    
    # Extract functions and classes for API documentation
    print_info "Generating API documentation..."
    
    # Count functions
    FUNCTION_COUNT=$(grep -r 'function\s\+[a-zA-Z_]' "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    
    # Count classes
    CLASS_COUNT=$(grep -r 'class\s\+[a-zA-Z_]' "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    
    # Count hooks
    HOOKS_COUNT=$(grep -r 'do_action\|apply_filters' "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    
    # Generate API documentation
    API_DOC="$SCAN_DIR/reports/api-documentation.md"
    
    cat > "$API_DOC" << EOF
# $plugin_name API Documentation
Generated: $(date)

## Overview
- Total Functions: $FUNCTION_COUNT
- Total Classes: $CLASS_COUNT
- Custom Hooks: $HOOKS_COUNT

## Code Structure
- PHP Files: $(find "$PLUGIN_PATH" -name "*.php" -type f | wc -l)
- JavaScript Files: $(find "$PLUGIN_PATH" -name "*.js" -type f | wc -l)
- CSS Files: $(find "$PLUGIN_PATH" -name "*.css" -type f | wc -l)

## Documentation Coverage
- DocBlocks: $DOCBLOCKS
- Inline Comments: $INLINE_COMMENTS
- Comment Ratio: ${COMMENT_RATIO}%
EOF
    
    # Advanced Documentation Generation
    if [ -f "$MODULES_PATH/shared/advanced-analysis.sh" ]; then
        source "$MODULES_PATH/shared/advanced-analysis.sh"
        
        # Generate AI documentation prompt for Claude
        handle_deep_analysis 9 "$plugin_name" "documentation" "$PLUGIN_PATH" "$SCAN_DIR"
        
        # Process any existing AI responses
        process_existing_analysis_reports "$SCAN_DIR" 9
        
        # Add documentation generation note to API doc
        echo "" >> "$API_DOC"
        echo "## Documentation Generation Resources" >> "$API_DOC"
        echo "- Template available in: analysis-requests/phase-9-documentation.md" >> "$API_DOC"
        echo "- Can generate:" >> "$API_DOC"
        echo "  - User documentation" >> "$API_DOC"
        echo "  - Developer documentation" >> "$API_DOC"
        echo "  - API reference" >> "$API_DOC"
        echo "  - Inline PHPDoc suggestions" >> "$API_DOC"
    fi
    
    # Generate user guide
    USER_GUIDE="$SCAN_DIR/reports/user-guide.md"
    
    cat > "$USER_GUIDE" << EOF
# $plugin_name User Guide
Generated: $(date)

## Installation
1. Upload the plugin folder to \`/wp-content/plugins/\`
2. Activate the plugin through the 'Plugins' menu in WordPress
3. Configure settings (if applicable)

## Features
$(if [ -f "$SCAN_DIR/detection-results.json" ]; then
    echo "Based on automatic detection:"
    grep -oP '"features":\s*\[[^\]]+\]' "$SCAN_DIR/detection-results.json" 2>/dev/null | sed 's/.*\[//;s/\].*//;s/","/\n- /g;s/"//g;s/^/- /'
fi)

## Configuration
Check the plugin settings page in WordPress admin for configuration options.

## Troubleshooting
- Clear cache if changes don't appear
- Check PHP error logs for issues
- Ensure WordPress version compatibility
- Verify required PHP extensions are installed

## Support
Refer to the plugin's official documentation or support forum.
EOF
    
    # Run documentation enhancement if available
    if [ -f "$FRAMEWORK_PATH/tools/documentation/enhance-documentation.sh" ]; then
        print_info "Enhancing documentation..."
        bash "$FRAMEWORK_PATH/tools/documentation/enhance-documentation.sh" "$plugin_name" 2>/dev/null || true
    fi
    
    # Run documentation validation if available
    if [ -f "$FRAMEWORK_PATH/tools/documentation/validate-documentation.sh" ]; then
        print_info "Validating documentation..."
        VALIDATION_OUTPUT=$(bash "$FRAMEWORK_PATH/tools/documentation/validate-documentation.sh" "$plugin_name" 2>&1 || echo "Validation skipped")
    fi
    
    # Calculate documentation score
    DOC_SCORE=0
    DOC_SCORE=$((DOC_SCORE + (${#EXISTING_DOCS[@]} * 10)))
    DOC_SCORE=$((DOC_SCORE + ($(echo "$COMMENT_RATIO > 10" | bc) == 1 ? 30 : $(echo "$COMMENT_RATIO * 3" | bc | cut -d. -f1))))
    DOC_SCORE=$((DOC_SCORE > 100 ? 100 : DOC_SCORE))
    
    # Generate final documentation report
    cat > "$DOC_REPORT" << EOF
# Documentation Quality Report
**Plugin**: $plugin_name  
**Date**: $(date)  
**Documentation Score**: $DOC_SCORE/100

## Existing Documentation
$(if [ ${#EXISTING_DOCS[@]} -gt 0 ]; then
    for doc in "${EXISTING_DOCS[@]}"; do
        echo "-  $doc"
    done
else
    echo "- L No documentation files found"
fi)

## Missing Documentation
$(for doc in "${DOC_FILES[@]}"; do
    if [[ ! " ${EXISTING_DOCS[@]} " =~ " ${doc} " ]]; then
        echo "- L $doc"
    fi
done)

## Code Documentation
- DocBlocks: $DOCBLOCKS
- Inline Comments: $INLINE_COMMENTS
- Total PHP Lines: $TOTAL_LINES
- **Comment Ratio**: ${COMMENT_RATIO}%

## API Coverage
- Functions: $FUNCTION_COUNT
- Classes: $CLASS_COUNT
- Hooks: $HOOKS_COUNT

## Generated Documentation
- API Documentation: api-documentation.md
- User Guide: user-guide.md

## Recommendations
$(if [ ${#EXISTING_DOCS[@]} -eq 0 ]; then
    echo "- Add a README.md file with plugin description and usage"
fi)
$(if [[ ! " ${EXISTING_DOCS[@]} " =~ "LICENSE" ]]; then
    echo "- Add a LICENSE file to clarify usage rights"
fi)
$(if [[ ! " ${EXISTING_DOCS[@]} " =~ "CHANGELOG" ]]; then
    echo "- Add a CHANGELOG to track version history"
fi)
$(if [ $(echo "$COMMENT_RATIO < 10" | bc) -eq 1 ]; then
    echo "- Increase code comments (current ratio: ${COMMENT_RATIO}%)"
fi)
EOF
    
    print_success "Documentation generation complete - Score: $DOC_SCORE/100"
    
    # Save phase results
    save_phase_results "09" "completed"
    
    # Interactive checkpoint
    checkpoint 9 "Documentation complete. Ready for report consolidation."
    
    return 0
}

# Execute if running standalone
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    if [ -z "$1" ]; then
        echo "Usage: $0 <plugin-name>"
        exit 1
    fi
    
    PLUGIN_NAME=$1
    FRAMEWORK_PATH="$(cd "$(dirname "$0")/../../" && pwd)"
    WP_PATH="$(dirname "$FRAMEWORK_PATH")"
    PLUGIN_PATH="$WP_PATH/wp-content/plugins/$PLUGIN_NAME"
    UPLOAD_PATH="$WP_PATH/wp-content/uploads"
    
    DATE_MONTH=$(date +"%Y-%m")
    SCAN_DIR="$UPLOAD_PATH/wbcom-scan/$PLUGIN_NAME/$DATE_MONTH"
    
    run_phase_09 "$PLUGIN_NAME"
fi