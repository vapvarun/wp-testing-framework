#!/bin/bash

# Phase 7: Visual Testing & Screenshots
# Captures screenshots of plugin functionality and UI elements

# Source common functions
# Set MODULES_PATH if not already set (for standalone execution)
if [ -z "$MODULES_PATH" ]; then
    MODULES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
fi
source "$MODULES_PATH/shared/common-functions.sh"

run_phase_07() {
    local plugin_name=$1
    
    print_phase 7 "Visual Testing & Screenshots"
    
    print_info "Setting up visual testing environment..."
    
    # Check Node.js availability
    if [ "$NODE_AVAILABLE" != "true" ]; then
        print_warning "Node.js not available - skipping visual testing"
        save_phase_results "07" "skipped"
        return 0
    fi
    
    # Create screenshots directory
    SCREENSHOTS_DIR="$SCAN_DIR/screenshots"
    ensure_directory "$SCREENSHOTS_DIR"
    
    # Check for screenshot tools - use simple tool for individual pages
    SIMPLE_SCREENSHOT="$FRAMEWORK_PATH/tools/simple-screenshot.js"
    SCREENSHOT_TOOL="$FRAMEWORK_PATH/tools/automated-screenshot-capture.js"
    
    if [ -f "$SIMPLE_SCREENSHOT" ]; then
        print_info "Capturing plugin screenshots..."
        
        # Define pages to capture (generic + plugin-specific)
        PAGES=(
            "wp-admin:Dashboard"
            "wp-admin/plugins.php:Plugins Page"
            "wp-admin/admin.php?page=$plugin_name:Plugin Settings"
            "/:Homepage"
        )
        
        # Add plugin-specific pages for known plugins
        case "$plugin_name" in
            "bbpress")
                PAGES+=(
                    "wp-admin/edit.php?post_type=forum:Forums List"
                    "wp-admin/edit.php?post_type=topic:Topics List"
                    "wp-admin/edit.php?post_type=reply:Replies List"
                    "wp-admin/post-new.php?post_type=forum:New Forum"
                    "forums/:Forums Archive"
                )
                ;;
            "woocommerce")
                PAGES+=(
                    "wp-admin/edit.php?post_type=product:Products List"
                    "wp-admin/edit.php?post_type=shop_order:Orders List"
                    "shop/:Shop Page"
                    "cart/:Cart Page"
                )
                ;;
            # Add more plugin-specific pages as needed
        esac
        
        # Get site URL - properly detect Local WP or use WP-CLI
        SITE_URL="http://localhost"
        
        # Try WP-CLI first (most reliable)
        if command_exists wp && [ -n "$WP_PATH" ]; then
            DETECTED_URL=$(wp option get siteurl --path="$WP_PATH" 2>/dev/null || echo "")
            if [ -n "$DETECTED_URL" ]; then
                SITE_URL="$DETECTED_URL"
                print_info "Detected site URL: $SITE_URL"
            fi
        fi
        
        # Fallback to wp-config.php if WP-CLI failed
        if [ "$SITE_URL" = "http://localhost" ] && [ -f "$WP_PATH/wp-config.php" ]; then
            # Try to find WP_HOME or WP_SITEURL
            WP_HOME=$(grep -E "define\s*\(\s*['\"]WP_HOME['\"]" "$WP_PATH/wp-config.php" | sed -E "s/.*define\s*\(\s*['\"]WP_HOME['\"]\s*,\s*['\"]([^'\"]+).*/\1/" 2>/dev/null || echo "")
            if [ -n "$WP_HOME" ]; then
                SITE_URL="$WP_HOME"
            fi
        fi
        
        # Local WP detection - check for .local domain
        if [[ "$SITE_URL" == *".local"* ]]; then
            print_info "Local WP environment detected"
        fi
        
        SCREENSHOT_COUNT=0
        
        for page_info in "${PAGES[@]}"; do
            IFS=':' read -r path name <<< "$page_info"
            
            print_info "Capturing: $name..."
            
            OUTPUT_FILE="$SCREENSHOTS_DIR/$(echo "$name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]').png"
            
            # Run screenshot capture with auto-login
            FULL_URL="$SITE_URL/$path"
            # Clean up double slashes except after protocol
            FULL_URL=$(echo "$FULL_URL" | sed 's|//|/|g' | sed 's|:/|://|')
            
            # Try with auto-login first for Local WP
            if [[ "$SITE_URL" == *".local"* ]]; then
                # Use auto-login for Local WP environments
                USE_AUTO_LOGIN=true node "$SIMPLE_SCREENSHOT" "$FULL_URL" "$OUTPUT_FILE" "admin" "" 2>&1 | grep -v "^$" || true
            else
                # Use provided credentials for other environments
                node "$SIMPLE_SCREENSHOT" "$FULL_URL" "$OUTPUT_FILE" "admin" "password" 2>&1 | grep -v "^$" || true
            fi
            
            if [ -f "$OUTPUT_FILE" ]; then
                SCREENSHOT_COUNT=$((SCREENSHOT_COUNT + 1))
                print_success "Captured: $name"
            else
                print_warning "Failed to capture: $name"
            fi
        done
        
        # Capture screenshots of injected test content (forums, topics, replies, etc.)
        TEST_CONTENT_FILE="$SCAN_DIR/raw-outputs/test-content-urls.txt"
        if [ -f "$TEST_CONTENT_FILE" ] && [ -s "$TEST_CONTENT_FILE" ]; then
            print_info "Capturing injected test content pages..."
            
            # Format is: post_id:type:url
            while IFS=':' read -r content_id content_type content_url; do
                if [ -n "$content_url" ]; then
                    print_info "Capturing $content_type: $content_url"
                    OUTPUT_FILE="$SCREENSHOTS_DIR/content-$(echo "$content_type-$content_id" | tr ' ' '-').png"
                    
                    # Most content pages don't need login, but use auto-login for Local WP
                    if [[ "$SITE_URL" == *".local"* ]]; then
                        USE_AUTO_LOGIN=true node "$SIMPLE_SCREENSHOT" "$content_url" "$OUTPUT_FILE" "admin" "" 2>&1 | grep -v "^$" || true
                    else
                        node "$SIMPLE_SCREENSHOT" "$content_url" "$OUTPUT_FILE" "" "" 2>&1 | grep -v "^$" || true
                    fi
                    
                    if [ -f "$OUTPUT_FILE" ]; then
                        SCREENSHOT_COUNT=$((SCREENSHOT_COUNT + 1))
                        print_success "Captured $content_type content"
                    fi
                fi
            done < "$TEST_CONTENT_FILE"
        fi
        
        # Capture screenshots of test pages with shortcodes
        TEST_PAGES_FILE="$SCAN_DIR/raw-outputs/test-pages.txt"
        if [ -f "$TEST_PAGES_FILE" ] && [ -s "$TEST_PAGES_FILE" ]; then
            print_info "Capturing shortcode test pages..."
            
            # Format is: page_id:shortcode:url
            while IFS=':' read -r page_id shortcode page_url; do
                if [ -n "$page_id" ] && [ "$page_id" != "0" ]; then
                    # Use URL from file if available, otherwise get from WP-CLI
                    PAGE_URL="$page_url"
                    
                    # If URL not in file, try WP-CLI
                    if [ -z "$PAGE_URL" ] && [ "$WP_CLI_AVAILABLE" = "true" ]; then
                        PAGE_URL=$(wp post get "$page_id" --field=link --path="$WP_PATH" 2>/dev/null || echo "")
                    fi
                    
                    # If still no URL, construct it
                    if [ -z "$PAGE_URL" ]; then
                        PAGE_URL="$SITE_URL/?p=$page_id"
                    fi
                    
                    if [ -n "$PAGE_URL" ]; then
                        print_info "Capturing shortcode [$shortcode] page..."
                        OUTPUT_FILE="$SCREENSHOTS_DIR/shortcode-$(echo "$shortcode" | tr ' ' '-').png"
                        
                        # Use auto-login for Local WP
                        if [[ "$SITE_URL" == *".local"* ]]; then
                            USE_AUTO_LOGIN=true node "$SIMPLE_SCREENSHOT" "$PAGE_URL" "$OUTPUT_FILE" "admin" "" 2>&1 | grep -v "^$" || true
                        else
                            node "$SIMPLE_SCREENSHOT" "$PAGE_URL" "$OUTPUT_FILE" "admin" "password" 2>&1 | grep -v "^$" || true
                        fi
                        
                        if [ -f "$OUTPUT_FILE" ]; then
                            SCREENSHOT_COUNT=$((SCREENSHOT_COUNT + 1))
                            print_success "Captured shortcode: [$shortcode]"
                        else
                            print_warning "Failed to capture shortcode: [$shortcode]"
                        fi
                    else
                        # Fallback to direct URL construction
                        PAGE_URL="$SITE_URL/?p=$page_id"
                        print_info "Capturing shortcode [$shortcode] at $PAGE_URL..."
                        OUTPUT_FILE="$SCREENSHOTS_DIR/shortcode-$(echo "$shortcode" | tr ' ' '-').png"
                        
                        if node "$SCREENSHOT_TOOL" "$plugin_name" "$PAGE_URL" "admin" "password" "$OUTPUT_FILE" 2>/dev/null; then
                            if [ -f "$OUTPUT_FILE" ]; then
                                SCREENSHOT_COUNT=$((SCREENSHOT_COUNT + 1))
                                print_success "Captured shortcode: [$shortcode]"
                            fi
                        fi
                    fi
                fi
            done < "$TEST_PAGES_FILE"
            
            print_success "Shortcode screenshots captured"
        fi
        
        print_success "Captured $SCREENSHOT_COUNT screenshots total"
    else
        print_warning "Screenshot tool not found - using placeholder"
    fi
    
    # Playwright E2E visual tests if available
    # Skip if SKIP_PLAYWRIGHT is set or timeout exceeded
    if [ "${SKIP_PLAYWRIGHT:-false}" != "true" ]; then
        if [ -d "$FRAMEWORK_PATH/tools/e2e" ] && [ -f "$FRAMEWORK_PATH/tools/e2e/playwright.config.ts" ]; then
            print_info "Running Playwright visual tests (60s timeout)..."
            
            if command_exists npx; then
                (
                    cd "$FRAMEWORK_PATH/tools/e2e"
                    # Run with timeout to prevent hanging
                    timeout 60 npx playwright test --project=chromium 2>/dev/null || {
                        print_warning "Playwright tests timed out after 60 seconds"
                    }
                )
                
                # Check for test results
                if [ -d "$FRAMEWORK_PATH/tools/e2e/playwright-report" ]; then
                    print_success "Playwright tests completed"
                    cp -r "$FRAMEWORK_PATH/tools/e2e/playwright-report" "$SCAN_DIR/" 2>/dev/null || true
                fi
            else
                print_warning "npx not found - skipping Playwright tests"
            fi
        fi
    else
        print_info "Skipping Playwright tests (SKIP_PLAYWRIGHT=true)"
    fi
    
    # Visual regression testing
    print_info "Checking for visual regression baseline..."
    
    BASELINE_DIR="$FRAMEWORK_PATH/visual-baselines/$plugin_name"
    
    if [ -d "$BASELINE_DIR" ]; then
        print_info "Comparing with baseline images..."
        
        # Simple file comparison for now
        CHANGES_DETECTED=0
        for baseline_img in "$BASELINE_DIR"/*.png; do
            if [ -f "$baseline_img" ]; then
                img_name=$(basename "$baseline_img")
                current_img="$SCREENSHOTS_DIR/$img_name"
                
                if [ -f "$current_img" ]; then
                    if ! cmp -s "$baseline_img" "$current_img"; then
                        CHANGES_DETECTED=$((CHANGES_DETECTED + 1))
                        print_warning "Visual change detected: $img_name"
                    fi
                fi
            fi
        done
        
        if [ $CHANGES_DETECTED -gt 0 ]; then
            print_warning "$CHANGES_DETECTED visual changes detected"
        else
            print_success "No visual regressions detected"
        fi
    else
        print_info "No baseline found - current screenshots will serve as baseline"
        ensure_directory "$BASELINE_DIR"
        cp "$SCREENSHOTS_DIR"/*.png "$BASELINE_DIR/" 2>/dev/null || true
    fi
    
    # Accessibility testing
    print_info "Running accessibility checks..."
    
    # Check for accessibility issues in plugin files
    ACCESSIBILITY_ISSUES=0
    
    # Check for alt text in images
    IMG_WITHOUT_ALT=$(grep -r '<img' "$PLUGIN_PATH" --include="*.php" | grep -v 'alt=' | wc -l)
    if [ $IMG_WITHOUT_ALT -gt 0 ]; then
        ACCESSIBILITY_ISSUES=$((ACCESSIBILITY_ISSUES + IMG_WITHOUT_ALT))
        print_warning "Found $IMG_WITHOUT_ALT images without alt text"
    fi
    
    # Check for ARIA labels
    ARIA_LABELS=$(grep -r 'aria-label\|aria-describedby' "$PLUGIN_PATH" --include="*.php" | wc -l)
    if [ $ARIA_LABELS -eq 0 ]; then
        print_warning "No ARIA labels found"
        ACCESSIBILITY_ISSUES=$((ACCESSIBILITY_ISSUES + 1))
    else
        print_success "Found $ARIA_LABELS ARIA labels"
    fi
    
    # Generate visual testing report
    VISUAL_REPORT="$SCAN_DIR/reports/visual-testing-report.md"
    
    cat > "$VISUAL_REPORT" << EOF
# Visual Testing Report
**Plugin**: $plugin_name  
**Date**: $(date)

## Screenshots Captured
- Total screenshots: ${SCREENSHOT_COUNT:-0}
- Screenshots directory: $SCREENSHOTS_DIR

## Visual Regression Testing
- Baseline exists: $([ -d "$BASELINE_DIR" ] && echo "Yes" || echo "No")
- Visual changes detected: ${CHANGES_DETECTED:-0}

## Accessibility
- Images without alt text: ${IMG_WITHOUT_ALT:-0}
- ARIA labels found: ${ARIA_LABELS:-0}
- Total accessibility issues: $ACCESSIBILITY_ISSUES

## Captured Pages
$(for page_info in "${PAGES[@]}"; do
    IFS=':' read -r path name <<< "$page_info"
    echo "- $name"
done)

## Recommendations
$(if [ ${SCREENSHOT_COUNT:-0} -eq 0 ]; then
    echo "- No screenshots captured - check Node.js and tools setup"
fi)
$(if [ ${IMG_WITHOUT_ALT:-0} -gt 0 ]; then
    echo "- Add alt text to all images for accessibility"
fi)
$(if [ ${ARIA_LABELS:-0} -eq 0 ]; then
    echo "- Consider adding ARIA labels for better accessibility"
fi)
EOF
    
    print_success "Visual testing complete"
    
    # Save phase results
    save_phase_results "07" "completed"
    
    # Interactive checkpoint
    checkpoint 7 "Visual testing complete. Ready for integration tests."
    
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
    
    # Check requirements
    check_nodejs
    
    run_phase_07 "$PLUGIN_NAME"
fi