#!/bin/bash

# Phase 8: WordPress Integration Tests
# Tests plugin integration with WordPress core functionality

# Source common functions
source "$MODULES_PATH/shared/common-functions.sh"

run_phase_08() {
    local plugin_name=$1
    
    print_phase 8 "WordPress Integration Tests"
    
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
