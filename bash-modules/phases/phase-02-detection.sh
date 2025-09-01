#!/bin/bash

# Phase 2: Deep Feature Extraction with JSON Output
# This phase extracts ACTUAL DATA not just counts

# Set default MODULES_PATH if not already set
if [ -z "$MODULES_PATH" ]; then
    MODULES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
fi

# Source common functions
source "$MODULES_PATH/shared/common-functions.sh"

# Main phase function
run_phase_02() {
    local plugin_name="${1:-}"
    if [ -z "$plugin_name" ]; then
        print_error "Plugin name required"
        return 1
    fi

    print_phase 2 "Deep Feature Extraction & Analysis"

# Initialize paths
WP_CONTENT_PATH="${WP_CONTENT_PATH:-/Users/varundubey/Local Sites/wptesting/app/public/wp-content}"
PLUGIN_PATH="$WP_CONTENT_PATH/plugins/$plugin_name"
SCAN_DIR="$WP_CONTENT_PATH/uploads/wbcom-scan/$plugin_name/$(date +%Y-%m)"
FEATURES_JSON="$SCAN_DIR/extracted-features.json"

# Validate plugin
if [ ! -d "$PLUGIN_PATH" ]; then
    print_error "Plugin not found: $PLUGIN_PATH"
    exit 1
fi

print_info "Extracting comprehensive plugin features..."

# Initialize JSON structure
cat > "$FEATURES_JSON" << EOF
{
  "plugin_name": "$plugin_name",
  "extraction_date": "$(date -Iseconds)",
  "functions": [],
  "classes": [],
  "hooks": {
    "actions": [],
    "filters": [],
    "registrations": []
  },
  "shortcodes": [],
  "ajax_handlers": [],
  "rest_routes": [],
  "custom_post_types": [],
  "custom_taxonomies": [],
  "database_tables": [],
  "admin_pages": [],
  "settings": [],
  "scripts_styles": {
    "scripts": [],
    "styles": []
  },
  "file_operations": [],
  "external_apis": [],
  "cron_jobs": [],
  "user_capabilities": [],
  "options": [],
  "widgets": [],
  "blocks": []
}
EOF

# Extract functions with signatures
print_info "Extracting function signatures..."
FUNC_COUNT=0
FUNCTIONS_JSON="["
while IFS= read -r func; do
    if [ ! -z "$func" ]; then
        # Clean and escape for JSON
        func_clean=$(echo "$func" | sed 's/^[[:space:]]*//' | sed 's/"/\\"/g')
        if [ $FUNC_COUNT -gt 0 ]; then
            FUNCTIONS_JSON+=","
        fi
        FUNCTIONS_JSON+="\"$func_clean\""
        ((FUNC_COUNT++))
    fi
done < <(find "$PLUGIN_PATH" -name "*.php" -type f -exec grep -h "function [a-zA-Z_]" {} \; 2>/dev/null | head -500)
FUNCTIONS_JSON+="]"

# Extract classes with details
print_info "Extracting class definitions..."
CLASS_COUNT=0
CLASSES_JSON="["
while IFS= read -r class; do
    if [ ! -z "$class" ]; then
        class_name=$(echo "$class" | sed -E 's/.*class\s+([a-zA-Z0-9_]+).*/\1/')
        if [ $CLASS_COUNT -gt 0 ]; then
            CLASSES_JSON+=","
        fi
        CLASSES_JSON+="{\"name\":\"$class_name\",\"type\":\"class\"}"
        ((CLASS_COUNT++))
    fi
done < <(find "$PLUGIN_PATH" -name "*.php" -type f -exec grep -h "^\s*class " {} \; 2>/dev/null)
CLASSES_JSON+="]"

# Extract hooks with context
print_info "Extracting WordPress hooks..."
ACTIONS_JSON="["
ACTION_COUNT=0
while IFS= read -r action; do
    if [ ! -z "$action" ]; then
        hook_name=$(echo "$action" | sed -E "s/.*do_action\s*\(\s*['\"]([^'\"]+).*/\1/")
        if [ $ACTION_COUNT -gt 0 ]; then
            ACTIONS_JSON+=","
        fi
        ACTIONS_JSON+="{\"hook\":\"$hook_name\",\"type\":\"action\"}"
        ((ACTION_COUNT++))
    fi
done < <(find "$PLUGIN_PATH" -name "*.php" -type f -exec grep -h "do_action(" {} \; 2>/dev/null | head -100)
ACTIONS_JSON+="]"

# Extract shortcodes
print_info "Extracting shortcodes..."
SHORTCODES_JSON="["
SC_COUNT=0
while IFS= read -r shortcode; do
    if [ ! -z "$shortcode" ]; then
        sc_name=$(echo "$shortcode" | sed -E "s/.*add_shortcode\s*\(\s*['\"]([^'\"]+).*/\1/")
        if [ $SC_COUNT -gt 0 ]; then
            SHORTCODES_JSON+=","
        fi
        SHORTCODES_JSON+="{\"tag\":\"$sc_name\"}"
        ((SC_COUNT++))
    fi
done < <(find "$PLUGIN_PATH" -name "*.php" -type f -exec grep -h "add_shortcode(" {} \; 2>/dev/null)
SHORTCODES_JSON+="]"

# Extract AJAX handlers
print_info "Extracting AJAX handlers..."
AJAX_JSON="["
AJAX_COUNT=0
while IFS= read -r ajax; do
    if [ ! -z "$ajax" ]; then
        handler=$(echo "$ajax" | sed -E "s/.*wp_ajax_([a-zA-Z0-9_]+).*/\1/")
        if [ $AJAX_COUNT -gt 0 ]; then
            AJAX_JSON+=","
        fi
        AJAX_JSON+="{\"handler\":\"$handler\"}"
        ((AJAX_COUNT++))
    fi
done < <(find "$PLUGIN_PATH" -name "*.php" -type f -exec grep -h "wp_ajax_" {} \; 2>/dev/null | grep -v "wp_ajax_nopriv")
AJAX_JSON+="]"

# Extract custom post types
print_info "Extracting custom post types..."
CPT_JSON="["
CPT_COUNT=0
while IFS= read -r cpt; do
    if [ ! -z "$cpt" ]; then
        cpt_name=$(echo "$cpt" | sed -E "s/.*register_post_type\s*\(\s*['\"]([^'\"]+).*/\1/")
        if [ $CPT_COUNT -gt 0 ]; then
            CPT_JSON+=","
        fi
        CPT_JSON+="{\"name\":\"$cpt_name\",\"type\":\"post_type\"}"
        ((CPT_COUNT++))
    fi
done < <(find "$PLUGIN_PATH" -name "*.php" -type f -exec grep -h "register_post_type(" {} \; 2>/dev/null)
CPT_JSON+="]"

# Extract REST API routes
print_info "Extracting REST API routes..."
REST_JSON="["
REST_COUNT=0
while IFS= read -r rest; do
    if [ ! -z "$rest" ]; then
        route=$(echo "$rest" | sed -E "s/.*register_rest_route\s*\([^,]+,\s*['\"]([^'\"]+).*/\1/")
        if [ $REST_COUNT -gt 0 ]; then
            REST_JSON+=","
        fi
        REST_JSON+="{\"route\":\"$route\"}"
        ((REST_COUNT++))
    fi
done < <(find "$PLUGIN_PATH" -name "*.php" -type f -exec grep -h "register_rest_route(" {} \; 2>/dev/null)
REST_JSON+="]"

# Update the JSON file with extracted data
print_info "Building comprehensive features JSON..."

# Use jq if available, otherwise use sed
if command -v jq &> /dev/null; then
    # Create temp file with extracted data
    cat > "$SCAN_DIR/temp-features.json" << EOF
{
  "plugin_name": "$plugin_name",
  "extraction_date": "$(date -Iseconds)",
  "statistics": {
    "functions": $FUNC_COUNT,
    "classes": $CLASS_COUNT,
    "hooks": $((ACTION_COUNT)),
    "shortcodes": $SC_COUNT,
    "ajax_handlers": $AJAX_COUNT,
    "custom_post_types": $CPT_COUNT,
    "rest_routes": $REST_COUNT
  },
  "functions": $FUNCTIONS_JSON,
  "classes": $CLASSES_JSON,
  "hooks": {
    "actions": $ACTIONS_JSON
  },
  "shortcodes": $SHORTCODES_JSON,
  "ajax_handlers": $AJAX_JSON,
  "custom_post_types": $CPT_JSON,
  "rest_routes": $REST_JSON
}
EOF
    
    # Format with jq
    jq '.' "$SCAN_DIR/temp-features.json" > "$FEATURES_JSON"
    rm -f "$SCAN_DIR/temp-features.json"
else
    # Fallback without jq
    cat > "$FEATURES_JSON" << EOF
{
  "plugin_name": "$plugin_name",
  "extraction_date": "$(date -Iseconds)",
  "statistics": {
    "functions": $FUNC_COUNT,
    "classes": $CLASS_COUNT,
    "hooks": $((ACTION_COUNT)),
    "shortcodes": $SC_COUNT,
    "ajax_handlers": $AJAX_COUNT,
    "custom_post_types": $CPT_COUNT,
    "rest_routes": $REST_COUNT
  },
  "functions": $FUNCTIONS_JSON,
  "classes": $CLASSES_JSON,
  "hooks": {
    "actions": $ACTIONS_JSON
  },
  "shortcodes": $SHORTCODES_JSON,
  "ajax_handlers": $AJAX_JSON,
  "custom_post_types": $CPT_JSON,
  "rest_routes": $REST_JSON
}
EOF
fi

print_success "Feature extraction complete!"
print_success "Extracted data saved to: $FEATURES_JSON"

# Summary
echo ""
print_info "Extraction Summary:"
echo "  - Functions: $FUNC_COUNT"
echo "  - Classes: $CLASS_COUNT"
echo "  - Hooks: $ACTION_COUNT"
echo "  - Shortcodes: $SC_COUNT"
echo "  - AJAX Handlers: $AJAX_COUNT"
echo "  - Custom Post Types: $CPT_COUNT"
echo "  - REST Routes: $REST_COUNT"

# Also generate a human-readable report
REPORT_FILE="$SCAN_DIR/reports/deep-extraction-report.md"
cat > "$REPORT_FILE" << EOF
# Deep Feature Extraction Report
**Plugin**: $plugin_name  
**Date**: $(date)

## Statistics
- Functions: $FUNC_COUNT
- Classes: $CLASS_COUNT
- Hooks: $ACTION_COUNT
- Shortcodes: $SC_COUNT
- AJAX Handlers: $AJAX_COUNT
- Custom Post Types: $CPT_COUNT
- REST Routes: $REST_COUNT

## Data Files
- JSON Data: $FEATURES_JSON
- AST Analysis: $SCAN_DIR/wordpress-ast-analysis.json

## Next Steps
This extracted data will be used by:
- Phase 3: For targeted code analysis
- Phase 4: For security scanning specific functions
- Phase 5: For performance analysis of complex functions
- Phase 6: For generating tests for discovered features
- Phase 9: For comprehensive documentation
- Phase 10: For final aggregation
EOF

    print_success "Phase 2 completed successfully"
    return 0
}