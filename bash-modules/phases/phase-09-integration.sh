#!/bin/bash

# Phase 9: WordPress Integration Tests
# Tests plugin integration with WordPress core functionality

# Source common functions
# Set MODULES_PATH if not already set (for standalone execution)
if [ -z "$MODULES_PATH" ]; then
    MODULES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
fi
source "$MODULES_PATH/shared/common-functions.sh"

run_phase_09() {
    local plugin_name=$1
    
    print_phase 9 "WordPress Integration Tests"
    
    print_info "Testing WordPress integration points..."
    
    # Integration test results
    INTEGRATION_REPORT="$SCAN_DIR/reports/integration-report.md"
    
    # Test core WordPress hooks
    print_info "Analyzing WordPress hook integration..."
    
    CORE_HOOKS=(
        "init"
        "wp_loaded"
        "admin_init"
        "admin_menu"
        "wp_enqueue_scripts"
        "admin_enqueue_scripts"
        "the_content"
        "wp_head"
        "wp_footer"
    )
    
    HOOKS_FOUND=0
    HOOK_DETAILS=""
    
    for hook in "${CORE_HOOKS[@]}"; do
        COUNT=$(grep -r "add_action.*'$hook'\|add_filter.*'$hook'" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
        if [ $COUNT -gt 0 ]; then
            HOOKS_FOUND=$((HOOKS_FOUND + COUNT))
            HOOK_DETAILS="$HOOK_DETAILS- $hook: $COUNT occurrences\n"
            print_success "Found $COUNT uses of '$hook' hook"
        fi
    done
    
    # Test database integration
    print_info "Checking database integration..."
    
    DB_TABLES=$(grep -r "CREATE TABLE" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    DB_QUERIES=$(grep -r '\$wpdb' "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    
    if [ $DB_TABLES -gt 0 ]; then
        print_info "Custom database tables: $DB_TABLES"
    fi
    
    if [ $DB_QUERIES -gt 0 ]; then
        print_info "Database queries found: $DB_QUERIES"
    fi
    
    # Test user capabilities
    print_info "Analyzing user capabilities..."
    
    CAPABILITY_CHECKS=$(grep -r "current_user_can\|user_can" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    CUSTOM_CAPS=$(grep -r "add_cap\|remove_cap" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    
    # Test REST API integration
    print_info "Checking REST API endpoints..."
    
    REST_ROUTES=$(grep -r "register_rest_route" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    
    if [ $REST_ROUTES -gt 0 ]; then
        print_success "REST API endpoints found: $REST_ROUTES"
    fi
    
    # Test admin pages
    print_info "Checking admin pages..."
    
    MENU_PAGES=$(grep -r "add_menu_page" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    SUBMENU_PAGES=$(grep -r "add_submenu_page" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    SETTINGS_PAGES=$(grep -r "add_options_page" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    
    TOTAL_ADMIN_PAGES=$((MENU_PAGES + SUBMENU_PAGES + SETTINGS_PAGES))
    
    # Test shortcodes
    print_info "Checking shortcodes..."
    
    SHORTCODES=$(grep -r "add_shortcode" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    
    if [ $SHORTCODES -gt 0 ]; then
        print_success "Shortcodes registered: $SHORTCODES"
    fi
    
    # Test widgets
    print_info "Checking widgets..."
    
    WIDGETS=$(grep -r "extends WP_Widget\|register_widget" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | wc -l)
    
    # Test Gutenberg blocks
    print_info "Checking Gutenberg blocks..."
    
    BLOCKS=$(grep -r "registerBlockType\|register_block_type" "$PLUGIN_PATH" --include="*.php" --include="*.js" 2>/dev/null | wc -l)
    
    # Generate test data if WP-CLI is available
    if [ "$WP_CLI_AVAILABLE" = "true" ]; then
        print_info "Generating test data for plugin..."
        
        # Create test users
        print_info "Creating test users..."
        wp user create test_admin test_admin@example.com --role=administrator --user_pass=test123 --path="$WP_PATH" 2>/dev/null || true
        wp user create test_editor test_editor@example.com --role=editor --user_pass=test123 --path="$WP_PATH" 2>/dev/null || true
        wp user create test_author test_author@example.com --role=author --user_pass=test123 --path="$WP_PATH" 2>/dev/null || true
        wp user create test_subscriber test_subscriber@example.com --role=subscriber --user_pass=test123 --path="$WP_PATH" 2>/dev/null || true
        print_success "Test users created"
        
        # Create test pages with shortcodes if detected
        SHORTCODES_FILE="$SCAN_DIR/raw-outputs/detected-shortcodes.txt"
        if [ -f "$SHORTCODES_FILE" ] && [ -s "$SHORTCODES_FILE" ]; then
            print_info "Creating test pages for shortcodes..."
            
            while IFS= read -r shortcode; do
                # Create a test page for each shortcode
                PAGE_TITLE="Test: $shortcode Shortcode"
                PAGE_CONTENT="<h2>Testing [$shortcode]</h2>\n\n"
                PAGE_CONTENT="${PAGE_CONTENT}<h3>Basic Usage:</h3>\n[$shortcode]\n\n"
                PAGE_CONTENT="${PAGE_CONTENT}<h3>With Parameters:</h3>\n[$shortcode id=\"1\" title=\"Test Title\"]\n\n"
                PAGE_CONTENT="${PAGE_CONTENT}<h3>Multiple Instances:</h3>\n[$shortcode]\n[$shortcode id=\"2\"]\n"
                
                PAGE_ID=$(wp post create --post_type=page --post_status=publish \
                    --post_title="$PAGE_TITLE" \
                    --post_content="$PAGE_CONTENT" \
                    --path="$WP_PATH" --porcelain 2>/dev/null || echo "0")
                
                if [ "$PAGE_ID" != "0" ]; then
                    print_success "Created test page for [$shortcode] - ID: $PAGE_ID"
                    echo "$PAGE_ID:$shortcode" >> "$SCAN_DIR/raw-outputs/test-pages.txt"
                fi
            done < "$SHORTCODES_FILE"
        fi
        
        # Create sample posts
        print_info "Creating sample content..."
        for i in {1..5}; do
            wp post create --post_type=post --post_status=publish \
                --post_title="Test Post $i for $plugin_name" \
                --post_content="This is test content for $plugin_name plugin testing. Lorem ipsum dolor sit amet." \
                --path="$WP_PATH" 2>/dev/null || true
        done
        print_success "Sample content created"
        
        # Check for custom post types and create sample data
        if [ "${CPT_COUNT:-0}" -gt 0 ]; then
            print_info "Detecting custom post types for test data..."
            
            # Try to extract CPT names
            CPT_NAMES=$(grep -r "register_post_type\s*(\s*['\"]" "$PLUGIN_PATH" --include="*.php" 2>/dev/null | \
                sed -E "s/.*register_post_type\s*\(\s*['\"]([^'\"]+).*/\1/" | \
                grep -v "^post$\|^page$" | \
                sort -u | head -5)
            
            if [ -n "$CPT_NAMES" ]; then
                for cpt in $CPT_NAMES; do
                    print_info "Creating sample $cpt posts..."
                    for i in {1..3}; do
                        wp post create --post_type="$cpt" --post_status=publish \
                            --post_title="Test $cpt $i" \
                            --post_content="Sample content for custom post type: $cpt" \
                            --path="$WP_PATH" 2>/dev/null || true
                    done
                done
                print_success "Custom post type samples created"
            fi
        fi
    else
        print_warning "WP-CLI not available - skipping test data generation"
    fi
    
    # Calculate integration score
    INTEGRATION_SCORE=0
    INTEGRATION_SCORE=$((INTEGRATION_SCORE + (HOOKS_FOUND > 0 ? 20 : 0)))
    INTEGRATION_SCORE=$((INTEGRATION_SCORE + (DB_QUERIES > 0 ? 15 : 0)))
    INTEGRATION_SCORE=$((INTEGRATION_SCORE + (CAPABILITY_CHECKS > 0 ? 15 : 0)))
    INTEGRATION_SCORE=$((INTEGRATION_SCORE + (REST_ROUTES > 0 ? 10 : 0)))
    INTEGRATION_SCORE=$((INTEGRATION_SCORE + (TOTAL_ADMIN_PAGES > 0 ? 10 : 0)))
    INTEGRATION_SCORE=$((INTEGRATION_SCORE + (SHORTCODES > 0 ? 10 : 0)))
    INTEGRATION_SCORE=$((INTEGRATION_SCORE + (WIDGETS > 0 ? 10 : 0)))
    INTEGRATION_SCORE=$((INTEGRATION_SCORE + (BLOCKS > 0 ? 10 : 0)))
    
    # Generate report
    cat > "$INTEGRATION_REPORT" << EOF
# WordPress Integration Test Report
**Plugin**: $plugin_name  
**Date**: $(date)  
**Integration Score**: $INTEGRATION_SCORE/100

## Core WordPress Hooks
- Total hooks integrated: $HOOKS_FOUND
$(echo -e "$HOOK_DETAILS")

## Database Integration
- Custom tables: $DB_TABLES
- Database operations: $DB_QUERIES

## User System Integration
- Capability checks: $CAPABILITY_CHECKS
- Custom capabilities: $CUSTOM_CAPS

## REST API
- Endpoints registered: $REST_ROUTES

## Admin Interface
- Menu pages: $MENU_PAGES
- Submenu pages: $SUBMENU_PAGES
- Settings pages: $SETTINGS_PAGES
- **Total admin pages**: $TOTAL_ADMIN_PAGES

## Content Integration
- Shortcodes: $SHORTCODES
- Widgets: $WIDGETS
- Gutenberg blocks: $BLOCKS

## Integration Analysis
$(if [ $HOOKS_FOUND -eq 0 ]; then
    echo "- � No core WordPress hooks found - plugin may not integrate properly"
fi)
$(if [ $CAPABILITY_CHECKS -eq 0 ]; then
    echo "- � No capability checks found - security concern"
fi)
$(if [ $TOTAL_ADMIN_PAGES -eq 0 ] && [ $SHORTCODES -eq 0 ]; then
    echo "- � No user interface detected"
fi)

## Recommendations
$(if [ $INTEGRATION_SCORE -lt 50 ]; then
    echo "- Plugin has minimal WordPress integration"
    echo "- Consider adding more WordPress-specific features"
fi)
$(if [ $REST_ROUTES -eq 0 ]; then
    echo "- Consider adding REST API support for modern integrations"
fi)
$(if [ $BLOCKS -eq 0 ]; then
    echo "- Consider adding Gutenberg block support"
fi)
EOF
    
    print_success "Integration tests complete - Score: $INTEGRATION_SCORE/100"
    
    # Save phase results
    save_phase_results "09" "completed"
    
    # Interactive checkpoint
    checkpoint 9 "Integration tests complete. Ready for documentation generation."
    
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