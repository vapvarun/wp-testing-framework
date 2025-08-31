#!/bin/bash

# Phase 2: Plugin Detection & Basic Analysis
# Detects plugin features and performs basic analysis

# Source common functions
# Set MODULES_PATH if not already set (for standalone execution)
if [ -z "$MODULES_PATH" ]; then
    MODULES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
fi
source "$MODULES_PATH/shared/common-functions.sh"

run_phase_02() {
    local plugin_name=$1
    
    print_phase 2 "Plugin Detection & Basic Analysis"
    
    print_info "Analyzing plugin structure..."
    
    # Count files by type
    PHP_COUNT=$(count_files "$PLUGIN_PATH" "php")
    JS_COUNT=$(count_files "$PLUGIN_PATH" "js")
    CSS_COUNT=$(count_files "$PLUGIN_PATH" "css")
    TOTAL_FILES=$(find "$PLUGIN_PATH" -type f | wc -l)
    
    # Calculate plugin size (macOS compatible)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - use du without -b flag
        PLUGIN_SIZE_KB=$(du -sk "$PLUGIN_PATH" 2>/dev/null | cut -f1)
        PLUGIN_SIZE=$((PLUGIN_SIZE_KB * 1024))  # Convert KB to bytes
    else
        # Linux - use du with -b flag
        PLUGIN_SIZE=$(du -sb "$PLUGIN_PATH" 2>/dev/null | cut -f1)
    fi
    PLUGIN_SIZE_FORMAT=$(format_size ${PLUGIN_SIZE:-0})
    
    print_info "Plugin Statistics:"
    echo "  - PHP Files: $PHP_COUNT"
    echo "  - JavaScript Files: $JS_COUNT"
    echo "  - CSS Files: $CSS_COUNT"
    echo "  - Total Files: $TOTAL_FILES"
    echo "  - Size: $PLUGIN_SIZE_FORMAT"
    
    # Detect WordPress features
    print_info "Detecting WordPress features..."
    
    FEATURES_DETECTED=()
    
    # Check for custom post types and extract names
    CPT_FILE="$SCAN_DIR/raw-outputs/detected-cpts.txt"
    if grep -r "register_post_type" "$PLUGIN_PATH" --include="*.php" >/dev/null 2>&1; then
        FEATURES_DETECTED+=("Custom Post Types")
        CPT_COUNT=$(grep -r "register_post_type" "$PLUGIN_PATH" --include="*.php" | wc -l)
        
        # Extract actual CPT names (direct and variable-based)
        {
            # Direct registration: register_post_type('name', ...)
            grep -r "register_post_type\s*(\s*['\"]" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | \
                sed -E "s/.*register_post_type\s*\(\s*['\"]([^'\"]+).*/\1/"
            
            # bbPress-style: Look for post type definitions
            grep -r "post_type.*=.*apply_filters.*'bbp_.*_post_type'" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | \
                sed -E "s/.*apply_filters.*'bbp_([^_]+)_post_type'[^']*'([^']+)'.*/\2/"
                
            # WooCommerce-style: Look for common e-commerce post types
            if grep -r "WooCommerce\|woocommerce" "$PLUGIN_PATH" --include="*.php" >/dev/null 2>&1; then
                echo "product"
                echo "shop_order"
                echo "shop_coupon"
            fi
            
            # Look for post type constants
            grep -r "define.*POST_TYPE.*'" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | \
                sed -E "s/.*define.*POST_TYPE[^']*'([^']+)'.*/\1/"
                
        } | grep -v "^post$\|^page$" | grep -v "^$" | sort -u > "$CPT_FILE"
        
        CPT_NAMES=$(cat "$CPT_FILE" 2>/dev/null | tr '\n' ' ')
        print_success "Custom Post Types detected: $CPT_COUNT"
        if [ -n "$CPT_NAMES" ]; then
            echo "   Found: $CPT_NAMES"
        fi
    fi
    
    # Check for custom taxonomies
    if grep -r "register_taxonomy" "$PLUGIN_PATH" --include="*.php" >/dev/null 2>&1; then
        FEATURES_DETECTED+=("Custom Taxonomies")
        TAX_COUNT=$(grep -r "register_taxonomy" "$PLUGIN_PATH" --include="*.php" | wc -l)
        print_success "Custom Taxonomies detected: $TAX_COUNT occurrences"
    fi
    
    # Check for shortcodes and extract names
    SHORTCODES_FILE="$SCAN_DIR/raw-outputs/detected-shortcodes.txt"
    if grep -r "add_shortcode" "$PLUGIN_PATH" --include="*.php" >/dev/null 2>&1; then
        FEATURES_DETECTED+=("Shortcodes")
        SHORTCODE_COUNT=$(grep -r "add_shortcode" "$PLUGIN_PATH" --include="*.php" | wc -l)
        
        # Extract actual shortcode names
        grep -r "add_shortcode\s*(\s*['\"]" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | \
            sed -E "s/.*add_shortcode\s*\(\s*['\"]([^'\"]+).*/\1/" | \
            sort -u > "$SHORTCODES_FILE"
        
        SHORTCODE_NAMES=$(cat "$SHORTCODES_FILE" | tr '\n' ' ')
        print_success "Shortcodes detected: $SHORTCODE_COUNT - [$SHORTCODE_NAMES]"
    fi
    
    # Check for AJAX handlers
    if grep -r "wp_ajax_" "$PLUGIN_PATH" --include="*.php" >/dev/null 2>&1; then
        FEATURES_DETECTED+=("AJAX Handlers")
        AJAX_COUNT=$(grep -r "wp_ajax_" "$PLUGIN_PATH" --include="*.php" | wc -l)
        print_success "AJAX handlers detected: $AJAX_COUNT"
    fi
    
    # Check for REST API endpoints
    if grep -r "register_rest_route" "$PLUGIN_PATH" --include="*.php" >/dev/null 2>&1; then
        FEATURES_DETECTED+=("REST API")
        REST_COUNT=$(grep -r "register_rest_route" "$PLUGIN_PATH" --include="*.php" | wc -l)
        print_success "REST API endpoints detected: $REST_COUNT"
    fi
    
    # Check for database tables
    if grep -r "CREATE TABLE" "$PLUGIN_PATH" --include="*.php" >/dev/null 2>&1; then
        FEATURES_DETECTED+=("Custom Database Tables")
        TABLE_COUNT=$(grep -r "CREATE TABLE" "$PLUGIN_PATH" --include="*.php" | wc -l)
        print_success "Custom database tables detected: $TABLE_COUNT"
    fi
    
    # Check for admin pages and extract menu details
    ADMIN_MENUS_FILE="$SCAN_DIR/raw-outputs/detected-admin-menus.txt"
    if grep -r "add_menu_page\|add_submenu_page" "$PLUGIN_PATH" --include="*.php" >/dev/null 2>&1; then
        FEATURES_DETECTED+=("Admin Pages")
        ADMIN_COUNT=$(grep -r "add_menu_page\|add_submenu_page" "$PLUGIN_PATH" --include="*.php" | wc -l)
        
        # Extract menu titles and slugs
        grep -r "add_\(sub\)\?menu_page" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | \
            while IFS= read -r line; do
                # Try to extract menu title and slug
                echo "$line" | sed -E 's/.*add_(sub)?menu_page\s*\([^,]*,\s*['\''"]([^'\''"]*)['\''"]\s*,\s*['\''"]([^'\''"]*)['\''"].*/\2 | \3/'
            done | sort -u > "$ADMIN_MENUS_FILE"
        
        print_success "Admin pages detected: $ADMIN_COUNT"
        if [ -s "$ADMIN_MENUS_FILE" ]; then
            echo "   Menu items:"
            while IFS='|' read -r title slug; do
                echo "   - $title (slug: $slug)"
            done < "$ADMIN_MENUS_FILE" | head -5
        fi
    fi
    
    # Check for hooks and categorize them
    HOOKS_FILE="$SCAN_DIR/raw-outputs/detected-hooks.txt"
    HOOK_COUNT=$(grep -r "add_action\|add_filter" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    if [ $HOOK_COUNT -gt 0 ]; then
        FEATURES_DETECTED+=("WordPress Hooks")
        
        # Extract and categorize hooks
        echo "=== FRONTEND HOOKS ===" > "$HOOKS_FILE"
        grep -r "add_\(action\|filter\).*\(wp_head\|wp_footer\|wp_enqueue_scripts\|the_content\|template_redirect\)" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | \
            sed -E "s/.*add_(action|filter)\s*\(\s*['\"]([^'\"]+).*/\2/" | sort -u >> "$HOOKS_FILE"
        
        echo "" >> "$HOOKS_FILE"
        echo "=== ADMIN HOOKS ===" >> "$HOOKS_FILE"
        grep -r "add_\(action\|filter\).*\(admin_\|wp_dashboard\)" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | \
            sed -E "s/.*add_(action|filter)\s*\(\s*['\"]([^'\"]+).*/\2/" | sort -u >> "$HOOKS_FILE"
        
        FRONTEND_HOOKS=$(grep -r "add_\(action\|filter\).*\(wp_head\|wp_footer\|wp_enqueue_scripts\|the_content\)" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
        ADMIN_HOOKS=$(grep -r "add_\(action\|filter\).*admin_" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
        
        print_success "WordPress hooks detected: $HOOK_COUNT"
        echo "   - Frontend hooks: $FRONTEND_HOOKS"
        echo "   - Admin hooks: $ADMIN_HOOKS"
    fi
    
    # Detect plugin type
    PLUGIN_TYPE="Generic"
    
    if grep -r "WooCommerce\|woocommerce\|WC_" "$PLUGIN_PATH" --include="*.php" >/dev/null 2>&1; then
        PLUGIN_TYPE="E-commerce"
    elif grep -r "bbPress\|BuddyPress\|bbp_\|bp_" "$PLUGIN_PATH" --include="*.php" >/dev/null 2>&1; then
        PLUGIN_TYPE="Community/Forum"
    elif grep -r "Contact Form\|form_submit\|wpforms\|cf7" "$PLUGIN_PATH" --include="*.php" >/dev/null 2>&1; then
        PLUGIN_TYPE="Forms"
    elif grep -r "seo_\|yoast\|rankmath\|meta_description" "$PLUGIN_PATH" --include="*.php" >/dev/null 2>&1; then
        PLUGIN_TYPE="SEO"
    elif grep -r "cache_\|wp_cache\|optimization" "$PLUGIN_PATH" --include="*.php" >/dev/null 2>&1; then
        PLUGIN_TYPE="Performance"
    fi
    
    print_info "Plugin Type: $PLUGIN_TYPE"
    
    # Advanced Architecture Analysis
    if [ -f "$MODULES_PATH/shared/advanced-analysis.sh" ]; then
        source "$MODULES_PATH/shared/advanced-analysis.sh"
        
        # Generate comprehensive architecture analysis request
        handle_deep_analysis 2 "$plugin_name" "detection" "$PLUGIN_PATH" "$SCAN_DIR"
        
        # Process any existing analysis reports
        process_existing_analysis_reports "$SCAN_DIR" 2
    fi
    
    # Save detection results
    cat > "$SCAN_DIR/detection-results.json" << EOF
{
    "plugin": "$plugin_name",
    "type": "$PLUGIN_TYPE",
    "statistics": {
        "php_files": $PHP_COUNT,
        "js_files": $JS_COUNT,
        "css_files": $CSS_COUNT,
        "total_files": $TOTAL_FILES,
        "size_bytes": $PLUGIN_SIZE,
        "size_formatted": "$PLUGIN_SIZE_FORMAT"
    },
    "features": [
        $(printf '"%s",' "${FEATURES_DETECTED[@]}" | sed 's/,$//')
    ],
    "feature_counts": {
        "hooks": ${HOOK_COUNT:-0},
        "shortcodes": ${SHORTCODE_COUNT:-0},
        "ajax_handlers": ${AJAX_COUNT:-0},
        "rest_endpoints": ${REST_COUNT:-0},
        "custom_post_types": ${CPT_COUNT:-0},
        "custom_taxonomies": ${TAX_COUNT:-0},
        "admin_pages": ${ADMIN_COUNT:-0},
        "database_tables": ${TABLE_COUNT:-0}
    }
}
EOF
    
    print_success "Plugin detection complete"
    
    # Generate basic report
    cat > "$SCAN_DIR/reports/detection-report.md" << EOF
# Plugin Detection Report
**Plugin**: $plugin_name  
**Type**: $PLUGIN_TYPE  
**Date**: $(date)

## Statistics
- PHP Files: $PHP_COUNT
- JavaScript Files: $JS_COUNT
- CSS Files: $CSS_COUNT
- Total Files: $TOTAL_FILES
- Plugin Size: $PLUGIN_SIZE_FORMAT

## Features Detected
$(for feature in "${FEATURES_DETECTED[@]}"; do echo "- $feature"; done)

## WordPress Integration
- Hooks: ${HOOK_COUNT:-0}
- Shortcodes: ${SHORTCODE_COUNT:-0}
- AJAX Handlers: ${AJAX_COUNT:-0}
- REST Endpoints: ${REST_COUNT:-0}
- Custom Post Types: ${CPT_COUNT:-0}
- Custom Taxonomies: ${TAX_COUNT:-0}
- Admin Pages: ${ADMIN_COUNT:-0}
- Database Tables: ${TABLE_COUNT:-0}
EOF
    
    # Generate comprehensive functionality report
    FUNCTIONALITY_REPORT="$SCAN_DIR/reports/functionality-report.md"
    {
        echo "# Plugin Functionality Report"
        echo "**Plugin**: $plugin_name"
        echo "**Generated**: $(date)"
        echo ""
        echo "## Detected Shortcodes"
        
        if [ -f "$SHORTCODES_FILE" ] && [ -s "$SHORTCODES_FILE" ]; then
            echo "The following shortcodes were found in the plugin:"
            echo '```'
            while IFS= read -r shortcode; do
                echo "[$shortcode]"
            done < "$SHORTCODES_FILE"
            echo '```'
            echo ""
            echo "### Test Pages to Create"
            echo "Create test pages with the following content to test each shortcode:"
            echo ""
            while IFS= read -r shortcode; do
                echo "- **Test Page: $shortcode**"
                echo '  ```'
                echo "  [$shortcode]"
                echo "  [$shortcode id=\"1\"]"
                echo "  [$shortcode title=\"Test Title\"]"
                echo '  ```'
                echo ""
            done < "$SHORTCODES_FILE"
        else
            echo "No shortcodes detected"
        fi
        
        echo "## Custom Post Types"
        if [ "${CPT_COUNT:-0}" -gt 0 ]; then
            echo "Found $CPT_COUNT custom post type registrations:"
            if [ -f "$CPT_FILE" ] && [ -s "$CPT_FILE" ]; then
                while IFS= read -r cpt; do
                    echo "- **$cpt**: Custom content type"
                    echo "  - Create test posts with various statuses"
                    echo "  - Test frontend display and admin editing"
                    echo "  - Verify permissions and capabilities"
                done < "$CPT_FILE"
            fi
            echo ""
            echo "**Recommended test data:**"
            echo "- Create 5-10 sample posts for each custom post type"
            echo "- Include various content types (text, images, videos)"
            echo "- Test different post statuses (draft, published, private)"
        else
            echo "No custom post types detected"
        fi
        
        echo ""
        echo "## Admin Menu Pages"
        if [ "${ADMIN_COUNT:-0}" -gt 0 ]; then
            echo "Found $ADMIN_COUNT admin page registrations:"
            if [ -f "$ADMIN_MENUS_FILE" ] && [ -s "$ADMIN_MENUS_FILE" ]; then
                while IFS='|' read -r title slug; do
                    if [ -n "$title" ] && [ -n "$slug" ]; then
                        echo "- **$title**"
                        echo "  - URL slug: \`$slug\`"
                        echo "  - Screenshot needed: wp-admin/admin.php?page=$slug"
                        echo "  - Test user permissions and functionality"
                    fi
                done < "$ADMIN_MENUS_FILE"
            fi
        else
            echo "No admin pages detected"
        fi
        
        echo ""
        echo "## Frontend Integration"
        if [ "${FRONTEND_HOOKS:-0}" -gt 0 ]; then
            echo "Found $FRONTEND_HOOKS frontend hooks:"
            if [ -f "$HOOKS_FILE" ]; then
                sed -n '/=== FRONTEND HOOKS ===/,/=== ADMIN HOOKS ===/p' "$HOOKS_FILE" | \
                    grep -v "===" | grep -v "^$" | while read -r hook; do
                    echo "- **$hook**: Frontend functionality"
                done
            fi
            echo ""
            echo "**Frontend testing needed:**"
            echo "- Check homepage display"
            echo "- Test shortcode rendering"
            echo "- Verify CSS/JS loading"
            echo "- Test responsive design"
        else
            echo "Limited frontend integration detected"
        fi
        
        echo ""
        echo "## AJAX Handlers"
        if [ "${AJAX_COUNT:-0}" -gt 0 ]; then
            echo "Found $AJAX_COUNT AJAX handler registrations"
            grep -r "wp_ajax_" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | \
                sed -E "s/.*wp_ajax_([^'\"]+).*/- \1/" | \
                sort -u | head -20
        else
            echo "No AJAX handlers detected"
        fi
        
        echo ""
        echo "## Admin Pages"
        if [ "${ADMIN_COUNT:-0}" -gt 0 ]; then
            echo "Found $ADMIN_COUNT admin page registrations"
            echo "Screenshots needed for:"
            grep -r "add_menu_page\|add_submenu_page" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | \
                sed -E "s/.*add_(sub)?menu_page\s*\([^,]*,[^,]*,\s*['\"]([^'\"]+).*/- \2/" | \
                sort -u | head -20
        else
            echo "No admin pages detected"
        fi
        
        echo ""
        echo "## Recommended Test Data"
        echo "1. **Users**: Create test users with different roles (admin, editor, author, subscriber)"
        echo "2. **Content**: Generate sample posts/pages with plugin features"
        echo "3. **Media**: Upload test images for visual elements"
        echo "4. **Settings**: Configure all plugin options"
        echo "5. **Shortcodes**: Create pages demonstrating each shortcode"
        echo ""
        echo "## Testing Checklist"
        echo "- [ ] All shortcodes render correctly"
        echo "- [ ] Admin pages load without errors"
        echo "- [ ] AJAX functions respond properly"
        echo "- [ ] Custom post types display correctly"
        echo "- [ ] Database operations work as expected"
        echo "- [ ] User permissions are enforced"
        echo "- [ ] Plugin activates/deactivates cleanly"
    } > "$FUNCTIONALITY_REPORT"
    
    print_success "Functionality report generated: $FUNCTIONALITY_REPORT"
    
    # Save phase results
    save_phase_results "02" "completed"
    
    # Interactive checkpoint
    checkpoint 2 "Plugin detection complete. Ready for advanced analysis."
    
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
    
    # Load scan directory from phase 1
    DATE_MONTH=$(date +"%Y-%m")
    SCAN_DIR="$UPLOAD_PATH/wbcom-scan/$PLUGIN_NAME/$DATE_MONTH"
    
    # Run the phase
    run_phase_02 "$PLUGIN_NAME"
fi