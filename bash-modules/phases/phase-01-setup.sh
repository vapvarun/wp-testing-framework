#!/bin/bash

# Phase 1: Setup & Directory Structure
# Creates directory structure and initializes environment

# Set MODULES_PATH if not already set (for standalone execution)
if [ -z "$MODULES_PATH" ]; then
    MODULES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
fi

# Source common functions
source "$MODULES_PATH/shared/common-functions.sh"

run_phase_01() {
    local plugin_name=$1
    
    print_phase 1 "Setup & Directory Structure"
    
    # Create timestamp
    DATE_MONTH=$(date +"%Y-%m")
    TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
    
    # Define directories
    SCAN_DIR="$UPLOAD_PATH/wbcom-scan/$plugin_name/$DATE_MONTH"
    PLAN_DIR="$UPLOAD_PATH/wbcom-plan/$plugin_name/$DATE_MONTH"
    SAFEKEEP_DIR="$FRAMEWORK_PATH/plugins/$plugin_name"
    
    # Export for other phases
    export SCAN_DIR
    export PLAN_DIR
    export SAFEKEEP_DIR
    export TIMESTAMP
    
    print_info "Creating directory structure..."
    
    # Create all required directories
    ensure_directory "$SCAN_DIR/raw-outputs"
    ensure_directory "$SCAN_DIR/raw-outputs/coverage"
    ensure_directory "$SCAN_DIR/ai-analysis"
    ensure_directory "$SCAN_DIR/reports"
    ensure_directory "$SCAN_DIR/generated-tests"
    ensure_directory "$SCAN_DIR/phase-results"
    ensure_directory "$PLAN_DIR/documentation"
    ensure_directory "$PLAN_DIR/test-results"
    ensure_directory "$SAFEKEEP_DIR/developer-tasks"
    ensure_directory "$SAFEKEEP_DIR/final-reports-$TIMESTAMP"
    
    print_success "Directory structure created"
    
    # Check system requirements
    print_info "Checking system requirements..."
    check_php
    check_nodejs
    check_wp_cli
    
    # Validate plugin
    validate_plugin
    
    # Get plugin metadata
    get_plugin_metadata
    
    # Create initial scan info
    cat > "$SCAN_DIR/scan-info.json" << EOF
{
    "plugin": "$plugin_name",
    "timestamp": "$TIMESTAMP",
    "date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "framework_version": "12.0",
    "mode": "$TEST_TYPE",
    "paths": {
        "scan": "$SCAN_DIR",
        "plan": "$PLAN_DIR",
        "safekeep": "$SAFEKEEP_DIR",
        "plugin": "$PLUGIN_PATH"
    },
    "metadata": {
        "version": "$PLUGIN_VERSION",
        "author": "$PLUGIN_AUTHOR",
        "description": "$PLUGIN_DESCRIPTION"
    }
}
EOF
    
    print_success "Scan initialized"
    
    # Save phase results
    save_phase_results "01" "completed"
    
    # Interactive checkpoint
    checkpoint 1 "Setup complete. Ready to begin plugin analysis."
    
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
    MODULES_PATH="$FRAMEWORK_PATH/bash-modules"
    WP_PATH="$(dirname "$FRAMEWORK_PATH")"
    PLUGIN_PATH="$WP_PATH/wp-content/plugins/$PLUGIN_NAME"
    UPLOAD_PATH="$WP_PATH/wp-content/uploads"
    TEST_TYPE=${TEST_TYPE:-full}
    
    # Set scan directory
    DATE_MONTH=$(date +"%Y-%m")
    SCAN_DIR="$UPLOAD_PATH/wbcom-scan/$PLUGIN_NAME/$DATE_MONTH"
    
    # Export all required variables
    export PLUGIN_NAME FRAMEWORK_PATH MODULES_PATH WP_PATH PLUGIN_PATH UPLOAD_PATH SCAN_DIR TEST_TYPE
    
    # Run the phase
    run_phase_01 "$PLUGIN_NAME"
fi