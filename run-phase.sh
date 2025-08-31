#!/bin/bash

# WordPress Plugin Testing Framework - Run Specific Phase
# Allows running individual phases on demand using the modular structure
# Usage: ./run-phase.sh -p <plugin-name> -n <1-12> [-c <config-file>]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export FRAMEWORK_PATH="$SCRIPT_DIR"
export MODULES_PATH="$FRAMEWORK_PATH/bash-modules"
export PHASES_PATH="$MODULES_PATH/phases"

# Source common functions if available
if [ -f "$MODULES_PATH/shared/common-functions.sh" ]; then
    source "$MODULES_PATH/shared/common-functions.sh"
else
    # Basic fallback functions if modules not found
    print_error() { echo -e "${RED}❌ $1${NC}"; }
    print_success() { echo -e "${GREEN}✅ $1${NC}"; }
    print_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
    print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
fi

# Function to get phase module file
get_phase_module() {
    local phase=$1
    case $phase in
        1) echo "phase-01-setup.sh" ;;
        2) echo "phase-02-detection.sh" ;;
        3) echo "phase-03-ai-analysis.sh" ;;
        4) echo "phase-04-security.sh" ;;
        5) echo "phase-05-performance-analysis.sh" ;;
        6) echo "phase-06-test-generation.sh" ;;
        7) echo "phase-07-visual-testing.sh" ;;
        8) echo "phase-08-integration.sh" ;;
        9) echo "phase-09-documentation.sh" ;;
        10) echo "phase-10-consolidation.sh" ;;
        11) echo "phase-11-live-testing.sh" ;;
        12) echo "phase-12-safekeeping.sh" ;;
        *) echo "" ;;
    esac
}

# Function to get phase name
get_phase_name() {
    local phase=$1
    case $phase in
        1) echo "Setup & Directory Structure" ;;
        2) echo "Plugin Detection & Basic Analysis" ;;
        3) echo "AI-Driven Code Analysis" ;;
        4) echo "Security Vulnerability Scanning" ;;
        5) echo "Performance Analysis" ;;
        6) echo "Test Generation & Coverage" ;;
        7) echo "Visual Testing & Screenshots" ;;
        8) echo "WordPress Integration Tests" ;;
        9) echo "Documentation Generation" ;;
        10) echo "Report Consolidation" ;;
        11) echo "Live Testing with Test Data" ;;
        12) echo "Framework Safekeeping" ;;
        *) echo "Unknown Phase" ;;
    esac
}

# Function to get phase description
get_phase_description() {
    local phase=$1
    case $phase in
        1) echo "Creates directory structure and initializes environment" ;;
        2) echo "Detects plugin features and analyzes structure" ;;
        3) echo "Performs AI-driven code analysis and AST parsing" ;;
        4) echo "Scans for security vulnerabilities" ;;
        5) echo "Analyzes performance metrics and bottlenecks" ;;
        6) echo "Generates and executes PHPUnit tests" ;;
        7) echo "Captures screenshots and performs visual regression" ;;
        8) echo "Tests WordPress integration points" ;;
        9) echo "Generates documentation and validates quality" ;;
        10) echo "Consolidates all reports into final summary" ;;
        11) echo "Performs live testing with generated data" ;;
        12) echo "Archives results and maintains framework" ;;
        *) echo "No description available" ;;
    esac
}

# Function to show help
show_help() {
    cat << EOF
${BLUE}WordPress Plugin Testing Framework - Phase Runner${NC}
================================================

Run individual testing phases on demand.

USAGE:
    ./run-phase.sh -p <plugin> -n <phase>
    ./run-phase.sh -c <config-file>
    ./run-phase.sh -l
    ./run-phase.sh -h

OPTIONS:
    -p, --plugin <name>     Name of the plugin to test
    -n, --phase <1-12>      Phase number to run
    -c, --config <file>     Path to saved configuration JSON file
    -l, --list              List all available phases
    -h, --help              Show this help message

EXAMPLES:
    # Run security scan on WooCommerce
    ./run-phase.sh -p woocommerce -n 4
    
    # Run performance analysis
    ./run-phase.sh -p elementor -n 5
    
    # Generate tests for a plugin
    ./run-phase.sh -p wpforms -n 6
    
    # Run using saved configuration
    ./run-phase.sh -c /path/to/config.json
    
    # List all available phases
    ./run-phase.sh -l

ENVIRONMENT VARIABLES:
    INTERACTIVE=true        Enable interactive mode
    USE_AST=false          Disable AST analysis
    ANTHROPIC_API_KEY=xxx  Enable AI features

NOTES:
    - Phase 1 must be run first for new plugins to set up directories
    - Some phases depend on results from previous phases
    - Configuration is saved after each run for reuse

EOF
}

# Function to list phases
list_phases() {
    echo ""
    echo -e "${BLUE}Available Phases:${NC}"
    echo -e "${BLUE}=================${NC}"
    echo ""
    
    for i in {1..12}; do
        local name=$(get_phase_name $i)
        local desc=$(get_phase_description $i)
        local module=$(get_phase_module $i)
        
        printf "${GREEN}Phase %2d: %-30s${NC}\n" "$i" "$name"
        printf "         ${CYAN}%s${NC}\n" "$desc"
        printf "         Module: ${YELLOW}%s${NC}\n\n" "$module"
    done
}

# Function to run a specific phase module
run_phase_module() {
    local plugin="$1"
    local phase="$2"
    
    # Validate phase number
    if [[ ! "$phase" =~ ^[0-9]+$ ]] || [ "$phase" -lt 1 ] || [ "$phase" -gt 12 ]; then
        print_error "Invalid phase number: $phase (must be 1-12)"
        return 1
    fi
    
    # Get module file
    local module_file=$(get_phase_module $phase)
    local module_path="$PHASES_PATH/$module_file"
    
    if [ ! -f "$module_path" ]; then
        print_error "Phase module not found: $module_file"
        return 1
    fi
    
    # Set up environment
    export PLUGIN_NAME="$plugin"
    export WP_PATH="$(dirname "$FRAMEWORK_PATH")"
    export PLUGIN_PATH="$WP_PATH/wp-content/plugins/$PLUGIN_NAME"
    export UPLOAD_PATH="$WP_PATH/wp-content/uploads"
    export INTERACTIVE_MODE=${INTERACTIVE:-false}
    export USE_AST=${USE_AST:-true}
    export TEST_TYPE=${TEST_TYPE:-single}
    
    # Check if plugin exists
    if [ ! -d "$PLUGIN_PATH" ]; then
        print_error "Plugin not found at: $PLUGIN_PATH"
        return 1
    fi
    
    # Set up scan directory (needed by most phases)
    DATE_MONTH=$(date +"%Y-%m")
    export SCAN_DIR="$UPLOAD_PATH/wbcom-scan/$PLUGIN_NAME/$DATE_MONTH"
    export PLAN_DIR="$UPLOAD_PATH/wbcom-plan/$PLUGIN_NAME/$DATE_MONTH"
    export SAFEKEEP_DIR="$FRAMEWORK_PATH/plugins/$PLUGIN_NAME"
    
    # Check if Phase 1 has been run (create directories if needed for phase 1)
    if [ "$phase" -eq 1 ]; then
        print_info "Running Phase 1: Setup"
    elif [ ! -d "$SCAN_DIR" ]; then
        print_warning "No previous scan found for $PLUGIN_NAME"
        read -p "Run Phase 1 (Setup) first? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Running Phase 1 first..."
            run_phase_module "$plugin" 1
        else
            print_warning "Some phases require Phase 1 to be run first. Creating minimal structure..."
            mkdir -p "$SCAN_DIR/raw-outputs/coverage"
            mkdir -p "$SCAN_DIR/ai-analysis"
            mkdir -p "$SCAN_DIR/reports"
            mkdir -p "$SCAN_DIR/generated-tests"
            mkdir -p "$SCAN_DIR/phase-results"
        fi
    fi
    
    # Get phase info
    local phase_name=$(get_phase_name $phase)
    local phase_desc=$(get_phase_description $phase)
    
    # Banner
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   WP Testing Framework - Phase Runner        ║${NC}"
    printf "${BLUE}║   Plugin: %-35s║${NC}\n" "$PLUGIN_NAME"
    printf "${BLUE}║   Phase:  %-35s║${NC}\n" "$phase - $phase_name"
    echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${CYAN}$phase_desc${NC}"
    echo ""
    
    # Start timer
    START_TIME=$(date +%s)
    
    # Source and run the module
    print_info "Loading module: $module_file"
    source "$module_path"
    
    # Call the phase function
    local func_name="run_phase_$(printf "%02d" $phase)"
    
    if declare -f "$func_name" > /dev/null; then
        print_info "Executing phase function: $func_name"
        
        # Run the phase
        if $func_name "$PLUGIN_NAME"; then
            PHASE_STATUS="SUCCESS"
            print_success "Phase $phase completed successfully"
        else
            PHASE_STATUS="FAILED"
            print_error "Phase $phase failed"
        fi
    else
        print_error "Phase function $func_name not found in module"
        PHASE_STATUS="ERROR"
    fi
    
    # Calculate duration
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    # Display completion
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Phase $phase ${PHASE_STATUS}${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════${NC}"
    echo -e "Duration: ${DURATION}s"
    
    # Show report location if available
    if [ -d "$SCAN_DIR/reports" ]; then
        echo ""
        echo -e "${CYAN}Reports location:${NC}"
        echo "$SCAN_DIR/reports/"
        
        # List recent reports
        if ls "$SCAN_DIR/reports"/*.md >/dev/null 2>&1; then
            echo ""
            echo -e "${CYAN}Generated reports:${NC}"
            ls -1t "$SCAN_DIR/reports"/*.md 2>/dev/null | head -5 | while read report; do
                echo "  - $(basename "$report")"
            done
        fi
    fi
    
    # Save configuration for reuse
    CONFIG_SAVE_PATH="$FRAMEWORK_PATH/last-phase-config.json"
    cat > "$CONFIG_SAVE_PATH" << EOF
{
    "PluginName": "$PLUGIN_NAME",
    "LastPhase": $phase,
    "ScanDir": "$SCAN_DIR",
    "Timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
    
    echo ""
    echo -e "${CYAN}Configuration saved to: $CONFIG_SAVE_PATH${NC}"
    echo -e "${CYAN}Rerun with: ./run-phase.sh -c \"$CONFIG_SAVE_PATH\"${NC}"
    
    # Suggest next steps
    if [ "$phase" -lt 12 ]; then
        NEXT_PHASE=$((phase + 1))
        NEXT_NAME=$(get_phase_name $NEXT_PHASE)
        echo ""
        echo -e "${BLUE}Next Step:${NC}"
        echo -e "Run Phase $NEXT_PHASE ($NEXT_NAME):"
        echo -e "${YELLOW}./run-phase.sh -p $PLUGIN_NAME -n $NEXT_PHASE${NC}"
    fi
    
    if [ "$phase" -eq 10 ]; then
        echo ""
        echo -e "${CYAN}Tip: Phase 10 consolidates all previous phase results.${NC}"
        echo -e "${CYAN}Make sure you've run all needed phases before consolidation.${NC}"
    fi
    
    return 0
}

# Parse command line arguments
PLUGIN=""
PHASE=""
CONFIG_FILE=""
LIST_PHASES=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--plugin)
            PLUGIN="$2"
            shift 2
            ;;
        -n|--phase)
            PHASE="$2"
            shift 2
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -l|--list)
            LIST_PHASES=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Handle list phases
if [ "$LIST_PHASES" = true ]; then
    list_phases
    exit 0
fi

# Load configuration if provided
if [ -n "$CONFIG_FILE" ]; then
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "Config file not found: $CONFIG_FILE"
        exit 1
    fi
    
    # Parse JSON config (requires jq)
    if command -v jq &> /dev/null; then
        PLUGIN=$(jq -r '.PluginName // empty' "$CONFIG_FILE")
        if [ -z "$PHASE" ]; then
            LAST_PHASE=$(jq -r '.LastPhase // empty' "$CONFIG_FILE")
            if [ -n "$LAST_PHASE" ] && [ "$LAST_PHASE" -lt 12 ]; then
                PHASE=$((LAST_PHASE + 1))
                print_info "Continuing from last phase: running Phase $PHASE"
            fi
        fi
    else
        print_warning "jq not found. Cannot parse config file."
        echo "Install jq: brew install jq (Mac) or apt-get install jq (Linux)"
        exit 1
    fi
fi

# Validate inputs
if [ -z "$PLUGIN" ] || [ -z "$PHASE" ]; then
    print_error "Error: Plugin name and phase number are required"
    show_help
    exit 1
fi

# Run the phase
echo ""
print_info "Running Phase $PHASE for plugin: $PLUGIN"
run_phase_module "$PLUGIN" "$PHASE"

# Exit with appropriate code
if [ "$PHASE_STATUS" = "SUCCESS" ]; then
    echo ""
    echo -e "${GREEN}✓ Phase $PHASE execution complete!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}✗ Phase $PHASE execution failed!${NC}"
    exit 1
fi