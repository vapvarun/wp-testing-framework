#!/bin/bash

# Phase 3: WordPress Plugin Check Integration
# This phase runs the official WordPress Plugin Check tool to analyze plugin compliance
# Runs early so AI and other analysis phases can use the data

# Set default MODULES_PATH if not already set
if [ -z "$MODULES_PATH" ]; then
    MODULES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
fi

# Source common functions
source "$MODULES_PATH/shared/common-functions.sh"

# Main phase function
run_phase_03() {
    local plugin_name="${1:-}"
    if [ -z "$plugin_name" ]; then
        print_error "Plugin name required"
        return 1
    fi

    print_phase 3 "WordPress Plugin Check Analysis"

    # Initialize paths
    WP_CONTENT_PATH="${WP_CONTENT_PATH:-/Users/varundubey/Local Sites/wptesting/app/public/wp-content}"
    PLUGIN_PATH="$WP_CONTENT_PATH/plugins/$plugin_name"
    SCAN_DIR="$WP_CONTENT_PATH/uploads/wbcom-scan/$plugin_name/$(date +%Y-%m)"
    PLUGIN_CHECK_DIR="$SCAN_DIR/plugin-check"
    
    # Create directory for plugin check results
    mkdir -p "$PLUGIN_CHECK_DIR"

    # Validate plugin
    if [ ! -d "$PLUGIN_PATH" ]; then
        print_error "Plugin not found: $PLUGIN_PATH"
        return 1
    fi

    print_info "Running WordPress Plugin Check analysis for: $plugin_name"
    
    # Plugin Check path
    PLUGIN_CHECK_PATH="$WP_CONTENT_PATH/plugins/plugin-check"
    
    # Ensure Plugin Check is installed
    if [ ! -d "$PLUGIN_CHECK_PATH" ]; then
        print_warning "Plugin Check not found. Installing..."
        wp plugin install plugin-check --quiet
    fi
    
    # Setup Plugin Check dependencies
    print_subsection "Setting up Plugin Check dependencies"
    
    # Check and install composer dependencies
    if [ -f "$PLUGIN_CHECK_PATH/composer.json" ]; then
        print_info "Installing Composer dependencies for Plugin Check..."
        cd "$PLUGIN_CHECK_PATH"
        
        if command -v composer >/dev/null 2>&1; then
            composer install --no-dev --quiet 2>/dev/null || {
                print_warning "Composer install failed. Trying with --ignore-platform-reqs..."
                composer install --no-dev --quiet --ignore-platform-reqs 2>/dev/null || true
            }
        else
            print_warning "Composer not found. Some Plugin Check features may be limited."
        fi
        
        cd - > /dev/null
    fi
    
    # Check and install npm dependencies if package.json exists
    if [ -f "$PLUGIN_CHECK_PATH/package.json" ]; then
        print_info "Installing npm dependencies for Plugin Check..."
        cd "$PLUGIN_CHECK_PATH"
        
        if command -v npm >/dev/null 2>&1; then
            # Check if node_modules exists, if not, install
            if [ ! -d "node_modules" ]; then
                npm install --silent 2>/dev/null || {
                    print_warning "npm install failed. Trying with --force..."
                    npm install --force --silent 2>/dev/null || true
                }
            fi
            
            # Build if needed
            if [ -f "package.json" ] && grep -q '"build"' package.json; then
                npm run build --silent 2>/dev/null || true
            fi
        else
            print_warning "npm not found. Some Plugin Check features may be limited."
        fi
        
        cd - > /dev/null
    fi
    
    # Activate Plugin Check if not active
    if ! wp plugin is-active plugin-check 2>/dev/null; then
        print_info "Activating Plugin Check..."
        wp plugin activate plugin-check --quiet
    fi

    # Setup environment for our test plugin's dependencies
    print_subsection "Preparing target plugin dependencies"
    
    # Check if target plugin needs npm/composer setup
    if [ -f "$PLUGIN_PATH/package.json" ]; then
        print_info "Installing npm dependencies for $plugin_name..."
        cd "$PLUGIN_PATH"
        if command -v npm >/dev/null 2>&1 && [ ! -d "node_modules" ]; then
            npm install --silent 2>/dev/null || true
        fi
        cd - > /dev/null
    fi
    
    if [ -f "$PLUGIN_PATH/composer.json" ]; then
        print_info "Installing composer dependencies for $plugin_name..."
        cd "$PLUGIN_PATH"
        if command -v composer >/dev/null 2>&1 && [ ! -d "vendor" ]; then
            composer install --no-dev --quiet 2>/dev/null || true
        fi
        cd - > /dev/null
    fi
    
    # Run comprehensive plugin check with all available checks
    print_subsection "Running All Plugin Checks"
    
    # Save results in multiple formats
    local json_output="$PLUGIN_CHECK_DIR/plugin-check-full.json"
    local table_output="$PLUGIN_CHECK_DIR/plugin-check-full.txt"
    local csv_output="$PLUGIN_CHECK_DIR/plugin-check-full.csv"
    
    # Run full check and save JSON output
    print_info "Generating comprehensive JSON report..."
    wp plugin check "$plugin_name" --format=json --include-experimental > "$json_output" 2>&1
    
    # Run check with table format for readability
    print_info "Generating readable table report..."
    wp plugin check "$plugin_name" --format=table --include-experimental > "$table_output" 2>&1
    
    # Run check with CSV format for data processing
    print_info "Generating CSV report for data processing..."
    wp plugin check "$plugin_name" --format=csv --include-experimental > "$csv_output" 2>&1
    
    # Run specific category checks
    print_subsection "Running Category-Specific Checks"
    
    # Security-focused checks
    print_info "Running security-focused checks..."
    local security_checks="late_escaping,direct_db_queries,non_blocking_scripts"
    wp plugin check "$plugin_name" --checks="$security_checks" --format=json > "$PLUGIN_CHECK_DIR/plugin-check-security.json" 2>&1
    
    # Performance-focused checks
    print_info "Running performance-focused checks..."
    local performance_checks="enqueued_scripts_in_footer,enqueued_scripts_size,enqueued_styles_size"
    wp plugin check "$plugin_name" --checks="$performance_checks" --format=json > "$PLUGIN_CHECK_DIR/plugin-check-performance.json" 2>&1 || true
    
    # Internationalization checks
    print_info "Running i18n checks..."
    local i18n_checks="i18n_usage"
    wp plugin check "$plugin_name" --checks="$i18n_checks" --format=json > "$PLUGIN_CHECK_DIR/plugin-check-i18n.json" 2>&1 || true
    
    # Run update mode check (for existing plugins)
    print_info "Running update mode analysis..."
    wp plugin check "$plugin_name" --mode=update --format=json > "$PLUGIN_CHECK_DIR/plugin-check-update-mode.json" 2>&1 || true
    
    # Parse and generate insights report
    print_subsection "Generating Plugin Check Insights"
    
    local insights_file="$PLUGIN_CHECK_DIR/plugin-check-insights.md"
    
    cat > "$insights_file" << EOF
# WordPress Plugin Check Insights for $plugin_name
Generated: $(date)

## Overview
This report provides insights from the WordPress Plugin Check tool analysis.

## Check Summary
EOF

    # Parse JSON results to extract key findings
    if [ -f "$json_output" ] && [ -s "$json_output" ]; then
        # Count errors and warnings
        local error_count=$(grep -o '"type":"ERROR"' "$json_output" 2>/dev/null | wc -l || echo "0")
        local warning_count=$(grep -o '"type":"WARNING"' "$json_output" 2>/dev/null | wc -l || echo "0")
        
        cat >> "$insights_file" << EOF

### Statistics
- **Total Errors:** $error_count
- **Total Warnings:** $warning_count

### Categories Analyzed
EOF

        # Extract unique categories
        if command -v jq >/dev/null 2>&1; then
            print_info "Extracting detailed insights using jq..."
            
            # Get unique categories
            local categories=$(jq -r '.[].category // empty' "$json_output" 2>/dev/null | sort -u)
            if [ ! -z "$categories" ]; then
                echo "$categories" | while read -r category; do
                    echo "- $category" >> "$insights_file"
                done
            fi
            
            # Extract critical issues
            cat >> "$insights_file" << EOF

## Critical Issues to Fix

### Errors
EOF
            
            # List errors with details
            jq -r '.[] | select(.type == "ERROR") | "- **\(.code // "Unknown")**: \(.message // "No message") [\(.file // "Unknown file"):\(.line // 0)]"' "$json_output" 2>/dev/null >> "$insights_file" || echo "No errors found or unable to parse." >> "$insights_file"
            
            cat >> "$insights_file" << EOF

### Warnings
EOF
            
            # List warnings with details
            jq -r '.[] | select(.type == "WARNING") | "- **\(.code // "Unknown")**: \(.message // "No message") [\(.file // "Unknown file"):\(.line // 0)]"' "$json_output" 2>/dev/null | head -20 >> "$insights_file" || echo "No warnings found or unable to parse." >> "$insights_file"
            
            # Generate fix recommendations
            cat >> "$insights_file" << EOF

## Recommended Fixes

Based on the Plugin Check analysis, here are the recommended actions:

EOF
            
            # Check for specific issues and provide recommendations
            if grep -q "late_escaping" "$json_output" 2>/dev/null; then
                cat >> "$insights_file" << EOF
### Escaping Issues
- Review all output statements and ensure proper escaping using functions like esc_html(), esc_attr(), esc_url()
- Pay special attention to user input and database output

EOF
            fi
            
            if grep -q "direct_db_queries" "$json_output" 2>/dev/null; then
                cat >> "$insights_file" << EOF
### Database Query Issues
- Replace direct database queries with WordPress API functions when possible
- Use \$wpdb->prepare() for all custom queries to prevent SQL injection
- Consider using WP_Query for post-related queries

EOF
            fi
            
            if grep -q "i18n_usage" "$json_output" 2>/dev/null; then
                cat >> "$insights_file" << EOF
### Internationalization Issues
- Wrap all user-facing strings in translation functions (__(), _e(), etc.)
- Ensure text domain is consistent throughout the plugin
- Load text domain properly in the main plugin file

EOF
            fi
            
        else
            # Fallback if jq is not available
            print_warning "jq not available. Using basic parsing..."
            
            # Basic parsing without jq
            echo "" >> "$insights_file"
            echo "### Raw Check Results" >> "$insights_file"
            echo '```' >> "$insights_file"
            head -100 "$table_output" >> "$insights_file" 2>/dev/null
            echo '```' >> "$insights_file"
        fi
    else
        echo "No Plugin Check results available or file is empty." >> "$insights_file"
    fi
    
    # Generate actionable summary
    cat >> "$insights_file" << EOF

## Integration with Testing Framework

The Plugin Check results have been saved in multiple formats:
- JSON: For programmatic processing and CI/CD integration
- Table: For human-readable review
- CSV: For spreadsheet analysis and reporting

These results can be integrated with:
1. **Security Scanner (Phase 4)**: Cross-reference security findings
2. **Performance Analysis (Phase 5)**: Combine with performance metrics
3. **Documentation (Phase 9)**: Include compliance status in docs
4. **Consolidation (Phase 10)**: Merge with overall test results

## Next Steps

1. Address all ERROR-level issues first
2. Review and fix WARNING-level issues
3. Consider implementing suggested best practices
4. Re-run Plugin Check after fixes to verify improvements
5. Use update mode for continuous monitoring

EOF

    print_success "Plugin Check analysis completed for $plugin_name"
    
    # Display summary
    print_info "Results saved to: $PLUGIN_CHECK_DIR"
    
    if [ -f "$insights_file" ]; then
        print_subsection "Quick Summary"
        echo ""
        head -30 "$insights_file"
        echo ""
        echo "... (full report available in $insights_file)"
    fi
    
    # Save phase completion marker
    echo "$(date): Phase 3 - Plugin Check completed for $plugin_name" >> "$SCAN_DIR/phase-completion.log"
    
    return 0
}

# Export the function for use by the main test runner
export -f run_phase_03