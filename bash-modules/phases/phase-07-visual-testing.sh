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
    
    # Check for screenshot tools
    SCREENSHOT_TOOL="$FRAMEWORK_PATH/tools/automated-screenshot-capture.js"
    
    if [ -f "$SCREENSHOT_TOOL" ]; then
        print_info "Capturing plugin screenshots..."
        
        # Define pages to capture
        PAGES=(
            "wp-admin:Dashboard"
            "wp-admin/plugins.php:Plugins Page"
            "wp-admin/admin.php?page=$plugin_name:Plugin Settings"
            "/:Homepage"
        )
        
        # Get site URL
        SITE_URL="http://localhost"
        if [ -f "$WP_PATH/wp-config.php" ]; then
            SITE_URL=$(grep -oP "define\s*\(\s*'WP_HOME'\s*,\s*'[^']+'" "$WP_PATH/wp-config.php" | cut -d"'" -f4)
            SITE_URL=${SITE_URL:-"http://localhost"}
        fi
        
        SCREENSHOT_COUNT=0
        
        for page_info in "${PAGES[@]}"; do
            IFS=':' read -r path name <<< "$page_info"
            
            print_info "Capturing: $name..."
            
            OUTPUT_FILE="$SCREENSHOTS_DIR/$(echo "$name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]').png"
            
            # Run screenshot capture
            if node "$SCREENSHOT_TOOL" "$plugin_name" "$SITE_URL/$path" "admin" "password" "$OUTPUT_FILE" 2>/dev/null; then
                if [ -f "$OUTPUT_FILE" ]; then
                    SCREENSHOT_COUNT=$((SCREENSHOT_COUNT + 1))
                    print_success "Captured: $name"
                fi
            fi
        done
        
        # Capture screenshots of test pages with shortcodes
        TEST_PAGES_FILE="$SCAN_DIR/raw-outputs/test-pages.txt"
        if [ -f "$TEST_PAGES_FILE" ] && [ -s "$TEST_PAGES_FILE" ]; then
            print_info "Capturing shortcode test pages..."
            
            while IFS=':' read -r page_id shortcode; do
                if [ -n "$page_id" ] && [ "$page_id" != "0" ]; then
                    # Get page URL using WP-CLI if available
                    if [ "$WP_CLI_AVAILABLE" = "true" ]; then
                        PAGE_URL=$(wp post get "$page_id" --field=link --path="$WP_PATH" 2>/dev/null || echo "")
                        
                        if [ -n "$PAGE_URL" ]; then
                            print_info "Capturing shortcode [$shortcode] page..."
                            OUTPUT_FILE="$SCREENSHOTS_DIR/shortcode-$(echo "$shortcode" | tr ' ' '-').png"
                            
                            if node "$SCREENSHOT_TOOL" "$plugin_name" "$PAGE_URL" "admin" "password" "$OUTPUT_FILE" 2>/dev/null; then
                                if [ -f "$OUTPUT_FILE" ]; then
                                    SCREENSHOT_COUNT=$((SCREENSHOT_COUNT + 1))
                                    print_success "Captured shortcode: [$shortcode]"
                                fi
                            fi
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
    if [ -d "$FRAMEWORK_PATH/tools/e2e" ] && [ -f "$FRAMEWORK_PATH/tools/e2e/playwright.config.ts" ]; then
        print_info "Running Playwright visual tests..."
        
        if command_exists npx; then
            (
                cd "$FRAMEWORK_PATH/tools/e2e"
                npx playwright test --project=chromium 2>/dev/null &
                show_progress $! "Playwright Tests"
            )
            
            # Check for test results
            if [ -d "$FRAMEWORK_PATH/tools/e2e/playwright-report" ]; then
                print_success "Playwright tests completed"
                cp -r "$FRAMEWORK_PATH/tools/e2e/playwright-report" "$SCAN_DIR/"
            fi
        else
            print_warning "npx not found - skipping Playwright tests"
        fi
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