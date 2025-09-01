#!/bin/bash

# Phase 6 Enhanced: Test Generation + Test Data Creation
# Combines test generation with test data creation

# Set default MODULES_PATH if not already set
if [ -z "$MODULES_PATH" ]; then
    MODULES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
fi

# Source common functions
source "$MODULES_PATH/shared/common-functions.sh"

# Source the original test generation
source "$MODULES_PATH/phases/phase-06-test-generation.sh"

# Source the new test data creation
source "$MODULES_PATH/phases/phase-06b-test-data-creation.sh"

# Wrapper function that runs both
run_phase_06_complete() {
    local plugin_name=$1
    
    print_info "Running Phase 6: Complete Test Setup"
    
    # Run original test generation
    print_info "Part 1: Test Generation"
    if run_phase_06 "$plugin_name"; then
        print_success "Test generation complete"
    else
        print_warning "Test generation had issues"
    fi
    
    # Run test data creation
    print_info "Part 2: Test Data Creation"
    if run_phase_06b "$plugin_name"; then
        print_success "Test data creation complete"
    else
        print_warning "Test data creation had issues"
    fi
    
    return 0
}