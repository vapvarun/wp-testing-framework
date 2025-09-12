#!/bin/bash

# WordPress Plugin Testing Framework v13.0
# Main orchestrator - calls modular phase implementations
# Usage: ./test-plugin.sh <plugin-name> [mode] [options]

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export FRAMEWORK_PATH="$SCRIPT_DIR"
export MODULES_PATH="$FRAMEWORK_PATH/bash-modules"
export PHASES_PATH="$MODULES_PATH/phases"

# Check if modules exist, fallback to modular script if not
if [ ! -d "$MODULES_PATH" ] || [ ! -f "$MODULES_PATH/shared/common-functions.sh" ]; then
    echo "⚠️  Modules not found. Using fallback script..."
    if [ -f "$FRAMEWORK_PATH/test-plugin-modular.sh" ]; then
        exec "$FRAMEWORK_PATH/test-plugin-modular.sh" "$@"
    else
        echo "❌ Error: No fallback script available"
        exit 1
    fi
fi

# Source common functions
source "$MODULES_PATH/shared/common-functions.sh"

# Parse arguments
PLUGIN_NAME=$1
TEST_TYPE=${2:-full}
SKIP_INTERACTIVE=${3:-false}

# Environment variables
export WP_PATH="$(dirname "$FRAMEWORK_PATH")"
export PLUGIN_PATH="$WP_PATH/wp-content/plugins/$PLUGIN_NAME"
export UPLOAD_PATH="$WP_PATH/wp-content/uploads"
export INTERACTIVE_MODE=${INTERACTIVE:-false}
export USE_AST=${USE_AST:-true}
export SKIP_PHASES=${SKIP_PHASES:-""}
export TEST_TYPE
export PLUGIN_NAME
export SKIP_INTERACTIVE

# Function to show usage
show_usage() {
    cat << EOF
${BLUE}WordPress Plugin Testing Framework v12.0${NC}
==========================================

USAGE:
    $0 <plugin-name> [mode] [options]

PARAMETERS:
    plugin-name : Name of the plugin to test (required)
    mode        : Testing mode (optional)
                  - full (default): Run all 12 phases
                  - quick: Skip time-consuming phases (3,7,11)
                  - security: Focus on security (phases 1,2,4)
                  - performance: Focus on performance (phases 1,2,5)

OPTIONS:
    INTERACTIVE=true     : Enable interactive mode with checkpoints
    USE_AST=false       : Disable AST analysis
    SKIP_PHASES="3,7,11": Skip specific phases

EXAMPLES:
    # Full test
    $0 woocommerce

    # Quick mode
    $0 elementor quick

    # Interactive mode
    INTERACTIVE=true $0 yoast-seo

    # Skip specific phases
    SKIP_PHASES="7,11" $0 wpforms

    # Run single phase
    ./run-phase.sh -p plugin-name -n 4

PHASES:
    1.  Setup & Directory Structure
    2.  Plugin Detection & Basic Analysis
    3.  Plugin Check Analysis (WP Standards)
    4.  AI-Driven Code Analysis (Uses Plugin Check Data)
    5.  Security Vulnerability Scanning
    6.  Performance Analysis
    7.  Test Generation & Coverage
    8.  Visual Testing & Screenshots
    9.  WordPress Integration Tests
    10. Documentation Generation
    11. Report Consolidation
    12. Live Testing with Test Data
    13. Framework Safekeeping

EOF
}

# Function to check if phase should be skipped
should_skip_phase() {
    local phase=$1
    
    # Check SKIP_PHASES environment variable
    if [[ ",$SKIP_PHASES," == *",$phase,"* ]]; then
        return 0
    fi
    
    # Check mode-based skipping
    case "$TEST_TYPE" in
        quick)
            [[ "$phase" == "3" ]] || [[ "$phase" == "7" ]] || [[ "$phase" == "11" ]] && return 0
            ;;
        security)
            [[ "$phase" != "1" ]] && [[ "$phase" != "2" ]] && [[ "$phase" != "4" ]] && return 0
            ;;
        performance)
            [[ "$phase" != "1" ]] && [[ "$phase" != "2" ]] && [[ "$phase" != "5" ]] && return 0
            ;;
    esac
    
    return 1
}

# Function to run a phase
run_phase() {
    local phase_num=$1
    local phase_name=$2
    local phase_script=$3
    
    if should_skip_phase "$phase_num"; then
        print_warning "Skipping Phase $phase_num: $phase_name"
        SKIPPED_PHASES+=("$phase_num")
        return 0
    fi
    
    local phase_file="$PHASES_PATH/$phase_script"
    
    if [ -f "$phase_file" ]; then
        # Source the phase module
        source "$phase_file"
        
        # Call the phase function
        local func_name="run_phase_$(printf "%02d" $phase_num)"
        
        if declare -f "$func_name" > /dev/null; then
            print_info "Starting Phase $phase_num: $phase_name"
            
            # Run the phase function
            if $func_name "$PLUGIN_NAME"; then
                COMPLETED_PHASES+=("$phase_num")
                print_success "Phase $phase_num completed successfully"
            else
                FAILED_PHASES+=("$phase_num")
                print_error "Phase $phase_num failed"
                
                if [ "$INTERACTIVE_MODE" = "true" ]; then
                    read -p "Continue with remaining phases? (y/n): " -n 1 -r
                    echo
                    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
                fi
            fi
        else
            print_error "Phase function $func_name not found"
            FAILED_PHASES+=("$phase_num")
        fi
    else
        print_error "Phase module not found: $phase_script"
        FAILED_PHASES+=("$phase_num")
    fi
}

# Main execution
main() {
    # Check arguments
    if [ -z "$PLUGIN_NAME" ] || [ "$PLUGIN_NAME" == "--help" ] || [ "$PLUGIN_NAME" == "-h" ]; then
        show_usage
        exit 0
    fi
    
    # Validate plugin exists
    if [ ! -d "$PLUGIN_PATH" ]; then
        print_error "Plugin not found: $PLUGIN_PATH"
        exit 1
    fi
    
    # Banner
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   WP Testing Framework v13.0              ║${NC}"
    echo -e "${BLUE}║   Complete Plugin Analysis & Testing      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Plugin: $PLUGIN_NAME"
    echo "Mode: $TEST_TYPE"
    echo ""
    
    # Initialize tracking arrays
    COMPLETED_PHASES=()
    FAILED_PHASES=()
    SKIPPED_PHASES=()
    
    # Start timer
    START_TIME=$(date +%s)
    
    # Define phases (Plugin Check runs early for AI to use the data)
    declare -a PHASES=(
        "1:Setup & Directory Structure:phase-01-setup.sh"
        "2:Plugin Detection:phase-02-detection.sh"
        "3:Plugin Check Analysis (WP Standards):phase-03-plugin-check.sh"
        "4:AI Analysis (Uses Plugin Check Data):phase-04-ai-analysis.sh"
        "5:Security Scan:phase-05-security.sh"
        "6:Performance Analysis:phase-06-performance-analysis.sh"
        "7:Test Generation & AI Data:phase-07-enhanced.sh"
        "8:Visual Testing:phase-08-visual-testing.sh"
        "9:Integration Tests:phase-09-integration.sh"
        "10:Documentation:phase-10-documentation.sh"
        "11:Consolidation:phase-11-consolidation.sh"
        "12:Live Testing:phase-12-live-testing.sh"
        "13:Safekeeping:phase-13-safekeeping.sh"
    )
    
    # Execute phases
    for phase_def in "${PHASES[@]}"; do
        IFS=':' read -r phase_num phase_name phase_script <<< "$phase_def"
        run_phase "$phase_num" "$phase_name" "$phase_script"
    done
    
    # Calculate duration
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    DURATION_MIN=$((DURATION / 60))
    DURATION_SEC=$((DURATION % 60))
    
    # Summary
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🎉 ANALYSIS COMPLETE!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    echo -e "${BLUE}📊 Execution Summary:${NC}"
    echo "   Plugin: $PLUGIN_NAME"
    echo "   Mode: $TEST_TYPE"
    echo "   Duration: ${DURATION_MIN}m ${DURATION_SEC}s"
    echo ""
    
    echo -e "${BLUE}📈 Phase Results:${NC}"
    echo "   ✅ Completed: ${#COMPLETED_PHASES[@]} phases"
    [ ${#FAILED_PHASES[@]} -gt 0 ] && echo "   ❌ Failed: ${#FAILED_PHASES[@]} phases (${FAILED_PHASES[*]})"
    [ ${#SKIPPED_PHASES[@]} -gt 0 ] && echo "   ⏭️  Skipped: ${#SKIPPED_PHASES[@]} phases (${SKIPPED_PHASES[*]})"
    
    # Show results location
    if [ -n "$SCAN_DIR" ] && [ -d "$SCAN_DIR" ]; then
        echo ""
        echo -e "${BLUE}📁 Results saved to:${NC}"
        echo "   $SCAN_DIR"
        
        if [ -f "$SCAN_DIR/FINAL-REPORT.md" ]; then
            echo ""
            echo -e "${BLUE}📄 Final Report:${NC}"
            echo "   $SCAN_DIR/FINAL-REPORT.md"
        fi
    fi
    
    echo ""
    echo -e "${GREEN}Thank you for using WP Testing Framework!${NC}"
    echo ""
    
    # Exit with appropriate code
    [ ${#FAILED_PHASES[@]} -gt 0 ] && exit 1
    exit 0
}

# Run main function
main "$@"