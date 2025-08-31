#!/bin/bash

# Phase 12: Framework Safekeeping
# Archives results and maintains framework integrity

# Source common functions
# Set MODULES_PATH if not already set (for standalone execution)
if [ -z "$MODULES_PATH" ]; then
    MODULES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
fi
source "$MODULES_PATH/shared/common-functions.sh"

run_phase_12() {
    local plugin_name=$1
    
    print_phase 12 "Framework Safekeeping"
    
    print_info "Archiving test results and maintaining framework..."
    
    # Safekeeping report
    SAFEKEEP_REPORT="$SCAN_DIR/reports/safekeeping-report.md"
    
    # Create safekeeping directories
    SAFEKEEP_BASE="$FRAMEWORK_PATH/safekeeping"
    ARCHIVE_DIR="$SAFEKEEP_BASE/archives"
    BACKUP_DIR="$SAFEKEEP_BASE/backups"
    HISTORY_DIR="$SAFEKEEP_BASE/history"
    
    ensure_directory "$SAFEKEEP_BASE"
    ensure_directory "$ARCHIVE_DIR"
    ensure_directory "$BACKUP_DIR"
    ensure_directory "$HISTORY_DIR"
    
    # Archive current scan results
    print_info "Archiving scan results..."
    
    ARCHIVE_NAME="${plugin_name}_$(date +"%Y%m%d_%H%M%S").tar.gz"
    ARCHIVE_PATH="$ARCHIVE_DIR/$ARCHIVE_NAME"
    
    if [ -d "$SCAN_DIR" ]; then
        tar -czf "$ARCHIVE_PATH" -C "$(dirname "$SCAN_DIR")" "$(basename "$SCAN_DIR")" 2>/dev/null
        
        if [ -f "$ARCHIVE_PATH" ]; then
            ARCHIVE_SIZE=$(du -h "$ARCHIVE_PATH" | cut -f1)
            print_success "Archived to: $ARCHIVE_NAME ($ARCHIVE_SIZE)"
        else
            print_warning "Failed to create archive"
        fi
    fi
    
    # Update scan history
    print_info "Updating scan history..."
    
    HISTORY_FILE="$HISTORY_DIR/scan-history.json"
    
    # Create or update history
    if [ ! -f "$HISTORY_FILE" ]; then
        echo "[]" > "$HISTORY_FILE"
    fi
    
    # Get scan summary
    OVERALL_SCORE=0
    CRITICAL_ISSUES=0
    
    if [ -f "$SCAN_DIR/summary.json" ]; then
        OVERALL_SCORE=$(grep -oP '"overall_score":\s*\d+' "$SCAN_DIR/summary.json" | grep -oP '\d+' || echo 0)
        CRITICAL_ISSUES=$(grep -oP '"critical_issues":\s*\d+' "$SCAN_DIR/summary.json" | grep -oP '\d+' || echo 0)
    fi
    
    # Add entry to history (simplified without jq)
    HISTORY_ENTRY="{
        \"plugin\": \"$plugin_name\",
        \"date\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\",
        \"score\": $OVERALL_SCORE,
        \"critical_issues\": $CRITICAL_ISSUES,
        \"archive\": \"$ARCHIVE_NAME\"
    }"
    
    # Append to history (simple approach)
    if [ -f "$HISTORY_FILE" ]; then
        # Remove last ']', add comma if needed, add new entry, close array
        sed -i.bak '$ s/]$//' "$HISTORY_FILE"
        if grep -q '\[.*\]' "$HISTORY_FILE"; then
            echo "]" >> "$HISTORY_FILE"
        else
            if [ $(wc -l < "$HISTORY_FILE") -gt 1 ]; then
                echo "," >> "$HISTORY_FILE"
            fi
            echo "$HISTORY_ENTRY" >> "$HISTORY_FILE"
            echo "]" >> "$HISTORY_FILE"
        fi
    fi
    
    print_success "Scan history updated"
    
    # Clean up old archives (older than 30 days)
    print_info "Cleaning up old archives..."
    
    CLEANED_COUNT=0
    find "$ARCHIVE_DIR" -name "*.tar.gz" -mtime +30 -type f | while read old_archive; do
        rm "$old_archive"
        CLEANED_COUNT=$((CLEANED_COUNT + 1))
        print_info "Removed old archive: $(basename "$old_archive")"
    done
    
    # Framework health check
    print_info "Performing framework health check..."
    
    HEALTH_STATUS="Good"
    HEALTH_ISSUES=()
    
    # Check core files
    CORE_FILES=(
        "test-plugin.sh"
        "test-plugin.ps1"
        "package.json"
        "README.md"
    )
    
    for file in "${CORE_FILES[@]}"; do
        if [ ! -f "$FRAMEWORK_PATH/$file" ]; then
            HEALTH_ISSUES+=("Missing core file: $file")
            HEALTH_STATUS="Warning"
        fi
    done
    
    # Check Node.js dependencies
    if [ -f "$FRAMEWORK_PATH/package.json" ] && [ ! -d "$FRAMEWORK_PATH/node_modules" ]; then
        HEALTH_ISSUES+=("Node modules not installed")
        HEALTH_STATUS="Warning"
    fi
    
    # Check PHP dependencies
    if [ -f "$FRAMEWORK_PATH/composer.json" ] && [ ! -d "$FRAMEWORK_PATH/vendor" ]; then
        HEALTH_ISSUES+=("Composer dependencies not installed")
        HEALTH_STATUS="Warning"
    fi
    
    # Backup framework configuration
    print_info "Backing up framework configuration..."
    
    CONFIG_BACKUP="$BACKUP_DIR/framework-config-$(date +"%Y%m%d").json"
    
    cat > "$CONFIG_BACKUP" << EOF
{
    "date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "framework_version": "12.0",
    "last_plugin": "$plugin_name",
    "health_status": "$HEALTH_STATUS",
    "php_version": "$(php -v 2>/dev/null | head -1 || echo "Not installed")",
    "node_version": "$(node -v 2>/dev/null || echo "Not installed")",
    "wp_cli": "$(wp --version 2>/dev/null || echo "Not installed")"
}
EOF
    
    # Update VERSION file
    echo "12.0" > "$FRAMEWORK_PATH/VERSION"
    
    # Calculate storage usage
    ARCHIVE_TOTAL=$(du -sh "$ARCHIVE_DIR" 2>/dev/null | cut -f1)
    SAFEKEEP_TOTAL=$(du -sh "$SAFEKEEP_BASE" 2>/dev/null | cut -f1)
    
    # Generate safekeeping report
    cat > "$SAFEKEEP_REPORT" << EOF
# Framework Safekeeping Report
**Date**: $(date)  
**Plugin Tested**: $plugin_name

## Archives
- Created: $ARCHIVE_NAME
- Size: ${ARCHIVE_SIZE:-Unknown}
- Location: $ARCHIVE_DIR
- Cleaned: $CLEANED_COUNT old archives

## Framework Health
- Status: $HEALTH_STATUS
$(if [ ${#HEALTH_ISSUES[@]} -gt 0 ]; then
    echo "- Issues:"
    for issue in "${HEALTH_ISSUES[@]}"; do
        echo "  - $issue"
    done
else
    echo "- No issues detected"
fi)

## Scan History
- Total scans recorded: $(grep -c '"plugin"' "$HISTORY_FILE" 2>/dev/null || echo 0)
- History file: $HISTORY_FILE

## Storage Usage
- Archives: ${ARCHIVE_TOTAL:-Unknown}
- Total Safekeeping: ${SAFEKEEP_TOTAL:-Unknown}

## Maintenance Tasks
-  Scan results archived
-  History updated
-  Old archives cleaned
-  Framework health checked
-  Configuration backed up
-  VERSION file updated

## Recommendations
$(if [ "$HEALTH_STATUS" = "Warning" ]; then
    echo "1. Address framework health issues"
fi)
$(if [ ! -d "$FRAMEWORK_PATH/node_modules" ]; then
    echo "2. Run 'npm install' to install Node.js dependencies"
fi)
$(if [ ! -d "$FRAMEWORK_PATH/vendor" ]; then
    echo "3. Run 'composer install' to install PHP dependencies"
fi)
$(if [ $(find "$ARCHIVE_DIR" -name "*.tar.gz" | wc -l) -gt 100 ]; then
    echo "4. Consider adjusting archive retention policy"
fi)
EOF
    
    print_success "Framework safekeeping complete"
    print_info "Archives stored in: $ARCHIVE_DIR"
    
    # Save phase results
    save_phase_results "12" "completed"
    
    # Final message
    echo ""
    echo -e "${GREEN}${NC}"
    echo -e "${GREEN}( All phases complete! Framework maintained and results archived.${NC}"
    echo -e "${GREEN}${NC}"
    
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
    
    run_phase_12 "$PLUGIN_NAME"
fi