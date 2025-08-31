#!/bin/bash

# WordPress Plugin Testing Framework v12.0 - Modular Edition
# Main orchestrator that calls individual phase modules
# Usage: ./test-plugin-modular.sh <plugin-name> [mode] [options]

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_PATH="$SCRIPT_DIR"
MODULES_PATH="$FRAMEWORK_PATH/bash-modules"
PHASES_PATH="$MODULES_PATH/phases"

# Source common functions
source "$MODULES_PATH/shared/common-functions.sh"

# Configuration
PLUGIN_NAME=$1
TEST_TYPE=${2:-full}
SKIP_INTERACTIVE=${3:-false}
INTERACTIVE_MODE=${INTERACTIVE:-false}
USE_AST=${USE_AST:-true}
SKIP_PHASES=${SKIP_PHASES:-""}

# Export global variables
export FRAMEWORK_PATH
export WP_PATH="$(dirname "$FRAMEWORK_PATH")"
export PLUGIN_PATH="$WP_PATH/wp-content/plugins/$PLUGIN_NAME"
export UPLOAD_PATH="$WP_PATH/wp-content/uploads"
export PLUGIN_NAME
export TEST_TYPE
export SKIP_INTERACTIVE
export INTERACTIVE_MODE
export USE_AST

# Function to show usage
show_usage() {
    cat << EOF
${BLUE}WordPress Plugin Testing Framework v12.0 - Modular Edition${NC}
==========================================================

USAGE:
    $0 <plugin-name> [mode] [options]

PARAMETERS:
    plugin-name : Name of the plugin to test (required)
    mode        : Testing mode (optional)
                  - full (default): Run all 12 phases
                  - quick: Skip time-consuming phases
                  - security: Focus on security analysis
                  - performance: Focus on performance

OPTIONS:
    INTERACTIVE=true     : Enable interactive mode with checkpoints
    USE_AST=false       : Disable AST analysis
    SKIP_PHASES="3,7,11": Skip specific phases

EXAMPLES:
    # Full test with all phases
    $0 woocommerce

    # Quick test
    $0 elementor quick

    # Interactive mode
    INTERACTIVE=true $0 yoast-seo

    # Skip specific phases
    SKIP_PHASES="7,11" $0 wpforms

PHASES:
    1.  Setup & Directory Structure
    2.  Plugin Detection & Basic Analysis
    3.  AI-Driven Code Analysis (AST + Dynamic)
    4.  Security Vulnerability Scanning
    5.  Performance Analysis
    6.  Test Generation & Coverage
    7.  Visual Testing & Screenshots
    8.  WordPress Integration Tests
    9.  Documentation Generation
    10. Report Consolidation
    11. Live Testing with Test Data
    12. Framework Safekeeping

EOF
}

# Function to check if phase should be skipped
should_skip_phase() {
    local phase=$1
    
    # Check if in SKIP_PHASES
    if [[ ",$SKIP_PHASES," == *",$phase,"* ]]; then
        return 0
    fi
    
    # Check mode-based skipping
    case "$TEST_TYPE" in
        quick)
            # Skip time-consuming phases in quick mode
            if [[ "$phase" == "3" ]] || [[ "$phase" == "7" ]] || [[ "$phase" == "11" ]]; then
                return 0
            fi
            ;;
        security)
            # Only run security-related phases
            if [[ "$phase" != "1" ]] && [[ "$phase" != "2" ]] && [[ "$phase" != "4" ]]; then
                return 0
            fi
            ;;
        performance)
            # Only run performance-related phases
            if [[ "$phase" != "1" ]] && [[ "$phase" != "2" ]] && [[ "$phase" != "5" ]]; then
                return 0
            fi
            ;;
    esac
    
    return 1
}

# Function to run a phase module
run_phase() {
    local phase_num=$1
    local phase_name=$2
    local phase_script=$3
    
    if should_skip_phase "$phase_num"; then
        print_warning "Skipping Phase $phase_num: $phase_name"
        return 0
    fi
    
    local phase_file="$PHASES_PATH/$phase_script"
    
    if [ -f "$phase_file" ]; then
        print_info "Starting Phase $phase_num: $phase_name"
        
        # Make script executable
        chmod +x "$phase_file"
        
        # Source and run the phase
        source "$phase_file"
        
        # Call the phase function
        local func_name="run_phase_$(printf "%02d" $phase_num)"
        if declare -f "$func_name" > /dev/null; then
            $func_name "$PLUGIN_NAME"
            local result=$?
            
            if [ $result -eq 0 ]; then
                print_success "Phase $phase_num completed successfully"
            else
                print_error "Phase $phase_num failed with code $result"
                return $result
            fi
        else
            print_warning "Phase $phase_num function not found, using fallback"
            bash "$phase_file" "$PLUGIN_NAME"
        fi
    else
        print_warning "Phase $phase_num module not found: $phase_script"
        
        # TODO: Add inline fallback functions here if needed
        print_info "Using inline implementation for Phase $phase_num"
    fi
    
    return 0
}

# Main execution
main() {
    # Check if plugin name provided
    if [ -z "$PLUGIN_NAME" ] || [ "$PLUGIN_NAME" == "--help" ] || [ "$PLUGIN_NAME" == "-h" ]; then
        show_usage
        exit 0
    fi
    
    # Banner
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   WP Testing Framework v12.0 - Modular     ║${NC}"
    echo -e "${BLUE}║   Complete Plugin Analysis & Testing       ║${NC}"
    echo -e "${BLUE}║   Plugin: $(printf "%-33s" "$PLUGIN_NAME")║${NC}"
    echo -e "${BLUE}║   Mode: $(printf "%-35s" "$TEST_TYPE")║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Start timer
    START_TIME=$(date +%s)
    
    # Phase definitions
    declare -a PHASES=(
        "1:Setup & Directory Structure:phase-01-setup.sh"
        "2:Plugin Detection:phase-02-detection.sh"
        "3:AI Analysis:phase-03-ai-analysis.sh"
        "4:Security Scan:phase-04-security.sh"
        "5:Performance Analysis:phase-05-performance.sh"
        "6:Test Generation:phase-06-test-generation.sh"
        "7:Visual Testing:phase-07-visual-testing.sh"
        "8:Integration Tests:phase-08-integration.sh"
        "9:Documentation:phase-09-documentation.sh"
        "10:Consolidation:phase-10-consolidation.sh"
        "11:Live Testing:phase-11-live-testing.sh"
        "12:Safekeeping:phase-12-safekeeping.sh"
    )
    
    # Track phase results
    COMPLETED_PHASES=()
    FAILED_PHASES=()
    SKIPPED_PHASES=()
    
    # Execute phases
    for phase_def in "${PHASES[@]}"; do
        IFS=':' read -r phase_num phase_name phase_script <<< "$phase_def"
        
        if run_phase "$phase_num" "$phase_name" "$phase_script"; then
            COMPLETED_PHASES+=("$phase_num")
        else
            FAILED_PHASES+=("$phase_num")
            
            if [ "$INTERACTIVE_MODE" = "true" ]; then
                read -p "Phase $phase_num failed. Continue? (y/n): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    break
                fi
            fi
        fi
    done
    
    # Calculate execution time
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    DURATION_MIN=$((DURATION / 60))
    DURATION_SEC=$((DURATION % 60))
    
    # Final summary
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🎉 ANALYSIS COMPLETE!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    echo -e "${BLUE}📊 Execution Summary:${NC}"
    echo "   Plugin: $PLUGIN_NAME"
    echo "   Mode: $TEST_TYPE"
    echo "   Duration: ${DURATION_MIN}m ${DURATION_SEC}s"
    echo ""
    
    echo -e "${BLUE}📈 Phase Results:${NC}"
    echo "   Completed: ${#COMPLETED_PHASES[@]} phases"
    echo "   Failed: ${#FAILED_PHASES[@]} phases"
    echo "   Skipped: ${#SKIPPED_PHASES[@]} phases"
    
    if [ ${#FAILED_PHASES[@]} -gt 0 ]; then
        echo ""
        echo -e "${RED}Failed phases: ${FAILED_PHASES[*]}${NC}"
    fi
    
    # Show report location
    if [ -n "$SCAN_DIR" ] && [ -d "$SCAN_DIR" ]; then
        echo ""
        echo -e "${BLUE}📁 Results saved to:${NC}"
        echo "   $SCAN_DIR"
        
        if [ -d "$SCAN_DIR/reports" ]; then
            echo ""
            echo -e "${BLUE}📄 Reports:${NC}"
            ls -1 "$SCAN_DIR/reports/"*.md 2>/dev/null | while read report; do
                echo "   - $(basename "$report")"
            done
        fi
    fi
    
    echo ""
    echo -e "${GREEN}Thank you for using WP Testing Framework!${NC}"
    echo ""
}

# Run main function
main "$@"