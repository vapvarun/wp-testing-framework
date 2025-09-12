#!/bin/bash

# Phase 7 Enhanced: Test Generation + Test Data Creation
# Combines test generation with test data creation

# Set default MODULES_PATH if not already set
if [ -z "$MODULES_PATH" ]; then
    MODULES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
fi

# Source common functions
source "$MODULES_PATH/shared/common-functions.sh"

# Source the original test generation
source "$MODULES_PATH/phases/phase-07-test-generation.sh"

# Source the test data creation
source "$MODULES_PATH/phases/phase-07b-test-data-creation.sh"

# Source the AI test data generation
source "$MODULES_PATH/phases/phase-07-ai-test-data.sh"

# Wrapper function that runs all three
run_phase_07() {
    local plugin_name=$1
    
    print_phase "7" "Complete Test Setup (Generation + AI Data + Test Data)"
    
    # Run original test generation
    print_info "Part 1: PHPUnit Test Generation"
    if run_phase_07_test_generation "$plugin_name"; then
        print_success "Test generation complete"
    else
        print_warning "Test generation had issues"
    fi
    
    # Run AI test data generation
    print_info "Part 2: AI Test Data Generation"
    if run_phase_07_ai_test_data "$plugin_name"; then
        print_success "AI test data generation complete"
    else
        print_warning "AI test data generation had issues"
    fi
    
    # Run test data creation
    print_info "Part 3: Test Data Creation"
    if run_phase_07b "$plugin_name"; then
        print_success "Test data creation complete"
    else
        print_warning "Test data creation had issues"
    fi
    
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
    
    # Load scan directory
    DATE_MONTH=$(date +"%Y-%m")
    SCAN_DIR="$UPLOAD_PATH/wbcom-scan/$PLUGIN_NAME/$DATE_MONTH"
    
    # Run the complete phase
    run_phase_07 "$PLUGIN_NAME"
fi