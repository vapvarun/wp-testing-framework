#!/bin/bash

# Phase 6: Test Generation & Coverage
# Generates PHPUnit tests and measures code coverage

# Source common functions
# Set MODULES_PATH if not already set (for standalone execution)
if [ -z "$MODULES_PATH" ]; then
    MODULES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
fi
source "$MODULES_PATH/shared/common-functions.sh"

run_phase_06() {
    local plugin_name=$1
    
    print_phase 6 "Test Generation & Coverage"
    
    print_info "Generating PHPUnit tests..."
    
    # Check PHP availability (check directly if not set)
    if [ -z "$PHP_AVAILABLE" ]; then
        if command -v php >/dev/null 2>&1; then
            export PHP_AVAILABLE=true
        else
            export PHP_AVAILABLE=false
        fi
    fi
    
    if [ "$PHP_AVAILABLE" != "true" ]; then
        print_error "PHP not available - cannot generate tests"
        save_phase_results "06" "failed"
        return 1
    fi
    
    # Create test directory
    TEST_DIR="$SCAN_DIR/generated-tests"
    ensure_directory "$TEST_DIR"
    
    # Generate basic test structure
    print_info "Creating test bootstrap..."
    
    cat > "$TEST_DIR/bootstrap.php" << 'EOF'
<?php
// PHPUnit Bootstrap for Plugin Testing
define('WP_USE_THEMES', false);

// Try to load WordPress test environment
$wp_tests = '/tmp/wordpress-tests-lib/includes/bootstrap.php';
if (file_exists($wp_tests)) {
    require_once $wp_tests;
} else {
    // Fallback to local WordPress
    $wp_load = dirname(__FILE__) . '/../../../../wp-load.php';
    if (file_exists($wp_load)) {
        require_once $wp_load;
    }
}
EOF
    
    # Generate PHPUnit configuration
    cat > "$TEST_DIR/phpunit.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<phpunit bootstrap="bootstrap.php"
         colors="true"
         convertErrorsToExceptions="true"
         convertNoticesToExceptions="true"
         convertWarningsToExceptions="true">
    <testsuites>
        <testsuite name="$plugin_name Test Suite">
            <directory>tests</directory>
        </testsuite>
    </testsuites>
    <coverage processUncoveredFiles="true">
        <include>
            <directory suffix=".php">$PLUGIN_PATH</directory>
        </include>
        <exclude>
            <directory>$PLUGIN_PATH/vendor</directory>
            <directory>$PLUGIN_PATH/tests</directory>
        </exclude>
    </coverage>
</phpunit>
EOF
    
    # Create tests directory
    ensure_directory "$TEST_DIR/tests"
    
    # Generate tests based on detected features
    print_info "Generating test cases..."
    
    # Use PHP test generator if available
    if [ -f "$FRAMEWORK_PATH/tools/generate-executable-tests.php" ]; then
        (
            cd "$FRAMEWORK_PATH"
            php tools/generate-executable-tests.php "$plugin_name" 2>/dev/null &
            show_progress $! "Test Generation"
        )
        
        # Count generated tests
        if [ -d "$TEST_DIR/tests" ]; then
            TEST_COUNT=$(find "$TEST_DIR/tests" -name "*Test.php" -type f 2>/dev/null | wc -l)
            print_success "Generated $TEST_COUNT test files"
        fi
    fi
    
    # Use AI-enhanced test generation if available
    if [ "$NODE_AVAILABLE" = "true" ] && [ -f "$FRAMEWORK_PATH/tools/ai/generate-smart-executable-tests.mjs" ]; then
        print_info "Running AI-enhanced test generation..."
        
        if [ -n "$ANTHROPIC_API_KEY" ]; then
            (
                cd "$FRAMEWORK_PATH"
                node tools/ai/generate-smart-executable-tests.mjs "$plugin_name" 2>/dev/null &
                show_progress $! "AI Test Generation"
            )
            print_success "AI-enhanced tests generated"
        else
            print_warning "ANTHROPIC_API_KEY not set - skipping AI test generation"
        fi
    fi
    
    # Run tests if PHPUnit is available
    print_info "Checking test execution capability..."
    
    # Check for PHPUnit (either global or via Composer)
    PHPUNIT_CMD=""
    if [ -f "$FRAMEWORK_PATH/vendor/bin/phpunit" ]; then
        PHPUNIT_CMD="$FRAMEWORK_PATH/vendor/bin/phpunit"
    elif command_exists phpunit; then
        PHPUNIT_CMD="phpunit"
    fi
    
    if [ -n "$PHPUNIT_CMD" ]; then
        print_info "Running generated tests with PHPUnit..."
        
        cd "$TEST_DIR"
        
        # Run tests with coverage if xdebug is available
        if php -m | grep -q xdebug; then
            print_info "Running tests with coverage..."
            COVERAGE_REPORT="$SCAN_DIR/raw-outputs/coverage/coverage.xml"
            ensure_directory "$(dirname "$COVERAGE_REPORT")"
            XDEBUG_MODE=coverage "$PHPUNIT_CMD" --coverage-clover="$COVERAGE_REPORT" 2>&1 | tail -20
            
            # Extract coverage percentage if report exists (macOS compatible)
            if [ -f "$COVERAGE_REPORT" ]; then
                COVERAGE=$(grep -o 'percent="[0-9.]*' "$COVERAGE_REPORT" | head -1 | cut -d'"' -f2)
                print_success "Code coverage: ${COVERAGE:-0}%"
            fi
        else
            print_warning "Xdebug not available - running tests without coverage"
            "$PHPUNIT_CMD" --no-coverage 2>&1 | tail -20
            COVERAGE=0
        fi
    else
        print_warning "PHPUnit not installed - tests generated but not executed"
        COVERAGE=0
    fi
    
    # Generate test report
    TEST_REPORT="$SCAN_DIR/reports/test-generation-report.md"
    
    cat > "$TEST_REPORT" << EOF
# Test Generation & Coverage Report
**Plugin**: $plugin_name  
**Date**: $(date)

## Test Generation Results
- Test files generated: ${TEST_COUNT:-0}
- Test directory: $TEST_DIR

## Code Coverage
- Coverage: ${COVERAGE:-0}%
- Coverage report: ${COVERAGE_REPORT:-"Not generated"}

## Test Types Generated
- Unit tests
- Integration tests (if applicable)
- Functional tests (if applicable)

## Recommendations
$(if [ "${TEST_COUNT:-0}" -eq 0 ]; then
    echo "- No tests were generated - check plugin structure"
fi)
$(if [ "${COVERAGE:-0}" -lt 50 ]; then
    echo "- Code coverage is low - add more test cases"
fi)
$(if ! command_exists phpunit; then
    echo "- Install PHPUnit to run tests: composer global require phpunit/phpunit"
fi)
EOF
    
    print_success "Test generation complete"
    
    # Save phase results
    save_phase_results "06" "completed"
    
    # Interactive checkpoint
    checkpoint 6 "Test generation complete. Ready for visual testing."
    
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
    MODULES_PATH="$FRAMEWORK_PATH/bash-modules"
    WP_PATH="$(dirname "$FRAMEWORK_PATH")"
    PLUGIN_PATH="$WP_PATH/wp-content/plugins/$PLUGIN_NAME"
    UPLOAD_PATH="$WP_PATH/wp-content/uploads"
    
    DATE_MONTH=$(date +"%Y-%m")
    SCAN_DIR="$UPLOAD_PATH/wbcom-scan/$PLUGIN_NAME/$DATE_MONTH"
    
    # Export required variables
    export PLUGIN_NAME FRAMEWORK_PATH MODULES_PATH WP_PATH PLUGIN_PATH UPLOAD_PATH SCAN_DIR
    
    # Check requirements
    check_php
    check_nodejs
    
    run_phase_06 "$PLUGIN_NAME"
fi